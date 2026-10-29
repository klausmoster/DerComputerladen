class_name TimelineRun
extends RefCounted

## Ein Spiel der Zeitleiste (research.md, R1 und R6). Aus Katalog und Seed legt der Lauf den
## Fahrplan für 1985 bis 1999 an und spielt ihn auf Aufruf ab. Jeder Aufruf gibt die Meldungen
## der Tage zurück, die er abgespielt hat, und hängt sie an das Protokoll.
##
## Der Lauf ist kein Node. Er braucht weder Szenenbaum noch Spieluhr und läuft deshalb gleich im
## Spiel, in der Werkstatt, in der Textausgabe, in der Statistik und in den Tests. Das Autoload
## Timeline hängt ihn an die Spieluhr und macht aus den Meldungen Signale. Er wendet keine Wirkung
## an, er meldet nur.
##
## Der Lauf kennt fixe, jährliche und beim Start gesetzte Termine, die Würfelrunde für Ereignisse
## über Wahrscheinlichkeit, Bedingungen, Folgeereignisse mit Kettenbremse, verzögerte Wirkungen
## und Ereignisse mit Dauer (R9). Ein Termin mit Dauer „läuft“ nach seinem Beginn und ist nach
## seinem Ende „beendet“; einer ohne Dauer ist ein Augenblick und nach dem Beginn „eingetreten“.
##
## Dazu kommen die Eingriffe (FR-025 bis FR-027, R11): Modifikatoren setzen und entfernen, Termine
## absagen, verschieben und einplanen. Sie wirken erst nach today, denn today ist schon
## abgespielt. Jeder angenommene Eingriff steht mit seinem Tag im Eingriffsprotokoll
## [member interventions] und als Meldung INTERVENTION im Protokoll; ein abgelehnter hinterlässt
## nichts außer seinem Grund in [member last_refusal]. Würfe kosten Eingriffe nie: Ein
## Modifikator verschiebt nur die Schwelle, und Würfel und Würfelzwecke bleiben, wie sie sind.
##
## Seit Feature 003 hat ein Spiel einen Schwierigkeitsgrad (research.md von Feature 003, R5 bis
## R7). Die Start-Modifikatoren aus dem Profil des Grads setzt _init(), bevor begin() zum ersten Mal
## würfelt. Sie stehen in einer eigenen Liste, [member start_modifiers], nie in
## [member modifiers] und nie im Eingriffsprotokoll, und lassen sich nicht entfernen. Sie
## verschieben wie Eingriffe nur Schwellen; der Seed und die Würfel hängen nicht am Grad. Mit
## Mittel oder einem leeren Profil läuft alles wie in Feature 002, Zeichen für Zeichen.

const FIRST_DAY := 0          # 01.01.1985
const LAST_DAY := 5477        # 31.12.1999
const MONTHS := 180
const MAX_CHAIN := 16         # Glieder einer Folgekette am selben Tag, gezählt je Kette (R10)

## Die Arten im Eingriffsprotokoll (data-model.md, „Eingriffsprotokoll“), Wert des Schlüssels
## "kind".
const INTERVENTION_ADD_MODIFIER := "add_modifier"
const INTERVENTION_REMOVE_MODIFIER := "remove_modifier"
const INTERVENTION_CANCEL := "cancel"
const INTERVENTION_MOVE := "move"
const INTERVENTION_SCHEDULE := "schedule"

## Eigene Kopie des Katalogs; der Lauf verändert sie nie.
var catalog: EventCatalog
# Der Name kommt aus dem Vertrag und ist zugleich der einer globalen Funktion, seed(); die
# Warnung darüber ist abgeschaltet, sonst wäre der Start mit -d nicht still.
## Der Seed des Spiels; aus ihm folgen alle Zufallsentscheidungen (R5).
@warning_ignore("shadowed_global_identifier")
var seed: int
## Der Grad des Spiels, fest ab _init() (Feature 003, FR-006).
var difficulty: Difficulty.Level = Difficulty.DEFAULT
## Die Start-Modifikatoren des Grads, als Kopien in der Reihenfolge des Profils. _init() setzt
## sie, bevor begin() zum ersten Mal würfelt (FR-007); danach ändern sie sich nie.
var start_modifiers: Array[ChanceModifier] = []
## Je Start-Modifikator, den der Lauf nicht setzen konnte, ein Satz mit dem Ort aus
## DifficultyProfile.place() und dem Grund, etwa „Profil „Schwer“, Start-Modifikator
## „reklamationswelle“: Das Ereignis „reklamationswelle“ gibt es im Katalog nicht.“ Dazu ein Satz,
## wenn der Grad unbekannt war. Meist leer, denn die Aufrufer rechnen mit without_faulty() und
## lehnen unbekannte Grade vorher ab.
var start_refusals: PackedStringArray = PackedStringArray()
## Zuletzt abgespielter Tag; −1 vor begin().
var today: int = -1
## Der Fahrplan: nach Tag sortiert, an einem Tag in der Reihenfolge, in der die Termine beginnen.
var entries: Array[ScheduleEntry] = []
## Die Modifikatoren der Chancen aus Eingriffen, in der Reihenfolge, in der sie gesetzt wurden.
## Gesetzt und entfernt werden sie über add_modifier() und remove_modifier(); chance_info() und die
## Würfelrunden rechnen ein, was hier und in start_modifiers steht. Abgelaufene bleiben stehen und
## gelten nur nicht mehr.
var modifiers: Array[ChanceModifier] = []
## Alle Meldungen und Eingriffe des Laufs in der Reihenfolge, in der sie entstanden sind.
var protocol: Array[TimelineMessage] = []
## Das Eingriffsprotokoll (data-model.md): jeder angenommene Eingriff als Dictionary, in der
## Reihenfolge, in der er geschah. Jeder hat "kind" (siehe INTERVENTION_*) und "at_day", den Wert
## von today beim Eingriff, also −1 vor Spielbeginn; dazu je nach Art "event_id", "day",
## "new_day", "reason" und bei Modifikatoren "modifier" mit den Feldern von ChanceModifier.
## Absagen und Verschiebungen nennen Ereignis und Tag des Termins statt seiner laufenden Nummer,
## denn die Nummer ändert sich, wenn sich der Katalog ändert. Ein frischer Lauf, der jeden Eintrag
## an seinem at_day mit apply_intervention() anwendet, ergibt denselben Fahrplan.
var interventions: Array[Dictionary] = []
## Deutscher Grund des zuletzt abgelehnten Eingriffs, etwa „Windows 95 ist fix und lässt sich
## weder absagen noch verschieben.“ Er bleibt stehen, bis ein anderer Eingriff abgelehnt wird; ob
## ein Aufruf geklappt hat, sagt sein Rückgabewert.
var last_refusal: String = ""

## Kennung → Ereignis, zum schnellen Nachschlagen.
var _events_by_id: Dictionary = {}
## Die Ereignisse über Wahrscheinlichkeit nach Kennung und daneben, an derselben Stelle, ihr
## Würfel für alle Würfelrunden (R5).
var _chance_events: Array[TimelineEvent] = []
var _chance_dice: Array[RandomNumberGenerator] = []
## Der Tag des Ersten jedes Monats 0 bis 179, dazu der 01.01.2000 als Ende.
var _month_starts: PackedInt32Array = PackedInt32Array()
## Nummer des Monats, dessen Würfelrunde als nächste ansteht.
var _next_month: int = 0
## Die Termine nach laufender Nummer; Nummer n steht an der Stelle n − 1.
var _by_serial: Array[ScheduleEntry] = []
## Kennung → die Tage der Termine des Ereignisses, die weder entfallen noch abgesagt sind,
## aufsteigend (PackedInt32Array). Ihre Zahl ist das, was für die Höchstzahl zählt, und für den
## Mindestabstand genügen die Nachbarn eines Tags (FR-005, _may_start_again()). Nachgeführt bei
## jedem Wechsel, der das ändert: neuer Termin, Entfall, Absage, Verschieben.
var _counted_days: Dictionary = {}
## Kennung → der Termin des Ereignisses, der gerade läuft (FR-022). Es läuft höchstens einer:
## Ein Termin beginnt nur, wenn hier keiner steht. Gesetzt beim Beginn mit Dauer, entfernt beim
## Ende.
var _running: Dictionary = {}
## Tag → die dann fälligen verzögerten Wirkungen, je [laufende Nummer, Stelle der Wirkung,
## Termin, Wirkung].
var _due_effects: Dictionary = {}
## Tag → die laufenden Termine, deren Ende an diesem Tag gemeldet wird. Ein Ende nach dem
## 31.12.1999 steht nicht darin, denn es wird nie gemeldet (FR-019).
var _ends: Dictionary = {}
## Die Stichtage (R6): aufsteigend die Tage nach today, an denen ein Termin beginnt oder endet oder
## eine Wirkung fällig wird. Der nächste Monatserste kommt in _next_stop() dazu.
var _stop_days: PackedInt32Array = PackedInt32Array()
## Kennung → Tag, an dem zuerst ein Termin des Ereignisses begann; für Bedingungen (FR-006).
var _first_start: Dictionary = {}
## Laufende Nummer → Glied in der Kette, nur für Folgetermine ohne Verzögerung. Jeder andere
## Termin ist das erste Glied seiner Kette (R10).
var _chain_links: Dictionary = {}


