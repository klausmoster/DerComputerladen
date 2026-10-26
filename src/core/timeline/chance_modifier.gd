class_name ChanceModifier
extends RefCounted

## Ein Modifikator (FR-025, data-model.md, „ChanceModifier“): Er verschiebt für eine Zeit die
## Chance eines Ereignisses über Wahrscheinlichkeit um einige Prozentpunkte, etwa „Ware vom
## windigen Händler: +5 Prozentpunkte vom 01.01.1990 bis 31.12.1993“ auf die Reklamationswelle.
##
## Ein Modifikator ändert nur die Schwelle, nie den Wurf (R5), und die Grundchance im Katalog
## bleibt unberührt. Gleichzeitig gültige Modifikatoren addieren sich; das rechnet
## TimelineRun.chance_info(). Abgelaufene werden nicht entfernt, sie gelten nur nicht mehr.
##
## Seit Feature 003 steht ein Modifikator auch im Katalog: als Start-Modifikator im Profil eines
## Schwierigkeitsgrads (DifficultyProfile). Dafür liest from_dict() ihn aus der Katalogdatei, und
## to_dict() schreibt ihn in derselben Form wie ein Modifikator in einer Was-wäre-wenn-Probe
## (contracts/ereigniskatalog.md, „Felder“).

## Die Schlüssel in Katalog und Probe, alphabetisch.
const KEYS := ["event_id", "from_day", "id", "reason", "to_day", "value"]

## Kennung, eindeutig im Lauf.
var id: String = ""
## Kennung eines Ereignisses über Wahrscheinlichkeit.
var event_id: String = ""
## Prozentpunkte als Anteil: +0.05 heißt +5 Prozentpunkte. Negativ senkt die Chance; 0 ist
## erlaubt.
var value: float = 0.0
## Lesbarer Grund, nicht leer, etwa „Ware vom windigen Händler“.
var reason: String = ""
## Erster Tag, an dem er gilt. Beim Eingreifen ist die Vorgabe der aktuelle Spieltag, vor
## Spielbeginn 0; dessen Würfelrunde ist dann schon vorbei, er wirkt also ab der nächsten.
var from_day: int = 0
## Letzter Tag, an dem er gilt, eingeschlossen. Das Ende ist Pflicht, „unbegrenzt“ heißt 5477,
## der 31.12.1999. Die Vorgabe −1 heißt „noch nicht gesetzt“; dann gilt er an keinem Tag.
var to_day: int = -1


## Liest einen Start-Modifikator in der Form der Katalogdatei: Tage als „JJJJ-MM-TT“, der Wert als
## Anteil. Ein fehlender Schlüssel, ein falscher Typ, ein unbekannter Schlüssel und ein Datum, das
## kein Kalendertag ist, ergeben je eine Meldung V22 in [param issues] und die Vorgabe aus
## data-model.md, „Vorgaben“: das ganze Spiel vom 01.01.1985 bis 31.12.1999, also to_day 5477 und
## nicht −1, der Wert 0, Grund, Ereignis und Kennung leer. Der Modifikator kommt trotzdem zurück,
## damit die Werkstatt ihn zeigen und reparieren kann.
##
## Das Feld einer Meldung ist hier nur der Schlüssel, etwa „value“, und der Text nur der Grund. Wo
## der Start-Modifikator steht, weiß erst DifficultyProfile.from_list(); es setzt Stelle und Ort.
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> ChanceModifier:
	var modifier := ChanceModifier.new()
	# Die Vorgabe der Klasse, −1 für „noch kein Ende“, gilt beim Eingreifen. Im Katalog heißt ein
	# fehlendes Ende dagegen „bis Spielende“, wie bei einem neuen Start-Modifikator der Werkstatt.
	modifier.to_day = TimelineRun.LAST_DAY
	CatalogIssue.check_keys(data, KEYS, issues)
	modifier.event_id = CatalogIssue.read_string(data, "event_id", issues, modifier.event_id)
	modifier.from_day = _read_day(data, "from_day", issues, modifier.from_day)
	modifier.id = CatalogIssue.read_string(data, "id", issues, modifier.id)
	modifier.reason = CatalogIssue.read_string(data, "reason", issues, modifier.reason)
	modifier.to_day = _read_day(data, "to_day", issues, modifier.to_day)
	modifier.value = CatalogIssue.read_float(data, "value", issues, modifier.value)
	return modifier


## Die Form der Katalogdatei: Tage als „JJJJ-MM-TT“, der Wert auf vier Nachkommastellen gerundet
## (Schreibregel 3). JSON.stringify() sortiert die Schlüssel beim Schreiben ohnehin.
func to_dict() -> Dictionary:
	return {
		"event_id": event_id,
		"from_day": GameDate.from_day_index(from_day).to_iso(),
		"id": id,
		"reason": reason,
		"to_day": GameDate.from_day_index(to_day).to_iso(),
		"value": roundf(value * 10000.0) / 10000.0,
	}


## Ob er am Tag [param day] gilt: from_day ≤ day ≤ to_day.
func is_active(day: int) -> bool:
	return from_day <= day and day <= to_day


## data[key] als Tagesindex aus „JJJJ-MM-TT“, sonst V22 und [param fallback]. Auch ein Text, der
## kein Kalendertag ist, etwa „1990-02-30“, ist V22. Dieselbe Regel und derselbe Text wie bei den
## Tagen eines Ereignisses (TimelineEvent).
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
