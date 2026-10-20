extends GutTest

## Rauchtest der Werkstatt (Feature 002, T039; contracts/werkstatt.md): Die Szene baut headless auf
## und lässt das Fenster in Ruhe, und eine Prüfmeldung führt zum Ereignis und ins Feld (FR-033).
## Dazu die Abläufe beim Start, beim Speichern, Verwerfen und Schließen, die Kürzel und die Liste
## (T034, T035, T038).
##
## Jeder Test öffnet eine Kopie eines Test-Katalogs in einem eigenen Ordner unter user:// und setzt
## eine eigene Sicherungsdatei, bevor die Szene in den Baum kommt; after_each() räumt auf. Der echte
## Katalog und die echte Sicherungskopie bleiben unberührt.
##
## Kein Test bestätigt das Schließen: get_tree().quit() beendete den ganzen Testlauf.

const SZENE := preload("res://tools/werkstatt/werkstatt.tscn")
const ORDNER := "user://test_werkstatt_scene/"
const MINIMAL := "res://test/fixtures/catalog_minimal.json"
## Wie MINIMAL, aber intel_pentium am 12.05.2001 (V06).
const DATUM_AUSSERHALB := "res://test/fixtures/catalog_v06_datum_ausserhalb.json"
## Eine Kategorie mit einer Farbe, die keine Kategorienfarbe ist (V21).
const KATEGORIE_FARBE := "res://test/fixtures/catalog_v21_kategorie_farbe.json"
## Kein gültiges JSON: Der Parser stolpert in Zeile 13.
const KAPUTT := "res://test/fixtures/catalog_v22_kaputt.json"
const UEBERNAHME := "res://test/fixtures/event_catalog_uebernahme.json"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)


func after_each() -> void:
	var ordner := DirAccess.open(ORDNER)
	if ordner != null:
		for datei in ordner.get_files():
			ordner.remove(datei)
	DirAccess.remove_absolute(ORDNER)


# --- Aufbau -----------------------------------------------------------------------------------

func test_szene_baut_headless_auf_und_laesst_das_fenster_in_ruhe() -> void:
	# Arrange
	var fenster := get_window()
	var vorher := [fenster.content_scale_mode, fenster.content_scale_factor, fenster.mode]

	# Act
	var werkstatt := await _werkstatt()

	# Assert
	assert_eq([fenster.content_scale_mode, fenster.content_scale_factor, fenster.mode], vorher,
		"Headless rührt die Werkstatt das Fenster nicht an.")
	assert_eq(werkstatt.editor.catalog.events.size(), 5)
	assert_eq(_liste(werkstatt).get_root().get_child_count(), 5, "Jedes Ereignis hat eine Zeile.")
	assert_eq(_node(werkstatt, "%Tabs").get_tab_title(0), "Prüfung")
	assert_eq(_node(werkstatt, "%CountLabel").text, "keine Meldungen")
	assert_false(_node(werkstatt, "%DirtyLabel").visible)
	assert_eq(werkstatt.theme.default_font, ThemeDB.fallback_font, "Open Sans per Code (R14).")
	var datei: Theme = load("res://tools/werkstatt/werkstatt_theme.tres")
	assert_false(datei.has_default_font(), "Die Schrift kommt in eine Kopie, nicht in die Datei.")
	for dialog: Window in _dialoge(werkstatt):
		assert_false(dialog.visible, "%s ist beim Start ohne Anlass offen." % dialog.name)


func test_schliessen_bleibt_der_werkstatt_ueberlassen() -> void:
	# Arrange und Act
	var werkstatt := await _werkstatt()

	# Assert: R15
	assert_false(get_tree().auto_accept_quit, "Ohne Rückfrage schließt das Fenster nicht.")
	remove_child(werkstatt)
	assert_true(get_tree().auto_accept_quit, "Ohne Werkstatt gilt wieder die Vorgabe.")


