# Vertrag: Blätter auf dem Titelbildschirm und Spielbildschirm

Technischer Vertrag zur Oberfläche: Hauptmenü mit fünf Einträgen, Gradwahl, Liste der Spielstände
mit Löschmodus, Rückfrage, Spielbildschirm mit dem Knopf „Zum Hauptmenü“. Entscheidungen in
[research.md](../research.md) (R11 bis R15, R17, R18), Wege und Vorwahl in
[data-model.md](../data-model.md), „Titelbildschirm: Blätter und Wege“. Der Vertrag von Feature 001,
[titelbildschirm.md](../../001-hauptmenue/contracts/titelbildschirm.md), gilt weiter, wo hier nichts
anderes steht. Rümpfe stehen hier bewusst nicht (Verfassung, Grundsatz II).

**Vorbedingung:** Die Abschnitte aus R17 stehen im Style-Guide, und Klaus hat sie freigegeben.
Farben, Schriften, Maße und Zustände kommen von dort und aus `UiPalette` und dem Theme, nicht aus
diesem Vertrag. Braucht der Agent etwas, das der Style-Guide nicht regelt, hält er an und fragt.

## Dateien

```text
src/
├── ui/
│   ├── computerladen_theme.tres       # geändert: Varianten Knopf, WarningPanel
│   └── knopf.gd                       # neu: class_name Knopf, Baustein Knopf
├── scenes/
│   ├── title/
│   │   ├── title_screen.tscn / .gd    # geändert: Blätter, Wege, Esc, Szenenwechsel
│   │   ├── main_menu.tscn / .gd       # geändert: Kopfzeile, Breite, Einträge zur Laufzeit
│   │   ├── menu_entry.gd              # geändert: neue Kennungen
│   │   ├── menu_hint.tscn / .gd       # geändert: Meldung
│   │   ├── menu_paper.gd              # neu: class_name MenuPaper, Papier malen für Menü und Liste
│   │   ├── save_list.tscn / .gd       # neu: class_name SaveList, Blatt „Spielstände“
│   │   └── title_texts.gd             # neu: class_name TitleTexts, alle Texte der Blätter
│   └── game/
│       ├── game_screen.tscn / .gd     # neu: class_name GameScreen
└── test/
    ├── test_main_menu.gd              # geändert
    ├── test_title_screen.gd           # geändert
    ├── test_save_list.gd              # neu
    ├── test_game_screen.gd            # neu
    └── test_knopf.gd                  # neu
```

## Szenenaufbau

```text
TitleScreen (Control, 640 × 360)                title_screen.gd
├── Background, LogoBlock, VersionLine          wie Feature 001
├── MainMenu (main_menu.tscn)                   HAUPTMENÜ, 144 breit, x 472, y 150
├── DifficultySheet (main_menu.tscn)            SCHWIERIGKEIT, 144 breit, x 472, y 150
├── SaveList (save_list.tscn)                   SPIELSTÄNDE, 296 breit, x 320, y 150
├── ConfirmSheet (main_menu.tscn)               LÖSCHEN?, 144 breit, x 472, y 150
└── MenuHint (menu_hint.tscn)                   ein Hinweis für alle Blätter, auch als Meldung

GameScreen (Control, 640 × 360)                 game_screen.gd
├── Background (ColorRect)                      nacht
├── LeaveButton (Button, Skript knopf.gd)       „Zum Hauptmenü“, Mitte, x 270, y 170
└── MenuHint (menu_hint.tscn)                   links neben dem Knopf, auch als Meldung
```

Es ist immer genau ein Blatt sichtbar; ein unsichtbares hat keinen Fokus. `TitleScreen` merkt sich,
welches Blatt welches geöffnet hat, für Esc und „Zurück“. Der Wechsel zum Spielbildschirm und
zurück geschieht mit `get_tree().change_scene_to_file()`; beim Erscheinen baut `TitleScreen` die
Einträge aus `GameSession.store().list_slots()` neu.

## MainMenu (geändert)

