extends GutTest

## Prüft den Titelbildschirm: den Text der Versionszeile (Feature 001, FR-014) und seit Feature 004
## die Blätter Hauptmenü und Gradwahl (T020; contracts/titelbildschirm.md, „TitleScreen“ und
## „Tests“; data-model.md, „Titelbildschirm: Blätter und Wege“): fünf Einträge, ihre Verfügbarkeit
## und Hinweise nach den Spielständen im Ordner, die Vorwahl, die Gradwahl mit Tastatur und Maus,
## Esc und „Zurück“, ein neues Spiel mit 3 Eingaben (SC-001), „Weiterspielen“ mit 1 (SC-002), die
## Meldung, wenn das Anlegen scheitert, und dass ohne Spiel nichts läuft und keine Datei entsteht
## (FR-003).
##
## Dazu die Liste der Spielstände (T026): bei jedem Öffnen neu gelesen, Fortsetzen über die Liste mit
## 2 Klicks oder 4 Tasten (SC-002), die Anzeige mit 20 Spielständen in höchstens 1 s, „Zurück“ und
## Esc. Und das Löschen (T027): Rückfrage, Abbrechen, Bestätigen, die Auswahl danach, das Ende des
## Löschmodus auf allen vier Wegen, fremde Dateien bleiben, Löschen scheitert, Datei schon weg. Die
## Meldung zum Löschen gehört zum Spielstand: Sie wandert beim Rollen mit, und ein anderer
## Spielstand an derselben Stelle bringt seinen Hinweis.
##
## Wie test_game_session.gd arbeiten die Tests nicht mit den Autoloads. _zeige_titel() baut je Test
## eine eigene Uhr, eine eigene Zeitleiste mit Test-Katalog und eine eigene GameSession mit dem
## Ordner ORDNER; den Szenenwechsel fängt ein eigener scene_callback ab, der nur mitschreibt. Nach
## user://spielstaende/ schreibt und liest kein Test; after_each() räumt WURZEL ab.
##
## Seit Feature 005 (T028) stehen die Blätter als Seiten auf der Anzeige des Communicators; die
## Pfade gehen über Communicator/<Seite>, jede Seite ist so groß wie die Anzeige und steht an ihrer
## Stelle, und der Hinweis steht links neben dem Gehäuse. Sonst prüfen die Tests dasselbe wie vorher
## (SC-007). Dafür fährt der Communicator in diesen Tests nicht (animate = false): Er steht sofort
## in der Endlage, und ein begonnenes Spiel wechselt sofort die Szene.
##
## Die Fahrt prüfen eigene Tests (T030): Erscheinen draußen und herein, Wache vor den Einträgen,
## Hinausfahren vor dem Spielbildschirm ohne zweites Spiel, die Meldung neben der Zeile, wo sie
## jetzt ist, und die Dauer. Dort taktet der Test die Fahrt selbst wie in test_communicator.gd:
## set_process(false) am Communicator und _process() mit festen Zeitschritten.
##
## „Beenden“ schließt sofort, ohne Fahrt hinaus (T041; FR-013a). get_tree().quit() beendete den
## ganzen Testlauf; deshalb fängt ein eigener quit_callback den Aufruf ab und zählt nur mit.
##
## Der Titel steht in einem eigenen Viewport von 640 × 360 wie die Menüs in test_main_menu.gd:
## eigene Eingabe, eigener Fokus, und GUTs Oberfläche fängt keine Klicks ab. Tasten und Klicks gehen
## über push_input wie echte Eingaben.
##
## Seit Feature 006 (T031) das Easter Egg: Die Gehäusetasten bekommen erfundene Mausereignisse an der
## Stelle, an der sie gerade stehen. Links, Mitte, rechts startet Space Invaders auf jeder der vier
## Seiten, jede andere Folge nichts; Esc und das Ende nach der Ergebnisanzeige stellen Seite, Fokus
## und Hinweis wieder her; das Easter Egg schreibt nichts, auch nicht beim Schließen des Fensters.
## SC-001 und SC-006 messen die Zeit mit Time.get_ticks_usec() und nennen sie im Protokoll.

const TITEL := preload("res://scenes/title/title_screen.tscn")
const SITZUNG := preload("res://core/game_session.gd")
const ZEITLEISTE := preload("res://core/timeline.gd")
const UHR := preload("res://core/game_clock.gd")
const WURZEL := "user://test_title_screen/"
const ORDNER := "user://test_title_screen/spielstaende/"
const KATALOGE := "res://test/fixtures/"
const FIXTURES := "res://test/fixtures/spielstaende/"
const SPIELBILDSCHIRM := "res://scenes/game/game_screen.tscn"
## 26.10.2026, 20:40:12 UTC
const ANGELEGT := 1793047212
const WUERFEL_SEED := 20261026
const ZEILE := MainMenu.ROW_HEIGHT
## Die Anzeige des Communicators im Titel (Style-Guide, Baustein Communicator, Lage im Titel): das
## Gehäuse bei (244, 92), die Anzeige darin bei (36, 28), 320 × 160. Jede Seite liegt genau darauf.
const ANZEIGE := Rect2(280, 120, 320, 160)
## Linke Kante des Gehäuses im Titel; der Hinweis steht 4 davor.
const GEHAEUSE_LINKS := 244.0
## Oberkante des Gehäuses in der Endlage, 9 unter dem Logoblock (Style-Guide: mindestens raster-8).
const GEHAEUSE_OBEN := 92.0
## Kleinster Abstand zwischen Logoblock und Gehäuse (Style-Guide, Token raster-8).
const RASTER_8 := 8.0

## Die Sätze für den Spieler, hier ausgeschrieben statt als Konstanten aus dem Code: So fällt jede
## Änderung hier auf.
const NICHT_ANGELEGT := "Speichern ging nicht. Es ist kein Spiel angelegt."
const LOESCHEN_GING_NICHT := "Löschen ging nicht. Der Spielstand ist noch da."
## „Spiel laden“, immer derselbe Satz, auch wenn sich keiner fortsetzen lässt (T038).
const HINWEIS_LADEN := "Zurück in einen deiner Läden."
const HINWEIS_ZURUECK_IM_MODUS := "Nicht löschen. Esc geht auch."
## SC-002: so viele Spielstände, so lange darf die Anzeige der Liste dauern, so oft gemessen.
const SPIELSTAENDE := 20
const LISTE_MSEC := 1000.0
const LAEUFE := 3
## Die Folge des Easter Eggs: Plätze 0, 1, 2 in case_keys, für den Spieler 1-2-3 (FR-002).
const FOLGE: Array[int] = [0, 1, 2]
## Die drei grauen Tasten von G-03 in Bildpixeln des Gehäuses (Style-Guide, Baustein Communicator,
## Gehäusetasten) und dieselben auf der Oberfläche im Titel, ×2 ab der Endlage (244, 92).
const TASTEN: Array[Rect2i] = [Rect2i(140, 114, 11, 8), Rect2i(154, 114, 12, 8),
	Rect2i(169, 114, 12, 8)]
const TASTEN_IM_TITEL: Array[Rect2] = [Rect2(524, 320, 22, 16), Rect2(552, 320, 24, 16),
	Rect2(582, 320, 24, 16)]
## SC-001: so lange darf es vom dritten Druck dauern, bis das Spiel den Fokus hat.
const SPIELBEREIT_S := 0.5
## SC-006: so lange darf es von finished dauern, bis der Titel wieder Eingaben annimmt.
const RUECKWEG_S := 1.0
## Mehr Schritte braucht keine Partie bis zum Ende (wie test_invaders_page.gd).
const HOECHSTENS_SCHRITTE := 10800

var _titel: TitleScreen
var _sitzung: SITZUNG
## Die Pfade, mit denen der Titel scene_callback aufgerufen hat.
var _wechsel: Array = []
## So oft hat der Titel quit_callback aufgerufen.
var _beendet := 0
var _auto_accept_quit_vorher := true


func before_each() -> void:
	_raeume_auf(WURZEL)
	DirAccess.make_dir_recursive_absolute(ORDNER)
	_wechsel.clear()
	_beendet = 0
	_titel = null
	_sitzung = null
	_auto_accept_quit_vorher = get_tree().auto_accept_quit


func after_each() -> void:
	# Ein Bild, damit die Zeilen, die ein Blatt beim Neubau mit queue_free() abgibt, wirklich frei
	# sind, bevor GUT nach verwaisten Knoten sucht.
	await wait_process_frames(1)
	get_tree().auto_accept_quit = _auto_accept_quit_vorher
	_raeume_auf(WURZEL)


# --- Versionszeile (Feature 001) ------------------------------------------------------------------

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


# --- Szenenaufbau und pixelschatten (Feature 005, T028) -------------------------------------------

func test_szenenaufbau_mit_t02_und_dem_communicator() -> void:
	# Arrange
	await _zeige_titel()
	var communicator := _titel.get_node(^"Communicator") as Communicator

	# Assert (contracts/titelbildschirm.md, „Szenenaufbau“)
	assert_eq((_titel.get_node(^"Background") as TextureRect).texture.resource_path,
		"res://assets/images/title_t02.png", "Titelbild T-02.")
	assert_eq(communicator.global_position, Vector2(GEHAEUSE_LINKS, GEHAEUSE_OBEN),
		"Endlage im Titel.")
	assert_eq(communicator.get_global_rect().end, Vector2(636, 360),
		"Das Gehäuse reicht bis x 636 und y 360, unten an den Bildrand.")
	for seite: Node in [_hauptmenue(), _gradwahl(), _rueckfrage()]:
		assert_eq((seite as MainMenu).look, MainMenu.Look.LCD, "%s auf der Anzeige." % seite.name)
	assert_eq(_liste().look, SaveList.Look.LCD, "Die Liste auf der Anzeige.")
	assert_false(_titel.has_node(^"MenuHint"), "Der eigene Hinweis des Titels entfällt.")


func test_zwischen_logoblock_und_gehaeuse_bleibt_mindestens_raster_8_frei() -> void:
	# Arrange: der Titel mit dem Communicator in der Endlage.
	await _zeige_titel()

	# Act: gemessen an den echten Rechtecken, nicht an Konstanten.
	var logoblock := (_titel.get_node(^"LogoBlock") as Control).get_global_rect()
	var gehaeuse := (_communicator().get_node(^"Case") as Control).get_global_rect()

	# Assert (Style-Guide, Baustein Communicator, „Lage im Titel“, und Logo: „Rundherum bleibt
	# mindestens raster-8 frei“). Gemessen wird ab dem Kasten des Logoblocks ohne Schatten, wie der
	# Style-Guide den freien Bereich festlegt (x 14 bis 296, y 12 bis 83). Der Schatten des
	# Untertitels liegt darin: Die Schrift hat Ascent 10, ihre Grundlinie liegt also bei
	# 70 + 10 = 80, und der Text hat keine Unterlängen. Die Schrift endet bei 80, ihr Schatten
	# 2 tiefer bei 82, noch im Kasten bis 83.
	assert_eq(_communicator().position, Vector2(GEHAEUSE_LINKS, GEHAEUSE_OBEN),
		"Voraussetzung: in der Endlage.")
	assert_lt(gehaeuse.position.x, logoblock.end.x,
		"Voraussetzung: Gehäuse und Logoblock liegen übereinander, es zählt der Abstand in y.")
	assert_gte(gehaeuse.position.y - logoblock.end.y, RASTER_8,
		"Vom Logoblock (bis y %s) zum Gehäuse (ab y %s) bleiben mindestens %s frei." % [
		logoblock.end.y, gehaeuse.position.y, RASTER_8])


func test_logo_untertitel_und_versionszeile_mit_pixelschatten() -> void:
	# Arrange
	await _zeige_titel()
	var logo := _titel.get_node(^"LogoBlock/Logo") as TextureRect
	var schatten := logo.get_node(^"Shadow") as TextureRect

	# Act: das Logo und sein Schatten Pixel für Pixel.
	var bild := logo.texture.get_image()
	bild.convert(Image.FORMAT_RGBA8)
	var form := schatten.texture.get_image()
	form.convert(Image.FORMAT_RGBA8)
	var falsch := 0
	for y in bild.get_height():
		for x in bild.get_width():
			var deckend := bild.get_pixel(x, y).a > 0.0
			var pixel := form.get_pixel(x, y)
			if deckend and pixel != UiPalette.TUSCHE or not deckend and pixel.a != 0.0:
				falsch += 1

	# Assert: harter Versatz 2 nach rechts unten in tusche, hinter dem Logo, ohne Unschärfe.
	assert_eq(form.get_size(), bild.get_size(), "Der Schatten hat die Form des Logos.")
	assert_eq(falsch, 0, "Jedes deckende Pixel tusche, jedes andere ganz durchsichtig.")
	assert_eq(schatten.position, Vector2(2, 2), "2 nach rechts unten.")
	assert_eq(schatten.size, logo.size, "So groß wie das Logo, also ebenfalls ×2.")
	assert_true(schatten.show_behind_parent, "Hinter dem Logo.")
	for label: Label in [_titel.get_node(^"LogoBlock/Subtitle"), _titel.get_node(^"VersionLine")]:
		assert_eq(label.get_theme_color(&"font_shadow_color"), UiPalette.TUSCHE, label.name)
		assert_eq([label.get_theme_constant(&"shadow_offset_x"),
			label.get_theme_constant(&"shadow_offset_y")], [2, 2], "%s: 2 nach rechts unten." %
			label.name)
		assert_eq(label.get_theme_constant(&"shadow_outline_size"), 0, "%s: ohne Unschärfe." %
			label.name)


func test_versionszeile_oben_rechts_im_himmel() -> void:
	# Arrange
	await _zeige_titel()
	var zeile := _titel.get_node(^"VersionLine") as Label

	# Assert: rechtsbündig, raster-16 vom oberen und vom rechten Bildrand (Style-Guide, Baustein
	# Communicator); sie wächst nach links.
	assert_eq(zeile.get_global_rect().end.x, 640.0 - 16.0, "Rechte Kante bei x 624.")
	assert_eq(zeile.get_global_rect().position.y, 16.0, "Oberkante bei y 16.")
	assert_eq(zeile.horizontal_alignment, HORIZONTAL_ALIGNMENT_RIGHT, "Rechtsbündig.")
	assert_eq(zeile.grow_horizontal, Control.GROW_DIRECTION_BEGIN, "Sie wächst nach links.")
	assert_gt(zeile.size.x, 0.0, "Voraussetzung: Sie hat Text.")
	assert_false(zeile.get_global_rect().intersects(_communicator().get_global_rect()),
		"Sie steht über dem Gerät, nicht darauf.")


func test_im_titel_kein_look_paper() -> void:
	# Arrange: die Szene als Text, wie sie auf der Platte liegt.
	var szene := FileAccess.get_file_as_string("res://scenes/title/title_screen.tscn")

	# Assert: Endlospapier kommt im Titel nicht mehr vor (FR-011).
	assert_eq(szene.count("look = 1"), 4, "Alle vier Seiten auf der Anzeige.")
	assert_false(szene.contains("look = 0"), "Keine Seite auf Papier.")


# --- Erscheinen und Wache (Feature 005, T029) -----------------------------------------------------

func test_erscheinen_draussen_dann_herein_auch_nach_der_rueckkehr() -> void:
	# Arrange: ohne Spielstand, dann wie nach „Zum Hauptmenü“ mit einem.
	_sitzung = await _neue_sitzung()
	for durchgang in 2:
		if durchgang == 1:
			_lege_an(1, Difficulty.Level.MITTEL, 0, ANGELEGT)

		# Act: einhängen, noch ohne Bild.
		_baue_titel_ohne_warten(true)

		# Assert: draußen, das Hauptmenü noch ohne Einträge.
		assert_eq(_communicator().position.y, Communicator.HIDDEN_Y, "Erst steht er draußen.")
		assert_eq(_hauptmenue().entries.size(), 0, "Noch keine Einträge.")

		# Act: ein Bild, dann Einträge und Auswahl, dann die Fahrt.
		await wait_process_frames(1)

		# Assert
		assert_eq(_hauptmenue().entries.size(), 5, "Erst die Einträge …")
		assert_true(_communicator().is_in(), "… dann fährt er herein.")
		_assert_nur_sichtbar(_hauptmenue())
		assert_eq(_hauptmenue().selected_index(), 1 - durchgang,
			"Vorwahl wie in Feature 004: Neues Spiel, mit Spielstand Weiterspielen.")
		_fahre(1.0 / 60.0, 1.0 / 60.0)
		assert_eq(_communicator().position, Vector2(GEHAEUSE_LINKS, GEHAEUSE_OBEN),
			"In der Endlage.")
		assert_eq(_wechsel, [])


