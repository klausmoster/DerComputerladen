---

description: "Taskliste für Feature 010 Ladeneröffnung"
---

# Tasks: Ladeneröffnung

**Input**: Design-Dokumente aus `specs/010-ladeneroeffnung/`

**Prerequisites**: plan.md, spec.md, research.md (R1 bis R17), data-model.md, contracts/
(ladenwahl.md, spielbildschirm.md, spielstand.md, game_bible.md), quickstart.md,
checklists/review.md, recherche-geld.md

**Tests**: GUT-Tests gehören zu jeder `[A]`-Aufgabe mit Code (Verfassung VI, „Was sich messen lässt,
prüfen Tests“): Kerne ohne Szene, Bausteine in Probeszenen, Büro und Spielbildschirm mit eigener
Session und eigenem Ordner. Vor jeder Abnahme alle grün, zweimal hintereinander mit derselben Zahl
von Prüfungen; dazu die Startprobe. Der Importer hat eigene Tests mit `unittest`.

**Organization**: Die Tasks folgen den neun Phasen aus plan.md, „Prüfer je Phase“, danach der
Abschluss. Umgesetzt wird nach Grundsatz II der Verfassung: eine Phase nach der anderen, nur auf
Klaus' Auftrag, `/speckit-implement` nie. Große Phasen (3, 6) laufen in zwei Teilen, erst der Kern,
dann der Rest, dazwischen prüft Claude (`ki_dev.md`, Punkt 4). Kürzel wie „CHK030“ verweisen auf
[review.md](checklists/review.md), „R14“ auf [research.md](research.md). Nach der Analyse vom
2026-10-29 kamen T002a und T002b dazu; T013, T025, T047, T048 und T053 sind genauer (Befunde D1,
D2, C1, K1, von Klaus nach Empfehlung freigegeben).

## Format: `[ID] [Besitzer] [P?] [Story] Beschreibung`

- **Besitzer**:
  - `[K]` Klaus: Entscheidungen, Wahl von Namen und Texten, Freigaben, Abnahmen, Bildauswahl, was er
    selbst bauen will.
  - `[A]` Godot-Agent `godot-entwickler`: Szenen, GDScript, Tests, Lernnotizen in `lernnotizen.md`.
  - `[C]` Claude: game_bible, Werkzeuge außerhalb von Godot (Importer, Platzhalter), Style-Guide,
    Leonardo über `dcl-grafik`, Phasenprüfung, Review, Doku, Commits.
- **[P]**: kann parallel laufen (andere Dateien, keine offene Abhängigkeit)
- **[Story]**: User Story aus spec.md: US1 Einen Laden aussuchen, US2 Mieten, anmelden, eröffnen,
  US3 Im eigenen Laden stehen, US4 Die Miete geht ab, US5 Spielstände von vorher

## Path Conventions

- Godot-Projekt unter `src/`: Kerne `src/core/shop/`, Spielstand `src/core/save/`, Daten
  `src/data/`, Bausteine `src/ui/adventure/`, `src/ui/paper/`, `src/ui/frame/`, `src/ui/bar/`, Büro
  `src/scenes/opening/`, Spielbildschirm `src/scenes/game/`, Bilder `src/assets/images/buero/` und
  `src/assets/images/laeden/`, Tests `src/test/`, Selbsttest `src/tools/selbsttest/`
