#!/usr/bin/env python3
"""Catálogo de horas das sessões do Claude Code, para cobrança.

O Claude Code apaga transcrições depois de `cleanupPeriodDays` (padrão 30 dias,
https://code.claude.com/docs/en/settings-reference#cleanupperioddays). Este script
extrai os fatos de cada sessão para um registro próprio, que nunca é apagado.

    horas.py sync [--hook]          # cataloga transcrições novas ou alteradas
    horas.py relatorio --de 2026-10-01 --ate 2026-10-31 [--cliente X] [--csv]

Fatos gravados por turno (um turno começa num pedido real seu e termina no último
evento antes do próximo pedido):
- inicio: horário do pedido (UTC).
- agente_s: soma dos intervalos entre eventos do turno, descartando intervalos
  maiores que PAUSA_AGENTE (agente parado esperando permissão ou processo).
- espera_s: tempo entre o fim do turno anterior e este pedido (leitura e escrita suas).
A regra de cobrança (quanto da espera conta como tempo seu) é aplicada só no
relatório, então pode mudar sem perder dado.
"""

import argparse
import csv
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

HOME = Path.home()
PROJECTS_DIR = HOME / ".claude" / "projects"
STATE_DIR = HOME / ".local" / "state" / "overseer" / "horas"
SESSIONS_DIR = STATE_DIR / "sessoes"
CLIENTS_FILE = HOME / ".config" / "overseer" / "clientes.json"
TZ = ZoneInfo("America/Sao_Paulo")

PAUSA_AGENTE_S = 10 * 60   # intervalo maior que isso dentro do turno = agente ocioso
TETO_ESPERA_S = 15 * 60    # espera até isso conta como tempo seu; acima, você estava fora
TASK_KEY = re.compile(r"(?<![A-Za-z0-9])([A-Z][A-Z0-9]{1,9}-\d{1,6})(?![A-Za-z0-9])")
UUID = re.compile(r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}")
NOISE_PREFIXES = (
    "<local-command", "<command-", "<system-reminder>", "<bash-input>", "<bash-stdout>",
    "<bash-stderr>", "Base directory for this skill:", "Caveat:", "[Request interrupted",
    "This session is being continued from a previous conversation",
)


def parse_ts(value):
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (AttributeError, ValueError):
        return None


