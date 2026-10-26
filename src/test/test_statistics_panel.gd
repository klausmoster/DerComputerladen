extends GutTest

## Prüft die Statistik in der Werkstatt (Feature 002, T066; FR-042, FR-044, FR-045; US7,
## Szenarien 1, 2 und 4): den Reiter „Statistik“, das Rechnen in Häppchen mit Fortschritt, das
## Abbrechen, die Tabelle mit „–“ ohne Obergrenze, die Verteilung auf die Jahre, das Häkchen für
## die Eingriffe des Simulators samt der Warnung über abgelehnte (T082), den Hinweis auf
## ausgenommene Ereignisse und auf einen geänderten Katalog. Die Zählung selbst prüft
## test_timeline_statistics.gd.
##
## Feature 003 (T030; FR-020, R15): die Auswahl des Grads, der Vergleich aller drei mit zehn
## Spalten aus results_for(), der Bereich der Verteilung beim Vergleich, das Abbrechen mit gleich
## vielen Spielen je Grad, der Grad im Ergebnistext, „Katalog geändert“ nach einer Änderung an
## einem Profil und die weggelassenen Start-Modifikatoren im Hinweis.
##
## Wie in test_simulator.gd baut jeder Test die ganze Werkstatt mit einer Kopie eines
## Test-Katalogs in einem eigenen Ordner unter user:// auf; after_each() räumt ab. Gerechnet werden
## wenige Spiele, damit die Suite schnell bleibt; ein Spiel mit catalog_minimal dauert rund 2 ms.

const SZENE := preload("res://tools/werkstatt/werkstatt.tscn")
const ORDNER := "user://test_statistics_panel/"
## Je ein Ereignis fix, gesetzt (0- oder 1-mal), über Wahrscheinlichkeit, jährlich, nur als Folge.
const MINIMAL := "res://test/fixtures/catalog_minimal.json"
## Wie MINIMAL, aber intel_pentium am 12.05.2001 (V06).
const DATUM_AUSSERHALB := "res://test/fixtures/catalog_v06_datum_ausserhalb.json"
const PENTIUM := "Intel Pentium erscheint"
## Feature 003: Profile „Leicht −2“ und „Schwer +5“ auf die Reklamationswelle, dazu fixe,
## jährliche und gesetzte Ereignisse, die kein Profil verändert.
const GRADE := "res://test/fixtures/catalog_us1_grade.json"
## Feature 003: drei Start-Modifikatoren in Schwer; einer zeigt auf ein Ereignis, das es nicht gibt,
## einer auf den Lieferengpass, der wegen einer Grundchance von 150 % ausgenommen ist, einer gilt.
const KAPUTT := "res://test/fixtures/catalog_us1_profil_kaputt.json"
## Feature 003: In Schwer steht an Stelle 1 der Wert „fünf“ als Text (V22 beim Lesen).
const WERT_TEXT := "res://test/fixtures/catalog_v22_profil_wert_text.json"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)


func after_each() -> void:
	var ordner := DirAccess.open(ORDNER)
	if ordner != null:
		for datei in ordner.get_files():
			ordner.remove(datei)
	DirAccess.remove_absolute(ORDNER)


# --- Aufbau -----------------------------------------------------------------------------------

func test_reiter_statistik_mit_vorgaben() -> void:
	# Arrange und Act
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)

	# Assert: der dritte Reiter neben Prüfung und Simulator (contracts/werkstatt.md)
	var tabs: TabContainer = werkstatt.get_node("%Tabs")
	assert_eq([tabs.get_tab_title(0), tabs.get_tab_title(1), tabs.get_tab_title(2)],
		["Prüfung", "Simulator", "Statistik"])
	assert_eq(panel.get_node("%CountEdit").text, "1.000", "Vorgabe 1.000 Spiele (FR-044)")
	var haekchen: CheckBox = panel.get_node("%WithInterventions")
	assert_eq(haekchen.text, "Mit Modifikatoren und Einplanungen aus dem Simulator")
	assert_false(haekchen.button_pressed)
	assert_false(panel.get_node("%StartButton").disabled)
	assert_true(panel.get_node("%CancelButton").disabled, "Abbrechen erst, wenn es läuft.")
	assert_false(panel.get_node("%Progress").show_percentage, "Kein Text auf der Farbfläche.")
	assert_eq(panel.get_node("%ResultTable").get_root().get_child_count(), 0)
	assert_string_contains(panel.get_node("%ResultLabel").text, "Noch keine Statistik")
	var info: Label = panel.get_node("%InterventionInfo")
	assert_false(info.visible, "Was das Häkchen mitnimmt, steht erst mit Häkchen da.")
	haekchen.button_pressed = true
	assert_true(info.visible)
	assert_eq(info.text, "Im Simulator ist noch kein Eingriff gesammelt.")
	assert_null(panel.statistics)


func test_anzahl_nimmt_ziffern_bis_100000_mit_tausenderpunkt() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)
	var feld: LineEdit = panel.get_node("%CountEdit")

	# Act und Assert: Buchstaben fallen weg, mehr als 100.000 wird 100.000.
	_anzahl(panel, "25a0")
	assert_eq(feld.text, "250")
	_anzahl(panel, "250000")
	assert_eq(feld.text, "100.000")
	# Ohne Anzahl geht „Starten“ nicht, und ein Hinweis sagt, warum; solange er steht, hat das
	# Feld die rote Kontur (T093, Style-Guide „Bedienelemente“).
	assert_eq(feld.theme_type_variation, &"", "Mit Anzahl ohne Kontur.")
	_anzahl(panel, "")
	assert_true(panel.get_node("%StartButton").disabled)
	assert_true(panel.get_node("%CountHint").visible)
	assert_eq(feld.theme_type_variation, &"ErrorLineEdit")
	# Beim Verlassen des Felds steht die Anzahl mit Tausenderpunkt da.
	_anzahl(panel, "2500")
	feld.focus_exited.emit()
	assert_eq(feld.text, "2.500")
	assert_false(panel.get_node("%StartButton").disabled)
	assert_false(panel.get_node("%CountHint").visible)
	assert_eq(feld.theme_type_variation, &"", "Mit dem Hinweis geht die Kontur.")


# --- Rechnen (US7, Szenarien 1 und 2) ---------------------------------------------------------

