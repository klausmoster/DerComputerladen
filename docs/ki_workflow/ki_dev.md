# Entwickeln mit KI – Erfahrungen

Was beim Entwickeln von „Der Computerladen“ gilt, über die [Blaupause](blaupause.md) hinaus: die
Ausprägung ihrer Regeln in diesem Projekt, die Anlässe, aus denen sie entstanden, und Werkzeuge und
Pfade. Die allgemeinen Regeln stehen in der Blaupause, die Werte des Projekts im
[Steckbrief](projekt.md). Wie geprüft wird, steht in [ki_pruefung.md](ki_pruefung.md); Pflege und
Abgrenzung im [Einstieg](README.md).

Bis 2026-10-29 stand hier die ganze Arbeitsweise; seitdem steht das Allgemeine in der Blaupause
(Abschnitte in Klammern), und hier bleibt, was nur hier gilt. Die Abschnitte und die Punkte 1 bis
11 behalten ihre Namen und Nummern, weil andere Dateien auf sie verweisen.

## Rollen

Blaupause 2. Entscheider ist **Klaus** (`[K]`), Bau-Agent der **Godot-Agent**
(`.claude/agents/godot-entwickler.md`, `[A]`). Was Klaus selbst bauen will, um Godot zu lernen,
trägt `[K]` (Modul Lernnotizen).

## Ablauf je Feature

Blaupause 4. Alle Schritte der Reihe nach, mit den Befehlen dieses Projekts, stehen im
[Fahrplan](feature_fahrplan.md).

1. **Ein Branch pro Feature** (Blaupause 5): `feature/NNN-kurzname`, Ordner `specs/NNN-kurzname/`.
2. **Spec Kit vollständig** (Blaupause 4.3). Anlass: Die Analyse von Feature 002 fand 40 Befunde,
   bevor eine Zeile Code entstand.
3. **Phasenweise umsetzen, ohne `/speckit-implement`** (Blaupause 4.4). Freigabe etwa „Starte
   Phase 4: T031 bis T039 mit dem Agent, T040 ist meine Abnahme“.
4. **Große Phasen in zwei Teilen** (Blaupause 4.5).
5. **Jede Phase endet mit Klaus' Abnahme**, einer `[K]`-Aufgabe, und erst danach mit einem Commit
   (Blaupause 4.6).
6. **Vor der Gesamtabnahme die Lückensuche** (Blaupause 4.7). Anlass: Bei Feature 002 fand sie 14
   Lücken, darunter zwei Widersprüche zur Spec, obwohl alle Tests grün waren (Klaus, 2026-10-21).
7. **Eine Claude-Sitzung je Feature, von `/speckit-specify` bis zur Gesamtabnahme** (Blaupause 4.1;
   Klaus, 2026-10-26). Sie heißt „[NNN] Featurename / Beschreibung“, etwa „[004] Neues Spiel“
   (Klaus, 2026-10-22). Eine eigene Sitzung je Schritt bietet Claude nicht an. Anlass: eine
   Sitzung mit Feature 001, dem Start von 002 und der Spec von 003, die beim Zusammenfassen
   Einzelheiten verlor. Bis 2026-10-26 begann die eigene Sitzung erst mit dem Plan (Klaus,
   2026-10-21).
8. **Phasenprüfung vor der Abnahme** (Blaupause 6; Klaus, 2026-10-22, fest seit dem Pilot in Feature
   004, 2026-10-26). Hier lösen sie aus: Sichtbares oder Texte, auch in Werkzeugen (Stil- und
   Text-Prüfer); Skripte, Szenen oder Resources unter `src/` außer Tests (Architektur-Prüfer,
   Klaus, 2026-10-28, Feature 008). Schon bei `/speckit-checklist` lesen die Prüfer Spec und
   Vertrag (Klaus, 2026-10-27), der Architektur-Prüfer Plan und Vertrag (2026-10-28). Einzelheiten
   in [ki_pruefung.md](ki_pruefung.md). Bis zum Pilot prüfte Claude allein.
9. **Als letzte Aufgabe die Spielbeschreibung prüfen** (Blaupause 4.8; Klaus, 2026-10-27):
   `<Stand-im-Code>` ist hier `docs/spielbeschreibung/`. Die Aufgabe bringt die Vorlage unter
   `.specify/templates/overrides/` mit.
