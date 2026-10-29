class_name TitleScreen
extends Control

## Der Titelbildschirm: Titelbild T-02, Logo mit Untertitel, die Versionszeile oben rechts im freien
## Himmel und rechts unten der Communicator mit dem Gehäuse des Organizers (Feature 005,
## contracts/titelbildschirm.md; Style-Guide, Baustein Communicator). Logo, Untertitel und
## Versionszeile stehen direkt auf dem Bild und tragen deshalb den pixelschatten (Style-Guide,
## README, Logo).
##
## Er setzt die Teile nur zusammen und verbindet sie. Ein Blatt meldet die gewählte Zeile per
## Signal, der Titelbildschirm reicht sie über den Communicator an den Hinweis weiter. Blätter und
## Hinweis kennen einander nicht. Ebenso meldet ein Blatt einen ausgelösten Eintrag nur; was dann
## geschieht, entscheidet der Titelbildschirm.
##
## Seit Feature 004 gibt es mehrere Blätter an derselben Stelle (contracts/titelbildschirm.md):
## Hauptmenü, Gradwahl und Rückfrage sind je eine Instanz von main_menu.tscn, die Liste der
## Spielstände ist eine SaveList. Seit Feature 005 stehen sie als Seiten auf der Anzeige des
## Communicators (look = LCD); welche zu sehen ist, sagt Communicator.show_page(). Es ist immer
## genau eine zu sehen; eine unsichtbare hat keinen Fokus. Esc und „Zurück“ führen eine Ebene
## zurück, im Hauptmenü tut Esc nichts; im Löschmodus der Liste beenden beide nur den Modus. Die
## Einträge des Hauptmenüs entstehen zur Laufzeit aus den Spielständen im Ordner der Session, beim
## Erscheinen und bei jeder Rückkehr aus einem Blatt neu gelesen (Analyse, F2); ebenso liest „Spiel
## laden“ den Ordner bei jedem Öffnen neu (CHK001). Alle Texte kommen aus TitleTexts, auch
## Untertitel und Versionszeile; in der Szene stehen sie leer.
##
## Ein Spiel beginnt oder setzt fort nur über die Session, gelöscht wird nur über ihren SaveStore;
## den Spielbildschirm zeigt scene_callback. Wege und Vorwahl: data-model.md, „Titelbildschirm:
## Blätter und Wege“.
##
## Der Communicator fährt (Feature 005, contracts/titelbildschirm.md, „Verhalten“; R8): Beim
## Erscheinen steht er draußen und fährt herein, sobald das Hauptmenü Einträge und Auswahl hat; bis
## dahin fängt die Wache _ready_for_input jede Eingabe ab. Beginnt oder setzt der Spieler ein Spiel
## fort, fährt er erst hinaus, und der Spielbildschirm kommt mit slide_finished. Ab dann fängt
## _leaving jede Eingabe ab, zusätzlich zur Sperre im Communicator.
##
## Das Easter Egg (Feature 006, contracts/titelbildschirm.md, „TitleScreen, neu“): Die drei grauen
## Tasten im Gehäuse melden sich mit case_key_pressed. Was die Drücke bedeuten, weiß der Titel, nicht
## der Communicator; er gibt sie an die Folge _sequence weiter. Links, Mitte, rechts startet Space
## Invaders als fünfte Seite auf der Anzeige. Vorher merkt sich der Titel Seite und Fokus; Zeile und
## Hinweis führt er ohnehin. Meldet die Seite finished, steht alles wieder so da wie vorher. Das
## Easter Egg berührt weder die Session noch einen Spielstand (FR-007).

## Der Spielbildschirm, zu dem ein begonnenes oder fortgesetztes Spiel führt.
const GAME_SCENE := "res://scenes/game/game_screen.tscn"
## Die Grade der Gradwahl in der Reihenfolge der Zeilen (FR-004).
const LEVELS: Array[Difficulty.Level] = [Difficulty.Level.LEICHT, Difficulty.Level.MITTEL,
	Difficulty.Level.SCHWER]
## Die Kennungen der Zeilen der Gradwahl, je Grad in LEVELS eine.
const LEVEL_IDS: Array[StringName] = [&"easy", &"medium", &"hard"]
## Die Folge der Gehäusetasten, die Space Invaders startet: links, Mitte, rechts (FR-002).
const EASTER_EGG_KEYS: Array[int] = [0, 1, 2]

