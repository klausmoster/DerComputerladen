extends GutTest

## Prüft die Eingriffe, Unterschiede und Proben im Simulator der Werkstatt (Feature 002, T061 und
## T062; FR-043, FR-051; US6, Szenarien 1 bis 5, 7 und 8), dazu Eingriffe, die außer der Reihe
## gesammelt sind (T075). Die Grundfunktionen des Simulators aus Phase 7 prüft
## test_werkstatt_scene.gd.
##
## Jeder Test baut die ganze Werkstatt mit einer Kopie eines Test-Katalogs in einem eigenen Ordner
## unter user:// auf; Proben schreibt der Simulator in dessen Unterordner proben/. after_each()
## räumt beides ab. Der echte Katalog und der echte Ordner der Proben bleiben unberührt.
##
## Grundlage ist catalog_us6_reklamation: die Reklamationswelle mit 3 % pro Monat, ihr Folgeereignis
## Zeitungsartikel, die Kundenflucht mit der Bedingung „Reklamationswelle eingetreten“, „Konkurrent
## eröffnet“ beim Start auf den 01.06.1992 gesetzt und Windows 95 als fixes Ereignis.
##
## Die Schwierigkeitsgrade (Feature 003, T025 und T026; US3) prüft der Teil am Ende mit
## catalog_us1_grade: dieselben Ereignisse und dazu der Lieferengpass mit 4 %, auf den kein Profil
## zeigt, ein jährliches Ereignis und die Profile „Leicht −2“ und „Schwer +5“ auf die
## Reklamationswelle. Fehlerhafte Start-Modifikatoren kommen aus catalog_us1_profil_kaputt.

const SZENE := preload("res://tools/werkstatt/werkstatt.tscn")
const ORDNER := "user://test_simulator/"
const PROBEN := ORDNER + "proben/"
const US6 := "res://test/fixtures/catalog_us6_reklamation.json"
## Nur die Reklamationswelle mit 3 % und ein Ereignis mit 0 %.
const SCHWELLE := "res://test/fixtures/catalog_us6_schwelle.json"
const HAENDLER := "Ware vom windigen Händler"
const PROBE := "Windiger Händler ab 1990"
## Feature 003: Profile „Leicht −2“ und „Schwer +5“ auf die Reklamationswelle.
const GRADE := "res://test/fixtures/catalog_us1_grade.json"
## Feature 003: drei Start-Modifikatoren in Schwer; einer zeigt auf ein Ereignis, das es nicht gibt,
## einer auf den Lieferengpass, der wegen einer Grundchance von 150 % ausgenommen ist, einer gilt.
const KAPUTT := "res://test/fixtures/catalog_us1_profil_kaputt.json"
const ENGPASS := "Engpass beim Großhändler"
## Die erste Zeile des Protokolls mit Schwer, wie TimelineMessage.to_line() sie schreibt.
const GRAD_SCHWER := ("31.12.1984  Grad  Reklamationswelle: Start-Modifikator „Anspruchsvolle "
	+ "Kunden“ (Schwer) +5 Prozentpunkte vom 01.01.1985 bis 31.12.1999")
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


func test_feld_mit_fehler_im_dialog_hat_die_rote_kontur() -> void:
	# Arrange (T093; Style-Guide, „Bedienelemente“): Solange der Hinweis steht, hat das Feld, um
	# das es geht, die Kontur von 2 Pixeln in kassenrot; die anderen nicht.
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	var dialog := _intervention_dialog(simulator)
	_druecken(simulator, "%ModifierButton")
	assert_eq(_konturen(dialog), [], "Frisch geöffnet ohne Kontur.")

	# Act und Assert: je Feld, das der Dialog selbst liest, nacheinander repariert
	for fall: Array in [
		[{"%ValueEdit": ""}, "%ValueEdit"],
		[{"%ValueEdit": "viel"}, "%ValueEdit"],
		[{"%ValueEdit": "+5", "%FromEdit": "32.1.1990"}, "%FromEdit"],
		[{"%FromEdit": "1.1.1990", "%ToEdit": ""}, "%ToEdit"],
		[{"%ToEdit": "31.12.1993", "%ReasonEdit": " "}, "%ReasonEdit"],
	]:
		_ausfuellen(dialog, fall[0])
		dialog.get_ok_button().pressed.emit()
		assert_true(dialog.get_node("%Hint").visible, "%s" % [fall[0]])
		assert_eq(_konturen(dialog), [fall[1]], "%s" % [fall[0]])
	var feld: LineEdit = dialog.get_node("%ReasonEdit")
	var kasten: StyleBoxFlat = feld.get_theme_stylebox(&"normal")
	assert_eq([kasten.border_color, kasten.border_width_left], [UiPalette.KASSENROT, 2])
	# Ein Ende vor dem Beginn lehnt der Lauf ab; es geht um beide Tage.
	_ausfuellen(dialog, {"%ReasonEdit": HAENDLER, "%FromEdit": "1.1.1993", "%ToEdit": "1.1.1990"})
	dialog.get_ok_button().pressed.emit()
	assert_eq(dialog.get_node("%Hint").text, simulator.run.last_refusal)
	assert_eq(_konturen(dialog), ["%FromEdit", "%ToEdit"])
	# Angenommen: Der Dialog schließt, Hinweis und Kontur gehen.
	_ausfuellen(dialog, {"%FromEdit": "1.1.1990", "%ToEdit": "31.12.1993"})
	dialog.get_ok_button().pressed.emit()
	assert_false(dialog.visible)
	assert_false(dialog.get_node("%Hint").visible)
	assert_eq(_konturen(dialog), [])

	# Act und Assert: Verschieben auf einen Tag, der schon abgespielt ist; es geht um den Tag.
	_bis(simulator, "1.1.1992")
	_termin_waehlen(simulator, _termin(simulator, "konkurrent_eroeffnet",
		ScheduleEntry.Origin.PRESET))
	_druecken(simulator, "%MoveButton")
	_ausfuellen(dialog, {"%DayEdit": "1.6.1990", "%ReasonEdit": "Bauamt hat Verspätung"})
	dialog.get_ok_button().pressed.emit()
	assert_string_contains(dialog.get_node("%Hint").text, "schon abgespielt")
	assert_eq(_konturen(dialog), ["%DayEdit"])
	dialog.hide()
	# Ein fixer Termin lässt sich auf keinen Tag verschieben; das liegt an keinem Feld.
	_termin_waehlen(simulator, _termin(simulator, "windows_95", ScheduleEntry.Origin.FIXED))
	_druecken(simulator, "%MoveButton")
	assert_eq(_konturen(dialog), [], "Beim Öffnen ist die Kontur weg.")
	_ausfuellen(dialog, {"%DayEdit": "1.9.1995", "%ReasonEdit": "Ausprobiert"})
	dialog.get_ok_button().pressed.emit()
	assert_string_contains(dialog.get_node("%Hint").text, "ist fix")
	assert_eq(_konturen(dialog), [])
	dialog.hide()
	# Einplanen nach dem Spielende: der Tag
	_druecken(simulator, "%ScheduleButton")
	_ausfuellen(dialog, {"%DayEdit": "1.1.2001", "%ReasonEdit": "Zu spät"})
	dialog.get_ok_button().pressed.emit()
	assert_string_contains(dialog.get_node("%Hint").text, "nach dem Spielende")
	assert_eq(_konturen(dialog), ["%DayEdit"])
	dialog.hide()


