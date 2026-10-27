extends GutTest

## Prüft das Hauptmenü: die Zeilen in ihrer Reihenfolge, welche sich auslösen lassen, die
## Startauswahl, die Meldung, wenn eine Zeile gewählt wird, die Meldung, wenn ein Eintrag
## ausgelöst wird, die Bedienung mit Tastatur und Maus, den Mauszeiger je Eintrag und die
## gedämpfte Schrift gesperrter Zeilen.
##
## Seit Feature 004 (T017) dazu: Kopfzeile und Breite als Eigenschaften, neue Einträge zur
## Laufzeit mit Vorwahl, und ein unsichtbares Menü nimmt keinen Fokus.
##
## Seit Feature 005 (T014) dazu: das Menü auf der Anzeige des Communicators (look = LCD). Die Tests
## dazu bauen ein eigenes Menü in einem eigenen Viewport, so groß wie die Anzeige, wie der
## Communicator es hinstellt; alle Tests davor laufen unverändert auf Papier.
##
## Die vier Einträge entstehen hier im Code, mit den Werten aus dem Datenmodell
## (specs/001-hauptmenue/data-model.md). Geprüft wird also das Menü, nicht die Daten,
## die später im Titelbildschirm stehen.
##
## Das Menü steht hier ohne Titelbildschirm. Auf entry_activated hört also nur GUT, und
## ein ausgelöstes „Beenden“ beendet nicht den Testlauf.
##
## Tasten und Klicks gehen wie echte Eingaben über push_input in den Viewport des Menüs,
## nicht über select(). So prüfen die Tests mit, was Godot daraus macht: die Aktionen
## ui_up, ui_focus_next und so weiter und den Weg des Fokus.

const MENU_SCENE := preload("res://scenes/title/main_menu.tscn")
## Größe der Anzeige des Communicators (Style-Guide, Baustein Communicator).
const ANZEIGE := Vector2(384, 192)

var _menu: MainMenu


func before_each() -> void:
	_menu = MENU_SCENE.instantiate() as MainMenu
	# Die Einträge müssen vor add_child stehen, denn _ready() baut aus ihnen die Zeilen.
	_menu.entries = _eintraege()
	# Ein eigener Viewport, wie ein kleiner Bildschirm nur für diesen Test: Im
	# Haupt-Viewport liegt GUTs Oberfläche über allem und finge jeden Mausklick ab. Der
	# eigene Viewport hat seine eigene Eingabe und seinen eigenen Fokus.
	var eigener_viewport := SubViewport.new()
	add_child_autofree(eigener_viewport)
	# Das Menü steht nicht allein: Oben rechts daneben liegt ein fremder Button, wie
	# später andere Bedienelemente. Pfeiltasten und Tab dürfen trotzdem nie dorthin.
	var buehne := Control.new()
	eigener_viewport.add_child(buehne)
	buehne.add_child(_menu)
	var fremder_button := Button.new()
	fremder_button.position = Vector2(MainMenu.PAPER_WIDTH + 40, 0)
	buehne.add_child(fremder_button)
	# Einen Frame warten: Die Startauswahl kommt zeitversetzt (call_deferred), und auch
	# der VBoxContainer ordnet die Zeilen erst dann an.
	await wait_process_frames(1)


func after_each() -> void:
	# Ein Bild warten: set_entries() nimmt die alten Zeilen mit remove_child() aus dem Baum und gibt
	# sie mit queue_free() erst am Ende des Bilds frei. Endet ein Test gleich danach, stünden sie
	# sonst noch als verwaiste Knoten da, wenn GUT nach after_each() zählt.
	await wait_process_frames(1)


# --- Aufbau ---------------------------------------------------------------

func test_vier_eintraege_in_der_richtigen_reihenfolge() -> void:
	# Act
	var texte := _zeilen().map(func(zeile: Button) -> String: return zeile.text)

	# Assert
	assert_eq(texte, ["Neues Spiel", "Spiel laden", "Einstellungen", "Beenden"],
		"Je Eintrag eine Zeile, in der Reihenfolge der Einträge.")


func test_nur_beenden_ist_verfuegbar() -> void:
	# Act
	var verfuegbar := _zeilen().map(func(zeile: Button) -> bool: return not zeile.disabled)

	# Assert
	assert_eq(verfuegbar, [false, false, false, true],
		"Nur „Beenden“ darf sich auslösen lassen, die übrigen Zeilen sind gesperrt.")


# --- Auswahl --------------------------------------------------------------

func test_startauswahl_ist_neues_spiel() -> void:
	# Assert
	assert_eq(_menu.selected_index(), 0, "Beim Erscheinen muss die erste Zeile gewählt sein.")
	assert_eq(_menu.selected_entry().id, &"new_game")
	assert_eq(_menu.get_viewport().gui_get_focus_owner(), _zeilen()[0],
		"Die Auswahl ist der Fokus: Der Button von „Neues Spiel“ muss ihn haben.")


