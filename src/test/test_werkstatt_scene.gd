extends GutTest

## Rauchtest der Werkstatt (Feature 002, T039; contracts/werkstatt.md): Die Szene baut headless auf
## und lässt das Fenster in Ruhe, und eine Prüfmeldung führt zum Ereignis und ins Feld (FR-033).
## Dazu die Abläufe beim Start, beim Speichern, Verwerfen und Schließen, die Kürzel und die Liste
## (T034, T035, T038), der Zeitstrahl in der Werkstatt (T049) und der Simulator (T054): Er rechnet,
## ohne Spieluhr und Katalog anzufassen, und sein Protokoll ist das der Textausgabe.
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


func test_langer_katalogpfad_kuerzt_sich_und_steht_voll_im_hinweis() -> void:
	# Arrange: ein Katalog unter einem Dateinamen von 237 Zeichen; erlaubt sind 255.
	var datei := "katalog_" + "mit_einem_sehr_langen_namen_".repeat(8) + ".json"
	var werkstatt := await _werkstatt(MINIMAL, datei)
	# Headless ist das Fenster 640 × 360 groß, zu schmal für Liste und Formular nebeneinander.
	werkstatt.size = Vector2(1200.0, 800.0)

	# Act
	await wait_process_frames(2)

	# Assert
	var layout: Control = _node(werkstatt, "Layout")
	assert_eq(layout.size.x, werkstatt.size.x - 16.0,
		"Der Inhalt bleibt so breit wie die Werkstatt, abzüglich der Ränder von 8 Pixeln.")
	var datei_label: Label = _node(werkstatt, "%FileLabel")
	assert_eq(datei_label.text, ORDNER + datei)
	var voll := datei_label.get_theme_font(&"font").get_string_size(datei_label.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, datei_label.get_theme_font_size(&"font_size")).x
	assert_lt(datei_label.size.x, voll, "Der Dateiname ist gekürzt.")
	assert_string_contains(datei_label.tooltip_text, ORDNER + datei,
		"Der Hinweis nennt den vollen Pfad.")


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


# --- Zebra in Liste und Prüfung (Phase 7) -----------------------------------------------------

func test_liste_im_zebra_mit_auswahl_in_petrol() -> void:
	# Arrange: Neubaugebiet in Zeile 1 bekommt einen Fehler (V07, Fenster endet vor dem Beginn),
	# die Reklamationswelle in Zeile 2 eine Warnung (V13, Grundchance 0).
	var werkstatt := await _werkstatt()
	werkstatt.editor.set_event_field("neubaugebiet", &"window_to", 0)
	werkstatt.editor.set_event_field("reklamationswelle", &"monthly_chance", 0.0)
	var zeilen: Array[TreeItem] = _liste(werkstatt).get_root().get_children()
	var zeichen := EventList.Column.MARK
	var titel := EventList.Column.TITLE
	assert_eq([zeilen[1].get_text(zeichen), zeilen[2].get_text(zeichen)], ["!", "?"])

	# Assert: Style-Guide, „Farbrollen“: jede zweite Zeile endlos-gruen
	assert_eq(zeilen[1].get_custom_bg_color(titel), UiPalette.ENDLOS_GRUEN)
	assert_eq(zeilen[3].get_custom_bg_color(titel), UiPalette.ENDLOS_GRUEN)
	assert_ne(zeilen[2].get_custom_bg_color(titel), UiPalette.ENDLOS_GRUEN)
	assert_eq(zeilen[1].get_custom_bg_color(zeichen), UiPalette.KASSENROT,
		"Das „!“ bleibt kassenrot, auch in einer gestreiften Zeile.")

	# Act: die Reklamationswelle wählen, wie mit der Maus
	zeilen[2].select(titel)

	# Assert: Die Auswahl ist petrol; das „?“ bleibt holz auf papier.
	assert_eq(werkstatt.selected_id, "reklamationswelle")
	assert_eq(zeilen[2].get_custom_bg_color(titel), UiPalette.PETROL)
	assert_eq([zeilen[2].get_custom_bg_color(zeichen), zeilen[2].get_custom_color(zeichen)],
		[UiPalette.PAPIER, UiPalette.HOLZ], "Das „?“ bleibt holz auf papier.")

	# Act und Assert: Auch in der gewählten Zeile bleibt das „!“ kassenrot.
	zeilen[1].select(titel)
	assert_eq(zeilen[1].get_custom_bg_color(titel), UiPalette.PETROL)
	assert_eq(zeilen[1].get_custom_bg_color(zeichen), UiPalette.KASSENROT)
	assert_ne(zeilen[2].get_custom_bg_color(titel), UiPalette.PETROL, "Die alte Auswahl ist weg.")

	# Act und Assert: Wählt die Werkstatt keins mehr, ist die Zeile wieder gestreift.
	werkstatt.select_event("")
	assert_eq(zeilen[1].get_custom_bg_color(titel), UiPalette.ENDLOS_GRUEN)


