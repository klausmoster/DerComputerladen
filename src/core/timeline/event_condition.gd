class_name EventCondition
extends RefCounted

## Eine Bedingung (FR-006, data-model.md, „EventCondition“): Das Ereignis [member event] ist
## schon eingetreten oder, mit [member occurred] = false, noch nicht. „Eingetreten“ heißt, ein
## Termin davon hat bis zum Vortag begonnen. Bedingungen gibt es nur bei Ereignissen, die nicht
## fix oder jährlich sind (V17).

## Schlüssel einer Bedingung in der Datei (contracts/ereigniskatalog.md, „Felder“).
const KEYS := ["event", "occurred"]

## Kennung des Ereignisses, auf das sich die Bedingung bezieht.
var event: String = ""
## true: schon eingetreten; false: noch nicht eingetreten. Vorgabe true.
var occurred: bool = true


## Liest eine Bedingung aus ihrem Dictionary in der Datei. Strukturfehler hängt es als V22 an
## [param issues] an; zu welchem Ereignis sie gehören, setzt `TimelineEvent.from_dict()`.
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> EventCondition:
	var condition := EventCondition.new()
	CatalogIssue.check_keys(data, KEYS, issues)
	condition.event = CatalogIssue.read_string(data, "event", issues, condition.event)
	condition.occurred = CatalogIssue.read_bool(data, "occurred", issues, condition.occurred)
	return condition


func to_dict() -> Dictionary:
	return {
		"event": event,
		"occurred": occurred,
	}
