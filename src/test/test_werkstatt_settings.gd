extends GutTest

## Die Werkstatt merkt sich die Lage ihrer Teiler (Feature 002, Phase 10): Ziehen speichert sie
## entprellt in einer Einstellungsdatei, der nächste Start stellt sie wieder her, eine Lage, die
## nicht ins Fenster passt, lässt jeden Bereich sichtbar, und eine kaputte Datei lässt still die
## Vorgaben gelten.
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
		namen.append(String(werkstatt.get_path_to(split)))
	assert_eq(namen, [LISTE_MITTE_FORMULAR, ZEITSTRAHL_REITER, SIMULATOR, SIMULATOR_FAHRPLAN,
		SIMULATOR_PROTOKOLL, STATISTIK], "Liste | Mitte | Formular, Zeitstrahl über Reitern, "
		+ "die drei im Simulator und der in der Statistik.")


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
	assert_eq(datei.get_section_keys(Werkstatt.SPLITS_SECTION).size(), 6,
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
	}
	for teiler: String in weit:
		datei.set_value(Werkstatt.SPLITS_SECTION, teiler, PackedInt32Array(weit[teiler]))
	datei.save(EINSTELLUNGEN)

	# Act: ein kleines Fenster, beide Reiter einmal vorn
	var werkstatt := await _werkstatt(KLEIN)
	var tabs: TabContainer = werkstatt.get_node("%Tabs")
	var geprueft := 0
	for reiter: Control in [werkstatt.get_node("%SimulatorPanel"),
			werkstatt.get_node("%StatisticsPanel")]:
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
	assert_eq(geprueft, 8, "Je Reiter Liste | Mitte | Formular und Zeitstrahl über Reitern, dazu "
		+ "die drei Teiler im Simulator bzw. der in der Statistik.")


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


func _split(werkstatt: Werkstatt, pfad: String) -> SplitContainer:
	return werkstatt.get_node(pfad)


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
