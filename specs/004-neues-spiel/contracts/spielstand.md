# Vertrag: Spielstand, Ordner und geteilte Eingriffe

Technischer Vertrag zum Kern der Spielstände: Klassen ohne Node, die Dateien lesen, prüfen und
sicher schreiben. Entscheidungen in [research.md](../research.md) (R1 bis R5, R10, R16), Felder und
Regeln in [data-model.md](../data-model.md). Rümpfe stehen hier bewusst nicht (Verfassung,
Grundsatz II). GDScript ist durchgehend typisiert, Doc-Kommentare deutsch wie im übrigen Projekt.

## Dateien

```text
src/
├── core/
│   ├── save/
│   │   ├── save_game.gd                # neu: class_name SaveGame
│   │   ├── save_slot.gd                # neu: class_name SaveSlot
│   │   └── save_store.gd               # neu: class_name SaveStore
│   └── timeline/
│       ├── intervention_file.gd        # neu: class_name InterventionFile (aus WhatIfProbe)
│       ├── timeline_run.gd             # geändert: replay()
│       └── event_catalog.gd            # geändert: from_data()
├── tools/werkstatt/what_if_probe.gd    # geändert: nutzt InterventionFile und replay()
└── test/
    ├── test_save_game.gd               # neu
    ├── test_save_store.gd              # neu
    ├── test_save_resume_run.gd         # neu: SC-003 im Kern
    ├── test_intervention_file.gd       # neu
    └── fixtures/spielstaende/          # neu: kaputte und zu neue Spielstände, ein gültiger
```

## InterventionFile

```gdscript
class_name InterventionFile
extends RefCounted

## Die Schlüssel im Eingriffsprotokoll, die Tage sind, auch im Modifikator darin; bisher
## WhatIfProbe.DATE_KEYS.
const DATE_KEYS := ["at_day", "day", "new_day", "from_day", "to_day"]

## Kopie eines Eintrags für die Datei: Tage als „JJJJ-MM-TT“, auch vor 1985; der Wert eines
## Modifikators auf vier Nachkommastellen. Bisher WhatIfProbe._to_file().
static func to_file(record: Dictionary) -> Dictionary
## Kopie eines Eintrags aus der Datei mit Tagesindizes. Nur für Einträge, die wrong_date()
## durchgelassen hat. Bisher WhatIfProbe._from_file().
static func from_file(record: Dictionary) -> Dictionary
## Warum ein Eintrag kein gültiges Datum hat, als Satz; leer, wenn alles stimmt. Bisher
## WhatIfProbe._wrong_date().
static func wrong_date(record: Dictionary) -> String
## Ob [param value] ein Kalendertag „JJJJ-MM-TT“ ist.
static func is_date(value: Variant) -> bool
```

`WhatIfProbe` ruft diese Funktionen auf, statt eigene zu haben; ihre übrigen Hilfen bleiben.
**Feste Größe:** `test_what_if_probe.gd` und `test_simulator.gd` laufen unverändert grün, und eine
Probe, die die Werkstatt schreibt, ist Byte für Byte dieselbe wie vorher.

## TimelineRun.replay()

```gdscript
## Spielt [param records] wie ein Eingriffsprotokoll nach: in der Reihenfolge von
## in_replay_order(), je Eintrag bis zu seinem at_day vor und dort apply_intervention(); danach bis
## [param until_day]. Gibt je abgelehntem Eintrag { "record": Dictionary, "reason": String } zurück,
## reason aus last_refusal, in der Reihenfolge des Nachspielens. Die Meldungen des Abspielens
## landen wie immer im Protokoll; zurückgegeben werden sie nicht.
func replay(records: Array[Dictionary], until_day: int) -> Array[Dictionary]
```

`WhatIfProbe.build_run()` legt den Lauf an, ruft `replay()` und setzt aus der Rückgabe
`not_applicable` mit seinen Bezeichnungen wie bisher.

## EventCatalog.from_data()

```gdscript
## Wie from_json(), aber für schon geparste Daten, etwa den Abschnitt „catalog“ eines Spielstands.
## from_json() parst den Text und ruft dann from_data(). Ist [param data] kein Objekt oder hat es
## ein anderes Format als 1: null und eine Meldung V22 in [param issues].
static func from_data(data: Variant, issues: Array[CatalogIssue]) -> EventCatalog
```

Die Meldungen von `from_json()` bleiben Zeichen für Zeichen gleich; die Tests des Katalogs laufen
unverändert.

## SaveGame

```gdscript
class_name SaveGame
extends RefCounted

const FORMAT := 1
const MAX_SEED := 2147483647

var number: int = 0
var name: String = ""
var difficulty: Difficulty.Level = Difficulty.DEFAULT
@warning_ignore("shadowed_global_identifier")
var seed: int = 0
## Spieldatum als Tagesindex, 0 bis TimelineRun.LAST_DAY.
var day: int = 0
## Unix-Zeit, UTC.
var created_at: int = 0
var last_played_at: int = 0
var game_version: String = ""
var catalog: EventCatalog
var interventions: Array[Dictionary] = []

## „Spiel 2“: der Name, den ein neues Spiel mit der Nummer [param p_number] bekommt.
static func default_name(p_number: int) -> String
## Kanonischer Text der Datei (data-model.md): Schlüssel alphabetisch, Tabs, Zeilenumbruch am Ende.
func to_json() -> String
## Aus gelesenem JSON; null und ein Satz in [param problems], wenn etwas nicht stimmt (Tabelle
## „Zustand“ in data-model.md, ohne die Zeile zur Formatversion > 1, die SaveSlot prüft).
## [param p_number] ist die Nummer aus dem Dateinamen.
static func from_data(data: Dictionary, p_number: int, problems: Array[String]) -> SaveGame
## „14.03.1986“
func day_text() -> String
## „26.10.2026 21:40“ in Ortszeit, für die Spalte der Liste.
static func time_text(unix: int) -> String
## „am 26.10.2026 um 21:40 Uhr“ in Ortszeit, für Hinweise.
static func time_sentence(unix: int) -> String
```

