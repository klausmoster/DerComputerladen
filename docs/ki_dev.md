# Entwickeln mit KI – Blaupause

Wie Klaus, Claude und der Godot-Agent bei „Der Computerladen“ zusammenarbeiten: Abläufe und
Regeln, die sich bewährt haben, jeweils mit Grund. Die Datei wächst mit dem Projekt. Neue
Erfahrungen kommen als Punkt dazu, mit dem Anlass, aus dem sie entstanden sind. Gedacht ist sie
als Vorlage, die sich auf spätere Projekte übertragen lässt.

**Pflege:** Erkennt Claude ein Muster, das die Arbeitsweise allgemein betrifft und nicht nur das
aktuelle Feature, fragt Claude nach, ob es hier aufgenommen wird, mit einem Vorschlag für den
Wortlaut und dem Anlass. Beispiele: eine Prüfung, die zum zweiten Mal einen Fehler gefunden hat;
eine Korrektur, die Klaus wiederholt. Eingetragen wird erst nach Klaus' OK (Klaus, 2026-10-21).

**Abgrenzung:**
- `CLAUDE.md` ist die verbindliche Arbeitsanweisung für Claude Code in diesem Projekt.
- `.specify/memory/constitution.md` fasst die verbindlichen Grundsätze für die Spec-Kit-Abläufe.
- Diese Datei ist die Blaupause dahinter: das Warum, die Erfahrungen, die Vorlage. `CLAUDE.md`
  verweist auf sie, ihre Regeln gelten also für Claude in diesem Projekt (Klaus, 2026-10-21).
  Wird eine Praxis grundsätzlich, wandert sie nach `CLAUDE.md` bzw. in die Verfassung.
- `docs/offene-punkte.md` sammelt offene Fragen, Lücken und Claudes eigene Entscheidungen, bis
  Klaus sie entschieden oder bestätigt hat.

**Kein lokales Gedächtnis** (Klaus, 2026-10-21): Nichts wird in einem lokalen Memory-Verzeichnis
abgelegt. Was dauerhaft gelten soll, wird in eine Repo-Datei geschrieben und committet: `CLAUDE.md`,
die Verfassung, diese Datei, die Feature-Dokumente, `docs/Ideensammlung.md` oder
`docs/offene-punkte.md`. Dann steht es allen Sitzungen und allen Beteiligten zur Verfügung und ist
versioniert. Fällt etwas an, das nirgends passt, gehört es in diese Datei. Bis 2026-10-21 hielt
Claudes lokales Memory Vorlieben und Stand fest; der Inhalt ist hierher und nach
`docs/offene-punkte.md` umgezogen.

## Rollen

- **Klaus** entscheidet und nimmt ab: Er gibt jede Phase frei, nimmt sie ab und pusht. Was er
  selbst bauen will, um es zu lernen, trägt `[K]`.
- **Claude** plant und prüft: Specs, Pläne, Aufträge an den Agent, Review, Doku, Commits (`[C]`).
- **Der Godot-Agent** (`.claude/agents/godot-entwickler.md`) macht die eigentliche Programmierung:
  Szenen, GDScript, Tests (`[A]`). Er committet nie.

Warum: Wer baut, prüft nicht selbst. Klaus bekommt nur zu sehen, was Claude schon geprüft hat, und
Claude bleibt frei für Planung und Review.

## Ablauf je Feature

1. **Ein Branch pro Feature:** `feature/NNN-kurzname`, Ordner `specs/NNN-kurzname/`.
2. **Spec Kit vollständig, auch die optionalen Schritte:**
   `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-checklist` →
   `/speckit-tasks` → `/speckit-analyze`. Clarify, Checklist und Analyze laufen immer.
   Warum: Jeder dieser Schritte hat bisher echte Lücken gefunden, etwa die 40 Befunde der Analyse
   von Feature 002, bevor eine Zeile Code entstand.
3. **Phasenweise umsetzen, nie `/speckit-implement` für alles:** Klaus gibt jede Phase einzeln
   frei, etwa „Starte Phase 4: T031 bis T039 mit dem Agent, T040 ist meine Abnahme“.
