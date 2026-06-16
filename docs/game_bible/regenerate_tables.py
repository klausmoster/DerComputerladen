#!/usr/bin/env python3
"""
Generiert Markdown-Tabellen aus YAML-Frontmatter.

VOLLSTANDIG GENERISCH (kein Spezialwissen über Felder/Kategorien):
- Flache Properties tragen ihre Kategorie als Präfix im Key: alles vor dem
  ersten '_' ist die Kategorie, der Rest der Feldname.
  Beispiel: technik_cache_l1 -> Kategorie "Technik", Feld "Cache L1".
  Gleiche Präfixe werden zu einer 2-Spalten-Tabelle "## Kategorie" gebündelt.
- List-Blöcke (Zeitreihen/Relationen) werden zu Tabellen (Keys = Spalten).
- Titel kommt aus dem Dateinamen.
- String-Listen (z.B. tags) und Keys ohne '_' werden entsprechend behandelt.

GESCHÜTZTE ABSCHNITTE:
- '##'-Überschriften, deren Titel mit SCHUTZ_MARKER ('+') beginnt, werden NICHT
  neu erzeugt, sondern aus der bestehenden Datei verbatim übernommen. Hier lebt
  Zusatzwissen (z.B. von einer KI recherchierte Fakten), das mehrere Läufe
  übersteht, ohne dass es dupliziert oder überschrieben wird.
- Alle anderen '##'-Abschnitte werden bei jedem Lauf aus dem Frontmatter erzeugt.
- Dateien, deren Name mit 'TEMPLATE' beginnt, werden übersprungen.

Verwendung:
  python3 regenerate_tables.py <pfad>
"""

import yaml
import os
import sys
import re

class OrderedDumper(yaml.SafeDumper):
    pass

def _dict_representer(dumper, data):
    return dumper.represent_mapping(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, data.items())

OrderedDumper.add_representer(dict, _dict_representer)

