class_name TimelineEvent
extends RefCounted

## Ein Ereignis des Ereigniskatalogs (data-model.md, „TimelineEvent“): was passieren kann, nicht
## wann es in einem bestimmten Spiel passiert. Wann, steht im Fahrplan eines Laufs.
##
## Es gibt fünf Arten. Fixe Ereignisse stehen an einem Datum, jährliche jedes Jahr an denselben
## Tagen, „beim Start gesetzte“ bekommen ihre Termine beim Spielstart in einem Zeitfenster,
## Ereignisse „über Wahrscheinlichkeit“ werden Monat für Monat gewürfelt, und „nur als Folge“
## kommen nur als Folgeereignis eines anderen. Welche Felder gelten, hängt an der Art; die übrigen
## behalten ihre Vorgaben und stehen nicht in der Datei.
##
## Tage sind Tagesindizes wie in GameDate (01.01.1985 = 0, 31.12.1999 = 5477); in der Datei
## stehen sie lesbar als "JJJJ-MM-TT", Tage im Jahr als "MM-TT" oder "MM-ende".

enum Kind { FIXED, YEARLY, PRESET, CHANCE, FOLLOW_ONLY }

## Namen in der Datei, in der Reihenfolge von Kind.
const KIND_NAMES: Array[String] = ["fixed", "yearly", "preset", "chance", "follow_only"]
## Anzeige in der Reihenfolge von Kind. YEARLY ist die Art „fix“ mit dem Häkchen „jährlich“.
const KIND_LABELS: Array[String] = [
	"fix", "fix, jährlich", "beim Start gesetzt", "über Wahrscheinlichkeit", "nur als Folge",
]
## Schlüssel, die jedes Ereignis in der Datei hat (contracts/ereigniskatalog.md, „Felder“).
const COMMON_KEYS := ["category", "description", "effects", "follow_ups", "id", "kind", "title"]
## Weitere Schlüssel je Art.
const KIND_KEYS := {
	Kind.FIXED: ["date", "duration_days"],
	Kind.YEARLY: ["yearly"],
	Kind.PRESET: [
		"conditions", "count_min", "count_weights", "duration_days", "min_gap_days", "window",
	],
	Kind.CHANCE: [
		"conditions", "duration_days", "max_occurrences", "min_gap_days", "monthly_chance",
		"window",
	],
	Kind.FOLLOW_ONLY: ["conditions", "duration_days"],
}
const WINDOW_KEYS := ["from", "to"]
const YEARLY_KEYS := ["end", "from", "start", "to"]

## Kennung aus a–z, 0–9 und _, eindeutig und stabil; andere Ereignisse verweisen darüber.
var id: String = ""
var title: String = ""
var description: String = ""
## Kennung einer EventCategory.
var category: String = ""
var kind: Kind = Kind.FIXED
var effects: Array[EventEffect] = []
var follow_ups: Array[FollowUp] = []
## Nur bei PRESET, CHANCE und FOLLOW_ONLY (FR-006). Steht der Schlüssel bei einem fixen oder
## jährlichen Ereignis in der Datei, wird er trotzdem gelesen, damit die Prüfung das als V17
## meldet und nicht als unbekannten Schlüssel.
var conditions: Array[EventCondition] = []

