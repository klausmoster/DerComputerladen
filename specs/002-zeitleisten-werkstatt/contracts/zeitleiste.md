# Vertrag: Kern der Zeitleiste, Autoload und Textausgabe

Technischer Vertrag zu [spec.md](../spec.md), Entscheidungen in [research.md](../research.md),
Daten in [data-model.md](../data-model.md), Dateiformat in
[ereigniskatalog.md](ereigniskatalog.md), Werkstatt in [werkstatt.md](werkstatt.md). Er legt
Pfade, Klassen, Signale und Signaturen fest; Rümpfe stehen bewusst nicht hier (Verfassung,
Grundsatz II).

Bezeichner im Code sind englisch, Texte und Doc-Kommentare deutsch. GDScript ist durchgehend
typisiert, Einrückung mit Tabs, Stil wie `src/core/game_clock.gd`.

## Dateien

```text
src/
├── core/
│   ├── game_clock.gd                 # geändert: season_changed entfällt
│   ├── game_date.gd                  # geändert: from_iso(), to_iso(), is_valid(); is_holiday_season() und season() entfallen
│   ├── timeline.gd                   # umgebaut: Autoload Timeline als Hülle um TimelineRun
│   └── timeline/                     # neu: der Kern
│       ├── event_catalog.gd          # EventCatalog
│       ├── event_category.gd         # EventCategory
│       ├── timeline_event.gd         # TimelineEvent, verschoben aus core/, umgebaut
│       ├── event_effect.gd           # EventEffect, verschoben aus core/, umgebaut
│       ├── follow_up.gd              # FollowUp
│       ├── event_condition.gd        # EventCondition
│       ├── catalog_issue.gd          # CatalogIssue
│       ├── catalog_validator.gd      # CatalogValidator
│       ├── event_dice.gd             # EventDice
│       ├── schedule_entry.gd         # ScheduleEntry
│       ├── chance_modifier.gd        # ChanceModifier
│       ├── timeline_message.gd       # TimelineMessage
│       ├── timeline_run.gd           # TimelineRun
│       ├── schedule_text.gd          # ScheduleText
│       ├── timeline_statistics.gd    # TimelineStatistics
│       └── event_statistic.gd        # EventStatistic
├── data/
│   ├── event_catalog.json            # neu: der Ereigniskatalog
│   └── event_database.gd             # entfällt
├── scenes/
│   └── timeline_demo.tscn/.gd        # entfällt, die Werkstatt ersetzt sie
├── ui/ui_palette.gd                  # geändert: TOKENS, by_token()
├── tools/werkstatt/                  # neu, siehe werkstatt.md; darin fahrplan_ausgabe.gd
├── export_presets.cfg                # geändert: exclude_filter um tools/* ergänzt
└── test/
    ├── fixtures/                     # neu: Test-Kataloge und Schnappschuss
    └── test_*.gd                     # siehe „Tests“
```

`timeline_event.gd` und `event_effect.gd` werden mit ihren `.uid`-Dateien verschoben
(`git mv`), damit die Resource-IDs bleiben. Gelöschte Skripte verlieren auch ihre `.uid`.

## Geänderte Bestandteile

**`src/core/game_date.gd`** (`class_name GameDate extends RefCounted`), neu:

```gdscript
## "1993-03-22" → GameDate; null, wenn der Text kein gültiges Datum ist.
static func from_iso(text: String) -> GameDate
## GameDate → "1993-03-22".
func to_iso() -> String
## Ob Jahr, Monat und Tag ein Kalendertag sind.
static func is_valid(y: int, m: int, d: int) -> bool
```

Es entfallen `is_holiday_season()` und `season()` samt ihren Tests: Weihnachtsgeschäft und
Jahreszeiten sind jetzt Ereignisse (FR-023, FR-024), und ungenutzter Code wird gelöscht
(Entscheidung aus 01-01).

**`src/core/game_clock.gd`**: Signal `season_changed` und sein Auslösen in `advance_day()`
entfallen (FR-024), ebenso der Test `test_weihnachtsgeschaeft_meldet_sich_am_ersten_november`.
Sonst bleibt die Uhr unverändert.

**`src/ui/ui_palette.gd`**, neu:

```gdscript
## Token-Name aus dem Style-Guide → Farbe, für alle 15 Farben, z. B. &"gehaeuse-hell".
const TOKENS := { &"tusche": TUSCHE, … }
## Farbe zum Token; Color(1, 0, 1) (Magenta) für unbekannte Tokens, damit Fehler auffallen.
static func by_token(token: StringName) -> Color
```

