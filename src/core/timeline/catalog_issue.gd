class_name CatalogIssue
extends RefCounted

## Eine Prüfmeldung zum Ereigniskatalog: ein Fehler oder eine Warnung zu einer der Regeln
## V01 bis V24 (data-model.md, „CatalogIssue“ und „Prüfregeln“).
##
## Meldungen entstehen an zwei Stellen. V22, die Strukturfehler, entstehen schon beim Lesen der
## Datei: in den `from_dict()` der Datenklassen und in `EventCatalog`. Dafür hat diese Klasse
## unten Hilfen zum Lesen, die jedes Mal V22 melden, wenn ein Schlüssel fehlt, unbekannt ist
## oder den falschen Typ hat. Alle übrigen Regeln prüft später der `CatalogValidator`.
##
## Eine Meldung nennt in [member event_id] das Ereignis und in [member field] die Stelle darin,
## etwa `date` oder `effects[1].delay_days`. Bei V22 ist das die Stelle in der Datei, also
## `window.from`. Meldungen ohne Ereignis haben ein leeres [member event_id]: Bei Kategorien
## steht im Feld etwa `categories[2].color`, bei einem Parse-Fehler die Zeile.

enum Severity { ERROR, WARNING }

## Regel für Strukturfehler beim Lesen.
const STRUCTURE_RULE := "V22"

var severity: Severity = Severity.ERROR
## Kennung der Regel, "V01" bis "V24".
var rule: String = ""
## Betroffenes Ereignis oder leer.
var event_id: String = ""
## Betroffenes Feld, etwa "date" oder "effects[1].delay_days".
var field: String = ""
## Deutscher Satz, der Ereignis und Feld nennt.
var message: String = ""


func _init(p_severity: Severity = Severity.ERROR, p_rule: String = "", p_event_id: String = "",
		p_field: String = "", p_message: String = "") -> void:
	severity = p_severity
	rule = p_rule
	event_id = p_event_id
	field = p_field
	message = p_message


## Für Logs und Testmeldungen, etwa „V22 ERROR intel_pentium date: …“.
func _to_string() -> String:
	var parts := PackedStringArray([rule, Severity.keys()[severity]])
	for part: String in [event_id, field]:
		if not part.is_empty():
			parts.append(part)
	return "%s: %s" % [" ".join(parts), message]


# --- Hilfen zum Lesen (V22) -------------------------------------------------
#
# Sie bekommen ein Dictionary aus der Datei und einen Schlüssel darin. Geht etwas schief, hängen
# sie eine Meldung an [param issues] an, deren Feld nur der Schlüssel ist und deren Text nur der
# Grund. Wo der Schlüssel im Ereignis steht, setzt danach [method prefix_fields], und zu welchem
# Ereignis die Meldung gehört, [method locate].


## Neue Meldung V22 an der Stelle [param p_field] mit dem Grund [param reason].
static func structure_error(p_field: String, reason: String) -> CatalogIssue:
	return CatalogIssue.new(Severity.ERROR, STRUCTURE_RULE, "", p_field, reason)


## Meldung V22, weil an der Stelle [param p_field] statt [param expected] der Wert
## [param value] steht.
static func wrong_type(p_field: String, expected: String, value: Variant) -> CatalogIssue:
	return structure_error(p_field,
		"Erwartet wird %s, in der Datei steht %s." % [expected, _describe(value)])


## Der Wert von data[key], wenn sein Typ in [param types] steht. Fehlt der Schlüssel oder hat
## der Wert einen anderen Typ, meldet es V22 und gibt null zurück. [param expected] beschreibt
## für die Meldung, was dort stehen muss, etwa „ein Text“.
static func fetch(data: Dictionary, key: String, types: Array[int], expected: String,
		issues: Array[CatalogIssue]) -> Variant:
	if not data.has(key):
		issues.append(structure_error(key, "Der Schlüssel fehlt."))
		return null
	var value: Variant = data[key]
	if not types.has(typeof(value)):
		issues.append(wrong_type(key, expected, value))
		return null
	return value


## data[key] als Text, sonst V22 und [param fallback].
static func read_string(data: Dictionary, key: String, issues: Array[CatalogIssue],
		fallback: String) -> String:
	var value: Variant = fetch(data, key, [TYPE_STRING, TYPE_STRING_NAME], "ein Text", issues)
	if typeof(value) == TYPE_NIL:
		return fallback
	return String(value)


## data[key] als ganze Zahl, sonst V22 und [param fallback].
##
## JSON kennt nur „Zahl“, und `JSON.parse()` liefert jede Zahl als float: Aus 14 in der Datei
## wird 14.0. Deshalb gilt ein float ohne Nachkommastellen als ganze Zahl und wird mit int()
## zurückgewandelt; 14.5 ist ein Fehler.
static func read_int(data: Dictionary, key: String, issues: Array[CatalogIssue],
		fallback: int) -> int:
	var value: Variant = fetch(data, key, [TYPE_INT, TYPE_FLOAT], "eine ganze Zahl", issues)
	if typeof(value) == TYPE_NIL:
		return fallback
	if typeof(value) == TYPE_FLOAT:
		var number: float = value
		# Über 10^15 hat ein float keine verlässlichen Nachkommastellen mehr.
		if number != floorf(number) or absf(number) > 1e15:
			issues.append(wrong_type(key, "eine ganze Zahl", value))
			return fallback
	return int(value)


