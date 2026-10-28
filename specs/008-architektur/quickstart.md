# Quickstart: Prüfanleitung für Feature 008

Wie Klaus und Claude prüfen, dass 008 tut, was die Spec verlangt. Befehle vom Repo-Ordner aus.
Einzelheiten stehen in den Verträgen; hier nur die Prüfungen.

## Phase 1: Leitfaden

1. `docs/architektur-leitfaden.md` öffnen.
2. Jede Regel hat alle acht Teile (Vertrag [leitfaden.md](contracts/leitfaden.md)), keine steht
   mehr auf „Vorschlag“ (SC-001). Claude zählt nach:

   ```bash
   grep -c "^### AR-" docs/architektur-leitfaden.md
   ```

   ```bash
   grep -c "Stand:\*\* Vorschlag" docs/architektur-leitfaden.md
   ```

   Die zweite Zahl muss 0 sein.
3. Stichprobe: eine Stelle aus `src/` aussuchen und nur mit dem Leitfaden sagen, ob sie eine Regel
   verletzt (Spec, US1).

## Phase 2: Prüfer und Fehlerprobe

1. `.claude/agents/architektur-pruefer.md` hat nur `Read, Grep, Glob` (FR-010).
2. Fehlerprobe: Claude gibt dem Prüfer `specs/008-architektur/fehlerprobe/` ohne `LOESUNG.md`.
   Erwartet: fünf Befunde, je einer zu AR-01 bis AR-05, und keiner an den erlaubten Stellen (SC-002).
   Claude vergleicht mit `LOESUNG.md` und trägt das Ergebnis in `ki_pruefung.md` ein.
3. Verfassung: Version 2.3.0, Grundsatz VI nennt Code-Phasen und den Leitfaden.
4. Die Vorlage `overrides/tasks-template.md` und der Skill `dcl-phasenpruefung` nennen Code als
   Auslöser (FR-021).

## Phase 3: Bestandsprüfung

1. `specs/008-architektur/bestandsbericht.md` nennt jede Datei (SC-003). Claude vergleicht:

   ```bash
   find src/core src/scenes src/ui src/tools -name "*.gd" -o -name "*.tscn" | sort
   ```

2. Jede Abweichung hat Claudes Urteil und Klaus' Entscheidung.
3. Große Behebungen stehen als Eintrag in `docs/features/Feature_Ideas.md`.

## Phase 4: Tests

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Zweimal, gleiche Zahl an Prüfungen, alles grün. In der Lernnotiz steht die Fehlerprobe je
Prüffunktion.

## Phase 5: Behebung

Vor der Phase hält Claude fest, nach der Phase vergleicht Claude:

```bash
for s in 1 4711 99999; do /Applications/Godot.app/Contents/MacOS/Godot --headless --no-header --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed $s > /tmp/fahrplan_$s.txt; done
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -d --quit-after 60
```

- Fahrpläne bytegleich mit vorher (`cmp`), Startprobe Exit 0 und still, Tests zweimal grün,
  `BIS_BEHEBUNG` leer (SC-004).
- Der Prüfer meldet an den behobenen Stellen nichts mehr.
- Von Hand, Klaus: das Spiel starten, einen Spielstand von vor der Phase fortsetzen, ein neues Spiel
  beginnen, die drei grauen Knöpfe drücken, die Werkstatt öffnen und einen Lauf simulieren. Alles
  wie vorher.

  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --path src
  ```

  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --path src res://tools/werkstatt/werkstatt.tscn
  ```

## Danach

Im ersten Feature nach 008 mit Code stehen in `plan.md` unter „Prüfer je Phase“ und in `tasks.md`
der Architektur-Prüfer, ohne dass jemand daran erinnert (SC-006).