func test_modifikator_ohne_ereignis_zur_wahl_hat_die_kontur_an_der_auswahl() -> void:
	# Arrange (T093): Im Katalog gibt es kein Ereignis über Wahrscheinlichkeit.
	var werkstatt := await _werkstatt("res://test/fixtures/catalog_us1_preset.json")
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	var dialog := _intervention_dialog(simulator)

	# Act
	_druecken(simulator, "%ModifierButton")
	_ausfuellen(dialog, {"%ValueEdit": "+5", "%ReasonEdit": HAENDLER, "%ToEdit": "31.12.1993"})
	dialog.get_ok_button().pressed.emit()

	# Assert: Auswahlfelder haben ihre eigene Variante.
	assert_eq(dialog.get_node("%Hint").text, "Wähle ein Ereignis.")
	assert_eq(dialog.get_node("%EventChoice").theme_type_variation, &"ErrorOptionButton")
	assert_eq(_konturen(dialog), ["%EventChoice"])
	dialog.hide()


func test_probe_ohne_namen_hat_die_rote_kontur() -> void:
	# Arrange (T093)
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	var feld: LineEdit = simulator.get_node("%ProbeNameEdit")
	var dialog: ConfirmationDialog = simulator.get_node("%SaveProbeDialog")

	# Act: speichern ohne Namen
	_druecken(simulator, "%SaveProbeButton")
	feld.text = "  "
	dialog.get_ok_button().pressed.emit()

	# Assert
	assert_true(dialog.visible, "Der Dialog bleibt offen.")
	assert_true(simulator.get_node("%SaveHint").visible)
	assert_eq(feld.theme_type_variation, &"ErrorLineEdit")

	# Act und Assert: Beim nächsten Öffnen sind Hinweis und Kontur weg.
	dialog.hide()
	_druecken(simulator, "%SaveProbeButton")
	assert_false(simulator.get_node("%SaveHint").visible)
	assert_eq(feld.theme_type_variation, &"")
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


func test_begruendung_eines_abgesagten_termins_nennt_keine_wirkung() -> void:
	# Arrange (T097): ein eingeplanter Termin mit einer Wirkung 14 Tage nach dem Beginn, von Hand
	# wie im Lauf
	var spaeter := EventEffect.new()
	spaeter.kind = EventEffect.Kind.NACHFRAGE
	spaeter.target = "ram"
	spaeter.magnitude = 0.2
	spaeter.delay_days = 14
	var ereignis := TimelineEvent.new()
	ereignis.id = "speicher"
	ereignis.title = "Speicher wird knapp"
	ereignis.kind = TimelineEvent.Kind.CHANCE
	ereignis.effects.assign([spaeter])
	var termin := ScheduleEntry.new()
	termin.serial = 1
	termin.event = ereignis
	termin.origin = ScheduleEntry.Origin.INTERVENTION
	termin.day = _tag(1993, 3, 22)
	termin.end_day = termin.day

	# Act und Assert: geplant mit ihrem Tag …
	assert_string_contains(SimulatorPanel._explanation(termin),
		"05.04.1993  Nachfrage · ram · +20%")
	# … abgesagt oder entfallen nicht mehr, denn sie käme nie (Klaus, 2026-10-21).
	for zustand: ScheduleEntry.State in [ScheduleEntry.State.CANCELLED,
			ScheduleEntry.State.SKIPPED]:
		termin.state = zustand
		var text := SimulatorPanel._explanation(termin)
		assert_string_contains(text, "Verzögerte Wirkungen: entfallen mit dem Termin")
		assert_false(text.contains("05.04.1993"), "Kein Tag einer Wirkung: %s" % text)
	ereignis.effects.clear()
	assert_string_contains(SimulatorPanel._explanation(termin), "Verzögerte Wirkungen: keine",
		"Ohne verzögerte Wirkung entfällt auch keine.")


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