## data[key] als Zahl, ganz oder mit Nachkommastellen, sonst V22 und [param fallback].
static func read_float(data: Dictionary, key: String, issues: Array[CatalogIssue],
		fallback: float) -> float:
	var value: Variant = fetch(data, key, [TYPE_INT, TYPE_FLOAT], "eine Zahl", issues)
	if typeof(value) == TYPE_NIL:
		return fallback
	return float(value)


## data[key] als true oder false, sonst V22 und [param fallback].
static func read_bool(data: Dictionary, key: String, issues: Array[CatalogIssue],
		fallback: bool) -> bool:
	var value: Variant = fetch(data, key, [TYPE_BOOL], "true oder false", issues)
	if typeof(value) == TYPE_NIL:
		return fallback
	return bool(value)


## Liest einen der Namen aus [param names], etwa "fixed" für die Art eines Ereignisses, und
## gibt seine Stelle in der Liste zurück; die Listen stehen in der Reihenfolge ihres Enums.
## Ein anderer Text meldet V22 und ergibt [param fallback].
static func read_choice(data: Dictionary, key: String, names: Array, issues: Array[CatalogIssue],
		fallback: int) -> int:
	var value: Variant = fetch(data, key, [TYPE_STRING], "ein Text", issues)
	if typeof(value) == TYPE_NIL:
		return fallback
	var index := names.find(value)
	if index < 0:
		issues.append(structure_error(key, "Unbekannter Wert „%s“, erlaubt sind: %s."
			% [value, ", ".join(PackedStringArray(names))]))
		return fallback
	return index


## Die Einträge der Liste data[key], die Objekte sind, nach ihrer Stelle in der Liste, etwa
## { 0: {…}, 2: {…} }. Fehlt die Liste oder ist ein Eintrag kein Objekt, meldet es V22; so
## ein Eintrag fehlt dann im Ergebnis.
static func read_entries(data: Dictionary, key: String, issues: Array[CatalogIssue]) -> Dictionary:
	var entries := {}
	var list: Variant = fetch(data, key, [TYPE_ARRAY], "eine Liste", issues)
	if typeof(list) == TYPE_NIL:
		return entries
	var items: Array = list
	for i in items.size():
		if typeof(items[i]) == TYPE_DICTIONARY:
			entries[i] = items[i]
		else:
			issues.append(wrong_type("%s[%d]" % [key, i], "ein Objekt", items[i]))
	return entries


## Meldet V22 für jeden Schlüssel in [param data], der nicht in [param allowed] steht. Der
## Katalog behält solche Schlüssel nicht (Schreibregel 5); die Meldung sorgt dafür, dass das
## nicht still geschieht.
static func check_keys(data: Dictionary, allowed: Array, issues: Array[CatalogIssue]) -> void:
	for key: Variant in data:
		if not allowed.has(key):
			issues.append(structure_error(str(key), "Diesen Schlüssel kennt der Katalog nicht."))


## Stellt bei allen Meldungen ab der Stelle [param first] [param prefix] vor das Feld, etwa
## „effects[1].“ oder „window.“, damit das Feld die ganze Stelle nennt.
static func prefix_fields(issues: Array[CatalogIssue], first: int, prefix: String) -> void:
	for i in range(first, issues.size()):
		issues[i].field = prefix + issues[i].field


## Ordnet alle Meldungen ab der Stelle [param first] ihrem Ort zu: Sie bekommen
## [param p_event_id], und aus dem Grund wird ein ganzer Satz mit Ort und Feld, etwa
## „Ereignis „intel_pentium“, Feld „date“: Der Schlüssel fehlt.“
static func locate(issues: Array[CatalogIssue], first: int, place: String,
		p_event_id: String = "") -> void:
	for i in range(first, issues.size()):
		var issue := issues[i]
		issue.event_id = p_event_id
		if issue.field.is_empty():
			issue.message = "%s: %s" % [place, issue.message]
		else:
			issue.message = "%s, Feld „%s“: %s" % [place, issue.field, issue.message]


## Ein Wert aus der Datei in Worten, für Meldungen.
static func _describe(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "true" if value else "false"
		TYPE_INT, TYPE_FLOAT:
			return "die Zahl %s" % value
		TYPE_STRING, TYPE_STRING_NAME:
			return "der Text „%s“" % value
		TYPE_ARRAY:
			return "eine Liste"
		TYPE_DICTIONARY:
			return "ein Objekt"
	return type_string(typeof(value))
