# Vertrag: Kern der Zeitleiste, Autoload und Textausgabe mit Schwierigkeitsgraden

Technischer Vertrag zu [spec.md](../spec.md) (US1, FR-001 bis FR-014, FR-020, FR-021),
Entscheidungen in [research.md](../research.md), Daten in [data-model.md](../data-model.md),
Dateiformat in [ereigniskatalog.md](ereigniskatalog.md), Werkstatt in
[werkstatt.md](werkstatt.md). Er ergänzt
[zeitleiste.md von Feature 002](../../002-zeitleisten-werkstatt/contracts/zeitleiste.md); was
dort steht und hier nicht geändert wird, gilt weiter. Er legt Pfade, Klassen und Signaturen fest,
Rümpfe stehen bewusst nicht hier (Verfassung, Grundsatz II).

Bezeichner im Code sind englisch, Texte und Doc-Kommentare deutsch, GDScript durchgehend
typisiert, Stil wie in `src/core/timeline/`. Die Werte der Aufzählung `Difficulty.Level` sind
deutsch wie die von `EventEffect.Kind` (R1).

## Dateien

```text
src/
├── core/
│   ├── timeline.gd                   # geändert: start_game() mit Grad, get_difficulty(), Meldungen zu Profilen
│   └── timeline/
│       ├── difficulty.gd             # neu: Difficulty, die Grade und ihre Namen
│       ├── difficulty_profile.gd     # neu: DifficultyProfile, ein Profil und die Chance je Zeitabschnitt
│       ├── chance_modifier.gd        # geändert: from_dict(), to_dict()
│       ├── event_catalog.gd          # geändert: profiles, get_profile(), to_dict()
│       ├── catalog_validator.gd      # geändert: V25 bis V31
│       ├── timeline_run.gd           # geändert: Grad, Start-Modifikatoren
│       ├── timeline_message.gd       # geändert: Art START_MODIFIER
│       ├── schedule_text.gd          # geändert: Kopfzeile mit Grad
│       └── timeline_statistics.gd    # geändert: mehrere Grade, Seed für Seed
├── tools/werkstatt/
│   └── fahrplan_ausgabe.gd           # geändert: --grad
└── test/                             # siehe „Tests“
```

Neue Skripte bekommen ihre `.uid`, wenn der Agent danach einmal
`Godot --headless --path src --import` aufruft. Die `.uid`-Dateien werden mit committet.

## Difficulty

```gdscript
class_name Difficulty extends RefCounted

enum Level { LEICHT, MITTEL, SCHWER }
const DEFAULT := Level.MITTEL
## Die Grade mit Profil, in der Reihenfolge der Profile im Katalog (FR-002, FR-004).
const WITH_PROFILE: Array[int] = [Level.LEICHT, Level.SCHWER]

## "leicht", "mittel", "schwer": der Name in Katalog, Probe und Textausgabe; leer bei einem
## unbekannten Grad.
static func key(level: int) -> String
## „Leicht“, „Mittel“, „Schwer“: der Name in Texten; bei einem unbekannten Grad „Grad 7“.
static func label(level: int) -> String
## Name → Grad; −1, wenn es den Grad nicht gibt. Groß- und Kleinschreibung zählt.
static func from_key(text: String) -> int
## Ob [param level] einer der drei Grade ist. Eine Aufzählung ist zur Laufzeit eine ganze Zahl,
## deshalb prüft jeder Spielstart hier (FR-011).
static func is_valid(level: int) -> bool
```

Die Hilfen nehmen `int`, damit sie auch einen unbekannten Wert sicher annehmen. Öffentliche
Methoden, die einen gültigen Grad erwarten, nehmen `Difficulty.Level`. Ein Grad aus `from_key()`
ist eine Zahl: Der Aufrufer prüft ihn mit `is_valid()` und übergibt ihn mit `as
Difficulty.Level`. Ein Parameter vom Typ `Difficulty.Level` nimmt auch eine 7 an, ohne Fehler
(Probe in research.md, R1); deshalb prüfen `Timeline.start_game()` und `TimelineRun._init()`
selbst.

Jede Umwandlung einer Zahl in `Difficulty.Level` geschieht mit `as Difficulty.Level`, so wie der
Code es mit `as Kind` hält: Werte aus `WITH_PROFILE`, aus `from_key()`, aus der Liste
`difficulties` und aus den Kennungen der Auswahlfelder. Die Startprobe mit `-d` läuft nach T005
und nach T011 und muss still bleiben (Analyse, U3).

