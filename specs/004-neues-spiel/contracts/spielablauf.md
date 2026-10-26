# Vertrag: Spielablauf mit Zeitleiste, Uhr und GameSession

Technischer Vertrag zu Beginn, Fortsetzen, Speichern und Verlassen eines Spiels. Entscheidungen in
[research.md](../research.md) (R6 bis R9, R16), Zustände in [data-model.md](../data-model.md).
Rümpfe stehen hier bewusst nicht (Verfassung, Grundsatz II).

## Dateien

```text
src/
├── project.godot                  # geändert: Autoload GameSession nach Timeline
├── core/
│   ├── game_session.gd            # neu: Autoload GameSession
│   ├── timeline.gd                # geändert: kein Selbststart, resume_game(), stop_game()
│   └── game_clock.gd              # geändert: set_date()
└── test/
    ├── test_game_session.gd       # neu
    ├── test_timeline.gd           # geändert: Selbststart entfällt
    └── test_game_clock.gd         # geändert: set_date()
```

Reihenfolge der Autoloads: `GameClock`, `Timeline`, `GameWindow`, `GameSession`. `GameSession`
braucht die beiden ersten und kommt deshalb danach.

## Timeline

Unverändert: `start_game(seed = -1, difficulty = Difficulty.DEFAULT) -> Error`, die Signale, die
Eingriffe und `get_seed()`, `get_difficulty()`, `get_event()`, `running_entries()`.

```gdscript
## Liest und prüft den Katalog und hängt sich an die Uhr. Ein Spiel beginnt hier nicht mehr; das
## tut GameSession (FR-003). Ein fehlerfreier Katalog erzeugt weiter keine Ausgabe.
func _ready() -> void

## Setzt ein gespeichertes Spiel fort (FR-008, FR-022): prüft [param game_catalog] wie den Katalog
## des Spiels (CatalogValidator, without_faulty(), Meldungen über push_error() wie in
## _load_catalog()), legt darauf einen Lauf mit [param seed] und [param difficulty] an, spielt
## [param interventions] mit TimelineRun.replay() nach und den Lauf bis [param day]. Für diese Tage
## sendet es kein Signal; das erste kommt für den Tag nach [param day]. Ein abgelehnter Eingriff
## kommt als push_warning() mit Grund, der Rest gilt.
##
## ERR_INVALID_PARAMETER und Meldung, wenn Seed, Grad oder Tag außerhalb liegen; ein laufendes
## Spiel bleibt dann, wie es ist.
@warning_ignore("shadowed_global_identifier")
func resume_game(game_catalog: EventCatalog, seed: int, difficulty: Difficulty.Level,
		interventions: Array[Dictionary], day: int) -> Error

## Beendet das laufende Spiel: run wird null. Danach kommt kein Signal mehr, bis ein Spiel beginnt.
func stop_game() -> void

## Ob ein Spiel läuft.
func is_running() -> bool
```

`_on_day_passed()` tut wie bisher nichts, solange `run` null ist.

## GameClock

```gdscript
## Setzt die Uhr auf [param new_date], ohne Signale. paused bleibt, wie es ist; liegt das Datum im
## Spielzeitraum, ist die Uhr danach nicht am Ende. Für Anlegen, Fortsetzen und Verlassen.
func set_date(new_date: GameDate) -> void
```

## GameSession

```gdscript
extends Node

## Autoload GameSession: das laufende Spiel (research.md, R7). Hält den Spielstand, zu dem es
## gehört, setzt Uhr und Zeitleiste und speichert über SaveStore. Solange ein Spiel läuft,
## speichert es auch beim Schließen des Fensters und bei Cmd+Q (R8).

## Speichern ist gescheitert; [param message] ist der Satz für die Meldung.
signal save_failed(message: String)

## Ordner der Spielstände; Tests setzen ihren eigenen, bevor der Knoten in den Baum kommt.
var folder: String = SaveStore.FOLDER
## null heißt GameClock bzw. Timeline; Tests setzen eigene Knoten.
var clock: Node = null
var timeline: Node = null
## Liefert die Unix-Zeit für „angelegt“ und „zuletzt gespielt“; Tests geben feste Zeiten vor.
var now: Callable = func() -> int: return int(Time.get_unix_time_from_system())
## Würfelt den Seed eines neuen Spiels; Tests setzen einen mit festem Seed (Analyse, C4).
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Wird beim Beenden aufgerufen; ungültig heißt get_tree().quit(). Tests setzen eine eigene
## Funktion, denn quit() beendete ihren ganzen Lauf (wie Werkstatt.quit_callback).
var quit_callback: Callable
## Das laufende Spiel; null, solange keins läuft.
var current: SaveGame = null
## Satz zum letzten Fehler, für die Meldung.
var last_error: String = ""

func is_running() -> bool
## Die Spielstände im Ordner, für Hauptmenü und Liste.
func store() -> SaveStore

## Beginnt ein Spiel am 01.01.1985 mit [param difficulty] und [param seed] (< 0 heißt würfeln mit
## rng), in dieser Reihenfolge (data-model.md, „GameSession“; Analyse, C6): Seed festlegen,
## Spielstand „Spiel N“ anlegen und mit is_new schreiben, dann Uhr setzen und
## Timeline.start_game(seed, difficulty). Gibt es zur Nummer schon eine Datei, etwa aus einem
## zweiten Fenster, nimmt es die nächste (CHK002). Scheitert das Schreiben, beginnt kein Spiel, die
## Zeitleiste sendet nichts, und last_error ist „Speichern ging nicht. Es ist kein Spiel angelegt.“
@warning_ignore("shadowed_global_identifier")
func start_new(difficulty: Difficulty.Level, seed: int = -1) -> Error
## Setzt [param slot] fort (FR-016), nur wenn er fortsetzbar ist, sonst ERR_UNAVAILABLE. Speichert
## gleich danach (R9); scheitert das, läuft das Spiel trotzdem: Rückgabe OK, last_error ist
## „Speichern ging nicht. Dein Spiel läuft weiter.“, und save_failed kommt. Der Spielbildschirm
## zeigt die Meldung beim Erscheinen (Analyse, F5).
func resume(slot: SaveSlot) -> Error
## Speichert das laufende Spiel; ERR_UNCONFIGURED ohne Spiel. Der Tag kommt von der Uhr, höchstens
## TimelineRun.LAST_DAY (Analyse, C11). Bei einem Fehler save_failed; nach einem gelungenen
## Speichern ist last_error leer.
func save() -> Error
## Speichert und beendet das laufende Spiel (FR-020). Scheitert das Speichern, läuft es weiter.
func leave() -> Error

## Fängt NOTIFICATION_WM_CLOSE_REQUEST ab, solange ein Spiel läuft: speichern und beenden; scheitert
## das Speichern, bleibt das Fenster offen, und ein zweites Schließen beendet ohne Speichern (R8).
func _notification(what: int) -> void
```

