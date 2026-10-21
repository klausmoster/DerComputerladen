extends GutTest

## Prüft den Vergleich zweier Läufe (Feature 002, T059; FR-043, R24): ScheduleDiff paart je
## Ereignis die Termine eines Laufs ohne Eingriffe mit denen eines Laufs mit Eingriffen. Erst am
## selben Tag, dann über moved_from_day, der Rest ist neu oder weggefallen.
##
## Grundlage ist catalog_us6_reklamation: die Reklamationswelle mit ihrem Zeitungsartikel als
## Folgeereignis und der Kundenflucht, die von ihr abhängt; daneben unabhängige Ereignisse, darunter
## „Konkurrent eröffnet“ am 01.06.1992 und „Konkurrent schließt“, das von ihm abhängt.

const KATALOG := "res://test/fixtures/catalog_us6_reklamation.json"
const LETZTER_TAG := TimelineRun.LAST_DAY
## Die Reklamationswelle und was über Folgeereignis oder Bedingung von ihr abhängt.
const VON_REKLAMATION := ["kundenflucht", "reklamationswelle", "zeitungsartikel_reklamation"]
## „Konkurrent eröffnet“ und „Konkurrent schließt“, das nur nach einer Eröffnung kommt.
const VON_KONKURRENT := ["konkurrent_eroeffnet", "konkurrent_schliesst"]

var _katalog: EventCatalog


func before_all() -> void:
	var issues: Array[CatalogIssue] = []
	_katalog = EventCatalog.read_file(KATALOG, issues)


func test_gleiche_laeufe_haben_keine_unterschiede() -> void:
	# Arrange
	var ohne := _lauf(4711)
	var mit := _lauf(4711)

	# Act
	var diff := ScheduleDiff.compare(ohne, mit)

	# Assert
	assert_eq(diff.marks.size(), mit.entries.size(), "Jeder Termin hat eine Markierung.")
	assert_eq(_markiert(diff, mit), [], "Alle sind NONE.")
	assert_eq(diff.removed.size(), 0)


func test_szenario_2_modifikator_markiert_nur_die_reklamationswelle_und_abhaengige() -> void:
	# Arrange (US6, Szenario 2): derselbe Seed mit und ohne den Modifikator aus Szenario 1
	var hinzu := 0
	var beides := 0

	for seed_wert in range(1, 101):
		var ohne := _lauf(seed_wert)
		var mit := TimelineRun.new(_katalog, seed_wert)
		if mit.add_modifier(_windiger_haendler()) != OK:
			fail_test("Seed %d: %s" % [seed_wert, mit.last_refusal])
			return
		mit.advance_to(LETZTER_TAG)

		# Act
		var diff := ScheduleDiff.compare(ohne, mit)

		# Assert: Markiert ist nur, was von der Reklamationswelle abhängt, und nie „verschoben“.
		var markiert := _markiert(diff, mit)
		var weggefallen := _kennungen(diff.removed)
		for zeile: String in markiert:
			assert_true(VON_REKLAMATION.has(zeile.get_slice(" ", 1)),
				"Seed %d: %s hängt von der Reklamationswelle ab." % [seed_wert, zeile])
			assert_false(zeile.begins_with("MOVED"), "Seed %d: %s ist nicht verschoben."
				% [seed_wert, zeile])
		for kennung: String in weggefallen:
			assert_true(VON_REKLAMATION.has(kennung), "Seed %d: %s." % [seed_wert, kennung])
		if markiert.any(
				func(zeile: String) -> bool: return zeile.begins_with("ADDED reklamationswelle ")):
			hinzu += 1
			if weggefallen.has("reklamationswelle"):
				beides += 1
	assert_gt(hinzu, 0, "Über 100 Seeds bringt der Modifikator Termine dazu.")
	assert_gt(beides, 0, "In manchen Seeds kommt ein Termin dazu und ein anderer fällt weg, wegen "
		+ "des Mindestabstands; auch dann heißt keiner „verschoben“.")


func test_verschobener_termin_ist_verschoben() -> void:
	# Arrange: „Konkurrent eröffnet“ vom 01.06.1992 auf den 01.09.1992
	var ohne := _lauf(4711)
	var mit := TimelineRun.new(_katalog, 4711)
	mit.advance_to(_tag(1992, 1, 1))
	var termin := mit.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	assert_eq(mit.move_entry(termin.serial, _tag(1992, 9, 1), "Bauarbeiten"), OK)
	mit.advance_to(LETZTER_TAG)

	# Act
	var diff := ScheduleDiff.compare(ohne, mit)

	# Assert
	assert_eq(diff.marks[termin.serial], ScheduleDiff.Mark.MOVED)
	assert_does_not_have(_kennungen(diff.removed), "konkurrent_eroeffnet",
		"Der alte Termin ist der Partner, nicht weggefallen.")
	for zeile: String in _markiert(diff, mit):
		assert_true(VON_KONKURRENT.has(zeile.get_slice(" ", 1)), zeile)


