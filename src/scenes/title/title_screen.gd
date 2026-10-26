class_name TitleScreen
extends Control

## Der Titelbildschirm: Titelbild T-01, Logo mit Untertitel, ein Blatt Endlospapier und die
## Versionszeile, angeordnet nach dem Titelscreen-Entwurf (Feature 001, FR-005).
##
## Er setzt die Teile nur zusammen und verbindet sie. Ein Blatt meldet die gewählte Zeile per
## Signal, der Titelbildschirm reicht sie an den Hinweis weiter. Blätter und Hinweis kennen
## einander nicht. Ebenso meldet ein Blatt einen ausgelösten Eintrag nur; was dann geschieht,
## entscheidet der Titelbildschirm.
##
## Seit Feature 004 gibt es mehrere Blätter an derselben Stelle, je eine Instanz von
## main_menu.tscn: das Hauptmenü und die Gradwahl (contracts/titelbildschirm.md). Es ist immer genau
## eins zu sehen; ein unsichtbares hat keinen Fokus. Esc und „Zurück“ führen eine Ebene zurück, im
## Hauptmenü tut Esc nichts. Die Einträge des Hauptmenüs entstehen zur Laufzeit aus den
## Spielständen im Ordner der Session, beim Erscheinen und bei jeder Rückkehr aus einem Blatt neu
## gelesen (Analyse, F2). Alle Texte kommen aus TitleTexts.
##
## Ein Spiel beginnt oder setzt fort nur über die Session; den Spielbildschirm zeigt
## scene_callback. „Spiel laden“ öffnet erst mit Phase 5 die Liste der Spielstände (T026).

## Kennzeichen in der Versionszeile, solange das Spiel ein Prototyp ist.
const STAGE := "PROTOTYP"
## Der Spielbildschirm, zu dem ein begonnenes oder fortgesetztes Spiel führt.
const GAME_SCENE := "res://scenes/game/game_screen.tscn"
## Die Grade der Gradwahl in der Reihenfolge der Zeilen (FR-004).
const LEVELS: Array[Difficulty.Level] = [Difficulty.Level.LEICHT, Difficulty.Level.MITTEL,
	Difficulty.Level.SCHWER]
## Die Kennungen der Zeilen der Gradwahl, je Grad in LEVELS eine.
const LEVEL_IDS: Array[StringName] = [&"easy", &"medium", &"hard"]

## GameSession hat als Autoload keinen class_name; den Typ gibt sein Skript.
const SESSION_SCRIPT := preload("res://core/game_session.gd")

## null heißt das Autoload GameSession; Tests setzen eine eigene.
var session: Node = null
## Wechselt die Szene und bekommt dafür den Pfad der neuen Szene; ungültig heißt
## get_tree().change_scene_to_file(). Tests setzen eine eigene Funktion und prüfen den Aufruf statt
## des echten Wechsels (wie GameSession.quit_callback; Analyse, C1).
var scene_callback: Callable

## Die Spielstände, aus denen das Hauptmenü zuletzt gebaut wurde. „Weiterspielen“ setzt den ersten
## fortsetzbaren davon fort, den Stand, den das Menü gelesen hat (CHK001).
var _slots: Array[SaveSlot] = []
## Der Eintrag des Hauptmenüs, der das sichtbare Blatt geöffnet hat; zurück im Hauptmenü steht
## die Auswahl wieder auf ihm.
var _opener_id: StringName = &""
## Die gewählte Zeile des sichtbaren Blatts in globalen Koordinaten; dort erscheint eine Meldung.
var _selected_row := Rect2()

@onready var _main_menu: MainMenu = $MainMenu
@onready var _difficulty_sheet: MainMenu = $DifficultySheet
@onready var _menu_hint: MenuHint = $MenuHint
@onready var _version_line: Label = $VersionLine


func _ready() -> void:
	# Die Nummer steht in project.godot und nicht in der Szene. So zeigt die Zeile immer die
	# Version des laufenden Spiels (FR-014).
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	_version_line.text = version_text(version)
	_main_menu.header_text = TitleTexts.HEADER_MAIN
	_difficulty_sheet.header_text = TitleTexts.HEADER_DIFFICULTY
	# Zeitversetzt: MainMenu._ready() hat seine Startzeile schon mit call_deferred() bestellt, mit
	# dem Wert von damals, Zeile 0. Zeitversetzte Aufrufe laufen in der Reihenfolge der Bestellung.
	# Käme set_entries() jetzt, wählte jener spätere Aufruf danach wieder Zeile 0; so kommt
	# _build_sheets() nach ihm, und seine Wahl gilt.
	_build_sheets.call_deferred()


