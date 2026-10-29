extends GutTest

## Prüft SelbsttestLaeufer ohne Fenster und ohne Spiel (Feature 007, T014; contracts/selbsttest-app.md,
## „Läufer“; R6, R22, R24; FR-003a, FR-006, FR-009, FR-010; Analyse, I1, U2): Abläufe nacheinander
## im Zeitraffer ihres Ablaufs, Warten auf den Zustand bis zur Höchstzeit, „Zeit abgelaufen“ und
## „Ziel nicht gefunden“, Dauer ab der ersten Eingabe, Meldungen je Schritt, Fenstertitel,
## Fokusverlust, Abbruch beim Schließen, und am Ende Protokoll, Ausgabe, Fotos, Zip und die
## Zusammenfassung.
##
## Statt des Fahrers geben erfundene Abläufe ihre Callables selbst vor. Frischer Titel, Foto,
## Zusammenfassung und Beenden ersetzt der Test über vorbereitung, fotograf, zusammenfassung und
## beenden; geschrieben wird in den eigenen Ordner BASIS, den after_each() abräumt. Die Session ist
## eine eigene, nicht im Baum, damit der quit_callback des Autoloads unberührt bleibt.

const BASIS := "user://test_selbsttest_laeufer/"
const SITZUNG := preload("res://core/game_session.gd")
## 28.10.2026, 14:03:12, Ortszeit
const START := {"year": 2026, "month": 10, "day": 28, "hour": 14, "minute": 3, "second": 12}
const LAUF_ID := "2026-10-28_14-03-12"

var _laeufer: SelbsttestLaeufer
var _lauf: SelbsttestLauf
var _logger: SelbsttestLogger
var _sitzung: SITZUNG
var _beendet := 0
var _zusammengefasst := 0
## Ob der Filter der Eingabe noch aktiv war, als die Zusammenfassung kam.
var _filter_bei_zusammenfassung := true
var _vorbereitet := 0
## Der Fenstertitel und Engine.time_scale, wie die Eingaben jedes Schritts sie sahen.
var _gesehen: Array[Dictionary] = []


func before_each() -> void:
	_raeume_auf(BASIS)
	_beendet = 0
	_zusammengefasst = 0
	_filter_bei_zusammenfassung = true
	_vorbereitet = 0
	_gesehen.clear()
	_lauf = SelbsttestLauf.new(START)
	_logger = SelbsttestLogger.new()
	_sitzung = SITZUNG.new()
	var ablage := SelbsttestAblage.new(LAUF_ID, BASIS)
	ablage.system = "macos"
	assert_eq(ablage.lege_an(), OK)
	_laeufer = SelbsttestLaeufer.new()
	_laeufer.ablage = ablage
	_laeufer.logger = _logger
	_laeufer.session = _sitzung
	_laeufer.vorbereitung = func() -> void: _vorbereitet += 1
	_laeufer.fotograf = _foto
	_laeufer.beenden = func() -> void: _beendet += 1
	_laeufer.zusammenfassung = func() -> void:
		_zusammengefasst += 1
		if _laeufer.eingabe != null:
			_filter_bei_zusammenfassung = _laeufer.eingabe.ist_aktiv()
	add_child_autofree(_laeufer)


func after_each() -> void:
	# Bricht ein Test mitten im Lauf ab, darf der Zeitraffer nicht für die folgenden gelten.
	Engine.time_scale = 1.0
	_sitzung.free()
	_raeume_auf(BASIS)


# --- Ein ganzer Lauf ------------------------------------------------------------------------------

