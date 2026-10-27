# Vertrag: Easter Egg im Titel

Einbau von Folge und Spiel in den Titel (Spec, FR-002 bis FR-007, FR-010, FR-017, FR-020 bis FR-022).
Entscheidungen in [research.md](../research.md) R5, R10, R16; Ablauf in [data-model.md](../data-model.md).
Die Verträge zum Titel aus Feature 001, 004 und 005 gelten weiter; ohne Druck auf eine Gehäusetaste
ändert sich nichts (FR-006, SC-004).

**Vorbedingung:** Gehäusetasten ([gehaeusetasten.md](gehaeusetasten.md)) und die Seite
([invaders.md](invaders.md)) sind gebaut und abgenommen.

## Dateien

```text
src/scenes/title/
├── key_sequence.gd                      # neu: class_name KeySequence
├── title_screen.tscn                    # geändert: Seite Invaders unter dem Communicator
└── title_screen.gd                      # geändert: Folge, Start, Rückweg
src/test/
├── test_key_sequence.gd                 # neu
└── test_title_screen.gd                 # geändert: Easter Egg
```

## Szenenaufbau

```text
Communicator
├── MainMenu, DifficultySheet, SaveList, ConfirmSheet   wie bisher
└── Invaders (invaders_page.tscn)                       neu, als fünfte Seite
```

## KeySequence

```gdscript
class_name KeySequence
extends RefCounted

## [param expected]: die Folge der Tastenplätze, hier [0, 1, 2].
func _init(expected: Array[int]) -> void
## Ein Druck auf [param index]. true, wenn die Folge damit vollständig ist; dann beginnt sie von vorn.
## Ein falscher Druck setzt zurück; ist er expected[0], zählt er als neuer Anfang (FR-003).
func press(index: int) -> bool
## Beginnt von vorn.
func reset() -> void
## Wie viele der Folge schon richtig kamen (Tests).
func progress() -> int
```

## TitleScreen, neu

- `_ready()` verbindet `Communicator.case_key_pressed` und `Invaders.finished`.
- **Druck:** Nimmt der Titel keine Eingabe an (`_accepts_input()` false) oder steht das Spiel auf der
  Anzeige, zählt der Druck nicht. Sonst `_sequence.press(index)`.
- **Start**, wenn `press()` true gibt: merken, was zu sehen ist (Seite, Fokus-Owner, Zeile und Text des
  Hinweises; die Meldung zählt dabei wie ein Hinweis), `hide_hint()`, `Invaders.start()`,
  `show_page(Invaders)`. Der Communicator bewegt sich nicht (FR-010).
- **Esc:** Steht das Spiel, nimmt die Seite Esc selbst; `_unhandled_input()` des Titels sieht es nicht.
- **Ende** bei `finished`: `show_page()` der gemerkten Seite, Fokus zurück auf das gemerkte Control
  (deferred, wenn es zu der Zeit noch nicht sichtbar ist), Hinweis zur gemerkten Zeile wieder zeigen
  (eine Meldung kommt als Hinweis zurück, nicht als Meldung), `_sequence.reset()` (FR-022).
- **Verlassen:** Der Titel startet kein Spiel des Computerladens aus dem Easter Egg, schreibt keinen
  Spielstand und ruft `GameSession` nicht (FR-007). Beginnt der Spieler nach dem Easter Egg ein Spiel,
  gilt alles aus Feature 005 unverändert.
- Erscheint der Titel neu (auch nach „Zum Hauptmenü“), ist die Folge auf 0.

## Tests

`test_key_sequence.gd`: 1-2-3 true; 2-1-3, 1-3, 3-2-1 nie true; 1-1-2-3 true; 1-2-2-3 false; nach
true wieder bei 0; 20 zufällige Folgen aus drei Drücken, die nicht 1-2-3 sind, nie true (SC-005; fester
Seed).

`test_title_screen.gd`, mit `animate = false` und erfundenen Mausereignissen auf den Tasten:
- Die Folge auf jeder der vier Seiten startet das Spiel; Gerät, Logo und Versionszeile stehen still,
  der Hinweis ist aus.
- Eine andere Folge startet nichts; Seite, Auswahl und Hinweis bleiben.
- 1, dann eine Zeile im Menü wählen, dann 2, 3: startet (FR-003).
- Während des Spiels: Pfeile, Leertaste, Enter lösen im Menü nichts aus und wechseln keine Auswahl
  (FR-017); die Tasten starten kein zweites Spiel.
- Esc im Spiel und `finished` nach dem Ende: dieselbe Seite, derselbe Fokus, derselbe Hinweis wie
  vorher; danach bedienen sich die Seiten wie zuvor.
- Fährt das Gerät hinaus (Spielstart), zählt kein Druck.
- Kein Spielstand im Testordner wird angelegt oder geändert.
- Alle bisherigen Tests des Titels laufen unverändert (SC-004).