func test_abgesagter_termin_hat_einen_anderen_zustand() -> void:
	# Arrange: „Konkurrent eröffnet“ am 01.01.1992 abgesagt; beide Läufe nur bis dahin und bis
	# zum Ende
	for bis in [_tag(1992, 1, 1), LETZTER_TAG]:
		var ohne := TimelineRun.new(_katalog, 4711)
		ohne.advance_to(bis)
		var mit := TimelineRun.new(_katalog, 4711)
		mit.advance_to(_tag(1992, 1, 1))
		var termin := mit.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
		assert_eq(mit.cancel_entry(termin.serial, "Laden nebenan selbst gemietet"), OK)
		mit.advance_to(bis)

		# Act
		var diff := ScheduleDiff.compare(ohne, mit)

		# Assert: geplant oder eingetreten gegen abgesagt
		assert_eq(diff.marks[termin.serial], ScheduleDiff.Mark.STATE_CHANGED)
		for zeile: String in _markiert(diff, mit):
			assert_true(VON_KONKURRENT.has(zeile.get_slice(" ", 1)), zeile)
		for kennung: String in _kennungen(diff.removed):
			assert_eq(kennung, "konkurrent_schliesst", "Ohne Eröffnung schließt keiner.")


func test_eingeplanter_termin_ist_neu() -> void:
	# Arrange
	var ohne := _lauf(4711)
	var mit := TimelineRun.new(_katalog, 4711)
	assert_eq(mit.schedule_event("zeitungsartikel_reklamation", _tag(1986, 3, 10), "Bericht"), OK)
	mit.advance_to(LETZTER_TAG)
	var termin := _termin_am(mit, "zeitungsartikel_reklamation", _tag(1986, 3, 10))

	# Act
	var diff := ScheduleDiff.compare(ohne, mit)

	# Assert
	assert_eq(_markiert(diff, mit), ["ADDED zeitungsartikel_reklamation 10.03.1986"])
	assert_eq(diff.marks[termin.serial], ScheduleDiff.Mark.ADDED)
	assert_eq(diff.removed.size(), 0)


func test_zwei_termine_am_selben_tag_paaren_sich_der_reihe_nach() -> void:
	# Arrange: ein zweiter „Konkurrent eröffnet“ am selben Tag wie der gesetzte
	var ohne := _lauf(4711)
	var mit := TimelineRun.new(_katalog, 4711)
	var tag := _tag(1992, 6, 1)
	assert_eq(mit.schedule_event("konkurrent_eroeffnet", tag, "Zweiter Laden"), OK)
	mit.advance_to(LETZTER_TAG)

	# Act
	var diff := ScheduleDiff.compare(ohne, mit)

	# Assert: Der gesetzte kommt im Fahrplan zuerst und bekommt den Partner.
	var termine := _termine(mit, "konkurrent_eroeffnet")
	assert_eq(termine.size(), 2)
	if termine.size() == 2:
		assert_eq([termine[0].origin_label(), diff.marks[termine[0].serial]],
			["gesetzt", ScheduleDiff.Mark.NONE])
		assert_eq([termine[1].origin_label(), diff.marks[termine[1].serial]],
			["Eingriff", ScheduleDiff.Mark.ADDED])
	assert_eq(diff.removed.size(), 0)


func test_verschoben_heisst_nur_mit_moved_from_day() -> void:
	# Arrange: „Konkurrent eröffnet“ abgesagt und am 01.09.1992 neu eingeplant. Das sieht aus wie
	# ein Verschieben, ist aber keins: Der neue Termin hat kein moved_from_day.
	var ohne := _lauf(4711)
	var mit := TimelineRun.new(_katalog, 4711)
	mit.advance_to(_tag(1992, 1, 1))
	var gesetzt := mit.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	assert_eq(mit.cancel_entry(gesetzt.serial, "Laden gemietet"), OK)
	assert_eq(mit.schedule_event("konkurrent_eroeffnet", _tag(1992, 9, 1), "Doch eröffnet"), OK)
	mit.advance_to(LETZTER_TAG)
	var neu := _termin_am(mit, "konkurrent_eroeffnet", _tag(1992, 9, 1))

	# Act
	var diff := ScheduleDiff.compare(ohne, mit)

	# Assert
	assert_eq(diff.marks[gesetzt.serial], ScheduleDiff.Mark.STATE_CHANGED)
	assert_eq(diff.marks[neu.serial], ScheduleDiff.Mark.ADDED)
	assert_false(diff.marks.values().has(ScheduleDiff.Mark.MOVED))


