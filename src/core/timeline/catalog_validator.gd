class_name CatalogValidator
extends RefCounted

## Prüft den Ereigniskatalog nach den Regeln V01 bis V24 aus data-model.md, Tabelle
## „Prüfregeln“; V22 entsteht schon beim Lesen (EventCatalog, CatalogIssue).
##
## Die Werkstatt prüft nach jeder Änderung, das Spiel beim Start und die Tests am echten
## Katalog. Jede Meldung nennt das Ereignis und die Stelle, benannt wie in der Datei, etwa
## `window.from` oder `effects[1].delay_days`; bei Kategorien `categories[2].color` mit leerer
## event_id.
##
## Die meisten Regeln lassen sich an einem Ereignis allein prüfen, das tut validate_event().
## Den ganzen Katalog brauchen nur V02 (doppelte Kennung), V18 und V23 (Kreise aus
## Folgeereignissen) und V21 (Kategorien).
##
## Seit Feature 003 prüft validate_profiles() mit V25 bis V31 die Start-Modifikatoren in den
## Profilen von Leicht und Schwer. Ihre Meldungen haben ein leeres event_id, auch wenn der
## Start-Modifikator auf ein Ereignis zeigt: Ein Fehler im Profil darf kein Ereignis aus dem Spiel
## nehmen (research.md von Feature 003, R8). Die Stelle steht im Feld, etwa
## `profiles.schwer[2].reason`.

## Regeln, die nur warnen; alle anderen sind Fehler.
const WARNING_RULES := ["V13", "V20", "V23", "V31"]
## Die Jahre des Spielzeitraums. Seine Tage, 0 für den 01.01.1985 bis 5477 für den 31.12.1999,
## stehen in TimelineRun.FIRST_DAY und TimelineRun.LAST_DAY.
const FIRST_YEAR := 1985
const LAST_YEAR := 1999
## Jahr ohne 29. Februar, in dem jährliche Tage geprüft und Dauern gezählt werden (V09, V19).
const REFERENCE_YEAR := 1985
## Erlaubte Abweichung der Gewichte von 100 (V11). Drei gleiche Gewichte stehen als 33,33 in der
## Datei und ergeben 99,99; float rechnet das auf 0,0100000000000051 genau, deshalb der Zuschlag.
const WEIGHT_TOLERANCE := 0.01 + 1e-9
## Wirkungsarten, die eine Stärke brauchen (V20). PRESSE ist eine reine Meldung.
const KINDS_WITH_STRENGTH := [
	EventEffect.Kind.PREIS, EventEffect.Kind.NACHFRAGE, EventEffect.Kind.REPUTATION,
	EventEffect.Kind.KUNDENSTROM,
]


## Alle Regeln aus data-model.md außer V22, die beim Lesen entsteht. Reihenfolge der Meldungen:
## Ereignisse nach Kennung, je Ereignis nach Regel; dann die Kategorien; zuletzt die Profile, Leicht
## vor Schwer, je Profil nach Stelle und je Start-Modifikator nach Regel.
static func validate(catalog: EventCatalog) -> Array[CatalogIssue]:
	# Ein Nachschlagewerk Kennung → Ereignisse, einmal gebaut. get_event() in den Schleifen
	# ginge jedes Mal die ganze Liste durch; bei 500 Ereignissen wäre das zu langsam (SC-011).
	var index := _index_by_id(catalog)
	var category_ids := _category_ids(catalog)
	var cycles := _cycle_issues(catalog, index)
	var result: Array[CatalogIssue] = []
	for event in _sorted_by_id(catalog.events):
		var issues := _event_issues(event, index, category_ids)
		var same_id: Array = index[event.id]
		if not event.id.is_empty() and same_id.size() > 1:
			issues.append(_issue("V02", "id", "Die Kennung „%s“ gibt es mehrfach." % event.id))
		if cycles.has(event):
			issues.append_array(cycles[event])
		result.append_array(_finish(issues, event))
	result.append_array(_category_issues(catalog))
	result.append_array(validate_profiles(catalog))
	return result


## Nur die Regeln der Profile, V25 bis V31 (Feature 003, data-model.md, „Prüfregeln“); validate()
## nutzt sie. Leicht vor Schwer, je Profil nach Stelle, je Start-Modifikator nach Regel. Jede
## Meldung hat das Feld wie in der Datei, etwa „profiles.schwer[2].reason“, und im Text den Ort aus
## DifficultyProfile.place() und das volle Feld, wie bei Kategorien.
static func validate_profiles(catalog: EventCatalog) -> Array[CatalogIssue]:
	var index := _index_by_id(catalog)
	var result: Array[CatalogIssue] = []
	for level: int in Difficulty.WITH_PROFILE:
		var profile := catalog.get_profile(level)
		if profile == null:
			continue
		# Kennung → wie oft sie im Profil vorkommt (V30).
		var count := {}
		for modifier in profile.modifiers:
			count[modifier.id] = int(count.get(modifier.id, 0)) + 1
		for i in profile.modifiers.size():
			var modifier := profile.modifiers[i]
			var issues := _start_modifier_issues(modifier, index, count)
			CatalogIssue.prefix_fields(issues, 0, DifficultyProfile.field_prefix(level, i))
			CatalogIssue.locate(issues, 0, DifficultyProfile.place(level, i, modifier))
			result.append_array(issues)
	return result


