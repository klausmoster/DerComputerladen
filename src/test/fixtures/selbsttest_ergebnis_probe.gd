extends Node

## Probeszene für die Zusammenfassung des Selbsttests (Feature 007, T029): zeigt SelbsttestErgebnis
## mit einem erfundenen Lauf im echten Fenster, für Bildschirmfotos und zum Ausprobieren. Der echte
## Lauf bleibt davon unberührt; die Probe liegt unter test/ und kommt in keinen Export.
##
## Die Schritte sind die echten 37 aus SelbsttestLaeufer.ablaeufe(), mit Wortlauten aus dem Spiel;
## die Ergebnisse sind erfunden. Die Systemdaten liest die Probe wie die Startszene vom Rechner.
## Zwischenablage und Dateimanager sind abgeklemmt: „Kopieren“ zeigt nur die Bestätigung.
##
## Start mit Fall und Schaltern nach „--“:
## [codeblock]
## Godot --path src res://test/fixtures/selbsttest_ergebnis_probe.tscn -- --fall fehler
## [/codeblock]
## --fall ok | fehler | nicht_beschreibbar   welcher Lauf (Vorgabe ok)
## --kopieren                                 drückt „Kopieren“, sobald die Seite steht
## --foto <pfad>                              legt ein Bildschirmfoto ab und beendet
## --filter                                   prüft den Filter der Eingabe, siehe _pruefe_filter()
##
## Mit --foto oder --filter gibt die Probe Größe und Lage des Fensters vor und nach dem Wechsel zur
## Zusammenfassung aus; sie müssen gleich bleiben (Klaus, 2026-10-28).

## Wie die Startszene: so viele Bilder, bis GameWindow dem Fenster seine Größe gegeben hat.
const BILDER_BIS_ZUR_FENSTERGROESSE := 3
## So lange wartet die Probe nach dem Wechsel, bevor sie misst und fotografiert, in Sekunden; eine
## Änderung des Fensters durch macOS wäre bis dahin durch.
const WARTEN_AUF_FOTO := 1.5
## 28.10.2026, 14:03:12, Ortszeit
const START := {"year": 2026, "month": 10, "day": 28, "hour": 14, "minute": 3, "second": 12}
## Ein langer, erfundener Pfad, damit der Umbruch nach einem Trenner zu sehen ist.
const LANGER_PFAD := "/Users/klaus/Library/Application Support/Godot/app_userdata/" \
	+ "Der Computerladen Selbsttest/Ablage auf dem Netzlaufwerk/Abteilung Qualitätssicherung/" \
	+ "Selbsttests der Woche 44/Rechner im Büro hinten links/Spielstände und Protokolle/" \
	+ "selbsttest/2026-10-28_14-03-12"

## Wie oft „Kopieren“ die Zwischenablage gerufen hätte.
var _kopiert := 0


func _ready() -> void:
	var argumente := OS.get_cmdline_user_args()
	var fall := _wert(argumente, "--fall", "ok")
	var foto := _wert(argumente, "--foto", "")

	for bild in BILDER_BIS_ZUR_FENSTERGROESSE:
		await get_tree().process_frame
	var system := SelbsttestSystem.new()
	system.erhebe()
	system.hole_treiber()

	var lauf := SelbsttestLauf.new(START)
	lauf.system = system.werte
	lauf.version = SelbsttestLaeufer.VERSION
	var ordner := ProjectSettings.globalize_path("user://selbsttest/" + lauf.id)
	var beschreibbar := fall != "nicht_beschreibbar"
	if beschreibbar:
		_plane_alle(lauf)
	if fall == "fehler":
		ordner = LANGER_PFAD
		_erfinde_fehler(lauf)
	elif beschreibbar:
		for schritt in lauf.schritte:
			lauf.melde_ok(schritt.kennung, 100)

	# Wie in der Startszene ist der Filter von Anfang an da, sobald --filter es verlangt.
	var eingabe := SelbsttestEingabe.new()
	if "--filter" in argumente:
		eingabe.einschalten(get_window())
	var vorher := _fenster_text()
	var ergebnis := SelbsttestErgebnis.erstelle(lauf, ordner, ordner + "_macos.zip", beschreibbar)
	ergebnis.zwischenablage = func(_text: String) -> void: _kopiert += 1
	ergebnis.dateimanager = func(_pfad: String) -> Error: return OK
	# Unter die Probe statt über change_scene_to_node(): Ein Szenenwechsel gäbe die Probe frei, und
	# dieses await liefe nie weiter. Ein Control unter einem Node richtet sich am Fenster aus.
	add_child(ergebnis)
	await get_tree().process_frame
	await get_tree().process_frame
	if "--kopieren" in argumente:
		ergebnis.kopiere()
	if foto.is_empty() and not "--filter" in argumente:
		return
	await get_tree().create_timer(WARTEN_AUF_FOTO).timeout
	print("fenster vorher: %s" % vorher)
	print("fenster nachher: %s" % _fenster_text())
	if "--filter" in argumente:
		await _pruefe_filter(ergebnis, eingabe)
	if not foto.is_empty():
		await RenderingServer.frame_post_draw
		ergebnis.get_viewport().get_texture().get_image().save_png(foto)
	_melde_lage(ergebnis)
	get_tree().quit()