4. **Große Phasen in zwei Teilen:** erst der Kern, dann die Oberfläche, dazwischen prüft Claude.
   So baut Teil 2 auf geprüftem Grund.
5. **Jede Phase endet mit Klaus' Abnahme**, einer `[K]`-Aufgabe, und erst danach mit einem Commit.
6. **Vor der Gesamtabnahme die Lückensuche:** Nach der letzten Umsetzungsphase läuft
   `/speckit-converge` über das ganze Feature. Prüfer lesen Spec, Plan, Verträge und Aufgaben
   gegen den Code, Claude prüft jeden Befund selbst nach. Die Lücken werden eine eigene Phase mit
   Klaus' Freigabe, erst danach folgt die Gesamtabnahme. Warum: Bei Feature 002 fand die
   Lückensuche 14 Lücken, darunter zwei Widersprüche zur Spec, obwohl alle Tests grün waren
   (Klaus, 2026-10-21).

## Git

- **Claude committet, Klaus pusht.** Claude gibt keine Push-Befehle und keine Anleitungen dazu.
- **Ein Commit je abgenommener Phase.** Die Nachricht nennt, was je Aufgabe gebaut ist, was aus
  Prüfung und Abnahme dazukam, und das Testergebnis.
- **Nach einem Commit nur Hash und Stand nennen**, ohne Hinweis aufs Pushen. Anlass: Nach einem
  gescheiterten Push kam einmal eine SSH-Anleitung, die Klaus nicht wollte (2026-10-19).
- **Nur eigene Dateien committen.** Im geteilten Ordner arbeiten mehrere Sitzungen; deshalb nie
  `stash`, `reset` oder Branchwechsel.
- **Vor dem Commit `export_presets.cfg` ansehen**, denn dort können Zugangsdaten im Klartext
  landen. Keine Zugangsdaten in Dateien.

## Aufträge an den Agent

Ein guter Auftrag enthält:
- die Aufgabennummern und ausdrücklich, was nicht dazugehört, etwa „T061 kommt in Teil 2“;
- was zuerst zu lesen ist: tasks.md, Spec, Verträge, research.md, Style-Guide, vorhandener Code;
- den Rahmen: Branch, nicht committen, welche Dateien tabu sind, etwa der echte Katalog;
- **feste Größen**, die nicht wackeln dürfen, etwa „ohne Eingriffe bleibt der Fahrplan
  bytegleich, geprüft für die Seeds 1, 4711 und 99999“;
- die Prüfbefehle, jeder mit Zeitlimit;
- bei Oberflächen Bildschirmfotos aus einem echten Fenster in Klaus' Fenstergröße, dazu eine
  Aussage, ob der Platz reicht;
- die Form des Berichts: Dateien, API, Testergebnis mit Zahlen, Auslegungen, offene Fragen.

Steht der Agent-Typ `godot-entwickler` in einer Sitzung nicht bereit (Agents laden nur beim
Start), nimmt Claude einen allgemeinen Agent, der zuerst `.claude/agents/godot-entwickler.md`
liest.

Bewährt: die **Fehlerprobe**. Der Agent baut in einer Kopie absichtlich Fehler ein und zeigt, dass
die Tests sie finden. Fällt ein Fehler durch, kommt ein Test dazu.

## Prüfen, bevor Klaus es sieht

- Die Tests selbst laufen lassen, zweimal: Schwankt die Zahl der Prüfungen, ist ein Test vom
  Zufall abhängig.
- Die Startprobe headless mit `-d`: Exit 0 und keine Ausgabe.
- Feste Größen nachmessen: Bytevergleich der Ausgaben, Daten unverändert, keine liegen gebliebenen
  Dateien.
- Die Bilder ansehen und den Code an den kritischen Stellen lesen.
- **Fensterverhalten im echten Fenster prüfen.** Headless sieht man es nicht. Anlass: In Phase 4
  startete die Werkstatt im Vollbild statt maximiert, alle Tests waren grün.