func test_eingriff_vor_spielbeginn_nach_fahrplan_erzeugen_gilt_an_seinem_tag() -> void:
	# Arrange (T075, Ablauf aus der Lückensuche): am 01.01.1992 ein Modifikator auf die
	# Reklamationswelle, dann „Fahrplan erzeugen“, dann vor Spielbeginn +100 Prozentpunkte auf
	# „Nur mit Aktion“, das ohne Modifikator nie kommt. Gesammelt steht der vom 01.01.1992 vorn.
	var werkstatt := await _werkstatt(SCHWELLE)
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_bis(simulator, "1.1.1992")
	_modifikator(simulator, "Werbung", "+5", "1.1.1992", "31.12.1999")
	_erzeugen(simulator, "4711")
	_modifikator(simulator, "Aktion im Laden", "+100", "1.1.1985", "31.12.1999", "nur_mit_aktion")
	var gesammelt := simulator.probe.interventions.duplicate(true)
	assert_eq(_tage_der_eingriffe(gesammelt), [_tag(1992, 1, 1), -1],
		"Gesammelt in der Reihenfolge der Aktionen.")

	# Act: speichern, solange der Lauf noch vor dem 01.01.1985 steht, dann neu starten
	_speichern(simulator, "Reihenfolge")
	var datei := FileAccess.get_file_as_string(PROBEN + "reihenfolge.json")
	_druecken(simulator, "%RestartWithButton")

	# Assert: Beide gelten an ihrem Tag, keiner ist nicht anwendbar.
	assert_eq(simulator.probe.not_applicable, PackedStringArray())
	assert_false(simulator.get_node("%ProbeNotice").visible)
	assert_eq(_tage_der_eingriffe(simulator.run.interventions), [-1, _tag(1992, 1, 1)],
		"Nachgespielt nach ihrem Tag.")
	var aktion := _termin(simulator, "nur_mit_aktion", ScheduleEntry.Origin.ROLLED)
	assert_not_null(aktion, "„Nur mit Aktion“ kommt mit dem Modifikator.")
	if aktion != null:
		assert_lt(aktion.day, _tag(1985, 2, 1), "Schon im Januar 1985, nicht erst 1992.")
	assert_eq(simulator.probe.interventions, gesammelt, "Die Sammlung bleibt, wie sie war.")
	# Der Endtag ist der letzte Eingriff, denn der Lauf stand vor dem 01.01.1985.
	assert_eq([simulator.run.today, simulator.probe.until_day],
		[_tag(1992, 1, 1), _tag(1992, 1, 1)])
	assert_string_contains(datei, "\t\"until_day\": \"1992-01-01\"\n")
	assert_lt(datei.find("\"at_day\": \"1992-01-01\""), datei.find("\"at_day\": \"1984-12-31\""),
		"Die Datei hat die Reihenfolge der Aktionen.")
	var fahrplan := ScheduleText.plan_lines(simulator.run)

	# Act: ein anderer Lauf, dann die Probe laden
	_erzeugen(simulator, "1")
	_druecken(simulator, "%LoadProbeButton")
	simulator.get_node("%ProbeList").get_root().get_child(0).select(0)
	simulator.get_node("%LoadProbeDialog").get_ok_button().pressed.emit()

	# Assert: Speichern und Laden ergeben denselben Fahrplan.
	assert_eq([simulator.run.seed, simulator.run.today], [4711, _tag(1992, 1, 1)])
	assert_eq(ScheduleText.plan_lines(simulator.run), fahrplan)

	# Act: bis zum Ende; dazu die Statistik mit denselben Eingriffen für diesen einen Seed
	_druecken(simulator, "%EndButton")
	var katalog := werkstatt.editor.catalog.without_faulty(werkstatt.editor.issues())
	var statistik := TimelineStatistics.new(katalog, 1, 4711)
	statistik.interventions = simulator.probe.interventions
	while not statistik.run_for(1000):
		pass

	# Assert: je Ereignis so viele Termine wie im Lauf
	for ergebnis in statistik.results():
		assert_eq(ergebnis.total, _begonnen(simulator.run, ergebnis.event_id), ergebnis.event_id)
	assert_eq(_begonnen(simulator.run, "nur_mit_aktion"), 180, "Jeden Monat ab Januar 1985.")


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
	assert_eq(_zeilen(liste), [[PROBE, "4711", "Mittel", "31.12.1993", "2"]],
		"Seit Feature 003 mit der Spalte „Grad“ (Analyse, B2).")
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


# --- Schwierigkeitsgrade: Grad und Neubau (Feature 003, T025; US3, FR-018, FR-019) -------------

func test_vorgabe_mittel_und_fahrplan_erzeugen_mit_schwer() -> void:
	# Arrange
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	var auswahl: OptionButton = simulator.get_node("%DifficultyOption")
	var leiste: HFlowContainer = simulator.get_node("%RunBar")

	# Assert: hinter „Würfeln“ der Text „Grad“ und die Auswahl, dann „Fahrplan erzeugen“
	var reihe := []
	for kind: Node in leiste.get_children():
		reihe.append(String(kind.name))
	var stelle := reihe.find("RollButton")
	assert_eq(reihe.slice(stelle, stelle + 4),
		["RollButton", "DifficultyCaption", "DifficultyOption", "GenerateButton"])
	assert_eq(leiste.get_node("DifficultyCaption").text, "Grad")
	var eintraege := []
	for i in auswahl.item_count:
		eintraege.append([auswahl.get_item_text(i), auswahl.get_item_id(i)])
	assert_eq(eintraege, [["Leicht", Difficulty.Level.LEICHT], ["Mittel", Difficulty.Level.MITTEL],
		["Schwer", Difficulty.Level.SCHWER]])
	assert_eq(simulator.selected_difficulty(), Difficulty.Level.MITTEL, "Vorgabe Mittel")

	# Act: ohne Lauf merkt sich die Auswahl den Grad nur
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)
	assert_null(simulator.run, "Ohne Lauf entsteht keiner.")
	_erzeugen(simulator, "4711")

	# Assert: „Fahrplan erzeugen“ nimmt den Grad; das Protokoll beginnt mit der Zeile „Grad“.
	assert_eq([simulator.run.seed, simulator.run.difficulty], [4711, Difficulty.Level.SCHWER])
	assert_eq(_kennungen(simulator.run.start_modifiers), ["reklamationswelle"])
	assert_eq(_zeilen(simulator.get_node("%Protocol")), [[GRAD_SCHWER]])
	assert_eq(simulator.get_node("%DateLabel").text, "Stand: vor dem 01.01.1985 · Seed 4711",
		"Der Stand bleibt, wie er ist; den Grad zeigt die Auswahl.")


