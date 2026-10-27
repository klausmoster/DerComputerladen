extends GutTest

## Prüft das Blatt SPIELSTÄNDE (Feature 004, T025; contracts/titelbildschirm.md, „SaveList“ und
## „Tests“; Style-Guide, Baustein Liste): die Spalten und ihre Anfänge, die Reihenfolge, gedämpfte
## Zeilen mit ihrem Zustand, im Löschmodus verfügbar, den gekürzten Namen, das Rollen mit 7 und 20
## Spielständen samt Rollmarken, den Löschmodus mit Kopfzeile und Hinweisen, auch „Zurück“, die
## Hinweise je Zeile, was jede Zeile auslöst, Tastatur, Maus und Mauszeiger.
##
## Die Spielstände entstehen hier als SaveSlot-Objekte im Speicher, ohne Dateien: Geprüft wird die
## Liste, nicht das Lesen. Was SaveStore und SaveSlot aus Dateien machen, prüfen test_save_store.gd
## und test_save_game.gd.
##
## Seit Feature 005 (T015) dazu: die Liste auf der Anzeige des Communicators (look = LCD). Die Tests
## dazu bauen eine eigene Liste in einem eigenen Viewport, so groß wie die Anzeige, wie der
## Communicator sie hinstellt; alle Tests davor laufen unverändert auf Papier.
##
## Wie in test_main_menu.gd steht die Liste in einem eigenen Viewport, neben einem fremden Button,
## und Tasten und Klicks gehen über push_input wie echte Eingaben. Das Ende des Löschmodus auf allen
## vier Wegen prüft test_title_screen.gd mit T027, denn beenden kann ihn nur der Titelbildschirm; hier
## steht, was die Liste selbst dazu tut: set_delete_mode(false) und show_slots() nach dem Löschen.

const LISTE := preload("res://scenes/title/save_list.tscn")
## 26.10.2026, 20:40:12 UTC; jeder weitere Spielstand ist eine Stunde früher gespielt.
const ZULETZT := 1793047212
const STUNDE := 3600
const ZEILE := SaveList.ROW_HEIGHT
## Größe der Anzeige des Communicators (Style-Guide, Baustein Communicator).
const ANZEIGE := Vector2(384, 192)
## Die Spalten einer fortsetzbaren Zeile.
const SPALTEN: Array[StringName] = [&"Name", &"Difficulty", &"Day", &"Played"]

## Die Sätze für den Spieler, hier ausgeschrieben statt als Konstanten aus dem Code: So fällt jede
## Änderung hier auf.
const HINWEIS_LOESCHEN := "Einen Spielstand löschen. Vorher kommt eine Rückfrage."
const HINWEIS_LOESCHEN_IM_MODUS := "Wähl oben den Spielstand, der weg soll. Esc bricht ab."
const HINWEIS_ZURUECK := "Zurück zum Hauptmenü. Esc geht auch."
const HINWEIS_ZURUECK_IM_MODUS := "Nicht löschen. Esc geht auch."
const GRUND_BESCHAEDIGT := "Lässt sich nicht lesen: Die Datei ist beschädigt."
const GRUND_ZU_NEU := "Mit einer neueren Version gespeichert."

var _liste: SaveList


func before_each() -> void:
	_liste = LISTE.instantiate() as SaveList
	# Ein eigener Viewport wie in test_main_menu.gd: eigene Eingabe, eigener Fokus, und GUTs
	# Oberfläche fängt keine Klicks ab.
	var eigener_viewport := SubViewport.new()
	add_child_autofree(eigener_viewport)
	var buehne := Control.new()
	eigener_viewport.add_child(buehne)
	buehne.add_child(_liste)
	# Ein fremder Button oben rechts daneben: Pfeiltasten und Tab dürfen nie dorthin.
	var fremder_button := Button.new()
	fremder_button.position = Vector2(SaveList.PAPER_WIDTH + 40, 0)
	buehne.add_child(fremder_button)
	# Die Maus steht im Viewport. Im Fenster meldet das das Betriebssystem; ohne diese Meldung gibt
	# ein Viewport Mausbewegungen nicht an gui_input weiter, nur mouse_entered käme an.
	eigener_viewport.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)
	await wait_process_frames(1)


# --- Werte und Aufbau -----------------------------------------------------------------------------

func test_werte_aus_dem_style_guide() -> void:
	# Assert: Style-Guide, Baustein Liste.
	assert_eq(SaveList.VISIBLE_ROWS, 6, "Höchstens 6 Zeilen mit Spielständen.")
	assert_eq(Array(SaveList.COLUMNS), [0, 64, 108, 172], "Spalten ab dem Text der Zeile.")
	assert_eq(SaveList.PAPER_WIDTH, 304, "Das Papier ist 304 breit.")


func test_drei_spielstaende_mit_allen_spalten_in_ihrer_reihenfolge() -> void:
	# Arrange
	var spielstaende := _drei()

	# Act
	await _zeige(spielstaende)

	# Assert
	assert_eq(_sichtbare_namen(), ["Spiel 7", "Spiel 6", "Spiel 5"],
		"Je Spielstand eine Zeile, in der übergebenen Reihenfolge.")
	assert_eq(_zellen(0), ["Spiel 7", "Schwer", "14.03.1986", SaveGame.time_text(ZULETZT)])
	assert_eq(_zellen(1), ["Spiel 6", "Mittel", "01.01.1985",
		SaveGame.time_text(ZULETZT - STUNDE)])
	assert_eq(_zellen(2), ["Spiel 5", "Leicht", "02.07.1991",
		SaveGame.time_text(ZULETZT - 2 * STUNDE)])
	assert_false(_zelle(0, &"State").visible, "Fortsetzbar: kein Zustand.")
	assert_eq([_knopf("DeleteMode").text, _knopf("Back").text], ["Löschen …", "Zurück"],
		"Darunter immer „Löschen …“ und „Zurück“.")
	assert_eq(_kopfzeile(), "SPIELSTÄNDE")
	assert_eq(_liste.size, Vector2(304, 6 * ZEILE),
		"Kopfzeile, drei Spielstände und zwei feste Zeilen, 304 breit.")
	assert_false(_liste._more_above() or _liste._more_below(), "Keine Rollmarke.")


func test_reihenfolge_ist_die_uebergebene() -> void:
	# Arrange: Die Ordnung macht SaveStore; die Liste ordnet nicht um.
	var spielstaende: Array[SaveSlot] = [_spielstand(3, Difficulty.Level.LEICHT, 0, ZULETZT),
		_spielstand(9, Difficulty.Level.MITTEL, 0, ZULETZT - STUNDE), _beschaedigt(12),
		_beschaedigt(1)]

	# Act
	await _zeige(spielstaende)

	# Assert
	assert_eq(_sichtbare_namen(), ["Spiel 3", "Spiel 9", "Spiel 12", "Spiel 1"])


func test_spalten_beginnen_an_ihren_festen_anfaengen() -> void:
	# Arrange
	await _zeige([_spielstand(7, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ZULETZT),
		_beschaedigt(4)])

	# Act: wo jede Spalte steht, gemessen vom linken Rand des Papiers.
	var anfaenge: Array[float] = []
	for zelle: StringName in [&"Name", &"Difficulty", &"Day", &"Played"]:
		anfaenge.append(_links(_zelle(0, zelle)))
	var zustand := _links(_zelle(1, &"State"))

	# Assert: Text ab 24, Spalten bei 0, 64, 108 und 172 ab dem Text (Style-Guide).
	assert_eq(anfaenge, [24.0, 88.0, 132.0, 196.0])
	assert_eq(zustand, 88.0, "Der Zustand steht, wo sonst der Grad steht.")
	for zeile in 2:
		var oben := _zelle(zeile, &"Name").global_position.y - _liste.global_position.y
		assert_eq(oben, float(ZEILE * (zeile + 1)), "Zeile %d steht unter der Kopfzeile." % zeile)