func test_select_meldet_selection_changed() -> void:
	# Arrange
	watch_signals(_menu)

	# Act
	_menu.select(3)

	# Assert
	assert_signal_emitted(_menu, "selection_changed", "Jede Auswahl muss gemeldet werden.")
	var parameter: Array = get_signal_parameters(_menu, "selection_changed")
	assert_eq(parameter[0], _menu.entries[3], "Gemeldet wird der neu gewählte Eintrag.")
	# Die ganze vierte Eintragszeile (unter der Kopfzeile), über die volle Papierbreite
	# und in globalen Koordinaten, damit der Hinweis sich danach richten kann.
	var erwartet := Rect2(_menu.global_position + Vector2(0, 4 * MainMenu.ROW_HEIGHT),
		Vector2(_menu.size.x, MainMenu.ROW_HEIGHT))
	assert_eq(parameter[1], erwartet, "Das Rechteck muss die gewählte Zeile sein.")
	assert_eq(_menu.selected_index(), 3)


# --- Auslösen -------------------------------------------------------------

func test_beenden_meldet_quit_genau_einmal() -> void:
	# Arrange
	_menu.select(3)
	watch_signals(_menu)

	# Act
	_menu.activate_selected()

	# Assert
	assert_signal_emit_count(_menu, "entry_activated", 1,
		"Einmal auslösen heißt genau einmal melden.")
	assert_signal_emitted_with_parameters(_menu, "entry_activated", [&"quit"])


func test_nicht_verfuegbare_eintraege_melden_nichts() -> void:
	# Arrange
	watch_signals(_menu)

	# Act und Assert für jeden der drei gesperrten Einträge. Die Zählung läuft über alle
	# drei weiter; meldet einer doch, nennt die Meldung ihn beim Namen.
	for index: int in [0, 1, 2]:
		var bezeichnung := _menu.entries[index].label
		_menu.select(index)
		_menu.activate_selected()
		assert_signal_emit_count(_menu, "entry_activated", 0,
			"„%s“ ist nicht verfügbar und darf nichts melden, auch gewählt nicht." % bezeichnung)


func test_enter_leertaste_und_klick_bewirken_nach_dem_erscheinen_nichts() -> void:
	# Arrange: Gewählt ist „Neues Spiel“, die Startauswahl, und der Eintrag ist nicht
	# verfügbar.
	watch_signals(_menu)
	var neues_spiel := _mitte(0)

	# Act und Assert je Eingabe, als echte Ereignisse über push_input.
	_taste(KEY_ENTER)
	assert_signal_emit_count(_menu, "entry_activated", 0, "Enter löst nichts aus.")
	_taste(KEY_SPACE)
	assert_signal_emit_count(_menu, "entry_activated", 0, "Die Leertaste löst nichts aus.")
	_maus_nach(neues_spiel)
	_klick(neues_spiel, MOUSE_BUTTON_LEFT)
	assert_signal_emit_count(_menu, "entry_activated", 0, "Ein Linksklick löst nichts aus.")
	assert_eq(_menu.selected_index(), 0, "Die Auswahl bleibt auf „Neues Spiel“.")


# --- Tastatur -------------------------------------------------------------

func test_pfeil_runter_laeuft_reihum() -> void:
	# Arrange: Gewählt ist „Neues Spiel“, die Startauswahl.

	# Act
	var auswahl := _auswahl_nach_jedem_druck(KEY_DOWN)

	# Assert
	assert_eq(auswahl, [1, 2, 3, 0], "Nach der letzten Zeile folgt wieder die erste.")


func test_pfeil_hoch_laeuft_reihum() -> void:
	# Arrange: Gewählt ist „Neues Spiel“, die Startauswahl.

	# Act
	var auswahl := _auswahl_nach_jedem_druck(KEY_UP)

	# Assert
	assert_eq(auswahl, [3, 2, 1, 0],
		"Vor der ersten Zeile kommt die letzte, nicht der fremde Button oben rechts.")


func test_tab_laeuft_wie_pfeil_runter() -> void:
	# Arrange: Gewählt ist „Neues Spiel“, die Startauswahl.

	# Act
	var auswahl := _auswahl_nach_jedem_druck(KEY_TAB)

	# Assert
	assert_eq(auswahl, [1, 2, 3, 0],
		"Tab wählt wie Pfeil runter und springt nach der letzten Zeile nicht aus dem Menü.")


