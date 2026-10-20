class_name EventCategory
extends RefCounted

## Eine Kategorie des Ereigniskatalogs, etwa „Hardware“ oder „Kalender“ (data-model.md,
## „EventCategory“). Im Zeitstrahl der Werkstatt ist jede Kategorie eine Zeile in ihrer Farbe.
##
## Die Farbe steht als Token-Name aus `UiPalette` im Katalog, nicht als Farbwert. Ob das Token
## zu den Kategorienfarben aus `UiPalette.CATEGORY_TOKENS` gehört, prüft erst der
## `CatalogValidator` (V21); beim Lesen zählt nur, dass ein Text dasteht.

## Schlüssel einer Kategorie in der Datei (contracts/ereigniskatalog.md, „Felder“).
const KEYS := ["color", "id", "name"]

## Kennung aus a–z, 0–9 und _, eindeutig; entsteht beim Anlegen aus dem Namen und bleibt fest.
var id: String = ""
## Anzeigename, deutsch; Umbenennen ändert nur ihn.
var name: String = ""
## Token aus UiPalette, etwa &"petrol".
var color: StringName = &""


## Liest eine Kategorie aus ihrem Dictionary in der Datei. Strukturfehler hängt es als V22 an
## [param issues] an; was fehlt oder falsch ist, bekommt die Vorgabe.
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> EventCategory:
	var category := EventCategory.new()
	var first := issues.size()
	CatalogIssue.check_keys(data, KEYS, issues)
	var token := CatalogIssue.read_string(data, "color", issues, String(category.color))
	category.color = StringName(token)
	category.id = CatalogIssue.read_string(data, "id", issues, category.id)
	category.name = CatalogIssue.read_string(data, "name", issues, category.name)
	CatalogIssue.locate(issues, first, category._place())
	return category


func to_dict() -> Dictionary:
	return {
		"color": String(color),
		"id": id,
		"name": name,
	}


## Die Kategorie in Meldungen: über ihre Kennung, ohne Kennung über ihren Namen.
func _place() -> String:
	if not id.is_empty():
		return "Kategorie „%s“" % id
	if not name.is_empty():
		return "Kategorie „%s“ ohne Kennung" % name
	return "Kategorie ohne Kennung"