func test_us3_szenario_1_wechsel_baut_denselben_lauf_mit_dem_neuen_grad() -> void:
	# Arrange: Mittel, ein Eingriff vor Spielbeginn und einer am 01.01.1990
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, ENGPASS, "-4", "1.1.1990", "31.12.1999", "lieferengpass")
	_bis(simulator, "1.1.1990")
	_modifikator(simulator, "Werbung", "+1", "1.1.1990", "31.12.1999")
	var angewandt := simulator.run.interventions.duplicate(true)
	var gesammelt := simulator.probe.interventions.duplicate(true)
	var unabhaengig := _unabhaengige_termine(simulator.run)

	# Act
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)

	# Assert: derselbe Seed und Tag, dieselben angewandten Eingriffe, nur der Grad ist neu.
	var lauf := simulator.run
	assert_eq([lauf.seed, lauf.today, lauf.difficulty],
		[4711, _tag(1990, 1, 1), Difficulty.Level.SCHWER])
	assert_eq(_kennungen(lauf.start_modifiers), ["reklamationswelle"])
	assert_eq(lauf.interventions, angewandt, "Die angewandten Eingriffe bleiben angewandt.")
	assert_eq(_kennungen(lauf.modifiers), ["engpass_beim_grosshaendler", "werbung"])
	assert_eq(simulator.probe.interventions, gesammelt, "Die gesammelten bleiben unberührt.")
	assert_eq(simulator.probe.difficulty, Difficulty.Level.SCHWER)
	assert_eq(simulator.selected_difficulty(), Difficulty.Level.SCHWER)
	assert_eq(simulator.get_node("%DateLabel").text, "Stand: 01.01.1990 · Seed 4711")
	assert_false(simulator.get_node("%ProbeNotice").visible, "Alles ließ sich anwenden.")
	assert_eq(_unabhaengige_termine(lauf), unabhaengig,
		"Was nicht von der Reklamationswelle abhängt, liegt wie bei Mittel (FR-009).")
	assert_eq(_zeilen(simulator.get_node("%Protocol"))[0], [GRAD_SCHWER],
		"Das Protokoll beginnt neu, mit der Zeile „Grad“.")

	# Act und Assert: ohne Eingriffe neu gestartet bleibt der Lauf beim Wechsel ohne.
	_druecken(simulator, "%RestartWithoutButton")
	assert_eq([simulator.run.difficulty, simulator.run.interventions.size()],
		[Difficulty.Level.SCHWER, 0], "Der Neustart behält den Grad.")
	_grad_waehlen(simulator, Difficulty.Level.LEICHT)
	assert_eq([simulator.run.difficulty, simulator.run.today, simulator.run.interventions.size()],
		[Difficulty.Level.LEICHT, _tag(1990, 1, 1), 0])
	assert_eq(simulator.run.start_modifiers[0].reason, "Nachsichtige Kunden")
	assert_eq(simulator.probe.interventions, gesammelt,
		"„Neu starten mit Eingriffen“ hat sie noch.")
	_druecken(simulator, "%RestartWithButton")
	assert_eq([simulator.run.difficulty, simulator.run.interventions.size()],
		[Difficulty.Level.LEICHT, 2])

	# Act und Assert: derselbe Grad noch einmal baut nichts neu.
	var vorher := simulator.run
	_grad_waehlen(simulator, Difficulty.Level.LEICHT)
	assert_same(simulator.run, vorher)


func test_wechsel_nennt_eine_absage_die_es_im_neuen_grad_nicht_gibt() -> void:
	# Arrange: Mit Schwer ein gewürfelter Termin der Reklamationswelle, den es bei Mittel mit
	# demselben Seed nicht gibt; Monat für Monat, bis einer geplant im Fahrplan steht.
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)
	_erzeugen(simulator, "4711")
	var mittel := TimelineRun.new(simulator.run.catalog, 4711)
	var gesucht: ScheduleEntry = null
	while gesucht == null and not simulator.run.is_finished():
		_druecken(simulator, "%MonthButton")
		mittel.advance_to(simulator.run.today)
		for termin in simulator.run.entries:
			if termin.event.id == "reklamationswelle" \
					and termin.state == ScheduleEntry.State.PLANNED \
					and termin.day > simulator.run.today \
					and mittel.find_planned("reklamationswelle", termin.day) == null:
				gesucht = termin
	assert_not_null(gesucht, "Mit Seed 4711 gibt es so einen Termin.")
	if gesucht == null:
		return
	_absagen(simulator, gesucht, "Kunden beruhigt")
	assert_eq(simulator.run.interventions.size(), 1)

	# Act
	_grad_waehlen(simulator, Difficulty.Level.MITTEL)

	# Assert: Die Absage ist nicht anwendbar und genannt; gesammelt bleibt sie (FR-018).
	var hinweis: Label = simulator.get_node("%ProbeNotice")
	assert_true(hinweis.visible)
	assert_string_contains(hinweis.text, "Absage: Reklamationswelle hat am %s keinen"
		% EventForm.format_date(gesucht.day))
	assert_eq([simulator.run.difficulty, simulator.run.interventions.size()],
		[Difficulty.Level.MITTEL, 0])
	assert_eq(simulator.probe.interventions.size(), 1)