## Kopiert den Katalog und legt den Fahrplan an: fixe, jährliche und beim Start gesetzte Termine
## (FR-010). Danach setzt es die Start-Modifikatoren des Grads [param p_difficulty] (Feature 003,
## data-model.md, „Anlegen“). TimelineRun.new(catalog, seed) heißt Mittel, wie bisher.
##
## Ein unbekannter Grad, etwa 7, gilt als Mittel und steht in start_refusals. Ablehnen müssen ihn
## die Aufrufer vorher (FR-011): Ein Parameter vom Typ Difficulty.Level nimmt auch eine 7 an.
func _init(p_catalog: EventCatalog, p_seed: int,
		p_difficulty: Difficulty.Level = Difficulty.DEFAULT) -> void:
	catalog = p_catalog.duplicate_catalog() if p_catalog != null else EventCatalog.new()
	seed = p_seed
	if Difficulty.is_valid(p_difficulty):
		difficulty = p_difficulty
	else:
		start_refusals.append("Den Schwierigkeitsgrad %d gibt es nicht; das Spiel läuft mit %s."
			% [p_difficulty, Difficulty.label(Difficulty.DEFAULT)])
	_month_starts = _first_days_of_months()
	# In Kennungsreihenfolge, egal wie der Katalog gerade sortiert ist: Dann vergibt der Lauf
	# die laufenden Nummern immer gleich, und die Würfelrunde geht nach Kennung (R8).
	var by_id: Array[TimelineEvent] = catalog.events.duplicate()
	by_id.sort_custom(func(a: TimelineEvent, b: TimelineEvent) -> bool: return a.id < b.id)
	for event in by_id:
		if not _events_by_id.has(event.id):
			_events_by_id[event.id] = event
		match event.kind:
			TimelineEvent.Kind.FIXED:
				_add_entry(event, event.date, ScheduleEntry.Origin.FIXED)
			TimelineEvent.Kind.YEARLY:
				_plan_yearly(event)
			TimelineEvent.Kind.PRESET:
				_plan_preset(event)
			TimelineEvent.Kind.CHANCE:
				_chance_events.append(event)
				_chance_dice.append(EventDice.make(seed, EventDice.PURPOSE_CHANCE, event.id))
			TimelineEvent.Kind.FOLLOW_ONLY:
				pass  # kommt nur als Folge eines anderen Ereignisses
	# Erst jetzt, mit Fahrplan und Würfeln, aber vor der ersten Würfelrunde in begin() (FR-007). Die
	# Würfel hängen nur an Seed, Zweck und Kennung; der Grad ändert an ihnen nichts (FR-008).
	_set_start_modifiers()


## Spielt den 01.01.1985 ab, mit der Würfelrunde für Januar 1985 und den jährlichen Ereignissen,
## die schon vor Spielbeginn liefen, wie dem Winter 1984/85 (R9). Nur einmal aufrufbar: Danach
## gibt es eine leere Liste zurück und spielt nichts mehr ab.
func begin() -> Array[TimelineMessage]:
	var messages: Array[TimelineMessage] = []
	if today < FIRST_DAY:
		_play_day(FIRST_DAY, messages)
	return messages


## Spielt alle Tage nach today bis einschließlich [param day] ab, höchstens bis LAST_DAY. Ruft
## begin() selbst auf, falls noch nicht geschehen.
##
## Der Lauf geht dabei nicht jeden Tag einzeln durch, sondern springt von Stichtag zu Stichtag
## (R6): zum nächsten Tag, an dem ein Termin beginnt oder endet, eine Wirkung fällig wird oder ein
## Monat anfängt. An allen anderen Tagen geschieht nichts. Ob man ihn Tag für Tag aufruft oder in
## Sprüngen, ergibt deshalb dieselben Meldungen.
func advance_to(day: int) -> Array[TimelineMessage]:
	var messages: Array[TimelineMessage] = []
	if day < FIRST_DAY:
		return messages
	if today < FIRST_DAY:
		messages.append_array(begin())
	var target := mini(day, LAST_DAY)
	while today < target:
		var next := _next_stop()
		if next > target:
			today = target
		else:
			_play_day(next, messages)
	return messages


## Ob der 31.12.1999 abgespielt ist. Danach meldet der Lauf nichts mehr (FR-019).
func is_finished() -> bool:
	return today == LAST_DAY


## Der Termin mit dieser laufenden Nummer; null, wenn es ihn nicht gibt. Die Nummern beginnen
## bei 1.
func get_entry(serial: int) -> ScheduleEntry:
	if serial < 1 or serial > _by_serial.size():
		return null
	return _by_serial[serial - 1]


## Die Termine, die gerade laufen, in der Reihenfolge des Fahrplans: begonnen, mit Dauer und noch
## nicht beendet. Ein Termin, dessen Ende erst nach dem 31.12.1999 käme, läuft bis zum Schluss.
func running_entries() -> Array[ScheduleEntry]:
	var running: Array[ScheduleEntry] = []
	for entry in entries:
		if entry.state == ScheduleEntry.State.RUNNING:
			running.append(entry)
	return running


## Die Chance eines Ereignisses über Wahrscheinlichkeit am Tag [param day] (FR-025) als
## Dictionary mit fünf Schlüsseln:
## - "base" (float): die Grundchance aus dem Katalog; 0 bei einem unbekannten Ereignis oder
##   einem Ereignis anderer Art;
## - "sum" (float): die Grundchance plus alle Start-Modifikatoren und Modifikatoren, die an diesem
##   Tag gelten, noch nicht begrenzt;
## - "effective" (float): sum, begrenzt auf 0 bis 1; damit wird gewürfelt;
## - "start_modifiers" (Array[ChanceModifier]): die Start-Modifikatoren des Grads, die an diesem
##   Tag gelten, in der Reihenfolge des Profils (Feature 003);
## - "modifiers" (Array[ChanceModifier]): die Modifikatoren aus Eingriffen, die an diesem Tag
##   gelten, in ihrer Reihenfolge; wie bisher.
##
## Beispiel aus US6, Szenario 3: 3 % mit −6 Prozentpunkten ergibt sum −0,03 und effective 0. Mit
## „Schwer +5“ dazu (US1, Szenario 7 von Feature 003) ergibt es 2 %.
func chance_info(event_id: String, day: int) -> Dictionary:
	var event: TimelineEvent = _events_by_id.get(event_id)
	var base := 0.0
	if event != null and event.kind == TimelineEvent.Kind.CHANCE:
		base = event.monthly_chance
	var total := base
	# Erst die Start-Modifikatoren, dann die Eingriffe. Ohne Start-Modifikatoren addiert die Schleife
	# also in derselben Reihenfolge wie in Feature 002, und jede Schwelle bleibt bis aufs Bit gleich.
	var from_profile: Array[ChanceModifier] = []
	for modifier in start_modifiers:
		if modifier.event_id == event_id and modifier.is_active(day):
			from_profile.append(modifier)
			total += modifier.value
	var active: Array[ChanceModifier] = []
	for modifier in modifiers:
		if modifier.event_id == event_id and modifier.is_active(day):
			active.append(modifier)
			total += modifier.value
	return {"base": base, "sum": total, "effective": clampf(total, 0.0, 1.0),
		"start_modifiers": from_profile, "modifiers": active}


## Der geplante Termin des Ereignisses [param event_id] am Tag [param day]; null, wenn es dort
## keinen gibt. Gibt es mehrere, kommt der erste in der Reihenfolge des Fahrplans. Absagen und
## Verschiebungen aus dem Eingriffsprotokoll finden ihren Termin hierüber, wenn eine Probe neu
## abgespielt wird (data-model.md, „Neu abspielen“).
func find_planned(event_id: String, day: int) -> ScheduleEntry:
	var index := _first_index_from(day)
	while index < entries.size() and entries[index].day == day:
		var entry := entries[index]
		if entry.event.id == event_id and entry.state == ScheduleEntry.State.PLANNED:
			return entry
		index += 1
	return null


# --- Eingriffe (FR-025 bis FR-027, R11) ----------------------------------------------
#
# Jede Methode gibt OK zurück oder einen Error mit dem Grund in last_refusal:
# - ERR_DOES_NOT_EXIST: Ereignis, Modifikator oder Termin gibt es nicht.
# - ERR_ALREADY_EXISTS: Die Kennung des Modifikators ist schon vergeben.
# - ERR_UNAVAILABLE: Der Termin ist fix oder jährlich oder nicht mehr geplant, oder der Tag liegt
#   nicht nach today oder nach dem 31.12.1999.
# - ERR_INVALID_PARAMETER: Grund oder Kennung fehlen, das Ende liegt vor dem Beginn, das Ereignis
#   hat die falsche Art, oder ein Termin soll auf den Tag verschoben werden, an dem er schon liegt.
#
# Vor begin() ist today −1; Eingriffe gehen dann ab dem 01.01.1985 (FR-027).


