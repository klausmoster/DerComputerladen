---

description: "Taskliste für Feature 005 Communicator als Steuerelement"
---

# Tasks: Communicator als Steuerelement

**Input**: Design-Dokumente aus `specs/005-communicator/`

**Prerequisites**: plan.md, spec.md, research.md (R1 bis R14), data-model.md,
contracts/communicator.md, contracts/titelbildschirm.md, quickstart.md, checklists/review.md

**Tests**: Die Verträge legen GUT-Tests fest, je im Abschnitt „Tests“. Sie entstehen mit der Logik
und müssen vor jeder Abnahme grün sein, zweimal hintereinander mit derselben Zahl von Prüfungen.
Die Oberfläche prüft Klaus zusätzlich von Hand nach quickstart.md.

**Organization**: Die Tasks folgen den sechs Phasen aus plan.md, „Umsetzungsphasen“. Phase 1 ist
Vorarbeit im Style-Guide, Phase 2 die Grafik, Phase 3 der Baustein (US3), Phase 4 die Seiten auf der
Anzeige, Phase 5 der Titel (US1, US2), Phase 6 der Abschluss. Umgesetzt wird nach Verfassung 2.1.1,
Grundsatz II: eine Phase nach der anderen, nur auf Klaus' Auftrag, `/speckit-implement` nie. Jede
Phase endet mit Klaus' Abnahme; jede Phase mit Sichtbarem hat davor die [C]-Aufgabe
„Phasenprüfung“ (plan.md, „Prüfer je Phase“). Kürzel wie „CHK001“ verweisen auf die Checkliste
[review.md](checklists/review.md).

## Format: `[ID] [Besitzer] [P?] [Story] Beschreibung`

- **Besitzer**:
  - `[K]` Klaus: Entscheidungen, Freigaben, Abnahmen, Bilder in Leonardo, was er selbst bauen will.
  - `[A]` Godot-Agent `godot-entwickler`: Szenen, Nodes, GDScript, Theme, Tests.
  - `[C]` Claude: Style-Guide, Prompts, Rastern, Doku, Phasenprüfung, Review.
- **[P]**: kann parallel laufen (andere Dateien, keine offene Abhängigkeit)
- **[Story]**: zugehörige User Story aus spec.md (US1 bis US3); Grundlagen tragen keine

## Path Conventions

- Godot-Projekt unter `src/`, Tests unter `src/test/`, Probeszenen für Tests unter
  `src/test/fixtures/` (GUT 9.7.1; `test/*` ist vom Export ausgeschlossen)
- Der Baustein unter `src/ui/communicator/`, Farben in `src/ui/ui_palette.gd`, Theme in
  `src/ui/computerladen_theme.tres`, Titel unter `src/scenes/title/`, Bilder unter
  `src/assets/images/`, Originale unter `docs/art/leonardo/`
- Pfade, Klassen, Signale und Signaturen laut [communicator.md](contracts/communicator.md) und
  [titelbildschirm.md](contracts/titelbildschirm.md); was dort nicht steht, gilt aus den Verträgen
  von Feature 001 und 004
- Werte für Farben, Maße, Lagen und Dauer kommen nach T001 aus dem Style-Guide, nicht aus diesen
  Tasks (Grundsatz IV)

---

## Phase 1: Style-Guide (Vorarbeit, kommt vor allem anderen)

**Purpose**: Was Phase 3 bis 5 zeigen, steht vorher im Style-Guide (FR-008; research.md, R12). Kein
Code.

