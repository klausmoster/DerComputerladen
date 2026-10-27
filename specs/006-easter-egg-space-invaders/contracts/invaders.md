# Vertrag: Das Spiel auf der Anzeige

Kern, Muster und Seite von Space Invaders (Spec, FR-010 bis FR-017, FR-020, FR-021, FR-030, FR-031,
FR-040, FR-044). Entscheidungen in [research.md](../research.md) R6 bis R11, Zustände in
[data-model.md](../data-model.md). Rümpfe stehen hier bewusst nicht (Verfassung, Grundsatz II).

**Vorbedingung:** Der Abschnitt „Spiel auf der Anzeige“ steht im Style-Guide mit Feld, Maßen,
Pixelmustern und Ergebnisanzeige, und Klaus hat ihn freigegeben (R12). Die Zahlen in R7 sind Vorschläge;
die Konstanten tragen die Werte aus dem Style-Guide. Für die Seite sind außerdem die Töne aus
[ton.md](ton.md) da.

## Dateien

```text
src/scenes/title/
├── invaders/
│   ├── invaders_game.gd                 # neu: class_name InvadersGame, der Kern ohne Node
│   ├── invaders_sprites.gd              # neu: class_name InvadersSprites, Pixelmuster als Daten
│   ├── invaders_page.gd                 # neu: class_name InvadersPage, die Seite
│   └── invaders_page.tscn               # neu: Seite mit ihren AudioStreamPlayern
└── title_texts.gd                       # geändert: Kopfzeile und Ergebnisanzeige (R10)
src/test/
├── test_invaders_game.gd                # neu: Kern
├── test_invaders_sprites.gd             # neu: Muster
├── test_invaders_page.gd                # neu: Seite mit erfundenen Eingaben
└── fixtures/invaders_probe.tscn / .gd   # neu: Seite auf einem Communicator, ohne Titel
```

## InvadersGame

```gdscript
class_name InvadersGame
extends RefCounted

enum State { PLAYING, RESPAWN, WON, LOST }
enum LostReason { NONE, HIT, LANDED }
enum Event { SHOT, ALIEN_HIT, MARCH, CANNON_HIT, WON, LOST }

## Ein Schritt in Sekunden: 1/60.
const STEP: float
## Größe des Felds in Bildpixeln: 160 × 80 (Style-Guide).
const FIELD := Vector2i(160, 80)
## Weitere Maße und Tempi aus R7 und dem Style-Guide als Konstanten an einer Stelle.

## Neue Partie mit [param seed] für die Bomben.
func _init(seed: int) -> void

## Ein Schritt. [param left], [param right]: gehalten; [param fire]: neuer Druck in diesem Schritt.
## Gibt die Ereignisse dieses Schritts zurück, je als { "event": Event, ... } (MARCH mit "note" 0–3,
## ALIEN_HIT mit "row" und "points").
func step(left: bool, right: bool, fire: bool) -> Array[Dictionary]

var state: State          # nur lesen
var lost_reason: LostReason
var score: int
var lives: int
var cannon_x: int
var march_frame: int
## Alles, was zu malen ist, je als { "sprite": StringName, "frame": int, "pos": Vector2i }:
## Außerirdische, Kanone (nicht in RESPAWN), Schuss, Bomben, Explosionen.
func drawables() -> Array[Dictionary]
## Wie viele Außerirdische übrig sind.
func aliens_left() -> int
```

In `WON` und `LOST` ändert `step()` nichts mehr und gibt eine leere Liste. Gleicher Seed und gleiche
Eingaben ergeben dieselbe Partie.

## InvadersSprites

```gdscript
class_name InvadersSprites
extends RefCounted

## Je Muster eine Liste von Bildern, jedes Bild eine Liste gleich langer Strings; "#" ist tusche,
## "." leer. Schlüssel: &"alien_a", &"alien_b", &"alien_c" (je 2 Bilder, 8 × 6), &"cannon" (9 × 5),
## &"shot", &"bomb", &"explosion", &"life" (Leben in der Kopfzeile).
const PATTERNS: Dictionary

## Die gesetzten Pixel von [param sprite], Bild [param frame], relativ zur linken oberen Ecke.
static func pixels(sprite: StringName, frame: int) -> Array[Vector2i]
## Größe in Bildpixeln.
static func size_of(sprite: StringName) -> Vector2i
```

Die Muster sind die aus dem Style-Guide, Zeichen für Zeichen. Welche Art in welcher Reihe steht, sagt
der Style-Guide (oben `alien_a` für 30 Punkte, Mitte `alien_b` für 20, unten `alien_c` für 10).

## InvadersPage

```gdscript
class_name InvadersPage
extends Control

## Das Spiel ist vorbei: nach der Ergebnisanzeige oder durch Esc. Der Bildschirm kehrt zurück.
signal finished

## true: Die Seite taktet sich selbst in _process(). false: Tests takten mit advance().
var autoplay: bool = true

## Beginnt eine neue Partie, nimmt den Fokus. [param seed] -1 heißt zufällig.
func start(seed: int = -1) -> void
## Taktet um [param seconds] weiter, mit festem Schritt und höchstens 4 Schritten je Aufruf (R6).
func advance(seconds: float) -> void
## Die laufende Partie (Tests).
func game() -> InvadersGame
## Ob die Ergebnisanzeige steht und eine Taste annimmt.
func is_waiting_for_key() -> bool
```

