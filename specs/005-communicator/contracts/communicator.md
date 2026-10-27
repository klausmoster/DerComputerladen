# Vertrag: Baustein Communicator

Technischer Vertrag zum Steuerelement Communicator (FR-001 bis FR-008). Entscheidungen in
[research.md](../research.md) (R1 bis R8, R11), Zustände in [data-model.md](../data-model.md). Rümpfe
stehen hier bewusst nicht (Verfassung, Grundsatz II).

**Vorbedingung:** Baustein Communicator, Token `lcd` und die Abschnitte „Auf der Anzeige“ der
Bausteine Menü und Liste stehen im Style-Guide, und Klaus hat sie freigegeben (R12). Farben, Maße,
Lagen und Dauer kommen von dort, aus `UiPalette` und dem Theme; wo der Vertrag eine Konstante nennt,
trägt sie den Wert aus dem Style-Guide. Braucht der Agent etwas, das der Style-Guide nicht regelt,
hält er an und fragt.

## Dateien

```text
src/
├── ui/
│   ├── ui_palette.gd                    # geändert: LCD, Token &"lcd", 16 Farben
│   ├── computerladen_theme.tres         # geändert: Varianten LcdRow, LcdHeader
│   └── communicator/
│       ├── communicator.tscn            # neu
│       └── communicator.gd              # neu: class_name Communicator
├── scenes/title/
│   ├── menu_paper.gd                    # geändert: LCD-Fassung der Auswahl und Maße
│   ├── main_menu.gd                     # geändert: look
│   └── save_list.gd                     # geändert: look
└── test/
    ├── test_communicator.gd             # neu
    ├── test_main_menu.gd                # geändert: look = LCD
    ├── test_save_list.gd                # geändert: look = LCD
    ├── test_ui_palette.gd               # geändert: 16 Farben
    └── test_bilder.gd                   # geändert: lcd nicht in der Hauptpalette (R1)
```

`MenuPaper`, `MainMenu`, `SaveList` und `MenuHint` bleiben in `scenes/title/`, obwohl der
Communicator sie benutzt; ein Umzug nach `src/ui/` ist kein Teil dieses Features (offener Punkt für
den Spielbildschirm).

## Szenenaufbau

```text
Communicator (Control, Größe des Gehäuses)       communicator.gd
├── Case (TextureRect)                           Gehäuse ×2, Texture-Filter Nearest; bis G-02 der Platzhalter (R11)
├── Display (ColorRect)                          Anzeige in lcd, Lage und Größe aus dem Style-Guide
├── Hint (menu_hint.tscn)                        links neben dem Gehäuse, außerhalb der Anzeige
└── … Seiten                                     vom Bildschirm unter die Instanz gehängt, auf die Anzeige gestellt
```

Die Seiten sind direkte Kinder des Communicators, nach dessen eigenen Kindern; so liegen sie über der
Anzeige, ohne umgehängt zu werden, und die Pfade des Bildschirms wie `$Communicator/MainMenu` bleiben
gültig. Der Hinweis liegt außerhalb der Anzeige und überschneidet keine Seite.

Alle Teile lassen die Maus durch (`mouse_filter = IGNORE`), außer den Seiten selbst.

## Communicator

```gdscript
class_name Communicator
extends Control

## Die Fahrt herein oder hinaus ist zu Ende. [param arrived_in] true heißt Endlage, false draußen.
signal slide_finished(arrived_in: bool)

## Dauer einer Fahrt, aus dem Style-Guide (R6).
const SLIDE_SECONDS: float
## Größter Zeitschritt je Bild (R6): 1.0 / 30.0.
const MAX_STEP: float
## Lage und Größe der Anzeige im Gehäuse, aus dem Style-Guide.
const DISPLAY_RECT: Rect2i

## false: Fahrten springen sofort ans Ziel (Tests, später „Bewegung reduzieren“).
var animate: bool = true

## Lage in y, beim Setzen auf ganze Oberflächenpixel gerundet; der Tween schreibt hierhin.
var slide_y: float

## Stellt [param page] auf die Anzeige: Kind des Communicators, auf DISPLAY_RECT gestellt, unsichtbar.
func add_page(page: Control) -> void
## Zeigt [param page] und verbirgt jede andere Seite; erst verbergen, dann zeigen (Fokus).
## Der Communicator bewegt sich dabei nicht (FR-005).
func show_page(page: Control) -> void
## Die Seite, die gerade zu sehen ist, oder null.
func current_page() -> Control

## Stellt den Communicator ohne Fahrt unter das Bild.
func place_hidden() -> void
## Fährt in die Endlage; aus jeder Lage, auch mitten aus der Fahrt hinaus.
func slide_in() -> void
## Fährt unter das Bild; nimmt dabei sofort jede Eingabe weg (R8).
func slide_out() -> void
## Ob der Communicator in der Endlage steht oder dorthin fährt.
func is_in() -> bool
## Ob er gerade Eingaben annimmt: in der Endlage und auf der Fahrt herein, sonst nicht.
func accepts_input() -> bool

## Hinweis zu der Zeile [param row_rect] (global): links neben dem Gehäuse, oben bündig mit der Zeile.
func show_hint(text: String, row_rect: Rect2) -> void
## Wie show_hint(), als Meldung (Baustein Meldung).
func show_warning(text: String, row_rect: Rect2) -> void
func hide_hint() -> void
```

