# Vertrag: Arbeitsweise, Verfassung, Skill und Vorlagen

Was sich in Phase 2 außerhalb des Leitfadens ändert (research.md, R10). Schreibt Claude `[C]`; die
Verfassung beschließt Klaus `[K]`. FR-016 bis FR-024.

## Verfassung, Grundsatz VI (Vorschlag für `/speckit-constitution`)

Den Wortlaut beschließt Klaus. Vorschlag, Änderungen gegenüber 2.2.0 fett:

> - Ändert eine Phase Sichtbares oder Texte, auch in Werkzeugen, **oder Skripte, Szenen und
>   Resources unter `src/` außer Tests**, endet sie
>   vor Klaus' Abnahme mit einer Phasenprüfung. Stil- und Text-Prüfer prüfen nur lesend gegen den
>   Style-Guide, **der Architektur-Prüfer gegen den Architektur-Leitfaden
>   (`docs/architektur-leitfaden.md`)**; Claude prüft jeden ihrer Befunde nach.
> - In `tasks.md` steht die Phasenprüfung als `[C]`-Aufgabe. Welche Prüfer für welche Phase gelten,
>   legt `plan.md` unter „Prüfer je Phase“ fest.
> - Bei `/speckit-checklist` lesen die Prüfer die Wortlaute und Zustände aus Spec und Vertrag, **der
>   Architektur-Prüfer Plan und Vertrag**, bevor gebaut wird.
> - **Ein Plan, der vom Leitfaden abweicht, nennt die Abweichung unter „Ausnahmen vom Leitfaden“;
>   Klaus gibt sie mit dem Plan frei.**
> - Was sich messen lässt, prüfen Tests, nicht Prüfer.

Begründung ergänzt um einen Satz zum Leitfaden. Versionssprung MINOR auf 2.3.0, weil ein Grundsatz
deutlich erweitert wird. Unter „Technische Rahmenbedingungen“ bleibt „Kern ohne Node“ ungenannt; es
steht im Leitfaden.

## `docs/ki_workflow/ki_pruefung.md`

- „Stand“: Feature 008 bringt den dritten Prüfer.
- „Wer prüft was“: Zeile „Architektur-Prüfer | beim Plan und am Ende jeder Phase mit Code | Aufbau:
  wer wen kennt, wo Logik und Daten liegen | Architektur-Leitfaden“.
- Schaubild „Regel → Test oder Prüfer“ bleibt; „Eine Regel aus dem Style-Guide“ wird „aus einem
  Maßstab“.
- „Die Prüfer“: Zeile „Architektur | Leitfaden | Baustein ruft den, der ihn einsetzt; neues Autoload
  ohne Grund; Logik in einer Szene | Kerne ohne Node, genau diese Autoloads, kein Weg nach oben |
  Feature 008“.
- „Nicht vorgesehen“: Der Punkt „ein eigener Code-Prüfer“ wird zu „bis 2026-10-28: ein eigener
  Code-Prüfer, denn Code prüft Claude. Seit Feature 008 gibt es den Architektur-Prüfer, weil er einen
  eigenen schriftlichen Maßstab hat (Grundsatz 2). Fehler im Code suchen weiter Claude und
  `/code-review`.“
- „Maßstäbe“: Absatz zum Leitfaden: liegt im Repo, der Prüfer liest ihn selbst.
- Ablauf: Teilnehmer „Architektur-Prüfer“ im Sequenzdiagramm, Schritt 2 „Code oder Szenen“.
- „Anbindung an Spec Kit“: Zeilen für `/speckit-checklist` (Plan und Vertrag) und `/speckit-tasks`
  (Code) ergänzt; `/speckit-analyze`: eine fehlende Phasenprüfung bei Code ist kritisch.
- „Nachmessen“: Zeilen für Fehlerprobe, Bestandsprüfung und die Phasen 4 und 5.

## `docs/ki_workflow/ki_dev.md` und `README.md`

- Punkt 8: „Ändert eine Phase Sichtbares, Texte oder Code …“; Verweis auf den Leitfaden.
- Schaubild „Ablauf je Feature“: Zweig „Sichtbares, Texte oder Code“ zur Phasenprüfung mit Stil-,
  Text- und Architektur-Prüfer.
- README, Schaubild „Wer macht was“: Prüfer-Knoten „Prüfer für Stil, Text und Architektur“; Tabelle
  „Was steht wo“: Zeile für den Leitfaden.

## `.claude/skills/dcl-phasenpruefung/SKILL.md`

- Beschreibung: „… Stil-, Text- und Architektur-Prüfer … Nutze dies am Ende jeder Phase, die
  Sichtbares, Texte oder Code ändert …“.
- Schritt 2: fehlt „Prüfer je Phase“, gilt zusätzlich: Architektur, wenn die Phase Skripte, Szenen
  oder Resources unter `src/` ändert; Tests und `addons/` allein lösen ihn nicht aus.
- Vorbereitung: für den Architektur-Prüfer die Liste der geänderten `.gd`, `.tscn` und `.tres` aus dem Diff,
  den Vertrag des Features und die Regeln, die `test_architektur.gd` misst.
- Ersatz-Auftrag für einen allgemeinen Agent wie bei den anderen.
- Checkliste: der Architektur-Prüfer liest Plan, research.md, data-model.md und contracts/.
- Bericht: Abschnitt „Architektur-Prüfer“ mit Befunden und begründeten Ausnahmen.

## `.specify/templates/overrides/tasks-template.md`

An jeder Phasenprüfung: „nur wenn die Phase Sichtbares, Texte oder Code ändert“, mit Verweis auf
„Prüfer je Phase“.

## `.claude/agents/godot-entwickler.md`

Unter „Vor jeder Aufgabe lesen“ als Punkt 2: `docs/architektur-leitfaden.md`. Unter „Godot“ ersetzt
der Verweis auf den Leitfaden den Satz „Systeme reden über Signale …“; „Die Timeline wendet keine
Effekte an“ bleibt, weil er aus der Verfassung kommt. Unter „Abliefern“, „Offen“: Abweichungen vom
Leitfaden mit Grund.

## `CLAUDE.md`

Nur mit Klaus' OK: Zeile `docs/architektur-leitfaden.md | Architektur-Leitfaden: Godot-Prinzipien,
Muster, Schichten; Maßstab des Architektur-Prüfers` in der Tabelle „Aufbau“. Claude legt den
Wortlaut in der Abnahme von Phase 2 vor.
