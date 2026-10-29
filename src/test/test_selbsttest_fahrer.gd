extends GutTest

## Prüft SelbsttestFahrer im echten Titel und im echten Spielbildschirm (Feature 007, T013;
## contracts/selbsttest-app.md, „Fahrer“; R5; FR-005, FR-006; Analyse, I3): Jedes Ziel wird
## gefunden, und eine Eingabe auf seine Mitte trifft genau diesen Eintrag; ein fehlendes Ziel nennt,
## was gesucht war; ob der Communicator steht, kommt aus slide_finished, nicht aus is_in(). Dazu der
## Ablauf „titel“ Schritt für Schritt über den Fahrer, ohne Fenster.
##
## Aufbau wie in test_title_screen.gd: eigene Uhr, eigene Zeitleiste mit Test-Katalog, eigene
## GameSession mit dem Ordner ORDNER, der Titel in einem eigenen Viewport von 640 × 360. Die Eingaben
## gehen über SelbsttestEingabe, aber statt an Input an push_input() dieses Viewports. Nach
## user://spielstaende/ schreibt kein Test; after_each() räumt WURZEL ab.
##
## Der Fahrer entsteht vor dem Titel, wie in der App: Er hört über node_added auf den neuen
## Communicator, bevor dessen Fahrt beginnt.

const TITEL := preload("res://scenes/title/title_screen.tscn")
const SPIELBILDSCHIRM := preload("res://scenes/game/game_screen.tscn")
const ABLAUF_TITEL := preload("res://tools/selbsttest/ablaeufe/ablauf_titel.gd")
const ABLAUF_TITEL_ECHTZEIT := preload("res://tools/selbsttest/ablaeufe/ablauf_titel_echtzeit.gd")
const SITZUNG := preload("res://core/game_session.gd")
const ZEITLEISTE := preload("res://core/timeline.gd")
const UHR := preload("res://core/game_clock.gd")
const WURZEL := "user://test_selbsttest_fahrer/"
const ORDNER := "user://test_selbsttest_fahrer/spielstaende/"
const KATALOG := "res://test/fixtures/catalog_us1_grade.json"
## 26.10.2026, 20:40:00 UTC, wie im Selbsttest.
const FESTE_ZEIT := 1793047200
const RASTER := Rect2(0, 0, 640, 360)
## So viele Bilder darf ein Schritt hier auf seinen Zustand warten; ohne Fahrt reicht eins.
const BILDER := 10

var _viewport: SubViewport
var _sitzung: SITZUNG
var _eingabe: SelbsttestEingabe
var _fahrer: SelbsttestFahrer
var _titel: TitleScreen


func before_each() -> void:
	_raeume_auf(WURZEL)
	DirAccess.make_dir_recursive_absolute(ORDNER)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(640, 360)
	add_child_autofree(_viewport)
	_sitzung = _neue_sitzung()
	_eingabe = SelbsttestEingabe.new()
	_eingabe.viewport = _viewport
	# Wie in der App über den Filter: das eigene Ereignis mit dem Gerät echter Maus und Tasten.
	_eingabe.senke = func(ereignis: InputEvent) -> void:
		_viewport.push_input(SelbsttestEingabe.fuer_das_spiel(ereignis))
	_fahrer = SelbsttestFahrer.new(get_tree(), _eingabe)
	_fahrer.session = _sitzung
	_titel = null


func after_each() -> void:
	await wait_process_frames(1)
	SaveGame.time_zone_bias = SaveGame.SYSTEM_BIAS
	_raeume_auf(WURZEL)


# --- Ziele im Hauptmenü ---------------------------------------------------------------------------

func test_jeder_eintrag_des_hauptmenues_wird_gefunden_und_getroffen() -> void:
	# Arrange
	await _zeige_titel()

	for kennung: StringName in [&"continue", &"new_game", &"load_game", &"settings", &"quit"]:
		# Act
		var ziel := _fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, kennung)
		await _eingabe.maus_zu(ziel.get_center())

		# Assert: Die Mitte des Ziels trifft genau diese Zeile, über den Weg echter Eingaben.
		assert_true(ziel.has_area(), String(kennung))
		assert_true(RASTER.encloses(ziel), "%s liegt im Raster: %s" % [kennung, ziel])
		assert_eq(_fahrer.gewaehlter_eintrag(), kennung)


func test_nach_der_fahrt_steht_das_hauptmenue_mit_neues_spiel() -> void:
	# Act
	await _zeige_titel()

	# Assert
	assert_true(_fahrer.communicator_steht())
	assert_eq(_fahrer.sichtbare_seite().name, SelbsttestFahrer.SEITE_HAUPTMENUE)
	assert_eq(_fahrer.gewaehlter_eintrag(), &"new_game")
	assert_eq(_fahrer.hinweis_text(), "Einen neuen Laden aufmachen. Los geht es am 01.01.1985.")
	assert_true(_fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"new_game"))
	assert_false(_fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"continue"))
	assert_eq(_fahrer.spielstaende(), PackedInt32Array())
	assert_eq(_fahrer.zustand(), "Menü steht: HAUPTMENÜ, „Neues Spiel“, Hinweis „Einen neuen "
		+ "Laden aufmachen. Los geht es am 01.01.1985.“; Spielstände: keine")


