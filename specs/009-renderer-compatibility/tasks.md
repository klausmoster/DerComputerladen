---

description: "Taskliste für Feature 009 Renderer Compatibility"
---

# Tasks: Renderer Compatibility

**Input**: Design-Dokumente aus `specs/009-renderer-compatibility/`

**Prerequisites**: plan.md, spec.md, research.md (R1 bis R8), data-model.md, contracts/renderer.md,
quickstart.md, checklists/review.md

**Tests**: Die GUT-Tests der Projekteinstellungen und des Selbsttests ändern sich mit der Einstellung
(research.md, R3, R4). Sie müssen vor jeder Abnahme grün sein, zweimal hintereinander mit derselben
Zahl von Prüfungen (SC-006). Das Bild belegen der Selbsttest auf drei Systemen und der Blick ins echte
Fenster (SC-002, SC-003, SC-007).

**Organization**: Die Tasks folgen den fünf Phasen aus plan.md, „Phasen im Überblick“: Phase 1
Vorbereitung, Phase 2 Regeln, Phase 3 Umstellung, Phase 4 Läufe, Phase 5 Doku, danach der Abschluss.
Umgesetzt wird nach Grundsatz II der Verfassung: eine Phase nach der anderen, nur auf Klaus' Auftrag,
`/speckit-implement` nie. Phase 2 kommt vor Phase 3, damit kein Commit gegen die geltende Verfassung
verstößt (R7). Kürzel wie „CHK016“ verweisen auf [review.md](checklists/review.md), „R7“ auf
[research.md](research.md). Nach der Analyse vom 2026-10-29 kam T026a dazu; T010, T012, T018 und
T027 sind genauer (Befunde D1, U1, C1, I3, von Klaus nach Empfehlung freigegeben).

## Format: `[ID] [Besitzer] [P?] [Story] Beschreibung`

- **Besitzer**:
  - `[K]` Klaus: Beschlüsse, Freigaben, Abnahmen, Läufe auf Windows und Linux.
  - `[A]` Godot-Agent `godot-entwickler`: Projekteinstellungen, GDScript, Tests, Lernnotizen.
  - `[C]` Claude: Regeln, Style-Guide, Quelltext lesen, Bauen, Läufe auf dem Mac, Belege, Doku,
    Phasenprüfung, Review.
- **[P]**: kann parallel laufen (andere Dateien, keine offene Abhängigkeit)
- **[Story]**: User Story aus spec.md (US1 Das Spiel startet auf dem Boot-Camp-Rechner, US2 Das Bild
  bleibt auf allen drei Systemen gleich, US3 Regeln und Doku sagen dasselbe wie das Spiel)

## Path Conventions

- Godot-Projekt unter `src/`; Einstellungen in `src/project.godot`; Selbsttest unter
  `src/tools/selbsttest/`; Tests unter `src/test/`, Beispieldaten unter `src/test/fixtures/selbsttest/`
- Bauen und Vergleichen: `tools/build/baue_alles.sh`, `tools/selbsttest/vergleich.py`; Referenzbilder
  unter `tools/selbsttest/referenz/macos/`; gebaut wird nach `build/` (nicht versioniert)
- Belege der Läufe unter `specs/009-renderer-compatibility/belege/`
- Style-Guide: Artifact https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX, Datei `project/README.md`

---

## Phase 1: Vorbereitung

**Purpose**: Godot-Doku im Arbeitsordner, damit Claude, Agent und Prüfer die API nachschlagen.

- [x] T001 [C] Godot-Doku im Arbeitsordner bereitlegen, immer die erste Aufgabe: Fehlt
  `godot_referenz/`, `tools/godot_referenz/erzeuge.sh --texte --handbuch` laufen lassen
  (`docs/ki_workflow/ki_dev.md`, „Werkzeuge und Pfade“). Erledigt beim Plan am 2026-10-29: 1078
  Klassen und 517 Seiten des Handbuchs von Godot 4.7.2 aus dem Cache.

---

## Phase 2: Regeln (US3, zuerst)

**Goal**: CLAUDE.md, Verfassung und Style-Guide nennen Compatibility als Renderer, bevor die
Einstellung sich ändert (FR-009, FR-009a; R6, R7).

