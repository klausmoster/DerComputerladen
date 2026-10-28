---

description: "Taskliste für Feature 007 Build & Export mit Selbsttest"
---

# Tasks: Build & Export mit Selbsttest

**Input**: Design-Dokumente aus `specs/007-build-export-selbsttest/`

**Prerequisites**: plan.md, spec.md, research.md (R1 bis R27), data-model.md,
contracts/selbsttest-app.md, contracts/ablaeufe.md, contracts/protokoll.md, contracts/vergleich.md,
contracts/export.md, quickstart.md, checklists/review.md

**Tests**: Die Verträge legen GUT-Tests fest (research.md, R23). Sie entstehen mit der Logik und
müssen vor jeder Abnahme grün sein, zweimal hintereinander mit derselben Zahl von Prüfungen. Die
Selbsttest-App selbst prüft Claude im echten Fenster: gebaut, mit `open` gestartet, Protokoll und
Fotos gelesen.

**Organization**: Die Tasks folgen den sieben Phasen aus plan.md, „Umsetzungsphasen“: Phase 1 Kern
ohne Fenster, Phase 2 App im Fenster, Phase 3 alle Abläufe, Phase 4 Zusammenfassung, Phase 5
Vergleich, Phase 6 Windows und Linux, Phase 7 Abschluss. Umgesetzt wird nach Verfassung 2.2.0,
Grundsatz II: eine Phase nach der anderen, nur auf Klaus' Auftrag, `/speckit-implement` nie. Jede
Phase endet mit Klaus' Abnahme; jede Phase mit Sichtbarem oder Texten hat davor die [C]-Aufgabe
„Phasenprüfung“ (plan.md, „Prüfer je Phase“). Kürzel wie „CHK016“ verweisen auf die Checkliste
[review.md](checklists/review.md), „R7“ auf [research.md](research.md). Nach der Analyse kamen T038a,
T041a, T041b, T046a und T048a dazu (plan.md, „Änderungen nach der Analyse“).

## Format: `[ID] [Besitzer] [P?] [Story] Beschreibung`

- **Besitzer**:
  - `[K]` Klaus: Entscheidungen, Freigaben, Abnahmen, Läufe auf Windows und Linux, Downloads.
  - `[A]` Godot-Agent `godot-entwickler`: Szenen, GDScript, Projekteinstellungen, Presets, Tests.
  - `[C]` Claude: Style-Guide, Vergleich, ICO, Bau-Skript, Doku, Phasenprüfung, Review.
- **[P]**: kann parallel laufen (andere Dateien, keine offene Abhängigkeit)
- **[Story]**: User Story aus spec.md (US1 Selbsttest auf dem Mac, US2 Spiel ohne Testcode, US3
  Fotos vergleichen, US4 Windows und Linux, US5 Selbsttest wächst mit)

## Path Conventions

- Godot-Projekt unter `src/`; der Selbsttest unter `src/tools/selbsttest/` (vom normalen Export
  ausgeschlossen, R2); Tests unter `src/test/`, erwartete Protokolle unter
  `src/test/fixtures/selbsttest/`
- Werkzeuge außerhalb von Godot: `tools/selbsttest/` (Vergleich, Referenzbilder), `tools/build/`
  (Bau-Skript), `tools/raster/make_icon.py` (ICO)
- Pfade, Klassen und Signaturen laut den Verträgen unter [contracts/](contracts/)
- Gebaut wird nach `build/` (nicht versioniert); Eingang von anderen Rechnern `build/selbsttest/`
- Werte für Farben, Schriften und Abstände der Zusammenfassung kommen nach T029 aus dem Abschnitt
  „Werkzeuge“ im Style-Guide, nicht aus diesen Tasks (Grundsatz IV)

---

## Phase 1: Kern ohne Fenster (Grundlage für US1)

**Goal**: Lauf, Protokoll, Systemdaten, Ausgabe und Ablage gibt es als Klassen ohne Fenster, mit
Tests; dazu die Stellschraube für die Zeitzone im Spiel (FR-008, FR-013, FR-014, FR-014a, FR-016;
R7, R9 bis R11, R20, R21; contracts/selbsttest-app.md, contracts/protokoll.md).

**Independent Test**: Die neuen GUT-Tests sind grün; ein erfundener Lauf ergibt Byte für Byte das
erwartete Protokoll und den erwarteten Text für „Kopieren“.

- [x] T001 [A] [US1] `src/tools/selbsttest/selbsttest_lauf.gd` (`class_name SelbsttestLauf`) und
  `src/tools/selbsttest/ablaeufe/selbsttest_ablauf.gd` (`class_name SelbsttestAblauf`) laut Vertrag
  und data-model.md: Lauf mit `id` `JJJJ-MM-TT_hh-mm-ss`, `zeitraffer`, Ergebnissen je Schritt
  (`OK`, `FEHLER`, `NICHT_GELAUFEN`), `fokusverluste`, `abbruch` mit Wert `keiner` (CHK038), Summe;
  „Baut ein Ablauf auf einem gescheiterten auf, gilt er ganz als nicht gelaufen, mit Grund“ (FR-009,
  CHK006). `src/test/test_selbsttest_lauf.gd`.