## FIXED: Tag des Ereignisses.
var date: int = 0
## FIXED, PRESET, CHANCE, FOLLOW_ONLY: Dauer in Tagen, int ≥ 0; 0 heißt Augenblick.
var duration_days: int = 0
## YEARLY: Jahre, in denen es gilt, 1985 bis 1999.
var yearly_from: int = 1985
var yearly_to: int = 1999
## YEARLY: (Monat, Tag) des Beginns.
var yearly_start: Vector2i = Vector2i(1, 1)
## YEARLY: (Monat, Tag) des letzten Tags; Tag 0 heißt Monatsende; (0, 0) heißt ohne Dauer.
var yearly_end: Vector2i = Vector2i(0, 0)
## PRESET, CHANCE: Zeitfenster, beide Tage einschließlich. Vorgabe ist der ganze Spielzeitraum
## bis zum Tag 5477, dem 31.12.1999.
var window_from: int = 0
var window_to: int = 5477
## PRESET, CHANCE: Mindestabstand zwischen zwei Beginnen in Tagen, int ≥ 0.
var min_gap_days: int = 0
## PRESET: kleinste Anzahl.
var count_min: int = 1
## PRESET: Gewicht je Anzahl ab count_min in Prozent, Summe 100. Die Vorgabe [100] heißt:
## genau count_min-mal.
var count_weights: Array[float] = [100.0]
## CHANCE: Grundchance pro Monat als Anteil von 0 bis 1.
var monthly_chance: float = 0.0
## CHANCE: Höchstzahl; 0 heißt unbegrenzt.
var max_occurrences: int = 0


## Liest ein Ereignis aus seinem Dictionary in der Datei.
##
## Fehlt ein Schlüssel, ist er unbekannt oder hat er den falschen Typ, hängt es eine Meldung V22
## an [param issues] an und setzt die Vorgabe (data-model.md, „Vorgaben“). Das Ereignis kommt
## trotzdem zurück, damit die Werkstatt es zeigen und reparieren kann.
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> TimelineEvent:
	var event := TimelineEvent.new()
	var first := issues.size()
	# Erst die Art, denn sie bestimmt, welche Schlüssel dazugehören. Ist sie unlesbar, gilt
	# FIXED, und die Schlüssel der Arten werden weder geprüft noch gelesen. Sonst käme zur
	# Meldung über die Art noch eine je Schlüssel, die zu FIXED nicht passt.
	var kind_known := _is_one_of(data.get("kind"), KIND_NAMES)
	event.kind = CatalogIssue.read_choice(data, "kind", KIND_NAMES, issues, event.kind) as Kind
	CatalogIssue.check_keys(data, event._allowed_keys(kind_known), issues)
	event.category = CatalogIssue.read_string(data, "category", issues, event.category)
	event.description = CatalogIssue.read_string(data, "description", issues, event.description)
	event.id = CatalogIssue.read_string(data, "id", issues, event.id)
	event.title = CatalogIssue.read_string(data, "title", issues, event.title)
	if kind_known:
		event._read_kind_fields(data, issues)
	# Die Wirkungen erst nach der Dauer: Ohne Scope hängt ihre Vorgabe an der Dauer.
	event._read_effects(data, issues)
	event._read_follow_ups(data, issues)
	# Bedingungen bei jeder Art; bei fixen und jährlichen aber nur, wenn sie dastehen.
	if data.has("conditions") or event._takes_conditions():
		event._read_conditions(data, issues)
	CatalogIssue.locate(issues, first, event._place(), event.id)
	return event


## Das Ereignis als Dictionary für die Datei, mit genau den Schlüsseln seiner Art
## (Schreibregel 4). Felder anderer Arten fallen weg, leere Listen bleiben stehen.
func to_dict() -> Dictionary:
	var effect_list: Array[Dictionary] = []
	for effect in effects:
		effect_list.append(effect.to_dict())
	var follow_up_list: Array[Dictionary] = []
	for follow_up in follow_ups:
		follow_up_list.append(follow_up.to_dict())
	var result := {
		"category": category,
		"description": description,
		"effects": effect_list,
		"follow_ups": follow_up_list,
		"id": id,
		"kind": KIND_NAMES[kind],
		"title": title,
	}
	match kind:
		Kind.FIXED:
			result["date"] = GameDate.from_day_index(date).to_iso()
			result["duration_days"] = duration_days
		Kind.YEARLY:
			result["yearly"] = {
				"end": _day_of_year_text(yearly_end),
				"from": yearly_from,
				"start": _day_of_year_text(yearly_start),
				"to": yearly_to,
			}
		Kind.PRESET:
			result["conditions"] = _condition_list()
			result["count_min"] = count_min
			result["count_weights"] = _weights_for_file()
			result["duration_days"] = duration_days
			result["min_gap_days"] = min_gap_days
			result["window"] = _window_dict()
		Kind.CHANCE:
			result["conditions"] = _condition_list()
			result["duration_days"] = duration_days
			result["max_occurrences"] = max_occurrences
			result["min_gap_days"] = min_gap_days
			# Anteile stehen auf vier Nachkommastellen in der Datei (Schreibregel 3).
			result["monthly_chance"] = roundf(monthly_chance * 10000.0) / 10000.0
			result["window"] = _window_dict()
		Kind.FOLLOW_ONLY:
			result["conditions"] = _condition_list()
			result["duration_days"] = duration_days
	return result