## Setzt einen Modifikator (FR-025): Er verschiebt die Chance eines Ereignisses über
## Wahrscheinlichkeit vom from_day bis zum to_day um value. Der Lauf merkt sich eine Kopie, damit
## eine spätere Änderung an [param modifier] weder den Fahrplan noch das Eingriffsprotokoll
## heimlich ändert. Ein Beginn in der Vergangenheit und der Wert 0 sind erlaubt; die Würfelrunden
## bis today sind schon gelaufen, er wirkt also ab der nächsten.
func add_modifier(modifier: ChanceModifier) -> Error:
	if modifier == null:
		return _refuse(ERR_INVALID_PARAMETER, "Es fehlt der Modifikator.")
	var event: TimelineEvent = _events_by_id.get(modifier.event_id)
	if event == null:
		return _refuse(ERR_DOES_NOT_EXIST, _unknown_event(modifier.event_id))
	if event.kind != TimelineEvent.Kind.CHANCE:
		return _refuse(ERR_INVALID_PARAMETER, ("%s ist kein Ereignis über Wahrscheinlichkeit; nur "
			+ "dort gibt es Modifikatoren.") % event.title)
	if modifier.id.is_empty():
		return _refuse(ERR_INVALID_PARAMETER, "Der Modifikator hat keine Kennung.")
	if _modifier_index(modifier.id) >= 0:
		return _refuse(ERR_ALREADY_EXISTS,
			"Einen Modifikator mit der Kennung „%s“ gibt es schon." % modifier.id)
	if modifier.reason.strip_edges().is_empty():
		return _refuse(ERR_INVALID_PARAMETER, "Der Modifikator braucht einen Grund.")
	# −1 ist die Vorgabe von ChanceModifier und heißt „kein Ende gesetzt“ (FR-025: Pflicht).
	if modifier.to_day == -1:
		return _refuse(ERR_INVALID_PARAMETER,
			"Dem Modifikator fehlt das Ende; „unbegrenzt“ heißt bis 31.12.1999.")
	if modifier.to_day < modifier.from_day:
		return _refuse(ERR_INVALID_PARAMETER,
			"Der Modifikator endet am %s, vor seinem Beginn am %s." % [_date(modifier.to_day),
			_date(modifier.from_day)])
	var copy := _modifier_from_record(_modifier_record(modifier))
	modifiers.append(copy)
	var record := _record(INTERVENTION_ADD_MODIFIER)
	record["modifier"] = _modifier_record(copy)
	_accept(record, event, null, "Modifikator „%s“ %s vom %s bis %s" % [copy.reason,
		_points_text(copy.value), _date(copy.from_day), _date(copy.to_day)])
	return OK


## Entfernt den Modifikator mit der Kennung [param id] (FR-025). Ab der nächsten Würfelrunde gilt
## er nicht mehr. Was er vorher bewirkt hat, bleibt: Gewürfelte Termine behalten ihre Schwelle und
## in modifier_notes seinen Grund.
##
## Gesucht wird nur unter den Eingriffen (R5 von Feature 003). Hat nur ein Start-Modifikator diese
## Kennung, gibt es ERR_UNAVAILABLE: Start-Modifikatoren lassen sich im Spiel nicht entfernen
## (FR-010). Haben beide sie, wird der Eingriff entfernt.
func remove_modifier(id: String) -> Error:
	var index := _modifier_index(id)
	if index < 0:
		if _start_modifier_index(id) >= 0:
			return _refuse(ERR_UNAVAILABLE, ("„%s“ ist ein Start-Modifikator von %s und lässt sich "
				+ "im laufenden Spiel nicht entfernen.") % [id, Difficulty.label(difficulty)])
		return _refuse(ERR_DOES_NOT_EXIST,
			"Einen Modifikator mit der Kennung „%s“ gibt es nicht." % id)
	var removed := modifiers[index]
	modifiers.remove_at(index)
	var record := _record(INTERVENTION_REMOVE_MODIFIER)
	record["modifier"] = _modifier_record(removed)
	_accept(record, _events_by_id.get(removed.event_id), null,
		"Modifikator „%s“ %s entfernt" % [removed.reason, _points_text(removed.value)])
	return OK


## Sagt den geplanten Termin mit der laufenden Nummer [param serial] ab (FR-026). Er bleibt mit dem
## Zustand „abgesagt“ und dem Grund im Fahrplan stehen und beginnt nie; seine Folgeereignisse
## kommen deshalb auch nicht. Fixe und jährliche Termine lassen sich nicht absagen.
func cancel_entry(serial: int, reason: String) -> Error:
	var entry := get_entry(serial)
	var error := _check_changeable(entry, serial)
	if error != OK:
		return error
	if reason.strip_edges().is_empty():
		return _refuse(ERR_INVALID_PARAMETER, "Die Absage braucht einen Grund.")
	_uncount_day(entry)
	entry.state = ScheduleEntry.State.CANCELLED
	entry.note = reason
	var record := _record(INTERVENTION_CANCEL)
	record["event_id"] = entry.event.id
	record["day"] = entry.day
	record["reason"] = reason
	_accept(record, entry.event, entry,
		"Termin am %s abgesagt, Grund: %s" % [_date(entry.day), reason])
	return OK


## Verschiebt den geplanten Termin mit der laufenden Nummer [param serial] auf [param new_day],
## einen Tag nach today bis zum 31.12.1999 (FR-026). Die Dauer bleibt. Das erste Verschieben merkt
## sich den ursprünglichen Tag in moved_from_day; daran erkennt ScheduleDiff den Termin als
## verschoben. Fixe und jährliche Termine lassen sich nicht verschieben.
func move_entry(serial: int, new_day: int, reason: String) -> Error:
	var entry := get_entry(serial)
	var error := _check_changeable(entry, serial)
	if error != OK:
		return error
	var problem := _day_problem(new_day)
	if not problem.is_empty():
		return _refuse(ERR_UNAVAILABLE, problem)
	if new_day == entry.day:
		return _refuse(ERR_INVALID_PARAMETER,
			"%s liegt schon am %s." % [entry.event.title, _date(new_day)])
	if reason.strip_edges().is_empty():
		return _refuse(ERR_INVALID_PARAMETER, "Die Verschiebung braucht einen Grund.")
	var old_day := entry.day
	# Der Termin wandert an seine neue Stelle im Fahrplan: herausnehmen, ändern, neu einsortieren.
	# Für den Mindestabstand wandert sein Tag mit.
	entries.remove_at(entries.find(entry))
	_uncount_day(entry)
	if entry.moved_from_day < 0:
		entry.moved_from_day = old_day
	entry.end_day = new_day + (entry.end_day - entry.day)
	entry.day = new_day
	entry.note = reason
	entries.insert(entries.bsearch_custom(entry, _comes_before), entry)
	_count_day(entry)
	# Der alte Tag bleibt als Stichtag stehen; an ihm geschieht dann eben nichts.
	_add_stop(new_day)
	var record := _record(INTERVENTION_MOVE)
	record["event_id"] = entry.event.id
	record["day"] = old_day
	record["new_day"] = new_day
	record["reason"] = reason
	_accept(record, entry.event, entry, "Termin vom %s auf den %s verschoben, Grund: %s"
		% [_date(old_day), _date(new_day), reason])
	return OK


## Plant das Ereignis [param event_id] als neuen Termin am Tag [param day] ein, einen Tag nach
## today bis zum 31.12.1999 (FR-026). Der Termin hat die Herkunft „Eingriff“ und den Grund als
## note. An seinem Tag gilt er wie jeder geplante Termin: Bedingungen werden geprüft, und ein
## Ereignis, das noch läuft, beginnt nicht noch einmal. Fixe und jährliche Ereignisse lassen sich
## nicht einplanen; sie haben ihre Tage schon.
func schedule_event(event_id: String, day: int, reason: String) -> Error:
	var event: TimelineEvent = _events_by_id.get(event_id)
	if event == null:
		return _refuse(ERR_DOES_NOT_EXIST, _unknown_event(event_id))
	if event.kind == TimelineEvent.Kind.FIXED or event.kind == TimelineEvent.Kind.YEARLY:
		return _refuse(ERR_UNAVAILABLE, ("%s ist %s; einplanen lassen sich nur Ereignisse, die "
			+ "weder fix noch jährlich sind.") % [event.title, _fixed_label(event.kind)])
	var problem := _day_problem(day)
	if not problem.is_empty():
		return _refuse(ERR_UNAVAILABLE, problem)
	if reason.strip_edges().is_empty():
		return _refuse(ERR_INVALID_PARAMETER, "Die Einplanung braucht einen Grund.")
	var entry := _add_entry(event, day, ScheduleEntry.Origin.INTERVENTION)
	entry.note = reason
	var record := _record(INTERVENTION_SCHEDULE)
	record["event_id"] = event_id
	record["day"] = day
	record["reason"] = reason
	_accept(record, event, entry, "Termin am %s eingeplant, Grund: %s" % [_date(day), reason])
	return OK