func test_shift_tab_laeuft_wie_pfeil_hoch() -> void:
	# Arrange: Gewählt ist „Neues Spiel“, die Startauswahl.

	# Act
	var auswahl := _auswahl_nach_jedem_druck(KEY_TAB, true)

	# Assert
	assert_eq(auswahl, [3, 2, 1, 0],
		"Shift+Tab wählt wie Pfeil hoch und springt vor der ersten Zeile nicht aus dem Menü.")


# --- Maus -----------------------------------------------------------------

func test_rechtsklick_waehlt_die_zeile_und_loest_nichts_aus() -> void:
	# Arrange: Die Maus steht schon auf „Beenden“, gewählt ist aber „Spiel laden“. So
	# kann nur der Rechtsklick die Zeile wählen, nicht schon das Überfahren.
	var beenden := _mitte(3)
	_maus_nach(beenden)
	_menu.select(1)
	watch_signals(_menu)

	# Act
	_klick(beenden, MOUSE_BUTTON_RIGHT)

	# Assert
	assert_eq(_menu.selected_index(), 3, "Der Rechtsklick wählt die Zeile unter der Maus.")
	assert_signal_not_emitted(_menu, "entry_activated",
		"Ein Rechtsklick löst nichts aus, auch nicht auf einem verfügbaren Eintrag.")


func test_mauszeiger_zeigt_die_hand_nur_ueber_verfuegbaren_eintraegen() -> void:
	# Act
	var zeiger := _zeilen().map(
		func(zeile: Button) -> Control.CursorShape: return zeile.mouse_default_cursor_shape)

	# Assert
	assert_eq(zeiger, [Control.CURSOR_ARROW, Control.CURSOR_ARROW, Control.CURSOR_ARROW,
		Control.CURSOR_POINTING_HAND], "Die Hand nur über „Beenden“, sonst der Pfeil.")


# --- Darstellung ----------------------------------------------------------

# Geprüft wird die Schrift, über den Zustand des Buttons und die Farbe aus dem Theme. Den
# Pfeil malt _draw(); headless entsteht dabei kein Bild, das ein Test ansehen könnte.
# Seine Farbe prüft Klaus mit dem Auge (T042).
func test_gesperrte_zeilen_sind_ausgewaehlt_so_gedaempft_wie_in_ruhe() -> void:
	for index: int in [0, 1, 2]:
		# Arrange: in Ruhe, gewählt ist „Beenden“.
		var zeile := _zeilen()[index] as Button
		_menu.select(3)
		var in_ruhe := zeile.get_draw_mode()

		# Act
		_menu.select(index)

		# Assert: Ein gesperrter Button bleibt auch mit Fokus im Zustand DRAW_DISABLED,
		# und darin nimmt Godot font_disabled_color aus dem Theme.
		assert_true(zeile.has_focus(), "Voraussetzung: „%s“ ist gewählt." % zeile.text)
		assert_eq([in_ruhe, zeile.get_draw_mode()],
			[BaseButton.DRAW_DISABLED, BaseButton.DRAW_DISABLED],
			"„%s“ wird in Ruhe und ausgewählt als gesperrt gezeichnet." % zeile.text)
		assert_eq(zeile.get_theme_color(&"font_disabled_color"), UiPalette.GEHAEUSE_DUNKEL,
			"Die Schrift gesperrter Zeilen ist gehaeuse-dunkel.")


# --- Lochrand (Style-Guide, Bildrahmen) ----------------------------------

# Die Löcher malt _draw() über MenuPaper; headless entsteht kein Bild. Geprüft werden die
# Lochmitten, die draw_paper() malt. Ein Loch mit Mitte y belegt die Pixelreihen y − 2 bis y + 1.

func test_lochrand_bei_fuenf_zeilen_wie_bisher() -> void:
	# Act: Kopfzeile und vier Einträge, 100 hoch.
	var mitten := MenuPaper.hole_centers(_menu.size.y)

	# Assert
	assert_eq(_menu.size.y, 5.0 * MainMenu.ROW_HEIGHT, "Voraussetzung: fünf Zeilen.")
	assert_eq(mitten, [10, 22, 34, 46, 58, 70, 82, 94],
		"Acht Löcher wie bisher; unter dem letzten (Reihen 92 bis 95) liegen noch 4 Pixel Papier.")


func test_lochrand_bei_sechs_zeilen_ohne_loch_an_der_unterkante() -> void:
	# Arrange: fünf Einträge wie das Hauptmenü aus Feature 004, 120 hoch.
	var neu := _eintraege()
	neu.push_front(_eintrag(&"continue", "Weiterspielen", true, "Weiter."))
	_menu.set_entries(neu, 0)

	# Act
	var mitten := MenuPaper.hole_centers(_menu.size.y)

	# Assert
	assert_eq(_menu.size.y, 6.0 * MainMenu.ROW_HEIGHT, "Voraussetzung: sechs Zeilen.")
	assert_eq(mitten, [10, 22, 34, 46, 58, 70, 82, 94, 106],
		"Das Loch bei 118 (Reihen 116 bis 119) berührte die Unterkante und entfällt.")