- game_bible: `docs/game_bible/Templates/`, `Stadt/`, `Läden/`, `Figuren/`
- Werkzeuge: `tools/bible/importiere.py`, `tools/raster/platzhalter.py`, `tools/build/baue_alles.sh`
- Tests: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd`
- Style-Guide: `docs/style-guide/` im Repo (seit 2026-10-29, Verfassung 3.0.1): `README.md`,
  `tokens.md` und `tokens.json` (immer beide zusammen), `sprache.md`, `ton.md`, `werkzeuge.md`,
  `leonardo-workflow.md`, Bausteine je Datei unter `bausteine/`, Vorschau optional unter `vorschau/`
- Bildkatalog: `docs/art/bildkatalog.md`, gepflegt von `dcl-grafik` zusammen mit dem Prompt-Log

---

## Phase 1: Vorbereitung

**Purpose**: Godot-Doku bereit, Leitfaden auf die neuen Schichten gestellt.

- [x] T001 [C] Godot-Doku im Arbeitsordner bereitlegen, immer die erste Aufgabe: Fehlt
  `godot_referenz/`, `tools/godot_referenz/erzeuge.sh --texte --handbuch` laufen lassen
  (`docs/ki_workflow/ki_dev.md`, „Werkzeuge und Pfade“). Erledigt beim Plan am 2026-10-29: Godot
  4.7.2 liegt in `godot_referenz/`.
- [ ] T002 [C] In `docs/architektur-leitfaden.md` den Stand von AR-16 bis AR-20 von „gilt ab dem
  ersten Feature der Schicht …“ auf „gilt seit 2026-10-29, Klaus (Feature 010)“ setzen; die Kopfzeile
  „Stand“ nachziehen (plan.md, „Ausnahmen vom Leitfaden“, Hinweis).
- [ ] T002a [C] Frage 16 aus research.md, R14 vorziehen, nur den Teil zum Minuszeichen: „-“ oder
  „−“ in Beträgen, nach den Zeichen, die Ark Pixel und Doto haben; als Auswahl mit Empfehlung
  (Analyse, D1). Antwort in R14 und im Style-Guide, Abschnitt „Sprache“.
- [ ] T002b [K] Das Minuszeichen aus T002a entscheiden.
- [ ] T003 [K] Phase 1 abnehmen: den Diff des Leitfadens lesen, dazu die Antwort aus T002b.

---

## Phase 2: Inhalt (game_bible, Namen, Figuren) — Grundlage für US1, US2

**Goal**: Stadt, vier Läden, Makler und Ladenbesitzer stehen in der game_bible, mit von Klaus
gewählten Namen und Texten (FR-001b, FR-001c, FR-005, FR-006, FR-008, FR-012; R16, R17).

**Independent Test**: Jede neue Notiz hat genau die Felder ihrer Vorlage; `regenerate_tables.py`
läuft ohne Fehler; `Figuren.md` und `Läden.md` listen alle Einträge.

- [ ] T004 [C] Vorlagen nach contracts/game_bible.md anlegen: `docs/game_bible/Templates/TEMPLATE_Laden.md`,
  `TEMPLATE_Stadt.md`, `TEMPLATE_Figur.md`, je mit den Feldern aus dem Vertrag und den geschützten
  Abschnitten `## +Hintergrund`, `## +Notizen`.
- [ ] T005 [C] Vorschläge schreiben, als eine Datei `specs/010-ladeneroeffnung/vorschlaege-inhalt.md`:
  je drei Namen für die Stadt (fiktiv, westdeutsch, kein Treffer bei echten Orten über 10.000
  Einwohnern, geprüft per Websuche), Straßen und Hausnummern der vier Läden, Titel, Beschreibung und
  Kleingedrucktes je Laden (FR-012: fester Text, Vor- und Nachteile, keine Ereignisse), zwei
  Steckbriefe für den Makler (Name, Alter, Optik, Sprechweise, Charakter) mit je allen Sätzen zu den
  Anlässen aus data-model.md, „Anlässe des Maklers“. Der Text-Prüfer liest die Datei gegen
  „Sprache“, Claude prüft die Befunde nach.
- [ ] T006 [K] Aus T005 wählen und freigeben: Stadt, Straßen, Texte der Läden, Makler mit Sätzen.
  Änderungen sagt Klaus direkt dazu.
- [ ] T007 [C] Notizen nach T006 anlegen: `docs/game_bible/Stadt/<Name>.md`, vier unter
  `docs/game_bible/Läden/` mit Beträgen aus spec.md, FR-020 (`preise_miete` mit `datum: "1985-01"`,
  `von` = `bis`; `quelle_miete` auf recherche-geld.md), `docs/game_bible/Figuren/Makler.md`.
- [ ] T008 [C] `docs/game_bible/Figuren/Ladenbesitzer.md` aus dem Style-Guide
  (`docs/style-guide/README.md`, „Szenen und Figuren“) anlegen; `bild_katalog` verweist auf F-01 im
  Bildkatalog (CHK020, R16).
- [ ] T009 [C] Übersichten: `docs/game_bible/Figuren.md` (Name, Rolle, Alter, Optik in einem Satz,
  Vorkommen, Verweis auf den Bildkatalog; FR-001c) und `docs/game_bible/Läden.md`; dann
  `python3 -I docs/game_bible/regenerate_tables.py docs/game_bible` für die Tabellen.
- [ ] T010 [C] Phasenprüfung Phase 2 mit `/dcl-phasenpruefung`, Prüfer Text, über die neuen Notizen;
  vor Klaus' Abnahme (`docs/ki_workflow/ki_pruefung.md`).
- [ ] T011 [K] Phase 2 abnehmen: Notizen und Übersichten in Obsidian ansehen.

---

## Phase 3: Kern (Daten, Konto, Eröffnung, Spielstand) — US1, US2, US4, US5

**Goal**: Alles ohne Oberfläche: Daten aus der game_bible im Spiel, Regeln für Geld und Namen, der
Ablauf der Eröffnung als Kern, das Konto mit Miete, der Spielstand mit Laden, `GameSession` mit
Eröffnung und Konto (R2 bis R7, R12, R15).

**Independent Test**: Alle Tests grün, zweimal gleich; `test_shop_account.gd` und
`test_game_session.gd` belegen 179 Mieten und den Kontostand auf den Pfennig (SC-003), Fortsetzen an
drei Tagen ohne Unterschied (SC-004); `test_fahrplan_laden.gd` belegt den bytegleichen Fahrplan
(SC-005); ein Spielstand ohne `shop` ist beschädigt (US5).