func test_jede_angabe_passt_in_ihr_feld() -> void:
	# Arrange
	await _zeige(_drei())
	var schrift := _zelle(0, &"Name").get_theme_font(&"font")
	var groesse := _zelle(0, &"Name").get_theme_font_size(&"font_size")
	# Ziffern sind in Ark Pixel 12 gleich breit; jedes Datum ist so breit wie dieses.
	var laengste := {
		&"Name": "Spiel 9999", &"Difficulty": "Schwer", &"Day": "14.03.1986",
		&"Played": "26.10.2026 21:40", &"State": "neuere Version",
	}
	# Wo das Feld samt 6 Luft spätestens endet: an der nächsten Spalte, die letzte 12 vor dem Rand.
	# Der Zustand reicht über Grad und Spieldatum.
	var grenze := {
		&"Name": 24.0 + 64.0, &"Difficulty": 24.0 + 108.0, &"Day": 24.0 + 172.0,
		&"Played": 304.0 - 12.0, &"State": 24.0 + 172.0,
	}

	for zelle: StringName in laengste:
		# Act
		var feld := _zelle(0, zelle)
		var breite := schrift.get_string_size(laengste[zelle], HORIZONTAL_ALIGNMENT_LEFT, -1,
			groesse).x

		# Assert
		assert_lte(breite, feld.size.x, "„%s“ passt in %s." % [laengste[zelle], zelle])
		assert_eq(_links(feld) + feld.size.x + SaveList.COLUMN_GAP, grenze[zelle],
			"Hinter %s bleiben 6 Luft bis zur Grenze." % zelle)