## Datenklassen

Alle erben von `RefCounted`, haben die Felder aus [data-model.md](../data-model.md) als typisierte
`var` und lesen bzw. schreiben das Format aus [ereigniskatalog.md](ereigniskatalog.md).

```gdscript
class_name EventCategory extends RefCounted
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> EventCategory
func to_dict() -> Dictionary

class_name TimelineEvent extends RefCounted
enum Kind { FIXED, YEARLY, PRESET, CHANCE, FOLLOW_ONLY }
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> TimelineEvent
func to_dict() -> Dictionary            # nur die Schlüssel der eigenen Art
func has_duration() -> bool
func kind_label() -> String             # „fix“, „jährlich“, „beim Start gesetzt“, „über Wahrscheinlichkeit“, „nur als Folge“
func duplicate_event() -> TimelineEvent # tiefe Kopie, gleiche Kennung

class_name EventEffect extends RefCounted
enum Kind { PREIS, NACHFRAGE, REPUTATION, KUNDENSTROM, PRESSE }
enum Scope { ONCE, DURING }
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> EventEffect
func to_dict() -> Dictionary
func kind_label() -> String             # „Preis“, „Nachfrage“, „Ruf“, „Kundenstrom“, „Presse“
func describe() -> String               # wie bisher, z. B. „Preis · cpu_486 · -30% — 486 wird …“

class_name FollowUp extends RefCounted
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> FollowUp
func to_dict() -> Dictionary

class_name EventCondition extends RefCounted
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> EventCondition
func to_dict() -> Dictionary

class_name CatalogIssue extends RefCounted
enum Severity { ERROR, WARNING }
var severity: Severity
var rule: String                        # "V01" … "V22"
var event_id: String
var field: String
var message: String
```

`from_dict()` hängt Strukturfehler (V22) an `issues` an und füllt Vorgabewerte; es gibt nie `null`
für ein Ereignis zurück, das sich als Dictionary lesen lässt.

## Katalog und Prüfung

```gdscript
class_name EventCatalog extends RefCounted
const DEFAULT_PATH := "res://data/event_catalog.json"
const FORMAT := 1
var categories: Array[EventCategory] = []
var events: Array[TimelineEvent] = []

## Parst JSON-Text. Bei einem Parse-Fehler: null und eine Meldung V22 mit Zeile und Grund in
## [param issues]. Strukturfehler landen ebenfalls in [param issues].
static func from_json(text: String, issues: Array[CatalogIssue]) -> EventCatalog
## Liest eine Datei; fehlt sie, null und eine Meldung mit Pfad.
static func read_file(path: String, issues: Array[CatalogIssue]) -> EventCatalog
## Kanonische Form nach den Schreibregeln (ereigniskatalog.md), mit Zeilenumbruch am Ende.
func to_json() -> String
func write_file(path: String) -> Error
func get_event(id: String) -> TimelineEvent        # null, wenn unbekannt
func get_category(id: String) -> EventCategory     # null, wenn unbekannt
func duplicate_catalog() -> EventCatalog           # tiefe Kopie über to_dict()/from_dict()
func sort_events() -> void                         # nach Kennung

class_name CatalogValidator extends RefCounted
## Alle Regeln V01 bis V21 aus data-model.md; Reihenfolge der Meldungen: Ereignisse nach
## Kennung, je Ereignis nach Regel.
static func validate(catalog: EventCatalog) -> Array[CatalogIssue]
static func has_errors(issues: Array[CatalogIssue]) -> bool
```

## Würfel

```gdscript
class_name EventDice extends RefCounted
## Neuer Generator; Startwert = SHA-256("<seed>|<purpose>|<key>"), erste 8 Byte (R5).
static func make(seed: int, purpose: String, key: String) -> RandomNumberGenerator
```

Zwecke und Würfe (verbindlich, sonst bricht FR-015):

| Zweck | Schlüssel | Wann | Würfe |
|---|---|---|---|
| `"chance"` | Kennung | ein Generator je `CHANCE`-Ereignis beim Anlegen des Laufs | je Monat 0 bis 179 genau zwei: `randf()` für den Wurf, `randf()` für den Tag, in dieser Reihenfolge, auch wenn das Ereignis nicht in Frage kommt |
| `"preset"` | Kennung | einmal beim Anlegen des Fahrplans | `rand_weighted(count_weights)`, dann k-mal `randf()` (R7) |
| `"follow"` | `"<quelle>|<index>|<tag>"` | beim Beginn der Quelle, je Folgeereignis | `randf()` für die Wahrscheinlichkeit, dann `randi_range(delay_min, delay_max)` |

