extends GutTest

## SC-003 im Kern (Feature 004, T009; research.md, R16; FR-008, FR-022): Ein Spiel, das am
## 14.03.1986 als Datei gespeichert, wieder gelesen und weitergespielt wird, meldet ab dem
## 15.03.1986 Zeile für Zeile dasselbe wie ein Spiel ohne Pause. Geprüft für die Seeds 1, 4711 und
## 99999 in allen drei Graden, ohne Eingriffe und mit Eingriffen vor und nach dem 14.03.1986.
##
## Der Weg ist der des Spiels ohne Autoloads: Der Lauf bis zum 14.03.1986 wird ein SaveGame, das
## SaveStore schreibt und SaveSlot.read() aus der Datei liest. Aus dem Gelesenen entsteht ein neuer
## Lauf, replay() spielt das Eingriffsprotokoll nach und still bis zum Spieldatum, danach geht es
## weiter bis zum 31.12.1999. Dasselbe über Uhr und Signale prüft Phase 3 (T013).
##
## Katalog ist catalog_alle_arten mit allen Arten von Ereignissen. Drei davon stehen in Kategorien,
## die es im Katalog nicht gibt (V05). Ein geprüfter Katalog behielte nur das fixe und das jährliche
## Ereignis, und ohne Würfel bewiese der Vergleich wenig. Für SC-003 laufen beide Seiten deshalb
## mit dem Katalog, wie er gelesen ist; Prüfen und Weglassen beim Fortsetzen ist Sache der
## Zeitleiste. Genau diese drei Ereignisse nimmt der Test zur Kopie mit fehlerhaften Ereignissen.

const ORDNER := "user://test_save_resume_run/"
const KATALOG := "res://test/fixtures/catalog_alle_arten.json"
const ANDERER_KATALOG := "res://test/fixtures/catalog_us1_grade.json"
const SEEDS: Array[int] = [1, 4711, 99999]
const GRADE: Array[Difficulty.Level] = [Difficulty.Level.LEICHT, Difficulty.Level.MITTEL,
	Difficulty.Level.SCHWER]
const LETZTER_TAG := TimelineRun.LAST_DAY
## 26.10.2026, 20:40:12 UTC
const ANGELEGT := 1793047212

## Die Nummer des nächsten Spielstands im Testordner.
var _nummer := 0


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)


func after_each() -> void:
	_raeume_auf(ORDNER)


# --- SC-003 -----------------------------------------------------------------------------------

func test_sc_003_fortgesetzt_am_14_03_1986_wie_ohne_pause() -> void:
	var leer: Array = []
	_vergleiche_alle_faelle(leer, leer)


func test_sc_003_mit_eingriffen_vor_und_nach_dem_14_03_1986() -> void:
	# Arrange: Eingriffe vor Spielbeginn, im Lauf, am 14.03.1986 selbst und nach dem Fortsetzen;
	# Absagen und Verschiebungen treffen den jeweils nächsten Termin, den man absagen kann.
	var gezaehlt := _vergleiche_alle_faelle(_schritte_vor(), _schritte_nach())

	# Assert: Die dynamischen Eingriffe haben in den neun Spielen wirklich etwas getroffen.
	assert_gt(gezaehlt["vor"], 0, "Vor dem 14.03.1986 wurde etwas abgesagt oder verschoben.")
	assert_gt(gezaehlt["nach"], 0, "Nach dem 14.03.1986 wurde etwas abgesagt oder verschoben.")