func test_us3_szenario_2_start_modifikatoren_im_protokoll_und_in_der_liste() -> void:
	# Arrange: Schwer mit einem Eingriff
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, ENGPASS, "-4", "1.1.1990", "31.12.1999", "lieferengpass")

	# Assert: im Protokoll „Grad“ vor „Eingriff“ (FR-010)
	var protokoll := _zeilen(simulator.get_node("%Protocol"))
	assert_eq(protokoll.size(), 2)
	assert_eq(protokoll[0], [GRAD_SCHWER])
	assert_string_contains(protokoll[1][0], "31.12.1984  Eingriff  Lieferengpass: Modifikator")

	# Assert: in der Liste zuerst der Start-Modifikator, mit dem Grad vor dem Grund
	var liste: Tree = simulator.get_node("%ModifierList")
	assert_eq(_zeilen(liste), [
		["Reklamationswelle", "+5", "01.01.1985", "31.12.1999", "Schwer: Anspruchsvolle Kunden"],
		["Lieferengpass", "−4", "01.01.1990", "31.12.1999", ENGPASS],
	])
	# Keine eigene Farbe (Analyse, U10): kein Text in eigener Farbe, der Hintergrund vom Zebra.
	var zeilen := liste.get_root().get_children()
	for spalte in liste.columns:
		assert_eq(zeilen[0].get_custom_color(spalte), Color(),
			"Spalte %d ohne eigene Farbe" % spalte)
	assert_ne(zeilen[0].get_custom_bg_color(0), UiPalette.ENDLOS_GRUEN, "Erste Zeile ohne Streifen")
	assert_eq(zeilen[1].get_custom_bg_color(0), UiPalette.ENDLOS_GRUEN, "Zweite mit Streifen")

	# Assert: Die Chance nennt den Anteil des Grads; ohne Start-Modifikator wie bisher.
	var chance: Label = simulator.get_node("%ChanceLabel")
	assert_eq(chance.text, "Nächste Würfelrunde am 01.01.1985:\n"
		+ "Reklamationswelle: Grundchance 3 %, Schwer +5, Summe 8 % → 8 %\n"
		+ "Lieferengpass: Grundchance 4 %, Summe 4 % → 4 %")

	# Act und Assert: Der Start-Modifikator gewählt, „Entfernen“ gesperrt mit Hinweis (FR-010, I4)
	var entfernen: Button = simulator.get_node("%RemoveModifierButton")
	var vorgabe := entfernen.tooltip_text
	zeilen[0].select(0)
	assert_true(entfernen.disabled)
	assert_eq(entfernen.tooltip_text, "Start-Modifikatoren gehören zum Grad und lassen sich im "
		+ "laufenden Spiel nicht entfernen; ändern lassen sie sich im Reiter „Schwierigkeitsgrade“")
	assert_eq(zeilen[0].get_custom_bg_color(0), UiPalette.PETROL, "Gewählt wie jede Zeile")
	_druecken(simulator, "%RemoveModifierButton")
	assert_eq(_kennungen(simulator.run.start_modifiers), ["reklamationswelle"], "Er bleibt.")
	assert_eq(simulator.probe.interventions.size(), 1, "Nichts ist dazugekommen.")
	# Der Eingriff gewählt: wie bisher
	liste.get_root().get_child(1).select(0)
	assert_false(entfernen.disabled)
	assert_eq(entfernen.tooltip_text, vorgabe)
	assert_eq(vorgabe, "Den gewählten Modifikator ab der nächsten Würfelrunde entfernen")


func test_us3_szenarien_3_und_4_proben_mit_grad() -> void:
	# Arrange: Schwer mit Engpass bis Ende 1993, als Probe gespeichert
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, ENGPASS, "-4", "1.1.1990", "31.12.1999", "lieferengpass")
	_bis(simulator, "31.12.1993")
	var fahrplan := ScheduleText.plan_lines(simulator.run)
	_speichern(simulator, "Schwer mit Engpass")
	var datei := FileAccess.get_file_as_string(PROBEN + "schwer_mit_engpass.json")
	assert_true(datei.begins_with("{\n\t\"difficulty\": \"schwer\",\n"), "Der Grad steht darin.")

	# Act: Mittel, dann die Probe laden
	_grad_waehlen(simulator, Difficulty.Level.MITTEL)
	assert_eq(simulator.run.difficulty, Difficulty.Level.MITTEL)
	_druecken(simulator, "%LoadProbeButton")
	var liste: Tree = simulator.get_node("%ProbeList")
	assert_eq(liste.get_column_title(SimulatorPanel.ProbeColumn.DIFFICULTY), "Grad")
	assert_eq(_zeilen(liste), [["Schwer mit Engpass", "4711", "Schwer", "31.12.1993", "1"]])
	liste.get_root().get_child(0).select(0)
	simulator.get_node("%LoadProbeDialog").get_ok_button().pressed.emit()

	# Assert: Seed, Grad und Eingriffe sind wieder gesetzt (Szenario 3).
	assert_eq(simulator.selected_difficulty(), Difficulty.Level.SCHWER)
	assert_eq([simulator.run.seed, simulator.run.difficulty, simulator.run.today],
		[4711, Difficulty.Level.SCHWER, _tag(1993, 12, 31)])
	assert_eq(_kennungen(simulator.run.modifiers), ["engpass_beim_grosshaendler"])
	assert_eq(ScheduleText.plan_lines(simulator.run), fahrplan, "Derselbe Fahrplan.")

	# Arrange: dieselbe Probe ohne Grad, wie aus Feature 002
	var alt := datei.replace("\t\"difficulty\": \"schwer\",\n", "").replace(
		"\"name\": \"Schwer mit Engpass\"", "\"name\": \"Aus Feature 002\"")
	assert_false(alt.contains("difficulty"))
	var schreiben := FileAccess.open(PROBEN + "aus_feature_002.json", FileAccess.WRITE)
	schreiben.store_string(alt)
	schreiben.close()

	# Act
	_druecken(simulator, "%LoadProbeButton")
	assert_eq(_zeilen(liste)[0], ["Aus Feature 002", "4711", "Mittel", "31.12.1993", "1"])
	liste.get_root().get_child(0).select(0)
	simulator.get_node("%LoadProbeDialog").get_ok_button().pressed.emit()

	# Assert: Sie gilt als Mittel (Szenario 4).
	assert_eq(simulator.selected_difficulty(), Difficulty.Level.MITTEL)
	assert_eq([simulator.run.difficulty, simulator.run.start_modifiers.size()],
		[Difficulty.Level.MITTEL, 0])
	assert_eq(_kennungen(simulator.run.modifiers), ["engpass_beim_grosshaendler"])


func test_neustart_nach_probe_mit_schwer_und_erzeugen_mit_leicht_bleibt_bei_leicht() -> void:
	# Arrange: eine Probe mit Schwer laden, dann Leicht wählen und neu erzeugen
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, ENGPASS, "-4", "1.1.1990", "31.12.1999", "lieferengpass")
	_speichern(simulator, "Schwer mit Engpass")
	_druecken(simulator, "%LoadProbeButton")
	simulator.get_node("%ProbeList").get_root().get_child(0).select(0)
	simulator.get_node("%LoadProbeDialog").get_ok_button().pressed.emit()
	assert_eq(simulator.probe.difficulty, Difficulty.Level.SCHWER)
	_grad_waehlen(simulator, Difficulty.Level.LEICHT)
	_erzeugen(simulator, "4711")
	# Über die Oberfläche hält schon der Wechsel die Probe auf dem Grad des Laufs. Den Grad, den
	# eine früher geladene Probe dort hinterlässt, setzt der Test deshalb selbst (werkstatt.md,
	# „Neu starten mit Eingriffen“): Den Grad des Laufs muss restart() übernehmen.
	simulator.probe.difficulty = Difficulty.Level.SCHWER

	# Act
	_druecken(simulator, "%RestartWithButton")

	# Assert
	assert_eq(simulator.run.difficulty, Difficulty.Level.LEICHT)
	assert_eq(simulator.probe.difficulty, Difficulty.Level.LEICHT)
	assert_eq(simulator.selected_difficulty(), Difficulty.Level.LEICHT)
	assert_eq(_kennungen(simulator.run.modifiers), ["engpass_beim_grosshaendler"])

	# Act und Assert: ohne Eingriffe ebenso
	_druecken(simulator, "%RestartWithoutButton")
	assert_eq(simulator.run.difficulty, Difficulty.Level.LEICHT)


