class_name SelbsttestLaeufer
extends Node

## Der Läufer spielt die Abläufe nacheinander durch (Feature 007, contracts/selbsttest-app.md,
## „Läufer“; R1, R6, R8, R22, R24; FR-003, FR-003a, FR-006 bis FR-010). Die Startszene hängt ihn an
## die Wurzel des Baums; so überlebt er jeden Szenenwechsel zwischen Titel und Spielbildschirm.
##
## Je Ablauf: Zeitraffer setzen (Engine.time_scale), bei einem Ablauf ohne baut_auf der frische
## Titel als Vorbereitung, dann je Schritt Fenstertitel, Eingaben über den Fahrer, jedes Bild die
## Prüfung, bis sie stimmt oder die Höchstzeit in echter Zeit vorbei ist, Foto, Ergebnis. Was
## daraus folgt (nicht gelaufene Schritte, abhängige Abläufe), regelt SelbsttestLauf. Am Ende
## schreibt er Protokoll, Ausgabe und Zip, schaltet den Filter der Eingabe aus und wechselt zur
## Zusammenfassung (SelbsttestErgebnis). Ab dann hört er nicht mehr auf das Schließen des Fensters;
## Schließen beendet einfach (CHK028).
##
## Der Ablauf ist eine Kette von await: Der Läufer wartet auf Bilder (process_frame), auf das fertig
## gemalte Bild für das Foto (frame_post_draw) und auf die Eingaben. Dazwischen läuft das Spiel
## ganz normal weiter. Wird das Fenster geschlossen, schreibt _brich_ab() sofort alles und beendet;
## die angehaltene Kette merkt beim nächsten Weiterlaufen an _hoert_auf(), dass sie aufhören soll.
##
## Zustand (AR-11): BEREIT bis starte(), dann LAEUFT. Schließt Klaus das Fenster, ist er kurz
## ABGEBROCHEN, bis Protokoll, Ausgabe und Zip geschrieben sind; nach dem Schreiben, beim normalen
## Ende wie beim Abbruch, ist er GESCHRIEBEN, und nach einem Abbruch beendet er die App: BEENDET.
## Jeder Zustand kommt nur einmal und nur in dieser Reihenfolge.
##
## Für Tests ohne Fenster lassen sich frischer Titel, Foto, Zusammenfassung und Beenden über
## Callables ersetzen (vorbereitung, fotograf, zusammenfassung, beenden), wie quit_callback in
## GameSession.

## Steht im Protokoll als selbsttest.version; steigt, wenn sich Abläufe ändern (R21).
const VERSION := 2
## Nur unter diesem Ordner leert der Läufer Spielstände; echte liegen nie dort (FR-008). Es ist
## der Ordner der App, in dem auch die Ablage liegt.
const EIGENER_ORDNER := SelbsttestAblage.BASIS
## Die Abläufe in der Reihenfolge des Vertrags; wer auf einem anderen aufbaut, kommt gleich nach
## ihm. titel_echtzeit läuft als letzter (contracts/ablaeufe.md).
## Szenarien kommen später als Skripte aus szenarien/ vor titel_echtzeit dazu (R27).
const ABLAEUFE: Array[Script] = [
	preload("res://tools/selbsttest/ablaeufe/ablauf_titel.gd"),
	preload("res://tools/selbsttest/ablaeufe/ablauf_neues_spiel.gd"),
	preload("res://tools/selbsttest/ablaeufe/ablauf_laden.gd"),
	preload("res://tools/selbsttest/ablaeufe/ablauf_loeschen.gd"),
	preload("res://tools/selbsttest/ablaeufe/ablauf_easter_egg.gd"),
	preload("res://tools/selbsttest/ablaeufe/ablauf_bedienung.gd"),
	preload("res://tools/selbsttest/ablaeufe/ablauf_liste.gd"),
	preload("res://tools/selbsttest/ablaeufe/ablauf_fenster.gd"),
	preload("res://tools/selbsttest/ablaeufe/ablauf_titel_echtzeit.gd"),
]