func test_esc_und_enter_vor_den_eintraegen_tun_nichts() -> void:
	# Arrange: eingehängt, die Blätter entstehen erst am Ende des Bilds.
	_sitzung = await _neue_sitzung()
	_baue_titel_ohne_warten()

	# Act
	_druecke(KEY_ESCAPE)
	_druecke(KEY_ENTER)

	# Assert: Ohne Wache hätte Esc das Hauptmenü schon jetzt gebaut (_go_back()).
	assert_eq(_hauptmenue().entries.size(), 0, "Esc hat nichts ausgelöst.")
	await wait_process_frames(2)
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 1, "Neues Spiel vorgewählt wie sonst.")
	assert_eq(_hinweis_text(), "Einen neuen Laden aufmachen. Los geht es am 01.01.1985.")
	assert_eq(_wechsel, [])
	assert_false(_sitzung.is_running())


func test_seitenwechsel_bewegt_den_communicator_nicht() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	var lage := _communicator().position
	var lagen := []

	# Act: Gradwahl, zurück, Liste, Löschmodus, Rückfrage, Abbrechen, zurück.
	_hauptmenue().select(1)
	await _taste(KEY_ENTER)
	lagen.append(_communicator().position)
	await _taste(KEY_ESCAPE)
	lagen.append(_communicator().position)
	await _oeffne_liste()
	lagen.append(_communicator().position)
	await _frage_nach(0)
	lagen.append(_communicator().position)
	await _taste(KEY_ESCAPE)
	await _taste(KEY_ESCAPE)
	lagen.append(_communicator().position)

	# Assert
	assert_eq(lage, Vector2(GEHAEUSE_LINKS, GEHAEUSE_OBEN))
	assert_eq(lagen, [lage, lage, lage, lage, lage], "Keine Seite bewegt den Communicator.")


# --- Platz auf der Anzeige und um das Gerät (SC-004, SC-006) --------------------------------------

func test_jede_seite_passt_auf_die_anzeige() -> void:
	# Arrange: sieben Spielstände, darunter Spiel 9999; fünf sind in der Liste zu sehen.
	_sechs_und_spiel_9999()
	await _zeige_titel()

	# Act und Assert: Hauptmenü, Gradwahl, Liste, Löschmodus, Rückfrage zu Spiel 9999.
	_assert_passt(_hauptmenue())
	_hauptmenue().select(1)
	await _taste(KEY_ENTER)
	_assert_passt(_gradwahl())
	await _taste(KEY_ESCAPE)
	await _oeffne_liste()
	assert_eq(_namen()[0], "Spiel 9999", "Voraussetzung: Spiel 9999 steht oben.")
	_assert_passt(_liste())
	await _frage_nach(0)
	assert_eq(_texte(_rueckfrage())[1], "Spiel 9999 löschen")
	_assert_passt(_rueckfrage())
	await _taste(KEY_ESCAPE)
	_liste().set_delete_mode(true)
	assert_eq(_kopfzeile_der_liste(), "WELCHES LÖSCHEN?")
	_assert_passt(_liste())


func test_logo_untertitel_und_versionszeile_bleiben_frei() -> void:
	# Arrange
	_sechs_und_spiel_9999()
	await _zeige_titel()
	var frei := _freie_flaechen()

	# Act und Assert: das Gerät selbst.
	_assert_frei(_communicator().get_global_rect(), frei, "Gehäuse und Anzeige")

	# Act und Assert: Hinweis und Meldung zu jeder Zeile jeder Seite.
	await _pruefe_jede_zeile(_hauptmenue(), frei)
	_hauptmenue().select(1)
	await _taste(KEY_ENTER)
	await _pruefe_jede_zeile(_gradwahl(), frei)
	await _taste(KEY_ESCAPE)
	await _oeffne_liste()
	await _pruefe_jede_zeile(_liste(), frei)
	_liste().set_delete_mode(true)
	await _pruefe_jede_zeile(_liste(), frei)
	_liste().set_delete_mode(false)
	await _frage_nach(0)
	await _pruefe_jede_zeile(_rueckfrage(), frei)


func test_logo_untertitel_und_versionszeile_bleiben_frei_in_jeder_lage_der_fahrt() -> void:
	# Arrange: ein Spielstand, damit „Weiterspielen“ die oberste Zeile ist; ihr Hinweis kommt dem
	# Logo am nächsten. Der Communicator fährt im Takt des Tests.
	_lege_an(1, Difficulty.Level.MITTEL, 0, ANGELEGT)
	await _zeige_titel(ORDNER, true)
	var frei := _freie_flaechen()
	var pruefe := func(was: String) -> void:
		_assert_frei(_communicator().get_global_rect(), frei, "%s, Gehäuse" % was)
		_assert_frei(_hinweis_flaeche(), frei, "%s, %s" % [was, _hinweis().theme_type_variation])

	for meldung: bool in [false, true]:
		# Arrange: draußen, die oberste Zeile gewählt, ihr Hinweis oder eine Meldung daneben.
		_communicator().place_hidden()
		_hauptmenue().select(0)
		if meldung:
			_communicator().show_warning(NICHT_ANGELEGT, _titel._current_row())
		var was := "Meldung" if meldung else "Hinweis"

		# Act und Assert: herein und hinaus, nach jedem Bild (SC-006, „in keiner Lage“).
		pruefe.call("%s draußen" % was)
		_communicator().slide_in()
		_fahre(1.0 / 60.0, 1.0 / 60.0, pruefe.bind("%s herein" % was))
		_communicator().slide_out()
		_fahre(1.0 / 60.0, 1.0 / 60.0, pruefe.bind("%s hinaus" % was))
		assert_true(_hinweis().visible, "Voraussetzung: %s war die ganze Fahrt zu sehen." % was)


# --- Hinausfahren (Feature 005, T029; R8) ---------------------------------------------------------

func test_weiterspielen_waehrend_der_fahrt_herein_dann_hinaus_dann_spielbildschirm() -> void:
	# Arrange: ein Spielstand; der Communicator fährt gerade herein.
	_lege_an(1, Difficulty.Level.MITTEL, 0, ANGELEGT)
	await _zeige_titel(ORDNER, true)
	for _bild in 3:
		_communicator()._process(1.0 / 60.0)
	assert_gt(_communicator().position.y, GEHAEUSE_OBEN, "Voraussetzung: noch unterwegs.")

	# Act: eine Eingabe (SC-001).
	await _taste(KEY_ENTER)

	# Assert: Das Spiel läuft, aber der Spielbildschirm kommt erst nach der Fahrt hinaus.
	assert_true(_sitzung.is_running(), "Weiterspielen hat fortgesetzt.")
	assert_false(_communicator().is_in(), "Er fährt hinaus.")
	assert_eq(_wechsel, [], "Noch kein Szenenwechsel.")
	assert_true(_hinweis().visible, "Der Hinweis fährt mit hinaus.")
	_fahre(1.0 / 60.0, 1.0 / 60.0)
	assert_eq(_communicator().position.y, Communicator.HIDDEN_Y)
	assert_eq(_wechsel, [SPIELBILDSCHIRM], "Erst jetzt der Spielbildschirm, genau einmal.")


func test_waehrend_der_fahrt_hinaus_kein_zweites_spiel() -> void:
	# Arrange: ohne Spielstand, in der Endlage; Neues Spiel, Mittel bestätigt.
	await _zeige_titel(ORDNER, true)
	_fahre(1.0 / 60.0, 1.0 / 60.0)
	await _taste(KEY_ENTER)
	await _taste(KEY_ENTER)
	_communicator()._process(1.0 / 60.0)
	assert_true(_sitzung.is_running(), "Voraussetzung: Spiel 1 ist angelegt.")

	# Act: während der Fahrt hinaus Enter, Esc, Maus über eine Zeile bewegen und Enter (B2).
	await _taste(KEY_ENTER)
	await _taste(KEY_ESCAPE)
	var leicht := _mitte(_gradwahl(), 0)
	await _maus_nach(leicht + Vector2(0, 2))
	await _maus_nach(leicht)
	await _taste(KEY_ENTER)
	_fahre(1.0 / 60.0, 1.0 / 60.0)

	# Assert
	assert_eq(_wechsel, [SPIELBILDSCHIRM], "scene_callback genau einmal.")
	assert_eq(_dateien(), ["spiel_1.json"], "Kein zweites Spiel.")
	assert_eq(_sitzung.current.difficulty, Difficulty.Level.MITTEL, "Es bleibt Mittel.")
	assert_eq(_gradwahl().selected_index(), 1, "Die Maus hat nichts gewählt.")


func test_hinaus_spaetestens_250_ms_nach_beginn_der_fahrt() -> void:
	# Arrange: ein Spielstand zum Weiterspielen.
	_lege_an(1, Difficulty.Level.MITTEL, 0, ANGELEGT)
	for schritt: float in [1.0 / 60.0, 1.0 / 30.0]:
		_wechsel.clear()
		_sitzung = await _neue_sitzung()
		await _baue_titel(true)
		_fahre(schritt, schritt)

		# Act
		await _taste(KEY_ENTER)
		var bilder := _fahre(schritt, schritt)

		# Assert: gezählt über die Zeitschritte der Bilder wie in test_communicator.gd (SC-002).
		var dauer := minf(schritt, Communicator.MAX_STEP) + (bilder - 1) * schritt
		assert_lte(dauer, 0.25, "Bilder zu %.3f s: %d Bilder, %.3f s." % [schritt, bilder, dauer])
		assert_eq(_wechsel, [SPIELBILDSCHIRM], "Danach ohne weitere Wartezeit der Spielbildschirm.")


func test_meldung_neben_der_zeile_in_ihrer_jetzigen_lage() -> void:
	# Arrange: Anlegen scheitert, denn der Ordner liegt unter einer Datei. Der Communicator fährt
	# herein, und während der Fahrt wird Mittel gewählt (Analyse, C3).
	_schreibe(WURZEL.path_join("datei"), "keine Ordner hier")
	await _zeige_titel(WURZEL.path_join("datei/spielstaende/"), true)
	_communicator()._process(1.0 / 60.0)
	await _taste(KEY_ENTER)
	var beim_waehlen := _communicator().position.y
	for _bild in 4:
		_communicator()._process(1.0 / 60.0)

	# Act: Mittel bestätigen; das Anlegen scheitert.
	await _taste(KEY_ENTER)

	# Assert: Die Meldung steht neben der Zeile, wo sie jetzt ist, und nichts fährt hinaus.
	assert_lt(_communicator().position.y, beim_waehlen, "Voraussetzung: Er ist weitergefahren.")
	assert_eq(_hinweis_text(), NICHT_ANGELEGT)
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel")
	_assert_neben_zeile(_gradwahl(), 1)
	assert_true(_communicator().is_in(), "Er fährt weiter herein, nicht hinaus.")
	assert_true(_communicator().accepts_input())
	assert_eq(_wechsel, [])
	assert_push_warning("Es ist kein Spiel angelegt.")
	assert_engine_error("Method/function failed")


func test_fortsetzen_scheitert_ohne_fahrt() -> void:
	# Arrange: die Liste ist offen; gemeldet wird ein Spielstand, der sich nicht fortsetzen lässt.
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	var kaputt := SaveSlot.new()
	kaputt.number = 7
	kaputt.state = SaveSlot.State.DAMAGED

	# Act
	_titel._on_save_list_resume_requested(kaputt)

	# Assert: wie in Feature 004 neu gelesen, ohne Meldung und ohne Fahrt (CHK016).
	assert_eq(_communicator().position, Vector2(GEHAEUSE_LINKS, GEHAEUSE_OBEN), "Er bleibt stehen.")
	assert_true(_communicator().is_in())
	assert_true(_communicator().accepts_input(), "Nichts ist gesperrt.")
	_assert_nur_sichtbar(_liste())
	assert_eq(_wechsel, [])
	assert_false(_sitzung.is_running())
	assert_push_warning("ließ sich nicht fortsetzen")


# --- Beenden: sofort, ohne Fahrt (Feature 005, T041; FR-013a) -------------------------------------

func test_beenden_schliesst_sofort_ohne_fahrt() -> void:
	# Arrange: in der Endlage, „Beenden“ gewählt. Der Communicator fährt im Takt des Tests; eine
	# Fahrt hinaus wäre also zu sehen und käme nicht sofort zu Ende wie mit animate = false.
	await _zeige_titel(ORDNER, true)
	_fahre(1.0 / 60.0, 1.0 / 60.0)
	_hauptmenue().select(4)
	assert_eq(_hauptmenue().entries[4].id, &"quit", "Voraussetzung: Zeile 4 ist „Beenden“.")
	var fahrten := []
	_communicator().slide_finished.connect(func(drin: bool) -> void: fahrten.append(drin))

	# Act: mit der Tastatur auslösen, dann laufen noch Bilder der Fahrt, falls eine begonnen hätte.
	await _taste(KEY_ENTER)
	for _bild in 20:
		_communicator()._process(1.0 / 60.0)

	# Assert
	assert_eq(_beendet, 1, "quit_callback genau einmal, sofort.")
	assert_true(_communicator().is_in(), "Er fährt nicht hinaus.")
	assert_true(_communicator().accepts_input(), "Nichts ist gesperrt wie beim Hinausfahren.")
	assert_eq(_communicator().position, Vector2(GEHAEUSE_LINKS, GEHAEUSE_OBEN), "Er bleibt stehen.")
	assert_eq(fahrten, [], "Keine Fahrt, also kein slide_finished.")
	assert_eq(_wechsel, [], "Kein Szenenwechsel.")
	assert_false(_sitzung.is_running(), "Es beginnt kein Spiel.")
	assert_eq(_dateien(), [], "Es entsteht keine Datei.")


func test_beenden_waehrend_der_fahrt_herein_wirkt_ebenso_sofort() -> void:
	# Arrange: Der Communicator fährt gerade herein (FR-003: herein ist alles bedienbar).
	await _zeige_titel(ORDNER, true)
	for _bild in 3:
		_communicator()._process(1.0 / 60.0)
	assert_gt(_communicator().position.y, GEHAEUSE_OBEN, "Voraussetzung: noch unterwegs.")
	_hauptmenue().select(4)
	var fahrten := []
	_communicator().slide_finished.connect(func(drin: bool) -> void: fahrten.append(drin))

	# Act
	await _taste(KEY_ENTER)

	# Assert: sofort beendet, und die Fahrt herein dreht nicht um.
	assert_eq(_beendet, 1, "quit_callback genau einmal, ohne das Ende der Fahrt abzuwarten.")
	assert_true(_communicator().is_in(), "Er fährt weiter herein, nicht hinaus.")
	assert_true(_communicator().accepts_input())
	assert_eq(fahrten, [], "Bis hierher keine Fahrt zu Ende.")
	_fahre(1.0 / 60.0, 1.0 / 60.0)
	assert_eq(fahrten, [true], "Die Fahrt herein endet in der Endlage, keine Fahrt hinaus.")
	assert_eq(_communicator().position, Vector2(GEHAEUSE_LINKS, GEHAEUSE_OBEN))
	assert_eq(_beendet, 1, "Nicht noch einmal.")
	assert_eq(_wechsel, [], "Kein Szenenwechsel.")


# --- Ohne Spiel läuft nichts (FR-003) -------------------------------------------------------------

