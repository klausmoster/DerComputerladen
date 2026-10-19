---

description: "Taskliste für Feature 001 Start bis zum Hauptmenü"
---

# Tasks: Start bis zum Hauptmenü

**Input**: Design-Dokumente aus `specs/001-hauptmenue/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/titelbildschirm.md,
quickstart.md

**Tests**: Der Plan sieht GUT-Tests für Menülogik, Fensterfaktor und Versionstext vor (research.md,
R14; Vertrag, Abschnitt Tests). Darstellung, Vollbild und Export prüft Klaus von Hand nach
quickstart.md.

**Organization**: Die Tasks sind nach User Stories gruppiert. Umgesetzt wird nach Verfassung 2.0.0,
Grundsatz II, eine Phase nach der anderen und nur auf Klaus' Auftrag. Jede Phase endet mit einer
Abnahme durch Klaus. Nach Grundsatz IV kommt der Style-Guide zuerst: T001 bis T003 stehen vor
allem anderen.

## Format: `[ID] [Besitzer] [P?] [Story] Beschreibung`

- **Besitzer**:
  - `[K]` Klaus: Godot-Editor, Grafikprogramme, Entscheidungen, Freigaben, Abnahmen.
  - `[A]` Godot-Agent `godot-entwickler`: Szenen, Nodes, GDScript, Tests, Projekteinstellungen,
    Export-Preset.
  - `[C]` Claude: Werkzeuge außerhalb von Godot, Style-Guide, Doku, Review.
- **[P]**: kann parallel laufen (andere Dateien, keine offene Abhängigkeit)
- **[Story]**: zugehörige User Story aus spec.md (US1 bis US4)

## Path Conventions

- Godot-Projekt unter `src/`, Tests unter `src/test/` (GUT 9.7.1)
- Werkzeuge außerhalb von Godot unter `tools/raster/`, Bildvorlagen unter `docs/art/`
- Export-Ziel `build/macos/`, nicht versioniert
- Pfade, Klassen und Signaturen laut [Vertrag](contracts/titelbildschirm.md)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Zuerst den Style-Guide ergänzen (Grundsatz IV), dann Palette, Werkzeuge, Schriften und
Export-Vorlagen bereitstellen

- [x] T001 [C] Style-Guide ergänzen, Oberfläche (plan.md, Vorarbeiten 1, 2, 3 und 5) im Artifact
  https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX:
  - Baustein Menü: Zustand „nicht verfügbar“ mit Text und Pfeil in `gehaeuse-dunkel`, samt
    Kontrastbegründung (4,98 / 4,14 / 3,31 : 1, Regel für große Schrift).
  - Neuer Baustein Hinweis: Feld in `papier`, ein Oberflächenpixel `tusche` als Kontur,
    `pixelschatten`, Text `klein` in `tusche`, höchstens 140 Oberflächenpixel breit, 4
    Oberflächenpixel links neben der gewählten Zeile, erscheint sofort. Nach der Sichtprobe
    (T013): Text in `text`, höchstens 160 breit.
  - Startgrund `anzeige-grund`.
  - Anrede „du“ für alle Texte.
- [x] T002 [C] Style-Guide ergänzen, Bild (plan.md, Vorarbeiten 4 und 6):
  - Abschnitt App-Symbol: Monitor aus dem Ladenschild auf `nacht`, 1024 × 1024 nach Apples
    Symbolraster, Liquid-Glass-Fassung.
  - Nachbearbeitung, Schritt 2: Flächenmittel, wenn die gemalten Pixel ungleich groß sind.
  - Hauptpalette aus „den ersten freigegebenen Bildern“.
- [x] T003 [K] Ergänzungen aus T001 und T002 im Style-Guide ansehen und freigeben
- [x] T004 [C] [P] `/build/` in die `.gitignore` im Repo-Root aufnehmen (Export-Ziel, research.md, R4)
- [x] T005 [C] Hauptpalette erzeugen mit `tools/raster/make_palette.py` (nur Standardbibliothek,
  Bilder per `sips` als BMP gelesen): 240 Farben per Median-Cut aus
  `docs/art/leonardo/stilanker-c2.jpg`, `t-01-titelbild.jpg` und `c-01-cover.jpg`, dazu die 15
  Oberflächenfarben aus `tokens.json` des Style-Guides und eine Transparenzfarbe; Ausgabe
  `docs/art/hauptpalette.gpl` und Farbtafel `docs/art/hauptpalette.png` (research.md, R7)
- [x] T006 [C] [P] Rasterskript `tools/raster/rasterize.py`: Flächenmittel auf die Zielgröße,
  Abbildung auf `docs/art/hauptpalette.gpl` ohne Dithering, Ausgabe als indiziertes PNG mit
  Transparenz; Aufruf und Reihenfolge in `tools/raster/README.md` (research.md, R6)
- [x] T007 [C] [P] Nach Freigabe des Downloads durch Klaus: Pixelify Sans und Doto von Google Fonts
  samt SIL-OFL-Lizenz nach `src/assets/fonts/` als `PixelifySans-Variable.ttf`,
  `Doto-Variable.ttf`, `OFL-PixelifySans.txt` und `OFL-Doto.txt` (research.md, R8)
- [ ] T008 [K] [P] Export-Vorlagen 4.7.2 im Godot-Editor installieren: „Editor → Export-Vorlagen
  verwalten → Herunterladen und installieren“, 1,3 GB (research.md, R4)

**Checkpoint**: Style-Guide ergänzt und freigegeben, Palette und Werkzeuge liegen vor, Schriften
im Projekt, Export-Vorlagen installiert.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Projekteinstellungen, Farben, Theme, Menü-Grundgerüst und Hinweis, auf denen alle User
Stories aufbauen

**⚠️ CRITICAL**: Keine User Story beginnt, bevor diese Phase abgenommen ist.

- [x] T009 [A] Projekteinstellungen in `src/project.godot` laut Vertrag, Tabelle
  „Projekteinstellungen“:
  - Basis 640 × 360, `display/window/stretch/mode = "viewport"`, `aspect = "keep"`,
    `scale_mode = "integer"`.
  - Texturfilter Nearest (0), `snap_2d_transforms_to_pixel` und `snap_2d_vertices_to_pixel` an.
  - `default_clear_color` und `application/boot_splash/bg_color` in `anzeige-grund` (#0d1716),
    `boot_splash/show_image = false`, `application/config/version = "0.1"`.
  - Fenstermodus und Hauptszene bleiben vorerst unverändert, die setzt T028.
- [x] T010 [A] [P] `src/ui/ui_palette.gd` mit `class_name UiPalette extends RefCounted`: die 15
  Farben aus `tokens.json` als Konstanten mit Token-Namen (`TUSCHE := Color("1d1916")` bis
  `HOLZ_DUNKEL`), Werte unverändert übernommen
- [x] T011 [A] Schriften aus T007 importieren, Einstellungen in den `.import`-Dateien unter
  `src/assets/fonts/`: `antialiasing` None, `hinting` None, `subpixel_positioning` Disabled,
  `generate_mipmaps` aus, `multichannel_signed_distance_field` aus (research.md, R8)
  - Dieselben Werte nach der Schriftprobe für Ark Pixel 10 und 12.
- [x] T012 [A] Theme `src/ui/computerladen_theme.tres` laut Vertrag:
  - Standardschrift Pixelify Sans, Größe 10.
  - Varianten `MenuRow`, `MenuHeader`, `Subtitle`, `VersionLine`, `HintPanel` und `HintLabel`.
  - Gewichte über `FontVariation.variation_opentype`, Farben nur aus der Palette.
  - `gui/theme/custom` in `src/project.godot` setzen.
  - Nach der Sichtprobe (T013): Pixelify Sans im Gewicht 400, Wortabstand über `spacing_space`,
    `HintLabel` und `VersionLine` in Größe 10, `Subtitle` in `drucker`.
  - Nach der Schriftprobe: `text` in Ark Pixel 10, `menue` in Ark Pixel 12, ohne Gewicht und
    Wortabstand (research.md, R8). Die Sichtprobe dazu folgt im Titelbildschirm.
- [x] T013 [K] Sichtprobe der Schriften bei 8, 10 und 12 Pixeln im Editor: gleichmäßige Striche,
  keine grauen Kantenpixel; Abweichungen an Claude melden (research.md, R8)
  - Erste Runde am 2026-10-19: Bei 12 kleben die Wörter, bei 8 sind Pixelify Sans und Doto nicht
    lesbar. Korrigiert im Style-Guide (Versionen 7 und 8), in T012 und T016.
  - Zweite Runde mit den korrigierten Stilen bei 10 und 12, in einer Vorschau-Szene außerhalb des
    Repos; von Klaus abgenommen am 2026-10-19.
- [x] T014 [A] [P] `src/scenes/title/menu_entry.gd` mit `class_name MenuEntry extends Resource`:
  - `@export var id: StringName`, `@export var label: String`, `@export var available: bool =
    false`, `@export_multiline var hint: String`.
  - Regeln aus data-model.md: `id` eindeutig und eines von `&"new_game"`, `&"load_game"`,
    `&"settings"`, `&"quit"`; „`hint` ist nie leer“.
- [x] T015 [A] Grundgerüst des Menüs in `src/scenes/title/main_menu.tscn` und
  `src/scenes/title/main_menu.gd` (`class_name MainMenu extends Control`):
  - Signale `entry_activated(id: StringName)` und
    `selection_changed(entry: MenuEntry, row_rect: Rect2)`; `const ROW_HEIGHT := 20`;
    `@export var entries: Array[MenuEntry]`.
  - Methoden `select(index: int)`, `selected_index() -> int`, `selected_entry() -> MenuEntry`
    und `activate_selected()`.
  - Kopfzeile „HAUPTMENÜ“ in Variante `MenuHeader` (FR-006).
  - Je Eintrag ein `Button` (`text = label`, `disabled = not available`, Variante `MenuRow`);
    Auswahl über den Fokus, Startauswahl 0 per `call_deferred`.
  - `_draw()`: Papier mit Zeilen abwechselnd `papier`/`endlos-gruen` (20 hoch), Lochränder,
    `pixelschatten` und die gewählte Zeile in `signalgelb` mit Pfeil in `tusche` (FR-011).
- [x] T016 [A] Hinweis in `src/scenes/title/menu_hint.tscn` und `src/scenes/title/menu_hint.gd`
  (`class_name MenuHint extends PanelContainer`):
  - `show_for(entry: MenuEntry, row_rect: Rect2)` und `hide_hint()`, Varianten `HintPanel` und
    `HintLabel`.
  - Stellt sich 4 Oberflächenpixel links neben `row_rect`, erscheint ohne Verzögerung und bleibt
    stehen, bis `show_for` mit einer anderen Zeile kommt (FR-017).
  - Nach der Sichtprobe (T013): Umbruch bei 150, Kasten höchstens 160 breit.
  - In Phase 3: Die Wuchsrichtung nach links setzt `_ready()`, weil `layout_mode = 0` an der
    Instanz sie beim Laden zurücksetzt.
- [x] T017 [A] Tests in `src/test/test_main_menu.gd` (Grundlagen): vier Einträge in der Reihenfolge
  „Neues Spiel“, „Spiel laden“, „Einstellungen“, „Beenden“; nur `quit` verfügbar;
  Startauswahl 0; `select()` sendet `selection_changed`

**Checkpoint**: Theme, Menü-Grundgerüst und Hinweis stehen, Tests grün. Abnahme durch Klaus, dann
Auftrag für Phase 3.

---

## Phase 3: User Story 1 - App unter macOS bis zum Titelbildschirm starten (Priority: P1) 🎯 MVP

**Goal**: Die gebaute Mac-App startet per Doppelklick im Vollbild und zeigt den Titelbildschirm.

**Independent Test**: App bauen und im Finder doppelklicken: Der Titelbildschirm erscheint im
Vollbild (quickstart.md, Abschnitte 4 und 5).

- [x] T018 [C] [US1] Titelbild rastern mit `tools/raster/rasterize.py`:
  `docs/art/leonardo/t-01-titelbild.jpg` auf 1920 × 1080 beschneiden (je 4 Pixel oben und unten),
  dann auf genau 320 × 180 Bildpixel → `src/assets/images/title_t01.png` (FR-019)
- [x] T019 [C] [P] [US1] Logo rastern: `docs/art/leonardo/logo-ladenschild.png` mit Faktor 6 auf
  etwa 142 × 27 Bildpixel mit Transparenz → `src/assets/images/logo_ladenschild.png`. Bricht der
  Schriftzug auf, Ausweichlösung Faktor 3 (FR-019, research.md, R6). Ergebnis 141 × 27, der
  Schriftzug bleibt lesbar.
- [ ] T020 [K] [US1] Groben Feinschliff an `src/assets/images/title_t01.png` und
  `src/assets/images/logo_ladenschild.png` in Pixelorama oder Aseprite: Einzelpixel und
  Farbreste entfernen, nur Farben der Hauptpalette; die Dateien bleiben an ihrem Ort. Danach
  erzeugt Claude das App-Symbol neu (T021), denn es nimmt den Monitor aus dem Logo
- [x] T021 [C] [P] [US1] App-Symbol per Skript `tools/raster/make_icon.py` vorbereiten:
  - Den Monitor aus dem gerasterten Logo `src/assets/images/logo_ladenschild.png` (T019) nehmen,
    also auf Bildraster und Hauptpalette, ganzzahlig vergrößert auf eine Fläche von 1024 × 1024
    nach Apples Symbolraster setzen, Grundfläche `nacht` → `src/assets/icon/app_icon.png`.
  - Die Ebenen für Icon Composer (Monitor freigestellt, Grundfarbe) nach `docs/art/app_icon/`
    (FR-002, research.md, R5).
- [ ] T022 [K] [US1] Liquid-Glass-Symbol in Icon Composer (Xcode 27.1) aus den Ebenen in
  `docs/art/app_icon/` bauen und als `src/assets/icon/app_icon.icon/` mit `.gdignore` darin
  ablegen
- [ ] T023 [K] [US1] Gerastertes Titelbild, Logo und App-Symbol freigeben (SC-007)
- [x] T024 [A] [US1] Titelbildschirm `src/scenes/title/title_screen.tscn` und
  `src/scenes/title/title_screen.gd` (`class_name TitleScreen extends Control`) laut Vertrag, mit
  den Bildern aus T018 und T019; Klaus' Feinschliff ändert nur deren Inhalt, nicht die Dateien:
  - Background als `TextureRect` (`title_t01.png`, 640 × 360, stretch_mode SCALE).
  - LogoBlock mit Logo und Subtitle „WIRTSCHAFTSSIMULATION · 1985–1999“ bei x 14, y 12.
  - MainMenu-Instanz bei x 472, y 150, Breite 144, mit den vier `MenuEntry` aus data-model.md
    (Bezeichnungen, `available`, Hinweistexte wie FR-016).
  - MenuHint-Instanz, über `_on_main_menu_selection_changed` an `selection_changed` angeschlossen
    (FR-017).
  - VersionLine unten links.
  - `const STAGE := "PROTOTYP"` und
    `static func version_text(version: String) -> String`: „0.1“ wird zu „V0.1 · PROTOTYP“, leer
    zu „PROTOTYP“ (FR-005, FR-006, FR-014).
- [x] T025 [A] [P] [US1] Tests in `src/test/test_title_screen.gd`: `version_text("0.1")` ergibt
  „V0.1 · PROTOTYP“, `version_text("")` ergibt „PROTOTYP“
- [x] T026 [A] [US1] Autoload `src/core/game_window.gd` (`GameWindow`, `extends Node`) laut
  Vertrag:
  - `BASE_SIZE`, `toggle_fullscreen()`, `is_fullscreen()` und
    `static func best_factor(usable: Vector2i, decorations: Vector2i) -> int`.
  - Headless ohne Wirkung; `get_window().min_size = BASE_SIZE`.
  - Beim Wechsel ins Fenster Größe nach `best_factor` auf dem aktuellen Bildschirm, dann
    zentrieren.
  - Eingabe-Aktion `toggle_fullscreen` (Ctrl+Cmd+F, physische Taste) und Autoload-Eintrag in
    `src/project.godot` (FR-004, FR-013).
  - Umgesetzt mit Abfrage in `_process()`, denn `size_changed` kommt bei Stretch `viewport` nie.
    Nach dem Kürzel wartet GameWindow 1 s auf das Ende des Übergangs; ob das reicht, zeigt T031.
- [x] T027 [A] [P] [US1] Tests in `src/test/test_game_window.gd`: `best_factor` für 1920 × 1050
  mit Titelleiste 28 (ergibt 2), 2560 × 1410 mit 28 (3), 3840 × 2130 mit 56 (5), 3024 × 1890 mit
  56 (4) und 600 × 300 mit 28 (1)
- [x] T028 [A] [US1] In `src/project.godot`: `display/window/size/mode = 3`,
  `application/run/main_scene = "res://scenes/title/title_screen.tscn"`,
  `application/config/icon = "res://assets/icon/app_icon.png"` (FR-001, FR-003, FR-004)
- [ ] T029 [A] [US1] Export-Preset „macOS“ in `src/export_presets.cfg` laut Vertrag:
  - Pfad `../build/macos/Der Computerladen.app`, `universal`.
  - Codesign Built-in (ad-hoc only), Notarisierung aus, `display/high_res` an.
  - Bundle-ID `de.klausmoster.dercomputerladen`, Versionen 0.1 und 0.1.0.
  - `application/icon` und `application/liquid_glass_icon`.
  - Keine Zugangsdaten in der Datei.
- [ ] T030 [C] [US1] `src/export_presets.cfg` auf Zugangsdaten prüfen (CLAUDE.md), dann die App
  laut quickstart.md, Abschnitt 4 nach `build/macos/Der Computerladen.app` exportieren
- [ ] T031 [K] [US1] Mac-App nach quickstart.md, Abschnitt 5 abnehmen:
  - Start per Doppelklick im Finder, aus dem Dock und über Spotlight (FR-001).
  - Startgrund ohne Godot-Logo (FR-003), Zeit bis zum Titel (SC-001, SC-002).
  - Dock, Symbol und Finder-Informationen.
  - Vollbild, Ctrl+Cmd+F, grüner Knopf und Fenstergröße.
  - Schärfe, Kameraaussparung und Seitenvergleich (SC-004, SC-006).
  - Das Export-Preset im Export-Dialog ansehen.

**Checkpoint**: Die Mac-App startet bis zum Titelbildschirm, das MVP steht. Abnahme durch Klaus,
dann Auftrag für Phase 4.

---

## Phase 4: User Story 2 - Spiel beenden (Priority: P2)

**Goal**: „Beenden“, Cmd+Q und das Schließen des Fensters beenden die App.

**Independent Test**: „Beenden“ wählen, dann Cmd+Q, dann Fenster schließen: Jedes Mal endet die App
vollständig.

- [ ] T032 [A] [US2] In `src/scenes/title/title_screen.gd`: `_on_main_menu_entry_activated` mit
  `entry_activated` des MainMenu verbinden; bei `&"quit"` ruft es `get_tree().quit()` auf (FR-008)
- [ ] T033 [A] [P] [US2] Test in `src/test/test_main_menu.gd`: `activate_selected()` auf „Beenden“
  sendet genau einmal `entry_activated(&"quit")`
- [ ] T034 [K] [US2] In der gebauten App prüfen:
  - „Beenden“ per Klick, Enter und Leertaste, jeweils mit höchstens drei Eingaben (SC-005).
  - Cmd+Q und Fenster schließen beenden die App. Fehlt Cmd+Q, Auftrag für T035.
- [ ] T035 [A] [US2] Nur wenn T034 kein Cmd+Q findet: in `src/core/game_window.gd` einen Eintrag
  „Der Computerladen beenden“ mit Cmd+Q über `NativeMenu` ergänzen (research.md, R11)

**Checkpoint**: Beenden funktioniert auf allen drei Wegen. Abnahme durch Klaus, dann Auftrag für
Phase 5.

---

## Phase 5: User Story 3 - Menü mit Maus und Tastatur bedienen (Priority: P2)

**Goal**: Maus und Tastatur teilen eine Auswahl, ein Hinweis erklärt jeden Eintrag.

**Independent Test**: Das Menü einmal nur mit der Tastatur und einmal nur mit der Maus bedienen
(quickstart.md, Abschnitt 3).

- [ ] T036 [A] [US3] Maus und Fokus in `src/scenes/title/main_menu.gd`:
  - `mouse_entered` ruft `grab_focus()` auf.
  - Umlauf über `focus_neighbor_top` und `focus_neighbor_bottom`.
  - Die rechte Maustaste über `gui_input` abfangen: Zeile fokussieren, nichts auslösen.
  - Kopfzeile und Lochränder ändern die Auswahl nicht (FR-009, FR-010, FR-011, Edge Cases).
- [ ] T037 [A] [US3] Mauszeiger in `src/scenes/title/main_menu.gd`: `mouse_default_cursor_shape`
  `CURSOR_POINTING_HAND` bei verfügbaren, `CURSOR_ARROW` bei nicht verfügbaren Einträgen (FR-018)
- [ ] T038 [A] [P] [US3] Tests in `src/test/test_main_menu.gd`:
  - Pfeil runter und hoch mit Umlauf an beiden Enden.
  - Rechtsklick wählt die Zeile und sendet kein `entry_activated`.
  - Mauszeiger je Eintrag nach `available`.
- [ ] T039 [K] [US3] Bedienung im Editor nach quickstart.md, Abschnitt 3 prüfen:
  - Pfeiltasten, Tab und Shift+Tab, Leertaste, Maus, Rechtsklick und Esc.
  - Der Hinweis erscheint sofort und bleibt stehen.
  - Jede Zeile reagiert ohne wahrnehmbare Verzögerung (SC-003).

**Checkpoint**: Das Menü lässt sich vollständig mit Maus und mit Tastatur bedienen. Abnahme durch
Klaus, dann Auftrag für Phase 6.

---

## Phase 6: User Story 4 - Noch nicht verfügbare Einträge (Priority: P3)

**Goal**: „Neues Spiel“, „Spiel laden“ und „Einstellungen“ sind als nicht verfügbar erkennbar, tun
nichts und erklären im Hinweis, warum.

**Independent Test**: Alle drei Einträge überfahren und auslösen: Es erscheint der Hinweis, sonst
passiert nichts.

- [ ] T040 [A] [US4] Darstellung „nicht verfügbar“ nach dem Style-Guide aus T001:
  - In `src/ui/computerladen_theme.tres`: `font_disabled_color` von `MenuRow` in
    `gehaeuse-dunkel`.
  - In `src/scenes/title/main_menu.gd`: Pfeil bei ausgewähltem nicht verfügbarem Eintrag in
    `gehaeuse-dunkel` (FR-007).
- [ ] T041 [A] [P] [US4] Tests in `src/test/test_main_menu.gd`: `activate_selected()` sendet bei
  „Neues Spiel“, „Spiel laden“ und „Einstellungen“ nichts; nach dem Erscheinen ist „Neues Spiel“
  gewählt, und Auslösen bewirkt nichts
- [ ] T042 [K] [US4] Im Editor prüfen: Hinweistexte wie FR-016, Lesbarkeit der nicht verfügbaren
  Einträge in Ruhe und ausgewählt, kein Fehler beim Auslösen

**Checkpoint**: Alle vier User Stories sind erfüllt. Abnahme durch Klaus, dann Auftrag für den
Abschluss.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Gesamtprüfung, Lernnotizen, Doku

- [ ] T043 [A] Alle Tests und die Startprobe laufen lassen (quickstart.md, Abschnitte 1 und 2):
  alle grün, Exit-Code 0, keine Warnungen
- [ ] T044 [C] Review des ganzen Features gegen Spec und Vertrag, etwa mit `/speckit-converge` als
  Lückensuche; Lernnotizen aller Phasen in `specs/001-hauptmenue/lernnotizen.md` vollständig
- [ ] T045 [C] Doku nachziehen: neue Pfade (`src/ui/`, `src/assets/`, `src/scenes/title/`,
  `tools/raster/`, `docs/art/app_icon/`) in die Aufbau-Tabelle von `CLAUDE.md`; Feature 001 in
  `docs/features/Features.md` verlinken
- [ ] T046 [K] Feature abnehmen: Abnahmen aus T023, T031, T034, T039 und T042 erledigt, Merge nach
  `main` freigeben

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: keine Abhängigkeiten nach außen.
  - Zuerst T001 und T002, dann die Freigabe T003.
  - T005 und T006 brauchen T003. T004, T007 und T008 hängen an nichts.
- **Foundational (Phase 2)**: braucht Phase 1.
  - T011 braucht T007, T012 braucht T010 und T011.
  - T015 und T016 brauchen T012 und T014, T017 braucht T015.
- **User Story 1 (Phase 3)**: braucht Phase 2.
  - T018 und T019 brauchen T005 und T006, T020 braucht T018 und T019.
  - T021 braucht T005, T022 braucht T021, T023 braucht T020 und T022.
  - T024 braucht T015, T016, T018 und T019, aber nicht die Freigabe T023.
  - T028 braucht T021 und T024, T029 braucht T008 und T022.
  - T030 braucht T028 und T029, T031 braucht T023 und T030.
- **User Story 2 (Phase 4)**: braucht T024; T034 braucht die gebaute App aus T030.
- **User Story 3 (Phase 5)**: braucht T015 und T024.
- **User Story 4 (Phase 6)**: braucht T001, T015 und T024.
- **Polish (Phase 7)**: braucht alle User Stories.

### User Story Dependencies

- **US1** ist das MVP und kommt zuerst; US2 bis US4 bauen auf dem Titelbildschirm aus T024 auf.
  Untereinander hängen sie nicht voneinander ab, denn den Hinweis liefert schon Phase 2 (T016).
- **US3 und US4** ändern beide `src/scenes/title/main_menu.gd`. Sie laufen deshalb nacheinander,
  nicht parallel.

### Within Each User Story

- Erst Struktur und Logik, dann Tests, dann die Prüfung durch Klaus.
- Eine Phase gilt erst als fertig, wenn Claude das Ergebnis des Agents geprüft und Klaus es
  abgenommen hat.

### Parallel Opportunities

- Phase 1: T004, T007 und T008 parallel zur Arbeit am Style-Guide; T005 und T006 parallel nach
  T003.
- Phase 2: T010 und T014 parallel.
- Phase 3: T019 und T021 parallel zu T018; T025 und T027 parallel zum übrigen Bau.
- Phasen 4 bis 6: die Testaufgaben T033, T038 und T041 parallel zur Umsetzung ihrer Phase.

---

## Parallel Example: User Story 1

```text
# Claude bereitet die Bilder parallel vor:
Task: "T019 [C] Logo rastern → src/assets/images/logo_ladenschild.png"
Task: "T021 [C] App-Symbol per tools/raster/make_icon.py → src/assets/icon/app_icon.png"

