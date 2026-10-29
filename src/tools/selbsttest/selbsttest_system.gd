class_name SelbsttestSystem
extends RefCounted

## Die Systemdaten eines Laufs mit festen Schlüsseln, gleich auf allen Systemen (Feature 007,
## data-model.md, „Systemdaten“; FR-013, FR-014; R20, R21). erhebe() liest sie einmal beim Start;
## danach stehen sie in [member werte]. Was das System nicht liefert, ist null und steht im
## Protokoll als „unbekannt“; ein Schlüssel fehlt nie.
##
## Die Werte bleiben in ihrem Typ, etwa Vector2i für Maße und float für die Skalierung; in
## Maschinenform bringt sie erst SelbsttestProtokoll.wert(). Vier Schlüssel der Tabelle gehören
## zum Lauf, nicht zum System: selbsttest.version, lauf.start, lauf.feste_zeit und lauf.zeitraffer.
## Sie stehen in SelbsttestLauf (LAUF_SCHLUESSEL nennt sie).
##
## Die Treiberversion gibt es nur unter Windows und Linux, und sie zu lesen kann dort Sekunden
## dauern (R20). erhebe() startet sie deshalb in einem eigenen Thread; hole_treiber() wartet auf
## ihn und trägt das Ergebnis ein. Der Läufer ruft es nach dem ersten Ablauf auf.

## Die Schlüssel unter „# System“ im Protokoll, in ihrer Reihenfolge.
const SYSTEM_SCHLUESSEL: Array[String] = [
	"system.os",
	"system.os_version",
	"system.cpu",
	"system.gpu",
	"system.gpu_vendor",
	"system.gpu_driver",
	"system.renderer",
	"system.grafik_api",
	"system.grafik_api_version",
	"system.bildschirm",
	"system.bildschirm_skalierung",
	"system.bildschirm_dpi",
	"system.bildwiederholrate",
	"system.fenster",
	"system.fenster_faktor",
	"system.sprache",
	"system.tastatur",
]
## Die Schlüssel zum Programm, die erhebe() ebenfalls liest; sie stehen im Protokoll unter
## „# Lauf“ (contracts/protokoll.md).
const PROGRAMM_SCHLUESSEL: Array[String] = ["computerladen.version", "godot.version",
	"selbsttest.gebaut"]
## Die Schlüssel der Tabelle „Systemdaten“, die SelbsttestLauf hält.
const LAUF_SCHLUESSEL: Array[String] = ["selbsttest.version", "lauf.start", "lauf.feste_zeit",
	"lauf.zeitraffer"]
## GameWindow hat als Autoload keinen class_name; seine Konstanten kommen über das Skript.
const FENSTER_SCRIPT := preload("res://core/game_window.gd")
## Das Raster des Spiels, für den Faktor des Fensters; es steht in GameWindow (AR-04).
const RASTER := FENSTER_SCRIPT.BASE_SIZE
## Die Display-Server, deren screen_get_scale() immer 1.0 liefert; dort kommt die Skalierung aus
## den dpi (skalierung()). Namen wie DisplayServer.get_name().
const SKALIERUNG_AUS_DPI: Array[String] = ["Windows", "X11"]
## So viele dpi hat ein Bildschirm mit Skalierung 1 unter Windows und X11.
const DPI_BEI_FAKTOR_1 := 96.0
## Auf dieses Raster rundet skalierung() den Faktor aus den dpi: 1, 1,25, 1,5 … wie die Stufen in
## den Anzeigeeinstellungen von Windows.
const SKALIERUNG_SCHRITT := 0.25

## Schlüssel → Wert; null heißt „unbekannt“.
var werte: Dictionary = {}
## Ob es eine Treiberversion zu lesen gibt; nur unter Windows und Linux (R20). Tests stellen es um.
var mit_treiber: bool = OS.get_name() in ["Windows", "Linux"]
## Liest die Treiberversion; gibt wie OS.get_video_adapter_driver_info() Name und Version. Tests
## geben eine eigene Funktion.
var treiber_leser: Callable = Callable(OS, "get_video_adapter_driver_info")

var _thread: Thread = null


## Liest alle Werte. Unter Windows und Linux läuft die Treiberversion danach im Thread weiter;
## bis hole_treiber() ist system.gpu_driver null.
func erhebe() -> void:
	werte.clear()
	for schluessel in SYSTEM_SCHLUESSEL + PROGRAMM_SCHLUESSEL:
		werte[schluessel] = null

	werte["system.os"] = _text(OS.get_name())
	werte["system.os_version"] = _text(OS.get_version())
	werte["system.cpu"] = _text(OS.get_processor_name())
	werte["system.gpu"] = _text(RenderingServer.get_video_adapter_name())
	werte["system.gpu_vendor"] = _text(RenderingServer.get_video_adapter_vendor())
	werte["system.renderer"] = _text(RenderingServer.get_current_rendering_method())
	var api := RenderingServer.get_current_rendering_driver_name()
	werte["system.grafik_api"] = _text(SelbsttestTexte.grafik_api_name(api))
	werte["system.grafik_api_version"] = _text(RenderingServer.get_video_adapter_api_version())

	# Ohne Fenster (headless) ist der Bildschirm -1 und alle Maße 0; das heißt „unbekannt“.
	var bildschirm := DisplayServer.window_get_current_screen()
	if bildschirm >= 0:
		werte["system.bildschirm"] = _mass(DisplayServer.screen_get_size(bildschirm))
		werte["system.bildschirm_skalierung"] = bildschirm_skalierung(bildschirm)
		werte["system.bildschirm_dpi"] = DisplayServer.screen_get_dpi(bildschirm)
		werte["system.bildwiederholrate"] = _rate(
			DisplayServer.screen_get_refresh_rate(bildschirm))
	var fenster := DisplayServer.window_get_size()
	werte["system.fenster"] = _mass(fenster)
	if werte["system.fenster"] != null:
		werte["system.fenster_faktor"] = faktor(fenster)

	werte["system.sprache"] = _text(OS.get_locale())
	werte["system.tastatur"] = _text(DisplayServer.keyboard_get_layout_name(
		DisplayServer.keyboard_get_current_layout()))

	werte["computerladen.version"] = _text(str(ProjectSettings.get_setting(
		"application/config/version", "")))
	werte["godot.version"] = godot_version()
	werte["selbsttest.gebaut"] = gebaut()

	if mit_treiber and _thread == null:
		_thread = Thread.new()
		_thread.start(_lies_treiber)


