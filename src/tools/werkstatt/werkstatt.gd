class_name Werkstatt
extends Control

## Die Zeitleisten-Werkstatt (Feature 002; contracts/werkstatt.md): Hier pflegt Klaus den
## Ereigniskatalog ohne Code. Diese Szene ist die Wurzel. Sie richtet das Fenster ein, öffnet den
## Katalog über einen CatalogEditor, fragt nach, bevor etwas verloren gehen könnte, und verdrahtet
## die Teile.
##
## Die Teile sind eigene Szenen bzw. Skripte: Liste, Formular, Prüfung, Zeitstrahl, Simulator,
## Statistik und die Schwierigkeitsgrade. Sie melden nach oben, was geschieht (Signale), und die Werkstatt ruft sie von oben
## auf (refresh(), show_event() …); untereinander kennen sie sich nicht. Den Katalog ändert nur der
## CatalogEditor, die Auswahl gehört der Werkstatt.
##
## Start im Editor mit F6, wenn die Szene offen ist, oder im Terminal, mit `--katalog` nach `--`
## auch für einen anderen Katalog:
## [codeblock]
## Godot --path src res://tools/werkstatt/werkstatt.tscn [-- --katalog res://…]
## [/codeblock]

signal selection_changed(id: String)

## Argument nach „--“, das einen anderen Katalog öffnet, etwa für die Prüfung von SC-011.
const CATALOG_ARGUMENT := "--katalog"
## In der Einstellungsdatei der Abschnitt für die Teiler: je Teiler ein Eintrag, benannt nach
## seinem Pfad unter der Werkstatt, etwa „Layout/Main“, mit seinen split_offsets.
const SPLITS_SECTION := "teiler"
## So lange nach dem letzten Ziehen an einem Teiler wartet die Werkstatt, bevor sie die Lage
## speichert, in Sekunden. Ein Ziehen meldet sich bei jeder Mausbewegung; geschrieben wird erst,
## wenn Ruhe ist.
const SETTINGS_DELAY := 1.0
## Größer ist kein Wert eines Teilers in Pixeln; was darüber liegt, gilt beim Lesen als kaputt.
const MAX_SPLIT_OFFSET := 100000
## So hoch bleibt der Inhalt eines Reiters mindestens, wenn er im zu kleinen Fenster rollt (T043):
## so viel, wie jeder Bereich der Werkstatt mindestens hat.
const MIN_TAB_HEIGHT := 80

## Der Katalog, den die Werkstatt öffnet. Tests setzen ihn, bevor die Szene in den Baum kommt.
var catalog_path: String = EventCatalog.DEFAULT_PATH
## Die Einstellungsdatei der Werkstatt, ein ConfigFile: Darin merkt sie sich die Lage ihrer
## Teiler. Sie liegt unter user://, also außerhalb des Projekts, wie die Sicherungskopie. Tests
## setzen eine eigene Datei, bevor die Szene in den Baum kommt.
var settings_path: String = "user://werkstatt_einstellungen.cfg"
## Der einzige, der den Katalog ändert. Tests setzen hier vorher einen eigenen Ordner für die
## Sicherungskopien (CatalogEditor.backup_folder).
var editor := CatalogEditor.new()
## Das gewählte Ereignis; leer heißt keins.
var selected_id: String = ""
## Was _quit() nach prepare_quit() aufruft, um das Programm zu beenden; ohne Wert
## get_tree().quit(). Tests setzen hier eine eigene Funktion, bevor sie schließen lassen, denn
## get_tree().quit() beendete ihren ganzen Lauf.
var quit_callback := Callable()
## GameWindow, das die Werkstatt beim Einrichten des Fensters anhält (AR-12); null heißt das
## Autoload, geholt über den Pfad /root/GameWindow (_set_up_window()). Tests setzen einen eigenen
## Knoten, bevor die Szene in den Baum kommt.
var game_window: Node = null

## Was nach erfolgreichem Speichern geschehen soll, etwa das Beenden beim Schließen.
var _after_save := Callable()
## Das Ereignis, dessen Löschen gerade bestätigt werden soll.
var _pending_delete := ""
## Ob die Sicherungskopie beim Schließen liegen bleibt: Klaus hat sie beim Start auf später
## verschoben und seitdem keine neue geschrieben.
var _keep_backup := false
## Ob die Werkstatt schon gesagt hat, dass sich die Sicherungskopie nicht schreiben lässt. Sie sagt
## es einmal, nicht alle 2 Minuten; nach einer gelungenen Sicherung wieder beim nächsten Fehler.
var _backup_failed := false
## Ergebnis von open() beim Start; nach der Frage zur Sicherungskopie kommt die zum Katalog.
var _open_error := OK
## Die offenen Dialoge der Werkstatt, der zuletzt geöffnete am Ende (T042).
var _open_dialogs: Array[AcceptDialog] = []

@onready var _save_button: Button = %SaveButton
@onready var _revert_button: Button = %RevertButton
@onready var _undo_button: Button = %UndoButton
@onready var _redo_button: Button = %RedoButton
@onready var _layout: VBoxContainer = $Layout
@onready var _file_label: Label = %FileLabel
@onready var _dirty_label: Label = %DirtyLabel
@onready var _count_label: Label = %CountLabel
@onready var _event_list: EventList = %EventList
@onready var _tabs: TabContainer = %Tabs
@onready var _issues_panel: IssuesPanel = %IssuesPanel
@onready var _event_form: EventForm = %EventForm
@onready var _form_scroll: ScrollContainer = %FormScroll
@onready var _timeline_view: TimelineView = %TimelineView
@onready var _simulator_panel: SimulatorPanel = %SimulatorPanel
@onready var _statistics_panel: StatisticsPanel = %StatisticsPanel
@onready var _difficulty_panel: DifficultyPanel = %DifficultyPanel
@onready var _backup_timer: Timer = %BackupTimer
@onready var _settings_timer: Timer = %SettingsTimer
@onready var _close_dialog: ConfirmationDialog = %CloseDialog
@onready var _revert_dialog: ConfirmationDialog = %RevertDialog
@onready var _delete_dialog: ConfirmationDialog = %DeleteDialog
@onready var _save_errors_dialog: ConfirmationDialog = %SaveErrorsDialog
@onready var _foreign_dialog: ConfirmationDialog = %ForeignChangeDialog
@onready var _backup_dialog: ConfirmationDialog = %BackupDialog
@onready var _missing_dialog: ConfirmationDialog = %MissingDialog
@onready var _unreadable_dialog: AcceptDialog = %UnreadableDialog
@onready var _notice_dialog: AcceptDialog = %NoticeDialog