func test_kein_loch_beruehrt_die_unterkante() -> void:
	for zeilen in range(1, 10):
		# Arrange
		var hoehe := zeilen * MenuPaper.ROW_HEIGHT

		# Act
		var mitten := MenuPaper.hole_centers(hoehe)

		# Assert: Unter dem untersten Loch bleibt Papier, und das nächste Loch passte nicht mehr.
		var letztes: int = mitten.back()
		assert_lt(letztes + MenuPaper.HOLE_RADIUS, hoehe,
			"%d Zeilen: Unter dem untersten Loch liegt Papier." % zeilen)
		assert_gte(letztes + MenuPaper.HOLE_SPACING + MenuPaper.HOLE_RADIUS, hoehe,
			"%d Zeilen: Kein weiteres Loch hätte noch Platz." % zeilen)
	# Bei 3, 6 und 9 Zeilen fiele das unterste Loch genau auf die Unterkante.
	assert_eq(MenuPaper.hole_centers(60).back(), 46, "3 Zeilen: ohne das Loch bei 58.")
	assert_eq(MenuPaper.hole_centers(180).back(), 166, "9 Zeilen: ohne das Loch bei 178.")


# --- Kopfzeile, Breite, Einträge zur Laufzeit (Feature 004) ---------------

func test_kopfzeile_zeigt_header_text() -> void:
	# Arrange
	var kopfzeile := _menu.get_node(^"Rows/Header") as Label
	var vorher := kopfzeile.text

	# Act
	_menu.header_text = "SCHWIERIGKEIT"

	# Assert
	assert_eq(vorher, "HAUPTMENÜ", "Ohne Angabe steht HAUPTMENÜ da, wie bisher.")
	assert_eq(kopfzeile.text, "SCHWIERIGKEIT", "Die Kopfzeile folgt header_text sofort.")


func test_header_text_vor_dem_erscheinen_gilt_beim_erscheinen() -> void:
	# Arrange
	var menue := MENU_SCENE.instantiate() as MainMenu
	menue.header_text = "LÖSCHEN?"

	# Act
	add_child_autofree(menue)

	# Assert
	assert_eq((menue.get_node(^"Rows/Header") as Label).text, "LÖSCHEN?")


func test_breite_ist_paper_width() -> void:
	# Arrange
	var vorher := _menu.size
	watch_signals(_menu)

	# Act
	_menu.paper_width = 304
	_menu.select(2)

	# Assert
	assert_eq(vorher, Vector2(MainMenu.PAPER_WIDTH, 5 * MainMenu.ROW_HEIGHT),
		"Ohne Angabe ist das Papier PAPER_WIDTH breit und so hoch wie Kopfzeile und Einträge.")
	assert_eq(_menu.size, Vector2(304, 5 * MainMenu.ROW_HEIGHT), "Danach ist es 304 breit.")
	var parameter: Array = get_signal_parameters(_menu, "selection_changed")
	assert_eq((parameter[1] as Rect2).size.x, 304.0,
		"Die gemeldete Zeile reicht über das ganze Papier.")


func test_set_entries_baut_die_zeilen_neu_und_waehlt_vor() -> void:
	# Arrange: fünf Einträge wie das Hauptmenü aus Feature 004, vorgewählt die zweite Zeile.
	var neu := _eintraege()
	neu.push_front(_eintrag(&"continue", "Weiterspielen", true,
		"Weiter mit Spiel 2, Schwer, am 14.03.1986."))
	watch_signals(_menu)

	# Act
	_menu.set_entries(neu, 1)

	# Assert: sofort, ohne auf ein Bild zu warten.
	var texte := _zeilen().map(func(zeile: Button) -> String: return zeile.text)
	assert_eq(texte, ["Weiterspielen", "Neues Spiel", "Spiel laden", "Einstellungen", "Beenden"],
		"Die alten Zeilen sind weg, die neuen stehen in der Reihenfolge der Einträge.")
	assert_eq(_menu.selected_index(), 1, "Vorgewählt ist die angegebene Zeile.")
	assert_eq(_menu.selected_entry().id, &"new_game")
	assert_eq(_menu.get_viewport().gui_get_focus_owner(), _zeilen()[1],
		"Die Vorwahl ist der Fokus.")
	assert_signal_emitted_with_parameters(_menu, "selection_changed", [neu[1],
		Rect2(_menu.global_position + Vector2(0, 2 * MainMenu.ROW_HEIGHT),
			Vector2(MainMenu.PAPER_WIDTH, MainMenu.ROW_HEIGHT))])
	assert_eq(_menu.size, Vector2(MainMenu.PAPER_WIDTH, 6 * MainMenu.ROW_HEIGHT),
		"Das Papier wächst um eine Zeile.")