## Nur die Regeln, die ein Ereignis für sich prüfen lassen (alle außer V02, V18, V21, V23); für
## die Vorschau beim Ziehen (R16). validate() nutzt sie je Ereignis.
static func validate_event(catalog: EventCatalog, event: TimelineEvent) -> Array[CatalogIssue]:
	var issues := _event_issues(event, _index_by_id(catalog), _category_ids(catalog))
	return _finish(issues, event)


static func has_errors(issues: Array[CatalogIssue]) -> bool:
	for issue in issues:
		if issue.severity == CatalogIssue.Severity.ERROR:
			return true
	return false


# --- Regeln je Ereignis -------------------------------------------------------

## Die Meldungen eines Ereignisses, noch ohne Ort im Text; den setzt _finish().
static func _event_issues(event: TimelineEvent, index: Dictionary,
		category_ids: Dictionary) -> Array[CatalogIssue]:
	var issues: Array[CatalogIssue] = []
	_check_texts(event, category_ids, issues)
	match event.kind:
		TimelineEvent.Kind.FIXED:
			_check_day(event.date, "date", "Das Datum", issues)
		TimelineEvent.Kind.YEARLY:
			_check_yearly(event, issues)
		TimelineEvent.Kind.PRESET:
			_check_window(event, issues)
			_check_preset(event, issues)
		TimelineEvent.Kind.CHANCE:
			_check_window(event, issues)
			_check_chance(event, issues)
	_check_numbers(event, issues)
	_check_effects(event, issues)
	_check_follow_ups(event, index, issues)
	_check_conditions(event, index, issues)
	return issues


## V01, V03 Kennung; V04 Titel; V05 Kategorie.
static func _check_texts(event: TimelineEvent, category_ids: Dictionary,
		issues: Array[CatalogIssue]) -> void:
	if event.id.is_empty():
		issues.append(_issue("V01", "id", "Die Kennung ist leer."))
	elif not _is_id(event.id):
		issues.append(_issue("V03", "id",
			"Die Kennung „%s“ enthält andere Zeichen als a–z, 0–9 und _." % event.id))
	if event.title.strip_edges().is_empty():
		issues.append(_issue("V04", "title", "Der Titel ist leer."))
	if event.category.is_empty():
		issues.append(_issue("V05", "category", "Die Kategorie fehlt."))
	elif not category_ids.has(event.category):
		issues.append(_issue("V05", "category",
			"Die Kategorie „%s“ gibt es nicht." % event.category))


## V06: ein Tag im Spielzeitraum.
static func _check_day(day: int, p_field: String, what: String,
		issues: Array[CatalogIssue]) -> void:
	if day < TimelineRun.FIRST_DAY or day > TimelineRun.LAST_DAY:
		issues.append(_issue("V06", p_field,
			"%s %s liegt außerhalb von 01.01.1985 bis 31.12.1999." % [what, _date(day)]))


## V06 und V07: Zeitfenster gesetzter Ereignisse und solcher über Wahrscheinlichkeit.
static func _check_window(event: TimelineEvent, issues: Array[CatalogIssue]) -> void:
	_check_day(event.window_from, "window.from", "Der Beginn des Zeitfensters", issues)
	_check_day(event.window_to, "window.to", "Das Ende des Zeitfensters", issues)
	if event.window_to < event.window_from:
		issues.append(_issue("V07", "window.to",
			"Das Zeitfenster endet am %s, vor seinem Beginn am %s."
			% [_date(event.window_to), _date(event.window_from)]))


## V08 Jahre und V09 Tage im Jahr jährlicher Ereignisse.
static func _check_yearly(event: TimelineEvent, issues: Array[CatalogIssue]) -> void:
	for pair: Array in [["yearly.from", event.yearly_from], ["yearly.to", event.yearly_to]]:
		var year: int = pair[1]
		if year < FIRST_YEAR or year > LAST_YEAR:
			issues.append(_issue("V08", pair[0],
				"Das Jahr %d liegt außerhalb von 1985 bis 1999." % year))
	if event.yearly_from > event.yearly_to:
		issues.append(_issue("V08", "yearly.to", "Die Jahre enden %d, vor ihrem Beginn %d."
			% [event.yearly_to, event.yearly_from]))
	var start_problem := _day_of_year_problem(event.yearly_start, true)
	if not start_problem.is_empty():
		issues.append(_issue("V09", "yearly.start", start_problem))
	var end_problem := _day_of_year_problem(event.yearly_end, false)
	if not end_problem.is_empty():
		issues.append(_issue("V09", "yearly.end", end_problem))


