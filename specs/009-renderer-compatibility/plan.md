# Implementation Plan: Renderer Compatibility

**Branch**: `feature/009-renderer-compatibility` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/009-renderer-compatibility/spec.md`

## Summary

Das Spiel wechselt auf allen drei Systemen von Forward+ auf Compatibility, damit es auf Rechnern wie
dem Boot-Camp-Mac startet. Technisch ist es eine Einstellung in `src/project.godot` plus zwei
gestrichene Forward+-Einstellungen (R1); für Compatibility bleiben alle Treiber und Rückfälle auf
Godots Vorgabe, unter macOS also Apples OpenGL. ANGLE ist in den Vorlagen für Windows und macOS fest
eingebaut, unter macOS läuft es über Metal (R2, belegt per Probestart). Das Protokoll des Selbsttests
liest schon, was läuft (R3); es bekommt nur zwei Anzeigenamen. Den Rest machen Tests, drei Läufe des
Selbsttests und die Regeln: erst Klaus' Beschluss in CLAUDE.md, Verfassung und Style-Guide, dann die
Einstellung (R7). Weil die Fotos nur das Bild in 640 × 360 zeigen, kommt je System ein Blick ins
echte Fenster dazu, auf dem Mac auch für die Werkstatt (R5, SC-007). Die Spec ist nach der
Checkliste vom 2026-10-29 angepasst (`checklists/review.md`).

## Technical Context

**Language/Version**: GDScript, Godot 4.7.2 stable

**Primary Dependencies**: Godot-Export-Vorlagen 4.7.2 (Windows, macOS, Linux); GUT 9.7.1; Python 3
für `tools/selbsttest/vergleich.py`

**Storage**: keine neuen Daten; Protokolle und Fotos des Selbsttests wie in Feature 007

**Testing**: GUT headless (`test_projekt_einstellungen.gd`, Tests des Selbsttests); Selbsttest-App
mit Fenster auf drei Rechnern, Vergleich mit den Referenzbildern

**Target Platform**: macOS (Apple Silicon, OpenGL 4.1 über Metal), Windows x86_64 (OpenGL 3.3, sonst
ANGLE über Direct3D 11), Linux x86_64 (OpenGL 3.3, unter X11 sonst OpenGL ES 3.0)

**Project Type**: Desktop-Spiel

**Performance Goals**: wie bisher; ein Selbsttest-Lauf auf dem Mac in rund 5 bis 8 s (007)

**Constraints**: Bild Pixel für Pixel gleich den Referenzbildern oder jede Abweichung von Klaus
beurteilt; keine Startoption und keine Zusatzdatei beim Spieler

**Scale/Scope**: eine Einstellungsdatei, zwei Skripte des Selbsttests (`selbsttest_system.gd`,
`selbsttest_texte.gd`), drei Testskripte (`test_projekt_einstellungen.gd`, `test_selbsttest_system.gd`,
dazu Beispieldaten in `test_selbsttest_protokoll.gd` und `test_selbsttest_ergebnis.gd`) und drei
Vorlagen unter `fixtures/selbsttest/`; Regeln und Doku an rund 15 Stellen (R6)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Stand | Bemerkung |
|---|---|---|
| I. Nur Desktop | **Verstoß bis Phase 2, dann erfüllt** | Grundsatz I verlangt heute Forward+. Klaus hat den Wechsel am 2026-10-28 entschieden und den Wortlaut am 2026-10-29 geklärt (FR-009). Phase 2 ändert die Regel, bevor Phase 3 die Einstellung ändert (R7). Mobile, Android und Touch bleiben ausgeschlossen. |
| II. Klaus entscheidet | erfüllt | Regel, Style-Guide-Satz, neue Referenzbilder und `export_angle` nur auf Klaus' Wort; phasenweise Freigabe; Lernnotizen in `lernnotizen.md`. |
| III. Erst spezifizieren | erfüllt | Spec und Klärung committet; Entscheidungen mit verworfener Alternative in Spec und `research.md`. |
| IV. Style-Guide | erfüllt | Palette, Raster, Schriften unverändert; neuer Satz kommt zuerst in den Style-Guide (FR-009a), bevor irgendetwas sich darauf beruft. |
| V. Daten | nicht berührt | |
| VI. Prüfen | erfüllt | Prüfer je Phase unten; was messbar ist, prüfen Tests und der Bildvergleich. |
| Technische Rahmenbedingungen | erfüllt | Godot 4.7, GUT 9.7.1, Autoloads unverändert. |

**Nach dem Entwurf erneut geprüft (2026-10-29):** unverändert. Der einzige Verstoß ist der gewollte
gegen Grundsatz I; er steht unter „Complexity Tracking“ und endet mit Phase 2.

## Prüfer je Phase

| Phase | Ändert | Prüfer |
|---|---|---|
| Phase 1: Vorbereitung (Godot-Referenz) | nichts davon | keine |
| Phase 2: Regeln (CLAUDE.md, Verfassung, Style-Guide) | Regeln, ein Satz im Style-Guide | keine; der Style-Guide ist selbst der Maßstab, Klaus gibt den Wortlaut frei |
| Phase 3: Umstellung (Einstellung, Anzeigenamen, Tests) | Code, Texte (Anzeigenamen im Protokoll und auf der Zusammenfassung) | Architektur, Text |
| Phase 4: Läufe auf drei Systemen | nichts davon; Referenzbilder nur nach Klaus' Abnahme. Ändert T026 doch `project.godot` oder `export_presets.cfg` (ANGLE über Metal, `export_angle`), dann Code | keine; im Ausnahmefall Architektur (T026a) |
| Phase 5: Doku (Feature 007, Spielbeschreibung, offene Punkte) | Doku | keine |

Das Bild selbst prüft kein Prüfer, sondern der Vergleich mit den Referenzbildern in Phase 4.

## Ausnahmen vom Leitfaden

Keine.

## Phasen im Überblick

Grundlage für `/speckit-tasks`; die Aufgaben selbst entstehen dort.

1. **Vorbereitung** `[C]`: Godot-Referenz im Arbeitsordner (erste Aufgabe aus der Vorlage; am
   2026-10-29 schon erzeugt).
2. **Regeln** `[K]`, `[C]`: Klaus beschließt den Wortlaut aus FR-009; Claude ändert CLAUDE.md und über
   `/speckit-constitution` die Verfassung auf 3.0.0 (R6); Claude legt den Satz für den Style-Guide vor
   und veröffentlicht ihn nach Klaus' OK. Abnahme durch Klaus.
3. **Umstellung** `[A]`, `[C]`: `project.godot` nach [contracts/renderer.md](contracts/renderer.md);
   `GRAFIK_API` zieht nach `SelbsttestTexte`, mit zwei neuen Namen; Tests der Projekteinstellungen
   neu (R4); Beispieldaten der Tests, alle fünf Dateien (R3). Claude sieht im Quelltext nach, was
   Godot ohne OpenGL 3.3 meldet (R8). Claude prüft: Tests zweimal, Probestart nach dem Quickstart mit
   der Zeile „Compatibility“, Phasenprüfung. Abnahme durch Klaus.
4. **Läufe** `[C]`, `[K]`: Claude baut mit `tools/build/baue_alles.sh` und lässt den Selbsttest auf
   dem Mac laufen; Klaus auf Linux und dem Boot-Camp-Rechner, dort auch mit `opengl3_angle`;
   Parallels nach Lust. Claude vergleicht und legt Belege unter `belege/` ab. Abweichungen gehen an
   Klaus (R5). Dazu der Blick ins echte Fenster (SC-007): auf dem Mac Bildschirmfotos von Start,
   krummer Fenstergröße und Werkstatt durch Claude, unter Windows und Linux durch Klaus nach der
   Prüfliste. Das ist zugleich der Selbsttest aus der Aufgaben-Vorlage.
5. **Doku** `[C]`: Vermerke in Feature 007, Spielbeschreibung, offene Punkte, Vermerk in
   `renderer.md` (R6). Abnahme durch Klaus.

Danach wie immer: Lückensuche mit `/speckit-converge`, Gesamtabnahme, Spielbeschreibung abgleichen,
Tagebuch, Merge. Eine Bestandsprüfung fällt nicht an: 009 beginnt keine neue Schicht und endet nicht
auf 3 oder 8.

## Project Structure

### Documentation (this feature)

```text
specs/009-renderer-compatibility/
├── spec.md
├── plan.md              # diese Datei
├── research.md          # R1 bis R7
├── data-model.md        # nur geänderte Werte im Protokoll
├── quickstart.md        # Tests, Probestart, drei Läufe, Suche nach Forward+
├── contracts/
│   └── renderer.md      # Einstellungen, Presets, Anzeigenamen, erwartete Protokollwerte
├── checklists/
│   └── requirements.md
├── belege/              # Phase 4: Läufe je System
├── lernnotizen.md       # ab Phase 3
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
src/
├── project.godot                                   Renderer, Forward+-Einstellungen gestrichen
├── tools/selbsttest/selbsttest_system.gd           liest GRAFIK_API aus SelbsttestTexte
├── tools/selbsttest/selbsttest_texte.gd            GRAFIK_API mit ANGLE und OpenGL ES (R3)
└── test/
    ├── test_projekt_einstellungen.gd               Tests zum Renderer neu (R4)
    ├── test_selbsttest_protokoll.gd                Beispieldaten
    ├── test_selbsttest_ergebnis.gd                 Beispieldaten
    └── fixtures/selbsttest/                        Beispieldaten: kopieren_erwartet.txt,
                                                    protokoll_erwartet.txt,
                                                    kopieren_nicht_beschreibbar.txt

tools/selbsttest/referenz/macos/                    nur bei Abweichung und nach Klaus' Abnahme

CLAUDE.md, .specify/memory/constitution.md          Regel (Phase 2)
docs/spielbeschreibung/, docs/offene-punkte.md,
docs/entscheidungen/renderer.md,
specs/007-build-export-selbsttest/                  Doku (Phase 5)
```

**Structure Decision**: Kein neuer Ordner im Spiel. Geändert wird an den Stellen, die Feature 007
für den Renderer angelegt hat.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Grundsatz I „Der Renderer bleibt Forward+“ | Forward+ startet auf dem Boot-Camp-Rechner und in Parallels nicht und zeigt keine Meldung; genau dort spielt die Zielgruppe (`renderer.md`). Klaus hat den Wechsel entschieden. | Startoption oder `override.cfg` beim Spieler: Er müsste erst wissen, dass er sie braucht. Compatibility nur unter Windows: zwei Renderer zu prüfen. Der Verstoß endet mit Phase 2, die die Regel vor der Einstellung ändert. |
