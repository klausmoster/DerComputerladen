class_name Werkstatt
extends Control

## Die Zeitleisten-Werkstatt (Feature 002; contracts/werkstatt.md): Hier pflegt Klaus den
## Ereigniskatalog ohne Code. Diese Szene ist die Wurzel. Sie richtet das Fenster ein, öffnet den
## Katalog über einen CatalogEditor, fragt nach, bevor etwas verloren gehen könnte, und verdrahtet
## die Teile.
##
## Die Teile sind eigene Szenen bzw. Skripte: Liste, Formular, Prüfung, Zeitstrahl, Simulator und
## Statistik. Sie melden nach oben, was geschieht (Signale), und die Werkstatt ruft sie von oben
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

## Der Katalog, den die Werkstatt öffnet. Tests setzen ihn, bevor die Szene in den Baum kommt.
var catalog_path: String = EventCatalog.DEFAULT_PATH
## Die Einstellungsdatei der Werkstatt, ein ConfigFile: Darin merkt sie sich die Lage ihrer
## Teiler. Sie liegt unter user://, also außerhalb des Projekts, wie die Sicherungskopie. Tests
## setzen eine eigene Datei, bevor die Szene in den Baum kommt.
var settings_path: String = "user://werkstatt_einstellungen.cfg"
## Der einzige, der den Katalog ändert. Tests setzen hier vorher eine eigene Sicherungsdatei.
var editor := CatalogEditor.new()
## Das gewählte Ereignis; leer heißt keins.
var selected_id: String = ""

## Was nach erfolgreichem Speichern geschehen soll, etwa das Beenden beim Schließen.
var _after_save := Callable()
## Das Ereignis, dessen Löschen gerade bestätigt werden soll.
var _pending_delete := ""
## Ob die Sicherungskopie beim Schließen liegen bleibt: Klaus hat sie beim Start auf später
## verschoben und seitdem keine neue geschrieben.
var _keep_backup := false
## Ergebnis von open() beim Start; nach der Frage zur Sicherungskopie kommt die zum Katalog.
var _open_error := OK

@onready var _save_button: Button = %SaveButton
@onready var _revert_button: Button = %RevertButton
@onready var _undo_button: Button = %UndoButton
@onready var _redo_button: Button = %RedoButton
@onready var _file_label: Label = %FileLabel
@onready var _dirty_label: Label = %DirtyLabel
@onready var _count_label: Label = %CountLabel
@onready var _event_list: EventList = %EventList
@onready var _tabs: TabContainer = %Tabs
@onready var _issues_panel: IssuesPanel = %IssuesPanel
@onready var _event_form: EventForm = %EventForm
@onready var _timeline_view: TimelineView = %TimelineView
@onready var _simulator_panel: SimulatorPanel = %SimulatorPanel
@onready var _statistics_panel: StatisticsPanel = %StatisticsPanel
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
@onready var _backup_notice_dialog: AcceptDialog = %BackupNoticeDialog
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
	_event_list.editor = editor
	_event_form.editor = editor
	_timeline_view.editor = editor
	_simulator_panel.editor = editor
	_statistics_panel.editor = editor
	# Das Häkchen der Statistik nimmt die Eingriffe, die der Simulator gesammelt hat (FR-045). Die
	# Werkstatt reicht sie als Callable weiter; so kennen sich die beiden Teile nicht.
	_statistics_panel.interventions_source = _simulator_interventions
	_set_up_shortcuts()
	_connect_signals()
	restore_settings()
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
func request_close() -> void:
	_commit_focused_field()
	if editor.catalog != null and editor.is_dirty():
		_close_dialog.popup_centered(Vector2i(420, 0))
		return
	_quit()


func _on_close_action(action: StringName) -> void:
	if action == &"discard":
		_close_dialog.hide()
		_quit()


## Beim regulären Schließen fällt die Sicherungskopie weg (FR-050), außer Klaus hat sie beim Start
## auf später verschoben. Die Lage der Teiler kommt in die Einstellungsdatei.
func _quit() -> void:
	if not _keep_backup:
		editor.discard_backup()
	save_settings()
	get_tree().quit()


## Felder übernehmen ihren Wert beim Verlassen. Cmd+S verlässt das Feld aber nicht; ohne das hier
## fehlte im gespeicherten Katalog, was Klaus gerade getippt hat.
func _commit_focused_field() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.release_focus()


