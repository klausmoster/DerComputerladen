# Vertrag: Titelbildschirm mit Communicator

Technischer Vertrag zum Umbau des Titels (FR-010 bis FR-015, FR-020). Entscheidungen in
[research.md](../research.md) (R8 bis R10, R13), Wege in [data-model.md](../data-model.md). Die
Verträge von Feature 001 und 004 zum Titelbildschirm gelten weiter, wo hier nichts anderes steht:
Einträge, Texte, Hinweise, Vorwahl, Esc und die Wege bleiben (FR-013). Rümpfe stehen hier bewusst
nicht (Verfassung, Grundsatz II).

**Vorbedingung:** Der Baustein Communicator aus [communicator.md](communicator.md) ist gebaut und
abgenommen. G-02 und T-02 sind gerastert, aufgeräumt und von Klaus freigegeben (R10). Lagen und Maße
kommen aus dem Style-Guide.

## Dateien

```text
src/
├── assets/images/
│   ├── organizer_1991.png / .import     # neu: Gehäuse G-02
│   └── title_t02.png / .import          # neu: Titelbild T-02; title_t01.png bleibt
├── ui/communicator/communicator.tscn    # geändert: Case zeigt G-02 statt des Platzhalters
├── scenes/title/
│   ├── title_screen.tscn / .gd          # geändert: Communicator mit vier Seiten, T-02, Fahrt
│   └── … übrige Dateien                 # unverändert bis auf look (communicator.md)
└── test/
    └── test_title_screen.gd             # geändert
docs/art/leonardo/
├── g-02-organizer.*, t-02-titelbild.*   # neu: Originale
└── prompt-log.md                        # geändert: G-02, T-02
```

## Szenenaufbau

```text
TitleScreen (Control, 640 × 360)                 title_screen.gd
├── Background (TextureRect)                     T-02 statt T-01, sonst wie bisher
├── LogoBlock, VersionLine                       unverändert
└── Communicator (communicator.tscn)             Endlage nach dem Style-Guide, rechts unten
    ├── MainMenu (main_menu.tscn)                look = LCD, HAUPTMENÜ
    ├── DifficultySheet (main_menu.tscn)         look = LCD, SCHWIERIGKEIT
    ├── SaveList (save_list.tscn)                look = LCD, SPIELSTÄNDE
    └── ConfirmSheet (main_menu.tscn)            look = LCD, LÖSCHEN?
```

Der eigene `MenuHint` des Titelbildschirms entfällt; der Hinweis gehört zum Communicator. Die Namen
der Seiten bleiben, damit Signalverbindungen und Tests wiedererkennbar sind.

## Verhalten

- **Erscheinen:** In `_ready()` stellt der Titelbildschirm den Communicator nach draußen
  (`place_hidden()`, ohne Sperre). Im zeitversetzten `_build_sheets()` setzt er erst Einträge und
  Auswahl des Hauptmenüs, dann ruft er `slide_in()` (Analyse, C5). Das geschieht bei jedem
  Erscheinen, auch nach „Zum Hauptmenü“ (FR-010).
- **Wache vor den Einträgen:** Eine eigene Variable `_ready_for_input`, erst nach den Einträgen
  `true`, fängt bis dahin jede Eingabe ab, auch Esc in `_unhandled_input()`. Die Sichtbarkeit des
  Hauptmenüs taugt dafür nicht mehr: `add_page()` verbirgt alle Seiten schon vorher, und
  `_main_menu.visible` wäre in dieser Lücke `false` (Analyse, C4).
- **Seiten:** `_show_only(sheet)` wird zu `Communicator.show_page(sheet)`; der Communicator fährt
  dabei nicht (FR-005).
- **Hinweis und Meldung:** Wo der Titelbildschirm bisher `_menu_hint.show_for()`, `show_text()`,
  `show_warning()` und `hide_hint()` rief, ruft er `Communicator.show_hint()`, `show_warning()` und
  `hide_hint()` mit derselben Zeile. `_selected_row` hält die gewählte Zeile relativ zum
  Communicator und wird beim Anzeigen in die jetzige Lage umgerechnet; so steht eine Meldung nach
  einer Wahl während der Fahrt neben der Zeile, wo sie jetzt ist (Analyse, C3).
- **Spielstart:** `_start_new()`, `_continue()` und das Fortsetzen über die Liste rufen erst die
  Session. Bei `OK` ruft der Titelbildschirm `Communicator.slide_out()` und wechselt die Szene im
  Signal `slide_finished(false)` über `_change_scene(GAME_SCENE)`; mit `animate = false` sofort.
  Vor `slide_out()` setzt er `_leaving = true`; ab dann fangen alle Handler der Seiten
  (`_on_*_entry_activated`, `_on_save_list_*`) und `_unhandled_input()` jede Eingabe ab (R8;
  Analyse, B2), zusätzlich zur Sperre im Communicator. Scheitert das Anlegen, bleibt alles wie in
  Feature 004.
- **Beenden:** `get_tree().quit()` sofort, ohne Fahrt.
- **Esc während der Fahrt herein:** wirkt wie im Stand (FR-003); im Hauptmenü also nichts.
- **Vor der Fahrt:** Bis das Hauptmenü seine Einträge hat, tut eine Eingabe nichts.
- **Fortsetzen scheitert:** wie Feature 004 neu lesen, ohne Meldung; der Communicator fährt nicht.

## Tests (`test_title_screen.gd`)

Bestehende Tests: Pfade auf `Communicator/<Seite>`, Hinweis über den Communicator; sonst unverändert
(SC-007). Neu:
- Beim Erscheinen steht der Communicator draußen und fährt herein; das Hauptmenü ist die
  sichtbare Seite. Nach einer Rückkehr aus dem Spiel ebenso.
- Jeder Seitenwechsel lässt die Lage des Communicators gleich.
- Jede Seite passt auf die Anzeige: Hauptmenü, Gradwahl, Rückfrage mit „Spiel 9999 löschen“, Liste
  mit sechs sichtbaren Spielständen, „Spiel 9999“ und Kopfzeile WELCHES LÖSCHEN? (SC-004).
- Logo, Untertitel und Versionszeile überschneiden sich weder mit Gehäuse noch Anzeige noch Hinweis,
  in Endlage und für jede Zeile jeder Seite, auch als Meldung (SC-006).
- „Weiterspielen“ mit Enter während der Fahrt herein setzt fort (SC-001); danach fährt der
  Communicator hinaus, und erst `slide_finished` ruft `scene_callback`.
- Ein zweites Enter, Esc oder „Maus über eine Zeile bewegen, dann Enter“ während der Fahrt hinaus
  legt kein zweites Spiel an und ruft `scene_callback` nur einmal (Analyse, B2).
- Scheitert das Anlegen, fährt nichts, und die Meldung steht neben dem Gehäuse auf Höhe der Zeile.
- Scheitert das Fortsetzen, fährt nichts, und der Titel liest neu.
- Eine Eingabe, bevor das Hauptmenü seine Einträge hat, tut nichts, auch Esc direkt nach dem
  Einhängen in den Baum (Analyse, C4).
- Eine Zeile während der Fahrt herein wählen, dann scheitert das Anlegen: Die Meldung steht neben
  der Zeile in ihrer jetzigen Lage (Analyse, C3).
- Auf dem Titel kommt kein `look = PAPER` mehr vor.