## GameSession hat als Autoload keinen class_name; den Typ gibt sein Skript.
const SESSION_SCRIPT := preload("res://core/game_session.gd")

## Nach dem Schreiben, beim normalen Ende wie beim Abbruch.
signal fertig(lauf: SelbsttestLauf)

## Wo der Läufer steht; siehe Kopf.
enum Zustand { BEREIT, LAEUFT, ABGEBROCHEN, GESCHRIEBEN, BEENDET }

var fahrer: SelbsttestFahrer = null
var eingabe: SelbsttestEingabe = null
var ablage: SelbsttestAblage = null
var logger: SelbsttestLogger = null
var system: SelbsttestSystem = null
## Ob die Startszene den Logger mit OS.add_logger() angemeldet hat; dann meldet der Läufer ihn am
## Ende ab.
var logger_angemeldet := false
## null heißt das Autoload GameSession; Tests setzen eine eigene.
var session: Node = null
## Bereitet einen Ablauf ohne baut_auf vor; ungültig heißt der frische Titel (_frischer_titel()).
var vorbereitung: Callable
## Gibt das Foto als Image, mit await; ungültig heißt das Bild des Fensters nach frame_post_draw.
var fotograf: Callable
## Beendet die App nach einem Abbruch; ungültig heißt get_tree().quit().
var beenden: Callable
## Zeigt nach dem Schreiben die Zusammenfassung; ungültig heißt der Wechsel zu SelbsttestErgebnis
## (_zeige_zusammenfassung()).
var zusammenfassung: Callable
## Der Lauf, den starte() bekam.
var lauf: SelbsttestLauf = null

var _ablaeufe: Array[SelbsttestAblauf] = []
## Kennung des Ablaufs → seine Schritte mit den Callables.
var _schritte: Dictionary = {}
## Die Kennung des Schritts, der gerade dran ist.
var _kennung := ""
var _start_ms := 0
var _zustand: Zustand = Zustand.BEREIT
var _quit_callback_vorher: Callable


## Eine neue Liste aller Abläufe in ihrer Reihenfolge.
static func ablaeufe() -> Array[SelbsttestAblauf]:
	var liste: Array[SelbsttestAblauf] = []
	for skript in ABLAEUFE:
		liste.append(skript.new())
	return liste


## Plant alle [param p_ablaeufe] in [param p_lauf] ein und spielt sie durch. Kehrt beim ersten
## Warten zurück; das Ende meldet fertig.
func starte(p_lauf: SelbsttestLauf, p_ablaeufe: Array[SelbsttestAblauf]) -> void:
	lauf = p_lauf
	_ablaeufe = p_ablaeufe
	for ablauf in _ablaeufe:
		var liste := ablauf.schritte(fahrer)
		_schritte[ablauf.kennung] = liste
		lauf.plane(ablauf, liste)
	# Beim Schließen des Fensters beendet GameSession das Programm selbst, solange ein Spiel läuft.
	# Dann soll erst das Protokoll geschrieben werden (Analyse, U2).
	var sitzung := _session()
	_quit_callback_vorher = sitzung.quit_callback
	sitzung.quit_callback = _brich_ab
	_zustand = Zustand.LAEUFT
	_start_ms = Time.get_ticks_msec()
	_laufe()


## Die Kennung des laufenden Schritts, für Logger und Fokus.
func schritt_kennung() -> String:
	return _kennung


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if _zustand == Zustand.LAEUFT and lauf != null:
				lauf.vermerke_fokusverlust(_kennung, Time.get_ticks_msec() - _start_ms)
		NOTIFICATION_WM_CLOSE_REQUEST:
			# Nach dem Schreiben hört der Läufer nicht mehr auf das Schließen (CHK028).
			if _zustand == Zustand.LAEUFT:
				_brich_ab()


# --- Lauf -----------------------------------------------------------------------------------------

