extends GutTest

## Prüft die Eingriffe, Unterschiede und Proben im Simulator der Werkstatt (Feature 002, T061 und
## T062; FR-043, FR-051; US6, Szenarien 1 bis 5, 7 und 8). Die Grundfunktionen des Simulators aus
## Phase 7 prüft test_werkstatt_scene.gd.
##
## Jeder Test baut die ganze Werkstatt mit einer Kopie eines Test-Katalogs in einem eigenen Ordner
## unter user:// auf; Proben schreibt der Simulator in dessen Unterordner proben/. after_each()
## räumt beides ab. Der echte Katalog und der echte Ordner der Proben bleiben unberührt.
##
## Grundlage ist catalog_us6_reklamation: die Reklamationswelle mit 3 % pro Monat, ihr Folgeereignis
## Zeitungsartikel, die Kundenflucht mit der Bedingung „Reklamationswelle eingetreten“, „Konkurrent
## eröffnet“ beim Start auf den 01.06.1992 gesetzt und Windows 95 als fixes Ereignis.

const SZENE := preload("res://tools/werkstatt/werkstatt.tscn")
const ORDNER := "user://test_simulator/"
const PROBEN := ORDNER + "proben/"
const US6 := "res://test/fixtures/catalog_us6_reklamation.json"
## Nur die Reklamationswelle mit 3 % und ein Ereignis mit 0 %.
const SCHWELLE := "res://test/fixtures/catalog_us6_schwelle.json"
const HAENDLER := "Ware vom windigen Händler"
const PROBE := "Windiger Händler ab 1990"
## Was von der Reklamationswelle abhängt: ihr Folgeereignis und die Kundenflucht mit Bedingung.
const ABHAENGIGE := ["reklamationswelle", "zeitungsartikel_reklamation", "kundenflucht"]


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(PROBEN)


func after_each() -> void:
	for ordner: String in [PROBEN, ORDNER]:
		var zugriff := DirAccess.open(ordner)
		if zugriff != null:
			for datei in zugriff.get_files():
				zugriff.remove(datei)
		DirAccess.remove_absolute(ordner)


# --- Modifikatoren (US6, Szenarien 1 und 3) ---------------------------------------------------

func test_szenario_1_modifikator_wirkt_in_den_begruendungen() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")

	# Act: „Ware vom windigen Händler: +5 Prozentpunkte vom 01.01.1990 bis 31.12.1993“
	var dialog := _modifikator(simulator, HAENDLER, "+5", "1.1.1990", "31.12.1993")

	# Assert: angenommen, gesammelt und im Protokoll
	assert_false(dialog.visible, "Der Dialog schließt nach dem Setzen.")
	assert_eq(simulator.run.modifiers.size(), 1)
	assert_eq(simulator.run.modifiers[0].id, "ware_vom_windigen_haendler",
		"Die Kennung entsteht aus dem Grund (FR-025).")
	assert_eq(simulator.probe.interventions.size(), 1, "Der Eingriff ist gesammelt.")
	assert_eq(_zeilen(simulator.get_node("%ModifierList")),
		[["Reklamationswelle", "+5", "01.01.1990", "31.12.1993", HAENDLER]])
	var protokoll := _zeilen(simulator.get_node("%Protocol"))
	assert_string_contains(protokoll.back()[0], "Eingriff  Reklamationswelle: Modifikator")

	# Act: bis zum Ende
	_druecken(simulator, "%EndButton")

	# Assert: 1990 bis 1993 würfelt die Reklamationswelle mit 8 %, sonst mit 3 %.
	var beginn := _tag(1990, 1, 1)
	var ende := _tag(1993, 12, 31)
	var innen: Array[ScheduleEntry] = []
	var aussen: Array[ScheduleEntry] = []
	for termin in simulator.run.entries:
		if termin.event.id == "reklamationswelle" and termin.origin == ScheduleEntry.Origin.ROLLED:
			if termin.day >= beginn and termin.day <= ende:
				innen.append(termin)
			else:
				aussen.append(termin)
	assert_gt(innen.size(), 0, "Mit Seed 4711 würfelt sie in den vier Jahren.")
	assert_gt(aussen.size(), 0, "… und außerhalb.")
	for termin in innen:
		assert_almost_eq(termin.threshold, 0.08, 0.0001, "Schwelle am %s" % _datum(termin.day))
	for termin in aussen:
		assert_almost_eq(termin.threshold, 0.03, 0.0001, "Schwelle am %s" % _datum(termin.day))
	_termin_waehlen(simulator, innen[0])
	assert_string_contains(simulator.get_node("%DetailText").text,
		"Schwelle 0,0800 (3 % + Ware vom windigen Händler +5)")