func test_name_ab_spiel_10000_wird_mit_auslassung_gekuerzt() -> void:
	# Arrange
	await _zeige([_spielstand(10000, Difficulty.Level.SCHWER, 0, ZULETZT),
		_spielstand(9999, Difficulty.Level.SCHWER, 0, ZULETZT)])
	var name := _zelle(0, &"Name")
	var schrift := name.get_theme_font(&"font")
	var groesse := name.get_theme_font_size(&"font_size")

	# Act
	var breit := schrift.get_string_size("Spiel 10000", HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x
	var passt := schrift.get_string_size("Spiel 9999", HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x

	# Assert: Das Label kürzt selbst; geprüft wird, dass es kürzen muss und wie.
	assert_eq(name.text, "Spiel 10000", "Der volle Name steht im Label.")
	assert_eq(name.size.x, 58.0, "Das Feld bleibt 58 breit: Spalte 64 ohne 6 Luft.")
	assert_gt(breit, name.size.x, "„Spiel 10000“ passt nicht und wird gekürzt.")
	assert_lte(passt, name.size.x, "„Spiel 9999“ passt ungekürzt.")
	assert_eq(name.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS,
		"Gekürzt wird zeichenweise mit Auslassungszeichen.")
	assert_eq(name.ellipsis_char, "…", "Das Auslassungszeichen ist „…“, nicht drei Punkte.")


func test_nicht_fortsetzbare_zeilen_sind_gedaempft_und_nennen_ihren_zustand() -> void:
	# Arrange
	await _zeige([_spielstand(2, Difficulty.Level.SCHWER, 0, ZULETZT), _beschaedigt(4),
		_zu_neu(3)])

	# Assert: Name und Zustand, keine Angaben in Grad, Spieldatum und zuletzt gespielt.
	assert_eq(_zellen(1), ["Spiel 4", "beschädigt"])
	assert_eq(_zellen(2), ["Spiel 3", "neuere Version"])
	# Gedämpft wie ein nicht verfügbarer Eintrag im Menü; fortsetzbare in tusche.
	for zelle: StringName in [&"Name", &"State"]:
		assert_eq(_zelle(1, zelle).get_theme_color(&"font_color"), UiPalette.GEHAEUSE_DUNKEL,
			"Beschädigt: %s gedämpft." % zelle)
		assert_eq(_zelle(2, zelle).get_theme_color(&"font_color"), UiPalette.GEHAEUSE_DUNKEL,
			"Zu neu: %s gedämpft." % zelle)
	for zelle: StringName in [&"Name", &"Difficulty", &"Day", &"Played"]:
		assert_eq(_zelle(0, zelle).get_theme_color(&"font_color"), UiPalette.TUSCHE,
			"Fortsetzbar: %s in tusche." % zelle)
	assert_true(_liste._is_dimmed(1) and _liste._is_dimmed(2), "Auch der Pfeil ist gedämpft.")
	assert_false(_liste._is_dimmed(0))


func test_im_loeschmodus_sind_nicht_fortsetzbare_zeilen_verfuegbar() -> void:
	# Arrange (Klaus, 2026-10-26): Gedämpft heißt „löst nichts aus“. Im Löschmodus löst jede Zeile
	# die Rückfrage aus, also ist keine gedämpft; das Zustandswort bleibt in der Spalte.
	await _zeige([_spielstand(2, Difficulty.Level.SCHWER, 0, ZULETZT), _beschaedigt(4),
		_zu_neu(3)])

	# Act
	_liste.set_delete_mode(true)

	# Assert
	assert_eq(_zellen(1), ["Spiel 4", "beschädigt"], "Der Zustand steht weiter da.")
	assert_eq(_zellen(2), ["Spiel 3", "neuere Version"])
	for zeile in [1, 2]:
		for zelle: StringName in [&"Name", &"State"]:
			assert_eq(_zelle(zeile, zelle).get_theme_color(&"font_color"), UiPalette.TUSCHE,
				"Zeile %d: %s in tusche wie eine fortsetzbare." % [zeile, zelle])
		assert_false(_zeile(zeile).disabled, "Zeile %d löst aus." % zeile)
		assert_false(_liste._is_dimmed(zeile), "Zeile %d: Der Pfeil ist nicht gedämpft." % zeile)
	assert_true(_liste._is_dimmed(3), "„Löschen …“ bleibt im Löschmodus gedämpft.")


func test_nach_dem_loeschmodus_sind_nicht_fortsetzbare_zeilen_wieder_gedaempft() -> void:
	# Arrange
	await _zeige([_spielstand(2, Difficulty.Level.SCHWER, 0, ZULETZT), _beschaedigt(4)], 1)
	_liste.set_delete_mode(true)
	watch_signals(_liste)

	# Act
	_liste.set_delete_mode(false)

	# Assert
	assert_eq(_zelle(1, &"Name").get_theme_color(&"font_color"), UiPalette.GEHAEUSE_DUNKEL)
	assert_true(_zeile(1).disabled, "Löst wieder nichts aus.")
	assert_true(_liste._is_dimmed(1), "Der Pfeil ist wieder gedämpft.")
	assert_signal_emitted_with_parameters(_liste, "selection_changed",
		[GRUND_BESCHAEDIGT, _rechteck(1)])


func test_daempfen_haengt_am_spielstand_nicht_an_der_zeile() -> void:
	# Arrange: sieben Spielstände, der unterste beschädigt.
	var spielstaende := _viele(7)
	spielstaende[6] = _beschaedigt(1)
	await _zeige(spielstaende)
	var vorher := _zelle(5, &"Name").get_theme_color(&"font_color")

	# Act: einmal rollen, dann zeigt die unterste Zeile den beschädigten.
	_liste._scroll_by(1)

	# Assert
	assert_eq(vorher, UiPalette.TUSCHE, "Vorher zeigt die unterste Zeile Spiel 2, fortsetzbar.")
	assert_eq(_zellen(5), ["Spiel 1", "beschädigt"])
	assert_eq(_zelle(5, &"Name").get_theme_color(&"font_color"), UiPalette.GEHAEUSE_DUNKEL,
		"Nachher ist dieselbe Zeile gedämpft.")


# --- Auswahl und Hinweise -------------------------------------------------------------------------

func test_vorwahl_ist_die_oberste_zeile_mit_ihrem_hinweis() -> void:
	# Arrange
	watch_signals(_liste)

	# Act
	await _zeige(_drei())

	# Assert
	assert_eq(_liste.selected_index(), 0)
	assert_eq(_liste.get_viewport().gui_get_focus_owner(), _zeile(0),
		"Die Auswahl ist der Fokus.")
	assert_signal_emitted_with_parameters(_liste, "selection_changed", [
		_zeilenhinweis("14.03.1986", ZULETZT), _rechteck(0)])


func test_show_slots_waehlt_die_angegebene_zeile() -> void:
	# Arrange
	watch_signals(_liste)

	# Act: Zeile 4 ist bei drei Spielständen „Zurück“.
	await _zeige(_drei(), 4)

	# Assert
	assert_eq(_liste.get_viewport().gui_get_focus_owner(), _knopf("Back"))
	assert_signal_emitted_with_parameters(_liste, "selection_changed",
		[HINWEIS_ZURUECK, _rechteck(4)])


func test_hinweise_je_zeile() -> void:
	# Arrange
	await _zeige([_spielstand(2, Difficulty.Level.SCHWER, 0, ZULETZT), _beschaedigt(4),
		_zu_neu(3)])
	watch_signals(_liste)
	var hinweise: Array[String] = []

	# Act
	for zeile in 5:
		_liste.select(zeile)
		hinweise.append(get_signal_parameters(_liste, "selection_changed")[0])

	# Assert
	assert_eq(hinweise, [_zeilenhinweis("01.01.1985", ZULETZT), GRUND_BESCHAEDIGT, GRUND_ZU_NEU,
		HINWEIS_LOESCHEN, HINWEIS_ZURUECK],
		"Fortsetzbar: Spieldatum, zuletzt gespielt; nicht fortsetzbar: der Grund; feste Zeilen.")


func test_selected_slot() -> void:
	# Arrange
	var spielstaende := _drei()
	await _zeige(spielstaende)
	var gewaehlt: Array = []

	# Act
	for zeile in 5:
		_liste.select(zeile)
		gewaehlt.append(_liste.selected_slot())

	# Assert
	assert_eq(gewaehlt, [spielstaende[0], spielstaende[1], spielstaende[2], null, null],
		"Bei „Löschen …“ und „Zurück“ ist kein Spielstand gewählt.")


# --- Auslösen -------------------------------------------------------------------------------------

func test_enter_auf_fortsetzbarer_zeile_meldet_resume_requested() -> void:
	# Arrange
	var spielstaende := _drei()
	await _zeige(spielstaende)
	watch_signals(_liste)

	# Act
	_taste(KEY_ENTER)

	# Assert
	assert_signal_emit_count(_liste, "resume_requested", 1)
	assert_signal_emitted_with_parameters(_liste, "resume_requested", [spielstaende[0]])
	assert_signal_not_emitted(_liste, "delete_requested")


func test_klick_auf_fortsetzbare_zeile_meldet_resume_requested() -> void:
	# Arrange
	var spielstaende := _drei()
	await _zeige(spielstaende)
	watch_signals(_liste)

	# Act
	_maus_nach(_mitte(_zeile(2)))
	_klick(_mitte(_zeile(2)), MOUSE_BUTTON_LEFT)

	# Assert
	assert_eq(_liste.selected_index(), 2, "Überfahren wählt die Zeile.")
	assert_signal_emitted_with_parameters(_liste, "resume_requested", [spielstaende[2]])


func test_nicht_fortsetzbare_zeile_loest_ausserhalb_des_loeschmodus_nichts_aus() -> void:
	# Arrange
	await _zeige([_spielstand(2, Difficulty.Level.SCHWER, 0, ZULETZT), _beschaedigt(4)])
	_liste.select(1)
	watch_signals(_liste)

	# Act
	_taste(KEY_ENTER)
	_taste(KEY_SPACE)
	_maus_nach(_mitte(_zeile(1)))
	_klick(_mitte(_zeile(1)), MOUSE_BUTTON_LEFT)

	# Assert
	for signal_name in ["resume_requested", "delete_requested", "back_requested"]:
		assert_signal_not_emitted(_liste, signal_name, "Kein %s." % signal_name)
	assert_false(_liste.is_delete_mode())
	assert_eq(_liste.selected_index(), 1, "Die Zeile bleibt gewählt.")


func test_zurueck_meldet_back_requested() -> void:
	# Arrange
	await _zeige(_drei())
	watch_signals(_liste)

	# Act
	_maus_nach(_mitte(_knopf("Back")))
	_klick(_mitte(_knopf("Back")), MOUSE_BUTTON_LEFT)

	# Assert
	assert_signal_emit_count(_liste, "back_requested", 1)


func test_rechtsklick_waehlt_die_zeile_und_loest_nichts_aus() -> void:
	# Arrange: Die Maus steht schon auf Zeile 2, gewählt ist aber Zeile 0. So kann nur der
	# Rechtsklick die Zeile wählen, nicht schon das Überfahren.
	await _zeige(_drei())
	_maus_nach(_mitte(_zeile(2)))
	_liste.select(0)
	watch_signals(_liste)

	# Act
	_klick(_mitte(_zeile(2)), MOUSE_BUTTON_RIGHT)

	# Assert
	assert_eq(_liste.selected_index(), 2, "Der Rechtsklick wählt die Zeile unter der Maus.")
	assert_signal_emitted(_liste, "selection_changed", "und zeigt ihren Hinweis.")
	assert_signal_not_emitted(_liste, "resume_requested")


# --- Löschmodus -----------------------------------------------------------------------------------

func test_loeschen_schaltet_den_loeschmodus_ein() -> void:
	# Arrange
	await _zeige(_drei())
	_liste.select(3)
	watch_signals(_liste)

	# Act
	_taste(KEY_ENTER)

	# Assert
	assert_true(_liste.is_delete_mode())
	assert_eq(_kopfzeile(), "WELCHES LÖSCHEN?")
	assert_eq(_liste.selected_index(), 3, "Die Auswahl bleibt auf „Löschen …“.")
	assert_signal_emitted_with_parameters(_liste, "selection_changed",
		[HINWEIS_LOESCHEN_IM_MODUS, _rechteck(3)])
	assert_true(_knopf("DeleteMode").disabled, "„Löschen …“ ist im Löschmodus nicht verfügbar.")
	assert_true(_liste._is_dimmed(3), "Gedämpft, auch der Pfeil.")


func test_loeschen_ist_im_loeschmodus_ohne_wirkung() -> void:
	# Arrange
	await _zeige(_drei(), 3)
	_liste.set_delete_mode(true)
	watch_signals(_liste)

	# Act
	_taste(KEY_ENTER)
	_maus_nach(_mitte(_knopf("DeleteMode")))
	_klick(_mitte(_knopf("DeleteMode")), MOUSE_BUTTON_LEFT)

	# Assert
	assert_true(_liste.is_delete_mode())
	for signal_name in ["resume_requested", "delete_requested", "back_requested"]:
		assert_signal_not_emitted(_liste, signal_name, "Kein %s." % signal_name)


func test_im_loeschmodus_meldet_jede_zeile_delete_requested() -> void:
	# Arrange: auch die beschädigte und die zu neue lassen sich löschen (FR-017a).
	var spielstaende: Array[SaveSlot] = [_spielstand(2, Difficulty.Level.SCHWER, 0, ZULETZT),
		_beschaedigt(4), _zu_neu(3)]
	await _zeige(spielstaende)
	_liste.set_delete_mode(true)
	watch_signals(_liste)
	var gemeldet: Array = []

	for zeile in 3:
		# Act
		_liste.select(zeile)
		_taste(KEY_ENTER)
		gemeldet.append(get_signal_parameters(_liste, "delete_requested", zeile)[0])

	# Assert
	assert_eq(gemeldet, Array(spielstaende))
	assert_signal_not_emitted(_liste, "resume_requested", "Im Löschmodus wird nichts fortgesetzt.")


func test_hinweise_im_loeschmodus() -> void:
	# Arrange
	await _zeige([_spielstand(2, Difficulty.Level.SCHWER, 0, ZULETZT), _beschaedigt(4)])
	watch_signals(_liste)
	var hinweise: Array[String] = []

	# Act
	_liste.set_delete_mode(true)
	for zeile in 4:
		_liste.select(zeile)
		hinweise.append(get_signal_parameters(_liste, "selection_changed")[0])

	# Assert
	assert_eq(hinweise, ["Spiel 2 wird gelöscht. Vorher kommt eine Rückfrage.",
		"Spiel 4 wird gelöscht. Vorher kommt eine Rückfrage.", HINWEIS_LOESCHEN_IM_MODUS,
		HINWEIS_ZURUECK_IM_MODUS])


func test_zurueck_im_loeschmodus_meldet_back_requested_und_der_titel_entscheidet() -> void:
	# Arrange
	await _zeige(_drei(), 4)
	_liste.set_delete_mode(true)
	watch_signals(_liste)

	# Act
	_taste(KEY_ENTER)

	# Assert: Die Liste meldet nur; den Modus beendet der Titelbildschirm (Analyse, F3).
	assert_signal_emit_count(_liste, "back_requested", 1)
	assert_true(_liste.is_delete_mode(), "Die Liste beendet den Modus nicht selbst.")


func test_set_delete_mode_aus_beendet_den_modus() -> void:
	# Arrange
	await _zeige(_drei(), 1)
	_liste.set_delete_mode(true)
	watch_signals(_liste)

	# Act
	_liste.set_delete_mode(false)

	# Assert
	assert_false(_liste.is_delete_mode())
	assert_eq(_kopfzeile(), "SPIELSTÄNDE")
	assert_false(_knopf("DeleteMode").disabled, "„Löschen …“ geht wieder.")
	assert_eq(_liste.selected_index(), 1, "Die Auswahl bleibt, wo sie war.")
	assert_signal_emitted_with_parameters(_liste, "selection_changed",
		[_zeilenhinweis("01.01.1985", ZULETZT - STUNDE), _rechteck(1)])


func test_show_slots_beendet_den_loeschmodus() -> void:
	# Arrange
	await _zeige(_drei())
	_liste.set_delete_mode(true)

	# Act
	await _zeige(_drei())

	# Assert
	assert_false(_liste.is_delete_mode())
	assert_eq(_kopfzeile(), "SPIELSTÄNDE")


func test_nach_dem_loeschen_im_gerollten_fenster_bleibt_keine_leere_zeile() -> void:
	# Arrange: sieben Spielstände, bis unten gerollt, im Löschmodus der unterste gewählt. Nach dem
	# Löschen ruft der Titelbildschirm show_slots() mit den übrigen sechs und der letzten Zeile (T027).
	var sieben := _viele(7)
	await _zeige(sieben, 6)
	_liste.set_delete_mode(true)
	var sechs: Array[SaveSlot] = []
	sechs.assign(sieben.slice(0, 6))
	watch_signals(_liste)

	# Act
	await _zeige(sechs, 5)

	# Assert
	assert_false(_liste.is_delete_mode(), "show_slots() beendet den Löschmodus.")
	assert_eq(_kopfzeile(), "SPIELSTÄNDE")
	assert_eq(_sichtbare_namen(), ["Spiel 7", "Spiel 6", "Spiel 5", "Spiel 4", "Spiel 3",
		"Spiel 2"], "Das Fenster rückt hoch und zeigt keine leere Zeile.")
	assert_eq(_liste.selected_index(), 5, "Auf dem letzten Spielstand.")
	assert_false(_liste._more_above(), "Keine Rollmarke oben.")
	assert_false(_liste._more_below(), "Keine Rollmarke unten.")
	assert_signal_emitted_with_parameters(_liste, "selection_changed",
		[_zeilenhinweis("06.01.1985", ZULETZT - 5 * STUNDE), _rechteck(5)])


func test_mauszeiger_die_hand_nur_ueber_zeilen_die_etwas_ausloesen() -> void:
	# Arrange
	await _zeige([_spielstand(2, Difficulty.Level.SCHWER, 0, ZULETZT), _beschaedigt(4),
		_zu_neu(3)])
	var hand := Control.CURSOR_POINTING_HAND
	var pfeil := Control.CURSOR_ARROW

	# Act
	var ausserhalb := _zeiger()
	_liste.set_delete_mode(true)
	var im_modus := _zeiger()

	# Assert
	assert_eq(ausserhalb, [hand, pfeil, pfeil, hand, hand],
		"Außerhalb des Löschmodus: Hand nur über fortsetzbaren Zeilen und den festen.")
	assert_eq(im_modus, [hand, hand, hand, pfeil, hand],
		"Im Löschmodus: jede Zeile löscht, „Löschen …“ tut nichts.")


# --- Tastatur -------------------------------------------------------------------------------------

func test_pfeil_runter_laeuft_reihum() -> void:
	# Arrange
	await _zeige(_drei())

	# Act
	var auswahl := _auswahl_nach_jedem_druck(KEY_DOWN, 5)

	# Assert
	assert_eq(auswahl, [1, 2, 3, 4, 0], "Nach „Zurück“ folgt wieder der oberste Spielstand.")


func test_pfeil_hoch_laeuft_reihum() -> void:
	# Arrange
	await _zeige(_drei())

	# Act
	var auswahl := _auswahl_nach_jedem_druck(KEY_UP, 5)

	# Assert
	assert_eq(auswahl, [4, 3, 2, 1, 0], "Vor dem obersten Spielstand kommt „Zurück“.")


func test_tab_und_shift_tab_laufen_reihum_und_bleiben_in_der_liste() -> void:
	# Arrange
	await _zeige(_drei())

	# Act
	var vor := _auswahl_nach_jedem_druck(KEY_TAB, 5)
	var zurueck := _auswahl_nach_jedem_druck(KEY_TAB, 5, true)

	# Assert
	assert_eq(vor, [1, 2, 3, 4, 0], "Tab wie Pfeil runter, nie zum fremden Button.")
	assert_eq(zurueck, [4, 3, 2, 1, 0], "Shift+Tab wie Pfeil hoch.")


# --- Rollen ---------------------------------------------------------------------------------------

func test_sieben_spielstaende_zeigen_sechs_und_unten_eine_rollmarke() -> void:
	# Act
	await _zeige(_viele(7))

	# Assert
	assert_eq(_sichtbare_namen(), ["Spiel 7", "Spiel 6", "Spiel 5", "Spiel 4", "Spiel 3",
		"Spiel 2"], "Sechs Zeilen, der siebte steht unten außerhalb.")
	assert_eq(_liste.size, Vector2(304, 9 * ZEILE), "Kopfzeile, sechs Zeilen und zwei feste.")
	assert_false(_liste._more_above(), "Oben steht nichts mehr.")
	assert_true(_liste._more_below(), "Unten steht mehr: Rollmarke in „Löschen …“.")


func test_sieben_spielstaende_rollen_mit_der_auswahl() -> void:
	# Arrange
	await _zeige(_viele(7))
	watch_signals(_liste)

	# Act: sechsmal runter, vom obersten zum siebten Spielstand.
	_auswahl_nach_jedem_druck(KEY_DOWN, 6)

	# Assert: Das Fenster ist um eine Zeile gerollt, die Auswahl steht in der untersten Zeile.
	assert_eq(_liste.selected_index(), 6)
	assert_eq(_sichtbare_namen(), ["Spiel 6", "Spiel 5", "Spiel 4", "Spiel 3", "Spiel 2",
		"Spiel 1"])
	assert_eq(_liste.get_viewport().gui_get_focus_owner(), _zeile(5))
	assert_eq(_liste.selected_slot().display_name(), "Spiel 1")
	assert_signal_emitted_with_parameters(_liste, "selection_changed", [
		_zeilenhinweis("07.01.1985", ZULETZT - 6 * STUNDE), _rechteck(5)])
	assert_true(_liste._more_above(), "Jetzt steht oben mehr.")
	assert_false(_liste._more_below())

	# Act und Assert: weiter über die festen Zeilen; das Fenster bleibt, bis es oben weitergeht.
	_taste(KEY_DOWN)
	assert_eq([_liste.selected_index(), _sichtbare_namen()[0]], [7, "Spiel 6"], "„Löschen …“")
	_taste(KEY_DOWN)
	assert_eq([_liste.selected_index(), _sichtbare_namen()[0]], [8, "Spiel 6"], "„Zurück“")
	_taste(KEY_DOWN)
	assert_eq([_liste.selected_index(), _sichtbare_namen()[0]], [0, "Spiel 7"],
		"Wieder oben, das Fenster rollt zurück.")


func test_zwanzig_spielstaende_rollen_reihum_und_die_auswahl_zeigt_immer_ihren() -> void:
	# Arrange
	await _zeige(_viele(20))
	var auswahl: Array[int] = []
	var passt := true

	# Act: einmal ganz herum, 22 Zeilen.
	for _druck in 22:
		_taste(KEY_DOWN)
		auswahl.append(_liste.selected_index())
		# Die Zeile mit dem Fokus zeigt den gewählten Spielstand.
		var fokus := _liste.get_viewport().gui_get_focus_owner() as Button
		var gewaehlt := _liste.selected_slot()
		if gewaehlt != null:
			passt = passt and (fokus.get_node(^"Name") as Label).text == gewaehlt.display_name()
		passt = passt and _sichtbare_namen().size() == 6

	# Assert
	var erwartet: Array[int] = []
	for zeile in range(1, 22):
		erwartet.append(zeile)
	erwartet.append(0)
	assert_eq(auswahl, erwartet)
	assert_true(passt, "Die gewählte Zeile zeigt immer den gewählten Spielstand, sechs Zeilen.")
	assert_eq(_sichtbare_namen()[0], "Spiel 20", "Wieder oben.")


func test_zwanzig_spielstaende_pfeil_hoch_vom_obersten() -> void:
	# Arrange
	await _zeige(_viele(20))

	# Act und Assert
	_taste(KEY_UP)
	assert_eq([_liste.selected_index(), _sichtbare_namen()[0]], [21, "Spiel 20"],
		"„Zurück“; die festen Zeilen stehen immer da, das Fenster rollt nicht.")
	_taste(KEY_UP)
	assert_eq(_liste.selected_index(), 20, "„Löschen …“")
	_taste(KEY_UP)
	assert_eq([_liste.selected_index(), _sichtbare_namen()[0], _sichtbare_namen()[5]],
		[19, "Spiel 6", "Spiel 1"], "Der unterste Spielstand, ganz nach unten gerollt.")
	assert_eq(_liste.get_viewport().gui_get_focus_owner(), _zeile(5))
	assert_true(_liste._more_above())
	assert_false(_liste._more_below())


func test_mausrad_rollt_um_je_eine_zeile() -> void:
	# Arrange: Die Maus steht auf der dritten Zeile und wählt damit Spiel 18.
	await _zeige(_viele(20))
	var ziel := _mitte(_zeile(2))
	_maus_nach(ziel)
	assert_eq(_liste.selected_slot().display_name(), "Spiel 18", "Voraussetzung: Überfahren wählt.")

	# Act
	for _dreh in 3:
		_rad(ziel, MOUSE_BUTTON_WHEEL_DOWN)

	# Assert: Spiel 18 ist oben herausgerollt; die Auswahl rückt auf die oberste sichtbare Zeile.
	assert_eq(_sichtbare_namen()[0], "Spiel 17", "Drei Drehs, drei Zeilen.")
	assert_eq(_liste.selected_slot().display_name(), "Spiel 17")
	assert_eq(_liste.get_viewport().gui_get_focus_owner(), _zeile(0))
	assert_true(_liste._more_above() and _liste._more_below(), "Oben und unten steht mehr.")

	# Act: zu weit zurück; oben ist Schluss.
	for _dreh in 5:
		_rad(ziel, MOUSE_BUTTON_WHEEL_UP)

	# Assert
	assert_eq(_sichtbare_namen()[0], "Spiel 20")
	assert_eq(_liste.selected_slot().display_name(), "Spiel 17",
		"Sie ist noch zu sehen und bleibt.")
	assert_false(_liste._more_above())


func test_mausrad_ueber_der_kopfzeile_und_den_festen_zeilen_rollt_auch() -> void:
	# Arrange
	await _zeige(_viele(20), 21)

	# Act
	_rad(_liste.global_position + Vector2(150, 10), MOUSE_BUTTON_WHEEL_DOWN)
	_rad(_mitte(_knopf("Back")), MOUSE_BUTTON_WHEEL_DOWN)

	# Assert
	assert_eq(_sichtbare_namen()[0], "Spiel 18", "Zwei Drehs, zwei Zeilen.")
	assert_eq(_liste.selected_index(), 21, "Die Auswahl bleibt auf „Zurück“.")


func test_mausrad_ohne_mehr_spielstaende_rollt_nicht() -> void:
	# Arrange
	await _zeige(_drei())

	# Act
	_rad(_mitte(_zeile(1)), MOUSE_BUTTON_WHEEL_DOWN)

	# Assert
	assert_eq(_sichtbare_namen(), ["Spiel 7", "Spiel 6", "Spiel 5"])


func test_nach_dem_rollen_waehlt_die_maus_den_spielstand_unter_ihr() -> void:
	# Arrange
	await _zeige(_viele(20))
	var ziel := _mitte(_zeile(3))
	_maus_nach(ziel)
	_rad(ziel, MOUSE_BUTTON_WHEEL_DOWN)
	_rad(ziel, MOUSE_BUTTON_WHEEL_DOWN)
	var vorher := _liste.selected_slot().display_name()

	# Act: Die Maus ruckt ein Pixel, sie bleibt in derselben Zeile.
	_maus_nach(ziel + Vector2(1, 0))

	# Assert
	assert_eq(vorher, "Spiel 17",
		"Das Rad allein ändert die Auswahl nicht, solange sie zu sehen ist.")
	assert_eq(_liste.selected_slot().display_name(), "Spiel 15",
		"Unter der Maus steht jetzt der fünfte Spielstand von oben, Spiel 15.")


func test_rollmarken_stehen_rechts_mit_12_abstand_zum_rand() -> void:
	# Arrange: 20 Spielstände, ein Stück gerollt; oben und unten steht mehr.
	await _zeige(_viele(20), 10)

	# Act
	var oben := _liste._scroll_mark_rect(0)
	var unten := _liste._scroll_mark_rect(7)

	# Assert: 7 × 4, rechts 12 vom Rand, in der Kopfzeile und in „Löschen …“ (Zeile 7).
	assert_true(_liste._more_above() and _liste._more_below())
	assert_eq(oben, Rect2(285, 8, 7, 4), "Kopfzeile")
	assert_eq(unten, Rect2(285, 7 * ZEILE + 8, 7, 4), "Zeile „Löschen …“")
	assert_eq(oben.end.x, 304.0 - 12.0)


func test_weniger_spielstaende_schrumpfen_das_papier_und_das_fenster_rueckt_hoch() -> void:
	# Arrange: 20, ganz nach unten gerollt.
	await _zeige(_viele(20), 19)

	# Act
	await _zeige(_drei())

	# Assert
	assert_eq(_liste.size, Vector2(304, 6 * ZEILE))
	assert_eq(_sichtbare_namen(), ["Spiel 7", "Spiel 6", "Spiel 5"])
	assert_false(_liste._more_above() or _liste._more_below())


func test_unsichtbare_liste_nimmt_keinen_fokus() -> void:
	# Arrange: Daneben ein sichtbarer Button mit Fokus, wie ein anderes Blatt.
	var anderer := Button.new()
	_liste.get_parent().add_child(anderer)
	anderer.grab_focus()
	_liste.visible = false
	watch_signals(_liste)

	# Act
	await _zeige(_drei(), 2)
	_liste.set_delete_mode(true)

	# Assert
	assert_eq(_liste.get_viewport().gui_get_focus_owner(), anderer)
	assert_eq(_liste.selected_index(), 2, "Die Liste merkt sich die Zeile trotzdem.")
	assert_signal_not_emitted(_liste, "selection_changed")


func test_show_slots_vor_dem_erscheinen_gilt_beim_erscheinen() -> void:
	# Arrange
	var liste := LISTE.instantiate() as SaveList
	liste.show_slots(_drei(), 2)

	# Act
	_liste.get_parent().add_child(liste)
	await wait_process_frames(1)

	# Assert
	assert_eq(liste.selected_index(), 2)
	assert_eq(liste.size, Vector2(304, 6 * ZEILE))


# --- Auf der Anzeige (Feature 005, T015) ---------------------------------------------------------

func test_papier_ohne_override_der_schrift() -> void:
	# Arrange und Act: auf Papier, gewählt die zweite Zeile.
	await _zeige(_drei(), 1)

	# Assert: Auf Papier kommt jede Farbe aus MenuRow; der Titel bleibt, wie er ist.
	assert_true(_liste._draws_paper())
	for button in _alle_knoepfe():
		for farbe in SaveList.LIT_FONT_COLORS:
			assert_false(button.has_theme_color_override(farbe),
				"%s hat auf Papier keinen Override %s." % [button.name, farbe])
	for zelle in SPALTEN:
		assert_eq(_zelle(1, zelle).get_theme_color(&"font_color"), UiPalette.TUSCHE,
			"Auf Papier ist auch die gewählte Zeile tusche: %s." % zelle)


func test_lcd_ohne_papier_mit_den_varianten_der_anzeige() -> void:
	# Arrange und Act
	await _auf_der_anzeige(_drei())

	# Assert
	assert_false(_liste._draws_paper(), "Auf der Anzeige kein Papier, kein Zebra, kein Schatten.")
	assert_eq((_liste.get_node(^"Rows/Header") as Label).theme_type_variation, &"LcdHeader")
	for button in _alle_knoepfe():
		assert_eq(button.theme_type_variation, &"LcdRow", "%s ist eine LcdRow." % button.name)
	var zeilen := _liste.get_node(^"Rows") as Control
	assert_eq([zeilen.offset_left, zeilen.offset_right],
		[float(MenuPaper.LCD_ROW_INSET), -float(MenuPaper.LCD_ROW_INSET)],
		"Der Innenbereich beginnt 4 vom Rand und endet 4 davor.")
	# Text bei x 16, die Spalten ab dem Text wie auf Papier.
	for spalte in SPALTEN.size():
		assert_eq(_links(_zelle(0, SPALTEN[spalte])),
			float(MenuPaper.LCD_TEXT_INSET + SaveList.COLUMNS[spalte]),
			"Spalte %s ab x 16." % SPALTEN[spalte])
	var loeschen := _knopf("DeleteMode")
	assert_eq(_links(loeschen) + loeschen.get_theme_stylebox(&"normal").content_margin_left,
		float(MenuPaper.LCD_TEXT_INSET), "Auch „Löschen …“ beginnt bei x 16.")


func test_lcd_spalten_so_breit_wie_auf_papier() -> void:
	# Arrange
	await _auf_der_anzeige(_drei())

	# Assert: Was auf Papier passt, passt auch auf der Anzeige; rechts bleibt nur mehr Luft.
	for zelle in SPALTEN:
		assert_eq(_zelle(0, zelle).size.x, float(SaveList._cell_width(zelle)), String(zelle))
	var letzte := _zelle(0, &"Played")
	assert_lte(_links(letzte) + letzte.size.x, ANZEIGE.x - MenuPaper.LCD_ROW_INSET,
		"Die letzte Spalte endet vor dem Innenrand.")


func test_lcd_groesse_kommt_von_aussen() -> void:
	# Arrange
	await _auf_der_anzeige(_drei())

	# Act: Was auf Papier die Größe setzt, darf sie auf der Anzeige nicht ändern.
	await _zeige(_viele(20), 3)
	_liste.set_delete_mode(true)

	# Assert
	assert_eq(_liste.size, ANZEIGE, "Die Seite bleibt so groß wie die Anzeige.")
	assert_eq(_liste.custom_minimum_size, Vector2.ZERO, "Keine Mindestgröße überstimmt sie.")


func test_lcd_auswahl_ist_invertiert_auch_in_den_spalten() -> void:
	# Arrange
	await _auf_der_anzeige(_drei())

	# Act: Pfeil runter auf „Spiel 6“.
	_taste(KEY_DOWN)

	# Assert: Schrift und Spalten der gewählten Zeile lcd, die übrigen tusche.
	assert_eq(_liste.selected_index(), 1)
	assert_eq(_spaltenfarben(0), [UiPalette.TUSCHE, UiPalette.TUSCHE, UiPalette.TUSCHE,
		UiPalette.TUSCHE])
	assert_eq(_spaltenfarben(1), [UiPalette.LCD, UiPalette.LCD, UiPalette.LCD, UiPalette.LCD])
	assert_eq(_zeile(1).get_theme_color(&"font_focus_color"), UiPalette.LCD)
	var ebenen := MenuPaper.lcd_selection_layers(_liste.size.x, 2, true)
	assert_eq(ebenen[0], {"rect": Rect2(4, 40, ANZEIGE.x - 8, ZEILE), "color": UiPalette.TUSCHE},
		"Balken in tusche über den Innenbereich.")


func test_lcd_maus_auf_a_pfeil_auf_b() -> void:
	# Arrange: Die Maus steht auf „Spiel 7“ und wählt sie.
	await _auf_der_anzeige(_drei())
	_maus_nach(_mitte(_zeile(0)))

	# Act: Pfeil runter wählt „Spiel 6“; die Maus bleibt auf „Spiel 7“.
	_taste(KEY_DOWN)

	# Assert
	assert_eq(_zeile(0).get_draw_mode(), BaseButton.DRAW_HOVER, "Voraussetzung: A unter der Maus.")
	assert_eq(_liste.selected_index(), 1)
	assert_eq(_spaltenfarben(0)[0], UiPalette.TUSCHE, "A unter der Maus bleibt tusche.")
	assert_eq(_spaltenfarben(1)[0], UiPalette.LCD, "B gewählt ist lcd.")


func test_lcd_loeschen_und_zurueck_unter_der_maus() -> void:
	# Arrange: Die Maus fährt auf „Löschen …“ und wählt es.
	await _auf_der_anzeige(_drei())
	_maus_nach(_mitte(_knopf("DeleteMode")))

	# Act und Assert: Pfeil runter auf „Zurück“, die Maus bleibt auf „Löschen …“.
	_taste(KEY_DOWN)
	assert_eq(_knopf("DeleteMode").get_draw_mode(), BaseButton.DRAW_HOVER)
	assert_eq(_schriftfarbe(_knopf("DeleteMode")), UiPalette.TUSCHE,
		"„Löschen …“ unter der Maus, nicht gewählt: tusche.")
	assert_eq(_schriftfarbe(_knopf("Back")), UiPalette.LCD, "„Zurück“ gewählt: lcd.")

	# Act und Assert: Die Maus fährt auf „Zurück“, gewählt und darunter.
	_maus_nach(_mitte(_knopf("Back")))
	assert_eq(_knopf("Back").get_draw_mode(), BaseButton.DRAW_HOVER)
	assert_eq(_schriftfarbe(_knopf("Back")), UiPalette.LCD, "Gewählt unter der Maus bleibt lcd.")
	assert_eq(_schriftfarbe(_knopf("DeleteMode")), UiPalette.TUSCHE)


func test_lcd_gewaehlt_und_nicht_verfuegbar_bleibt_gedaempft() -> void:
	# Arrange: oben fortsetzbar, darunter beschädigt.
	await _auf_der_anzeige([_spielstand(2, Difficulty.Level.SCHWER, 0, ZULETZT), _beschaedigt(4)])

	# Act
	_liste.select(1)

	# Assert
	for zelle: StringName in [&"Name", &"State"]:
		assert_eq(_zelle(1, zelle).get_theme_color(&"font_color"), UiPalette.GEHAEUSE_DUNKEL,
			"Beschädigt und gewählt: %s gedämpft." % zelle)
	assert_eq(_spaltenfarben(0)[0], UiPalette.TUSCHE, "Die vorige Zeile ist wieder tusche.")
	assert_true(_liste._is_dimmed(1), "Der Pfeil im Balken ist gehaeuse-dunkel.")
	var ebenen := MenuPaper.lcd_selection_layers(_liste.size.x, 2, false)
	assert_eq(ebenen[1]["color"], UiPalette.GEHAEUSE_DUNKEL)

	# Act und Assert: im Löschmodus „Löschen …“ gewählt, gesperrt und gedämpft.
	_liste.set_delete_mode(true)
	_liste.select(2)
	assert_eq(_schriftfarbe(_knopf("DeleteMode")), UiPalette.GEHAEUSE_DUNKEL)


func test_lcd_rollmarke_8_vom_rand_in_der_gewaehlten_zeile_lcd() -> void:
	# Arrange: sieben Spielstände, unten steht mehr; gewählt ist der oberste.
	await _auf_der_anzeige(_viele(7))

	# Act und Assert: nicht gewählt tusche.
	var marke := _liste._scroll_mark_layers()
	assert_true(_liste._more_below() and not _liste._more_above())
	assert_eq(_liste._scroll_mark_rect(7), Rect2(ANZEIGE.x - 8 - 7, 7 * ZEILE + 8, 7, 4),
		"In „Löschen …“, 8 vom rechten Rand der Anzeige.")
	assert_eq(_farben(marke), [UiPalette.TUSCHE], "Nicht gewählt: tusche.")

	# Act und Assert: „Löschen …“ gewählt, die Marke im Balken lcd.
	_liste.select(7)
	assert_eq(_farben(_liste._scroll_mark_layers()), [UiPalette.LCD], "Gewählt: lcd (CHK001).")

	# Act und Assert: gerollt; oben in der Kopfzeile tusche, unten keine mehr.
	_liste.select(6)
	assert_true(_liste._more_above() and not _liste._more_below())
	assert_eq(_liste._scroll_mark_rect(0), Rect2(ANZEIGE.x - 8 - 7, 8, 7, 4), "Kopfzeile.")
	assert_eq(_farben(_liste._scroll_mark_layers()), [UiPalette.TUSCHE])


func test_papier_rollmarke_bleibt_tusche_auch_gewaehlt() -> void:
	# Arrange
	await _zeige(_viele(7))

	# Act
	_liste.select(7)

	# Assert
	assert_eq(_farben(_liste._scroll_mark_layers()), [UiPalette.TUSCHE],
		"Auf Papier steht die Marke in tusche auf signalgelb.")
	assert_eq(_liste._scroll_mark_rect(7).end.x, 304.0 - 12.0)


func test_lcd_bedienung_rollen_und_loeschmodus_wie_auf_papier() -> void:
	# Arrange: sieben Spielstände, der oberste gewählt.
	var spielstaende := _viele(7)
	await _auf_der_anzeige(spielstaende)
	watch_signals(_liste)

	# Act und Assert: Pfeil runter läuft über sieben Spielstände, „Löschen …“, „Zurück“ reihum.
	assert_eq(_auswahl_nach_jedem_druck(KEY_DOWN, 9), [1, 2, 3, 4, 5, 6, 7, 8, 0])
	_taste(KEY_ENTER)
	assert_signal_emitted_with_parameters(_liste, "resume_requested", [spielstaende[0]])
	var parameter: Array = get_signal_parameters(_liste, "selection_changed")
	assert_eq((parameter[1] as Rect2).size.x, ANZEIGE.x, "Die Zeile reicht über die Anzeige.")

	# Mausrad rollt um eine Zeile.
	_rad(_mitte(_zeile(2)), MOUSE_BUTTON_WHEEL_DOWN)
	assert_true(_liste._more_above(), "Nach dem Rad steht oben mehr.")

	# Löschmodus über „Löschen …“, dann eine Zeile, dann „Zurück“.
	_liste.select(7)
	_taste(KEY_ENTER)
	assert_true(_liste.is_delete_mode())
	assert_eq(_kopfzeile(), "WELCHES LÖSCHEN?")
	_liste.select(2)
	_taste(KEY_ENTER)
	assert_signal_emitted_with_parameters(_liste, "delete_requested", [spielstaende[2]])
	_liste.select(8)
	_taste(KEY_ENTER)
	assert_signal_emit_count(_liste, "back_requested", 1)


func test_lcd_beschaedigt_und_neuere_version_wie_auf_papier() -> void:
	# Arrange und Act
	await _auf_der_anzeige([_spielstand(2, Difficulty.Level.SCHWER, 0, ZULETZT), _beschaedigt(4),
		_zu_neu(3)])

	# Assert
	assert_eq(_zellen(1), ["Spiel 4", "beschädigt"])
	assert_eq(_zellen(2), ["Spiel 3", "neuere Version"])
	assert_eq(_zelle(2, &"State").get_theme_color(&"font_color"), UiPalette.GEHAEUSE_DUNKEL)


func test_look_spaeter_setzen_baut_die_zeilen_neu() -> void:
	# Arrange: auf Papier, gewählt die zweite Zeile.
	await _zeige(_drei(), 1)

	# Act: auf die Anzeige …
	_liste.look = SaveList.Look.LCD

	# Assert
	for button in _alle_knoepfe():
		assert_eq(button.theme_type_variation, &"LcdRow", "%s ist neu gebaut." % button.name)
	assert_eq(_liste.get_node(^"Rows").get_child_count(), 1 + SaveList.VISIBLE_ROWS + 2,
		"Keine alte Zeile bleibt stehen.")
	assert_eq(_liste.selected_index(), 1, "Die Auswahl bleibt auf ihrer Zeile.")
	assert_eq(_spaltenfarben(1)[0], UiPalette.LCD)
	assert_eq(_sichtbare_namen(), ["Spiel 7", "Spiel 6", "Spiel 5"])

	# Act: … und zurück aufs Papier.
	_liste.look = SaveList.Look.PAPER

	# Assert
	assert_eq(_zeile(1).theme_type_variation, &"MenuRow")
	assert_false(_zeile(1).has_theme_color_override(&"font_focus_color"))
	assert_eq(_spaltenfarben(1)[0], UiPalette.TUSCHE)
	assert_eq(_liste.size, Vector2(SaveList.PAPER_WIDTH, 6 * ZEILE),
		"Auf Papier setzt die Liste ihre Größe wieder selbst.")
	# Ein Bild warten: Die alten Zeilen gibt queue_free() erst am Ende des Bilds frei. Endete der Test
	# vorher, zählte GUT sie als verwaiste Knoten (wie after_each() in test_main_menu.gd).
	await wait_process_frames(1)


# --- Helfer ---------------------------------------------------------------------------------------

## Zeigt [param spielstaende] und wartet ein Bild, bis der VBoxContainer die Zeilen angeordnet hat
## und die Maus sie dort trifft, wo sie zu sehen sind.
func _zeige(spielstaende: Array[SaveSlot], index := 0) -> void:
	_liste.show_slots(spielstaende, index)
	await wait_process_frames(1)


## Zeile [param zeile] des Fensters, 0 ist die oberste.
func _zeile(zeile: int) -> Button:
	return _liste.get_node("Rows/Slot%d" % zeile) as Button


func _knopf(name: String) -> Button:
	return _liste.get_node("Rows/" + name) as Button


func _zelle(zeile: int, zelle: StringName) -> Label:
	return _zeile(zeile).get_node(String(zelle)) as Label


func _kopfzeile() -> String:
	return (_liste.get_node(^"Rows/Header") as Label).text


## Die Texte der sichtbaren Spalten von Zeile [param zeile], von links nach rechts.
func _zellen(zeile: int) -> Array[String]:
	var texte: Array[String] = []
	for zelle: StringName in [&"Name", &"Difficulty", &"State", &"Day", &"Played"]:
		var label := _zelle(zeile, zelle)
		if label.visible:
			texte.append(label.text)
	return texte


## Die Namen in den sichtbaren Zeilen des Fensters.
func _sichtbare_namen() -> Array[String]:
	var namen: Array[String] = []
	for zeile in SaveList.VISIBLE_ROWS:
		if _zeile(zeile).visible:
			namen.append(_zelle(zeile, &"Name").text)
	return namen


## Abstand von [param control] zum linken Rand des Papiers.
func _links(control: Control) -> float:
	return control.global_position.x - _liste.global_position.x


## Die ganze Zeile [param zeile] unter der Kopfzeile, global und über die volle Papierbreite.
func _rechteck(zeile: int) -> Rect2:
	return Rect2(_liste.global_position + Vector2(0, (zeile + 1) * ZEILE),
		Vector2(SaveList.PAPER_WIDTH, ZEILE))


func _mitte(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


## Der Hinweis einer fortsetzbaren Zeile: „Steht am 14.03.1986. Gespielt am 26.10.2026, 21:40 Uhr.“
## Der Satz steht hier ausgeschrieben; nur „zuletzt gespielt“ kommt aus der Ortszeit des Rechners.
func _zeilenhinweis(spieldatum: String, zuletzt: int) -> String:
	return "Steht am %s. Gespielt am %s Uhr." % [spieldatum, _gespielt(zuletzt)]


## „26.10.2026, 21:40“ in Ortszeit, wie im Hinweis.
func _gespielt(zuletzt: int) -> String:
	return SaveGame.time_text(zuletzt).replace(" ", ", ")


## Mauszeiger der Spielstandzeilen, dann von „Löschen …“ und „Zurück“.
func _zeiger() -> Array:
	var zeiger := []
	for zeile in SaveList.VISIBLE_ROWS:
		if _zeile(zeile).visible:
			zeiger.append(_zeile(zeile).mouse_default_cursor_shape)
	zeiger.append(_knopf("DeleteMode").mouse_default_cursor_shape)
	zeiger.append(_knopf("Back").mouse_default_cursor_shape)
	return zeiger


func _auswahl_nach_jedem_druck(taste: Key, anzahl: int, shift := false) -> Array[int]:
	var auswahl: Array[int] = []
	for _druck in anzahl:
		_taste(taste, shift)
		auswahl.append(_liste.selected_index())
	return auswahl


## Drückt [param taste] und lässt sie los, über push_input wie in test_main_menu.gd.
func _taste(taste: Key, shift := false) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventKey.new()
		ereignis.keycode = taste
		ereignis.physical_keycode = taste
		ereignis.shift_pressed = shift
		ereignis.pressed = gedrueckt
		_liste.get_viewport().push_input(ereignis)


func _maus_nach(ziel: Vector2) -> void:
	var ereignis := InputEventMouseMotion.new()
	ereignis.position = ziel
	ereignis.global_position = ziel
	_liste.get_viewport().push_input(ereignis, true)


func _klick(ziel: Vector2, taste: MouseButton) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventMouseButton.new()
		ereignis.button_index = taste
		ereignis.position = ziel
		ereignis.global_position = ziel
		ereignis.pressed = gedrueckt
		_liste.get_viewport().push_input(ereignis, true)


## Ein Dreh am Mausrad bei [param ziel]: Godot meldet ihn als Drücken und Loslassen.
func _rad(ziel: Vector2, richtung: MouseButton) -> void:
	_klick(ziel, richtung)


## Ein fortsetzbarer Spielstand im Speicher, ohne Datei.
func _spielstand(nummer: int, grad: Difficulty.Level, tag: int, zuletzt: int) -> SaveSlot:
	var spiel := SaveGame.new()
	spiel.number = nummer
	spiel.name = SaveGame.default_name(nummer)
	spiel.difficulty = grad
	spiel.day = tag
	spiel.last_played_at = zuletzt
	var slot := SaveSlot.new()
	slot.number = nummer
	slot.state = SaveSlot.State.OK
	slot.game = spiel
	return slot


func _beschaedigt(nummer: int) -> SaveSlot:
	var slot := SaveSlot.new()
	slot.number = nummer
	slot.state = SaveSlot.State.DAMAGED
	slot.reason = SaveSlot.REASON_UNREADABLE
	return slot


func _zu_neu(nummer: int) -> SaveSlot:
	var slot := SaveSlot.new()
	slot.number = nummer
	slot.state = SaveSlot.State.TOO_NEW
	slot.reason = SaveSlot.REASON_TOO_NEW
	return slot


## Spiel 7 Schwer am 14.03.1986, Spiel 6 Mittel am 01.01.1985, Spiel 5 Leicht am 02.07.1991, je
## eine Stunde früher gespielt.
func _drei() -> Array[SaveSlot]:
	return [_spielstand(7, Difficulty.Level.SCHWER, _tag(1986, 3, 14), ZULETZT),
		_spielstand(6, Difficulty.Level.MITTEL, _tag(1985, 1, 1), ZULETZT - STUNDE),
		_spielstand(5, Difficulty.Level.LEICHT, _tag(1991, 7, 2), ZULETZT - 2 * STUNDE)]


## [param anzahl] fortsetzbare Spielstände, der jüngste oben: Spiel anzahl bis Spiel 1.
func _viele(anzahl: int) -> Array[SaveSlot]:
	var spielstaende: Array[SaveSlot] = []
	for platz in anzahl:
		spielstaende.append(_spielstand(anzahl - platz, Difficulty.Level.MITTEL, platz,
			ZULETZT - platz * STUNDE))
	return spielstaende


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()


## Ersetzt die Liste dieses Tests durch eine auf der Anzeige: look = LCD, so groß wie die Anzeige
## des Communicators, in einem eigenen Viewport, mit [param spielstaende] und Zeile [param index]
## gewählt. Die Helfer oben gelten dann für diese Liste.
func _auf_der_anzeige(spielstaende: Array[SaveSlot], index := 0) -> void:
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	_liste = LISTE.instantiate() as SaveList
	_liste.look = SaveList.Look.LCD
	eigener_viewport.add_child(_liste)
	# Das täte der Communicator in add_page().
	_liste.size = ANZEIGE
	eigener_viewport.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)
	await _zeige(spielstaende, index)


## Alle Buttons der Liste: die Zeilen des Fensters, „Löschen …“ und „Zurück“.
func _alle_knoepfe() -> Array[Button]:
	var knoepfe: Array[Button] = []
	for zeile in SaveList.VISIBLE_ROWS:
		knoepfe.append(_zeile(zeile))
	knoepfe.append_array([_knopf("DeleteMode"), _knopf("Back")])
	return knoepfe


## Die Farben der vier Spalten einer fortsetzbaren Zeile [param zeile].
func _spaltenfarben(zeile: int) -> Array[Color]:
	var farben: Array[Color] = []
	for zelle in SPALTEN:
		farben.append(_zelle(zeile, zelle).get_theme_color(&"font_color"))
	return farben


## Die verschiedenen Farben in einer Liste von Ebenen { "rect", "color" }.
func _farben(ebenen: Array[Dictionary]) -> Array[Color]:
	var farben: Array[Color] = []
	for ebene in ebenen:
		if not farben.has(ebene["color"]):
			farben.append(ebene["color"])
	return farben


## Die Schriftfarbe von [param button], wie Godots Button sie für seinen Zustand wählt (wie in
## test_main_menu.gd): gesperrt, unter der Maus, gedrückt, sonst mit oder ohne Fokus.
func _schriftfarbe(button: Button) -> Color:
	var farbname: StringName = &"font_focus_color" if button.has_focus() else &"font_color"
	match button.get_draw_mode():
		BaseButton.DRAW_DISABLED:
			farbname = &"font_disabled_color"
		BaseButton.DRAW_HOVER:
			farbname = &"font_hover_color"
		BaseButton.DRAW_PRESSED:
			farbname = &"font_pressed_color"
		BaseButton.DRAW_HOVER_PRESSED:
			farbname = &"font_hover_pressed_color"
	return button.get_theme_color(farbname)
