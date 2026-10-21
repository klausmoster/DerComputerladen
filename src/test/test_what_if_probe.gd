extends GutTest

## Prüft die Was-wäre-wenn-Proben (Feature 002, T060; FR-051, R22): aus einem Lauf erzeugen,
## kanonisch speichern, lesen, auflisten, löschen und neu abspielen, auch wenn sich der Katalog
## inzwischen geändert hat (US6, Szenarien 7 und 8).
##
## Jeder Test schreibt in einen eigenen Ordner unter user://, den after_each() samt Inhalt wieder
## abräumt. In den echten Proben-Ordner der Werkstatt schreibt kein Test. Grundlage ist
## catalog_us6_reklamation mit „Konkurrent eröffnet“, beim Start auf den 01.06.1992 gesetzt.

const ORDNER := "user://test_what_if_probe/"
const KATALOG := "res://test/fixtures/catalog_us6_reklamation.json"
const LETZTER_TAG := TimelineRun.LAST_DAY
const NAME := "Windiger Händler ab 1990"
const DATEI := ORDNER + "windiger_haendler_ab_1990.json"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)


func after_each() -> void:
	_raeume_auf(ORDNER)


func test_ordner_der_werkstatt_liegt_mit_gitkeep_bereit() -> void:
	# Act und Assert: nur lesen, nichts schreiben
	assert_eq(WhatIfProbe.FOLDER, "res://tools/werkstatt/proben/")
	assert_true(DirAccess.dir_exists_absolute(WhatIfProbe.FOLDER))
	assert_true(FileAccess.file_exists(WhatIfProbe.FOLDER + ".gitkeep"),
		"Git kennt nur Dateien; die leere .gitkeep hält den Ordner in der Versionsverwaltung.")


func test_from_run_nimmt_seed_tag_und_eine_kopie_des_protokolls() -> void:
	# Arrange
	var run := TimelineRun.new(_katalog(), 4711)
	assert_eq(run.add_modifier(_windiger_haendler()), OK)
	run.advance_to(_tag(1991, 6, 30))

	# Act
	var probe := WhatIfProbe.from_run(NAME, run)
	run.interventions[0]["at_day"] = 99
	run.interventions[0]["modifier"]["value"] = 0.5

	# Assert
	assert_eq([probe.id, probe.name, probe.seed, probe.until_day],
		["windiger_haendler_ab_1990", NAME, 4711, _tag(1991, 6, 30)])
	assert_eq(probe.interventions.size(), 1)
	assert_eq(probe.interventions[0]["at_day"], -1, "Die Probe hat eine eigene Kopie.")
	assert_eq(probe.interventions[0]["modifier"]["value"], 0.05, "Auch vom Modifikator darin.")
	assert_eq(WhatIfProbe.from_run("!!!", run).id, "probe", "Ohne Buchstaben und Ziffern.")


func test_szenario_7_gespeicherte_probe_ergibt_denselben_fahrplan() -> void:
	# Arrange (US6, Szenario 7): Seed 4711, der Modifikator aus Szenario 1, die Absage von
	# „Konkurrent eröffnet“ am 01.01.1992 und die Absage eines gewürfelten Termins, den es erst
	# gibt, seit seine Würfelrunde lief.
	var run := _lauf_mit_absagen()
	if run == null:
		return
	var gewuerfelt := run.interventions[2]
	run.advance_to(LETZTER_TAG)
	var fahrplan := ScheduleText.plan_lines(run)
	var protokoll := ScheduleText.protocol_lines(run)
	var eingriffe := run.interventions.duplicate(true)

	# Act: speichern, „Werkstatt schließen“, also alles vergessen, dann lesen und neu abspielen
	var gespeichert := WhatIfProbe.from_run(NAME, run).write_file(ORDNER)
	run = null
	var geladen := WhatIfProbe.read_file(DATEI)
	var neu := geladen.build_run(_katalog())

	# Assert
	assert_eq(gespeichert, OK)
	assert_eq([geladen.id, geladen.name, geladen.seed, geladen.until_day],
		["windiger_haendler_ab_1990", NAME, 4711, LETZTER_TAG], "Seed und Tag sind wieder da.")
	assert_eq(geladen.interventions, eingriffe, "Das Eingriffsprotokoll ist wieder da.")
	assert_eq(geladen.not_applicable, PackedStringArray(), "Alles ließ sich anwenden.")
	assert_eq(_kennungen(neu.modifiers), ["windiger_haendler"], "Der Modifikator ist gesetzt.")
	var konkurrent := _termin_am(neu, "konkurrent_eroeffnet", _tag(1992, 6, 1))
	assert_eq([konkurrent.state_label(), konkurrent.note],
		["abgesagt", "Laden nebenan selbst gemietet"], "Die Absage ist gesetzt.")
	var abgesagt := _termin_am(neu, gewuerfelt["event_id"], gewuerfelt["day"])
	assert_eq([abgesagt.origin_label(), abgesagt.state_label(), abgesagt.note],
		["gewürfelt", "abgesagt", "Kunde abgesprungen"],
		"Auch der gewürfelte Termin ist wieder abgesagt.")
	assert_eq(ScheduleText.plan_lines(neu), fahrplan, "Der Fahrplan ist derselbe wie vorher.")
	assert_eq(ScheduleText.protocol_lines(neu), protokoll, "Das Protokoll auch.")


