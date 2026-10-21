# Quickstart: Start bis zum Hauptmenü prüfen

So lässt sich nachweisen, dass das Feature fertig ist. Was gebaut wird, steht im
[Vertrag](contracts/titelbildschirm.md); hier steht nur, wie man es prüft. Alle Befehle laufen vom
Repo-Root aus, Godot liegt unter `/Applications/Godot.app/Contents/MacOS/Godot`.

## Voraussetzungen

- Godot 4.7.2 mit installierten Export-Vorlagen 4.7.2 („Editor → Export-Vorlagen verwalten“).
- Schriften, Titelbild, Logo und App-Symbol liegen unter `src/assets/` (siehe Vertrag).
- Das Export-Preset „macOS“ ist angelegt, die Bundle-ID ist gesetzt.

## 1. Automatische Tests

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Erwartet: alle Tests grün. GDScript-Warnungen zeigt Godot headless nur mit `-d` hinter dem
Programmnamen; ohne `-d` belegt eine Ausgabe ohne Warnungen nichts.

## 2. Startprobe ohne Fenster

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --quit-after 60
```

Erwartet: Die Hauptszene startet und endet mit Exit-Code 0, ohne Fehler oder Warnungen in der
Ausgabe. Für die Warnungen dasselbe noch einmal mit `-d`:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless -d --path src --quit-after 60
```

## 3. Im Editor

Projekt im Godot-Editor starten (F5).

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Startbild | kein Godot-Logo, nur dunkler Grund | FR-003 |
| Titelbildschirm | Titelbild, Logo mit Untertitel, Menü auf Endlospapier, „V0.1 · PROTOTYP“ | FR-005, FR-014 |
| Vorauswahl | „Neues Spiel“ ist gewählt, Enter und Leertaste bewirken nichts | FR-010, US4 |
| Pfeiltasten, Tab | jede Zeile erreichbar, Umlauf an beiden Enden; Tab wie Pfeil runter, Shift+Tab wie Pfeil hoch | FR-010 |
| Hinweis | erscheint sofort links neben der gewählten Zeile, Texte wie in FR-016, bleibt stehen, wenn die Maus das Menü verlässt | FR-016, FR-017 |
| Maus | Überfahren wählt die Zeile; nie zwei Zeilen hervorgehoben; Kopfzeile und Lochränder ändern nichts | FR-009, FR-011 |
| Mauszeiger | Hand nur über „Beenden“, sonst Pfeil | FR-018 |
| Rechtsklick | wählt die Zeile und zeigt den Hinweis, löst nichts aus | FR-009 |
| Esc | löst nichts aus | Edge Cases |
| „Beenden“ | per Klick, Enter und Leertaste: Spiel schließt sofort (per Tastatur: Pfeil hoch, dann Enter oder Leertaste) | FR-008, FR-010 |

## 4. Mac-App bauen

Über den Export-Dialog oder auf der Kommandozeile (der Pfad gilt relativ zu `src/`):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --export-release "macOS" "../build/macos/Der Computerladen.app"
```

Danach `src/export_presets.cfg` ansehen: Es dürfen keine Passwörter oder Schlüssel darin stehen.
In einem frisch geklonten Stand ohne `src/.godot/` meldet der erste `--import` einige Male
„Cannot open file … .fontdata“, weil das Theme vor den Schriften geladen wird; der zweite Lauf
ist sauber.
Vertrauliches legt Godot in `src/.godot/export_credentials.cfg` ab, das nicht versioniert wird.

## 5. Mac-App prüfen

Den Godot-Editor schließen, dann die App im Finder doppelklicken oder:

```bash
open "build/macos/Der Computerladen.app"
```

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Start | ohne Editor, ohne Warnung von macOS | FR-001, SC-002 |
| Zeit bis zum Titel | höchstens 3 Sekunden vom Doppelklick bis zur ersten Reaktion des Menüs; Stoppuhr, schlechtester von drei Starts, ohne den ersten nach dem Export | SC-001 |
| Dock und App-Umschalter | „Der Computerladen“ mit dem Monitor auf `nacht` als Symbol, kein grauer Rahmen; in der Listenansicht des Finders als Monitor erkennbar | FR-002 |
| Informationen im Finder | Version 0.1, dieselbe wie in der Versionszeile | FR-014 |
| Start im Fenster | das Fenster hat den größten Faktor, der samt Titelleiste auf den Bildschirm passt, und steht mittig | FR-004 |
| Ctrl+Cmd+F | wechselt ins Vollbild, ganzzahlig skaliert, Rest schwarz, und zurück ins Fenster mit dem größten Faktor | FR-004, FR-012 |
| Grüner Knopf | wechselt ebenso ins Vollbild und zurück | FR-004 |
| Fenster verkleinern | geht nicht unter 640 × 360; Darstellung bleibt ganzzahlig mit Rand | FR-012, FR-013 |
| Cmd+Q, Fenster schließen | beendet die App wie „Beenden“ | FR-008 |
| Zweiter Doppelklick | holt die laufende App nach vorn | Edge Cases |
| Schärfe | Bildschirmfoto in Originalgröße (Cmd+Shift+3): jeder Rasterpixel ist ein Block gleichfarbiger Bildschirmpixel, Schrift ohne Zwischentöne | SC-004 |
| Kameraaussparung | auf einem MacBook mit Aussparung liegt das ganze Bild darunter, nichts ist verdeckt | Edge Cases |
| Seitenvergleich | Bildschirmfoto neben dem [Titelscreen-Entwurf](https://claude.ai/artifact/RHKxpTb6JfWFQdNnPYEWHH): Farben und Schriften genau, Lage und Größen auf 2 Oberflächenpixel, nur das Logo darf kleiner sein | SC-006 |
| Bildfreigabe | Klaus gibt gerastertes Titelbild, Logo und App-Symbol frei | SC-007 |

Falls ein externer Bildschirm mit 1080p, 1440p oder 4K zur Hand ist: dort im Vollbild prüfen,
dass das Bild ohne Rand füllt (SC-004), und das Fenster auf diesen Bildschirm ziehen: Beim
Wechsel ins Fenster richtet sich der Faktor nach ihm (FR-004). Fällt der Faktor im Vollbild um
eins zu klein aus, siehe research.md, R2.

Fehlt Cmd+Q im App-Menü, siehe research.md, R11. Fängt macOS Ctrl+Cmd+F selbst ab, ist das in
Ordnung, solange der Wechsel genau einmal passiert.