func test_szenario_3_summe_und_begrenzung() -> void:
	# Arrange: 3 % Grundchance mit +4 und −6 Prozentpunkten
	var werkstatt := await _werkstatt(SCHWELLE)
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, "Werbung", "+4", "1.1.1985", "31.12.1999")
	_modifikator(simulator, "Gute Ware", "-6", "1.1.1985", "31.12.1999")
	var chance: Label = simulator.get_node("%ChanceLabel")
	assert_string_contains(chance.text, "Reklamationswelle: Grundchance 3 %, Summe 1 % → 1 %")

	# Act: „+4“ entfernen
	var liste: Tree = simulator.get_node("%ModifierList")
	liste.get_root().get_child(0).select(0)
	assert_false(simulator.get_node("%RemoveModifierButton").disabled)
	_druecken(simulator, "%RemoveModifierButton")

	# Assert: „−6“ bleibt, die Summe ist −3 %, wirksam 0 %.
	assert_eq(_zeilen(liste).size(), 1)
	assert_eq(_zeilen(liste)[0][SimulatorPanel.ModifierColumn.VALUE], "−6")
	assert_string_contains(chance.text, "Summe −3 % → 0 % (begrenzt)")
	assert_eq(simulator.probe.interventions.size(), 3, "Setzen, setzen, entfernen.")
	assert_eq(simulator.probe.interventions[2]["kind"], TimelineRun.INTERVENTION_REMOVE_MODIFIER)


func test_kennung_bleibt_eindeutig_auch_ueber_neustarts() -> void:
	# Arrange: Derselbe Grund zweimal, dazwischen ein Neustart ohne Eingriffe.
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, HAENDLER, "+5", "1.1.1990", "31.12.1993")
	_druecken(simulator, "%RestartWithoutButton")

	# Act
	_modifikator(simulator, HAENDLER, "+2", "1.1.1994", "31.12.1995")
	_druecken(simulator, "%RestartWithButton")

	# Assert: Der Neustart setzt beide, keiner ist nicht anwendbar.
	assert_eq(_kennungen(simulator.run.modifiers),
		["ware_vom_windigen_haendler", "ware_vom_windigen_haendler_2"])
	assert_false(simulator.get_node("%ProbeNotice").visible)


func test_ungueltige_eingabe_und_ablehnung_lassen_den_dialog_offen() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	var dialog := _intervention_dialog(simulator)
	_druecken(simulator, "%ModifierButton")

	# Act und Assert: ohne Ende geht es nicht.
	_ausfuellen(dialog, {"%ValueEdit": "+5", "%ReasonEdit": HAENDLER, "%ToEdit": ""})
	dialog.get_ok_button().pressed.emit()
	assert_true(dialog.visible)
	assert_string_contains(dialog.get_node("%Hint").text, "Ende")
	# Ende vor dem Beginn: Das lehnt der Lauf ab, sein Grund steht da (last_refusal).
	_ausfuellen(dialog, {"%FromEdit": "1.1.1993", "%ToEdit": "1.1.1990"})
	dialog.get_ok_button().pressed.emit()
	assert_true(dialog.visible)
	assert_eq(dialog.get_node("%Hint").text, simulator.run.last_refusal)
	assert_string_contains(simulator.run.last_refusal, "vor seinem Beginn")
	assert_eq(simulator.probe.interventions.size(), 0, "Abgelehntes wird nicht gesammelt.")
	dialog.hide()


# --- Absagen, Verschieben, Einplanen (US6, Szenarien 4 und 5) --------------------------------

func test_szenario_4_absage_mit_grund() -> void:
	# Arrange: Am 01.01.1992 steht „Konkurrent eröffnet“ für den 01.06.1992 im Fahrplan.
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_bis(simulator, "1.1.1992")
	var konkurrent := _termin(simulator, "konkurrent_eroeffnet", ScheduleEntry.Origin.PRESET)
	assert_eq(konkurrent.day, _tag(1992, 6, 1))

	# Act: Rechtsklick auf den Termin, im Menü „Absagen …“, dann der Grund
	_termin_waehlen(simulator, konkurrent)
	var menue: PopupMenu = simulator.get_node("%PlanMenu")
	simulator.get_node("%PlanTable").item_mouse_selected.emit(Vector2(20, 40), MOUSE_BUTTON_RIGHT)
	assert_true(menue.visible, "Der Rechtsklick öffnet das Menü.")
	menue.hide()
	menue.id_pressed.emit(SimulatorPanel.MenuItem.CANCEL)
	var dialog := _intervention_dialog(simulator)
	assert_eq(dialog.kind, InterventionDialog.Kind.CANCEL)
	_ausfuellen(dialog, {"%ReasonEdit": "Laden nebenan selbst gemietet"})
	dialog.get_ok_button().pressed.emit()

	# Assert: abgesagt mit Grund, und bis zum Ende tritt er nicht ein.
	assert_false(dialog.visible)
	_druecken(simulator, "%EndButton")
	assert_eq(konkurrent.state, ScheduleEntry.State.CANCELLED)
	assert_eq(konkurrent.note, "Laden nebenan selbst gemietet")
	assert_has(_zeilen(simulator.get_node("%PlanTable")).map(_ohne_unterschied),
		["01.06.1992", "Konkurrent eröffnet", "gesetzt", "abgesagt"])
	_termin_waehlen(simulator, konkurrent)
	assert_string_contains(simulator.get_node("%DetailText").text,
		"abgesagt: Laden nebenan selbst gemietet")
	assert_eq(simulator.probe.interventions[0]["kind"], TimelineRun.INTERVENTION_CANCEL)


