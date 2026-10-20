# Vertrag: Titelbildschirm, Hauptmenü und macOS-App

Technischer Vertrag zu [spec.md](../spec.md), Entscheidungen in [research.md](../research.md),
Daten in [data-model.md](../data-model.md). Er legt fest, was gebaut wird und wie die Teile
zusammenhängen, damit beim Bauen und Zuarbeiten niemand raten muss. Rümpfe stehen hier bewusst
nicht; die Umsetzung folgt Grundsatz II der Verfassung.

Bezeichner im Code sind englisch wie im übrigen Projekt (`GameClock`, `timeline_demo`), Texte im
Spiel deutsch. GDScript ist durchgehend typisiert.

## Dateien

```text
src/
├── project.godot                      # geändert, siehe „Projekteinstellungen“
├── export_presets.cfg                 # neu, entsteht beim ersten Export; vor dem Commit ansehen
├── assets/
│   ├── fonts/
│   │   ├── ark-pixel-10px-proportional-latin.otf   # `text`, + OFL-ArkPixel.txt
│   │   ├── ark-pixel-12px-proportional-latin.woff2 # `menue`
│   │   └── Doto-Variable.ttf          # `drucker`, + OFL-Doto.txt
│   ├── images/
│   │   ├── title_t01.png              # 320 × 180, indiziert, Hauptpalette
│   │   └── logo_ladenschild.png       # etwa 142 × 27, indiziert, mit Transparenz
│   └── icon/
│       ├── app_icon.png               # 1024 × 1024
│       └── app_icon.icon/             # Liquid-Glass-Symbol aus Icon Composer, mit .gdignore
├── core/
│   └── game_window.gd                 # Autoload GameWindow
├── ui/
│   ├── ui_palette.gd                  # class_name UiPalette
│   └── computerladen_theme.tres       # Theme des ganzen Spiels
├── scenes/
│   └── title/
│       ├── title_screen.tscn / .gd    # class_name TitleScreen, neue Hauptszene
│       ├── main_menu.tscn / .gd       # class_name MainMenu
│       ├── menu_entry.gd              # class_name MenuEntry (Resource)
│       └── menu_hint.tscn / .gd       # class_name MenuHint
└── test/
    ├── test_main_menu.gd
    ├── test_game_window.gd
    └── test_title_screen.gd

tools/raster/                          # Repo-Root, außerhalb des Godot-Projekts
├── make_palette.py                    # Hauptpalette per Median-Cut
├── rasterize.py                       # Flächenmittel + Palette → indiziertes PNG
├── cleanup.py                         # grober Feinschliff per Regel: Farbreste, Einzelpixel
├── make_icon.py                       # App-Symbol 1024 × 1024 und Ebenen für Icon Composer
└── README.md                          # Aufruf und Reihenfolge

docs/art/
├── hauptpalette.gpl                   # 256 Farben, eingefroren
├── hauptpalette.png                   # Farbtafel zum Ansehen
└── app_icon/                          # Ebenen für Icon Composer: Monitor freigestellt, Grundfarbe

.gitignore                             # ergänzt um /build/
```

Jede neue Datei unter `src/` bekommt beim Import ihre `.uid` bzw. `.import`; beide werden
mitcommittet (Verfassung, Arbeitsweise).

## Szenenaufbau

```text
TitleScreen (Control, füllt 640 × 360)              title_screen.gd
├── Background (TextureRect)       title_t01.png, 640 × 360, stretch_mode SCALE → genau ×2
├── LogoBlock (VBoxContainer)      Position laut Titelscreen-Entwurf (x 14, y 12)
│   ├── Logo (TextureRect)         logo_ladenschild.png, ×2
│   └── Subtitle (Label)           „WIRTSCHAFTSSIMULATION · 1985–1999“, Variante Subtitle
├── MainMenu (Instanz main_menu.tscn)   Position x 472, y 150, Breite 144
├── MenuHint (Instanz menu_hint.tscn)   links neben der gewählten Zeile
└── VersionLine (Label)            unten links (x 16, Unterkante 6 über dem Rand, also y 354), Variante VersionLine

MainMenu (Control)                 main_menu.gd: zeichnet Papier, Zeilen, Lochränder,
│                                  Auswahl und Pfeil in _draw()
└── Rows (VBoxContainer)           Abstand 0, links und rechts je 12 frei für Lochrand und Pfeil
    ├── Header (Label)             „HAUPTMENÜ“, Variante MenuHeader, 20 hoch
    └── je Eintrag ein Button      in _ready() aus `entries` erzeugt, Variante MenuRow, 20 hoch

MenuHint (PanelContainer)          menu_hint.gd, Variante HintPanel
└── Text (Label)                   Variante HintLabel, mit Zeilenumbruch
```