## Wendet einen Eintrag des Eingriffsprotokolls an, mit denselben Prüfungen wie die Methoden oben,
## an denen er auch landet. Absagen und Verschiebungen finden ihren Termin über find_planned();
## fehlt er, gibt es ERR_DOES_NOT_EXIST. Der Eintrag darf aus einer Datei stammen: Zahlen dürfen
## float sein, und ein fehlender oder falscher Wert führt zu einer Ablehnung, nie zum Absturz.
func apply_intervention(record: Dictionary) -> Error:
	var kind := _text_of(record, "kind")
	match kind:
		INTERVENTION_ADD_MODIFIER, INTERVENTION_REMOVE_MODIFIER:
			var data: Variant = record.get("modifier")
			if typeof(data) != TYPE_DICTIONARY:
				return _refuse(ERR_INVALID_PARAMETER, "Dem Eingriff fehlt der Modifikator.")
			if kind == INTERVENTION_ADD_MODIFIER:
				var unreadable := _unreadable_modifier(data)
				if not unreadable.is_empty():
					return _refuse(ERR_INVALID_PARAMETER, unreadable)
				return add_modifier(_modifier_from_record(data))
			return remove_modifier(_text_of(data, "id"))
		INTERVENTION_CANCEL, INTERVENTION_MOVE:
			var event_id := _text_of(record, "event_id")
			var day := _int_of(record, "day", FIRST_DAY - 1)
			if not _events_by_id.has(event_id):
				return _refuse(ERR_DOES_NOT_EXIST, _unknown_event(event_id))
			var entry := find_planned(event_id, day)
			if entry == null:
				return _refuse(ERR_DOES_NOT_EXIST,
					"%s hat am %s keinen geplanten Termin im Fahrplan." % [_title_of(event_id),
					_date(day)])
			if kind == INTERVENTION_CANCEL:
				return cancel_entry(entry.serial, _text_of(record, "reason"))
			return move_entry(entry.serial, _int_of(record, "new_day", FIRST_DAY - 1),
				_text_of(record, "reason"))
		INTERVENTION_SCHEDULE:
			return schedule_event(_text_of(record, "event_id"),
				_int_of(record, "day", FIRST_DAY - 1), _text_of(record, "reason"))
	return _refuse(ERR_INVALID_PARAMETER, "Einen Eingriff der Art „%s“ gibt es nicht." % kind)


## Der Tag, an dem ein Eintrag des Eingriffsprotokolls geschah, at_day, als ganze Zahl. Aus einer
## Datei kommt jede Zahl als float, 2556 also als 2556.0; das zählt als ganze Zahl. Fehlt der Tag
## oder ist er keine ganze Zahl, gibt es [param fallback], als Vorgabe −1. Ein Lauf, der bis −1
## abspielen soll, spielt nichts ab; so gilt ein Eingriff ohne lesbaren Tag dort, wo der Lauf
## gerade steht.
static func intervention_day(record: Dictionary, fallback: int = FIRST_DAY - 1) -> int:
	return _int_of(record, "at_day", fallback)


## Das Eingriffsprotokoll [param records] in der Reihenfolge, in der ein Lauf es nachspielt: nach
## at_day, bei gleichem Tag in der Reihenfolge des Protokolls. Ein Eintrag ohne lesbaren Tag bleibt
## hinter seinem Vorgänger und gilt dort, wo der Lauf nach ihm steht; steht er ganz vorn, gilt er
## vor Spielbeginn. Gibt eine neue Liste mit denselben Einträgen zurück; [param records] bleibt,
## wie es ist.
##
## Nötig ist das, weil der Simulator Eingriffe in der Reihenfolge der Aktionen sammelt. Nach
## „Fahrplan erzeugen“ steht der Lauf wieder vor dem 01.01.1985, und ein neuer Eingriff mit at_day
## −1 kommt hinter einen vom 01.01.1992. Der Reihe nach gespielt, gälte er erst 1992, denn
## advance_to() läuft nur vorwärts. WhatIfProbe.build_run() und TimelineStatistics spielen beide
## in dieser Reihenfolge; so steht die Regel an einer Stelle (FR-043, FR-045, R11, R22).
static func in_replay_order(records: Array[Dictionary]) -> Array[Dictionary]:
	# Der Tag, nach dem jeder Eintrag einsortiert wird: sein at_day, ohne lesbaren Tag der seines
	# Vorgängers, ganz vorn −1. So wandert ein Eintrag ohne Tag mit seinem Vorgänger.
	var keys: Array[int] = []
	var key := FIRST_DAY - 1
	for record in records:
		key = intervention_day(record, key)
		keys.append(key)
	# sort_custom() ist nicht stabil: Einträge vom selben Tag könnten ihre Reihenfolge tauschen,
	# etwa Setzen und Entfernen desselben Modifikators. Sortiert werden deshalb die Stellen im
	# Protokoll, und bei gleichem Tag entscheidet die Stelle.
	var order: Array[int] = []
	for index in records.size():
		order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool:
		if keys[a] != keys[b]:
			return keys[a] < keys[b]
		return a < b)
	var sorted: Array[Dictionary] = []
	for index in order:
		sorted.append(records[index])
	return sorted


## Spielt [param records] wie ein Eingriffsprotokoll nach: in der Reihenfolge von
## in_replay_order(), je Eintrag bis zu seinem at_day vor und dort apply_intervention(); danach bis
## [param until_day]. Gibt je abgelehntem Eintrag { "record": Dictionary, "reason": String } zurück,
## reason aus last_refusal, in der Reihenfolge des Nachspielens. Die Meldungen des Abspielens
## landen wie immer im Protokoll; zurückgegeben werden sie nicht.
##
## Ein Eintrag ohne lesbaren Tag spielt bis −1, also gar nicht ab, und gilt dort, wo der Lauf
## gerade steht (intervention_day()). Ein abgelehnter Eintrag hält nichts auf; die übrigen gelten.
## "record" ist der Eintrag aus [param records] selbst, keine Kopie. Die Proben der Werkstatt
## (WhatIfProbe.build_run()) und das Fortsetzen eines Spielstands spielen beide hierüber nach,
## mit derselben Regel (Feature 004, R5).
func replay(records: Array[Dictionary], until_day: int) -> Array[Dictionary]:
	var refused: Array[Dictionary] = []
	for record in in_replay_order(records):
		advance_to(intervention_day(record))
		if apply_intervention(record) != OK:
			refused.append({"record": record, "reason": last_refusal})
	advance_to(until_day)
	return refused


## Die Vorkommen eines jährlichen Ereignisses, die in den Fahrplan kommen (R9), aufsteigend, je als
## Vector2i(Beginn, letzter Tag) in Tagesindizes; ohne Dauer ist der letzte Tag der Beginn. Ein
## Vorkommen, das vor dem 01.01.1985 beginnt, behält hier seinen echten Beginn, beim Winter ab dem
## 01.12.1984 also −31; erst der Fahrplan setzt es auf Tag 0. Die Regel:
## - Kandidaten sind die Vorkommen, die in den Jahren yearly_from − 1 bis yearly_to beginnen.
## - Es zählt nur, was sich mit dem 01.01. von yearly_from bis 31.12. von yearly_to und mit dem
##   Spielzeitraum überschneidet. So hat der Winter ab 1985 ein Vorkommen ab dem 01.12.1984, die
##   CeBIT ab 1986 aber keins im März 1985.
##
## Der Fahrplan und der Zeitstrahl der Werkstatt fragen beide hier; so kann die Regel an keiner der
## beiden Stellen anders ausfallen.
static func yearly_occurrences(event: TimelineEvent) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	# Ein Vorkommen reicht höchstens ins Folgejahr. Was vor 1984 oder nach 1999 beginnt, berührt den
	# Spielzeitraum deshalb nie. Die Grenzen ändern am Ergebnis nichts; sie halten nur unsinnige
	# Jahre schnell, wie sie die Werkstatt bis zur Korrektur zeigt (V08), etwa 999999999.
	var first_year := maxi(event.yearly_from - 1, CatalogValidator.FIRST_YEAR - 1)
	var last_year := mini(event.yearly_to, CatalogValidator.LAST_YEAR)
	var from_day := maxi(_new_year(event.yearly_from), FIRST_DAY)
	var to_day := mini(_new_year(event.yearly_to + 1) - 1, LAST_DAY)
	for year in range(first_year, last_year + 1):
		var occurrence := _occurrence(event, year)
		if occurrence.is_empty() or occurrence[1] < from_day or occurrence[0] > to_day:
			continue
		result.append(Vector2i(occurrence[0], occurrence[1]))
	return result


# --- Start-Modifikatoren (Feature 003, R6) ------------------------------------------

## Setzt die Start-Modifikatoren aus dem Profil des Grads, in der Reihenfolge des Profils. Jeder
## wird geprüft wie in add_modifier(): Das Ereignis gibt es, und es kommt über Wahrscheinlichkeit;
## Kennung und Grund sind nicht leer; die Kennung kommt im Profil nur einmal vor; das Ende ist
## gesetzt und liegt nicht vor dem Beginn. Wer besteht, kommt als Kopie nach start_modifiers und
## mit einer Meldung START_MODIFIER am Tag −1 ins Protokoll; wer durchfällt, mit einem Satz nach
## start_refusals. Mittel hat kein Profil, dann geschieht nichts.
func _set_start_modifiers() -> void:
	var profile := catalog.get_profile(difficulty)
	if profile == null:
		return
	# Kennung → wie oft sie im Profil vorkommt. Kommt sie mehrfach vor, fällt jeder mit ihr durch,
	# wie V30 jeden meldet; sonst hinge es an der Reihenfolge, welcher gilt.
	var count := {}
	for modifier in profile.modifiers:
		count[modifier.id] = int(count.get(modifier.id, 0)) + 1
	for index in profile.modifiers.size():
		var modifier := profile.modifiers[index]
		var problem := _start_modifier_problem(modifier, count)
		if not problem.is_empty():
			start_refusals.append("%s: %s" % [DifficultyProfile.place(difficulty, index, modifier),
				problem])
			continue
		var copy := _modifier_from_record(_modifier_record(modifier))
		start_modifiers.append(copy)
		var event: TimelineEvent = _events_by_id[copy.event_id]
		var message := TimelineMessage.new()
		# −1 ist der 31.12.1984, wie bei Eingriffen vor Spielbeginn: Er gilt, bevor der erste Tag
		# abgespielt ist. Die Meldung geht nur ins Protokoll, in keine Rückgabe; so wird sie kein
		# Signal.
		message.day = FIRST_DAY - 1
		message.kind = TimelineMessage.Kind.START_MODIFIER
		message.event = event
		message.text = "%s: Start-Modifikator „%s“ (%s) %s vom %s bis %s" % [event.title,
			copy.reason, Difficulty.label(difficulty), _points_text(copy.value),
			_date(copy.from_day), _date(copy.to_day)]
		protocol.append(message)