- [ ] T001 [C] Style-Guide ergänzen, https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX, Dateien
  unter `project/`, nach research.md, R12 (mit CHK001 bis CHK004, CHK014, CHK015, CHK017, CHK019,
  CHK023):
  - Neuer Baustein **Communicator** mit README und Vorschau: Gehäuse als reine Grafik ohne Klick,
    Anzeige 384 × 192 für jedes Gehäuse mit ihrer Farbe je Gehäuse (Organizer: `lcd`), Lage im
    Titel nach R9, Fahrt herein und hinaus (Dauer, Verlauf, ganze Oberflächenpixel, Endlage auf
    ganzen Bildpixeln), Fahrt als Deko-Animation für „Bewegung reduzieren“, Seitenwechsel ohne
    Übergang, keine Eingabe während der Fahrt hinaus, Hinweis und Meldung neben dem Gehäuse.
  - Token **`lcd`** in `tokens.json` und im README, „Farben“: Wert (Vorschlag #b8c4a8, R2) mit den
    vier Kontrasten, „nur Oberfläche, nie im Bild“ (R1), die neuen Textpaare.
  - Bausteine **Menü** und **Liste**: Abschnitt „Auf der Anzeige“ (ohne Papier, Lochränder, Zebra,
    Schatten; Balken `tusche`, Schrift, Pfeil und Rollmarke darin `lcd`, gedämpft
    `gehaeuse-dunkel`; Abstände); „Blätter im Titel“ wird „Seiten im Titel“ mit Verweis auf den
    Communicator.
  - Bausteine **Hinweis** und **Meldung**: Lage neben dem Gehäuse.
  - README: Schrift (Doto auch für Kopfzeilen auf der Anzeige), `signalgelb` und der invertierte
    Balken, Bildaufbau Titel mit T-02 und Gerät, Bewegung mit der Fahrt.

  Vorher liest Claude die betroffenen Dateien neu und ändert nur diese; danach bekommt Klaus den
  Link und eine Liste der Änderungen.
- [ ] T002 [C] [P] Prompt **G-02 Organizer 1991** mit dem Stilblock des Style-Guides in die
  Prompt-Bibliothek: frontal, aufgeklappt, leeres LCD „exactly twice as wide as high“, keine Marke,
  keine Sprenkel über dem LCD; Modell, Seitenverhältnis und Style Reference C2 nach dem aktuellen
  Stand von Leonardo (R10). Der Prompt für T-02 folgt erst in T006 (CHK005).
- [ ] T003 [K] Phase 1 abnehmen: Style-Guide lesen, den Wert von `lcd` und die Lage im Titel
  freigeben oder ändern lassen, den Prompt G-02 freigeben. Erst danach beginnt Phase 3.

**Checkpoint**: Der Style-Guide regelt alles, was der Communicator braucht.

---

## Phase 2: Grafik G-02 und T-02 (Vorarbeit, blockiert nur Phase 5)

**Purpose**: Gehäuse und Titelbild nach dem Leonardo-Workflow (FR-020; R10). Teilt keine Datei mit
Phase 3 und 4 und darf neben ihnen laufen; die Reihenfolge innerhalb ist fest: erst G-02, dann
T-02.

- [ ] T004 [K] G-02 in Leonardo erzeugen mit dem Prompt aus T002; ein Bild auswählen und als
  Original nach `docs/art/leonardo/g-02-organizer.*` legen.
- [ ] T005 [C] G-02 rastern: freistellen, mit `tools/raster/rasterize.py` so verkleinern, dass das
  LCD 192 × 96 Bildpixel hat, `cleanup.py`, die LCD-Fläche von Hand auf genau 192 × 96 bringen;
  Ergebnis `src/assets/images/organizer_1991.png`, nur Farben der Hauptpalette. Lage der Anzeige im
  Gehäuse nachmessen und, falls sie vom Style-Guide abweicht, dort nachtragen. Eintrag im
  Prompt-Log `docs/art/leonardo/prompt-log.md` mit Modell, Seed und Rasterfassung.
- [ ] T006 [C] Prompt **T-02 Titelbild**: dieselbe Welt wie T-01, ruhige dunkle Fläche rechts unten
  in der Größe des Gehäuses aus T005; T-01 als Bildvorlage, wenn Leonardo es anbietet, sonst in
  Worten, C2 als Style Reference (R10, CHK026). In die Prompt-Bibliothek.
- [ ] T007 [K] T-02 in Leonardo erzeugen; Original nach `docs/art/leonardo/t-02-titelbild.*`.
- [ ] T008 [C] T-02 rastern auf 320 × 180 (`rasterize.py --groesse 320x180`, `cleanup.py`), Ergebnis
  `src/assets/images/title_t02.png`; Prompt-Log. `title_t01.png` bleibt.
- [ ] T009 [C] Phasenprüfung Phase 2 mit `/dcl-phasenpruefung`: Stil-Prüfer mit README (Szenen und
  Figuren, Farben), Leonardo-Workflow, Stilanker C2 und beiden Bildern ×4; dazu eine Montage von
  G-02 auf T-02 in der Lage aus R9.
- [ ] T010 [K] Phase 2 abnehmen: beide Bilder freigeben; an der Montage entscheiden, ob nichts
  Wichtiges verdeckt ist (FR-015, CHK024).

**Checkpoint**: G-02 und T-02 sind freigegeben und im Prompt-Log vermerkt.

---

## Phase 3: User Story 3 – Ein Steuerelement für spätere Bildschirme (Priority: P2)

**Goal**: Der Baustein Communicator mit Platzhalter-Gehäuse: Fahrt, Seiten, Hinweis, gesperrte
Eingabe; bedienbar außerhalb des Titels (FR-001 bis FR-007; R4, R6, R7, R8, R11).

**Independent Test**: `test_communicator.gd` zeigt den Communicator in einer Probeszene mit einem
Menü aus drei Einträgen, fährt ihn herein und hinaus, wählt per Tastatur und bekommt den Eintrag
gemeldet, ohne Titelbildschirm und `TitleTexts` (SC-005).

- [ ] T011 [A] [US3] `lcd` in `src/ui/ui_palette.gd`: `const LCD` mit dem Wert aus dem Style-Guide,
  Token `&"lcd"` in `TOKENS`, Kopfkommentar „16 Farben; `lcd` nicht in der Hauptpalette“ (R1);
  `CATEGORY_TOKENS` bleibt. Tests: `src/test/test_ui_palette.gd` mit 16 Farben und den vier
  Kontrasten aus R2 gegen 4,5 : 1 und 3 : 1 (CHK023); `src/test/test_bilder.gd` prüft nur die 15
  reservierten Farben in der Hauptpalette, `lcd` als Ausnahme mit Verweis auf R1, und ein neuer
  Test sichert, dass `lcd` in keinem Bild unter `res://assets/images/` vorkommt.
- [ ] T012 [A] [US3] `src/ui/communicator/communicator.tscn` und `communicator.gd`
  (`class_name Communicator`) laut communicator.md:
  - Aufbau `Case` (Platzhalter: Rechteck in `gehaeuse` mit Kontur `tusche` in Größe des Gehäuses,
    R11), `Display` (Farbe `lcd`, `DISPLAY_RECT` aus dem Style-Guide), `Hint` (`menu_hint.tscn`),
    danach die Seiten als direkte Kinder; alles außer den Seiten `mouse_filter = IGNORE`; ein Klick
    auf das Gehäuse tut nichts (CHK002).
  - `add_page()`, `show_page()`, `current_page()`; Seiten aus der Szene stellt `_ready()` auf die
    Anzeige.
  - Fahrt: `place_hidden()`, `slide_in()`, `slide_out()`, `is_in()`, `accepts_input()`, `slide_y`,
    `animate`, Signal `slide_finished(arrived_in)`; Tween angehalten und in `_process()` mit
    `custom_step(minf(delta, MAX_STEP))`, `MAX_STEP` 1/30 s, herein `EASE_OUT`, hinaus `EASE_IN`,
    `TRANS_CUBIC`; Umkehr aus der aktuellen Lage; Endlage auf ganzen Bildpixeln (CHK015). Übernommen
    aus dem Spike mit `git show 481c7e0:src/scenes/title/organizer.gd`, nicht gemergt (R14).
  - Eingabe: herein bedienbar; eine Zeile, die unter dem ruhenden Zeiger durchfährt, wird nicht
    gewählt (CHK007; der Agent prüft, ob `mouse_entered` dabei kommt); hinaus kein Fokus auf den
    Seiten und keine Maus (R8).
  - Hinweis: `show_hint()`, `show_warning()`, `hide_hint()`; rechte Kante 4 vor der linken Kante
    des Gehäuses, oben bündig mit der Zeile; fährt als Kind mit (R7). Wie `MenuHint` dafür an eine
    Lage gestellt wird, nennt der Agent im Bericht.
- [ ] T013 [A] [US3] Probeszene `src/test/fixtures/communicator_probe.tscn` (Hintergrund `nacht`,
  ein Communicator, ein `MainMenu` mit drei `MenuEntry`) und Tests `src/test/test_communicator.gd`
  laut communicator.md, „Tests“: Fahrt Bild für Bild auf ganzen Pixeln und nie über die Endlage
  (SC-003); Endlage nach höchstens 250 ms bei 1/60 s und 1/30 s je Bild und mit einem ersten Bild
  von 0,5 s, gezählt ab dem ersten fahrenden Bild (SC-002, CHK010); Umkehr in beide Richtungen;
  `slide_finished` einmal je Fahrt, mit `animate = false` sofort; Probeseite per Tastatur, ohne
  `title_screen.tscn` und `TitleTexts` (SC-005); keine Eingabe während der Fahrt hinaus; ruhender
  Zeiger wählt nicht; Klick aufs Gehäuse tut nichts; Hinweis links neben dem Gehäuse und um genau
  die Strecke der Fahrt mitbewegt. Bis Phase 4 steht das Menü der Probe auf `PAPER`; T019 stellt
  es auf `LCD` um.
- [ ] T014 [A] [US3] Lernnotizen zu T011 bis T013 in `specs/005-communicator/lernnotizen.md`
  (neu): Tween mit `custom_step()`, gerundete Eigenschaft als Ziel, Seiten als Kinder einer
  Instanz, Hinweis als Kind statt per Differenz.
- [ ] T015 [C] [US3] Prüfen: Tests zweimal, Startprobe mit `-d` still, Code an Fahrt und Eingabe
  lesen, Bildschirmfoto der Probeszene im echten Fenster in Klaus' Größe.
- [ ] T016 [C] [US3] Phasenprüfung Phase 3 mit `/dcl-phasenpruefung`: Stil-Prüfer mit Baustein
  Communicator und `tokens.json`; Bildschirmfotos der Probeszene in Endlage und unterwegs.
- [ ] T017 [K] [US3] Phase 3 abnehmen (Quickstart, Zuordnung Phase 3).

**Checkpoint**: Der Communicator fährt, zeigt eine Seite und meldet sie, ohne den Titel.

---

## Phase 4: Seiten auf der Anzeige (Grundlage für US1 und US2)

**Purpose**: Menü und Liste können auf der Anzeige stehen: Schalter `look` mit `PAPER` und `LCD`
(R3, R5). Der Titel bleibt in dieser Phase Papier.

- [ ] T018 [A] Theme `src/ui/computerladen_theme.tres`: Varianten `LcdRow` (Basis `Button`, Ark
  Pixel 12, `font_color` `tusche`, Fokus, Überfahren und gedrückt `lcd`, `font_disabled_color`
  `gehaeuse-dunkel`, leere Styles wie `MenuRow`, Innenabstand links aus dem Style-Guide) und
  `LcdHeader` (wie `MenuHeader`); ein Test vergleicht die Farben mit `UiPalette`.
- [ ] T019 [A] `src/scenes/title/menu_paper.gd`: LCD-Fassung `draw_lcd_selection()` (Balken
  `tusche`, Pfeil `lcd`, gedämpft `gehaeuse-dunkel`) und die Maße der Anzeige aus dem Style-Guide;
  `src/scenes/title/main_menu.gd`: `enum Look { PAPER, LCD }`, `@export var look` mit Vorgabe
  `PAPER`; auf `LCD` kein Papier, Zeilen mit `LcdRow`, Kopfzeile mit `LcdHeader`, Breite der Anzeige
  (aus dem Spike übernommen, R14). Die Probeszene aus T013 stellt ihr Menü auf `LCD`. Tests in
  `src/test/test_main_menu.gd`: auf `LCD` kein Papier und invertierte Auswahl, Bedienung und
  Signale wie auf `PAPER`; alle bisherigen Tests mit `PAPER` unverändert grün.
- [ ] T020 [A] `src/scenes/title/save_list.gd`: derselbe Schalter `look`; auf `LCD` kein Papier und
  kein Zebra, Spalten-Labels in den Farben der Zeile auch invertiert, Rollmarke in der gewählten
  Zeile `lcd` (CHK001), Breite der Anzeige. Tests in `src/test/test_save_list.gd`: wie T019, dazu
  die Rollmarke auf „Löschen …“ gewählt. Hängt an T019 (`menu_paper.gd`).
- [ ] T021 [A] Lernnotizen zu T018 bis T020: Theme-Varianten statt Farben im Code, warum ein
  gesperrter Button die gedämpfte Schrift auch mit Fokus behält, ein Schalter statt zweier Klassen.
- [ ] T022 [C] Prüfen: Tests zweimal, Startprobe still, Bildschirmfotos von Menü und Liste auf
  `LCD` in der Probeszene, gewählt verfügbar und nicht verfügbar.
- [ ] T023 [C] Phasenprüfung Phase 4 mit `/dcl-phasenpruefung`: Stil-Prüfer mit Bausteinen Menü,
  Liste und Communicator, `tokens.json`; die Bildschirmfotos aus T022.
- [ ] T024 [K] Phase 4 abnehmen.

**Checkpoint**: Menü und Liste stehen auf der Anzeige wie im Style-Guide; der Titel ist unverändert.

---

## Phase 5: User Story 1 und 2 – Titel auf dem Communicator (Priority: P1) 🎯

**Goal**: Der Titel mit T-02 und dem Organizer; alle vier Seiten auf seiner Anzeige; Hinausfahren
vor dem Spielstart (FR-010 bis FR-015). Braucht Phase 2, 3 und 4.

**Independent Test**: Spiel starten: Der Organizer fährt herein, HAUPTMENÜ auf dem LCD; „Neues
Spiel“ → SCHWIERIGKEIT auf derselben Anzeige, das Gerät steht; ein Grad → das Gerät fährt hinaus,
dann der Spielbildschirm (Quickstart, „Von Hand“).

- [ ] T025 [A] [US1] `src/ui/communicator/communicator.tscn`: `Case` zeigt `organizer_1991.png` ×2
  statt des Platzhalters, `DISPLAY_RECT` nach der Messung aus T005; Tests aus Phase 3 bleiben grün.
- [ ] T026 [A] [US1] `src/scenes/title/title_screen.tscn`: `Background` mit `title_t02.png`;
  `Communicator` in der Endlage aus dem Style-Guide mit den Seiten `MainMenu`, `DifficultySheet`,
  `SaveList`, `ConfirmSheet`, alle `look = LCD`; der eigene `MenuHint` entfällt
  (titelbildschirm.md, „Szenenaufbau“).
- [ ] T027 [A] [US1] [US2] `src/scenes/title/title_screen.gd` laut titelbildschirm.md, „Verhalten“:
  `place_hidden()` in `_ready()`, Fahrt herein, sobald das Hauptmenü seine Einträge hat, vorher tut
  keine Eingabe etwas (CHK018); `_show_only()` über `show_page()`; Hinweis und Meldung über den
  Communicator; nach `OK` von `start_new()` oder `resume()` erst `slide_out()`, Szenenwechsel in
  `slide_finished(false)`, ab dann ignoriert `_unhandled_input()` alles (R8); scheitert das
  Fortsetzen, wie in 004 neu lesen, ohne Fahrt (CHK016); „Beenden“ sofort.
- [ ] T028 [A] [US1] [US2] Tests in `src/test/test_title_screen.gd` laut titelbildschirm.md,
  „Tests“: Pfade auf `Communicator/<Seite>`; Erscheinen draußen und Fahrt herein, auch nach der
  Rückkehr; Seitenwechsel ohne Bewegung; jede Seite passt auf die Anzeige mit den längsten Texten
  und „Spiel 9999“ (SC-004); keine Überschneidung von Logo, Untertitel und Versionszeile mit
  Gehäuse, Anzeige, Hinweis oder Meldung für jede Zeile jeder Seite (SC-006); Enter während der
  Fahrt herein setzt fort (SC-001); kein zweites Spiel und ein Aufruf von `scene_callback` bei Enter
  oder Esc während der Fahrt hinaus; Anlegen scheitert: keine Fahrt, Meldung neben dem Gehäuse;
  Fortsetzen scheitert: keine Fahrt; kein `look = PAPER` im Titel. Alte Tests nur angepasst, wo sie
  Papier, Lage der Blätter oder Lage des Hinweises prüfen (SC-007).
- [ ] T029 [A] [US1] Lernnotizen zu T025 bis T028: Szenenwechsel erst nach einem Signal, Eingabe
  sperren beim Verlassen, warum die Fahrt mit den Einträgen beginnt.
- [ ] T030 [C] [US1] [US2] Prüfen: Tests zweimal, Startprobe still; Bildschirmfotos im echten
  Fenster in Klaus' Größe: Hauptmenü mit und ohne Spielstände, Gradwahl, Liste mit mehr als sechs
  Spielständen und „Löschen …“ gewählt, Rückfrage, Meldung, Fahrt herein und hinaus.
- [ ] T031 [C] [US1] [US2] Phasenprüfung Phase 5 mit `/dcl-phasenpruefung`: Stil-Prüfer mit
  README (Bildaufbau, Bewegung, Logo), Bausteinen Communicator, Menü, Liste, Hinweis, Meldung,
  `tokens.json`; Text-Prüfer mit `Sprache.md` als Gegenprobe, dass kein Text sich verschoben oder
  gekürzt hat; die Bildschirmfotos aus T030.
- [ ] T032 [K] [US1] [US2] Phase 5 abnehmen nach dem Quickstart, „Von Hand“, Punkte 1 bis 10; noch
  einmal entscheiden, ob T-02 nichts Wichtiges verdeckt (CHK024).

**Checkpoint**: Der Titel läuft ganz über den Communicator; alle Wege aus Feature 004 gehen.

---

## Phase 6: Abschluss

**Purpose**: Doku, Lückensuche, Gesamtabnahme.

- [ ] T033 [C] Doku nachziehen: `docs/features/Features.md` (005 fertig, System 10);
  `docs/Ideensammlung.md` und `docs/recherche/navigation-taschengeraet.md` mit Verweis auf 005;
  in `docs/offene-punkte.md` der Umzug von Menü, Liste, Papier und Hinweis nach `src/ui/` als
  offener Punkt für das Feature, das sie als Erstes außerhalb des Titels braucht; `CLAUDE.md`
  (Tabelle „Aufbau“: `src/ui/communicator/`) nur mit Klaus' OK.
- [ ] T034 [C] Lückensuche mit `/speckit-converge` über das ganze Feature (`ki_dev.md`, „Ablauf je
  Feature“), dazu der Stil-Prüfer einmal über alles. Lücken werden eine eigene Phase mit Klaus'
  Freigabe; hat sie Sichtbares, endet sie mit eigener Phasenprüfung.
- [ ] T035 [K] Gesamtabnahme nach dem ganzen Quickstart.
- [ ] T036 [C] Spielbeschreibung prüfen (immer die letzte Aufgabe des Features, nach der
  Gesamtabnahme und vor dem Merge; `docs/ki_workflow/ki_dev.md`, „Ablauf je Feature“): Claude
  gleicht `docs/spielbeschreibung/` mit dem Code ab und legt Klaus eine Liste vor, welche Dateien
  veralten und welche neu angelegt werden sollten, mit Grund, mindestens `titel-und-hauptmenue.md`,
  `darstellung.md`, `bilder.md`, `glossar.md` und `architektur.md` (CHK006). Abweichungen zwischen
  Spec und Code gehören dazu. Geändert wird erst nach Klaus' OK.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** (Style-Guide): keine; blockiert alles andere.
- **Phase 2** (Grafik): nach Phase 1; darf neben Phase 3 und 4 laufen; blockiert Phase 5.
- **Phase 3** (Baustein, US3): nach Phase 1.
- **Phase 4** (Seiten): nach Phase 3, weil T019 die Probeszene aus T013 umstellt.
- **Phase 5** (Titel, US1, US2): nach Phase 2, 3 und 4.
- **Phase 6** (Abschluss): nach Phase 5.

Die Code-Phasen 3, 4 und 5 laufen streng nacheinander, jede erst nach Klaus' Abnahme der vorigen
(Verfassung, Grundsatz II).

### User Story Dependencies

- **US3** (Baustein) ist die Grundlage; ohne sie gibt es nichts, worauf US1 und US2 stehen.
- **US1** und **US2** entstehen gemeinsam in Phase 5, weil der Titel als Ganzes umgebaut wird:
  Ein Hauptmenü auf dem Gerät mit Papier für die anderen Seiten hat der Spike als ungewollt
  erkannt (Spec, Clarifications).

### Within Each Phase

- Kern vor Szene, Szene vor Tests der Szene, Tests vor Lernnotiz; dann Claudes Prüfung,
  Phasenprüfung, Klaus' Abnahme, Commit.

### Parallel Opportunities

- T001 und T002 (Style-Guide und Prompt G-02).
- Phase 2 als Ganzes neben Phase 3 und 4: Klaus' und Claudes Grafikarbeit teilt keine Datei mit dem
  Code des Agents.
- Innerhalb der Code-Phasen kaum: T019 und T020 teilen `menu_paper.gd`, T026 bis T028 den Titel.

---

## Parallel Example: Phase 1 und 2 neben dem Code

```text
Claude: T001 Style-Guide ergänzen
Claude: T002 Prompt G-02 in die Prompt-Bibliothek
--- nach T003 ---
Klaus und Claude: T004 bis T010 Grafik
Agent (auf Klaus' Auftrag): T011 bis T014 Baustein Communicator
```

---

## Implementation Strategy

### Erst der Baustein, dann der Titel

1. Phase 1: Style-Guide, Klaus nimmt ab.
2. Phase 3: der Communicator mit Platzhalter, prüfbar in der Probeszene, ohne Titel.
3. Phase 4: Menü und Liste auf der Anzeige, der Titel noch auf Papier.
4. Phase 2 läuft nebenher, bis G-02 und T-02 freigegeben sind.
5. Phase 5: Umbau des Titels in einem Zug; hier entsteht der sichtbare Wert für den Spieler (US1,
   US2).
6. Phase 6: Lückensuche, Gesamtabnahme, Spielbeschreibung.

Ein früheres sichtbares Ergebnis als Phase 5 gibt es bewusst nicht: Ein halber Titel mit Gerät und
Papier wäre der Zustand, den der Spike verworfen hat.

---

## Notes

- Format: Task-ID, Besitzer, `[P]` für parallel ausführbar, `[Story]` für die User Story.
- Die Verfassung verlangt kein testgetriebenes Vorgehen; Tests entstehen mit der Logik und müssen
  vor der Abnahme grün sein.
- Zu jeder umgesetzten Task gibt es eine Lernnotiz in `specs/005-communicator/lernnotizen.md`
  (Verfassung, Grundsatz II). Bei `[A]`-Tasks schreibt sie der Agent, und Claude trägt sie nach
  jeder Phase ein.
- Nach dem Anlegen von Skripten ruft der Agent einmal `Godot --headless --path src --import` auf.
  Erst dabei bekommen neue Skripte ihre `.uid`, neue Bilder ihre `.import`, und Godot lernt neue
  `class_name` kennen. `.uid` und `.import` werden committet.
- **Feste Größen** für jeden Auftrag an den Agent:
  - Wege, Einträge, Texte, Hinweise, Vorwahl und Esc des Titels bleiben wie in Feature 004
    (FR-013); `test_title_texts.gd` läuft unverändert.
  - Bis Phase 5 sieht der Titel Pixel für Pixel aus wie vorher; alle Tests mit `look = PAPER`
    bleiben unverändert grün.
  - Die Hauptpalette `docs/art/hauptpalette.gpl` bleibt Byte für Byte gleich (R1).
  - Die Startprobe mit `-d` bleibt still.
- **Echte Daten:** Kein Test schreibt nach `user://spielstaende/`; jeder Test nutzt einen eigenen
  Ordner unter `user://`. Den echten Katalog fasst der Agent nicht an.
- **Nur ein Testlauf zur selben Zeit:** Alle Sitzungen teilen sich `user://` (`ki_pruefung.md`,
  „Tests“).
- Braucht der Agent einen Wert oder eine Regel, die der Style-Guide nach T001 nicht hat, hält er an
  und fragt (Grundsatz IV).
- Der Spike wird nie gemergt; der Agent liest ihn mit `git show 481c7e0:<pfad>` (R14).