## GameSession hat als Autoload keinen class_name; den Typ gibt sein Skript.
const SESSION_SCRIPT := preload("res://core/game_session.gd")

## null heißt das Autoload GameSession; Tests setzen eine eigene.
var session: Node = null
## Wechselt die Szene und bekommt dafür den Pfad der neuen Szene; ungültig heißt
## get_tree().change_scene_to_file(). Tests setzen eine eigene Funktion und prüfen den Aufruf statt
## des echten Wechsels (wie GameSession.quit_callback; Analyse, C1).
var scene_callback: Callable
## Wird bei „Beenden“ aufgerufen; ungültig heißt get_tree().quit(). Tests setzen eine eigene
## Funktion, denn quit() beendete ihren ganzen Lauf (wie GameSession.quit_callback).
var quit_callback: Callable

## Die Spielstände, aus denen das Hauptmenü zuletzt gebaut wurde. „Weiterspielen“ setzt den ersten
## fortsetzbaren davon fort, den Stand, den das Menü gelesen hat (CHK001).
var _slots: Array[SaveSlot] = []
## Der Eintrag des Hauptmenüs, der das sichtbare Blatt geöffnet hat; zurück im Hauptmenü steht
## die Auswahl wieder auf ihm.
var _opener_id: StringName = &""
## Die gewählte Zeile des sichtbaren Blatts, relativ zum Communicator; dort erscheint eine Meldung.
## Relativ, weil der Communicator fährt: Eine Zeile, die während der Fahrt herein gewählt wurde,
## steht später woanders, und die Meldung gehört neben die Zeile, wo sie jetzt ist (Analyse, C3).
## _current_row() rechnet sie in die jetzige Lage um.
var _selected_row := Rect2()
## Der Hinweis der gewählten Zeile; beim Hinausfahren steht er wieder da und fährt mit dem Gerät.
var _selected_hint := ""
## Die Wache vor den Einträgen: false, bis das Hauptmenü Einträge und Auswahl hat. Die Sichtbarkeit
## des Hauptmenüs taugt dafür nicht, denn der Communicator verbirgt alle Seiten schon in seinem
## _ready() (Analyse, C4).
var _ready_for_input := false
## true ab dem Moment, in dem ein Spiel begonnen oder fortgesetzt ist und der Communicator
## hinausfährt; dann tut keine Eingabe mehr etwas, und es entsteht kein zweites Spiel (R8; B2).
var _leaving := false
## Die Spielstände, die die Liste gerade zeigt, in ihrer Reihenfolge. Fortsetzen und Löschen nehmen
## den Stand, den die Liste gelesen hat (CHK001).
var _list_slots: Array[SaveSlot] = []
## Der Spielstand, nach dem die Rückfrage fragt, und seine Zeile in der Liste; null, solange keine
## Rückfrage offen ist.
var _confirm_slot: SaveSlot = null
var _confirm_index := 0
## Die Nummer des Spielstands, zu dem die Meldung „Löschen ging nicht“ gehört; -1, solange keine
## steht. Die Meldung gehört zum Spielstand, nicht zur Stelle: Rollt die Liste, zeigt dieselbe Zeile
## einen anderen Spielstand, und dann gilt dessen Hinweis.
var _warning_number := -1
## Wie weit die Folge der Gehäusetasten gekommen ist. Ein neuer Titel beginnt mit einer neuen Folge,
## also bei 0, auch nach „Zum Hauptmenü“.
var _sequence := KeySequence.new(EASTER_EGG_KEYS)
## Die Seite, die beim Start des Easter Eggs zu sehen war, und das Control, das den Fokus hatte;
## null, solange kein Spiel auf der Anzeige steht. Zeile und Hinweis stehen schon in _selected_row und
## _selected_hint (Analyse, D1).
var _return_page: Control = null
var _return_focus: Control = null