**Independent Test**: CLAUDE.md und Verfassung Grundsatz I enthalten den Wortlaut aus FR-009, die
Verfassung hat Version 3.0.0; die Godot-Zeile im Style-Guide nennt den Renderer und hat den Satz aus
FR-009a; die alte Regel steht mit „bis 2026-10-29“ da.

- [x] T002 [K] [US3] Den Wortlaut der neuen Regel beschließen, wie in spec.md, FR-009: „Der Renderer
  ist Compatibility, auf allen drei Systemen. Mittel, die es nur in Forward+ gibt (HDR,
  Kantenglättung des Bildes in 2D, Compute), werden nicht genutzt.“; dazu „Keine Rücksicht auf den
  Renderer Mobile“ statt des Satzes zu Compatibility, Mobile und GLES; Verfassung 3.0.0 als MAJOR
  (R6). Claude legt beide Stellen vorher als Diff vor.
- [x] T003 [C] [US3] `CLAUDE.md`, „Harte Rahmenbedingungen“, nach T002 ändern: neue Regel, alte als
  „bis 2026-10-29: Renderer bleibt Forward+“ mit Verweis auf Feature 009; die Verbote für Mobile,
  Android, Touch bleiben (FR-009).
- [x] T004 [C] [US3] Verfassung über `/speckit-constitution` auf 3.0.0: Grundsatz I wie in T002, die
  Begründung des Grundsatzes nennt den Anlass (Boot Camp, `docs/entscheidungen/renderer.md`);
  danach mit `git diff` prüfen, dass `.specify/templates/overrides/` unverändert ist
  (`.specify/memory/constitution.md`; `ki_dev.md`, „Spec Kit aktualisieren“).
- [x] T005 [C] [US3] Den Satz für den Style-Guide vorlegen (FR-009a, CHK013, CHK014, CHK018): Ende
  der Zeile „Godot: …“ in `project/README.md`, „Raster und Auflösung“; dieselbe Zeile nennt den
  Renderer Compatibility (Verfassung, Grundsatz I) und `snap_2d_vertices_to_pixel`; Wortwahl
  „Kantenglättung des Bildes“ und „Glühen über Weiß, eine Folge von HDR (Farbwerte über 1,0)“; die
  Kantenglättung der Schrift bleibt beim Abschnitt Schrift.
- [x] T006 [K] [US3] Den Satz aus T005 freigeben oder ändern.
- [x] T007 [C] [US3] Den Style-Guide nach T006 veröffentlichen: Artifact lesen, nur die Zeile ändern,
  veröffentlichen, die neue Version nennen. Erledigt 2026-10-29: Version 66.
- [x] T008 [C] Phasenprüfung Phase 2: entfällt laut plan.md, „Prüfer je Phase“ (keine Prüfer; der
  Style-Guide ist selbst der Maßstab, Klaus gibt den Wortlaut in T006 frei).
- [x] T009 [K] [US3] Phase 2 abnehmen: Diff von CLAUDE.md und Verfassung, Zeile im Style-Guide.

**Checkpoint**: Die Regel erlaubt Compatibility; Phase 3 darf die Einstellung ändern.

---

## Phase 3: Umstellung (US1, US2)

**Goal**: Das Spiel läuft ohne Startoption mit Compatibility; das Protokoll nennt Rückfälle lesbar;
Tests und Beispieldaten passen zum neuen Stand (FR-001 bis FR-005; R1, R3, R4, R8;
contracts/renderer.md).

**Independent Test**: Tests zweimal grün mit derselben Zahl; Probestart auf dem Mac zeigt „OpenGL API
4.1 Metal … - Compatibility“ (quickstart.md, „Probestart auf dem Mac“).

- [x] T010 [A] [US1] `src/project.godot` nach contracts/renderer.md: `rendering/renderer/rendering_method
  = "gl_compatibility"`, `config/features` mit `"GL Compatibility"` statt `"Forward Plus"`;
  `rendering_device/driver.windows` und `rendering_device/fallback_to_opengl3` streichen; für
  `gl_compatibility/` nichts eintragen. Startgrund, Hintergrundfarbe, Texturfilter, Einrasten,
  Viewport und Skalierung bleiben unverändert (FR-004, CHK016). Per Hand in der Datei, nicht über
  den Editor, der beim Umschalten weitere Schlüssel schreiben kann; nur die Schlüssel aus dem Vertrag;
  danach `--import`; Ergebnis als Diff (Analyse U1).