func test_der_communicator_steht_erst_mit_slide_finished_nicht_schon_mit_is_in() -> void:
	# Arrange: Er fährt, aber nur im Takt des Tests.
	await _zeige_titel(true)
	var communicator := _titel.get_node("Communicator") as Communicator

	# Assert: Auf der Fahrt herein ist is_in() schon wahr, er steht aber noch nicht (Analyse, I3).
	assert_true(communicator.is_in())
	assert_false(_fahrer.communicator_steht())
	assert_eq(_fahrer.zustand(), "Communicator nicht in Endlage; Spielstände: keine")

	# Act: zu Ende fahren
	for schritt in 30:
		communicator._process(1.0 / 60.0)

	# Assert
	assert_true(_fahrer.communicator_steht())


func test_fehlendes_ziel_nennt_was_gesucht_war_und_schickt_nichts() -> void:
	# Arrange
	await _zeige_titel()
	_eingabe.merke_beginn()

	# Act
	var antwort: String = await _fahrer.maus_ueber_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE,
		&"gibt_es_nicht", "HAUPTMENÜ, „Gibt es nicht“")

	# Assert
	assert_eq(antwort, "Ziel nicht gefunden: HAUPTMENÜ, „Gibt es nicht“")
	assert_eq(_eingabe.erste_eingabe_ms(), -1, "Ohne Ziel geht keine Eingabe hinaus.")
	assert_eq(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, &"gibt_es_nicht"), Rect2())
	assert_eq(_fahrer.ziel_eintrag(&"GibtEsNicht", &"new_game"), Rect2())
	assert_eq(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_GRADWAHL, &"medium"), Rect2(),
		"Eine unsichtbare Seite hat keine Ziele.")
	assert_eq(_fahrer.ziel_zeile(1), Rect2())
	assert_eq(_fahrer.ziel_gehaeusetaste(3), Rect2())
	assert_eq(_fahrer.ziel_knopf_hauptmenue(), Rect2())
	assert_eq(_fahrer.fehlt("SPIELSTÄNDE, Spiel 1"), "Ziel nicht gefunden: SPIELSTÄNDE, Spiel 1")


func test_eine_nicht_verfuegbare_zeile_nennt_das_in_gefunden() -> void:
	# Arrange: ohne Spielstand ist „Weiterspielen“ nicht verfügbar.
	await _zeige_titel()

	# Act
	await _eingabe.maus_zu(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, &"continue")
		.get_center())
	var nicht_verfuegbar := _fahrer.zustand()
	await _eingabe.maus_zu(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, &"quit")
		.get_center())
	var verfuegbar := _fahrer.zustand()

	# Assert: „verfügbar“ steht nur, wo ein Schritt es erwartet, nie in gefunden.
	assert_eq(nicht_verfuegbar, "Menü steht: HAUPTMENÜ, „Weiterspielen“, nicht verfügbar, "
		+ "Hinweis „Noch kein Spiel angefangen.“; Spielstände: keine")
	assert_eq(verfuegbar, "Menü steht: HAUPTMENÜ, „Beenden“, Hinweis „Laden abschließen und "
		+ "zurück zum Desktop.“; Spielstände: keine")
	assert_true(_fahrer.gewaehlt_verfuegbar())


func test_titel_03_scheitert_wenn_beenden_nicht_verfuegbar_ist() -> void:
	# Arrange: „Beenden“ gesperrt, wie ein eingebauter Fehler.
	await _zeige_titel()
	var menue := _titel.get_node("Communicator/MainMenu") as MainMenu
	var eintraege := menue.entries.duplicate()
	(eintraege[4] as MenuEntry).available = false
	menue.set_entries(eintraege, 4)
	var ablauf := ABLAUF_TITEL.new() as SelbsttestAblauf
	var schritte := ablauf.schritte(_fahrer)

	# Act
	await wait_process_frames(1)
	var gefunden: String = (schritte[2]["erwartet"] as Callable).call()

	# Assert: Erwartung und Befund unterscheiden sich sichtbar an genau dieser Stelle.
	assert_eq(schritte[2]["erwartet_text"], "Menü steht: HAUPTMENÜ, „Beenden“, verfügbar, "
		+ "Hinweis „Laden abschließen und zurück zum Desktop.“; nichts ausgelöst")
	assert_eq(gefunden, "Menü steht: HAUPTMENÜ, „Beenden“, nicht verfügbar, Hinweis „Laden "
		+ "abschließen und zurück zum Desktop.“; Spielstände: keine")