## Warum (Monat, Tag) kein erlaubter Beginn bzw. kein erlaubtes Ende ist; leer, wenn alles
## stimmt. Als Ende sind auch „Monatsende“ (Tag 0) und „ohne Dauer“ (0, 0) erlaubt, als Beginn
## nicht.
static func _day_of_year_problem(value: Vector2i, is_start: bool) -> String:
	if not is_start and (value == Vector2i.ZERO or _is_month_end(value)):
		return ""
	if _is_day_of_year(value):
		return ""
	var what := "Der Beginn" if is_start else "Das Ende"
	if value == Vector2i(2, 29) and is_start:
		return "Den 29.02. gibt es nicht in jedem Jahr."
	if value == Vector2i(2, 29):
		return ("Den 29.02. gibt es nicht in jedem Jahr; für das Ende des Februars nimm "
			+ "„Monatsende“.")
	if value == Vector2i.ZERO:
		return "%s fehlt." % what
	if _is_month_end(value):
		return "%s kann nicht „Monatsende“ sein." % what
	return "%s %02d-%02d ist kein Tag im Jahr." % [what, value.x, value.y]


## V10, V11 und V24 für Ereignisse „beim Start gesetzt“.
static func _check_preset(event: TimelineEvent, issues: Array[CatalogIssue]) -> void:
	# Höchste Anzahl k: count_min ist die kleinste, jedes Gewicht steht für eine Anzahl mehr.
	var k := event.count_min + event.count_weights.size() - 1
	var span := event.window_to - event.window_from
	var needed := (k - 1) * event.min_gap_days
	if k >= 2 and span < needed:
		issues.append(_issue("V10", "count_weights", ("Bis zu %d Termine mit %d Tagen Abstand "
			+ "brauchen vom ersten bis zum letzten %d Tage, das Zeitfenster reicht nur über %d.")
			% [k, event.min_gap_days, needed, span]))
	var total := 0.0
	var negative := false
	for weight in event.count_weights:
		total += weight
		negative = negative or weight < 0.0
	if negative:
		issues.append(_issue("V11", "count_weights", "Ein Gewicht ist negativ."))
	if absf(total - 100.0) > WEIGHT_TOLERANCE:
		issues.append(_issue("V11", "count_weights",
			"Die Gewichte ergeben zusammen %s statt 100." % _decimal(total)))
	# Ohne Dauer kann sich nichts überlappen; ein negativer Abstand ist dann V14.
	if k >= 2 and event.duration_days > 0 and event.min_gap_days < event.duration_days:
		issues.append(_issue("V24", "min_gap_days", ("Der Mindestabstand von %d Tagen ist kürzer "
			+ "als die Dauer von %d Tagen; gesetzte Termine würden sich überlappen.")
			% [event.min_gap_days, event.duration_days]))


## V12 und V13 für Ereignisse über Wahrscheinlichkeit.
static func _check_chance(event: TimelineEvent, issues: Array[CatalogIssue]) -> void:
	if event.monthly_chance < 0.0 or event.monthly_chance > 1.0:
		issues.append(_issue("V12", "monthly_chance", "Die Grundchance von %s liegt außerhalb "
			% _percent(event.monthly_chance) + "von 0 % bis 100 %."))
	elif event.monthly_chance == 0.0:
		issues.append(_issue("V13", "monthly_chance",
			"Die Grundchance ist 0 %; ohne Modifikator tritt das Ereignis nie ein."))


## V14 für die Zahlen des Ereignisses selbst; Wirkungen und Folgeereignisse prüfen ihre eigenen.
static func _check_numbers(event: TimelineEvent, issues: Array[CatalogIssue]) -> void:
	var kind := event.kind
	if kind != TimelineEvent.Kind.YEARLY and event.duration_days < 0:
		issues.append(_issue("V14", "duration_days",
			"Die Dauer von %d Tagen ist negativ." % event.duration_days))
	if kind == TimelineEvent.Kind.PRESET and event.count_min < 0:
		issues.append(_issue("V14", "count_min",
			"Die kleinste Anzahl %d ist negativ." % event.count_min))
	if (kind == TimelineEvent.Kind.PRESET or kind == TimelineEvent.Kind.CHANCE) \
			and event.min_gap_days < 0:
		issues.append(_issue("V14", "min_gap_days",
			"Der Mindestabstand von %d Tagen ist negativ." % event.min_gap_days))
	if kind == TimelineEvent.Kind.CHANCE and event.max_occurrences < 0:
		issues.append(_issue("V14", "max_occurrences",
			"Die Höchstzahl %d ist negativ." % event.max_occurrences))