func test_datei_ist_kanonisch_und_liest_sich_bytegleich_zurueck() -> void:
	# Arrange: Modifikator vor Spielbeginn, also am Tag −1, dem 31.12.1984; Absage am 01.01.1992
	# für den 01.06.1992.
	var run := TimelineRun.new(_katalog(), 4711)
	assert_eq(run.add_modifier(_windiger_haendler()), OK)
	run.advance_to(_tag(1992, 1, 1))
	var konkurrent := run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	assert_eq(run.cancel_entry(konkurrent.serial, "Laden nebenan selbst gemietet"), OK)
	var erwartet := "\n".join(PackedStringArray([
		"{",
		"\t\"format\": 1,",
		"\t\"id\": \"windiger_haendler_ab_1990\",",
		"\t\"interventions\": [",
		"\t\t{",
		"\t\t\t\"at_day\": \"1984-12-31\",",
		"\t\t\t\"kind\": \"add_modifier\",",
		"\t\t\t\"modifier\": {",
		"\t\t\t\t\"event_id\": \"reklamationswelle\",",
		"\t\t\t\t\"from_day\": \"1990-01-01\",",
		"\t\t\t\t\"id\": \"windiger_haendler\",",
		"\t\t\t\t\"reason\": \"Ware vom windigen Händler\",",
		"\t\t\t\t\"to_day\": \"1993-12-31\",",
		"\t\t\t\t\"value\": 0.05",
		"\t\t\t}",
		"\t\t},",
		"\t\t{",
		"\t\t\t\"at_day\": \"1992-01-01\",",
		"\t\t\t\"day\": \"1992-06-01\",",
		"\t\t\t\"event_id\": \"konkurrent_eroeffnet\",",
		"\t\t\t\"kind\": \"cancel\",",
		"\t\t\t\"reason\": \"Laden nebenan selbst gemietet\"",
		"\t\t}",
		"\t],",
		"\t\"name\": \"Windiger Händler ab 1990\",",
		"\t\"seed\": 4711,",
		"\t\"until_day\": \"1992-01-01\"",
		"}",
	])) + "\n"

	# Act
	var gespeichert := WhatIfProbe.from_run(NAME, run).write_file(ORDNER)
	var text := FileAccess.get_file_as_string(DATEI)
	var noch_einmal := WhatIfProbe.read_file(DATEI).write_file(ORDNER)

	# Assert
	assert_eq(gespeichert, OK)
	assert_eq(text, erwartet, "Schlüssel alphabetisch, Tabs, Tage als Datum, Format 1.")
	assert_eq(noch_einmal, OK)
	assert_eq(FileAccess.get_file_as_string(DATEI), text,
		"Lesen und wieder schreiben ergibt bytegleichen Text.")