- [x] T011 [A] [US1] `src/test/test_projekt_einstellungen.gd` nach R4: die drei Tests zu Forward+
  entfallen; neu: Renderer ist `gl_compatibility`; kein Schlüssel unter `rendering_device/` im Text der
  Datei; `fallback_to_angle`, `fallback_to_gles`, `fallback_to_native` sind true und nicht
  eingetragen; `gl_compatibility/driver.macos` ist `opengl3` und nicht eingetragen. Kopf des Skripts
  nennt Feature 009 und R4.
- [x] T012 [A] [US2] Die Konstante `GRAFIK_API` zieht von `src/tools/selbsttest/selbsttest_system.gd`
  nach `src/tools/selbsttest/selbsttest_texte.gd` (`SelbsttestTexte`), mit den neuen Einträgen
  `opengl3_angle` → „ANGLE“ und `opengl3_es` → „OpenGL ES“; `SelbsttestSystem` liest sie dort (R3,
  CHK012). Benutzt wird die Konstante heute nur in `selbsttest_system.gd`, Zeilen 46 und 85 (Analyse
  C1). Ein Test prüft die beiden neuen Namen und dass ein unbekannter Schlüssel unverändert
  durchgeht (`src/test/test_selbsttest_system.gd`).
- [x] T013 [A] [P] [US2] Beispieldaten auf `gl_compatibility` und OpenGL umstellen, Format unverändert
  (R3, CHK010): `src/test/fixtures/selbsttest/kopieren_erwartet.txt`, `protokoll_erwartet.txt`,
  `kopieren_nicht_beschreibbar.txt`; `src/test/test_selbsttest_protokoll.gd` (Zeilen 261, 327, 328);
  `src/test/test_selbsttest_ergebnis.gd` (Zeilen 27, 90, 277).
- [x] T014 [A] Lernnotizen zu T010 bis T013 in `specs/009-renderer-compatibility/lernnotizen.md`: was
  `rendering_method` und die Treiber-Overrides tun, warum Vorgaben nicht eingetragen werden, warum
  `get_current_rendering_method()` den Stand nach dem Rückfall liefert, warum die Namen in die
  Textklasse ziehen.
- [x] T015 [C] [P] [US1] Im Quelltext von Godot 4.7.2 nachsehen, was Godot ohne OpenGL 3.3 (und unter
  Windows ohne Direct3D 11) meldet (`platform/windows/display_server_windows.cpp`,
  `platform/linuxbsd/x11/display_server_x11.cpp`); Ergebnis in research.md, R8, und spec.md, „Edge
  Cases“ (CHK005).
- [x] T016 [C] Phase 3 prüfen: `--import`, Tests zweimal, Startprobe headless, Probestart mit Fenster
  mit beiden Treibern laut quickstart.md (Zeile „Compatibility“, bei ANGLE „ANGLE Metal Renderer“),
  Diff von `project.godot` gegen den Vertrag, Code an den kritischen Stellen.
- [x] T017 [C] Phasenprüfung Phase 3 mit `/dcl-phasenpruefung`, Prüfer laut plan.md: Architektur
  (`project.godot`, `selbsttest_system.gd`, `selbsttest_texte.gd`) und Text (Anzeigenamen „ANGLE“,
  „OpenGL ES“); vor Klaus' Abnahme (`docs/ki_workflow/ki_pruefung.md`).
- [x] T018 [K] [US1] Phase 3 abnehmen: Diff, Lernnotizen, Testergebnis, Ausgabe des Probestarts; die
  Bitte um Abnahme enthält den Startbefehl laut quickstart.md, „Probestart auf dem Mac“ (Analyse I3).

**Checkpoint**: Das Spiel läuft auf dem Mac mit Compatibility; Läufe auf allen Systemen können
beginnen.

---

## Phase 4: Läufe auf drei Systemen (US1, US2)

**Goal**: Belege, dass Spiel und Selbsttest auf Mac, Linux und dem Boot-Camp-Rechner mit
Compatibility laufen und das Bild gleich bleibt (FR-006 bis FR-008; SC-001 bis SC-004, SC-007; R2,
R5). Das ist zugleich der Selbsttest zur Gesamtabnahme aus der Aufgaben-Vorlage.

