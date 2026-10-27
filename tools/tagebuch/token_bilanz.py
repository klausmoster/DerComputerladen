"""Zählt Token und geschätzte Kosten je Branch aus den Sitzungsprotokollen von Claude Code.

Liest alle Protokolle unter ~/.claude/projects/ zu diesem Repo, auch die der Worktrees und der
Sub-Agents, und ordnet jede Antwort dem Branch zu, auf dem ihre Sitzung lief. Gezählt wird jede
Antwort nur einmal, auch wenn sie im Protokoll über mehrere Zeilen verteilt ist. Die Kosten sind
eine Schätzung nach API-Listenpreis; bei einem Abo zahlt man anders.

Claude Code löscht Protokolle nach 30 Tagen. Die Zahlen gehören deshalb beim Merge ins Tagebuch.

Aufruf vom Repo-Root:
  python3 -I tools/tagebuch/token_bilanz.py                       # alle Branches als Tabelle
  python3 -I tools/tagebuch/token_bilanz.py feature/004-neues-spiel  # Zeile fürs Tagebuch
"""
import argparse
import collections
import glob
import json
import os

PROJEKTE = os.path.expanduser("~/.claude/projects")
MUSTER = "*DerComputerladen*"

# Dollar je Million Token, API-Listenpreis, Stand 2026-10-06.
# Cache-Schreiben kostet 1,25 × Input bei 5 Minuten Lebensdauer und 2 × Input bei einer Stunde.
PREISE = {
    "claude-opus-5-5": {"input": 4.00, "output": 20.00, "cw_5m": 5.00, "cw_1h": 8.00, "cr": 0.20},
    "claude-haiku-5-5": {"input": 0.10, "output": 0.50, "cw_5m": 0.125, "cw_1h": 0.20, "cr": 0.01},
}
FELDER = ("input", "output", "cw_5m", "cw_1h", "cr")


def lies_protokolle():
    """Liefert je Branch die Summen, die Tage und die Modelle ohne Preis."""
    summen = collections.defaultdict(collections.Counter)
    tage = collections.defaultdict(set)
    ohne_preis = collections.Counter()
    gesehen = set()
    dateien = glob.glob(os.path.join(PROJEKTE, MUSTER, "**", "*.jsonl"), recursive=True)
    for datei in dateien:
        sub_agent = os.sep + "subagents" + os.sep in datei
        with open(datei, encoding="utf-8", errors="replace") as f:
            for zeile in f:
                try:
                    eintrag = json.loads(zeile)
                except json.JSONDecodeError:
                    continue
                nachricht = eintrag.get("message")
                if not isinstance(nachricht, dict) or "usage" not in nachricht:
                    continue
                schluessel = (nachricht.get("id"), eintrag.get("requestId"))
                if schluessel in gesehen:
                    continue
                gesehen.add(schluessel)
                modell = nachricht.get("model")
                if modell == "<synthetic>":
                    continue
                branch = eintrag.get("gitBranch") or "?"
                u = nachricht["usage"]
                cache = u.get("cache_creation") or {}
                cw = u.get("cache_creation_input_tokens") or 0
                cw_1h = cache.get("ephemeral_1h_input_tokens") or 0
                werte = {
                    "input": u.get("input_tokens") or 0,
                    "output": u.get("output_tokens") or 0,
                    "cw_5m": cw - cw_1h,
                    "cw_1h": cw_1h,
                    "cr": u.get("cache_read_input_tokens") or 0,
                }
                s = summen[branch]
                for feld in FELDER:
                    s[feld] += werte[feld]
                preis = PREISE.get(modell)
                if preis is None:
                    ohne_preis[modell] += 1
                else:
                    s["kosten"] += sum(werte[f] * preis[f] for f in FELDER) / 1e6
                s["sub_agents" if sub_agent else "claude"] += 1
                tag = (eintrag.get("timestamp") or "")[:10]
                if tag:
                    tage[branch].add(tag)
    return summen, tage, ohne_preis


def mio(n):
    return f"{n / 1e6:,.1f} M"


def zeitraum(tage):
    t = sorted(tage)
    if not t:
        return "?"
    return t[0] if t[0] == t[-1] else f"{t[0]} to {t[-1]}"


def tagebuchzeile(branch, s, tage):
    cw = s["cw_5m"] + s["cw_1h"]
    return (
        f"- **Tokens and cost:** {zeitraum(tage)} on `{branch}`: {mio(s['output'])} output, "
        f"{s['input']:,} input, {mio(cw)} cache write, {mio(s['cr'])} cache read; "
        f"{s['claude']:,} responses from Claude, {s['sub_agents']:,} from sub-agents; "
        f"about ${s['kosten']:,.0f} at API list price."
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("branches", nargs="*", help="nur diese Branches, als Zeile fürs Tagebuch")
    args = parser.parse_args()
    summen, tage, ohne_preis = lies_protokolle()
    if args.branches:
        for branch in args.branches:
            if branch not in summen:
                print(f"{branch}: keine Protokolle gefunden")
                continue
            print(tagebuchzeile(branch, summen[branch], tage[branch]))
    else:
        print("| Branch | Zeitraum | Output | Input | Cache-Schreiben | Cache-Lesen | Antworten | Kosten |")
        print("|---|---|---:|---:|---:|---:|---:|---:|")
        for branch, s in sorted(summen.items()):
            print(
                f"| {branch} | {zeitraum(tage[branch])} | {mio(s['output'])} | {s['input']:,} | "
                f"{mio(s['cw_5m'] + s['cw_1h'])} | {mio(s['cr'])} | "
                f"{s['claude']:,} / {s['sub_agents']:,} | ${s['kosten']:,.0f} |"
            )
    for modell, anzahl in ohne_preis.items():
        print(f"Hinweis: {anzahl} Antworten von {modell} ohne Preis, nicht in den Kosten.")


if __name__ == "__main__":
    main()