func test_ausgenommen_nennt_beide_arten_weggelassener_start_modifikatoren() -> void:
	# Arrange (FR-013; Analyse, G1)
	var werkstatt := await _werkstatt(KAPUTT)
	var simulator := _simulator(werkstatt)
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)

	# Act
	_erzeugen(simulator, "4711")

	# Assert: das ausgenommene Ereignis, der Start-Modifikator mit eigenem Fehler und der, dessen
	# Ereignis ausgenommen ist; es gilt nur der dritte.
	var hinweis: Label = simulator.get_node("%ExcludedNotice")
	assert_true(hinweis.visible)
	assert_eq(hinweis.text, "! Ausgenommen, weil fehlerhaft: „Lieferengpass“, Profil „Schwer“, "
		+ "Start-Modifikator „geisterereignis“, Profil „Schwer“, Start-Modifikator "
		+ "„lieferengpass“. Die Gründe stehen in der Prüfung.")
	assert_eq(_kennungen(simulator.run.start_modifiers), ["reklamationswelle"])
	assert_eq(simulator.run.start_refusals, PackedStringArray(), "Der Lauf lehnt nichts mehr ab.")


func test_katalog_geaendert_nach_profilaenderung_und_wechsel_nimmt_den_aktuellen() -> void:
	# Arrange (FR-018; Analyse, G4)
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	var hinweis: Label = simulator.get_node("%CatalogNotice")
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)
	_erzeugen(simulator, "4711")
	_bis(simulator, "1.1.1990")
	var lauf := simulator.run

	# Act: Schwer +8 statt +5, ungespeichert
	werkstatt.editor.set_start_modifier_field(Difficulty.Level.SCHWER, 0, &"value", 0.08)
	await wait_process_frames(1)

	# Assert: der Hinweis; der Lauf rechnet mit seiner Kopie weiter.
	assert_true(hinweis.visible)
	assert_same(simulator.run, lauf)
	assert_almost_eq(lauf.start_modifiers[0].value, 0.05, 0.0001)

	# Act und Assert: Rückgängig nimmt den Hinweis, Wiederholen bringt ihn.
	werkstatt.editor.undo()
	await wait_process_frames(1)
	assert_false(hinweis.visible)
	werkstatt.editor.redo()
	await wait_process_frames(1)
	assert_true(hinweis.visible)

	# Act: ein Wechsel des Grads baut mit dem aktuellen Katalog.
	_grad_waehlen(simulator, Difficulty.Level.LEICHT)

	# Assert
	assert_false(hinweis.visible, "Der Hinweis „Katalog geändert“ verschwindet (CHK033).")
	var schwer := simulator.run.catalog.get_profile(Difficulty.Level.SCHWER)
	assert_almost_eq(schwer.modifiers[0].value, 0.08, 0.0001)
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)
	assert_almost_eq(simulator.run.start_modifiers[0].value, 0.08, 0.0001)
	assert_string_contains(simulator.get_node("%ChanceLabel").text, "Schwer +8, Summe 11 % → 11 %")


# --- Schwierigkeitsgrade: Vergleich mit Mittel (Feature 003, T026; US3, FR-018) ---------------

func test_us3_szenario_5_mit_haekchen_markiert_nur_den_grad_und_abhaengige() -> void:
	# Arrange: Schwer ohne Eingriffe bis zum Ende
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	var vergleich: Label = simulator.get_node("%CompareLabel")
	var haekchen: CheckBox = simulator.get_node("%CompareMittel")
	var tabelle: Tree = simulator.get_node("%PlanTable")
	assert_eq(haekchen.text, "mit Mittel vergleichen")
	assert_eq(vergleich.text, "", "Ohne Lauf nennt er nichts.")
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)
	_erzeugen(simulator, "4711")
	_druecken(simulator, "%EndButton")

	# Assert: Ohne Häkchen gibt es keinen Vergleichslauf (Analyse, A3).
	assert_eq(tabelle.columns, 4)
	assert_eq(vergleich.text, "Kein Vergleich: Der Lauf hat keine Eingriffe.")
	assert_true(simulator.get_node("%DiffFilter").disabled)

	# Act
	haekchen.button_pressed = true

	# Assert: verglichen mit Mittel ohne Eingriffe; markiert nur, was vom Profil abhängt.
	assert_true(simulator.compare_with_mittel)
	assert_eq(vergleich.text, "Vergleich: Mittel ohne Eingriffe")
	assert_eq(vergleich.tooltip_text, vergleich.text, "Ganz zu lesen beim Überfahren")
	assert_eq(tabelle.columns, 5)
	var markiert := _markierte_ereignisse(simulator)
	assert_true(markiert.has("reklamationswelle"), "Das Profil verändert die Reklamationswelle.")
	for kennung: String in markiert:
		assert_has(ABHAENGIGE, kennung, "%s hängt von der Reklamationswelle ab." % kennung)
	assert_false(simulator.get_node("%DiffFilter").disabled)

	# Act und Assert: Häkchen aus, wieder ohne Vergleich
	haekchen.button_pressed = false
	assert_eq([tabelle.columns, vergleich.text],
		[4, "Kein Vergleich: Der Lauf hat keine Eingriffe."])