func test_ein_lauf_in_ordnung_schreibt_protokoll_ausgabe_fotos_und_zip() -> void:
	# Arrange
	var titel := _ablauf("titel", [_schritt("01_start"), _schritt("02_zwei")])
	var echtzeit := _ablauf("titel_echtzeit", [_schritt("01_start")], "", 1)

	# Act
	await _laufe([titel, echtzeit])

	# Assert
	assert_eq(_lauf.summe_text(), "Alles in Ordnung: 3 von 3 Schritten.")
	assert_eq(_zusammengefasst, 1, "Nach dem Schreiben kommt die Zusammenfassung.")
	assert_eq(_beendet, 0, "Die App bleibt offen, bis Klaus sie beendet.")
	assert_eq(_vorbereitet, 2, "Jeder Ablauf ohne baut_auf beginnt beim frischen Titel.")
	var ordner := BASIS + LAUF_ID + "/"
	var protokoll := FileAccess.get_file_as_string(ordner + "protokoll.txt")
	assert_string_starts_with(protokoll, "# Der Computerladen Selbsttest\n"
		+ "ergebnis: Alles in Ordnung: 3 von 3 Schritten.\n")
	assert_string_contains(protokoll, "\nlauf.abbruch: keiner\n")
	assert_string_contains(protokoll, "\nschritt: titel_echtzeit.01_start\nablauf: titel_echtzeit\n"
		+ "beschreibung: Beschreibung 01_start\neingaben: keine\n")
	assert_string_contains(protokoll, "\nzeitraffer: 1\nfoto: titel_echtzeit.01_start.png\n")
	for foto in ["titel.01_start", "titel.02_zwei", "titel_echtzeit.01_start"]:
		assert_true(FileAccess.file_exists(ordner + "fotos/%s.png" % foto), foto)
	assert_true(FileAccess.file_exists(ordner + "ausgabe.txt"))
	assert_true(FileAccess.file_exists(BASIS + LAUF_ID + "_macos.zip"))
	assert_gte(_lauf.dauer_ms, 0)


func test_vor_der_zusammenfassung_ist_der_filter_aus() -> void:
	# Arrange: Headless gibt es keinen Empfang am Fenster; einschalten() setzt nur den Zustand.
	var eingabe := SelbsttestEingabe.new()
	var gesammelt := Input.use_accumulated_input
	eingabe.einschalten(get_window())
	_laeufer.eingabe = eingabe

	# Act
	await _laufe([_ablauf("titel", [_schritt("01_start")])])

	# Assert: Sonst kämen echte Klicks auf ihren Knöpfen nie an (Analyse, U3).
	assert_eq(_zusammengefasst, 1)
	assert_false(_filter_bei_zusammenfassung,
		"Der Filter ist aus, bevor die Zusammenfassung kommt.")
	assert_true(eingabe.durchlassen(InputEventMouseButton.new()), "Echte Klicks gehen durch.")
	assert_eq(Input.use_accumulated_input, gesammelt, "Wie vor dem Selbsttest.")


func test_zeitraffer_und_fenstertitel_je_ablauf() -> void:
	# Arrange
	var titel := _ablauf("titel", [_schritt("01_start"), _schritt("02_zwei")])
	var echtzeit := _ablauf("titel_echtzeit", [_schritt("01_start")], "", 1)

	# Act
	await _laufe([titel, echtzeit])

	# Assert (R24, CHK035)
	assert_eq(_gesehen.size(), 3)
	assert_eq(_gesehen[0]["zeitraffer"], 8.0)
	assert_eq(_gesehen[2]["zeitraffer"], 1.0)
	assert_eq(_gesehen[0]["titel"], "Selbsttest · Schritt 1 von 3: Titel")
	assert_eq(_gesehen[1]["titel"], "Selbsttest · Schritt 2 von 3: Titel")
	assert_eq(_gesehen[2]["titel"], "Selbsttest · Schritt 3 von 3: Titel in Echtzeit")
	assert_eq(Engine.time_scale, 1.0, "Nach dem Lauf wieder normal.")
	assert_eq(get_window().title, "Der Computerladen Selbsttest")


func test_der_laeufer_wartet_bild_fuer_bild_auf_den_zustand() -> void:
	# Arrange: Der Zustand kommt erst im dritten Bild.
	var bilder := [0]
	var spaet := func() -> String:
		bilder[0] += 1
		return "" if bilder[0] >= 3 else "Communicator nicht in Endlage"
	var titel := _ablauf("titel", [_schritt("01_start", _nichts, spaet)])

	# Act
	await _laufe([titel])

	# Assert
	assert_eq(_lauf.schritt("titel.01_start").status, SelbsttestLauf.Status.OK)
	assert_eq(bilder[0], 3)