**Independent Test**: Drei Belege unter `belege/` mit `gl_compatibility` im Protokoll, alle Schritte
in Ordnung, alle Fotos gleich oder jede Abweichung beurteilt; Bildschirmfotos aus dem echten Fenster
auf dem Mac; Klaus' Prüfliste für Windows und Linux abgehakt.

- [x] T019 [C] [US2] Bauen mit `tools/build/baue_alles.sh`: Zips für macOS, Windows und Linux unter
  `build/abnahme/`; prüfen, dass kein `libEGL.dll` oder `libGLESv2.dll` im Windows-Zip nötig ist
  (R2).
- [x] T020 [C] [US2] Selbsttest auf dem Mac: Lauf, `tools/selbsttest/vergleich.py … --beleg`; im
  Protokoll `gl_compatibility` und OpenGL; Dauer gegen den Beleg aus 007, mehr als doppelt so lang
  geht an Klaus (CHK006). Beleg unter `specs/009-renderer-compatibility/belege/`. Erledigt
  2026-10-29: 45 von 45, 43 Fotos gleich, 2 nicht vergleichbar (Space Invaders, wie in 007), 3709 ms
  gegen 5260 ms im Beleg aus 007; `vergleich.py --beleg` legt nach 007 ab, deshalb von Hand kopiert.
- [x] T021 [C] [P] [US2] Das echte Fenster auf dem Mac (SC-007, CHK017): Bildschirmfotos vom
  Startgrund, von einer krummen Fenstergröße und von der Werkstatt bei 1920 × 925 (CHK003), je mit
  Aussage; Fotos in den Scratchpad, nicht ins Repo. Erledigt 2026-10-29, nachdem Klaus die
  Bildschirmaufnahme freigab: Fenster 2900 × 1700 Pixel auf 4K, Bild ×4 mit schwarzen Rändern, harte
  Pixel; beim Start mit Bildschirmgröße ×5 ohne Ränder. Werkstatt bei 1920 × 925 gegen Forward+:
  43.188 Pixel um höchstens 1 von 255 verschieden (geglättete Schriftkanten). Den Startgrund vor dem
  ersten Bild hat kein Foto erwischt; die Einstellung dazu ist unverändert.
- [x] T022 [K] [US1] Boot-Camp-Rechner nach quickstart.md, „Windows auf dem Boot-Camp-Rechner“:
  Spiel per Doppelklick, Selbsttest per Doppelklick, einmal mit `--rendering-driver opengl3_angle`,
  Prüfliste fürs echte Fenster; Zips und kopierten Text an Claude.
- [x] T023 [K] [P] [US2] Linux-Rechner nach quickstart.md, „Linux“: Selbsttest per Doppelklick,
  Prüfliste fürs echte Fenster; Zip und kopierten Text an Claude.
- [x] T024 [K] [P] [US1] Kann: derselbe Lauf unter Windows in Parallels (Klärung vom 2026-10-29).
  Erledigt 2026-10-29 mit dem Build von 12:21: per Doppelklick natives OpenGL 3.3, mit
  `opengl3_angle` ANGLE über Direct3D 11; beide 45 von 45, 43 Fotos gleich. Damit ist auch FR-006
  belegt (ANGLE im Export).
- [x] T025 [C] [US2] Die Zips aus T022 bis T024 vergleichen und als Belege ablegen; je Protokoll
  Renderer und Grafikschnittstelle nennen (SC-004); den Lauf mit `opengl3_angle` als Beleg für FR-006
  festhalten. Erledigt 2026-10-29: Boot Camp (OpenGL 3.3 über den AMD-Treiber von 2017), Linux
  (OpenGL 4.6 über Mesa), Parallels (OpenGL 3.3 und ANGLE); alle 45 von 45, je 43 Fotos gleich und 2
  nicht vergleichbar wie auf dem Mac; Belege unter `belege/`.