### Teil 1: Daten und Regeln

- [ ] T012 [P] [A] [US1] `ShopRules` in `src/core/shop/shop_rules.gd` nach data-model.md,
  „Stellschrauben“: `START_CAPITAL` je Grad in Pfennig (Leicht 10.000.000, Mittel 6.000.000,
  Schwer 3.000.000), `DEPOSIT_MONTHS = 3`, `PROOF_MONTHS = 6`, `LEASE_START_DAY` aus
  `TimelineRun.FIRST_DAY` abgeleitet, `RENT_FREE_MONTHS = 1` (CHK040); statische `deposit()`,
  `proof()`, `affordable()`. Test `src/test/test_shop_rules.gd` mit der Tabelle „bezahlbar je Grad“.
- [ ] T013 [P] [A] [US3] `Money` in `src/core/shop/money.gd`: Pfennig → „25.680,00 DM“, negativ mit
  Minus und SOLL nach dem Baustein Anzeige (das Minuszeichen aus T002b); Test `src/test/test_money.gd`
  mit 0, 1, 99, 100, 2.568.000, −23.208.000 Pfennig.
- [ ] T014 [P] [A] [US1] Datenklassen als `Resource` mit `class_name`: `ShopOffer`
  (`src/core/shop/shop_offer.gd`, Felder aus data-model.md, `enum Level { LOW, MEDIUM, HIGH }` mit
  den Schlüsseln „niedrig“, „mittel“, „hoch“, `image_path(id, art)` für „aussen“, „innen“, „ort“,
  `load_by_id(id)`; CHK041, CHK044), `CityData` (`city_data.gd`), `FigureData` (`figure_data.gd`,
  `OCCASIONS` als Konstante, `lines` als Dictionary Anlass → PackedStringArray). Geladene Resources
  werden nie beschrieben (AR-04). Tests mit eigenen `.tres` unter `src/test/fixtures/laeden/`.
- [ ] T015 [C] [US1] Importer `tools/bible/importiere.py` nach contracts/game_bible.md: liest Stadt,
  Läden, Figuren, schreibt `src/data/stadt.tres`, `src/data/laeden/<id>.tres`,
  `src/data/figuren/<id>.tres`, kanonisch, mit Kopfkommentar; `--pruefen`; Fehler mit Datei und Feld;
  Pfennig mit Ganzzahlen, Kommabeträge abgelehnt (CHK047); der Kopf nennt `ShopOffer`, `CityData`,
  `FigureData`, `FigureData.OCCASIONS`, `ShopOffer.Level`, `ShopOffer.image_path()` (CHK041). Tests
  `tools/bible/test_importiere.py` mit Beispielnotizen unter `tools/bible/fixtures/`. Danach einmal
  laufen lassen und die erzeugten Dateien committen.
- [ ] T016 [C] `tools/build/baue_alles.sh`: vor dem Bau `python3 -I tools/bible/importiere.py
  --pruefen`, bei einem Unterschied Abbruch mit Satz (CHK015, FR-008).
- [ ] T017 [A] [US1] `test_daten_laeden.gd` in `src/test/`: liest die erzeugten Daten, vier Läden in
  fester Reihenfolge, Beträge wie spec.md, FR-020, auf „Schwer“ genau die Fußgängerzone nicht
  mietbar, auf „Mittel“ und „Leicht“ keiner (SC-002); jeder Anlass aus `FigureData.OCCASIONS` hat
  beim Makler mindestens einen Satz.
- [ ] T018 [P] [A] [US2] `ShopName` in `src/core/shop/shop_name.gd` nach data-model.md, „ShopName“:
  säubern, „1 bis `MAX_LENGTH` = 24 Zeichen nach dem Säubern“, `ALLOWED` „A–Z, a–z, ÄÖÜäöüß, 0–9,
  Leerzeichen, `. , - & ' / + ( )`“ ohne „!“ und „?“ (CHK026), `REASON_EMPTY` „Der Laden braucht
  einen Namen.“, `REASON_SIGN` „Nur Buchstaben, Ziffern und einfache Satzzeichen.“ (CHK023). Test
  `src/test/test_shop_name.gd`, dazu: Ark Pixel 10 und 12 haben jedes Zeichen aus `ALLOWED`.

### Teil 2: Eröffnung, Konto, Spielstand, GameSession

- [ ] T019 [A] [US1] [US2] `ShopOpening` in `src/core/shop/shop_opening.gd` nach data-model.md:
  `enum Step { MAP, EXPOSE, LEASE, REGISTRATION }`, Felder „Nur lesen.“, `typed_name` (CHK008),
  Vorwahl erster bezahlbarer (CHK003), `open_expose()`, `next()`, `previous()` im Kreis auch über
  nicht mietbare, `choose()` mit `ERR_UNAVAILABLE`, `sign()`, `back()`, `check_name()`, `finish()`.
  Test `src/test/test_shop_opening.gd` mit jedem Übergang des Zustandsdiagramms.