func _laufe() -> void:
	var treiber_geholt := false
	for ablauf in _ablaeufe:
		if _hoert_auf():
			return
		var liste: Array[Dictionary] = _schritte[ablauf.kennung]
		if liste.is_empty() or not lauf.ablauf_offen(ablauf.kennung):
			continue
		var erster: String = liste[0]["kennung"]
		_beginne(erster, ablauf)
		# Vor dem frischen Titel: Auch die Fahrt herein läuft im Tempo des Ablaufs (R24).
		Engine.time_scale = ablauf.zeitraffer
		var frisch := ablauf.baut_auf.is_empty()
		if frisch:
			if vorbereitung.is_valid():
				await vorbereitung.call()
			else:
				await _frischer_titel()
			if _hoert_auf():
				return
		for daten in liste:
			if _hoert_auf():
				return
			if lauf.ist_offen(daten["kennung"]):
				await _fuehre_aus(ablauf, daten, frisch and daten["kennung"] == erster)
		if _hoert_auf():
			return
		if fahrer != null:
			ablauf.aufraeumen(fahrer)
		Engine.time_scale = 1.0
		# Die Treiberversion liest unter Windows und Linux ein Thread; nach dem ersten Ablauf ist
		# sie längst da (R20).
		if not treiber_geholt and system != null:
			system.hole_treiber()
			treiber_geholt = true
	if _hoert_auf():
		return
	_schreibe()
	fertig.emit(lauf)
	if zusammenfassung.is_valid():
		zusammenfassung.call()
	else:
		_zeige_zusammenfassung()


## Ein Schritt: Eingaben, warten auf den Zustand, Foto, Ergebnis. [param nach_frischem_titel]: Der
## Schritt ist der erste nach dem frischen Titel; hat er Eingaben, wartet er erst, bis der
## Communicator steht, sonst gingen sie an ein fahrendes Menü.
func _fuehre_aus(ablauf: SelbsttestAblauf, daten: Dictionary, nach_frischem_titel: bool) -> void:
	var kennung: String = daten["kennung"]
	_beginne(kennung, ablauf)
	var beginn := Time.get_ticks_msec()
	var hoechstzeit: int = daten.get("hoechstzeit_ms", SelbsttestAblauf.HOECHSTZEIT_MS)
	if nach_frischem_titel and fahrer != null \
			and daten.get("eingaben_text", SelbsttestTexte.EINGABEN_KEINE) \
				!= SelbsttestTexte.EINGABEN_KEINE:
		await _warte_bis(fahrer.communicator_steht, beginn + hoechstzeit)
		if _hoert_auf():
			return
	if eingabe != null:
		eingabe.merke_beginn()
	var antwort: Variant = await (daten["eingaben"] as Callable).call()
	if _hoert_auf():
		return
	# dauer_ms zählt ab der ersten Eingabe, ohne Eingabe ab Beginn des Schritts (Analyse, I1).
	var erste := eingabe.erste_eingabe_ms() if eingabe != null else -1
	var start := erste if erste >= 0 else beginn
	var gefunden := ""
	if antwort is String and not (antwort as String).is_empty():
		# Der Fahrer fand ein Ziel nicht; warten hilft nicht.
		gefunden = antwort
	else:
		var erwartet: Callable = daten["erwartet"]
		while true:
			var zustand := _text(erwartet.call())
			if zustand.is_empty():
				break
			if Time.get_ticks_msec() - start >= hoechstzeit:
				gefunden = SelbsttestTexte.zeit_abgelaufen(zustand)
				break
			await get_tree().process_frame
			if _hoert_auf():
				return
	var dauer := Time.get_ticks_msec() - start
	await _fotografiere(kennung)
	if _hoert_auf():
		return
	var meldungen := logger.meldungen(kennung) if logger != null else PackedStringArray()
	if gefunden.is_empty():
		lauf.melde_ok(kennung, dauer, meldungen)
	else:
		lauf.melde_fehler(kennung, gefunden, dauer, meldungen)