## DifficultyProfile

```gdscript
class_name DifficultyProfile extends RefCounted

var level: Difficulty.Level = Difficulty.Level.LEICHT
## Die Start-Modifikatoren in der Reihenfolge der Datei.
var modifiers: Array[ChanceModifier] = []

func _init(p_level: Difficulty.Level = Difficulty.Level.LEICHT) -> void
## Liest die Liste eines Profils (ereigniskatalog.md). Strukturfehler V22 kommen mit Feld und Ort
## nach [param issues]: ChanceModifier.from_dict() meldet sie mit dem bloßen Schlüssel, etwa
## „value“, und from_list() setzt danach mit CatalogIssue.prefix_fields() field_prefix() davor
## und mit CatalogIssue.locate() den Ort aus place(). Ein Eintrag, der kein Objekt ist, wird ein
## Start-Modifikator mit den Vorgaben, Feld „profiles.schwer[2]“, damit die Stellen zu den
## Feldern der Meldungen passen.
static func from_list(p_level: Difficulty.Level, data: Variant,
		issues: Array[CatalogIssue]) -> DifficultyProfile
## Je Start-Modifikator ChanceModifier.to_dict(), in der Reihenfolge des Profils.
func to_list() -> Array[Dictionary]
## { "schwer": to_list() }: der Teil des Abschnitts profiles für diesen Grad. EventCatalog.to_dict()
## setzt den Abschnitt daraus zusammen, und CatalogEditor.content_key() bekommt darüber den Text
## des Profils (Analyse, U1).
func to_dict() -> Dictionary
## Tiefe Kopie über to_list() und from_list().
func duplicate_profile() -> DifficultyProfile

## „profiles.schwer[2].“: der Anfang der Felder aller Meldungen zu dieser Stelle.
static func field_prefix(p_level: int, index: int) -> String
## „Profil „Schwer“, Start-Modifikator „reklamationswelle““, ohne Kennung
## „Profil „Schwer“, Start-Modifikator Nr. 3 ohne Kennung“.
static func place(p_level: int, index: int, modifier: ChanceModifier) -> String
## Die Stellen im Profil von [param p_level], zu denen eine Meldung der Stufe ERROR gehört, als
## { index: true }: Feld „profiles.<key>[<i>]“ oder mit „profiles.<key>[<i>].“ am Anfang,
## verglichen nach ganzen Pfadteilen. without_faulty() und das Formular nutzen es.
static func faulty_indices(issues: Array[CatalogIssue], p_level: int) -> Dictionary
## Die wirksame Chance von [param event] über das ganze Spiel in Abschnitten, je
## { "from_day": int, "to_day": int, "chance": float } (data-model.md, „Chance je
## Zeitabschnitt“). [param profile] null heißt Mittel. Stellen in [param skip] zählen nicht.
static func chance_periods(event: TimelineEvent, profile: DifficultyProfile,
		skip: Dictionary = {}) -> Array[Dictionary]
## „8 %“ oder „3 % bis 31.12.1994, 6 % ab 01.01.1995“, in der Mitte „5 % vom 01.01.1990 bis
## 31.12.1994“. Formatiert im Kern wie ScheduleEntry._percent(), nie über EventForm, denn die
## Werkstatt ist vom Export ausgeschlossen (Analyse, U11).
static func describe_periods(periods: Array[Dictionary]) -> String
```

## ChanceModifier

Bisher ohne Lesen und Schreiben (R2 von Feature 002), jetzt auch als Start-Modifikator im
Katalog:

```gdscript
## Die Schlüssel in Katalog und Probe, alphabetisch.
const KEYS := ["event_id", "from_day", "id", "reason", "to_day", "value"]

## Liest einen Start-Modifikator in der Form der Katalogdatei. Ein fehlender Schlüssel, ein
## falscher Typ, ein unbekannter Schlüssel und ein Datum, das kein Kalendertag ist, ergeben V22
## und die Vorgabe aus data-model.md; to_day ist dann 5477, nicht −1. Das Feld der Meldung ist der
## bloße Schlüssel; Stelle und Ort setzt DifficultyProfile.from_list().
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> ChanceModifier
## Form der Katalogdatei: Tage als „JJJJ-MM-TT“, value auf vier Nachkommastellen gerundet.
func to_dict() -> Dictionary
```