## Wartet, bis der Thread die Treiberversion gelesen hat, und trägt sie ein. Ohne Thread tut es
## nichts. Danach ist der Thread weg.
func hole_treiber() -> void:
	if _thread == null:
		return
	var info: PackedStringArray = _thread.wait_to_finish()
	_thread = null
	# Name und Version, etwa „nvidia 550.54.14“: Unter Linux sagt der Name, ob der Treiber des
	# Herstellers oder ein freier läuft.
	werte["system.gpu_driver"] = _text(" ".join(info).strip_edges())


## „4.7.2.stable.official“: die Version von Godot, immer mit drei Zahlen.
static func godot_version() -> String:
	var info := Engine.get_version_info()
	return "%d.%d.%d.%s.%s" % [info["major"], info["minor"], info["patch"], info["status"],
		info["build"]]


## Die Skalierung des Bildschirms [param bildschirm], wie der Selbsttest sie nimmt: für
## system.bildschirm_skalierung und für content_scale_factor der Zusammenfassung. -1 heißt der
## Bildschirm des Fensters. Gerechnet mit skalierung() aus dem, was der Display-Server meldet.
static func bildschirm_skalierung(bildschirm: int = DisplayServer.SCREEN_OF_MAIN_WINDOW) -> float:
	return skalierung(DisplayServer.get_name(), DisplayServer.screen_get_scale(bildschirm),
		DisplayServer.screen_get_dpi(bildschirm))


## Die Skalierung für den Display-Server [param server] (DisplayServer.get_name()) aus seinen
## Angaben [param scale] (screen_get_scale()) und [param dpi] (screen_get_dpi()); ohne Fenster
## prüfbar. Unter Windows und X11 liefert screen_get_scale() immer 1.0; dort zählen die dpi geteilt
## durch 96, gerundet auf SKALIERUNG_SCHRITT und mindestens 1 (Klaus, Phase 8). macOS und Wayland
## kennen die Skalierung selbst; dort bleibt [param scale].
static func skalierung(server: String, scale: float, dpi: int) -> float:
	if server not in SKALIERUNG_AUS_DPI:
		return scale
	return maxf(snappedf(dpi / DPI_BEI_FAKTOR_1, SKALIERUNG_SCHRITT), 1.0)


## Der ganzzahlige Faktor, mit dem das Raster 640 × 360 in ein Fenster der Größe [param fenster]
## passt, mindestens 1; so vergrößert das Spiel mit Stretch „integer“.
static func faktor(fenster: Vector2i) -> int:
	return maxi(mini(floori(fenster.x / float(RASTER.x)), floori(fenster.y / float(RASTER.y))), 1)


## Änderungszeit des Pakets, „2026-10-28 13:58“ in der Zeitzone des Rechners (R21); null, wenn das
## Spiel nicht aus einem Export läuft. Unter macOS ist es die .pck in Contents/Resources/, unter
## Windows und Linux die ausführbare Datei mit eingebettetem Paket.
static func gebaut() -> Variant:
	if not OS.has_feature("template"):
		return null
	var programm := OS.get_executable_path()
	var datei := programm
	if OS.get_name() == "macOS":
		var ressourcen := programm.get_base_dir().path_join("../Resources").simplify_path()
		datei = ressourcen.path_join(programm.get_file() + ".pck")
		if not FileAccess.file_exists(datei):
			datei = _erste_pck(ressourcen)
	if datei.is_empty() or not FileAccess.file_exists(datei):
		return null
	var unix := FileAccess.get_modified_time(datei)
	var versatz: int = Time.get_time_zone_from_system().get("bias", 0)
	return SelbsttestProtokoll.zeit_text(Time.get_datetime_dict_from_unix_time(unix + versatz * 60),
		false)


func _lies_treiber() -> PackedStringArray:
	return treiber_leser.call()


# Ein Thread muss abgeholt werden, bevor sein Objekt verschwindet; sonst warnt Godot.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _thread != null:
		_thread.wait_to_finish()


## Die erste .pck in [param ordner]; leer, wenn es keine gibt.
static func _erste_pck(ordner: String) -> String:
	for datei in DirAccess.get_files_at(ordner):
		if datei.get_extension() == "pck":
			return ordner.path_join(datei)
	return ""


## Ein Text, oder null, wenn er leer ist.
static func _text(text: String) -> Variant:
	if text.is_empty():
		return null
	return text


## Ein Maß, oder null, wenn eine Seite 0 ist.
static func _mass(mass: Vector2i) -> Variant:
	if mass.x <= 0 or mass.y <= 0:
		return null
	return mass


## Die Bildwiederholrate: ganzzahlig, wenn sie es ist, etwa 120; null, wenn das System sie nicht
## kennt (dann meldet Godot -1).
static func _rate(rate: float) -> Variant:
	if rate <= 0.0:
		return null
	if is_equal_approx(rate, roundf(rate)):
		return roundi(rate)
	return rate