func test_starten_rechnet_in_haeppchen_und_zeigt_das_ergebnis() -> void:
	# Arrange: 200 Spiele brauchen mit catalog_minimal rund 360 ms Rechenzeit, das Zwanzigfache
	# eines Häppchens von 15 ms. Wie viele Spiele ein Häppchen schafft, prüft der Test nicht: Das
	# hängt am Rechner und daran, was er nebenher tut; unter Last wird im ersten auch keins fertig.
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)
	_anzahl(panel, "200")

	# Act: Das erste Häppchen rechnet „Starten“ selbst.
	_druecken(panel, "%StartButton")

	# Assert: Es läuft noch, und dazwischen bekommt die Werkstatt ihre Bilder (R17).
	var fortschritt: ProgressBar = panel.get_node("%Progress")
	var erstes := panel.statistics.games_done
	assert_true(panel.is_running(), "„Starten“ kehrt zurück, bevor alle Spiele fertig sind.")
	assert_lt(erstes, 200)
	assert_eq([fortschritt.max_value, fortschritt.value], [200.0, float(erstes)])
	assert_string_contains(panel.get_node("%ProgressLabel").text, "von 200 Spielen")
	assert_true(panel.get_node("%StartButton").disabled)
	assert_false(panel.get_node("%CancelButton").disabled)
	assert_false(panel.get_node("%CountEdit").editable, "Die Anzahl gilt erst beim nächsten Start.")

	# Act und Assert: Nach einigen Bildern ist sie weiter, und der Balken zeigt den Stand.
	var weiter: bool = await wait_until(func() -> bool:
		return panel.statistics.games_done > erstes, 10.0)
	assert_true(weiter, "Bild für Bild werden weitere Spiele fertig.")
	assert_eq(fortschritt.value, float(panel.statistics.games_done))

	# Act
	await _bis_fertig(panel)

	# Assert: 100 % und eine Zeile je Ereignis nach Kennung; „–“ ohne Obergrenze (FR-044)
	assert_eq(panel.statistics.games_done, 200)
	assert_eq(fortschritt.value, 200.0)
	assert_string_starts_with(panel.get_node("%ProgressLabel").text, "100 % · 200 von 200 Spielen")
	# Feature 003 (R15): Der Text nennt den Grad, auch Mittel.
	assert_string_starts_with(panel.get_node("%ResultLabel").text,
		"Ergebnis über 200 Spiele, Seeds 1 bis 200, Mittel, ohne Eingriffe")
	var zeilen := _zeilen(panel)
	assert_eq(zeilen.size(), 5)
	assert_eq(zeilen[0], [PENTIUM, "1,00", "1", "1", "0,0 %", "–"], "fix: keine Obergrenze")
	assert_eq(zeilen[3], ["Weihnachtsgeschäft", "15,00", "15", "15", "0,0 %", "–"])
	for zeile: Array in [zeilen[2], zeilen[4]]:
		assert_eq(zeile[StatisticsPanel.Column.AT_MAX], "–", "%s: keine Obergrenze" % zeile[0])
	# Gesetzt, 0- oder 1-mal: Obergrenze 1, also ist „ohne“ und „Obergrenze“ zusammen 100 %.
	var gesetzt: Array = zeilen[1]
	assert_eq(gesetzt[0], "Neubaugebiet am Stadtrand")
	assert_almost_eq(_zahl(gesetzt[StatisticsPanel.Column.WITHOUT])
		+ _zahl(gesetzt[StatisticsPanel.Column.AT_MAX]), 100.0, 0.01)
	# Die Zahlen sind die der Statistik, mit Komma.
	var welle := _ergebnis(panel, "reklamationswelle")
	var zeile: Array = zeilen[2]
	assert_eq(zeile[StatisticsPanel.Column.MEAN], ("%.2f" % welle.mean()).replace(".", ","))
	assert_eq([zeile[StatisticsPanel.Column.MINIMUM], zeile[StatisticsPanel.Column.MAXIMUM]],
		[str(welle.minimum), str(welle.maximum)])


func test_ergebnis_im_zebra_mit_auswahl_in_petrol() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)
	_anzahl(panel, "5")
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)
	var zeilen: Array[TreeItem] = panel.get_node("%ResultTable").get_root().get_children()

	# Assert: Style-Guide, „Farbrollen“
	assert_eq(zeilen[1].get_custom_bg_color(0), UiPalette.ENDLOS_GRUEN)
	assert_ne(zeilen[2].get_custom_bg_color(0), UiPalette.ENDLOS_GRUEN)
	zeilen[2].select(0)
	assert_eq(zeilen[2].get_custom_bg_color(0), UiPalette.PETROL)


func test_abbrechen_zeigt_die_fertigen_spiele_samt_ihrer_zahl() -> void:
	# Arrange: die Vorgabe, 1.000 Spiele. Abgebrochen wird, sobald mindestens eines fertig ist;
	# wie viele Bilder das dauert, hängt am Rechner.
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)
	_druecken(panel, "%StartButton")
	var eines: bool = await wait_until(func() -> bool: return panel.statistics.games_done > 0, 10.0)
	assert_true(eines, "Ein Spiel ist fertig.")

	# Act
	_druecken(panel, "%CancelButton")

	# Assert: das Ergebnis der fertigen Spiele samt ihrer Zahl (Edge Cases)
	var fertig := panel.statistics.games_done
	assert_false(panel.is_running())
	assert_between(fertig, 1, 999)
	assert_string_starts_with(panel.get_node("%ResultLabel").text,
		"Abgebrochen nach %d von 1.000 Spielen. Das Ergebnis zeigt die %d fertigen" % [fertig,
		fertig])
	assert_string_contains(panel.get_node("%ProgressLabel").text, "%d von 1.000 Spielen" % fertig)
	for ergebnis in panel.statistics.results():
		assert_eq(ergebnis.games, fertig, ergebnis.event_id)
	assert_eq(_zeilen(panel)[0], [PENTIUM, "1,00", "1", "1", "0,0 %", "–"])
	assert_false(panel.get_node("%StartButton").disabled)
	assert_true(panel.get_node("%CancelButton").disabled)

	# Assert: Danach rechnet nichts mehr.
	await wait_process_frames(3)
	assert_eq(panel.statistics.games_done, fertig)