## Ob das Ereignis eine Dauer hat: jährliche über ihr Ende, alle anderen über duration_days.
func has_duration() -> bool:
	if kind == Kind.YEARLY:
		return yearly_end != Vector2i.ZERO
	return duration_days > 0


## „fix“, „fix, jährlich“, „beim Start gesetzt“, „über Wahrscheinlichkeit“, „nur als Folge“.
func kind_label() -> String:
	return KIND_LABELS[kind]


## Tiefe Kopie mit gleicher Kennung. Sie entsteht wie bei EventCatalog.duplicate_catalog() über
## to_dict() und from_dict() und enthält deshalb, was in der Datei stünde: Felder einer anderen
## Art haben ihre Vorgaben, Anteile sind gerundet.
func duplicate_event() -> TimelineEvent:
	var ignored: Array[CatalogIssue] = []
	return TimelineEvent.from_dict(to_dict(), ignored)


# --- Lesen ------------------------------------------------------------------

## Erlaubte Schlüssel. conditions ist immer dabei; bei unlesbarer Art auch alle Schlüssel aller
## Arten.
func _allowed_keys(kind_known: bool) -> Array:
	var allowed: Array = COMMON_KEYS.duplicate()
	allowed.append("conditions")
	if kind_known:
		allowed.append_array(KIND_KEYS[kind])
	else:
		for keys: Array in KIND_KEYS.values():
			allowed.append_array(keys)
	return allowed


func _read_kind_fields(data: Dictionary, issues: Array[CatalogIssue]) -> void:
	match kind:
		Kind.FIXED:
			date = _read_day(data, "date", issues, date)
			duration_days = CatalogIssue.read_int(data, "duration_days", issues, duration_days)
		Kind.YEARLY:
			_read_yearly(data, issues)
		Kind.PRESET:
			count_min = CatalogIssue.read_int(data, "count_min", issues, count_min)
			_read_weights(data, issues)
			duration_days = CatalogIssue.read_int(data, "duration_days", issues, duration_days)
			min_gap_days = CatalogIssue.read_int(data, "min_gap_days", issues, min_gap_days)
			_read_window(data, issues)
		Kind.CHANCE:
			duration_days = CatalogIssue.read_int(data, "duration_days", issues, duration_days)
			max_occurrences = CatalogIssue.read_int(data, "max_occurrences", issues,
				max_occurrences)
			min_gap_days = CatalogIssue.read_int(data, "min_gap_days", issues, min_gap_days)
			monthly_chance = CatalogIssue.read_float(data, "monthly_chance", issues,
				monthly_chance)
			_read_window(data, issues)
		Kind.FOLLOW_ONLY:
			duration_days = CatalogIssue.read_int(data, "duration_days", issues, duration_days)


## "window": {"from": "JJJJ-MM-TT", "to": "JJJJ-MM-TT"} → window_from, window_to.
func _read_window(data: Dictionary, issues: Array[CatalogIssue]) -> void:
	var window: Variant = CatalogIssue.fetch(data, "window", [TYPE_DICTIONARY], "ein Objekt",
		issues)
	if typeof(window) == TYPE_NIL:
		return
	var first := issues.size()
	CatalogIssue.check_keys(window, WINDOW_KEYS, issues)
	window_from = _read_day(window, "from", issues, window_from)
	window_to = _read_day(window, "to", issues, window_to)
	CatalogIssue.prefix_fields(issues, first, "window.")