## Klickt mit einem gewöhnlichen Ereignis (Gerät 0, wie Godot echte Mausklicks anlegt) auf
## „Kopieren“, einmal bei eingeschaltetem Filter, einmal danach. Input.parse_input_event() ist der
## Eingang, den auch macOS-Ereignisse nehmen; von dort geht es über den Empfang am Fenster, den
## SelbsttestEingabe ersetzt hat. Erwartet: mit Filter 0, ohne Filter 1 (Analyse, U3).
func _pruefe_filter(ergebnis: SelbsttestErgebnis, eingabe: SelbsttestEingabe) -> void:
	var knopf := ergebnis.get_node("%Kopieren") as Control
	var ziel := ergebnis.get_viewport().get_final_transform() * knopf.get_global_rect().get_center()
	for runde in ["filter an", "filter aus"]:
		if runde == "filter aus":
			eingabe.ausschalten()
		var vorher := _kopiert
		await _klick(ziel)
		print("%s: kopiert %d" % [runde, _kopiert - vorher])


func _klick(ziel: Vector2) -> void:
	var bewegung := InputEventMouseMotion.new()
	bewegung.position = ziel
	bewegung.global_position = ziel
	Input.parse_input_event(bewegung)
	await get_tree().process_frame
	for gedrueckt: bool in [true, false]:
		var taste := InputEventMouseButton.new()
		taste.button_index = MOUSE_BUTTON_LEFT
		taste.pressed = gedrueckt
		taste.button_mask = MOUSE_BUTTON_MASK_LEFT if gedrueckt else 0
		taste.position = ziel
		taste.global_position = ziel
		Input.parse_input_event(taste)
		await get_tree().process_frame
	await get_tree().process_frame


## „3200x1800 bei 0,64“: Größe und Lage der Fläche des Fensters in Bildschirmpixeln.
static func _fenster_text() -> String:
	var groesse := DisplayServer.window_get_size()
	var lage := DisplayServer.window_get_position()
	return "%dx%d bei %d,%d" % [groesse.x, groesse.y, lage.x, lage.y]


## Plant alle Abläufe des Selbsttests mit ihren echten Schritten ein. Der Fahrer ist echt, aber
## ohne Filter: Die Schritte binden ihn nur, ausgeführt wird hier nichts.
func _plane_alle(lauf: SelbsttestLauf) -> void:
	var fahrer := SelbsttestFahrer.new(get_tree(), SelbsttestEingabe.new())
	for ablauf in SelbsttestLaeufer.ablaeufe():
		lauf.plane(ablauf, ablauf.schritte(fahrer))


## 2 Fehler, 3 nicht gelaufen: easter_egg.04 scheitert (05 läuft nicht), fenster.02 scheitert
## (03 und 04 laufen nicht). Die gefundenen Zustände entstehen aus denselben Funktionen wie im
## echten Lauf (SelbsttestTexte, SelbsttestFahrer.fenster_text()), damit sie nur Formen zeigen, die
## der Selbsttest auch schreibt.
func _erfinde_fehler(lauf: SelbsttestLauf) -> void:
	for schritt in lauf.schritte:
		if not lauf.ist_offen(schritt.kennung):
			continue
		match schritt.kennung:
			"easter_egg.04_spielen":
				lauf.melde_fehler(schritt.kennung, SelbsttestTexte.zeit_abgelaufen(
					_invaders_haengt()), 5004)
			"fenster.02_faktor_1":
				# Ein Fenster, in dem das Bild mit Faktor 2 unten rechts klebt: Rand links und oben.
				var bild := Transform2D(0.0, Vector2(2, 2), 0.0, Vector2(37, 21))
				lauf.melde_fehler(schritt.kennung, SelbsttestTexte.zeit_abgelaufen(
					SelbsttestFahrer.fenster_text(Vector2i(1317, 741), bild)), 5001)
			_:
				lauf.melde_ok(schritt.kennung, 100)


## Wie _pruefe_gespielt() in ablauf_easter_egg.gd es schreibt, wenn die Kanone nicht fährt und nicht
## schießt: Kanone, Schuss, dann der Zustand des Fahrers mit Seite, Hinweis und Spielständen.
static func _invaders_haengt() -> String:
	var seite := "%s, %s" % [SelbsttestTexte.ZUSTAND_SEITE_NICHT_AKTIV
		% SelbsttestFahrer.SEITE_INVADERS, SelbsttestTexte.hinweis("")]
	return SelbsttestTexte.zustaende([SelbsttestTexte.ZUSTAND_KANONE_NICHT_RECHTS,
		SelbsttestTexte.ZUSTAND_KEIN_SCHUSS, seite, SelbsttestTexte.spielstaende([])])


## Gibt Lage und Größe des Fensters und die Mitte der Knöpfe in Punkten des Bildschirms aus, für
## Klicks von außen auf die echte App, die gleich aussieht.
func _melde_lage(ergebnis: SelbsttestErgebnis) -> void:
	var faktor := DisplayServer.screen_get_scale()
	var fenster := DisplayServer.window_get_size()
	var lage := DisplayServer.window_get_position()
	print("fenster_logisch: %dx%d" % [roundi(fenster.x / faktor), roundi(fenster.y / faktor)])
	for name in ["Kopieren", "OrdnerZeigen", "Beenden"]:
		var knopf := ergebnis.get_node("%" + name) as Control
		var mitte := (Vector2(lage) + knopf.get_global_rect().get_center()
			* ergebnis.get_window().content_scale_factor) / faktor
		print("knopf %s: %d %d" % [name, roundi(mitte.x), roundi(mitte.y)])


static func _wert(argumente: PackedStringArray, schalter: String, vorgabe: String) -> String:
	var index := argumente.find(schalter)
	if index >= 0 and index + 1 < argumente.size():
		return argumente[index + 1]
	return vorgabe
