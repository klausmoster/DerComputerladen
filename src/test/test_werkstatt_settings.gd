extends GutTest

## Die Werkstatt merkt sich die Lage ihrer Teiler (Feature 002, Phase 10): Ziehen speichert sie
## entprellt in einer Einstellungsdatei, der nächste Start stellt sie wieder her, eine Lage, die
## nicht ins Fenster passt, lässt jeden Bereich sichtbar, und eine kaputte Datei lässt still die
## Vorgaben gelten. Aus Phase 8 (T043): Im kleinen Fenster rollt ein Reiter, der zu hoch ist, bei
## Klaus' Größe rollt keiner, und die Teiler behalten in der Datei ihre Namen.
##
## Jeder Test setzt Katalog, Sicherungskopie und Einstellungsdatei in einen eigenen Ordner unter
## user://, bevor die Szene in den Baum kommt; after_each() räumt ihn weg. Die echte
## Einstellungsdatei liest und schreibt kein Test.

const SZENE := preload("res://tools/werkstatt/werkstatt.tscn")
const ORDNER := "user://test_werkstatt_settings/"
const EINSTELLUNGEN := ORDNER + "einstellungen.cfg"
const MINIMAL := "res://test/fixtures/catalog_minimal.json"
## Die echte Einstellungsdatei; die Tests sehen nur nach, dass sie unberührt bleibt.
const ECHTE_DATEI := "user://werkstatt_einstellungen.cfg"
## Die Teiler der Werkstatt mit ihrem Namen in der Datei.
const LISTE_MITTE_FORMULAR := "Layout/Main"
const ZEITSTRAHL_REITER := "Layout/Main/Center"
const SIMULATOR := "Layout/Main/Center/Tabs/SimulatorPanel/Split"
const SIMULATOR_FAHRPLAN := "Layout/Main/Center/Tabs/SimulatorPanel/Split/PlanSplit"
const SIMULATOR_PROTOKOLL := "Layout/Main/Center/Tabs/SimulatorPanel/Split/ProtocolBox"
const STATISTIK := "Layout/Main/Center/Tabs/StatisticsPanel/Split"
const SCHWIERIGKEITSGRADE := "Layout/Main/Center/Tabs/DifficultyPanel/Split"
## Die Fenstergröße, die Klaus' Bildschirm hat (1920 × 925), und eine kleine.
const GROSS := Vector2(1920, 925)
const KLEIN := Vector2(1280, 720)


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)


func after_each() -> void:
	var ordner := DirAccess.open(ORDNER)
	if ordner != null:
		for datei in ordner.get_files():
			ordner.remove(datei)
	DirAccess.remove_absolute(ORDNER)


func test_alle_teiler_sind_dabei_und_die_vorgabe_liegt_unter_user() -> void:
	# Arrange und Act: die Vorgabe am bloßen Skript, ohne Szene
	var neue := Werkstatt.new()
	var vorgabe := neue.settings_path
	neue.free()
	var werkstatt := await _werkstatt()

	# Assert
	assert_eq(vorgabe, ECHTE_DATEI, "Die Einstellungen liegen außerhalb des Projekts.")
	var namen := []
	for split in werkstatt.splits():
		namen.append(werkstatt._split_key(split))
	assert_eq(namen, [LISTE_MITTE_FORMULAR, ZEITSTRAHL_REITER, SIMULATOR, SIMULATOR_FAHRPLAN,
		SIMULATOR_PROTOKOLL, STATISTIK, SCHWIERIGKEITSGRADE], "Liste | Mitte | Formular, "
		+ "Zeitstrahl über Reitern, die drei im Simulator, der in der Statistik und der zwischen "
		+ "Tabelle und Feldern im Reiter „Schwierigkeitsgrade“.")
	# Seit T043 liegen die Teiler der Reiter in deren Rollbereich; ihre Namen in der Datei bleiben,
	# damit Klaus' gespeicherte Lage weiter gilt.
	for reiter: String in ["%SimulatorPanel", "%StatisticsPanel", "%DifficultyPanel"]:
		var rollbereich: ScrollContainer = werkstatt.get_node(reiter).get_node("Scroll")
		assert_eq(String(werkstatt.get_path_to(rollbereich.get_child(0))),
			String(werkstatt.get_path_to(werkstatt.get_node(reiter))) + "/Scroll/Content")
	assert_true(werkstatt.get_node("%SimulatorPanel/Scroll").is_ancestor_of(
		_split(werkstatt, SIMULATOR_PROTOKOLL)), "Der Name ohne „Scroll/Content“ findet den Teiler.")