# Der Godot-Agent schreibt die Tests parallel zum Bau:
Task: "T025 [A] Tests in src/test/test_title_screen.gd"
Task: "T027 [A] Tests in src/test/test_game_window.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup abschließen, mit dem Style-Guide zuerst.
2. Phase 2: Foundational abschließen. Das blockiert alles.
3. Phase 3: User Story 1 umsetzen.
4. **Halt und prüfen:** Die Mac-App startet bis zum Titelbildschirm (T031).

### Incremental Delivery

1. Setup und Foundational: Das Grundgerüst steht.
2. US1: Die App startet bis zum Titel, das MVP.
3. US2: Beenden auf allen Wegen.
4. US3: volle Bedienung mit Maus und Tastatur.
5. US4: nicht verfügbare Einträge fertig gestaltet.
6. Jede Phase einzeln von Klaus beauftragt und abgenommen.

### Arbeitsteilung

- Claude beauftragt den Agent je Phase mit den `[A]`-Tasks und prüft sein Ergebnis gegen Vertrag
  und Verfassung. Dann bekommt Klaus Diff, Erklärung und Lernnotiz.
- `[K]`-Tasks erledigt Klaus selbst. `[C]`-Tasks erledigt Claude, Downloads nur nach Freigabe.
- Committet wird nach Klaus' Abnahme einer Phase, auf `feature/001-hauptmenue`.

---

## Notes

- Format: Task-ID, Besitzer, `[P]` für parallel ausführbar, `[Story]` für die User Story.
- Die Verfassung verlangt kein testgetriebenes Vorgehen; Tests entstehen mit der Logik und müssen
  vor der Abnahme grün sein.
- Zu jeder `[A]`-Task schreibt der Agent eine Lernnotiz. Claude trägt sie nach jeder Phase in
  `specs/001-hauptmenue/lernnotizen.md` ein, eine Notiz je Task.
- Zu vermeiden: vage Tasks, zwei Tasks gleichzeitig an derselben Datei, Abhängigkeiten zwischen
  Stories, die ihre Unabhängigkeit brechen.
