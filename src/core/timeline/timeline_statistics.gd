class_name TimelineStatistics
extends RefCounted

## Statistik über viele Spiele (FR-044, FR-045; research.md, R17): Spiel für Spiel entsteht ein
## TimelineRun mit dem nächsten Seed und läuft bis zum 31.12.1999. Danach zählt die Statistik, wie
## oft jedes Ereignis begonnen hat und in welchen Jahren (EventStatistic).
##
## Gerechnet wird in Häppchen nach Zeit: run_for() spielt das laufende Spiel Monat für Monat weiter
## und beginnt danach das nächste, bis das Budget verbraucht ist. Die Werkstatt ruft es einmal je
## Bild mit 15 ms auf und bleibt so bedienbar, auch wenn 1.000 Spiele Sekunden dauern. Abbrechen
## heißt nur: nicht mehr aufrufen. results() kennt die fertigen Spiele; ein angefangenes Spiel
## zählt erst, wenn es fertig ist.
##
## Die Seeds laufen fortlaufend ab first_seed, also 1, 2, 3 und so weiter. Dieselbe Rechnung ergibt
## deshalb immer dasselbe Ergebnis, egal in wie vielen Häppchen sie läuft (US7, Szenario 5).
##
## Den Katalog bekommt die Statistik so, wie das Spiel rechnet: ohne die Ereignisse mit Fehlern,
## also aus EventCatalog.without_faulty() mit allen Meldungen, auch denen beim Lesen. Sie prüft ihn
## nicht noch einmal. Eine zweite Prüfung meldete jede Bedingung, die auf ein ausgenommenes
## Ereignis zeigt, als Fehler (V15) und nähme dann auch dieses Ereignis aus; das Spiel lässt solche
## Bedingungen stehen (data-model.md, „Fehlerhafte Ereignisse ausnehmen“). Die Statistik legt sich
## eine eigene Kopie an, damit Änderungen in der Werkstatt eine laufende Rechnung nicht erreichen
## (FR-042).
##
## Eingriffe: [member interventions] nimmt das Eingriffsprotokoll des Simulators. Davon gelten nur
## Modifikatoren, gesetzte wie entfernte, und Einplanungen, in jedem Spiel an ihrem at_day über
## TimelineRun.apply_intervention(), wie beim Neu abspielen einer Probe. Absagen und Verschiebungen
## meinen einen Termin eines bestimmten Seeds und gelten deshalb nicht (R11, FR-045).

## Die Arten im Eingriffsprotokoll, die sich auf jeden Seed übertragen lassen (R11).
const SEED_FREE_KINDS: Array[String] = [
	TimelineRun.INTERVENTION_ADD_MODIFIER,
	TimelineRun.INTERVENTION_REMOVE_MODIFIER,
	TimelineRun.INTERVENTION_SCHEDULE,
]

## Der Katalog aller Spiele: eine eigene Kopie, ohne fehlerhafte Ereignisse.
var catalog: EventCatalog
## Der Seed des ersten Spiels; jedes weitere Spiel hat den nächsten.
var first_seed: int = 1
var game_count: int = 1000
## Wie viele Spiele fertig gerechnet sind.
var games_done: int = 0
## Eingriffsprotokoll aus dem Simulator; angewandt werden nur add_modifier, remove_modifier und
## schedule, je Spiel an ihrem at_day über TimelineRun.apply_intervention() (R11, FR-045). Setzen
## vor dem ersten run_for(); danach gilt, was das erste Spiel vorgefunden hat.
var interventions: Array[Dictionary] = []

## Das angefangene Spiel; null zwischen zwei Spielen.
var _run: TimelineRun
## Die Eingriffe, die für jeden Seed gelten, ausgesucht beim Start des ersten Spiels, und welcher
## davon im laufenden Spiel als nächster an der Reihe ist.
var _records: Array[Dictionary] = []
var _records_chosen := false
var _next_record := 0
## Je Ereignis die Zählung über die fertigen Spiele, nach Kennung; dazu Kennung → Stelle und an
## derselben Stelle die Obergrenze, −1 ohne.
var _statistics: Array[EventStatistic] = []
var _index: Dictionary = {}
var _limits: PackedInt32Array = PackedInt32Array()
## Der Erste jedes Monats von Januar 1985 bis Dezember 1999, dazu der 01.01.2000.
var _month_starts: PackedInt32Array = PackedInt32Array()


