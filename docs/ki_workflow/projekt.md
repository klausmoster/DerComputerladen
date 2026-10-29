# Projektsteckbrief: Der Computerladen

**Konzept, 2026-10-29.** Die Werte, mit denen die [Blaupause](blaupause.md) in diesem Projekt gilt.
Die Felder folgen Anhang A der Blaupause. Verbindlich bleiben `CLAUDE.md` und die Verfassung; was
dort steht, wird hier nur verwiesen, nicht abgeschrieben.

## Projekt

| Feld | Wert |
|---|---|
| Projekt | „Der Computerladen“: Wirtschaftssimulation und Point-and-Click-Adventure, Deutschland 1985–1999 |
| Entscheider | Klaus, Kürzel `[K]` |
| Bau-Agent | `godot-entwickler` (`.claude/agents/godot-entwickler.md`), Modell Opus |
| Sprache | Deutsch für Doku, Specs und Gespräch; Tagebuch auf Englisch, übersetzt wird später |
| Eingedeutschte Fachwörter | bleiben, wie sie sind: „scrollen“, nicht „rollen“ |
| Anrede, Ton | Spiel und Werkzeuge duzen; trocken-ironisch, Vorbild „Das Amt“; Regeln im Style-Guide, Abschnitt „Sprache“ |
| Rahmenbedingungen | nur Desktop (Windows, macOS, Linux), Renderer Compatibility; Einzelheiten in `CLAUDE.md` und Verfassung I |

## Stack und Befehle

| Feld | Wert |
|---|---|
| Engine | Godot 4.7.2 stable, nicht .NET, unter `/Applications/Godot.app/Contents/MacOS/Godot` |
| Sprache | GDScript |
| Tests | GUT 9.7.1, headless |
| Spec Kit | 1.2.3 |
| Projekt-Root | `src/`, deshalb immer `--path src` |
| Spiel | `/Applications/Godot.app/Contents/MacOS/Godot --path src` |
| Tests | `/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd` |
| Startprobe | headless mit `-d`: Exit 0 und keine Ausgabe |
| Build | `tools/build/baue_alles.sh` |
| Fenstergröße | 1920 × 925 logisch, Klaus' Bildschirm |
| Gefährliche Dateien | `export_presets.cfg` vor jedem Commit ansehen |
| Prozesse | Claude darf mit `kill` beenden, etwa ein hängendes Godot (`Bash(kill *)` in Klaus' Einstellungen) |

## Ordner

| Platzhalter | Hier |
|---|---|
| `<Vision>` | `docs/game_design.md` |
| `<Stand-im-Code>` | `docs/spielbeschreibung/`, Index `README.md` |
| `<Maßstäbe>` | `docs/style-guide/` (mit „Sprache“ und „Werkzeuge“), `docs/architektur-leitfaden.md` (Regeln `AR-NN`) |
| `<Backlog>` | `docs/features/Feature_Ideas.md` (IDs `SS-NN` reserviert); Systemliste in `docs/features/Features.md` |
| Inhaltsdaten | `docs/game_bible/` |
| Code | `src/` |
| Werkzeuge | `tools/`, Werkzeuge im Spielprojekt unter `src/tools/` |
| Erfahrungen | `docs/ki_workflow/ki_dev.md`, `ki_pruefung.md`; Fahrplan `feature_fahrplan.md` |
| Präfix | `dcl-` |

## Prüfer

| Prüfer | Maßstab | Auslöser |
|---|---|---|
| Stil (`stil-pruefer`) | Style-Guide | Phase ändert Sichtbares, auch in Werkzeugen |
| Text (`text-pruefer`) | Style-Guide, „Sprache“ | Phase ändert Texte |
| Architektur (`architektur-pruefer`) | Architektur-Leitfaden | Phase ändert Skripte, Szenen oder Resources unter `src/` außer Tests; ob er bleibt, entscheidet Klaus nach den Code-Phasen des nächsten Features |
| Fakten | game_bible und Quellen | später, wenn Katalog und game_bible wachsen |

- **Bestandsprüfung:** wenn eine neue Schicht beginnt, etwa Wirtschaft oder Adventure, und jedes
  fünfte Feature nach 008: 013, 018, … (Klaus, 2026-10-29).
- **Skill:** `dcl-phasenpruefung`, mit `scripts/fotos.gd` (Bildschirmfotos aus Godot) und
  `scripts/texte_ziehen.py` (sichtbare Texte mit Datei und Zeile).
- **Tests aus Prüferbefunden:** `src/test/test_bilder.gd`, `src/test/test_texte.gd`.

## Module

| Modul | Gilt | Hier |
|---|---|---|
| Lernnotizen | ja | Klaus lernt Godot; `specs/NNN/lernnotizen.md`, `[K]`-Aufgaben nach Wahl |
| Stack-Referenz | ja | `tools/godot_referenz/erzeuge.sh --texte --handbuch` schreibt nach `godot_referenz/` (nicht im Repo), in jedem Worktree einmal; Cache `~/.cache/der-computerladen/`; eine neue Godot-Version lädt neu, nur mit Klaus' Erlaubnis |
| Selbsttest | ja | `src/tools/selbsttest/`, Vergleich mit `tools/selbsttest/vergleich.py`; auf dem Mac bei jedem Feature, auf Windows und Linux startet Klaus ihn bei Änderungen an Fenster, Eingabe, Grafik, Dateien oder Export, sonst spätestens jedes dritte Feature |
| Grafik-Pipeline | ja | Skill `dcl-grafik`: Claude erzeugt in Leonardo.ai über Claude in Chrome, Klaus wählt aus; Stilanker C2, Prompt-Log `docs/art/leonardo/prompt-log.md`, Bildkatalog `docs/art/bildkatalog.md`; Chrome startet nur mit eigenem Profilordner (`ki_dev.md`, „Grafik“) |
| Inhaltsdaten | ja | `docs/game_bible/` mit Konventionen aus `CLAUDE.md`; Skill `dcl-komponente` |

## Abweichungen von der Blaupause

| Was | Abweichung | Grund |
|---|---|---|
| Ereigniskatalog | Ereignisse liegen in `src/data/event_catalog.json` und werden in der Zeitleisten-Werkstatt gepflegt, nicht in den Inhaltsdaten | Die Werkstatt muss den Katalog lesen und schreiben; Ereignisse brauchen Tagesdaten (Verfassung V) |
| Selbstständig befüllt | `docs/game_bible/` und die Skills darf Claude ohne Freigabe befüllen | `CLAUDE.md` |
| Hooks | vorerst keiner | Klaus: Tests startet Claude selbst, ein Hook kommt erst bei Bedarf (`ki_pruefung.md`, „Bausteine“) |
| Sitzungen | Werkzeuge außerhalb von Features (Arbeitsweise, Style-Guide) laufen in eigenen Sitzungen auf eigenen Branches `claude/…` | kein Feature, keine Nummer; bisher so gehandhabt, noch nicht beschlossen |