func test_zeit_abgelaufen_nach_der_hoechstzeit_und_der_rest_laeuft_nicht() -> void:
	# Arrange
	var nie := func() -> String: return "Menü steht: HAUPTMENÜ, „Weiterspielen“"
	var titel := _ablauf("titel", [_schritt("01_start", _nichts, nie, 100), _schritt("02_zwei")])
	var abhaengig := _ablauf("neues_spiel", [_schritt("01_gradwahl")], "titel")

	# Act
	await _laufe([titel, abhaengig])

	# Assert (FR-009)
	var erster := _lauf.schritt("titel.01_start")
	assert_eq(erster.status, SelbsttestLauf.Status.FEHLER)
	assert_eq(erster.gefunden, "Zeit abgelaufen, zuletzt: Menü steht: HAUPTMENÜ, „Weiterspielen“")
	assert_between(erster.dauer_ms, 100, 2000)
	assert_true(FileAccess.file_exists(BASIS + LAUF_ID + "/fotos/titel.01_start.png"),
		"Auch bei FEHLER gibt es ein Foto.")
	assert_eq(_lauf.schritt("titel.02_zwei").gefunden, "Fehler in Schritt titel.01_start")
	assert_eq(_lauf.schritt("neues_spiel.01_gradwahl").gefunden, "Fehler in Ablauf titel")
	assert_eq(_gesehen.size(), 1, "Nur der erste Schritt lief.")
	assert_eq(_lauf.summe_text(), "0 von 3 Schritten in Ordnung, 1 Fehler, 2 nicht gelaufen.")


func test_ziel_nicht_gefunden_scheitert_sofort() -> void:
	# Arrange
	var ohne_ziel := func() -> String: return "Ziel nicht gefunden: HAUPTMENÜ, „Neues Spiel“"
	var titel := _ablauf("titel", [_schritt("01_start", ohne_ziel, _passt, 5000)])

	# Act
	var beginn := Time.get_ticks_msec()
	await _laufe([titel])

	# Assert
	var schritt := _lauf.schritt("titel.01_start")
	assert_eq(schritt.status, SelbsttestLauf.Status.FEHLER)
	assert_eq(schritt.gefunden, "Ziel nicht gefunden: HAUPTMENÜ, „Neues Spiel“")
	assert_lt(Time.get_ticks_msec() - beginn, 1000, "Ohne Warten auf die Höchstzeit.")


func test_dauer_zaehlt_ab_der_ersten_eingabe() -> void:
	# Arrange: Der Schritt wartet erst 150 ms, dann geht die erste Eingabe hinaus.
	var viewport := SubViewport.new()
	add_child_autofree(viewport)
	var eingabe := SelbsttestEingabe.new()
	eingabe.viewport = viewport
	eingabe.senke = func(_ereignis: InputEvent) -> void: pass
	_laeufer.eingabe = eingabe
	var spaete_eingabe := func() -> void:
		var bis := Time.get_ticks_msec() + 150
		while Time.get_ticks_msec() < bis:
			await get_tree().process_frame
		await eingabe.taste(KEY_ENTER)
	var titel := _ablauf("titel", [_schritt("01_start", spaete_eingabe)])

	# Act
	await _laufe([titel])

	# Assert (Analyse, I1)
	assert_lt(_lauf.schritt("titel.01_start").dauer_ms, 150)


func test_meldungen_gehoeren_zum_schritt() -> void:
	# Arrange
	var mit_meldung := func() -> void: _logger._log_message("Seite fehlt\n", true)
	var titel := _ablauf("titel", [_schritt("01_start"), _schritt("02_zwei", mit_meldung)])

	# Act
	await _laufe([titel])

	# Assert
	assert_eq(_lauf.schritt("titel.01_start").meldungen, PackedStringArray())
	assert_eq(_lauf.schritt("titel.02_zwei").meldungen, PackedStringArray(["Seite fehlt"]))
	assert_string_contains(FileAccess.get_file_as_string(BASIS + LAUF_ID + "/ausgabe.txt"),
		"[titel.02_zwei] Seite fehlt\n")


