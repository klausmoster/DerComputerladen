class_name ScheduleEntry
extends RefCounted

## Ein Termin im Fahrplan eines Laufs (data-model.md, „ScheduleEntry“): an welchem Tag welches
## Ereignis beginnt, woher der Termin kommt, in welchem Zustand er ist und warum er dort steht.
##
## Termine werden nie gelöscht. Was entfällt oder abgesagt wird, bleibt mit seinem Zustand und
## Grund stehen; so ist der Fahrplan zugleich die Geschichte des Spiels. Angelegt werden Termine
## vom Lauf (TimelineRun, Phase 3); die Zeitleiste meldet sie, etwa über entry_skipped.

enum Origin { FIXED, YEARLY, PRESET, ROLLED, FOLLOW_UP, INTERVENTION }
enum State { PLANNED, RUNNING, OCCURRED, ENDED, SKIPPED, CANCELLED }

## Laufende Nummer im Fahrplan; Eingriffe nennen den Termin darüber.
var serial: int = 0
var event: TimelineEvent
## Tag des Beginns als Tagesindex.
var day: int = 0
## Tag, an dem das Ende gemeldet wird; ohne Dauer gleich day. Über 5477 heißt: nach Spielende.
var end_day: int = 0
var origin: Origin = Origin.FIXED
## Bei FOLLOW_UP die Kennung des auslösenden Ereignisses.
var source_event_id: String = ""
## Bei FOLLOW_UP der Titel des auslösenden Ereignisses, für Herkunft und Begründung; den setzt
## der Lauf. Ist er leer, nennen sie die Kennung.
var source_title: String = ""
## Bei YEARLY: lief schon vor dem 01.01.1985 (R9).
var started_before_game: bool = false
var state: State = State.PLANNED
## Bei ROLLED und FOLLOW_UP der Würfelwert und die Schwelle, die er unterschreiten musste;
## sonst −1.
var roll: float = -1.0
var threshold: float = -1.0
## Bei ROLLED die Grundchance aus dem Katalog, bei FOLLOW_UP die Wahrscheinlichkeit des
## Folgeereignisses; sonst −1.
var base_chance: float = -1.0
## Bei ROLLED die Modifikatoren, wie sie beim Wurf galten, je „<grund> <wert in
## Prozentpunkten>“, etwa „Ware vom windigen Händler +5“. So bleibt die Begründung lesbar,
## auch wenn ein Modifikator später entfernt wird.
var modifier_notes: PackedStringArray = PackedStringArray()
## Der ursprüngliche Tag, wenn ein Eingriff den Termin verschoben hat; sonst −1.
var moved_from_day: int = -1
## Grund bei Entfall, Absage, Verschiebung oder Einplanung; der letzte gilt.
var note: String = ""


## „fix“, „jährlich“, „gesetzt“, „gewürfelt“, „Folge von …“ oder „Eingriff“.
func origin_label() -> String:
	match origin:
		Origin.FIXED:
			return "fix"
		Origin.YEARLY:
			return "jährlich"
		Origin.PRESET:
			return "gesetzt"
		Origin.ROLLED:
			return "gewürfelt"
		Origin.FOLLOW_UP:
			return "Folge von %s" % _source_name()
		Origin.INTERVENTION:
			return "Eingriff"
	return ""


## „geplant“, „läuft“, „eingetreten“, „beendet“, „entfallen“ oder „abgesagt“.
func state_label() -> String:
	match state:
		State.PLANNED:
			return "geplant"
		State.RUNNING:
			return "läuft"
		State.OCCURRED:
			return "eingetreten"
		State.ENDED:
			return "beendet"
		State.SKIPPED:
			return "entfallen"
		State.CANCELLED:
			return "abgesagt"
	return ""


