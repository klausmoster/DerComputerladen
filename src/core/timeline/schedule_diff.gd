class_name ScheduleDiff
extends RefCounted

## Vergleicht zwei Läufe mit demselben Seed (FR-043; research.md, R24): einen ohne Eingriffe, die
## baseline, und einen mit, with_changes. Das Ergebnis sagt zu jedem Termin des Laufs mit
## Eingriffen, ob er gleich, neu, verschoben oder in einem anderen Zustand ist, und listet die
## Termine, die ohne Eingriffe da wären und mit Eingriffen fehlen.
##
## Laufende Nummern taugen dafür nicht: Kommt ein Termin dazu, verschieben sich alle späteren.
## Verglichen wird deshalb je Ereignis, in drei Schritten:
## 1. Termine am selben Tag bilden ein Paar; bei anderem Zustand STATE_CHANGED, sonst NONE.
## 2. Ein übriger Termin mit moved_from_day ≥ 0 paart sich mit dem übrigen Termin desselben
##    Ereignisses an diesem Tag in der baseline und bekommt MOVED.
## 3. Was dann mit Eingriffen übrig ist, ist ADDED; was ohne übrig ist, kommt nach removed.
##
## Dank der unabhängigen Würfel (R5) unterscheiden sich beide Läufe nur dort, wo Eingriffe wirken.
## „Verschoben“ heißt dabei nur, was ein Eingriff wirklich verschoben hat. Ein Modifikator bringt
## Termine dazu oder nimmt welche weg; paarte der Vergleich die übrigen einfach der Reihe nach,
## hieße ein weggefallener Termin 1995 zusammen mit einem neuen 1992 „verschoben“.

## REMOVED steht nie in marks, denn ein weggefallener Termin hat im Lauf mit Eingriffen keine
## Nummer; die Werkstatt zeigt damit die Termine aus removed.
enum Mark { NONE, ADDED, REMOVED, MOVED, STATE_CHANGED }

## Laufende Nummer eines Termins in with_changes → Mark, für jeden Termin dieses Laufs.
var marks: Dictionary = {}
## Die Termine aus der baseline ohne Gegenstück, in der Reihenfolge ihres Fahrplans.
var removed: Array[ScheduleEntry] = []


## Vergleicht denselben Seed ohne (baseline) und mit Eingriffen (with_changes), beide bis zum
## selben Tag abgespielt (FR-043).
static func compare(baseline: TimelineRun, with_changes: TimelineRun) -> ScheduleDiff:
	var diff := ScheduleDiff.new()
	# Je Ereignis die Termine der baseline, die noch keinen Partner haben. _take() nimmt einen
	# Partner aus dieser Liste heraus; am Ende steht darin, was weggefallen ist.
	var unpaired := _by_event(baseline)
	var changed := _by_event(with_changes)
	for event_id: String in changed:
		var candidates: Array = unpaired.get(event_id, [])
		var entries: Array = changed[event_id]
		# Schritt 1, gleicher Tag. Liegen an einem Tag mehr Termine als in der baseline, bekommen
		# die unverschobenen ihren Partner zuerst; ein verschobener sucht ihn sonst in Schritt 2.
		var unmoved := entries.filter(func(e: ScheduleEntry) -> bool: return e.moved_from_day < 0)
		var moved := entries.filter(func(e: ScheduleEntry) -> bool: return e.moved_from_day >= 0)
		var rest: Array[ScheduleEntry] = []
		for entry: ScheduleEntry in unmoved + moved:
			var partner := _take(candidates, entry.day)
			if partner == null:
				rest.append(entry)
			elif partner.state != entry.state:
				diff.marks[entry.serial] = Mark.STATE_CHANGED
			else:
				diff.marks[entry.serial] = Mark.NONE
		# Schritt 2, verschoben, und Schritt 3, neu. Nur ein verschobener Termin sucht seinen
		# Partner am ursprünglichen Tag; alle anderen übrigen sind neu.
		for entry in rest:
			if entry.moved_from_day >= 0 and _take(candidates, entry.moved_from_day) != null:
				diff.marks[entry.serial] = Mark.MOVED
			else:
				diff.marks[entry.serial] = Mark.ADDED
	# Schritt 3, weggefallen: was in der baseline ohne Partner blieb, in ihrer Reihenfolge.
	var left := {}
	for event_id: String in unpaired:
		for entry: ScheduleEntry in unpaired[event_id]:
			left[entry] = true
	for entry in baseline.entries:
		if left.has(entry):
			diff.removed.append(entry)
	return diff


## Die Termine eines Laufs je Ereignis, Kennung → Liste in der Reihenfolge des Fahrplans.
static func _by_event(run: TimelineRun) -> Dictionary:
	var by_event := {}
	for entry in run.entries:
		if not by_event.has(entry.event.id):
			by_event[entry.event.id] = []
		by_event[entry.event.id].append(entry)
	return by_event


## Nimmt den ersten Termin am Tag [param day] aus [param candidates] heraus und gibt ihn zurück;
## null, wenn dort keiner liegt. Die Liste ist dieselbe wie im Dictionary des Aufrufers, das
## Herausnehmen wirkt also auch dort.
static func _take(candidates: Array, day: int) -> ScheduleEntry:
	for i in candidates.size():
		var entry: ScheduleEntry = candidates[i]
		if entry.day == day:
			candidates.remove_at(i)
			return entry
	return null