func test_tage_stehen_als_datum_in_der_datei_und_als_tagesindex_im_speicher() -> void:
	# Arrange: „Konkurrent eröffnet“ am 01.01.1992 vom 01.06.1992 auf den 01.09.1992 verschoben
	var run := TimelineRun.new(_katalog(), 4711)
	run.advance_to(_tag(1992, 1, 1))
	var konkurrent := run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	assert_eq(run.move_entry(konkurrent.serial, _tag(1992, 9, 1), "Bauarbeiten"), OK)

	# Act
	assert_eq(WhatIfProbe.from_run(NAME, run).write_file(ORDNER), OK)
	var text := FileAccess.get_file_as_string(DATEI)
	var geladen := WhatIfProbe.read_file(DATEI)
	assert_eq(geladen.write_file(ORDNER), OK)

	# Assert: In der Datei „1992-06-01“ statt einer Zahl wie 2708, im Speicher wieder 2708.
	assert_string_contains(text, "\t\t\t\"day\": \"1992-06-01\",\n")
	assert_string_contains(text, "\t\t\t\"new_day\": \"1992-09-01\",\n")
	assert_false(text.contains(str(_tag(1992, 6, 1))), "Kein Tagesindex in der Datei.")
	assert_eq(geladen.interventions, run.interventions, "Dasselbe Dictionary wie im Lauf.")
	assert_eq(typeof(geladen.interventions[0]["day"]), TYPE_INT)
	assert_eq([geladen.interventions[0]["day"], geladen.interventions[0]["new_day"]],
		[_tag(1992, 6, 1), _tag(1992, 9, 1)])
	assert_eq(geladen.until_day, _tag(1992, 1, 1))
	assert_eq(FileAccess.get_file_as_string(DATEI), text,
		"Lesen und wieder schreiben bleibt bytegleich.")


func test_eintrag_mit_falschem_datum_wird_abgelehnt_und_genannt() -> void:
	# Arrange: eine Probe mit Modifikator, Einplanung und Absage; dann von Hand verdorben: Die
	# Einplanung hat eine Zahl statt eines Datums, die Absage den 30. Februar.
	var run := TimelineRun.new(_katalog(), 4711)
	assert_eq(run.add_modifier(_windiger_haendler()), OK)
	assert_eq(run.schedule_event("grossauftrag", _tag(1986, 3, 10), "Messeauftrag"), OK)
	run.advance_to(_tag(1992, 1, 1))
	var konkurrent := run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	assert_eq(run.cancel_entry(konkurrent.serial, "Laden nebenan selbst gemietet"), OK)
	assert_eq(WhatIfProbe.from_run(NAME, run).write_file(ORDNER), OK)
	var text := FileAccess.get_file_as_string(DATEI)
	_schreibe(DATEI, text.replace("\"day\": \"1986-03-10\"", "\"day\": 400").replace(
		"\"day\": \"1992-06-01\"", "\"day\": \"1992-02-30\""))

	# Act
	var geladen := WhatIfProbe.read_file(DATEI)
	var nach_dem_lesen := geladen.not_applicable
	var neu := geladen.build_run(_katalog())

	# Assert: Die Probe ist da, nur die beiden Einträge fehlen; kein Absturz, kein push_error.
	var genannt := PackedStringArray([
		"Einplanung: Bei „day“ steht 400, kein gültiges Datum JJJJ-MM-TT.",
		"Absage: Bei „day“ steht „1992-02-30“, kein gültiges Datum JJJJ-MM-TT.",
	])
	assert_not_null(geladen)
	assert_eq(geladen.interventions.size(), 1, "Der Modifikator bleibt.")
	assert_eq(nach_dem_lesen, genannt, "Schon nach dem Lesen genannt.")
	assert_eq(geladen.not_applicable, genannt, "Und nach build_run() wieder, mit den übrigen.")
	assert_eq(_kennungen(neu.modifiers), ["windiger_haendler"], "Der Modifikator gilt.")
	neu.advance_to(LETZTER_TAG)
	assert_eq(_termin_am(neu, "konkurrent_eroeffnet", _tag(1992, 6, 1)).state_label(),
		"eingetreten", "Die verdorbene Absage gilt nicht.")