## "yearly": {"end", "from", "start", "to"} → yearly_end, yearly_from, yearly_start, yearly_to.
func _read_yearly(data: Dictionary, issues: Array[CatalogIssue]) -> void:
	var yearly: Variant = CatalogIssue.fetch(data, "yearly", [TYPE_DICTIONARY], "ein Objekt",
		issues)
	if typeof(yearly) == TYPE_NIL:
		return
	var first := issues.size()
	CatalogIssue.check_keys(yearly, YEARLY_KEYS, issues)
	yearly_end = _read_day_of_year(yearly, "end", issues, yearly_end)
	yearly_from = CatalogIssue.read_int(yearly, "from", issues, yearly_from)
	yearly_start = _read_day_of_year(yearly, "start", issues, yearly_start)
	yearly_to = CatalogIssue.read_int(yearly, "to", issues, yearly_to)
	CatalogIssue.prefix_fields(issues, first, "yearly.")


## Gewichte je Anzahl. Ist ein Eintrag keine Zahl, gilt für das ganze Feld die Vorgabe.
func _read_weights(data: Dictionary, issues: Array[CatalogIssue]) -> void:
	var list: Variant = CatalogIssue.fetch(data, "count_weights", [TYPE_ARRAY],
		"eine Liste von Zahlen", issues)
	if typeof(list) == TYPE_NIL:
		return
	var items: Array = list
	var weights: Array[float] = []
	for i in items.size():
		if typeof(items[i]) != TYPE_INT and typeof(items[i]) != TYPE_FLOAT:
			issues.append(CatalogIssue.wrong_type("count_weights[%d]" % i, "eine Zahl", items[i]))
			return
		weights.append(float(items[i]))
	count_weights = weights


func _read_effects(data: Dictionary, issues: Array[CatalogIssue]) -> void:
	var entries := CatalogIssue.read_entries(data, "effects", issues)
	for i: int in entries:
		var entry: Dictionary = entries[i]
		var first := issues.size()
		var effect := EventEffect.from_dict(entry, issues)
		CatalogIssue.prefix_fields(issues, first, "effects[%d]." % i)
		# Ohne lesbaren Scope gilt die Vorgabe aus FR-007: DURING bei Ereignissen mit Dauer.
		if not _is_one_of(entry.get("scope"), EventEffect.SCOPE_NAMES):
			effect.scope = EventEffect.Scope.DURING if has_duration() else EventEffect.Scope.ONCE
		effects.append(effect)


func _read_follow_ups(data: Dictionary, issues: Array[CatalogIssue]) -> void:
	var entries := CatalogIssue.read_entries(data, "follow_ups", issues)
	for i: int in entries:
		var first := issues.size()
		follow_ups.append(FollowUp.from_dict(entries[i], issues))
		CatalogIssue.prefix_fields(issues, first, "follow_ups[%d]." % i)


func _read_conditions(data: Dictionary, issues: Array[CatalogIssue]) -> void:
	var entries := CatalogIssue.read_entries(data, "conditions", issues)
	for i: int in entries:
		var first := issues.size()
		conditions.append(EventCondition.from_dict(entries[i], issues))
		CatalogIssue.prefix_fields(issues, first, "conditions[%d]." % i)


## Ob die Art Bedingungen kennt (FR-006).
func _takes_conditions() -> bool:
	return kind == Kind.PRESET or kind == Kind.CHANCE or kind == Kind.FOLLOW_ONLY


## Das Ereignis in Meldungen: über seine Kennung, ohne Kennung über seinen Titel.
func _place() -> String:
	if not id.is_empty():
		return "Ereignis „%s“" % id
	if not title.is_empty():
		return "Ereignis „%s“ ohne Kennung" % title
	return "Ereignis ohne Kennung"


