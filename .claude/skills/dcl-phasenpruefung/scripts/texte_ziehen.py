"""Zieht die sichtbaren Texte aus Godot-Dateien für den Text-Prüfer, je mit Datei und Zeile.

Aufruf vom Repo-Ordner aus, je Gruppe „Name=Ordner,Ordner“ relativ zu src/:
  python3 -I .claude/skills/dcl-phasenpruefung/scripts/texte_ziehen.py src \
      "Spiel=scenes/title" "Werkstatt=tools/werkstatt" > liste.txt

Gelesen werden .gd und .tscn. Aus .tscn kommen Felder wie text, tooltip_text und hint, aus .gd
alle Zeichenketten mit Buchstaben, ohne Kommentare, Fehlerausgaben und Bezeichner. Die Liste ist
grob: Technische Namen wie Theme-Varianten bleiben drin, das sagt der Auftrag an den Prüfer.
"""
import re, sys, pathlib
root = pathlib.Path(sys.argv[1])
gruppen = {}
for arg in sys.argv[2:]:
    name, _, ordner = arg.partition("=")
    gruppen[name] = [o for o in ordner.split(",") if o]
if not gruppen:
    sys.exit("Aufruf: texte_ziehen.py src \"Name=ordner,ordner\" …")
lit = re.compile(r'"((?:[^"\\]|\\.)*)"')
tscn_key = re.compile(r'^(text|tooltip_text|placeholder_text|title|dialog_text|label|hint|ok_button_text|cancel_button_text) = "((?:[^"\\]|\\.)*)"')
def sichtbar(s):
    if not re.search(r"[A-Za-zÄÖÜäöüß]", s): return False
    if s.startswith(("res://", "user://", "uid://")): return False
    if re.fullmatch(r"[a-z0-9_./:%\-]+", s): return False   # Bezeichner, Pfade, Schlüssel
    if re.fullmatch(r"[A-Z0-9_]+", s): return False
    if re.fullmatch(r"%[-0-9.]*[sdf]", s): return False
    return True
for name, ordner in gruppen.items():
    print(f"\n## {name}\n")
    for o in ordner:
        for p in sorted((root / o).glob("*")):
            if p.suffix not in (".gd", ".tscn"): continue
            for n, zeile in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
                z = zeile.strip()
                if p.suffix == ".tscn":
                    m = tscn_key.match(z)
                    if m and sichtbar(m.group(2)):
                        print(f"{p.relative_to(root)}:{n}: {m.group(1)} = \"{m.group(2)}\"")
                    continue
                if z.startswith("#") or z.startswith("##"): continue
                code = zeile.split(" #")[0] if '"' not in zeile.split(" #")[-1] else zeile
                if "push_error" in code or "push_warning" in code or "print(" in code or "assert(" in code: continue
                if "get_node" in code or "has_method" in code or "connect(" in code: continue
                for m in lit.finditer(code):
                    if sichtbar(m.group(1)):
                        print(f"{p.relative_to(root)}:{n}: \"{m.group(1)}\"")