func test_set_entries_mit_weniger_eintraegen_schrumpft_das_papier() -> void:
	# Arrange: vier Einträge wie die Gradwahl.
	var neu: Array[MenuEntry] = [
		_eintrag(&"easy", "Leicht", true, "Das Glück ist eher auf deiner Seite."),
		_eintrag(&"medium", "Mittel", true, "Das Glück hält sich raus."),
		_eintrag(&"hard", "Schwer", true, "Das Glück ist eher auf der Seite der anderen."),
	]

	# Act
	_menu.set_entries(neu, 1)

	# Assert
	assert_eq(_menu.size, Vector2(MainMenu.PAPER_WIDTH, 4 * MainMenu.ROW_HEIGHT))
	assert_eq(_zeilen().size(), 3, "Keine alte Zeile bleibt stehen.")


func test_nach_set_entries_laufen_tasten_und_maus_wie_vorher() -> void:
	# Arrange
	var neu := _eintraege()
	neu.push_front(_eintrag(&"continue", "Weiterspielen", true, "Weiter."))
	_menu.set_entries(neu, 0)
	# Ein Bild warten: Erst dann hat der VBoxContainer die neuen Buttons angeordnet, und die
	# Maus trifft sie dort, wo sie zu sehen sind.
	await wait_process_frames(1)
	watch_signals(_menu)

	# Act und Assert: Die Enden sind neu verbunden, und die Maus wählt die neue Zeile.
	_taste(KEY_UP)
	assert_eq(_menu.selected_index(), 4, "Vor der ersten Zeile kommt die neue letzte.")
	_taste(KEY_DOWN)
	assert_eq(_menu.selected_index(), 0, "Nach der letzten Zeile kommt wieder die erste.")
	_maus_nach(_mitte(4))
	_klick(_mitte(4), MOUSE_BUTTON_LEFT)
	assert_eq(_menu.selected_index(), 4, "Überfahren wählt die neue Zeile „Beenden“.")
	assert_signal_emitted_with_parameters(_menu, "entry_activated", [&"quit"])


func test_set_entries_vor_dem_erscheinen_waehlt_beim_erscheinen_vor() -> void:
	# Arrange
	var menue := MENU_SCENE.instantiate() as MainMenu
	menue.set_entries(_eintraege(), 3)

	# Act
	add_child_autofree(menue)
	await wait_process_frames(1)

	# Assert
	assert_eq(menue.selected_index(), 3, "Die Vorwahl gilt, sobald das Menü erscheint.")
	assert_eq(menue.size.y, 5.0 * MainMenu.ROW_HEIGHT)


func test_unsichtbares_menue_nimmt_keinen_fokus() -> void:
	# Arrange: Ein zweites Blatt liegt unsichtbar neben dem Menü, wie später die Gradwahl.
	var blatt := MENU_SCENE.instantiate() as MainMenu
	blatt.visible = false
	blatt.entries = _eintraege()
	_menu.get_parent().add_child(blatt)
	await wait_process_frames(1)
	watch_signals(blatt)

	# Act
	blatt.select(2)
	blatt.set_entries(_eintraege(), 1)

	# Assert
	assert_eq(_menu.get_viewport().gui_get_focus_owner(), _zeilen()[0],
		"Der Fokus bleibt im sichtbaren Menü, auch nach der Startauswahl des Blatts.")
	assert_eq(blatt.selected_index(), 1, "Das Blatt merkt sich die Zeile trotzdem.")
	assert_signal_not_emitted(blatt, "selection_changed",
		"Unsichtbar meldet es keine Auswahl, sonst stünde ein Hinweis neben nichts.")


# --- Auf der Anzeige (Feature 005, T014) ---------------------------------

func test_papier_ohne_override_der_schrift() -> void:
	# Act: die verfügbare Zeile wählen, auf Papier.
	_menu.select(3)

	# Assert: Auf Papier kommt jede Farbe aus MenuRow; der Titel bleibt, wie er ist.
	assert_true(_menu._draws_paper(), "Auf Papier malt das Menü Papier.")
	for zeile: Button in _zeilen():
		for farbe in MainMenu.LIT_FONT_COLORS:
			assert_false(zeile.has_theme_color_override(farbe),
				"„%s“ hat auf Papier keinen Override %s." % [zeile.text, farbe])
	assert_eq(_menu.size, Vector2(MainMenu.PAPER_WIDTH, 5 * MainMenu.ROW_HEIGHT))