@onready var _communicator: Communicator = $Communicator
@onready var _main_menu: MainMenu = $Communicator/MainMenu
@onready var _difficulty_sheet: MainMenu = $Communicator/DifficultySheet
@onready var _save_list: SaveList = $Communicator/SaveList
@onready var _confirm_sheet: MainMenu = $Communicator/ConfirmSheet
@onready var _invaders: InvadersPage = $Communicator/Invaders
@onready var _version_line: Label = $VersionLine
@onready var _subtitle: Label = $LogoBlock/Subtitle
@onready var _logo: TextureRect = $LogoBlock/Logo
@onready var _logo_shadow: TextureRect = $LogoBlock/Logo/Shadow


func _ready() -> void:
	# Die Nummer steht in project.godot und nicht in der Szene. So zeigt die Zeile immer die
	# Version des laufenden Spiels (FR-014).
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	_version_line.text = version_text(version)
	_subtitle.text = TitleTexts.SUBTITLE
	# Der pixelschatten des Logos: dieselbe Form in tusche, 2 nach rechts unten, hinter dem Logo
	# (show_behind_parent in der Szene). Die Farbe kommt aus UiPalette, nicht aus der Szene.
	_logo_shadow.texture = silhouette(_logo.texture, UiPalette.TUSCHE)
	# Draußen hinstellen, ohne Sperre: _build_sheets() setzt gleich Einträge und Auswahl, dann
	# fährt der Communicator herein (Analyse, C5).
	_communicator.place_hidden()
	_main_menu.header_text = TitleTexts.HEADER_MAIN
	_difficulty_sheet.header_text = TitleTexts.HEADER_DIFFICULTY
	_confirm_sheet.header_text = TitleTexts.HEADER_CONFIRM
	# Wie der Vertrag es sagt, im Code verbunden statt in der Szene (beide neu in Feature 006).
	_communicator.case_key_pressed.connect(_on_communicator_case_key_pressed)
	_invaders.finished.connect(_on_invaders_finished)
	# Zeitversetzt: MainMenu._ready() hat seine Startzeile schon mit call_deferred() bestellt, mit
	# dem Wert von damals, Zeile 0. Zeitversetzte Aufrufe laufen in der Reihenfolge der Bestellung.
	# Käme set_entries() jetzt, wählte jener spätere Aufruf danach wieder Zeile 0; so kommt
	# _build_sheets() nach ihm, und seine Wahl gilt.
	_build_sheets.call_deferred()


## Esc führt eine Ebene zurück, im Hauptmenü tut es nichts (FR-023): aus der Rückfrage in die
## Liste, aus dem Löschmodus in die Liste ohne Modus, aus Liste und Gradwahl ins Hauptmenü. Hier und
## nicht in den Blättern: Welche Ebene darüber liegt, weiß nur der Titelbildschirm.
## _unhandled_input() bekommt die Taste erst, wenn kein Bedienelement sie genommen hat; die Zeilen
## von Menü und Liste nehmen Esc nicht.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	# Vor den Einträgen und beim Hinausfahren fängt der Titel Esc ab und tut nichts.
	if not _accepts_input():
		get_viewport().set_input_as_handled()
		return
	# Steht das Spiel auf der Anzeige, gehört Esc ihm. Kommt es trotzdem hier an, etwa in dem Bild,
	# in dem die Seite ihren Fokus zurückholt, führt es nicht eine Ebene zurück (Analyse, C3).
	if _invaders.visible:
		get_viewport().set_input_as_handled()
		return
	if _main_menu.visible:
		return
	get_viewport().set_input_as_handled()
	if _confirm_sheet.visible:
		_cancel_delete()
	elif _save_list.visible:
		# Esc wirkt wie „Zurück“ in der Liste, im Löschmodus wie außerhalb.
		_on_save_list_back_requested()
	else:
		_go_back()


## Der Text der Versionszeile: Aus „0.1“ wird „V0.1 · PROTOTYP“. Ohne Version steht nur
## das Kennzeichen da, kein „V“ ohne Zahl.
static func version_text(version: String) -> String:
	if version.is_empty():
		return TitleTexts.STAGE
	return TitleTexts.version_line(version)