func test_wert_des_modifikators_steht_auf_vier_stellen_gerundet() -> void:
	# Arrange: ein Anteil mit mehr Stellen, wie im Katalog auf vier gerundet
	var probe := WhatIfProbe.new()
	probe.id = "gerundet"
	probe.name = "Gerundet"
	probe.interventions.append({"at_day": -1, "kind": "add_modifier", "modifier": {
		"event_id": "reklamationswelle", "from_day": 0, "id": "krumm", "reason": "Krumm",
		"to_day": LETZTER_TAG, "value": 0.123456}})

	# Act
	var gespeichert := probe.write_file(ORDNER)

	# Assert
	assert_eq(gespeichert, OK)
	assert_string_contains(FileAccess.get_file_as_string(ORDNER + "gerundet.json"),
		"\t\t\t\t\"value\": 0.1235\n")
	assert_eq(probe.interventions[0]["modifier"]["value"], 0.123456,
		"Gerundet wird nur in der Datei.")


func test_szenario_8_nennt_die_nicht_anwendbare_absage() -> void:
	# Arrange (US6, Szenario 8): Danach wird „Konkurrent eröffnet“ im Katalog auf „über
	# Wahrscheinlichkeit“ gestellt; mit 0 % kommt der abgesagte Termin nicht mehr vor.
	var run := _lauf_mit_absagen()
	if run == null:
		return
	var gewuerfelt := run.interventions[2]
	assert_eq(WhatIfProbe.from_run(NAME, run).write_file(ORDNER), OK)
	var geaendert := _katalog()
	geaendert.get_event("konkurrent_eroeffnet").kind = TimelineEvent.Kind.CHANCE
	var geladen := WhatIfProbe.read_file(DATEI)

	# Act
	var neu := geladen.build_run(geaendert)

	# Assert
	assert_eq(geladen.not_applicable, PackedStringArray([
		"Absage: Konkurrent eröffnet hat am 01.06.1992 keinen geplanten Termin im Fahrplan.",
	]), "Die Absage wird genannt, statt still wegzufallen.")
	assert_eq(_kennungen(neu.modifiers), ["windiger_haendler"], "Der Modifikator ist gesetzt.")
	var abgesagt := _termin_am(neu, gewuerfelt["event_id"], gewuerfelt["day"])
	assert_eq(abgesagt.state_label(), "abgesagt", "Die andere Absage gilt weiter.")
	assert_eq(neu.interventions.size(), 2, "Im neuen Lauf stehen die beiden anwendbaren.")


func test_nicht_anwendbar_wenn_das_ereignis_fehlt() -> void:
	# Arrange: Die Reklamationswelle ist aus dem Katalog gelöscht.
	var run := _lauf_mit_absagen()
	if run == null:
		return
	var probe := WhatIfProbe.from_run(NAME, run)
	var ohne_welle := _katalog()
	ohne_welle.events.erase(ohne_welle.get_event("reklamationswelle"))

	# Act
	var neu := probe.build_run(ohne_welle)

	# Assert
	assert_eq(probe.not_applicable[0],
		"Modifikator: Das Ereignis „reklamationswelle“ gibt es im Katalog nicht.")
	assert_eq(neu.modifiers.size(), 0)
	assert_eq(_termin_am(neu, "konkurrent_eroeffnet", _tag(1992, 6, 1)).state_label(), "abgesagt",
		"Die übrigen Eingriffe gelten.")
	var zweiter_lauf := probe.build_run(_katalog())
	assert_eq(probe.not_applicable.size(), 0, "Jedes build_run() füllt die Liste neu.")
	assert_eq(zweiter_lauf.modifiers.size(), 1)


func test_neu_abspielen_bis_zum_gespeicherten_tag() -> void:
	# Arrange: ein Lauf, der bis zum 30.06.1995 abgespielt ist, mit einer Einplanung von 1990
	var run := TimelineRun.new(_katalog(), 4711)
	run.advance_to(_tag(1990, 6, 30))
	assert_eq(run.schedule_event("zeitungsartikel_reklamation", _tag(1990, 8, 1), "Sommerloch"), OK)
	run.advance_to(_tag(1995, 6, 30))
	var probe := WhatIfProbe.from_run("Halbzeit", run)
	var vor_dem_start := WhatIfProbe.from_run("Vor dem Start", TimelineRun.new(_katalog(), 7))

	# Act
	var neu := probe.build_run(_katalog())
	var frisch := vor_dem_start.build_run(_katalog())

	# Assert
	assert_eq(neu.today, _tag(1995, 6, 30), "Bis zu dem Tag, auf dem der Lauf stand.")
	assert_eq(ScheduleText.plan_lines(neu), ScheduleText.plan_lines(run))
	assert_eq(ScheduleText.protocol_lines(neu), ScheduleText.protocol_lines(run))
	assert_eq(neu.interventions, run.interventions)
	assert_eq([vor_dem_start.until_day, frisch.today, frisch.seed], [-1, -1, 7],
		"Eine Probe vor dem 01.01.1985 spielt nichts ab.")