def text_of(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text")
    return ""


def is_human_prompt(entry) -> bool:
    if entry.get("type") != "user" or entry.get("isMeta") or entry.get("isSidechain"):
        return False
    content = entry.get("message", {}).get("content")
    if isinstance(content, list) and any(isinstance(c, dict) and c.get("type") == "tool_result" for c in content):
        return False
    text = text_of(content).strip()
    return bool(text) and not text.startswith(NOISE_PREFIXES) and not text.startswith("<task-notification>")


def is_wakeup(entry) -> bool:
    """Notificação de tarefa em background: reativa o agente sem ação sua."""
    if entry.get("type") != "user":
        return False
    return text_of(entry.get("message", {}).get("content")).lstrip().startswith("<task-notification>")


def read_entries(file: Path):
    with file.open("rb") as fh:
        for raw in fh:
            try:
                yield json.loads(raw)
            except (json.JSONDecodeError, UnicodeDecodeError):
                continue


def agent_seconds(stamps) -> float:
    stamps = sorted(stamps)
    return sum(b - a for a, b in zip(stamps, stamps[1:]) if b - a <= PAUSA_AGENTE_S)


def analyse(file: Path) -> dict:
    """Turnos, tokens e metadados de uma transcrição principal."""
    turns, current, last_event = [], None, None
    tokens, seen_messages = defaultdict(lambda: defaultdict(int)), set()
    meta = {"cwd": None, "branch": None, "title": None, "custom_title": None}
    for entry in read_entries(file):
        meta["cwd"] = meta["cwd"] or entry.get("cwd")
        if entry.get("gitBranch") and entry.get("gitBranch") != "HEAD":
            meta["branch"] = entry["gitBranch"]
        if entry.get("type") == "ai-title":
            meta["title"] = entry.get("aiTitle")
        if entry.get("type") == "custom-title":
            meta["custom_title"] = entry.get("customTitle")
        if entry.get("isSidechain"):
            continue
        ts = parse_ts(entry.get("timestamp"))
        if ts is None or entry.get("type") not in ("user", "assistant", "system"):
            continue
        stamp = ts.timestamp()
        if entry.get("type") == "assistant":
            message = entry.get("message", {})
            usage, key = message.get("usage"), message.get("id") or entry.get("requestId")
            if usage and key and key not in seen_messages:
                seen_messages.add(key)
                bucket = tokens[message.get("model") or "?"]
                for field in ("input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"):
                    bucket[field] += usage.get(field) or 0
        if is_human_prompt(entry):
            if current:
                turns.append(current)
            gap = stamp - last_event if last_event else 0
            current = {"inicio": ts.isoformat(), "espera_s": round(max(0, gap)), "stamps": [stamp], "humano": True}
        elif current is None and is_wakeup(entry):
            current = {"inicio": ts.isoformat(), "espera_s": 0, "stamps": [stamp], "humano": False}
        elif current is not None:
            current["stamps"].append(stamp)
        last_event = stamp
    if current:
        turns.append(current)
    for turn in turns:
        turn["agente_s"] = round(agent_seconds(turn.pop("stamps")))
    return {"turns": turns, "tokens": {m: dict(v) for m, v in tokens.items()}, **meta}


def subagents(file: Path) -> list:
    folder = file.with_suffix("") / "subagents"
    result = []
    for sub in sorted(folder.glob("agent-*.jsonl")) if folder.is_dir() else []:
        stamps, tokens, seen = [], defaultdict(lambda: defaultdict(int)), set()
        for entry in read_entries(sub):
            ts = parse_ts(entry.get("timestamp"))
            if ts:
                stamps.append(ts.timestamp())
            message = entry.get("message", {}) if entry.get("type") == "assistant" else {}
            key = message.get("id")
            if message.get("usage") and key and key not in seen:
                seen.add(key)
                for field in ("input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"):
                    tokens[message.get("model") or "?"][field] += message["usage"].get(field) or 0
        if not stamps:
            continue
        try:
            info = json.loads(sub.with_suffix(".meta.json").read_text())
        except (OSError, json.JSONDecodeError):
            info = {}
        result.append({
            "id": sub.stem, "descricao": info.get("description"), "modelo": info.get("model"),
            "inicio": datetime.fromtimestamp(min(stamps), timezone.utc).isoformat(),
            "agente_s": round(agent_seconds(stamps)), "tokens": {m: dict(v) for m, v in tokens.items()},
        })
    return result


def sync_file(file: Path, force=False) -> bool:
    target = SESSIONS_DIR / f"{file.stem}.json"
    mtime = file.stat().st_mtime
    if not force and target.exists():
        try:
            if json.loads(target.read_text()).get("fonte_mtime", 0) >= mtime:
                return False
        except json.JSONDecodeError:
            pass
    data = analyse(file)
    if not data["turns"]:
        return False
    labels = UUID.sub(" ", " ".join(filter(None, [data["branch"], data["custom_title"], data["title"]])))
    keys = sorted(set(TASK_KEY.findall(labels)))
    record = {
        "sessao": file.stem,
        "titulo": data["custom_title"] or data["title"],
        "cwd": data["cwd"],
        "repo": Path(data["cwd"]).name if data["cwd"] else file.parent.name,
        "branch": data["branch"],
        "tasks": keys,
        "turnos": data["turns"],
        "tokens": data["tokens"],
        "subagentes": subagents(file),
        "fonte": str(file),
        "fonte_mtime": mtime,
        "catalogado_em": datetime.now(timezone.utc).isoformat(),
    }
    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    tmp = target.with_suffix(".tmp")
    tmp.write_text(json.dumps(record, ensure_ascii=False))
    tmp.replace(target)
    return True


def cmd_sync(args):
    if args.hook:
        try:
            payload = json.load(sys.stdin)
        except json.JSONDecodeError:
            return
        path = payload.get("transcript_path")
        if path and Path(path).is_file():
            sync_file(Path(path))
        return
    files = [f for f in PROJECTS_DIR.glob("*/*.jsonl")]
    changed = sum(sync_file(f, force=args.force) for f in files)
    total = len(list(SESSIONS_DIR.glob("*.json")))
    print(f"{changed} sessão(ões) catalogada(s) agora; {total} no catálogo ({SESSIONS_DIR}).")


def load_clients():
    try:
        rules = json.loads(CLIENTS_FILE.read_text()).get("regras", [])
    except (OSError, json.JSONDecodeError):
        rules = []
    return [(re.compile(r["padrao"], re.I), r["cliente"]) for r in rules]


def client_of(record, rules) -> str:
    haystack = " ".join(filter(None, [record.get("cwd"), record.get("repo"), record.get("branch")]))
    for pattern, client in rules:
        if pattern.search(haystack):
            return client
    return "não classificado"


def human_seconds(turn) -> int:
    if not turn.get("humano", True):
        return 0
    wait = turn.get("espera_s", 0)
    return wait if wait <= TETO_ESPERA_S else 0


def fmt(seconds: float) -> str:
    minutes = round(seconds / 60)
    return f"{minutes // 60}h{minutes % 60:02d}"


def cmd_report(args):
    start = datetime.fromisoformat(args.de).date()
    end = datetime.fromisoformat(args.ate).date()
    rules = load_clients()
    rows = defaultdict(lambda: {"agente": 0, "humano": 0, "paralelo": 0, "turnos": 0, "saida": 0, "dias": set(), "titulo": None})
    for path in SESSIONS_DIR.glob("*.json"):
        record = json.loads(path.read_text())
        client = client_of(record, rules)
        if args.cliente and args.cliente.lower() not in client.lower():
            continue
        task = ", ".join(record.get("tasks") or []) or "-"
        key = (client, task, record["repo"], record["sessao"])
        for turn in record["turnos"]:
            day = datetime.fromisoformat(turn["inicio"]).astimezone(TZ).date()
            if start <= day <= end:
                row = rows[key]
                row["agente"] += turn["agente_s"]
                row["humano"] += human_seconds(turn)
                row["turnos"] += 1
                row["dias"].add(day.isoformat())
                row["titulo"] = record.get("titulo")
        for sub in record.get("subagentes", []):
            day = datetime.fromisoformat(sub["inicio"]).astimezone(TZ).date()
            if start <= day <= end:
                rows[key]["paralelo"] += sub["agente_s"]
                rows[key]["titulo"] = record.get("titulo")
                rows[key]["dias"].add(day.isoformat())
        if key in rows:
            rows[key]["saida"] += sum(t.get("output_tokens", 0) for t in record.get("tokens", {}).values())

    ordered = sorted(rows.items(), key=lambda kv: (kv[0][0], -(kv[1]["agente"] + kv[1]["humano"])))
    if args.csv:
        out = csv.writer(sys.stdout)
        out.writerow(["cliente", "task", "repo", "sessao", "titulo", "dias", "turnos",
                      "horas_agente", "horas_suas", "horas_subagentes", "tokens_saida"])
        for (client, task, repo, session), r in ordered:
            out.writerow([client, task, repo, session, r["titulo"] or "", " ".join(sorted(r["dias"])), r["turnos"],
                          round(r["agente"] / 3600, 2), round(r["humano"] / 3600, 2),
                          round(r["paralelo"] / 3600, 2), r["saida"]])
        return

    print(f"# Horas por cliente — {start} a {end} (America/Sao_Paulo)\n")
    print(f"Regra: agente = eventos do turno com pausas > {PAUSA_AGENTE_S // 60} min descartadas; "
          f"suas = espera antes de cada pedido, até {TETO_ESPERA_S // 60} min; "
          f"subagentes = soma em paralelo, fora do total.\n")
    by_client = defaultdict(list)
    for key, r in ordered:
        by_client[key[0]].append((key, r))
    for client, items in by_client.items():
        agent = sum(r["agente"] for _, r in items)
        human = sum(r["humano"] for _, r in items)
        print(f"## {client} — total {fmt(agent + human)} (agente {fmt(agent)} · suas {fmt(human)})\n")
        print("| Task | Sessão | Repo | Dias | Agente | Suas | Subagentes |")
        print("|---|---|---|---|---|---|---|")
        for (client, task, repo, session), r in items:
            days = sorted(r["dias"])
            span = days[0][5:] if len(days) == 1 else f"{days[0][5:]}→{days[-1][5:]} ({len(days)})"
            title = (r["titulo"] or session[:8]).replace("|", "/")
            print(f"| {task} | «{title}» `{session[:8]}` | {repo} | {span} | {fmt(r['agente'])} | "
                  f"{fmt(r['humano'])} | {fmt(r['paralelo'])} |")
        print()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    sync = sub.add_parser("sync", help="cataloga transcrições novas ou alteradas")
    sync.add_argument("--hook", action="store_true", help="lê transcript_path do JSON do hook no stdin")
    sync.add_argument("--force", action="store_true", help="recataloga tudo")
    report = sub.add_parser("relatorio", help="horas por cliente, task e sessão")
    today = datetime.now(TZ).date()
    report.add_argument("--de", default=today.replace(day=1).isoformat())
    report.add_argument("--ate", default=today.isoformat())
    report.add_argument("--cliente")
    report.add_argument("--csv", action="store_true")
    args = parser.parse_args()
    cmd_sync(args) if args.cmd == "sync" else cmd_report(args)


if __name__ == "__main__":
    main()