func test_pruefung_im_zebra_mit_auswahl_in_petrol() -> void:
	# Arrange: drei Meldungen, nach Ereignis und Regel: V06 als Fehler, V20 und V13 als Warnungen.
	var werkstatt := await _werkstatt(DATUM_AUSSERHALB)
	werkstatt.editor.set_item_field("intel_pentium", &"effects", 0, &"magnitude", 0.0)
	werkstatt.editor.set_event_field("reklamationswelle", &"monthly_chance", 0.0)
	var pruefung: IssuesPanel = _node(werkstatt, "%IssuesPanel")
	var zeilen: Array[TreeItem] = pruefung.get_root().get_children()
	var stufe := IssuesPanel.Column.SEVERITY
	var text := IssuesPanel.Column.TEXT
	assert_eq([zeilen[0].get_text(stufe), zeilen[1].get_text(stufe), zeilen[2].get_text(stufe)],
		["! Fehler", "? Warnung", "? Warnung"])

	# Assert: Style-Guide, „Farbrollen“
	assert_eq(zeilen[1].get_custom_bg_color(text), UiPalette.ENDLOS_GRUEN)
	assert_ne(zeilen[2].get_custom_bg_color(text), UiPalette.ENDLOS_GRUEN)
	assert_eq([zeilen[1].get_custom_bg_color(stufe), zeilen[1].get_custom_color(stufe)],
		[UiPalette.PAPIER, UiPalette.HOLZ], "Die Warnung bleibt holz auf papier, auch gestreift.")

	# Act: den Fehler wählen
	zeilen[0].select(text)

	# Assert
	assert_eq(zeilen[0].get_custom_bg_color(text), UiPalette.PETROL)
	assert_eq(zeilen[0].get_custom_bg_color(stufe), UiPalette.KASSENROT,
		"Das Fehlerfeld bleibt kassenrot, auch in der gewählten Zeile.")


# --- Zeitstrahl (T049) ------------------------------------------------------------------------
#
# Headless ist das Fenster 640 × 360 groß; neben Liste und Formular bleibt für den Zeitstrahl dann
# keine Breite. Wo ein Test auf Marken klickt, gibt er ihm deshalb selbst eine Größe. Der Container
# setzt sie erst im nächsten Bild zurück, darum kommt bis zum Ende des Tests kein await.


func test_ziehen_im_zeitstrahl_aendert_den_katalog_und_cmd_z_nimmt_es_zurueck() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var zeitstrahl: TimelineView = _node(werkstatt, "%TimelineView")
	var tag_vorher := _tag(1993, 3, 22)

	# Act: Beim Loslassen meldet der Zeitstrahl event_moved (test_timeline_view.gd).
	zeitstrahl.event_moved.emit("intel_pentium", &"date", _tag(1993, 4, 15))

	# Assert: US4, Szenarien 1 und 7
	assert_eq(werkstatt.editor.catalog.get_event("intel_pentium").date, _tag(1993, 4, 15))
	assert_eq(werkstatt.editor.undo_name(), "Datum von Intel Pentium erscheint",
		"Das Ziehen ist ein Schritt im Verlauf.")
	get_viewport().push_input(_taste(KEY_Z))
	assert_eq(werkstatt.editor.catalog.get_event("intel_pentium").date, tag_vorher,
		"Cmd+Z stellt den 22.03.1993 wieder her.")


func test_zeitstrahl_folgt_katalog_und_auswahl() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var zeitstrahl: TimelineView = _node(werkstatt, "%TimelineView")
	zeitstrahl.size = Vector2(900.0, 300.0)
	var vorher := zeitstrahl.mark_rects("intel_pentium")[0].position.x

	# Act
	werkstatt.editor.set_event_field("intel_pentium", &"date", _tag(1996, 3, 22))
	zeitstrahl.event_clicked.emit("neubaugebiet")

	# Assert
	assert_gt(zeitstrahl.mark_rects("intel_pentium")[0].position.x, vorher,
		"Nach catalog_changed steht der Pentium drei Jahre später.")
	assert_eq(werkstatt.selected_id, "neubaugebiet", "Ein Klick im Zeitstrahl wählt.")