func test_ziehen_speichert_die_teiler_entprellt() -> void:
	# Arrange
	var echte_vorher := _stand(ECHTE_DATEI)
	var werkstatt := await _werkstatt()
	var timer: Timer = werkstatt.get_node("%SettingsTimer")
	var main := _split(werkstatt, LISTE_MITTE_FORMULAR)

	# Act: Klaus zieht; der Teiler meldet sich bei jeder Bewegung.
	main.split_offsets = PackedInt32Array([420, -460])
	main.dragged.emit(420)
	main.dragged.emit(421)

	# Assert: Gespeichert wird noch nicht, erst wenn eine Sekunde Ruhe ist.
	assert_false(timer.is_stopped(), "Das Ziehen startet die Wartezeit.")
	assert_eq(timer.wait_time, Werkstatt.SETTINGS_DELAY)
	assert_true(timer.one_shot)
	assert_false(FileAccess.file_exists(EINSTELLUNGEN),
		"Während des Ziehens wird nichts geschrieben.")

	# Act: Die Wartezeit ist um.
	timer.timeout.emit()

	# Assert
	assert_true(timer.is_stopped())
	var datei := ConfigFile.new()
	assert_eq(datei.load(EINSTELLUNGEN), OK)
	assert_eq(datei.get_value(Werkstatt.SPLITS_SECTION, LISTE_MITTE_FORMULAR),
		PackedInt32Array([420, -460]))
	assert_eq(datei.get_section_keys(Werkstatt.SPLITS_SECTION).size(), 7,
		"Alle Teiler stehen drin.")
	assert_eq(_stand(ECHTE_DATEI), echte_vorher, "Die echte Einstellungsdatei bleibt unberührt.")


func test_der_naechste_start_stellt_die_teiler_wieder_her() -> void:
	# Arrange: Eine frühere Sitzung hat gespeichert.
	var erste := await _werkstatt()
	_split(erste, LISTE_MITTE_FORMULAR).split_offsets = PackedInt32Array([420, -460])
	_split(erste, ZEITSTRAHL_REITER).split_offsets = PackedInt32Array([-60])
	_split(erste, SIMULATOR).split_offsets = PackedInt32Array([150])
	_split(erste, STATISTIK).split_offsets = PackedInt32Array([40])
	assert_eq(erste.save_settings(), OK)
	# Aus dem Baum genügt; freigegeben wird sie mit den anderen am Ende des Tests.
	remove_child(erste)

	# Act
	var werkstatt := await _werkstatt()

	# Assert: die Werte und die Lage, die sie ergeben
	assert_eq(_split(werkstatt, LISTE_MITTE_FORMULAR).split_offsets,
		PackedInt32Array([420, -460]))
	assert_eq(_split(werkstatt, ZEITSTRAHL_REITER).split_offsets, PackedInt32Array([-60]))
	assert_eq(_split(werkstatt, SIMULATOR).split_offsets, PackedInt32Array([150]))
	assert_eq(_split(werkstatt, SIMULATOR_FAHRPLAN).split_offsets, PackedInt32Array([0]))
	assert_eq(_split(werkstatt, STATISTIK).split_offsets, PackedInt32Array([40]))
	var main := _split(werkstatt, LISTE_MITTE_FORMULAR)
	assert_eq(main.get_child(0).size.x, 420.0, "Die Liste ist so breit wie gezogen.")
	assert_eq(main.get_child(2).size.x, 460.0, "Das Formular auch.")