**Eingabe** (R9): in `_gui_input()`, jede Taste ohne Cmd, Strg oder Alt mit `accept_event()`. Tasten
mit Cmd, Strg oder Alt und die Aktion `toggle_fullscreen` gehen durch (Review, CHK006). Shift, Strg,
Alt und Cmd allein zählen in der Ergebnisanzeige nicht als Taste (CHK009).

| Eingabe | läuft | Ende, gesperrt (0,5 s) | Ende, wartet |
|---|---|---|---|
| Pfeil links/rechts halten | fährt | – | `finished` bei neuem Druck |
| Leertaste neu gedrückt | Schuss | – | `finished` |
| andere Taste | nichts | – | `finished` |
| Esc | `finished` | `finished` | `finished` |
| Linksklick auf die Seite | nichts | – | `finished` |
| Rechts- oder Mittelklick, Mausrad | nichts | – | nichts |

Echo-Ereignisse zählen nie als neuer Druck. Verliert die Seite den Fokus, während sie zu sehen ist,
holt sie ihn zurück (`focus_exited` → `grab_focus` deferred). Die Seite zeigt keinen Fokusrahmen
(CHK025); der Zeiger über ihr ist immer der Pfeil (CHK022).

**Malen:** `_draw()` füllt nichts (der Grund ist die Anzeige in `lcd`) und malt jedes Pixel aus
`drawables()` als 2 × 2 Oberflächenpixel in `UiPalette.TUSCHE`. Die Kopfzeile: Punkte als Text in
`drucker` wie `LcdHeader`, ab dem Innenrand links, und die Leben als Muster `life`, rechtsbündig am
Innenrand (R7; Review, CHK005, CHK023). Die Ergebnisanzeige (R10): Zeilen 1 und 2 in `drucker`,
Zeile 3 in `menue` wie `LcdRow`, Zeilenhöhe 20, als Block mittig; vom Feld bleibt nur die
Kopfzeile (CHK024).

**Töne** (`invaders_page.tscn`, je ein `AudioStreamPlayer` auf `Effekte`):

| Ereignis | Ton |
|---|---|
| `SHOT` | `schuss.wav` |
| `ALIEN_HIT` | `treffer.wav` |
| `MARCH` | `marsch_1.wav` … `marsch_4.wav` nach `note` |
| `CANNON_HIT` | `kanone.wav` |
| `WON` / `LOST` | `sieg.wav` / `niederlage.wav` |

Die vier Marschtöne teilen sich einen Player; ein neuer Takt schneidet den vorigen Ton ab (CHK015).
`finished` und eine verborgene Seite stoppen alle Töne der Seite (FR-044).

**Fokus des Fensters** (R11): Bei `NOTIFICATION_APPLICATION_FOCUS_OUT` taktet die Seite nicht mehr
und setzt `stream_paused` auf allen Playern; bei `…_FOCUS_IN` geht es ohne Nachholen weiter. Auch
die Sperre der Ergebnisanzeige läuft nur mit Fokus (CHK014).

## Texte (`TitleTexts`)

Neu, Wortlaute aus R10 nach der Checkliste:

```gdscript
const INVADERS_SCORE := "PUNKTE %04d"
const INVADERS_WON := "ALLE ERWISCHT."
const INVADERS_LOST_HIT := "KANONE KAPUTT."
const INVADERS_LOST_LANDED := "DIE SIND GELANDET."
const INVADERS_POINTS := "%d PUNKTE"
const INVADERS_CONTINUE := "Weiter mit Taste oder Klick."
```

`test_title_texts.gd` prüft, dass jede Zeile der Ergebnisanzeige in die Breite der Anzeige passt.

## Tests

`test_invaders_game.gd` (fester Seed, Schritt für Schritt):
- Start: 32 Außerirdische, 3 Leben, 0 Punkte, Kanone mittig, `PLAYING`.
- Die Kanone fährt und bleibt im Feld; links und rechts zugleich heben sich auf.
- Ein Schuss nur, wenn keiner im Feld ist; er trifft höchstens einen; Punkte je Reihe.
- Der Block rückt im Takt, am Rand tiefer und zurück; der Abstand der Takte sinkt mit den Übrigen.
- Bomben höchstens 3; eine Bombe auf der Kanone: ein Leben weniger, `RESPAWN`, nach 1 s `PLAYING`.
- Ende `WON`, `LOST`/`HIT`, `LOST`/`LANDED`; danach ändert `step()` nichts.
- Zwei Partien mit gleichem Seed und gleichen Eingaben ergeben bytegleiche Folgen von Ereignissen.
- Ein gezielter Durchlauf (Kanone fährt unter den Block und schießt) gewinnt in weniger als 3
  Minuten Spielzeit (SC-002, unterer Teil).

`test_invaders_sprites.gd`: Jedes Muster hat gleich lange Zeilen und die Größe aus dem Style-Guide;
nur `#` und `.`; die beiden Bilder je Außerirdischem unterscheiden sich.

`test_invaders_page.gd` (mit `autoplay = false` und `advance()`):
- `start()` nimmt den Fokus; Pfeile, Leertaste und unbekannte Tasten erreichen den Titel nicht.
- Ereignisse spielen den passenden Player auf `Effekte`.
- Die Ergebnisanzeige nimmt in den ersten 0,5 s nichts außer Esc; danach einen neuen Druck, kein Echo;
  Shift allein zählt nicht.
- Cmd+Q, Strg+Cmd+F und `toggle_fullscreen` werden nicht verbraucht.
- Esc zu jeder Zeit `finished`; danach spielt kein Player mehr.
- Ohne Fokus des Fensters taktet nichts und die Player sind angehalten.