## Warum sich ein Start-Modifikator nicht setzen lässt; leer, wenn er geht. Dieselben Prüfungen in
## derselben Reihenfolge wie add_modifier(), nur die doppelte Kennung zählt im Profil statt unter
## den Eingriffen. [param count] ist Kennung → wie oft sie im Profil vorkommt.
func _start_modifier_problem(modifier: ChanceModifier, count: Dictionary) -> String:
	var event: TimelineEvent = _events_by_id.get(modifier.event_id)
	if event == null:
		return _unknown_event(modifier.event_id)
	if event.kind != TimelineEvent.Kind.CHANCE:
		return ("%s ist kein Ereignis über Wahrscheinlichkeit; nur dort gibt es "
			+ "Start-Modifikatoren.") % event.title
	if modifier.id.is_empty():
		return "Der Start-Modifikator hat keine Kennung."
	if int(count.get(modifier.id, 0)) > 1:
		return "Die Kennung „%s“ gibt es in diesem Profil mehrfach." % modifier.id
	if modifier.reason.strip_edges().is_empty():
		return "Der Start-Modifikator braucht einen Grund."
	if modifier.to_day == -1:
		return "Dem Start-Modifikator fehlt das Ende; „unbegrenzt“ heißt bis 31.12.1999."
	if modifier.to_day < modifier.from_day:
		return "Der Start-Modifikator endet am %s, vor seinem Beginn am %s." % [
			_date(modifier.to_day), _date(modifier.from_day)]
	return ""


## Stelle des Start-Modifikators mit der Kennung [param id] in start_modifiers; −1, wenn es ihn
## nicht gibt.
func _start_modifier_index(id: String) -> int:
	for i in start_modifiers.size():
		if start_modifiers[i].id == id:
			return i
	return -1


# --- Fahrplan anlegen ----------------------------------------------------------

## Würfelt die Termine eines Ereignisses „beim Start gesetzt“ (R7):
## - Erst zieht rand_weighted() über die Gewichte einen Index j; die Anzahl ist k = count_min + j.
## - Dann kommen k Zahlen z aus randi_range(0, L − (k − 1) · g), aufsteigend sortiert; L ist die
##   Länge des Zeitfensters in Tagen, g der Mindestabstand.
## - Der i-te Termin liegt auf window_from + zᵢ + i · g.
##
## So hält jeder Termin den Mindestabstand ein, ohne dass neu gewürfelt wird, und die Zahl der
## Würfe hängt nur von k ab. Dass auch die höchste Anzahl ins Fenster passt, prüft V10.
func _plan_preset(event: TimelineEvent) -> void:
	var dice := EventDice.make(seed, EventDice.PURPOSE_PRESET, event.id)
	var count := event.count_min
	# Bei einer leeren Liste meldete rand_weighted() einen Fehler; die Prüfung kennt sie als V11.
	if not event.count_weights.is_empty():
		# Sind alle Gewichte 0, liefert rand_weighted() −1; dann bleibt es bei count_min.
		count += maxi(dice.rand_weighted(PackedFloat32Array(event.count_weights)), 0)
	var gap := event.min_gap_days
	var spread := maxi(event.window_to - event.window_from - (count - 1) * gap, 0)
	var offsets: Array[int] = []
	for i in count:
		offsets.append(dice.randi_range(0, spread))
	offsets.sort()
	for i in count:
		_add_entry(event, event.window_from + offsets[i] + i * gap, ScheduleEntry.Origin.PRESET)


## Legt die Termine eines jährlichen Ereignisses an, einen je Vorkommen aus yearly_occurrences()
## (R9). Ein Vorkommen, das vor dem 01.01.1985 begann, beginnt im Fahrplan am 01.01.1985 und trägt
## started_before_game. Seine Tage vor 1985 rechnet GameDate mit negativen Indizes.
func _plan_yearly(event: TimelineEvent) -> void:
	for occurrence in yearly_occurrences(event):
		var entry := _add_entry(event, maxi(occurrence.x, FIRST_DAY), ScheduleEntry.Origin.YEARLY)
		entry.started_before_game = occurrence.x < FIRST_DAY
		# Das Ende wird am Tag nach dem letzten gemeldet. Ohne Dauer bleibt end_day = day.
		if event.has_duration():
			entry.end_day = occurrence.y + 1


## Neuer, geplanter Termin. Er bekommt die nächste laufende Nummer und seine Stelle im Fahrplan:
## nach Tag, Herkunft, Kennung und laufender Nummer. Mit [param at_day_end] kommt er stattdessen
## hinter alle Termine seines Tags; so reihen sich Folgetermine ein, die noch heute beginnen.
func _add_entry(event: TimelineEvent, day: int, origin: ScheduleEntry.Origin,
		at_day_end: bool = false) -> ScheduleEntry:
	var entry := ScheduleEntry.new()
	entry.serial = _by_serial.size() + 1
	entry.event = event
	entry.day = day
	# Das Ende wird am Tag nach dem letzten Tag gemeldet, also am Beginn plus Dauer (R9); ohne
	# Dauer ist end_day der Beginn, und nichts endet. Jährliche Ereignisse haben kein
	# duration_days, ihr Ende setzt _plan_yearly().
	entry.end_day = day + maxi(event.duration_days, 0)
	entry.origin = origin
	_by_serial.append(entry)
	_count_day(entry)
	if at_day_end:
		entries.insert(_first_index_from(day + 1), entry)
	else:
		entries.insert(entries.bsearch_custom(entry, _comes_before), entry)
	_add_stop(day)
	return entry


## Merkt einen Stichtag vor. Was heute oder früher liegt, ist schon abgespielt; nach dem
## 31.12.1999 wird nichts mehr abgespielt.
func _add_stop(day: int) -> void:
	if day <= today or day > LAST_DAY:
		return
	var index := _stop_days.bsearch(day)
	if index < _stop_days.size() and _stop_days[index] == day:
		return
	_stop_days.insert(index, day)


# --- Abspielen -----------------------------------------------------------------

## Der nächste Stichtag nach today: der nächste Monatserste oder, falls früher, der nächste
## vorgemerkte Tag.
func _next_stop() -> int:
	var next := _month_starts[_next_month]
	if not _stop_days.is_empty():
		next = mini(next, _stop_days[0])
	return next


## Spielt einen Stichtag ab, in der festen Folge aus dem Vertrag (Tagesablauf; R6, FR-016).
func _play_day(day: int, messages: Array[TimelineMessage]) -> void:
	# 1. Enden laufender Termine, vor allem anderen: So endet am 01.03. erst der Winter, und dann
	#    beginnt der Frühling.
	_end_entries(day, messages)
	# 2. Verzögerte Wirkungen, die heute fällig werden.
	_start_due_effects(day, messages)
	# 3. Am Monatsersten die Würfelrunde.
	if _month_starts[_next_month] == day:
		_roll_month(_next_month, day)
		_next_month += 1
	# 4. Beginne.
	_start_entries(day, messages)
	today = day
	# Der Stichtag ist erledigt; alles, was jetzt noch vorgemerkt ist, liegt nach heute.
	while not _stop_days.is_empty() and _stop_days[0] <= day:
		_stop_days.remove_at(0)


## Schritt 1: Die Termine, deren Ende heute gemeldet wird, enden nach laufender Nummer. Je Termin
## erst das Ende jeder Wirkung, die nur während des Ereignisses gilt und schon begonnen hat, in
## Listenreihenfolge, dann das Ende des Ereignisses. Einmalige Anstöße enden nicht (FR-021).
func _end_entries(day: int, messages: Array[TimelineMessage]) -> void:
	if not _ends.has(day):
		return
	var ending: Array = _ends[day]
	_ends.erase(day)
	ending.sort_custom(_serial_before)
	for entry: ScheduleEntry in ending:
		entry.state = ScheduleEntry.State.ENDED
		_running.erase(entry.event.id)
		for effect in entry.event.effects:
			# Auch eine verzögerte Wirkung „während“ endet mit dem Ereignis, wenn sie begonnen hat.
			if entry.is_during(effect) and entry.effect_begins(effect):
				_emit(TimelineMessage.Kind.EFFECT_ENDED, day, entry, effect, messages)
		_emit(TimelineMessage.Kind.EVENT_ENDED, day, entry, null, messages)