func test_ein_foto_das_sich_nicht_speichern_laesst_ist_ein_eigener_fehler() -> void:
	# Arrange
	_laeufer.fotograf = func() -> Image:
		await get_tree().process_frame
		return null
	var titel := _ablauf("titel", [_schritt("01_start")])

	# Act
	await _laufe([titel])

	# Assert
	assert_eq(_lauf.schritt("titel.01_start").meldungen, PackedStringArray([
		"[selbsttest] titel.01_start.png ließ sich nicht schreiben: Invalid parameter"]))


# --- Fokus und Abbruch ----------------------------------------------------------------------------

func test_fokusverlust_mit_schritt() -> void:
	# Arrange
	var fokus_weg := func() -> void:
		_laeufer.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var titel := _ablauf("titel", [_schritt("01_start"), _schritt("02_zwei", fokus_weg)])

	# Act
	await _laufe([titel])

	# Assert
	assert_eq(_lauf.fokusverluste.size(), 1)
	assert_eq(_lauf.fokusverluste[0]["kennung"], "titel.02_zwei")
	assert_string_contains(FileAccess.get_file_as_string(BASIS + LAUF_ID + "/protokoll.txt"),
		"\nfokus.verluste: 1\nfokus.verlust: titel.02_zwei ")


func test_schliessen_bricht_ab_schreibt_und_beendet() -> void:
	# Arrange: Der zweite Schritt wartet auf einen Zustand, der nie kommt.
	var nie := func() -> String: return "Communicator nicht in Endlage"
	var titel := _ablauf("titel", [_schritt("01_start"), _schritt("02_zwei", _nichts, nie, 60000),
		_schritt("03_drei")])
	var fertig := []
	_laeufer.fertig.connect(func(lauf: SelbsttestLauf) -> void: fertig.append(lauf))
	_laeufer.starte(_lauf, [titel] as Array[SelbsttestAblauf])
	await wait_process_frames(5)

	# Act (FR-010)
	_laeufer.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	_laeufer.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	await wait_process_frames(2)

	# Assert
	assert_eq(_lauf.abbruch, "titel.02_zwei")
	assert_eq(_lauf.schritt("titel.01_start").status, SelbsttestLauf.Status.OK)
	assert_eq(_lauf.schritt("titel.02_zwei").gefunden, "Fenster geschlossen")
	assert_eq(_lauf.schritt("titel.03_drei").gefunden, "Fenster geschlossen")
	assert_eq(_beendet, 1, "Einmal beendet, auch beim zweiten Schließen.")
	assert_eq(_zusammengefasst, 0, "Nach einem Abbruch keine Zusammenfassung.")
	assert_eq(fertig.size(), 1)
	assert_string_contains(FileAccess.get_file_as_string(BASIS + LAUF_ID + "/protokoll.txt"),
		"\nlauf.abbruch: titel.02_zwei\n")
	assert_true(FileAccess.file_exists(BASIS + LAUF_ID + "_macos.zip"), "Das Zip ist geschrieben.")
	assert_eq(Engine.time_scale, 1.0)


func test_schliessen_bei_laufendem_spiel_geht_ueber_den_quit_callback_der_session() -> void:
	# Arrange
	var vorher := func() -> void: pass
	_sitzung.quit_callback = vorher
	var nie := func() -> String: return "Spielbildschirm steht"
	var titel := _ablauf("titel", [_schritt("01_start", _nichts, nie, 60000)])
	_laeufer.starte(_lauf, [titel] as Array[SelbsttestAblauf])
	await wait_process_frames(2)

	# Act: So ruft GameSession ihn, nachdem sie beim Schließen gespeichert hat (Analyse, U2).
	_sitzung.quit_callback.call()
	await wait_process_frames(2)

	# Assert
	assert_eq(_lauf.abbruch, "titel.01_start")
	assert_eq(_beendet, 1)
	assert_true(FileAccess.file_exists(BASIS + LAUF_ID + "/protokoll.txt"))
	assert_eq(_sitzung.quit_callback, vorher, "Nach dem Schreiben gilt wieder der alte.")