Felder, Vorgaben der Klasse und `is_active()` bleiben, wie sie sind. Das Eingriffsprotokoll des
Laufs schreibt seine Modifikatoren weiter mit `TimelineRun._modifier_record()`, mit Tagen als
Zahl. Die Proben wandeln die Tage beim Schreiben in Daten um, wie bisher.

## Katalog und Prüfung

```gdscript
class_name EventCatalog extends RefCounted
const KEYS := ["categories", "events", "format", "profiles"]
## Immer zwei: [0] Leicht, [1] Schwer, auch leer; _init() legt sie an.
var profiles: Array[DifficultyProfile] = []

func _init() -> void
## Das Profil des Grads; null für Mittel und unbekannte Grade.
func get_profile(level: int) -> DifficultyProfile
## Die Datei als Dictionary nach den Schreibregeln: categories, events, format, profiles. Die
## einzige Stelle, die die oberste Ebene zusammenstellt; to_json() und die Sicherungskopie der
## Werkstatt nutzen sie. Den Abschnitt profiles setzt es aus DifficultyProfile.to_dict() zusammen.
func to_dict() -> Dictionary
## Jeder Start-Modifikator, den without_faulty() mit denselben [param issues] weglässt, je
## { "level": int, "index": int, "modifier": ChanceModifier, "place": String,
## "reason": String, "by_event": bool }. reason ist der Text der ersten Meldung der Stufe ERROR
## an seiner Stelle, sonst „Das Ereignis „<kennung>“ wird übersprungen, deshalb auch dieser
## Start-Modifikator.“ by_event ist true, wenn es an seiner Stelle keine solche Meldung gibt und er
## nur wegen seines Ereignisses wegfällt. Simulator und Statistik nennen alle; Zeitleiste und
## Textausgabe nennen nur die mit by_event, die übrigen stehen schon in ihren Meldungen (FR-013;
## Analyse, G1).
func skipped_start_modifiers(issues: Array[CatalogIssue]) -> Array[Dictionary]
```

Geändert:
- `from_json()` liest `profiles` nach ereigniskatalog.md. Fehlt der Abschnitt, gibt es keine
  Meldung.
- `to_json()` schreibt `to_dict()` mit `JSON.stringify(…, "\t", true)` und einem Zeilenumbruch
  am Ende.
- `duplicate_catalog()` kopiert die Profile mit.
- `without_faulty(issues)` lässt in den Profilen der Kopie die Start-Modifikatoren weg, zu deren
  Stelle eine Meldung der Stufe `ERROR` gehört. Ebenso die, deren Ereignis in der Kopie kein
  Ereignis über Wahrscheinlichkeit ist (data-model.md). Dieselbe Regel liefert
  `skipped_start_modifiers()`; beide teilen sich eine Hilfe, damit sie nie auseinanderlaufen.

```gdscript
class_name CatalogValidator extends RefCounted
## Geändert: nach Ereignissen und Kategorien folgen die Profile mit V25 bis V31, Leicht vor
## Schwer, je Profil nach Stelle, je Start-Modifikator nach Regel.
static func validate(catalog: EventCatalog) -> Array[CatalogIssue]
## Nur die Regeln der Profile, V25 bis V31; validate() nutzt sie.
static func validate_profiles(catalog: EventCatalog) -> Array[CatalogIssue]
```

`validate_event()` bleibt, wie es ist, denn die Regeln der Profile sind keine Regeln eines
Ereignisses. Meldungen zu Profilen haben ein leeres `event_id` (R8). Ihr Text nennt den Ort aus
`place()` und das volle Feld, wie bei Kategorien: „Profil „Schwer“, Start-Modifikator
„reklamationswelle“, Feld „profiles.schwer[2].reason“: Der Grund ist leer.“ (Analyse, B4)

`WARNING_RULES` bekommt `"V31"`. Beginn und Ende prüft V31 einzeln, mit den Texten aus R8: Ein
Beginn, der kein Monatserster ist, ergibt eine Warnung an `from_day` mit der ersten Würfelrunde,
ein Ende, das kein Monatsletzter ist, eine an `to_day` mit der letzten. Liegt im Zeitraum kein
Monatserster, gibt es nur eine Warnung an `from_day`: Er wirkt nie. Gilt V27 oder V28, prüft V31
nicht (Analyse, U7). `without_faulty()` nimmt wegen einer Warnung nichts aus.