- [x] T002 [A] [US1] `src/tools/selbsttest/selbsttest_texte.gd` (`class_name SelbsttestTexte`) mit
  allen Wortlauten aus contracts/selbsttest-app.md, „Texte“, und
  `src/tools/selbsttest/selbsttest_protokoll.gd` (`class_name SelbsttestProtokoll`) laut
  contracts/protokoll.md: eine Funktion für `protokoll.txt` und den Text für „Kopieren“ (FR-014a),
  UTF-8 ohne BOM, `\n`, feste Schlüssel in fester Reihenfolge, `unbekannt` für fehlende Werte,
  Werte ohne Schlusspunkt außer `ergebnis:`, Ergebniszeile mit Dativ („von 1 Schritt“), Maschinenform
  für Zeiten und Maße (CHK033, CHK034, CHK039). `src/test/test_selbsttest_protokoll.gd` vergleicht
  einen erfundenen Lauf mit je einem Schritt `OK`, `FEHLER`, `NICHT_GELAUFEN` Byte für Byte mit
  `src/test/fixtures/selbsttest/protokoll_erwartet.txt` und `kopieren_erwartet.txt`; dazu „Alles in
  Ordnung“ mit 1 und 37 Schritten und der Text bei nicht beschreibbarem Ordner gegen
  `kopieren_nicht_beschreibbar.txt` (Analyse, U5). Je Schritt eine Zeile `zeitraffer:` (U7).
- [x] T003 [A] [P] [US1] `src/tools/selbsttest/selbsttest_system.gd` (`class_name
  SelbsttestSystem`): alle Schlüssel aus data-model.md, „Systemdaten“, mit `computerladen.version`
  (CHK029); Treiberinfo unter Windows und Linux in einem Thread (R20). `src/test/test_selbsttest_system.gd`:
  jeder Schlüssel ist da, headless darf ein Wert `unbekannt` sein.
- [x] T004 [A] [P] [US1] `src/tools/selbsttest/selbsttest_logger.gd` (`class_name SelbsttestLogger`,
  `extends Logger`): Zeilen mit Schritt-Kennung, `[start]` und `[ende]`, Fehler und Warnungen als
  Meldung des Schritts, eigene als `[selbsttest] …` (CHK007); `Mutex`, gibt selbst nichts aus (R10).
  `src/tools/selbsttest/selbsttest_ablage.gd` (`class_name SelbsttestAblage`): Ordner
  `selbsttest/<lauf-id>/`, Fotos als PNG unter `fotos/`, `protokoll.txt`, `ausgabe.txt`, Zip
  `<lauf-id>_<system>.zip` mit `ZIPPacker`, Fehler „nicht beschreibbar“ mit Pfad (R11). Tests in
  eigenen Ordnern unter `user://`, nie in `user://spielstaende/`.
- [x] T005 [A] [US1] `src/core/save/save_game.gd`: statische Stellschraube für den
  Zeitzonenversatz, Vorgabe „wie der Rechner“ (R7). `src/test/test_save_game.gd` erweitert; alle
  bisherigen Tests bleiben unverändert grün.
- [x] T006 [A] [US1] Lernnotizen zu T001 bis T005: Klassen ohne Node wie `TimelineRun`, ein
  Formatierer für zwei Ausgaben, `Logger` und Threads, `ZIPPacker`, statische Stellschraube statt
  Abhängigkeit des Spiels vom Selbsttest.
- [x] T007 [C] [US1] Prüfen: Tests zweimal mit gleicher Zahl, Startprobe still; Fehlerprobe in einer
  Kopie: Reihenfolge der Schlüssel, Dativ, fehlender Schlüssel, falscher Zeitzonenversatz; die Tests
  finden jeden.
- [x] T008 [C] Phasenprüfung Phase 1 mit `/dcl-phasenpruefung`, Text-Prüfer über die Protokolle aus
  den Fixtures und `SelbsttestTexte` (plan.md, „Prüfer je Phase“); Maßstab zusätzlich CHK030 und
  CHK039 aus review.md, bis sie in Phase 4 im Style-Guide stehen (Analyse, I4); vor Klaus' Abnahme
  (`docs/ki_workflow/ki_pruefung.md`).
- [x] T009 [K] [US1] Phase 1 abnehmen: Diff, Lernnotizen, Testergebnis, ein Beispielprotokoll.

Erledigt am 2026-10-28, von Klaus abgenommen: `SelbsttestLauf`, `SelbsttestTexte`,
`SelbsttestProtokoll`, `SelbsttestSystem`, `SelbsttestLogger`, `SelbsttestAblage` und
`SelbsttestAblauf` unter `src/tools/selbsttest/`; `SaveGame.time_zone_bias` für die Zeitzone. 78 neue
Tests in fünf Skripten, drei Fixtures mit den erwarteten Protokollen. Zweimal 1212 von 1212 Tests grün
(187 088 Prüfungen), Startprobe still, Fehlerprobe 4 von 4. Phasenprüfung: Text 1 Befund im Vertrag
(behoben), 4 Lücken, von Claude geklärt. Auslegungen in research.md, „Auslegungen aus Phase 1“.