func test_hauptszene_laeuft_und_es_beginnt_kein_spiel_und_entsteht_keine_datei() -> void:
	# Arrange (FR-003; US1, Szenario 5): die Hauptszene aus project.godot mit eigener Session und das
	# echte Autoload Timeline. Es kommt über seinen Pfad; seinen Namen kennt GDScript in einem
	# Skript, das mit -s startet, nicht. Der Test beginnt kein Spiel und schreibt nichts.
	var pfad: String = ProjectSettings.get_setting("application/run/main_scene")
	var zeitleiste_autoload := get_node(^"/root/Timeline")
	var szene: PackedScene = load(pfad)
	_sitzung = await _neue_sitzung()
	var titel := szene.instantiate() as TitleScreen
	titel.session = _sitzung
	titel.scene_callback = _merke_wechsel

	# Act: mehrere Bilder, länger als bis zum früheren Selbststart am Ende des ersten
	add_child_autofree(titel)
	await wait_process_frames(5)

	# Assert
	assert_eq(pfad, "res://scenes/title/title_screen.tscn", "Die Hauptszene ist der Titel.")
	assert_true(titel.is_inside_tree(), "Die Szene läuft.")
	assert_null(zeitleiste_autoload.run, "Ohne Beginn läuft kein Spiel.")
	assert_false(_sitzung.is_running(), "Auch die Session hat kein Spiel.")
	assert_null(_zeitleiste().run)
	assert_eq(_dateien(), [], "Im Ordner der Session entsteht keine Datei (FR-003).")
	assert_eq(_wechsel, [], "Kein Szenenwechsel.")


# --- Hauptmenü: Einträge, Verfügbarkeit, Hinweise, Vorwahl (FR-001, FR-001a, FR-002) -------------

func test_fuenf_eintraege_in_der_reihenfolge_von_fr_001() -> void:
	# Arrange
	await _zeige_titel()

	# Act
	var eintraege := _hauptmenue().entries

	# Assert
	assert_eq(eintraege.map(func(eintrag: MenuEntry) -> StringName: return eintrag.id),
		[&"continue", &"new_game", &"load_game", &"settings", &"quit"])
	assert_eq(_texte(_hauptmenue()),
		["Weiterspielen", "Neues Spiel", "Spiel laden", "Einstellungen", "Beenden"])
	assert_eq(_hauptmenue().header_text, "HAUPTMENÜ")
	assert_eq(_hauptmenue().get_global_rect(), ANZEIGE, "Auf der Anzeige des Communicators.")


func test_ohne_spielstaende_ist_neues_spiel_gewaehlt_und_weiterspielen_und_laden_gesperrt() -> void:
	# Arrange
	await _zeige_titel()

	# Assert
	assert_eq(_verfuegbar(_hauptmenue()), [false, true, false, false, true])
	assert_eq(_hinweise(_hauptmenue()), [
		"Noch kein Spiel angefangen.",
		"Einen neuen Laden aufmachen. Los geht es am 01.01.1985.",
		"Noch keine Spielstände.",
		"Noch nichts einzustellen. Kommt später.",
		"Laden abschließen und zurück zum Desktop.",
	])
	assert_eq(_hauptmenue().selected_index(), 1, "„Neues Spiel“ ist vorgewählt (FR-001a).")
	assert_true(_hat_fokus(_hauptmenue()), "Die Auswahl ist der Fokus.")
	assert_eq(_hinweis_text(), "Einen neuen Laden aufmachen. Los geht es am 01.01.1985.")
	_assert_neben_zeile(_hauptmenue(), 1)
	_assert_nur_sichtbar(_hauptmenue())


func test_mit_spielstaenden_ist_weiterspielen_gewaehlt_und_nennt_den_zuletzt_gespielten() -> void:
	# Arrange: Spiel 2 ist zuletzt gespielt, obwohl Spiel 1 die kleinere Nummer hat.
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT + 60)
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 120)
	await _zeige_titel()

	# Assert
	assert_eq(_verfuegbar(_hauptmenue()), [true, true, true, false, true])
	assert_eq(_hauptmenue().entries[0].hint, "Weiter mit Spiel 2, Schwer, am 14.03.1986.")
	assert_eq(_hauptmenue().entries[2].hint, "Zurück in einen deiner Läden.")
	assert_eq(_hauptmenue().selected_index(), 0, "„Weiterspielen“ ist vorgewählt (FR-001a).")
	assert_eq(_hinweis_text(), "Weiter mit Spiel 2, Schwer, am 14.03.1986.")
	_assert_neben_zeile(_hauptmenue(), 0)


func test_nur_beschaedigte_spielstaende_machen_nur_spiel_laden_verfuegbar() -> void:
	# Arrange (FR-002): Auch ein beschädigter Spielstand lässt sich später löschen.
	_kopiere("spiel_kein_json.json", 1)
	await _zeige_titel()

	# Assert
	assert_eq(_verfuegbar(_hauptmenue()), [false, true, true, false, true])
	assert_eq(_hauptmenue().entries[0].hint, "Kein Spielstand lässt sich fortsetzen.")
	assert_eq(_hauptmenue().entries[2].hint, HINWEIS_LADEN,
		"Derselbe Satz, auch wenn sich keiner fortsetzen lässt (T038).")
	assert_eq(_hauptmenue().selected_index(), 1, "Ohne fortsetzbaren: „Neues Spiel“.")
	assert_push_warning("spiel_1.json", "Das Protokoll nennt die beschädigte Datei.")


func test_nur_zu_neue_und_beschaedigte_spielstaende_bei_spiel_laden_derselbe_satz() -> void:
	# Arrange (T038): ein zu neuer und ein beschädigter, keiner fortsetzbar
	_kopiere("spiel_format_2.json", 1)
	_kopiere("spiel_kein_json.json", 2)
	await _zeige_titel()

	# Assert
	assert_eq(_verfuegbar(_hauptmenue()), [false, true, true, false, true])
	assert_eq(_hauptmenue().entries[2].hint, HINWEIS_LADEN)


func test_nur_ein_zu_neuer_spielstand_bei_spiel_laden_derselbe_satz() -> void:
	# Arrange (T038)
	_kopiere("spiel_format_2.json", 1)
	await _zeige_titel()

	# Assert
	assert_eq(_hauptmenue().entries[2].hint, HINWEIS_LADEN)


func test_ein_fortsetzbarer_neben_beschaedigten_bei_spiel_laden_derselbe_satz() -> void:
	# Arrange (T038)
	_kopiere("spiel_kein_json.json", 2)
	_kopiere("spiel_format_2.json", 3)
	_lege_an(1, Difficulty.Level.MITTEL, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()

	# Assert
	assert_eq(_hauptmenue().entries[2].hint, HINWEIS_LADEN)


func test_esc_im_hauptmenue_tut_nichts() -> void:
	# Arrange
	_lege_an(1, Difficulty.Level.MITTEL, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()

	# Act
	await _taste(KEY_ESCAPE)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 0, "Die Auswahl bleibt.")
	assert_eq(_wechsel, [])
	assert_false(_sitzung.is_running())


# --- Gradwahl (FR-004, FR-005, FR-023) ------------------------------------------------------------

func test_neues_spiel_zeigt_die_gradwahl_mit_mittel_und_seinem_satz() -> void:
	# Arrange
	await _zeige_titel()

	# Act: „Neues Spiel“ ist gewählt.
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_gradwahl())
	assert_eq(_gradwahl().header_text, "SCHWIERIGKEIT")
	assert_eq(_texte(_gradwahl()), ["Leicht", "Mittel", "Schwer", "Zurück"])
	assert_eq(_verfuegbar(_gradwahl()), [true, true, true, true])
	assert_eq(_gradwahl().selected_index(), 1, "Mittel ist vorgewählt.")
	assert_true(_hat_fokus(_gradwahl()), "Die Gradwahl hat den Fokus.")
	assert_false(_hat_fokus(_hauptmenue()), "Das unsichtbare Hauptmenü hat keinen.")
	assert_eq(_hinweis_text(), "Das Glück hält sich raus.", "Sein Satz steht sofort da (R13).")
	assert_eq(_gradwahl().get_global_rect(), ANZEIGE, "Auf der Anzeige, wie das Hauptmenü.")
	_assert_neben_zeile(_gradwahl(), 1)


func test_der_satz_wechselt_mit_dem_grad() -> void:
	# Arrange
	await _zeige_titel()
	await _taste(KEY_ENTER)
	var saetze := []

	# Act: hoch auf Leicht, dann zweimal runter auf Schwer, dann auf Zurück.
	for taste: Key in [KEY_UP, KEY_DOWN, KEY_DOWN, KEY_DOWN]:
		await _taste(taste)
		saetze.append(_hinweis_text())

	# Assert
	assert_eq(saetze, [
		"Das Glück ist eher auf deiner Seite.",
		"Das Glück hält sich raus.",
		"Das Glück ist eher auf der Seite der anderen.",
		"Zurück zum Hauptmenü. Esc geht auch.",
	])


func test_esc_in_der_gradwahl_fuehrt_ohne_spielstand_zurueck() -> void:
	# Arrange (US1, Szenario 3)
	await _zeige_titel()
	await _taste(KEY_ENTER)

	# Act
	await _taste(KEY_ESCAPE)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 1, "Zurück auf „Neues Spiel“, das die Wahl öffnete.")
	assert_true(_hat_fokus(_hauptmenue()))
	assert_eq(_hinweis_text(), "Einen neuen Laden aufmachen. Los geht es am 01.01.1985.")
	assert_eq(_dateien(), [], "Abbrechen legt keinen Spielstand an.")
	assert_false(_sitzung.is_running())
	assert_eq(_wechsel, [])


func test_zurueck_in_der_gradwahl_wirkt_wie_esc() -> void:
	# Arrange: „Zurück“ ist die letzte Zeile, von Mittel zweimal runter.
	await _zeige_titel()
	await _taste(KEY_ENTER)
	await _taste(KEY_DOWN)
	await _taste(KEY_DOWN)

	# Act
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 1)
	assert_eq(_dateien(), [])
	assert_eq(_wechsel, [])


func test_beim_wiederoeffnen_ist_wieder_mittel_gewaehlt() -> void:
	# Arrange: Schwer wählen, dann zurück.
	await _zeige_titel()
	await _taste(KEY_ENTER)
	await _taste(KEY_DOWN)
	await _taste(KEY_ESCAPE)

	# Act
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_gradwahl().selected_index(), 1)
	assert_eq(_hinweis_text(), "Das Glück hält sich raus.")


func test_rueckkehr_ins_hauptmenue_liest_den_ordner_neu() -> void:
	# Arrange (Analyse, F2): Während die Gradwahl offen ist, kommt ein Spielstand in den Ordner.
	await _zeige_titel()
	await _taste(KEY_ENTER)
	_lege_an(4, Difficulty.Level.LEICHT, _tag(1985, 2, 15), ANGELEGT)

	# Act
	await _taste(KEY_ESCAPE)

	# Assert
	assert_eq(_verfuegbar(_hauptmenue()), [true, true, true, false, true])
	assert_eq(_hauptmenue().entries[0].hint, "Weiter mit Spiel 4, Leicht, am 15.02.1985.")
	assert_eq(_hauptmenue().selected_index(), 1, "Die Auswahl bleibt beim Eintrag, der öffnete.")


# --- Spiel beginnen (FR-006, SC-001) --------------------------------------------------------------

func test_leicht_bestaetigen_legt_spiel_1_an_und_zeigt_den_spielbildschirm() -> void:
	# Arrange (US1, Szenario 2)
	await _zeige_titel()
	var szene_vorher := get_tree().current_scene

	# Act: Enter, hoch auf Leicht, Enter
	await _taste(KEY_ENTER)
	await _taste(KEY_UP)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_wechsel, [SPIELBILDSCHIRM], "Einmal zum Spielbildschirm.")
	assert_eq(get_tree().current_scene, szene_vorher, "Gewechselt wird nur über scene_callback.")
	assert_true(_sitzung.is_running())
	assert_eq(_dateien(), ["spiel_1.json"])
	var slot := SaveSlot.read(ORDNER.path_join("spiel_1.json"), 1)
	assert_eq(slot.state, SaveSlot.State.OK, slot.reason)
	assert_eq(slot.game.difficulty, Difficulty.Level.LEICHT)
	assert_eq(slot.game.day_text(), "01.01.1985")


func test_sc_001_mit_drei_tasten_zum_spielbildschirm_mit_mittel() -> void:
	# Arrange: Mit einem Spielstand ist „Weiterspielen“ vorgewählt, der längste Weg.
	_lege_an(1, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT)
	await _zeige_titel()
	var eingaben := 0

	# Act: runter auf „Neues Spiel“, Enter, Enter für Mittel
	for taste: Key in [KEY_DOWN, KEY_ENTER, KEY_ENTER]:
		await _taste(taste)
		eingaben += 1

	# Assert
	assert_eq(eingaben, 3, "SC-001: höchstens 3 Eingaben.")
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.number, 2, "Ein neues Spiel überschreibt keinen Spielstand.")
	assert_eq(_sitzung.current.difficulty, Difficulty.Level.MITTEL)
	assert_eq(_dateien(), ["spiel_1.json", "spiel_2.json"])


func test_ohne_spielstaende_reichen_zwei_tasten() -> void:
	# Arrange
	await _zeige_titel()

	# Act
	await _taste(KEY_ENTER)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.difficulty, Difficulty.Level.MITTEL)


func test_gradwahl_mit_der_maus() -> void:
	# Arrange
	await _zeige_titel()

	# Act: auf „Neues Spiel“ klicken, über „Schwer“ fahren, klicken
	var neues_spiel := _mitte(_hauptmenue(), 1)
	await _maus_nach(neues_spiel)
	await _klick(neues_spiel)
	var gradwahl_offen := _gradwahl().visible
	var schwer := _mitte(_gradwahl(), 2)
	await _maus_nach(schwer)
	var satz := _hinweis_text()
	await _klick(schwer)

	# Assert
	assert_true(gradwahl_offen, "Ein Klick auf „Neues Spiel“ öffnet die Gradwahl.")
	assert_eq(satz, "Das Glück ist eher auf der Seite der anderen.", "Überfahren zeigt den Satz.")
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.difficulty, Difficulty.Level.SCHWER)


func test_zurueck_mit_der_maus() -> void:
	# Arrange
	await _zeige_titel()
	await _taste(KEY_ENTER)

	# Act
	var zurueck := _mitte(_gradwahl(), 3)
	await _maus_nach(zurueck)
	await _klick(zurueck)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_dateien(), [])


func test_meldung_wenn_das_anlegen_scheitert() -> void:
	# Arrange (FR-011): Der Ordner liegt unter einer Datei und lässt sich nicht anlegen.
	_schreibe(WURZEL.path_join("datei"), "keine Ordner hier")
	await _zeige_titel(WURZEL.path_join("datei/spielstaende/"))
	await _taste(KEY_ENTER)

	# Act: Mittel bestätigen
	await _taste(KEY_ENTER)

	# Assert: Die Meldung steht an der Stelle des Hinweises, die Gradwahl bleibt.
	assert_eq(_hinweis_text(), NICHT_ANGELEGT)
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel", "Kontur kassenrot.")
	_assert_neben_zeile(_gradwahl(), 1)
	_assert_nur_sichtbar(_gradwahl())
	assert_eq(_wechsel, [])
	assert_false(_sitzung.is_running())
	assert_push_warning("Es ist kein Spiel angelegt.")
	assert_engine_error("Method/function failed")


func test_die_meldung_geht_mit_einer_anderen_zeile() -> void:
	# Arrange
	_schreibe(WURZEL.path_join("datei"), "keine Ordner hier")
	await _zeige_titel(WURZEL.path_join("datei/spielstaende/"))
	await _taste(KEY_ENTER)
	await _taste(KEY_ENTER)

	# Act
	await _taste(KEY_DOWN)

	# Assert
	assert_eq(_hinweis_text(), "Das Glück ist eher auf der Seite der anderen.")
	assert_eq(_hinweis().theme_type_variation, &"HintPanel")
	assert_engine_error("Method/function failed")


func test_die_meldung_geht_mit_esc_auch_wenn_die_zeile_an_derselben_stelle_steht() -> void:
	# Arrange: Mittel und „Neues Spiel“ stehen beide in der zweiten Zeile, also an derselben Stelle.
	_schreibe(WURZEL.path_join("datei"), "keine Ordner hier")
	await _zeige_titel(WURZEL.path_join("datei/spielstaende/"))
	await _taste(KEY_ENTER)
	await _taste(KEY_ENTER)

	# Act
	await _taste(KEY_ESCAPE)

	# Assert: Esc löst etwas aus, die Meldung geht (Style-Guide, Baustein Meldung).
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hinweis_text(), "Einen neuen Laden aufmachen. Los geht es am 01.01.1985.")
	assert_eq(_hinweis().theme_type_variation, &"HintPanel")
	assert_engine_error("Method/function failed")