func test_doppelklick_oeffnet_den_dialog_vorbelegt_und_legt_das_ereignis_an() -> void:
	# Arrange: US4, Szenario 5, ein Doppelklick in der Zeile Hardware am 12.03.1996
	var werkstatt := await _werkstatt()
	var liste: EventList = _node(werkstatt, "%EventList")
	var tag := _tag(1996, 3, 12)

	# Act: Den Doppelklick meldet der Zeitstrahl als create_requested (test_timeline_view.gd).
	_node(werkstatt, "%TimelineView").create_requested.emit("hardware", tag)

	# Assert: Der Dialog „Neu …“ ist vorbelegt, der Fokus steht im Titel.
	var dialog: ConfirmationDialog = liste.get_node("%NewDialog")
	assert_true(dialog.visible)
	var art: OptionButton = liste.get_node("%NewKind")
	var kategorie: OptionButton = liste.get_node("%NewCategory")
	assert_eq(art.get_item_text(art.selected), "fix")
	assert_eq(kategorie.get_item_metadata(kategorie.selected), "hardware")
	assert_true(liste.get_node("%NewDate").visible)
	assert_eq(liste.get_node("%NewDate").text, "12.03.1996")
	var titel: LineEdit = liste.get_node("%NewTitle")
	assert_true(titel.has_focus(), "Der Fokus steht im Titel des Dialogs.")

	# Act: Titel eingeben und anlegen
	titel.text = "Neuer Rechner"
	titel.text_changed.emit(titel.text)
	assert_eq(liste.get_node("%NewId").text, "neuer_rechner", "Die Kennung folgt dem Titel.")
	dialog.get_ok_button().pressed.emit()

	# Assert
	var neu := werkstatt.editor.catalog.get_event("neuer_rechner")
	assert_not_null(neu)
	if neu != null:
		assert_eq([neu.kind, neu.date, neu.category], [TimelineEvent.Kind.FIXED, tag, "hardware"])
	assert_eq(werkstatt.selected_id, "neuer_rechner", "Das neue Ereignis ist gewählt.")
	assert_same(get_viewport().gui_get_focus_owner(),
		_node(werkstatt, "%EventForm").get_input("title"),
		"Der Fokus steht im Titel des Formulars.")


func test_doppelklick_mit_anderer_art_nimmt_deren_vorgaben() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var liste: EventList = _node(werkstatt, "%EventList")
	_node(werkstatt, "%TimelineView").create_requested.emit("lokal", _tag(1996, 3, 12))
	var titel: LineEdit = liste.get_node("%NewTitle")
	titel.text = "Neue Siedlung"
	titel.text_changed.emit(titel.text)

	# Act: Der Tag gilt nur für fix.
	_waehlen(liste.get_node("%NewKind"), "beim Start gesetzt")

	# Assert
	assert_false(liste.get_node("%NewDate").visible, "Für eine andere Art steht kein Datum da.")
	liste.get_node("%NewDialog").get_ok_button().pressed.emit()
	var neu := werkstatt.editor.catalog.get_event("neue_siedlung")
	assert_not_null(neu)
	if neu != null:
		assert_eq([neu.kind, neu.category, neu.window_from, neu.window_to],
			[TimelineEvent.Kind.PRESET, "lokal", 0, 5477], "Die Vorgaben der Art gelten.")


func test_doppelklick_abbrechen_legt_nichts_an() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var anzahl := werkstatt.editor.catalog.events.size()
	var dialog: ConfirmationDialog = _node(werkstatt, "%EventList").get_node("%NewDialog")
	_node(werkstatt, "%TimelineView").create_requested.emit("hardware", _tag(1996, 3, 12))

	# Act
	dialog.get_cancel_button().pressed.emit()
	await wait_process_frames(1)

	# Assert
	assert_false(dialog.visible)
	assert_eq(werkstatt.editor.catalog.events.size(), anzahl)
	assert_false(werkstatt.editor.can_undo(), "Kein Schritt im Verlauf.")
	# Der Knopf „Neu …“ öffnet den Dialog wieder ohne Datum.
	_node(werkstatt, "%EventList").get_node("%NewButton").pressed.emit()
	assert_false(_node(werkstatt, "%EventList").get_node("%NewDate").visible)


