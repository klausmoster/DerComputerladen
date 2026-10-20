class_name FollowUp
extends RefCounted

## Ein Folgeereignis (FR-008, data-model.md, „FollowUp“): Beginnt das Ereignis, zu dem es
## gehört, kommt mit der Wahrscheinlichkeit [member chance] das Ereignis [member target] dazu,
## [member delay_min] bis [member delay_max] Tage später. Ob und wann, würfelt der Lauf beim
## Beginn des auslösenden Ereignisses.

## Schlüssel eines Folgeereignisses in der Datei (contracts/ereigniskatalog.md, „Felder“).
const KEYS := ["chance", "delay_max", "delay_min", "target"]

## Kennung des Folgeereignisses; es darf nicht fix oder jährlich sein (V16).
var target: String = ""
## Wahrscheinlichkeit als Anteil von 0 bis 1, Vorgabe 1.0.
var chance: float = 1.0
## Verzögerung in Tagen, int ≥ 0; sind beide gleich, ist sie fest.
var delay_min: int = 0
var delay_max: int = 0


## Liest ein Folgeereignis aus seinem Dictionary in der Datei. Strukturfehler hängt es als V22
## an [param issues] an; zu welchem Ereignis sie gehören, setzt `TimelineEvent.from_dict()`.
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> FollowUp:
	var follow_up := FollowUp.new()
	CatalogIssue.check_keys(data, KEYS, issues)
	follow_up.chance = CatalogIssue.read_float(data, "chance", issues, follow_up.chance)
	follow_up.delay_max = CatalogIssue.read_int(data, "delay_max", issues, follow_up.delay_max)
	follow_up.delay_min = CatalogIssue.read_int(data, "delay_min", issues, follow_up.delay_min)
	follow_up.target = CatalogIssue.read_string(data, "target", issues, follow_up.target)
	return follow_up


func to_dict() -> Dictionary:
	return {
		# Anteile stehen auf vier Nachkommastellen in der Datei (Schreibregel 3).
		"chance": roundf(chance * 10000.0) / 10000.0,
		"delay_max": delay_max,
		"delay_min": delay_min,
		"target": target,
	}