func test_lcd_ohne_papier_mit_den_varianten_der_anzeige() -> void:
	# Arrange und Act
	await _auf_der_anzeige()

	# Assert
	assert_false(_menu._draws_paper(), "Auf der Anzeige kein Papier, keine Lochränder.")
	assert_eq((_menu.get_node(^"Rows/Header") as Label).theme_type_variation, &"LcdHeader")
	for zeile: Button in _zeilen():
		assert_eq(zeile.theme_type_variation, &"LcdRow", "„%s“ ist eine LcdRow." % zeile.text)
	var zeilen := _menu.get_node(^"Rows") as Control
	assert_eq([zeilen.offset_left, zeilen.offset_right],
		[float(MenuPaper.LCD_ROW_INSET), -float(MenuPaper.LCD_ROW_INSET)],
		"Der Innenbereich beginnt 4 vom Rand und endet 4 davor.")
	assert_eq((_zeilen()[0] as Button).global_position.x
		+ (_zeilen()[0] as Button).get_theme_stylebox(&"normal").content_margin_left,
		float(MenuPaper.LCD_TEXT_INSET), "Der Text beginnt bei x 16.")


func test_lcd_groesse_kommt_von_aussen() -> void:
	# Arrange
	await _auf_der_anzeige()

	# Act: Was auf Papier die Größe setzt, darf sie auf der Anzeige nicht ändern.
	var neu := _lcd_eintraege()
	neu.append(_eintrag(&"vier", "Vier", true, "Vier."))
	_menu.set_entries(neu, 0)
	_menu.paper_width = 144

	# Assert
	assert_eq(_menu.size, ANZEIGE, "Die Seite bleibt so groß wie die Anzeige.")
	assert_eq(_menu.custom_minimum_size, Vector2.ZERO, "Keine Mindestgröße überstimmt sie.")


func test_lcd_auswahl_ist_invertiert() -> void:
	# Arrange
	await _auf_der_anzeige()

	# Act: Pfeil runter auf „Zwei“.
	_taste(KEY_DOWN)

	# Assert: Schrift der gewählten Zeile lcd, die übrigen tusche.
	assert_eq(_menu.selected_index(), 1)
	assert_eq(_schriftfarben(), [UiPalette.TUSCHE, UiPalette.LCD, UiPalette.GEHAEUSE_DUNKEL])
	# Balken und Pfeil, wie _draw() sie malt.
	var ebenen := MenuPaper.lcd_selection_layers(_menu.size.x, 2, true)
	assert_eq(ebenen[0], {"rect": Rect2(4, 40, ANZEIGE.x - 8, 20), "color": UiPalette.TUSCHE},
		"Balken in tusche über den Innenbereich, ganze Zeilenhöhe.")
	for spalte: Dictionary in ebenen.slice(1):
		assert_eq(spalte["color"], UiPalette.LCD, "Der Pfeil ist lcd.")
	assert_eq((ebenen[1]["rect"] as Rect2).position, Vector2(MenuPaper.LCD_ARROW_X, 46),
		"Pfeil bei x 8, in der Zeile wie auf Papier.")
	assert_eq(ebenen.size(), 1 + MenuPaper.ARROW_WIDTH, "Balken und vier Spalten Pfeil.")


func test_lcd_maus_auf_a_pfeil_auf_b() -> void:
	# Arrange: Die Maus steht auf „Eins“ und wählt sie.
	await _auf_der_anzeige()
	_maus_nach(_mitte(0))

	# Act: Pfeil runter wählt „Zwei“; die Maus bleibt auf „Eins“.
	_taste(KEY_DOWN)

	# Assert: „Eins“ ist unter der Maus, aber nicht gewählt, und bleibt tusche (Analyse, B1).
	var eins := _zeilen()[0] as Button
	assert_eq(eins.get_draw_mode(), BaseButton.DRAW_HOVER, "Voraussetzung: „Eins“ unter der Maus.")
	assert_eq(_menu.selected_index(), 1)
	assert_eq(_schriftfarben(), [UiPalette.TUSCHE, UiPalette.LCD, UiPalette.GEHAEUSE_DUNKEL],
		"A unter der Maus tusche, B gewählt lcd.")


func test_lcd_gewaehlt_unter_der_maus_bleibt_hell() -> void:
	# Arrange
	await _auf_der_anzeige()

	# Act: Die Maus fährt auf „Zwei“ und wählt sie.
	_maus_nach(_mitte(1))

	# Assert
	assert_eq((_zeilen()[1] as Button).get_draw_mode(), BaseButton.DRAW_HOVER)
	assert_eq(_schriftfarben(), [UiPalette.TUSCHE, UiPalette.LCD, UiPalette.GEHAEUSE_DUNKEL])