func test_menue_im_zeitstrahl_bearbeiten_duplizieren_loeschen() -> void:
	# Arrange: ein Rechtsklick auf den Pentium im Zeitstrahl
	var werkstatt := await _werkstatt()
	var zeitstrahl: TimelineView = _node(werkstatt, "%TimelineView")
	zeitstrahl.size = Vector2(900.0, 300.0)
	var knopf := InputEventMouseButton.new()
	knopf.button_index = MOUSE_BUTTON_RIGHT
	knopf.pressed = true
	knopf.position = zeitstrahl.mark_rects("intel_pentium")[0].get_center()
	zeitstrahl._gui_input(knopf)
	var menue: PopupMenu = null
	for kind in zeitstrahl.get_children(true):
		if kind is PopupMenu:
			menue = kind
	assert_true(menue != null and menue.visible, "Das Menü ist offen.")
	assert_eq(werkstatt.selected_id, "intel_pentium", "Der Rechtsklick wählt.")
	if menue == null:
		return

	# Act und Assert: „Bearbeiten“ setzt den Fokus in den Titel des Formulars.
	menue.id_pressed.emit(TimelineView.MenuItem.EDIT)
	assert_same(get_viewport().gui_get_focus_owner(),
		_node(werkstatt, "%EventForm").get_input("title"))
	# „Duplizieren“ legt die Kopie an und wählt sie.
	menue.id_pressed.emit(TimelineView.MenuItem.DUPLICATE)
	assert_eq(werkstatt.selected_id, "intel_pentium_2")
	# „Löschen“ führt zur Rückfrage (FR-036) und löscht noch nichts.
	menue.id_pressed.emit(TimelineView.MenuItem.DELETE)
	var dialog: ConfirmationDialog = _node(werkstatt, "%DeleteDialog")
	assert_true(dialog.visible)
	assert_string_contains(dialog.dialog_text, "„Intel Pentium erscheint“ löschen?")
	assert_not_null(werkstatt.editor.catalog.get_event("intel_pentium"), "Erst nach der Antwort.")
	menue.hide()


# --- Simulator (T054) -------------------------------------------------------------------------
#
# Die Tests drücken die Knöpfe über ihr Signal pressed, wie die übrigen Tests der Werkstatt. Ein
# Signal fragt nicht, ob der Knopf gesperrt ist; wo das zählt, prüfen die Tests es selbst.


func test_simulator_erzeugt_fuer_seed_4711_einen_fahrplan() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	var tabs: TabContainer = _node(werkstatt, "%Tabs")
	assert_eq(tabs.get_tab_title(tabs.get_tab_idx_from_control(simulator)), "Simulator")
	assert_true(simulator.get_node("%DayButton").disabled, "Ohne Fahrplan ist nichts abzuspielen.")

	# Act
	_erzeugen(simulator, "4711")

	# Assert: US5, Szenario 1
	assert_not_null(simulator.run)
	assert_eq([simulator.run.seed, simulator.run.today], [4711, -1],
		"Der Lauf hat den Seed aus dem Feld und steht vor dem 01.01.1985.")
	var zeilen := _zeilen(simulator.get_node("%PlanTable"))
	assert_gt(zeilen.size(), 0, "Die Tabelle hat Zeilen.")
	assert_eq(zeilen.size(), simulator.run.entries.size(), "Je Termin eine Zeile.")
	assert_has(zeilen, ["22.03.1993", "Intel Pentium erscheint", "fix", "geplant"])
	var zustaende := {}
	for zeile: Array in zeilen:
		zustaende[zeile[SimulatorPanel.PlanColumn.STATE]] = true
	assert_eq(zustaende.keys(), ["geplant"], "Alle Termine, die schon feststehen, sind geplant.")
	assert_eq(_zeilen(simulator.get_node("%Protocol")).size(), 0, "Noch ist nichts gemeldet.")
	assert_eq(simulator.get_node("%DateLabel").text, "Stand: vor dem 01.01.1985 · Seed 4711")
	assert_false(simulator.get_node("%DayButton").disabled)
	assert_false(simulator.get_node("%ExcludedNotice").visible, "Der Katalog hat keine Fehler.")


