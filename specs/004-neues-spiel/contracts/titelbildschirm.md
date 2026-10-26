# Vertrag: Blätter auf dem Titelbildschirm und Spielbildschirm

Technischer Vertrag zur Oberfläche: Hauptmenü mit fünf Einträgen, Gradwahl, Liste der Spielstände
mit Löschmodus, Rückfrage, Spielbildschirm mit dem Knopf „Zum Hauptmenü“. Entscheidungen in
[research.md](../research.md) (R11 bis R15, R17, R18), Wege und Vorwahl in
[data-model.md](../data-model.md), „Titelbildschirm: Blätter und Wege“. Der Vertrag von Feature 001,
[titelbildschirm.md](../../001-hauptmenue/contracts/titelbildschirm.md), gilt weiter, wo hier nichts
anderes steht. Rümpfe stehen hier bewusst nicht (Verfassung, Grundsatz II).

**Vorbedingung:** Die Abschnitte aus R17 stehen im Style-Guide, und Klaus hat sie freigegeben (T001,
T002). Farben, Schriften, Maße, Lagen und Zustände kommen von dort und aus `UiPalette` und dem
Theme, nicht aus diesem Vertrag; wo der Vertrag eine Konstante nennt, trägt sie den Wert aus dem
Style-Guide (Verfassung, Grundsatz IV; Analyse, D1). Braucht der Agent etwas, das der Style-Guide
nicht regelt, hält er an und fragt.

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
    ├── test_title_texts.gd            # neu: jeder Text passt in sein Feld
    ├── test_menu_hint.gd              # neu: show_text(), show_warning()
    └── test_knopf.gd                  # neu
```

## Szenenaufbau

```text
TitleScreen (Control, 640 × 360)                title_screen.gd
├── Background, LogoBlock, VersionLine          wie Feature 001
├── MainMenu (main_menu.tscn)                   HAUPTMENÜ, Lage wie Feature 001
├── DifficultySheet (main_menu.tscn)            SCHWIERIGKEIT
├── SaveList (save_list.tscn)                   SPIELSTÄNDE
├── ConfirmSheet (main_menu.tscn)               LÖSCHEN?
└── MenuHint (menu_hint.tscn)                   ein Hinweis für alle Blätter, auch als Meldung

GameScreen (Control, 640 × 360)                 game_screen.gd
├── Background (ColorRect)                      nacht
├── LeaveButton (Button, Skript knopf.gd)       „Zum Hauptmenü“, in der Mitte
└── MenuHint (menu_hint.tscn)                   links neben dem Knopf, auch als Meldung
```

Lage und Breite der Blätter, Spalten, Rollmarken und die Lage des Knopfs stehen im Style-Guide
(Baustein Menü, „Blätter im Titel“; Baustein Liste; README, „Bildaufbau“), eingetragen mit T001.
Die Messungen dazu stehen in research.md, R11, R12 und R15.

Es ist immer genau ein Blatt sichtbar; ein unsichtbares hat keinen Fokus. `TitleScreen` merkt sich,
welches Blatt welches geöffnet hat, für Esc und „Zurück“. Den Wechsel zum Spielbildschirm und
zurück macht `scene_callback` (unten); ohne ihn `get_tree().change_scene_to_file()`. Beim
Erscheinen und bei jeder Rückkehr ins Hauptmenü baut `TitleScreen` die Einträge aus
`session.store().list_slots()` neu (Analyse, F2).

## MainMenu (geändert)

```gdscript
## Text der Kopfzeile, bisher fest „HAUPTMENÜ“ in der Szene.
@export var header_text: String = "HAUPTMENÜ"
## Breite des Papiers. PAPER_WIDTH bleibt als Vorgabe stehen; test_main_menu.gd nutzt es weiter
## (Analyse, F11).
@export var paper_width: int = PAPER_WIDTH

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
## „Zurück“ wurde ausgelöst, im Löschmodus wie außerhalb. Was dann geschieht, entscheidet
## TitleScreen: im Löschmodus den Modus beenden, sonst ins Hauptmenü (Analyse, F3).
signal back_requested
## Eine Zeile wurde gewählt; für den Hinweis wie MainMenu.selection_changed.
signal selection_changed(hint: String, row_rect: Rect2)

