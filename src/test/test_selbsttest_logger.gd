extends GutTest

## Prüft SelbsttestLogger (Feature 007, T004; R10; contracts/protokoll.md, „Ausgabe“; CHK007):
## jede Zeile mit der Kennung des Schritts, „[start]“ und „[ende]“, Fehler und Warnungen als
## Meldung des Schritts, eigene als „[selbsttest] …“, und mehrere Threads zugleich.
##
## Die meisten Tests rufen _log_message() und _log_error() selbst, so wie Godot es täte. Einer
## meldet den Logger wirklich mit OS.add_logger() an und gibt eine Zeile mit print() aus; danach
## meldet er ihn wieder ab. push_error() kommt hier nicht vor, weil GUT jeden Fehler als
## Testfehler zählt.

const ART_FEHLER := Logger.ERROR_TYPE_ERROR
const ART_WARNUNG := Logger.ERROR_TYPE_WARNING

var _logger: SelbsttestLogger


func before_each() -> void:
	_logger = SelbsttestLogger.new()


func test_vor_dem_ersten_schritt_steht_start() -> void:
	# Act
	_logger._log_message("Godot Engine v4.7.2\n", false)

	# Assert
	assert_eq(_logger.ausgabe(), "[start] Godot Engine v4.7.2\n")
	assert_eq(_logger.schritt(), "start")


func test_jede_zeile_mit_der_kennung_des_schritts() -> void:
	# Arrange
	_logger.setze_schritt("neues_spiel.02_zurueck_esc")

	# Act: print() liefert den Text mit "\n" am Ende; zwei Zeilen werden zwei Zeilen.
	_logger._log_message("eins\n", false)
	_logger._log_message("zwei\ndrei\n", false)

	# Assert
	assert_eq(_logger.ausgabe(), "[neues_spiel.02_zurueck_esc] eins\n"
		+ "[neues_spiel.02_zurueck_esc] zwei\n[neues_spiel.02_zurueck_esc] drei\n")


func test_nach_dem_letzten_schritt_steht_ende() -> void:
	# Arrange
	_logger.setze_schritt("titel_echtzeit.03_beenden_da")

	# Act
	_logger.beende()
	_logger._log_message("Fertig\n", false)

	# Assert
	assert_eq(_logger.ausgabe(), "[ende] Fertig\n")


func test_print_ist_keine_meldung_printerr_schon() -> void:
	# Arrange
	_logger.setze_schritt("titel.01_start")

	# Act
	_logger._log_message("nur Ausgabe\n", false)
	_logger._log_message("Fehler aus printerr\n", true)

	# Assert
	assert_eq(_logger.meldungen("titel.01_start"), PackedStringArray(["Fehler aus printerr"]))
	assert_eq(_logger.ausgabe(), "[titel.01_start] nur Ausgabe\n"
		+ "[titel.01_start] Fehler aus printerr\n")


func test_warnung_als_meldung_mit_ort() -> void:
	# Arrange
	_logger.setze_schritt("laden.03_liste")

	# Act
	_logger._log_error("_ready", "res://scenes/title/save_list.gd", 42, "zeile != null",
		"Zeile fehlt", false, ART_WARNUNG, [] as Array[ScriptBacktrace])

	# Assert: in der Ausgabe zwei Zeilen wie bei Godot, als Meldung eine
	assert_eq(_logger.ausgabe(), "[laden.03_liste] WARNING: Zeile fehlt\n"
		+ "[laden.03_liste]    at: _ready (res://scenes/title/save_list.gd:42)\n")
	assert_eq(_logger.meldungen("laden.03_liste"), PackedStringArray([
		"WARNING: Zeile fehlt · at: _ready (res://scenes/title/save_list.gd:42)"]))


func test_ohne_begruendung_zaehlt_die_bedingung() -> void:
	# Arrange
	_logger.setze_schritt("titel.01_start")

	# Act
	_logger._log_error("f", "datei.cpp", 7, "Bedingung „x“ ist wahr", "", false, ART_FEHLER,
		[] as Array[ScriptBacktrace])

	# Assert
	assert_eq(_logger.meldungen("titel.01_start")[0],
		"ERROR: Bedingung „x“ ist wahr · at: f (datei.cpp:7)")