# --- Verteilung auf die Jahre (US7, Szenario 2) -----------------------------------------------

func test_verteilung_der_gewaehlten_zeile_als_balken_ohne_text_auf_der_farbe() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)
	_anzahl(panel, "10")
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)
	assert_eq(panel.year_bars().size(), 0, "Ohne gewählte Zeile keine Balken.")

	# Act: die Zeile des Pentium wählen
	_zeile_waehlen(panel, PENTIUM)

	# Assert: nur 1993, in der Farbe der Kategorie Hardware, der Wert darüber
	assert_string_contains(panel.get_node("%YearTitle").text, PENTIUM)
	var balken := panel.year_bars()
	assert_eq(balken.size(), EventStatistic.YEARS)
	for jahr: Dictionary in balken:
		var hoch: bool = jahr["bar"].size.y > 0.0
		assert_eq(hoch, jahr["year"] == 1993, "Balken %d" % jahr["year"])
	var pentium: Dictionary = balken[1993 - 1985]
	assert_eq([pentium["value_text"], pentium["color"]], ["1,00", UiPalette.NACHT_HELL])
	assert_string_contains(panel.get_node("%YearChart").tooltip_text, "1993: 1,00 je Spiel")

	# Act und Assert: Bei der Reklamationswelle steht kein Text auf einem Balken.
	_zeile_waehlen(panel, "Reklamationswelle")
	var hoechster: Dictionary = {}
	for jahr: Dictionary in panel.year_bars():
		var flaeche: Rect2 = jahr["bar"]
		for schluessel: String in ["value_rect", "year_rect"]:
			assert_false(flaeche.intersects(jahr[schluessel]), "%d %s" % [jahr["year"], schluessel])
		assert_lte(jahr["value_rect"].end.y, flaeche.position.y, "Der Wert steht darüber.")
		assert_gte(jahr["year_rect"].position.y, flaeche.end.y, "Das Jahr steht darunter.")
		if hoechster.is_empty() or jahr["value"] > hoechster["value"]:
			hoechster = jahr
	for jahr: Dictionary in panel.year_bars():
		assert_lte(jahr["bar"].size.y, hoechster["bar"].size.y,
			"Der höchste Wert hat den höchsten Balken.")


# --- Eingriffe aus dem Simulator (US7, Szenario 4; FR-045) ------------------------------------

func test_haekchen_rechnet_mit_den_eingriffen_des_simulators() -> void:
	# Arrange: Im Simulator kommen +50 Prozentpunkte auf die Reklamationswelle, 1985 bis 1999.
	var werkstatt := await _werkstatt()
	var simulator: SimulatorPanel = werkstatt.get_node("%SimulatorPanel")
	var tabs: TabContainer = werkstatt.get_node("%Tabs")
	tabs.current_tab = tabs.get_tab_idx_from_control(simulator)
	var seed_feld: LineEdit = simulator.get_node("%SeedEdit")
	seed_feld.text = "4711"
	seed_feld.text_changed.emit("4711")
	simulator.get_node("%GenerateButton").pressed.emit()
	_modifikator(simulator, "Ware vom windigen Händler", "+50", "1.1.1985", "31.12.1999")
	assert_eq(simulator.probe.interventions.size(), 1, "Der Simulator hat den Eingriff gesammelt.")
	var panel := _statistik(werkstatt)
	_anzahl(panel, "15")

	# Act: mit Häkchen
	panel.get_node("%WithInterventions").button_pressed = true
	var info: Label = panel.get_node("%InterventionInfo")
	assert_eq(info.text, "Aus dem Simulator: 1 Modifikator.", "Der Reiter zeigt, was gilt.")
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)
	var mit := _ergebnis(panel, "reklamationswelle").mean()

	# Assert
	assert_eq(panel.statistics.interventions.size(), 1)
	assert_string_contains(panel.get_node("%ResultLabel").text, "mit 1 Eingriff aus dem Simulator")

	# Act: ohne Häkchen
	panel.get_node("%WithInterventions").button_pressed = false
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)
	var ohne := _ergebnis(panel, "reklamationswelle").mean()

	# Assert: mit Häkchen kommt die Reklamationswelle viel öfter.
	gut.p("Reklamationswelle im Schnitt: mit Modifikator %.2f, ohne %.2f" % [mit, ohne])
	assert_eq(panel.statistics.interventions.size(), 0)
	assert_string_contains(panel.get_node("%ResultLabel").text, "ohne Eingriffe")
	assert_gt(mit, 2.0 * ohne)


func test_absagen_und_verschiebungen_nennt_der_hinweis_und_zaehlt_die_statistik_nicht() -> void:
	# Arrange: ein Protokoll mit Modifikator, Einplanung, Absage und Verschiebung
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)
	var protokoll: Array[Dictionary] = [
		{"at_day": -1, "kind": TimelineRun.INTERVENTION_ADD_MODIFIER, "modifier": {
			"event_id": "reklamationswelle", "from_day": 0, "id": "werbung", "reason": "Werbung",
			"to_day": TimelineRun.LAST_DAY, "value": 0.05}},
		{"at_day": -1, "kind": TimelineRun.INTERVENTION_SCHEDULE, "event_id": "zeitungsartikel",
			"day": _tag(1990, 6, 1), "reason": "Pressetermin"},
		{"at_day": -1, "kind": TimelineRun.INTERVENTION_CANCEL, "event_id": "neubaugebiet",
			"day": _tag(1990, 6, 1), "reason": "Bauamt"},
		{"at_day": -1, "kind": TimelineRun.INTERVENTION_MOVE, "event_id": "neubaugebiet",
			"day": _tag(1990, 6, 1), "new_day": _tag(1991, 6, 1), "reason": "Bauamt"},
	]
	panel.interventions_source = func() -> Array[Dictionary]: return protokoll
	_anzahl(panel, "3")

	# Act
	panel.get_node("%WithInterventions").button_pressed = true
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)

	# Assert: genannt wird alles; gelten und gezählt werden nur Modifikator und Einplanung (FR-045).
	assert_eq(panel.get_node("%InterventionInfo").text, ("Aus dem Simulator: 1 Modifikator, "
		+ "1 Einplanung. 1 Absage und 1 Verschiebung gelten nur für ihren Seed und bleiben weg."))
	assert_string_contains(panel.get_node("%ResultLabel").text,
		"mit 2 Eingriffen aus dem Simulator")
	assert_eq(panel.statistics.interventions.size(), 4,
		"Das Panel gibt alles weiter; was davon gilt, entscheidet TimelineStatistics.")