func test_verschobener_termin_auf_einem_belegten_tag() -> void:
	# Arrange: In beiden Läufen steht ein zweiter „Konkurrent eröffnet“ am 01.09.1992. Mit
	# Eingriffen kommt der gesetzte vom 01.06.1992 dazu; am 01.09.1992 liegen dann zwei.
	var ohne := TimelineRun.new(_katalog, 4711)
	var mit := TimelineRun.new(_katalog, 4711)
	var september := _tag(1992, 9, 1)
	for run: TimelineRun in [ohne, mit]:
		assert_eq(run.schedule_event("konkurrent_eroeffnet", september, "Zweiter Laden"), OK)
	var gesetzt := mit.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	assert_eq(mit.move_entry(gesetzt.serial, september, "Bauarbeiten"), OK)
	var eingeplant: ScheduleEntry = _termine(mit, "konkurrent_eroeffnet").filter(
		func(termin: ScheduleEntry) -> bool: return termin.origin_label() == "Eingriff")[0]
	ohne.advance_to(LETZTER_TAG)
	mit.advance_to(LETZTER_TAG)

	# Act
	var diff := ScheduleDiff.compare(ohne, mit)

	# Assert: Der unverschobene bekommt den Partner am selben Tag, der verschobene seinen am
	# ursprünglichen. Der Reihe nach im Fahrplan bekäme der gesetzte, der dort zuerst steht, den
	# Partner am 01.09.1992; dann hießen der eingeplante „neu“ und der Termin im Juni
	# „weggefallen“.
	assert_eq(diff.marks[eingeplant.serial], ScheduleDiff.Mark.NONE)
	assert_eq(diff.marks[gesetzt.serial], ScheduleDiff.Mark.MOVED)
	assert_eq(diff.removed.size(), 0)


func test_weggefallene_termine_stehen_in_der_reihenfolge_der_baseline() -> void:
	# Arrange: Ohne Reklamationswellen gibt es weder Zeitungsartikel noch Kundenflucht. −100
	# Prozentpunkte über das ganze Spiel nehmen alle weg.
	var ohne := _lauf(4711)
	var mit := TimelineRun.new(_katalog, 4711)
	var nie := ChanceModifier.new()
	nie.id = "nie"
	nie.event_id = "reklamationswelle"
	nie.value = -1.0
	nie.reason = "Nur noch Markenware"
	nie.from_day = 0
	nie.to_day = LETZTER_TAG
	assert_eq(mit.add_modifier(nie), OK)
	mit.advance_to(LETZTER_TAG)

	# Act
	var diff := ScheduleDiff.compare(ohne, mit)

	# Assert
	var erwartet: Array[ScheduleEntry] = []
	for termin in ohne.entries:
		if VON_REKLAMATION.has(termin.event.id):
			erwartet.append(termin)
	assert_gt(erwartet.size(), 0, "Voraussetzung: Mit Seed 4711 gibt es solche Termine.")
	assert_eq(diff.removed, erwartet, "Alle, in der Reihenfolge des Fahrplans ohne Eingriffe.")
	assert_eq(_markiert(diff, mit), [], "Alles andere ist gleich.")


# --- Helfer ---------------------------------------------------------------------------

## Ein Lauf ohne Eingriffe bis zum Spielende.
func _lauf(seed_wert: int) -> TimelineRun:
	var run := TimelineRun.new(_katalog, seed_wert)
	run.advance_to(LETZTER_TAG)
	return run


## „Ware vom windigen Händler: +5 Prozentpunkte vom 01.01.1990 bis 31.12.1993“ (US6, Szenario 1).
func _windiger_haendler() -> ChanceModifier:
	var modifikator := ChanceModifier.new()
	modifikator.id = "windiger_haendler"
	modifikator.event_id = "reklamationswelle"
	modifikator.value = 0.05
	modifikator.reason = "Ware vom windigen Händler"
	modifikator.from_day = _tag(1990, 1, 1)
	modifikator.to_day = _tag(1993, 12, 31)
	return modifikator


## Die markierten Termine des Laufs mit Eingriffen, je „<Mark> <kennung> <TT.MM.JJJJ>“, in der
## Reihenfolge des Fahrplans; NONE fehlt.
func _markiert(diff: ScheduleDiff, mit: TimelineRun) -> Array:
	var zeilen := []
	for termin in mit.entries:
		var markierung: ScheduleDiff.Mark = diff.marks.get(termin.serial, ScheduleDiff.Mark.NONE)
		if markierung != ScheduleDiff.Mark.NONE:
			zeilen.append("%s %s %s" % [ScheduleDiff.Mark.keys()[markierung], termin.event.id,
				GameDate.from_day_index(termin.day)])
	return zeilen


func _kennungen(termine: Array[ScheduleEntry]) -> Array:
	var kennungen := []
	for termin in termine:
		kennungen.append(termin.event.id)
	return kennungen


func _termine(run: TimelineRun, kennung: String) -> Array[ScheduleEntry]:
	var gefunden: Array[ScheduleEntry] = []
	for termin in run.entries:
		if termin.event.id == kennung:
			gefunden.append(termin)
	return gefunden


func _termin_am(run: TimelineRun, kennung: String, tag: int) -> ScheduleEntry:
	for termin in _termine(run, kennung):
		if termin.day == tag:
			return termin
	return null


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()