func test_us3_szenario_6_mit_eingriff_vergleicht_mit_demselben_grad() -> void:
	# Arrange: Schwer mit „Lieferengpass −4 Prozentpunkte ab 01.01.1990“, Häkchen aus
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	var vergleich: Label = simulator.get_node("%CompareLabel")
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, ENGPASS, "-4", "1.1.1990", "31.12.1999", "lieferengpass")

	# Act
	_druecken(simulator, "%EndButton")

	# Assert: markiert nur, was der Eingriff ändert; der Text nennt den Vergleichslauf.
	assert_eq(vergleich.text, "Vergleich: Schwer ohne Eingriffe")
	assert_eq(_markierte_ereignisse(simulator).keys(), ["lieferengpass"],
		"Der Lieferengpass hat keine Abhängigen, und den Grad haben beide Läufe.")

	# Act und Assert: mit Häkchen kommt der Grad dazu.
	simulator.compare_with_mittel = true
	assert_true(simulator.get_node("%CompareMittel").button_pressed, "Das Häkchen zieht mit.")
	assert_eq(vergleich.text, "Vergleich: Mittel ohne Eingriffe")
	var markiert := _markierte_ereignisse(simulator)
	assert_true(markiert.has("lieferengpass") and markiert.has("reklamationswelle"))
	for kennung: String in markiert:
		assert_has(ABHAENGIGE + ["lieferengpass"], kennung)


func test_mittel_mit_haekchen_aendert_keine_markierung() -> void:
	# Arrange: Mittel ohne Eingriffe (Edge Case „Vergleich bei Mittel“)
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	var vergleich: Label = simulator.get_node("%CompareLabel")
	var haekchen: CheckBox = simulator.get_node("%CompareMittel")
	_erzeugen(simulator, "4711")
	_druecken(simulator, "%EndButton")
	var vorher := _ansicht(simulator)

	# Act und Assert: Häkchen an, kein Vergleichslauf
	haekchen.button_pressed = true
	assert_eq(_ansicht(simulator), vorher)
	assert_eq(vergleich.text, "Kein Vergleich: Der Lauf hat keine Eingriffe.")
	assert_eq(simulator.get_node("%PlanTable").columns, 4)

	# Arrange: mit Eingriff
	haekchen.button_pressed = false
	_druecken(simulator, "%GenerateButton")
	_modifikator(simulator, HAENDLER, "+5", "1.1.1990", "31.12.1993")
	_druecken(simulator, "%EndButton")
	vorher = _ansicht(simulator)
	assert_eq(vergleich.text, "Vergleich: Mittel ohne Eingriffe")

	# Act
	haekchen.button_pressed = true

	# Assert: Markierungen, ihre Texte und der Hinweis am Filter bleiben, wie sie sind.
	assert_eq(_ansicht(simulator), vorher)
	assert_eq(vergleich.text, "Vergleich: Mittel ohne Eingriffe")


func test_texte_der_markierungen_beim_vergleich_mit_demselben_grad_wie_bisher() -> void:
	# Arrange: Schwer; die Reklamationswelle fällt ganz weg (3 + 5 − 8), der Lieferengpass kommt
	# öfter, „Konkurrent eröffnet“ wird verschoben. So gibt es „neu“, „weggefallen“ und
	# „verschoben“.
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, "Zufriedene Kunden", "-8", "1.1.1985", "31.12.1999")
	_modifikator(simulator, ENGPASS, "+20", "1.1.1985", "31.12.1999", "lieferengpass")
	_termin_waehlen(simulator, _termin(simulator, "konkurrent_eroeffnet",
		ScheduleEntry.Origin.PRESET))
	_druecken(simulator, "%MoveButton")
	var dialog := _intervention_dialog(simulator)
	var tag := EventForm.format_date(_termin(simulator, "konkurrent_eroeffnet",
		ScheduleEntry.Origin.PRESET).day)
	_ausfuellen(dialog, {"%DayEdit": "1.1.1999", "%ReasonEdit": "Bauamt hat Verspätung"})
	dialog.get_ok_button().pressed.emit()
	_druecken(simulator, "%EndButton")
	var filter: CheckBox = simulator.get_node("%DiffFilter")

	# Assert: Vergleich mit demselben Grad: die Texte aus Feature 002
	var verschoben := "Ein Eingriff hat den Termin vom %s hierher verschoben." % tag
	assert_eq(_texte_je_markierung(simulator), {
		"+ neu": "Neu durch die Eingriffe; ohne sie gäbe es den Termin nicht.",
		"− weggefallen": "Fällt durch die Eingriffe weg; ohne sie stünde der Termin hier.",
		"→ verschoben": verschoben,
	})
	assert_eq(filter.tooltip_text,
		"Nur Termine zeigen, die mit den Eingriffen anders sind als ohne sie")
	simulator.struck_rows()[0].select(0)
	assert_string_contains(simulator.get_node("%DetailText").text,
		"Unterschied: Fällt durch die Eingriffe weg; ohne sie stünde der Termin hier.")

	# Act: mit Mittel vergleichen
	simulator.get_node("%CompareMittel").button_pressed = true

	# Assert: die zweite Reihe, die den Vergleichslauf nennt
	assert_eq(_texte_je_markierung(simulator), {
		"+ neu": "Neu gegenüber Mittel ohne Eingriffe; dort gibt es den Termin nicht.",
		"− weggefallen": "Fällt gegenüber Mittel ohne Eingriffe weg; dort stünde der Termin hier.",
		"→ verschoben": verschoben,
	})
	assert_eq(filter.tooltip_text,
		"Zeigt nur Termine, die anders sind als bei Mittel ohne Eingriffe.")
	simulator.struck_rows()[0].select(0)
	assert_string_contains(simulator.get_node("%DetailText").text,
		"Unterschied: Fällt gegenüber Mittel ohne Eingriffe weg; dort stünde der Termin hier.")

	# Act und Assert: Häkchen aus, wieder die Texte aus Feature 002
	simulator.get_node("%CompareMittel").button_pressed = false
	assert_eq(_texte_je_markierung(simulator)["− weggefallen"],
		"Fällt durch die Eingriffe weg; ohne sie stünde der Termin hier.")