func test_zu_grosse_lage_wird_begrenzt_und_jeder_bereich_bleibt_sichtbar() -> void:
	# Arrange: auf einem großen Bildschirm gezogen, bis an den Rand und darüber hinaus
	var datei := ConfigFile.new()
	var weit := {
		LISTE_MITTE_FORMULAR: [5000, -5000], ZEITSTRAHL_REITER: [5000], SIMULATOR: [-5000],
		SIMULATOR_FAHRPLAN: [5000], SIMULATOR_PROTOKOLL: [-5000], STATISTIK: [5000],
		SCHWIERIGKEITSGRADE: [5000],
	}
	for teiler: String in weit:
		datei.set_value(Werkstatt.SPLITS_SECTION, teiler, PackedInt32Array(weit[teiler]))
	datei.save(EINSTELLUNGEN)

	# Act: ein kleines Fenster, jeder Reiter mit Teiler einmal vorn
	var werkstatt := await _werkstatt(KLEIN)
	var tabs: TabContainer = werkstatt.get_node("%Tabs")
	var geprueft := 0
	for reiter: Control in [werkstatt.get_node("%SimulatorPanel"),
			werkstatt.get_node("%StatisticsPanel"), werkstatt.get_node("%DifficultyPanel")]:
		tabs.current_tab = tabs.get_tab_idx_from_control(reiter)
		await wait_process_frames(2)

		# Assert: Jeder Bereich hat mindestens seine Mindestgröße und liegt im Teiler.
		for split in werkstatt.splits():
			if not split.is_visible_in_tree():
				continue
			geprueft += 1
			var achse := 1 if split.vertical else 0
			for kind in split.get_children():
				var bereich := kind as Control
				var stelle := "%s/%s" % [werkstatt.get_path_to(split), bereich.name]
				assert_gte(bereich.size[achse], bereich.get_combined_minimum_size()[achse],
					"%s behält seine Mindestgröße." % stelle)
				assert_gte(bereich.get_combined_minimum_size()[achse], 80.0,
					"%s ist auch dann zu sehen." % stelle)
				assert_gte(bereich.position[achse], 0.0, "%s beginnt im Teiler." % stelle)
				assert_lte(bereich.position[achse] + bereich.size[achse],
					split.size[achse] + 0.5, "%s endet im Teiler." % stelle)
	assert_eq(geprueft, 11, "Je Reiter Liste | Mitte | Formular und Zeitstrahl über Reitern, dazu "
		+ "die drei Teiler im Simulator, der in der Statistik bzw. der im Reiter "
		+ "„Schwierigkeitsgrade“.")


func test_im_kleinen_fenster_passt_jeder_reiter_in_die_breite() -> void:
	# Arrange (Feature 003, T017): Ist die Mitte breiter, als Liste und Formular ihr lassen, wächst
	# Layout über das Fenster hinaus, nach beiden Seiten, und Toolbar und Formular sind am Rand
	# abgeschnitten. Der Reiter „Schwierigkeitsgrade“ tat das zuerst mit 40 Pixeln je Seite.
	var werkstatt := await _werkstatt(KLEIN)
	var tabs: TabContainer = werkstatt.get_node("%Tabs")
	var layout: Control = werkstatt.get_node("Layout")

	for i in tabs.get_tab_count():
		# Act
		tabs.current_tab = i
		await wait_process_frames(2)

		# Assert
		var titel := tabs.get_tab_title(i)
		assert_gte(layout.position.x, 0.0, "„%s“: Layout beginnt im Fenster." % titel)
		assert_lte(layout.position.x + layout.size.x, KLEIN.x,
			"„%s“: Layout endet im Fenster." % titel)