func test_ort_aus_dem_skript_statt_aus_godot() -> void:
	# Arrange: wie bei push_warning(), Ort in C++, im Backtrace dieser Test
	_logger.setze_schritt("titel.01_start")
	var backtraces := Engine.capture_script_backtraces()

	# Act
	_logger._log_error("push_warning", "core/variant/variant_utility.cpp", 1033, "Achtung", "",
		false, ART_WARNUNG, backtraces)

	# Assert
	var meldung := _logger.meldungen("titel.01_start")[0]
	assert_string_starts_with(meldung, "WARNING: Achtung · at: test_ort_aus_dem_skript_statt_aus_godot"
		+ " (res://test/test_selbsttest_logger.gd:")


func test_arten_wie_bei_godot() -> void:
	# Act
	for art: int in [Logger.ERROR_TYPE_ERROR, Logger.ERROR_TYPE_WARNING, Logger.ERROR_TYPE_SCRIPT,
			Logger.ERROR_TYPE_SHADER]:
		_logger._log_error("f", "d", 1, "x", "", false, art, [] as Array[ScriptBacktrace])

	# Assert
	var arten: Array[String] = []
	for meldung in _logger.meldungen("start"):
		arten.append(meldung.get_slice(":", 0))
	assert_eq(arten, ["ERROR", "WARNING", "SCRIPT ERROR", "SHADER ERROR"] as Array[String])


func test_eigener_fehler_ist_markiert() -> void:
	# Arrange
	_logger.setze_schritt("bedienung.06_mausrad")

	# Act
	_logger.eigener_fehler("Foto ließ sich nicht speichern")

	# Assert (CHK007)
	assert_eq(_logger.meldungen("bedienung.06_mausrad"),
		PackedStringArray(["[selbsttest] Foto ließ sich nicht speichern"]))
	assert_eq(_logger.ausgabe(),
		"[bedienung.06_mausrad] [selbsttest] Foto ließ sich nicht speichern\n")


func test_meldungen_je_schritt_getrennt() -> void:
	# Act
	_logger.setze_schritt("titel.01_start")
	_logger.eigener_fehler("eins")
	_logger.setze_schritt("titel.02_nicht_verfuegbar")
	_logger.eigener_fehler("zwei")
	_logger.eigener_fehler("drei")

	# Assert
	assert_eq(_logger.meldungen("titel.01_start").size(), 1)
	assert_eq(_logger.meldungen("titel.02_nicht_verfuegbar").size(), 2)
	assert_eq(_logger.meldungen("gibt_es_nicht").size(), 0)


func test_meldungen_sind_eine_kopie() -> void:
	# Arrange
	_logger.eigener_fehler("eins")

	# Act
	var liste := _logger.meldungen("start")
	liste.append("von außen")

	# Assert
	assert_eq(_logger.meldungen("start").size(), 1)


func test_angemeldet_bekommt_er_print() -> void:
	# Arrange
	_logger.setze_schritt("titel.01_start")

	# Act
	OS.add_logger(_logger)
	print("Probe des Selbsttest-Loggers")
	OS.remove_logger(_logger)
	print("nach dem Abmelden")

	# Assert
	assert_eq(_logger.ausgabe(), "[titel.01_start] Probe des Selbsttest-Loggers\n")


func test_mehrere_threads_zugleich() -> void:
	# Arrange
	_logger.setze_schritt("titel.01_start")
	var threads: Array[Thread] = []

	# Act: je 200 Zeilen aus zwei Threads und dem eigenen
	for nummer in 2:
		var thread := Thread.new()
		thread.start(_schreibe.bind(nummer))
		threads.append(thread)
	_schreibe(9)
	for thread in threads:
		thread.wait_to_finish()

	# Assert: keine Zeile verloren, keine zerrissen
	var zeilen := _logger.ausgabe().trim_suffix("\n").split("\n")
	assert_eq(zeilen.size(), 600)
	for zeile in zeilen:
		if not zeile.begins_with("[titel.01_start] Zeile "):
			fail_test("Zerrissen: " + zeile)
			return
	assert_eq(_logger.meldungen("titel.01_start").size(), 600)


func _schreibe(nummer: int) -> void:
	for i in 200:
		_logger._log_message("Zeile %d.%d\n" % [nummer, i], true)