# --- Weiterspielen (FR-016, SC-002) ---------------------------------------------------------------

func test_weiterspielen_mit_einer_eingabe_setzt_den_zuletzt_gespielten_fort() -> void:
	# Arrange
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT + 120)
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 60)

	await _zeige_titel()

	# Act: „Weiterspielen“ ist vorgewählt.
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_wechsel, [SPIELBILDSCHIRM], "SC-002: 1 Eingabe.")
	assert_true(_sitzung.is_running())
	assert_eq(_sitzung.current.number, 1, "Spiel 1 ist zuletzt gespielt.")
	assert_eq(_uhr().date.to_iso(), "1985-01-01")
	assert_eq(_sitzung.last_error, "", "Gespeichert beim Fortsetzen.")


func test_weiterspielen_mit_der_maus() -> void:
	# Arrange
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT)
	await _zeige_titel()

	# Act
	var weiterspielen := _mitte(_hauptmenue(), 0)
	await _maus_nach(weiterspielen)
	await _klick(weiterspielen)

	# Assert
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_uhr().date.to_iso(), "1986-03-14")
	assert_eq(_sitzung.current.difficulty, Difficulty.Level.SCHWER)


# --- Liste der Spielstände (T026; FR-015, FR-016, SC-002) -----------------------------------------

func test_spiel_laden_oeffnet_die_liste_mit_der_obersten_zeile() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()

	# Act: „Weiterspielen“ ist gewählt; zweimal runter auf „Spiel laden“, Enter
	await _taste(KEY_DOWN)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_liste())
	assert_eq(_namen(), ["Spiel 2", "Spiel 3", "Spiel 1"],
		"Das zuletzt gespielte oben (US3, Szenario 5).")
	assert_eq(_zellen(0), ["Spiel 2", "Schwer", "14.03.1986", SaveGame.time_text(ANGELEGT + 180)],
		"Name, Grad, Spieldatum, zuletzt gespielt (FR-015).")
	assert_eq(_kopfzeile_der_liste(), "SPIELSTÄNDE")
	assert_false(_liste().is_delete_mode())
	assert_eq(_liste().selected_index(), 0, "Die oberste Zeile ist vorgewählt.")
	assert_true(_hat_fokus(_liste()), "Die Liste hat den Fokus.")
	assert_false(_hat_fokus(_hauptmenue()), "Das unsichtbare Hauptmenü hat keinen.")
	assert_eq(_hinweis_text(), _zeilenhinweis("14.03.1986", ANGELEGT + 180))
	assert_eq(_liste().get_global_rect(), ANZEIGE, "Auf der Anzeige, wie das Hauptmenü.")
	_assert_neben_zeile(_liste(), 0)
	assert_eq(_wechsel, [])


func test_die_liste_ist_bei_jedem_oeffnen_neu_gelesen() -> void:
	# Arrange (CHK001; Analyse, E3): Nach dem Erscheinen des Titels kommt ein Spielstand dazu.
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()
	_lege_an(5, Difficulty.Level.SCHWER, _tag(1990, 5, 5), ANGELEGT + 60)

	# Act: öffnen, zurück, Spiel 5 verschwindet von außen, wieder öffnen
	await _oeffne_liste()
	var beim_ersten_mal := _namen()
	await _taste(KEY_ESCAPE)
	assert_eq(DirAccess.remove_absolute(ORDNER.path_join("spiel_5.json")), OK)
	await _oeffne_liste()

	# Assert
	assert_eq(beim_ersten_mal, ["Spiel 5", "Spiel 1"], "Die neue Datei steht in der Liste.")
	assert_eq(_namen(), ["Spiel 1"], "Die verschwundene fehlt beim nächsten Öffnen.")


func test_eine_fortsetzbare_zeile_setzt_fort() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()

	# Act: runter auf Spiel 3, Enter
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert (FR-016)
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_true(_sitzung.is_running())
	assert_eq(_sitzung.current.number, 3)
	assert_eq(_sitzung.current.difficulty, Difficulty.Level.MITTEL)
	assert_eq(_uhr().date.to_iso(), "1991-07-02")


func test_nicht_fortsetzbare_zeilen_loesen_ausserhalb_des_loeschmodus_nichts_aus() -> void:
	# Arrange: Spiel 4 beschädigt, Spiel 3 zu neu; sie stehen unten, nach Nummer absteigend (R12).
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	_kopiere("spiel_kein_json.json", 4)
	_kopiere("spiel_format_2.json", 3)
	await _zeige_titel()
	await _oeffne_liste()
	var hinweise := []

	# Act
	for zeile in [1, 2]:
		_liste().select(zeile)
		hinweise.append(_hinweis_text())
		await _taste(KEY_ENTER)

	# Assert
	assert_eq(_namen(), ["Spiel 1", "Spiel 4", "Spiel 3"])
	assert_eq(hinweise, ["Lässt sich nicht lesen: Die Datei ist beschädigt.",
		"Mit einer neueren Version gespeichert."], "Der Hinweis nennt den Grund.")
	_assert_nur_sichtbar(_liste())
	assert_eq(_wechsel, [])
	assert_false(_sitzung.is_running())


func test_zurueck_fuehrt_ins_hauptmenue_auf_spiel_laden_und_liest_neu() -> void:
	# Arrange: Während die Liste offen ist, kommt ein Spielstand dazu (Analyse, F2).
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()
	await _oeffne_liste()
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 60)

	# Act: Pfeil hoch läuft von der obersten Zeile um auf „Zurück“.
	await _taste(KEY_UP)
	var hinweis := _hinweis_text()
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(hinweis, "Zurück zum Hauptmenü. Esc geht auch.")
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 2, "Auf „Spiel laden“, das die Liste öffnete.")
	assert_true(_hat_fokus(_hauptmenue()))
	assert_eq(_hinweis_text(), HINWEIS_LADEN)
	assert_eq(_hauptmenue().entries[0].hint, "Weiter mit Spiel 2, Schwer, am 14.03.1986.",
		"Das Hauptmenü ist neu gelesen.")
	assert_eq(_wechsel, [])


func test_esc_in_der_liste_fuehrt_ins_hauptmenue_auf_spiel_laden() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	await _taste(KEY_DOWN)

	# Act
	await _taste(KEY_ESCAPE)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 2)
	assert_eq(_hinweis_text(), HINWEIS_LADEN)
	assert_eq(_wechsel, [])
	assert_false(_sitzung.is_running())


func test_ein_aelterer_spielstand_rueckt_nach_dem_fortsetzen_nach_oben() -> void:
	# Arrange (US3, Szenario 3)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()

	# Act: das älteste, Spiel 1, fortsetzen und verlassen; danach erscheint der Titel neu.
	_liste().select(2)
	await _taste(KEY_ENTER)
	var fortgesetzt := _sitzung.current.number
	assert_eq(_sitzung.leave(), OK)
	await _baue_titel()
	var weiterspielen := _hauptmenue().entries[0].hint
	await _oeffne_liste()

	# Assert
	assert_eq(fortgesetzt, 1)
	assert_eq(weiterspielen, "Weiter mit Spiel 1, Leicht, am 01.01.1985.",
		"„Weiterspielen“ setzt es fort.")
	assert_eq(_namen(), ["Spiel 1", "Spiel 2", "Spiel 3"], "In der Liste steht es oben.")


func test_sc_002_ueber_die_liste_mit_vier_tasten() -> void:
	# Arrange: „Weiterspielen“ ist vorgewählt.
	_drei_spiele()
	await _zeige_titel()
	var eingaben := 0

	# Act: zweimal runter auf „Spiel laden“, Enter, Enter auf der obersten Zeile
	for taste: Key in [KEY_DOWN, KEY_DOWN, KEY_ENTER, KEY_ENTER]:
		await _taste(taste)
		eingaben += 1

	# Assert
	assert_eq(eingaben, 4, "SC-002: höchstens 4 Eingaben über die Liste.")
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.number, 2, "Der oberste Spielstand der Liste.")


func test_sc_002_ueber_die_liste_mit_zwei_klicks() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	var klicks := 0

	# Act: auf „Spiel laden“ klicken, dann auf Spiel 3 in der zweiten Zeile
	var spiel_laden := _mitte(_hauptmenue(), 2)
	await _maus_nach(spiel_laden)
	await _klick(spiel_laden)
	klicks += 1
	var liste_offen := _liste().visible
	var spiel_3 := _mitte_in_der_liste("Slot1")
	await _maus_nach(spiel_3)
	await _klick(spiel_3)
	klicks += 1

	# Assert
	assert_true(liste_offen, "Ein Klick auf „Spiel laden“ öffnet die Liste.")
	assert_eq(klicks, 2, "SC-002: 2 Klicks.")
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.number, 3)


func test_sc_002_liste_mit_zwanzig_spielstaenden_in_hoechstens_einer_sekunde() -> void:
	# Arrange (R16): 20 Spielstände, je mit einer Kopie von catalog_500.json
	var meldungen: Array[CatalogIssue] = []
	var katalog := EventCatalog.read_file(KATALOGE + "catalog_500.json", meldungen)
	assert_eq(katalog.events.size(), 500)
	for nummer in range(1, SPIELSTAENDE + 1):
		_lege_an(nummer, Difficulty.Level.MITTEL, _tag(1990, 1, 1), ANGELEGT + nummer, katalog)
	await _zeige_titel()
	var zeiten: Array[float] = []

	# Act: je Lauf „Spiel laden“ von Enter bis nach dem nächsten Bild, dann mit Esc zurück
	for lauf in LAEUFE:
		_hauptmenue().select(2)
		var beginn := Time.get_ticks_usec()
		await _taste(KEY_ENTER)
		zeiten.append((Time.get_ticks_usec() - beginn) / 1000.0)
		assert_true(_liste().visible, "Lauf %d: Die Liste ist zu sehen." % lauf)
		assert_eq(_namen().size(), SaveList.LCD_VISIBLE_ROWS)
		await _taste(KEY_ESCAPE)

	# Assert
	var sortiert := zeiten.duplicate()
	sortiert.sort()
	var median: float = sortiert[floori(sortiert.size() / 2.0)]
	gut.p("SC-002, Anzeige der Liste mit %d Spielständen zu je 500 Ereignissen: Median %.1f ms aus %s"
		% [SPIELSTAENDE, median, zeiten])
	assert_lt(median, LISTE_MSEC, "SC-002: Die Liste erscheint in höchstens einer Sekunde.")


func test_spiel_laden_bei_inzwischen_leerem_ordner_bleibt_im_hauptmenue() -> void:
	# Arrange: Nach dem Erscheinen des Titels verschwindet der einzige Spielstand, etwa durch ein
	# zweites Fenster.
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()
	assert_eq(DirAccess.remove_absolute(ORDNER.path_join("spiel_1.json")), OK)

	# Act
	await _oeffne_liste()

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_verfuegbar(_hauptmenue()), [false, true, false, false, true], "Neu gelesen.")
	assert_eq(_hauptmenue().selected_index(), 2, "Auf „Spiel laden“; sein Hinweis sagt, warum.")
	assert_eq(_hinweis_text(), "Noch keine Spielstände.")
	assert_eq(_wechsel, [])


# --- Löschen (T027; FR-017, FR-017a, FR-018, US4) -------------------------------------------------

func test_loeschen_und_eine_zeile_zeigen_die_rueckfrage_mit_abbrechen_vorgewaehlt() -> void:
	# Arrange (US4, Szenario 1)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	var vorher := _inhalte()

	# Act: „Löschen …“, dann Spiel 1 in der untersten Zeile; danach runter auf „Spiel 1 löschen“
	_liste().select(3)
	await _taste(KEY_ENTER)
	var kopfzeile := _kopfzeile_der_liste()
	var hinweis_im_modus := _hinweis_text()
	await _taste(KEY_UP)
	await _taste(KEY_ENTER)
	var hinweis_abbrechen := _hinweis_text()
	var vorwahl := _rueckfrage().selected_index()
	var fokus := _hat_fokus(_rueckfrage())
	await _taste(KEY_DOWN)

	# Assert
	assert_eq(kopfzeile, "WELCHES LÖSCHEN?")
	assert_eq(hinweis_im_modus, "Wähl oben den Spielstand, der weg soll. Esc bricht ab.")
	_assert_nur_sichtbar(_rueckfrage())
	assert_eq(_rueckfrage().header_text, "LÖSCHEN?")
	assert_eq(_texte(_rueckfrage()), ["Abbrechen", "Spiel 1 löschen"])
	assert_eq(_verfuegbar(_rueckfrage()), [true, true])
	assert_eq(vorwahl, 0, "„Abbrechen“ ist vorgewählt.")
	assert_true(fokus, "Die Rückfrage hat den Fokus.")
	assert_eq(hinweis_abbrechen, "Spiel 1 bleibt: Leicht, 01.01.1985. Esc geht auch.")
	assert_eq(_hinweis_text(), "Spiel 1 ist danach weg: Leicht, 01.01.1985. Für immer.")
	_assert_neben_zeile(_rueckfrage(), 1)
	assert_eq(_rueckfrage().get_global_rect(), ANZEIGE, "Auf der Anzeige, wie das Hauptmenü.")
	assert_eq(_inhalte(), vorher, "Noch ist nichts gelöscht.")


func test_rueckfrage_zu_nicht_fortsetzbaren_nennt_den_zustand() -> void:
	# Arrange: Spiel 4 zu neu, Spiel 3 beschädigt
	_kopiere("spiel_kein_json.json", 3)
	_kopiere("spiel_format_2.json", 4)
	await _zeige_titel()
	await _oeffne_liste()
	var gesehen := []

	# Act: zu jeder Zeile die Rückfrage, dann mit Esc zurück
	for zeile in 2:
		await _frage_nach(zeile)
		gesehen.append([_texte(_rueckfrage())[1]] + _hinweise(_rueckfrage()))
		await _taste(KEY_ESCAPE)

	# Assert (FR-017; R14)
	assert_eq(gesehen, [
		["Spiel 4 löschen", "Spiel 4 bleibt: neuere Version. Esc geht auch.",
			"Spiel 4 ist danach weg: neuere Version. Für immer."],
		["Spiel 3 löschen", "Spiel 3 bleibt: beschädigt. Esc geht auch.",
			"Spiel 3 ist danach weg: beschädigt. Für immer."],
	])


func test_esc_in_der_rueckfrage_fuehrt_in_die_liste_und_der_spielstand_bleibt() -> void:
	# Arrange (US4, Szenario 4)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	var vorher := _inhalte()
	await _frage_nach(1)

	# Act
	await _taste(KEY_ESCAPE)

	# Assert
	_assert_abgebrochen(vorher)


func test_abbrechen_in_der_rueckfrage_wirkt_wie_esc() -> void:
	# Arrange (US4, Szenario 4)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	var vorher := _inhalte()
	await _frage_nach(1)

	# Act: „Abbrechen“ ist vorgewählt.
	await _taste(KEY_ENTER)

	# Assert
	_assert_abgebrochen(vorher)