## Die Silhouette von [param texture]: jedes Pixel, das nicht ganz durchsichtig ist, in
## [param color], alle anderen ganz durchsichtig. Daraus wird der pixelschatten eines Bilds, ein
## harter Versatz ohne Unschärfe (Style-Guide, pixelschatten). Ein Bild ist nur ganz durchsichtig
## oder ganz deckend (test_bilder.gd); die Silhouette also auch.
##
## Ein Shader könnte dasselbe auf der Grafikkarte, aber eine Farbe als Uniform läuft dort je nach
## Farbraum durch eine Umrechnung. So ist jedes Pixel genau die Farbe aus UiPalette, und ein Test
## kann es nachlesen.
static func silhouette(texture: Texture2D, color: Color) -> ImageTexture:
	var image := texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	var clear := Color(color, 0.0)
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, color if image.get_pixel(x, y).a > 0.0 else clear)
	return ImageTexture.create_from_image(image)


## Führt den ausgelösten Eintrag des Hauptmenüs aus. Verbunden in title_screen.tscn. Das Menü
## meldet nur verfügbare Einträge.
func _on_main_menu_entry_activated(id: StringName) -> void:
	if not _accepts_input():
		return
	match id:
		&"continue":
			_continue()
		&"new_game":
			_open_difficulty_sheet()
		&"load_game":
			_open_save_list()
		&"quit":
			# Ohne Rückfrage (Feature 001, FR-008) und ohne Fahrt hinaus (FR-013a); es läuft kein
			# Spiel.
			_quit()


## Führt den ausgelösten Eintrag der Gradwahl aus. Verbunden in title_screen.tscn.
func _on_difficulty_sheet_entry_activated(id: StringName) -> void:
	if not _accepts_input():
		return
	# Etwas auslösen beendet eine Meldung (Style-Guide, Baustein Meldung).
	_hide_hint()
	if id == &"back":
		_go_back()
		return
	var index := LEVEL_IDS.find(id)
	if index != -1:
		_start_new(LEVELS[index])


## Zeigt den Hinweis zur gewählten Zeile neben ihr, für jedes Blatt aus main_menu.tscn. Alle drei
## sind in title_screen.tscn mit dieser einen Methode verbunden; gemeldet wird nur vom sichtbaren.
##
## Ohne Wache: Die erste Auswahl kommt aus _build_sheets(), noch bevor _ready_for_input true ist,
## und ihr Hinweis soll stehen. Während der Fahrt hinaus meldet keine Seite eine Auswahl, denn der
## Communicator sperrt sie.
func _on_sheet_selection_changed(entry: MenuEntry, row_rect: Rect2) -> void:
	_remember_row(row_rect, entry.hint)
	_communicator.show_hint(entry.hint, row_rect)


## Wie _on_sheet_selection_changed(), für die Liste: Sie meldet den Text des Hinweises selbst, denn
## ihre Zeilen sind keine MenuEntry. Verbunden in title_screen.tscn.
##
## Steht die Meldung zum Löschen, entscheidet der Spielstand der Zeile, nicht ihre Stelle: Ist er
## noch gewählt, wandert die Meldung mit an die neue Stelle, etwa wenn das Mausrad seine Zeile
## verschiebt. Sonst ersetzt der Hinweis sie, auch an derselben Stelle; show_text() allein ließe sie
## dort stehen, denn der Hinweis kennt nur Stellen.
func _on_save_list_selection_changed(hint: String, row_rect: Rect2) -> void:
	_remember_row(row_rect, hint)
	if _warning_number != -1:
		var slot := _save_list.selected_slot()
		if slot != null and slot.number == _warning_number:
			_communicator.show_warning(TitleTexts.MESSAGE_DELETE_FAILED, row_rect)
			return
		_hide_hint()
	_communicator.show_hint(hint, row_rect)


## Eine fortsetzbare Zeile der Liste wurde ausgelöst (FR-016): fortsetzen wie „Weiterspielen“, mit
## dem Stand, den die Liste gelesen hat. Verbunden in title_screen.tscn; nicht fortsetzbare Zeilen
## meldet die Liste gar nicht erst.
func _on_save_list_resume_requested(slot: SaveSlot) -> void:
	if not _accepts_input():
		return
	_hide_hint()
	var error := _session().resume(slot)
	if error == OK:
		_leave()
		return
	# Bei einem fortsetzbaren Spielstand kommt das nicht vor; dann liest die Liste den Ordner neu.
	push_warning("Titel: %s ließ sich nicht fortsetzen (%s)." % [slot.display_name(),
		error_string(error)])
	if not _reload_save_list(_list_slots.find(slot)):
		_show_main_menu(&"")