func test_filterleiste_bleibt_im_kleinen_fenster_so_breit() -> void:
	# Arrange (Analyse, G10): die kleine Fenstergröße aus test_werkstatt_settings.gd
	var werkstatt := await _werkstatt(GRADE)
	var simulator := _simulator(werkstatt)
	var leiste: Control = simulator.get_node("FilterBar")
	var layout: Control = werkstatt.get_node("Layout")
	var vergleich: Label = simulator.get_node("%CompareLabel")
	werkstatt.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	werkstatt.size = Vector2(1280, 720)
	await wait_process_frames(3)
	var breite := leiste.size.x

	# Act: Schwer mit Eingriff, Häkchen und „nur Unterschiede“, der längste Stand der Leiste
	_grad_waehlen(simulator, Difficulty.Level.SCHWER)
	_erzeugen(simulator, "4711")
	_modifikator(simulator, ENGPASS, "-4", "1.1.1990", "31.12.1999", "lieferengpass")
	_druecken(simulator, "%EndButton")
	simulator.compare_with_mittel = true
	(simulator.get_node("%DiffFilter") as CheckBox).button_pressed = true
	await wait_process_frames(3)

	# Assert: nicht breiter als vorher, das Layout bleibt im Fenster, der Text kürzt mit „…“.
	assert_eq(leiste.size.x, breite)
	assert_gte(layout.position.x, 0.0)
	assert_lte(layout.position.x + layout.size.x, 1280.0)
	assert_eq(vergleich.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS)
	assert_eq(vergleich.tooltip_text, "Vergleich: Mittel ohne Eingriffe")

	# Act: bei Klaus' Größe
	werkstatt.size = Vector2(1920, 925)
	await wait_process_frames(3)

	# Assert: alles in einer Zeile, der Text ganz
	for kind: Control in leiste.get_children():
		assert_true(SimulatorPanel._same_line(kind, vergleich), "%s in der Zeile" % kind.name)
	var schrift := vergleich.get_theme_font(&"font")
	var noetig := schrift.get_string_size(vergleich.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		vergleich.get_theme_font_size(&"font_size")).x
	assert_gte(vergleich.size.x, noetig, "Bei 1920 × 925 ist der Text nicht gekürzt.")


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
	werkstatt.editor.backup_folder = ORDNER
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


## Wählt [param grad] in %DifficultyOption wie mit der Maus: erst die Auswahl, dann ihr Signal.
func _grad_waehlen(simulator: SimulatorPanel, grad: Difficulty.Level) -> void:
	var auswahl: OptionButton = simulator.get_node("%DifficultyOption")
	var stelle := auswahl.get_item_index(grad)
	auswahl.select(stelle)
	auswahl.item_selected.emit(stelle)


## Die Termine der Ereignisse, die nicht von der Reklamationswelle abhängen, je [Tag, Kennung,
## Herkunft, Zustand]; sie liegen in jedem Grad gleich.
func _unabhaengige_termine(run: TimelineRun) -> Array:
	var termine := []
	for termin in run.entries:
		if not ABHAENGIGE.has(termin.event.id):
			termine.append([termin.day, termin.event.id, termin.origin, termin.state])
	return termine


func _druecken(simulator: SimulatorPanel, knopf: String) -> void:
	var button: Button = simulator.get_node(knopf)
	button.pressed.emit()


func _bis(simulator: SimulatorPanel, datum: String) -> void:
	var feld: LineEdit = simulator.get_node("%UntilEdit")
	feld.text = datum
	_druecken(simulator, "%UntilButton")


func _intervention_dialog(simulator: SimulatorPanel) -> InterventionDialog:
	return simulator.get_node("%InterventionDialog")


## Die Felder des Dialogs mit der roten Kontur eines Fehlers, als „%Name“ in ihrer Reihenfolge im
## Dialog.
func _konturen(dialog: InterventionDialog) -> Array:
	var felder := []
	for pfad: String in ["%EventChoice", "%ValueEdit", "%ReasonEdit", "%FromEdit", "%ToEdit",
			"%DayEdit"]:
		var feld: Control = dialog.get_node(pfad)
		if String(feld.theme_type_variation).begins_with("Error"):
			felder.append(pfad)
	return felder


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


## Die Kennungen der Ereignisse mit Markierung im Fahrplan, auch weggefallene, als
## { kennung: true }.
func _markierte_ereignisse(simulator: SimulatorPanel) -> Dictionary:
	var markiert := {}
	var tabelle: Tree = simulator.get_node("%PlanTable")
	if tabelle.columns <= SimulatorPanel.PlanColumn.DIFF:
		return markiert
	for zeile in tabelle.get_root().get_children():
		if not zeile.get_text(SimulatorPanel.PlanColumn.DIFF).is_empty():
			markiert[_ereignis_der_zeile(simulator, zeile)] = true
	return markiert


## Je Markierung der Text darunter im Hinweis der Zeile, für jede vorkommende Markierung einer.
func _texte_je_markierung(simulator: SimulatorPanel) -> Dictionary:
	var texte := {}
	var tabelle: Tree = simulator.get_node("%PlanTable")
	for zeile in tabelle.get_root().get_children():
		var markierung := zeile.get_text(SimulatorPanel.PlanColumn.DIFF)
		if not markierung.is_empty():
			texte[markierung] = zeile.get_tooltip_text(0).get_slice("\n", 2)
	return texte


## Was der Fahrplan zeigt: Zeilen mit Hinweisen, Spalten, Zahl und den Hinweis am Filter.
func _ansicht(simulator: SimulatorPanel) -> Array:
	var tabelle: Tree = simulator.get_node("%PlanTable")
	var hinweise := []
	for zeile in tabelle.get_root().get_children():
		hinweise.append(zeile.get_tooltip_text(0))
	return [_zeilen(tabelle), hinweise, tabelle.columns, simulator.get_node("%PlanCount").text,
		simulator.get_node("%DiffFilter").tooltip_text, simulator.struck_rows().size()]


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


## Die at_day der Einträge eines Eingriffsprotokolls in ihrer Reihenfolge.
func _tage_der_eingriffe(eingriffe: Array[Dictionary]) -> Array:
	var tage := []
	for eingriff in eingriffe:
		tage.append(eingriff["at_day"])
	return tage


## Wie viele Termine des Ereignisses [param id] begonnen haben: laufen, eingetreten oder beendet.
func _begonnen(run: TimelineRun, id: String) -> int:
	var anzahl := 0
	for termin in run.entries:
		if termin.event.id == id and termin.state in [ScheduleEntry.State.RUNNING,
				ScheduleEntry.State.OCCURRED, ScheduleEntry.State.ENDED]:
			anzahl += 1
	return anzahl