10. **Vor jedem Merge das Tagebuch fortschreiben** (Blaupause 11; Klaus, 2026-10-27): auf Englisch,
    in der Form aus dem [README](../tagebuch/README.md); übersetzt wird nicht während der
    Entwicklung. Ein kleiner Branch, etwa zur Arbeitsweise, schreibt in die Datei, die zeitlich
    passt. Bei Grafik kommt das Bild dazu. Zeile zu Tokens und Kosten:
    `python3 -I tools/tagebuch/token_bilanz.py feature/NNN-kurzname`. Wo der Grund fehlt, fragt
    Claude Klaus.
11. **Selbsttest zur Gesamtabnahme** (Modul Selbsttest; Klaus, 2026-10-28, Feature 007): Nicht nach
    jeder Phase, dort reichen Tests und Startprobe. Ändert ein Feature Seiten, Wege, Texte oder
    Eingaben, die der Selbsttest durchspielt, passt vor der Gesamtabnahme die Aufgabe „[A]
    Selbsttest-Abläufe anpassen“ die Abläufe unter `src/tools/selbsttest/ablaeufe/` an. Dann baut
    Claude mit `tools/build/baue_alles.sh`, lässt den Selbsttest auf dem Mac laufen, vergleicht mit
    `tools/selbsttest/vergleich.py` und nennt das Ergebnis in der Bitte um Gesamtabnahme. Neue
    Referenzbilder gibt es nur nach Klaus' Abnahme. Auf Windows und Linux startet Klaus ihn, wenn
    das Feature Fenster, Eingabe, Grafik, Dateien oder Export ändert, sonst spätestens jedes dritte
    Feature. Warum: Tests ohne Fenster sehen weder Treiber noch echtes Fenster; in 007 fand der
    Selbsttest die falsche Fenstermitte und einen Windows-Rechner, auf dem Forward+ nicht startet
    (deshalb seit 2026-10-29, Feature 009, Compatibility).

## Git

Blaupause 7. Hier dazu:
- **Nach einem Commit nur Hash und Stand nennen**, ohne Hinweis aufs Pushen. Anlass: Nach einem
  gescheiterten Push kam einmal eine SSH-Anleitung, die Klaus nicht wollte (2026-10-19). Auf diesem
  Rechner liegen keine GitHub-Zugangsdaten.
- **Vor dem Commit `export_presets.cfg` ansehen**: Je nach Godot-Version landen dort
  Signierungs-Zugangsdaten im Klartext.

## Aufträge an den Agent

Blaupause 8. Hier dazu:
- Ein Beispiel für feste Größen: „Ohne Eingriffe bleibt der Fahrplan bytegleich, geprüft für die
  Seeds 1, 4711 und 99999.“
- Tabu ist etwa der echte Ereigniskatalog `src/data/event_catalog.json`.
- Bildschirmfotos aus einem echten Fenster in Klaus' Fenstergröße (Steckbrief, „Prüfgröße“).
- Steht der Agent-Typ `godot-entwickler` in einer Sitzung nicht bereit, nimmt Claude einen
  allgemeinen Agent, der zuerst `.claude/agents/godot-entwickler.md` liest.

## Prüfen, bevor Klaus es sieht

Blaupause 9. Hier dazu, jeweils mit Anlass:
- **Startprobe:** headless mit `-d`, Exit 0 und keine Ausgabe.
- **Fensterverhalten im echten Fenster prüfen.** Anlass: In Phase 4 von Feature 002 startete die
  Werkstatt im Vollbild statt maximiert, alle Tests waren grün.
- **Neue Oberflächen bei Klaus' echter Fenstergröße prüfen**, derzeit 1920 × 925 logisch, und den
  Platz schon im Auftrag an den Agent abfragen. Anlass: In den Phasen 7 bis 9 zeigte erst der
  Bericht des Agents, dass eine Tabelle unter dem Zeitstrahl nur drei, vier Zeilen hat (Klaus,
  2026-10-21).
- **Funde aus früheren Phasen gleich mit beheben lassen**, etwa das fehlende Zebra in Liste und
  Prüfung aus Phase 4.

## Abnahme durch Klaus

Blaupause 9, „Bitte um Abnahme“. Ohne Startweg ist die Bitte unvollständig, auch bei der
Gesamtabnahme und jeder Ankündigung „danach folgt deine Abnahme“ (Klaus, 2026-10-28). Anlass: die
Bitte um Gesamtabnahme von Feature 006 ohne Startbefehl. Zum Aufräumen gehört etwa `git restore`
für den Ereigniskatalog.

## Tests