func test_ohne_fokus_heisst_es_seite_nicht_menue_steht() -> void:
	# Arrange
	await _zeige_titel()

	# Act: „Menü steht“ heißt, eine Zeile hat den Fokus (contracts/ablaeufe.md).
	_viewport.gui_release_focus()

	# Assert
	assert_eq(_fahrer.gewaehlter_eintrag(), &"")
	assert_false(_fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"new_game"))
	assert_eq(_fahrer.zustand(), "Seite HAUPTMENÜ, keine Zeile gewählt, Hinweis „Einen neuen "
		+ "Laden aufmachen. Los geht es am 01.01.1985.“; Spielstände: keine")


# --- Gradwahl, Liste, Gehäusetasten, Spielbildschirm ----------------------------------------------

func test_jeder_eintrag_der_gradwahl_wird_gefunden() -> void:
	# Arrange
	await _zeige_titel()

	# Act
	await _eingabe.klick(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, &"new_game")
		.get_center())

	# Assert
	assert_true(_fahrer.menue_steht(SelbsttestFahrer.SEITE_GRADWAHL, &"medium"))
	for kennung: StringName in [&"easy", &"medium", &"hard", &"back"]:
		var ziel := _fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_GRADWAHL, kennung)
		await _eingabe.maus_zu(ziel.get_center())
		assert_eq(_fahrer.gewaehlter_eintrag(), kennung)


func test_in_der_gradwahl_steht_der_grad_ohne_und_zurueck_mit_anfuehrungszeichen() -> void:
	# Arrange
	await _zeige_titel()
	await _eingabe.klick(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, &"new_game")
		.get_center())

	# Act
	await _eingabe.maus_zu(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_GRADWAHL, &"easy")
		.get_center())
	var grad := _fahrer.zustand()
	await _eingabe.maus_zu(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_GRADWAHL, &"back")
		.get_center())
	var zurueck := _fahrer.zustand()

	# Assert: in der Form der Spalte „Erwartet“, etwa „Menü steht: SCHWIERIGKEIT, Mittel“ (CHK031)
	assert_eq(grad, "Menü steht: SCHWIERIGKEIT, Leicht, Hinweis „Das Glück ist eher auf deiner "
		+ "Seite.“; Spielstände: keine")
	assert_eq(zurueck, "Menü steht: SCHWIERIGKEIT, „Zurück“, Hinweis „Zurück zum Hauptmenü. Esc "
		+ "geht auch.“; Spielstände: keine")


func test_in_der_liste_steht_der_spielstand_ohne_und_zurueck_mit_anfuehrungszeichen() -> void:
	# Arrange: „zuletzt gespielt“ in UTC+1 wie im Selbsttest
	SaveGame.time_zone_bias = 60
	_lege_an(1)
	await _zeige_titel()
	await _eingabe.klick(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, &"load_game")
		.get_center())

	# Act
	var spielstand := _fahrer.zustand()
	await _eingabe.maus_zu(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_SPIELSTAENDE,
		SelbsttestFahrer.ZEILE_LOESCHEN).get_center())
	var loeschen := _fahrer.zustand()

	# Assert
	assert_eq(spielstand, "Menü steht: SPIELSTÄNDE, Spiel 1 mit Mittel, 01.01.1985, Hinweis „Steht "
		+ "am 01.01.1985. Gespielt am 26.10.2026, 21:40 Uhr.“; Spielstände: Spiel 1")
	assert_eq(loeschen, "Menü steht: SPIELSTÄNDE, „Löschen …“, Hinweis „Einen Spielstand löschen. "
		+ "Vorher kommt eine Rückfrage.“; Spielstände: Spiel 1")


func test_zeile_und_feste_zeilen_der_liste_werden_gefunden() -> void:
	# Arrange
	_lege_an(1)
	await _zeige_titel()
	await _eingabe.klick(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, &"load_game")
		.get_center())

	# Assert
	assert_true(_fahrer.menue_steht(SelbsttestFahrer.SEITE_SPIELSTAENDE, &"slot_1"),
		_fahrer.zustand())
	assert_eq(_fahrer.ziel_zeile(2), Rect2(), "Spiel 2 gibt es nicht.")
	for ziel: Rect2 in [_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_SPIELSTAENDE,
			SelbsttestFahrer.ZEILE_LOESCHEN),
			_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_SPIELSTAENDE,
			SelbsttestFahrer.ZEILE_ZURUECK), _fahrer.ziel_zeile(1)]:
		assert_true(ziel.has_area())
	await _eingabe.maus_zu(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_SPIELSTAENDE,
		SelbsttestFahrer.ZEILE_ZURUECK).get_center())
	assert_true(_fahrer.menue_steht(SelbsttestFahrer.SEITE_SPIELSTAENDE,
		SelbsttestFahrer.ZEILE_ZURUECK), _fahrer.zustand())
	await _eingabe.maus_zu(_fahrer.ziel_zeile(1).get_center())
	assert_eq(_fahrer.gewaehlter_eintrag(), &"slot_1")
	assert_eq(_fahrer.spielstaende(), PackedInt32Array([1]))