func test_szenario_5_fix_wird_mit_grund_abgelehnt() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	var windows := _termin(simulator, "windows_95", ScheduleEntry.Origin.FIXED)
	_termin_waehlen(simulator, windows)
	var dialog := _intervention_dialog(simulator)

	for knopf: String in ["%CancelButton", "%MoveButton"]:
		# Act
		_druecken(simulator, knopf)
		_ausfuellen(dialog, {"%ReasonEdit": "Ausprobiert", "%DayEdit": "1.9.1995"})
		dialog.get_ok_button().pressed.emit()

		# Assert: abgelehnt mit dem Grund des Laufs; der Dialog bleibt offen.
		assert_true(dialog.visible, "%s: Der Dialog bleibt offen." % knopf)
		assert_eq(dialog.get_node("%Hint").text,
			"%s ist fix und lässt sich weder absagen noch verschieben." % windows.event.title)
		dialog.hide()
	assert_eq([windows.state, windows.day], [ScheduleEntry.State.PLANNED, _tag(1995, 8, 24)])
	assert_eq(simulator.probe.interventions.size(), 0)


func test_verschieben_und_einplanen() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	var konkurrent := _termin(simulator, "konkurrent_eroeffnet", ScheduleEntry.Origin.PRESET)
	var dialog := _intervention_dialog(simulator)

	# Act: verschieben
	_termin_waehlen(simulator, konkurrent)
	_druecken(simulator, "%MoveButton")
	_ausfuellen(dialog, {"%DayEdit": "1.7.1992", "%ReasonEdit": "Bauamt hat Verspätung"})
	dialog.get_ok_button().pressed.emit()

	# Act: einplanen, das Ereignis ist aus dem gewählten Termin vorgewählt
	_druecken(simulator, "%ScheduleButton")
	assert_eq(dialog.kind, InterventionDialog.Kind.SCHEDULE)
	_ausfuellen(dialog, {"%DayEdit": "15.3.1993", "%ReasonEdit": "Zweiter Laden"})
	dialog.get_ok_button().pressed.emit()

	# Assert
	assert_eq([konkurrent.day, konkurrent.moved_from_day], [_tag(1992, 7, 1), _tag(1992, 6, 1)])
	var eingeplant := _termin(simulator, "konkurrent_eroeffnet", ScheduleEntry.Origin.INTERVENTION)
	assert_not_null(eingeplant, "Der neue Termin steht im Fahrplan.")
	if eingeplant != null:
		assert_eq([eingeplant.day, eingeplant.note], [_tag(1993, 3, 15), "Zweiter Laden"])
	var arten := []
	for eingriff in simulator.probe.interventions:
		arten.append(eingriff["kind"])
	assert_eq(arten, [TimelineRun.INTERVENTION_MOVE, TimelineRun.INTERVENTION_SCHEDULE])


# --- Unterschiede (US6, Szenario 2; FR-043) ---------------------------------------------------