func test_im_kleinen_fenster_passt_jeder_reiter_in_die_hoehe() -> void:
	# Arrange (T043; Quickstart 002, 4.1, „Fenster verkleinern“): Bei 1280 × 720 war der Simulator
	# höher, als das Fenster hergab. Layout wuchs nach oben und unten hinaus, und Toolbar und Knöpfe
	# lagen außerhalb. Jetzt rollt der Inhalt eines Reiters, der nicht mehr hineinpasst.
	var werkstatt := await _werkstatt(KLEIN)
	var tabs: TabContainer = werkstatt.get_node("%Tabs")
	var layout: Control = werkstatt.get_node("Layout")
	var toolbar: Control = werkstatt.get_node("Layout/Toolbar")
	var fenster := Rect2(Vector2.ZERO, KLEIN)
	var gerollt := []

	for i in tabs.get_tab_count():
		# Act
		tabs.current_tab = i
		await wait_process_frames(2)

		# Assert: Alles liegt im Fenster, die Toolbar ganz oben.
		var titel := tabs.get_tab_title(i)
		var reiter := tabs.get_tab_control(i)
		assert_gte(layout.position.y, 0.0, "„%s“: Layout beginnt im Fenster." % titel)
		assert_lte(layout.position.y + layout.size.y, KLEIN.y, "„%s“: Layout endet im Fenster." % titel)
		assert_true(fenster.encloses(toolbar.get_global_rect()),
			"„%s“: Die Toolbar ist ganz zu sehen, %s." % [titel, toolbar.get_global_rect()])
		assert_true(fenster.encloses(reiter.get_global_rect()),
			"„%s“: Der Reiter liegt im Fenster, %s." % [titel, reiter.get_global_rect()])
		var rollbereich := Werkstatt._tab_scroll(reiter)
		if rollbereich == null:
			continue
		var inhalt: Control = rollbereich.get_child(0)
		if inhalt.size.y <= rollbereich.size.y:
			assert_false(rollbereich.get_v_scroll_bar().visible, "„%s“ passt und rollt nicht." % titel)
			continue
		gerollt.append(titel)
		assert_true(rollbereich.get_v_scroll_bar().visible,
			"„%s“: Eine Rollleiste zeigt, dass unten mehr kommt." % titel)
		assert_true(rollbereich.clip_contents, "„%s“: Was nicht hineinpasst, schneidet er ab." % titel)

		# Act: ganz nach unten rollen
		rollbereich.scroll_vertical = ceili(inhalt.size.y)
		await wait_process_frames(1)

		# Assert: Das Ende des Inhalts mit den Knöpfen ist zu sehen.
		assert_almost_eq(inhalt.get_global_rect().end.y, rollbereich.get_global_rect().end.y, 0.5,
			"„%s“: Gerollt steht das Ende des Inhalts am Ende des Reiters." % titel)
	assert_eq(gerollt, ["Simulator"], "In dieser Größe muss nur der Simulator rollen.")


func test_bei_klaus_groesse_rollt_kein_reiter() -> void:
	# Arrange (T043): Bei 1920 × 925 in der Vorgabe-Teilung bleibt alles, wie es war. Der
	# Rollbereich rollt nicht, hat keine Leiste, und sein Inhalt füllt den Reiter genau.
	var werkstatt := await _werkstatt()
	var tabs: TabContainer = werkstatt.get_node("%Tabs")
	var geprueft := 0

	for i in tabs.get_tab_count():
		# Act
		tabs.current_tab = i
		await wait_process_frames(2)

		# Assert
		var titel := tabs.get_tab_title(i)
		var reiter := tabs.get_tab_control(i)
		var rollbereich := Werkstatt._tab_scroll(reiter)
		if rollbereich == null:
			continue
		geprueft += 1
		var inhalt: Control = rollbereich.get_child(0)
		assert_eq(rollbereich.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED,
			"„%s“ rollt nicht." % titel)
		assert_false(rollbereich.get_v_scroll_bar().visible, "„%s“ hat keine Rollleiste." % titel)
		assert_false(rollbereich.clip_contents,
			"„%s“ schneidet nichts ab, auch keine Fokuslinie am Rand." % titel)
		assert_eq(rollbereich.get_global_rect(), reiter.get_global_rect(),
			"„%s“: Der Rollbereich nimmt den ganzen Reiter." % titel)
		assert_eq(inhalt.get_global_rect(), reiter.get_global_rect(),
			"„%s“: Der Inhalt steht, wo er vorher direkt im Reiter stand." % titel)
	assert_eq(geprueft, 3, "Simulator, Statistik und Schwierigkeitsgrade; die Prüfung rollt selbst.")


func test_kaputte_datei_laesst_die_vorgaben_ohne_meldung() -> void:
	# Arrange: abgebrochen geschrieben
	_schreiben(EINSTELLUNGEN, "[teiler]\nLayout/Main=PackedInt32Array(420, -46")

	# Act
	var werkstatt := await _werkstatt()

	# Assert: Vorgaben, kein Dialog, keine Meldung von Godot
	for split in werkstatt.splits():
		assert_eq(split.split_offsets, _vorgabe(split), "%s steht auf der Vorgabe."
			% werkstatt.get_path_to(split))
	for kind in werkstatt.get_children():
		if kind is Window:
			assert_false(kind.visible, "%s bleibt zu." % kind.name)
	assert_engine_error_count(0, "Die kaputte Datei meldet niemand.")

	# Act und Assert: Speichern macht die Datei wieder heil.
	assert_eq(werkstatt.save_settings(), OK)
	var datei := ConfigFile.new()
	assert_eq(datei.load(EINSTELLUNGEN), OK)
	assert_eq(datei.get_value(Werkstatt.SPLITS_SECTION, LISTE_MITTE_FORMULAR),
		PackedInt32Array([0, 0]))


