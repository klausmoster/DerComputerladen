# Der Computerladen – Verfassung

Wirtschaftssimulation und Point-and-Click-Adventure, Deutschland 1985–1999. Die Verfassung fasst
die Regeln zusammen, die für jedes Feature gelten. Sie beschreibt, *wie* gebaut wird; *was* das
Spiel ist, steht in `docs/game_design.md`.

## Grundsätze

### I. Nur Desktop

- Zielplattformen sind ausschließlich Windows, macOS und Linux. Android, iOS, Mobile, Touch und
  Web sind dauerhaft ausgeschlossen, nicht „später vielleicht“.
- Maus und Tastatur werden vorausgesetzt. Hover, Tooltips, Rechtsklick, Cursor-Wechsel und
  Drag & Drop sind erwünschte Mittel.
- Es gibt keine touch-tauglichen Mindestgrößen für Klickflächen, keine Gesten, kein
  `InputEventScreenTouch`, keine Orientierungswechsel und keine Safe Areas.
- Der Renderer bleibt Forward+. Auf Compatibility, Mobile oder GLES wird keine Rücksicht
  genommen, und Android-Build-Templates werden nie installiert.

Begründung: Die Entscheidung ist endgültig. Rücksicht auf andere Plattformen kostet
Gestaltungsfreiheit und bringt diesem Spiel nichts.

### II. Klaus entscheidet, der Agent baut, Claude plant und prüft

- Klaus gibt jede Umsetzung frei und nimmt sie ab. Was er selbst in Godot bauen will, um es zu
  lernen, trägt `[K]`, ebenso alles, was nur im Godot-Editor, in Grafikprogrammen oder mit seiner
  Entscheidung geht.
- Der Godot-Agent (`.claude/agents/godot-entwickler.md`) setzt `[A]`-Aufgaben um: Szenen, Nodes,
  GDScript und Tests, nach dem Vertrag des Features, dieser Verfassung und dem Style-Guide. Für
  Arbeit in Godot ist er der Standard.
- Claude schreibt Spec und Plan, recherchiert, verteilt die Aufgaben auf `[K]`, `[A]` und `[C]`
  und übernimmt die `[C]`-Aufgaben: Werkzeuge außerhalb von Godot, Style-Guide, Doku. Claude
  beauftragt den Agent und prüft jedes Ergebnis, bevor Klaus es sieht.
- Umgesetzt wird nur auf ausdrücklichen Auftrag von Klaus, eine Phase aus `tasks.md` nach der
  anderen, nie das ganze Feature in einem Zug. Eine Spec, ein Plan oder eine Taskliste ist eine
  Beschreibung, keine Beauftragung. `/speckit-implement` wird nicht verwendet.
- Code eines Agents bleibt auf dem Feature-Branch und wird erst committet, wenn Klaus Diff und
  Erklärung gesehen hat.
- Zu jeder umgesetzten Aufgabe gibt es eine Lernnotiz in `specs/<nummer>-<kurzname>/lernnotizen.md`:
  welche Godot-Konzepte vorkommen und warum es so gebaut ist, an der konkreten Stelle im Projekt.
  Die Schritte bleiben klein und einzeln überprüfbar.

Begründung: Die Umsetzung in Godot übernimmt ein spezialisierter Agent. Klaus behält jede
Entscheidung und lernt über Lernnotizen, Review und die `[K]`-Aufgaben, die er sich aussucht.

### III. Erst spezifizieren, dann bauen

- Gearbeitet wird featureweise. Vor dem Bauen steht für jedes Feature eine Spezifikation: erst,
  *was* es tut und woran man erkennt, dass es fertig ist, dann die Klärung offener Fragen, dann
  der Plan, dann die Aufgaben.
- In die Spezifikation gehört kein Godot-Detail. Nodes, Signaturen und Dateien kommen erst im
  Plan.
- Jedes Feature bekommt einen eigenen Branch.
- Jedes Feature hat eine feste Nummer, die Spec Kit vergibt (`001`, `002`, …). Branch und Ordner
  heißen danach, etwa `feature/001-hauptmenue` und `specs/001-hauptmenue/`. Branches und Commits
  verweisen auf die Nummer, deshalb wird sie nie geändert.
- Zu welchem System (01–11 aus `docs/features/Features.md`) ein Feature gehört, steht in seiner
  Spezifikation. Die älteren Feature-Docs in `docs/features/` behalten ihre IDs `SS-NN`.
- Entscheidungen werden mit verworfener Alternative und Grund festgehalten. Bekannte Lücken
  stehen als offene Fragen im Dokument, statt verschwiegen zu werden.

Begründung: Die Spezifikation ist die Gesprächsgrundlage für „wir arbeiten jetzt an Feature xy“.
In sechs Monaten zählt vor allem, warum etwas so und nicht anders gebaut wurde.

### IV. Ein Look: der Style-Guide

- Alles Sichtbare folgt dem
  [Computerladen Style-Guide](https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX): Raster und
  Auflösung, Farben, Schriften, Logo, Oberfläche, Figuren, Bewegung und Symbole.