func test_die_gehaeusetasten_werden_gefunden_und_starten_das_easter_egg() -> void:
	# Arrange
	await _zeige_titel()
	var gehaeuse := (_titel.get_node("Communicator/Case") as Control).get_global_rect()

	# Act: links, Mitte, rechts
	for index in 3:
		var ziel := _fahrer.ziel_gehaeusetaste(index)
		assert_true(gehaeuse.encloses(ziel), "Taste %d liegt im Gehäuse." % index)
		await _eingabe.klick(ziel.get_center())

	# Assert
	assert_eq(_fahrer.sichtbare_seite().name, SelbsttestFahrer.SEITE_INVADERS)
	assert_eq(_fahrer.zustand(), "Seite Invaders sichtbar und aktiv, Hinweis aus; Spielstände: keine")
	assert_true(_fahrer.invaders_aktiv())
	assert_eq(_fahrer.kanone_x(), InvadersGame.CANNON_START_X)
	assert_false(_fahrer.schuss_unterwegs())
	assert_eq(_fahrer.treffer(), 0)


func test_der_knopf_zum_hauptmenue_wird_gefunden() -> void:
	# Arrange
	var spiel := SPIELBILDSCHIRM.instantiate() as GameScreen
	spiel.session = _sitzung
	_viewport.add_child(spiel)
	_fahrer.szene = spiel
	await wait_process_frames(1)

	# Act
	var ziel := _fahrer.ziel_knopf_hauptmenue()

	# Assert
	assert_true(ziel.has_area())
	assert_true(RASTER.encloses(ziel))
	assert_null(_fahrer.titel())
	assert_eq(_fahrer.spielbildschirm(), spiel)
	assert_eq(_fahrer.gewaehlter_eintrag(), SelbsttestFahrer.KNOPF_HAUPTMENUE)
	assert_eq(_fahrer.zustand(), "Spielbildschirm steht, Hinweis aus; Spielstände: keine")


func test_beenden_wird_abgefangen_und_gezaehlt() -> void:
	# Arrange
	await _zeige_titel()

	# Act
	await _eingabe.klick(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, &"quit")
		.get_center())

	# Assert: Der Titel ruft den quit_callback des Fahrers statt get_tree().quit().
	assert_eq(_fahrer.beenden_ausgeloest(), 1)
	assert_string_contains(_fahrer.zustand(), "; „Beenden“ ausgelöst; ")


func test_die_zeile_eines_spielstands_nennt_grad_und_spieldatum_wie_sie_dastehen() -> void:
	# Arrange
	_lege_an(1)
	await _zeige_titel()
	await _eingabe.klick(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, &"load_game")
		.get_center())

	# Act
	var angaben := _fahrer.zeile_angaben()
	await _eingabe.maus_zu(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_SPIELSTAENDE,
		SelbsttestFahrer.ZEILE_ZURUECK).get_center())

	# Assert: gelesen aus den Spalten der Zeile; ohne Spielstand in der Zeile leer.
	assert_eq(angaben, "Mittel, 01.01.1985")
	assert_eq(_fahrer.zeile_angaben(), "")
	assert_eq(_fahrer.kopfzeile(), "SPIELSTÄNDE")


func test_im_loeschmodus_ist_loeschen_nicht_verfuegbar_auch_in_gefunden() -> void:
	# Arrange
	_lege_an(1)
	await _zeige_titel()
	await _eingabe.klick(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, &"load_game")
		.get_center())
	var vorher := _fahrer.gewaehlt_verfuegbar()

	# Act
	var antwort: String = await _fahrer.klick_auf_eintrag(SelbsttestFahrer.SEITE_SPIELSTAENDE,
		SelbsttestFahrer.ZEILE_LOESCHEN, "SPIELSTÄNDE, „Löschen …“")

	# Assert: „nicht verfügbar“ steht wie im Menü hinter der Zeile (Verfügbarkeit im Vertrag).
	assert_eq(antwort, "")
	assert_true(vorher, "Spiel 1 ist fortsetzbar.")
	assert_false(_fahrer.gewaehlt_verfuegbar())
	assert_eq(_fahrer.kopfzeile(), "WELCHES LÖSCHEN?")
	assert_eq(_fahrer.zustand(), "Menü steht: WELCHES LÖSCHEN?, „Löschen …“, nicht verfügbar, "
		+ "Hinweis „Wähl oben den Spielstand, der weg soll. Esc bricht ab.“; Spielstände: Spiel 1")


func test_hinausgefahren_gilt_nach_der_fahrt_hinaus_bis_zum_naechsten_communicator() -> void:
	# Arrange
	await _zeige_titel()
	var communicator := _titel.get_node("Communicator") as Communicator
	var vorher := _fahrer.hinausgefahren()

	# Act
	communicator.slide_out()
	var danach := _fahrer.hinausgefahren()
	_titel.queue_free()
	await wait_process_frames(1)
	var ohne_titel := _fahrer.hinausgefahren()
	await _zeige_titel()

	# Assert
	assert_false(vorher)
	assert_true(danach)
	assert_true(ohne_titel, "Der Titel ist weg, die Fahrt bleibt vermerkt.")
	assert_false(_fahrer.hinausgefahren(), "Ein neuer Communicator beginnt von vorn.")