- [ ] T020 [P] [A] [US2] `ShopLease` in `src/core/shop/shop_lease.gd`: Datenobjekt mit den Feldern
  und JSON-Schlüsseln aus data-model.md, „ShopLease“; `to_dict()`, `from_data()` mit Prüfung.
- [ ] T021 [A] [US4] `ShopAccount` in `src/core/shop/shop_account.gd` nach data-model.md:
  `opened()`, `month_begins(date)`, `to_dict()`, `from_data()`; Test `src/test/test_shop_account.gd`:
  eine Buchung je Erstem ab 01.02.1985, keine doppelte, 179 bis 31.12.1999 mit Kontostand
  −23.208.000 Pfennig im Stadtteilzentrum auf Schwer (SC-003).
- [ ] T022 [A] [US2] [US5] `SaveGame` in `src/core/save/save_game.gd`: Pflichtschlüssel `shop` und
  `account`, `REQUIRED_KEYS` erweitert, Prüfungen aus data-model.md, „SaveGame — Änderungen“ mit
  `REASON_FILE_PART`; `FORMAT` bleibt 1 mit dem Kommentar
  `# Ausnahme AR-13: vor der ersten Herausgabe keine Rücksicht auf alte Spielstände (Klaus, 2026-10-29)`.
  Fixtures unter `src/test/fixtures/spielstaende/` bekommen `shop` und `account`; eine Fixture ohne
  belegt „beschädigt“ (US5). `src/test/test_save_game.gd` erweitert.
- [ ] T023 [C] In `docs/architektur-leitfaden.md`, Tabelle „Ausnahmen“, die Zeile zu AR-13 aus
  plan.md eintragen (CHK038).
- [ ] T024 [A] [US2] `SaveGameFactory.new_game()` in `src/core/save/save_game_factory.gd` nach
  contracts/spielstand.md; der Fahrer des Selbsttests (`src/tools/selbsttest/selbsttest_fahrer.gd`)
  baut neue Spielstände nur noch darüber (R12, behebt B4 aus 11-09).
- [ ] T025 [A] [US2] [US4] `GameSession` in `src/core/game_session.gd` nach data-model.md,
  „GameSession — Änderungen“: `opening`, `account` („Nur lesen.“), `begin_opening()` mit
  `ERR_ALREADY_IN_USE` bei laufendem Spiel (CHK046), `end_opening()`, `start_new(shop_name, seed)`,
  `account_changed`, Konto an `month_passed` der Uhr, Werte des Kontos beim Speichern in den
  Spielstand, beim Fortsetzen daraus neu; `leave()` hält die Uhr an. Dazu `GameClock.set_speed()` in
  `src/core/game_clock.gd` (CHK039). `src/test/test_game_session.gd`: Mieten über Speichern und
  Fortsetzen an einem Ersten, am Tag davor und am 15.03.1985 gleich (SC-004); nichts geschrieben vor
  `start_new()` (SC-007); ein Spiel über 15 Jahre mit Konto im Test vorgespult in unter 2 s
  (plan.md, „Performance Goals“; Analyse, C1).
- [ ] T026 [A] Übergang bis Phase 6, damit das Spiel startbar bleibt: `TitleScreen._start_new()` in
  `src/scenes/title/title_screen.gd` ruft `begin_opening(grad)`, nimmt den vorgewählten Laden, und
  `start_new(SaveGame.default_name(n))`. Mit dem Kommentar `# Übergang bis T047 (Feature 010)`;
  T047 entfernt ihn, `test_title_screen.gd` angepasst.
- [ ] T027 [P] [A] `src/test/test_architektur.gd`: `res://core/shop/` in `KERNORDNER` (CHK042).
- [ ] T028 [P] [A] [US1] `src/test/test_fahrplan_laden.gd`: Fahrplan für Seeds 1, 4711, 99999 in
  allen drei Graden bytegleich zu einer eingefrorenen Ausgabe von vor Feature 010, je mit jedem der
  vier Läden (SC-005, R15).
- [ ] T029 [C] Phasenprüfung Phase 3 mit `/dcl-phasenpruefung`, Prüfer Architektur und Text; vor
  Klaus' Abnahme.
- [ ] T030 [K] Phase 3 abnehmen nach quickstart.md, „Automatische Tests“ und „Startprobe“; dazu ein
  neues Spiel über den Übergang aus T026.

---

## Phase 4: Style-Guide — Vorarbeit für Phase 5 bis 8

**Goal**: Der Style-Guide regelt alles, was Büro, Blätter und Spielbildschirm zeigen (Verfassung IV;
R14 mit 16 Fragen).