func test_kopie_mit_fehlerhaften_ereignissen_laeuft_ohne_diese_weiter() -> void:
	# Arrange: Das Spiel lief mit einem Katalog, dessen Ereignisse später als fehlerhaft gelten;
	# hier stehen drei in Kategorien, die es nicht gibt. Seine Eingriffe treffen sie.
	var gespielt := TimelineRun.new(_katalog(), 4711, Difficulty.Level.SCHWER)
	_spiele(gespielt, _schritte_vor(), _pause())
	var slot := _speichere_und_lies(gespielt)
	if slot == null:
		return
	assert_eq(slot.game.catalog.events.size(), 5, "Die Kopie im Spielstand hat alle fünf.")

	# Act: fortsetzen wie die Zeitleiste, mit geprüfter Kopie ohne die fehlerhaften Ereignisse
	var issues := CatalogValidator.validate(slot.game.catalog)
	var geprueft := slot.game.catalog.without_faulty(issues)
	var weiter := TimelineRun.new(geprueft, slot.game.seed, slot.game.difficulty)
	var abgelehnt := weiter.replay(slot.game.interventions, slot.game.day)
	weiter.advance_to(LETZTER_TAG)

	# Assert
	assert_eq(_kennungen(geprueft), ["intel_pentium", "weihnachtsgeschaeft"])
	assert_eq(abgelehnt.size(), slot.game.interventions.size(),
		"Jeder Eingriff traf ein ausgenommenes Ereignis.")
	for eintrag in abgelehnt:
		assert_string_contains(eintrag["reason"], "gibt es im Katalog nicht.")
	assert_true(weiter.is_finished(), "Das Spiel läuft bis zum 31.12.1999 weiter.")
	var ohne := TimelineRun.new(geprueft, 4711, Difficulty.Level.SCHWER)
	ohne.advance_to(LETZTER_TAG)
	var zeilen := _zeilen_ab(weiter, _pause() + 1)
	assert_eq(zeilen, _zeilen_ab(ohne, _pause() + 1),
		"Dasselbe wie ein Spiel, das von Anfang an ohne sie lief.")
	assert_gt(zeilen.size(), 0)
	for zeile in zeilen:
		for titel: String in ["Reklamation", "Neubaugebiet", "Zeitungsartikel"]:
			assert_false(zeile.contains(titel), "Ohne „%s“: %s" % [titel, zeile])


func test_spielstand_laeuft_mit_seinem_katalog_auch_wenn_der_aktuelle_ein_anderer_ist() -> void:
	# Arrange (FR-022; Analyse, E1): gespeichert mit dem Katalog aller Arten; der Katalog der
	# Zeitleiste ist inzwischen ein anderer.
	var gespielt := TimelineRun.new(_katalog(), 4711, Difficulty.Level.SCHWER)
	_spiele(gespielt, _schritte_vor(), _pause())
	var slot := _speichere_und_lies(gespielt)
	if slot == null:
		return
	var aktuell := _katalog(ANDERER_KATALOG)
	var ohne_pause := TimelineRun.new(_katalog(), 4711, Difficulty.Level.SCHWER)
	_spiele(ohne_pause, _schritte_vor(), LETZTER_TAG)

	# Act
	var weiter := TimelineRun.new(slot.game.catalog, slot.game.seed, slot.game.difficulty)
	assert_eq(weiter.replay(slot.game.interventions, slot.game.day), [])
	weiter.advance_to(LETZTER_TAG)

	# Assert
	var mit_aktuellem := TimelineRun.new(aktuell, 4711, Difficulty.Level.SCHWER)
	mit_aktuellem.advance_to(LETZTER_TAG)
	assert_ne(ScheduleText.plan_lines(mit_aktuellem), ScheduleText.plan_lines(ohne_pause),
		"Die beiden Kataloge ergeben verschiedene Fahrpläne.")
	assert_eq(ScheduleText.plan_lines(weiter), ScheduleText.plan_lines(ohne_pause),
		"Fortgesetzt mit dem Katalog aus dem Spielstand.")
	assert_eq(_zeilen_ab(weiter, _pause() + 1), _zeilen_ab(ohne_pause, _pause() + 1))


# --- Hilfen ---------------------------------------------------------------------------------