func test_spielbildschirm_steht_mit_dem_laufenden_spiel() -> void:
	# Arrange
	assert_eq(_sitzung.start_new(Difficulty.Level.MITTEL), OK)
	var spiel := SPIELBILDSCHIRM.instantiate() as GameScreen
	spiel.session = _sitzung
	_viewport.add_child(spiel)
	_fahrer.szene = spiel
	await wait_process_frames(1)

	# Assert
	assert_eq(_fahrer.laufendes_spiel(), "Spiel 1")
	assert_true(_fahrer.spielbildschirm_steht("Spiel 1"))
	assert_false(_fahrer.spielbildschirm_steht("Spiel 2"))
	assert_false(_fahrer.spielbildschirm_steht(""))
	assert_eq(_fahrer.zustand(), "Spielbildschirm steht, Hinweis „Speichert Spiel 1 und führt ins "
		+ "Hauptmenü.“; Spielstände: Spiel 1")
	assert_eq(_sitzung.leave(), OK)


func test_pfeil_runter_bis_waehlt_den_eintrag_und_meldet_einen_fehlenden() -> void:
	# Arrange: „Neues Spiel“ ist vorgewählt.
	await _zeige_titel()

	# Act
	var antwort: String = await _fahrer.pfeil_runter_bis(SelbsttestFahrer.SEITE_HAUPTMENUE, &"quit",
		"HAUPTMENÜ, „Beenden“")
	var fehlt: String = await _fahrer.pfeil_runter_bis(SelbsttestFahrer.SEITE_HAUPTMENUE,
		&"gibt_es_nicht", "HAUPTMENÜ, „Gibt es nicht“")

	# Assert
	assert_eq(antwort, "")
	assert_eq(_fahrer.gewaehlter_eintrag(), &"quit")
	assert_eq(_fahrer.beenden_ausgeloest(), 0)
	assert_eq(fehlt, "Ziel nicht gefunden: HAUPTMENÜ, „Gibt es nicht“")


func test_klicks_ohne_ziel_nennen_was_gesucht_war() -> void:
	# Arrange: im Titel gibt es keine Liste und keinen Spielbildschirm.
	await _zeige_titel()
	_eingabe.merke_beginn()

	# Act
	var zeile: String = await _fahrer.klick_auf_zeile(1, "SPIELSTÄNDE, Spiel 1")
	var knopf: String = await _fahrer.klick_auf_knopf_hauptmenue("Spielbildschirm, „Zum Hauptmenü“")

	# Assert
	assert_eq(zeile, "Ziel nicht gefunden: SPIELSTÄNDE, Spiel 1")
	assert_eq(knopf, "Ziel nicht gefunden: Spielbildschirm, „Zum Hauptmenü“")
	assert_eq(_eingabe.erste_eingabe_ms(), -1, "Ohne Ziel geht keine Eingabe hinaus.")


func test_das_versteckte_spiel_nach_esc_ist_nicht_mehr_aktiv() -> void:
	# Arrange: gestartet, dann die Partie beendet, ohne die Seite zu schließen.
	await _zeige_titel()
	for index in 3:
		await _eingabe.klick(_fahrer.ziel_gehaeusetaste(index).get_center())
	var seite := _fahrer.invaders()

	# Act
	seite.game().state = InvadersGame.State.LOST

	# Assert
	assert_false(_fahrer.invaders_aktiv())
	assert_string_starts_with(_fahrer.zustand(), "Seite Invaders sichtbar und nicht aktiv, ")


func test_ohne_versteckes_spiel_gibt_es_keine_kanone() -> void:
	# Arrange
	await _zeige_titel()

	# Assert
	assert_null(_fahrer.invaders())
	assert_false(_fahrer.invaders_aktiv())
	assert_eq(_fahrer.kanone_x(), -1)
	assert_false(_fahrer.schuss_unterwegs())
	assert_eq(_fahrer.treffer(), 0)


func test_gewaehlter_text_steht_wie_die_zeile() -> void:
	# Arrange
	await _zeige_titel()

	# Act
	var neues_spiel := _fahrer.gewaehlter_text()
	await _fahrer.taste(KEY_TAB, true)

	# Assert: Umschalt+Tab geht eine Zeile hoch.
	assert_eq(neues_spiel, "Neues Spiel")
	assert_eq(_fahrer.gewaehlter_text(), "Weiterspielen")


func test_vorbereitung_legt_spielstaende_an_und_raeumt_nur_sie_weg() -> void:
	# Arrange: Spiel 9 lag schon da und bleibt.
	SaveGame.time_zone_bias = 60
	_lege_an(9)

	# Act
	var antwort := _fahrer.lege_spielstaende_an(3)
	var angelegt := _fahrer.spielstaende()
	_fahrer.raeume_spielstaende_weg()

	# Assert: „zuletzt gespielt“ fest, Spiel 1 ganz oben, dann je eine Stunde früher.
	assert_eq(antwort, "")
	assert_true(angelegt.has(9))
	assert_eq(Array(angelegt).filter(func(nummer: int) -> bool: return nummer != 9), [1, 2, 3])
	assert_eq(_fahrer.spielstaende(), PackedInt32Array([9]))