func test_eingriff_auf_ein_geloeschtes_ereignis_wird_genannt_aber_nicht_gezaehlt() -> void:
	# Arrange (T082): Im Simulator kommt ein Modifikator auf die Reklamationswelle; danach löscht
	# Klaus das Ereignis im Katalog.
	var werkstatt := await _werkstatt()
	var simulator: SimulatorPanel = werkstatt.get_node("%SimulatorPanel")
	var seed_feld: LineEdit = simulator.get_node("%SeedEdit")
	seed_feld.text = "4711"
	seed_feld.text_changed.emit("4711")
	simulator.get_node("%GenerateButton").pressed.emit()
	_modifikator(simulator, "Ware vom windigen Händler", "+50", "1.1.1985", "31.12.1999")
	assert_eq(simulator.probe.interventions.size(), 1, "Der Simulator hat den Eingriff gesammelt.")
	werkstatt.editor.delete_event("reklamationswelle")
	var panel := _statistik(werkstatt)
	_anzahl(panel, "3")
	panel.get_node("%WithInterventions").button_pressed = true

	# Act
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)

	# Assert: genannt ja, gezählt nein (FR-045)
	assert_eq(panel.get_node("%InterventionInfo").text, "Aus dem Simulator: 1 Modifikator.",
		"Gesammelt ist er.")
	assert_string_contains(panel.get_node("%ResultLabel").text, "ohne Eingriffe",
		"Gezählt wird er nicht.")
	var hinweis: Label = panel.get_node("%RefusedNotice")
	assert_true(hinweis.visible)
	assert_eq(hinweis.theme_type_variation, &"WarningLabel", "Eine Warnung als Text in holz.")
	assert_eq(hinweis.text, "? In jedem Spiel abgelehnt, deshalb nicht gezählt:\n"
		+ "Modifikator: Das Ereignis „reklamationswelle“ gibt es im Katalog nicht.")


func test_mit_n_eingriffen_zaehlt_nur_die_angenommenen() -> void:
	# Arrange (T082): eine Einplanung, die gilt, und ein Modifikator auf ein Ereignis, das nicht
	# über Wahrscheinlichkeit kommt; den lehnt jedes Spiel ab.
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)
	var protokoll: Array[Dictionary] = [
		{"at_day": -1, "kind": TimelineRun.INTERVENTION_SCHEDULE, "event_id": "zeitungsartikel",
			"day": _tag(1990, 6, 1), "reason": "Pressetermin"},
		{"at_day": -1, "kind": TimelineRun.INTERVENTION_ADD_MODIFIER, "modifier": {
			"event_id": "intel_pentium", "from_day": 0, "id": "rabatt", "reason": "Rabatt",
			"to_day": TimelineRun.LAST_DAY, "value": 0.05}},
	]
	panel.interventions_source = func() -> Array[Dictionary]: return protokoll
	_anzahl(panel, "3")
	panel.get_node("%WithInterventions").button_pressed = true

	# Act
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)

	# Assert
	assert_string_contains(panel.get_node("%ResultLabel").text, "mit 1 Eingriff aus dem Simulator")
	var hinweis: Label = panel.get_node("%RefusedNotice")
	assert_true(hinweis.visible)
	assert_string_contains(hinweis.text, "Modifikator: Intel Pentium erscheint ist kein Ereignis "
		+ "über Wahrscheinlichkeit")

	# Act und Assert: ohne Häkchen keine Warnung
	panel.get_node("%WithInterventions").button_pressed = false
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)
	assert_false(hinweis.visible)
	assert_string_contains(panel.get_node("%ResultLabel").text, "ohne Eingriffe")


# --- Katalog (FR-042) -------------------------------------------------------------------------

func test_fehlerhaftes_ereignis_wird_ausgenommen_und_genannt() -> void:
	# Arrange: intel_pentium liegt am 12.05.2001 (V06).
	var werkstatt := await _werkstatt(DATUM_AUSSERHALB)
	var panel := _statistik(werkstatt)
	_anzahl(panel, "5")

	# Act
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)

	# Assert: wie im Simulator, als gefülltes Feld in kassenrot
	var hinweis: Label = panel.get_node("%ExcludedNotice")
	assert_true(hinweis.visible)
	assert_string_contains(hinweis.text, "„%s“" % PENTIUM)
	assert_eq(hinweis.theme_type_variation, &"ErrorNoticeLabel")
	var titel := []
	for zeile: Array in _zeilen(panel):
		titel.append(zeile[StatisticsPanel.Column.EVENT])
	assert_eq(titel.size(), 4)
	assert_does_not_have(titel, PENTIUM, "Es fehlt in der Tabelle …")
	assert_null(panel.statistics.catalog.get_event("intel_pentium"), "… und in der Rechnung …")
	assert_not_null(werkstatt.editor.catalog.get_event("intel_pentium"), "… aber nicht im Katalog.")


func test_katalog_geaendert_waehrend_der_rechnung() -> void:
	# Arrange: 1.000 Spiele laufen.
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)
	var hinweis: Label = panel.get_node("%CatalogNotice")
	_druecken(panel, "%StartButton")
	var rechnung := panel.statistics
	assert_false(hinweis.visible)

	# Act: eine Änderung ohne Speichern
	werkstatt.editor.set_event_field("intel_pentium", &"date", _tag(1996, 3, 22))
	await wait_process_frames(1)

	# Assert: Der Hinweis erscheint, die Rechnung läuft mit ihrer Kopie weiter.
	assert_true(hinweis.visible)
	assert_eq(hinweis.text, "? Katalog geändert, neu starten")
	assert_eq(hinweis.theme_type_variation, &"WarningLabel")
	assert_true(panel.is_running())
	assert_same(panel.statistics, rechnung)
	assert_eq(rechnung.catalog.get_event("intel_pentium").date, _tag(1993, 3, 22))

	# Act und Assert: Rückgängig bringt den Katalog der Rechnung zurück; der Hinweis geht.
	werkstatt.editor.undo()
	await wait_process_frames(1)
	assert_false(hinweis.visible)
	_druecken(panel, "%CancelButton")
	# Die Schleife wartet noch auf das nächste Bild und endet erst dort. Endete der Test vorher,
	# gäbe GUT die Werkstatt frei, während das Signal die Schleife schon wecken will, und Godot
	# meldete „class instance is gone“.
	await wait_process_frames(1)


