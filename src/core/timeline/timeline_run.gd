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
## Stand Phase 5: fixe, jährliche und beim Start gesetzte Termine, die Würfelrunde für Ereignisse
## über Wahrscheinlichkeit, Bedingungen, Folgeereignisse mit Kettenbremse, verzögerte Wirkungen
## und Ereignisse mit Dauer (R9). Ein Termin mit Dauer „läuft“ nach seinem Beginn und ist nach
## seinem Ende „beendet“; einer ohne Dauer ist ein Augenblick und nach dem Beginn „eingetreten“.
## Eingriffe kommen mit Phase 8; die Stelle dafür ist im Code mit „Phase 8“ markiert.

const FIRST_DAY := 0          # 01.01.1985
const LAST_DAY := 5477        # 31.12.1999
const MONTHS := 180
const MAX_CHAIN := 16         # Glieder einer Folgekette am selben Tag, gezählt je Kette (R10)

## Eigene Kopie des Katalogs; der Lauf verändert sie nie.
var catalog: EventCatalog
# Der Name kommt aus dem Vertrag und ist zugleich der einer globalen Funktion, seed(); die
# Warnung darüber ist abgeschaltet, sonst wäre der Start mit -d nicht still.
## Der Seed des Spiels; aus ihm folgen alle Zufallsentscheidungen (R5).
@warning_ignore("shadowed_global_identifier")
var seed: int
## Zuletzt abgespielter Tag; −1 vor begin().
var today: int = -1
## Der Fahrplan: nach Tag sortiert, an einem Tag in der Reihenfolge, in der die Termine beginnen.
var entries: Array[ScheduleEntry] = []
## Modifikatoren der Chancen. Die Eingriffe, die sie setzen und entfernen, kommen mit Phase 8;
## was hier steht, rechnen chance_info() und die Würfelrunden schon ein.
var modifiers: Array[ChanceModifier] = []
## Alle Meldungen des Laufs in der Reihenfolge, in der sie entstanden sind.
var protocol: Array[TimelineMessage] = []

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
## Kennung → alle Termine des Ereignisses in der Reihenfolge ihres Entstehens.
var _entries_by_event: Dictionary = {}
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
## (FR-010).
func _init(p_catalog: EventCatalog, p_seed: int) -> void:
	catalog = p_catalog.duplicate_catalog() if p_catalog != null else EventCatalog.new()
	seed = p_seed
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
## Dictionary mit vier Schlüsseln:
## - "base" (float): die Grundchance aus dem Katalog; 0 bei einem unbekannten Ereignis oder
##   einem Ereignis anderer Art;
## - "sum" (float): die Grundchance plus alle Modifikatoren, die an diesem Tag gelten, noch nicht
##   begrenzt;
## - "effective" (float): sum, begrenzt auf 0 bis 1; damit wird gewürfelt;
## - "modifiers" (Array[ChanceModifier]): die Modifikatoren, die an diesem Tag gelten, in ihrer
##   Reihenfolge.
##
## Beispiel aus US6, Szenario 3: 3 % mit −6 Prozentpunkten ergibt sum −0,03 und effective 0.
func chance_info(event_id: String, day: int) -> Dictionary:
	var event: TimelineEvent = _events_by_id.get(event_id)
	var base := 0.0
	if event != null and event.kind == TimelineEvent.Kind.CHANCE:
		base = event.monthly_chance
	var active: Array[ChanceModifier] = []
	var total := base
	for modifier in modifiers:
		if modifier.event_id == event_id and modifier.is_active(day):
			active.append(modifier)
			total += modifier.value
	return {"base": base, "sum": total, "effective": clampf(total, 0.0, 1.0), "modifiers": active}


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
	if not _entries_by_event.has(event.id):
		_entries_by_event[event.id] = []
	_entries_by_event[event.id].append(entry)
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
		for effect in entry.event.effects:
			# Auch eine verzögerte Wirkung „während“ endet mit dem Ereignis.
			if _is_during(entry, effect) and _effect_day(entry, effect) < entry.end_day:
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
		var active: Array[ChanceModifier] = info["modifiers"]
		entry.modifier_notes = _modifier_notes(active)


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
		_plan_end(entry)
	else:
		entry.state = ScheduleEntry.State.OCCURRED
	if not _first_start.has(entry.event.id):
		_first_start[entry.event.id] = day
	_emit(TimelineMessage.Kind.EVENT_STARTED, day, entry, null, messages)
	var effects := entry.event.effects
	for i in effects.size():
		var effect_day := _effect_day(entry, effects[i])
		# Eine Wirkung „während“, die erst mit dem Ende oder danach begänne, beginnt nie (V19).
		if _is_during(entry, effects[i]) and effect_day >= entry.end_day:
			continue
		if effect_day > day:
			_plan_effect(entry, i, effect_day)
		else:
			_emit(TimelineMessage.Kind.EFFECT_STARTED, day, entry, effects[i], messages)
	for i in entry.event.follow_ups.size():
		_decide_follow_up(entry, i, day, link, queue)


func _skip(entry: ScheduleEntry, day: int, kind: TimelineMessage.Kind, reason: String,
		messages: Array[TimelineMessage]) -> void:
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
func _may_start_again(event: TimelineEvent, day: int) -> bool:
	var counted := 0
	for entry: ScheduleEntry in _entries_by_event.get(event.id, []):
		if entry.state == ScheduleEntry.State.SKIPPED \
				or entry.state == ScheduleEntry.State.CANCELLED:
			continue
		if event.min_gap_days > 0 and absi(day - entry.day) < event.min_gap_days:
			return false
		counted += 1
	return event.max_occurrences <= 0 or counted < event.max_occurrences


## Der Termin des Ereignisses, der gerade läuft; null, wenn keiner läuft (FR-022).
func _running_entry(event: TimelineEvent) -> ScheduleEntry:
	for entry: ScheduleEntry in _entries_by_event.get(event.id, []):
		if entry.state == ScheduleEntry.State.RUNNING:
			return entry
	return null


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


## Ob die Wirkung nur während ihres Termins gilt: Sie ist „während“, und der Termin hat eine
## Dauer. Bei Ereignissen ohne Dauer wirkt „während“ wie „einmal“ (FR-021).
static func _is_during(entry: ScheduleEntry, effect: EventEffect) -> bool:
	return effect.scope == EventEffect.Scope.DURING and entry.end_day > entry.day


## Der Tag, an dem die Wirkung beginnt: der Beginn des Termins plus ihre Verzögerung. Eine
## negative Verzögerung (V14) gilt als 0.
static func _effect_day(entry: ScheduleEntry, effect: EventEffect) -> int:
	return entry.day + maxi(effect.delay_days, 0)


## Die Modifikatoren für die Begründung, je „<grund> <wert in Prozentpunkten>“, etwa
## „Ware vom windigen Händler +5“. Der Termin behält den Text, auch wenn der Modifikator später
## entfernt wird (R8).
static func _modifier_notes(active: Array[ChanceModifier]) -> PackedStringArray:
	var notes := PackedStringArray()
	for modifier in active:
		notes.append("%s %s" % [modifier.reason, _points(modifier.value)])
	return notes


## Anteil als Prozentpunkte mit Vorzeichen und deutschem Komma, etwa +0.05 als „+5“ und −0.025
## als „-2,5“.
static func _points(share: float) -> String:
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
