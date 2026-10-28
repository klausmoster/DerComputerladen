extends GutTest

## Prüft SelbsttestAblage (Feature 007, T004; R11; data-model.md, „Ergebnis eines Laufs“):
## Ordner des Laufs, Fotos als PNG, Protokoll und Ausgabe als UTF-8 ohne BOM, das Zip daneben und
## die Meldung, wenn sich nicht schreiben lässt.
##
## Alles geschieht im eigenen Ordner BASIS, den after_each() wieder abräumt; nie in
## user://selbsttest/ der App und nie in user://spielstaende/.

const BASIS := "user://test_selbsttest_ablage/"
const LAUF_ID := "2026-10-28_14-03-12"

var _ablage: SelbsttestAblage


func before_each() -> void:
	_ablage = SelbsttestAblage.new(LAUF_ID, BASIS)
	_ablage.system = "macos"


func after_each() -> void:
	_raeume_auf(BASIS)


func test_vorgaben() -> void:
	# Act
	var ablage := SelbsttestAblage.new(LAUF_ID)

	# Assert
	assert_eq(ablage.basis, "user://selbsttest/")
	assert_eq(ablage.system, OS.get_name().to_lower(), "macos, windows, linux")


func test_legt_ordner_und_fotos_an() -> void:
	# Act
	var fehler := _ablage.lege_an()

	# Assert
	assert_eq(fehler, OK)
	assert_true(DirAccess.dir_exists_absolute(BASIS + LAUF_ID + "/fotos"))
	assert_false(FileAccess.file_exists(BASIS + LAUF_ID + "/" + SelbsttestAblage.PROBE),
		"Die Probedatei bleibt nicht liegen.")


func test_pfade_sind_absolut() -> void:
	# Act
	var ordner := _ablage.ordner()
	var zip := _ablage.zip_pfad()

	# Assert
	assert_false(ordner.begins_with("user://"), ordner)
	assert_string_ends_with(ordner, "/test_selbsttest_ablage/" + LAUF_ID)
	assert_string_ends_with(zip, "/test_selbsttest_ablage/" + LAUF_ID + "_macos.zip")
	assert_eq(ordner, ProjectSettings.globalize_path(BASIS + LAUF_ID))


func test_texte_als_utf8_ohne_bom() -> void:
	# Arrange
	_ablage.lege_an()
	var text := "# Der Computerladen Selbsttest\nmeldung: Grüße⏎„Neues Spiel“\n"

	# Act
	var fehler_protokoll := _ablage.schreibe_protokoll(text)
	var fehler_ausgabe := _ablage.schreibe_ausgabe("[start] Godot\n")

	# Assert
	assert_eq([fehler_protokoll, fehler_ausgabe], [OK, OK])
	assert_eq(FileAccess.get_file_as_bytes(BASIS + LAUF_ID + "/protokoll.txt"),
		text.to_utf8_buffer(), "Byte für Byte, ohne BOM, mit \\n")
	assert_eq(FileAccess.get_file_as_string(BASIS + LAUF_ID + "/ausgabe.txt"), "[start] Godot\n")


func test_foto_als_png() -> void:
	# Arrange
	_ablage.lege_an()
	var bild := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	bild.fill(Color(0.05, 0.09, 0.086))

	# Act
	var fehler := _ablage.speichere_foto("titel.01_start", bild)

	# Assert
	assert_eq(fehler, OK)
	var gelesen := Image.load_from_file(BASIS + LAUF_ID + "/fotos/titel.01_start.png")
	assert_not_null(gelesen)
	assert_eq(gelesen.get_size(), Vector2i(640, 360))
	assert_eq(gelesen.get_pixel(10, 10).to_rgba32(), bild.get_pixel(10, 10).to_rgba32())


func test_ohne_bild_kein_foto() -> void:
	# Arrange
	_ablage.lege_an()

	# Act und Assert
	assert_eq(_ablage.speichere_foto("titel.01_start", null), ERR_INVALID_PARAMETER)


func test_zip_enthaelt_den_ordner() -> void:
	# Arrange
	_ablage.lege_an()
	_ablage.schreibe_protokoll("protokoll\n")
	_ablage.schreibe_ausgabe("ausgabe\n")
	var bild := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	_ablage.speichere_foto("titel.02_nicht_verfuegbar", bild)
	_ablage.speichere_foto("titel.01_start", bild)

	# Act
	var fehler := _ablage.packe()

	# Assert: neben dem Ordner, Pfade ohne den Ordner des Laufs, in fester Reihenfolge
	assert_eq(fehler, OK)
	var zip := BASIS + LAUF_ID + "_macos.zip"
	assert_true(FileAccess.file_exists(zip))
	var leser := ZIPReader.new()
	assert_eq(leser.open(zip), OK)
	var dateien: Array[String] = []
	for datei in leser.get_files():
		if not datei.ends_with("/"):
			dateien.append(datei)
	assert_eq(dateien, ["ausgabe.txt", "protokoll.txt", "fotos/titel.01_start.png",
		"fotos/titel.02_nicht_verfuegbar.png"] as Array[String])
	assert_eq(leser.read_file("protokoll.txt"), "protokoll\n".to_utf8_buffer())
	assert_eq(leser.read_file("fotos/titel.01_start.png"),
		FileAccess.get_file_as_bytes(BASIS + LAUF_ID + "/fotos/titel.01_start.png"))
	leser.close()


func test_zip_ersetzt_ein_altes() -> void:
	# Arrange
	_ablage.lege_an()
	_ablage.schreibe_protokoll("alt\n")
	_ablage.packe()
	_ablage.schreibe_protokoll("neu\n")

	# Act
	_ablage.packe()

	# Assert
	var leser := ZIPReader.new()
	leser.open(BASIS + LAUF_ID + "_macos.zip")
	assert_eq(leser.read_file("protokoll.txt"), "neu\n".to_utf8_buffer())
	leser.close()


func test_nicht_beschreibbar_mit_pfad() -> void:
	# Arrange: Wo der Basisordner hin soll, liegt eine Datei; darunter lässt sich nichts anlegen.
	DirAccess.make_dir_recursive_absolute(BASIS)
	var datei := FileAccess.open(BASIS + "blockiert", FileAccess.WRITE)
	datei.close()
	var ablage := SelbsttestAblage.new(LAUF_ID, BASIS + "blockiert/")

	# Act
	var fehler := ablage.lege_an()

	# Assert: Die Zusammenfassung nennt den Pfad (R11). Godot meldet das Scheitern von
	# make_dir_recursive_absolute() zusätzlich selbst als Fehler; der ist hier erwartet.
	assert_ne(fehler, OK)
	assert_engine_error("Method/function failed")
	var meldung := SelbsttestTexte.kein_protokoll(ablage.ordner())
	assert_string_starts_with(meldung, "Kein Protokoll: In /")
	assert_string_contains(meldung, "/test_selbsttest_ablage/blockiert/" + LAUF_ID)
	assert_string_ends_with(meldung, " lässt sich nicht schreiben.")
	assert_ne(ablage.schreibe_protokoll("x"), OK, "Schreiben scheitert auch danach.")


func _raeume_auf(pfad: String) -> void:
	var ordner := DirAccess.open(pfad)
	if ordner == null:
		return
	for datei in ordner.get_files():
		ordner.remove(datei)
	for unterordner in ordner.get_directories():
		_raeume_auf(pfad.path_join(unterordner))
	DirAccess.remove_absolute(pfad)