# --- Schwierigkeitsgrade (Feature 003, US4; FR-020, R15) --------------------------------------

func test_auswahl_mit_vier_eintraegen_vorgabe_mittel() -> void:
	# Arrange und Act
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)

	# Assert: hinter der Anzahl „Grad“ und die Auswahl (contracts/werkstatt.md, „Statistik“)
	var auswahl: OptionButton = panel.get_node("%DifficultyOption")
	var texte := []
	var kennungen := []
	for i in auswahl.item_count:
		texte.append(auswahl.get_item_text(i))
		kennungen.append(auswahl.get_item_id(i))
	assert_eq(texte, ["Leicht", "Mittel", "Schwer", "Alle drei vergleichen"])
	assert_eq(kennungen, [Difficulty.Level.LEICHT, Difficulty.Level.MITTEL,
		Difficulty.Level.SCHWER, StatisticsPanel.COMPARE_ALL])
	assert_eq(auswahl.get_selected_id(), Difficulty.Level.MITTEL, "Vorgabe Mittel")
	var leiste: Control = panel.get_node("%InputBar")
	assert_eq(auswahl.get_index(), panel.get_node("%CountEdit").get_index() + 2,
		"Hinter der Anzahl, nach dem Text „Grad“.")
	assert_eq((leiste.get_child(auswahl.get_index() - 1) as Label).text, "Grad")


func test_mittel_rechnet_wie_feature_002_mit_typisierter_liste() -> void:
	# Arrange
	var werkstatt := await _werkstatt(GRADE)
	var panel := _statistik(werkstatt)
	_anzahl(panel, "5")

	# Act
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)

	# Assert: immer ein Array[int] (Analyse, I2), hier nur Mittel; die Tabelle wie bisher.
	var grade := panel.statistics.difficulties
	assert_true(grade.is_typed(), "difficulties ist typisiert.")
	assert_eq(grade.get_typed_builtin(), TYPE_INT)
	assert_eq(grade, [Difficulty.Level.MITTEL] as Array[int])
	var tabelle: Tree = panel.get_node("%ResultTable")
	assert_eq(tabelle.columns, StatisticsPanel.TITLES.size())
	assert_eq(tabelle.get_column_title(StatisticsPanel.Column.MEAN), "Mittelwert")
	assert_string_starts_with(panel.get_node("%ProgressLabel").text, "100 % · 5 von 5 Spielen · ")


func test_ein_grad_allein_mit_tabelle_wie_bisher_und_grad_im_text() -> void:
	# Arrange
	var werkstatt := await _werkstatt(GRADE)
	var panel := _statistik(werkstatt)
	_anzahl(panel, "10")
	_grad(panel, Difficulty.Level.SCHWER)

	# Act
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)

	# Assert: sechs Spalten, die Werte von Schwer, der Text nennt Schwer.
	assert_eq(panel.statistics.difficulties, [Difficulty.Level.SCHWER] as Array[int])
	assert_eq(panel.get_node("%ResultTable").columns, StatisticsPanel.TITLES.size())
	var schwer := _ergebnis_fuer(panel, Difficulty.Level.SCHWER, "reklamationswelle")
	var zeile := _zeile(panel, "Reklamationswelle")
	assert_eq(zeile[StatisticsPanel.Column.MEAN], _komma(schwer.mean(), 2))
	var text: String = panel.get_node("%ResultLabel").text
	assert_string_starts_with(text, "Ergebnis über 10 Spiele, Seeds 1 bis 10, Schwer, ohne Eingriffe")

	# Act und Assert: Die Auswahl umstellen ändert nichts an Text und Tabelle; sie sagen, wozu das
	# Ergebnis gehört (R15).
	_grad(panel, StatisticsPanel.COMPARE_ALL)
	await wait_process_frames(1)
	assert_eq(panel.get_node("%ResultLabel").text, text)
	assert_eq(panel.get_node("%ResultTable").columns, StatisticsPanel.TITLES.size())

	# Act und Assert: Die Verteilung gibt es bei einem Grad wie bisher.
	_zeile_waehlen(panel, "Reklamationswelle")
	assert_eq(panel.year_bars().size(), EventStatistic.YEARS)
	assert_string_contains(panel.get_node("%YearTitle").text, "Reklamationswelle")