# Die Werte der drei Konstanten stehen im Style-Guide, Baustein Liste (T001); der Agent übernimmt
# sie von dort, nicht aus research.md.
## Höchstens so viele Spielstände sind zu sehen.
const VISIBLE_ROWS: int
## Anfänge der Spalten ab dem Text der Zeile: Name, Grad, Spieldatum, zuletzt gespielt.
const COLUMNS: Array[int]
## Breite des Papiers.
const PAPER_WIDTH: int

## Zeigt [param slots] in dieser Reihenfolge, Löschmodus aus, Auswahl auf Zeile [param index].
func show_slots(slots: Array[SaveSlot], index: int = 0) -> void
func set_delete_mode(on: bool) -> void
func is_delete_mode() -> bool
## Der Spielstand der gewählten Zeile; null bei „Löschen …“ und „Zurück“.
func selected_slot() -> SaveSlot
```

Verhalten:
- Kopfzeile SPIELSTÄNDE, im Löschmodus WELCHES LÖSCHEN?.
- Bis zu `VISIBLE_ROWS` Zeilen für Spielstände, darunter immer „Löschen …“ und „Zurück“. Mit mehr
  rollt das Fenster mit der Auswahl und mit dem Mausrad um je eine Zeile; ein Dreieck rechts in der
  Kopfzeile zeigt, dass oben mehr steht, eins rechts in der Zeile „Löschen …“, dass unten mehr
  steht (R12). Pfeiltasten und Tab laufen an den Enden um wie im Hauptmenü.
- Der Name in der ersten Spalte wird mit „…“ gekürzt, wenn er nicht hineinpasst (ab „Spiel
  10000“).
- Nicht fortsetzbare Zeilen sind gedämpft, wählbar und lösen außerhalb des Löschmodus nichts aus;
  im Löschmodus schon (FR-017a). Mauszeiger: die Hand nur über Zeilen, die etwas auslösen.
- „Löschen …“ ist im Löschmodus nicht verfügbar. Der Hinweis von „Zurück“ lautet im Löschmodus
  „Nicht löschen. Esc geht auch.“ (Analyse, F3).
- Rechtsklick wählt und zeigt den Hinweis, wie im Menü.

## MenuHint (geändert)

```gdscript
## Zeigt [param text] als Hinweis neben [param row_rect], wie show_for(), aber ohne MenuEntry. Für
## die Liste und den Knopf; show_for() ruft es mit entry.hint auf (Analyse, C2).
func show_text(text: String, row_rect: Rect2) -> void
## Zeigt [param text] als Meldung an der Stelle des Hinweises: Kontur kassenrot (Theme-Variante
## WarningPanel), sonst wie show_text(). Sie bleibt, bis show_for() oder show_text() mit einer
## anderen Zeile kommt.
func show_warning(text: String, row_rect: Rect2) -> void
```

## Knopf

```gdscript
class_name Knopf
extends Button