## Schritt 2: die verzögerten Wirkungen des Tags, Termine nach laufender Nummer, je Termin die
## Wirkungen in Listenreihenfolge.
func _start_due_effects(day: int, messages: Array[TimelineMessage]) -> void:
	if not _due_effects.has(day):
		return
	var due: Array = _due_effects[day]
	_due_effects.erase(day)
	due.sort_custom(_due_before)
	for item: Array in due:
		_emit(TimelineMessage.Kind.EFFECT_STARTED, day, item[2], item[3], messages)


## Schritt 3, die Würfelrunde am Ersten des Monats [param month] (R8). Jedes Ereignis über
## Wahrscheinlichkeit würfelt mit seinem eigenen Würfel, in Kennungsreihenfolge. Ein Termin
## entsteht, wenn alles zutrifft:
## - Der Monat überschneidet das Zeitfenster.
## - Der Wurf trifft die wirksame Chance (chance_info(), _hits()).
## - Höchstzahl und Mindestabstand lassen ihn zu (FR-005).
## - Die Bedingungen sind erfüllt (FR-006).
func _roll_month(month: int, day: int) -> void:
	var month_end := _month_starts[month + 1] - 1
	for i in _chance_events.size():
		var event := _chance_events[i]
		var dice := _chance_dice[i]
		# Genau zwei Würfe je Monat, auch wenn das Ereignis gar nicht in Frage kommt. Sonst hinge
		# jeder spätere Wurf davon ab, was vorher geschah: Eine geänderte Bedingung oder Chance
		# verschöbe alle folgenden Würfe (R5).
		var roll := dice.randf()
		var share := dice.randf()
		# Nur die Tage dieses Monats im Zeitfenster; ein Monat, den es nur teilweise überdeckt,
		# wird gewürfelt, der Tag aber nur unter diesen Tagen.
		var first := maxi(day, event.window_from)
		var last := mini(month_end, event.window_to)
		if first > last:
			continue
		var info := chance_info(event.id, day)
		var threshold: float = info["effective"]
		if not _hits(roll, threshold):
			continue
		# Der Tag ist der share-te Teil dieser Tage. randf() kann genau 1,0 liefern, deshalb die
		# Grenze beim letzten Tag.
		var span := last - first + 1
		var rolled_day := first + mini(int(share * span), span - 1)
		if not _may_start_again(event, rolled_day) or not _unmet_condition(event, day).is_empty():
			continue
		var entry := _add_entry(event, rolled_day, ScheduleEntry.Origin.ROLLED)
		entry.roll = roll
		entry.threshold = threshold
		entry.base_chance = info["base"]
		# Die Begründung nennt zuerst die Start-Modifikatoren mit ihrem Grad, dann die Eingriffe
		# (R6 von Feature 003): „3 % + Schwer: Anspruchsvolle Kunden +5 + Ware vom windigen …“.
		var from_profile: Array[ChanceModifier] = info["start_modifiers"]
		var active: Array[ChanceModifier] = info["modifiers"]
		var notes := _modifier_notes(from_profile, Difficulty.label(difficulty) + ": ")
		notes.append_array(_modifier_notes(active))
		entry.modifier_notes = notes


## Schritt 4: Die geplanten Termine des Tags beginnen in der Reihenfolge, in der sie im Fahrplan
## stehen, also nach Herkunft, Kennung und laufender Nummer. Folgetermine ohne Verzögerung kommen
## hinten an die Reihe und beginnen noch heute.
func _start_entries(day: int, messages: Array[TimelineMessage]) -> void:
	var queue: Array[ScheduleEntry] = []
	var index := _first_index_from(day)
	while index < entries.size() and entries[index].day == day:
		if entries[index].state == ScheduleEntry.State.PLANNED:
			queue.append(entries[index])
		index += 1
	# Kein for: Die Schleife sieht so auch Termine, die _start_entry() hinten anhängt.
	var position := 0
	while position < queue.size():
		_start_entry(queue[position], day, queue, messages)
		position += 1


## Ein Termin beginnt oder entfällt. Die Prüfungen kommen in der Reihenfolge aus dem Vertrag:
## erst die Bedingungen, dann ob das Ereignis noch läuft, dann die Kettenbremse.
func _start_entry(entry: ScheduleEntry, day: int, queue: Array[ScheduleEntry],
		messages: Array[TimelineMessage]) -> void:
	var unmet := _unmet_condition(entry.event, day)
	if not unmet.is_empty():
		_skip(entry, day, TimelineMessage.Kind.ENTRY_SKIPPED, unmet, messages)
		return
	# Ein Ereignis läuft nie zweimal gleichzeitig (FR-022). Was heute endet, hat Schritt 1 schon
	# beendet; es hält den neuen Termin nicht auf.
	var running := _running_entry(entry.event)
	if running != null:
		_skip(entry, day, TimelineMessage.Kind.ENTRY_SKIPPED,
			"läuft noch bis %s" % GameDate.from_day_index(running.end_day - 1), messages)
		return
	var link: int = _chain_links.get(entry.serial, 1)
	if link > MAX_CHAIN:
		_skip(entry, day, TimelineMessage.Kind.CHAIN_STOPPED,
			"Glied %d einer Kette am selben Tag, erlaubt sind %d" % [link, MAX_CHAIN], messages)
		return
	if entry.end_day > entry.day:
		entry.state = ScheduleEntry.State.RUNNING
		_running[entry.event.id] = entry
		_plan_end(entry)
	else:
		entry.state = ScheduleEntry.State.OCCURRED
	if not _first_start.has(entry.event.id):
		_first_start[entry.event.id] = day
	_emit(TimelineMessage.Kind.EVENT_STARTED, day, entry, null, messages)
	var effects := entry.event.effects
	for i in effects.size():
		# Eine Wirkung „während“, die erst mit dem Ende oder danach begänne, beginnt nie (V19).
		# Die Regel steht in ScheduleEntry, damit der Fahrplan (due_effects()) dieselbe nimmt.
		if not entry.effect_begins(effects[i]):
			continue
		var effect_day := entry.effect_day(effects[i])
		if effect_day > day:
			_plan_effect(entry, i, effect_day)
		else:
			_emit(TimelineMessage.Kind.EFFECT_STARTED, day, entry, effects[i], messages)
	for i in entry.event.follow_ups.size():
		_decide_follow_up(entry, i, day, link, queue)


func _skip(entry: ScheduleEntry, day: int, kind: TimelineMessage.Kind, reason: String,
		messages: Array[TimelineMessage]) -> void:
	_uncount_day(entry)
	entry.state = ScheduleEntry.State.SKIPPED
	entry.note = reason
	_emit(kind, day, entry, null, messages)


## Merkt die Wirkung Nummer [param index] des Termins für ihren Tag vor (FR-013). Nach dem
## 31.12.1999 wird sie nicht mehr gemeldet (FR-019); der Fahrplan zeigt sie trotzdem, über
## ScheduleEntry.due_effects().
func _plan_effect(entry: ScheduleEntry, index: int, day: int) -> void:
	if day > LAST_DAY:
		return
	if not _due_effects.has(day):
		_due_effects[day] = []
	_due_effects[day].append([entry.serial, index, entry, entry.event.effects[index]])
	_add_stop(day)


## Merkt das Ende eines laufenden Termins für seinen Tag vor. Ein Ende nach dem 31.12.1999 wird
## nie gemeldet (FR-019): Der Termin läuft dann bis zum Schluss, und der Fahrplan zeigt sein Ende
## trotzdem, über end_day.
func _plan_end(entry: ScheduleEntry) -> void:
	if entry.end_day > LAST_DAY:
		return
	if not _ends.has(entry.end_day):
		_ends[entry.end_day] = []
	_ends[entry.end_day].append(entry)
	_add_stop(entry.end_day)


## Würfelt über das Folgeereignis Nummer [param index] des Termins [param source], der heute
## beginnt (R10). Jede Entscheidung hat ihren eigenen Würfel mit dem Schlüssel
## "<quelle>|<index>|<tag>": erst randf() für die Wahrscheinlichkeit, dann randi_range() für
## die Verzögerung. Der neue Termin steht sofort im Fahrplan (FR-011), mit Wurf und Schwelle.
func _decide_follow_up(source: ScheduleEntry, index: int, day: int, link: int,
		queue: Array[ScheduleEntry]) -> void:
	var follow_up := source.event.follow_ups[index]
	var dice := EventDice.make(seed, EventDice.PURPOSE_FOLLOW,
		"%s|%d|%d" % [source.event.id, index, day])
	var roll := dice.randf()
	# Eine negative Verzögerung (V14) gilt als 0; ein Termin vor heute käme nie mehr an die Reihe.
	var delay := maxi(dice.randi_range(follow_up.delay_min, follow_up.delay_max), 0)
	var target: TimelineEvent = _events_by_id.get(follow_up.target)
	if not _hits(roll, follow_up.chance) or target == null:
		return
	var entry := _add_entry(target, day + delay, ScheduleEntry.Origin.FOLLOW_UP, delay == 0)
	entry.roll = roll
	entry.threshold = follow_up.chance
	entry.base_chance = follow_up.chance
	entry.source_event_id = source.event.id
	entry.source_title = source.event.title
	if delay == 0:
		# Ein Glied mehr als sein Auslöser; er beginnt noch heute, hinten in der Reihe. Ein
		# Folgetermin mit Verzögerung beginnt an seinem Tag dagegen eine neue Kette.
		_chain_links[entry.serial] = link + 1
		queue.append(entry)