## Im Löschmodus wurde eine Zeile ausgelöst: die Rückfrage zu ihr (FR-017). Verbunden in
## title_screen.tscn.
func _on_save_list_delete_requested(slot: SaveSlot) -> void:
	if not _accepts_input():
		return
	_hide_hint()
	_confirm_slot = slot
	_confirm_index = maxi(_list_slots.find(slot), 0)
	_show_only(_confirm_sheet)
	# Erst sichtbar, dann die Einträge: So nimmt „Abbrechen“ gleich den Fokus, und sein Hinweis
	# kommt mit selection_changed (data-model.md, „Vorwahl in Blättern“).
	_confirm_sheet.set_entries(_confirm_entries(slot), 0)


## „Zurück“ in der Liste, verbunden in title_screen.tscn; Esc kommt auch hierher. Im Löschmodus
## endet nur der Modus, und die Liste bleibt mit der Auswahl, wo sie war (Analyse, F3); sonst geht es
## ins Hauptmenü auf „Spiel laden“.
func _on_save_list_back_requested() -> void:
	if not _accepts_input():
		return
	_hide_hint()
	if _save_list.is_delete_mode():
		# Die Liste ist sichtbar: set_delete_mode() wählt die Zeile neu und bringt ihren Hinweis.
		_save_list.set_delete_mode(false)
		return
	_go_back()


## Führt den ausgelösten Eintrag der Rückfrage aus. Verbunden in title_screen.tscn.
func _on_confirm_sheet_entry_activated(id: StringName) -> void:
	if not _accepts_input():
		return
	_hide_hint()
	match id:
		&"cancel":
			_cancel_delete()
		&"delete":
			_delete_confirmed()


## Die Fahrt hinaus ist zu Ende: Erst jetzt kommt der Spielbildschirm (R8). Verbunden in
## title_screen.tscn. Die Fahrt herein meldet sich auch; dann ist nichts zu tun.
func _on_communicator_slide_finished(arrived_in: bool) -> void:
	if arrived_in or not _leaving:
		return
	_change_scene(GAME_SCENE)


## Eine Gehäusetaste ist gedrückt (Feature 006). Sie zählt nur, wenn der Titel Eingaben annimmt
## und das Spiel nicht schon auf der Anzeige steht; sonst klickt sie nur (R5, R16; FR-004). Ist die
## Folge damit voll, startet das Spiel.
func _on_communicator_case_key_pressed(index: int) -> void:
	if not _accepts_input() or _invaders.visible:
		return
	if _sequence.press(index):
		_start_invaders()


## Startet Space Invaders auf der Anzeige (contracts/titelbildschirm.md, „Start“). Gemerkt werden
## Seite und Fokus; dann gehen Hinweis und Meldung weg (Analyse, C2). Erst wird die Seite gezeigt,
## dann gestartet: Nur eine sichtbare Seite kann den Fokus nehmen (Analyse, C1). Das Gerät bewegt
## sich nicht (FR-010).
func _start_invaders() -> void:
	_sequence.reset()
	_return_page = _communicator.current_page()
	_return_focus = get_viewport().gui_get_focus_owner()
	_hide_hint()
	_communicator.show_page(_invaders)
	_invaders.start()


## Das Spiel ist zu Ende, nach der Ergebnisanzeige oder mit Esc: dieselbe Seite, derselbe Fokus,
## derselbe Hinweis wie beim Start (FR-022). Eine Meldung von damals kommt als Hinweis der Zeile
## zurück, nicht als Meldung (CHK008); _hide_hint() hat sie beim Start vergessen.
##
## Die Taste, die das Spiel beendet hat, wird gleich danach losgelassen. Das Loslassen geht an die
## Zeile mit dem Fokus und löst dort nichts aus, denn ihr Drücken kam nie dort an.
func _on_invaders_finished() -> void:
	var page := _return_page
	var focus := _return_focus
	_return_page = null
	_return_focus = null
	_sequence.reset()
	if page == null:
		page = _main_menu
	_communicator.show_page(page)
	_restore_focus(page, focus)
	_communicator.show_hint(_selected_hint, _current_row())