**Independent Test**: Jede Frage aus R14 hat eine Antwort im Style-Guide; die Verträge nennen keine
Werte mehr, die nur dort stehen dürften.

- [ ] T031 [C] Die 16 Fragen aus research.md, R14 einzeln mit Klaus klären, je als Auswahl mit
  Empfehlung zuerst und Beispiel; Antworten mit Datum in research.md, R14.
- [ ] T032 [K] Die Fragen aus T031 entscheiden.
- [ ] T033 [C] Style-Guide ergänzen nach T032: neue Bausteine Anklickbare Stelle, Sprechblase,
  Blatt (mit Stempel, Unterschrift, Kleingedrucktem), Eingabefeld, Markierung (mit „nicht
  mietbar“, CHK030); geändert Bedienleiste (Uhr statt Weiter-Pfeil, Ortsbild ohne Klick, Lage von
  „Zum Hauptmenü“), Anzeige (Größe, Blinken, `zeile-klein`), README (Szene Büro, Ladenname im Bild),
  Sprache (Papiere der Spielwelt, Minus). In den Dateien unter `docs/style-guide/`: ein neuer
  Baustein bekommt `bausteine/<name>.md`, Tokens immer in `tokens.md` und `tokens.json` zugleich.
  Vorher `main` in den Branch holen, falls dort am Style-Guide gearbeitet wurde.
- [ ] T034 [K] Die Ergänzungen im Style-Guide freigeben.
- [ ] T035 [C] Verträge an den Style-Guide angleichen: Werte aus `contracts/ladenwahl.md` und
  `contracts/spielbildschirm.md`, die jetzt im Style-Guide stehen, durch Verweise ersetzen; Tasten
  in die Wortlaute der Tooltips (CHK024).

---

## Phase 5: Bausteine und Platzhalter — US1, US3

**Goal**: Die Bausteine ohne Inhalt, je in einer Probeszene, und alle Bilder als Platzhalter an
ihren endgültigen Pfaden (R8, R11).

**Independent Test**: Jede Probeszene läuft mit F6; Tests der Bausteine grün; alle Pfade aus
data-model.md haben eine Datei.

- [ ] T036 [C] `tools/raster/platzhalter.py`: Platzhalter nach R11 für `buero/buero.png`,
  `buero/makler.png`, `buero/stadtplan.png` und je Laden `<id>_aussen.png`, `<id>_innen.png`
  (312 × 144), `<id>_ort.png` (60 × 28), Größen aus dem Style-Guide; Farben aus der Hauptpalette;
  laufen lassen, Dateien und `.import` committen.
- [ ] T037 [P] [A] [US1] `Hotspot` in `src/ui/adventure/hotspot.tscn` / `.gd` nach Style-Guide,
  Baustein Anklickbare Stelle: Fläche, Tooltip, Mauszeiger, `signalgelb`, Fokus, Rechtsklick zeigt
  nur den Tooltip, Signal `activated`; kennt keinen Inhalt (AR-18). Probeszene unter
  `src/test/fixtures/`, Test `test_hotspot.gd`.
- [ ] T038 [P] [A] [US1] `SpeechBubble` in `src/ui/adventure/speech_bubble.tscn` / `.gd` nach
  Style-Guide; Probeszene, Test `test_speech_bubble.gd`.
- [ ] T039 [P] [A] [US1] `PaperSheet` in `src/ui/paper/paper_sheet.tscn` / `.gd` nach Style-Guide,
  Baustein Blatt: Inhalt von außen, „Zurück“ und höchstens eine Handlung, Signale; Probeszene, Test
  `test_paper_sheet.gd`.
- [ ] T040 [P] [A] [US3] `PictureFrame` in `src/ui/frame/` und `ControlBar` in `src/ui/bar/` nach den
  Bausteinen Bildrahmen, Bedienleiste und Anzeige: bekommen Bild, Texte und Zustand der Uhr hinein,
  melden Pause und Tempo per Signal, kennen weder `GameClock` noch `ShopLease` (CHK045). Probeszenen,
  Tests `test_picture_frame.gd`, `test_control_bar.gd`.
- [ ] T041 [C] Phasenprüfung Phase 5, Prüfer Stil und Architektur, mit Fotos der Probeszenen.
- [ ] T042 [K] Phase 5 abnehmen: Probeszenen ansehen.

---

## Phase 6: Büro des Maklers — US1, US2 🎯 MVP

**Goal**: Von der Gradwahl über Stadtplan, Exposé, Mietvertrag und Anmeldung in den Laden, mit
Maus und Tastatur, mit den Sätzen des Maklers (FR-001 bis FR-019).

**Independent Test**: quickstart.md, „Von Hand“, Schritte 1 bis 5 und 11; `test_broker_office.gd`
grün.

### Teil 1: Szene und Blätter

- [ ] T043 [A] [US1] `OpeningTexts` in `src/scenes/opening/opening_texts.gd` mit allen Wortlauten aus
  contracts/ladenwahl.md, „Wortlaute“ (CHK021, CHK023, CHK024, CHK025).