# --- Hilfen ---------------------------------------------------------------------

## Der Grund, warum eine Bedingung des Ereignisses am Tag [param day] nicht erfüllt ist; leer,
## wenn alle erfüllt sind. „Eingetreten“ heißt: Ein Termin hat bis zum Vortag begonnen, auch wenn
## er noch läuft. Was heute beginnt, zählt erst ab morgen (FR-006); so entscheidet die
## Reihenfolge innerhalb eines Tags nichts.
func _unmet_condition(event: TimelineEvent, day: int) -> String:
	for condition in event.conditions:
		var occurred := _first_start.has(condition.event) \
			and int(_first_start[condition.event]) < day
		if condition.occurred and not occurred:
			return "Bedingung nicht erfüllt, „%s“ ist noch nicht eingetreten" \
				% _title_of(condition.event)
		if not condition.occurred and occurred:
			return "Bedingung nicht erfüllt, „%s“ ist schon eingetreten" \
				% _title_of(condition.event)
	return ""


## Ob das Ereignis an [param day] noch einmal beginnen darf (FR-005): Die Höchstzahl ist nicht
## erreicht, und der Tag liegt von jedem Termin des Ereignisses mindestens den Mindestabstand
## entfernt, in beide Richtungen, auch von einem, der erst noch geplant ist. Entfallene und
## abgesagte Termine zählen bei beidem nicht mit. Ein Mindestabstand von 0 prüft nichts.
##
## Dafür muss es nicht jeden Termin durchgehen: _counted_days hält die Tage, die zählen,
## aufsteigend. Ihre Zahl ist die Zahl für die Höchstzahl. Der nächste Termin vor und nach dem Tag
## steht direkt neben der Stelle, an die bsearch() den Tag einsortieren würde; liegen beide weit
## genug weg, liegen es alle anderen auch.
func _may_start_again(event: TimelineEvent, day: int) -> bool:
	var days: PackedInt32Array = _counted_days.get(event.id, PackedInt32Array())
	if event.max_occurrences > 0 and days.size() >= event.max_occurrences:
		return false
	if event.min_gap_days <= 0:
		return true
	# Die erste Stelle mit einem Tag ≥ day; davor liegen nur frühere Tage.
	var index := days.bsearch(day)
	if index < days.size() and days[index] - day < event.min_gap_days:
		return false
	return index == 0 or day - days[index - 1] >= event.min_gap_days


## Der Termin des Ereignisses, der gerade läuft; null, wenn keiner läuft (FR-022).
func _running_entry(event: TimelineEvent) -> ScheduleEntry:
	return _running.get(event.id)


## Ein Termin zählt ab jetzt für Höchstzahl und Mindestabstand: neu angelegt oder verschoben.
## Sein Tag kommt an seine Stelle in _counted_days.
func _count_day(entry: ScheduleEntry) -> void:
	var days: PackedInt32Array = _counted_days.get(entry.event.id, PackedInt32Array())
	days.insert(days.bsearch(entry.day), entry.day)
	# Zurückschreiben: So stimmt es, ob das Dictionary die Liste als Verweis hält oder als Kopie.
	_counted_days[entry.event.id] = days


## Ein geplanter Termin zählt nicht mehr, weil er entfällt oder abgesagt wird; beim Verschieben
## zählt er danach mit seinem neuen Tag wieder. Stehen mehrere Termine am selben Tag, ist egal,
## welcher Eintrag wegfällt; es bleibt dieselbe Liste von Tagen.
func _uncount_day(entry: ScheduleEntry) -> void:
	var days: PackedInt32Array = _counted_days[entry.event.id]
	days.remove_at(days.bsearch(entry.day))
	_counted_days[entry.event.id] = days


## Neue Meldung über einen Termin. Sie geht an die Liste dieses Aufrufs und ins Protokoll. Der
## Text nennt den Titel, bei Wirkungen dahinter die Wirkung, bei Entfall den Grund.
func _emit(kind: TimelineMessage.Kind, day: int, entry: ScheduleEntry, effect: EventEffect,
		messages: Array[TimelineMessage]) -> void:
	var message := TimelineMessage.new()
	message.day = day
	message.kind = kind
	message.event = entry.event
	message.effect = effect
	message.entry = entry
	match kind:
		TimelineMessage.Kind.EFFECT_STARTED, TimelineMessage.Kind.EFFECT_ENDED:
			message.text = "%s: %s" % [entry.event.title, effect.describe()]
		TimelineMessage.Kind.ENTRY_SKIPPED, TimelineMessage.Kind.CHAIN_STOPPED:
			message.text = "%s: %s" % [entry.event.title, entry.note]
		_:
			message.text = entry.event.title
	messages.append(message)
	protocol.append(message)


## Titel eines Ereignisses für Texte; steht es nicht im Katalog, die Kennung.
func _title_of(event_id: String) -> String:
	var event: TimelineEvent = _events_by_id.get(event_id)
	return event.title if event != null else event_id


## Stelle des ersten Termins im Fahrplan, der an [param day] oder später beginnt. entries ist
## nach Tag sortiert, deshalb genügt eine Binärsuche: die Hälfte prüfen, in der der Tag liegen
## muss, und so weiter. bsearch_custom() hilft hier nicht, denn auf einem typisierten Array sucht
## es nur nach einem ScheduleEntry, nicht nach einer Zahl.
func _first_index_from(day: int) -> int:
	var low := 0
	var high := entries.size()
	while low < high:
		var middle := floori((low + high) / 2.0)
		if entries[middle].day < day:
			low = middle + 1
		else:
			high = middle
	return low


## Reihenfolge im Fahrplan: nach Tag, dann Herkunft, Kennung und laufender Nummer (R6). Die
## Herkunft zählt in der Reihenfolge von ScheduleEntry.Origin: fix, jährlich, gesetzt,
## gewürfelt, Folge, Eingriff.
static func _comes_before(a: ScheduleEntry, b: ScheduleEntry) -> bool:
	if a.day != b.day:
		return a.day < b.day
	if a.origin != b.origin:
		return a.origin < b.origin
	if a.event.id != b.event.id:
		return a.event.id < b.event.id
	return a.serial < b.serial


## Ob ein Wurf trifft: unter der Schwelle, und eine Schwelle von 100 % trifft immer (R8, R10).
## randf() kann laut Doku genau 1,0 liefern; mit „Wurf < Schwelle“ allein verfehlte eine Chance
## von 100 % dann, im Schnitt etwa einmal in 33 Millionen Würfen.
static func _hits(roll: float, threshold: float) -> bool:
	return roll < threshold or threshold >= 1.0


## Fällige Wirkungen nach laufender Nummer ihres Termins, dann nach ihrer Stelle in der Liste.
static func _due_before(a: Array, b: Array) -> bool:
	if a[0] != b[0]:
		return a[0] < b[0]
	return a[1] < b[1]


## Termine nach laufender Nummer.
static func _serial_before(a: ScheduleEntry, b: ScheduleEntry) -> bool:
	return a.serial < b.serial


## Die Modifikatoren für die Begründung, je „<grund> <wert in Prozentpunkten>“, etwa
## „Ware vom windigen Händler +5“. Der Termin behält den Text, auch wenn der Modifikator später
## entfernt wird (R8). Start-Modifikatoren bekommen [param prefix] mit ihrem Grad davor, etwa
## „Schwer: Anspruchsvolle Kunden +5“.
static func _modifier_notes(active: Array[ChanceModifier], prefix: String = "") -> PackedStringArray:
	var notes := PackedStringArray()
	for modifier in active:
		notes.append("%s%s %s" % [prefix, modifier.reason, format_points(modifier.value)])
	return notes


## Anteil als Prozentpunkte mit Vorzeichen und deutschem Komma, etwa +0.05 als „+5“ und −0.025
## als „-2,5“, mit dem einfachen Minus. So steht der Wert eines Modifikators in der Begründung
## eines Termins; die Werkstatt zeigt ihn genauso und liest ihn wieder.
static func format_points(share: float) -> String:
	var text := ("%+.2f" % (share * 100.0)).rstrip("0").rstrip(".")
	return text.replace(".", ",")


## Der Tag des Ersten jedes Monats von Januar 1985 bis Dezember 1999, dazu der 01.01.2000.
static func _first_days_of_months() -> PackedInt32Array:
	var days := PackedInt32Array()
	var year := GameDate.EPOCH_YEAR
	var month := 1
	var day := FIRST_DAY
	while days.size() <= MONTHS:
		days.append(day)
		day += GameDate.days_in_month(year, month)
		month += 1
		if month > 12:
			month = 1
			year += 1
	return days


