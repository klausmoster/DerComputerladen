extends GutTest

## Prüft das Hauptmenü: die Zeilen in ihrer Reihenfolge, welche sich auslösen lassen, die
## Startauswahl, die Meldung, wenn eine Zeile gewählt wird, die Meldung, wenn ein Eintrag
## ausgelöst wird, die Bedienung mit Tastatur und Maus, den Mauszeiger je Eintrag und die
## gedämpfte Schrift gesperrter Zeilen.
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