func test_pruefmeldung_fuehrt_zum_ereignis_und_ins_feld() -> void:
	# Arrange: intel_pentium liegt am 12.05.2001 (V06).
	var werkstatt := await _werkstatt(DATUM_AUSSERHALB)
	var pruefung: IssuesPanel = _node(werkstatt, "%IssuesPanel")
	var zeile := pruefung.get_root().get_child(0)
	assert_eq([zeile.get_text(IssuesPanel.Column.EVENT), zeile.get_text(IssuesPanel.Column.FIELD)],
		["intel_pentium", "date"])

	# Act: die Zeile wählen und aktivieren, wie mit Enter oder einem Doppelklick
	zeile.select(0)
	pruefung.item_activated.emit()

	# Assert: FR-033
	var formular: EventForm = _node(werkstatt, "%EventForm")
	assert_eq(werkstatt.selected_id, "intel_pentium", "Die Meldung wählt ihr Ereignis.")
	assert_same(get_viewport().gui_get_focus_owner(), formular.get_input("date"),
		"Der Fokus steht im Feld Datum.")
	assert_eq(formular.get_input("date").theme_type_variation, &"ErrorLineEdit",
		"Das Feld trägt die rote Kontur des Fehlers.")


func test_kategorienmeldung_fuehrt_zum_bereich_fuer_kategorien() -> void:
	# Arrange
	var werkstatt := await _werkstatt(KATEGORIE_FARBE)
	var meldung := _erste_meldung(werkstatt, "V21")
	assert_eq(meldung.event_id, "", "Meldungen zu Kategorien haben kein Ereignis.")

	# Act
	_node(werkstatt, "%IssuesPanel").issue_activated.emit(meldung.event_id, meldung.field)

	# Assert
	var formular: EventForm = _node(werkstatt, "%EventForm")
	assert_same(get_viewport().gui_get_focus_owner(), formular.get_input(meldung.field),
		"Der Fokus steht bei der Farbe der Kategorie.")
	assert_eq(werkstatt.selected_id, "", "Die Auswahl bleibt, wie sie war.")


# --- Start ------------------------------------------------------------------------------------

func test_fehlende_datei_bietet_einen_leeren_katalog_an() -> void:
	# Arrange und Act
	var werkstatt := await _werkstatt("", "fehlt.json")

	# Assert: Edge Case „Es gibt noch keine Katalogdatei“
	var dialog: ConfirmationDialog = _node(werkstatt, "%MissingDialog")
	assert_true(dialog.visible)
	assert_string_contains(dialog.dialog_text, "fehlt.json")
	dialog.get_ok_button().pressed.emit()
	assert_eq(werkstatt.editor.catalog.categories.size(), 10)
	assert_false(FileAccess.file_exists(ORDNER + "fehlt.json"),
		"Geschrieben wird erst beim Speichern.")
	assert_true(_node(werkstatt, "%DirtyLabel").visible)


func test_unlesbare_datei_nennt_zeile_und_grund() -> void:
	# Arrange und Act
	var werkstatt := await _werkstatt(KAPUTT)

	# Assert
	var dialog: AcceptDialog = _node(werkstatt, "%UnreadableDialog")
	assert_true(dialog.visible)
	assert_string_contains(dialog.dialog_text, "Zeile 13")
	assert_true(_node(werkstatt, "%SaveButton").disabled,
		"Ohne Katalog gibt es nichts zu speichern.")
	assert_eq(FileAccess.get_file_as_string(ORDNER + "katalog.json"),
		FileAccess.get_file_as_string(KAPUTT), "Die Datei bleibt, wie sie ist.")


func test_sicherungskopie_dieses_katalogs_wird_angeboten() -> void:
	# Arrange: Eine frühere Sitzung hat gesichert und ist dann abgestürzt.
	var ziel := _kopieren(MINIMAL, ORDNER + "katalog.json")
	var frueher := _editor()
	assert_eq(frueher.open(ziel), OK)
	frueher.set_event_field("intel_pentium", &"title", "Pentium kommt")
	frueher.write_backup()

	# Act
	var werkstatt := await _werkstatt("")

	# Assert: FR-050
	var dialog: ConfirmationDialog = _node(werkstatt, "%BackupDialog")
	assert_true(dialog.visible)
	assert_string_contains(dialog.dialog_text, "Sicherungskopie dieses Katalogs vom")
	assert_string_contains(dialog.dialog_text, "Katalogdatei wurde zuletzt am")
	dialog.get_ok_button().pressed.emit()
	assert_eq(werkstatt.editor.catalog.get_event("intel_pentium").title, "Pentium kommt",
		"Übernehmen lädt den Stand der Kopie.")
	assert_true(werkstatt.editor.is_dirty())