## Der Lauf

```gdscript
class_name TimelineRun extends RefCounted

## Der Grad des Spiels, fest ab _init().
var difficulty: Difficulty.Level = Difficulty.DEFAULT
## Die Start-Modifikatoren des Grads, als Kopien in der Reihenfolge des Profils. _init() setzt
## sie, bevor begin() zum ersten Mal würfelt (FR-007); danach ändern sie sich nie.
var start_modifiers: Array[ChanceModifier] = []
## Je Start-Modifikator, den der Lauf nicht setzen konnte, ein Satz mit dem Ort aus place() und
## dem Grund, etwa „Profil „Schwer“, Start-Modifikator „reklamationswelle“: Das Ereignis
## „reklamationswelle“ gibt es im Katalog nicht.“ Meist leer, denn die Aufrufer rechnen mit
## without_faulty().
var start_refusals: PackedStringArray = PackedStringArray()

## Geändert: mit Grad. Ein unbekannter Grad gilt als Mittel und steht in start_refusals;
## ablehnen müssen ihn die Aufrufer vorher (FR-011). TimelineRun.new(catalog, seed) bleibt
## gültig und heißt Mittel.
func _init(p_catalog: EventCatalog, p_seed: int,
		p_difficulty: Difficulty.Level = Difficulty.DEFAULT) -> void
## Geändert: dazu "start_modifiers" mit den Start-Modifikatoren, die an dem Tag gelten. "sum" und
## "effective" rechnen sie mit. "modifiers" bleiben die Modifikatoren aus Eingriffen.
func chance_info(event_id: String, day: int) -> Dictionary
## Geändert: Hat nur ein Start-Modifikator diese Kennung, ERR_UNAVAILABLE mit dem Grund
## „„reklamationswelle“ ist ein Start-Modifikator von Schwer und lässt sich im laufenden Spiel
## nicht entfernen.“ (FR-010)
func remove_modifier(id: String) -> Error
```

Ablauf in `_init()` (data-model.md, „Anlegen“):
1. Alles wie in Feature 002: Katalog kopieren, fixe, jährliche und gesetzte Termine, Würfel je
   Ereignis über Wahrscheinlichkeit.
2. Je Start-Modifikator des Profils prüfen wie `add_modifier()`: Das Ereignis gibt es, und es
   kommt über Wahrscheinlichkeit; Kennung und Grund sind nicht leer; das Ende ist gesetzt und
   liegt nicht vor dem Beginn; die Kennung kommt im Profil nicht zweimal vor. Besteht er, kommt
   eine Kopie nach `start_modifiers` und eine Meldung `START_MODIFIER` mit dem Tag −1 ins
   Protokoll. Sonst kommt ein Satz nach `start_refusals`.

Regeln:
- Start-Modifikatoren kommen nie nach `modifiers` und nie ins Eingriffsprotokoll `interventions`.
  `add_modifier()` prüft doppelte Kennungen nur unter `modifiers` (R5).
- In der Würfelrunde schreibt `_roll_month()` die geltenden Start-Modifikatoren zuerst in
  `modifier_notes`, als „Schwer: Anspruchsvolle Kunden +5“, dann die Eingriffe wie bisher (R6).
- Würfel, Zwecke und Würfe bleiben, wie sie sind. Ein Grad verschiebt nur Schwellen (FR-009).
- Mit Mittel oder einem leeren Profil entstehen dieselben Termine und dasselbe Protokoll wie in
  Feature 002, Zeichen für Zeichen.

## Meldungen

```gdscript
class_name TimelineMessage extends RefCounted
enum Kind {
	EVENT_STARTED, EVENT_ENDED, EFFECT_STARTED, EFFECT_ENDED, ENTRY_SKIPPED, CHAIN_STOPPED,
	INTERVENTION,
	START_MODIFIER,  ## neu: ein Start-Modifikator des Grads gilt ab Spielbeginn
}
const KIND_LABELS: Array[String] = [
	"Beginn", "Ende", "Wirkung", "Wirkungsende", "Entfall", "Kettenabbruch", "Eingriff", "Grad",
]
```