func test_titel_neu_laden_wartet_bis_das_hauptmenue_steht() -> void:
	# Arrange: Der Test wechselt selbst, wie die App es mit change_scene_to_file() täte.
	await _zeige_titel()
	var alt := _titel
	_fahrer.szenenwechsel = func(_pfad: String) -> void:
		alt.queue_free()
		_zeige_titel.call_deferred()

	# Act
	var antwort: String = await _fahrer.lade_titel_neu()

	# Assert
	assert_eq(antwort, "")
	assert_ne(_fahrer.titel(), alt)
	assert_true(_fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"new_game"))


func test_spielbildschirm_ohne_fokus_steht_nicht() -> void:
	# Arrange
	assert_eq(_sitzung.start_new(Difficulty.Level.MITTEL), OK)
	var spiel := SPIELBILDSCHIRM.instantiate() as GameScreen
	spiel.session = _sitzung
	_viewport.add_child(spiel)
	_fahrer.szene = spiel
	await wait_process_frames(1)

	# Act: „Zum Hauptmenü“ verliert den Fokus.
	_viewport.gui_release_focus()

	# Assert: „steht“ nur mit Fokus (B4).
	assert_false(_fahrer.spielbildschirm_steht("Spiel 1"))
	assert_eq(_fahrer.zustand(), "Spielbildschirm, „Zum Hauptmenü“ ohne Fokus, Hinweis „Speichert "
		+ "Spiel 1 und führt ins Hauptmenü.“; Spielstände: Spiel 1")
	assert_eq(_sitzung.leave(), OK)


func test_eine_fehlende_gehaeusetaste_heisst_nach_ihrer_lage() -> void:
	# Arrange: ohne Titel gibt es keine Gehäusetasten.
	_eingabe.merke_beginn()

	# Act
	var antwort: String = await _fahrer.klick_auf_gehaeusetasten([2, 0])

	# Assert (B11)
	assert_eq(antwort, "Ziel nicht gefunden: Gehäusetaste rechts")
	assert_eq(_eingabe.erste_eingabe_ms(), -1)


func test_die_uhr_laesst_sich_noch_nicht_bedienen() -> void:
	# Act
	var antwort := _fahrer.uhr_bis(GameDate.new(1987, 3, 1))

	# Assert
	assert_eq(antwort, "Die Uhr lässt sich im Spielbildschirm noch nicht bedienen")


func test_liste_oben_und_marke_nach_dem_mausrad() -> void:
	# Arrange: sieben Spielstände, die Anzeige zeigt fünf.
	SaveGame.time_zone_bias = 60
	assert_eq(_fahrer.lege_spielstaende_an(7), "")
	await _zeige_titel()
	await _fahrer.klick_auf_eintrag(SelbsttestFahrer.SEITE_HAUPTMENUE, &"load_game", "")
	var vorher := [_fahrer.liste_oben(), _fahrer.marke_oben()]

	# Act
	var antwort: String = await _fahrer.mausrad_auf_zeile(1, MOUSE_BUTTON_WHEEL_DOWN, "")

	# Assert
	assert_eq(antwort, "")
	assert_eq(vorher, ["Spiel 1", false])
	assert_eq(_fahrer.liste_oben(), "Spiel 2")
	assert_true(_fahrer.marke_oben())
	assert_eq(_fahrer.gewaehlter_eintrag(), &"slot_2")


func test_fenster_text_ohne_rand_mit_rand_und_krumm() -> void:
	# Act
	var faktor_1 := SelbsttestFahrer.fenster_text(Vector2i(640, 360), Transform2D.IDENTITY)
	var start := SelbsttestFahrer.fenster_text(Vector2i(3200, 1800),
		Transform2D(0.0, Vector2(5, 5), 0.0, Vector2.ZERO))
	var krumm := SelbsttestFahrer.fenster_text(Vector2i(1317, 741),
		Transform2D(0.0, Vector2(2, 2), 0.0, Vector2(18, 10)))
	var seitlich := SelbsttestFahrer.fenster_text(Vector2i(1317, 741),
		Transform2D(0.0, Vector2(2, 2), 0.0, Vector2(0, 10)))
	var gestreckt := SelbsttestFahrer.fenster_text(Vector2i(1600, 900),
		Transform2D(0.0, Vector2(2.5, 2.5), 0.0, Vector2.ZERO))

	# Assert
	assert_eq(faktor_1, "Fenster 640 × 360, Bild Faktor 1, ohne Rand")
	assert_eq(start, "Fenster 3200 × 1800, Bild Faktor 5, ohne Rand")
	assert_eq(krumm, "Fenster 1317 × 741, Bild Faktor 2, mittig, Rand ringsum, ganze Pixel")
	assert_eq(seitlich, "Fenster 1317 × 741, Bild Faktor 2, nicht mittig, Rand links 0, "
		+ "rechts 37, oben 10, unten 11, ganze Pixel")
	assert_eq(gestreckt, "Fenster 1600 × 900, Bild Faktor 2,5, ohne Rand, keine ganzen Pixel")