func test_proben_nach_name_auflisten_und_loeschen() -> void:
	# Arrange: fünf Proben und eine Datei, die keine ist
	var run := TimelineRun.new(_katalog(), 4711)
	for titel in ["Zebra", "apfel", "Mitte", "Probe 10", "Probe 2"]:
		assert_eq(WhatIfProbe.from_run(titel, run).write_file(ORDNER), OK)
	_schreibe(ORDNER + "notiz.txt", "keine Probe")
	var mitte: WhatIfProbe = null
	for probe in WhatIfProbe.list_probes(ORDNER):
		if probe.name == "Mitte":
			mitte = probe

	# Act
	var namen := _namen(WhatIfProbe.list_probes(ORDNER))
	var geloescht := mitte.delete_file(ORDNER)
	var noch_einmal := mitte.delete_file(ORDNER)

	# Assert
	assert_eq(namen, ["apfel", "Mitte", "Probe 2", "Probe 10", "Zebra"],
		"Nach Name, Groß- und Kleinschreibung egal, Zahlen nach ihrem Wert.")
	assert_eq(geloescht, OK)
	assert_false(FileAccess.file_exists(ORDNER + "mitte.json"), "Die Datei ist weg (FR-051).")
	assert_eq(_namen(WhatIfProbe.list_probes(ORDNER)), ["apfel", "Probe 2", "Probe 10", "Zebra"])
	assert_eq(noch_einmal, ERR_FILE_NOT_FOUND)
	assert_true(FileAccess.file_exists(ORDNER + "notiz.txt"), "Andere Dateien bleiben liegen.")


func test_unlesbare_probe_wird_gemeldet_und_uebersprungen() -> void:
	# Arrange
	assert_eq(WhatIfProbe.from_run("Gut", TimelineRun.new(_katalog(), 4711)).write_file(ORDNER), OK)
	_schreibe(ORDNER + "kaputt.json", "{ \"name\": \"Kaputt\", ")
	_schreibe(ORDNER + "liste.json", "[1, 2, 3]")
	_schreibe(ORDNER + "ohne_format.json", "{\"interventions\": [], \"name\": \"X\", "
		+ "\"seed\": 1, \"until_day\": \"1985-01-01\"}")
	_schreibe(ORDNER + "format_2.json", "{\"format\": 2, \"interventions\": [], \"name\": \"X\", "
		+ "\"seed\": 1, \"until_day\": \"1985-01-01\"}")
	_schreibe(ORDNER + "ohne_seed.json", "{\"format\": 1, \"interventions\": [], \"name\": \"X\", "
		+ "\"until_day\": \"1985-01-01\"}")
	_schreibe(ORDNER + "tag_als_zahl.json", "{\"format\": 1, \"interventions\": [], "
		+ "\"name\": \"X\", \"seed\": 1, \"until_day\": 0}")

	# Act
	var proben := WhatIfProbe.list_probes(ORDNER)
	var fehlt := WhatIfProbe.read_file(ORDNER + "gibt_es_nicht.json")

	# Assert
	assert_eq(_namen(proben), ["Gut"], "Nur die lesbare Probe steht in der Liste.")
	assert_push_error("kaputt.json ist kein gültiges JSON, Zeile 1")
	assert_push_error("liste.json lässt sich nicht lesen: Die Datei enthält kein Objekt")
	assert_push_error("ohne_format.json lässt sich nicht lesen: Das Format („format“) fehlt; "
		+ "diese Version liest nur Format 1.")
	assert_push_error("format_2.json lässt sich nicht lesen: Das Format 2 kennt diese Version "
		+ "nicht, sie liest nur 1.")
	assert_push_error("ohne_seed.json lässt sich nicht lesen: „seed“ fehlt oder ist keine ganze")
	assert_push_error("tag_als_zahl.json lässt sich nicht lesen: „until_day“ fehlt oder ist kein "
		+ "gültiges Datum JJJJ-MM-TT.")
	assert_null(fehlt)
	assert_push_error("Die Probe user://test_what_if_probe/gibt_es_nicht.json fehlt.")


