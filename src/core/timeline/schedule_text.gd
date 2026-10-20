class_name ScheduleText
extends RefCounted

## Der Fahrplan eines Laufs als Text (FR-046; contracts/zeitleiste.md, „Textausgabe“). Die
## Textausgabe fahrplan_ausgabe.gd schreibt ihn auf die Konsole, die Tests vergleichen ihn
## Zeichen für Zeichen (SC-002).
##
## Eine Fahrplanzeile hat feste Spalten, getrennt durch zwei Leerzeichen:
## [codeblock]
## TT.MM.JJJJ  <bis, 14>  <kennung, 28>  <herkunft, 12>  <zustand, 12>  <titel>
## [/codeblock]
## Jede Spalte außer der letzten wird mit Leerzeichen auf ihre Breite aufgefüllt. So stehen die
## Spalten untereinander, und diff zeigt eine Änderung genau in ihrer Zeile.

const UNTIL_WIDTH := 14
const ID_WIDTH := 28
const ORIGIN_WIDTH := 12
const STATE_WIDTH := 12
const SEPARATOR := "  "
## Die Herkunft kurz, in der Reihenfolge von ScheduleEntry.Origin.
const ORIGIN_SHORT: Array[String] = ["fix", "jährlich", "gesetzt", "gewürfelt", "Folge", "Eingriff"]


## Kopfzeile „# Seed 4711, bis 31.12.1999“, dann je Termin bis [param until_day] eine Zeile:
## „TT.MM.JJJJ  <bis, 14>  <kennung, 28>  <herkunft, 12>  <zustand, 12>  <titel>“
## und je verzögerter Wirkung darunter „TT.MM.JJJJ    └ <describe()>“.
static func plan_lines(run: TimelineRun,
		until_day: int = TimelineRun.LAST_DAY) -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("# Seed %d, bis %s" % [run.seed, GameDate.from_day_index(until_day)])
	for entry in run.entries:
		# Der Fahrplan ist nach Tag sortiert; ab dem ersten Termin danach kommt keiner mehr.
		if entry.day > until_day:
			break
		lines.append(_entry_line(entry))
		for due in entry.due_effects():
			var effect: EventEffect = due["effect"]
			lines.append("%s    └ %s" % [GameDate.from_day_index(due["day"]), effect.describe()])
	return lines


## Je Meldung des Protokolls TimelineMessage.to_line().
static func protocol_lines(run: TimelineRun) -> PackedStringArray:
	var lines := PackedStringArray()
	for message in run.protocol:
		lines.append(message.to_line())
	return lines


## Die Fahrplanzeile eines Termins. Hinter dem Titel stehen, in dieser Reihenfolge, die Zusätze
## für Folgetermine, für jährliche Vorkommen, die schon vor dem 01.01.1985 liefen, wie der Winter
## 1984/85, und für Termine, deren Ende erst nach dem 31.12.1999 gemeldet würde, wie das
## Weihnachtsgeschäft 1999.
static func _entry_line(entry: ScheduleEntry) -> String:
	var has_duration := entry.end_day > entry.day
	# Die Spalte „bis“ nennt den letzten Tag; das Ende wird erst am Tag danach gemeldet.
	var until := "bis %s" % GameDate.from_day_index(entry.end_day - 1) if has_duration else ""
	var title := entry.event.title
	if entry.origin == ScheduleEntry.Origin.FOLLOW_UP:
		title += " (Folge von %s)" % entry.source_event_id
	if entry.origin == ScheduleEntry.Origin.YEARLY and entry.started_before_game:
		title += " (lief schon vor Spielbeginn)"
	var will_end := entry.state != ScheduleEntry.State.SKIPPED \
		and entry.state != ScheduleEntry.State.CANCELLED
	if has_duration and will_end and entry.end_day > TimelineRun.LAST_DAY:
		title += " (Ende nach Spielende)"
	return SEPARATOR.join(PackedStringArray([
		str(GameDate.from_day_index(entry.day)),
		until.rpad(UNTIL_WIDTH),
		entry.event.id.rpad(ID_WIDTH),
		ORIGIN_SHORT[entry.origin].rpad(ORIGIN_WIDTH),
		entry.state_label().rpad(STATE_WIDTH),
		title,
	]))