func _ready() -> void:
	# Ressourcen sind geteilt: Wer das geladene Theme änderte, änderte es für alle, die die Datei
	# laden. Die Schrift kommt deshalb in eine eigene Kopie. Open Sans SemiBold ist Godots
	# eingebaute Schrift und hat keine Datei, die das Theme nennen könnte (R14).
	theme = theme.duplicate()
	theme.default_font = ThemeDB.fallback_font
	_set_up_window()
	catalog_path = catalog_from_args(OS.get_cmdline_user_args(), catalog_path)
	# Das Fenster schließt erst, wenn _notification() es sagt (R15).
	get_tree().auto_accept_quit = false
	_tabs.set_tab_title(0, "Prüfung")
	_tabs.set_tab_title(_tabs.get_tab_idx_from_control(_simulator_panel), "Simulator")
	_tabs.set_tab_title(_tabs.get_tab_idx_from_control(_statistics_panel), "Statistik")
	_tabs.set_tab_title(_tabs.get_tab_idx_from_control(_difficulty_panel), "Schwierigkeitsgrade")
	_event_list.editor = editor
	_event_form.editor = editor
	_timeline_view.editor = editor
	_simulator_panel.editor = editor
	_statistics_panel.editor = editor
	_difficulty_panel.editor = editor
	# Das Häkchen der Statistik nimmt die Eingriffe, die der Simulator gesammelt hat (FR-045). Die
	# Werkstatt reicht sie als Callable weiter; so kennen sich die beiden Teile nicht.
	_statistics_panel.interventions_source = _simulator_interventions
	_set_up_shortcuts()
	_set_up_dialogs()
	_connect_signals()
	restore_settings()
	_fit_tab()
	_update_toolbar()
	# Erst wenn alles im Baum steht, damit die Dialoge sich in der Mitte öffnen können.
	_start.call_deferred()


func _exit_tree() -> void:
	get_tree().auto_accept_quit = true


## Das Betriebssystem will das Fenster schließen: per Fensterknopf, unter macOS auch per Cmd+Q.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_close()


## Liest den Pfad nach „--katalog“ aus den Argumenten hinter „--“; sonst [param fallback].
static func catalog_from_args(args: PackedStringArray, fallback: String) -> String:
	var index := args.find(CATALOG_ARGUMENT)
	if index >= 0 and index + 1 < args.size():
		return args[index + 1]
	return fallback


# --- Auswahl ----------------------------------------------------------------------------------

## Wählt ein Ereignis; leer heißt keins. Liste und Formular folgen über selection_changed.
func select_event(id: String) -> void:
	if id == selected_id:
		return
	selected_id = id
	selection_changed.emit(id)


func _on_selection_changed(id: String) -> void:
	_event_list.select_event(id)
	_event_form.show_event(id)
	_timeline_view.select_event(id)
	# „Neu“ im Reiter „Schwierigkeitsgrade“ nimmt das gewählte Ereignis (R11).
	_difficulty_panel.selected_event_id = id


## Nach einer Änderung kann das gewählte Ereignis fehlen, etwa nach Löschen oder Rückgängig.
func _check_selection() -> void:
	if selected_id.is_empty():
		return
	if editor.catalog == null or editor.catalog.get_event(selected_id) == null:
		select_event("")


# --- Speichern, Verwerfen, Schließen ----------------------------------------------------------

## Speichern über den Knopf oder Cmd+S (FR-034): erst die Eingabe im Feld mit dem Fokus übernehmen,
## bei Fehlern im Katalog nachfragen, dann speichern; hat jemand die Datei inzwischen geändert,
## noch einmal nachfragen. [param then] läuft nach erfolgreichem Speichern.
func request_save(then: Callable = Callable()) -> void:
	if editor.catalog == null:
		return
	_commit_focused_field()
	_after_save = then
	var errors := _count(CatalogIssue.Severity.ERROR)
	if errors > 0:
		_save_errors_dialog.dialog_text = "Der Katalog hat %d Fehler. Trotzdem speichern?" % errors
		_save_errors_dialog.popup_centered(Vector2i(420, 0))
		return
	_save(false)


func _save(force: bool) -> void:
	var error := editor.save(force)
	if error == ERR_FILE_ALREADY_IN_USE and not force:
		_foreign_dialog.dialog_text = "%s\n\nTrotzdem speichern und die Datei überschreiben?" \
			% editor.last_error
		_foreign_dialog.popup_centered(Vector2i(480, 0))
		return
	if error != OK:
		_after_save = Callable()
		_show_notice("Speichern ging nicht", editor.last_error)
		_update_toolbar()
		return
	editor.discard_backup()
	_keep_backup = false
	_update_toolbar()
	var then := _after_save
	_after_save = Callable()
	if then.is_valid():
		then.call()


func _cancel_save() -> void:
	_after_save = Callable()


## Verwerfen über den Knopf: Bei ungespeicherten Änderungen erst nachfragen (FR-034).
func request_revert() -> void:
	if editor.catalog == null:
		return
	_commit_focused_field()
	if editor.is_dirty():
		_revert_dialog.popup_centered(Vector2i(420, 0))
		return
	_revert()


func _revert() -> void:
	if editor.revert() != OK:
		_show_notice("Verwerfen ging nicht", editor.last_error)
	_keep_backup = false
	_update_toolbar()