func test_bestaetigen_loescht_nur_diesen_spielstand() -> void:
	# Arrange (US4, Szenario 3; FR-018): Zu Spiel 3 gehört noch eine übrig gebliebene .alt; daneben
	# liegen fremde Dateien.
	_drei_spiele()
	assert_eq(DirAccess.copy_absolute(ORDNER.path_join("spiel_3.json"),
		ORDNER.path_join("spiel_3.json.alt")), OK)
	_schreibe(ORDNER.path_join("notizen.txt"), "Mein Laden")
	_schreibe(ORDNER.path_join("spiel_02.json"), "{}")
	await _zeige_titel()
	await _oeffne_liste()
	var andere := _inhalte()
	andere.erase("spiel_3.json")
	andere.erase("spiel_3.json.alt")

	# Act: Spiel 3 in der zweiten Zeile löschen
	await _frage_nach(1)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_dateien(), ["notizen.txt", "spiel_02.json", "spiel_1.json", "spiel_2.json"],
		"Weg sind spiel_3.json und spiel_3.json.alt, sonst nichts.")
	assert_eq(_inhalte(), andere, "Die anderen Dateien sind unverändert.")
	_assert_nur_sichtbar(_liste())
	assert_eq(_namen(), ["Spiel 2", "Spiel 1"], "Er verschwindet aus der Liste.")
	assert_false(_liste().is_delete_mode(), "Der Löschmodus ist aus.")
	assert_eq(_kopfzeile_der_liste(), "SPIELSTÄNDE")
	assert_eq(_liste().selected_index(), 1, "Auf der Zeile, die an seine Stelle rückt.")
	assert_true(_hat_fokus(_liste()))
	assert_eq(_hinweis_text(), _zeilenhinweis("01.01.1985", ANGELEGT + 60))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Keine Meldung.")
	assert_eq(_wechsel, [])


func test_nach_dem_loeschen_der_untersten_zeile_steht_die_auswahl_auf_der_letzten() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()

	# Act: Spiel 1 in der untersten Zeile löschen
	await _frage_nach(2)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_namen(), ["Spiel 2", "Spiel 3"])
	assert_eq(_liste().selected_index(), 1, "Auf dem letzten Spielstand.")
	assert_eq(_hinweis_text(), _zeilenhinweis("02.07.1991", ANGELEGT + 120))


func test_einen_beschaedigten_spielstand_loeschen() -> void:
	# Arrange (Edge Cases): Auch was sich nicht lesen lässt, lässt sich löschen.
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	_kopiere("spiel_kein_json.json", 8)
	await _zeige_titel()
	await _oeffne_liste()

	# Act
	await _frage_nach(1)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_dateien(), ["spiel_1.json"])
	assert_eq(_namen(), ["Spiel 1"])
	assert_eq(_liste().selected_index(), 0)


func test_den_letzten_spielstand_loeschen_fuehrt_ins_hauptmenue_mit_neues_spiel() -> void:
	# Arrange (US4, Szenario 5)
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()
	await _oeffne_liste()

	# Act
	await _frage_nach(0)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_verfuegbar(_hauptmenue()), [false, true, false, false, true])
	assert_eq(_hauptmenue().selected_index(), 1, "„Neues Spiel“ ist gewählt.")
	assert_true(_hat_fokus(_hauptmenue()))
	assert_eq(_hinweis_text(), "Einen neuen Laden aufmachen. Los geht es am 01.01.1985.")
	assert_eq(_dateien(), [])
	assert_eq(_wechsel, [])


func test_den_zuletzt_gespielten_loeschen_dann_nennt_weiterspielen_den_naechsten() -> void:
	# Arrange (Analyse, F2)
	_drei_spiele()
	await _zeige_titel()
	var vorher := _hauptmenue().entries[0].hint
	await _oeffne_liste()

	# Act: Spiel 2 oben löschen, mit Esc ins Hauptmenü, „Weiterspielen“
	await _frage_nach(0)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)
	await _taste(KEY_ESCAPE)
	var nachher := _hauptmenue().entries[0].hint
	var auswahl := _hauptmenue().selected_index()
	_hauptmenue().select(0)
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(vorher, "Weiter mit Spiel 2, Schwer, am 14.03.1986.")
	assert_eq(nachher, "Weiter mit Spiel 3, Mittel, am 02.07.1991.")
	assert_eq(auswahl, 2, "Zurück auf „Spiel laden“.")
	assert_eq(_wechsel, [SPIELBILDSCHIRM])
	assert_eq(_sitzung.current.number, 3)


func test_esc_im_loeschmodus_beendet_nur_den_modus() -> void:
	# Arrange (US4, Szenario 2; Analyse, F3)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	_liste().select(3)
	await _taste(KEY_ENTER)
	_liste().select(1)

	# Act: Esc, dann Enter auf derselben Zeile
	await _taste(KEY_ESCAPE)
	var sichtbar := _liste().visible
	var modus := _liste().is_delete_mode()
	var kopfzeile := _kopfzeile_der_liste()
	var auswahl := _liste().selected_index()
	var hinweis := _hinweis_text()
	await _taste(KEY_ENTER)

	# Assert
	assert_true(sichtbar, "Die Liste bleibt.")
	assert_false(modus, "Der Löschmodus ist aus.")
	assert_eq(kopfzeile, "SPIELSTÄNDE")
	assert_eq(auswahl, 1, "Die Auswahl bleibt, wo sie war.")
	assert_eq(hinweis, _zeilenhinweis("02.07.1991", ANGELEGT + 120))
	assert_eq(_wechsel, [SPIELBILDSCHIRM], "Enter auf einer Zeile setzt wieder fort.")
	assert_eq(_sitzung.current.number, 3)
	assert_eq(_dateien(), ["spiel_1.json", "spiel_2.json", "spiel_3.json"])


func test_zurueck_im_loeschmodus_beendet_nur_den_modus() -> void:
	# Arrange (Analyse, F3)
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	_liste().select(3)
	await _taste(KEY_ENTER)
	_liste().select(4)
	var hinweis_im_modus := _hinweis_text()

	# Act
	await _taste(KEY_ENTER)
	var sichtbar := _liste().visible
	var modus := _liste().is_delete_mode()
	var hinweis := _hinweis_text()
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(hinweis_im_modus, HINWEIS_ZURUECK_IM_MODUS)
	assert_true(sichtbar, "Die Liste bleibt.")
	assert_false(modus, "Der Löschmodus ist aus.")
	assert_eq(hinweis, "Zurück zum Hauptmenü. Esc geht auch.", "Die Auswahl bleibt auf „Zurück“.")
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 2, "Ein zweites „Zurück“ führt ins Hauptmenü.")


func test_der_loeschmodus_endet_auf_allen_vier_wegen() -> void:
	# Arrange (FR-017a): nach dem Löschen, mit „Abbrechen“ in der Rückfrage, mit „Zurück“, mit Esc
	for nummer in range(1, 6):
		_lege_an(nummer, Difficulty.Level.MITTEL, _tag(1985, 1, 1), ANGELEGT + nummer)
	await _zeige_titel()
	await _oeffne_liste()
	var wege := {}

	# Act
	await _frage_nach(0)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)
	wege["nach dem Löschen"] = _zustand_der_liste()
	await _frage_nach(0)
	await _taste(KEY_ENTER)
	wege["Abbrechen"] = _zustand_der_liste()
	_liste().select(-2)
	await _taste(KEY_ENTER)
	_liste().select(-1)
	await _taste(KEY_ENTER)
	wege["Zurück"] = _zustand_der_liste()
	_liste().select(-2)
	await _taste(KEY_ENTER)
	await _taste(KEY_ESCAPE)
	wege["Esc"] = _zustand_der_liste()

	# Assert
	var erwartet := [true, false, "SPIELSTÄNDE"]
	assert_eq(wege, {"nach dem Löschen": erwartet, "Abbrechen": erwartet, "Zurück": erwartet,
		"Esc": erwartet}, "Liste sichtbar, Löschmodus aus, Kopfzeile SPIELSTÄNDE.")
	assert_eq(_namen().size(), 4, "Gelöscht wurde nur einmal.")


func test_loeschen_mit_der_maus() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()

	# Act: „Löschen …“, Spiel 3, „Spiel 3 löschen“
	for ziel: Vector2 in [_mitte_in_der_liste("DeleteMode"), _mitte_in_der_liste("Slot1")]:
		await _maus_nach(ziel)
		await _klick(ziel)
	var loeschen := _mitte(_rueckfrage(), 1)
	await _maus_nach(loeschen)
	await _klick(loeschen)

	# Assert
	assert_eq(_dateien(), ["spiel_1.json", "spiel_2.json"])
	assert_eq(_namen(), ["Spiel 2", "Spiel 1"])
	assert_false(_liste().is_delete_mode())


func test_loeschen_scheitert_meldung_und_der_spielstand_bleibt_in_der_liste() -> void:
	# Arrange (CHK003; Analyse, E2): An der Stelle von spiel_2.json liegt ein Ordner mit Inhalt,
	# daneben eine fortsetzbare spiel_2.json.alt.
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT + 120)
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 60)
	assert_eq(DirAccess.rename_absolute(ORDNER.path_join("spiel_2.json"),
		ORDNER.path_join("spiel_2.json.alt")), OK)
	assert_eq(DirAccess.make_dir_recursive_absolute(ORDNER.path_join("spiel_2.json/inhalt")), OK)
	await _zeige_titel()
	await _oeffne_liste()

	# Act: Spiel 2 in der zweiten Zeile löschen
	await _frage_nach(1)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_liste())
	assert_eq(_namen(), ["Spiel 1", "Spiel 2"], "Der Spielstand steht noch in der Liste.")
	assert_false(_liste().is_delete_mode(), "Der Löschmodus ist aus.")
	assert_eq(_kopfzeile_der_liste(), "SPIELSTÄNDE")
	assert_eq(_liste().selected_index(), 1, "Auf seiner Zeile.")
	assert_eq(_hinweis_text(), LOESCHEN_GING_NICHT)
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel", "Kontur kassenrot.")
	_assert_neben_zeile(_liste(), 1)
	assert_true(FileAccess.file_exists(ORDNER.path_join("spiel_2.json.alt")), "Die .alt bleibt.")
	assert_push_warning("ließ sich nicht löschen", "Das Protokoll nennt den Fehler.")


func test_die_meldung_zum_loeschen_geht_mit_einer_anderen_zeile() -> void:
	# Arrange
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT + 120)
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 60)
	assert_eq(DirAccess.rename_absolute(ORDNER.path_join("spiel_2.json"),
		ORDNER.path_join("spiel_2.json.alt")), OK)
	assert_eq(DirAccess.make_dir_recursive_absolute(ORDNER.path_join("spiel_2.json/inhalt")), OK)
	await _zeige_titel()
	await _oeffne_liste()
	await _frage_nach(1)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Act
	await _taste(KEY_UP)

	# Assert
	assert_eq(_hinweis_text(), _zeilenhinweis("01.01.1985", ANGELEGT + 120))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel")
	assert_push_warning("ließ sich nicht löschen")


# Die Meldung gehört zum Spielstand, nicht zur Stelle (Klaus, 2026-10-26, Phasenprüfung Phase 5):
# Beim Rollen zeigt dieselbe Zeile einen anderen Spielstand, und dann gilt dessen Hinweis.

func test_meldung_dann_pfeil_hoch_am_oberen_rand_zeigt_den_neuen_hinweis() -> void:
	# Arrange: acht Spielstände, das Fenster zwei Zeilen gerollt; Spiel 6 steht in der obersten
	# Zeile, darüber stehen noch zwei. Sein Löschen scheitert.
	_acht_spiele_eins_gesperrt(6)
	await _zeige_titel()
	await _oeffne_liste()
	_liste().select(7)
	await _scheitere_beim_loeschen(2)
	var vorher := [_hinweis_text(), _liste()._more_above()]
	_assert_neben_zeile(_liste(), 0)

	# Act: Das Fenster rollt eine Zeile; dieselbe Zeile zeigt jetzt Spiel 7.
	await _taste(KEY_UP)

	# Assert
	assert_eq(vorher, [LOESCHEN_GING_NICHT, true], "Voraussetzung: Meldung, oben steht mehr.")
	assert_eq(_liste().selected_slot().display_name(), "Spiel 7")
	assert_eq(_hinweis_text(), _zeilenhinweis("07.01.1985", ANGELEGT + 7 * 60))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Keine Meldung mehr.")
	_assert_neben_zeile(_liste(), 0)
	assert_push_warning("ließ sich nicht löschen")


func test_meldung_dann_pfeil_runter_am_unteren_rand_zeigt_den_neuen_hinweis() -> void:
	# Arrange: Spiel 3 steht in der untersten Zeile des Fensters, darunter noch zwei.
	_acht_spiele_eins_gesperrt(3)
	await _zeige_titel()
	await _oeffne_liste()
	await _scheitere_beim_loeschen(5)
	var vorher := [_hinweis_text(), _liste()._more_below()]
	var unterste := _liste().visible_rows() - 1
	_assert_neben_zeile(_liste(), unterste)

	# Act
	await _taste(KEY_DOWN)

	# Assert
	assert_eq(vorher, [LOESCHEN_GING_NICHT, true], "Voraussetzung: Meldung, unten steht mehr.")
	assert_eq(_liste().selected_slot().display_name(), "Spiel 2")
	assert_eq(_hinweis_text(), _zeilenhinweis("02.01.1985", ANGELEGT + 2 * 60))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Keine Meldung mehr.")
	_assert_neben_zeile(_liste(), unterste)
	assert_push_warning("ließ sich nicht löschen")


func test_mausrad_das_nur_rollt_laesst_die_meldung_beim_spielstand() -> void:
	# Arrange: Spiel 5 in der vierten Zeile mit Meldung.
	_acht_spiele_eins_gesperrt(5)
	await _zeige_titel()
	await _oeffne_liste()
	await _scheitere_beim_loeschen(3)
	_assert_neben_zeile(_liste(), 3)

	# Act: ein Dreh über der Kopfzeile; Spiel 5 bleibt zu sehen und gewählt, eine Zeile höher.
	await _rad(_liste().global_position + Vector2(150, 10), MOUSE_BUTTON_WHEEL_DOWN)

	# Assert
	assert_eq(_liste().selected_slot().display_name(), "Spiel 5")
	assert_eq(_hinweis_text(), LOESCHEN_GING_NICHT, "Die Meldung bleibt beim Spielstand.")
	assert_eq(_hinweis().theme_type_variation, &"WarningPanel")
	_assert_neben_zeile(_liste(), 2)
	assert_push_warning("ließ sich nicht löschen")


func test_mausrad_das_die_auswahl_rueckt_zeigt_den_neuen_hinweis() -> void:
	# Arrange: Spiel 8 in der obersten Zeile mit Meldung.
	_acht_spiele_eins_gesperrt(8)
	await _zeige_titel()
	await _oeffne_liste()
	await _scheitere_beim_loeschen(0)
	assert_eq(_hinweis_text(), LOESCHEN_GING_NICHT, "Voraussetzung: Meldung.")

	# Act: Spiel 8 rollt oben hinaus; die Auswahl rückt auf Spiel 7 in derselben Zeile.
	await _rad(_liste().global_position + Vector2(150, 10), MOUSE_BUTTON_WHEEL_DOWN)

	# Assert
	assert_eq(_liste().selected_slot().display_name(), "Spiel 7")
	assert_eq(_hinweis_text(), _zeilenhinweis("07.01.1985", ANGELEGT + 7 * 60))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel")
	_assert_neben_zeile(_liste(), 0)
	assert_push_warning("ließ sich nicht löschen")


func test_nach_esc_kommt_die_meldung_beim_naechsten_oeffnen_nicht_wieder() -> void:
	# Arrange
	_acht_spiele_eins_gesperrt(8)
	await _zeige_titel()
	await _oeffne_liste()
	await _scheitere_beim_loeschen(0)

	# Act: ins Hauptmenü und wieder in die Liste; Spiel 8 ist wieder oben gewählt.
	await _taste(KEY_ESCAPE)
	await _oeffne_liste()

	# Assert
	assert_eq(_liste().selected_slot().display_name(), "Spiel 8")
	assert_eq(_hinweis_text(), _zeilenhinweis("08.01.1985", ANGELEGT + 8 * 60))
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Esc hat die Meldung beendet.")
	assert_push_warning("ließ sich nicht löschen")


func test_ist_die_datei_schon_weg_gibt_es_keine_meldung() -> void:
	# Arrange: Während die Rückfrage offen ist, löscht ein zweites Fenster Spiel 2.
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	await _frage_nach(0)
	assert_eq(DirAccess.remove_absolute(ORDNER.path_join("spiel_2.json")), OK)

	# Act
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_liste())
	assert_eq(_namen(), ["Spiel 3", "Spiel 1"], "Neu gelesen.")
	assert_false(_liste().is_delete_mode())
	assert_eq(_liste().selected_index(), 0)
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Keine Meldung.")
	assert_eq(_hinweis_text(), _zeilenhinweis("02.07.1991", ANGELEGT + 120))
	assert_eq(_dateien(), ["spiel_1.json", "spiel_3.json"])