## data[key] als Tagesindex aus "JJJJ-MM-TT", sonst V22 und [param fallback]. Auch ein Text,
## der kein Kalendertag ist, etwa "1993-02-30", ist V22.
static func _read_day(data: Dictionary, key: String, issues: Array[CatalogIssue],
		fallback: int) -> int:
	var text: Variant = CatalogIssue.fetch(data, key, [TYPE_STRING], "ein Datum als Text", issues)
	if typeof(text) == TYPE_NIL:
		return fallback
	var parsed := GameDate.from_iso(text)
	if parsed == null:
		issues.append(CatalogIssue.structure_error(key,
			"„%s“ ist kein Kalendertag in der Form JJJJ-MM-TT." % text))
		return fallback
	return parsed.to_day_index()


## data[key] als (Monat, Tag) aus "MM-TT", "MM-ende" (Tag 0) oder "" (0, 0), sonst V22 und
## [param fallback]. Ob es den Tag im Monat gibt, etwa beim 02-30, prüft erst der Validator
## (V09); hier zählen die Form, ein Monat von 01 bis 12 und ein Tag ab 01, damit nichts verloren
## geht, was sich zurückschreiben lässt. Ein Monat oder Tag 00 ließe sich nicht zurückschreiben:
## „00-00“ und „00-ende“ ergäben (0, 0), also still „ohne Dauer“, und beim Speichern „“; „05-00“
## ergäbe (5, 0), also still „Monatsende“, und beim Speichern „05-ende“ (T098).
static func _read_day_of_year(data: Dictionary, key: String, issues: Array[CatalogIssue],
		fallback: Vector2i) -> Vector2i:
	var text: Variant = CatalogIssue.fetch(data, key, [TYPE_STRING], "ein Tag im Jahr als Text",
		issues)
	if typeof(text) == TYPE_NIL:
		return fallback
	var value: String = text
	if value.is_empty():
		return Vector2i.ZERO
	var month_text := value.substr(0, 2)
	var day_text := value.substr(3)
	if value.length() >= 5 and value[2] == "-" and _is_digits(month_text) \
			and month_text.to_int() >= 1 and month_text.to_int() <= 12:
		if day_text == "ende":
			return Vector2i(month_text.to_int(), 0)
		if day_text.length() == 2 and _is_digits(day_text) and day_text.to_int() >= 1:
			return Vector2i(month_text.to_int(), day_text.to_int())
	issues.append(CatalogIssue.structure_error(key,
		"„%s“ ist kein Tag im Jahr wie 11-01 oder 12-ende." % value))
	return fallback


## Ob [param value] einer der Namen ist. Ein typisiertes Array meldet einen Fehler, wenn man es
## nach einem Wert anderen Typs fragt; deshalb kommt erst der Typ.
static func _is_one_of(value: Variant, names: Array[String]) -> bool:
	return typeof(value) == TYPE_STRING and names.has(value)


## Ob [param text] nur aus Ziffern besteht und nicht leer ist.
static func _is_digits(text: String) -> bool:
	if text.is_empty():
		return false
	for i in text.length():
		if not text[i].is_valid_int():
			return false
	return true


# --- Schreiben --------------------------------------------------------------

func _condition_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for condition in conditions:
		list.append(condition.to_dict())
	return list


func _window_dict() -> Dictionary:
	return {
		"from": GameDate.from_day_index(window_from).to_iso(),
		"to": GameDate.from_day_index(window_to).to_iso(),
	}


## Gewichte für die Datei: auf zwei Nachkommastellen gerundet, ganze als int, also 30 statt
## 30.0 (Schreibregel 3).
func _weights_for_file() -> Array:
	var weights := []
	for weight in count_weights:
		var rounded := roundf(weight * 100.0) / 100.0
		if rounded == floorf(rounded):
			weights.append(int(rounded))
		else:
			weights.append(rounded)
	return weights


## (Monat, Tag) als "MM-TT", Tag 0 als "MM-ende", (0, 0) als "".
static func _day_of_year_text(value: Vector2i) -> String:
	if value == Vector2i.ZERO:
		return ""
	if value.y == 0:
		return "%02d-ende" % value.x
	return "%02d-%02d" % [value.x, value.y]