## Schließen (R15): Bei ungespeicherten Änderungen fragt ein Dialog „Speichern“, „Verwerfen“ oder
## „Abbrechen“. „Speichern“ läuft über dieselben Rückfragen wie der Knopf.
##
## Ist dabei ein anderer Dialog offen, geht er erst zu wie mit „Abbrechen“, beim Dialog zur
## Sicherungskopie also wie mit „Später“ (T042). Dann geht das Schließen weiter wie ohne Dialog.
## Steht die Rückfrage zum Schließen schon da, bleibt sie, wie sie ist; sie ist die Antwort.
func request_close() -> void:
	if _close_dialog.visible:
		return
	_cancel_open_dialogs()
	_commit_focused_field()
	if editor.catalog != null and editor.is_dirty():
		_close_dialog.popup_centered(Vector2i(420, 0))
		return
	_quit()


func _on_close_action(action: StringName) -> void:
	if action == &"discard":
		_close_dialog.hide()
		_quit()


## Was beim regulären Schließen geschieht, bevor das Programm endet: Die Sicherungskopie dieses
## Katalogs fällt weg (FR-050), außer Klaus hat sie beim Start auf später verschoben (R23), und die
## Lage der Teiler kommt in die Einstellungsdatei. Eine eigene Funktion für die Tests:
## get_tree().quit() in _quit() beendete ihren ganzen Lauf.
##
## Ist der Dialog zur Sicherungskopie noch offen, hat Klaus sich nicht entschieden; er schließt
## das Fenster per Fensterknopf oder Cmd+Q, beides kommt als NOTIFICATION_WM_CLOSE_REQUEST. Das gilt
## wie „Später“, die Kopie bleibt liegen (T096). request_close() schließt den Dialog schon vorher
## so; zu ist er aber erst am Ende des Bilds.
func prepare_quit() -> void:
	if _backup_dialog.visible:
		_keep_backup = true
	if not _keep_backup:
		editor.discard_backup()
	save_settings()


func _quit() -> void:
	prepare_quit()
	if quit_callback.is_valid():
		quit_callback.call()
	else:
		get_tree().quit()


## Felder übernehmen ihren Wert beim Verlassen. Cmd+S verlässt das Feld aber nicht; ohne das hier
## fehlte im gespeicherten Katalog, was Klaus gerade getippt hat.
func _commit_focused_field() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.release_focus()


# --- Dialoge (T042) ---------------------------------------------------------------------------
#
# Ein Dialog ist in Godot von Haus aus „exklusiv“: Solange er offen ist, sperrt er sein Fenster,
# und kein Klick und keine Taste kommen bei der Werkstatt an. Er sperrt dabei aber auch die
# Schließanfrage des Fensters. Godot verwirft sie, solange ein exklusiver Dialog offen ist
# (Window::_event_callback), und Cmd+Q und der Fensterknopf kamen nie in _notification() an.
#
# Die Dialoge der Werkstatt sind deshalb nicht exklusiv, und die Werkstatt sperrt selbst: _input()
# schluckt, was an einem offenen Dialog vorbei bei ihr ankommt. Das ist ein Klick neben den Dialog,
# oder eine Taste danach, denn so ein Klick nimmt dem Dialog den Fokus. Der Dialog bekommt den
# Fokus dann gleich zurück. Was für ihn bestimmt ist, bekommt er vorher, bei der Werkstatt kommt es
# gar nicht erst an. So bleibt jeder Dialog bedienbar wie bisher, und die Schließanfrage kommt
# trotzdem an.


## Macht alle Dialoge der Werkstatt nicht exklusiv, auch die von Liste und Simulator, und merkt
## sich, welche offen sind. find_children() sucht mit owned = false auch in deren Szenen.
func _set_up_dialogs() -> void:
	for node in find_children("*", "AcceptDialog", true, false):
		var dialog := node as AcceptDialog
		dialog.exclusive = false
		dialog.visibility_changed.connect(_on_dialog_visibility_changed.bind(dialog))


func _on_dialog_visibility_changed(dialog: AcceptDialog) -> void:
	_open_dialogs.erase(dialog)
	if dialog.visible:
		_open_dialogs.append(dialog)


## Die Sperre für offene Dialoge. _input() kommt vor der Oberfläche und den Kürzeln dran; was hier
## als behandelt gilt, erreicht weder ein Feld noch einen Knopf noch Cmd+S.
func _input(_event: InputEvent) -> void:
	if _open_dialogs.is_empty():
		return
	get_viewport().set_input_as_handled()
	_open_dialogs[-1].grab_focus()


## Schließt jeden offenen Dialog wie mit „Abbrechen“, den zuletzt geöffneten zuerst. Jeder bekommt
## dafür die Nachricht, die Godot einem Dialog schickt, dessen Fenster zugehen soll: Er meldet dann
## canceled und geht am Ende des Bilds zu, wie nach „Abbrechen“ oder Esc.
func _cancel_open_dialogs() -> void:
	var open := _open_dialogs.duplicate()
	open.reverse()
	for dialog: AcceptDialog in open:
		dialog.notification(NOTIFICATION_WM_CLOSE_REQUEST)


# --- Start und Sicherungskopie (R23) ----------------------------------------------------------
#
# Jeder Katalog hat seine eigene Sicherungsdatei (CatalogEditor.backup_path()). Angeboten wird
# deshalb nur die Kopie des Katalogs, der gerade aufgeht; die Kopien anderer Kataloge bleiben
# unberührt und kommen erst wieder, wenn Klaus deren Katalog öffnet.


func _start() -> void:
	_open_error = editor.open(catalog_path)
	_update_toolbar()
	if editor.backup_matches():
		_offer_backup()
	else:
		_report_open_error()


func _offer_backup() -> void:
	var info := editor.backup_info()
	_backup_dialog.dialog_text = ("Es gibt eine Sicherungskopie dieses Katalogs vom %s. Die "
		+ "Katalogdatei wurde zuletzt am %s geändert.\n\n„Übernehmen“ lädt den Stand der Kopie, "
		+ "noch ungespeichert. „Verwerfen“ löscht sie. „Später“ lässt sie liegen, bis du "
		+ "speicherst oder die Werkstatt nach deiner ersten Änderung neu sichert.") % [
		_time_text(info["saved"]), _time_text(info["catalog_modified"])]
	_backup_dialog.popup_centered(Vector2i(480, 0))