- [ ] T044 [A] [US1] `BrokerOffice` in `src/scenes/opening/broker_office.tscn` / `.gd`: Büro mit
  Hotspots Stadtplan, Schreibtisch, Makler; hält `ShopOpening` aus `GameSession.opening` (Naht
  `session`, AR-12) und reicht es den Blättern hinein (CHK045); Phase der Eingabe als `enum`;
  Sätze des Maklers mit Zähler je Anlass im Büro (CHK043); Tastaturreihenfolge aus dem Vertrag
  (CHK014).
- [ ] T045 [P] [A] [US1] Blätter `city_map`, `expose` in `src/scenes/opening/` nach
  contracts/ladenwahl.md, „Blätter“: Markierungen mit Zustand „nicht mietbar“, die trotzdem das
  Exposé öffnen (CHK030); Exposé mit Stempel und Vermerk, Blättern.
- [ ] T046 [P] [A] [US2] Blätter `lease_contract`, `registration` in `src/scenes/opening/`:
  Unterschrift, Namensfeld (`LineEdit`, `max_length` 24, unerlaubte Zeichen nicht angenommen),
  Grund als Text unter dem Feld, „Anmelden“ aus bis zum gültigen Namen, Meldung links neben
  „Anmelden“ (CHK033).

### Teil 2: Anbindung und Tests

- [ ] T047 [A] [US1] [US2] Titel anbinden in `src/scenes/title/title_screen.gd`: Gradwahl ruft
  `begin_opening()`, nach der Fahrt hinaus `OPENING_SCENE`; Rückkehr vom Stadtplan zeigt die Gradwahl
  mit dem Grad vorgewählt und ruft `end_opening()`; den Übergang aus T026 entfernen. Den Fahrer des
  Selbsttests (`src/tools/selbsttest/selbsttest_fahrer.gd`) und seine Tests mitziehen, damit sie
  grün bleiben; die Knotennamen sind seine Schnittstelle (Leitfaden, „Werkzeuge“; Analyse, D2).
  Neue Schritte im Selbsttest kommen erst in T064.
- [ ] T048 [A] [US1] [US2] `src/test/test_broker_office.gd`: jeder Weg aus dem Vertrag mit Maus und
  Tastatur, Esc und „Zurück“ aus jedem Schritt, Name bleibt beim Zurückgehen (CHK008), kein
  Spielstand vor „Anmelden“ an jeder Stelle (SC-007), scheiterndes Speichern zeigt die Meldung;
  jedes Blatt erscheint in unter 0,2 s (SC-001); immer ein Blatt vorn und die Anlässe des Maklers
  nach der Tabelle im Vertrag; im Titel steht der Kommentar „Übergang bis T047“ nicht mehr
  (Analyse, K1).
- [ ] T049 [A] [US2] `src/test/test_title_texts.gd`: Hinweise, Rückfrage und „{Name} löschen“ mit dem
  breitesten erlaubten Namen aus 24 Zeichen messen (CHK027, SC-006). Passt einer nicht, hält der
  Agent an; Klaus entscheidet über eine kleinere `ShopName.MAX_LENGTH`.
- [ ] T050 [C] Phasenprüfung Phase 6, Prüfer Stil, Text und Architektur, mit Fotos aus dem echten
  Fenster in Klaus' Fenstergröße.
- [ ] T051 [K] Phase 6 abnehmen nach quickstart.md, „Von Hand“, Schritte 1 bis 5 und 11.

---

## Phase 7: Spielbildschirm — US3, US4

**Goal**: Der eigene Laden mit Bildrahmen, Leiste, Leuchtanzeige und Uhr; die Miete sichtbar
(FR-024 bis FR-027a; contracts/spielbildschirm.md).

**Independent Test**: quickstart.md, „Von Hand“, Schritte 6 bis 9 und 12.

- [ ] T052 [A] [US3] `GameScreenTexts` in `src/scenes/game/game_screen_texts.gd` mit den Wortlauten
  aus contracts/spielbildschirm.md.
- [ ] T053 [A] [US3] [US4] `GameScreen` in `src/scenes/game/game_screen.tscn` / `.gd` nach dem
  Vertrag: `PictureFrame` mit dem Inneren des Ladens, Ladenname nach Style-Guide, `ControlBar` mit
  Ortsbild, Leuchtanzeige und Uhr; Naht `clock` (CHK039); erscheint angehalten; Tempi
  `SPEEDS = [1.0, 2.0, 7.0]` über `set_speed()`; Leertaste gehört der Uhr (CHK035); Datum blinkt bei
  laufender Uhr nicht, Kontostand bei jeder Buchung (CHK034); am Ende Uhr aus ohne Tooltip
  (CHK031); „Zum Hauptmenü“ mit Tooltip statt Hinweis, Meldung links daneben (CHK032). Fahrer
  des Selbsttests und seine Tests mitziehen, er liest `LeaveButton` und `MenuHint` des
  Spielbildschirms (Analyse, D2).
