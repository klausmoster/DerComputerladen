class_name EventCatalog
extends RefCounted

## Der Ereigniskatalog: alle Kategorien und Ereignisse des Spiels, gelesen aus einer JSON-Datei
## (contracts/ereigniskatalog.md). Er beschreibt, was passieren kann, und ändert sich während
## eines Spiels nie; ein Lauf arbeitet auf einer eigenen Kopie.
##
## Lesen: Ist die Datei kein gültiges JSON, gibt es keinen Katalog, sondern eine Meldung V22 mit
## Zeile und Grund. Fehler in einzelnen Einträgen sind dagegen Meldungen V22 neben einem Katalog,
## in dem der Eintrag mit seinen Vorgaben steht, damit die Werkstatt ihn zeigen und reparieren
## kann.
##
## Schreiben: Gleicher Inhalt ergibt immer dieselbe Datei, und eine Feldänderung ändert genau eine
## Zeile (FR-035). Dafür sorgen die Schreibregeln: Schlüssel alphabetisch, Tabs, Ereignisse nach
## Kennung, ganze Zahlen als int, Anteile gerundet.

const DEFAULT_PATH := "res://data/event_catalog.json"
const FORMAT := 1
## Schlüssel der obersten Ebene.
const KEYS := ["categories", "events", "format"]

## Reihenfolge = Zeilen im Zeitstrahl.
var categories: Array[EventCategory] = []
## Nach Kennung sortiert.
var events: Array[TimelineEvent] = []


## Parst JSON-Text. Bei einem Parse-Fehler: null und eine Meldung V22 mit Zeile und Grund in
## [param issues]. Strukturfehler landen ebenfalls in [param issues].
##
## null kommt auch zurück, wenn der Text gar kein Objekt ist oder ein anderes Format als 1 hat:
## So einen Text als Katalog zu lesen und wieder zu speichern, würde ihn zerstören.
static func from_json(text: String, issues: Array[CatalogIssue]) -> EventCatalog:
	var json := JSON.new()
	if json.parse(text) != OK:
		# get_error_line() zählt ab 0, Texteditoren zählen ab 1.
		var line := json.get_error_line() + 1
		# Godots Text endet ohne Punkt; mit Punkt passt er zu allen anderen Meldungen.
		issues.append(CatalogIssue.structure_error("Zeile %d" % line,
			"Kein gültiges JSON in Zeile %d: %s." % [line, json.get_error_message()]))
		return null
	var first := issues.size()
	if typeof(json.data) != TYPE_DICTIONARY:
		issues.append(CatalogIssue.wrong_type("", "ein Objekt { … }", json.data))
		CatalogIssue.locate(issues, first, "Katalog")
		return null
	var data: Dictionary = json.data
	# Fehlt format, gilt 1. Eine andere Zahl heißt: Die Datei stammt aus einer späteren Version.
	var format := CatalogIssue.read_int(data, "format", issues, FORMAT)
	if format != FORMAT:
		issues.append(CatalogIssue.structure_error("format",
			"Das Format %d kennt diese Version nicht, sie liest nur %d." % [format, FORMAT]))
		CatalogIssue.locate(issues, first, "Katalog")
		return null
	CatalogIssue.check_keys(data, KEYS, issues)
	var category_entries := CatalogIssue.read_entries(data, "categories", issues)
	var event_entries := CatalogIssue.read_entries(data, "events", issues)
	CatalogIssue.locate(issues, first, "Katalog")

	var catalog := EventCatalog.new()
	for i: int in category_entries:
		var start := issues.size()
		catalog.categories.append(EventCategory.from_dict(category_entries[i], issues))
		# Für Ereignisse hat eine Meldung das Feld event_id, für Kategorien keins. Deshalb kommt
		# die Stelle der Kategorie in der Liste vor das Feld, etwa „categories[2].color“.
		CatalogIssue.prefix_fields(issues, start, "categories[%d]." % i)
	for i: int in event_entries:
		catalog.events.append(TimelineEvent.from_dict(event_entries[i], issues))
	catalog.sort_events()
	return catalog