func _restore_backup() -> void:
	if editor.restore_backup() != OK:
		_show_notice("Sicherungskopie nicht lesbar", editor.last_error)
		_report_open_error()
	_update_toolbar()


func _on_backup_action(action: StringName) -> void:
	if action == &"discard":
		_backup_dialog.hide()
		editor.discard_backup()
		_report_open_error()


func _on_backup_later() -> void:
	_keep_backup = true
	_report_open_error()


## Fehlt der Katalog, bietet ein Dialog den leeren an; ist er unlesbar, nennt einer Zeile und Grund.
func _report_open_error() -> void:
	if editor.catalog != null:
		return
	match _open_error:
		OK:
			pass
		ERR_FILE_NOT_FOUND:
			_missing_dialog.dialog_text = ("Die Katalogdatei %s gibt es nicht. Soll die Werkstatt "
				+ "einen leeren Katalog mit den zehn Kategorien anlegen? Geschrieben wird er erst "
				+ "beim Speichern.") % editor.path
			_missing_dialog.popup_centered(Vector2i(480, 0))
		_:
			_unreadable_dialog.dialog_text = ("Die Katalogdatei lässt sich nicht lesen:\n%s\n\nDie "
				+ "Werkstatt lässt sie unverändert.") % editor.last_error
			_unreadable_dialog.popup_centered(Vector2i(480, 0))


## Alle 120 Sekunden, aber nur bei ungespeicherten Änderungen (CatalogEditor.write_backup()). Die
## neue Kopie ersetzt eine, die beim Start auf später verschoben wurde. Geht das Schreiben schief,
## sagt die Werkstatt es einmal und versucht es beim nächsten Mal still wieder.
func _on_backup_timer() -> void:
	if not editor.is_dirty():
		return
	var error := editor.write_backup()
	if error == OK:
		_keep_backup = false
		_backup_failed = false
		return
	if _backup_failed:
		return
	_backup_failed = true
	_show_notice("Sicherung ging nicht", ("Die Sicherungskopie %s lässt sich nicht schreiben (%s). "
		+ "Die Werkstatt versucht es alle 2 Minuten wieder; Speichern geht weiterhin.") % [
		ProjectSettings.globalize_path(editor.backup_path()), error_string(error)])


# --- Teiler -----------------------------------------------------------------------------------
#
# Die Werkstatt merkt sich, wo Klaus ihre Teiler hingezogen hat: zwischen Liste, Mitte und
# Formular, zwischen Zeitstrahl und Reitern und die im Simulator und in der Statistik. Ein
# SplitContainer hält die Lage in split_offsets, je Teiler einen Wert in Pixeln; 0 ist die
# Vorgabe der Szene. Genau diese Werte stehen in der Einstellungsdatei.
#
# Begrenzen muss die Werkstatt dabei nichts selbst. Passt ein gespeicherter Wert nicht ins
# Fenster, etwa weil es kleiner ist als beim letzten Mal, ordnet Godot die Kinder trotzdem so an,
# dass jedes mindestens seine Mindestgröße behält (bei allen Bereichen 80 Pixel oder mehr), und
# beim nächsten Ziehen rechnet es vom begrenzten Wert aus weiter. Der Wert in der Datei bleibt bis
# dahin stehen; wird das Fenster wieder größer, gilt wieder die alte Lage.


## Alle Teiler der Werkstatt, in der Reihenfolge des Baums. find_children() sucht mit
## owned = false auch in den eingesetzten Szenen von Simulator und Statistik.
func splits() -> Array[SplitContainer]:
	var result: Array[SplitContainer] = []
	for node in find_children("*", "SplitContainer", true, false):
		result.append(node as SplitContainer)
	return result


## Stellt die Teiler so, wie es die Einstellungsdatei sagt. Fehlt sie, ist sie kaputt oder passt
## ein Eintrag nicht zu seinem Teiler, gilt dort die Vorgabe, ohne Meldung: Eine verlorene Lage
## ist keinen Dialog wert.
func restore_settings() -> void:
	var config := _read_settings()
	for split in splits():
		# Ohne Vorgabe meldete get_value() einen fehlenden Eintrag als Fehler.
		var saved: Variant = config.get_value(SPLITS_SECTION, _split_key(split),
			PackedInt32Array())
		var offsets := _offsets_for(split, saved)
		if not offsets.is_empty():
			split.split_offsets = offsets


## Schreibt die Lage aller Teiler in die Einstellungsdatei, eine Sekunde nach dem letzten Ziehen
## und beim Schließen. Andere Abschnitte der Datei bleiben stehen. Lässt sie sich nicht schreiben,
## merkt sich die Werkstatt eben nichts; das Ergebnis sagt es nur den Tests.
func save_settings() -> Error:
	_settings_timer.stop()
	var config := _read_settings()
	for split in splits():
		config.set_value(SPLITS_SECTION, _split_key(split), split.split_offsets)
	return config.save(settings_path)


## Ein Teiler wird gezogen; das meldet er bei jeder Bewegung. start() beginnt die Wartezeit jedes
## Mal von vorn, gespeichert wird also erst, wenn eine Sekunde lang nichts mehr gezogen wurde.
func _on_split_dragged(_offset: int) -> void:
	_settings_timer.start()


## Die Einstellungsdatei; ohne lesbare Datei eine leere. Eine kaputte Datei soll still die
## Vorgaben gelten lassen, ConfigFile.load() meldet sie aber selbst als Fehler auf der Konsole.
## Für diesen einen Aufruf schaltet die Werkstatt Godots Meldungen deshalb ab; genau dafür gibt es
## Engine.print_error_messages. Danach gilt wieder, was vorher galt.
func _read_settings() -> ConfigFile:
	var config := ConfigFile.new()
	if not FileAccess.file_exists(settings_path):
		return config
	var printing := Engine.print_error_messages
	Engine.print_error_messages = false
	var error := config.load(settings_path)
	Engine.print_error_messages = printing
	return config if error == OK else ConfigFile.new()