## Die Begründung in einem Satz, nur aus den Feldern des Termins, etwa
## „Würfel 0,0213 < Schwelle 0,0800 (3 % + Ware vom windigen Händler +5)“ oder
## „Würfel 0,4120 < 50 %, Folge von Reklamationswelle“. Dahinter stehen, falls es sie gibt, die
## Verschiebung und der Grund aus [member note].
##
## Würfel und Schwelle stehen mit vier Nachkommastellen. Der Würfel wird dabei abgerundet, damit
## er nie gleich der Schwelle aussieht: 0,02997 unter 3 % heißt „Würfel 0,0299 < Schwelle
## 0,0300“. Nur eine Chance von 100 % trifft auch mit dem Wurf 1,0; dann steht dort „≤“.
func explain() -> String:
	var text := _origin_reason()
	if moved_from_day >= 0:
		text += ", verschoben vom %s" % GameDate.from_day_index(moved_from_day)
	if not note.is_empty():
		match state:
			State.SKIPPED:
				text += "; entfallen: %s" % note
			State.CANCELLED:
				text += "; abgesagt: %s" % note
			_:
				text += "; Grund: %s" % note
	return text


## Die verzögerten Wirkungen mit ihrem Fälligkeitstag, [{ "effect": EventEffect, "day": int }],
## in der Reihenfolge der Wirkungen (FR-013). Wirkungen ohne Verzögerung gehören zum Beginn.
func due_effects() -> Array[Dictionary]:
	var due: Array[Dictionary] = []
	if event == null:
		return due
	for effect in event.effects:
		if effect.delay_days > 0:
			due.append({"effect": effect, "day": day + effect.delay_days})
	return due


## Woher der Termin kommt, bei Zufall mit Würfelwert und Schwelle.
func _origin_reason() -> String:
	match origin:
		Origin.FIXED:
			return "Fixes Datum aus dem Katalog"
		Origin.YEARLY:
			if started_before_game:
				return "Jedes Jahr laut Katalog, lief schon vor Spielbeginn"
			return "Jedes Jahr laut Katalog"
		Origin.PRESET:
			return "Beim Spielstart gesetzt"
		Origin.ROLLED:
			var parts := PackedStringArray([_percent(base_chance)])
			parts.append_array(modifier_notes)
			return "Würfel %s %s Schwelle %s (%s)" % [_four_places_down(roll), _relation(),
				_four_places(threshold), " + ".join(parts)]
		Origin.FOLLOW_UP:
			return "Würfel %s %s %s, Folge von %s" % [_four_places_down(roll), _relation(),
				_percent(threshold), _source_name()]
		Origin.INTERVENTION:
			return "Per Eingriff eingeplant"
	return ""


## Das auslösende Ereignis: sein Titel, ohne Titel seine Kennung.
func _source_name() -> String:
	return source_title if not source_title.is_empty() else source_event_id


## „<“ zwischen Würfel und Schwelle; „≤“ nur, wenn eine Chance von 100 % mit dem Wurf 1,0 traf.
func _relation() -> String:
	return "<" if roll < threshold else "≤"


## Zahl mit vier Nachkommastellen und deutschem Komma, etwa „0,0800“.
static func _four_places(value: float) -> String:
	return ("%.4f" % value).replace(".", ",")


## Zahl auf vier Nachkommastellen abgerundet, mit deutschem Komma: 0,02997 wird „0,0299“.
##
## Der winzige Zuschlag vor floorf() gleicht aus, dass eine Dezimalzahl wie 0,412 als float knapp
## darunter liegt; ohne ihn stünde dort „0,4119“. Würfe aus randf() liegen nie so dicht unter
## einer vierten Stelle, für sie ändert er nichts.
static func _four_places_down(value: float) -> String:
	return _four_places(floorf(value * 10000.0 + 1e-11) / 10000.0)


## Anteil als Prozent mit höchstens zwei Nachkommastellen, etwa 0.03 als „3 %“ und 0.025 als
## „2,5 %“.
static func _percent(share: float) -> String:
	var text := ("%.2f" % (share * 100.0)).rstrip("0").rstrip(".")
	return "%s %%" % text.replace(".", ",")