func test_sicherungskopie_eines_anderen_katalogs_bleibt_liegen() -> void:
	# Arrange: R23. Die Kopie gehört zu anderer.json.
	var anderer := _editor()
	assert_eq(anderer.open(_kopieren(UEBERNAHME, ORDNER + "anderer.json")), OK)
	anderer.set_event_field("intel_pentium", &"title", "Pentium kommt")
	anderer.write_backup()
	var kopie := FileAccess.get_file_as_string(anderer.backup_path)

	# Act
	var werkstatt := await _werkstatt()
	werkstatt.editor.set_event_field("intel_pentium", &"date", 3026)
	_node(werkstatt, "%BackupTimer").timeout.emit()

	# Assert
	var hinweis: AcceptDialog = _node(werkstatt, "%BackupNoticeDialog")
	assert_false(_node(werkstatt, "%BackupDialog").visible, "Übernehmen wird nicht angeboten.")
	assert_true(hinweis.visible)
	assert_string_contains(hinweis.dialog_text, "anderer.json")
	assert_string_contains(hinweis.dialog_text, "sicherung.json", "Der Hinweis nennt ihren Pfad.")
	assert_eq(FileAccess.get_file_as_string(anderer.backup_path), kopie,
		"Der Timer überschreibt die fremde Kopie nicht.")


# --- Speichern, Verwerfen, Schließen ----------------------------------------------------------

func test_speichern_mit_fehler_fragt_nach() -> void:
	# Arrange
	var werkstatt := await _werkstatt(DATUM_AUSSERHALB)
	werkstatt.editor.set_event_field("neubaugebiet", &"title", "Neue Siedlung")

	# Act
	_node(werkstatt, "%SaveButton").pressed.emit()

	# Assert: FR-034
	var dialog: ConfirmationDialog = _node(werkstatt, "%SaveErrorsDialog")
	assert_true(dialog.visible)
	assert_eq(dialog.dialog_text, "Der Katalog hat 1 Fehler. Trotzdem speichern?")
	assert_false(_datei().contains("Neue Siedlung"), "Vor der Antwort wird nicht gespeichert.")
	dialog.get_ok_button().pressed.emit()
	assert_true(_datei().contains("Neue Siedlung"))
	assert_false(_node(werkstatt, "%DirtyLabel").visible)


func test_fremde_aenderung_fragt_vor_dem_ueberschreiben() -> void:
	# Arrange: Jemand ändert die Datei, während die Werkstatt offen ist.
	var werkstatt := await _werkstatt()
	var fremd := _datei().replace("Superskalare", "Superskalar")
	_schreiben(ORDNER + "katalog.json", fremd)
	werkstatt.editor.set_event_field("intel_pentium", &"date", 3026)

	# Act
	_node(werkstatt, "%SaveButton").pressed.emit()

	# Assert
	var dialog: ConfirmationDialog = _node(werkstatt, "%ForeignChangeDialog")
	assert_true(dialog.visible)
	assert_string_contains(dialog.dialog_text, "geändert")
	assert_eq(_datei(), fremd, "Die fremde Änderung bleibt bis zur Antwort stehen.")
	dialog.get_ok_button().pressed.emit()
	assert_eq(_datei(), werkstatt.editor.catalog.to_json())


func test_verwerfen_fragt_nach_und_laedt_die_datei() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var revert: Button = _node(werkstatt, "%RevertButton")
	assert_true(revert.disabled, "Ohne Änderung gibt es nichts zu verwerfen.")
	werkstatt.editor.set_event_field("intel_pentium", &"date", 3026)

	# Act
	revert.pressed.emit()

	# Assert
	var dialog: ConfirmationDialog = _node(werkstatt, "%RevertDialog")
	assert_true(dialog.visible)
	dialog.get_ok_button().pressed.emit()
	assert_eq(werkstatt.editor.catalog.to_json(), _datei())
	assert_false(werkstatt.editor.can_undo(), "Verwerfen leert den Verlauf.")


func test_schliessen_mit_aenderungen_fragt_nach() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	werkstatt.editor.set_event_field("intel_pentium", &"date", 3026)

	# Act
	werkstatt.notification(NOTIFICATION_WM_CLOSE_REQUEST)

	# Assert: R15
	var dialog: ConfirmationDialog = _node(werkstatt, "%CloseDialog")
	assert_true(dialog.visible)
	var knoepfe := []
	for knopf in dialog.get_ok_button().get_parent().get_children():
		if knopf is Button and knopf.visible:
			knoepfe.append(knopf.text)
	assert_has(knoepfe, "Speichern")
	assert_has(knoepfe, "Verwerfen")
	assert_has(knoepfe, "Abbrechen")
	dialog.get_cancel_button().pressed.emit()
	# Bei „Abbrechen“ versteckt sich ein Dialog erst am Ende des Bilds.
	await wait_process_frames(1)
	assert_false(dialog.visible)
	assert_true(werkstatt.editor.is_dirty(), "Abbrechen lässt alles, wie es war.")