## Name eines Teilers in der Datei: sein Pfad unter der Werkstatt, etwa
## „Layout/Main/Center/Tabs/SimulatorPanel/Split“. Seit T043 liegt der Inhalt eines Reiters in einem
## Rollbereich „Scroll/Content“; diese zwei Stufen zählen im Namen nicht mit. So bleiben die Namen,
## die schon in Klaus' Datei stehen, und seine Teiler gelten weiter.
func _split_key(split: SplitContainer) -> String:
	var path := String(get_path_to(split))
	for i in _tabs.get_tab_count():
		var panel := _tabs.get_tab_control(i)
		var scroll := _tab_scroll(panel)
		if scroll == null:
			continue
		var inner := String(get_path_to(scroll.get_child(0))) + "/"
		if path.begins_with(inner):
			return String(get_path_to(panel)).path_join(path.substr(inner.length()))
	return path


## Die gespeicherten Werte für [param split], wenn sie zu ihm passen: eine Liste ganzer Zahlen mit
## einem Wert je Teiler. Sonst eine leere Liste, und es gilt die Vorgabe. Aus einer Datei, die
## jemand von Hand geändert hat, darf auch eine Liste wie [300, -80.0] kommen; Werte jenseits von
## MAX_SPLIT_OFFSET gelten als kaputt, denn so groß ist kein Bildschirm.
static func _offsets_for(split: SplitContainer, saved: Variant) -> PackedInt32Array:
	if typeof(saved) != TYPE_PACKED_INT32_ARRAY and typeof(saved) != TYPE_ARRAY:
		return PackedInt32Array()
	var values: Array = Array(saved)
	if values.size() != _dragger_count(split):
		return PackedInt32Array()
	var offsets := PackedInt32Array()
	for value: Variant in values:
		if typeof(value) == TYPE_FLOAT and is_finite(value) and value == floorf(value) \
				and absf(value) <= MAX_SPLIT_OFFSET:
			value = int(value)
		if typeof(value) != TYPE_INT or value < -MAX_SPLIT_OFFSET or value > MAX_SPLIT_OFFSET:
			return PackedInt32Array()
		offsets.append(value)
	return offsets


## Wie viele Teiler [param split] hat: einen weniger als sichtbare Kinder. split_offsets taugt dafür
## beim Start nicht; bei drei Kindern legt Godot den zweiten Wert erst beim Anordnen an.
static func _dragger_count(split: SplitContainer) -> int:
	var count := 0
	for child in split.get_children():
		var control := child as Control
		if control != null and control.visible and not control.top_level:
			count += 1
	return maxi(count - 1, 0)


# --- Reiter im kleinen Fenster (T043) ---------------------------------------------------------
#
# Ein Container ist mindestens so groß, wie seine Kinder es mindestens brauchen. War der Inhalt
# eines Reiters höher, als das Fenster hergab, wuchs deshalb die ganze Werkstatt über das Fenster
# hinaus, nach oben und unten, und Toolbar und Knöpfe lagen außerhalb. Simulator, Statistik und
# Schwierigkeitsgrade haben ihren Inhalt deshalb in einem ScrollContainer „Scroll“. Die Prüfung ist
# eine Tabelle und rollt selbst.
#
# Rollen soll ein Reiter aber erst, wenn es sein muss. Bis dahin gibt wie bisher der Zeitstrahl
# Platz ab, bis auf seine Mindesthöhe. Der Rollbereich rollt deshalb zunächst gar nicht
# (SCROLL_MODE_DISABLED); dann braucht er so viel Höhe wie sein Inhalt, und alles steht wie vorher.
# Wäre die Werkstatt damit höher als das Fenster, rollt er (SCROLL_MODE_AUTO) und nimmt nur noch so
# viel Höhe, dass sie passt.
#
# Abschneiden (clip_contents) muss er nur, während er rollt. Sonst schnitte er ab, was über den
# Rand seines Inhalts hinaus zeichnet, etwa die Fokuslinie eines Felds in der obersten Leiste.


## Der Rollbereich im Reiter [param panel], oder null bei einem Reiter, der selbst rollt.
static func _tab_scroll(panel: Control) -> ScrollContainer:
	if panel == null:
		return null
	return panel.get_node_or_null(^"Scroll") as ScrollContainer


## Lässt den Inhalt des gezeigten Reiters rollen, wenn das Fenster zu klein für ihn ist; sonst
## nicht. Nach jeder Änderung der Fenstergröße, beim Wechsel des Reiters und wenn sein Inhalt
## andere Höhe braucht, etwa weil eine Leiste umbricht oder ein Hinweis erscheint.
##
## get_combined_minimum_size() rechnet sofort mit dem neuen Wert; angeordnet wird erst am Ende des
## Bilds. Das Hin und Her zwischen den beiden Modi sieht deshalb niemand.
func _fit_tab() -> void:
	var scroll := _tab_scroll(_tabs.get_current_tab_control())
	if scroll == null:
		return
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.clip_contents = false
	scroll.custom_minimum_size.y = 0
	# So hoch ist Layout, wenn es nicht über das Fenster hinauswächst: die Werkstatt abzüglich der
	# Ränder, die seine Anker lassen.
	var room := size.y + _layout.offset_bottom - _layout.offset_top
	var over := _layout.get_combined_minimum_size().y - room
	if over <= 0.0:
		scroll.scroll_vertical = 0
		return
	var content: Control = scroll.get_child(0)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.clip_contents = true
	scroll.custom_minimum_size.y = maxf(MIN_TAB_HEIGHT,
		content.get_combined_minimum_size().y - over)


# --- Meldungen des Editors und der Teile ------------------------------------------------------