- [ ] T054 [A] [US3] [US4] `src/test/test_game_screen.gd`: Laden, Name, Datum mit Wochentag,
  Kontostand; Buchung am Ersten im selben Bild; SOLL bei negativem Kontostand; Leertaste; Fortsetzen
  zeigt denselben Stand angehalten.
- [ ] T055 [C] Phasenprüfung Phase 7, Prüfer Stil, Text und Architektur, mit Fotos aus dem echten
  Fenster.
- [ ] T056 [K] Phase 7 abnehmen nach quickstart.md, „Von Hand“, Schritte 6 bis 9 und 12.

---

## Phase 8: Bilder — US1, US3

**Goal**: Die Platzhalter durch die echten Bilder ersetzt, nach dem Leonardo-Workflow, und der Makler
mit Figurenblatt im Bildkatalog (Verfassung IV, R11, R16).

**Independent Test**: Keine Datei unter `src/assets/images/buero/` und `laeden/` ist noch ein
Platzhalter; jedes Bild steht im Prompt-Log und im Bildkatalog.

- [ ] T057 [C] Figurenblatt des Maklers mit `dcl-grafik` nach seinem Steckbrief; Klaus wählt aus;
  `dcl-grafik` trägt ihn ins Prompt-Log und in den Bildkatalog unter „Figuren“ ein, mit Aussehen und
  festem Prompt-Baustein wie den Ladenbesitzer; `bild_katalog` in
  `docs/game_bible/Figuren/Makler.md` verweist darauf.
- [ ] T058 [K] Figurenblatt des Maklers auswählen.
- [ ] T059 [C] Büro (mit dem Makler aus T057 als Referenz), Stadtplan, vier Läden von außen, vier
  leere Läden von innen mit `dcl-grafik`, gerastert, je mit Eintrag im Prompt-Log und im Bildkatalog
  (Orte und Szenen); die vier Ausschnitte `<id>_ort.png` ohne Skalierung aus den Fotos (CHK028).
- [ ] T060 [K] Die Bilder aus T059 auswählen.
- [ ] T061 [A] [US1] Markierungen und Hotspots in `city_map.tscn` und `broker_office.tscn` an die
  echten Bilder setzen; Test, dass kein Platzhalter mehr da ist (CHK036).
- [ ] T062 [C] Phasenprüfung Phase 8, Prüfer Stil, mit Fotos.
- [ ] T063 [K] Phase 8 abnehmen: Büro, Stadtplan, Exposés und Spielbildschirm ansehen.

---

## Phase 9: Selbsttest-Abläufe

**Goal**: Jede neue Seite, jeder Weg, Text und jede Eingabe hat einen Schritt im Selbsttest
(`ki_dev.md`, Punkt 11; R12).

- [ ] T064 [A] Selbsttest-Abläufe anpassen in `src/tools/selbsttest/ablaeufe/`: `neues_spiel` endet
  im Büro; neuer Ablauf `ladenwahl` durch Stadtplan, nicht mietbares Exposé auf Schwer, Blättern,
  Mietvertrag, Anmeldung mit leerem und festem Namen bis in den Laden, Uhr eine Woche laufen
  lassen, Zeit von der Gradwahl bis zum Laden unter 60 s (SC-001); `laden`, `liste`, `loeschen` mit
  Spielständen aus der Fabrik; Texte in `SelbsttestTexte`.
- [ ] T065 [C] Phasenprüfung Phase 9, Prüfer Architektur und Text.
- [ ] T066 [K] Phase 9 abnehmen: Selbsttest auf dem Mac laufen sehen.

---

## Abschluss

- [ ] T067 [C] Bestandsprüfung mit dem Architektur-Prüfer über ganz `src/`, weil mit diesem Feature
  die Schichten Adventure und Wirtschaft beginnen; vor der Lückensuche
  (`docs/ki_workflow/ki_pruefung.md`). Befunde und Lücken in `docs/offene-punkte.md`; Klaus
  entscheidet, was behoben wird.
- [ ] T068 [C] Lückensuche mit `/speckit-converge`: Spec, Plan, Verträge und Aufgaben gegen den Code,
  die Prüfer einmal über das ganze Feature; Lücken als neue Phase mit Klaus' Freigabe.
- [ ] T069 [C] Phasenprüfung einer Lücken-Phase, nur wenn sie Sichtbares, Texte oder Code ändert,
  mit den Prüfern aus plan.md; vor der Gesamtabnahme.
- [ ] T070 [C] Selbsttest zur Gesamtabnahme: `tools/build/baue_alles.sh`, Lauf auf dem Mac,
  `tools/selbsttest/vergleich.py`; Ergebnis in der Bitte um Gesamtabnahme; neue Referenzbilder nur
  nach Klaus' Abnahme.