func test_unpassende_eintraege_gelten_nicht_die_passenden_schon() -> void:
	# Arrange: von Hand geändert. Text, falsche Länge, Bruchteile und Riesenwerte gelten nicht.
	_schreiben(EINSTELLUNGEN, "\n".join([
		"[teiler]",
		"Layout/Main=\"breit\"",
		"Layout/Main/Center=PackedInt32Array(10, 20)",
		"Layout/Main/Center/Tabs/SimulatorPanel/Split=[12.5]",
		"Layout/Main/Center/Tabs/SimulatorPanel/Split/PlanSplit=[9999999]",
		"Layout/Main/Center/Tabs/SimulatorPanel/Split/ProtocolBox=[-40.0]",
		"Layout/Main/Center/Tabs/StatisticsPanel/Split=PackedInt32Array(30)",
	]) + "\n")

	# Act
	var werkstatt := await _werkstatt()

	# Assert
	assert_eq(_split(werkstatt, LISTE_MITTE_FORMULAR).split_offsets, PackedInt32Array([0, 0]))
	assert_eq(_split(werkstatt, ZEITSTRAHL_REITER).split_offsets, PackedInt32Array([0]))
	assert_eq(_split(werkstatt, SIMULATOR).split_offsets, PackedInt32Array([0]))
	assert_eq(_split(werkstatt, SIMULATOR_FAHRPLAN).split_offsets, PackedInt32Array([0]))
	assert_eq(_split(werkstatt, SIMULATOR_PROTOKOLL).split_offsets, PackedInt32Array([-40]),
		"Eine ganze Zahl als Kommazahl ist von Hand schnell geschrieben und gilt.")
	assert_eq(_split(werkstatt, STATISTIK).split_offsets, PackedInt32Array([30]))
	assert_engine_error_count(0)


# --- Helfer -----------------------------------------------------------------------------------

## Baut die Werkstatt mit einer Kopie von catalog_minimal und den Dateien des Tests, in der Größe
## [param groesse], und wartet, bis der Start gelaufen ist und alles angeordnet ist.
func _werkstatt(groesse: Vector2 = GROSS) -> Werkstatt:
	var ziel := ORDNER + "katalog.json"
	_schreiben(ziel, FileAccess.get_file_as_string(MINIMAL))
	var werkstatt: Werkstatt = SZENE.instantiate()
	werkstatt.catalog_path = ziel
	werkstatt.editor.backup_folder = ORDNER
	werkstatt.settings_path = EINSTELLUNGEN
	# Headless ist das Fenster winzig; die Werkstatt bekommt deshalb selbst eine Größe. Mit
	# Ankern über das ganze Fenster legte Godot die Größe nach dem Fenster fest, nicht nach size.
	werkstatt.set_anchors_preset(Control.PRESET_TOP_LEFT)
	werkstatt.size = groesse
	add_child_autofree(werkstatt)
	await wait_process_frames(3)
	return werkstatt


## Der Teiler, der in der Einstellungsdatei [param name] heißt. Seit T043 ist das nicht mehr
## überall sein Pfad: Die Teiler der Reiter liegen in deren Rollbereich „Scroll/Content“.
func _split(werkstatt: Werkstatt, name: String) -> SplitContainer:
	for split in werkstatt.splits():
		if werkstatt._split_key(split) == name:
			return split
	fail_test("Kein Teiler heißt in der Datei „%s“." % name)
	return autofree(HSplitContainer.new())


## Die Vorgabe der Szene: 0 für jeden Teiler.
func _vorgabe(split: SplitContainer) -> PackedInt32Array:
	var nullen := PackedInt32Array()
	nullen.resize(split.split_offsets.size())
	nullen.fill(0)
	return nullen


func _schreiben(ziel: String, text: String) -> void:
	var datei := FileAccess.open(ziel, FileAccess.WRITE)
	datei.store_string(text)
	datei.close()


## Ob es die Datei gibt und wann sie zuletzt geändert wurde.
func _stand(pfad: String) -> Array:
	if not FileAccess.file_exists(pfad):
		return [false, 0]
	return [true, FileAccess.get_modified_time(pfad)]