## Der Baustein Knopf aus dem Style-Guide: gehaeuse, Kontur tusche, Relief erhaben, gedrückt
## vertieft, beim Überfahren signalgelb, Schrift menue. Steht er allein auf einem Bildschirm, zeigt
## der Bildschirm seinen Hinweis wie im Menü statt eines Tooltips (Style-Guide, CHK017). Das Relief
## und die Fokuslinie malt _draw(), denn eine StyleBoxFlat kennt kein Relief in zwei Farben. Auf dunklem Grund ist die Fokuslinie
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
## Wechselt die Szene; ungültig heißt get_tree().change_scene_to_file(). Tests setzen eine eigene
## Funktion und prüfen den Aufruf statt des echten Wechsels (wie GameSession.quit_callback; Analyse,
## C1).
var scene_callback: Callable
```

- Beim Erscheinen hat der Knopf den Fokus, und der Hinweis steht links neben ihm.
- Knopf: `session.leave()`; bei OK über `scene_callback` zum Titelbildschirm, sonst die Meldung aus
  `last_error`, und das Spiel läuft weiter (FR-011).
- `session.save_failed` zeigt die Meldung. Scheitert schon das Speichern beim Fortsetzen, kommt das
  Signal vor dem Szenenwechsel; deshalb zeigt der Spielbildschirm beim Erscheinen die Meldung, wenn
  `session.last_error` nicht leer ist. `GameSession` leert `last_error` nach jedem gelungenen
  Speichern.

## TitleScreen (geändert)

```gdscript
## null heißt das Autoload GameSession; Tests setzen eine eigene.
var session: Node = null
## Wechselt die Szene, wie GameScreen.scene_callback (Analyse, C1).
var scene_callback: Callable
```

- Hauptmenü: fünf Einträge nach FR-001, Verfügbarkeit und Vorwahl nach data-model.md; neu
  aufgebaut beim Erscheinen und bei jeder Rückkehr aus einem Blatt (Analyse, F2).
- „Weiterspielen“: `session.resume()` mit dem ersten fortsetzbaren Spielstand, dann Spielbildschirm.
- Gradwahl bestätigen: `session.start_new(grad)`; bei OK Spielbildschirm, sonst Meldung auf der
  Gradwahl.
- Liste: wird bei jedem Öffnen neu gelesen (CHK001). Fortsetzen wie „Weiterspielen“; im Löschmodus
  Rückfrage; bestätigt `store().delete()`, Liste neu, Löschmodus aus; ist sie leer, Hauptmenü mit
  „Neues Spiel“. Scheitert das Löschen: Meldung, Liste neu, Löschmodus aus (CHK003).
- `ui_cancel` (Esc) und `back_requested`: eine Ebene zurück, im Hauptmenü nichts. Im Löschmodus
  beenden beide nur den Modus, die Liste bleibt (US4, Szenario 2; Analyse, F3).
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
| Zurück, in der Liste im Löschmodus | „Nicht löschen. Esc geht auch.“ |
| Liste, fortsetzbare Zeile | „Zuletzt gespielt am 26.10.2026 um 21:40 Uhr.“ |
| Liste, nicht fortsetzbare Zeile | der Grund aus `SaveSlot.reason` |
| Liste, Löschen … | „Einen Spielstand löschen. Vorher fragt das Spiel nach.“ |
| Löschen …, im Löschmodus | „Wähl oben den Spielstand, der weg soll. Esc bricht ab.“ |
| Liste im Löschmodus, Zeile | „Spiel 2 wird gelöscht. Vorher fragt das Spiel nach.“ |
| Rückfrage, Abbrechen | „Spiel 2 bleibt: Schwer, 14.03.1986. Esc geht auch.“ (Klaus, 2026-10-26: vorher „Spiel 2, Schwer, 14.03.1986, bleibt. …“, mit „Spiel 9999“ drei Zeilen) |
| Rückfrage, Spiel 2 löschen | „Spiel 2 ist danach weg: Schwer, 14.03.1986. Für immer.“ |
| Rückfrage, Abbrechen, nicht fortsetzbar | „Spiel 3, beschädigt, bleibt. Esc geht auch.“, bei zu neuen „neuere Version“ statt „beschädigt“ |
| Rückfrage, löschen, nicht fortsetzbar | „Spiel 3, beschädigt, ist danach weg. Für immer.“, bei zu neuen „neuere Version“ |
| Liste, Spalten Grad und Spieldatum, nicht fortsetzbar | „beschädigt“ oder „neuere Version“ |
| Spielbildschirm, Knopf | „Speichert Spiel 2 und führt ins Hauptmenü.“ |
| Meldung, Speichern beim Fortsetzen oder Verlassen (Spielbildschirm) | „Speichern ging nicht. Dein Spiel läuft weiter.“ |
| Meldung, Speichern beim Beenden (Fensterknopf, Cmd+Q) | „Speichern ging nicht. Dein Spiel läuft weiter.“; ein zweites Beenden endet ohne Speichern (Klaus, 2026-10-26) |
| Meldung, neues Spiel | „Speichern ging nicht. Es ist kein Spiel angelegt.“ |
| Meldung, Löschen | „Löschen ging nicht. Der Spielstand ist noch da.“ |

Die drei Meldungen stehen als Konstanten in `GameSession` (Speichern) und `TitleTexts` (Löschen);
`GameSession.last_error` ist nach einem Fehler einer der zwei Sätze zum Speichern, und
`push_warning()` nennt zusätzlich Datei und Schritt aus `SaveStore.last_error`.

`test_title_texts.gd` prüft, dass jeder dieser Texte mit den längsten Platzhaltern („Spiel 9999“,
„Schwer“, „neuere Version“) in höchstens zwei Zeilen des Hinweises passt, gemessen mit der Schrift
des Themes. Dazu gehören auch die zwei Meldungen aus `GameSession` und die Gründe aus `SaveGame` und
`SaveSlot` (Analyse, C10).

## Tests

| Test | prüft | Anforderung |
|---|---|---|
| `test_main_menu.gd` | Kopfzeile, Breite, `set_entries()` mit Vorwahl; das Hauptmenü wie vorher | FR-001, SC-006 |
| `test_title_screen.gd` | Szenenwechsel nur über `scene_callback`; fünf Einträge in Reihenfolge; Vorwahl mit und ohne Spielstände, nur beschädigte; Hinweise nach FR-002; Wege aus dem Schaubild mit Tastatur und Maus; Esc je Blatt; SC-001 mit 3 Eingaben, SC-002 mit 1 Eingabe für Weiterspielen, 2 Klicks und höchstens 4 Tasten über die Liste; Anzeige der Liste mit 20 Spielständen in höchstens 1 s; Abbrechen der Gradwahl legt keine Datei an; ohne Spiel läuft nach mehreren Bildern keins; den zuletzt gespielten löschen, zurück ins Hauptmenü: „Weiterspielen“ nennt den nächsten (Analyse, F2); Löschen scheitert (Ordner mit Inhalt an der Stelle von `spiel_N.json` neben einer fortsetzbaren `.alt`): Meldung, Liste neu, der Spielstand steht noch darin, Löschmodus aus (Analyse, E2); ohne Spiel entsteht nach mehreren Bildern keine Datei im Ordner der Session (FR-003); die Liste ist beim Öffnen neu gelesen, auch nach einer Änderung im Ordner (Analyse, E3) | FR-001 bis FR-006, FR-015, FR-023, SC-001, SC-002, SC-006 |
| `test_save_list.gd` | Spalten, Ordnung, gedämpfte Zeilen, gekürzter Name, Rollen mit 7 und 20 Spielständen, Dreiecke, Löschmodus mit Kopfzeile und Hinweisen, auch „Zurück“, Ende des Modus auf allen vier Wegen | FR-015, FR-017a |
| `test_game_screen.gd` | Knopf mit Fokus und Hinweis; Esc tut nichts; Knopf speichert und ruft `scene_callback`; Meldung bei Fehler, Spiel läuft weiter; Meldung beim Erscheinen nach gescheitertem Speichern beim Fortsetzen | FR-019, FR-020, FR-011 |
| `test_title_texts.gd` | jeder Text aus „Texte“, die Meldungen und die Gründe in höchstens zwei Zeilen des Hinweises | FR-021 |
| `test_knopf.gd` | Farben nur aus der Palette, Relief, Fokuslinie hell und dunkel | FR-021 |
| `test_menu_hint.gd` | `show_text()` und `show_warning()`: Lage links neben der Zeile, Breite, Kontur `tusche` und `kassenrot` | FR-011, FR-021 |
| `test_texte.gd` | läuft unverändert über die neuen Dateien: kein „Sie“ | FR-021 |

Jeder Test der Oberfläche setzt eine eigene `GameSession` mit eigenem Ordner unter `user://` und
einen eigenen `scene_callback`.