## Der frische Titel (contracts/selbsttest-app.md, „Läufer“; Analyse, I3): Läuft ein Spiel, beendet
## es GameSession.leave() und speichert dabei in den Ordner des Selbsttests; dann den Ordner leeren
## und den Titel neu laden. Fertig ist die Vorbereitung, sobald der neue Titel im Baum steht; die
## Fahrt herein gehört zum ersten Schritt („Start, der Communicator fährt herein“).
func _frischer_titel() -> void:
	var baum := get_tree()
	var frist := Time.get_ticks_msec() + SelbsttestAblauf.HOECHSTZEIT_MS
	# Erst muss ein Bildschirm stehen. Beim ersten Ablauf wechselt die Startszene gerade zum Titel;
	# zwei Wechsel in einem Bild vertragen sich nicht.
	await _warte_bis(func() -> bool: return baum.current_scene is TitleScreen \
		or baum.current_scene is GameScreen, frist)
	if _hoert_auf():
		return
	var sitzung := _session()
	if sitzung.is_running():
		var fehler := sitzung.leave()
		if fehler != OK and logger != null:
			logger.eigener_fehler(SelbsttestTexte.SPIEL_NICHT_BEENDET % error_string(fehler))
	_leere_spielstaende(sitzung.folder)
	var alt := baum.current_scene.get_instance_id() if baum.current_scene != null else 0
	baum.change_scene_to_file(SelbsttestFahrer.TITEL)
	var neu := await _warte_bis(func() -> bool: return baum.current_scene is TitleScreen \
		and baum.current_scene.get_instance_id() != alt,
		Time.get_ticks_msec() + SelbsttestAblauf.HOECHSTZEIT_MS)
	if not neu and not _hoert_auf() and logger != null:
		logger.eigener_fehler(SelbsttestTexte.TITEL_KAM_NICHT)


## Löscht alles in [param ordner], aber nur, wenn er unter EIGENER_ORDNER liegt. Gibt es ihn noch
## nicht, ist er schon leer; SaveStore legt ihn beim ersten Speichern an.
func _leere_spielstaende(ordner: String) -> void:
	if not ordner.begins_with(EIGENER_ORDNER):
		if logger != null:
			logger.eigener_fehler(SelbsttestTexte.ORDNER_NICHT_GELEERT % ordner)
		return
	if DirAccess.dir_exists_absolute(ordner):
		_leere(ordner)


## Wartet Bild für Bild, bis [param bedingung] wahr ist oder [param frist] (Time.get_ticks_msec())
## vorbei; true, wenn die Bedingung kam.
func _warte_bis(bedingung: Callable, frist: int) -> bool:
	while not bedingung.call():
		if _hoert_auf() or Time.get_ticks_msec() >= frist:
			return false
		await get_tree().process_frame
	return true


## Fotografiert und legt das Bild als fotos/<kennung>.png ab. Scheitert das, steht es als eigener
## Fehler beim Schritt.
func _fotografiere(kennung: String) -> void:
	var bild: Image
	if fotograf.is_valid():
		bild = await fotograf.call()
	else:
		bild = await _foto()
	if _hoert_auf() or ablage == null:
		return
	var fehler := ablage.speichere_foto(kennung, bild)
	if fehler != OK and logger != null:
		logger.eigener_fehler(SelbsttestTexte.nicht_geschrieben(kennung + ".png",
			error_string(fehler)))


## Das Bild des Fensters, wenn es fertig gemalt ist: Mit Stretch „viewport“ immer 640 × 360, ohne
## Mauszeiger (R8).
func _foto() -> Image:
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


## Ab jetzt ist [param kennung] dran: für Logger, Fokus und Fenstertitel (R22, CHK035).
func _beginne(kennung: String, ablauf: SelbsttestAblauf) -> void:
	_kennung = kennung
	if logger != null:
		logger.setze_schritt(kennung)
	get_window().title = SelbsttestTexte.fenstertitel(lauf.nummer(kennung), lauf.gesamt(),
		ablauf.name)


# --- Ende -----------------------------------------------------------------------------------------

## Das Fenster wurde geschlossen (FR-010): Abbruch vermerken, schreiben, beenden. Kommt über
## NOTIFICATION_WM_CLOSE_REQUEST und, solange ein Spiel läuft, über GameSession.quit_callback,
## nachdem die Session gespeichert hat; was zuerst kommt, gilt.
func _brich_ab() -> void:
	if not _ist_geschrieben():
		_zustand = Zustand.ABGEBROCHEN
		lauf.brich_ab(_kennung)
		_schreibe()
		fertig.emit(lauf)
	_beende()