- **Neue Oberflächen bei Klaus' echter Fenstergröße prüfen**, derzeit 1920 × 925 logisch, und den
  Platz schon im Auftrag an den Agent abfragen. Anlass: In den Phasen 7 bis 9 zeigte erst der
  Bericht des Agents, dass eine Tabelle unter dem Zeitstrahl nur drei, vier Zeilen hat (Klaus,
  2026-10-21).
- Auslegungen des Agents in die Spec-Dokumente schreiben. Kleine entscheidet Claude, echte
  Entscheidungen legt Claude Klaus vor.
- Funde aus früheren Phasen gleich mit beheben lassen, etwa das fehlende Zebra in Liste und
  Prüfung aus Phase 4.

## Abnahme durch Klaus

Die Bitte um Abnahme enthält, in dieser Reihenfolge:
1. den Startbefehl als eigenen `bash`-Block, damit Klaus ihn mit dem Play-Knopf startet;
2. was gebaut ist, kurz je Aufgabe;
3. was geprüft ist, mit Zahlen;
4. die Auslegungen, die Klaus ablehnen kann, jede mit einem Beispiel;
5. die Prüfliste im Quickstart und Hinweise zum Aufräumen, etwa `git restore` für den Katalog.

## Tests

- **Deterministisch:** feste Seeds. Anlass: Ein Test ohne festen Seed prüfte mal 0, mal 1 Termin.
- **Tests schreiben nie in echte Daten:** eigene Ordner unter `user://`; der echte Katalog gehört
  nicht in Tests, Maßstab ist eine eingefrorene Kopie.
- **Ausgaben als Ganzes vergleichen:** Bytevergleich oder gespeicherte Erwartung, nicht nur
  Stichproben.
- **Zahlen aus der Spec messen**, statt sie zu schätzen, etwa „Bis zum Ende“ in 21 ms bei einem
  Ziel von unter 1 Sekunde.

## Dokumentation und Entscheidungen

- **Jede Entscheidung mit Datum und wer sie traf**, in research.md oder der Spec.
- **Ändert sich eine Entscheidung, bleibt die alte sichtbar:** „bis 2026-10-20: im Vollbild“, wie
  bei FR-004 von Feature 001.
- **Lernnotizen** zu jeder Aufgabe, an der konkreten Stelle im Projekt, kein Tutorial.
- **Lose Ideen sofort festhalten**, unten in `docs/Ideensammlung.md`, ohne die Arbeit zu
  unterbrechen: Datum, Kern in ein, zwei Sätzen, bei Bedarf Bezug und offene Fragen. Nicht erst
  fragen und nicht ausarbeiten; wird eine Idee konkret, wandert sie nach
  `docs/features/Feature_Ideas.md` oder ins GDD.
- **Entscheidungen nicht stillschweigend treffen** (Klaus, 2026-10-21):
  - Wo eine Festlegung nötig ist, die nicht aus den Dokumenten folgt: entscheiden, umsetzen und
    die Entscheidung sichtbar als eigene kennzeichnen, in `docs/offene-punkte.md` und, wo sie
    hingehört, in Spec oder Verfassung.
  - Wo zwei Lesarten zu deutlich verschiedener Arbeit führen: fragen, bevor gebaut wird.
  - Wo etwas in den Dokumenten fehlt oder sich widerspricht: als offenen Punkt in
    `docs/offene-punkte.md` eintragen, statt es im Vorbeigehen zu erfinden.
- **Verfassung und `CLAUDE.md` ändern sich nur auf Klaus' Beschluss**, die Verfassung mit
  Versionssprung über `/speckit-constitution`.
- **Was man sieht, steht zuerst im Style-Guide:** Eine neue Farbrolle oder Darstellung kommt erst
  in den Style-Guide, dann in den Code, etwa Raster und Achse des Zeitstrahls.

## Zusammenarbeit