## Esc führt eine Ebene zurück, im Hauptmenü tut es nichts (FR-023). Hier und nicht in den Blättern:
## Welche Ebene darüber liegt, weiß nur der Titelbildschirm. _unhandled_input() bekommt die Taste
## erst, wenn kein Bedienelement sie genommen hat; die Zeilen des Menüs nehmen Esc nicht.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel") or not _difficulty_sheet.visible:
		return
	get_viewport().set_input_as_handled()
	_go_back()


## Der Text der Versionszeile: Aus „0.1“ wird „V0.1 · PROTOTYP“. Ohne Version steht nur
## das Kennzeichen da, kein „V“ ohne Zahl.
static func version_text(version: String) -> String:
	if version.is_empty():
		return STAGE
	return "V%s · %s" % [version, STAGE]


## Führt den ausgelösten Eintrag des Hauptmenüs aus. Verbunden in title_screen.tscn. Das Menü
## meldet nur verfügbare Einträge.
func _on_main_menu_entry_activated(id: StringName) -> void:
	match id:
		&"continue":
			_continue()
		&"new_game":
			_open_difficulty_sheet()
		&"quit":
			# Ohne Rückfrage (Feature 001, FR-008); es läuft kein Spiel. quit() beendet nicht
			# sofort, sondern am Ende des laufenden Bilds.
			get_tree().quit()
		# &"load_game" öffnet mit Phase 5 die Liste der Spielstände (T026); bis dahin tut es
		# nichts.


## Führt den ausgelösten Eintrag der Gradwahl aus. Verbunden in title_screen.tscn.
func _on_difficulty_sheet_entry_activated(id: StringName) -> void:
	# Etwas auslösen beendet eine Meldung (Style-Guide, Baustein Meldung).
	_menu_hint.hide_hint()
	if id == &"back":
		_go_back()
		return
	var index := LEVEL_IDS.find(id)
	if index != -1:
		_start_new(LEVELS[index])


## Zeigt den Hinweis zur gewählten Zeile neben ihr, für jedes Blatt. Beide Blätter sind in
## title_screen.tscn mit dieser einen Methode verbunden; gemeldet wird nur vom sichtbaren.
func _on_sheet_selection_changed(entry: MenuEntry, row_rect: Rect2) -> void:
	_selected_row = row_rect
	_menu_hint.show_for(entry, row_rect)


## Baut beim Erscheinen die Einträge beider Blätter und zeigt das Hauptmenü.
func _build_sheets() -> void:
	# Die Gradwahl ist noch unsichtbar: set_entries() merkt sich die Zeile nur, und das Blatt
	# nimmt keinen Fokus.
	_difficulty_sheet.set_entries(_difficulty_entries(), _medium_index())
	_show_main_menu(&"")


## Zeigt das Hauptmenü, mit Einträgen aus dem frisch gelesenen Ordner. Gewählt ist der Eintrag
## [param opener_id], wenn das Hauptmenü aus einem Blatt zurückkehrt; leer heißt die Vorwahl beim
## Erscheinen (FR-001a).
func _show_main_menu(opener_id: StringName) -> void:
	_slots = _session().store().list_slots()
	var entries := _main_entries(_slots)
	var index := _preselected_index(entries)
	for row in entries.size():
		if entries[row].id == opener_id:
			index = row
	_opener_id = &""
	_show_only(_main_menu)
	# Das Menü ist jetzt sichtbar: set_entries() baut die Zeilen und gibt der gewählten den Fokus,
	# und deren selection_changed bringt den Hinweis.
	_main_menu.set_entries(entries, index)


func _open_difficulty_sheet() -> void:
	_opener_id = &"new_game"
	_show_only(_difficulty_sheet)
	# Jedes Öffnen beginnt bei Mittel (FR-004). Erst jetzt ist das Blatt sichtbar und nimmt den
	# Fokus.
	_difficulty_sheet.select(_medium_index())


## Eine Ebene zurück: aus der Gradwahl ins Hauptmenü, auf den Eintrag, der sie geöffnet hat.
func _go_back() -> void:
	_menu_hint.hide_hint()
	_show_main_menu(_opener_id)


## Zeigt [param sheet] und verbirgt jedes andere Blatt. Erst verbergen, dann zeigen: Ein Control,
## das unsichtbar wird, gibt den Fokus ab, auch den eines Buttons darin.
func _show_only(sheet: MainMenu) -> void:
	for other: MainMenu in [_main_menu, _difficulty_sheet]:
		if other != sheet:
			other.visible = false
	sheet.visible = true