## Beginn und letzter Tag des Vorkommens eines jährlichen Ereignisses, das im Jahr [param year]
## beginnt, als Tagesindizes; ohne Dauer ist der letzte Tag der Beginn. Leer, wenn Beginn oder
## Ende in diesem Jahr kein Kalendertag ist, etwa der 29.02. außerhalb eines Schaltjahrs; die
## Prüfung meldet das als V09.
static func _occurrence(event: TimelineEvent, year: int) -> PackedInt32Array:
	var start := event.yearly_start
	if not GameDate.is_valid(year, start.x, start.y):
		return PackedInt32Array()
	var first := GameDate.new(year, start.x, start.y).to_day_index()
	var end := event.yearly_end
	if end == Vector2i.ZERO:
		return PackedInt32Array([first, first])
	# Liegt das Ende im Jahr vor dem Beginn, reicht das Vorkommen ins nächste Jahr, wie der Winter
	# vom 01.12. bis Ende Februar. Das Monatsende, Tag 0, liegt hinter jedem Tag seines Monats.
	var end_year := year
	if end.x < start.x or (end.x == start.x and end.y != 0 and end.y < start.y):
		end_year += 1
	# „ende“ heißt Monatsende; so reicht der Februar im Schaltjahr bis zum 29.
	var last := end.y if end.y != 0 else GameDate.days_in_month(end_year, end.x)
	if not GameDate.is_valid(end_year, end.x, last):
		return PackedInt32Array()
	return PackedInt32Array([first, GameDate.new(end_year, end.x, last).to_day_index()])


## Tagesindex des 01.01. von [param year]. Jahre vor 1984 zählen wie 1984, Jahre nach 2001 wie 2001;
## für yearly_occurrences() ändert das nichts, aber GameDate muss keine Jahrtausende abzählen.
static func _new_year(year: int) -> int:
	var clamped := clampi(year, CatalogValidator.FIRST_YEAR - 1, CatalogValidator.LAST_YEAR + 2)
	return GameDate.new(clamped, 1, 1).to_day_index()


# --- Hilfen für Eingriffe ----------------------------------------------------------

## Lehnt einen Eingriff ab: merkt den Grund in last_refusal und gibt [param error] zurück.
## Fahrplan, Protokoll und Eingriffsprotokoll bleiben unberührt.
func _refuse(error: Error, reason: String) -> Error:
	last_refusal = reason
	return error


## Nimmt einen Eingriff an: Der Eintrag kommt ins Eingriffsprotokoll, und eine Meldung
## INTERVENTION mit dem Tag today kommt ins Protokoll, etwa „01.01.1992  Eingriff  Konkurrent
## eröffnet: Termin am 01.06.1992 abgesagt, Grund: …“. Vor Spielbeginn steht dort der 31.12.1984:
## Der Eingriff geschah, bevor der erste Tag abgespielt war (FR-027, „mit Zeitpunkt und Grund“).
## Die Meldung geht nicht in die Rückgabe von advance_to(); das Autoload macht daraus kein Signal.
func _accept(record: Dictionary, event: TimelineEvent, entry: ScheduleEntry, text: String) -> void:
	interventions.append(record)
	var message := TimelineMessage.new()
	message.day = today
	message.kind = TimelineMessage.Kind.INTERVENTION
	message.event = event
	message.entry = entry
	message.text = "%s: %s" % [event.title, text] if event != null else text
	protocol.append(message)


## Neuer Eintrag fürs Eingriffsprotokoll mit Art und Tag; die übrigen Felder setzt der Eingriff.
func _record(kind: String) -> Dictionary:
	return {"at_day": today, "kind": kind}


## Ob sich der Termin absagen oder verschieben lässt (FR-026): Es gibt ihn, er ist weder fix noch
## jährlich, er ist noch geplant, und sein Tag liegt nach today und spätestens am 31.12.1999. Gibt
## OK zurück oder lehnt ab.
func _check_changeable(entry: ScheduleEntry, serial: int) -> Error:
	if entry == null:
		return _refuse(ERR_DOES_NOT_EXIST, "Einen Termin mit der Nummer %d gibt es nicht." % serial)
	var title := entry.event.title
	if entry.origin == ScheduleEntry.Origin.FIXED or entry.origin == ScheduleEntry.Origin.YEARLY:
		var label := "fix" if entry.origin == ScheduleEntry.Origin.FIXED else "jährlich"
		return _refuse(ERR_UNAVAILABLE,
			"%s ist %s und lässt sich weder absagen noch verschieben." % [title, label])
	if entry.state != ScheduleEntry.State.PLANNED:
		return _refuse(ERR_UNAVAILABLE, "%s am %s ist nicht mehr geplant, sondern %s."
			% [title, _date(entry.day), entry.state_label()])
	var problem := _day_problem(entry.day)
	if not problem.is_empty():
		return _refuse(ERR_UNAVAILABLE, "%s: %s" % [title, problem])
	return OK


## Warum ein Eingriff am Tag [param day] nicht geht; leer, wenn er geht. Möglich sind die Tage nach
## today bis zum 31.12.1999 (FR-026). today selbst ist schon abgespielt, vor Spielbeginn ist das
## der 31.12.1984.
func _day_problem(day: int) -> String:
	if day > LAST_DAY:
		return "Der %s liegt nach dem Spielende am %s." % [_date(day), _date(LAST_DAY)]
	if day > today:
		return ""
	if day < FIRST_DAY:
		return "Der %s liegt vor dem Spielbeginn am %s." % [_date(day), _date(FIRST_DAY)]
	return "Der %s ist schon abgespielt; frühestens geht der %s." % [_date(day),
		_date(today + 1)]


## Stelle des Modifikators mit der Kennung [param id] in modifiers; −1, wenn es ihn nicht gibt.
func _modifier_index(id: String) -> int:
	for i in modifiers.size():
		if modifiers[i].id == id:
			return i
	return -1


## Grund für ein Ereignis, das es im Katalog des Laufs nicht gibt.
static func _unknown_event(event_id: String) -> String:
	return "Das Ereignis „%s“ gibt es im Katalog nicht." % event_id


## „fix“ oder „jährlich“, für Ablehnungen.
static func _fixed_label(kind: TimelineEvent.Kind) -> String:
	return "jährlich" if kind == TimelineEvent.Kind.YEARLY else "fix"


## Ein Modifikator als Dictionary fürs Eingriffsprotokoll, mit den Feldern von ChanceModifier.
static func _modifier_record(modifier: ChanceModifier) -> Dictionary:
	return {
		"event_id": modifier.event_id,
		"from_day": modifier.from_day,
		"id": modifier.id,
		"reason": modifier.reason,
		"to_day": modifier.to_day,
		"value": modifier.value,
	}


## Ein Modifikator aus einem Dictionary wie von _modifier_record(). Fehlen Kennung, Ereignis, Grund
## oder Ende, bekommen sie die Vorgabe von ChanceModifier, und add_modifier() lehnt ihn dann ab.
## Wert und Beginn prüft apply_intervention() vorher mit _unreadable_modifier(): Ihre Vorgaben, 0
## und der 01.01.1985, wären gültige Werte, und der Modifikator gälte still damit.
static func _modifier_from_record(data: Dictionary) -> ChanceModifier:
	var modifier := ChanceModifier.new()
	modifier.id = _text_of(data, "id")
	modifier.event_id = _text_of(data, "event_id")
	modifier.reason = _text_of(data, "reason")
	modifier.from_day = _int_of(data, "from_day", modifier.from_day)
	modifier.to_day = _int_of(data, "to_day", modifier.to_day)
	var value: Variant = data.get("value")
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		modifier.value = float(value)
	return modifier


## Warum sich ein Modifikator aus dem Eingriffsprotokoll nicht lesen lässt; leer, wenn Wert und
## Beginn lesbar sind. Beides prüft add_modifier() nicht, denn ein ChanceModifier hat immer einen
## Wert und einen Beginn. Aus einer Probe, die jemand von Hand geändert hat, kann aber etwa
## "value": "0,05" kommen, ein Text, oder der Beginn fehlen; mit den Vorgaben gälte der
## Modifikator dann still mit 0 Prozentpunkten bzw. ab dem 01.01.1985 (T099).
static func _unreadable_modifier(data: Dictionary) -> String:
	var value: Variant = data.get("value")
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return "Der Wert des Modifikators („value“) fehlt oder ist keine Zahl."
	if not _has_int(data, "from_day"):
		return "Der Beginn des Modifikators („from_day“) fehlt oder ist kein Tag."
	return ""


## data[key] als Text; leer, wenn es fehlt oder kein Text ist.
static func _text_of(data: Dictionary, key: String) -> String:
	var value: Variant = data.get(key)
	if typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
		return String(value)
	return ""


## data[key] als ganze Zahl. Aus einer JSON-Datei kommt jede Zahl als float, 14 also als 14.0;
## ein float ohne Nachkommastellen gilt deshalb als ganze Zahl. Sonst [param fallback].
static func _int_of(data: Dictionary, key: String, fallback: int) -> int:
	return int(data[key]) if _has_int(data, key) else fallback


## Ob data[key] eine ganze Zahl ist, als int oder als float ohne Nachkommastellen wie aus JSON.
static func _has_int(data: Dictionary, key: String) -> bool:
	var value: Variant = data.get(key)
	if typeof(value) == TYPE_INT:
		return true
	return typeof(value) == TYPE_FLOAT and value == floorf(value) and absf(value) < 1e15


## Tagesindex als „TT.MM.JJJJ“, auch vor 1985 und nach 1999.
static func _date(day: int) -> String:
	return str(GameDate.from_day_index(day))


## Wert eines Modifikators in Prozentpunkten, etwa „+5 Prozentpunkte“ oder „-1 Prozentpunkt“.
static func _points_text(share: float) -> String:
	var unit := "Prozentpunkt" if is_equal_approx(absf(share * 100.0), 1.0) else "Prozentpunkte"
	return "%s %s" % [format_points(share), unit]