func test_versatz_misst_den_rahmen_samt_titelleiste_im_nutzbaren_bereich() -> void:
	# Arrange: wie am Mac gemessen, nutzbar ab y 60 mit 1914 Höhe, Rahmen 3200 × 1864.
	var nutzbar := Rect2i(0, 60, 3840, 1914)

	# Assert: vor Feature 007 stand der Rahmen bei y 116, mittig wäre 85.
	assert_eq(SelbsttestFahrer.versatz_zur_mitte(nutzbar, Rect2i(320, 85, 3200, 1864)),
		Vector2i.ZERO)
	assert_eq(SelbsttestFahrer.versatz_zur_mitte(nutzbar, Rect2i(320, 116, 3200, 1864)),
		Vector2i(0, 31))


func test_fenster_rechteck_nennt_lage_und_groesse_des_fensters() -> void:
	# Arrange (Feature 008, T036a, M1): Die Abläufe lesen Größe und Lage nur über den Fahrer.
	var fenster := get_tree().root

	# Act
	var rechteck := _fahrer.fenster_rechteck()

	# Assert
	assert_eq(rechteck, Rect2i(fenster.position, fenster.size))


func test_lage_text_auf_einen_pixel_genau() -> void:
	# Assert
	assert_eq(SelbsttestFahrer.lage_text(Vector2i(1, -1)),
		"mittig im nutzbaren Bereich, auf 1 Pixel genau")
	assert_eq(SelbsttestFahrer.lage_text(Vector2i(0, 2)),
		"0 Pixel rechts, 2 Pixel unter der Mitte des nutzbaren Bereichs")
	assert_eq(SelbsttestFahrer.lage_text(Vector2i(-12, -3)),
		"12 Pixel links, 3 Pixel über der Mitte des nutzbaren Bereichs",
		"Negativer Versatz heißt links und über (B8).")


# --- Ablauf „titel“ über den Fahrer ---------------------------------------------------------------

func test_ablauf_titel_hat_die_schritte_aus_dem_vertrag() -> void:
	# Act
	var schritte := ABLAUF_TITEL.new().schritte(_fahrer)

	# Assert: Wortlaute ausgeschrieben, damit jede Änderung hier auffällt.
	assert_eq(_feld(schritte, "kennung"), ["titel.01_start", "titel.02_nicht_verfuegbar",
		"titel.03_beenden_da", "titel.04_einstellungen"])
	assert_eq(_feld(schritte, "beschreibung"), ["Start, der Communicator fährt herein",
		"Maus über „Weiterspielen“ wählt, ohne Spielstand nicht verfügbar",
		"Maus über „Beenden“ wählt, ohne auszulösen",
		"Maus über „Einstellungen“ wählt, noch nicht verfügbar"])
	assert_eq(_feld(schritte, "eingaben_text"), ["keine", "Maus über „Weiterspielen“",
		"Maus über „Beenden“", "Maus über „Einstellungen“"])
	assert_eq(_feld(schritte, "erwartet_text"), [
		"Menü steht: HAUPTMENÜ, „Neues Spiel“; Spielstände: keine",
		"Menü steht: HAUPTMENÜ, „Weiterspielen“, nicht verfügbar, Hinweis „Noch kein Spiel "
			+ "angefangen.“; nichts ausgelöst",
		"Menü steht: HAUPTMENÜ, „Beenden“, verfügbar, Hinweis „Laden abschließen und zurück "
			+ "zum Desktop.“; nichts ausgelöst",
		"Menü steht: HAUPTMENÜ, „Einstellungen“, nicht verfügbar, Hinweis „Noch nichts "
			+ "einzustellen. Kommt später.“; nichts ausgelöst"])
	assert_eq(_feld(schritte, "foto_vergleichbar"), [true, true, true, true])


func test_titel_in_echtzeit_hat_dieselben_schritte_ohne_zeitraffer() -> void:
	# Act
	var titel := ABLAUF_TITEL.new() as SelbsttestAblauf
	var echtzeit := ABLAUF_TITEL_ECHTZEIT.new() as SelbsttestAblauf
	var schritte := echtzeit.schritte(_fahrer)

	# Assert
	assert_eq(titel.zeitraffer, 8)
	assert_eq(echtzeit.zeitraffer, 1)
	assert_eq(echtzeit.name, "Titel in Echtzeit")
	assert_eq(_feld(schritte, "kennung"), ["titel_echtzeit.01_start",
		"titel_echtzeit.02_nicht_verfuegbar", "titel_echtzeit.03_beenden_da",
		"titel_echtzeit.04_einstellungen"])
	assert_eq(_feld(schritte, "erwartet_text"), _feld(titel.schritte(_fahrer), "erwartet_text"))