Eine Meldung `START_MODIFIER` hat den Tag −1, das Ereignis des Start-Modifikators, keinen Termin
und den Text „Reklamationswelle: Start-Modifikator „Anspruchsvolle Kunden“ (Schwer) +5
Prozentpunkte vom 01.01.1985 bis 31.12.1999“. Den Wert schreibt der Lauf wie bei Eingriffen, mit
`_points_text()`, also „+5 Prozentpunkte“ oder „-1 Prozentpunkt“.

## Textausgabe des Fahrplans

```gdscript
class_name ScheduleText extends RefCounted
## Geändert: Kopfzeile „# Seed 4711, Grad Schwer, bis 31.12.1999“, mit dem Grad des Laufs, auch
## bei Mittel (FR-021). Die Zeilen darunter wie bisher.
static func plan_lines(run: TimelineRun, until_day: int = TimelineRun.LAST_DAY) -> PackedStringArray
```

`protocol_lines()` bleibt. Bei Schwer stehen die Zeilen „Grad“ vorn, denn sie sind die ersten
Meldungen des Protokolls.

## Statistik

```gdscript
class_name TimelineStatistics extends RefCounted
## Die Grade, die die Statistik rechnet, je ein Wert aus Difficulty.Level, in dieser Reihenfolge.
var difficulties: Array[int] = [Difficulty.DEFAULT]

## Geändert: [param p_difficulties] leer heißt nur Mittel.
func _init(p_catalog: EventCatalog, p_game_count: int = 1000, p_first_seed: int = 1,
		p_difficulties: Array[int] = []) -> void
## Wie bisher: die Ergebnisse des ersten Grads der Liste, nach Kennung.
func results() -> Array[EventStatistic]
## Die Ergebnisse eines Grads; leer, wenn er nicht in der Liste steht.
func results_for(level: int) -> Array[EventStatistic]
```

Geändert (R15, data-model.md):
- Ein Spiel ist ein Seed. `run_for()` spielt den Seed `first_seed + games_done` nacheinander in
  jedem Grad der Liste, jeden mit denselben Eingriffen in derselben Ordnung wie bisher.
- `games_done` zählt Seeds, die in allen Graden fertig sind. Erst dann gehen ihre Zahlen in die
  Ergebnisse ein.
- Ein Abbruch verwirft den angefangenen Seed in allen Graden.
- `accepted` und `refused` stammen aus dem ersten Seed im ersten Grad.
- Mit nur Mittel rechnet die Statistik genau wie in Feature 002.

## Autoload `Timeline`

```gdscript
## Geändert: mit Grad (FR-006). Ein Seed über MAX_SEED oder ein unbekannter Grad ergibt
## ERR_INVALID_PARAMETER und ein push_error(); es beginnt kein neues Spiel, und ein laufendes
## bleibt, wie es ist (FR-011). Der Start am Ende des ersten Bilds bleibt ohne Argumente: Mittel
## mit gewürfeltem Seed, bis 01-05 „Neues Spiel“ den Grad übergibt.
func start_game(seed: int = -1, difficulty: Difficulty.Level = Difficulty.DEFAULT) -> Error
## Der Grad des laufenden Spiels; −1, solange keins läuft (FR-006).
func get_difficulty() -> int
```

Geändert:
- **Beim Laden:** `_load_catalog()` meldet Fehler in Profilen wie die übrigen mit `push_error()`.
  - Den Zusatz „Das Ereignis wird übersprungen.“ bekommt eine Meldung nur, wenn sie eine Kennung
    eines Ereignisses trägt. Bisher hing er auch an leeren Kennungen und träfe sonst Meldungen zu
    Profilen (Analyse, U5).
  - Eine Meldung an der Stelle eines Start-Modifikators bekommt „Der Start-Modifikator wird
    übersprungen.“
  - Start-Modifikatoren, die nur wegfallen, weil ihr Ereignis ausgenommen ist, nennt es aus
    `catalog.skipped_start_modifiers(issues)`, die mit `by_event`: „Zeitleiste: Profil „Schwer“,
    Start-Modifikator „reklamationswelle“: Das Ereignis „reklamationswelle“ wird übersprungen,
    deshalb auch dieser Start-Modifikator.“ (FR-013)
- **Beim Start:** `start_game()` legt `TimelineRun.new(catalog, game_seed, difficulty)` an. Steht
  danach etwas in `run.start_refusals`, meldet es jeden Satz mit `push_error()`.