- [ ] T071 [K] Selbsttest auf Windows und Linux starten: Das Feature ändert Eingabe (Texteingabe),
  Grafik und Dateien (Spielstand).
- [ ] T072 [K] Gesamtabnahme nach dem ganzen quickstart.md; alle Abnahmen T003, T011, T030, T034,
  T042, T051, T056, T063, T066 sind erledigt.
- [ ] T073 [C] Spielbeschreibung prüfen (immer die letzte Aufgabe des Features, nach der
  Gesamtabnahme und vor dem Merge; `docs/ki_workflow/ki_dev.md`, „Ablauf je Feature“): Claude
  gleicht `docs/spielbeschreibung/` mit dem Code ab und legt Klaus eine Liste vor, welche Dateien
  veralten und welche neu angelegt werden sollten, mit Grund, etwa eine neue Datei zu Laden und
  Konto. Abweichungen zwischen Spec und Code gehören dazu. Geändert wird erst nach Klaus' OK.
- [ ] T074 [C] Doku zum Abschluss: `docs/features/Features.md` (Zeile 010, Stand der Systeme 03, 05,
  10, 11), `docs/features/Feature_Ideas.md` (05-01 gebaut), `docs/game_design.md` (§5 Verweis,
  offene Frage zu Startkapital und Graden), Tagebuch mit Token und Kosten
  (`tools/tagebuch/token_bilanz.py feature/010-ladeneroeffnung`); Klaus nimmt ab, Merge auf sein
  Wort.

---

## Abdeckung der Anforderungen

| Anforderung | Tasks |
|---|---|
| FR-001, FR-001a, FR-002, FR-004 | T037, T044, T047, T048 |
| FR-001b, FR-001c | T005 bis T009, T014, T044, T057 |
| FR-003, SC-007 | T025, T048 |
| FR-005 bis FR-008 | T004 bis T009, T014 bis T017 |
| FR-009, FR-010 | T045, T061 |
| FR-011 bis FR-014 | T045 |
| FR-015 | T046 |
| FR-016 bis FR-019, SC-006 | T018, T046, T049 |
| FR-020 bis FR-022, SC-002 | T007, T012, T017, T019 |
| FR-023, FR-029, SC-003, SC-004 | T021, T025 |
| FR-024, FR-025 | T013, T053 |
| FR-026 bis FR-027a | T040, T053, T054 |
| FR-028, FR-030, FR-031 | T020, T022 |
| FR-032, SC-005 | T028 |
| SC-001 | T048, T064 |

---

## Dependencies & Execution Order

- **Phase 1** zuerst; **Phase 2** vor Phase 3, weil der Importer die Notizen braucht.
- **Phase 3** vor allen Oberflächen-Phasen. Teil 1 (T012 bis T018) vor Teil 2 (T019 bis T028).
- **Phase 4** vor Phase 5 bis 8; sie kann parallel zu Phase 3 laufen, weil sie keinen Code ändert.
- **Phase 5** vor 6 und 7; **Phase 6** vor 7 (der Spielbildschirm braucht ein Spiel mit Laden über
  den echten Weg, bis dahin über den Übergang aus T026).
- **Phase 8** nach 6 und 7; **Phase 9** nach 8, damit die Fotos des Selbsttests die echten Bilder
  zeigen.
- **Abschluss** nach allen Phasen, in der Reihenfolge T067 bis T074.

## Parallel Example: Phase 3, Teil 1

```text
T012 ShopRules        src/core/shop/shop_rules.gd
T013 Money            src/core/shop/money.gd
T014 Datenklassen     src/core/shop/shop_offer.gd, city_data.gd, figure_data.gd
T018 ShopName         src/core/shop/shop_name.gd
```

## Implementation Strategy

- **MVP** ist Phase 6: Danach geht der Weg von der Gradwahl bis in den Laden, mit Platzhaltern.
- `[K]`-Tasks erledigt Klaus selbst. Vor jeder Phase kann er sich `[A]`-Tasks oder Teile davon
  nehmen, die er in Godot lernen will, etwa den Baustein `Hotspot` (T037) oder die Blätter (T045,
  T046); dann trägt die Aufgabe `[K]`.
- Nach jeder Abnahme committet Claude die Phase, ein Commit je Phase.

## Notes

- Jede `[A]`-Aufgabe endet mit einer Lernnotiz in `lernnotizen.md` an der konkreten Stelle
  (Verfassung II).
- Der Agent committet nie; Claude prüft vor jeder Abnahme: Tests zweimal, Startprobe, feste Größen,
  Fotos im echten Fenster bei Oberfläche (`ki_dev.md`, „Prüfen, bevor Klaus es sieht“).
- Geld immer in Pfennig (AR-16); Spielinhalt nur über den Importer (AR-04); Bausteine ohne Inhalt
  (AR-18).