func test_bis_zum_ende_laesst_spieluhr_und_katalog_in_ruhe() -> void:
	# Arrange: Die Autoloads GameClock und Timeline kommen über ihren Pfad. Ihre Namen kennt
	# GDScript erst, wenn Godot sie angelegt hat; ein Skript, das mit -s startet, kennt sie nicht.
	var uhr := get_node(^"/root/GameClock")
	var zeitleiste := get_node(^"/root/Timeline")
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	var datum: GameDate = uhr.date
	var tag := datum.to_day_index()
	var pausiert: bool = uhr.paused
	var spiel: TimelineRun = zeitleiste.run
	var katalog := werkstatt.editor.catalog.to_json()
	_erzeugen(simulator, "4711")

	# Act
	_druecken(simulator, "%EndButton")

	# Assert: US5, Szenario 5; FR-042
	assert_true(simulator.run.is_finished())
	assert_same(uhr.date, datum, "Die Spieluhr hat noch dasselbe Datum …")
	assert_eq(uhr.date.to_day_index(), tag, "… mit demselben Tag …")
	assert_eq(uhr.paused, pausiert, "… und läuft nicht los.")
	assert_same(zeitleiste.run, spiel, "Das Spiel behält seinen Lauf.")
	assert_eq(werkstatt.editor.catalog.to_json(), katalog, "Der Katalog ist unverändert.")
	assert_false(werkstatt.editor.can_undo(), "Kein Schritt im Verlauf.")
	assert_eq(simulator.get_node("%DateLabel").text, "Stand: 31.12.1999, Spielende · Seed 4711")
	for knopf in ["%DayButton", "%MonthButton", "%YearButton", "%UntilButton", "%EndButton"]:
		assert_true(simulator.get_node(knopf).disabled, "%s ist am Spielende gesperrt." % knopf)


func test_protokoll_entspricht_der_textausgabe() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")

	# Act: in Schritten wie im Quickstart, dann bis zum Ende
	_druecken(simulator, "%DayButton")
	_druecken(simulator, "%MonthButton")
	_druecken(simulator, "%YearButton")
	_bis(simulator, "31.12.1990")
	_druecken(simulator, "%EndButton")

	# Assert: derselbe Lauf wie in fahrplan_ausgabe.gd mit --protokoll, in einem Zug abgespielt
	var meldungen: Array[CatalogIssue] = []
	var katalog := EventCatalog.read_file(MINIMAL, meldungen)
	meldungen.append_array(CatalogValidator.validate(katalog))
	var lauf := TimelineRun.new(katalog.without_faulty(meldungen), 4711)
	lauf.advance_to(TimelineRun.LAST_DAY)
	var erwartet := Array(ScheduleText.protocol_lines(lauf))
	var protokoll := []
	for zeile: Array in _zeilen(simulator.get_node("%Protocol")):
		protokoll.append(zeile[0])
	assert_gt(erwartet.size(), 0)
	assert_eq(protokoll, erwartet, "Zeile für Zeile wie die Textausgabe.")


func test_seed_feld_nimmt_nur_ziffern_bis_zum_groessten_seed() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	var feld: LineEdit = simulator.get_node("%SeedEdit")
	var erzeugen: Button = simulator.get_node("%GenerateButton")
	assert_true(erzeugen.disabled, "Ohne Seed gibt es nichts zu erzeugen.")
	feld.grab_focus()

	# Act: Buchstaben zwischen den Ziffern. Ein LineEdit meldet text_changed am Ende des Bilds.
	_tippen("4a7b1c1")
	await wait_process_frames(1)

	# Assert: FR-040
	assert_eq(feld.text, "4711", "Die Buchstaben sind weg.")
	assert_false(erzeugen.disabled)

	# Act und Assert: Mehr als 2.147.483.647 gibt es nicht.
	feld.clear()
	_tippen("3000000000")
	await wait_process_frames(1)
	assert_eq(feld.text, "2147483647", "Zu groß wird zum größten Seed.")
	_tippen("5")
	await wait_process_frames(1)
	assert_eq(feld.text, "2147483647", "Eine weitere Ziffer ändert nichts.")
	feld.release_focus()

	# Act und Assert: „Würfeln“ schreibt einen Seed aus 0 bis 2.147.483.647 ins Feld.
	_druecken(simulator, "%RollButton")
	assert_true(feld.text.is_valid_int() and feld.text.lstrip("0123456789").is_empty(),
		"Nur Ziffern: %s" % feld.text)
	assert_between(feld.text.to_int(), 0, SimulatorPanel.MAX_SEED)