func test_szenario_2_markiert_nur_die_reklamationswelle_und_abhaengige() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, HAENDLER, "+5", "1.1.1990", "31.12.1993")
	var tabelle: Tree = simulator.get_node("%PlanTable")

	# Act: neu starten mit dem Eingriff, bis zum Ende
	_druecken(simulator, "%RestartWithButton")
	_druecken(simulator, "%EndButton")

	# Assert: Die Spalte „Unterschied“ ist da, markiert sind nur Abhängige der Reklamationswelle.
	assert_eq(tabelle.columns, 5)
	assert_eq(tabelle.get_column_title(SimulatorPanel.PlanColumn.DIFF), "Unterschied")
	var markiert := {}
	for zeile in tabelle.get_root().get_children():
		var unterschied := zeile.get_text(SimulatorPanel.PlanColumn.DIFF)
		if not unterschied.is_empty():
			markiert[_ereignis_der_zeile(simulator, zeile)] = true
			assert_ne(unterschied, "→ verschoben", "Ein Modifikator verschiebt nichts.")
	assert_true(markiert.has("reklamationswelle"), "Die Reklamationswelle hat Unterschiede.")
	for kennung: String in markiert:
		assert_has(ABHAENGIGE, kennung, "%s hängt von der Reklamationswelle ab." % kennung)

	# Act und Assert: der Filter „nur Unterschiede“
	var unterschiede := _anzahl_unterschiede(simulator)
	var filter: CheckBox = simulator.get_node("%DiffFilter")
	assert_false(filter.disabled)
	filter.button_pressed = true
	var zeilen := _zeilen(tabelle)
	assert_eq(zeilen.size(), unterschiede, "Nur die markierten Zeilen.")
	for zeile: Array in zeilen:
		assert_ne(zeile[SimulatorPanel.PlanColumn.DIFF], "")
	assert_string_contains(simulator.get_node("%PlanCount").text,
		"%d Unterschiede" % zeilen.size())


func test_weggefallene_stehen_durchgestrichen_und_verschoben_nur_bei_verschiebung() -> void:
	# Arrange: −3 Prozentpunkte drücken die Reklamationswelle auf 0 %; ihre Termine fallen weg.
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, "Zufriedene Kunden", "-3", "1.1.1985", "31.12.1999")
	var konkurrent := _termin(simulator, "konkurrent_eroeffnet", ScheduleEntry.Origin.PRESET)
	_termin_waehlen(simulator, konkurrent)
	_druecken(simulator, "%MoveButton")
	var dialog := _intervention_dialog(simulator)
	_ausfuellen(dialog, {"%DayEdit": "1.7.1992", "%ReasonEdit": "Bauamt hat Verspätung"})
	dialog.get_ok_button().pressed.emit()

	# Act
	_druecken(simulator, "%EndButton")

	# Assert: Weggefallene stehen an ihrem Tag, durchgestrichen und mit „− weggefallen“.
	var tabelle: Tree = simulator.get_node("%PlanTable")
	var gestrichen := simulator.struck_rows()
	assert_gt(gestrichen.size(), 0, "Ohne Eingriffe würfelte die Reklamationswelle.")
	for zeile in gestrichen:
		assert_eq(zeile.get_text(SimulatorPanel.PlanColumn.DIFF), "− weggefallen")
		assert_lt(int(zeile.get_metadata(SimulatorPanel.PlanColumn.DATE)), 0,
			"Ein weggefallener Termin gehört nicht zum Lauf.")
	var tage := []
	for zeile in tabelle.get_root().get_children():
		tage.append(EventForm.parse_date(zeile.get_text(SimulatorPanel.PlanColumn.DATE))[1])
	var sortiert := tage.duplicate()
	sortiert.sort()
	assert_eq(tage, sortiert, "Alle Zeilen stehen nach Tag, auch die weggefallenen.")
	# „verschoben“ steht genau beim verschobenen Termin.
	var verschoben := []
	for zeile in tabelle.get_root().get_children():
		if zeile.get_text(SimulatorPanel.PlanColumn.DIFF) == "→ verschoben":
			verschoben.append(zeile.get_metadata(SimulatorPanel.PlanColumn.DATE))
	assert_eq(verschoben, [konkurrent.serial])
	# Ein weggefallener Termin lässt sich wählen; die Begründung sagt, warum er fehlt.
	gestrichen[0].select(0)
	assert_string_contains(simulator.get_node("%DetailText").text, "Fällt durch die Eingriffe weg")
	assert_true(simulator.get_node("%CancelButton").disabled, "Er gehört nicht zum Lauf.")


# --- Neustarts (FR-043) -----------------------------------------------------------------------