**Checkpoint**: Ein Lauf lässt sich beschreiben und schreiben; zu sehen ist noch nichts.

---

## Phase 2: App im Fenster (US1, US2)

**Goal**: Die Selbsttest-App startet per Doppelklick, spielt `titel` im Zeitraffer und
`titel_echtzeit` in normalem Tempo über die echte Eingabe, filtert echte Eingaben, fotografiert,
schreibt Protokoll und Zip und beendet sich; das normale Spiel bleibt ohne Testcode (FR-001 bis
FR-010, FR-003a; R3 bis R8, R22, R24; contracts/selbsttest-app.md, contracts/export.md).

**Independent Test**: `Selbsttest macOS` bauen, mit `open` starten: Protokoll mit allen Schritten von
`titel` und `titel_echtzeit` in Ordnung, Fotos beider Abläufe gleich.

- [ ] T010 [K] [US2] Entscheiden, ob Klaus das Preset „Selbsttest macOS“ selbst im Export-Dialog des
  Editors anlegt, um Presets und Feature-Tags zu lernen (plan.md, „Vorarbeiten“, 3). Sonst schreibt es
  der Agent in T011.
- [ ] T011 [A] [US2] `src/project.godot`: Overrides `application/config/name.selbsttest` und
  `application/run/main_scene.selbsttest` (R3); `src/export_presets.cfg`: Preset `Selbsttest macOS`
  laut contracts/export.md (Tag `selbsttest`, Bundle-ID `de.klausmoster.dercomputerladen.selbsttest`,
  Ausschluss `addons/gut/*, test/*`, Ziel `../build/macos/Der Computerladen Selbsttest.app`), keine
  Zugangsdaten. Das Preset `macOS` bleibt unverändert.
- [ ] T012 [A] [US1] `src/tools/selbsttest/selbsttest_eingabe.gd` (`class_name SelbsttestEingabe`)
  laut Vertrag: `device = 4711`, Filter über `DisplayServer.window_set_input_event_callback()`,
  `Input.use_accumulated_input = false`, Umrechnung mit `get_tree().root.get_final_transform()`,
  Drücken und Loslassen in zwei Bildern, vor jedem Klick eine Bewegung aufs Ziel (R4).
- [ ] T013 [A] [US1] `src/tools/selbsttest/selbsttest_fahrer.gd` (`class_name SelbsttestFahrer`)
  laut Vertrag: Ziele über Kennungen, Zustand lesen, Wortlaute aus `TitleTexts`, „Ziel nicht
  gefunden: …“ (FR-005, R5). `src/test/test_selbsttest_fahrer.gd`: jedes Ziel im echten Titel
  gefunden, ein fehlendes mit Namen gemeldet. Braucht der Fahrer eine neue Abfrage am Spiel, ist das
  eine eigene kleine Änderung mit Test und steht im Bericht.
- [ ] T014 [A] [US1] `src/tools/selbsttest/selbsttest_laeufer.gd` (`class_name SelbsttestLaeufer`)
  und `src/tools/selbsttest/selbsttest_start.tscn`/`.gd` laut Vertrag: Ablage, Logger, Systemdaten,
  `GameSession` mit Ordner `user://selbsttest/spielstaende/`, fester Zeit `2026-10-26 20:40 UTC`,
  Seed 4711, Zeitzone UTC+1, eigener `quit_callback`, der erst schreibt und dann beendet (Analyse,
  U2); Läufer an die Wurzel; frischer Titel als `Vorbereitung` über `leave()` und Ordner leeren
  (CHK001; Analyse, I3); Fahrer verfolgt `slide_finished` (I3); `dauer_ms` ohne Eingabe ab Beginn
  des Schritts (I1);
  `Engine.time_scale` 8 bzw. 1 je Ablauf (R24); Warten auf Zustände bis 5000 ms echter Zeit (R6);
  Foto nach `frame_post_draw` (R8); Fenstertitel `Selbsttest · Schritt {n} von {gesamt}: {ablauf}`
  (CHK035); Fokusverluste; Schließen bricht ab und schreibt noch. Abläufe
  `src/tools/selbsttest/ablaeufe/ablauf_titel.gd` und `ablauf_titel_echtzeit.gd` laut
  contracts/ablaeufe.md. Am Ende Protokoll, Ausgabe, Zip, dann beendet sich die App (die
  Zusammenfassung kommt in Phase 4).
- [ ] T015 [A] [US1] Lernnotizen zu T011 bis T014: Feature-Tags und Overrides, `get_setting_with_override()`,
  Weg eines Ereignisses durch Godot, warum der Filter am Fenster sitzt, `Engine.time_scale`,
  `await` auf Bilder.