- **Signale:** `_send()` macht aus `START_MODIFIER` kein Signal.
- **Ohne Ausgabe:** Ein gültiger Katalog erzeugt beim Start weiterhin keine Ausgabe, auch mit
  Profilen; die Startprobe bleibt still.

## Textausgabe

`src/tools/werkstatt/fahrplan_ausgabe.gd`:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 --grad schwer [--bis 1999-12-31] [--katalog res://…] [--protokoll]
```

- **Argument:** `--grad` nimmt `leicht`, `mittel` oder `schwer`, ohne Angabe gilt `mittel`.
  Jeder andere Wert und ein fehlender Wert sind ein falsches Argument: Meldung und Aufrufhilfe
  auf stderr, Exit-Code 1. Die Aufrufhilfe nennt `--grad`.
- **Lauf:** `TimelineRun.new(catalog, seed, grad)` auf `without_faulty()`, wie bisher.
- **Profilfehler:** Fehler in Profilen stehen auf stderr wie Fehler in Ereignissen, über dieselbe
  Schleife, und der Exit-Code ist 1. Eine Meldung an der Stelle eines Start-Modifikators bekommt
  „Der Start-Modifikator fehlt in der Ausgabe.“, so wie Ereignisse „Das Ereignis fehlt in der
  Ausgabe.“ bekommen. Start-Modifikatoren, die nur wegen ihres Ereignisses wegfallen, nennt sie
  dazu aus `skipped_start_modifiers()`, die mit `by_event`. So steht jeder weggelassene genau
  einmal auf stderr, und die Ausgabe läuft ohne sie (FR-013; Analyse, G1).
- **Kopfzeile:** Sie kommt von `ScheduleText` und nennt den Grad, auch bei Mittel.

## Tests

Neu oder geändert, alle mit Test-Katalogen unter `src/test/fixtures/` und festen Seeds:

| Datei | Prüft |
|---|---|
| `test_difficulty.gd` | neu: `key()`, `label()`, `from_key()` mit unbekanntem Namen und großem S, `is_valid()` mit 7 und −1 |
| `test_difficulty_profile.gd` | neu: `ChanceModifier.from_dict()` und `to_dict()` als Rundreise und jeder Fall von V22 darin, mit dem bloßen Schlüssel als Feld; `from_list()`/`to_list()` mit Stelle und Ort in den Meldungen, `to_dict()`, `field_prefix()`, `place()` mit und ohne Kennung, `faulty_indices()` für beide Formen des Felds und nicht für `profiles.schwerr`. Dazu `chance_periods()` und `describe_periods()`: US2, Szenario 6 (1 %, 3 %, 8 %), Szenario 7 (3 % bis 31.12.1994, 6 % ab 01.01.1995), drei Abschnitte, Begrenzung auf 0 % und 100 %, Fehlerhaftes zählt nicht, Mittel |
| `test_event_catalog.gd` | geändert, siehe Liste unten |
| `test_catalog_validator.gd` | geändert: V25 bis V31 je mit einer kaputten Fixture in `FAELLE`, V25 bis V30 als `ERROR`, V31 als `WARNING`; der Test für jede Regel erwartet bei Feldern `profiles…` „Profil „“ statt „Ereignis „“ und das volle Feld im Text (Analyse, B4). Dazu Randfälle im Code: V26 für alle vier falschen Arten (fix, jährlich, gesetzt, nur als Folge), V30 leer, mit falschen Zeichen und doppelt, bei jedem Eintrag gemeldet; V31 an Beginn, an Ende, an beiden und „wirkt nie“; Beginn 01.01.1985 und Ende 31.12.1999 ohne Meldung; Reihenfolge Ereignisse, Kategorien, Profile (Analyse, G6) |
| `test_difficulty_run.gd` | neu, siehe Liste unten |
| `test_difficulty_baseline.gd` | neu: Mittel gegen die eingefrorene Grundlinie, Fahrplan ohne Kopfzeile und Protokoll für die Seeds 1, 4711 und 99999, Zeichen für Zeichen (R17) |
| `test_schedule_text.gd` | geändert: die drei Erwartungen an die Kopfzeile mit „Grad Mittel“; eine Kopfzeile mit „Grad Schwer“ |
| `test_fahrplan_ausgabe.gd` | neu in Phase 2, nach der Fehlerprobe: startet die Textausgabe mit `OS.execute()` und vergleicht stdout und stderr als Ganzes; `--grad`, ohne Grad wie Mittel, falsche Werte, und mit `catalog_us1_profil_kaputt.json` jeder weggelassene Start-Modifikator genau einmal |
| `test_timeline.gd` | geändert: Vorgabe Mittel; `start_game()` mit Schwer, `get_difficulty()`; zwei Starts ohne Seed mit Schwer haben je einen eigenen Seed, bei festgesetztem globalem Zufall (`seed()`), damit der Test wiederholbar ist (US1, Szenario 2; Review, CHK027); ein unbekannter Grad wird abgelehnt, und das laufende Spiel bleibt (FR-011); mit `catalog_us1_profil_kaputt.json` wird ein Start-Modifikator auf ein fehlendes Ereignis übersprungen und mit Grad, Kennung und Fehlergrund gemeldet, ebenso einer, dessen Ereignis wegen eines Fehlers ausgenommen ist, und der dritte gilt (US1, Szenario 6; FR-013) |
| `test_timeline_run.gd` | geändert: Der Test der Zeilen je Art kennt acht Arten, mit „Grad“ (Analyse, B1) |
| `test_timeline_statistics.gd` | geändert: Liste der Grade; Seed für Seed; ein Abbruch mitten im Seed lässt alle Grade gleich; SC-003; US4, Szenarien 2 bis 4; `results_for()` |

`test_event_catalog.gd` prüft dazu:
- Profile lesen und schreiben; ein fehlender Abschnitt und ein fehlender Grad ohne Meldung;
- V22 für `mittel`, für einen unbekannten Grad, für Abschnitt, Profil und Eintrag mit falschem
  Typ, für einen Wert als Text, ein ungültiges Datum, einen unbekannten und einen fehlenden
  Schlüssel;
- die Rundreise der eingefrorenen Übernahme ergibt sie selbst, mit Komma hinter `"format": 1`
  und den vier Zeilen des leeren Abschnitts; eine zweite Rundreise ändert nichts;
- `catalog_alle_arten.json` mit Abschnitt ist bytegleich;
- `to_dict()`, und `duplicate_catalog()` kopiert die Profile;
- `without_faulty()` lässt fehlerhafte Start-Modifikatoren weg und die auf ausgenommene oder
  falsche Ereignisse;
- `skipped_start_modifiers()` nennt genau diese, mit Grad, Stelle, Ort und Fehlergrund; `by_event`
  ist nur bei denen gesetzt, die ohne eigene Meldung wegen ihres Ereignisses wegfallen (G1).

`test_difficulty_run.gd` prüft:
- US1, Szenario 1: 8 % im Schwellenwert der Begründung;
- Szenario 3: zweimal Seed 4711 und Schwer ergibt dasselbe;
- Szenario 4: Mittel gegen Schwer unterscheidet sich nur bei Abhängigen;
- Szenario 7: +5 und −6 ergibt 2 %;
- SC-001 mit 100 Wiederholungen; SC-002 mit 100 Seeds und der Hülle der Abhängigen wie
  `VON_REKLAMATION` in `test_schedule_diff.gd`. Geprüft werden alle Markierungen und alle
  weggefallenen Termine in `removed` (Analyse, G2);
- ein leeres Profil ergibt dasselbe wie Mittel;
- zwei Start-Modifikatoren auf dasselbe Ereignis addieren sich; zusammen mit Eingriffen bleibt
  die Chance zwischen 0 % und 100 % (Edge Cases);
- ein Start-Modifikator für einen Teil des Spiels wirkt nur in den Würfelrunden seines Zeitraums:
  vom 15.03.1990 bis 15.06.1994 gilt in der Würfelrunde am 01.03.1990 und am 01.07.1994 die
  Grundchance, am 01.04.1990 und am 01.06.1994 die Summe (Edge Case; Analyse, G3);
- gesetzte, fixe und jährliche Termine von Ereignissen außerhalb der Hülle der Abhängigen sind in
  allen Graden gleich (FR-003; Analyse, I6);
- die Meldungen `START_MODIFIER` am Tag −1, nicht in der Rückgabe von `begin()`, nicht in
  `interventions`;
- `chance_info()` mit `"start_modifiers"`, `modifier_notes` mit dem Grad vorn;
- `remove_modifier()` auf einen Start-Modifikator wird abgelehnt; ein Eingriff mit derselben
  Kennung wie ein Start-Modifikator wird angenommen;
- `start_refusals` bei einem ungeprüften Katalog, ein unbekannter Grad gilt als Mittel.

Bleiben unverändert und müssen grün bleiben: `test_uebernahme.gd`, `test_interventions.gd` und
`test_schedule_diff.gd`.

`test_large_catalog.gd` bekommt einen Test dazu: Er fügt `catalog_500.json` im Speicher 20
Start-Modifikatoren je Profil hinzu, und Prüfung sowie Änderung samt Prüfung bleiben unter
100 ms. Die Fixture selbst bekommt nur den leeren Abschnitt, siehe unten (Analyse, G9).

`test_shipped_catalog.gd` prüft die Profile über `validate()` ohne Änderung mit (FR-014). In
Phase 3 bekommt er einen Test dazu, sobald Klaus die Profile im echten Katalog angelegt hat:
Leicht und Schwer haben je mindestens einen Start-Modifikator, die Werte prüft er nicht (Klaus,
2026-10-22, CHK008). Vorher bliebe der Test rot, denn der echte Katalog hat bis dahin leere
Profile.

Fixtures aus Feature 002, schon in Phase 1 (research.md, R17):
- `event_catalog_uebernahme.json` bleibt Byte für Byte, wie sie ist.
- `catalog_minimal.json` und `catalog_500.json` bekommen den leeren Abschnitt, denn Tests
  vergleichen geschriebenen Text Zeichen für Zeichen mit ihnen.
- `catalog_alle_arten.json` bekommt je einen Start-Modifikator in Leicht und Schwer.
- Weitere Fixtures, die ein Test so vergleicht, behandelt der Agent genauso und nennt sie im
  Bericht.

Fixtures, Namen als Vorschlag:
- `catalog_us1_grade.json`, für US1, US3, US4 und SC-001 bis SC-003:
  - `reklamationswelle` mit 3 % pro Monat, ohne weitere Grenzen;
  - eine Folge davon, die nur als Folge vorkommt, und ein Ereignis über Wahrscheinlichkeit mit
    einer Bedingung darauf;
  - `lieferengpass` mit 4 % pro Monat, unabhängig, auf das kein Profil zeigt (US4, Szenario 4);
  - ein fixes, ein jährliches und ein beim Start gesetztes Ereignis, alle unabhängig (I6);
  - „Leicht −2“ und „Schwer +5“ auf die Reklamationswelle, je für das ganze Spiel.

  Die Tests des Simulators nutzen dieselbe Fixture (Analyse, U6).
- `catalog_us1_profil_kaputt.json` für US1, Szenario 6 und FR-013, mit drei Start-Modifikatoren
  in Schwer: einer auf ein Ereignis, das es nicht gibt (V25), einer auf ein Ereignis über
  Wahrscheinlichkeit, das selbst einen Fehler hat und deshalb ausgenommen wird, etwa mit einer
  Grundchance über 100 % (V12), und einer, der gilt (U6).
- `catalog_v25_profil_ereignis_unbekannt.json` bis `catalog_v31_profil_monatsmitte.json`, je
  eine Regel.
- Drei Fixtures für V22, die mit dem Lesen des Abschnitts entstehen und in `test_event_catalog.gd`
  gelesen werden (Analyse, I8); die übrigen Fälle von V22 prüft der Test im Code:
  - `catalog_v22_profil_mittel.json`: neben `leicht` und `schwer` ein Profil `mittel` mit einem
    Start-Modifikator; Meldung an `profiles.mittel`;
  - `catalog_v22_profil_unbekannt.json`: dazu ein Profil `extrem`; Meldung an `profiles.extrem`;
  - `catalog_v22_profil_wert_text.json`: in Schwer zwei Start-Modifikatoren, der erste gültig, der
    zweite mit dem Wert `"fünf"`; Meldung an `profiles.schwer[1].value`. Die Werkstatt nutzt sie
    auch für die Lesemeldungen eines Profils (werkstatt.md, `test_catalog_editor.gd`; Analyse,
    U2).
- Die Grundlinie `fahrplan_uebernahme_seed_<n>.txt` und `protokoll_uebernahme_seed_<n>.txt` für
  n = 1, 4711, 99999. Sie entsteht mit dem Code vor diesem Feature, als erste Aufgabe.