## V14 Verzögerung, V19 Wirkung nach dem Ende, V20 Stärke 0.
static func _check_effects(event: TimelineEvent, issues: Array[CatalogIssue]) -> void:
	var duration := _duration(event)
	for i in event.effects.size():
		var effect := event.effects[i]
		var prefix := "effects[%d]." % i
		if effect.delay_days < 0:
			issues.append(_issue("V14", prefix + "delay_days",
				"Die Verzögerung von %d Tagen ist negativ." % effect.delay_days))
		if effect.scope == EventEffect.Scope.DURING and duration > 0 \
				and effect.delay_days >= duration:
			issues.append(_issue("V19", prefix + "delay_days", ("Die Wirkung gilt nur während des "
				+ "Ereignisses, beginnt aber erst nach %d Tagen; das Ereignis dauert %d Tage.")
				% [effect.delay_days, duration]))
		if KINDS_WITH_STRENGTH.has(effect.kind) and effect.magnitude == 0.0:
			issues.append(_issue("V20", prefix + "magnitude",
				"Die Wirkung hat die Stärke 0 und bewirkt nichts."))


## V12 Wahrscheinlichkeit, V14 Verzögerung, V15 unbekanntes Ziel, V16 Ziel fix oder jährlich.
static func _check_follow_ups(event: TimelineEvent, index: Dictionary,
		issues: Array[CatalogIssue]) -> void:
	for i in event.follow_ups.size():
		var follow_up := event.follow_ups[i]
		var prefix := "follow_ups[%d]." % i
		if follow_up.chance < 0.0 or follow_up.chance > 1.0:
			issues.append(_issue("V12", prefix + "chance", "Die Wahrscheinlichkeit von %s liegt "
				% _percent(follow_up.chance) + "außerhalb von 0 % bis 100 %."))
		if follow_up.delay_min < 0:
			issues.append(_issue("V14", prefix + "delay_min",
				"Die Verzögerung von %d Tagen ist negativ." % follow_up.delay_min))
		if follow_up.delay_max < 0:
			issues.append(_issue("V14", prefix + "delay_max",
				"Die Verzögerung von %d Tagen ist negativ." % follow_up.delay_max))
		if follow_up.delay_min > follow_up.delay_max:
			issues.append(_issue("V14", prefix + "delay_max",
				"Die Verzögerung reicht von %d bis %d Tagen; „bis“ liegt vor „von“."
				% [follow_up.delay_min, follow_up.delay_max]))
		if follow_up.target.is_empty():
			issues.append(_issue("V15", prefix + "target", "Das Folgeereignis fehlt."))
		elif not index.has(follow_up.target):
			issues.append(_issue("V15", prefix + "target",
				"Das Folgeereignis „%s“ gibt es nicht." % follow_up.target))
		elif _is_fixed_or_yearly(index[follow_up.target]):
			issues.append(_issue("V16", prefix + "target", ("„%s“ ist fix oder jährlich und käme "
				+ "sonst an seinem Datum und zusätzlich als Folge.") % follow_up.target))


## V17 Bedingungen an fixen und jährlichen Ereignissen, sonst V15: Die Bedingung nennt kein
## Ereignis, das Ereignis selbst oder eines, das es nicht gibt. Auf sich selbst zeigen darf sie
## nicht (data-model.md, EventCondition; FR-006): „schon eingetreten“ hielte das Ereignis für immer
## zurück, „noch nicht eingetreten“ ließe es nur einmal zu. Die Werkstatt bietet das gar nicht an;
## es kann nur in einer Datei stehen, die jemand von Hand geändert hat.
static func _check_conditions(event: TimelineEvent, index: Dictionary,
		issues: Array[CatalogIssue]) -> void:
	if event.kind == TimelineEvent.Kind.FIXED or event.kind == TimelineEvent.Kind.YEARLY:
		# Eine leere Liste ist kein Fehler; sie fällt beim Speichern ohnehin weg.
		if not event.conditions.is_empty():
			issues.append(_issue("V17", "conditions", ("Fixe und jährliche Ereignisse haben keine "
				+ "Bedingungen; beim Speichern fallen sie weg.")))
		return
	for i in event.conditions.size():
		var condition := event.conditions[i]
		var p_field := "conditions[%d].event" % i
		if condition.event.is_empty():
			issues.append(_issue("V15", p_field, "Die Bedingung nennt kein Ereignis."))
		elif condition.event == event.id:
			issues.append(_issue("V15", p_field,
				"Die Bedingung verweist auf das Ereignis selbst; nimm ein anderes."))
		elif not index.has(condition.event):
			issues.append(_issue("V15", p_field,
				"Die Bedingung verweist auf „%s“, das es nicht gibt." % condition.event))