## Schreibt Protokoll, Ausgabe und Zip, einmal. Danach ist der Filter aus und der Logger ab.
func _schreibe() -> void:
	if _ist_geschrieben():
		return
	_zustand = Zustand.GESCHRIEBEN
	Engine.time_scale = 1.0
	lauf.dauer_ms = Time.get_ticks_msec() - _start_ms
	_session().quit_callback = _quit_callback_vorher
	if logger != null:
		logger.beende()
	if system != null:
		system.hole_treiber()
		lauf.system = system.werte
	if ablage != null:
		_melde_schreibfehler(SelbsttestAblage.PROTOKOLL,
			ablage.schreibe_protokoll(SelbsttestProtokoll.protokoll(lauf)))
		_melde_schreibfehler(SelbsttestAblage.AUSGABE,
			ablage.schreibe_ausgabe(logger.ausgabe() if logger != null else ""))
		_melde_schreibfehler(ablage.zip_pfad().get_file(), ablage.packe())
	if eingabe != null:
		eingabe.ausschalten()
	if logger != null and logger_angemeldet:
		OS.remove_logger(logger)
		logger_angemeldet = false
	get_window().title = SelbsttestTexte.FENSTERTITEL_DANACH


## Nach dem Schreiben gibt es keinen Schritt mehr, zu dem ein Fehler gehören könnte; er geht
## deshalb nur in die Ausgabe von Godot.
static func _melde_schreibfehler(datei: String, fehler: Error) -> void:
	if fehler != OK:
		printerr(SelbsttestTexte.nicht_geschrieben(datei, error_string(fehler)))


## Wechselt zur Zusammenfassung. change_scene_to_node() nimmt den fertigen Knoten; so stehen Lauf
## und Pfade, bevor sie in den Baum kommt. Der Filter ist hier schon aus (_schreibe()), sonst
## kämen echte Klicks auf ihren Knöpfen nie an (Analyse, U3).
func _zeige_zusammenfassung() -> void:
	var ordner := ablage.ordner() if ablage != null else ""
	var zip := ablage.zip_pfad() if ablage != null else ""
	get_tree().change_scene_to_node(SelbsttestErgebnis.erstelle(lauf, ordner, zip))


func _beende() -> void:
	if _zustand == Zustand.BEENDET:
		return
	_zustand = Zustand.BEENDET
	if beenden.is_valid():
		beenden.call()
	else:
		get_tree().quit()


# --- Hilfen ---------------------------------------------------------------------------------------

## Ob die Kette der Abläufe aufhören soll: Der Lauf läuft nicht mehr, weil Klaus das Fenster
## geschlossen hat. Die Kette selbst schreibt erst, wenn sie fertig ist, und fragt danach nicht
## mehr.
func _hoert_auf() -> bool:
	return _zustand != Zustand.LAEUFT


## Ob Protokoll, Ausgabe und Zip schon geschrieben sind; BEENDET kommt nur nach dem Schreiben.
func _ist_geschrieben() -> bool:
	match _zustand:
		Zustand.GESCHRIEBEN, Zustand.BEENDET:
			return true
	return false


func _session() -> SESSION_SCRIPT:
	return (session if session != null else GameSession) as SESSION_SCRIPT


## Ein Rückgabewert einer Prüfung als Text; null heißt "" (Zustand stimmt).
static func _text(wert: Variant) -> String:
	return "" if wert == null else str(wert)


## Löscht Dateien und Unterordner in [param ordner]; der Ordner selbst bleibt.
static func _leere(ordner: String) -> void:
	for datei in DirAccess.get_files_at(ordner):
		DirAccess.remove_absolute(ordner.path_join(datei))
	for unterordner in DirAccess.get_directories_at(ordner):
		_leere(ordner.path_join(unterordner))
		DirAccess.remove_absolute(ordner.path_join(unterordner))