- Deutsch; Fachbegriffe mit einem Beispiel aus dem Spiel erklären. Anlass: Im Review von Feature
  002 verstand Klaus „Eingriffe aus dem Simulator“ erst mit dem Beispiel „Was wäre, wenn der
  Spieler ab 1990 beim windigen Händler kauft? Dann stellst du von Hand ein: Reklamationswelle +5
  Prozentpunkte“ (2026-10-20).
- Alle Texte im Spiel und in den Werkzeugen duzen den Spieler, etwa „Bald kannst du ihn
  eröffnen.“ (Klaus, 2026-10-19, im Review von Feature 001, gegen die Empfehlung „Sie“).
- Claude empfiehlt eine Lösung, statt nur Möglichkeiten aufzuzählen, und fragt nur, was wirklich
  Klaus' Entscheidung ist, eine Frage nach der anderen.
- **Fragen immer als Auswahl** (Klaus, 2026-10-21): Jede Frage an Klaus kommt mit Antworten zum
  Auswählen, die Empfehlung zuerst; eine freie Antwort bleibt möglich. Das gilt auch für die Fragen
  von `/speckit-specify` und `/speckit-clarify`, die Spec Kit sonst als Kurzantwort zulässt.
  Anlass: die Klärungsfragen zu Feature 003.
- Dauert etwas länger, meldet Claude kurz den Stand.

## Werkzeuge und Pfade

- Godot liegt unter `/Applications/Godot.app/Contents/MacOS/Godot`, Version 4.7.2 stable, nicht
  .NET; den Pfad direkt nutzen statt zu suchen. Kommt eine zweite Version dazu, hier nachtragen.
- Projekt-Root ist `src/`, also immer `--path src`. Startbefehle vom Repo-Ordner aus:
  - Spiel: `/Applications/Godot.app/Contents/MacOS/Godot --path src`
  - Werkstatt:
    `/Applications/Godot.app/Contents/MacOS/Godot --path src res://tools/werkstatt/werkstatt.tscn`
  - Tests:
    `/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd`

## Grafik

- Grafik läuft über Artifacts, nicht über Dateien im Repo (seit 2026-10-19):
  - Style-Guide, verbindlich: https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX, mit Leitbild,
    Tokens, Bausteinen, dem Abschnitt „Werkzeuge“ und dem Leonardo-Workflow samt
    Prompt-Bibliothek.
  - Claude Design „Computerladen Titelscreen & Cover“:
    https://claude.ai/artifact/RHKxpTb6JfWFQdNnPYEWHH, noch mit den alten Platzhalter-Skizzen
    vor der Pixel-Umstellung.
- Entscheidungen von Klaus: Vorbild für Aufbau und Humor sind die deutschen
  Wirtschaftssimulationen der 90er wie „Das Amt“. Grundstil ist VGA-Pixel-Art, Stilanker ist Bild
  C2 aus der Leonardo-Stilprobe vom 2026-10-19 (Ladenbesitzer hinter der Theke). Zwei Raster:
  Szenen 320 × 180 Bildpixel, Oberfläche 640 × 360, ganzzahlig skaliert. „Cooler Retro-Style, der
  trotzdem als modernes Spiel durchgeht“; Konsistenz ist oberstes Ziel.
- Klaus erzeugt die Bilder selbst in Leonardo.ai. Claude liefert dafür jedes Mal den fertigen
  Prompt auf Englisch mit dem Stilblock aus dem Style-Guide, das Modell und das Seitenverhältnis
  und trägt den Prompt in die Prompt-Bibliothek ein (Klaus, 2026-10-19). Bisher: Lucid Origin mit
  C2 als Style Reference (Stärke High), Prompt Enhance aus, Style None. Die Modellliste von
  Leonardo ändert sich, also vorher prüfen.
- Leonardo bedient Claude über Claude in Chrome. Chrome startet auf Klaus' Rechner nur mit
  `--user-data-dir="$HOME/Library/Application Support/Google/Chrome-Profil"`, weil macOS den
  Standard-Profilordner sperrt.
- Die Grafikstil-Zeile im GDD ändert Claude nur mit Klaus' OK.

## Offen

- Szenario-Tests aus gespeicherten Proben, siehe Ideensammlung vom 2026-10-21.
