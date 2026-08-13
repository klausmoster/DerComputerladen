extends Node

## Autoload-Singleton: die Ereignis-Engine.
##
## Registriert alle Ereignisse, lauscht auf die Spieluhr und feuert fixe
## Ereignisse an ihrem Datum bzw. würfelt variable Ereignisse monatlich aus.
## Beim Feuern werden die Kettenreaktionen (EventEffect) verteilt – sofort
## oder zeitverzögert – und per `effect_applied` an andere Systeme gemeldet.

signal event_fired(event: TimelineEvent, date: GameDate)
signal effect_applied(effect: EventEffect, source: TimelineEvent, date: GameDate)

var fixed_events: Array[TimelineEvent] = []
var variable_events: Array[TimelineEvent] = []
var history: Array[Dictionary] = []  ## { event, day_index }

var _fixed_by_day: Dictionary = {}    ## day_index -> Array[TimelineEvent]
var _pending_effects: Array[Dictionary] = []  ## { apply_day, effect, source }
var _occurrences: Dictionary = {}     ## event id -> int
var _last_fired_day: Dictionary = {}  ## event id -> day_index
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_load_events()
	GameClock.day_passed.connect(_on_day_passed)
	GameClock.month_passed.connect(_on_month_passed)


func _load_events() -> void:
	for event in EventDatabase.build_fixed_events():
		register_event(event)
	for event in EventDatabase.build_variable_events():
		register_event(event)


func register_event(event: TimelineEvent) -> void:
	if event.is_fixed:
		fixed_events.append(event)
		var idx := event.trigger_day_index()
		if not _fixed_by_day.has(idx):
			_fixed_by_day[idx] = [] as Array[TimelineEvent]
		_fixed_by_day[idx].append(event)
	else:
		variable_events.append(event)


## Bereits ausgelöste Ereignisse bis (einschließlich) `date` – nützlich beim
## Spielstart, um den Markt auf den passenden Stand zu bringen, ohne dass die
## Uhr durch die ganze Vergangenheit ticken muss.
func fast_forward_to(date: GameDate) -> void:
	var target := date.to_day_index()
	for idx: int in _fixed_by_day.keys():
		if idx <= target:
			for event: TimelineEvent in _fixed_by_day[idx]:
				_fire(event, GameDate.from_day_index(idx))


func _on_day_passed(date: GameDate) -> void:
	_apply_due_effects(date)
	var idx := date.to_day_index()
	if _fixed_by_day.has(idx):
		for event: TimelineEvent in _fixed_by_day[idx]:
			_fire(event, date)


func _on_month_passed(date: GameDate) -> void:
	_roll_variable_events(date)


func _roll_variable_events(date: GameDate) -> void:
	var current_day := date.to_day_index()
	for event in variable_events:
		var occ: int = _occurrences.get(event.id, 0)
		var last: int = _last_fired_day.get(event.id, -1)
		if not event.can_occur(date, occ, last, current_day):
			continue
		if _rng.randf() < event.monthly_chance:
			_fire(event, date)


func _fire(event: TimelineEvent, date: GameDate) -> void:
	history.append({"event": event, "day_index": date.to_day_index()})
	_occurrences[event.id] = int(_occurrences.get(event.id, 0)) + 1
	_last_fired_day[event.id] = date.to_day_index()
	event_fired.emit(event, date)

	for effect in event.effects:
		if effect.delay_days <= 0:
			_dispatch_effect(effect, event, date)
		else:
			_pending_effects.append({
				"apply_day": date.to_day_index() + effect.delay_days,
				"effect": effect,
				"source": event,
			})


func _apply_due_effects(date: GameDate) -> void:
	var idx := date.to_day_index()
	var still_pending: Array[Dictionary] = []
	for pending in _pending_effects:
		if pending["apply_day"] <= idx:
			_dispatch_effect(pending["effect"], pending["source"], date)
		else:
			still_pending.append(pending)
	_pending_effects = still_pending


func _dispatch_effect(effect: EventEffect, source: TimelineEvent, date: GameDate) -> void:
	effect_applied.emit(effect, source, date)
	# SPAWN-Effekte lösen ein weiteres registriertes Ereignis aus.
	if effect.kind == EventEffect.Kind.SPAWN and not effect.target.is_empty():
		var spawned := _find_event(effect.target)
		if spawned != null:
			_fire(spawned, date)


func _find_event(event_id: String) -> TimelineEvent:
	for event in fixed_events + variable_events:
		if event.id == event_id:
			return event
	return null