# --- Kürzel und Toolbar -----------------------------------------------------------------------

func test_cmd_z_nimmt_zurueck_ausser_im_textfeld() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	werkstatt.editor.set_event_field("intel_pentium", &"date", 3026)
	werkstatt.editor.set_event_field("intel_pentium", &"title", "Pentium kommt")

	# Act und Assert: R15, ohne Fokus in einem Textfeld geht Cmd+Z an den Katalog …
	get_viewport().push_input(_taste(KEY_Z))
	assert_eq(werkstatt.editor.catalog.get_event("intel_pentium").title, "Intel Pentium erscheint")
	# … mit Fokus in einem Textfeld gehört es dem Feld.
	werkstatt.select_event("neubaugebiet")
	var titel: LineEdit = _node(werkstatt, "%EventForm").get_input("title")
	titel.grab_focus()
	get_viewport().push_input(_taste(KEY_Z))
	assert_eq(werkstatt.editor.catalog.get_event("intel_pentium").date, 3026,
		"Das Datum ist noch geändert; das Textfeld hat Cmd+Z bekommen.")
	titel.release_focus()
	get_viewport().push_input(_taste(KEY_Z, true))
	assert_eq(werkstatt.editor.catalog.get_event("intel_pentium").title, "Pentium kommt",
		"Shift+Cmd+Z wiederholt.")


func test_cmd_s_uebernimmt_das_feld_und_speichert() -> void:
	# Arrange: Klaus tippt einen Titel und drückt Cmd+S, ohne das Feld zu verlassen.
	var werkstatt := await _werkstatt()
	werkstatt.select_event("neubaugebiet")
	var titel: LineEdit = _node(werkstatt, "%EventForm").get_input("title")
	titel.grab_focus()
	titel.text = "Neue Siedlung"

	# Act
	get_viewport().push_input(_taste(KEY_S))

	# Assert
	assert_true(_datei().contains("\"title\": \"Neue Siedlung\""), "Das Feld ist mitgespeichert.")


func test_knoepfe_nennen_aktion_und_kuerzel() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var undo: Button = _node(werkstatt, "%UndoButton")
	var redo: Button = _node(werkstatt, "%RedoButton")
	assert_true(undo.disabled)

	# Act
	werkstatt.editor.set_event_field("intel_pentium", &"date", 3026)

	# Assert
	assert_false(undo.disabled)
	assert_eq(undo.tooltip_text, "Rückgängig: Datum von Intel Pentium erscheint (%s)"
		% Werkstatt.keys_text("Z"))
	assert_true(_node(werkstatt, "%DirtyLabel").visible, "Die Toolbar zeigt „ungespeichert“.")
	werkstatt.editor.undo()
	assert_eq(redo.tooltip_text, "Wiederholen: Datum von Intel Pentium erscheint (%s)"
		% Werkstatt.keys_text("Z", true))
	assert_eq(undo.tooltip_text, "Rückgängig (%s)" % Werkstatt.keys_text("Z"))


func test_toolbar_zaehlt_fehler_und_warnungen() -> void:
	# Arrange
	var werkstatt := await _werkstatt(DATUM_AUSSERHALB)

	# Act
	werkstatt.editor.set_event_field("reklamationswelle", &"monthly_chance", 0.0)

	# Assert: V06 als Fehler, V13 als Warnung
	assert_eq(_node(werkstatt, "%CountLabel").text, "1 Fehler, 1 Warnung")


# --- Liste ------------------------------------------------------------------------------------

func test_liste_sucht_im_titel_und_filtert_nach_art_und_kategorie() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var liste: EventList = _node(werkstatt, "%EventList")
	var suche: LineEdit = liste.get_node("%Search")

	# Act und Assert: FR-030, Teilwort, Groß- und Kleinschreibung egal
	suche.text = "PENT"
	suche.text_changed.emit(suche.text)
	assert_eq(_titel(liste), ["Intel Pentium erscheint"])
	suche.text = ""
	suche.text_changed.emit("")
	_waehlen(liste.get_node("%KindFilter"), "beim Start gesetzt")
	assert_eq(_titel(liste), ["Neubaugebiet am Stadtrand"])
	_waehlen(liste.get_node("%KindFilter"), "Alle Arten")
	_waehlen(liste.get_node("%CategoryFilter"), "Reklamation")
	assert_eq(_titel(liste), ["Reklamationswelle", "Zeitungsartikel über Reklamationen"])


