# Töne

Ein Werkzeug, das alle Töne des Spiels erzeugt: kurze Piepser in Rechteckwelle und Rauschen, wie
ein Taschengerät von 1991. Nur Python 3 mit Standardbibliothek; Aufruf vom Repo-Root mit
`python3 -I`.

```bash
python3 -I tools/ton/make_sounds.py
```

Das Skript schreibt die zehn Dateien nach `src/assets/sounds/`, WAV, 22 050 Hz, 16 Bit, mono, und
gibt je Datei Länge und Größe aus. Jeder Lauf schreibt dieselben Bytes: Das Rauschen kommt aus
einem festen Seed je Datei.

| Datei | Wofür |
|---|---|
| `knopf.wav` | Gehäusetaste des Communicators gedrückt |
| `schuss.wav`, `treffer.wav`, `kanone.wav` | Schuss, Außerirdischer getroffen, Kanone getroffen |
| `marsch_1.wav` bis `marsch_4.wav` | Takt des Blocks im Spiel auf der Anzeige |
| `sieg.wav`, `niederlage.wav` | Ende des Spiels |

## Ändern

Klang, Tonhöhen, Längen und Pegel regelt der Style-Guide, Abschnitt „Ton“. Wer einen Ton ändern
will, ändert erst dort, dann die Tabelle `TOENE` im Skript, und schreibt danach die Prüfsummen neu:

```bash
python3 -I tools/ton/make_sounds.py --pruefsummen
```

Die Prüfsummen stehen in `src/test/fixtures/ton_pruefsummen.txt`; `src/test/test_ton.gd` vergleicht
die Dateien im Projekt damit. Godot importiert die Dateien ohne Kompression (PCM), ohne Trimmen,
Normalisieren und Schleife; das steht in der `.import` jeder Datei.

## Anhören

```bash
for f in src/assets/sounds/*.wav; do echo "$f"; afplay "$f"; done
```
