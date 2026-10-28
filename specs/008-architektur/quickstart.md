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

   Die zweite Zahl muss 0 sein. Dazu zählt ein kurzes Skript je `### AR-` die acht fett gesetzten
   Teile; die Zahl steht in der Bitte um Abnahme (CHK017).
3. Stichprobe: eine Stelle aus `src/` aussuchen und nur mit dem Leitfaden sagen, ob sie eine Regel
   verletzt (Spec, US1).

## Phase 2: Prüfer und Fehlerprobe

1. `.claude/agents/architektur-pruefer.md` hat nur `Read, Grep, Glob` (FR-010).
2. Fehlerprobe: Claude gibt dem Prüfer `specs/008-architektur/fehlerprobe/` ohne `LOESUNG.md`.
   Erwartet: fünf Befunde, je einer zu AR-01 bis AR-05, und keiner an den erlaubten Stellen (SC-002).
   Claude vergleicht mit `LOESUNG.md` und trägt das Ergebnis in `ki_pruefung.md` ein. Besteht er
   nicht: Anweisung nachschärfen, höchstens zweimal wiederholen, dann entscheidet Klaus.
3. Planprobe: Plan, research.md, Datenmodell und Verträge von 006 als Auftrag „Plan“. Erwartet: ein
   Bericht in der Form des Vertrags, jeder Ort ein Abschnitt (Spec, US3).
4. Verfassung: Version 2.3.0, Grundsatz VI nennt Code-Phasen und den Leitfaden.
5. Die Vorlage `overrides/tasks-template.md` und der Skill `dcl-phasenpruefung` nennen Code als
   Auslöser (FR-021).

## Phase 3: Bestandsprüfung

0. Vorher: Ist 007 gemergt, ist `main` mit Klaus' OK im Branch; sonst sagt der Bericht, dass 007
   fehlt.
1. `specs/008-architektur/bestandsbericht.md` nennt jede Datei (SC-003). Claude vergleicht:

   ```bash
   find src/core src/scenes src/ui src/tools src/project.godot src/*.tres \( -name "*.gd" -o -name "*.tscn" -o -name "*.tres" -o -name "project.godot" \) | sort
   ```

2. Jede Abweichung hat Claudes Urteil und Klaus' Entscheidung.
3. Große Behebungen stehen als Eintrag in `docs/features/Feature_Ideas.md`.

## Phase 4: Tests

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Zweimal, gleiche Zahl an Prüfungen, alles grün. In der Lernnotiz steht die Fehlerprobe je
Prüffunktion. Phasenprüfung nur mit dem Text-Prüfer über die Testmeldungen; Tests lösen den
Architektur-Prüfer nicht aus (FR-016).

## Phase 5: Behebung

Die Phase beginnt erst, wenn 007 gemergt und `main` im Branch ist. Vor der Phase hält Claude fest
und sichert zwei Spielstände (Mittel, Seed 4711, 1987; Schwer mit einem Eingriff, 1993); nach der
Phase vergleicht Claude:

```bash
for s in 1 4711 99999; do /Applications/Godot.app/Contents/MacOS/Godot --headless --no-header --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed $s > /tmp/fahrplan_$s.txt; done
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -d --quit-after 60
```

- Fahrpläne bytegleich mit vorher (`cmp`), Startprobe Exit 0 und still, Tests zweimal grün,
  `BIS_BEHEBUNG` leer (SC-004).
- Der Prüfer meldet an den behobenen Stellen nichts mehr.
- Beide gesicherten Spielstände laden mit einem kurzen Skript wie vorher.
- Von Hand, Klaus: das Spiel starten, einen der beiden Spielstände fortsetzen, ein neues Spiel
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