func test_ist_die_datei_schon_weg_und_keiner_mehr_da_geht_es_ins_hauptmenue() -> void:
	# Arrange
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT)
	await _zeige_titel()
	await _oeffne_liste()
	await _frage_nach(0)
	assert_eq(DirAccess.remove_absolute(ORDNER.path_join("spiel_1.json")), OK)

	# Act
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)

	# Assert
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 1, "„Neues Spiel“ ist gewählt.")
	assert_eq(_hinweis().theme_type_variation, &"HintPanel", "Keine Meldung.")


# --- Easter Egg (Feature 006, T031) ---------------------------------------------------------------

func test_titel_hat_die_drei_tasten_und_die_seite_invaders() -> void:
	# Arrange
	await _zeige_titel()

	# Assert (contracts/titelbildschirm.md, „Szenenaufbau“ und „Tasten im Titel“)
	assert_eq(_communicator().case_keys, TASTEN, "Die drei Rechtecke aus dem Style-Guide.")
	for index in TASTEN_IM_TITEL.size():
		assert_eq(_gehaeusetaste_flaeche(index), TASTEN_IM_TITEL[index], "Taste %d" % (index + 1))
	assert_eq(_invaders().get_parent(), _communicator(), "Invaders ist eine Seite.")
	assert_eq(_invaders().get_global_rect(), ANZEIGE, "So groß wie die Anzeige, an ihrer Stelle.")
	assert_false(_invaders().visible, "Beim Erscheinen nicht zu sehen.")
	assert_null(_invaders().game(), "Und keine Partie.")
	_assert_nur_sichtbar(_hauptmenue())


func test_die_folge_startet_das_spiel_auf_jeder_der_vier_seiten() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	var dateien_vorher := _inhalte()
	var lagen := _lagen()

	for seite: String in ["Hauptmenü", "Gradwahl", "Liste", "Rückfrage"]:
		await _oeffne(seite)
		var vorher := _zustand_des_titels()

		# Act
		await _folge(FOLGE)

		# Assert: das Spiel auf der Anzeige, mit Fokus; Gerät, Logo und Versionszeile still.
		assert_eq(_communicator().current_page(), _invaders(), "%s: Das Spiel ist die Seite." % seite)
		assert_true(_invaders().has_focus(), "%s: Die Seite hat den Fokus." % seite)
		assert_not_null(_invaders().game(), "%s: Eine Partie läuft." % seite)
		assert_false(_hinweis().visible, "%s: Der Hinweis ist aus." % seite)
		assert_eq(_lagen(), lagen, "%s: Nichts hat sich bewegt." % seite)

		# Act: Esc beendet das Spiel.
		await _taste(KEY_ESCAPE)

		# Assert: alles wie vorher (FR-022).
		assert_eq(_zustand_des_titels(), vorher, "%s: Seite, Fokus und Hinweis wie vorher." % seite)
		assert_false(_invaders().visible)

	assert_eq(_inhalte(), dateien_vorher, "Kein Spielstand angelegt oder geändert (FR-007).")
	assert_false(_sitzung.is_running(), "Kein Spiel des Computerladens.")
	assert_eq(_wechsel, [])


func test_eine_andere_folge_startet_nichts() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	var vorher := _zustand_des_titels()

	for druecke: Array in [[1, 0, 2], [2, 1, 0], [0, 2], [0, 1, 1, 2]]:
		# Act
		await _folge(druecke)

		# Assert
		assert_false(_invaders().visible, "%s startet nichts." % [druecke])
		assert_eq(_zustand_des_titels(), vorher, "%s: Seite, Auswahl und Hinweis bleiben." % [druecke])
		_titel._sequence.reset()


func test_eins_dann_eine_zeile_waehlen_dann_zwei_drei_startet() -> void:
	# Arrange (FR-003): Eine andere Eingabe dazwischen unterbricht die Folge nicht.
	_drei_spiele()
	await _zeige_titel()
	await _gehaeusetaste(0)

	# Act: eine andere Zeile wählen, dann 2 und 3.
	await _taste(KEY_DOWN)
	var vorher := _zustand_des_titels()
	await _gehaeusetaste(1)
	await _gehaeusetaste(2)

	# Assert
	assert_true(_invaders().visible, "Das Spiel startet.")
	await _taste(KEY_ESCAPE)
	assert_eq(_zustand_des_titels(), vorher, "Zurück auf der Zeile, die zuletzt gewählt war.")
	assert_eq(_hauptmenue().selected_index(), 1, "„Neues Spiel“.")


func test_waehrend_des_spiels_loest_im_menue_nichts_aus() -> void:
	# Arrange: ohne Spielstand, „Neues Spiel“ gewählt.
	await _zeige_titel()
	var vorher := _zustand_des_titels()
	await _folge(FOLGE)
	var partie := _invaders().game()

	# Act (FR-017): Pfeile, Leertaste, Enter, die Maus über einer Zeile und noch einmal die Folge.
	for taste: Key in [KEY_UP, KEY_DOWN, KEY_SPACE, KEY_ENTER]:
		await _taste(taste)
	await _maus_nach(_mitte(_hauptmenue(), 0) + Vector2(0, 2))
	await _maus_nach(_mitte(_hauptmenue(), 0))
	await _klick(_mitte(_hauptmenue(), 0))
	await _folge(FOLGE)

	# Assert: noch dieselbe Partie, das Menü unberührt.
	assert_eq(_communicator().current_page(), _invaders(), "Das Spiel steht noch.")
	assert_same(_invaders().game(), partie, "Kein zweites Spiel.")
	assert_false(_gradwahl().visible, "Enter hat „Neues Spiel“ nicht ausgelöst.")
	assert_eq(_hauptmenue().selected_index(), 1, "Die Auswahl hat sich nicht bewegt.")
	assert_eq(_titel._sequence.progress(), 0, "Die Folge zählt während des Spiels nicht.")
	await _taste(KEY_ESCAPE)
	assert_eq(_zustand_des_titels(), vorher)
	assert_eq(_wechsel, [])


func test_nach_esc_bedienen_sich_die_seiten_wie_zuvor() -> void:
	# Arrange
	await _zeige_titel()
	await _folge(FOLGE)
	await _taste(KEY_ESCAPE)

	# Act und Assert: Pfeil runter wählt die nächste Zeile, Pfeil hoch zurück, Enter öffnet die
	# Gradwahl, Esc führt zurück.
	await _taste(KEY_DOWN)
	assert_eq(_hauptmenue().selected_index(), 2)
	assert_eq(_hinweis_text(), _hauptmenue().entries[2].hint)
	await _taste(KEY_UP)
	await _taste(KEY_ENTER)
	_assert_nur_sichtbar(_gradwahl())
	assert_eq(_gradwahl().selected_index(), 1, "Mittel.")
	await _taste(KEY_ESCAPE)
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 1)


func test_ende_nach_der_ergebnisanzeige_fuehrt_zurueck() -> void:
	# Arrange: Gradwahl offen, das Spiel gestartet und ohne Spieler bis zur Niederlage gespielt.
	await _zeige_titel()
	_hauptmenue().select(1)
	await _taste(KEY_ENTER)
	var vorher := _zustand_des_titels()
	await _folge(FOLGE)
	_invaders().autoplay = false
	_spiele_bis_zum_ende()
	for _schritt in roundi(InvadersPage.RESULT_LOCK / InvadersGame.STEP):
		_invaders().advance(InvadersGame.STEP)
	assert_true(_invaders().is_waiting_for_key(), "Voraussetzung: Die Ergebnisanzeige wartet.")

	# Act: Enter führt weiter; das Loslassen kommt danach bei der Gradwahl an.
	await _taste(KEY_ENTER)

	# Assert
	assert_eq(_zustand_des_titels(), vorher, "Gradwahl, Mittel, sein Hinweis wie vorher.")
	assert_eq(_wechsel, [], "Das Loslassen von Enter hat kein Spiel begonnen.")
	assert_false(_sitzung.is_running())
	assert_eq(_dateien(), [])


func test_waehrend_der_fahrt_hinaus_zaehlt_kein_druck() -> void:
	# Arrange: ein Spielstand; Weiterspielen, und der Communicator fährt hinaus.
	_lege_an(1, Difficulty.Level.MITTEL, 0, ANGELEGT)
	await _zeige_titel(ORDNER, true)
	_fahre(1.0 / 60.0, 1.0 / 60.0)
	await _taste(KEY_ENTER)
	_communicator()._process(1.0 / 60.0)
	assert_false(_communicator().is_in(), "Voraussetzung: Er fährt hinaus.")

	# Act: die Folge auf die Tasten, wo sie gerade sind.
	await _folge(FOLGE)
	_fahre(1.0 / 60.0, 1.0 / 60.0)

	# Assert (FR-004)
	assert_false(_invaders().visible, "Das Spiel startet nicht.")
	assert_null(_invaders().game())
	assert_eq(_titel._sequence.progress(), 0, "Kein Druck hat gezählt.")
	assert_eq(_wechsel, [SPIELBILDSCHIRM], "Der Weg zum Spielbildschirm bleibt, wie er war.")


func test_folge_beginnt_bei_neuem_erscheinen_und_nach_dem_spiel_von_vorn() -> void:
	# Arrange: 1 und 2 gedrückt, dann erscheint der Titel neu wie nach „Zum Hauptmenü“.
	await _zeige_titel()
	await _folge([0, 1])
	assert_eq(_titel._sequence.progress(), 2, "Voraussetzung: zwei richtige.")
	await _baue_titel()

	# Act: nur noch die 3.
	await _gehaeusetaste(2)

	# Assert
	assert_false(_invaders().visible, "Der neue Titel beginnt bei 0.")

	# Arrange: im Spiel 1 und 2, dann Esc.
	await _folge(FOLGE)
	await _folge([0, 1])
	await _taste(KEY_ESCAPE)

	# Act
	await _gehaeusetaste(2)

	# Assert
	assert_false(_invaders().visible, "Nach dem Spiel beginnt die Folge bei 0.")
	await _folge(FOLGE)
	assert_true(_invaders().visible, "Und lässt sich wieder eingeben.")


func test_meldung_dann_folge_dann_esc_zeigt_den_hinweis_der_zeile() -> void:
	# Arrange (Analyse, C2; CHK008): „Löschen ging nicht“ steht an Spiel 8.
	_acht_spiele_eins_gesperrt(8)
	await _zeige_titel()
	await _oeffne_liste()
	await _scheitere_beim_loeschen(0)
	assert_eq(_hinweis_text(), LOESCHEN_GING_NICHT, "Voraussetzung: die Meldung.")
	var fokus := _titel.get_viewport().gui_get_focus_owner()

	# Act
	await _folge(FOLGE)
	assert_false(_hinweis().visible, "Im Spiel ist auch die Meldung aus.")
	await _taste(KEY_ESCAPE)

	# Assert
	_assert_nur_sichtbar(_liste())
	assert_same(_titel.get_viewport().gui_get_focus_owner(), fokus, "Derselbe Fokus.")
	assert_eq(_liste().selected_slot().display_name(), "Spiel 8")
	assert_eq(_hinweis_text(), _zeilenhinweis("08.01.1985", ANGELEGT + 8 * 60),
		"Der Hinweis der Zeile, nicht die Meldung.")
	assert_eq(_hinweis().theme_type_variation, &"HintPanel")
	_assert_neben_zeile(_liste(), 0)
	assert_push_warning("ließ sich nicht löschen")


func test_esc_direkt_an_den_titel_waehrend_des_spiels_wechselt_keine_seite() -> void:
	# Arrange (Analyse, C3): Die Gradwahl ist offen; aus ihr führte Esc ins Hauptmenü.
	await _zeige_titel()
	_hauptmenue().select(1)
	await _taste(KEY_ENTER)
	var vorher := _zustand_des_titels()
	await _folge(FOLGE)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true

	# Act: Esc direkt an _unhandled_input().
	_titel._unhandled_input(esc)

	# Assert
	assert_eq(_communicator().current_page(), _invaders(), "Keine Seite wechselt.")

	# Act: wie in dem Bild, in dem die Seite ihren Fokus zurückholt; Esc geht an den Titel.
	_titel.get_viewport().gui_release_focus()
	_druecke(KEY_ESCAPE)

	# Assert
	assert_eq(_communicator().current_page(), _invaders(), "Auch so wechselt keine Seite.")
	assert_false(_hauptmenue().visible, "Nicht ins Hauptmenü.")
	await wait_process_frames(1)
	assert_true(_invaders().has_focus(), "Die Seite hat den Fokus wieder.")

	# Act: Esc an die Seite beendet das Spiel.
	await _taste(KEY_ESCAPE)

	# Assert
	assert_eq(_zustand_des_titels(), vorher, "Zurück in der Gradwahl.")


func test_schliessen_des_fensters_waehrend_des_spiels_schreibt_keinen_spielstand() -> void:
	# Arrange (CHK019): ein Spielstand im Testordner, das Spiel auf der Anzeige.
	_lege_an(1, Difficulty.Level.MITTEL, 0, ANGELEGT)
	await _zeige_titel()
	var vorher := _inhalte()
	await _folge(FOLGE)
	assert_true(_invaders().visible, "Voraussetzung: Das Spiel steht.")

	# Act: das Schließen des Fensters, wie Godot es meldet, an Session und Titel mit allen Knoten.
	_an_alle_knoten(_sitzung, NOTIFICATION_WM_CLOSE_REQUEST)
	_an_alle_knoten(_titel, NOTIFICATION_WM_CLOSE_REQUEST)

	# Assert: Es läuft kein Spiel des Computerladens; das Fenster schließt ohne Speichern.
	assert_false(_sitzung.is_running(), "Das Easter Egg ist kein Spiel der Session.")
	assert_true(get_tree().auto_accept_quit, "Das Fenster schließt gleich, wie auf dem Titel.")
	assert_eq(_inhalte(), vorher, "Kein Spielstand angelegt oder geändert.")
	assert_eq(_beendet, 0, "Der Titel beendet nichts selbst.")


func test_sc_001_vom_dritten_druck_bis_zum_fokus_hoechstens_eine_halbe_sekunde() -> void:
	# Arrange
	await _zeige_titel()
	await _folge([0, 1])
	var stelle := _gehaeusetaste_flaeche(2).get_center()

	# Act: der dritte Druck, dann Bild für Bild, bis die Seite den Fokus hat.
	var beginn := Time.get_ticks_usec()
	_maus_klick_ohne_warten(stelle)
	var bilder := 0
	while not _invaders().has_focus() and bilder < 60:
		await wait_process_frames(1)
		bilder += 1
	var dauer := (Time.get_ticks_usec() - beginn) / 1000000.0

	# Assert
	gut.p("SC-001, vom dritten Druck bis die Seite den Fokus hat: %.4f s, %d Bilder" % [dauer,
		bilder])
	assert_true(_invaders().has_focus())
	assert_lte(dauer, SPIELBEREIT_S, "SC-001: höchstens 0,5 s.")


func test_sc_006_von_finished_bis_der_titel_eingaben_annimmt_hoechstens_eine_sekunde() -> void:
	# Arrange
	_drei_spiele()
	await _zeige_titel()
	await _oeffne_liste()
	var vorher := _zustand_des_titels()
	var fertig_um := [0]
	_invaders().finished.connect(func() -> void: fertig_um[0] = Time.get_ticks_usec())
	var dauern := {}

	for weg: String in ["Esc", "Ergebnisanzeige"]:
		await _folge(FOLGE)
		if weg == "Ergebnisanzeige":
			_invaders().autoplay = false
			_spiele_bis_zum_ende()
			for _schritt in roundi(InvadersPage.RESULT_LOCK / InvadersGame.STEP):
				_invaders().advance(InvadersGame.STEP)

		# Act: Esc oder eine Taste, dann Bild für Bild, bis der Titel wieder Eingaben annimmt.
		_druecke(KEY_ESCAPE if weg == "Esc" else KEY_A)
		var bilder := 0
		while not _nimmt_eingaben_an(vorher) and bilder < 60:
			await wait_process_frames(1)
			bilder += 1
		dauern[weg] = (Time.get_ticks_usec() - fertig_um[0]) / 1000000.0
		_invaders().autoplay = true

		# Assert
		assert_true(_nimmt_eingaben_an(vorher), "%s: Der Titel nimmt Eingaben an." % weg)
		assert_lte(dauern[weg], RUECKWEG_S, "SC-006, %s: höchstens 1 s." % weg)
		assert_eq(_zustand_des_titels(), vorher, "%s: wie vorher." % weg)

	gut.p("SC-006, von finished bis der Titel wieder Eingaben annimmt: Esc %.4f s, Ergebnisanzeige %.4f s"
		% [dauern["Esc"], dauern["Ergebnisanzeige"]])