- Der Style-Guide ist die einzige Quelle für diese Werte. Specs und Pläne verweisen auf ihn,
  statt Werte abzuschreiben.
- Braucht ein Feature etwas, das der Style-Guide nicht abdeckt oder anders regelt, wird zuerst
  der Style-Guide ergänzt und dann das Feature gebaut.
- Grafiken entstehen nach dem Leonardo-Workflow im Style-Guide. Jedes freigegebene Bild steht
  mit Prompt, Modell und Seed in `docs/art/leonardo/prompt-log.md`.

Begründung: Das Spiel soll wie aus einem Guss wirken, im Retro-Look der frühen 90er und modern
bedienbar.

### V. Daten sauber halten

- Spielinhalt (Komponenten, Preise, Prospekte) liegt in `docs/game_bible/`, nicht im Code.
- Strukturierte Daten stehen dort nur im YAML-Frontmatter, Skalare als `kategorie_feld`.
- Preise sind Ranges: je Eintrag `von`/`bis` als Zahl in DM, ohne „DM“ und ohne Tausenderpunkt.
- Freitext steht nur unter `##`-Überschriften, deren Titel mit `+` beginnt. Diese Abschnitte
  sind vor Regenerierung geschützt.
- `Templates/TEMPLATE_*.md` ist die alleinige Autorität für Struktur und Feldnamen. Eine
  vorhandene Datei ist nie Strukturvorlage.
- Bezug ist der deutsche Markt der 1990er, in DM und mit dem Datumsformat `JJJJ-MM`.
- Ausnahme Ereigniskatalog: Die Ereignisse der Zeitleiste liegen als Datei im Spielprojekt und
  werden mit der Zeitleisten-Werkstatt gepflegt, nicht in der game_bible. Die Werkstatt muss den
  Katalog lesen und schreiben können, und Ereignisse brauchen tagesgenaue Daten statt `JJJJ-MM`.

Begründung: Die Daten sind der Spielinhalt. Sie müssen maschinell lesbar bleiben und dürfen beim
Regenerieren der Tabellen nicht verloren gehen.

## Technische Rahmenbedingungen

- Engine ist Godot 4.7 mit GDScript. Das Godot-Projekt liegt in `src/`, nicht im Repo-Root.
- Tests laufen mit GUT 9.7.1, auch headless von der Kommandozeile.
- `GameClock` und `Timeline` sind Autoloads.
- Die Timeline wendet Effekte nicht an. Sie meldet sie per Signal (`Timeline.effect_applied`),
  und Wirtschaft, Nachfrage und Reputation hängen sich daran.
- Alles, was ein Ereignis auslösen kann, steht in der Timeline. So gibt es eine Quelle statt
  zwei, und der Spielverlauf lässt sich an einer Stelle prüfen (entschieden am 2026-08-13).

## Arbeitsweise

- Projektsprache ist Deutsch: Dokumente und Spezifikationen werden deutsch geschrieben.
- `docs/game_design.md` ist die Vision (*was* das Spiel ist), die Feature-Spezifikationen sind
  der Bauplan (*wie*), und `docs/game_bible/` ist der Spielinhalt.
- Ablauf je Feature: `/speckit-specify` legt Branch und Spezifikation an, `/speckit-clarify`
  klärt die offenen Fragen mit Klaus, danach folgen `/speckit-plan`, `/speckit-checklist`,
  `/speckit-tasks` und `/speckit-analyze`. Danach setzen Godot-Agent und Klaus die freigegebenen
  Phasen um (Grundsatz II), und Claude prüft jede Phase gegen Spec und Vertrag.
- Clarify, Checklist und Analyze sind in Spec Kit optional, bei uns laufen sie immer.
- Claude committet, Klaus pusht; der Godot-Agent committet nicht. Claude versucht nie zu pushen,
  denn auf diesem Rechner liegen keine GitHub-Zugangsdaten. Code committet Claude erst, wenn Klaus
  ihn gesehen hat.
- `.godot/` bleibt draußen. `*.uid` und `*.import` werden committet, weil sie die stabile
  Resource-ID und die Import-Einstellungen halten.
- `export_presets.cfg` wird vor dem Committen angesehen, weil dort je nach Godot-Version
  Signierungs-Credentials im Klartext landen.

## Geltung und Änderungen

- CLAUDE.md bleibt die Arbeitsanweisung für Claude Code. Die Verfassung fasst deren verbindliche
  Regeln für die Spec-Kit-Abläufe zusammen. Widersprechen sich beide, gilt CLAUDE.md, und die
  Verfassung wird angeglichen.
- Jeder Plan prüft im Constitution Check gegen diese Grundsätze. `/speckit-analyze` behandelt
  Verstöße als kritisch.
- Änderungen an der Verfassung beschließt Klaus. Jede Änderung erhöht die Version: MAJOR, wenn
  ein Grundsatz wegfällt oder neu definiert wird; MINOR, wenn ein Grundsatz oder Abschnitt
  hinzukommt oder deutlich erweitert wird; PATCH für Klarstellungen und Wortlaut.

**Version**: 2.1.0 | **Beschlossen**: 2026-10-19 | **Zuletzt geändert**: 2026-10-20
