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
##
## Seit Feature 003 gehören die Profile der Schwierigkeitsgrade dazu, als Abschnitt „profiles“
## am Ende der Datei (contracts/ereigniskatalog.md von Feature 003). Beim Lesen ist er freiwillig,
## eine Datei aus Feature 002 hat ihn nicht; geschrieben wird er immer. Die Formatnummer bleibt 1.

const DEFAULT_PATH := "res://data/event_catalog.json"
const FORMAT := 1
## Schlüssel der obersten Ebene.
const KEYS := ["categories", "events", "format", "profiles"]

## Reihenfolge = Zeilen im Zeitstrahl.
var categories: Array[EventCategory] = []
## Nach Kennung sortiert.
var events: Array[TimelineEvent] = []
## Immer zwei: [0] Leicht, [1] Schwer, auch leer; _init() legt sie an. Mittel hat kein Profil.
var profiles: Array[DifficultyProfile] = []


## Ein leerer Katalog mit zwei leeren Profilen.
func _init() -> void:
	for level: int in Difficulty.WITH_PROFILE:
		profiles.append(DifficultyProfile.new(level as Difficulty.Level))


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
	var profile_lists := _read_profile_lists(data, issues)
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
	# Fehlt ein Grad im Abschnitt, bleibt sein Profil aus _init() leer, ohne Meldung (FR-005).
	for i in Difficulty.WITH_PROFILE.size():
		var level := Difficulty.WITH_PROFILE[i] as Difficulty.Level
		if profile_lists.has(level):
			catalog.profiles[i] = DifficultyProfile.from_list(level, profile_lists[level], issues)
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


## Die Datei als Dictionary nach den Schreibregeln: categories, events, format, profiles. Das ist
## die einzige Stelle, die die oberste Ebene zusammenstellt; to_json() und die Sicherungskopie der
## Werkstatt nutzen sie. Den Abschnitt profiles setzt es aus DifficultyProfile.to_dict() zusammen,
## mit beiden Graden, auch leer (Schreibregel 4).
func to_dict() -> Dictionary:
	var category_list: Array[Dictionary] = []
	for category in categories:
		category_list.append(category.to_dict())
	var event_list: Array[Dictionary] = []
	for event in _sorted_by_id(events):
		event_list.append(event.to_dict())
	var profile_section := {}
	for profile in profiles:
		profile_section.merge(profile.to_dict())
	return {
		"categories": category_list,
		"events": event_list,
		"format": FORMAT,
		"profiles": profile_section,
	}


## Kanonische Form nach den Schreibregeln (ereigniskatalog.md), mit Zeilenumbruch am Ende;
## Anteile auf vier, Gewichte auf zwei Nachkommastellen gerundet.
func to_json() -> String:
	# Mit "\t" steht jedes Element auf einer eigenen Zeile, je Ebene ein Tab mehr; true sortiert
	# die Schlüssel jedes Dictionarys alphabetisch. So kommt profiles ans Ende, hinter format.
	return JSON.stringify(to_dict(), "\t", true) + "\n"


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


## Das Profil des Grads [param level]; null für Mittel und unbekannte Grade, denn sie haben keins.
func get_profile(level: int) -> DifficultyProfile:
	if not Difficulty.WITH_PROFILE.has(level):
		return null
	for profile in profiles:
		if profile.level == level:
			return profile
	return null


## Tiefe Kopie über to_dict()/from_dict(): Die Kopie hat nur, was auch in der Datei stünde. Die
## Profile kopiert duplicate_profile() auf dieselbe Weise.
func duplicate_catalog() -> EventCatalog:
	var copy := EventCatalog.new()
	# Aus einem gültigen to_dict() entstehen keine Meldungen.
	var ignored: Array[CatalogIssue] = []
	for category in categories:
		copy.categories.append(EventCategory.from_dict(category.to_dict(), ignored))
	for event in events:
		copy.events.append(TimelineEvent.from_dict(event.to_dict(), ignored))
	var copied: Array[DifficultyProfile] = []
	for profile in profiles:
		copied.append(profile.duplicate_profile())
	copy.profiles = copied
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
##
## In den Profilen der Kopie fehlen zwei Arten von Start-Modifikatoren (Feature 003, data-model.md,
## „Fehlerhafte Start-Modifikatoren ausnehmen“): die, zu deren Stelle eine Meldung der Stufe ERROR
## gehört, und die, deren Ereignis in der Kopie kein Ereignis über Wahrscheinlichkeit ist, etwa
## weil es selbst ausgenommen ist. Welche das sind, nennt skipped_start_modifiers().
func without_faulty(issues: Array[CatalogIssue]) -> EventCatalog:
	var faulty := _faulty_event_ids(issues)
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
	# Grad → { Stelle: true }. Die Profile der Kopie haben dieselben Stellen wie die des Katalogs.
	var dropped := {}
	for skip in _start_modifier_skips(issues, faulty):
		if not dropped.has(skip["level"]):
			dropped[skip["level"]] = {}
		dropped[skip["level"]][skip["index"]] = true
	for profile in copy.profiles:
		var gone: Dictionary = dropped.get(profile.level, {})
		var kept_modifiers: Array[ChanceModifier] = []
		for index in profile.modifiers.size():
			if not gone.has(index):
				kept_modifiers.append(profile.modifiers[index])
		profile.modifiers = kept_modifiers
	return copy


