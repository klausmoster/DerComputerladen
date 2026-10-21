extends GutTest

## Prüft die Statistik in der Werkstatt (Feature 002, T066; FR-042, FR-044, FR-045; US7,
## Szenarien 1, 2 und 4): den Reiter „Statistik“, das Rechnen in Häppchen mit Fortschritt, das
## Abbrechen, die Tabelle mit „–“ ohne Obergrenze, die Verteilung auf die Jahre, das Häkchen für
## die Eingriffe des Simulators, den Hinweis auf ausgenommene Ereignisse und auf einen geänderten
## Katalog. Die Zählung selbst prüft test_timeline_statistics.gd.
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
	# Ohne Anzahl geht „Starten“ nicht, und ein Hinweis sagt, warum.
	_anzahl(panel, "")
	assert_true(panel.get_node("%StartButton").disabled)
	assert_true(panel.get_node("%CountHint").visible)
	# Beim Verlassen des Felds steht die Anzahl mit Tausenderpunkt da.
	_anzahl(panel, "2500")
	feld.focus_exited.emit()
	assert_eq(feld.text, "2.500")
	assert_false(panel.get_node("%StartButton").disabled)
	assert_false(panel.get_node("%CountHint").visible)


# --- Rechnen (US7, Szenarien 1 und 2) ---------------------------------------------------------

func test_starten_rechnet_in_haeppchen_und_zeigt_das_ergebnis() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)
	_anzahl(panel, "40")

	# Act: Das erste Häppchen rechnet „Starten“ selbst.
	_druecken(panel, "%StartButton")

	# Assert: Es läuft, und dazwischen bekommt die Werkstatt ihre Bilder (R17).
	var fortschritt: ProgressBar = panel.get_node("%Progress")
	var erstes := panel.statistics.games_done
	assert_true(panel.is_running())
	assert_between(erstes, 1, 39, "Ein Häppchen von 15 ms reicht nicht für 40 Spiele.")
	assert_eq([fortschritt.max_value, fortschritt.value], [40.0, float(erstes)])
	assert_string_contains(panel.get_node("%ProgressLabel").text, "von 40 Spielen")
	assert_true(panel.get_node("%StartButton").disabled)
	assert_false(panel.get_node("%CancelButton").disabled)
	assert_false(panel.get_node("%CountEdit").editable, "Die Anzahl gilt erst beim nächsten Start.")
	await wait_process_frames(1)
	assert_gt(panel.statistics.games_done, erstes, "Ein Bild später ist sie weiter.")

	# Act
	await _bis_fertig(panel)

	# Assert: 100 % und eine Zeile je Ereignis nach Kennung; „–“ ohne Obergrenze (FR-044)
	assert_eq(fortschritt.value, 40.0)
	assert_string_starts_with(panel.get_node("%ProgressLabel").text, "100 % · 40 von 40 Spielen")
	assert_string_starts_with(panel.get_node("%ResultLabel").text,
		"Ergebnis über 40 Spiele, Seeds 1 bis 40, ohne Eingriffe")
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
	# Arrange: die Vorgabe, 1.000 Spiele
	var werkstatt := await _werkstatt()
	var panel := _statistik(werkstatt)
	_druecken(panel, "%StartButton")
	await wait_process_frames(2)

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
	werkstatt.editor.backup_path = ORDNER + "sicherung.json"
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