# --- Randfälle zum Easter Egg (Feature 006, T043) -------------------------------------------------

func test_waehrend_der_fahrt_herein_startet_die_folge_wie_die_seiten_eingaben_annehmen() -> void:
	# Arrange (Edge Cases, „noch hereinfährt“; FR-004): ohne Spielstand. Der Communicator fährt
	# gerade herein und ist nicht gesperrt; seine Seiten nehmen schon Eingaben an (Feature 005,
	# FR-003), also zählen auch die Tasten.
	await _zeige_titel(ORDNER, true)
	for _bild in 3:
		_communicator()._process(1.0 / 60.0)
	assert_gt(_communicator().position.y, GEHAEUSE_OBEN, "Voraussetzung: noch unterwegs.")
	assert_true(_communicator().accepts_input(), "Voraussetzung: Die Seiten nehmen Eingaben an.")

	# Act: die Folge auf die Tasten, wo sie gerade sind.
	await _folge(FOLGE)

	# Assert: Das Spiel startet wie in der Endlage.
	assert_eq(_communicator().current_page(), _invaders(), "Das Spiel ist die Seite.")
	assert_true(_invaders().has_focus(), "Die Seite hat den Fokus.")
	assert_not_null(_invaders().game(), "Eine Partie läuft.")
	assert_false(_hinweis().visible, "Der Hinweis ist aus.")

	# Act: Die Fahrt geht zu Ende.
	_fahre(1.0 / 60.0, 1.0 / 60.0)

	# Assert: in der Endlage noch dasselbe Spiel; Esc führt ins Hauptmenü wie vorher.
	assert_eq(_communicator().position, Vector2(GEHAEUSE_LINKS, GEHAEUSE_OBEN), "In der Endlage.")
	assert_eq(_communicator().current_page(), _invaders(), "Das Spiel steht noch.")
	await _taste(KEY_ESCAPE)
	_assert_nur_sichtbar(_hauptmenue())
	assert_eq(_hauptmenue().selected_index(), 1, "„Neues Spiel“ wie beim Erscheinen.")
	assert_eq(_hinweis_text(), _hauptmenue().entries[1].hint)
	_assert_neben_zeile(_hauptmenue(), 1)
	assert_eq(_wechsel, [])
	assert_false(_sitzung.is_running())


func test_mit_einem_beschaedigten_spielstand_startet_die_folge_das_spiel() -> void:
	# Arrange (Edge Cases, „einen beschädigten“): nur ein Spielstand, und der lässt sich nicht lesen.
	_kopiere("spiel_kein_json.json", 1)
	await _zeige_titel()
	var dateien_vorher := _inhalte()

	for seite: String in ["Hauptmenü", "Liste"]:
		if seite == "Liste":
			# Die Liste steht auf ihrer obersten Zeile, dem beschädigten Spielstand.
			await _oeffne_liste()
		var vorher := _zustand_des_titels()

		# Act
		await _folge(FOLGE)

		# Assert: Das Easter Egg braucht keinen Spielstand.
		assert_eq(_communicator().current_page(), _invaders(), "%s: Das Spiel ist die Seite." % seite)
		assert_true(_invaders().has_focus(), "%s: Die Seite hat den Fokus." % seite)
		assert_not_null(_invaders().game(), "%s: Eine Partie läuft." % seite)

		# Act
		await _taste(KEY_ESCAPE)

		# Assert
		assert_eq(_zustand_des_titels(), vorher, "%s: Seite, Fokus und Hinweis wie vorher." % seite)

	assert_eq(_inhalte(), dateien_vorher, "Der beschädigte Spielstand bleibt, wie er war (FR-007).")
	assert_false(_sitzung.is_running(), "Kein Spiel des Computerladens.")
	assert_eq(_wechsel, [])
	assert_push_warning("spiel_1.json", "Das Protokoll nennt die beschädigte Datei.")


func test_waehrend_des_spiels_druecken_sich_die_tasten_ein_und_klicken_ohne_zweites_spiel() -> void:
	# Arrange (Edge Cases, „während das Spiel läuft“): das Spiel auf der Anzeige.
	await _zeige_titel()
	await _folge(FOLGE)
	var partie := _invaders().game()
	var klick := _communicator().get_node(^"KeyClick") as AudioStreamPlayer

	for index: int in FOLGE:
		var stelle := _gehaeusetaste_flaeche(index).get_center()
		klick.stop()

		# Act: die linke Maustaste runter auf die Taste. Geprüft wird ohne ein Bild zu warten wie in
		# test_communicator.gd: Der Klick ist kurz und könnte in einem langsamen Bild schon verklungen
		# sein.
		_maus_taste(stelle, true)

		# Assert (FR-001a, FR-041)
		assert_true(_communicator().is_case_key_down(index), "Taste %d ist eingedrückt." % (index + 1))
		assert_true(klick.playing, "Taste %d klickt." % (index + 1))

		# Act: über der Taste loslassen; der Druck ginge an die Folge, wenn sie zählte.
		_maus_taste(stelle, false)
		await wait_process_frames(1)

		# Assert
		assert_false(_communicator().is_case_key_down(index), "Taste %d ist wieder oben." % (index + 1))

	# Assert: dieselbe Seite, dieselbe Partie, die Folge bei 0 (FR-004; R16).
	assert_eq(_communicator().current_page(), _invaders(), "Das Spiel steht noch.")
	assert_same(_invaders().game(), partie, "Kein zweites Spiel.")
	assert_eq(_invaders().game().state, InvadersGame.State.PLAYING, "Die Partie läuft weiter.")
	assert_true(_invaders().has_focus(), "Die Seite hat den Fokus.")
	assert_eq(_titel._sequence.progress(), 0, "Kein Druck hat gezählt.")
	assert_eq(_wechsel, [])


# --- Helfer ---------------------------------------------------------------------------------------

## Baut eine Session mit eigener Uhr, eigener Zeitleiste und dem Ordner [param ordner], dann den
## Titel in einem eigenen Viewport, und wartet, bis er seine Blätter gebaut hat.
func _zeige_titel(ordner: String = ORDNER, faehrt := false) -> void:
	_sitzung = await _neue_sitzung(ordner)
	await _baue_titel(faehrt)


## Baut den Titel mit der Session _sitzung in einem eigenen Viewport, wie beim Erscheinen nach dem
## Verlassen eines Spiels, und wartet, bis er seine Blätter gebaut hat.
##
## [param faehrt] false: Der Communicator fährt nicht und steht gleich in der Endlage. true: Er
## fährt, aber nur im Takt des Tests (_fahre()); die Engine treibt ihn nicht.
func _baue_titel(faehrt := false) -> void:
	_baue_titel_ohne_warten(faehrt)
	# Die Blätter entstehen zeitversetzt, die Zeilen ordnet der VBoxContainer im nächsten Bild.
	await wait_process_frames(2)


## Wie _baue_titel(), aber ohne zu warten: Danach ist der Titel im Baum, hat seine Blätter aber
## noch nicht gebaut, denn _build_sheets() kommt zeitversetzt am Ende des Bilds.
func _baue_titel_ohne_warten(faehrt := false) -> void:
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	_titel = TITEL.instantiate() as TitleScreen
	_titel.session = _sitzung
	_titel.scene_callback = _merke_wechsel
	_titel.quit_callback = _merke_beenden
	eigener_viewport.add_child(_titel)
	# Nach dem Einhängen: _ready() hat _process() eingeschaltet; die Fahrt herein beginnt erst
	# zeitversetzt in _build_sheets(), mit dem Wert von animate von jetzt.
	_communicator().animate = faehrt
	if faehrt:
		_communicator().set_process(false)
	# Die Maus steht im Viewport. Im Fenster meldet das das Betriebssystem; ohne diese Meldung gibt
	# ein Viewport Mausbewegungen nicht an gui_input weiter, und die Liste wählt ihre Zeilen über
	# gui_input (wie in test_save_list.gd).
	eigener_viewport.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)


func _neue_sitzung(ordner: String = ORDNER) -> SITZUNG:
	var uhr := UHR.new()
	add_child_autofree(uhr)
	var zeitleiste := ZEITLEISTE.new()
	zeitleiste.catalog_path = KATALOGE + "catalog_us1_grade.json"
	zeitleiste.clock = uhr
	add_child_autofree(zeitleiste)
	var sitzung := SITZUNG.new()
	sitzung.folder = ordner
	sitzung.clock = uhr
	sitzung.timeline = zeitleiste
	sitzung.now = func() -> int: return ANGELEGT + 3600
	sitzung.rng = RandomNumberGenerator.new()
	sitzung.rng.seed = WUERFEL_SEED
	sitzung.quit_callback = func() -> void: pass
	add_child_autofree(sitzung)
	await wait_process_frames(2)
	return sitzung


func _merke_wechsel(pfad: String) -> void:
	_wechsel.append(pfad)


func _merke_beenden() -> void:
	_beendet += 1


func _uhr() -> UHR:
	return _sitzung.clock as UHR


func _zeitleiste() -> ZEITLEISTE:
	return _sitzung.timeline as ZEITLEISTE


func _communicator() -> Communicator:
	return _titel.get_node(^"Communicator") as Communicator


func _hauptmenue() -> MainMenu:
	return _titel.get_node(^"Communicator/MainMenu") as MainMenu


func _gradwahl() -> MainMenu:
	return _titel.get_node(^"Communicator/DifficultySheet") as MainMenu


func _liste() -> SaveList:
	return _titel.get_node(^"Communicator/SaveList") as SaveList


func _rueckfrage() -> MainMenu:
	return _titel.get_node(^"Communicator/ConfirmSheet") as MainMenu


## Der Hinweis gehört seit Feature 005 zum Communicator.
func _hinweis() -> MenuHint:
	return _titel.get_node(^"Communicator/Hint") as MenuHint


func _hinweis_text() -> String:
	assert_true(_hinweis().visible, "Der Hinweis ist zu sehen.")
	return (_hinweis().get_node(^"Text") as Label).text


func _texte(blatt: MainMenu) -> Array:
	return blatt.entries.map(func(eintrag: MenuEntry) -> String: return eintrag.label)


func _verfuegbar(blatt: MainMenu) -> Array:
	return blatt.entries.map(func(eintrag: MenuEntry) -> bool: return eintrag.available)


func _hinweise(blatt: MainMenu) -> Array:
	return blatt.entries.map(func(eintrag: MenuEntry) -> String: return eintrag.hint)


## Ob der Fokus im Viewport des Titels auf einer Zeile von [param blatt] liegt.
func _hat_fokus(blatt: Control) -> bool:
	var besitzer := _titel.get_viewport().gui_get_focus_owner()
	return besitzer != null and blatt.is_ancestor_of(besitzer)


## Genau [param blatt] ist zu sehen, kein anderes Blatt.
func _assert_nur_sichtbar(blatt: Control) -> void:
	for anderes: Control in [_hauptmenue(), _gradwahl(), _liste(), _rueckfrage()]:
		assert_eq(anderes.visible, anderes == blatt,
			"%s sichtbar: %s" % [anderes.name, anderes == blatt])


## Der Hinweis steht oben bündig mit Zeile [param index] von [param blatt] und seit Feature 005 4
## Pixel links neben dem Gehäuse des Communicators (R7). Bei der Liste ist [param index] die Zeile
## auf der Anzeige unter der Kopfzeile.
func _assert_neben_zeile(blatt: Control, index: int) -> void:
	var oben := blatt.global_position.y + ZEILE * (index + 1)
	assert_eq(_hinweis().global_position.y, oben, "Oben bündig mit Zeile %d." % index)
	assert_eq(_hinweis().global_position.x + _hinweis().size.x,
		GEHAEUSE_LINKS - MenuHint.GAP, "4 Pixel links neben dem Gehäuse.")


## Öffnet die Liste über „Spiel laden“ mit Enter.
func _oeffne_liste() -> void:
	_hauptmenue().select(2)
	await _taste(KEY_ENTER)


## Schaltet in der offenen Liste den Löschmodus ein und löst Zeile [param zeile] aus: Die Rückfrage
## erscheint. -2 ist „Löschen …“, denn select() läuft an den Enden um.
func _frage_nach(zeile: int) -> void:
	_liste().select(-2)
	await _taste(KEY_ENTER)
	_liste().select(zeile)
	await _taste(KEY_ENTER)


## Löscht in der offenen Liste Zeile [param zeile] über Löschmodus, Rückfrage und „löschen“; ist
## der Spielstand gesperrt, scheitert es, und die Meldung steht an seiner Zeile.
func _scheitere_beim_loeschen(zeile: int) -> void:
	await _frage_nach(zeile)
	await _taste(KEY_DOWN)
	await _taste(KEY_ENTER)


## Die Namen in den sichtbaren Zeilen der Liste, von oben nach unten.
func _namen() -> Array:
	var namen := []
	for zeile in _liste().visible_rows():
		var knopf := _liste().get_node("Rows/Slot%d" % zeile) as Button
		if knopf.visible:
			namen.append((knopf.get_node(^"Name") as Label).text)
	return namen


## Die Texte der sichtbaren Spalten von Zeile [param zeile] der Liste, von links nach rechts.
func _zellen(zeile: int) -> Array:
	var texte := []
	var knopf := _liste().get_node("Rows/Slot%d" % zeile) as Button
	for zelle: StringName in [&"Name", &"Difficulty", &"State", &"Day", &"Played"]:
		var label := knopf.get_node(String(zelle)) as Label
		if label.visible:
			texte.append(label.text)
	return texte


func _kopfzeile_der_liste() -> String:
	return (_liste().get_node(^"Rows/Header") as Label).text


## Ist die Liste zu sehen, ist der Löschmodus an, und was steht in der Kopfzeile.
func _zustand_der_liste() -> Array:
	return [_liste().visible, _liste().is_delete_mode(), _kopfzeile_der_liste()]


## Nach Abbrechen in der Rückfrage: die Liste ohne Löschmodus, die Auswahl auf Spiel 3 in Zeile 1,
## nach dem gefragt wurde, und alle Dateien wie [param vorher].
func _assert_abgebrochen(vorher: Dictionary) -> void:
	_assert_nur_sichtbar(_liste())
	assert_false(_liste().is_delete_mode(), "Der Löschmodus ist aus.")
	assert_eq(_kopfzeile_der_liste(), "SPIELSTÄNDE")
	assert_eq(_liste().selected_index(), 1, "Auf dem Spielstand, nach dem gefragt wurde.")
	assert_true(_hat_fokus(_liste()))
	assert_eq(_hinweis_text(), _zeilenhinweis("02.07.1991", ANGELEGT + 120))
	assert_eq(_inhalte(), vorher, "Der Spielstand ist unverändert.")
	assert_eq(_wechsel, [])


## Die Mitte der Zeile [param knopf] der Liste, etwa „Slot1“ oder „DeleteMode“, in Koordinaten des
## Viewports.
func _mitte_in_der_liste(knopf: String) -> Vector2:
	return (_liste().get_node("Rows/" + knopf) as Button).get_global_rect().get_center()


## Die Mitte von Zeile [param index] in [param blatt], in Koordinaten des Viewports.
func _mitte(blatt: MainMenu, index: int) -> Vector2:
	var zeilen := blatt.find_children("*", "Button", true, false)
	return (zeilen[index] as Button).get_global_rect().get_center()