## [param p_catalog] kommt ohne fehlerhafte Ereignisse (siehe oben); die Statistik rechnet
## [param p_game_count] Spiele mit den Seeds ab [param p_first_seed].
func _init(p_catalog: EventCatalog, p_game_count: int = 1000, p_first_seed: int = 1) -> void:
	catalog = p_catalog.duplicate_catalog() if p_catalog != null else EventCatalog.new()
	game_count = maxi(p_game_count, 0)
	first_seed = p_first_seed
	_month_starts = _first_days_of_months()
	var by_id: Array[TimelineEvent] = catalog.events.duplicate()
	by_id.sort_custom(func(a: TimelineEvent, b: TimelineEvent) -> bool: return a.id < b.id)
	for event in by_id:
		# Eine doppelte Kennung (V02) ist ein Fehler und kommt hier nicht an; käme sie doch, zählte
		# die Statistik beide Ereignisse zusammen.
		if _index.has(event.id):
			continue
		var statistic := EventStatistic.new()
		statistic.event_id = event.id
		statistic.title = event.title
		var limit := upper_limit(event)
		statistic.games_at_max = 0 if limit >= 0 else -1
		_index[event.id] = _statistics.size()
		_statistics.append(statistic)
		_limits.append(limit)


## Rechnet weiter, bis [param budget_msec] Millisekunden verbraucht sind: das laufende Spiel Monat
## für Monat, dann das nächste (R17). Die Zeit prüft run_for() nach jedem Monat; es kehrt also
## höchstens um die Rechenzeit eines Monats später zurück und rechnet auch mit dem Budget 0 einen
## Monat. Gibt true zurück, wenn alle Spiele fertig sind.
func run_for(budget_msec: int) -> bool:
	# Time.get_ticks_usec() zählt Mikrosekunden seit dem Programmstart. Für ein Budget von 15 ms ist
	# das genauer als get_ticks_msec(), das ganze Millisekunden abschneidet.
	var deadline := Time.get_ticks_usec() + budget_msec * 1000
	while games_done < game_count:
		if _run == null:
			_start_game()
		_play_month()
		if _run.is_finished():
			_count_game()
			_run = null
			games_done += 1
		if Time.get_ticks_usec() >= deadline:
			break
	return games_done >= game_count


## Je Ereignis eine EventStatistic über die fertigen Spiele, nach Kennung. Jeder Aufruf liefert neue
## Objekte; was jemand daran ändert, erreicht die Rechnung nicht.
func results() -> Array[EventStatistic]:
	var copies: Array[EventStatistic] = []
	for statistic in _statistics:
		copies.append(_copy(statistic))
	return copies


## Die Obergrenze eines Ereignisses (FR-044): die Höchstzahl bei Ereignissen über Wahrscheinlichkeit
## und die höchste Anzahl bei gesetzten; −1 ohne Obergrenze. Eine Höchstzahl von 0 heißt
## unbegrenzt und ergibt deshalb ebenfalls −1.
static func upper_limit(event: TimelineEvent) -> int:
	match event.kind:
		TimelineEvent.Kind.CHANCE:
			return event.max_occurrences if event.max_occurrences > 0 else -1
		TimelineEvent.Kind.PRESET:
			# Das erste Gewicht gehört zu count_min, das letzte zur höchsten Anzahl.
			return event.count_min + maxi(event.count_weights.size() - 1, 0)
	return -1


# --- Ein Spiel --------------------------------------------------------------------------------

## Beginnt das nächste Spiel, mit dem Seed first_seed + games_done. Vor dem ersten Spiel sucht die
## Statistik aus dem Eingriffsprotokoll heraus, was für jeden Seed gilt.
func _start_game() -> void:
	if not _records_chosen:
		_records = _seed_free(interventions)
		_records_chosen = true
	_run = TimelineRun.new(catalog, first_seed + games_done)
	_next_record = 0


## Spielt das laufende Spiel einen Monat weiter, bis zum letzten Tag des Monats nach today. Davor
## wendet es die Eingriffe an, die in diesem Monat geschahen, jeden an seinem at_day und in der
## Reihenfolge des Protokolls, wie WhatIfProbe.build_run() (data-model.md, „Neu abspielen“). Liegt
## at_day schon zurück, etwa −1 vor Spielbeginn, gilt der Eingriff dort, wo das Spiel gerade steht.
func _play_month() -> void:
	var month_end := _month_end_after(_run.today)
	while _next_record < _records.size():
		var record := _records[_next_record]
		var at_day := _at_day(record)
		# Im letzten Monat kommen auch Eingriffe mit einem Tag nach dem 31.12.1999 an die Reihe;
		# das Spiel steht dann am Ende, wie beim Neu abspielen.
		if at_day > month_end and month_end < TimelineRun.LAST_DAY:
			break
		_run.advance_to(at_day)
		# Ob der Lauf einen Eingriff ablehnt, hängt nie am Seed, sondern an Katalog und Tag; eine
		# Ablehnung trifft also jedes Spiel gleich, und der Eingriff gilt nirgends.
		_run.apply_intervention(record)
		_next_record += 1
	_run.advance_to(month_end)


