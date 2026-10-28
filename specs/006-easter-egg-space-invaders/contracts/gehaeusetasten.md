# Vertrag: Gehäusetasten am Communicator

Erweiterung des Bausteins Communicator aus Feature 005 (`specs/005-communicator/contracts/communicator.md`)
um drückbare Tasten im Gehäuse (Spec, FR-001 bis FR-001b, FR-004, FR-041). Entscheidungen in
[research.md](../research.md) R1 bis R4, Zustände in [data-model.md](../data-model.md). Rümpfe stehen
hier bewusst nicht (Verfassung, Grundsatz II).

**Vorbedingung:** Der Abschnitt „Gehäusetasten“ im Baustein Communicator steht im Style-Guide mit den
nachgemessenen Rechtecken von G-03, und Klaus hat ihn freigegeben (R12). Rechtecke und die Regel zum
Zeiger kommen von dort.

## Dateien

```text
src/
├── ui/communicator/
│   ├── communicator.gd                  # geändert: case_keys, case_key_pressed, Eindrücken, Klick
│   ├── communicator.tscn                # geändert: Knoten Keys, KeyClick
│   └── case_key.gd                      # neu: class_name CaseKey, eine Klickfläche
├── assets/sounds/knopf.wav / .import    # aus contracts/ton.md
└── test/
    ├── test_communicator.gd             # geändert: Gehäusetasten
    └── fixtures/communicator_probe.*    # geändert: zeigt case_key_pressed an
```

## Szenenaufbau

```text
Communicator
├── Case, Display, Hint                   wie bisher
├── Keys (Control, IGNORE)                neu: je Taste ein CaseKey, zur Laufzeit aus case_keys gebaut
├── KeyClick (AudioStreamPlayer)          neu: knopf.wav, bus Effekte
└── … Seiten
```

`Keys` zählt zu den eigenen Kindern; `_page_list()` nimmt es ausdrücklich aus wie `Case`, `Display`
und `Hint`, sonst verbärge `show_page()` die Tasten. `KeyClick` ist kein Control und fällt ohnehin
heraus (Analyse, C4). Weil die Seiten danach kommen, liegen sie weiter oben; die Tasten liegen
außerhalb der Anzeige und überschneiden keine Seite.

## Communicator, neu

```gdscript
## Eine Gehäusetaste wurde gedrückt und über ihr losgelassen (R4). [param index] ist ihr Platz in
## case_keys, von links gezählt ab 0.
signal case_key_pressed(index: int)

## Die Tasten im Gehäuse, je ein Rechteck in Bildpixeln des Gehäusebilds. Sie gehören zum Gehäuse
## wie display_rect. Vorgabe ist leer; der Titel setzt die drei grauen Tasten von G-03 in seiner
## Szene mit den Rechtecken aus dem Style-Guide (R1, R2; Analyse, I2).
## Ein Gehäuse ohne Tasten setzt ein leeres Array.
@export var case_keys: Array[Rect2i]

## Ob die Taste [param index] gerade eingedrückt ist (für Tests und die Probeszene).
func is_case_key_down(index: int) -> bool
```

## CaseKey

```gdscript
class_name CaseKey
extends Control

## Linke Maustaste über dieser Taste losgelassen, nachdem sie hier gedrückt wurde.
signal pressed
## Die Taste geht runter oder wieder hoch; der Communicator malt danach neu.
signal down_changed(is_down: bool)

var is_down: bool  # nur lesen
```

- `mouse_filter = STOP`, `mouse_default_cursor_shape = CURSOR_ARROW`, `focus_mode = NONE`: keine
  Tastatur, kein Fokus, kein Hand-Zeiger (FR-001b).
- Lage und Größe: das Rechteck aus `case_keys` mal `Case.scale`, relativ zum Communicator.
- Linke Maustaste runter: `is_down = true`, `down_changed(true)`; der Communicator spielt `KeyClick`
  von vorn (FR-041).
- Linke Maustaste hoch: war sie unten und steht die Maus über der Taste, `pressed`; in jedem Fall
  `is_down = false`, `down_changed(false)`.
- Rechte und mittlere Maustaste: nichts. Wegen `mouse_filter` STOP gehen sie auch nicht zum Bild
  darunter durch; das ist gleichgültig, denn dort tut ein Klick ohnehin nichts (T025).
- Sperre: Mit `mouse_behavior_recursive = DISABLED` (Feature 005) bekommt die Taste keine Maus mehr.
  Damit eine Taste, die in dem Moment unten ist, nicht unten hängen bleibt, ruft `_set_locked(true)`
  von jeder Taste `cancel()`: Sie geht hoch, ohne `pressed`.
- Fokusverlust des Fensters: Bei `NOTIFICATION_APPLICATION_FOCUS_OUT` ruft die Taste `cancel()`.
  Das Loslassen, das Godot dabei selbst schickt (Gerät `DEVICE_ID_INTERNAL`, -2), zählt nie, auch
  wenn es vor der Benachrichtigung kommt (Klaus, nach der Phasenprüfung von Phase 5).

```gdscript
## Lässt die Taste ohne pressed hochgehen, falls sie unten ist.
func cancel() -> void
```

## Eindrücken (R3)

Für jede Taste, die `is_down` ist, malt der Communicator in `_draw()` über das Gehäuse:
1. die oberste Zeile der Taste in der Farbe des Bildpixels links neben ihr (der Spalt);
2. den Ausschnitt der Taste ohne ihre unterste Zeile, eine Bildpixelzeile tiefer, aus der Textur von
   `Case` (`draw_texture_rect_region`), ×2 wie das Gehäuse.

Eine helle linke Spalte haben die Tasten von G-03 nicht (T001, R2); eine eigene Lichtkante gibt es
nicht (R3; Review, CHK029). Kein `relief-gedrueckt`, kein `signalgelb`, kein Tooltip (FR-001b). Die Taste
ist im nächsten Bild nach dem Drücken eingedrückt (FR-001a). Die unterste Zeile der Taste fällt dabei weg; der Ausschnitt reicht nie über das Rechteck hinaus.
Gemalt wird in `Keys._draw()`, nicht im Communicator: Dessen `_draw()` läge unter dem Kind `Case`.
`Keys` liegt über dem Gehäuse und unter den Seiten und malt neu bei jedem `down_changed`.

## Tests (`test_communicator.gd`)

- Mit den drei Rechtecken aus dem Style-Guide gibt es drei Tasten an diesen Rechtecken ×2.
- Links runter und hoch über Taste 1: genau ein `case_key_pressed(0)`; dazwischen `is_case_key_down(0)`.
- Links runter auf Taste 2, hoch über Taste 3 oder außerhalb: kein Signal, Taste wieder oben.
- Rechte Maustaste: kein Signal, nicht eingedrückt.
- Nach `slide_out()`: kein Signal; eine gedrückte Taste geht hoch.
- Nach `slide_in()`: wieder Signale.
- Fokusverlust des Fensters bei gedrückter Taste: Sie geht hoch, kein Signal; auch Godots eigenes
  Loslassen danach zählt nicht.
- Jeder Druck links spielt `KeyClick` auf dem Kanal `Effekte`, auch der, der nicht zählt.
- Der Zeiger über einer Taste ist der Pfeil; keine Taste nimmt den Fokus.
- Eingedrückt: Die Pixel innerhalb der Taste entsprechen dem Ausschnitt eine Zeile tiefer
  (Bildvergleich auf einem `SubViewport` oder Prüfung der Rechtecke, die `_draw()` benutzt).
- Ein Communicator mit `case_keys = []` hat keine Tasten, und alles aus Feature 005 gilt unverändert.