## Drückt [param taste] und lässt sie los, über push_input wie ein echter Tastendruck, und wartet
## ein Bild wie zwischen zwei Tasten eines Menschen. Erst dann hat der VBoxContainer eines eben
## gezeigten oder neu gebauten Blatts seine Zeilen angeordnet, und Pfeiltasten finden die
## Nachbarzeile.
func _taste(taste: Key) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventKey.new()
		ereignis.keycode = taste
		ereignis.physical_keycode = taste
		ereignis.pressed = gedrueckt
		_titel.get_viewport().push_input(ereignis)
	await wait_process_frames(1)


## Drückt [param taste] und lässt sie los wie _taste(), aber ohne ein Bild zu warten: für Eingaben,
## bevor der Titel seine Blätter zeitversetzt baut.
func _druecke(taste: Key) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventKey.new()
		ereignis.keycode = taste
		ereignis.physical_keycode = taste
		ereignis.pressed = gedrueckt
		_titel.get_viewport().push_input(ereignis)


## Taktet die laufende Fahrt des Communicators: [param erstes] im ersten Bild, [param danach] in
## jedem weiteren, bis slide_finished kommt. Gibt die Zahl der Bilder zurück. Fährt er hinaus,
## wechselt der Titel dabei die Szene über scene_callback. [param nach_jedem_bild] läuft, wenn
## gesetzt, nach jedem Bild der Fahrt.
func _fahre(erstes: float, danach: float, nach_jedem_bild := Callable()) -> int:
	var fertig := [false]
	var ende := func(_drin: bool) -> void: fertig[0] = true
	_communicator().slide_finished.connect(ende)
	var bilder := 0
	var schritt := erstes
	while not fertig[0] and bilder < 200:
		_communicator()._process(schritt)
		if nach_jedem_bild.is_valid():
			nach_jedem_bild.call()
		bilder += 1
		schritt = danach
	_communicator().slide_finished.disconnect(ende)
	assert_true(fertig[0], "Die Fahrt endet.")
	return bilder


## Fährt mit der Maus nach [param ziel] und wartet ein Bild; true heißt: Koordinaten des Viewports.
func _maus_nach(ziel: Vector2) -> void:
	var ereignis := InputEventMouseMotion.new()
	ereignis.position = ziel
	ereignis.global_position = ziel
	_titel.get_viewport().push_input(ereignis, true)
	await wait_process_frames(1)


## Ein Dreh am Mausrad bei [param ziel], als Drücken und Loslassen wie in test_save_list.gd, ohne
## Mausbewegung; dann ein Bild.
func _rad(ziel: Vector2, richtung: MouseButton) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = richtung
		ereignis.position = ziel
		ereignis.global_position = ziel
		ereignis.pressed = gedrueckt
		_titel.get_viewport().push_input(ereignis, true)
	await wait_process_frames(1)


## Klickt mit der linken Taste bei [param ziel] und wartet ein Bild.
func _klick(ziel: Vector2) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = MOUSE_BUTTON_LEFT
		ereignis.position = ziel
		ereignis.global_position = ziel
		ereignis.pressed = gedrueckt
		_titel.get_viewport().push_input(ereignis, true)
	await wait_process_frames(1)


## Legt im Testordner Spiel [param nummer] an: Grad, Spieltag und „zuletzt gespielt“ wie angegeben,
## Katalog [param katalog], ohne ihn catalog_us1_grade.json.
func _lege_an(nummer: int, grad: Difficulty.Level, tag: int, zuletzt: int,
		katalog: EventCatalog = null) -> void:
	var meldungen: Array[CatalogIssue] = []
	var game := SaveGame.new()
	game.number = nummer
	game.name = SaveGame.default_name(nummer)
	game.difficulty = grad
	game.seed = 4711
	game.day = tag
	game.created_at = ANGELEGT
	game.last_played_at = zuletzt
	game.game_version = "0.1"
	game.catalog = katalog if katalog != null \
		else EventCatalog.read_file(KATALOGE + "catalog_us1_grade.json", meldungen)
	assert_eq(SaveStore.new(ORDNER).write(game, true), OK, "Spiel %d angelegt." % nummer)


## Kopiert eine Fixture als spiel_<nummer>.json in den Testordner.
func _kopiere(fixture: String, nummer: int) -> void:
	assert_eq(DirAccess.copy_absolute(FIXTURES.path_join(fixture),
		ORDNER.path_join("spiel_%d.json" % nummer)), OK, "Kopiert: %s" % fixture)


## Spiel 1 Leicht am 01.01.1985, Spiel 2 Schwer am 14.03.1986, Spiel 3 Mittel am 02.07.1991; zuletzt
## gespielt ist Spiel 2, dann 3, dann 1. Die Liste zeigt also Spiel 2, Spiel 3, Spiel 1.
func _drei_spiele() -> void:
	_lege_an(1, Difficulty.Level.LEICHT, _tag(1985, 1, 1), ANGELEGT + 60)
	_lege_an(2, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ANGELEGT + 180)
	_lege_an(3, Difficulty.Level.MITTEL, _tag(1991, 7, 2), ANGELEGT + 120)


## Der Hinweis einer fortsetzbaren Zeile der Liste: „Steht am 14.03.1986. Gespielt am 26.10.2026,
## 21:40 Uhr.“ Nur „zuletzt gespielt“ kommt aus der Ortszeit des Rechners.
func _zeilenhinweis(spieldatum: String, zuletzt: int) -> String:
	return "Steht am %s. Gespielt am %s Uhr." % [spieldatum,
		SaveGame.time_text(zuletzt).replace(" ", ", ")]


## Spiel 1 bis Spiel 8, Mittel, Spiel n am 0n.01.1985 und n Minuten nach ANGELEGT gespielt; die
## Liste zeigt also Spiel 8 bis Spiel 1, und es wird gerollt. Löschen von Spiel [param gesperrt]
## scheitert wie in test_loeschen_scheitert_…: An der Stelle von spiel_N.json liegt ein Ordner mit
## Inhalt, daneben die fortsetzbare spiel_N.json.alt.
func _acht_spiele_eins_gesperrt(gesperrt: int) -> void:
	for nummer in range(1, 9):
		_lege_an(nummer, Difficulty.Level.MITTEL, _tag(1985, 1, nummer), ANGELEGT + nummer * 60)
	var datei := ORDNER.path_join("spiel_%d.json" % gesperrt)
	assert_eq(DirAccess.rename_absolute(datei, datei + ".alt"), OK)
	assert_eq(DirAccess.make_dir_recursive_absolute(datei.path_join("inhalt")), OK)


## Name → Inhalt jeder Datei im Testordner.
func _inhalte() -> Dictionary:
	var inhalte := {}
	for datei in DirAccess.get_files_at(ORDNER):
		inhalte[datei] = FileAccess.get_file_as_string(ORDNER.path_join(datei))
	return inhalte


## Die Dateien und Ordner im Testordner, sortiert.
func _dateien() -> Array:
	var namen := Array(DirAccess.get_files_at(ORDNER))
	namen.append_array(DirAccess.get_directories_at(ORDNER))
	namen.sort()
	return namen


func _schreibe(pfad: String, text: String) -> void:
	var datei := FileAccess.open(pfad, FileAccess.WRITE)
	datei.store_string(text)
	datei.close()


func _raeume_auf(pfad: String) -> void:
	var ordner := DirAccess.open(pfad)
	if ordner == null:
		return
	for datei in ordner.get_files():
		ordner.remove(datei)
	for unterordner in ordner.get_directories():
		_raeume_auf(pfad.path_join(unterordner))
	DirAccess.remove_absolute(pfad)


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()


## Sechs Spielstände, Spiel 1 bis 6, und Spiel 9999, das zuletzt gespielte: Die Liste zeigt es oben.
func _sechs_und_spiel_9999() -> void:
	for nummer in range(1, 7):
		_lege_an(nummer, Difficulty.Level.LEICHT, nummer, ANGELEGT + nummer * 60)
	_lege_an(9999, Difficulty.Level.SCHWER, _tag(1999, 12, 31), ANGELEGT + 3000)


## [param seite] passt auf die Anzeige (SC-004): Sie liegt genau auf ihr, ihre Zeilen passen in die
## Höhe, jede Zeile und die Kopfzeile in die Breite, und kein Text einer Spalte wird gekürzt.
func _assert_passt(seite: Control) -> void:
	assert_eq(seite.get_global_rect(), ANZEIGE, "%s liegt auf der Anzeige." % seite.name)
	var zeilen := seite.get_node(^"Rows") as VBoxContainer
	assert_lte(zeilen.get_combined_minimum_size().y, ANZEIGE.size.y,
		"%s: Alle Zeilen passen in die Höhe." % seite.name)
	for kind in zeilen.get_children():
		var zeile := kind as Control
		if not zeile.visible:
			continue
		assert_lte(zeile.get_combined_minimum_size().x, zeilen.size.x,
			"%s/%s passt in die Breite." % [seite.name, zeile.name])
		for knoten in zeile.find_children("*", "Label", false, false):
			var spalte := knoten as Label
			if not spalte.visible or spalte.text.is_empty():
				continue
			var schrift := spalte.get_theme_font(&"font")
			var breite := schrift.get_string_size(spalte.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				spalte.get_theme_font_size(&"font_size")).x
			assert_lte(breite, spalte.size.x, "%s/%s „%s“ wird nicht gekürzt." % [seite.name,
				zeile.name, spalte.text])


## Was frei bleiben muss (SC-006): Logo samt pixelschatten, Untertitel und Versionszeile, je mit den
## 2 Pixeln Schatten nach rechts unten.
func _freie_flaechen() -> Dictionary:
	var schatten := Vector2(2, 2)
	var flaechen := {}
	for pfad: String in ["LogoBlock/Logo", "LogoBlock/Subtitle", "VersionLine"]:
		var teil := _titel.get_node(pfad) as Control
		flaechen[pfad] = Rect2(teil.global_position, teil.size + schatten)
	return flaechen


## [param flaeche] überschneidet keine der freien Flächen [param frei].
func _assert_frei(flaeche: Rect2, frei: Dictionary, was: String) -> void:
	for pfad: String in frei:
		assert_false(flaeche.intersects(frei[pfad]), "%s überschneidet %s: %s und %s." % [was,
			pfad, flaeche, frei[pfad]])


## Wählt jede Zeile von [param seite] und prüft Hinweis und Meldung daneben gegen [param frei], die
## Meldung mit beiden Sätzen des Titels. Der Hinweiskasten zählt mit seinem Schatten.
func _pruefe_jede_zeile(seite: Control, frei: Dictionary) -> void:
	var anzahl := 0
	if seite is MainMenu:
		anzahl = (seite as MainMenu).entries.size()
	else:
		anzahl = (seite as SaveList)._slots.size() + 2
	for zeile in anzahl:
		if seite is MainMenu:
			(seite as MainMenu).select(zeile)
		else:
			(seite as SaveList).select(zeile)
		await wait_process_frames(1)
		_assert_frei(_hinweis_flaeche(), frei, "%s, Zeile %d, Hinweis" % [seite.name, zeile])
		for satz: String in [NICHT_ANGELEGT, LOESCHEN_GING_NICHT]:
			_communicator().show_warning(satz, _titel._current_row())
			_assert_frei(_hinweis_flaeche(), frei, "%s, Zeile %d, Meldung" % [seite.name, zeile])
		_communicator().hide_hint()


func _hinweis_flaeche() -> Rect2:
	var schatten := Vector2(MenuHint.SHADOW_OFFSET, MenuHint.SHADOW_OFFSET)
	return Rect2(_hinweis().global_position, _hinweis().size + schatten)


# --- Helfer zum Easter Egg ------------------------------------------------------------------------

func _invaders() -> InvadersPage:
	return _titel.get_node(^"Communicator/Invaders") as InvadersPage


## Die Klickfläche der Gehäusetaste [param index] da, wo sie gerade steht, in Koordinaten des
## Viewports.
func _gehaeusetaste_flaeche(index: int) -> Rect2:
	return (_communicator().get_node("Keys/CaseKey%d" % index) as Control).get_global_rect()


## Ein Linksklick auf die Mitte der Gehäusetaste [param index], dann ein Bild.
func _gehaeusetaste(index: int) -> void:
	await _klick(_gehaeusetaste_flaeche(index).get_center())


## Klickt die Gehäusetasten [param druecke] nacheinander.
func _folge(druecke: Array) -> void:
	for index: int in druecke:
		await _gehaeusetaste(index)


## Ein Linksklick bei [param ziel] wie _klick(), aber ohne ein Bild zu warten (für Messungen).
func _maus_klick_ohne_warten(ziel: Vector2) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = MOUSE_BUTTON_LEFT
		ereignis.position = ziel
		ereignis.global_position = ziel
		ereignis.pressed = gedrueckt
		_titel.get_viewport().push_input(ereignis, true)


## Nur Drücken ([param gedrueckt] true) oder nur Loslassen der linken Maustaste bei [param ziel],
## ohne ein Bild zu warten; dazwischen lässt sich prüfen, ob eine Gehäusetaste eingedrückt ist.
func _maus_taste(ziel: Vector2, gedrueckt: bool) -> void:
	var ereignis := InputEventMouseButton.new()
	ereignis.button_index = MOUSE_BUTTON_LEFT
	ereignis.position = ziel
	ereignis.global_position = ziel
	ereignis.pressed = gedrueckt
	_titel.get_viewport().push_input(ereignis, true)


## Öffnet [param seite] aus dem Zustand des Tests davor: Hauptmenü beim Erscheinen, dann Gradwahl
## über „Neues Spiel“, die Liste über das Hauptmenü, die Rückfrage aus der Liste.
func _oeffne(seite: String) -> void:
	match seite:
		"Gradwahl":
			_hauptmenue().select(1)
			await _taste(KEY_ENTER)
		"Liste":
			await _taste(KEY_ESCAPE)
			await _oeffne_liste()
		"Rückfrage":
			await _frage_nach(0)
	await wait_process_frames(1)


## Was nach dem Easter Egg wieder so sein muss wie vorher: sichtbare Seite, ihre Auswahl, der
## Fokus und der Hinweis mit Text, Art und Lage. Pfade statt Objekte, damit ein Unterschied lesbar ist.
func _zustand_des_titels() -> Dictionary:
	var seite := _communicator().current_page()
	var fokus := _titel.get_viewport().gui_get_focus_owner()
	var hinweis := _hinweis()
	return {
		"seite": String(seite.name) if seite != null else "",
		"auswahl": seite.call(&"selected_index") if seite != null
			and seite.has_method(&"selected_index") else -1,
		"fokus": String(_titel.get_path_to(fokus)) if fokus != null else "",
		"hinweis": (hinweis.get_node(^"Text") as Label).text if hinweis.visible else "",
		"art": hinweis.theme_type_variation if hinweis.visible else &"",
		"lage": hinweis.global_position if hinweis.visible else Vector2(),
	}


## Lagen von Gerät, Logoblock und Versionszeile.
func _lagen() -> Array:
	return [_communicator().global_position,
		(_titel.get_node(^"LogoBlock") as Control).global_position,
		(_titel.get_node(^"VersionLine") as Control).global_position]


## Taktet die Partie ohne Spieler bis WON oder LOST; die Seite taktet sich dabei nicht selbst.
func _spiele_bis_zum_ende() -> void:
	for _schritt in HOECHSTENS_SCHRITTE:
		var partie := _invaders().game()
		if partie.state == InvadersGame.State.WON or partie.state == InvadersGame.State.LOST:
			return
		_invaders().advance(InvadersGame.STEP)
	fail_test("Die Partie endet nicht in %d Schritten." % HOECHSTENS_SCHRITTE)


## Ob der Titel wieder Eingaben annimmt: das Spiel weg, die Wache offen und der Fokus da, wo er in
## [param vorher] war.
func _nimmt_eingaben_an(vorher: Dictionary) -> bool:
	return (not _invaders().visible and _titel._accepts_input()
		and _zustand_des_titels()["fokus"] == vorher["fokus"])


## Schickt [param nachricht] an [param knoten] und alle Knoten darunter, wie Godot das Schließen des
## Fensters meldet (wie test_werkstatt_scene.gd).
func _an_alle_knoten(knoten: Node, nachricht: int) -> void:
	knoten.notification(nachricht)
	for kind in knoten.get_children(true):
		if not kind is Window:
			_an_alle_knoten(kind, nachricht)