Blaupause 10. Hier dazu:
- **Deterministisch.** Anlass: Ein Test ohne festen Seed prüfte mal 0, mal 1 Termin.
- **Nie in echte Daten:** eigene Ordner unter `user://`; Maßstab ist eine eingefrorene Kopie des
  Katalogs.
- **Zahlen messen**, etwa „Bis zum Ende“ in 21 ms bei einem Ziel von unter 1 Sekunde.
- Was die Tests schon messen, steht in [ki_pruefung.md](ki_pruefung.md), „Tests“.

## Dokumentation und Entscheidungen

Blaupause 11. Hier dazu:
- **Die alte Entscheidung bleibt sichtbar**, wie bei FR-004 von Feature 001: „bis 2026-10-20: im
  Vollbild“.
- **Lernnotizen** zu jeder Aufgabe in `specs/NNN-kurzname/lernnotizen.md` (Modul Lernnotizen).
- **Lose Ideen** stehen in `docs/Ideensammlung.md`; wird eine konkret, wandert sie nach
  `docs/features/Feature_Ideas.md` oder ins GDD.
- **Entscheidungen nicht stillschweigend treffen** (Klaus, 2026-10-21): Blaupause 11, mit
  `docs/offene-punkte.md`.
- **Verfassung und `CLAUDE.md` ändern sich nur auf Klaus' Beschluss**, die Verfassung mit
  Versionssprung über `/speckit-constitution`.
- **Was man sieht, steht zuerst im Style-Guide**, etwa Raster und Achse des Zeitstrahls.

## Zusammenarbeit

Blaupause 12. Hier dazu, jeweils mit Anlass:
- **Fachbegriffe mit einem Beispiel aus dem Spiel.** Im Review von Feature 002 verstand Klaus
  „Eingriffe aus dem Simulator“ erst mit dem Beispiel „Was wäre, wenn der Spieler ab 1990 beim
  windigen Händler kauft? Dann stellst du von Hand ein: Reklamationswelle +5 Prozentpunkte“
  (2026-10-20).
- **Spiel und Werkzeuge duzen den Spieler**, etwa „Bald kannst du ihn eröffnen.“ (Klaus,
  2026-10-19, im Review von Feature 001, gegen die Empfehlung „Sie“).
- **Fragen immer als Auswahl** (Klaus, 2026-10-21), auch bei `/speckit-specify` und
  `/speckit-clarify`. Anlass: die Klärungsfragen zu Feature 003.
- **Eingedeutschte Fachwörter bleiben, wie sie sind** (Klaus, 2026-10-27): „scrollen“, nicht
  „rollen“. Anlass: eine Frage mit „rollen“.
- **Bei jeder Frage, ob etwas gebaut wird, steht der ungefähre Aufwand dabei** (Klaus,
  2026-10-27), etwa „Aufwand: klein, eine Aufgabe für den Agent“. Anlass: T044 in Feature 004.

## Werkzeuge und Pfade

Befehle zum Starten, Testen und Bauen stehen im [Steckbrief](projekt.md), „Stack und Befehle“.

- Godot liegt unter `/Applications/Godot.app/Contents/MacOS/Godot`, Version 4.7.2 stable, nicht
  .NET; den Pfad direkt nutzen statt zu suchen. Kommt eine zweite Version dazu, im Steckbrief
  nachtragen.
- **Godot-Referenz** (Modul Stack-Referenz; Klaus, 2026-10-29): `godot_referenz/klassen/<Klasse>.xml`
  im Repo-Root ist die Klassenreferenz der installierten Godot mit Beschreibungen,
  `godot_referenz/handbuch/` das Handbuch als `.rst`; beides erzeugt mit
  `tools/godot_referenz/erzeuge.sh --texte --handbuch` und nicht im Repo. Bei API-Fragen sehen
  Claude, der Godot-Agent und der Architektur-Prüfer dort nach statt aus dem Gedächtnis; fehlt der
  Ordner, läuft zuerst das Skript, in jedem Worktree einmal. Geladen wird je Rechner und
  Godot-Version nur einmal (Cache `~/.cache/der-computerladen/`); eine neue Version lädt neu, das
  braucht Klaus' Erlaubnis mit Quelle und Größe. Seit 2026-10-29 ist das die erste Aufgabe in jedem
  `tasks.md`.
- Claude darf Prozesse selbst mit `kill` beenden, etwa ein hängendes Godot oder eine offene
  Werkstatt nach einem Test (Klaus, 2026-10-27, im Spike zum Communicator). Die Erlaubnis steht als
  `Bash(kill *)` in Klaus' `~/.claude/settings.json`.