# --- Regeln über den ganzen Katalog ---------------------------------------------

## V18 und V23: Kreise aus Folgeereignissen mit 100 %, nach Ereignis. Bedingungen spielen dafür
## keine Rolle (data-model.md).
##
## Die Folgeereignisse bilden einen Graphen: Jedes Ereignis ist ein Knoten, jedes Folgeereignis
## mit chance ≥ 1.0 ein Pfeil zu seinem Ziel. Ein Pfeil von A nach B liegt genau dann auf einem
## Kreis, wenn man von B aus über weitere Pfeile wieder zu A kommt.
## - V18: Der Kreis kommt mit Pfeilen ohne Verzögerung (delay_max = 0) aus; am selben Tag liefe
##   er endlos.
## - V23: Zum Kreis gehört ein Pfeil mit Verzögerung; die Kette läuft bis Spielende weiter.
static func _cycle_issues(catalog: EventCatalog, index: Dictionary) -> Dictionary:
	var all_arrows := {}       # Kennung → Ziele aller Pfeile mit 100 %
	var instant_arrows := {}   # Kennung → Ziele der Pfeile ohne Verzögerung
	var delayed_arrows := []   # [von, nach] der Pfeile mit Verzögerung
	for event in catalog.events:
		for follow_up in event.follow_ups:
			if follow_up.chance < 1.0 or not index.has(follow_up.target):
				continue
			_add_arrow(all_arrows, event.id, follow_up.target)
			if follow_up.delay_max == 0:
				_add_arrow(instant_arrows, event.id, follow_up.target)
			else:
				delayed_arrows.append([event.id, follow_up.target])
	var result := {}
	if all_arrows.is_empty():
		return result
	# Wer von wo aus erreichbar ist, rechnet _reachable() je Knoten nur einmal aus.
	var reach_all := {}
	var reach_instant := {}
	for event in catalog.events:
		for i in event.follow_ups.size():
			var follow_up := event.follow_ups[i]
			if follow_up.chance < 1.0 or not index.has(follow_up.target):
				continue
			var issues: Array[CatalogIssue] = []
			var p_field := "follow_ups[%d].target" % i
			var target := follow_up.target
			if follow_up.delay_max == 0 \
					and _on_cycle(instant_arrows, reach_instant, event.id, target):
				issues.append(_issue("V18", p_field, ("Die Folge auf „%s“ führt mit 100 %% und "
					+ "ohne Verzögerung im Kreis zurück; am selben Tag liefe die Kette endlos.")
					% target))
			if _on_cycle(all_arrows, reach_all, event.id, target) \
					and _cycle_has_delay(all_arrows, reach_all, delayed_arrows, event.id):
				issues.append(_issue("V23", p_field, ("Die Folge auf „%s“ führt mit 100 %% im "
					+ "Kreis zurück; die Kette läuft bis Spielende weiter.") % target))
			if not issues.is_empty():
				if not result.has(event):
					var list: Array[CatalogIssue] = []
					result[event] = list
				result[event].append_array(issues)
	return result


static func _add_arrow(arrows: Dictionary, from: String, to: String) -> void:
	if not arrows.has(from):
		arrows[from] = []
	arrows[from].append(to)


## Ob der Pfeil von [param from] nach [param to] auf einem Kreis liegt: Er zeigt auf sich selbst,
## oder von [param to] aus führt ein Weg zurück zu [param from].
static func _on_cycle(arrows: Dictionary, cache: Dictionary, from: String, to: String) -> bool:
	return from == to or _reachable(arrows, cache, to).has(from)


## Alle Kennungen, die von [param start] aus über einen oder mehrere Pfeile erreichbar sind. Die
## Suche hält die noch offenen Knoten in einer Liste und folgt von jedem allen Pfeilen; wer schon
## erreicht ist, wird übersprungen. Das Ergebnis bleibt je Start in [param cache].
static func _reachable(arrows: Dictionary, cache: Dictionary, start: String) -> Dictionary:
	if cache.has(start):
		return cache[start]
	var reached := {}
	var queue: Array = arrows.get(start, []).duplicate()
	while not queue.is_empty():
		var id: String = queue.pop_back()
		if reached.has(id):
			continue
		reached[id] = true
		queue.append_array(arrows.get(id, []))
	cache[start] = reached
	return reached