## Klassen

**`src/scenes/title/menu_entry.gd`**: `class_name MenuEntry extends Resource`

```gdscript
@export var id: StringName              # &"new_game" | &"load_game" | &"settings" | &"quit"
@export var label: String
@export var available: bool = false
@export_multiline var hint: String
```

**`src/scenes/title/main_menu.gd`**: `class_name MainMenu extends Control`

```gdscript
signal entry_activated(id: StringName)                   # nur für verfügbare Einträge
signal selection_changed(entry: MenuEntry, row_rect: Rect2)

const ROW_HEIGHT := 20

@export var entries: Array[MenuEntry] = []

func select(index: int) -> void         # setzt Fokus auf Zeile index, mit Umlauf
func selected_index() -> int
func selected_entry() -> MenuEntry
func activate_selected() -> void        # löst nur aus, wenn der Eintrag verfügbar ist
```

Verbindlich:
- Je Eintrag ein `Button` mit `text = label`, `disabled = not available`,
  `theme_type_variation = &"MenuRow"` und `mouse_default_cursor_shape` `CURSOR_POINTING_HAND`
  bei verfügbaren, `CURSOR_ARROW` bei nicht verfügbaren Einträgen (FR-018).
- `mouse_entered` ruft `grab_focus()` auf. Es gibt also nur eine Auswahl, den Fokus (FR-011).
- `focus_entered` aktualisiert die Auswahl, ruft `queue_redraw()` auf und sendet
  `selection_changed`.
- `focus_neighbor_top` des ersten und `focus_neighbor_bottom` des letzten Buttons zeigen
  aufeinander (Umlauf, FR-010), ebenso `focus_previous` des ersten und `focus_next` des letzten,
  damit Tab das Menü nie verlässt, auch wenn später andere Bedienelemente daneben stehen.
- `pressed` sendet `entry_activated(id)`. Ein gesperrter Button löst `pressed` nicht aus.
  Enter und Leertaste kommen über Godots `ui_accept`, Tab und Shift+Tab über
  `ui_focus_next`/`ui_focus_prev`; dafür ist außer den Nachbarn an den Enden kein Code nötig.
- `gui_input` jedes Buttons fängt die rechte Maustaste ab: Zeile fokussieren, Ereignis als
  behandelt markieren, nichts auslösen (FR-009).
- Nach dem Aufbau wird Zeile 0 gewählt (`select(0)`, zeitversetzt per `call_deferred`).
- `_draw()` malt:
  - die Zeilen abwechselnd in `papier` und `endlos-gruen`,
  - die Lochränder links und rechts,
  - die gewählte Zeile in `signalgelb` mit Pfeil in `tusche`, bei nicht verfügbarem Eintrag in
    `gehaeuse-dunkel`, ohne zusätzliche Fokuslinie,
  - darunter den `pixelschatten`.

**`src/scenes/title/menu_hint.gd`**: `class_name MenuHint extends PanelContainer`

```gdscript
func show_for(entry: MenuEntry, row_rect: Rect2) -> void   # Text setzen, neben row_rect stellen
func hide_hint() -> void
```

**`src/scenes/title/title_screen.gd`**: `class_name TitleScreen extends Control`

```gdscript
const STAGE := "PROTOTYP"

static func version_text(version: String) -> String   # "0.1" → "V0.1 · PROTOTYP", "" → "PROTOTYP"
func _on_main_menu_entry_activated(id: StringName) -> void        # &"quit" → get_tree().quit()
func _on_main_menu_selection_changed(entry: MenuEntry, row_rect: Rect2) -> void   # → MenuHint
```

Die vier `MenuEntry` liegen als Unter-Resources in `title_screen.tscn` am `MainMenu`, mit den
Werten aus dem [Datenmodell](../data-model.md).

**`src/core/game_window.gd`**: Autoload `GameWindow`, `extends Node`

Registriert in `src/project.godot` unter `[autoload]` als
`GameWindow="*res://core/game_window.gd"`.