func test_schritte_springen_wie_die_spieluhr() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	var hinweis: Label = simulator.get_node("%InputHint")
	_erzeugen(simulator, "4711")

	# Act und Assert: Der erste Schritt spielt den 01.01.1985 ab, ob „+1 Monat“ oder „+1 Jahr“.
	_druecken(simulator, "%MonthButton")
	assert_eq(simulator.run.today, 0)
	assert_eq(simulator.get_node("%DateLabel").text, "Stand: 01.01.1985 · Seed 4711")
	_druecken(simulator, "%GenerateButton")
	_druecken(simulator, "%YearButton")
	assert_eq(simulator.run.today, 0)
	# FR-041: tage-, monats- und jahresweise, wie GameClock bis zum nächsten Ersten
	_druecken(simulator, "%DayButton")
	assert_eq(simulator.run.today, _tag(1985, 1, 2))
	_druecken(simulator, "%MonthButton")
	assert_eq(simulator.run.today, _tag(1985, 2, 1))
	_druecken(simulator, "%YearButton")
	assert_eq(simulator.run.today, _tag(1986, 1, 1))
	_bis(simulator, "15.3.1993")
	assert_eq(simulator.run.today, _tag(1993, 3, 15), "Auch ohne führende Nullen.")
	assert_eq(simulator.get_node("%UntilEdit").text, "15.03.1993")
	_druecken(simulator, "%MonthButton")
	assert_eq(simulator.run.today, _tag(1993, 4, 1), "Von der Monatsmitte zum nächsten Ersten.")

	# Act und Assert: Ein Datum, das nicht passt, spielt nichts ab und sagt, warum.
	for falsch: Array in [["abc", "kein Datum"], ["1.1.1990", "schon abgespielt"],
			["1.1.2001", "31.12.1999"]]:
		_bis(simulator, falsch[0])
		assert_eq(simulator.run.today, _tag(1993, 4, 1), "%s spielt nichts ab." % falsch[0])
		assert_true(hinweis.visible)
		assert_string_contains(hinweis.text, falsch[1])
	assert_eq(simulator.get_node("%UntilEdit").theme_type_variation, &"ErrorLineEdit")
	_druecken(simulator, "%EndButton")
	assert_eq(simulator.run.today, TimelineRun.LAST_DAY)
	assert_false(hinweis.visible, "Nach einem Schritt ist der Hinweis weg.")


func test_gewaehlter_termin_zeigt_begruendung_und_verzoegerte_wirkungen() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_druecken(simulator, "%EndButton")
	var begruendung: Label = simulator.get_node("%DetailText")

	# Act: den Pentium wählen
	_termin_waehlen(simulator, _termin(simulator, "intel_pentium", ScheduleEntry.Origin.FIXED))

	# Assert: FR-041, SC-007
	assert_eq(simulator.get_node("%DetailTitle").text, "Intel Pentium erscheint (intel_pentium)")
	assert_string_contains(begruendung.text, "Begründung: Fixes Datum aus dem Katalog")
	assert_string_contains(begruendung.text, "05.04.1993  Nachfrage · ram · +20%")
	assert_eq(werkstatt.selected_id, "intel_pentium", "Die Auswahl der Werkstatt folgt.")

	# Act: einen gewürfelten Termin wählen
	var gewuerfelt := _termin(simulator, "reklamationswelle", ScheduleEntry.Origin.ROLLED)
	assert_not_null(gewuerfelt, "Mit Seed 4711 würfelt die Reklamationswelle.")
	if gewuerfelt == null:
		return
	_termin_waehlen(simulator, gewuerfelt)

	# Assert: US5, Szenario 3; Würfelwert, Grundchance und Schwelle stehen da.
	assert_string_contains(begruendung.text, "Begründung: %s" % gewuerfelt.explain())
	assert_string_contains(begruendung.text, "Würfel 0,")
	assert_string_contains(begruendung.text, "< Schwelle 0,0300 (3 %)")
	assert_eq(werkstatt.selected_id, "reklamationswelle")


func test_auswahl_folgt_nur_einem_ereignis_das_es_noch_gibt() -> void:
	# Arrange: Der Lauf rechnet mit einer Kopie; im Katalog heißt der Pentium inzwischen anders.
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	werkstatt.editor.rename_event("intel_pentium", "pentium")

	# Act
	_termin_waehlen(simulator, _termin(simulator, "intel_pentium", ScheduleEntry.Origin.FIXED))

	# Assert
	assert_eq(werkstatt.selected_id, "", "Die Werkstatt wählt kein Ereignis, das es nicht gibt.")
	assert_string_contains(simulator.get_node("%DetailText").text, "Fixes Datum aus dem Katalog",
		"Die Begründung steht trotzdem da.")