func _connect_signals() -> void:
	editor.catalog_changed.connect(_on_catalog_changed)
	editor.issues_changed.connect(_on_issues_changed)
	selection_changed.connect(_on_selection_changed)
	_event_list.event_selected.connect(select_event)
	_event_list.event_created.connect(_on_event_created)
	_event_list.delete_requested.connect(_on_delete_requested)
	_event_list.filter_changed.connect(_on_list_filter_changed)
	_issues_panel.issue_activated.connect(_on_issue_activated)
	# Die Auswahl folgt einer neuen Kennung, solange das umbenannte Ereignis gewählt ist. Kommt das
	# Umbenennen erst, weil schon ein anderes gewählt wird, übernimmt das Formular die offene
	# Eingabe beim Wechsel (T095); dann bleibt das andere gewählt.
	_event_form.event_renamed.connect(func(old_id: String, new_id: String) -> void:
		if selected_id == old_id:
			select_event(new_id))
	# Der Zeitstrahl wählt wie die Liste, und ein Ziehen geht beim Loslassen als ein Schritt an den
	# CatalogEditor; Cmd+Z nimmt es zurück.
	_timeline_view.event_clicked.connect(select_event)
	_timeline_view.event_moved.connect(editor.set_event_field)
	_timeline_view.create_requested.connect(_on_create_requested)
	_timeline_view.event_created.connect(_on_event_created)
	_timeline_view.edit_requested.connect(_on_edit_requested)
	_timeline_view.delete_requested.connect(_on_delete_requested)
	_simulator_panel.event_selected.connect(_on_simulator_event_selected)
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
	_save_button.pressed.connect(request_save)
	_revert_button.pressed.connect(request_revert)
	_undo_button.pressed.connect(func() -> void: editor.undo())
	_redo_button.pressed.connect(func() -> void: editor.redo())
	_backup_timer.timeout.connect(_on_backup_timer)
	_settings_timer.wait_time = SETTINGS_DELAY
	_settings_timer.timeout.connect(save_settings)
	for split in splits():
		split.dragged.connect(_on_split_dragged)
	resized.connect(_fit_tab)
	_tabs.tab_changed.connect(func(_tab: int) -> void: _fit_tab())
	for i in _tabs.get_tab_count():
		var scroll := _tab_scroll(_tabs.get_tab_control(i))
		if scroll != null:
			(scroll.get_child(0) as Control).minimum_size_changed.connect(_fit_tab)
	_save_errors_dialog.confirmed.connect(func() -> void: _save(false))
	_save_errors_dialog.canceled.connect(_cancel_save)
	_foreign_dialog.confirmed.connect(func() -> void: _save(true))
	_foreign_dialog.canceled.connect(_cancel_save)
	_revert_dialog.confirmed.connect(_revert)
	_close_dialog.confirmed.connect(func() -> void: request_save(_quit))
	_close_dialog.add_button("Verwerfen", true, "discard")
	_close_dialog.custom_action.connect(_on_close_action)
	_delete_dialog.confirmed.connect(func() -> void: editor.delete_event(_pending_delete))
	_backup_dialog.confirmed.connect(_restore_backup)
	_backup_dialog.add_button("Verwerfen", true, "discard")
	_backup_dialog.custom_action.connect(_on_backup_action)
	_backup_dialog.canceled.connect(_on_backup_later)
	_missing_dialog.confirmed.connect(editor.new_catalog)


## Nach jeder Änderung: Liste, Formular und Zeitstrahl neu, die Toolbar auch. Fehlt danach das
## gewählte Ereignis, gilt am Ende des Bilds keins mehr als gewählt; bis dahin kann noch eine neue
## Kennung kommen, wenn die Änderung ein Umbenennen war. Simulator und Statistik behalten ihren
## Lauf bzw. ihre Rechnung und sagen nur, ob der Katalog jetzt ein anderer ist (FR-042).
func _on_catalog_changed() -> void:
	_event_list.refresh()
	_event_list.select_event(selected_id)
	_event_form.refresh()
	_timeline_view.refresh()
	_simulator_panel.refresh()
	_statistics_panel.refresh()
	_difficulty_panel.refresh()
	_update_toolbar()
	_check_selection.call_deferred()


## Auch ohne Änderung am Katalog können sich die Meldungen ändern: Nach dem Speichern fallen die
## Meldungen beim Lesen weg. Dann nähmen ein neuer Lauf im Simulator und eine neue Statistik andere
## Ereignisse aus.
func _on_issues_changed(issues: Array[CatalogIssue]) -> void:
	_issues_panel.show_issues(issues)
	_event_list.show_issues(issues)
	_event_form.refresh()
	_simulator_panel.refresh()
	_statistics_panel.refresh()
	_difficulty_panel.refresh()
	_update_toolbar()


## Die Liste filtert anders: Der Zeitstrahl zeigt dasselbe wie sie (T074). Er bekommt ihre Regel
## als Callable statt einer eigenen; ohne Filter ein leeres, dann zeigt er alles. Nach einer
## Änderung am Katalog fragt er beim Neuaufbau wieder die Liste, so verschwindet etwa ein
## Ereignis, dessen neuer Titel nicht mehr passt, hier wie dort.
func _on_list_filter_changed() -> void:
	_timeline_view.event_filter = _event_list.passes if _event_list.is_filtered() else Callable()


## Ein neues Ereignis, aus dem Dialog oder als Kopie, wird gewählt; der Fokus steht im Titel.
func _on_event_created(id: String) -> void:
	select_event(id)
	_event_form.focus_title()


## Doppelklick auf freie Fläche im Zeitstrahl (US4, Szenario 5): Der Dialog „Neu …“ der Liste
## öffnet sich vorbelegt mit der Art fix, der Kategorie der Zeile und dem Tag. Erst „Anlegen“
## legt das Ereignis an, und dann geht es weiter wie bei jedem neuen über event_created.
func _on_create_requested(category: String, day: int) -> void:
	_event_list.open_new_dialog(TimelineEvent.Kind.FIXED, category, day)


## „Bearbeiten“ im Menü des Zeitstrahls: Das Ereignis wird gewählt, der Fokus steht im Titel.
func _on_edit_requested(id: String) -> void:
	select_event(id)
	_event_form.focus_title()