## Ob zum Kreis um [param id] ein Pfeil mit Verzögerung gehört. Zum Kreis gehört jeder Knoten,
## der von [param id] aus erreichbar ist und von dem aus [param id] erreichbar ist; ein Pfeil
## gehört dazu, wenn beide Enden dazugehören.
static func _cycle_has_delay(arrows: Dictionary, cache: Dictionary, delayed_arrows: Array,
		id: String) -> bool:
	var from_here := _reachable(arrows, cache, id)
	for arrow: Array in delayed_arrows:
		var both_inside := true
		for end: String in arrow:
			var back := _reachable(arrows, cache, end)
			var inside := end == id or (from_here.has(end) and back.has(id))
			both_inside = both_inside and inside
		if both_inside:
			return true
	return false


## V21: Kennung leer, mit anderen Zeichen als a–z, 0–9 und _ oder doppelt; Farbe nicht unter den
## Kategorienfarben. Die Zeichen prüft dieselbe Regel wie bei Ereignissen (V03). Die Werkstatt
## bildet Kennungen von Kategorien selbst aus dem Namen; „Konkurrenz“ mit großem K kann nur in
## einer Datei stehen, die jemand von Hand geändert hat.
static func _category_issues(catalog: EventCatalog) -> Array[CatalogIssue]:
	var count := {}
	for category in catalog.categories:
		count[category.id] = int(count.get(category.id, 0)) + 1
	var result: Array[CatalogIssue] = []
	for i in catalog.categories.size():
		var category := catalog.categories[i]
		var prefix := "categories[%d]." % i
		var issues: Array[CatalogIssue] = []
		if category.id.is_empty():
			issues.append(_issue("V21", prefix + "id", "Die Kennung ist leer."))
		elif not _is_id(category.id):
			issues.append(_issue("V21", prefix + "id",
				"Die Kennung „%s“ enthält andere Zeichen als a–z, 0–9 und _." % category.id))
		elif int(count[category.id]) > 1:
			issues.append(_issue("V21", prefix + "id",
				"Die Kennung „%s“ haben mehrere Kategorien." % category.id))
		if category.color.is_empty():
			issues.append(_issue("V21", prefix + "color", "Die Farbe fehlt."))
		elif not UiPalette.CATEGORY_TOKENS.has(category.color):
			issues.append(_issue("V21", prefix + "color",
				"„%s“ ist keine Kategorienfarbe aus dem Style-Guide." % category.color))
		CatalogIssue.locate(issues, 0, _category_place(category))
		result.append_array(issues)
	return result


# --- Regeln der Profile (Feature 003) ---------------------------------------------

## V25 bis V31 für einen Start-Modifikator, nach Regel, noch ohne Stelle und Ort; die setzt
## validate_profiles(). [param index] ist Kennung → Ereignisse, [param count] Kennung → wie oft sie
## im Profil vorkommt.
static func _start_modifier_issues(modifier: ChanceModifier, index: Dictionary,
		count: Dictionary) -> Array[CatalogIssue]:
	var issues: Array[CatalogIssue] = []
	_check_target(modifier, index, issues)
	var period_ok := _check_period(modifier, issues)
	if modifier.reason.strip_edges().is_empty():
		issues.append(_issue("V29", "reason", "Der Grund ist leer."))
	if modifier.id.is_empty():
		issues.append(_issue("V30", "id", "Die Kennung ist leer."))
	elif not _is_id(modifier.id):
		issues.append(_issue("V30", "id",
			"Die Kennung „%s“ enthält andere Zeichen als a–z, 0–9 und _." % modifier.id))
	elif int(count[modifier.id]) > 1:
		issues.append(_issue("V30", "id",
			"Die Kennung „%s“ gibt es in diesem Profil mehrfach." % modifier.id))
	# Ein Zeitraum, der umgedreht ist oder aus dem Spiel ragt, hat keine sinnvollen Würfelrunden.
	if period_ok:
		_check_rounds(modifier, issues)
	return issues


## V25: Das Ereignis fehlt oder ist unbekannt. V26: Es kommt nicht über Wahrscheinlichkeit; dann
## hat seine Chance nichts, was ein Start-Modifikator verschieben könnte (FR-003).
static func _check_target(modifier: ChanceModifier, index: Dictionary,
		issues: Array[CatalogIssue]) -> void:
	if modifier.event_id.is_empty():
		issues.append(_issue("V25", "event_id", "Der Start-Modifikator nennt kein Ereignis."))
		return
	if not index.has(modifier.event_id):
		issues.append(_issue("V25", "event_id",
			"Das Ereignis „%s“ gibt es im Katalog nicht." % modifier.event_id))
		return
	var other := _not_by_chance(index[modifier.event_id])
	if other != null:
		issues.append(_issue("V26", "event_id", ("„%s“ hat die Art „%s“; Start-Modifikatoren "
			+ "gehören nur zu Ereignissen über Wahrscheinlichkeit.")
			% [modifier.event_id, other.kind_label()]))