## Jeder Start-Modifikator, den without_faulty() mit denselben [param issues] weglässt, je
## { "level": int, "index": int, "modifier": ChanceModifier, "place": String, "reason": String,
## "by_event": bool }, Leicht vor Schwer und je Profil nach Stelle. reason ist der Text der ersten
## Meldung der Stufe ERROR an seiner Stelle, sonst „Das Ereignis „<kennung>“ wird übersprungen,
## deshalb auch dieser Start-Modifikator.“ by_event ist true, wenn es an seiner Stelle keine solche
## Meldung gibt und er nur wegen seines Ereignisses wegfällt.
##
## Simulator und Statistik nennen alle. Zeitleiste und Textausgabe nennen nur die mit by_event,
## denn die übrigen stehen schon in ihren eigenen Meldungen (FR-013; Analyse, G1).
func skipped_start_modifiers(issues: Array[CatalogIssue]) -> Array[Dictionary]:
	return _start_modifier_skips(issues, _faulty_event_ids(issues))


## Liest den Abschnitt profiles: Grad → Liste aus der Datei, noch ungeprüft. Fehlt er, ist das
## Ergebnis leer, ohne Meldung. Ist er kein Objekt, steht dort „mittel“ oder ein Grad, den es nicht
## gibt, kommt V22 mit dem Feld „profiles“ bzw. „profiles.<schlüssel>“ (research.md, R4). Den Ort
## „Katalog“ setzt from_json() wie bei den übrigen Schlüsseln der obersten Ebene.
static func _read_profile_lists(data: Dictionary, issues: Array[CatalogIssue]) -> Dictionary:
	var lists := {}
	if not data.has("profiles"):
		return lists
	var section: Variant = data["profiles"]
	if typeof(section) != TYPE_DICTIONARY:
		issues.append(CatalogIssue.wrong_type("profiles", "ein Objekt", section))
		return lists
	var by_key: Dictionary = section
	for key: Variant in by_key:
		var text := str(key)
		var level := Difficulty.from_key(text)
		if Difficulty.WITH_PROFILE.has(level):
			lists[level] = by_key[key]
		elif level == Difficulty.Level.MITTEL:
			issues.append(CatalogIssue.structure_error("profiles.%s" % text, "Für „Mittel“ gibt es "
				+ "kein Profil: Mittel ist der Katalog ohne Start-Modifikatoren."))
		else:
			issues.append(CatalogIssue.structure_error("profiles.%s" % text, ("Den "
				+ "Schwierigkeitsgrad „%s“ gibt es nicht; Profile gibt es nur für „leicht“ und "
				+ "„schwer“.") % text))
	return lists


## Die Kennungen der Ereignisse, zu denen eine Meldung der Stufe ERROR gehört, als
## { kennung: true }. Meldungen ohne Ereignis, etwa zu Kategorien oder Profilen, stehen unter „“.
static func _faulty_event_ids(issues: Array[CatalogIssue]) -> Dictionary:
	var faulty := {}
	for issue in issues:
		if issue.severity == CatalogIssue.Severity.ERROR:
			faulty[issue.event_id] = true
	return faulty


## Die gemeinsame Hilfe von without_faulty() und skipped_start_modifiers(), damit beide nie
## auseinanderlaufen: die Start-Modifikatoren, die wegfallen, in der Form von
## skipped_start_modifiers(). [param faulty] sind die Kennungen der ausgenommenen Ereignisse aus
## _faulty_event_ids().
func _start_modifier_skips(issues: Array[CatalogIssue], faulty: Dictionary) -> Array[Dictionary]:
	# Was die Kopie aus without_faulty() als Ereignis über Wahrscheinlichkeit behält.
	var kept_chance := {}
	for event in events:
		if event.kind == TimelineEvent.Kind.CHANCE and not faulty.has(event.id):
			kept_chance[event.id] = true
	var skips: Array[Dictionary] = []
	for profile in profiles:
		var errors := DifficultyProfile.faulty_indices(issues, profile.level)
		for index in profile.modifiers.size():
			var modifier := profile.modifiers[index]
			var reason := ""
			if errors.has(index):
				reason = _first_error_at(issues, profile.level, index)
			elif not kept_chance.has(modifier.event_id):
				reason = ("Das Ereignis „%s“ wird übersprungen, deshalb auch dieser "
					+ "Start-Modifikator.") % modifier.event_id
			else:
				continue
			skips.append({
				"level": profile.level,
				"index": index,
				"modifier": modifier,
				"place": DifficultyProfile.place(profile.level, index, modifier),
				"reason": reason,
				"by_event": not errors.has(index),
			})
	return skips


## Der Text der ersten Meldung der Stufe ERROR, die zur Stelle [param index] im Profil von
## [param level] gehört. Welche Meldung zu welcher Stelle gehört, entscheidet faulty_indices(),
## dieselbe Regel wie in without_faulty().
static func _first_error_at(issues: Array[CatalogIssue], level: int, index: int) -> String:
	for issue in issues:
		var single: Array[CatalogIssue] = [issue]
		if DifficultyProfile.faulty_indices(single, level).has(index):
			return issue.message
	return ""


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