- [ ] T016 [C] [US1] Prüfen: Tests zweimal, Startprobe still; App bauen und zweimal mit `open`
  starten: alle Schritte in Ordnung (SC-003), Fotos beider Läufe und von `titel` und
  `titel_echtzeit` Byte für Byte gleich, verglichen mit `cmp` (SC-002, FR-011.8; Analyse, I5),
  `titel` schneller als `titel_echtzeit` (SC-001); Schließen des Fensters mitten im Lauf: Abbruch im
  Protokoll, Zip geschrieben (FR-010; Analyse, U2); echte Spielstände vorher und nachher gleich (SC-006); normales Spiel
  bauen und starten wie bisher; `export_presets.cfg` ohne Zugangsdaten. Restrisiken aus R4 im Lauf
  ansehen.
- [ ] T017 [C] Phasenprüfung Phase 2 mit `/dcl-phasenpruefung`, Text-Prüfer über Fenstertitel und
  die Beschreibungen von `titel` im Protokoll eines echten Laufs, Maßstab wie T008; vor Klaus'
  Abnahme.
- [ ] T018 [K] [US1] Phase 2 abnehmen: die App selbst starten und während des Laufs Maus und Tastatur
  benutzen; der Lauf bleibt unberührt; einmal das Fenster mitten im Lauf schließen und das Protokoll
  ansehen (FR-010; Analyse, U2). Diff, Lernnotizen, Protokoll.

**Checkpoint**: Der Selbsttest läuft im echten Fenster; ein Ablauf ist da.

---

## Phase 3: Alle Abläufe (US1)

**Goal**: Alle Abläufe aus contracts/ablaeufe.md und der Rahmen für Szenarien (FR-011, FR-011a,
FR-012; R16, R27). In zwei Teilen (`ki_dev.md`, Punkt 4).

**Independent Test**: Ein Lauf auf dem Mac mit allen acht Abläufen ist in Ordnung; die Fehlerprobe
findet alle sechs eingebauten Fehler (SC-004).

### Teil 1: Spielstände

- [ ] T019 [A] [US1] `ablauf_neues_spiel.gd`, `ablauf_laden.gd` (Name „Spiel laden“, CHK037),
  `ablauf_loeschen.gd` unter `src/tools/selbsttest/ablaeufe/` laut contracts/ablaeufe.md, mit
  `baut_auf` und der Form der Spalte „Erwartet“ (CHK031, CHK032).
- [ ] T020 [C] [US1] Prüfen von Teil 1: Tests zweimal, App bauen und laufen lassen, Protokoll und
  Fotos lesen.

### Teil 2: Easter Egg, Bedienung, Fenster, Szenarien

- [ ] T021 [A] [US1] `ablauf_easter_egg.gd` (Fotos von 03 und 04 nicht vergleichbar, R7),
  `ablauf_bedienung.gd` (sieben Spielstände als `Vorbereitung` über `SaveStore`, danach Titel neu
  laden, am Ende weggeräumt; CHK001; Analyse, U1), `ablauf_fenster.gd` (Zeitraffer 1, Fenster über `get_window().size`, Prüfung über
  `GameWindow.best_factor()` und `get_final_transform()`, `eingaben: Fenster`; R16).
- [ ] T022 [A] [US1] `src/tools/selbsttest/ablaeufe/selbsttest_szenario.gd` (`class_name
  SelbsttestSzenario`) laut Vertrag, „Szenario“, und der leere Ordner
  `src/tools/selbsttest/szenarien/` mit `.gitkeep` (Analyse, U6); Test mit einem erfundenen Szenario ohne Fenster in
  `src/test/test_selbsttest_lauf.gd`; ohne Bedienung der Uhr meldet der Fahrer „Die Uhr lässt sich im
  Spielbildschirm noch nicht bedienen“ (R27).
- [ ] T023 [A] [US1] Lernnotizen zu T019 bis T022: abhängige Abläufe, Vorbereitung statt Eingabe,
  Fenster und `get_final_transform()`, Rahmen für Szenarien.
- [ ] T024 [C] [US1] Prüfen: Tests zweimal, Startprobe still, zwei Läufe der App mit gleichen Fotos
  (`cmp`); der Eingabe-Filter wirkt noch nach dem Ablauf `fenster` (Analyse, U3);
  **Fehlerprobe** (SC-004): in einer Kopie des Projekts im Scratchpad je ein Fehler in Titel,
  Gradwahl, Liste, Rückfrage, Easter Egg und Fenster, Selbsttest daraus bauen und laufen lassen; jeder
  Fehler steht im passenden Schritt. Dazu SC-010: Claude ordnet die sechs Protokolle ohne weitere
  Angaben den eingebauten Fehlern zu.
- [ ] T025 [C] Phasenprüfung Phase 3 mit `/dcl-phasenpruefung`, Text-Prüfer über Beschreibungen und
  Erwartungen aller Abläufe im Protokoll eines echten Laufs, Maßstab wie T008; vor Klaus' Abnahme.
- [ ] T026 [K] [US1] Phase 3 abnehmen: Protokoll eines vollständigen Laufs, Ergebnis der Fehlerprobe,
  Diff, Lernnotizen.

**Checkpoint**: Der Selbsttest deckt das ganze heutige Spiel ab.

---

## Phase 4: Zusammenfassung (US1, US2)