func test_kennung_muss_als_dateiname_taugen() -> void:
	# Arrange
	var probe := WhatIfProbe.new()
	probe.name = "Ausbruch"

	# Act und Assert
	probe.id = "../ausbruch"
	assert_eq(probe.write_file(ORDNER), ERR_INVALID_PARAMETER, "Kein Weg aus dem Ordner.")
	probe.id = ""
	assert_eq(probe.write_file(ORDNER), ERR_INVALID_PARAMETER)
	assert_eq(DirAccess.get_files_at(ORDNER).size(), 0, "Nichts geschrieben.")
	probe.id = "ausbruch"
	assert_eq(probe.write_file(ORDNER + "unterordner/"), OK, "Ein fehlender Ordner entsteht.")
	assert_true(FileAccess.file_exists(ORDNER + "unterordner/ausbruch.json"))


# --- Helfer ---------------------------------------------------------------------------

## Der Test-Katalog, jedes Mal frisch gelesen.
func _katalog() -> EventCatalog:
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.read_file(KATALOG, issues)
	assert_not_null(catalog, "%s lässt sich lesen: %s" % [KATALOG, issues])
	return catalog


## Seed 4711 mit dem Modifikator aus Szenario 1 vor Spielbeginn, der Absage von „Konkurrent
## eröffnet“ am 01.01.1992 und der Absage des nächsten gewürfelten Termins, der danach noch geplant
## ist. Der Lauf steht auf dem Monatsersten dieser zweiten Absage; null, wenn es keinen gibt.
func _lauf_mit_absagen() -> TimelineRun:
	var run := TimelineRun.new(_katalog(), 4711)
	assert_eq(run.add_modifier(_windiger_haendler()), OK)
	run.advance_to(_tag(1992, 1, 1))
	var konkurrent := run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	assert_eq(run.cancel_entry(konkurrent.serial, "Laden nebenan selbst gemietet"), OK)
	var gewuerfelt := _naechster_geplanter_gewuerfelter(run, _tag(1992, 2, 1))
	if gewuerfelt == null:
		fail_test("Voraussetzung: nach dem 01.02.1992 ein gewürfelter Termin, der noch "
			+ "geplant ist.")
		return null
	assert_eq(run.cancel_entry(gewuerfelt.serial, "Kunde abgesprungen"), OK)
	return run


## Spielt den Lauf von Monatserstem zu Monatserstem ab [param ab] und gibt den ersten gewürfelten
## Termin zurück, der danach noch geplant ist; null, wenn es bis zum Spielende keinen gibt.
func _naechster_geplanter_gewuerfelter(run: TimelineRun, ab: int) -> ScheduleEntry:
	var datum := GameDate.from_day_index(ab)
	var monat := GameDate.new(datum.year, datum.month, 1)
	while monat.to_day_index() <= LETZTER_TAG:
		run.advance_to(monat.to_day_index())
		for termin in run.entries:
			if termin.origin == ScheduleEntry.Origin.ROLLED \
					and termin.state == ScheduleEntry.State.PLANNED and termin.day > run.today:
				return termin
		monat = GameDate.new(monat.year + (1 if monat.month == 12 else 0),
			1 if monat.month == 12 else monat.month + 1, 1)
	return null


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


func _termin_am(run: TimelineRun, kennung: String, tag: int) -> ScheduleEntry:
	for termin in run.entries:
		if termin.event.id == kennung and termin.day == tag:
			return termin
	return null


func _kennungen(modifikatoren: Array[ChanceModifier]) -> Array:
	var kennungen := []
	for modifikator in modifikatoren:
		kennungen.append(modifikator.id)
	return kennungen


func _namen(proben: Array[WhatIfProbe]) -> Array:
	var namen := []
	for probe in proben:
		namen.append(probe.name)
	return namen


func _schreibe(pfad: String, text: String) -> void:
	var datei := FileAccess.open(pfad, FileAccess.WRITE)
	datei.store_string(text)
	datei.close()


## Löscht einen Ordner samt Dateien und Unterordnern.
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