```gdscript
const BASE_SIZE := Vector2i(640, 360)

func toggle_fullscreen() -> void        # MODE_FULLSCREEN ↔ MODE_WINDOWED
func is_fullscreen() -> bool
static func best_factor(usable: Vector2i, decorations: Vector2i) -> int   # immer ≥ 1
```

Verbindlich:
- In `_ready()`: Läuft Godot headless (`DisplayServer.get_name() == "headless"`), tut der
  Autoload nichts. Sonst setzt er `get_window().min_size = BASE_SIZE`.
- Den Wechsel des Fenstermodus erkennt `_process()`: Es vergleicht den Modus mit dem des
  vorigen Bilds. Ein Signal dafür gibt es nicht, denn bei Stretch `viewport` meldet
  `size_changed` nur den Viewport, und der bleibt 640 × 360.
- `_unhandled_input()` reagiert auf die Aktion `toggle_fullscreen`.
- Wechselt der Modus ins Fenster (gleich ob per Kürzel oder grünem Knopf), gilt nach dem Ende
  des Übergangs:
  - Faktor `best_factor(screen_get_usable_rect(window_get_current_screen()).size, Titelleiste)`;
    die Titelleiste ergibt sich aus `window_get_size_with_decorations() − Fenstergröße`.
  - Danach `size = BASE_SIZE * Faktor` und `move_to_center()`.
- `best_factor` rechnet `min((usable.x − decorations.x) / 640, (usable.y − decorations.y) / 360)`
  ganzzahlig, mindestens 1.
- Das Ende des Übergangs: Beim grünen Knopf meldet Godot das Fenster erst, wenn macOS fertig
  ist. Nach dem Kürzel meldet es den Wechsel sofort; GameWindow wartet dann `TRANSITION_MSEC`
  (1000) ab dem Umschalten.
- Ob macOS die Größe nach dem Übergang übernimmt, prüft Klaus in der gebauten App (T031).

**`src/ui/ui_palette.gd`**: `class_name UiPalette extends RefCounted`

Die 15 Oberflächenfarben aus dem Style-Guide als Konstanten, Namen wie die Tokens:

```gdscript
const TUSCHE := Color("1d1916")
# … NACHT, NACHT_HELL, GEHAEUSE_DUNKEL, GEHAEUSE, GEHAEUSE_HELL, PAPIER, ENDLOS_GRUEN,
#   ANZEIGE_GRUND, ANZEIGE, KASSENROT, SIGNALGELB, PETROL, HOLZ, HOLZ_DUNKEL
```

Die Werte kommen aus `tokens.json` des Style-Guides und werden nicht von Hand verändert.

## Theme `src/ui/computerladen_theme.tres`

Projektweit gesetzt über `gui/theme/custom`. Standardschrift ist `text`: Ark Pixel 10, Größe 10.

| Variante | Basis | Inhalt |
|---|---|---|
| `MenuRow` | Button | `menue`: Ark Pixel 12, Größe 12, `tusche`; nicht verfügbar `gehaeuse-dunkel` (Vorschlag für den Style-Guide, Kontrast ≥ 3 : 1); alle Styleboxen leer, auch `focus`; links 12 frei für den Pfeil |
| `MenuHeader` | Label | `drucker`: Doto, Gewicht 600, Größe 10, Laufweite 1, `tusche`, mittig |
| `Subtitle` | Label | `drucker`: Doto, Gewicht 600, Größe 10, Laufweite 1, `papier`, Schatten `tusche` um (1, 1) |
| `VersionLine` | Label | `drucker`: Doto, Gewicht 600, Größe 10, Laufweite 1, `papier`, Schatten `tusche` um (1, 1) |
| `HintPanel` | PanelContainer | laut Style-Guide: `papier`, Kontur 1 `tusche`, `content_margin` 5 (Kontur 1 und Innenabstand 4); der Kasten ist höchstens 160 breit |
| `HintLabel` | Label | laut Style-Guide: `text` in `tusche`, `line_spacing` 0 (Ark Pixel 10 ist 14 hoch), Umbruch bei 150 |

Ark Pixel ist je Größe eine eigene, statische Datei: kein Gewicht, kein Wortabstand, jede Größe
nur in ihrer Entwurfsgröße. Doto bekommt Gewicht und Laufweite über eine `FontVariation`
(`variation_opentype`, `spacing_glyph`); `MenuHeader`, `Subtitle` und `VersionLine` teilen sich
diese eine (`drucker`).
Import der Schriften und Sichtprobe: siehe research.md, R8.