**Goal**: Nach dem Lauf zeigt die App die Zusammenfassung im Look der Werkzeuge mit „Kopieren“,
„Ordner zeigen“ und „Beenden“; der normale Export ist nachweislich ohne Testcode (FR-015, FR-016,
FR-014a, SC-005, SC-007; R11, R12; contracts/selbsttest-app.md, „Zusammenfassung“, „Texte“).

**Independent Test**: Lauf auf dem Mac endet auf der Zusammenfassung; „Ordner zeigen“ zeigt das Zip;
„Kopieren“ legt den Text aus contracts/protokoll.md ab; mit nicht beschreibbarem Ordner steht die
Meldung.

- [ ] T027 [C] Style-Guide ergänzen, https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX, Abschnitt
  `project/Werkzeuge.md`, nach der Checkliste: keine Farbe für „in Ordnung“, Feld „!“ für Fehler und
  Feld „–“ für nicht gelaufen (CHK019), gesperrter Knopf (CHK020), zweite Farbe je Eintrag in
  mehrzeiligen Listen, kein Überfahren bei nicht anklickbaren Zeilen (CHK024), Bestätigung (CHK025),
  Tooltip und Handzeiger in allen Werkzeugen (CHK026), Umbruch langer Werte (CHK027), Geltung der
  Wortliste der Zeit (CHK030), Formen im Protokoll und Tastennamen (CHK039), Maschinenform nur für
  Messwerte (Phasenprüfung Phase 1, L1).
- [ ] T028 [K] Style-Guide-Ergänzung aus T027 freigeben.
- [ ] T029 [A] [US1] `src/tools/selbsttest/selbsttest_ergebnis.tscn`/`.gd` laut Vertrag,
  „Zusammenfassung“: `GameWindow` anhalten, Skalierung aus, Faktor des Bildschirms, Fenster maximiert
  (CHK016); Kopie von `werkstatt_theme.tres` mit `default_font = ThemeDB.fallback_font` (CHK017);
  Aufbau, Schriften, Abstände, Grund `papier` (CHK018, CHK021, CHK022); `src/test/test_texte.gd`
  durchsucht auch `res://tools/selbsttest/` (Phasenprüfung Phase 1); Einträge mit Feld „!“ oder
  „–“ (CHK019); Standard-`Button` mit Tooltip und Handzeiger (CHK026); Fokus auf „Kopieren“, Tasten
  (CHK023); „Kopieren“ mit Bestätigung, unter Linux mit Zusatz; „Ordner zeigen“ mit
  `OS.shell_show_in_file_manager()` auf das Zip (CHK002); „Beenden“; Ordner nicht beschreibbar
  (CHK020); Läufer wechselt nach dem Schreiben dorthin und hört nicht mehr auf das Schließen
  (CHK028). Wortlaute aus `SelbsttestTexte`. Bildschirmfotos aus dem echten Fenster bei 1920 × 925
  logisch: alles in Ordnung, mit Fehlern (erfunden), Ordner nicht beschreibbar, nach „Kopieren“;
  Aussage, ob der Platz reicht.
- [ ] T030 [A] [US1] Lernnotizen zu T029: Werkzeug im Spielfenster, Theme-Kopie, Zwischenablage,
  Dateimanager.
- [ ] T031 [C] [US2] SC-005 belegen: Spiel und Selbsttest für macOS bauen, nach `selbsttest_laeufer`
  in beiden `.pck` suchen (contracts/export.md); im Spiel 0, im Selbsttest mehr als 0.
- [ ] T032 [C] [US1] Prüfen: Tests zweimal, Startprobe still, ein Lauf bis zur Zusammenfassung,
  „Ordner zeigen“ und „Kopieren“ selbst ausprobieren, Fotos aus T029 ansehen; nach dem Maximieren
  kommen echte Eingaben an (Analyse, U3); SC-010 mit dem kopierten Text der Fehlerprobe wiederholen
  (A1).
- [ ] T033 [C] Phasenprüfung Phase 4 mit `/dcl-phasenpruefung`, Stil- und Text-Prüfer mit den Fotos
  aus T029 gegen `Werkzeuge.md` nach T028, `tokens.json`, `Sprache.md`; vor Klaus' Abnahme.
- [ ] T034 [K] [US1] Phase 4 abnehmen: App starten, Lauf bis zur Zusammenfassung, die drei Knöpfe.

**Checkpoint**: User Story 1 und 2 sind fertig: Der Selbsttest läuft auf dem Mac von Doppelklick bis
Zusammenfassung, das Spiel ist ohne Testcode.

---

## Phase 5: Vergleich mit Referenzbildern (US3)

**Goal**: Fotos eines Laufs lassen sich Pixel für Pixel mit Referenzbildern vom Mac vergleichen;
Belege landen im Spec-Ordner (FR-018 bis FR-020a, SC-008; R17 bis R19; contracts/vergleich.md).

**Independent Test**: Zwei Läufe auf dem Mac: alles gleich oder nicht vergleichbar; ein geänderter
Pixel wird genau gefunden.

