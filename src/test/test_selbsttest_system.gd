extends GutTest

## Prüft SelbsttestSystem (Feature 007, T003; data-model.md, „Systemdaten“; R20, R21; CHK029):
## Jeder Schlüssel ist da, gleich welches System; headless darf ein Wert „unbekannt“ sein. Die
## Treiberversion kommt aus einem Thread; ein erfundener Leser zeigt, dass sie ankommt, auch auf dem
## Mac, wo es sie sonst nicht gibt.

## Alle Schlüssel der Tabelle „Systemdaten“ in data-model.md, abgeschrieben, nicht aus dem Code.
const TABELLE := ["system.os", "system.os_version", "system.cpu", "system.gpu",
	"system.gpu_vendor", "system.gpu_driver", "system.renderer", "system.grafik_api",
	"system.grafik_api_version", "system.bildschirm", "system.bildschirm_skalierung",
	"system.bildschirm_dpi", "system.bildwiederholrate", "system.fenster", "system.fenster_faktor",
	"system.sprache", "system.tastatur", "computerladen.version", "godot.version",
	"selbsttest.version", "selbsttest.gebaut", "lauf.start", "lauf.feste_zeit", "lauf.zeitraffer"]


func test_jeder_schluessel_ist_da() -> void:
	# Arrange
	var system := SelbsttestSystem.new()
	system.mit_treiber = false

	# Act
	system.erhebe()

	# Assert: Was das System nicht liefert, ist null, im Protokoll „unbekannt“; der Schlüssel fehlt nie.
	for schluessel in SelbsttestSystem.SYSTEM_SCHLUESSEL + SelbsttestSystem.PROGRAMM_SCHLUESSEL:
		assert_true(system.werte.has(schluessel), schluessel)
		var text := SelbsttestProtokoll.wert(system.werte[schluessel])
		assert_false(text.is_empty(), schluessel)
		assert_false(text.contains("\n"), schluessel)


func test_schluessel_decken_die_tabelle_genau_ab() -> void:
	# Arrange
	var alle: Array[String] = SelbsttestSystem.SYSTEM_SCHLUESSEL \
		+ SelbsttestSystem.PROGRAMM_SCHLUESSEL + SelbsttestSystem.LAUF_SCHLUESSEL

	# Act und Assert: jeder genau einmal, keiner zu viel; computerladen statt spiel (CHK029)
	assert_eq(alle.size(), TABELLE.size())
	for schluessel: String in TABELLE:
		assert_eq(alle.count(schluessel), 1, schluessel)
	assert_false("spiel.version" in alle)


func test_was_ueberall_bekannt_ist() -> void:
	# Arrange
	var system := SelbsttestSystem.new()
	system.mit_treiber = false

	# Act
	system.erhebe()

	# Assert
	assert_eq(system.werte["system.os"], OS.get_name())
	assert_eq(system.werte["computerladen.version"], "0.1", "Aus application/config/version.")
	assert_eq(system.werte["godot.version"], SelbsttestSystem.godot_version())
	assert_eq(system.werte["system.sprache"], OS.get_locale())
	assert_null(system.werte["system.gpu_driver"], "Ohne Thread keine Treiberversion.")


func test_godot_version_in_maschinenform() -> void:
	# Act
	var version := SelbsttestSystem.godot_version()

	# Assert: „4.7.2.stable.official“
	var muster := RegEx.create_from_string("^\\d+\\.\\d+\\.\\d+\\.[a-z0-9]+\\.[a-z0-9_]+$")
	assert_not_null(muster.search(version), version)
	assert_true(version.begins_with("4.7."), version)


func test_ohne_export_ist_die_bauzeit_unbekannt() -> void:
	# Act und Assert: Tests laufen nie aus einem Export (R21).
	assert_null(SelbsttestSystem.gebaut())


func test_treiberversion_kommt_aus_dem_thread() -> void:
	# Arrange
	var system := SelbsttestSystem.new()
	system.mit_treiber = true
	system.treiber_leser = func() -> PackedStringArray:
		return PackedStringArray(["nvidia", "550.54.14"])

	# Act
	system.erhebe()
	system.hole_treiber()

	# Assert
	assert_eq(system.werte["system.gpu_driver"], "nvidia 550.54.14")


func test_leere_treiberinfo_ist_unbekannt() -> void:
	# Arrange
	var system := SelbsttestSystem.new()
	system.mit_treiber = true
	system.treiber_leser = func() -> PackedStringArray: return PackedStringArray()

	# Act
	system.erhebe()
	system.hole_treiber()

	# Assert
	assert_null(system.werte["system.gpu_driver"])


func test_hole_treiber_ohne_thread_tut_nichts() -> void:
	# Arrange
	var system := SelbsttestSystem.new()
	system.mit_treiber = false
	system.erhebe()

	# Act
	system.hole_treiber()
	system.hole_treiber()

	# Assert
	assert_null(system.werte["system.gpu_driver"])


func test_treiber_nur_unter_windows_und_linux() -> void:
	# Act und Assert (R20)
	assert_eq(SelbsttestSystem.new().mit_treiber, OS.get_name() in ["Windows", "Linux"])


func test_faktor_des_fensters() -> void:
	# Act und Assert: wie Stretch „integer“
	assert_eq(SelbsttestSystem.faktor(Vector2i(1920, 1080)), 3)
	assert_eq(SelbsttestSystem.faktor(Vector2i(640, 360)), 1)
	assert_eq(SelbsttestSystem.faktor(Vector2i(1317, 741)), 2, "Fenster „krumm“ aus ablaeufe.md")
	assert_eq(SelbsttestSystem.faktor(Vector2i(3840, 1000)), 2, "Die kleinere Achse zählt.")
	assert_eq(SelbsttestSystem.faktor(Vector2i(300, 200)), 1, "Mindestens 1.")