```gdscript
## Text der Kopfzeile, bisher fest „HAUPTMENÜ“ in der Szene.
@export var header_text: String = "HAUPTMENÜ"
## Breite des Papiers, bisher PAPER_WIDTH = 144.
@export var paper_width: int = 144

## Baut die Zeilen aus [param new_entries] neu und wählt Zeile [param index]. Für Einträge, deren
## Verfügbarkeit oder Hinweis sich ändert, etwa „Weiterspielen“.
func set_entries(new_entries: Array[MenuEntry], index: int = 0) -> void
```

Das Malen von Papier, Zebra, Lochrändern, Schatten, Auswahl und Pfeil wandert nach `MenuPaper`
(statische Funktionen), damit `SaveList` dasselbe Papier malt. **Feste Größe:** Das Hauptmenü sieht
Pixel für Pixel aus wie vorher; `test_main_menu.gd` läuft mit seinen Erwartungen weiter.

## MenuEntry (geändert)

Neue Kennungen: `&"continue"`, `&"easy"`, `&"medium"`, `&"hard"`, `&"back"`, `&"delete_mode"`,
`&"cancel"`, `&"delete"`. Die Liste der erlaubten Kennungen im Doc-Kommentar wächst entsprechend.

## SaveList

```gdscript
class_name SaveList
extends Control

## Eine fortsetzbare Zeile wurde ausgelöst.
signal resume_requested(slot: SaveSlot)
## Im Löschmodus wurde eine Zeile ausgelöst.
signal delete_requested(slot: SaveSlot)
## „Zurück“ wurde ausgelöst.
signal back_requested
## Eine Zeile wurde gewählt; für den Hinweis wie MainMenu.selection_changed.
signal selection_changed(hint: String, row_rect: Rect2)

## Höchstens so viele Spielstände sind zu sehen (R12).
const VISIBLE_ROWS := 6
## Anfänge der Spalten ab dem Text der Zeile: Name, Grad, Spieldatum, zuletzt gespielt (R12).
const COLUMNS := [0, 56, 100, 164]
const PAPER_WIDTH := 296

## Zeigt [param slots] in dieser Reihenfolge, Löschmodus aus, Auswahl auf Zeile [param index].
func show_slots(slots: Array[SaveSlot], index: int = 0) -> void
func set_delete_mode(on: bool) -> void
func is_delete_mode() -> bool
## Der Spielstand der gewählten Zeile; null bei „Löschen …“ und „Zurück“.
func selected_slot() -> SaveSlot
```

Verhalten:
- Kopfzeile SPIELSTÄNDE, im Löschmodus WELCHES LÖSCHEN?.
- Bis zu 6 Zeilen für Spielstände, darunter immer „Löschen …“ und „Zurück“. Mit mehr als 6 rollt das
  Fenster mit der Auswahl und mit dem Mausrad um je eine Zeile; die Dreiecke zeigen, ob oben oder
  unten mehr steht (R12). Pfeiltasten und Tab laufen an den Enden um wie im Hauptmenü.
- Nicht fortsetzbare Zeilen sind gedämpft, wählbar und lösen außerhalb des Löschmodus nichts aus;
  im Löschmodus schon (FR-017a). Mauszeiger: die Hand nur über Zeilen, die etwas auslösen.
- „Löschen …“ ist im Löschmodus nicht verfügbar.
- Rechtsklick wählt und zeigt den Hinweis, wie im Menü.

## MenuHint (geändert)

```gdscript
## Zeigt [param text] als Meldung an der Stelle des Hinweises: Kontur kassenrot (Theme-Variante
## WarningPanel), sonst wie show_for(). Sie bleibt, bis show_for() mit einer anderen Zeile kommt.
func show_warning(text: String, row_rect: Rect2) -> void
```

## Knopf

```gdscript
class_name Knopf
extends Button

## Der Baustein Knopf aus dem Style-Guide: gehaeuse, Kontur tusche, Relief erhaben, gedrückt
## vertieft, beim Überfahren signalgelb, Schrift menue. Steht er allein auf einem Bildschirm, zeigt
## der Bildschirm seinen Hinweis wie im Menü statt eines Tooltips (Style-Guide, CHK017). Das Relief und die Fokuslinie malt _draw(),
## denn eine StyleBoxFlat kennt kein Relief in zwei Farben. Auf dunklem Grund ist die Fokuslinie
## papier (Style-Guide, R17).

## Ob der Knopf auf dunklem Grund steht; dann ist die Fokuslinie papier statt tusche.
@export var on_dark: bool = false
```