func test_lcd_gewaehlt_und_nicht_verfuegbar_bleibt_gedaempft() -> void:
	# Arrange
	await _auf_der_anzeige()

	# Act: „Drei“ ist nicht verfügbar.
	_menu.select(2)

	# Assert
	assert_eq(_schriftfarben(), [UiPalette.TUSCHE, UiPalette.TUSCHE, UiPalette.GEHAEUSE_DUNKEL],
		"Gewählt und nicht verfügbar: gehaeuse-dunkel, die vorige Zeile wieder tusche.")
	var ebenen := MenuPaper.lcd_selection_layers(_menu.size.x, 3, false)
	assert_eq(ebenen[0]["color"], UiPalette.TUSCHE, "Der Balken bleibt tusche.")
	for spalte: Dictionary in ebenen.slice(1):
		assert_eq(spalte["color"], UiPalette.GEHAEUSE_DUNKEL, "Der Pfeil ist gedämpft.")


func test_lcd_bedienung_und_signale_wie_auf_papier() -> void:
	# Arrange
	await _auf_der_anzeige()
	watch_signals(_menu)

	# Act und Assert: Pfeile laufen um, Enter löst nur Verfügbares aus, Rechtsklick wählt nur.
	assert_eq(_auswahl_nach_jedem_druck(KEY_DOWN), [1, 2, 0], "Pfeil runter läuft reihum.")
	assert_eq(_auswahl_nach_jedem_druck(KEY_UP), [2, 1, 0], "Pfeil hoch läuft reihum.")
	_taste(KEY_ENTER)
	assert_signal_emitted_with_parameters(_menu, "entry_activated", [&"eins"])
	_menu.select(2)
	_taste(KEY_ENTER)
	assert_signal_emit_count(_menu, "entry_activated", 1, "„Drei“ ist nicht verfügbar.")
	_maus_nach(_mitte(0))
	_menu.select(1)
	_klick(_mitte(0), MOUSE_BUTTON_RIGHT)
	assert_eq(_menu.selected_index(), 0, "Der Rechtsklick wählt.")
	assert_signal_emit_count(_menu, "entry_activated", 1, "Der Rechtsklick löst nichts aus.")
	_maus_nach(_mitte(1))
	_klick(_mitte(1), MOUSE_BUTTON_LEFT)
	assert_signal_emitted_with_parameters(_menu, "entry_activated", [&"zwei"])
	var parameter: Array = get_signal_parameters(_menu, "selection_changed")
	assert_eq(parameter[1], Rect2(Vector2(0, 2 * MainMenu.ROW_HEIGHT),
		Vector2(ANZEIGE.x, MainMenu.ROW_HEIGHT)), "Die gemeldete Zeile reicht über die Anzeige.")


func test_look_spaeter_setzen_baut_die_zeilen_neu() -> void:
	# Arrange: das Papiermenü aus before_each, gewählt „Beenden“.
	_menu.select(3)

	# Act: auf die Anzeige …
	_menu.look = MainMenu.Look.LCD

	# Assert
	assert_eq(_zeilen().map(func(zeile: Button) -> StringName: return zeile.theme_type_variation),
		[&"LcdRow", &"LcdRow", &"LcdRow", &"LcdRow"], "Die Zeilen sind neu gebaut.")
	assert_eq(_menu.selected_index(), 3, "Die Auswahl bleibt auf ihrer Zeile.")
	assert_eq((_zeilen()[3] as Button).get_theme_color(&"font_focus_color"), UiPalette.LCD)

	# Act: … und zurück aufs Papier.
	_menu.look = MainMenu.Look.PAPER

	# Assert
	assert_eq((_menu.get_node(^"Rows/Header") as Label).theme_type_variation, &"MenuHeader")
	assert_eq((_zeilen()[3] as Button).theme_type_variation, &"MenuRow")
	assert_false((_zeilen()[3] as Button).has_theme_color_override(&"font_focus_color"))
	assert_eq(_menu.size, Vector2(MainMenu.PAPER_WIDTH, 5 * MainMenu.ROW_HEIGHT),
		"Auf Papier setzt das Menü seine Größe wieder selbst.")
	assert_eq(_menu.selected_index(), 3)


# --- Helfer ---------------------------------------------------------------

## Die Buttons des Menüs, in der Reihenfolge, in der sie im Baum stehen. Sie entstehen
## im Code und haben deshalb keinen Owner; ohne owned = false fände die Suche keinen.
func _zeilen() -> Array[Node]:
	return _menu.find_children("*", "Button", true, false)


## Die Mitte von Zeile [param index], in Viewport-Koordinaten.
func _mitte(index: int) -> Vector2:
	return (_zeilen()[index] as Button).get_global_rect().get_center()