## Bildschirmfotos und Platz

Vor T017 nimmt der Agent ein Bild des Hauptmenüs ohne Spielstände auf und legt es in den
Scratchpad, nicht ins Repo; nach T017 vergleicht er es Pixel für Pixel mit dem neuen, bis auf
Einträge, Hinweise und Höhe (Analyse, C8).

Zur Phasenprüfung liefert der Agent Bildschirmfotos mit `scripts/fotos.gd` aus
`dcl-phasenpruefung`, im Raster 640 × 360 und dreifach, wie der Skill es vorsieht. Die Szene bekommt
dafür eine eigene Session mit einem Ordner unter `user://test_fotos/`, gefüllt aus den Fixtures
unter `src/test/fixtures/spielstaende/`; die echten Spielstände sind tabu (Analyse, C7). Gebraucht
werden:
- Hauptmenü ohne Spielstände und mit Spielständen, je mit Hinweis;
- Gradwahl mit dem Satz zu Mittel;
- Liste mit 3 und mit 9 Spielständen, darunter ein beschädigter und ein zu neuer; Löschmodus;
- Rückfrage;
- Spielbildschirm mit Hinweis und mit Meldung.

Dazu die Aussage, ob jede Zeile und jeder Hinweis in sein Feld passt, gemessen wie in R11 und R12.