def parse_frontmatter(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    if not content.startswith('---'):
        return None, content
    parts = content.split('---', 2)
    if len(parts) < 3:
        return None, content
    data = yaml.safe_load(parts[1])
    return data, parts[2]

# Bekannte Abkürzungen, die nicht title-cased werden sollen (generisch, kein
# feldspezifisches Wissen – nur Schreibweisen). Key = kleingeschrieben.
ABKUERZUNGEN = {
    'cpu': 'CPU', 'fpu': 'FPU', 'gpu': 'GPU', 'apu': 'APU', 'tdp': 'TDP',
    'pc': 'PC', 'ram': 'RAM', 'rom': 'ROM', 'simm': 'SIMM', 'dimm': 'DIMM',
    'mhz': 'MHz', 'ghz': 'GHz', 'khz': 'kHz', 'hz': 'Hz',
    'kb': 'KB', 'mb': 'MB', 'gb': 'GB', 'tb': 'TB', 'bit': 'Bit',
    'l1': 'L1', 'l2': 'L2', 'l3': 'L3', 'vcore': 'VCore',
    'dm': 'DM', 'pga': 'PGA', 'lga': 'LGA', 'pqfp': 'PQFP', 'socket': 'Socket',
    'ia': 'IA', 'dx': 'DX', 'sx': 'SX', 'de': 'DE', 'usb': 'USB',
    'io': 'I/O', 'id': 'ID', 'os': 'OS', 'isa': 'ISA', 'pci': 'PCI', 'agp': 'AGP',
}

def pretty_label(key):
    """Formatiert einen YAML-Key zu einem hübschen Label: cache_l1 -> Cache L1,
    preise_cpu -> Preise CPU."""
    woerter = str(key).replace('_', ' ').split()
    return ' '.join(ABKUERZUNGEN.get(w.lower(), w.capitalize()) for w in woerter)

# H2-Überschriften, deren Titel hiermit beginnt, werden bei der Regenerierung
# erhalten statt überschrieben (KI-/Handwissen).
SCHUTZ_MARKER = '+'

def extrahiere_geschuetzte_abschnitte(body):
    """Alle H2-Abschnitte, deren Titel mit SCHUTZ_MARKER beginnt, verbatim
    (inkl. Überschrift) als Liste von Textblöcken."""
    geschuetzt = []
    aktuell = None
    for line in body.split('\n'):
        m = re.match(r'^##\s+(.*)$', line)
        if m:
            if aktuell is not None:
                geschuetzt.append(aktuell)
            aktuell = [line] if m.group(1).strip().startswith(SCHUTZ_MARKER) else None
        elif aktuell is not None:
            aktuell.append(line)
    if aktuell is not None:
        geschuetzt.append(aktuell)
    return ['\n'.join(block).rstrip() for block in geschuetzt]

def render_dict_as_table(data, titel):
    lines = [f"## {pretty_label(titel)}"]
    lines.append("| Eigenschaft | Wert |")
    lines.append("|---|---|")
    for key, val in data.items():
        lines.append(f"| {pretty_label(key)} | {val} |")
    lines.append("")
    return '\n'.join(lines)

def render_list_as_table(items, titel):
    if not items:
        return ""
    keys = list(items[0].keys())
    spalten = [pretty_label(k) for k in keys]
    lines = [f"## {pretty_label(titel)}"]
    lines.append("| " + " | ".join(spalten) + " |")
    lines.append("|" + "|".join(["---" for _ in spalten]) + "|")
    for row in items:
        zellen = [str(row.get(k, '')) for k in keys]
        lines.append("| " + " | ".join(zellen) + " |")
    lines.append("")
    return '\n'.join(lines)

def regenerate_file(filepath):
    if os.path.basename(filepath).startswith('TEMPLATE'):
        print(f"[SKIP] Template: {filepath}")
        return

    data, alter_body = parse_frontmatter(filepath)
    if not data:
        print(f"[WARN] Kein Frontmatter in {filepath}")
        return

    title = f"# {os.path.splitext(os.path.basename(filepath))[0]}\n\n"

    # Flache Skalare anhand ihres Präfixes (vor dem ersten '_') zu Kategorien
    # bündeln. Listen-Blöcke bleiben eigenständig. Das Skript kennt keine
    # Kategorienamen – es liest sie aus den Keys ab.
    kategorien = {}   # kategorie -> {feld: wert}  (Reihenfolge bleibt erhalten)
    listen = []       # [(name, items), ...]
    for key, block in data.items():
        if isinstance(block, list) and block and isinstance(block[0], dict):
            listen.append((key, block))
        elif isinstance(block, dict):
            kategorien.setdefault(key, {}).update(block)
        elif isinstance(block, (list, dict)):
            continue  # z.B. tags (String-Liste) -> nicht rendern
        else:
            kategorie, sep, feld = str(key).partition('_')
            if not sep:
                kategorie, feld = 'allgemein', key
            kategorien.setdefault(kategorie, {})[feld] = block

    body = ""
    for kategorie, felder in kategorien.items():
        body += render_dict_as_table(felder, kategorie)
    for name, items in listen:
        body += render_list_as_table(items, name)

    if not body:
        print(f"[WARN] Keine renderbaren Blöcke in {filepath}")
        return

    # Geschützte Abschnitte (## + …) aus der bestehenden Datei erhalten.
    geschuetzt = extrahiere_geschuetzte_abschnitte(alter_body or "")

    fm_str = '---\n' + yaml.dump(data, Dumper=OrderedDumper, allow_unicode=True, sort_keys=False) + '---\n'
    inhalt = fm_str + title + body
    if geschuetzt:
        inhalt = inhalt.rstrip() + '\n\n' + '\n\n'.join(geschuetzt) + '\n'
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(inhalt)

    erhalten = f" (+{len(geschuetzt)} geschützt)" if geschuetzt else ""
    print(f"[OK] {filepath}{erhalten}")

def main():
    if len(sys.argv) < 2:
        print("Verwendung: python3 regenerate_tables.py <pfad>")
        sys.exit(1)

    target = sys.argv[1]
    if os.path.isfile(target):
        files = [target] if target.endswith('.md') else []
    elif os.path.isdir(target):
        files = [os.path.join(target, f) for f in os.listdir(target) if f.endswith('.md')]
    else:
        print(f"Fehler: '{target}' existiert nicht oder ist ungültig.")
        sys.exit(1)

    if not files:
        print("Keine .md-Dateien gefunden.")
        return

    for f in files:
        regenerate_file(f)

    print(f"\nFertig! ({len(files)} Datei(en) verarbeitet)")

if __name__ == '__main__':
    main()
