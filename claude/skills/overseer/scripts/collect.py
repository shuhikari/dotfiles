#!/usr/bin/env python3
"""Coleta o estado de todos os agentes do Orca para o overseer.

Fontes (somente leitura):
- `orca worktree ps --json`: worktrees, agentes, estado, última resposta.
- Transcrições do Claude Code (~/.claude/projects/<slug>/*.jsonl): tema da
  sessão e últimos pedidos do usuário.
- git de cada worktree: alterações locais, commits à frente/atrás do upstream.
- ai-memory (SQLite, modo leitura): handoffs abertos.

Saída: Markdown compacto em stdout, pensado para ser lido por um modelo.
"""

import argparse
import json
import os
import re
import shlex
import sqlite3
import subprocess
import sys
import time
from pathlib import Path

HOME = Path.home()
PROJECTS_DIR = HOME / ".claude" / "projects"
AI_MEMORY_DB = HOME / "Library" / "Application Support" / "ai-memory" / "db" / "memory.sqlite"

MAX_ASSISTANT = 2500
MAX_PROMPT = 500
HEAD_BYTES = 400_000
TAIL_BYTES = 3_000_000

NOISE_PREFIXES = (
    "<task-notification>",
    "<local-command",
    "<command-",
    "<system-reminder>",
    "Base directory for this skill:",
    "Caveat:",
    "[Request interrupted",
    "This session is being continued from a previous conversation",
    "<bash-input>",
    "<bash-stdout>",
    "<bash-stderr>",
)

SECRET_PATTERNS = [
    (re.compile(r"(discord(?:app)?\.com/api/webhooks/\d+/)[\w-]+"), r"\1[REDACTED]"),
    (re.compile(r"\b(sk-[a-z]*-?|ghp_|gho_|github_pat_|xox[abpr]-|pk_|AKIA)[A-Za-z0-9_\-]{8,}"), "[REDACTED]"),
    (re.compile(r"(?i)\b(bearer|token|api[_-]?key|secret|password|senha)(\s*[:=]\s*)\S{6,}"), r"\1\2[REDACTED]"),
]


def redact(text: str) -> str:
    for pattern, repl in SECRET_PATTERNS:
        text = pattern.sub(repl, text)
    return text
TRIVIAL_PROMPTS = {"resume", "/resume", "continue", "continua", "continuar", "ok", "sim", "s", "y"}


def now_ms() -> int:
    return int(time.time() * 1000)