func test_neustart_mit_und_ohne_eingriffe_behaelt_die_gesammelten() -> void:
	# Arrange: Modifikator und Absage, Stand 31.12.1990
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	assert_true(simulator.get_node("%RestartWithButton").disabled, "Noch ist nichts gesammelt.")
	_modifikator(simulator, HAENDLER, "+5", "1.1.1990", "31.12.1993")
	_absagen(simulator, _termin(simulator, "konkurrent_eroeffnet", ScheduleEntry.Origin.PRESET),
		"Laden nebenan selbst gemietet")
	_bis(simulator, "31.12.1990")

	# Act und Assert: ohne Eingriffe
	_druecken(simulator, "%RestartWithoutButton")
	assert_eq([simulator.run.today, simulator.run.interventions.size()], [_tag(1990, 12, 31), 0])
	assert_eq(simulator.probe.interventions.size(), 2, "Die gesammelten bleiben.")
	assert_eq(simulator.get_node("%PlanTable").columns, 4, "Ohne Eingriffe keine Unterschiede.")

	# Act und Assert: Der Katalog ändert sich, ungespeichert; die gesammelten bleiben trotzdem.
	werkstatt.editor.set_event_field("windows_95", &"title", "Windows 95 kommt")
	_druecken(simulator, "%RestartWithButton")
	assert_eq([simulator.run.today, simulator.run.interventions.size()], [_tag(1990, 12, 31), 2])
	assert_eq(simulator.run.catalog.get_event("windows_95").title, "Windows 95 kommt",
		"Der Neustart rechnet mit dem Katalog, wie er jetzt dasteht.")
	assert_eq(_termin(simulator, "konkurrent_eroeffnet", ScheduleEntry.Origin.PRESET).state,
		ScheduleEntry.State.CANCELLED)
	assert_false(simulator.get_node("%ProbeNotice").visible, "Alles ließ sich anwenden.")

	# Act und Assert: Auch „Fahrplan erzeugen“ lässt sie liegen.
	_erzeugen(simulator, "1")
	assert_eq([simulator.run.seed, simulator.run.interventions.size()], [1, 0])
	assert_eq(simulator.probe.interventions.size(), 2)
	assert_eq(simulator.get_node("%ProbeLabel").text, "2 Eingriffe gesammelt")


# --- Proben (US6, Szenarien 7 und 8; FR-051) --------------------------------------------------

func test_szenario_7_probe_speichern_und_laden() -> void:
	# Arrange: Seed 4711 mit Modifikator und Absage, bis Ende 1993
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, HAENDLER, "+5", "1.1.1990", "31.12.1993")
	_absagen(simulator, _termin(simulator, "konkurrent_eroeffnet", ScheduleEntry.Origin.PRESET),
		"Laden nebenan selbst gemietet")
	_bis(simulator, "31.12.1993")
	var fahrplan := ScheduleText.plan_lines(simulator.run)

	# Act: speichern
	_speichern(simulator, PROBE)

	# Assert
	var datei := PROBEN + "windiger_haendler_ab_1990.json"
	assert_true(FileAccess.file_exists(datei), "Die Probe liegt im Ordner der Proben.")
	assert_eq(simulator.get_node("%ProbeLabel").text, "2 Eingriffe gesammelt · Probe „%s“" % PROBE)

	# Act: ein anderer Lauf, dann die Probe laden
	_erzeugen(simulator, "1")
	_druecken(simulator, "%LoadProbeButton")
	var laden: ConfirmationDialog = simulator.get_node("%LoadProbeDialog")
	var liste: Tree = simulator.get_node("%ProbeList")
	assert_true(laden.visible)
	assert_eq(_zeilen(liste), [[PROBE, "4711", "31.12.1993", "2"]])
	liste.get_root().get_child(0).select(0)
	laden.get_ok_button().pressed.emit()

	# Assert: Seed, Modifikator und Absage sind wieder da, der Fahrplan ist derselbe.
	assert_eq(simulator.get_node("%SeedEdit").text, "4711")
	assert_eq([simulator.run.seed, simulator.run.today], [4711, _tag(1993, 12, 31)])
	assert_eq(_kennungen(simulator.run.modifiers), ["ware_vom_windigen_haendler"])
	assert_eq(ScheduleText.plan_lines(simulator.run), fahrplan, "Derselbe Fahrplan.")
	assert_false(simulator.get_node("%ProbeNotice").visible)