## Liest eine Datei; fehlt sie, null und eine Meldung mit Pfad.
static func read_file(path: String, issues: Array[CatalogIssue]) -> EventCatalog:
	if not FileAccess.file_exists(path):
		issues.append(CatalogIssue.structure_error("", "Die Katalogdatei %s fehlt." % path))
		return null
	var text := FileAccess.get_file_as_string(path)
	var error := FileAccess.get_open_error()
	if error != OK:
		issues.append(CatalogIssue.structure_error("",
			"Die Katalogdatei %s lässt sich nicht lesen: %s." % [path, error_string(error)]))
		return null
	var first := issues.size()
	var catalog := from_json(text, issues)
	if catalog == null:
		# Ohne Katalog weiß nur die Meldung, welche Datei gemeint ist.
		for i in range(first, issues.size()):
			issues[i].message = "%s: %s" % [path, issues[i].message]
	return catalog


## Kanonische Form nach den Schreibregeln (ereigniskatalog.md), mit Zeilenumbruch am Ende;
## Anteile auf vier, Gewichte auf zwei Nachkommastellen gerundet.
func to_json() -> String:
	var category_list: Array[Dictionary] = []
	for category in categories:
		category_list.append(category.to_dict())
	var event_list: Array[Dictionary] = []
	for event in _sorted_by_id(events):
		event_list.append(event.to_dict())
	var data := {"categories": category_list, "events": event_list, "format": FORMAT}
	# Mit "\t" steht jedes Element auf einer eigenen Zeile, je Ebene ein Tab mehr; true sortiert
	# die Schlüssel jedes Dictionarys alphabetisch.
	return JSON.stringify(data, "\t", true) + "\n"


func write_file(path: String) -> Error:
	var text := to_json()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var stored := file.store_string(text)
	file.close()
	return OK if stored else ERR_FILE_CANT_WRITE


## null, wenn unbekannt.
func get_event(id: String) -> TimelineEvent:
	for event in events:
		if event.id == id:
			return event
	return null


## null, wenn unbekannt.
func get_category(id: String) -> EventCategory:
	for category in categories:
		if category.id == id:
			return category
	return null


## Tiefe Kopie über to_dict()/from_dict(): Die Kopie hat nur, was auch in der Datei stünde.
func duplicate_catalog() -> EventCatalog:
	var copy := EventCatalog.new()
	# Aus einem gültigen to_dict() entstehen keine Meldungen.
	var ignored: Array[CatalogIssue] = []
	for category in categories:
		copy.categories.append(EventCategory.from_dict(category.to_dict(), ignored))
	for event in events:
		copy.events.append(TimelineEvent.from_dict(event.to_dict(), ignored))
	return copy


## Nach Kennung, verglichen mit < (Unicode-Codepunkte).
func sort_events() -> void:
	events = _sorted_by_id(events)


## Kopie ohne die Ereignisse, zu denen eine Meldung der Stufe ERROR gehört, samt der
## Folgeereignisse, die auf sie zeigen (data-model.md, „Fehlerhafte Ereignisse ausnehmen“).
## Bedingungen bleiben stehen: Ein ausgenommenes Ereignis tritt nie ein.
##
## Eine Meldung gehört über ihre event_id zu einem Ereignis. Eine Meldung ohne Ereignis, etwa zu
## einer Kategorie, trifft deshalb nur Ereignisse ohne Kennung; die sind ohnehin fehlerhaft (V01).
func without_faulty(issues: Array[CatalogIssue]) -> EventCatalog:
	var faulty := {}
	for issue in issues:
		if issue.severity == CatalogIssue.Severity.ERROR:
			faulty[issue.event_id] = true
	var copy := duplicate_catalog()
	var kept: Array[TimelineEvent] = []
	for event in copy.events:
		if faulty.has(event.id):
			continue
		var follow_ups: Array[FollowUp] = []
		for follow_up in event.follow_ups:
			if not faulty.has(follow_up.target):
				follow_ups.append(follow_up)
		event.follow_ups = follow_ups
		kept.append(event)
	copy.events = kept
	return copy


## Die Ereignisse nach Kennung. sort_custom() ist nicht stabil; bei gleicher Kennung (V02)
## entscheidet deshalb die bisherige Stelle, damit gleicher Inhalt immer gleich herauskommt.
static func _sorted_by_id(list: Array[TimelineEvent]) -> Array[TimelineEvent]:
	var position := {}
	for i in list.size():
		position[list[i]] = i
	var by_id := func(a: TimelineEvent, b: TimelineEvent) -> bool:
		if a.id != b.id:
			return a.id < b.id
		return position[a] < position[b]
	var sorted: Array[TimelineEvent] = list.duplicate()
	sorted.sort_custom(by_id)
	return sorted