func test_neu_schlaegt_die_kennung_vor_und_zeigt_die_felder_der_art() -> void:
	# Arrange: US2, Szenario 1.
	var werkstatt := await _werkstatt()
	var liste: EventList = _node(werkstatt, "%EventList")
	liste.get_node("%NewButton").pressed.emit()
	var dialog: ConfirmationDialog = liste.get_node("%NewDialog")
	assert_true(dialog.visible)

	# Act
	var titel: LineEdit = liste.get_node("%NewTitle")
	titel.text = "Neubaugebiet am Stadtrand"
	titel.text_changed.emit(titel.text)
	_waehlen(liste.get_node("%NewKind"), "beim Start gesetzt")
	_waehlen(liste.get_node("%NewCategory"), "Lokal")
	var vorschlag: String = liste.get_node("%NewId").text
	dialog.get_ok_button().pressed.emit()

	# Assert
	assert_eq(vorschlag, "neubaugebiet_am_stadtrand")
	var neu := werkstatt.editor.catalog.get_event("neubaugebiet_am_stadtrand")
	assert_not_null(neu)
	assert_eq([neu.kind, neu.category], [TimelineEvent.Kind.PRESET, "lokal"])
	assert_eq(werkstatt.selected_id, "neubaugebiet_am_stadtrand", "Das neue Ereignis ist gewählt.")
	var formular: EventForm = _node(werkstatt, "%EventForm")
	for feld in ["window.from", "window.to", "count_min", "count_max", "count_weights",
			"min_gap_days"]:
		assert_not_null(formular.get_input(feld), "Das Formular zeigt %s." % feld)
	assert_same(get_viewport().gui_get_focus_owner(), formular.get_input("title"),
		"Der Fokus steht im Titel.")


func test_neu_sperrt_eine_vorhandene_kennung() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var liste: EventList = _node(werkstatt, "%EventList")
	liste.open_new_dialog()
	var titel: LineEdit = liste.get_node("%NewTitle")
	var kennung: LineEdit = liste.get_node("%NewId")

	# Act
	titel.text = "Noch ein Pentium"
	titel.text_changed.emit(titel.text)
	kennung.text = "intel_pentium"
	kennung.text_changed.emit(kennung.text)

	# Assert: FR-032
	var dialog: ConfirmationDialog = liste.get_node("%NewDialog")
	assert_true(dialog.get_ok_button().disabled, "„Anlegen“ ist gesperrt.")
	assert_string_contains(liste.get_node("%NewHint").text, "gibt es schon")


func test_loeschen_fragt_nach_und_nennt_die_verweise() -> void:
	# Arrange: US2, Szenario 4; FR-036. Die Reklamationswelle hat zeitungsartikel als Folge.
	var werkstatt := await _werkstatt()
	werkstatt.select_event("zeitungsartikel")

	# Act
	_node(werkstatt, "%EventList").get_node("%DeleteButton").pressed.emit()

	# Assert
	var dialog: ConfirmationDialog = _node(werkstatt, "%DeleteDialog")
	assert_true(dialog.visible)
	assert_string_contains(dialog.dialog_text, "„Reklamationswelle“")
	assert_not_null(werkstatt.editor.catalog.get_event("zeitungsartikel"), "Erst nach der Antwort.")
	dialog.get_ok_button().pressed.emit()
	assert_null(werkstatt.editor.catalog.get_event("zeitungsartikel"))
	assert_eq(werkstatt.editor.catalog.get_event("reklamationswelle").follow_ups.size(), 0)
	await wait_process_frames(1)
	assert_eq(werkstatt.selected_id, "", "Das gelöschte Ereignis ist nicht mehr gewählt.")


func test_duplizieren_waehlt_die_kopie() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	werkstatt.select_event("intel_pentium")

	# Act
	_node(werkstatt, "%EventList").get_node("%DuplicateButton").pressed.emit()

	# Assert
	assert_eq(werkstatt.selected_id, "intel_pentium_2")