func test_katalog_geaendert_waehrend_eines_laufs() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	var hinweis: Label = simulator.get_node("%CatalogNotice")
	_erzeugen(simulator, "4711")
	_bis(simulator, "31.12.1990")
	var lauf := simulator.run
	var fahrplan := _zeilen(simulator.get_node("%PlanTable"))
	var protokoll := _zeilen(simulator.get_node("%Protocol"))
	assert_false(hinweis.visible)

	# Act: FR-042, eine Änderung ohne Speichern
	werkstatt.editor.set_event_field("intel_pentium", &"date", _tag(1996, 3, 22))
	await wait_process_frames(1)

	# Assert: Der Hinweis erscheint, der Lauf behält seinen Stand.
	assert_true(hinweis.visible)
	assert_eq(hinweis.text, "? Katalog geändert, neu starten")
	assert_eq(hinweis.theme_type_variation, &"WarningLabel", "Eine Warnung als Text in holz.")
	assert_same(simulator.run, lauf)
	assert_eq(lauf.today, _tag(1990, 12, 31))
	assert_eq(lauf.catalog.get_event("intel_pentium").date, _tag(1993, 3, 22),
		"Der Lauf rechnet mit seiner Kopie.")
	assert_eq(_zeilen(simulator.get_node("%PlanTable")), fahrplan)
	assert_eq(_zeilen(simulator.get_node("%Protocol")), protokoll)

	# Act und Assert: Rückgängig bringt den Katalog des Laufs zurück; der Hinweis geht.
	werkstatt.editor.undo()
	await wait_process_frames(1)
	assert_false(hinweis.visible)

	# Act und Assert: Neu erzeugt gilt die Änderung, auch ungespeichert, und der Hinweis geht.
	werkstatt.editor.redo()
	await wait_process_frames(1)
	assert_true(hinweis.visible)
	_druecken(simulator, "%GenerateButton")
	assert_false(hinweis.visible)
	assert_has(_zeilen(simulator.get_node("%PlanTable")),
		["22.03.1996", "Intel Pentium erscheint", "fix", "geplant"])


func test_fehlerhaftes_ereignis_wird_ausgenommen_und_genannt() -> void:
	# Arrange: intel_pentium liegt am 12.05.2001 (V06).
	var werkstatt := await _werkstatt(DATUM_AUSSERHALB)
	var simulator := _simulator(werkstatt)

	# Act
	_erzeugen(simulator, "4711")

	# Assert: FR-042 mit FR-049
	var hinweis: Label = simulator.get_node("%ExcludedNotice")
	assert_true(hinweis.visible)
	assert_string_contains(hinweis.text, "„Intel Pentium erscheint“")
	assert_eq(hinweis.theme_type_variation, &"ErrorNoticeLabel",
		"Ein Fehler als gefülltes Feld in kassenrot.")
	assert_null(simulator.run.catalog.get_event("intel_pentium"), "Es fehlt im Lauf …")
	var titel := []
	for zeile: Array in _zeilen(simulator.get_node("%PlanTable")):
		titel.append(zeile[SimulatorPanel.PlanColumn.EVENT])
	assert_does_not_have(titel, "Intel Pentium erscheint", "… und in der Tabelle …")
	assert_not_null(werkstatt.editor.catalog.get_event("intel_pentium"), "… aber nicht im Katalog.")


func test_fahrplan_im_zebra_mit_auswahl_in_petrol() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	var zeilen: Array[TreeItem] = simulator.get_node("%PlanTable").get_root().get_children()

	# Assert: Style-Guide, „Farbrollen“: jede zweite Zeile endlos-gruen
	assert_eq(zeilen[1].get_custom_bg_color(0), UiPalette.ENDLOS_GRUEN)
	assert_eq(zeilen[3].get_custom_bg_color(0), UiPalette.ENDLOS_GRUEN)
	assert_ne(zeilen[2].get_custom_bg_color(0), UiPalette.ENDLOS_GRUEN)

	# Act und Assert: Die gewählte Zeile ist petrol, auch eine aus dem Zebra.
	zeilen[1].select(0)
	assert_eq(zeilen[1].get_custom_bg_color(0), UiPalette.PETROL)
	zeilen[2].select(0)
	assert_eq(zeilen[2].get_custom_bg_color(0), UiPalette.PETROL)
	assert_eq(zeilen[1].get_custom_bg_color(0), UiPalette.ENDLOS_GRUEN, "Die alte ist wieder grün.")