## V27: Ende vor dem Beginn. V28: Beginn oder Ende außerhalb des Spiels. Gibt zurück, ob der
## Zeitraum beide Regeln besteht.
static func _check_period(modifier: ChanceModifier, issues: Array[CatalogIssue]) -> bool:
	var before := issues.size()
	if modifier.to_day < modifier.from_day:
		issues.append(_issue("V27", "to_day",
			"Der Start-Modifikator endet am %s, vor seinem Beginn am %s."
			% [_date(modifier.to_day), _date(modifier.from_day)]))
	for pair: Array in [["from_day", modifier.from_day, "Der Beginn"],
			["to_day", modifier.to_day, "Das Ende"]]:
		var day: int = pair[1]
		if day < TimelineRun.FIRST_DAY or day > TimelineRun.LAST_DAY:
			issues.append(_issue("V28", pair[0],
				"%s %s liegt außerhalb von 01.01.1985 bis 31.12.1999." % [pair[2], _date(day)]))
	return issues.size() == before


## V31: Gewürfelt wird am Monatsersten (FR-007). Ein Beginn mitten im Monat wirkt erst ab der
## nächsten Würfelrunde, ein Ende mitten im Monat noch in der Würfelrunde seines Monats. Die Warnung
## nennt diese Würfelrunde, an from_day bzw. to_day. Liegt im Zeitraum gar kein Monatserster, gibt
## es nur eine Warnung, an from_day: Er wirkt nie (research.md von Feature 003, R8).
static func _check_rounds(modifier: ChanceModifier, issues: Array[CatalogIssue]) -> void:
	var first_round := _first_round_from(modifier.from_day)
	if first_round > modifier.to_day:
		issues.append(_issue("V31", "from_day", ("Zwischen %s und %s liegt keine Würfelrunde; der "
			+ "Start-Modifikator wirkt nie.") % [_date(modifier.from_day), _date(modifier.to_day)]))
		return
	if first_round != modifier.from_day:
		issues.append(_issue("V31", "from_day", ("Der Beginn %s ist kein Monatserster; der "
			+ "Start-Modifikator wirkt ab der Würfelrunde am %s.")
			% [_date(modifier.from_day), _date(first_round)]))
	var end := GameDate.from_day_index(modifier.to_day)
	if end.day != GameDate.days_in_month(end.year, end.month):
		var last_round := modifier.to_day - end.day + 1
		issues.append(_issue("V31", "to_day", ("Das Ende %s ist kein Monatsletzter; der "
			+ "Start-Modifikator wirkt noch in der Würfelrunde am %s.")
			% [_date(modifier.to_day), _date(last_round)]))


## Der erste Monatserste ab [param day]: day selbst, wenn er einer ist, sonst der Erste des
## nächsten Monats.
static func _first_round_from(day: int) -> int:
	var date := GameDate.from_day_index(day)
	if date.day == 1:
		return day
	return day + GameDate.days_in_month(date.year, date.month) - date.day + 1


## Das erste der Ereignisse mit einer Kennung, das nicht über Wahrscheinlichkeit kommt; null, wenn
## alle es tun. Mehrere mit derselben Kennung meldet schon V02.
static func _not_by_chance(events: Array) -> TimelineEvent:
	for event: TimelineEvent in events:
		if event.kind != TimelineEvent.Kind.CHANCE:
			return event
	return null


# --- Hilfen ---------------------------------------------------------------------

## Neue Meldung ohne Ort; Fehler oder Warnung je nach Regel.
static func _issue(rule: String, p_field: String, reason: String) -> CatalogIssue:
	var severity := CatalogIssue.Severity.ERROR
	if WARNING_RULES.has(rule):
		severity = CatalogIssue.Severity.WARNING
	return CatalogIssue.new(severity, rule, "", p_field, reason)


## Sortiert die Meldungen eines Ereignisses nach Regel und setzt Ereignis und Ort in den Text.
static func _finish(issues: Array[CatalogIssue], event: TimelineEvent) -> Array[CatalogIssue]:
	# Nach Regel gruppieren statt sort_custom(): So bleibt die Reihenfolge innerhalb einer
	# Regel, wie sie gefunden wurde, etwa effects[0] vor effects[1].
	var by_rule := {}
	for issue in issues:
		if not by_rule.has(issue.rule):
			by_rule[issue.rule] = []
		by_rule[issue.rule].append(issue)
	var rules := by_rule.keys()
	rules.sort()
	var sorted: Array[CatalogIssue] = []
	for rule: String in rules:
		for issue: CatalogIssue in by_rule[rule]:
			sorted.append(issue)
	CatalogIssue.locate(sorted, 0, _place(event), event.id)
	return sorted