Theme-Variante `Knopf` für Schrift und Innenabstand. Mauszeiger: die Hand.

## GameScreen

```gdscript
class_name GameScreen
extends Control

## Der noch leere Spielbildschirm (FR-019, FR-020): ein Knopf „Zum Hauptmenü“ mit Hinweis.
## Esc löst nichts aus.

## null heißt das Autoload GameSession; Tests setzen eine eigene.
var session: Node = null
```

- Beim Erscheinen hat der Knopf den Fokus, und der Hinweis steht links neben ihm.
- Knopf: `session.leave()`; bei OK Szenenwechsel zum Titelbildschirm, sonst die Meldung aus
  `last_error`, und das Spiel läuft weiter (FR-011).
- `session.save_failed` zeigt die Meldung. Scheitert schon das Speichern beim Fortsetzen, kommt das
  Signal vor dem Szenenwechsel; deshalb zeigt der Spielbildschirm beim Erscheinen die Meldung, wenn
  `session.last_error` nicht leer ist. `GameSession` leert `last_error` nach jedem gelungenen
  Speichern.

## TitleScreen (geändert)

```gdscript
## null heißt das Autoload GameSession; Tests setzen eine eigene.
var session: Node = null
```

- Hauptmenü: fünf Einträge nach FR-001, Verfügbarkeit und Vorwahl nach data-model.md.
- „Weiterspielen“: `session.resume()` mit dem ersten fortsetzbaren Spielstand, dann Spielbildschirm.
- Gradwahl bestätigen: `session.start_new(grad)`; bei OK Spielbildschirm, sonst Meldung auf der
  Gradwahl.
- Liste: wird bei jedem Öffnen neu gelesen (CHK001). Fortsetzen wie „Weiterspielen“; im Löschmodus
  Rückfrage; bestätigt `store().delete()`, Liste neu, Löschmodus aus; ist sie leer, Hauptmenü mit
  „Neues Spiel“. Scheitert das Löschen: Meldung, Liste neu, Löschmodus aus (CHK003).
- `ui_cancel` (Esc): eine Ebene zurück, im Hauptmenü nichts. Im Löschmodus beendet Esc den Modus,
  die Liste bleibt (US4, Szenario 2).
- „Beenden“: wie bisher `get_tree().quit()`; es läuft kein Spiel.

## Texte

Alle Texte der Blätter stehen in `TitleTexts` an einer Stelle, auch die Sätze zu den Graden und die
Hinweise mit Platzhaltern. Vorschläge, gemessen auf höchstens zwei Zeilen des Hinweises; der
Text-Prüfer prüft sie in der Phase. Die Sätze zu den Graden hat Klaus entschieden (R18).

| Wo | Text |
|---|---|
| Hauptmenü, Weiterspielen | „Weiter mit Spiel 2, Schwer, am 14.03.1986.“ |
| Weiterspielen, nicht verfügbar, keine Spielstände | „Noch kein Spiel angefangen.“ |
| Weiterspielen, nicht verfügbar, keiner fortsetzbar | „Kein Spielstand lässt sich fortsetzen.“ |
| Neues Spiel | „Einen neuen Laden aufmachen. Los geht es am 01.01.1985.“ |
| Spiel laden | „Alle Spielstände: fortsetzen oder löschen.“ |
| Spiel laden, nicht verfügbar | „Noch keine Spielstände.“ |
| Einstellungen, Beenden | wie Feature 001 |
| Gradwahl, Leicht | „Das Glück ist eher auf deiner Seite.“ (Klaus, 2026-10-26, R18) |
| Gradwahl, Mittel | „Das Glück hält sich raus.“ |
| Gradwahl, Schwer | „Das Glück ist eher auf der Seite der anderen.“ |
| Zurück, in Gradwahl und Liste | „Zurück zum Hauptmenü. Esc geht auch.“ |
| Liste, fortsetzbare Zeile | „Zuletzt gespielt am 26.10.2026 um 21:40 Uhr.“ |
| Liste, nicht fortsetzbare Zeile | der Grund aus `SaveSlot.reason` |
| Liste, Löschen … | „Einen Spielstand löschen. Vorher fragt das Spiel nach.“ |
| Löschen …, im Löschmodus | „Wähl oben den Spielstand, der weg soll. Esc bricht ab.“ |
| Liste im Löschmodus, Zeile | „Spiel 2 wird gelöscht. Vorher fragt das Spiel nach.“ |
| Rückfrage, Abbrechen | „Spiel 2, Schwer, 14.03.1986, bleibt. Esc geht auch.“ |
| Rückfrage, Spiel 2 löschen | „Spiel 2, Schwer, 14.03.1986, ist danach weg. Für immer.“ |
| Spielbildschirm, Knopf | „Speichert Spiel 2 und führt ins Hauptmenü.“ |
| Meldung, Speichern beim Verlassen | „Speichern ging nicht. Dein Spiel läuft weiter.“ |
| Meldung, Speichern beim Schließen | „Speichern ging nicht. Schließt du noch einmal, dann ohne.“ |
| Meldung, neues Spiel | „Speichern ging nicht. Es ist kein Spiel angelegt.“ |
| Meldung, Löschen | „Löschen ging nicht. Der Spielstand ist noch da.“ |