## SaveSlot

```gdscript
class_name SaveSlot
extends RefCounted

enum State { OK, DAMAGED, TOO_NEW }

var number: int = 0
var state: State = State.DAMAGED
var reason: String = ""
var game: SaveGame = null
var path: String = ""

## Liest die Datei [param p_path] mit der Nummer [param p_number] und prüft sie (data-model.md,
## „SaveSlot“). Wirft nie und gibt nie null zurück; eine unlesbare Datei ergibt DAMAGED mit Grund.
static func read(p_path: String, p_number: int) -> SaveSlot
func can_resume() -> bool
## game.name bei OK, sonst „Spiel N“.
func display_name() -> String
```

## SaveStore

```gdscript
class_name SaveStore
extends RefCounted

const FOLDER := "user://spielstaende/"

var folder: String = FOLDER
var last_error: String = ""

func _init(p_folder: String = FOLDER) -> void
## Alle Spielstände im Ordner, geordnet nach research.md, R12; fehlt der Ordner, leer.
func list_slots() -> Array[SaveSlot]
## Größte Nummer unter den Dateien eines Spielstands plus 1; ohne solche Dateien 1 (R4).
func next_number() -> int
## Schreibt [param game] nach R3 in fünf Schritten. OK oder der Fehler des Schritts, der scheiterte;
## dann ist der vorige Stand lesbar, und last_error nennt Datei und Schritt für das Protokoll, etwa
## „Die Datei user://spielstaende/spiel_2.json.neu lässt sich nicht schreiben.“ Den Satz für den
## Spieler wählt GameSession (spielablauf.md).
func write(game: SaveGame) -> Error
## Löscht spiel_<N>.json, .neu und .alt dieser Nummer, sonst nichts (FR-018).
func delete(p_number: int) -> Error
## Pfad der Datei zu einer Nummer, etwa „user://spielstaende/spiel_2.json“.
func path_of(p_number: int) -> String
```

## Tests

Alle Tests schreiben in eigene Ordner unter `user://`, etwa `user://test_save_store/`, und räumen
sie in `after_each()` ab. Kataloge kommen aus `src/test/fixtures/`, nie aus `src/data/`.

| Test | prüft | Anforderung |
|---|---|---|
| `test_intervention_file.gd` | Umrechnung hin und zurück, falsches Datum mit Satz, −1 als „1984-12-31“ | R5 |
| `test_save_game.gd` | Rundreise Speicher → Text → Speicher, Text Zeichen für Zeichen gegen eine Erwartung; jede Zeile der Tabelle „Zustand“ mit ihrem Grund; Zeitpunkte als UTC; `default_name()` | FR-007, FR-013, FR-014 |
| `test_save_store.gd` | Liste mit Ordnung, fremde Dateien, fehlender Ordner; nächste Nummer mit Lücken, beschädigten und `.neu`; Schreiben über einen vorhandenen Stand; jeder Abbruch aus R3 mit dem lesbaren Stand danach; Speichern scheitert, weil an der Stelle der `.neu` ein Ordner liegt: alter Stand unverändert, `last_error` gesetzt; Löschen nur der drei Dateien einer Nummer; beschädigte und zu neue werden nie überschrieben; 20 Spielstände mit `catalog_500.json` in höchstens 1 s gelesen | FR-009, FR-011, FR-013, FR-018, SC-002, SC-004 |
| `test_save_resume_run.gd` | SC-003: Seeds 1, 4711, 99999 × drei Grade, Lauf ohne Pause gegen Lauf mit Datei am 14.03.1986, alle Zeilen ab dem 15.03.1986 gleich; dasselbe mit Eingriffen vor und nach dem 14.03.1986; eine Kopie mit einem fehlerhaften Ereignis läuft ohne dieses weiter | FR-008, FR-022, SC-003 |

Die Fixtures unter `fixtures/spielstaende/` sind kleine Dateien je Fehlerfall, benannt nach dem
Fall, etwa `spiel_kein_json.json`, `spiel_format_2.json`, `spiel_ohne_format.json`,
`spiel_grad_extrem.json`, `spiel_seed_negativ.json`, `spiel_seed_zu_gross.json`,
`spiel_datum_2000.json`, `spiel_eingriff_datum.json` und `spiel_katalog_zahl.json`, dazu
`spiel_gueltig.json` mit `catalog_alle_arten.json` und einem Eingriff. Ein Test kopiert sie unter
einem Namen nach dem Muster `spiel_<N>.json` in seinen Ordner, statt sie an Ort und Stelle zu
lesen; so prüft er auch die Namensregel. Quickstart 3.4 nutzt zwei davon.