- [ ] T035 [C] [US3] `tools/selbsttest/vergleich.py` und `tools/selbsttest/README.md` laut Vertrag:
  Zip oder Ordner, Schutz gegen Pfade aus dem Ordner hinaus, Ergebnisse `gleich`, `abweichend`,
  `nicht_vergleichbar`, `referenz_fehlt`, `foto_fehlt`, Bild mit markierten Pixeln in `kassenrot`,
  `vergleich.md`, `--gegen`, `--beleg`, `--referenz-erneuern`, Exit 0, 1, 2 (Analyse, I5). Proben aus dem Vertrag, „Prüfung“
  (SC-008).
- [ ] T036 [C] [US3] Lernnotiz zu T035: Vergleich ohne Toleranz, warum außerhalb von Godot, `-I`.
- [ ] T037 [K] [US3] Einen vollständigen Lauf auf dem Mac als Referenz abnehmen: Claude legt
  Protokoll und Fotos vor (FR-020).
- [ ] T038 [C] [US3] Referenzbilder mit `--referenz-erneuern alle` nach
  `tools/selbsttest/referenz/macos/` übernehmen; zweiten Lauf dagegen vergleichen: alles `gleich`
  oder `nicht_vergleichbar`.
- [ ] T038a [C] Phasenprüfung Phase 5 mit `/dcl-phasenpruefung`, Text-Prüfer über einen Bericht
  `vergleich.md` aus den Proben und die README gegen `Sprache.md` und `Werkzeuge.md` (Analyse, V2);
  vor Klaus' Abnahme.
- [ ] T039 [K] [US3] Phase 5 abnehmen: Bericht der Proben, Referenzbilder, README.

**Checkpoint**: Ein Foto eines anderen Rechners lässt sich bewerten.

---

## Phase 6: Windows und Linux (US4)

**Goal**: Spiel und Selbsttest für Windows x86_64 und Linux x86_64, ein Befehl baut alles, Klaus
startet den Selbsttest auf beiden Systemen, Claude vergleicht (FR-017, FR-021 bis FR-025, FR-026a,
SC-009; R13 bis R15, R26; contracts/export.md).

**Independent Test**: `tools/build/baue_alles.sh` endet mit Exit 0; auf je einem Windows- und
Linux-Rechner läuft der Selbsttest bis zur Zusammenfassung; jedes Foto hat ein Vergleichsergebnis.

- [ ] T040 [C] [US4] Download der Export-Templates 4.7.2 für Windows und Linux anfragen: Dateiname,
  Quelle und Größe nennen (FR-024, R14).
- [ ] T041 [K] [US4] Export-Templates installieren, etwa über den Export Template Manager des
  Editors; Claude prüft danach den Ordner `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`
  und ob die Direct3D-12-Dateien dabei sind.
- [ ] T041a [C] [US4] Style-Guide ergänzen, Abschnitt „App-Symbol“ in `project/README.md`: Symbol
  für Windows als ICO mit 16, 32, 48, 64, 128 und 256 Pixeln; wie die kleinen Größen aus dem
  gerasterten Monitor entstehen, ganzzahlig und ohne Weichzeichnen (Analyse, V1).
- [ ] T041b [K] [US4] Ergänzung aus T041a freigeben.
- [ ] T042 [C] [US4] `tools/raster/make_icon.py` schreibt nach T041b zusätzlich
  `src/assets/icon/app_icon.ico` mit 16, 32, 48, 64, 128 und 256 Pixeln als PNG-Einträge, die kleinen
  pixelgenau (R14); README in `tools/raster/` nachziehen; Lernnotiz.
- [ ] T043 [A] [US4] Nach T042. `src/project.godot`: `rendering/rendering_device/fallback_to_opengl3 = false`
  (R13), `toggle_fullscreen` mit F11 und Alt+Enter dazu (R15); `src/core/game_window.gd` fängt das
  Kürzel in `_input()` ab, mit genauem Vergleich der Zusatztasten, `src/test/test_game_window.gd`:
  Alt+Enter im Menü schaltet nur das Vollbild und löst nichts aus, Enter allein löst aus (Analyse,
  I2); `src/export_presets.cfg`: Presets
  `Windows`, `Selbsttest Windows`, `Linux`, `Selbsttest Linux` laut contracts/export.md (Symbol,
  Versionsangaben, `embed_pck`, ohne Signatur, keine Zugangsdaten);
  `src/test/test_projekt_einstellungen.gd` für Renderer, Vollbildtasten und Overrides. Export ohne
  Warnung „Icon size … is missing“.
- [ ] T044 [C] [US4] `tools/build/baue_alles.sh` laut contracts/export.md und R26: alle sechs
  Presets, Prüfung SC-005 je System, Zips unter `build/abnahme/`, `ditto` für macOS, Ausführrecht
  für Linux, `--nur macos`, Exit 0 nur bei vollem Erfolg; Lernnotiz.
- [ ] T045 [A] [US4] Lernnotizen zu T043: Renderer-Ausweichen, Eingabe-Aktionen mit mehreren Tasten,
  Presets für Windows und Linux.