## Projekteinstellungen (`src/project.godot`)

| Schlüssel | Wert | Bisher |
|---|---|---|
| `application/run/main_scene` | `res://scenes/title/title_screen.tscn` | `timeline_demo.tscn` |
| `application/config/version` | `0.1` | leer |
| `application/config/icon` | `res://assets/icon/app_icon.png` | `res://icon.svg` |
| `application/boot_splash/show_image` | `false` | `true` |
| `application/boot_splash/bg_color` | `anzeige-grund` (#0d1716) | Grau |
| `display/window/size/viewport_width` / `_height` | 640 / 360 | 1152 / 648 |
| `display/window/size/mode` | 3 (Fullscreen) | 0 |
| `display/window/stretch/mode` | `viewport` | `disabled` |
| `display/window/stretch/aspect` | `keep` | `keep` |
| `display/window/stretch/scale_mode` | `integer` | `fractional` |
| `gui/theme/custom` | `res://ui/computerladen_theme.tres` | leer |
| `rendering/textures/canvas_textures/default_texture_filter` | 0 (Nearest) | 1 (Linear) |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | `true` | `false` |
| `rendering/2d/snap/snap_2d_vertices_to_pixel` | `true` | `false` |
| `rendering/environment/defaults/default_clear_color` | `anzeige-grund` | Grau |
| `rendering/textures/vram_compression/import_etc2_astc` | `true` (für den Export `universal` und `arm64` nötig; ändert an unseren verlustfreien Texturen nichts) | `false` |
| `[autoload] GameWindow` | `*res://core/game_window.gd` | – |

Eingabe-Aktion `toggle_fullscreen`: Taste F mit Ctrl und Cmd (Meta), physische Taste. Windows
und Linux bekommen ihre Kürzel mit 11-03.

## Export-Preset „macOS“

| Option | Wert |
|---|---|
| Exportpfad | `../build/macos/Der Computerladen.app` (relativ zu `src/`) |
| `binary_format/architecture` | `universal` |
| `codesign/codesign` | Built-in (ad-hoc only) |
| `notarization/notarization` | aus |
| `display/high_res` | an |
| `application/bundle_identifier` | `de.klausmoster.dercomputerladen` |
| `application/short_version` / `version` | leer: Godot übernimmt `application/config/version` (0.1) in beide Felder der `Info.plist`; die Nummer wird nur in `project.godot` gepflegt |
| `application/icon` | `res://assets/icon/app_icon.png` |
| `application/liquid_glass_icon` | `res://assets/icon/app_icon.icon` |
| `exclude_filter` | `addons/gut/*, test/*`: GUT und die Tests kommen nicht in die App |

`export_presets.cfg` schreibt Godot selbst; Geheimes legt es getrennt in
`.godot/export_credentials.cfg` ab, das nicht versioniert wird.

## Tests (GUT 9.7.1)

| Datei | Prüft |
|---|---|
| `test_main_menu.gd` | vier Einträge in der richtigen Reihenfolge; nur `quit` verfügbar; Startauswahl 0; Pfeil runter/hoch mit Umlauf; `activate_selected()` sendet bei nicht verfügbaren Einträgen nichts und bei `quit` genau einmal `entry_activated(&"quit")`; `select()` sendet `selection_changed`; Rechtsklick wählt die Zeile und sendet kein `entry_activated`; Mauszeiger je Eintrag nach `available` |
| `test_game_window.gd` | `best_factor` für 1080p, 1440p, 4K, MacBook-Bildschirm und zu kleine Flächen (dann 1) |
| `test_title_screen.gd` | `version_text("0.1")` und `version_text("")` |

## Nicht dazu gehört

- Export für Windows und Linux, Signieren mit Developer-ID, Beglaubigung (→ 11-03)
- Einstellungsbildschirm, Spielstände (→ 11-01), Ton und Musik (→ 11-02)
- Ein spielbarer Bildschirm hinter „Neues Spiel“, ein Pausenmenü oder ein Rückweg zum Titel
- Animation im Titelbild, Parallax, SubViewport für Szenen (→ 10-02)
- Eigene Tastenkürzel je Eintrag, Lokalisierung in andere Sprachen