## Drückt [param taste] so oft, wie das Menü Zeilen hat, also eine ganze Runde, und merkt
## sich nach jedem Druck die gewählte Zeile.
func _auswahl_nach_jedem_druck(taste: Key, shift := false) -> Array[int]:
	var auswahl: Array[int] = []
	for _druck in _menu.entries.size():
		_taste(taste, shift)
		auswahl.append(_menu.selected_index())
	return auswahl


## Drückt [param taste] und lässt sie los. Die Ereignisse gehen über push_input in den
## Viewport, denselben Eingang, über den auch das Fenster echte Tastendrücke weitergibt.
## Godot macht daraus ui_down, ui_focus_next und so weiter und verschiebt den Fokus selbst.
func _taste(taste: Key, shift := false) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventKey.new()
		ereignis.keycode = taste
		ereignis.physical_keycode = taste
		ereignis.shift_pressed = shift
		ereignis.pressed = gedrueckt
		_menu.get_viewport().push_input(ereignis)


## Fährt mit der Maus nach [param ziel], ebenfalls über push_input. Das zweite Argument
## true sagt: Die Koordinaten gelten schon im Viewport, so wie get_global_rect() sie
## liefert, und müssen nicht erst aus Fensterpixeln umgerechnet werden.
func _maus_nach(ziel: Vector2) -> void:
	var ereignis := InputEventMouseMotion.new()
	ereignis.position = ziel
	ereignis.global_position = ziel
	_menu.get_viewport().push_input(ereignis, true)


## Klickt mit [param taste] bei [param ziel]: drücken und loslassen.
func _klick(ziel: Vector2, taste: MouseButton) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = taste
		ereignis.position = ziel
		ereignis.global_position = ziel
		ereignis.pressed = gedrueckt
		_menu.get_viewport().push_input(ereignis, true)


## Die vier Einträge mit den Werten aus dem Datenmodell.
func _eintraege() -> Array[MenuEntry]:
	return [
		_eintrag(&"new_game", "Neues Spiel", false,
			"Der Laden hat noch zu. Bald kannst du ihn eröffnen."),
		_eintrag(&"load_game", "Spiel laden", false,
			"Noch keine Spielstände. Speichern kommt bald."),
		_eintrag(&"settings", "Einstellungen", false,
			"Noch nichts einzustellen. Kommt später."),
		_eintrag(&"quit", "Beenden", true,
			"Laden abschließen und zurück zum Desktop."),
	]


func _eintrag(id: StringName, label: String, available: bool, hint: String) -> MenuEntry:
	var entry := MenuEntry.new()
	entry.id = id
	entry.label = label
	entry.available = available
	entry.hint = hint
	return entry


## Ersetzt das Menü dieses Tests durch eines auf der Anzeige: look = LCD, drei Einträge („Drei“
## nicht verfügbar), so groß wie die Anzeige des Communicators, in einem eigenen Viewport. Die
## Helfer oben gelten dann für dieses Menü. Wartet ein Bild für Startauswahl und Anordnung.
func _auf_der_anzeige() -> void:
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	_menu = MENU_SCENE.instantiate() as MainMenu
	_menu.look = MainMenu.Look.LCD
	_menu.entries = _lcd_eintraege()
	eigener_viewport.add_child(_menu)
	# Das täte der Communicator in add_page().
	_menu.size = ANZEIGE
	await wait_process_frames(1)


func _lcd_eintraege() -> Array[MenuEntry]:
	return [
		_eintrag(&"eins", "Eins", true, "Eins."),
		_eintrag(&"zwei", "Zwei", true, "Zwei."),
		_eintrag(&"drei", "Drei", false, "Geht noch nicht."),
	]


## Die Schriftfarbe jeder Zeile, wie Godots Button sie für seinen Zustand wählt: gesperrt
## font_disabled_color, unter der Maus font_hover_color, gedrückt font_pressed_color, sonst mit
## Fokus font_focus_color und ohne font_color. Headless entsteht kein Bild; so sieht der Test, was
## die Zeile zeigen würde.
func _schriftfarben() -> Array[Color]:
	var farben: Array[Color] = []
	for knoten in _zeilen():
		var zeile := knoten as Button
		var farbname: StringName = &"font_focus_color" if zeile.has_focus() else &"font_color"
		match zeile.get_draw_mode():
			BaseButton.DRAW_DISABLED:
				farbname = &"font_disabled_color"
			BaseButton.DRAW_HOVER:
				farbname = &"font_hover_color"
			BaseButton.DRAW_PRESSED:
				farbname = &"font_pressed_color"
			BaseButton.DRAW_HOVER_PRESSED:
				farbname = &"font_hover_pressed_color"
		farben.append(zeile.get_theme_color(farbname))
	return farben