- **Seiten aus der Szene:** Controls, die ein Bildschirm in seiner Szene direkt unter die Instanz
  des Communicators hängt, stellt dieser in `_ready()` mit `add_page()` auf die Anzeige und
  verbirgt sie. `add_page()` hängt eine Seite, die noch kein Kind ist, als letztes Kind an.
- **Endlage** ist die Lage, die der Bildschirm dem Communicator in seiner Szene gibt; „draußen“ heißt
  Oberkante bei y 360.
- **Fahrt:** Tween auf `slide_y`, angehalten, in `_process()` mit `custom_step(minf(delta,
  MAX_STEP))` getaktet; herein `EASE_OUT`, hinaus `EASE_IN`, `TRANS_CUBIC` (R6). Eine neue Fahrt
  beendet die laufende und startet aus der aktuellen Lage.
- **Maus während der Fahrt herein:** Gewählt wird nur auf Bewegung oder Klick der Maus; eine Zeile,
  die unter dem ruhenden Zeiger durchfährt, wird nicht gewählt. Der Agent prüft, ob Godot dabei
  `mouse_entered` auslöst, und sperrt es sonst bis zur nächsten Bewegung.
- **Endlage** liegt auf ganzen Bildpixeln, also gerader Lage in x und y; unterwegs ganze
  Oberflächenpixel.
- **Eingabe während der Fahrt hinaus:** Der Fokus geht von der Seite weg, und keine Seite nimmt
  Maus oder Tastatur an, bis `slide_in()` kommt. Danach wählt der Bildschirm die Zeile neu.
- **Hinweis:** `show_hint()` rechnet aus `row_rect` nur die Oberkante; die rechte Kante des Hinweises
  liegt 4 vor der linken Kante des Gehäuses (R7). `MenuHint` braucht dafür eine Funktion, die an
  eine Lage statt neben eine Zeile stellt, oder der Communicator reicht ein umgerechnetes Rechteck;
  das entscheidet der Agent und nennt es im Bericht.

## Seiten: `look` an `MainMenu` und `SaveList`

```gdscript
## In beiden Klassen gleich.
enum Look { PAPER, LCD }
## Vorgabe PAPER wie bisher; LCD für die Anzeige des Communicators.
@export var look: Look = Look.PAPER
```

- `PAPER`: unverändert gegenüber Feature 004; alle bisherigen Tests bleiben.
- `LCD`: kein Papier, keine Lochränder, kein Zebra, kein Schatten; Auswahl über
  `MenuPaper.draw_lcd_selection()` (Balken `tusche`, Pfeil `lcd`, gedämpft `gehaeuse-dunkel`, R3);
  eine Rollmarke in der gewählten Zeile in `lcd`;
  Zeilen-Buttons mit Theme-Variante `LcdRow`, Kopfzeile mit `LcdHeader`; die Breite ist die Breite
  der Anzeige (`paper_width` bzw. `PAPER_WIDTH` gilt nur für `PAPER`). Die Spalten der Liste in
  ihren Labels nehmen die Farben der Zeile mit, auch invertiert.
- Bedienung, Signale, Rollen, Löschmodus und Rollmarken sind in beiden Fassungen gleich.

## UiPalette

- `const LCD := Color("<Wert aus dem Style-Guide>")`, Token `&"lcd"` in `TOKENS`.
- Der Kopfkommentar nennt 16 Farben und sagt, dass `lcd` nicht in der Hauptpalette steht (R1).
- `CATEGORY_TOKENS` bleibt.

## Theme

- `LcdRow` (Basis `Button`): Ark Pixel 12, `font_color` `tusche`, `font_focus_color`,
  `font_hover_color` und die gedrückten Farben `lcd`, `font_disabled_color` `gehaeuse-dunkel`,
  Styles leer wie `MenuRow`, Innenabstand links nach dem Style-Guide.
- `LcdHeader` (Basis `Label`): wie `MenuHeader`, Farbe `tusche`.
- Farben im Theme als Werte, gleich den Konstanten in `UiPalette`; ein Test vergleicht sie.

## Tests (`test_communicator.gd`)

- Fahrt Bild für Bild mit `_process()` und festen Zeitschritten: jede Lage ganzzahlig, keine über der
  Endlage, Endlage nach höchstens 250 ms bei 1/60 und 1/30 s je Bild und mit einem ersten Bild von
  0,5 s (SC-002, SC-003).
- Umkehr mitten in der Fahrt herein und hinaus, ohne Sprung.
- `slide_finished` einmal je Fahrt mit dem richtigen Wert; mit `animate = false` sofort.
- Probeseite: ein `MainMenu` mit drei `MenuEntry`, `look = LCD`, außerhalb des Titels in einer
  Testszene; Pfeil runter, Enter meldet den zweiten Eintrag. Der Test lädt nichts aus
  `res://scenes/title/title_screen.tscn` und keine `TitleTexts` (SC-005).
- Während der Fahrt hinaus lösen Enter, Leertaste und Linksklick nichts aus.
- Eine Zeile, die unter dem ruhenden Mauszeiger durchfährt, wird nicht gewählt; ein Klick auf das
  Gehäuse tut nichts.
- Der Hinweis steht links neben dem Gehäuse auf Höhe der Zeile und hat sich nach einer Fahrt um
  genau so viel bewegt wie der Communicator.