## Beginnt ein Spiel mit [param level] (FR-006). Gelingt das Anlegen, führt es zum Spielbildschirm;
## sonst steht die Meldung der Session an der gewählten Zeile, und die Gradwahl bleibt (FR-011).
func _start_new(level: Difficulty.Level) -> void:
	var game_session := _session()
	if game_session.start_new(level) == OK:
		_change_scene(GAME_SCENE)
		return
	_menu_hint.show_warning(game_session.last_error, _selected_row)


## Setzt den ersten fortsetzbaren Spielstand fort, den zuletzt gespielten (data-model.md,
## „Titelbildschirm“). Scheitert das Speichern dabei, läuft das Spiel trotzdem, und der
## Spielbildschirm zeigt die Meldung. Lässt sich der Spielstand gar nicht fortsetzen, liest das
## Hauptmenü den Ordner neu.
func _continue() -> void:
	var slot := _first_resumable(_slots)
	var error := _session().resume(slot)
	if error == OK:
		_change_scene(GAME_SCENE)
		return
	push_warning("Titel: Weiterspielen ging nicht (%s)." % error_string(error))
	_show_main_menu(&"")


## Wechselt zur Szene [param path]: über scene_callback, ohne ihn mit change_scene_to_file().
func _change_scene(path: String) -> void:
	if scene_callback.is_valid():
		scene_callback.call(path)
	else:
		get_tree().change_scene_to_file(path)


## Die fünf Einträge des Hauptmenüs nach FR-001 und FR-002: „Weiterspielen“ nur mit einem
## fortsetzbaren Spielstand, „Spiel laden“ mit irgendeinem, auch einem beschädigten; die Hinweise
## nennen sonst den Grund.
func _main_entries(slots: Array[SaveSlot]) -> Array[MenuEntry]:
	var resumable := _first_resumable(slots)
	var continue_hint := TitleTexts.HINT_CONTINUE_NO_SAVES
	if resumable != null:
		var game := resumable.game
		continue_hint = TitleTexts.continue_hint(game.name, Difficulty.label(game.difficulty),
			game.day_text())
	elif not slots.is_empty():
		continue_hint = TitleTexts.HINT_CONTINUE_NONE_RESUMABLE
	var has_slots := not slots.is_empty()
	return [
		_entry(&"continue", TitleTexts.LABEL_CONTINUE, resumable != null, continue_hint),
		_entry(&"new_game", TitleTexts.LABEL_NEW_GAME, true, TitleTexts.HINT_NEW_GAME),
		_entry(&"load_game", TitleTexts.LABEL_LOAD_GAME, has_slots,
			TitleTexts.HINT_LOAD_GAME if has_slots else TitleTexts.HINT_LOAD_GAME_NO_SAVES),
		_entry(&"settings", TitleTexts.LABEL_SETTINGS, false, TitleTexts.HINT_SETTINGS),
		_entry(&"quit", TitleTexts.LABEL_QUIT, true, TitleTexts.HINT_QUIT),
	]


## Die vier Einträge der Gradwahl: die Grade mit ihrem Satz als Hinweis (R13), dann „Zurück“.
func _difficulty_entries() -> Array[MenuEntry]:
	var entries: Array[MenuEntry] = []
	for index in LEVELS.size():
		entries.append(_entry(LEVEL_IDS[index], Difficulty.label(LEVELS[index]), true,
			TitleTexts.difficulty_hint(LEVELS[index])))
	entries.append(_entry(&"back", TitleTexts.LABEL_BACK, true, TitleTexts.HINT_BACK))
	return entries


## Vorwahl beim Erscheinen (FR-001a): „Weiterspielen“, wenn es verfügbar ist, sonst „Neues Spiel“.
static func _preselected_index(entries: Array[MenuEntry]) -> int:
	return 0 if entries[0].available else 1


static func _medium_index() -> int:
	return LEVELS.find(Difficulty.Level.MITTEL)


## Der erste fortsetzbare Spielstand; die Liste ist nach „zuletzt gespielt“ geordnet (R12). null,
## wenn es keinen gibt.
static func _first_resumable(slots: Array[SaveSlot]) -> SaveSlot:
	for slot in slots:
		if slot.can_resume():
			return slot
	return null


static func _entry(id: StringName, label: String, available: bool, hint: String) -> MenuEntry:
	var entry := MenuEntry.new()
	entry.id = id
	entry.label = label
	entry.available = available
	entry.hint = hint
	return entry


## Die Session: session oder das Autoload GameSession.
func _session() -> SESSION_SCRIPT:
	return (session if session != null else GameSession) as SESSION_SCRIPT