func test_ablauf_titel_laeuft_im_echten_titel_durch() -> void:
	# Arrange: Der Communicator fährt; zu Beginn steht er also noch nicht.
	await _zeige_titel(true)
	var communicator := _titel.get_node("Communicator") as Communicator
	# Die Callables der Schritte halten ihren Ablauf nicht; der Test hält ihn, wie in der App der
	# Läufer.
	var ablauf := ABLAUF_TITEL.new() as SelbsttestAblauf
	var schritte := ablauf.schritte(_fahrer)
	assert_ne((schritte[0]["erwartet"] as Callable).call(), "", "Vor dem Ende der Fahrt nicht.")
	for schritt in 30:
		communicator._process(1.0 / 60.0)

	for schritt in schritte:
		# Act
		var antwort: Variant = await (schritt["eingaben"] as Callable).call()
		var zustand := await _warte_auf(schritt["erwartet"])

		# Assert
		assert_eq(antwort, "", schritt["kennung"])
		assert_eq(zustand, "", schritt["kennung"])
	assert_eq(_fahrer.beenden_ausgeloest(), 0)


func test_ablauf_titel_meldet_einen_falschen_zustand_in_der_form_der_erwartung() -> void:
	# Arrange: ein Spielstand, also ist „Weiterspielen“ vorgewählt statt „Neues Spiel“.
	_lege_an(1)
	await _zeige_titel()
	var ablauf := ABLAUF_TITEL.new() as SelbsttestAblauf
	var schritte := ablauf.schritte(_fahrer)

	# Act
	var zustand: String = (schritte[0]["erwartet"] as Callable).call()

	# Assert
	assert_eq(zustand, "Menü steht: HAUPTMENÜ, „Weiterspielen“, Hinweis „Weiter mit Spiel 1, "
		+ "Mittel, am 01.01.1985.“; Spielstände: Spiel 1")


# --- Hilfen ---------------------------------------------------------------------------------------

## Baut den Titel mit der Session _sitzung im eigenen Viewport und wartet, bis er seine Blätter
## gebaut hat. [param faehrt] false: Der Communicator steht sofort in der Endlage; true: Er fährt,
## aber nur im Takt des Tests.
func _zeige_titel(faehrt := false) -> void:
	_titel = TITEL.instantiate() as TitleScreen
	_titel.session = _sitzung
	_titel.scene_callback = func(_pfad: String) -> void: pass
	_viewport.add_child(_titel)
	_fahrer.szene = _titel
	var communicator := _titel.get_node("Communicator") as Communicator
	communicator.animate = faehrt
	if faehrt:
		communicator.set_process(false)
	# Wie test_title_screen.gd: Die Maus steht im Viewport, sonst gibt er Bewegungen nicht weiter.
	_viewport.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)
	await wait_process_frames(2)


## Ruft [param pruefung] bis zu BILDER Bilder lang, bis sie "" gibt; gibt den letzten Zustand.
func _warte_auf(pruefung: Callable) -> String:
	var zustand: String = pruefung.call()
	for bild in BILDER:
		if zustand.is_empty():
			break
		await wait_process_frames(1)
		zustand = pruefung.call()
	return zustand


func _neue_sitzung() -> SITZUNG:
	var uhr := UHR.new()
	add_child_autofree(uhr)
	var zeitleiste := ZEITLEISTE.new()
	zeitleiste.catalog_path = KATALOG
	zeitleiste.clock = uhr
	add_child_autofree(zeitleiste)
	var sitzung := SITZUNG.new()
	sitzung.folder = ORDNER
	sitzung.clock = uhr
	sitzung.timeline = zeitleiste
	sitzung.now = func() -> int: return FESTE_ZEIT
	sitzung.quit_callback = func() -> void: pass
	add_child_autofree(sitzung)
	return sitzung


## Legt im Testordner Spiel [param nummer] an, Mittel, am 01.01.1985.
func _lege_an(nummer: int) -> void:
	var meldungen: Array[CatalogIssue] = []
	var game := SaveGame.new()
	game.number = nummer
	game.name = SaveGame.default_name(nummer)
	game.difficulty = Difficulty.Level.MITTEL
	game.seed = 4711
	game.day = TimelineRun.FIRST_DAY
	game.created_at = FESTE_ZEIT
	game.last_played_at = FESTE_ZEIT
	game.game_version = "0.1"
	game.catalog = EventCatalog.read_file(KATALOG, meldungen)
	assert_eq(SaveStore.new(ORDNER).write(game, true), OK, "Spiel %d angelegt." % nummer)


## Die Werte von [param schluessel] aus allen [param schritte].
static func _feld(schritte: Array[Dictionary], schluessel: String) -> Array:
	var werte := []
	for schritt in schritte:
		werte.append(schritt[schluessel])
	return werte


func _raeume_auf(pfad: String) -> void:
	var ordner := DirAccess.open(pfad)
	if ordner == null:
		return
	for datei in ordner.get_files():
		ordner.remove(datei)
	for unterordner in ordner.get_directories():
		_raeume_auf(pfad.path_join(unterordner))
	DirAccess.remove_absolute(pfad)