Die vier Meldungen stehen als Konstanten in `GameSession` (Speichern) und `TitleTexts` (Löschen);
`GameSession.last_error` ist nach einem Fehler einer der drei Sätze zum Speichern, und
`push_warning()` nennt zusätzlich Datei und Schritt aus `SaveStore.last_error`.

Bei einem nicht fortsetzbaren Spielstand nennt die Rückfrage statt Grad und Spieldatum seinen
Zustand: „Spiel 3, beschädigt, ist danach weg. Für immer.“

## Tests

| Test | prüft | Anforderung |
|---|---|---|
| `test_main_menu.gd` | Kopfzeile, Breite, `set_entries()` mit Vorwahl; das Hauptmenü wie vorher | FR-001, SC-006 |
| `test_title_screen.gd` | fünf Einträge in Reihenfolge; Vorwahl mit und ohne Spielstände, nur beschädigte; Hinweise nach FR-002; Wege aus dem Schaubild mit Tastatur und Maus; Esc je Blatt; SC-001 mit 3 Eingaben, SC-002 mit 1 Eingabe für Weiterspielen, 2 Klicks und höchstens 4 Tasten über die Liste; Anzeige der Liste mit 20 Spielständen in höchstens 1 s; Abbrechen der Gradwahl legt keine Datei an; ohne Spiel läuft nach mehreren Bildern keins | FR-001 bis FR-006, FR-015, FR-023, SC-001, SC-002, SC-006 |
| `test_save_list.gd` | Spalten, Ordnung, gedämpfte Zeilen, Rollen mit 7 und 20 Spielständen, Dreiecke, Löschmodus mit Kopfzeile und Hinweisen, Ende des Modus auf allen vier Wegen | FR-015, FR-017a |
| `test_game_screen.gd` | Knopf mit Fokus und Hinweis; Esc tut nichts; Knopf speichert und wechselt; Meldung bei Fehler, Spiel läuft weiter | FR-019, FR-020, FR-011 |
| `test_knopf.gd` | Farben nur aus der Palette, Relief, Fokuslinie hell und dunkel | FR-021 |
| `test_texte.gd` | läuft unverändert über die neuen Dateien: kein „Sie“ | FR-021 |

Jeder Test der Oberfläche setzt eine eigene `GameSession` mit eigenem Ordner unter `user://`.

## Bildschirmfotos und Platz

Zur Phasenprüfung liefert der Agent Bildschirmfotos aus einem echten Fenster in Klaus' Größe, mit
dem Hilfsskript aus `dcl-phasenpruefung`:
- Hauptmenü ohne Spielstände und mit Spielständen, je mit Hinweis;
- Gradwahl mit dem Satz zu Mittel;
- Liste mit 3 und mit 9 Spielständen, darunter ein beschädigter und ein zu neuer; Löschmodus;
- Rückfrage;
- Spielbildschirm mit Hinweis und mit Meldung.

Dazu die Aussage, ob jede Zeile und jeder Hinweis in sein Feld passt, gemessen wie in R11 und R12.