func test_fehler_und_warnung_stehen_als_zeichen_in_der_liste() -> void:
	# Arrange
	var werkstatt := await _werkstatt(DATUM_AUSSERHALB)
	werkstatt.editor.set_event_field("reklamationswelle", &"monthly_chance", 0.0)

	# Act
	var zeichen := {}
	for zeile in _liste(werkstatt).get_root().get_children():
		zeichen[zeile.get_metadata(EventList.Column.MARK)] = zeile.get_text(EventList.Column.MARK)

	# Assert: Style-Guide, „Farbrollen“
	assert_eq(zeichen["intel_pentium"], "!", "Fehler")
	assert_eq(zeichen["reklamationswelle"], "?", "Warnung")
	assert_eq(zeichen["neubaugebiet"], "")


func test_umbenennen_im_formular_behaelt_die_auswahl() -> void:
	# Arrange: US2, Szenario 6.
	var werkstatt := await _werkstatt()
	werkstatt.select_event("reklamationswelle")
	var kennung: LineEdit = _node(werkstatt, "%EventForm").get_input("id")

	# Act
	kennung.text = "reklamationen"
	kennung.focus_exited.emit()
	await wait_process_frames(2)

	# Assert
	assert_eq(werkstatt.selected_id, "reklamationen")
	assert_eq(werkstatt.editor.catalog.get_event("zeitungsartikel").conditions[0].event,
		"reklamationen", "Die Bedingung zeigt auf die neue Kennung.")
	assert_eq(_node(werkstatt, "%EventForm").get_input("id").text, "reklamationen")


# --- Helfer -----------------------------------------------------------------------------------

## Baut die Werkstatt mit einer Kopie von [param fixture] als Katalog; ohne Fixture mit dem, was
## schon unter [param datei] liegt oder eben nicht. Wartet, bis der Start gelaufen ist.
func _werkstatt(fixture: String = MINIMAL, datei: String = "katalog.json") -> Werkstatt:
	var ziel := ORDNER + datei
	if not fixture.is_empty():
		_kopieren(fixture, ziel)
	var werkstatt: Werkstatt = SZENE.instantiate()
	werkstatt.catalog_path = ziel
	werkstatt.editor.backup_path = ORDNER + "sicherung.json"
	add_child_autofree(werkstatt)
	# _start() kommt per call_deferred() am Ende des ersten Bilds.
	await wait_process_frames(2)
	return werkstatt


func _editor() -> CatalogEditor:
	var editor := CatalogEditor.new()
	editor.backup_path = ORDNER + "sicherung.json"
	return editor


func _node(werkstatt: Werkstatt, pfad: String) -> Node:
	return werkstatt.get_node(pfad)


func _liste(werkstatt: Werkstatt) -> Tree:
	return _node(werkstatt, "%EventList").get_node("%List")


func _dialoge(werkstatt: Werkstatt) -> Array[Window]:
	var dialoge: Array[Window] = []
	for kind in werkstatt.get_children():
		if kind is Window:
			dialoge.append(kind)
	return dialoge


func _erste_meldung(werkstatt: Werkstatt, regel: String) -> CatalogIssue:
	for meldung in werkstatt.editor.issues():
		if meldung.rule == regel:
			return meldung
	return null


## Die Titel in der Liste, wie sie dasteht.
func _titel(liste: EventList) -> Array:
	var titel := []
	for zeile in liste.get_node("%List").get_root().get_children():
		titel.append(zeile.get_text(EventList.Column.TITLE))
	return titel


## Wählt in [param auswahl] den Eintrag [param text], wie es Klaus mit der Maus täte.
func _waehlen(auswahl: OptionButton, text: String) -> void:
	for i in auswahl.item_count:
		if auswahl.get_item_text(i) == text:
			auswahl.select(i)
			auswahl.item_selected.emit(i)
			return
	fail_test("„%s“ fehlt in der Auswahl." % text)


## Cmd bzw. Ctrl plus [param taste], gedrückt.
func _taste(taste: Key, shift: bool = false) -> InputEventKey:
	var ereignis := InputEventKey.new()
	ereignis.keycode = taste
	ereignis.shift_pressed = shift
	ereignis.command_or_control_autoremap = true
	ereignis.pressed = true
	return ereignis


func _kopieren(fixture: String, ziel: String) -> String:
	_schreiben(ziel, FileAccess.get_file_as_string(fixture))
	return ziel


func _schreiben(ziel: String, text: String) -> void:
	var datei := FileAccess.open(ziel, FileAccess.WRITE)
	datei.store_string(text)
	datei.close()


func _datei() -> String:
	return FileAccess.get_file_as_string(ORDNER + "katalog.json")