- [x] T026 [K] [US2] Nur bei Abweichungen: je Abweichung entscheiden, ANGLE über Metal versuchen oder
  neue Referenzbilder abnehmen (FR-002, FR-008); nur wenn T022 mit `opengl3_angle` auf OpenGL
  zurückfällt: über `export_angle = 1` entscheiden (FR-006). Claude legt jede Abweichung mit Bild vor.
  Entfällt 2026-10-29: keine Abweichung, ANGLE läuft (Parallels mit `opengl3_angle`).
- [x] T026a [C] Nur wenn T026 `src/project.godot` oder `src/export_presets.cfg` ändert: der Agent
  setzt es um und schreibt die Lernnotiz, danach Phasenprüfung mit `/dcl-phasenpruefung` und dem
  Architektur-Prüfer, vor Klaus' Abnahme (Verfassung VI; Analyse D1). Sonst entfällt sie. Entfällt 2026-10-29, weil T026 entfällt.
- [x] T027 [K] [US1] Phase 4 abnehmen: Belege, Bildschirmfotos, Ergebnis der Prüflisten; die Bitte um
  Abnahme enthält den Startweg der App laut quickstart.md, „Selbsttest auf dem Mac“ (Analyse I3).

**Checkpoint**: US1 und US2 sind belegt.

---

## Phase 5: Doku (US3)

**Goal**: Feature 007, Spielbeschreibung, offene Punkte und Entscheidung zeigen den neuen Stand; die
alte Regel bleibt als Geschichte lesbar (FR-010 bis FR-013, SC-005; R6).

**Independent Test**: Die Suche aus quickstart.md, „Regeln und Doku“, findet „Forward+“ nur mit Datum
oder in älteren Specs.

- [x] T028 [C] [P] [US3] Feature 007 mit Vermerk „bis 2026-10-29“ und Verweis auf Feature 009, alter
  Text lesbar (FR-010): `specs/007-build-export-selbsttest/spec.md` (FR-017, Klärung „Was passiert
  ohne Forward+?“, Begriff „Renderer“), `research.md` (R13), `quickstart.md` (Schritt 5 unter
  „Windows und Linux“, „Voraussetzungen“), `lernnotizen.md` (T043).
- [x] T029 [C] [P] [US3] `docs/spielbeschreibung/`: `darstellung.md`, `architektur.md`,
  `build-und-tests.md`, `selbsttest.md` („Grenzen“, „Belegte Läufe“) auf den neuen Renderer und die
  Belege aus Phase 4 (FR-011).
- [x] T030 [C] [P] [US3] `docs/offene-punkte.md`: „Renderer“, „Abweichung von FR-017“ und die Frage
  nach den Direct3D-12-Dateien nach „Erledigt“, mit Verweis auf Feature 009 (FR-012).
- [x] T031 [C] [P] [US3] `docs/entscheidungen/renderer.md`: ein Vermerk unter „Stand“, dass die
  Entscheidung in Feature 009 umgesetzt ist; sonst unverändert (FR-013).
- [x] T032 [C] [US3] Suche nach „Forward+“ laut quickstart.md (SC-005); jede Fundstelle einordnen.
- [x] T033 [C] Phasenprüfung Phase 5: entfällt laut plan.md, „Prüfer je Phase“ (nur Doku).
- [x] T034 [K] [US3] Phase 5 abnehmen: Diff der Doku.

---

## Abschluss

**Purpose**: Lückensuche, Gesamtabnahme, Spielbeschreibung, Tagebuch, Merge.

- [ ] T035 [C] Bestandsprüfung mit dem Architektur-Prüfer über ganz `src/`: entfällt, denn 009 beginnt
  keine neue Schicht und endet nicht auf 3 oder 8 (`docs/ki_workflow/ki_pruefung.md`).
- [ ] T036 [C] Lückensuche mit `/speckit-converge` über das ganze Feature; Prüfer einmal über das
  Feature; Lücken werden eine neue Phase mit Klaus' Freigabe (`ki_dev.md`, Punkt 6).
- [ ] T037 [A] Selbsttest-Abläufe anpassen: entfällt, denn das Feature ändert keine Seiten, Wege, Texte
  der Abläufe oder Eingaben (`ki_dev.md`, Punkt 11).
- [ ] T038 [C] Selbsttest zur Gesamtabnahme: liegt mit Phase 4 vor; hat sich nach Phase 4 Code
  geändert, auf dem Mac neu bauen, laufen lassen und vergleichen. Ergebnis in der Bitte um
  Gesamtabnahme; neue Referenzbilder nur nach Klaus' Abnahme.