## Termine, Modifikatoren, Meldungen

```gdscript
class_name ScheduleEntry extends RefCounted
enum Origin { FIXED, YEARLY, PRESET, ROLLED, FOLLOW_UP, INTERVENTION }
enum State { PLANNED, RUNNING, OCCURRED, SKIPPED, CANCELLED }
# Felder wie data-model.md
func origin_label() -> String     # „fix“, „jährlich“, „gesetzt“, „gewürfelt“, „Folge von <titel>“, „Eingriff“
func state_label() -> String      # „geplant“, „läuft“, „eingetreten“, „entfallen“, „abgesagt“
func explain() -> String          # Begründung in einem Satz, z. B. „Würfel 0,021 < Schwelle 0,080 (3 % + Ware vom windigen Händler +5)“
func due_effects() -> Array[Dictionary]   # [{ "effect": EventEffect, "day": int }], nur verzögerte

class_name ChanceModifier extends RefCounted
# Felder wie data-model.md
func is_active(day: int) -> bool          # from_day <= day <= to_day

class_name TimelineMessage extends RefCounted
enum Kind { EVENT_STARTED, EVENT_ENDED, EFFECT_STARTED, EFFECT_ENDED, ENTRY_SKIPPED, CHAIN_STOPPED, INTERVENTION }
# Felder wie data-model.md
func to_line() -> String                  # „22.03.1993  Beginn  Intel Pentium erscheint“ usw., deterministisch
```

## Der Lauf

```gdscript
class_name TimelineRun extends RefCounted

const FIRST_DAY := 0          # 01.01.1985
const LAST_DAY := 5477        # 31.12.1999
const MONTHS := 180
const MAX_CHAIN := 16         # Glieder einer Folgekette am selben Tag (R10)

var catalog: EventCatalog                  # eigene Kopie, wird nie verändert
var seed: int
var today: int = -1                        # zuletzt abgespielter Tag; -1 vor begin()
var entries: Array[ScheduleEntry] = []     # Fahrplan, nach Tag und Tagesreihenfolge sortiert
var modifiers: Array[ChanceModifier] = []
var protocol: Array[TimelineMessage] = []  # alle Meldungen und Eingriffe des Laufs
var last_refusal: String = ""              # deutscher Grund des zuletzt abgelehnten Eingriffs

## Kopiert den Katalog und legt den Fahrplan an: fixe, jährliche und gesetzte Termine (FR-010).
func _init(p_catalog: EventCatalog, p_seed: int) -> void
## Spielt den 01.01.1985 ab, inklusive Würfelrunde Januar 1985 und jährlicher Ereignisse, die
## schon laufen (R9). Nur einmal aufrufbar.
func begin() -> Array[TimelineMessage]
## Spielt alle Tage nach today bis einschließlich day ab, höchstens bis LAST_DAY. Ruft begin()
## selbst auf, falls noch nicht geschehen. Springt von Stichtag zu Stichtag (R6).
func advance_to(day: int) -> Array[TimelineMessage]
func is_finished() -> bool                 # today == LAST_DAY
func get_entry(serial: int) -> ScheduleEntry
func running_entries() -> Array[ScheduleEntry]
## { "base": float, "sum": float, "effective": float, "modifiers": Array[ChanceModifier] }
func chance_info(event_id: String, day: int) -> Dictionary

## Eingriffe (FR-025 bis FR-027). OK oder Error mit Grund in last_refusal:
## ERR_DOES_NOT_EXIST (unbekannte Kennung oder Nummer), ERR_ALREADY_EXISTS (Modifikator-Kennung
## doppelt), ERR_UNAVAILABLE (fix, jährlich, schon begonnen, Tag nicht nach today oder nach
## LAST_DAY), ERR_INVALID_PARAMETER (kein Grund, kein Enddatum, falsche Art).
func add_modifier(modifier: ChanceModifier) -> Error
func remove_modifier(id: String) -> Error
func cancel_entry(serial: int, reason: String) -> Error
func move_entry(serial: int, new_day: int, reason: String) -> Error
func schedule_event(event_id: String, day: int, reason: String) -> Error
```

**Tagesablauf** (R6, FR-016), je abgespieltem Tag d:

1. Enden: `RUNNING`-Termine mit `end_day == d`, nach `serial`. Je Termin erst `EFFECT_ENDED` für
   jede begonnene `DURING`-Wirkung in Listenreihenfolge, dann `EVENT_ENDED`; Zustand
   `OCCURRED`.
2. Fällige verzögerte Wirkungen: `EFFECT_STARTED` für jede Wirkung mit `day + delay_days == d`,
   deren Termin begonnen hat; Termine nach `serial`, Wirkungen in Listenreihenfolge.
3. Würfelrunde, wenn d ein Monatserster ist: `CHANCE`-Ereignisse nach Kennung (R8).
4. Beginne: `PLANNED`-Termine mit `day == d`, sortiert nach `origin`, Kennung, `serial`. Pro
   Termin:
   - Bedingungen prüfen; ist eine nicht erfüllt, `ENTRY_SKIPPED`.
   - Läuft das Ereignis noch, ebenfalls `ENTRY_SKIPPED`.
   - Sonst `EVENT_STARTED`, dann `EFFECT_STARTED` für Wirkungen ohne Verzögerung, dann über die
     Folgeereignisse würfeln. Neue Termine für d kommen hinten an; nach `MAX_CHAIN` Gliedern
     `CHAIN_STOPPED`.

   Zustand danach: `RUNNING` mit Dauer, sonst `OCCURRED`.

Nach `LAST_DAY` gibt es keine Meldung mehr (FR-019). Enden oder Wirkungen, die danach fällig
wären, bleiben mit ihrem Tag im Fahrplan stehen.

## Statistik

```gdscript
class_name EventStatistic extends RefCounted
# Felder wie data-model.md
func mean() -> float
func share_without() -> float
func share_at_max() -> float

class_name TimelineStatistics extends RefCounted
var catalog: EventCatalog                  # Kopie
var first_seed: int = 1
var game_count: int = 1000
var games_done: int = 0
var modifiers: Array[ChanceModifier] = []  # werden in jedem Spiel gesetzt
var schedulings: Array[Dictionary] = []    # [{ "event_id": String, "day": int, "reason": String }]

func _init(p_catalog: EventCatalog, p_game_count: int = 1000, p_first_seed: int = 1) -> void
## Rechnet bis zu [param max_games] weitere Spiele bis zum 31.12.1999. true, wenn alle fertig sind.
func run_batch(max_games: int) -> bool
func results() -> Array[EventStatistic]    # nach Kennung, nur für die fertigen Spiele
```

Absagen und Verschiebungen kennt die Statistik nicht (R11, FR-045).

## Autoload `Timeline`

`src/core/timeline.gd`, `extends Node`, registriert wie bisher als
`Timeline="*res://core/timeline.gd"`.

```gdscript
signal event_fired(event: TimelineEvent, date: GameDate)                       # wie bisher: Beginn
signal effect_applied(effect: EventEffect, source: TimelineEvent, date: GameDate)  # wie bisher
signal event_ended(event: TimelineEvent, date: GameDate)                       # neu
signal effect_ended(effect: EventEffect, source: TimelineEvent, date: GameDate)    # neu
signal entry_skipped(entry: ScheduleEntry, date: GameDate)                     # neu

const CATALOG_PATH := EventCatalog.DEFAULT_PATH
var catalog_path: String = CATALOG_PATH    # Tests setzen einen Test-Katalog, bevor der Knoten in den Baum kommt
var clock: Node = null                     # null heißt Autoload GameClock; Tests setzen eine eigene Uhr
var catalog: EventCatalog                  # geladen, ohne Ereignisse mit Fehlern
var run: TimelineRun

## Legt einen neuen Lauf an; seed < 0 heißt würfeln. Spielt den ersten Tag ab und sendet dessen
## Meldungen.
func start_game(seed: int = -1) -> void
func get_seed() -> int
func get_event(id: String) -> TimelineEvent
# Eingriffe: gleiche Signaturen wie TimelineRun, reichen durch.
func add_modifier(modifier: ChanceModifier) -> Error
func remove_modifier(id: String) -> Error
func cancel_entry(serial: int, reason: String) -> Error
func move_entry(serial: int, new_day: int, reason: String) -> Error
func schedule_event(event_id: String, day: int, reason: String) -> Error
```

Ablauf:
- `_ready()` lädt den Katalog von `catalog_path` und prüft ihn. Ereignisse mit Fehlern meldet es
  mit Kennung und Grund über `push_error()` und nimmt sie heraus. Fehlt der Katalog oder ist er
  unlesbar, gibt es ein `push_error()` mit Pfad und Grund, und der Lauf ist leer (FR-049).
