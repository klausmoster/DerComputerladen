extends GutTest

## Prüft das Grundgerüst des Hauptmenüs: die Zeilen in ihrer Reihenfolge, welche sich
## auslösen lassen, die Startauswahl und die Meldung, wenn eine Zeile gewählt wird.
##
## Die vier Einträge entstehen hier im Code, mit den Werten aus dem Datenmodell
## (specs/001-hauptmenue/data-model.md). Geprüft wird also das Menü, nicht die Daten,
## die später im Titelbildschirm stehen.

const MENU_SCENE := preload("res://scenes/title/main_menu.tscn")

var _menu: MainMenu


func before_each() -> void:
	_menu = MENU_SCENE.instantiate() as MainMenu
	# Die Einträge müssen vor add_child stehen, denn _ready() baut aus ihnen die Zeilen.
	_menu.entries = _eintraege()
	add_child_autofree(_menu)
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


# --- Helfer ---------------------------------------------------------------

## Die Buttons des Menüs, in der Reihenfolge, in der sie im Baum stehen. Sie entstehen
## im Code und haben deshalb keinen Owner; ohne owned = false fände die Suche keinen.
func _zeilen() -> Array[Node]:
	return _menu.find_children("*", "Button", true, false)


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