func test_vergleich_hat_zehn_spalten_mit_den_werten_aus_results_for() -> void:
	# Arrange (US4, Szenarien 1 und 3)
	var werkstatt := await _werkstatt(GRADE)
	var panel := _statistik(werkstatt)
	_anzahl(panel, "20")
	_grad(panel, StatisticsPanel.COMPARE_ALL)

	# Act
	_druecken(panel, "%StartButton")

	# Assert: Während gerechnet wird, gilt der Grad erst für den nächsten Start, und die Tabelle hat
	# schon ihre zehn Spalten.
	var tabelle: Tree = panel.get_node("%ResultTable")
	assert_true(panel.get_node("%DifficultyOption").disabled, "Gesperrt, solange es rechnet.")
	assert_eq(tabelle.columns, 10)
	assert_string_contains(panel.get_node("%ProgressLabel").text, "von 20 Spielen je Grad")
	await _bis_fertig(panel)

	# Assert: alle drei Grade, typisiert, und Titel samt Hinweis je Spalte
	assert_false(panel.get_node("%DifficultyOption").disabled)
	assert_eq(panel.statistics.difficulties, [Difficulty.Level.LEICHT, Difficulty.Level.MITTEL,
		Difficulty.Level.SCHWER] as Array[int])
	var titel := []
	for spalte in tabelle.columns:
		titel.append(tabelle.get_column_title(spalte))
		assert_false(tabelle.get_column_title_tooltip_text(spalte).is_empty(), "Hinweis %d" % spalte)
	assert_eq(titel, ["Ereignis", "Ø Leicht", "Ø Mittel", "Ø Schwer", "Spanne Leicht",
		"Spanne Mittel", "Spanne Schwer", "ohne Leicht", "ohne Mittel", "ohne Schwer"])
	assert_eq(tabelle.get_column_title_tooltip_text(3),
		"Mittelwert bei Schwer: so oft beginnt das Ereignis im Schnitt je Spiel")
	assert_string_starts_with(panel.get_node("%ProgressLabel").text,
		"100 % · 20 von 20 Spielen je Grad · ")
	assert_string_starts_with(panel.get_node("%ResultLabel").text, "Ergebnis über 20 Spiele je "
		+ "Grad, Seeds 1 bis 20, Leicht, Mittel und Schwer, ohne Eingriffe; gerechnet in ")

	# Assert: Jede Zelle kommt aus der Zählung ihres Grads.
	var zeilen := _zeilen(panel)
	var ergebnisse := []
	for grad in StatisticsPanel.COMPARED:
		ergebnisse.append(panel.statistics.results_for(grad))
	assert_eq(zeilen.size(), ergebnisse[0].size())
	for zeile_nr in zeilen.size():
		var zeile: Array = zeilen[zeile_nr]
		for stelle in 3:
			var wert: EventStatistic = ergebnisse[stelle][zeile_nr]
			assert_eq(zeile[0], wert.title)
			assert_eq([zeile[1 + stelle], zeile[4 + stelle], zeile[7 + stelle]],
				[_komma(wert.mean(), 2), "%d–%d" % [wert.minimum, wert.maximum],
				"%s %%" % _komma(wert.share_without() * 100.0, 1)],
				"%s, %s" % [wert.event_id, Difficulty.label(StatisticsPanel.COMPARED[stelle])])

	# Assert: Die Reklamationswelle unterscheidet die Grade; was kein Profil verändert, hat in allen
	# dreien dieselben Werte (US4, Szenario 3).
	var welle := _zeile(panel, "Reklamationswelle")
	assert_lt(_zahl(welle[1]), _zahl(welle[2]), "Leicht seltener als Mittel")
	assert_lt(_zahl(welle[2]), _zahl(welle[3]), "Mittel seltener als Schwer")
	for titel_fix: String in ["Windows 95 erscheint", "Weihnachtsgeschäft"]:
		var fix := _zeile(panel, titel_fix)
		for gruppe: int in [1, 4, 7]:
			assert_eq([fix[gruppe + 1], fix[gruppe + 2]], [fix[gruppe], fix[gruppe]],
				"%s, Spalte %d" % [titel_fix, gruppe])


func test_vergleich_laesst_den_bereich_der_verteilung_mit_text_stehen() -> void:
	# Arrange
	var werkstatt := await _werkstatt(GRADE)
	var panel := _statistik(werkstatt)
	_anzahl(panel, "3")
	_grad(panel, Difficulty.Level.MITTEL)
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)
	_zeile_waehlen(panel, "Reklamationswelle")
	assert_eq(panel.year_bars().size(), EventStatistic.YEARS, "Bei einem Grad mit Verteilung.")

	# Act
	_grad(panel, StatisticsPanel.COMPARE_ALL)
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)

	# Assert: Der Bereich bleibt mit seiner Mindesthöhe und sagt, wo es die Verteilung gibt (R15).
	var titel: Label = panel.get_node("%YearTitle")
	var flaeche: Control = panel.get_node("%YearChart")
	assert_eq(titel.text, "Die Verteilung auf die Jahre zeigt die Statistik für einen einzelnen "
		+ "Grad.")
	assert_eq(titel.theme_type_variation, &"MutedLabel")
	assert_true(flaeche.is_visible_in_tree(), "Der Bereich bleibt stehen.")
	assert_eq(flaeche.custom_minimum_size.y, 64.0)
	assert_eq(panel.year_bars().size(), 0, "Keine Balken, auch mit gewählter Zeile.")
	assert_eq(panel.get_node("%ResultTable").get_selected().get_text(0), "Reklamationswelle",
		"Die Zeile bleibt gewählt.")

	# Act und Assert: wieder ein Grad, wieder die Verteilung
	_grad(panel, Difficulty.Level.SCHWER)
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)
	assert_eq(panel.get_node("%ResultTable").columns, StatisticsPanel.TITLES.size())
	assert_eq(panel.year_bars().size(), EventStatistic.YEARS)
	assert_string_contains(titel.text, "Reklamationswelle")


func test_abbrechen_beim_vergleich_laesst_jedem_grad_gleich_viele_spiele() -> void:
	# Arrange: 1.000 Spiele je Grad; abgebrochen wird, sobald ein Seed in allen dreien fertig ist.
	var werkstatt := await _werkstatt(GRADE)
	var panel := _statistik(werkstatt)
	_grad(panel, StatisticsPanel.COMPARE_ALL)
	_druecken(panel, "%StartButton")
	var eines: bool = await wait_until(func() -> bool: return panel.statistics.games_done > 0, 10.0)
	assert_true(eines, "Ein Seed ist fertig.")

	# Act
	_druecken(panel, "%CancelButton")

	# Assert (FR-020)
	var fertig := panel.statistics.games_done
	assert_between(fertig, 1, 999)
	for grad in StatisticsPanel.COMPARED:
		for ergebnis in panel.statistics.results_for(grad):
			assert_eq(ergebnis.games, fertig, "%s, %s" % [ergebnis.event_id,
				Difficulty.label(grad)])
	assert_eq(panel.get_node("%ResultLabel").text, ("Abgebrochen nach %d von 1.000 Spielen je "
		+ "Grad. Das Ergebnis zeigt die %d fertigen, Seeds 1 bis %d, Leicht, Mittel und Schwer, "
		+ "ohne Eingriffe.") % [fertig, fertig, fertig])
	assert_string_contains(panel.get_node("%ProgressLabel").text,
		"%d von 1.000 Spielen je Grad" % fertig)
	assert_eq(_zeile(panel, "Windows 95 erscheint").slice(1, 4), ["1,00", "1,00", "1,00"])
	await wait_process_frames(3)
	assert_eq(panel.statistics.games_done, fertig, "Danach rechnet nichts mehr.")