- Danach verbindet es sich mit `day_passed` von `clock` (ohne Angabe `GameClock`) und ruft
  `start_game()` per `call_deferred()` auf (R12).
- `_on_day_passed(date)` ruft `run.advance_to(date.to_day_index())` auf und macht aus jeder
  Meldung das passende Signal.
- Ein gültiger Katalog erzeugt beim Start keine Ausgabe; die Startprobe bleibt still.
- Es entfallen: `fixed_events`, `variable_events`, `history`, `register_event()`,
  `fast_forward_to()` und alle privaten Hilfen der alten Engine. Ein späterer Spielstart kommt mit
  01-05, auf Basis von `TimelineRun.advance_to()`.

## Textausgabe

`src/tools/werkstatt/fahrplan_ausgabe.gd`, `extends SceneTree` (R18):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 [--bis 1999-12-31] [--katalog res://…] [--protokoll]
```

- Ohne `--seed` gilt 1, ohne `--bis` der 31.12.1999, ohne `--katalog` `EventCatalog.DEFAULT_PATH`.
- Ausgabe auf stdout, gebaut von `ScheduleText`. Exit-Code 0; bei unlesbarem Katalog oder
  Katalogfehlern stehen die Meldungen auf stderr, Exit-Code 1.

```gdscript
class_name ScheduleText extends RefCounted
## Kopfzeile „# Seed 4711, bis 31.12.1999“, dann je Termin bis until_day eine Zeile:
## „TT.MM.JJJJ  <kennung, 28 Zeichen>  <herkunft, 12>  <zustand, 12>  <titel>“
## und je verzögerter Wirkung darunter „TT.MM.JJJJ    └ <describe()>“.
static func plan_lines(run: TimelineRun, until_day: int = TimelineRun.LAST_DAY) -> PackedStringArray
## Je Meldung des Protokolls TimelineMessage.to_line().
static func protocol_lines(run: TimelineRun) -> PackedStringArray
```

## Tests

| Datei | Prüft |
|---|---|
| `test_game_date.gd` | geändert: `from_iso`, `to_iso`, `is_valid`; Tests zu Jahreszeit und Weihnachtsgeschäft entfallen |
| `test_game_clock.gd` | geändert: Test zu `season_changed` entfällt |
| `test_event_catalog.gd` | Lesen, Schreiben, Rundreise Datei → Katalog → Datei bytegleich, Zahlen als `int`, Parse-Fehler mit Zeile |
| `test_catalog_validator.gd` | jede Regel V01 bis V22 mit einer kaputten Fixture (SC-006), Warnungen V13 und V20 |
| `test_timeline_run.gd` | Fahrplan fix, jährlich, gesetzt; Würfelrunde inklusive Januar 1985; Dauer, Enden vor Beginnen, Winter am ersten Tag; Wirkungen `ONCE`/`DURING`; Folgeereignisse und Kettenbremse; Bedingungen; nach dem 31.12.1999 nichts mehr; Tag für Tag = Sprünge (SC-002); Unabhängigkeit der Würfel (FR-015, SC-003) |
| `test_interventions.gd` | Modifikatoren: Summe, Begrenzung, Ablauf, einzeln entfernen; Absagen, Verschieben, Einplanen; Ablehnungen |
| `test_timeline_statistics.gd` | 50 % pro Monat → Mittelwert 85,5 bis 94,5 (SC-008); gesetzt 30/70 → 27 bis 33 % ohne; gleiche Ergebnisse bei Wiederholung; mit Modifikatoren |
| `test_schedule_text.gd` | gleiche Ausgabe bei gleichem Seed, Format der Zeilen |
| `test_timeline.gd` | Autoload-Hülle mit eigener Uhr: Signale in der richtigen Reihenfolge, fehlerhafte Ereignisse ausgenommen |
| `test_shipped_catalog.gd` | echter Katalog: fehlerfrei (FR-048), 19 historische Ereignisse für 100 Seeds wie im Schnappschuss (SC-005), Kalender-Ereignisse (FR-023, SC-009) |

Es entfallen `test_timeline_event.gd` und `test_event_database.gd`. Test-Kataloge liegen unter
`src/test/fixtures/` und tragen ihren Zweck im Namen, etwa `catalog_v10_preset_zu_eng.json`.
Wie in `test_game_clock.gd` erzeugen Tests eigene Instanzen und fassen die Autoloads nicht an.