`auto_accept_quit` ist aus, solange `current` gesetzt ist, und sonst an. In der Werkstatt läuft nie
ein Spiel; dort bleibt die Einstellung der Werkstatt.

## Tests

Wie `test_timeline.gd` arbeiten die Tests nicht mit den Autoloads: Jeder baut eigene Uhr,
Zeitleiste und `GameSession` mit Test-Katalog und eigenem Ordner unter `user://`.

| Test | prüft | Anforderung |
|---|---|---|
| `test_timeline.gd` | Nach `_ready()` und zwei Bildern läuft kein Spiel (`run == null`, Uhrtage senden nichts); `resume_game()` am 14.03.1986 sendet für den 14.03. nichts und ab dem 15.03. dasselbe wie ein Spiel ohne Pause, Tag für Tag bis zum 31.12.1986, Seed 4711, Schwer; `resume_game()` nimmt die übergebene Kopie, nicht den Katalog der Zeitleiste; Grenzen von Seed, Grad, Tag; `stop_game()`. Fünf Tests nutzten bisher den Selbststart und rufen künftig `start_game()` selbst auf, mit unveränderten Erwartungen: `test_ohne_seed_wird_gewuerfelt`, `test_ohne_grad_gilt_mittel`, `test_meldung_zu_einem_profil_bekommt_keinen_zusatz_zum_ereignis`, `test_fehlender_katalog_ergibt_leeren_lauf_und_fehlermeldung` und `test_unlesbarer_katalog_ergibt_leeren_lauf_und_fehlermeldung` (Analyse, F1). Der Helfer `_zeitleiste()` startet kein Spiel mehr; sein Doc-Kommentar sagt das | FR-003, FR-008, FR-022, US3 Szenario 4 |
| `test_game_clock.gd` | `set_date()` ohne Signale, am 31.12.1999 nicht am Ende | R6 |
| `test_game_session.gd` | Neues Spiel legt „Spiel 1“ mit Grad, Seed, 01.01.1985 an; zwei neue Spiele mit demselben Grad haben verschiedene Seeds; Nummern mit Lücken; Verlassen speichert das Datum auf den Tag: 01.01.1985, 15.02.1985, 14.03.1986, 31.12.1999, vorgespult mit der eigenen Uhr; Fortsetzen setzt Uhr, Lauf und „zuletzt gespielt“; zwei Fenster: Eine Datei `spiel_N.json` mit der nächsten Nummer liegt schon da, bevor `start_new()` schreibt, und das neue Spiel weicht auf N + 1 aus, ohne sie zu berühren; ein neues Spiel mit `rng` aus festem Seed hat den erwarteten Seed, das nächste einen anderen; ein Spiel anlegen, den Katalog der Zeitleiste gegen einen anderen tauschen, fortsetzen: der Fahrplan ist der des gespeicherten Katalogs (FR-022; Analyse, E1); Fortsetzen, nachdem die Datei von außen gelöscht wurde, schreibt den gelesenen Stand wieder (Edge Case „Datei ändert sich von außen“; Analyse, E3); scheitert das Anlegen, sendet die Zeitleiste nichts; ein Spielstand mit `catalog_500.json` vom 31.12.1999 ist in höchstens 1 s fortgesetzt; Speichern scheitert beim Anlegen, beim Fortsetzen, beim Verlassen und beim Schließen; Schließen mit Spiel speichert und ruft `quit_callback`, beim zweiten Mal nach einem Fehler ohne Speichern; ohne Spiel kein Speichern | FR-006, FR-009, FR-010, FR-011, FR-016, FR-022, SC-002, SC-005, US1 Szenario 4 |
| `test_title_screen.gd`, Startprobe | Die Hauptszene startet, und nach mehreren Bildern läuft kein Spiel. Dass auch keine Datei entsteht, prüft der Test in Phase 4, sobald `TitleScreen.session` da ist (T020) | FR-003, US1 Szenario 5, SC-006 |

**Feste Größe:** Ein Spiel, das mit `start_game(4711)` beginnt, sendet dieselben Signale wie vor
dem Feature; die übrigen Tests von `test_timeline.gd` laufen mit dem geänderten Helfer unverändert.