- [ ] T039 [K] Gesamtabnahme nach dem ganzen quickstart.md, mit Startweg und Ergebnis des Selbsttests.
- [ ] T040 [C] Spielbeschreibung prüfen (immer die letzte Aufgabe des Features, nach der
  Gesamtabnahme und vor dem Merge; `docs/ki_workflow/ki_dev.md`, „Ablauf je Feature“): Claude
  gleicht `docs/spielbeschreibung/` mit dem Code ab und legt Klaus eine Liste vor, welche Dateien
  veralten und welche neu angelegt werden sollten, mit Grund. Abweichungen zwischen Spec und Code
  gehören dazu. Geändert wird erst nach Klaus' OK.
- [ ] T041 [C] Tagebuch: je echter Entscheidung ein Eintrag auf Englisch in einer eigenen Datei des
  Features unter `docs/tagebuch/`, oben die Zeile aus
  `python3 -I tools/tagebuch/token_bilanz.py feature/009-renderer-compatibility` (`ki_dev.md`,
  Punkt 10); Klaus nimmt ab.
- [ ] T042 [K] Merge nach `main` freigeben; Claude merged, Klaus pusht.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** ist erledigt.
- **Phase 2 (Regeln)** zuerst; sie blockiert Phase 3 (R7).
- **Phase 3 (Umstellung)** nach Phase 2; sie blockiert Phase 4.
- **Phase 4 (Läufe)** nach Phase 3. T022 bis T024 laufen auf Klaus' Rechnern und können gleichzeitig
  mit T020 und T021 laufen; T025 wartet auf ihre Zips, T026 auf T020 und T025, T026a auf T026.
- **Phase 5 (Doku)** nach Phase 4, weil Spielbeschreibung und 007 die Belege nennen.
- **Abschluss** nach Phase 5.

### User Story Dependencies

- **US3** steht in Phase 2 (Regeln) vor allem anderen und in Phase 5 (Doku) am Ende.
- **US1** und **US2** hängen an derselben Einstellung (T010) und werden in Phase 4 gemeinsam belegt;
  getrennt testbar sind sie über verschiedene Belege: US1 über SC-001 (Boot Camp), US2 über SC-002,
  SC-003, SC-007 (Bild).

### Within Each Phase

- T002 vor T003 und T004; T005 vor T006 vor T007.
- T010 vor T011 (die Tests lesen die neue Datei); T012 und T013 unabhängig davon; T014 zuletzt.
- T019 vor T020 bis T024.

### Parallel Opportunities

- Phase 3: T013 neben T010 bis T012 (andere Dateien); T015 neben dem Agent.
- Phase 4: T021 neben T020; T023 und T024 neben T022.
- Phase 5: T028 bis T031 sind verschiedene Dateien.

---

## Parallel Example: Phase 3

```text
Agent: T010, T011, T012 nacheinander (project.godot, dann Tests, dann Textklasse)
Agent: T013 Beispieldaten (eigene Dateien)
Claude: T015 Quelltext von Godot zu R8 lesen
```

---

## Implementation Strategy

### Kleinster Nutzen zuerst

1. Phase 2: Regel ändern (nur Doku, klein).
2. Phase 3: Einstellung umstellen; danach startet das Spiel auf dem Mac mit Compatibility.
3. Phase 4: T019 und T022 zuerst, wenn Klaus den Boot-Camp-Rechner bereit hat: Das ist der Anlass des
   Features (US1). Dann der Rest der Läufe.
4. Phase 5 und Abschluss.

### Schrittweise

Jede Phase endet mit Klaus' Abnahme und einem Commit. Bei Abweichungen in Phase 4 entscheidet Klaus,
bevor Phase 5 die Doku auf den Stand bringt.

---

## Notes

- Ein Commit je abgenommener Phase (`ki_dev.md`, „Git“); der Agent committet nie.
- `export_presets.cfg` bleibt unverändert, außer Klaus entscheidet in T026 über `export_angle`; vor
  jedem Commit ansehen.
- Fotos aus dem echten Fenster kommen nicht ins Repo; Referenzbilder ändern sich nur nach T026.