## Gibt [param focus] den Fokus zurück; ist es noch nicht zu sehen, erst nach diesem Bild. Fehlt
## es, weil beim Start kein Control den Fokus hatte, wählt [param page] ihre gemerkte Zeile neu.
func _restore_focus(page: Control, focus: Control) -> void:
	if focus != null and is_instance_valid(focus) and focus.is_inside_tree():
		if focus.is_visible_in_tree():
			focus.grab_focus()
		else:
			focus.grab_focus.call_deferred()
		return
	if page.has_method(&"select") and page.has_method(&"selected_index"):
		page.call(&"select", page.call(&"selected_index"))


## Baut beim Erscheinen die Einträge von Hauptmenü und Gradwahl, zeigt das Hauptmenü und lässt den
## Communicator hereinfahren. Liste und Rückfrage bekommen ihren Inhalt erst beim Öffnen.
func _build_sheets() -> void:
	# Die Gradwahl ist noch unsichtbar: set_entries() merkt sich die Zeile nur, und das Blatt
	# nimmt keinen Fokus.
	_difficulty_sheet.set_entries(_difficulty_entries(), _medium_index())
	_show_main_menu(&"")
	# Erst Einträge und Auswahl, dann die Wache auf und die Fahrt (Analyse, C4, C5). Herein ist
	# alles bedienbar (FR-003).
	_ready_for_input = true
	_communicator.slide_in()


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


## „Spiel laden“: liest den Ordner neu und zeigt die Liste, die oberste Zeile gewählt (CHK001).
## Ist der Ordner inzwischen leer, etwa weil ein zweites Fenster gelöscht hat, bleibt es beim
## Hauptmenü, neu gelesen und auf „Spiel laden“, dessen Hinweis dann sagt, dass es keine gibt.
func _open_save_list() -> void:
	if not _reload_save_list(0):
		_show_main_menu(&"load_game")
		return
	_opener_id = &"load_game"


## Liest den Ordner neu und zeigt die Liste mit Zeile [param index] gewählt, Löschmodus aus; eine
## Zeile hinter dem letzten Spielstand wird der letzte. false und nichts gezeigt, wenn der Ordner
## keinen Spielstand hat.
func _reload_save_list(index: int) -> bool:
	_list_slots = _session().store().list_slots()
	if _list_slots.is_empty():
		return false
	# Die Liste ist hier noch unsichtbar oder gleich wieder sichtbar: show_slots() merkt sich die
	# Zeile, _show_save_list() wählt sie, sobald das Blatt zu sehen ist.
	_save_list.show_slots(_list_slots, clampi(index, 0, _list_slots.size() - 1))
	_show_save_list()
	return true


## Zeigt die Liste mit der Zeile, die sie sich gemerkt hat. Unsichtbar meldet sie keine Auswahl und
## nimmt keinen Fokus; erst select() nach dem Zeigen bringt beides und den Hinweis.
func _show_save_list() -> void:
	_show_only(_save_list)
	_save_list.select(_save_list.selected_index())


## Abbrechen in der Rückfrage, auch mit Esc: zurück in die Liste, Löschmodus aus, die Auswahl auf
## dem Spielstand, nach dem gefragt wurde (FR-017a). Die Liste liest dafür nicht neu; gelöscht
## wurde nichts.
func _cancel_delete() -> void:
	_hide_hint()
	_confirm_slot = null
	_save_list.set_delete_mode(false)
	_show_save_list()