## Löschen fragt nach und nennt, was darauf verweist (FR-036): erst die Ereignisse, dann die
## Start-Modifikatoren in den Profilen (Feature 003, FR-017). delete_event() entfernt beides im
## selben Schritt mit, außer die Kennung gehört noch zu einem zweiten Ereignis (V02). Dann bleiben
## die Verweise stehen, denn sie gelten auch dem anderen, und der Dialog sagt das (T037).
func _on_delete_requested(id: String) -> void:
	var event := editor.catalog.get_event(id)
	if event == null:
		return
	_pending_delete = id
	var text := "„%s“ löschen?" % _title_of(event)
	var references := editor.references_to(id)
	var in_profiles := editor.profile_references_to(id)
	var names := PackedStringArray()
	for reference in references:
		names.append("„%s“" % _title_of(editor.catalog.get_event(reference)))
	if not references.is_empty() and not in_profiles.is_empty():
		text += "\n\nDarauf verweisen: %s. In den Profilen: %s." % [", ".join(names),
			", ".join(in_profiles)]
	elif not references.is_empty():
		text += "\n\nDarauf verweisen: %s." % ", ".join(names)
	elif not in_profiles.is_empty():
		text += "\n\nIn den Profilen verweisen darauf: %s." % ", ".join(in_profiles)
	var has_references := not references.is_empty() or not in_profiles.is_empty()
	if has_references and _has_twin(id):
		text += (" Diese Verweise bleiben stehen, denn die Kennung „%s“ gehört noch zu einem "
			+ "zweiten Ereignis.") % id
	elif has_references:
		text += " Diese Verweise werden mit entfernt."
	text += "\n\nRückgängig holt alles zurück."
	_delete_dialog.dialog_text = text
	_delete_dialog.popup_centered(Vector2i(440, 0))


## Ob mehr als ein Ereignis die Kennung [param id] trägt (V02). Dieselbe Regel entscheidet in
## CatalogEditor.delete_event(), ob die Verweise mit entfernt werden.
func _has_twin(id: String) -> bool:
	var count := 0
	for event in editor.catalog.events:
		if event.id == id:
			count += 1
	return count > 1


## Ein Termin im Simulator wählt sein Ereignis, sofern es noch im Katalog steht: Der Lauf rechnet
## mit einer Kopie, und seit seinem Start kann Klaus das Ereignis gelöscht oder umbenannt haben.
func _on_simulator_event_selected(id: String) -> void:
	if editor.catalog != null and editor.catalog.get_event(id) != null:
		select_event(id)


## Alle Eingriffe, die der Simulator gesammelt hat, für das Häkchen der Statistik. Welche davon in
## jedem Spiel gelten, entscheidet TimelineStatistics: Modifikatoren und Einplanungen (FR-045).
func _simulator_interventions() -> Array[Dictionary]:
	return _simulator_panel.probe.interventions


## Der Fokus kommt in ein Feld des Formulars: Im nächsten Bild rollt der Formularbereich so, dass
## das Feld samt Fokuslinie zu sehen ist (T094). Vorher stünde ein Feld, das der Neubau gerade
## angelegt hat, noch nicht an seinem Platz; Container ordnen ihre Kinder erst am Ende des Bilds an.
##
## Godots follow_focus ist dafür aus: Es rollt ein Feld nur bis an den Rand des Bereichs, und die
## Linie, die der Stil „focus“ 4 Pixel außen um das Feld zeichnet, fiele dann halb heraus.
func _on_gui_focus_changed(control: Control) -> void:
	if _form_scroll.is_ancestor_of(control) \
			and not get_tree().process_frame.is_connected(_reveal_focus):
		get_tree().process_frame.connect(_reveal_focus, CONNECT_ONE_SHOT)


## Rollt den Formularbereich so wenig wie nötig, bis die Fokuslinie des Felds mit dem Fokus ganz
## darin liegt; oben, wenn sie höher ist als der Bereich. Gefragt wird erst jetzt nach dem Fokus:
## Er kann inzwischen woanders sein.
func _reveal_focus() -> void:
	var control := get_viewport().gui_get_focus_owner()
	if control == null or not _form_scroll.is_ancestor_of(control):
		return
	var ring := _focus_ring(control)
	var area := _form_scroll.get_global_rect()
	var shift := 0.0
	if ring.position.y < area.position.y:
		shift = ring.position.y - area.position.y
	elif ring.end.y > area.end.y:
		shift = minf(ring.end.y - area.end.y, ring.position.y - area.position.y)
	if shift != 0.0:
		_form_scroll.scroll_vertical += int(signf(shift) * ceilf(absf(shift)))