## Vergleicht für alle Seeds und Grade ein Spiel ohne Pause mit einem, das am 14.03.1986 als Datei
## gespeichert und fortgesetzt wird. [param vor] und [param nach] sind die Schritte aus
## _schritte_vor() und _schritte_nach(). Gibt zurück, wie viele Absagen und Verschiebungen vor
## und nach der Pause angenommen wurden: { "vor": int, "nach": int }.
func _vergleiche_alle_faelle(vor: Array, nach: Array) -> Dictionary:
	var gezaehlt := {"vor": 0, "nach": 0}
	var katalog := _katalog()
	var pause := _pause()
	for grad in GRADE:
		for seed_wert in SEEDS:
			var wo := "Seed %d, %s" % [seed_wert, Difficulty.label(grad)]
			# Arrange: ohne Pause bis zum Ende, mit allen Eingriffen an ihren Tagen
			var ohne_pause := TimelineRun.new(katalog, seed_wert, grad)
			_spiele(ohne_pause, vor + nach, LETZTER_TAG)
			# und bis zum 14.03.1986, dann gespeichert und gelesen
			var bis_zur_pause := TimelineRun.new(katalog, seed_wert, grad)
			_spiele(bis_zur_pause, vor, pause)
			var slot := _speichere_und_lies(bis_zur_pause)
			if slot == null:
				return gezaehlt

			# Act: neuer Lauf aus der Datei, Eingriffe nachgespielt bis zum Spieldatum, weiter
			var weiter := TimelineRun.new(slot.game.catalog, slot.game.seed, slot.game.difficulty)
			var abgelehnt := weiter.replay(slot.game.interventions, slot.game.day)
			_spiele(weiter, nach, LETZTER_TAG)

			# Assert
			assert_eq(abgelehnt, [], "Jeder gespeicherte Eingriff gilt wieder: %s." % wo)
			assert_eq([slot.game.seed, slot.game.difficulty, slot.game.day_text()],
				[seed_wert, grad, "14.03.1986"], "Aus der Datei: %s." % wo)
			var zeilen := _zeilen_ab(ohne_pause, pause + 1)
			assert_gt(zeilen.size(), 0, "Es gibt Zeilen zu vergleichen: %s." % wo)
			assert_eq(_zeilen_ab(weiter, pause + 1), zeilen,
				"Ab dem 15.03.1986 dieselben Zeilen: %s." % wo)
			assert_eq(ScheduleText.plan_lines(weiter), ScheduleText.plan_lines(ohne_pause),
				"Derselbe Fahrplan: %s." % wo)
			assert_eq(weiter.interventions, ohne_pause.interventions,
				"Dasselbe Eingriffsprotokoll: %s." % wo)
			for eintrag in weiter.interventions:
				var art: String = eintrag["kind"]
				if art == TimelineRun.INTERVENTION_CANCEL or art == TimelineRun.INTERVENTION_MOVE:
					gezaehlt["vor" if eintrag["at_day"] <= pause else "nach"] += 1
	return gezaehlt


## Spielt [param run] bis [param bis] ab und wendet unterwegs die Schritte an, die bis dahin
## fällig sind. Ein Schritt ist [Tag, Callable(run) -> Eintrag]; ein leerer Eintrag heißt: an
## diesem Tag nichts zu tun. Die Schritte sind nach Tag geordnet.
func _spiele(run: TimelineRun, schritte: Array, bis: int) -> void:
	for schritt: Array in schritte:
		var tag: int = schritt[0]
		if tag > bis:
			break
		run.advance_to(tag)
		var eintrag: Dictionary = (schritt[1] as Callable).call(run)
		if not eintrag.is_empty():
			assert_eq(run.apply_intervention(eintrag), OK, "%s: %s" % [eintrag, run.last_refusal])
	run.advance_to(bis)


## Eingriffe bis einschließlich 14.03.1986: ein Modifikator vor Spielbeginn, eine Einplanung, eine
## Absage, eine Verschiebung und eine Einplanung am Tag der Pause selbst.
func _schritte_vor() -> Array:
	return [
		[-1, _fest({"kind": TimelineRun.INTERVENTION_ADD_MODIFIER, "modifier": {
			"event_id": "reklamationswelle", "from_day": _tag(1985, 6, 1),
			"id": "windiger_haendler", "reason": "Ware vom windigen Händler",
			"to_day": _tag(1990, 12, 31), "value": 0.05}})],
		[_tag(1985, 4, 11), _fest({"kind": TimelineRun.INTERVENTION_SCHEDULE,
			"event_id": "zeitungsartikel_reklamation", "day": _tag(1985, 9, 1),
			"reason": "Leserbrief"})],
		[_tag(1985, 7, 20), _absage],
		[_tag(1985, 10, 28), _verschiebung],
		[_pause(), _fest({"kind": TimelineRun.INTERVENTION_SCHEDULE,
			"event_id": "zeitungsartikel_reklamation", "day": _tag(1986, 6, 1),
			"reason": "Bericht über den Laden"})],
	]