func test_probe_ueberschreiben_fragt_nach_und_loeschen_raeumt_auf() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, HAENDLER, "+5", "1.1.1990", "31.12.1993")
	_speichern(simulator, PROBE)
	var datei := PROBEN + "windiger_haendler_ab_1990.json"
	var vorher := FileAccess.get_file_as_string(datei)

	# Act: Ein zweiter Eingriff, dann unter demselben Namen speichern
	_modifikator(simulator, "Werbung", "+1", "1.1.1985", "31.12.1985")
	_druecken(simulator, "%SaveProbeButton")
	var speichern: ConfirmationDialog = simulator.get_node("%SaveProbeDialog")
	assert_eq(simulator.get_node("%ProbeNameEdit").text, PROBE, "Der Name ist vorgegeben.")
	speichern.get_ok_button().pressed.emit()

	# Assert: erst die Rückfrage, dann überschrieben
	var rueckfrage: ConfirmationDialog = simulator.get_node("%OverwriteDialog")
	assert_true(rueckfrage.visible)
	assert_string_contains(rueckfrage.dialog_text, "Überschreiben?")
	assert_eq(FileAccess.get_file_as_string(datei), vorher, "Vor der Antwort bleibt die Datei.")
	rueckfrage.get_ok_button().pressed.emit()
	assert_ne(FileAccess.get_file_as_string(datei), vorher)

	# Act und Assert: löschen mit Rückfrage
	assert_false(simulator.get_node("%DeleteProbeButton").disabled)
	_druecken(simulator, "%DeleteProbeButton")
	var loeschen: ConfirmationDialog = simulator.get_node("%DeleteProbeDialog")
	assert_true(loeschen.visible)
	assert_string_contains(loeschen.dialog_text, PROBE)
	loeschen.get_ok_button().pressed.emit()
	assert_false(FileAccess.file_exists(datei), "Die Datei ist weg.")
	assert_eq(WhatIfProbe.list_probes(PROBEN).size(), 0)
	assert_eq(simulator.probe.interventions.size(), 2, "Die gesammelten Eingriffe bleiben.")
	assert_true(simulator.get_node("%DeleteProbeButton").disabled)


func test_szenario_8_nicht_anwendbares_wird_genannt() -> void:
	# Arrange: Probe mit Modifikator und Absage
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, HAENDLER, "+5", "1.1.1990", "31.12.1993")
	_absagen(simulator, _termin(simulator, "konkurrent_eroeffnet", ScheduleEntry.Origin.PRESET),
		"Laden nebenan selbst gemietet")
	_speichern(simulator, PROBE)

	# Act: „Konkurrent eröffnet“ wird ein Ereignis über Wahrscheinlichkeit, ungespeichert; der
	# abgesagte Termin vom 01.06.1992 kommt dann nicht mehr vor.
	werkstatt.editor.set_event_kind("konkurrent_eroeffnet", TimelineEvent.Kind.CHANCE)
	_druecken(simulator, "%LoadProbeButton")
	simulator.get_node("%ProbeList").get_root().get_child(0).select(0)
	simulator.get_node("%LoadProbeDialog").get_ok_button().pressed.emit()

	# Assert: Die Absage ist genannt, der Modifikator gesetzt.
	var hinweis: Label = simulator.get_node("%ProbeNotice")
	assert_true(hinweis.visible)
	assert_string_contains(hinweis.text, "Absage: Konkurrent eröffnet hat am 01.06.1992 keinen")
	assert_eq(hinweis.theme_type_variation, &"WarningLabel")
	assert_eq(_kennungen(simulator.run.modifiers), ["ware_vom_windigen_haendler"])
	assert_eq(simulator.probe.interventions.size(), 2,
		"Die Probe behält auch den nicht anwendbaren Eingriff.")


# --- Zebra ------------------------------------------------------------------------------------

func test_neue_listen_im_zebra() -> void:
	# Arrange: zwei Modifikatoren, zwei Proben
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, "Werbung", "+1", "1.1.1985", "31.12.1985")
	_modifikator(simulator, HAENDLER, "+5", "1.1.1990", "31.12.1993")
	_speichern(simulator, "Probe A")
	_speichern(simulator, "Probe B")

	# Act
	_druecken(simulator, "%LoadProbeButton")

	# Assert: jede zweite Zeile endlos-gruen (Style-Guide, „Farbrollen“)
	for liste: String in ["%ModifierList", "%ProbeList"]:
		var zeilen: Array[TreeItem] = simulator.get_node(liste).get_root().get_children()
		assert_eq(zeilen.size(), 2, liste)
		assert_eq(zeilen[1].get_custom_bg_color(0), UiPalette.ENDLOS_GRUEN, liste)
		assert_ne(zeilen[0].get_custom_bg_color(0), UiPalette.ENDLOS_GRUEN, liste)
	simulator.get_node("%LoadProbeDialog").hide()


# --- Schalterzeile oben -----------------------------------------------------------------------