## Löschen bestätigt (FR-018): nur die Dateien dieser Nummer über SaveStore.delete(), dann die
## Liste neu gelesen, Löschmodus aus, die Auswahl auf der Zeile, die an die Stelle rückt, sonst auf
## der letzten. Ist keiner mehr da, das Hauptmenü mit „Neues Spiel“ (US4, Szenario 5).
##
## Scheitert das Löschen, steht die Meldung an der Zeile des Spielstands, wenn er danach noch in der
## Liste steht (CHK003; Analyse, E2), und das Protokoll nennt Datei und Fehler. Ist die Datei schon
## weg (ERR_FILE_NOT_FOUND), etwa weil ein zweites Fenster sie gelöscht hat, gibt es keine Meldung:
## Was der Spieler wollte, ist erreicht (Claude, 2026-10-26).
func _delete_confirmed() -> void:
	var slot := _confirm_slot
	_confirm_slot = null
	var saves := _session().store()
	var error := saves.delete(slot.number)
	var failed := error != OK and error != ERR_FILE_NOT_FOUND
	if failed:
		push_warning("Titel: %s ließ sich nicht löschen. %s" % [slot.display_name(),
			saves.last_error])
	_list_slots = saves.list_slots()
	if _list_slots.is_empty():
		_show_main_menu(&"")
		return
	var index := mini(_confirm_index, _list_slots.size() - 1)
	var still_there := _index_of_number(_list_slots, slot.number) if failed else -1
	if still_there != -1:
		index = still_there
	_save_list.show_slots(_list_slots, index)
	# Steht er noch da, gehört die Meldung zu ihm: _show_save_list() wählt seine Zeile, und
	# _on_save_list_selection_changed() zeigt statt ihres Hinweises die Meldung. Sie bleibt, bis ein
	# anderer Spielstand, „Löschen …“ oder „Zurück“ gewählt oder etwas ausgelöst wird.
	if still_there != -1:
		_warning_number = slot.number
	_show_save_list()


## Eine Ebene zurück ins Hauptmenü, auf den Eintrag, der das Blatt geöffnet hat: aus der Gradwahl
## und aus der Liste außerhalb des Löschmodus.
func _go_back() -> void:
	_hide_hint()
	_show_main_menu(_opener_id)


## Blendet Hinweis und Meldung aus. Mit der Meldung geht auch ihr Spielstand: Sonst käme sie zurück,
## sobald seine Zeile wieder gewählt wird, etwa nach Esc und erneutem Öffnen der Liste.
func _hide_hint() -> void:
	_warning_number = -1
	_communicator.hide_hint()


## Zeigt [param sheet] als Seite des Communicators und verbirgt jede andere; der Communicator bewegt
## sich dabei nicht (FR-005). Er verbirgt erst und zeigt dann: Ein Control, das unsichtbar wird,
## gibt den Fokus ab, auch den eines Buttons darin.
func _show_only(sheet: Control) -> void:
	_communicator.show_page(sheet)


## Beginnt ein Spiel mit [param level] (FR-006). Gelingt das Anlegen, führt es zum Spielbildschirm;
## sonst steht die Meldung der Session an der gewählten Zeile, und die Gradwahl bleibt (FR-011).
func _start_new(level: Difficulty.Level) -> void:
	var game_session := _session()
	if game_session.start_new(level) == OK:
		_leave()
		return
	_communicator.show_warning(game_session.last_error, _current_row())


## Setzt den ersten fortsetzbaren Spielstand fort, den zuletzt gespielten (data-model.md,
## „Titelbildschirm“). Scheitert das Speichern dabei, läuft das Spiel trotzdem, und der
## Spielbildschirm zeigt die Meldung. Lässt sich der Spielstand gar nicht fortsetzen, liest das
## Hauptmenü den Ordner neu.
func _continue() -> void:
	var slot := _first_resumable(_slots)
	var error := _session().resume(slot)
	if error == OK:
		_leave()
		return
	push_warning("Titel: Weiterspielen ging nicht (%s)." % error_string(error))
	_show_main_menu(&"")


## Das Spiel läuft schon: _leaving sperrt jede weitere Eingabe, dann fährt der Communicator hinaus,
## und _on_communicator_slide_finished() wechselt die Szene. Der Hinweis der gewählten Zeile steht
## wieder da und fährt mit dem Gerät hinaus; eine Meldung endete schon beim Auslösen. Schließt der
## Spieler während der Fahrt das Fenster, speichert die Session wie in Feature 004.
func _leave() -> void:
	_leaving = true
	_communicator.show_hint(_selected_hint, _current_row())
	_communicator.slide_out()


## Ob eine Eingabe etwas tun darf: erst wenn das Hauptmenü Einträge hat, und nicht mehr beim
## Hinausfahren.
func _accepts_input() -> bool:
	return _ready_for_input and not _leaving