def age(ms) -> str:
    if not ms:
        return "?"
    delta = max(0, (now_ms() - int(ms)) // 1000)
    if delta < 3600:
        return f"{delta // 60}min"
    if delta < 86400:
        return f"{delta // 3600}h{(delta % 3600) // 60:02d}"
    return f"{delta // 86400}d"


def flat(text: str, limit: int) -> str:
    """Uma linha só: evita que títulos Markdown do conteúdo virem seções do snapshot."""
    return clip(re.sub(r"\s+", " ", text or ""), limit)


def clip(text: str, limit: int) -> str:
    text = redact((text or "").strip())
    if len(text) <= limit:
        return text
    return text[:limit].rstrip() + " […]"


def run(cmd, cwd=None, timeout=20):
    try:
        out = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return out.returncode, out.stdout
    except (OSError, subprocess.TimeoutExpired):
        return 1, ""


def orca_ps():
    code, out = run(["orca", "worktree", "ps", "--json"], timeout=30)
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        sys.exit(f"orca worktree ps falhou (exit {code}). O Orca está aberto? Rode `orca open --json`.")
    if not data.get("ok"):
        sys.exit(f"orca worktree ps retornou erro: {json.dumps(data.get('error'))[:500]}")
    return data["result"]["worktrees"]


def git_state(path: str) -> str:
    if not path or not os.path.isdir(path):
        return "pasta ausente"
    code, porcelain = run(["git", "-C", path, "status", "--porcelain"])
    if code != 0:
        return "não é git"
    dirty = len([l for l in porcelain.splitlines() if l.strip()])
    parts = [f"{dirty} arquivo(s) alterado(s)" if dirty else "limpo"]
    code, counts = run(["git", "-C", path, "rev-list", "--left-right", "--count", "@{u}...HEAD"])
    if code == 0 and counts.strip():
        behind, ahead = counts.split()
        if ahead != "0":
            parts.append(f"{ahead} commit(s) não publicados")
        if behind != "0":
            parts.append(f"{behind} atrás do upstream")
    elif code != 0:
        parts.append("sem upstream")
    code, last = run(["git", "-C", path, "log", "-1", "--format=%cr · %s"])
    if code == 0 and last.strip():
        parts.append(f"último commit {clip(last.strip(), 90)}")
    return "; ".join(parts)


def text_of(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text")
    return ""


def is_real_prompt(entry) -> bool:
    if entry.get("type") != "user" or entry.get("isMeta") or entry.get("isSidechain"):
        return False
    content = entry.get("message", {}).get("content")
    if isinstance(content, list) and any(isinstance(c, dict) and c.get("type") == "tool_result" for c in content):
        return False
    text = text_of(content).strip()
    return bool(text) and not text.startswith(NOISE_PREFIXES) and text.lower() not in TRIVIAL_PROMPTS


def read_lines(fh, start: int, size: int):
    fh.seek(start)
    chunk = fh.read(size)
    lines = chunk.split(b"\n")
    if start > 0:
        lines = lines[1:]  # primeira linha provavelmente cortada
    for raw in lines:
        try:
            yield json.loads(raw)
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue


def transcript_dir(path: str) -> Path:
    return PROJECTS_DIR / re.sub(r"[^A-Za-z0-9]", "-", path)


def session_title(file: Path):
    """Último título gravado pelo Claude Code (`/rename` ou título automático)."""
    code, out = run(["grep", "-o", '"\\(customTitle\\|aiTitle\\)":"[^"]*"', str(file)])
    if code != 0 or not out.strip():
        return None
    custom = [l for l in out.splitlines() if l.startswith('"customTitle"')]
    last = (custom or out.splitlines())[-1]
    return json.loads("{" + last + "}").popitem()[1]


def find_transcript(path: str, title, used: set):
    """Transcrição do agente: a da pasta da worktree cujo título bate com a aba do Orca;
    senão, a mais recente ainda não atribuída a outro agente."""
    folder = transcript_dir(path)
    if not folder.is_dir():
        return None
    files = sorted(folder.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)[:8]
    if title:
        for file in files:
            if file not in used and session_title(file) == title:
                return file
    return next((f for f in files if f not in used), None)


def transcript_info(file: Path):
    size = file.stat().st_size
    first_prompt, prompts, last_assistant = None, [], None
    with file.open("rb") as fh:
        for entry in read_lines(fh, 0, HEAD_BYTES):
            if is_real_prompt(entry):
                first_prompt = text_of(entry["message"]["content"])
                break
        for entry in read_lines(fh, max(0, size - TAIL_BYTES), TAIL_BYTES):
            if is_real_prompt(entry):
                prompts.append(text_of(entry["message"]["content"]))
            elif entry.get("type") == "assistant" and not entry.get("isSidechain"):
                text = text_of(entry.get("message", {}).get("content"))
                if text.strip():
                    last_assistant = text
    return {
        "session": file.stem,
        "title": session_title(file),
        "first_prompt": first_prompt,
        "recent_prompts": prompts[-3:],
        "last_assistant": last_assistant,
    }


def orca_terminals():
    """Terminais vivos do Orca (handle, title, tabId, leafId, worktreePath)."""
    code, out = run(["orca", "terminal", "list", "--json"], timeout=30)
    try:
        return json.loads(out)["result"]["terminals"]
    except (json.JSONDecodeError, KeyError, TypeError):
        return []


def match_terminal(agent, path, terminals, used):
    """Terminal do agente: pelo paneKey (tabId:leafId). Abas não montadas na UI vêm com
    ids `pty:...`; nesse caso vale o único terminal livre do caminho."""
    for t in terminals:
        if f"{t.get('tabId')}:{t.get('leafId')}" == agent.get("paneKey"):
            return t
    free = [t for t in terminals if t.get("worktreePath") == path and t["handle"] not in used]
    return free[0] if len(free) == 1 else None


def open_handoffs():
    if not AI_MEMORY_DB.exists():
        return []
    try:
        con = sqlite3.connect(f"file:{AI_MEMORY_DB}?mode=ro", uri=True, timeout=5)
        rows = con.execute(
            """select h.created_at, p.name, h.cwd, h.summary, h.next_steps, h.open_questions
               from handoffs h left join projects p on p.id = h.project_id
               where h.state = 'open' order by h.created_at desc"""
        ).fetchall()
        con.close()
    except sqlite3.Error as err:
        return [{"error": str(err)}]
    result = []
    for created, project, cwd, summary, next_steps, questions in rows:
        result.append({
            "created": time.strftime("%Y-%m-%d %H:%M", time.localtime(int(created) / 1_000_000)) if created else "?",
            "project": project,
            "cwd": cwd,
            "summary": summary,
            "next_steps": json.loads(next_steps or "[]"),
            "open_questions": json.loads(questions or "[]"),
        })
    return result


def describe_agent(agent, terminal, transcript, path) -> list:
    if agent.get("paneKey") and agent.get("paneKey") == os.environ.get("ORCA_PANE_KEY"):
        return [f"- agente {agent.get('agentType')}: ESTA SESSÃO (o próprio overseer, ignore)"]
    state = agent.get("state") or "?"
    flag = " (interrompido)" if agent.get("interrupted") else ""
    name = (terminal or {}).get("title") or (transcript or {}).get("title") or agent.get("displayName") or "sem título"
    lines = [f"- sessão «{name}» — agente {agent.get('agentType')}: **{state}**{flag} há {age(agent.get('stateStartedAt'))}"]
    access = []
    if terminal:
        access.append(f"focar no Orca: `orca terminal switch --terminal {terminal['handle']}`")
    if transcript:
        access.append(f"retomar fora do Orca: `cd {shlex.quote(path)} && claude --resume {transcript['session']}`")
    if access:
        lines.append("  - acesso: " + " · ".join(access))
    if state == "working" and agent.get("toolName"):
        status = (agent.get("programStatus") or {}).get("message") or ""
        lines.append(f"  - agora: {agent['toolName']} — {clip(status or agent.get('toolInput') or '', 160)}")
    if agent.get("taskTitle"):
        lines.append(f"  - task: {agent['taskTitle']}")
    if transcript and transcript.get("first_prompt"):
        lines.append(f"  - tema da sessão (1º pedido): {flat(transcript['first_prompt'], MAX_PROMPT)}")
    recent = (transcript or {}).get("recent_prompts") or []
    if recent:
        for prompt in recent:
            lines.append(f"  - pedido recente: {flat(prompt, MAX_PROMPT)}")
    elif agent.get("prompt"):
        lines.append(f"  - último pedido: {flat(agent['prompt'], MAX_PROMPT)}")
    answer = agent.get("lastAssistantMessage") or (transcript or {}).get("last_assistant")
    if answer:
        quoted = re.sub(r"^#+\s*", "", clip(answer, MAX_ASSISTANT), flags=re.M).replace("\n", "\n    > ")
        lines.append(f"  - última resposta do agente:\n    > {quoted}")
    return lines


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true", help="detalha também worktrees sem terminal vivo")
    parser.add_argument("--no-git", action="store_true", help="pula o git (mais rápido)")
    args = parser.parse_args()

    worktrees = orca_ps()
    terminals = orca_terminals()
    handoffs = open_handoffs()
    live, idle = [], []
    for wt in worktrees:
        if wt.get("isArchived"):
            continue
        has_agents = bool(wt.get("agents"))
        (live if has_agents or wt.get("liveTerminalCount") or args.all else idle).append(wt)

    live.sort(key=lambda w: w.get("lastActivityAt") or 0, reverse=True)
    out = [f"# Snapshot do Orca — {time.strftime('%Y-%m-%d %H:%M')}", ""]
    out.append(f"{len(live)} worktree(s) com terminal ou agente; {len(idle)} sem terminal vivo; {len(handoffs)} handoff(s) aberto(s).")
    out.append("")

    numbers = {}
    for number, wt in enumerate(live, start=1):
        numbers[wt.get("path")] = number
        branch = (wt.get("branch") or "").removeprefix("refs/heads/")
        out.append(f"## [{number}] {wt.get('displayName')} — repo {wt.get('repo')}")
        meta = [f"branch `{branch}`", f"status no Orca: {wt.get('workspaceStatus')}",
                f"última atividade há {age(wt.get('lastActivityAt'))}"]
        if wt.get("isPinned"):
            meta.append("fixado")
        if wt.get("unread"):
            meta.append("não lido")
        out.append("- " + " · ".join(meta))
        out.append(f"- card no Orca: «{wt.get('displayName')}» (repo {wt.get('repo')}) · caminho `{wt.get('path')}`")
        if wt.get("comment"):
            out.append(f"- comentário no card: {wt['comment']}")
        if wt.get("linkedPR"):
            out.append(f"- PR vinculado: {json.dumps(wt['linkedPR'], ensure_ascii=False)[:200]}")
        if wt.get("linkedIssue") or wt.get("linkedItems"):
            out.append(f"- itens vinculados: {json.dumps(wt.get('linkedIssue') or wt.get('linkedItems'), ensure_ascii=False)[:200]}")
        if not args.no_git:
            out.append(f"- git: {git_state(wt.get('path'))}")
        agents = wt.get("agents") or []
        used, used_terms = set(), set()
        if not agents:
            out.append("- nenhum agente detectado no terminal")
            for t in terminals:
                if t.get("worktreePath") == wt.get("path"):
                    out.append(f"  - aba «{t.get('title') or 'sem título'}»: `orca terminal switch --terminal {t['handle']}`")
        for agent in agents:
            terminal = match_terminal(agent, wt.get("path"), terminals, used_terms)
            if terminal:
                used_terms.add(terminal["handle"])
            transcript = None
            if agent.get("agentType") == "claude" and agent.get("paneKey") != os.environ.get("ORCA_PANE_KEY"):
                file = find_transcript(wt.get("path") or "", (terminal or {}).get("title"), used)
                if file:
                    used.add(file)
                    transcript = transcript_info(file)
            out.extend(describe_agent(agent, terminal, transcript, wt.get("path") or ""))
        out.append("")

    if idle:
        out.append("## Worktrees sem terminal vivo")
        for wt in sorted(idle, key=lambda w: w.get("lastActivityAt") or 0, reverse=True):
            branch = (wt.get("branch") or "").removeprefix("refs/heads/")
            out.append(f"- {wt.get('repo')} / {wt.get('displayName')} (`{branch}`, {wt.get('workspaceStatus')}, "
                       f"atividade há {age(wt.get('lastActivityAt'))})")
        out.append("")

    if handoffs:
        out.append("## Handoffs abertos no ai-memory (ainda não retomados)")
        for h in handoffs:
            if "error" in h:
                out.append(f"- erro lendo o ai-memory: {h['error']}")
                continue
            steps = [x for x in h["next_steps"] if not x.startswith("Tools used:")]
            questions = [x for x in h["open_questions"] if not x.startswith("Continue from:")]
            auto = not steps and not questions
            kind = "automático" if auto else "manual"
            where = f"worktree [{numbers[h['cwd']]}]" if h["cwd"] in numbers else f"origem `{h['cwd']}`"
            out.append(f"- [{h['created']}] ({kind}) projeto `{h['project']}` ({where}): "
                       f"{flat(h['summary'], 300 if auto else 600)}")
            for step in steps[:3]:
                out.append(f"  - próximo: {flat(step, 300)}")
            for question in questions[:2]:
                out.append(f"  - em aberto: {flat(question, 300)}")
        out.append("")

    print("\n".join(out))


if __name__ == "__main__":
    main()