func test_abbrechen_mit_einem_grad_nennt_ihn() -> void:
	# Arrange
	var werkstatt := await _werkstatt(GRADE)
	var panel := _statistik(werkstatt)
	_grad(panel, Difficulty.Level.SCHWER)
	_druecken(panel, "%StartButton")
	var eines: bool = await wait_until(func() -> bool: return panel.statistics.games_done > 0, 10.0)
	assert_true(eines, "Ein Spiel ist fertig.")

	# Act
	_druecken(panel, "%CancelButton")

	# Assert
	var fertig := panel.statistics.games_done
	assert_eq(panel.get_node("%ResultLabel").text, ("Abgebrochen nach %d von 1.000 Spielen. Das "
		+ "Ergebnis zeigt die %d fertigen, Seeds 1 bis %d, Schwer, ohne Eingriffe.") % [fertig,
		fertig, fertig])
	await wait_process_frames(1)


func test_vergleich_mit_haekchen_rechnet_alle_grade_mit_dem_eingriff() -> void:
	# Arrange (US4, Szenario 4): −4 Prozentpunkte auf den Lieferengpass, den kein Profil verändert
	var werkstatt := await _werkstatt(GRADE)
	var panel := _statistik(werkstatt)
	var protokoll: Array[Dictionary] = [
		{"at_day": -1, "kind": TimelineRun.INTERVENTION_ADD_MODIFIER, "modifier": {
			"event_id": "lieferengpass", "from_day": _tag(1990, 1, 1), "id": "engpass",
			"reason": "Engpass beim Großhändler", "to_day": TimelineRun.LAST_DAY, "value": -0.04}},
	]
	panel.interventions_source = func() -> Array[Dictionary]: return protokoll
	_anzahl(panel, "10")
	_grad(panel, StatisticsPanel.COMPARE_ALL)
	panel.get_node("%WithInterventions").button_pressed = true

	# Act
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)

	# Assert: in jedem Grad mit dem Eingriff, der Lieferengpass überall gleich
	assert_string_contains(panel.get_node("%ResultLabel").text,
		"Leicht, Mittel und Schwer, mit 1 Eingriff aus dem Simulator")
	var engpass: Array = []
	for grad in StatisticsPanel.COMPARED:
		engpass.append(_ergebnis_fuer(panel, grad, "lieferengpass").total)
	assert_eq(engpass, [engpass[0], engpass[0], engpass[0]])


func test_katalog_geaendert_nach_einer_aenderung_an_einem_profil() -> void:
	# Arrange (FR-020; Analyse, G4): Der Vergleich über 1.000 Spiele läuft.
	var werkstatt := await _werkstatt(GRADE)
	var panel := _statistik(werkstatt)
	var hinweis: Label = panel.get_node("%CatalogNotice")
	_grad(panel, StatisticsPanel.COMPARE_ALL)
	_druecken(panel, "%StartButton")
	var rechnung := panel.statistics

	# Act: Schwer +8 statt +5, ungespeichert
	werkstatt.editor.set_start_modifier_field(Difficulty.Level.SCHWER, 0, &"value", 0.08)
	await wait_process_frames(1)

	# Assert: Der Hinweis erscheint, die Rechnung bleibt beim alten Stand.
	assert_true(hinweis.visible)
	assert_eq(hinweis.text, "? Katalog geändert, neu starten")
	assert_true(panel.is_running())
	assert_same(panel.statistics, rechnung)
	assert_almost_eq(rechnung.catalog.get_profile(Difficulty.Level.SCHWER).modifiers[0].value,
		0.05, 0.0001)

	# Act und Assert: Rückgängig nimmt den Hinweis.
	werkstatt.editor.undo()
	await wait_process_frames(1)
	assert_false(hinweis.visible)
	_druecken(panel, "%CancelButton")
	await wait_process_frames(1)


func test_katalog_geaendert_wenn_nur_eine_lesemeldung_zu_einem_profil_verschwindet() -> void:
	# Arrange: In Schwer steht an Stelle 1 ein Wert als Text (V22 beim Lesen). In Leicht kommt ein
	# Start-Modifikator ohne Grund dazu (V29); dieser Profilfehler bleibt auch nach dem Speichern
	# stehen, damit sich nicht schon die Liste der fehlerhaften Kennungen ändert.
	var werkstatt := await _werkstatt(WERT_TEXT)
	var panel := _statistik(werkstatt)
	var hinweis: Label = panel.get_node("%CatalogNotice")
	werkstatt.editor.add_start_modifier(Difficulty.Level.LEICHT, "reklamationswelle")
	await wait_process_frames(1)
	var vorher := _weggelassen(werkstatt)
	assert_true(vorher.has("%d:1" % Difficulty.Level.SCHWER), "Schwer, Stelle 1 fehlt (V22).")
	_druecken(panel, "%StartButton")
	var inhalt := werkstatt.editor.content_key()

	# Act: Speichern verwirft die Meldungen beim Lesen; der Inhalt bleibt.
	assert_eq(werkstatt.editor.save(), OK)
	await wait_process_frames(1)

	# Assert: Ein neuer Start nähme Schwer, Stelle 1 mit; deshalb „Katalog geändert“.
	assert_eq(werkstatt.editor.content_key(), inhalt, "Der Inhalt ist derselbe.")
	assert_false(_weggelassen(werkstatt).has("%d:1" % Difficulty.Level.SCHWER))
	assert_true(_weggelassen(werkstatt).has("%d:0" % Difficulty.Level.LEICHT),
		"Der Fehler in Leicht steht noch.")
	assert_true(hinweis.visible)
	assert_true(panel.is_running(), "Die Rechnung bleibt beim alten Stand.")
	_druecken(panel, "%CancelButton")
	await wait_process_frames(1)