## Eingriffe nach dem 14.03.1986, also nach dem Fortsetzen.
func _schritte_nach() -> Array:
	return [
		[_pause() + 1, _absage],
		[_tag(1988, 1, 1), _verschiebung],
		[_tag(1990, 6, 1), _fest({"kind": TimelineRun.INTERVENTION_REMOVE_MODIFIER,
			"modifier": {"id": "windiger_haendler"}})],
		[_tag(1991, 1, 1), _fest({"kind": TimelineRun.INTERVENTION_ADD_MODIFIER, "modifier": {
			"event_id": "reklamationswelle", "from_day": _tag(1991, 1, 1), "id": "spaeter",
			"reason": "Billige Netzteile", "to_day": _tag(1995, 12, 31), "value": 0.1}})],
		[_tag(1993, 2, 1), _absage],
		[_tag(1995, 1, 1), _fest({"kind": TimelineRun.INTERVENTION_SCHEDULE,
			"event_id": "zeitungsartikel_reklamation", "day": _tag(1995, 5, 1),
			"reason": "Jubiläum"})],
	]


## Ein Schritt, der immer denselben Eintrag liefert.
func _fest(eintrag: Dictionary) -> Callable:
	return func(_run: TimelineRun) -> Dictionary: return eintrag.duplicate(true)


## Sagt den nächsten Termin nach heute ab, der sich absagen lässt; leer, wenn es keinen gibt.
func _absage(run: TimelineRun) -> Dictionary:
	var termin := _naechster_termin(run)
	if termin == null:
		return {}
	return {"kind": TimelineRun.INTERVENTION_CANCEL, "event_id": termin.event.id, "day": termin.day,
		"reason": "Kunde abgesprungen"}


## Verschiebt den nächsten Termin nach heute, der sich verschieben lässt, um 30 Tage.
func _verschiebung(run: TimelineRun) -> Dictionary:
	var termin := _naechster_termin(run)
	if termin == null or termin.day + 30 > LETZTER_TAG:
		return {}
	return {"kind": TimelineRun.INTERVENTION_MOVE, "event_id": termin.event.id, "day": termin.day,
		"new_day": termin.day + 30, "reason": "Bauarbeiten"}


## Der erste geplante Termin nach heute, der weder fix noch jährlich ist; null, wenn es keinen gibt.
func _naechster_termin(run: TimelineRun) -> ScheduleEntry:
	for termin in run.entries:
		if termin.day > run.today and termin.state == ScheduleEntry.State.PLANNED \
				and termin.origin != ScheduleEntry.Origin.FIXED \
				and termin.origin != ScheduleEntry.Origin.YEARLY:
			return termin
	return null


## Speichert den Lauf als Spielstand über SaveStore und liest ihn mit SaveSlot.read() wieder.
func _speichere_und_lies(run: TimelineRun) -> SaveSlot:
	_nummer += 1
	var game := SaveGame.new()
	game.number = _nummer
	game.name = SaveGame.default_name(_nummer)
	game.difficulty = run.difficulty
	game.seed = run.seed
	game.day = run.today
	game.created_at = ANGELEGT
	game.last_played_at = ANGELEGT
	game.game_version = "0.1"
	# Der Katalog, mit dem das Spiel lief: die eigene Kopie des Laufs.
	game.catalog = run.catalog
	game.interventions = run.interventions.duplicate(true)
	var store := SaveStore.new(ORDNER)
	assert_eq(store.write(game, true), OK, store.last_error)
	var slot := SaveSlot.read(store.path_of(_nummer), _nummer)
	assert_eq(slot.state, SaveSlot.State.OK, slot.reason)
	if not slot.can_resume():
		return null
	return slot


## Die Zeilen des Protokolls ab dem Tag [param tag].
func _zeilen_ab(run: TimelineRun, tag: int) -> PackedStringArray:
	var zeilen := PackedStringArray()
	for meldung in run.protocol:
		if meldung.day >= tag:
			zeilen.append(meldung.to_line())
	return zeilen


func _kennungen(katalog: EventCatalog) -> Array:
	return katalog.events.map(func(event: TimelineEvent) -> String: return event.id)


func _katalog(pfad: String = KATALOG) -> EventCatalog:
	var issues: Array[CatalogIssue] = []
	return EventCatalog.read_file(pfad, issues)


## 14.03.1986, der Tag der Pause.
func _pause() -> int:
	return _tag(1986, 3, 14)


func _raeume_auf(pfad: String) -> void:
	var ordner := DirAccess.open(pfad)
	if ordner == null:
		return
	for datei in ordner.get_files():
		ordner.remove(datei)
	for unterordner in ordner.get_directories():
		_raeume_auf(pfad.path_join(unterordner))
	DirAccess.remove_absolute(pfad)


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()