func test_probenknoepfe_brechen_nur_gemeinsam_um() -> void:
	# Arrange: die Werkstatt so groß wie das maximierte Fenster, 1920 × 925 logisch
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	var leiste: HFlowContainer = simulator.get_node("%RunBar")
	var gruppe: HBoxContainer = simulator.get_node("%ProbeButtons")
	var strich: VSeparator = leiste.get_node("ProbeSeparator")
	var knoepfe: Array[Control] = []
	for knopf: String in ["%SaveProbeButton", "%LoadProbeButton", "%DeleteProbeButton"]:
		knoepfe.append(simulator.get_node(knopf))
	var abstand := float(leiste.get_theme_constant("h_separation"))
	werkstatt.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	werkstatt.size = Vector2(1920, 925)
	await wait_process_frames(3)

	# Assert: eine eigene Gruppe in der Leiste, innen mit demselben Abstand wie die Leiste
	assert_eq(gruppe.get_parent(), leiste)
	for knopf in knoepfe:
		assert_eq(knopf.get_parent(), gruppe, "%s steht in der Gruppe." % knopf.name)
	assert_eq(float(gruppe.get_theme_constant("separation")), abstand)

	# Assert: alle drei in derselben Zeile; die Gruppe bricht als Ganzes in die zweite um
	_pruefe_nebeneinander(knoepfe, abstand)
	assert_gt(gruppe.position.y, strich.position.y, "Bei 1920 × 925 bricht die Gruppe um.")
	assert_eq(gruppe.position.x, 0.0, "Sie beginnt die neue Zeile.")
	assert_eq(strich.self_modulate.a, 0.0, "Der Strich am Ende der ersten Zeile ist durchsichtig.")
	assert_eq(leiste.get_node("RestartSeparator").self_modulate.a, 1.0,
		"Der andere Strich steht zwischen zwei Knöpfen.")

	# Act: so breit, dass alles in eine Zeile passt
	werkstatt.size = Vector2(2560, 925)
	await wait_process_frames(3)

	# Assert: eine Zeile mit denselben Abständen wie ohne Gruppe; der Strich ist wieder zu sehen.
	assert_eq(gruppe.position.y, strich.position.y, "Bei 2560 passt alles in eine Zeile.")
	assert_eq(knoepfe[0].global_position.x, strich.get_global_rect().end.x + abstand)
	_pruefe_nebeneinander(knoepfe, abstand)
	assert_eq(strich.self_modulate.a, 1.0)


# --- Helfer -----------------------------------------------------------------------------------

func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()


func _datum(tag: int) -> String:
	return str(GameDate.from_day_index(tag))


## Baut die Werkstatt mit einer Kopie von [param fixture] als Katalog und wartet den Start ab.
func _werkstatt(fixture: String = US6) -> Werkstatt:
	var ziel := ORDNER + "katalog.json"
	var datei := FileAccess.open(ziel, FileAccess.WRITE)
	datei.store_string(FileAccess.get_file_as_string(fixture))
	datei.close()
	var werkstatt: Werkstatt = SZENE.instantiate()
	werkstatt.catalog_path = ziel
	werkstatt.editor.backup_path = ORDNER + "sicherung.json"
	werkstatt.settings_path = ORDNER + "einstellungen.cfg"
	add_child_autofree(werkstatt)
	await wait_process_frames(2)
	return werkstatt


## Der Simulator, mit dem Ordner der Proben unter user://; sein Reiter wird gewählt.
func _simulator(werkstatt: Werkstatt) -> SimulatorPanel:
	var simulator: SimulatorPanel = werkstatt.get_node("%SimulatorPanel")
	simulator.probe_folder = PROBEN
	var tabs: TabContainer = werkstatt.get_node("%Tabs")
	tabs.current_tab = tabs.get_tab_idx_from_control(simulator)
	return simulator


func _erzeugen(simulator: SimulatorPanel, seed_text: String) -> void:
	var feld: LineEdit = simulator.get_node("%SeedEdit")
	feld.text = seed_text
	feld.text_changed.emit(seed_text)
	_druecken(simulator, "%GenerateButton")


func _druecken(simulator: SimulatorPanel, knopf: String) -> void:
	var button: Button = simulator.get_node(knopf)
	button.pressed.emit()


func _bis(simulator: SimulatorPanel, datum: String) -> void:
	var feld: LineEdit = simulator.get_node("%UntilEdit")
	feld.text = datum
	_druecken(simulator, "%UntilButton")


func _intervention_dialog(simulator: SimulatorPanel) -> InterventionDialog:
	return simulator.get_node("%InterventionDialog")


## Setzt Felder im Dialog, je eindeutiger Name → Text. Die Variablen heißen nicht „name“:
## GutTest erbt von Node, und Node hat schon name; -d warnte vor dem Überdecken.
func _ausfuellen(dialog: InterventionDialog, felder: Dictionary) -> void:
	for pfad: String in felder:
		var feld: LineEdit = dialog.get_node(pfad)
		feld.text = felder[pfad]