func test_bis_zum_ende_dauert_unter_einer_sekunde() -> void:
	# Arrange: SC-004 an der eingefrorenen Übernahme; den echten Katalog prüfen Tests nicht (R20).
	var werkstatt := await _werkstatt(UEBERNAHME)
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")

	# Act: samt Tabelle und Protokoll
	var beginn := Time.get_ticks_usec()
	_druecken(simulator, "%EndButton")
	var dauer := (Time.get_ticks_usec() - beginn) / 1000.0

	# Assert
	gut.p("„Bis zum Ende“ mit der Übernahme: %.1f ms" % dauer)
	assert_true(simulator.run.is_finished())
	assert_gt(_zeilen(simulator.get_node("%Protocol")).size(), 0)
	assert_lt(dauer, 1000.0, "SC-004: unter 1 Sekunde.")


# --- Helfer -----------------------------------------------------------------------------------

## Tagesindex eines Datums.
func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()


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


## Der Simulator der Werkstatt; sein Reiter wird gewählt, wie es Klaus täte.
func _simulator(werkstatt: Werkstatt) -> SimulatorPanel:
	var simulator: SimulatorPanel = _node(werkstatt, "%SimulatorPanel")
	var tabs: TabContainer = _node(werkstatt, "%Tabs")
	tabs.current_tab = tabs.get_tab_idx_from_control(simulator)
	return simulator


## Seed ins Feld, dann „Fahrplan erzeugen“.
func _erzeugen(simulator: SimulatorPanel, seed_text: String) -> void:
	var feld: LineEdit = simulator.get_node("%SeedEdit")
	feld.text = seed_text
	feld.text_changed.emit(seed_text)
	_druecken(simulator, "%GenerateButton")


func _druecken(simulator: SimulatorPanel, knopf: String) -> void:
	var button: Button = simulator.get_node(knopf)
	button.pressed.emit()


## Datum ins Feld neben „Bis“, dann „Bis“.
func _bis(simulator: SimulatorPanel, datum: String) -> void:
	var feld: LineEdit = simulator.get_node("%UntilEdit")
	feld.text = datum
	_druecken(simulator, "%UntilButton")


## Die Zeilen einer Tabelle, je Zeile die Texte ihrer Spalten.
func _zeilen(tabelle: Tree) -> Array:
	var zeilen := []
	for zeile in tabelle.get_root().get_children():
		var texte := []
		for spalte in tabelle.columns:
			texte.append(zeile.get_text(spalte))
		zeilen.append(texte)
	return zeilen


## Tippt [param text] in das Feld mit dem Fokus, Zeichen für Zeichen.
func _tippen(text: String) -> void:
	for zeichen in text:
		var taste := InputEventKey.new()
		taste.unicode = zeichen.unicode_at(0)
		taste.pressed = true
		get_viewport().push_input(taste)


## Der erste Termin des Ereignisses [param id] mit der Herkunft [param herkunft]; null ohne einen.
func _termin(simulator: SimulatorPanel, id: String,
		herkunft: ScheduleEntry.Origin) -> ScheduleEntry:
	for termin in simulator.run.entries:
		if termin.event.id == id and termin.origin == herkunft:
			return termin
	return null


## Wählt die Zeile des Termins in der Tabelle des Fahrplans, wie mit der Maus.
func _termin_waehlen(simulator: SimulatorPanel, termin: ScheduleEntry) -> void:
	var tabelle: Tree = simulator.get_node("%PlanTable")
	for zeile in tabelle.get_root().get_children():
		if zeile.get_metadata(SimulatorPanel.PlanColumn.DATE) == termin.serial:
			zeile.select(SimulatorPanel.PlanColumn.DATE)
			return
	fail_test("Der Termin %d fehlt in der Tabelle." % termin.serial)


func _kopieren(fixture: String, ziel: String) -> String:
	_schreiben(ziel, FileAccess.get_file_as_string(fixture))
	return ziel


func _schreiben(ziel: String, text: String) -> void:
	var datei := FileAccess.open(ziel, FileAccess.WRITE)
	datei.store_string(text)
	datei.close()


func _datei() -> String:
	return FileAccess.get_file_as_string(ORDNER + "katalog.json")