- **Spec Kit aktualisieren** (Blaupause 5; Klaus, 2026-10-27): Nach jedem Update, bevor committet
  wird:
  1. Claude prüft mit `git diff`, dass `overrides/` und die Verfassung unverändert sind. Anlass:
     Klaus' Frage, ob ein Update die Aufgaben „Phasenprüfung“ und „Spielbeschreibung prüfen“
     löschen kann.
  2. Claude vergleicht die neuen Vorlagen von Spec Kit mit den Ausgangsfassungen im
     [Steckbrief](projekt.md), „Eigene Vorlagen“, zieht Verbesserungen in die eigenen Kopien nach
     und trägt die neuen Prüfsummen ein. Anlass: die Proben der Blaupause (Klaus, 2026-10-29).

## Grafik

Modul Grafik-Pipeline.

- Alles, womit die KI für die Grafik arbeitet, liegt im Repo, als Markdown und in Obsidian
  lesbar, nicht in Claude Design oder Artifacts (Klaus, 2026-10-29; vom 2026-10-19 an lag der
  Style-Guide als Artifact vor):
  - Style-Guide, verbindlich: `docs/style-guide/`, mit Leitbild, Tokens, Bausteinen, den
    Abschnitten „Sprache“, „Ton“ und „Werkzeuge“ und dem Leonardo-Workflow samt
    Prompt-Bibliothek.
  - Cover-Entwurf: `docs/art/entwuerfe/cover.md`, übernommen aus dem Claude-Design-Artifact
    „Computerladen Titelscreen & Cover“ (2026-10-19). Dessen Titelscreen ist durch T-02 und den
    Communicator überholt und wurde nicht übernommen.
- Entscheidungen von Klaus: Vorbild für Aufbau und Humor sind die deutschen
  Wirtschaftssimulationen der 90er wie „Das Amt“. Grundstil ist VGA-Pixel-Art, Stilanker ist Bild
  C2 aus der Leonardo-Stilprobe vom 2026-10-19 (Ladenbesitzer hinter der Theke). Zwei Raster:
  Szenen 320 × 180 Bildpixel, Oberfläche 640 × 360, ganzzahlig skaliert. „Cooler Retro-Style, der
  trotzdem als modernes Spiel durchgeht“; Konsistenz ist oberstes Ziel.
- Die Bilder erzeugt Claude selbst in Leonardo.ai, über Claude in Chrome im Konto des Projekts;
  Klaus wählt nur das Bild aus und gibt es frei. Claude fragt nicht, ob Klaus erzeugen will, und
  liefert keine Anleitung zum Selbermachen (Klaus, 2026-10-27; bis dahin erzeugte Klaus selbst).
  Den Prompt schreibt Claude auf Englisch mit dem Stilblock aus dem Style-Guide und trägt ihn
  vorher in die Prompt-Bibliothek ein. Ist Claude in Chrome nicht erreichbar, sagt Claude das
  sofort und nennt den Grund, statt auf einen anderen Weg auszuweichen. Den ganzen Ablauf vom
  Prompt bis zum Prompt-Log beschreibt der Skill `dcl-grafik`
  (`.claude/skills/dcl-grafik/SKILL.md`); er wird bei jeder Grafikaufgabe geladen. Anlass: Die
  Regeln lagen auf drei Dateien verteilt, und Claude bat Klaus zweimal, selbst in Leonardo zu
  erzeugen (2026-10-27). Bisher: Lucid Origin mit
  C2 als Style Reference (Stärke High), Prompt Enhance aus, Style None. Die Modellliste von
  Leonardo ändert sich, also vorher prüfen.
- Leonardo bedient Claude über Claude in Chrome. Chrome startet auf Klaus' Rechner nur mit
  `--user-data-dir="$HOME/Library/Application Support/Google/Chrome-Profil"`, weil macOS den
  Standard-Profilordner sperrt; ohne das schließt Chrome sich sofort wieder. Claude startet es
  selbst mit `open -na "Google Chrome" --args --user-data-dir="$HOME/Library/Application
  Support/Google/Chrome-Profil"`, wenn Claude in Chrome nicht erreichbar ist (2026-10-27).
- Die Grafikstil-Zeile im GDD ändert Claude nur mit Klaus' OK.

## Offen

- Szenario-Tests aus gespeicherten Proben, siehe Ideensammlung vom 2026-10-21.