## „Modifikator …“ für [param ereignis], ausgefüllt und gesetzt; gibt den Dialog zurück.
func _modifikator(simulator: SimulatorPanel, grund: String, wert: String, von: String,
		bis: String, ereignis: String = "reklamationswelle") -> InterventionDialog:
	var dialog := _intervention_dialog(simulator)
	_druecken(simulator, "%ModifierButton")
	var auswahl: OptionButton = dialog.get_node("%EventChoice")
	for i in auswahl.item_count:
		if auswahl.get_item_text(i).ends_with("(%s)" % ereignis):
			auswahl.select(i)
	_ausfuellen(dialog, {"%ValueEdit": wert, "%ReasonEdit": grund, "%FromEdit": von,
		"%ToEdit": bis})
	dialog.get_ok_button().pressed.emit()
	return dialog


## Wählt den Termin und sagt ihn über „Absagen …“ mit Grund ab.
func _absagen(simulator: SimulatorPanel, termin: ScheduleEntry, grund: String) -> void:
	_termin_waehlen(simulator, termin)
	_druecken(simulator, "%CancelButton")
	var dialog := _intervention_dialog(simulator)
	_ausfuellen(dialog, {"%ReasonEdit": grund})
	dialog.get_ok_button().pressed.emit()


## „Probe speichern …“ unter [param probenname]; gibt es die Probe schon, bestätigt es die
## Rückfrage.
func _speichern(simulator: SimulatorPanel, probenname: String) -> void:
	_druecken(simulator, "%SaveProbeButton")
	var feld: LineEdit = simulator.get_node("%ProbeNameEdit")
	feld.text = probenname
	simulator.get_node("%SaveProbeDialog").get_ok_button().pressed.emit()
	var rueckfrage: ConfirmationDialog = simulator.get_node("%OverwriteDialog")
	if rueckfrage.visible:
		rueckfrage.get_ok_button().pressed.emit()


## Die Zeilen einer Tabelle, je Zeile die Texte ihrer Spalten.
func _zeilen(tabelle: Tree) -> Array:
	var zeilen := []
	for zeile in tabelle.get_root().get_children():
		var texte := []
		for spalte in tabelle.columns:
			texte.append(zeile.get_text(spalte))
		zeilen.append(texte)
	return zeilen


## Eine Zeile ohne die Spalte „Unterschied“.
func _ohne_unterschied(zeile: Array) -> Array:
	return zeile.slice(0, SimulatorPanel.PlanColumn.DIFF)


## Der erste Termin des Ereignisses [param id] mit der Herkunft [param herkunft]; null ohne einen.
func _termin(simulator: SimulatorPanel, id: String,
		herkunft: ScheduleEntry.Origin) -> ScheduleEntry:
	for termin in simulator.run.entries:
		if termin.event.id == id and termin.origin == herkunft:
			return termin
	return null


## Wählt die Zeile des Termins in der Tabelle des Fahrplans, wie mit der Maus.
func _termin_waehlen(simulator: SimulatorPanel, termin: ScheduleEntry) -> void:
	var tabelle: Tree = simulator.get_node("%PlanTable")
	for zeile in tabelle.get_root().get_children():
		if zeile.get_metadata(SimulatorPanel.PlanColumn.DATE) == termin.serial:
			zeile.select(SimulatorPanel.PlanColumn.DATE)
			return
	fail_test("Der Termin %d fehlt in der Tabelle." % termin.serial)


## Die Kennung des Ereignisses einer Zeile, auch einer weggefallenen.
func _ereignis_der_zeile(simulator: SimulatorPanel, zeile: TreeItem) -> String:
	zeile.select(0)
	return simulator.get_node("%DetailTitle").text.get_slice("(", 1).trim_suffix(")")


func _anzahl_unterschiede(simulator: SimulatorPanel) -> int:
	var anzahl := 0
	for zeile in simulator.get_node("%PlanTable").get_root().get_children():
		if not zeile.get_text(SimulatorPanel.PlanColumn.DIFF).is_empty():
			anzahl += 1
	return anzahl


## Die [param knoepfe] stehen in derselben Zeile, von links nach rechts im Abstand [param abstand].
func _pruefe_nebeneinander(knoepfe: Array[Control], abstand: float) -> void:
	for i in range(1, knoepfe.size()):
		var davor := knoepfe[i - 1].get_global_rect()
		assert_eq(knoepfe[i].global_position.y, davor.position.y, "%s in derselben Zeile" \
			% knoepfe[i].name)
		assert_eq(knoepfe[i].global_position.x, davor.end.x + abstand, "%s im Abstand der Leiste" \
			% knoepfe[i].name)


func _kennungen(modifikatoren: Array[ChanceModifier]) -> Array:
	var kennungen := []
	for modifikator in modifikatoren:
		kennungen.append(modifikator.id)
	return kennungen