func test_nach_dem_schreiben_hoert_der_laeufer_nicht_mehr_auf_das_schliessen() -> void:
	# Arrange
	await _laufe([_ablauf("titel", [_schritt("01_start")])])

	# Act (CHK028)
	_laeufer.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)

	# Assert: Das Schließen beendet dann über auto_accept_quit, ohne den Läufer.
	assert_eq(_lauf.abbruch, "keiner")
	assert_eq(_beendet, 0)
	assert_eq(_zusammengefasst, 1)


func test_vor_dem_start_hoert_der_laeufer_nicht_auf_das_schliessen() -> void:
	# Arrange (Feature 008, T036a, B3): Der Läufer ist bereit, starte() kam noch nicht.
	var fertig := []
	_laeufer.fertig.connect(func(lauf: SelbsttestLauf) -> void: fertig.append(lauf))

	# Act
	_laeufer.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	_laeufer.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)

	# Assert: Nichts geschrieben, nichts beendet, kein Fokusverlust vermerkt.
	assert_eq([fertig.size(), _beendet, _zusammengefasst], [0, 0, 0])
	assert_eq(_lauf.fokusverluste.size(), 0)
	assert_false(FileAccess.file_exists(BASIS + LAUF_ID + "/protokoll.txt"))


func test_ein_ordner_ausserhalb_des_selbsttests_wird_nie_geleert() -> void:
	# Arrange: wie ein echter Ordner mit Spielständen, hier im Testordner
	var fremd := BASIS + "spielstaende/"
	DirAccess.make_dir_recursive_absolute(fremd)
	var datei := FileAccess.open(fremd + "spiel_1.json", FileAccess.WRITE)
	datei.store_string("{}")
	datei.close()
	_logger.setze_schritt("titel.01_start")

	# Act (FR-008, SC-006)
	_laeufer._leere_spielstaende(fremd)
	_laeufer._leere_spielstaende(SaveStore.FOLDER)

	# Assert
	assert_true(FileAccess.file_exists(fremd + "spiel_1.json"))
	assert_eq(_logger.meldungen("titel.01_start"), PackedStringArray([
		"[selbsttest] Ordner %s ist nicht der des Selbsttests und bleibt, wie er ist" % fremd,
		"[selbsttest] Ordner user://spielstaende/ ist nicht der des Selbsttests und bleibt, "
			+ "wie er ist"]))


func test_ein_fehlender_eigener_ordner_ist_schon_leer() -> void:
	# Arrange
	_logger.setze_schritt("titel.01_start")

	# Act: ohne Fehler aus DirAccess
	_laeufer._leere_spielstaende(SelbsttestLaeufer.EIGENER_ORDNER + "gibt_es_nicht_im_test/")

	# Assert
	assert_eq(_logger.meldungen("titel.01_start"), PackedStringArray())
	assert_false(DirAccess.dir_exists_absolute(SelbsttestLaeufer.EIGENER_ORDNER
		+ "gibt_es_nicht_im_test/"))


func test_die_liste_der_ablaeufe() -> void:
	# Act
	var ablaeufe := SelbsttestLaeufer.ablaeufe()

	# Assert: in der Reihenfolge des Vertrags, titel_echtzeit als letzter (contracts/ablaeufe.md);
	# wer auf einem anderen aufbaut, steht gleich hinter ihm.
	var kennungen: Array[String] = []
	var baut_auf: Array[String] = []
	for ablauf in ablaeufe:
		kennungen.append(ablauf.kennung)
		baut_auf.append(ablauf.baut_auf)
	assert_eq(kennungen, ["titel", "neues_spiel", "laden", "loeschen", "easter_egg", "bedienung",
		"liste", "fenster", "titel_echtzeit"] as Array[String])
	assert_eq(baut_auf, ["", "", "neues_spiel", "laden", "", "", "", "", ""] as Array[String])
	assert_eq(SelbsttestLaeufer.VERSION, 2, "Seit Phase 8 mit titel.04 und liste (R21).")