## Zählt das fertige Spiel: je Ereignis die Beginne und das Jahr jedes Beginns.
func _count_game() -> void:
	var starts := PackedInt32Array()
	starts.resize(_statistics.size())
	starts.fill(0)
	for entry in _run.entries:
		if not _has_begun(entry):
			continue
		var index: int = _index.get(entry.event.id, -1)
		if index < 0:
			continue
		starts[index] += 1
		_statistics[index].per_year[_year_of(entry.day)] += 1
	for i in _statistics.size():
		var statistic := _statistics[i]
		var count := starts[i]
		if statistic.games == 0 or count < statistic.minimum:
			statistic.minimum = count
		if statistic.games == 0 or count > statistic.maximum:
			statistic.maximum = count
		statistic.games += 1
		statistic.total += count
		if count == 0:
			statistic.games_without += 1
		if _limits[i] >= 0 and count >= _limits[i]:
			statistic.games_at_max += 1


# --- Hilfen -----------------------------------------------------------------------------------

## Ob ein Termin begonnen hat: Er läuft, ist eingetreten oder beendet. Entfallene und abgesagte
## haben nie begonnen, geplante noch nicht.
static func _has_begun(entry: ScheduleEntry) -> bool:
	return entry.state == ScheduleEntry.State.RUNNING \
		or entry.state == ScheduleEntry.State.OCCURRED \
		or entry.state == ScheduleEntry.State.ENDED


## Die Stelle des Jahres in per_year für einen Tag des Spiels; Stelle 0 ist 1985.
func _year_of(day: int) -> int:
	# bsearch() mit false liefert die Stelle hinter dem letzten Ersten, der nicht nach day liegt.
	var month := _month_starts.bsearch(day, false) - 1
	return clampi(floori(month / 12.0), 0, EventStatistic.YEARS - 1)


## Der letzte Tag des Monats, in dem der Tag nach [param today] liegt: vor Spielbeginn (−1) der
## 31.01.1985, im Dezember 1999 der 31.12.1999.
func _month_end_after(today: int) -> int:
	var month := clampi(_month_starts.bsearch(today + 1, false) - 1, 0, TimelineRun.MONTHS - 1)
	return _month_starts[month + 1] - 1


## Der Erste jedes Monats von Januar 1985 bis Dezember 1999 als Tagesindex, dazu der 01.01.2000.
static func _first_days_of_months() -> PackedInt32Array:
	var days := PackedInt32Array()
	var last_year := EventStatistic.FIRST_YEAR + EventStatistic.YEARS - 1
	for year in range(EventStatistic.FIRST_YEAR, last_year + 1):
		for month in range(1, 13):
			days.append(GameDate.new(year, month, 1).to_day_index())
	days.append(TimelineRun.LAST_DAY + 1)
	return days


## Die Einträge des Eingriffsprotokolls, die für jeden Seed gelten, als Kopien in ihrer
## Reihenfolge (SEED_FREE_KINDS).
static func _seed_free(records: Array[Dictionary]) -> Array[Dictionary]:
	var usable: Array[Dictionary] = []
	for record in records:
		if SEED_FREE_KINDS.has(str(record.get("kind", ""))):
			usable.append(record.duplicate(true))
	return usable


## at_day eines Eintrags als ganze Zahl; aus einer Datei kommt jede Zahl als float. Fehlt der Tag,
## gilt −1, und der Eingriff gilt dort, wo das Spiel gerade steht, wie in WhatIfProbe.build_run().
static func _at_day(record: Dictionary) -> int:
	var value: Variant = record.get("at_day")
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_FLOAT and value == floorf(value) and absf(value) < 1e15:
		return int(value)
	return TimelineRun.FIRST_DAY - 1


static func _copy(statistic: EventStatistic) -> EventStatistic:
	var copy := EventStatistic.new()
	copy.event_id = statistic.event_id
	copy.title = statistic.title
	copy.games = statistic.games
	copy.total = statistic.total
	copy.minimum = statistic.minimum
	copy.maximum = statistic.maximum
	copy.games_without = statistic.games_without
	copy.games_at_max = statistic.games_at_max
	copy.per_year = statistic.per_year.duplicate()
	return copy