## Kennung → alle Ereignisse mit dieser Kennung; mehrere heißt V02.
static func _index_by_id(catalog: EventCatalog) -> Dictionary:
	var index := {}
	for event in catalog.events:
		if not index.has(event.id):
			index[event.id] = []
		index[event.id].append(event)
	return index


static func _category_ids(catalog: EventCatalog) -> Dictionary:
	var ids := {}
	for category in catalog.categories:
		ids[category.id] = true
	return ids


## Die Ereignisse nach Kennung, bei gleicher Kennung in ihrer Reihenfolge im Katalog; wie
## EventCatalog beim Schreiben.
static func _sorted_by_id(events: Array[TimelineEvent]) -> Array[TimelineEvent]:
	var position := {}
	for i in events.size():
		position[events[i]] = i
	var by_id := func(a: TimelineEvent, b: TimelineEvent) -> bool:
		if a.id != b.id:
			return a.id < b.id
		return position[a] < position[b]
	var sorted: Array[TimelineEvent] = events.duplicate()
	sorted.sort_custom(by_id)
	return sorted


static func _is_fixed_or_yearly(events: Array) -> bool:
	for event: TimelineEvent in events:
		if event.kind == TimelineEvent.Kind.FIXED or event.kind == TimelineEvent.Kind.YEARLY:
			return true
	return false


## Ob die Kennung nur aus a–z, 0–9 und _ besteht.
static func _is_id(text: String) -> bool:
	for i in text.length():
		var c := text[i]
		if not ((c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_"):
			return false
	return true


## Ob (Monat, Tag) ein Tag in einem Jahr ohne 29. Februar ist.
static func _is_day_of_year(value: Vector2i) -> bool:
	return GameDate.is_valid(REFERENCE_YEAR, value.x, value.y)


## (Monat, 0) heißt Monatsende.
static func _is_month_end(value: Vector2i) -> bool:
	return value.y == 0 and value.x >= 1 and value.x <= 12


## Dauer in Tagen; 0 ohne Dauer. Bei jährlichen Ereignissen die Dauer eines Vorkommens in einem
## Jahr ohne 29. Februar (V19); endet es vor seinem Beginn im Jahr, reicht es ins nächste Jahr.
static func _duration(event: TimelineEvent) -> int:
	if event.kind != TimelineEvent.Kind.YEARLY:
		return maxi(event.duration_days, 0)
	var start := event.yearly_start
	var end := event.yearly_end
	if end == Vector2i.ZERO or not _is_day_of_year(start):
		return 0
	if not (_is_month_end(end) or _is_day_of_year(end)):
		return 0
	var last_day_of_month := end.y if end.y > 0 else GameDate.days_in_month(REFERENCE_YEAR, end.x)
	var last := Vector2i(end.x, last_day_of_month)
	var end_year := REFERENCE_YEAR if last >= start else REFERENCE_YEAR + 1
	var first_day := GameDate.new(REFERENCE_YEAR, start.x, start.y).to_day_index()
	var last_day := GameDate.new(end_year, last.x, last.y).to_day_index()
	return last_day - first_day + 1


## Das Ereignis in Meldungen, wie bei den Meldungen beim Lesen (TimelineEvent).
static func _place(event: TimelineEvent) -> String:
	if not event.id.is_empty():
		return "Ereignis „%s“" % event.id
	if not event.title.is_empty():
		return "Ereignis „%s“ ohne Kennung" % event.title
	return "Ereignis ohne Kennung"


## Die Kategorie in Meldungen, wie bei den Meldungen beim Lesen (EventCategory).
static func _category_place(category: EventCategory) -> String:
	if not category.id.is_empty():
		return "Kategorie „%s“" % category.id
	if not category.name.is_empty():
		return "Kategorie „%s“ ohne Kennung" % category.name
	return "Kategorie ohne Kennung"


## Tag als „TT.MM.JJJJ“.
static func _date(day: int) -> String:
	return str(GameDate.from_day_index(day))


## Zahl mit deutschem Komma und höchstens zwei Nachkommastellen, etwa „99,99“ oder „100“.
static func _decimal(value: float) -> String:
	var text := "%.2f" % value
	text = text.rstrip("0").rstrip(".")
	return text.replace(".", ",")


## Anteil als Prozent, etwa 0.03 als „3 %“.
static func _percent(share: float) -> String:
	return "%s %%" % _decimal(share * 100.0)