## Merkt sich die gewählte Zeile [param row_rect] (global) relativ zum Communicator und ihren
## Hinweis [param hint].
func _remember_row(row_rect: Rect2, hint: String) -> void:
	_selected_row = Rect2(row_rect.position - _communicator.global_position, row_rect.size)
	_selected_hint = hint


## Die gewählte Zeile in globalen Koordinaten, da, wo der Communicator jetzt steht.
func _current_row() -> Rect2:
	return Rect2(_selected_row.position + _communicator.global_position, _selected_row.size)


## Wechselt zur Szene [param path]: über scene_callback, ohne ihn mit change_scene_to_file().
func _change_scene(path: String) -> void:
	if scene_callback.is_valid():
		scene_callback.call(path)
	else:
		get_tree().change_scene_to_file(path)


## Beendet die App: über quit_callback, ohne ihn mit get_tree().quit().
func _quit() -> void:
	if quit_callback.is_valid():
		quit_callback.call()
	else:
		# quit() beendet nicht sofort, sondern am Ende des laufenden Bilds.
		get_tree().quit()


## Die fünf Einträge des Hauptmenüs nach FR-001 und FR-002: „Weiterspielen“ nur mit einem
## fortsetzbaren Spielstand, „Spiel laden“ mit irgendeinem, auch einem beschädigten; die Hinweise
## nennen sonst den Grund. Der Hinweis von „Spiel laden“ ist immer derselbe, ob sich einer
## fortsetzen lässt oder nicht.
func _main_entries(slots: Array[SaveSlot]) -> Array[MenuEntry]:
	var resumable := _first_resumable(slots)
	var has_slots := not slots.is_empty()
	var continue_hint := TitleTexts.HINT_CONTINUE_NO_SAVES
	if resumable != null:
		var game := resumable.game
		continue_hint = TitleTexts.continue_hint(game.name, Difficulty.label(game.difficulty),
			game.day_text())
	elif has_slots:
		continue_hint = TitleTexts.HINT_CONTINUE_NONE_RESUMABLE
	var load_hint := TitleTexts.HINT_LOAD_GAME if has_slots else TitleTexts.HINT_LOAD_GAME_NO_SAVES
	return [
		_entry(&"continue", TitleTexts.LABEL_CONTINUE, resumable != null, continue_hint),
		_entry(&"new_game", TitleTexts.LABEL_NEW_GAME, true, TitleTexts.HINT_NEW_GAME),
		_entry(&"load_game", TitleTexts.LABEL_LOAD_GAME, has_slots, load_hint),
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


## Die zwei Einträge der Rückfrage zu [param slot] (FR-017; R14): „Abbrechen“, vorgewählt, und
## „Spiel 2 löschen“. Die Hinweise nennen Name, Grad und Spieldatum, bei einem Spielstand, der sich
## nicht fortsetzen lässt, statt Grad und Spieldatum seinen Zustand.
static func _confirm_entries(slot: SaveSlot) -> Array[MenuEntry]:
	var game_name := slot.display_name()
	var cancel_hint: String
	var delete_hint: String
	if slot.can_resume():
		var difficulty := Difficulty.label(slot.game.difficulty)
		var day := slot.game.day_text()
		cancel_hint = TitleTexts.confirm_cancel_hint(game_name, difficulty, day)
		delete_hint = TitleTexts.confirm_delete_hint(game_name, difficulty, day)
	else:
		var state := TitleTexts.STATE_TOO_NEW if slot.state == SaveSlot.State.TOO_NEW \
			else TitleTexts.STATE_DAMAGED
		cancel_hint = TitleTexts.confirm_cancel_hint_unresumable(game_name, state)
		delete_hint = TitleTexts.confirm_delete_hint_unresumable(game_name, state)
	return [
		_entry(&"cancel", TitleTexts.LABEL_CANCEL, true, cancel_hint),
		_entry(&"delete", TitleTexts.delete_label(game_name), true, delete_hint),
	]


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


## Die Zeile des Spielstands mit Nummer [param number] in [param slots]; -1, wenn er fehlt.
static func _index_of_number(slots: Array[SaveSlot], number: int) -> int:
	for index in slots.size():
		if slots[index].number == number:
			return index
	return -1


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