func test_ausgenommen_nennt_beide_arten_weggelassener_start_modifikatoren() -> void:
	# Arrange (FR-013; Analyse, G1): wie im Simulator
	var werkstatt := await _werkstatt(KAPUTT)
	var panel := _statistik(werkstatt)
	_anzahl(panel, "3")
	_grad(panel, Difficulty.Level.SCHWER)

	# Act
	_druecken(panel, "%StartButton")
	await _bis_fertig(panel)

	# Assert: das ausgenommene Ereignis, der Start-Modifikator mit eigenem Fehler und der, dessen
	# Ereignis ausgenommen ist
	var hinweis: Label = panel.get_node("%ExcludedNotice")
	assert_true(hinweis.visible)
	assert_eq(hinweis.text, "! Ausgenommen, weil fehlerhaft: „Lieferengpass“, Profil „Schwer“, "
		+ "Start-Modifikator „geisterereignis“, Profil „Schwer“, Start-Modifikator "
		+ "„lieferengpass“. Die Gründe stehen in der Prüfung.")
	var profil := panel.statistics.catalog.get_profile(Difficulty.Level.SCHWER)
	assert_eq(profil.modifiers.size(), 1, "Gerechnet wird nur mit dem dritten.")


# --- Helfer -----------------------------------------------------------------------------------

func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()


## Baut die Werkstatt mit einer Kopie von [param fixture] als Katalog und wartet den Start ab.
func _werkstatt(fixture: String = MINIMAL) -> Werkstatt:
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


## Die Statistik der Werkstatt; ihr Reiter wird gewählt, wie es Klaus täte.
func _statistik(werkstatt: Werkstatt) -> StatisticsPanel:
	var panel: StatisticsPanel = werkstatt.get_node("%StatisticsPanel")
	var tabs: TabContainer = werkstatt.get_node("%Tabs")
	tabs.current_tab = tabs.get_tab_idx_from_control(panel)
	return panel


## Schreibt [param text] ins Feld „Anzahl der Spiele“, wie getippt.
func _anzahl(panel: StatisticsPanel, text: String) -> void:
	var feld: LineEdit = panel.get_node("%CountEdit")
	feld.text = text
	feld.text_changed.emit(text)


func _druecken(panel: StatisticsPanel, knopf: String) -> void:
	var button: Button = panel.get_node(knopf)
	button.pressed.emit()


func _bis_fertig(panel: StatisticsPanel) -> void:
	var fertig: bool = await wait_until(func() -> bool: return not panel.is_running(), 10.0)
	assert_true(fertig, "Die Statistik ist fertig geworden.")


## Die Zeilen der Ergebnis-Tabelle, je Zeile die Texte ihrer Spalten.
func _zeilen(panel: StatisticsPanel) -> Array:
	var tabelle: Tree = panel.get_node("%ResultTable")
	var zeilen := []
	for zeile in tabelle.get_root().get_children():
		var texte := []
		for spalte in tabelle.columns:
			texte.append(zeile.get_text(spalte))
		zeilen.append(texte)
	return zeilen


## Wählt die Zeile mit dem Titel [param titel], wie mit der Maus.
func _zeile_waehlen(panel: StatisticsPanel, titel: String) -> void:
	var tabelle: Tree = panel.get_node("%ResultTable")
	for zeile in tabelle.get_root().get_children():
		if zeile.get_text(StatisticsPanel.Column.EVENT) == titel:
			zeile.select(StatisticsPanel.Column.EVENT)
			return
	fail_test("„%s“ fehlt in der Tabelle." % titel)


func _ergebnis(panel: StatisticsPanel, kennung: String) -> EventStatistic:
	for ergebnis in panel.statistics.results():
		if ergebnis.event_id == kennung:
			return ergebnis
	fail_test("Keine Statistik für %s." % kennung)
	return EventStatistic.new()


## Wählt in %DifficultyOption den Eintrag mit der Kennung [param kennung], wie mit der Maus; der
## Grad gilt beim nächsten „Starten“.
func _grad(panel: StatisticsPanel, kennung: int) -> void:
	var auswahl: OptionButton = panel.get_node("%DifficultyOption")
	var stelle := auswahl.get_item_index(kennung)
	auswahl.select(stelle)
	auswahl.item_selected.emit(stelle)


## Die Texte der Zeile mit dem Titel [param titel].
func _zeile(panel: StatisticsPanel, titel: String) -> Array:
	for zeile: Array in _zeilen(panel):
		if zeile[0] == titel:
			return zeile
	fail_test("„%s“ fehlt in der Tabelle." % titel)
	return []


func _ergebnis_fuer(panel: StatisticsPanel, grad: int, kennung: String) -> EventStatistic:
	for ergebnis in panel.statistics.results_for(grad):
		if ergebnis.event_id == kennung:
			return ergebnis
	fail_test("Keine Statistik für %s bei %s." % [kennung, Difficulty.label(grad)])
	return EventStatistic.new()


## Eine Zahl mit [param stellen] Nachkommastellen und Komma, wie die Tabelle sie zeigt (unter 1.000).
func _komma(wert: float, stellen: int) -> String:
	return (("%." + str(stellen) + "f") % wert).replace(".", ",")


## Die Start-Modifikatoren, die ein neuer Start weglassen würde, als „Grad:Stelle“.
func _weggelassen(werkstatt: Werkstatt) -> PackedStringArray:
	var stellen := PackedStringArray()
	for skip in werkstatt.editor.catalog.skipped_start_modifiers(werkstatt.editor.issues()):
		stellen.append("%d:%d" % [skip["level"], skip["index"]])
	return stellen


## „30,0 %“ als Zahl 30.0.
func _zahl(text: String) -> float:
	return text.trim_suffix("%").strip_edges().replace(".", "").replace(",", ".").to_float()


## „Modifikator …“ im Simulator für [param ereignis], ausgefüllt und gesetzt, wie in
## test_simulator.gd.
func _modifikator(simulator: SimulatorPanel, grund: String, wert: String, von: String,
		bis: String, ereignis: String = "reklamationswelle") -> void:
	var dialog: InterventionDialog = simulator.get_node("%InterventionDialog")
	simulator.get_node("%ModifierButton").pressed.emit()
	var auswahl: OptionButton = dialog.get_node("%EventChoice")
	for i in auswahl.item_count:
		if auswahl.get_item_text(i).ends_with("(%s)" % ereignis):
			auswahl.select(i)
	for pfad: String in ["%ValueEdit", "%ReasonEdit", "%FromEdit", "%ToEdit"]:
		var feld: LineEdit = dialog.get_node(pfad)
		feld.text = {"%ValueEdit": wert, "%ReasonEdit": grund, "%FromEdit": von,
			"%ToEdit": bis}[pfad]
	dialog.get_ok_button().pressed.emit()