## Wo die Fokuslinie um [param control] liegt, in globalen Koordinaten: sein Rechteck, vergrößert
## um die Ränder, die sein Stil „focus“ nach außen zeichnet. Im Theme sind das 4 Pixel, 2 Abstand
## und 2 Linie (Style-Guide, Rolle „Fokus“).
static func _focus_ring(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	var style := control.get_theme_stylebox(&"focus")
	if style is StyleBoxFlat:
		var flat: StyleBoxFlat = style
		rect = rect.grow_individual(flat.expand_margin_left, flat.expand_margin_top,
			flat.expand_margin_right, flat.expand_margin_bottom)
	return rect


## Ein Klick in der Prüfung wählt das Ereignis und setzt den Fokus ins Feld (FR-033). Meldungen zu
## Kategorien haben kein Ereignis; ihr Feld liegt im Bereich für Kategorien. Meldungen zu Profilen
## haben auch keins: Ihr Feld beginnt mit „profiles“ und liegt im Reiter „Schwierigkeitsgrade“; die
## Auswahl des Ereignisses bleibt dann, wie sie ist (Feature 003, FR-016).
func _on_issue_activated(event_id: String, field: String) -> void:
	if _is_profile_field(field):
		_tabs.current_tab = _tabs.get_tab_idx_from_control(_difficulty_panel)
		_difficulty_panel.focus_field(field)
		return
	if not event_id.is_empty() and editor.catalog != null \
			and editor.catalog.get_event(event_id) != null:
		select_event(event_id)
	_event_form.focus_field(field)


## Ob [param field] zu den Profilen gehört: „profiles“ selbst oder alles darunter, nach ganzen
## Pfadteilen; „profiles.schwer[2].reason“ ja, ein Feld „profilesx“ nicht.
static func _is_profile_field(field: String) -> bool:
	return field == "profiles" or field.begins_with("profiles.") or field.begins_with("profiles[")


# --- Toolbar ----------------------------------------------------------------------------------

func _set_up_shortcuts() -> void:
	_save_button.shortcut = _shortcut(KEY_S)
	_undo_button.shortcut = _shortcut(KEY_Z)
	_redo_button.shortcut = _shortcut(KEY_Z, true)
	# Die Tooltips nennen die Kürzel selbst, als „Cmd+Z“ statt Godots „Command+Z“.
	for button: Button in [_save_button, _undo_button, _redo_button]:
		button.shortcut_in_tooltip = false


## Kürzel mit Cmd auf dem Mac und Ctrl unter Windows und Linux (R15). Ein Textfeld mit dem Fokus
## bekommt Cmd+Z vorher selbst; bis zum Knopf kommt es dann nicht.
static func _shortcut(key: Key, shift: bool = false) -> Shortcut:
	var event := InputEventKey.new()
	event.keycode = key
	event.shift_pressed = shift
	event.command_or_control_autoremap = true
	var shortcut := Shortcut.new()
	shortcut.events = [event]
	return shortcut


## Das Kürzel so, wie die Tabelle im Vertrag es nennt: „Shift+Cmd+Z“ bzw. „Ctrl+Shift+Z“.
static func keys_text(key: String, shift: bool = false) -> String:
	if OS.get_name() == "macOS":
		return ("Shift+Cmd+%s" if shift else "Cmd+%s") % key
	return ("Ctrl+Shift+%s" if shift else "Ctrl+%s") % key


## Liest nach jeder Meldung des Editors neu, was die Toolbar zeigt: Datei, „ungespeichert“, die
## Zahl der Meldungen und welche Knöpfe gerade gehen.
func _update_toolbar() -> void:
	var has_catalog := editor.catalog != null
	# Der Dateiname nimmt den freien Platz der Toolbar und kürzt sich darin mit „…“, sonst machte
	# ein langer Pfad die ganze Werkstatt breiter als ihr Fenster. Voll steht er im Hinweis.
	_file_label.text = editor.path if has_catalog else "%s (nicht geladen)" % editor.path
	_file_label.tooltip_text = "Die Katalogdatei, die die Werkstatt bearbeitet:\n%s" % editor.path
	_dirty_label.visible = has_catalog and editor.is_dirty()
	_count_label.text = _count_text()
	_save_button.disabled = not has_catalog
	_save_button.tooltip_text = "Speichern (%s)" % keys_text("S")
	_revert_button.disabled = not (has_catalog and editor.is_dirty())
	_revert_button.tooltip_text = "Ungespeicherte Änderungen verwerfen und die Datei neu laden"
	_undo_button.disabled = not editor.can_undo()
	_undo_button.tooltip_text = _history_tooltip("Rückgängig", editor.undo_name(), keys_text("Z"))
	_redo_button.disabled = not editor.can_redo()
	_redo_button.tooltip_text = _history_tooltip("Wiederholen", editor.redo_name(),
		keys_text("Z", true))


## „Rückgängig: Datum von Intel Pentium erscheint (Cmd+Z)“; ohne Aktion nur „Rückgängig (Cmd+Z)“.
static func _history_tooltip(verb: String, action: String, keys: String) -> String:
	if action.is_empty():
		return "%s (%s)" % [verb, keys]
	return "%s: %s (%s)" % [verb, action, keys]


func _count_text() -> String:
	if editor.catalog == null:
		return ""
	var errors := _count(CatalogIssue.Severity.ERROR)
	var warnings := _count(CatalogIssue.Severity.WARNING)
	var parts := PackedStringArray()
	if errors > 0:
		parts.append("%d Fehler" % errors)
	if warnings > 0:
		parts.append("%d %s" % [warnings, "Warnung" if warnings == 1 else "Warnungen"])
	return ", ".join(parts) if not parts.is_empty() else "keine Meldungen"


func _count(severity: CatalogIssue.Severity) -> int:
	var count := 0
	for issue in editor.issues():
		if issue.severity == severity:
			count += 1
	return count


# --- Hilfen -----------------------------------------------------------------------------------

## Fenster für ein Werkzeug (R13; Style-Guide, „Werkzeuge“): volle Auflösung statt des Spielrasters,
## Text in normaler Größe auch auf dem Retina-Bildschirm, maximiert. Headless gibt es kein Fenster;
## der Rauchtest braucht genau diesen Fall, und GameWindow bleibt dann unberührt.
func _set_up_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	# Zuerst GameWindow anhalten: Es gäbe dem Fenster sonst beim Start und beim Wechsel aus dem
	# Vollbild die ganzzahlige Spielgröße. Ohne Naht kommt das Autoload über seinen Pfad.
	# Ausnahme AR-02: Die Werkstatt hält GameWindow über den Pfad /root/GameWindow an. Mit -s
	# geladen, etwa von der Textausgabe, kennt GDScript den Namen des Autoloads beim
	# Kompilieren nicht; der Pfad ist der einzige Weg. Die Naht nach AR-12 bleibt davon
	# unberührt (Klaus, 2026-10-28)
	var window_node := game_window if game_window != null \
		else get_node_or_null(^"/root/GameWindow")
	if window_node != null:
		window_node.set_process(false)
		window_node.set_process_input(false)
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.content_scale_factor = DisplayServer.screen_get_scale()
	# Das Projekt startet im Fenster; das Maximieren greift deshalb sofort.
	if not Engine.is_embedded_in_editor():
		window.mode = Window.MODE_MAXIMIZED


func _show_notice(title: String, text: String) -> void:
	_notice_dialog.title = title
	_notice_dialog.dialog_text = text
	_notice_dialog.popup_centered(Vector2i(440, 0))


static func _title_of(event: TimelineEvent) -> String:
	if event == null:
		return "?"
	return event.title if not event.title.strip_edges().is_empty() else event.id


## Unix-Zeit als „20.10.2026, 16:42 Uhr“ in der Zeitzone des Rechners; „–“ ohne Zeit.
static func _time_text(unix: int) -> String:
	if unix <= 0:
		return "–"
	var zone := Time.get_time_zone_from_system()
	var bias: int = zone.get("bias", 0)
	var local := Time.get_datetime_dict_from_unix_time(unix + bias * 60)
	return "%02d.%02d.%04d, %02d:%02d Uhr" % [local["day"], local["month"], local["year"],
		local["hour"], local["minute"]]
