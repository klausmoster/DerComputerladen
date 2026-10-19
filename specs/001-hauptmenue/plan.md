# Implementation Plan: Start bis zum Hauptmenü

**Branch**: `feature/001-hauptmenue` | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-hauptmenue/spec.md`

## Summary

Das Spiel wird als eigenständige Mac-App gebaut, startet per Doppelklick im Vollbild und lädt
bis zum Titelbildschirm mit Hauptmenü. Nur „Beenden“ ist verfügbar, die übrigen drei Einträge sind
sichtbar, aber gesperrt.

Technischer Ansatz (Details in [research.md](research.md), Vertrag in
[contracts/titelbildschirm.md](contracts/titelbildschirm.md)):
- **Darstellung:** Godot 4.7.2 mit Basis 640 × 360, Stretch-Modus `viewport` und ganzzahliger
  Skalierung, Nearest-Filter, Start in `MODE_FULLSCREEN`.
- **Titelszene:** Sie hat ein Menü auf Endlospapier. Je Eintrag gibt es einen `Button`, und Maus
  und Tastatur teilen sich Godots Fokus als einzige Auswahl. Gesperrte Buttons bleiben laut Probe
  in 4.7.2 fokussierbar.
- **Fenster:** Ein Autoload `GameWindow` schaltet mit Ctrl+Cmd+F um, setzt die Fenstergröße auf den
  größten ganzzahligen Faktor und hält die Mindestgröße.
- **Export:** Das Preset „macOS“ signiert ad hoc, ohne Beglaubigung, mit `high_res`.
- **Bilder:** Titelbild und Logo kommen per Flächenmittel aufs Bildraster und auf die
  Hauptpalette. Die Palette wird dafür erstmals erzeugt und eingefroren.
- **App-Symbol:** Es entsteht aus dem Monitor im Logo, als PNG und als Liquid-Glass-Symbol.

## Technical Context

**Language/Version**: GDScript, typisiert, Godot 4.7.2 (Forward+)

**Primary Dependencies**: Godot-Export-Vorlagen 4.7.2 (macOS); Schriften Pixelify Sans und Doto
(Google Fonts, SIL OFL 1.1); für die Bildvorbereitung `sips` (macOS) und Python 3.9 nur mit
Standardbibliothek; für das Liquid-Glass-Symbol Icon Composer aus Xcode 27.1

**Storage**: N/A, keine Spielstände

**Testing**: GUT 9.7.1 headless; Darstellung, Vollbild und Export von Hand nach
[quickstart.md](quickstart.md)

**Target Platform**: macOS (Entwicklungsrechner: macOS 27.0.1, Apple Silicon); Export als
Universal-Binary; Windows und Linux mit 11-03

**Project Type**: Desktop-Spiel (Godot-Projekt unter `src/`)

**Performance Goals**: höchstens 3 s bis zum bedienbaren Titelbildschirm (SC-001); Rückmeldung
auf Eingaben unter 100 ms (SC-003)

**Constraints**:
- Pixelgenau: Oberflächenraster 640 × 360, Bildraster 320 × 180, nur ganzzahlige Faktoren.
- Oberfläche nur in den 15 Farben des Style-Guides, Schrift ohne Kantenglättung.
- Nur Desktop mit Maus und Tastatur.

**Scale/Scope**: eine Szene mit vier Menüeinträgen, ein Autoload, ein Theme, ein Export-Preset,
drei Bild-Assets, zwei Schriften, zwei Werkzeugskripte

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Prüfung | Vor Phase 0 | Nach Phase 1 |
|---|---|---|---|
| I. Nur Desktop | macOS-Export, Maus und Tastatur, Forward+ bleibt, keine Touch-Eingaben | erfüllt | erfüllt |
| II. Klaus entscheidet, der Agent baut, Claude plant und prüft (Verfassung 2.0.0) | Der Plan enthält nur Signaturen, keine Rümpfe. Die Aufteilung `[K]`/`[A]`/`[C]` folgt in den Tasks; umgesetzt wird phasenweise auf Klaus' Auftrag, `/speckit-implement` wird nicht verwendet | erfüllt | erfüllt |
| III. Erst spezifizieren | Spec geklärt (fünf Fragen), eigener Branch, Godot-Details erst hier, Entscheidungen mit Alternativen in research.md | erfüllt | erfüllt |
| IV. Ein Look: der Style-Guide | Folgendes fehlt im Style-Guide, siehe „Vorarbeiten“ unten: Zustand „nicht verfügbar“, Hinweis, Startgrund, App-Symbol, Nachbearbeitung bei ungleichem Raster. Es wird vor dem Bauen ergänzt. | erfüllt mit Vorarbeit | erfüllt mit Vorarbeit |
| V. Daten sauber halten | game_bible unberührt, keine Spieldaten im Code | erfüllt | erfüllt |
| Technische Rahmenbedingungen | Godot 4.7, Projekt in `src/`, GUT; Timeline und GameClock unverändert | erfüllt | erfüllt |
| Arbeitsweise | deutsche Dokumente; `.uid`/`.import` neuer Assets werden committet; `export_presets.cfg` vor dem Commit prüfen; `build/` ignorieren | erfüllt | erfüllt |

Ergebnis: Die Prüfung ist bestanden, es gibt keine Verstöße, die begründet werden müssten.
Grundsatz IV ist nur dann erfüllt, wenn die Vorarbeiten am Style-Guide vor dem Bauen passieren.

## Project Structure

### Documentation (this feature)

```text
specs/001-hauptmenue/
├── plan.md                      # dieser Plan
├── research.md                  # Phase 0: Entscheidungen R1–R14
├── data-model.md                # Phase 1: Menüeintrag, Versionszeile, Zustände
├── quickstart.md                # Phase 1: Prüfanleitung
├── contracts/
│   └── titelbildschirm.md       # Phase 1: technischer Vertrag
├── checklists/
│   └── requirements.md          # Qualitätsprüfung der Spec
└── tasks.md                     # Phase 2, entsteht mit /speckit-tasks
```

### Source Code (repository root)

```text
src/                             # Godot-Projekt
├── project.godot                # geändert
├── export_presets.cfg           # neu
├── assets/{fonts,images,icon}/  # neu
├── core/game_window.gd          # neu, Autoload
├── ui/                          # neu: ui_palette.gd, computerladen_theme.tres
├── scenes/title/                # neu: Titelbildschirm, Menü, Eintrag, Hinweis
└── test/                        # neu: drei Testdateien