func test_nach_jedem_ablauf_raeumt_er_auf_auch_nach_einem_fehler() -> void:
	# Arrange: der zweite Ablauf scheitert; aufgeräumt wird trotzdem.
	_laeufer.fahrer = SelbsttestFahrer.new(get_tree())
	var falsch := func() -> String: return "falsch"
	var titel := _ablauf("titel", [_schritt("01_start")]) as ErfundenerAblauf
	var bedienung := _ablauf("bedienung", [_schritt("01_pfeile", Callable(), falsch, 50),
		_schritt("02_tab")]) as ErfundenerAblauf

	# Act
	await _laufe([titel, bedienung])

	# Assert
	assert_eq(titel.aufgeraeumt, 1)
	assert_eq(bedienung.aufgeraeumt, 1)
	assert_eq(_lauf.summe_text(), "1 von 3 Schritten in Ordnung, 1 Fehler, 1 nicht gelaufen.")


# --- Hilfen ---------------------------------------------------------------------------------------

## Startet den Lauf und wartet auf fertig, höchstens 10 s.
func _laufe(ablaeufe: Array) -> void:
	var liste: Array[SelbsttestAblauf] = []
	liste.assign(ablaeufe)
	_laeufer.starte(_lauf, liste)
	await wait_for_signal(_laeufer.fertig, 10)


## Ein erfundener Ablauf mit festen Schritten.
func _ablauf(kennung: String, schritte: Array, baut_auf: String = "",
		zeitraffer: int = 8) -> SelbsttestAblauf:
	var ablauf := ErfundenerAblauf.new()
	ablauf.kennung = kennung
	ablauf.name = SelbsttestTexte.ablauf_name(kennung)
	ablauf.baut_auf = baut_auf
	ablauf.zeitraffer = zeitraffer
	ablauf.vorlagen = schritte
	return ablauf


## Ein Schritt: Kennung, Eingaben, Prüfung und Höchstzeit. Die Eingaben schreiben vorher mit, was
## sie sehen.
func _schritt(nn_kurz: String, eingaben: Callable = Callable(), erwartet: Callable = Callable(),
		hoechstzeit_ms: int = 5000) -> Dictionary:
	var eingeben := eingaben if eingaben.is_valid() else _nichts
	var mit_blick := func() -> Variant:
		_gesehen.append({"titel": get_window().title, "zeitraffer": Engine.time_scale})
		return await eingeben.call()
	if not erwartet.is_valid():
		erwartet = _passt
	return {"nn_kurz": nn_kurz, "eingaben": mit_blick, "erwartet": erwartet,
		"hoechstzeit_ms": hoechstzeit_ms}


## Wie das echte Foto wartet es auf ein Bild; sonst liefe ein Lauf ohne Warten ganz in starte()
## durch, und fertig käme, bevor der Test darauf hört.
func _foto() -> Image:
	await get_tree().process_frame
	return Image.create(640, 360, false, Image.FORMAT_RGBA8)


func _nichts() -> void:
	pass


func _passt() -> String:
	return ""


## Wie ein echter Ablauf: erbt und baut seine Schritte mit neuer_schritt().
class ErfundenerAblauf:
	extends SelbsttestAblauf

	var vorlagen: Array = []
	var aufgeraeumt := 0

	func aufraeumen(_fahrer: SelbsttestFahrer) -> void:
		aufgeraeumt += 1

	func schritte(_fahrer: SelbsttestFahrer) -> Array[Dictionary]:
		var liste: Array[Dictionary] = []
		for vorlage: Dictionary in vorlagen:
			liste.append(neuer_schritt(vorlage["nn_kurz"], "Beschreibung %s" % vorlage["nn_kurz"],
				SelbsttestTexte.EINGABEN_KEINE, vorlage["eingaben"], vorlage["erwartet"],
				"Erwartet %s" % vorlage["nn_kurz"], true, vorlage["hoechstzeit_ms"]))
		return liste


func _raeume_auf(pfad: String) -> void:
	var ordner := DirAccess.open(pfad)
	if ordner == null:
		return
	for datei in ordner.get_files():
		ordner.remove(datei)
	for unterordner in ordner.get_directories():
		_raeume_auf(pfad.path_join(unterordner))
	DirAccess.remove_absolute(pfad)
