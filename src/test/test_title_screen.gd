extends GutTest

## Prüft den Text der Versionszeile auf dem Titelbildschirm (FR-014): Aus der Versionsnummer
## des Projekts wird „V0.1 · PROTOTYP“, ohne Nummer steht nur „PROTOTYP“ da.
##
## `version_text()` ist statisch. Die Tests rufen sie an der Klasse auf und brauchen
## deshalb keinen Titelbildschirm im Baum.
##
## Seit Feature 004 (T013) dazu: Die Hauptszene läuft, und es beginnt kein Spiel von selbst.


func test_version_wird_mit_v_und_kennzeichen_gezeigt() -> void:
	# Act
	var text := TitleScreen.version_text("0.1")

	# Assert
	assert_eq(text, "V0.1 · PROTOTYP",
		"Vor der Nummer steht ein V, dahinter mit Mittelpunkt das Kennzeichen.")


func test_ohne_version_steht_nur_das_kennzeichen_da() -> void:
	# Act
	var text := TitleScreen.version_text("")

	# Assert
	assert_eq(text, "PROTOTYP", "Ohne Nummer darf kein „V“ ohne Zahl erscheinen.")


func test_hauptszene_laeuft_und_es_beginnt_kein_spiel() -> void:
	# Arrange (FR-003; US1, Szenario 5): die Hauptszene aus project.godot und das echte Autoload
	# Timeline. Es kommt über seinen Pfad; seinen Namen kennt GDScript in einem Skript, das mit -s
	# startet, nicht. Der Test beginnt kein Spiel und schreibt nichts.
	var pfad: String = ProjectSettings.get_setting("application/run/main_scene")
	var zeitleiste := get_node(^"/root/Timeline")
	var szene: PackedScene = load(pfad)

	# Act: mehrere Bilder, länger als bis zum früheren Selbststart am Ende des ersten
	var titel: Node = add_child_autofree(szene.instantiate())
	await wait_process_frames(5)

	# Assert
	assert_eq(pfad, "res://scenes/title/title_screen.tscn", "Die Hauptszene ist der Titel.")
	assert_true(titel.is_inside_tree(), "Die Szene läuft.")
	assert_null(zeitleiste.run, "Ohne Beginn läuft kein Spiel.")