- [ ] T046 [C] [US4] Prüfen: Tests zweimal, Startprobe still, `baue_alles.sh` Exit 0, Selbsttest auf
  dem Mac weiter grün und gleich den Referenzbildern, `export_presets.cfg` ohne Zugangsdaten.
- [ ] T046a [C] [US4] `quickstart.md` nachziehen (FR-026; Analyse, U4): Godots Meldung „Unable to
  initialize video driver“ ohne Vulkan oder Direct3D 12, die Warnung von macOS beim ersten Start einer
  unbekannten App, `chmod +x` unter Linux als Rückfall, Handtest des Vollbilds auf dem Mac
  (Ctrl+Cmd+F) neben F11 und Alt+Enter, der Bau mit `tools/build/baue_alles.sh`.
- [ ] T047 [K] [US4] Selbsttest auf einem Windows- und einem Linux-Rechner starten nach quickstart.md;
  „Kopieren“ in den Chat, Zips nach `build/selbsttest/`; kurzer Blick: Symbol der `.exe` im Explorer,
  im Fenster und in der Taskleiste, Vollbild mit F11 und Alt+Enter hin und zurück, Fenstergröße.
- [ ] T048 [C] [US4] Vergleichen mit `--beleg`, Belege unter `specs/007-build-export-selbsttest/belege/`;
  Bericht an Klaus mit jeder Abweichung und Empfehlung (SC-009).
- [ ] T048a [C] Phasenprüfung Phase 6 mit `/dcl-phasenpruefung`, Stil-Prüfer über eine Montage der
  sechs Größen der ICO ×8 gegen den Abschnitt „App-Symbol“ nach T041b (Analyse, V1); vor Klaus'
  Abnahme.
- [ ] T049 [K] [US4] Phase 6 abnehmen: Bericht, Belege, Entscheidung zu Abweichungen.

**Checkpoint**: Das Spiel läuft auf drei Systemen, belegt durch den Selbsttest.

---

## Phase 7: Abschluss (US5)

**Purpose**: Regel zur Arbeitsweise, Lückensuche, Gesamtabnahme, Doku, Tagebuch.

- [ ] T050 [C] [US5] Regel vorschlagen (FR-027, R25, CHK003): Wortlaut für `docs/ki_workflow/ki_dev.md`
  (Selbsttest zur Endabnahme, nicht nach jeder Phase; Bau mit `tools/build/baue_alles.sh`; wann auf
  Windows und Linux), für `.specify/templates/overrides/tasks-template.md` (Aufgabe „[A]
  Selbsttest-Abläufe anpassen“ vor der Gesamtabnahme) und für `docs/ki_workflow/ki_pruefung.md`
  (Abdeckung neuer Seiten und Wege bei der Lückensuche); gegebenenfalls Verfassung.
- [ ] T051 [K] [US5] Je Datei entscheiden; die Verfassung nur über `/speckit-constitution`. Claude
  ändert danach, was angenommen ist.
- [ ] T052 [C] Lückensuche mit `/speckit-converge` über das ganze Feature (`ki_dev.md`, „Ablauf je
  Feature“), dazu Stil- und Text-Prüfer einmal über alles. Lücken werden eine eigene Phase mit
  Klaus' Freigabe; hat sie Sichtbares, endet sie mit eigener Phasenprüfung.
- [ ] T053 [K] Gesamtabnahme nach dem ganzen Quickstart, die erste mit Selbsttest auf drei Systemen:
  Claude baut mit `tools/build/baue_alles.sh`, lässt den Selbsttest auf dem Mac laufen und nennt das
  Ergebnis in der Bitte um Abnahme.
- [ ] T054 [C] Doku nachziehen: `docs/features/Features.md` (007 fertig, System 11),
  `docs/offene-punkte.md`; `CLAUDE.md` (Tabelle „Aufbau“: `src/tools/selbsttest/`,
  `tools/selbsttest/`, `tools/build/`) nur mit Klaus' OK.
- [ ] T055 [C] Spielbeschreibung prüfen (die letzte Aufgabe vor dem Tagebuch, nach der
  Gesamtabnahme und vor dem Merge; `docs/ki_workflow/ki_dev.md`, „Ablauf je Feature“): Claude
  gleicht `docs/spielbeschreibung/` mit dem Code ab und legt Klaus eine Liste vor, welche Dateien
  veralten und welche neu angelegt werden sollten, mit Grund, mindestens `build-und-tests.md`,
  `darstellung.md` (Vollbildtasten), `spielstaende.md` (Zeitzonenversatz), `architektur.md`,
  `glossar.md` und ein mögliches neues `selbsttest.md` samt Index. Abweichungen zwischen Spec und
  Code gehören dazu. Geändert wird erst nach Klaus' OK.
- [ ] T056 [C] Tagebuch vor dem Merge (`ki_dev.md`, Punkt 10): eigene Datei für Feature 007 unter
  `docs/tagebuch/` nach dem README dort, auf Englisch, je echter Entscheidung ein Eintrag, oben die
  Zeile „Tokens and cost“ aus `python3 -I tools/tagebuch/token_bilanz.py
  feature/007-build-export-selbsttest`. Klaus nimmt die Einträge ab.