tools/raster/                    # neu: Palette und Rasterfassung (Python, außerhalb von Godot)
docs/art/                        # neu: hauptpalette.gpl, hauptpalette.png
build/                           # Export-Ziel, nicht versioniert
```

**Structure Decision**: Die vorhandene Aufteilung bleibt: `src/core/` für Autoloads,
`src/scenes/` für Szenen, `src/test/` für GUT. Neu sind `src/ui/` für Theme und Farben, die von
mehreren Szenen genutzt werden, und `src/assets/` für importierte Dateien. Die Originale aus
Leonardo bleiben in `docs/art/leonardo/`. Werkzeuge, die nicht ins Spiel gehören, liegen in
`tools/` außerhalb des Godot-Projekts, damit Godot sie nicht importiert. Einzelheiten stehen im
[Vertrag](contracts/titelbildschirm.md).

## Complexity Tracking

Keine Einträge, die Prüfung der Verfassung zeigt keine Verstöße.

## Vorarbeiten vor dem Bauen

Laut Grundsatz IV kommt zuerst der Style-Guide, dann das Feature. Ergänzt werden, mit den
Vorschlägen aus dem Review:

1. **Menü, Zustand „nicht verfügbar“:** Text und Pfeil in `gehaeuse-dunkel`, in Ruhe wie
   ausgewählt. Die Kontraste liegen bei 4,98 : 1 auf `papier`, 4,14 : 1 auf `endlos-gruen` und
   3,31 : 1 auf `signalgelb`. Das erfüllt die Regel für große Schrift (3 : 1), denn die
   12-Pixel-Schrift ist ab Faktor 2 mindestens 24 Bildschirmpixel hoch. Die bisherige Regel
   „gedämpfter Text in `gehaeuse-dunkel` nur auf `papier`“ wird für Menüeinträge erweitert.
2. **Hinweis:**
   - Feld in `papier` mit einem Oberflächenpixel `tusche` als Kontur und `pixelschatten`.
   - Text in Pixelify Sans `klein` (8) in `tusche`, höchstens 140 Oberflächenpixel breit.
   - Lage links neben der gewählten Zeile, 4 Oberflächenpixel Abstand. Er erscheint sofort, für
     Maus und Tastatur gleich.
3. **Startgrund:** `anzeige-grund` bis zum ersten Bild; die schwarzen Ränder der Skalierung
   bleiben, wie sie sind.
4. **App-Symbol:**
   - Motiv: der Monitor aus dem Ladenschild auf einem abgerundeten Quadrat in `nacht`.
   - Raster: Fläche 1024 × 1024 nach Apples Symbolraster, Monitor ganzzahlig vergrößert.
   - Zusätzlich eine Liquid-Glass-Fassung aus Icon Composer.
5. **Texte:** Der Spieler wird geduzt (R15).
6. **Nachbearbeitung, Schritt 2:** Flächenmittel statt Nearest Neighbor, wenn die gemalten Pixel
   ungleich groß sind (R6). Bei der Hauptpalette heißt es künftig „die ersten freigegebenen Bilder“
   statt „Szenen“ (R7).

## Entscheidungen aus dem Review

Im Review der Checkliste [review.md](checklists/review.md) hat Klaus entschieden:
- Anrede „du“.
- Ein Rechtsklick zeigt den Hinweis.
- Die Grundfläche des Symbols ist `nacht`.
- Die Rasterfassung gehört in dieses Feature, den groben Feinschliff macht Klaus.
- Leertaste und Tab gelten mit.
- Die Hand als Mauszeiger erscheint nur über verfügbaren Einträgen.
- Die Bundle-ID ist `de.klausmoster.dercomputerladen`.

Eingearbeitet in Spec, Datenmodell, Vertrag, Recherche und Quickstart.

Die übrigen 25 Punkte hat Claude vorgeschlagen, darunter die Hinweistexte, die Messmethoden und
die Vorarbeiten 1 bis 6. Klaus hat sie am 2026-10-19 freigegeben; alle 33 Punkte der Checkliste
sind erledigt.

## Offene Entscheidungen für Klaus

Keine. Die Rollenfrage ist entschieden: Der Godot-Agent `godot-entwickler` setzt die Arbeit in
Godot um, `[K]` bleibt für das, was Klaus selbst lernen will oder was nur im Editor, in
Grafikprogrammen oder mit seiner Entscheidung geht (Verfassung 2.0.0, Grundsatz II).