# --- Start und Sicherungskopie (R23) ----------------------------------------------------------

func _start() -> void:
	_open_error = editor.open(catalog_path)
	_update_toolbar()
	if editor.backup_matches():
		_offer_backup()
	elif editor.has_backup():
		var info := editor.backup_info()
		var belongs := "eines anderen Katalogs (%s)" % info["path"] if not info.is_empty() \
			else "unbekannter Herkunft"
		_backup_notice_dialog.dialog_text = ("Es gibt eine Sicherungskopie %s. Sie bleibt liegen, "
			+ "unter %s.") % [belongs, ProjectSettings.globalize_path(editor.backup_path)]
		_backup_notice_dialog.popup_centered(Vector2i(480, 0))
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


## Alle 120 Sekunden, aber nur bei ungespeicherten Änderungen (CatalogEditor.write_backup()).
func _on_backup_timer() -> void:
	if editor.is_dirty() and editor.write_backup() == OK:
		_keep_backup = false


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


## Name eines Teilers in der Datei: sein Pfad unter der Werkstatt.
func _split_key(split: SplitContainer) -> String:
	return String(get_path_to(split))


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
	_event_form.event_renamed.connect(func(_old_id: String, new_id: String) -> void:
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
	_save_button.pressed.connect(request_save)
	_revert_button.pressed.connect(request_revert)
	_undo_button.pressed.connect(func() -> void: editor.undo())
	_redo_button.pressed.connect(func() -> void: editor.redo())
	_backup_timer.timeout.connect(_on_backup_timer)
	_settings_timer.wait_time = SETTINGS_DELAY
	_settings_timer.timeout.connect(save_settings)
	for split in splits():
		split.dragged.connect(_on_split_dragged)
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
	_backup_notice_dialog.confirmed.connect(_report_open_error)
	_backup_notice_dialog.canceled.connect(_report_open_error)
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


## Löschen fragt nach und nennt die Ereignisse, die darauf verweisen (FR-036).
func _on_delete_requested(id: String) -> void:
	var event := editor.catalog.get_event(id)
	if event == null:
		return
	_pending_delete = id
	var text := "„%s“ löschen?" % _title_of(event)
	var references := editor.references_to(id)
	if not references.is_empty():
		var names := PackedStringArray()
		for reference in references:
			names.append("„%s“" % _title_of(editor.catalog.get_event(reference)))
		text += ("\n\nDarauf verweisen: %s. Diese Verweise werden mit entfernt.") % ", ".join(names)
	text += "\n\nRückgängig holt alles zurück."
	_delete_dialog.dialog_text = text
	_delete_dialog.popup_centered(Vector2i(440, 0))


## Ein Termin im Simulator wählt sein Ereignis, sofern es noch im Katalog steht: Der Lauf rechnet
## mit einer Kopie, und seit seinem Start kann Klaus das Ereignis gelöscht oder umbenannt haben.
func _on_simulator_event_selected(id: String) -> void:
	if editor.catalog != null and editor.catalog.get_event(id) != null:
		select_event(id)


## Alle Eingriffe, die der Simulator gesammelt hat, für das Häkchen der Statistik. Welche davon in
## jedem Spiel gelten, entscheidet TimelineStatistics: Modifikatoren und Einplanungen (FR-045).
func _simulator_interventions() -> Array[Dictionary]:
	return _simulator_panel.probe.interventions


## Ein Klick in der Prüfung wählt das Ereignis und setzt den Fokus ins Feld (FR-033). Meldungen zu
## Kategorien haben kein Ereignis; ihr Feld liegt im Bereich für Kategorien.
func _on_issue_activated(event_id: String, field: String) -> void:
	if not event_id.is_empty() and editor.catalog != null \
			and editor.catalog.get_event(event_id) != null:
		select_event(event_id)
	_event_form.focus_field(field)


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
	# Vollbild die ganzzahlige Spielgröße. Das Autoload kommt über seinen Pfad; seinen Namen
	# kennt GDScript beim Kompilieren nicht immer, etwa wenn ein Skript mit -s die Werkstatt lädt.
	var game_window := get_node_or_null(^"/root/GameWindow")
	if game_window != null:
		game_window.set_process(false)
		game_window.set_process_unhandled_input(false)
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