---

## Dependencies & Execution Order

### Phase Dependencies

Die Phasen laufen streng nacheinander, jede erst nach Klaus' Abnahme der vorigen (Verfassung,
Grundsatz II):

- **Phase 1** (Kern): keine.
- **Phase 2** (App im Fenster): nach Phase 1; braucht Lauf, Protokoll, Ablage, Zeitzone.
- **Phase 3** (alle Abläufe): nach Phase 2; Teil 2 erst nach Claudes Prüfung von Teil 1.
- **Phase 4** (Zusammenfassung): nach Phase 3; T029 erst nach T028.
- **Phase 5** (Vergleich): nach Phase 4, weil die Referenzbilder aus einem vollständigen Lauf kommen.
- **Phase 6** (Windows, Linux): nach Phase 5; T042 erst nach T041b; T043 erst nach T041 und T042;
  T044 erst nach T043; T047 erst nach T046 und T046a.
- **Phase 7** (Abschluss): nach Phase 6; T056 vor dem Merge, der Merge nur auf Klaus' Wort.

### User Story Dependencies

- **US1** (Selbsttest auf dem Mac) ist der Kern; US2 entsteht mit ihr (Preset und Ausschluss in
  Phase 2, Beleg in Phase 4).
- **US3** (Vergleich) braucht einen vollständigen Lauf aus US1.
- **US4** (Windows, Linux) braucht US1 bis US3, damit Läufe dort bewertbar sind.
- **US5** (Arbeitsweise) braucht das fertige Werkzeug und den Bau-Befehl aus US4.

### Within Each Phase

- Klassen vor Szenen, Szenen vor Abläufen, Tests mit der Logik, dann Lernnotiz; dann Claudes Prüfung,
  Phasenprüfung, Klaus' Abnahme, Commit.

### Parallel Opportunities

- T003 und T004 in Phase 1 berühren eigene Dateien und hängen nur am Vertrag.
- T041a und T042 (Style-Guide und ICO) brauchen die Templates nicht und können neben T040 und T041
  laufen; T043 wartet auf die ICO (Analyse, I8).
- Sonst keine: Läufer, Fahrer und Abläufe bauen aufeinander auf.

---

## Implementation Strategy

### Erst der Mac, dann die anderen

1. Phase 1 und 2: Der Selbsttest läuft auf dem Mac mit einem Ablauf; das ist der erste nutzbare
   Stand.
2. Phase 3: alle Abläufe und die Fehlerprobe; ab hier prüft er das ganze heutige Spiel.
3. Phase 4: die Zusammenfassung; ab hier ist er für Klaus bequem.
4. Phase 5: Vergleich und Referenzbilder; ab hier lassen sich andere Rechner bewerten.
5. Phase 6: Windows und Linux mit einem Bau-Befehl.
6. Phase 7: Regel, Lückensuche, Gesamtabnahme mit drei Systemen, Spielbeschreibung, Tagebuch.

---

## Notes

- Format: Task-ID, Besitzer, `[P]` für parallel ausführbar, `[Story]` für die User Story.
- Die Verfassung verlangt kein testgetriebenes Vorgehen; Tests entstehen mit der Logik und müssen
  vor der Abnahme grün sein.
- Zu jeder umgesetzten Task gibt es eine Lernnotiz in
  `specs/007-build-export-selbsttest/lernnotizen.md` (Verfassung, Grundsatz II). Bei `[A]`-Tasks
  schreibt sie der Agent, und Claude trägt sie nach jeder Phase ein.
- Nach dem Anlegen von Skripten oder Szenen ruft der Agent einmal
  `Godot --headless --path src --import` auf; `.uid` und `.import` werden committet.
- **Feste Größen** für jeden Auftrag an den Agent:
  - Ohne Selbsttest verhält sich das Spiel wie vorher; alle bisherigen Tests laufen unverändert
    grün (FR-002). Änderungen am Spielcode: der Zeitzonenversatz in `SaveGame` (Phase 1) und das
    Abfangen des Vollbild-Kürzels in `GameWindow` (Phase 6).
  - Das Preset `macOS` bleibt bis Phase 6 unverändert; das normale Paket enthält keine Datei unter
    `tools/selbsttest/` (SC-005).
  - Die Startprobe mit `-d` bleibt still.
  - `export_presets.cfg` enthält keine Zugangsdaten; Claude sieht die Datei vor jedem Commit an.
- **Echte Daten:** Kein Test und kein Lauf schreibt nach `user://spielstaende/` des Spiels; der
  Selbsttest hat seinen eigenen Datenordner (R3).
- **Nur ein Testlauf zur selben Zeit:** Alle Sitzungen teilen sich den Datenordner des Spiels.
- Der Selbsttest läuft in 007 in den Phasen 2 bis 6, weil er dort gebaut wird; ab 008 nur zur
  Endabnahme (R25).
- Braucht der Agent einen Wert oder eine Regel, die der Style-Guide nach T028 nicht hat, hält er an
  und fragt (Grundsatz IV).
