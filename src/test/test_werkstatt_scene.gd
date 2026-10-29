extends GutTest

## Rauchtest der Werkstatt (Feature 002, T039; contracts/werkstatt.md): Die Szene baut headless auf
## und lässt das Fenster in Ruhe, und eine Prüfmeldung führt zum Ereignis und ins Feld (FR-033).
## Dazu die Abläufe beim Start, beim Speichern, Verwerfen und Schließen samt der Sicherungskopie je
## Katalog (T078), die Kürzel und die Liste (T034, T035, T038), Klicks mit offener Eingabe in
## Liste, Prüfung, Zeitstrahl und Formular (T076, T077, T080), der Zeitstrahl in der Werkstatt
## (T049) und der Simulator (T054): Er rechnet, ohne Spieluhr und Katalog anzufassen, und sein
## Protokoll ist das der Textausgabe. Aus Feature 003 (T017) kommt der Reiter
## „Schwierigkeitsgrade“ dazu: sein Platz, der Sprung aus der Prüfung, der Löschdialog, auch bei
## doppelter Kennung (T037), und der Grad in der Spalte „Ereignis“ der Prüfung.
##
## Jeder Test öffnet eine Kopie eines Test-Katalogs in einem eigenen Ordner unter user:// und setzt
## diesen Ordner auch für die Sicherungskopien, dazu eine eigene Einstellungsdatei, bevor die Szene
## in den Baum kommt; after_each() räumt auf. Der echte Katalog, die echten Sicherungskopien und
## die echten Einstellungen bleiben unberührt.
##
## Kein Test lässt get_tree().quit() laufen, es beendete den ganzen Testlauf. Was davor geschieht,
## prüfen die Tests über Werkstatt.prepare_quit(); wer die Werkstatt schließen lässt, setzt vorher
## Werkstatt.quit_callback (T042). Cmd+Q bei offenem Dialog kommt aus Phase 8 dazu (T042), Tab durch
## das Formular auch (T041).

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
## Leicht −2 und Schwer +5 auf die Reklamationswelle; Kundenflucht hat sie als Bedingung.
const GRADE := "res://test/fixtures/catalog_us1_grade.json"
## Leicht: ein Start-Modifikator ohne Grund (V29).
const GRUND_LEER := "res://test/fixtures/catalog_v29_profil_grund_leer.json"
## Schwer: ein Start-Modifikator auf das jährliche Weihnachtsgeschäft (V26).
const JAEHRLICH := "res://test/fixtures/catalog_v26_profil_ereignis_jaehrlich.json"


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


func test_headless_haelt_die_werkstatt_game_window_nicht_an() -> void:
	# Arrange (Feature 008, T036a, W2): eine Vertretung für GameWindow über die Naht game_window.
	# Ohne Fenster richtet die Werkstatt keins ein und hält deshalb auch nichts an; mit Fenster
	# hielte sie die Vertretung an statt des Autoloads. Das zeigt nur ein echtes Fenster (Prüfung
	# von Hand).
	var vertretung := Node.new()
	vertretung.set_process(true)
	vertretung.set_process_input(true)
	add_child_autofree(vertretung)
	var autoload := get_node(^"/root/GameWindow")
	var vorher := [autoload.is_processing(), autoload.is_processing_input()]
	var werkstatt: Werkstatt = SZENE.instantiate()
	werkstatt.catalog_path = _kopieren(MINIMAL, ORDNER + "katalog.json")
	werkstatt.editor.backup_folder = ORDNER
	werkstatt.settings_path = ORDNER + "einstellungen.cfg"
	werkstatt.game_window = vertretung

	# Act
	add_child_autofree(werkstatt)
	await wait_process_frames(2)

	# Assert
	assert_eq([vertretung.is_processing(), vertretung.is_processing_input()], [true, true],
		"Headless bleibt die Vertretung, wie sie ist.")
	assert_eq([autoload.is_processing(), autoload.is_processing_input()], vorher,
		"Das Autoload auch.")


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


func test_kopie_eines_anderen_katalogs_wird_nicht_erwaehnt_und_blockiert_nichts() -> void:
	# Arrange (T078): Eine Sitzung mit anderer.json ist abgestürzt; ihre Kopie liegt im Ordner der
	# Sicherungskopien, in ihrer eigenen Datei.
	var anderer := _editor()
	assert_eq(anderer.open(_kopieren(UEBERNAHME, ORDNER + "anderer.json")), OK)
	anderer.set_event_field("intel_pentium", &"title", "Pentium kommt")
	anderer.write_backup()
	var kopie := FileAccess.get_file_as_string(anderer.backup_path())

	# Act: Die Werkstatt öffnet katalog.json, Klaus ändert etwas, der Timer sichert.
	var werkstatt := await _werkstatt()
	werkstatt.editor.set_event_field("intel_pentium", &"date", 3026)
	_node(werkstatt, "%BackupTimer").timeout.emit()

	# Assert: kein Dialog, keine Meldung; dieser Katalog ist trotzdem gesichert.
	for dialog: Window in _dialoge(werkstatt):
		assert_false(dialog.visible, "%s ist offen; die fremde Kopie wird nicht erwähnt."
			% dialog.name)
	assert_true(werkstatt.editor.backup_matches(), "Die Kopie des anderen blockiert nichts.")
	assert_ne(werkstatt.editor.backup_path(), anderer.backup_path(), "Zwei Kataloge, zwei Dateien.")
	assert_eq(FileAccess.get_file_as_string(anderer.backup_path()), kopie,
		"Die Kopie des anderen bleibt, wie sie war.")

	# Act und Assert: Speichern löscht nur die Kopie dieses Katalogs.
	_node(werkstatt, "%SaveButton").pressed.emit()
	assert_false(werkstatt.editor.has_backup(), "Nach dem Speichern ist die Kopie weg (FR-050).")
	assert_eq(FileAccess.get_file_as_string(anderer.backup_path()), kopie)


func test_start_bietet_nur_die_kopie_dieses_katalogs_an_und_verwerfen_loescht_sie() -> void:
	# Arrange (T078): je eine Kopie von katalog.json und anderer.json
	var frueher := _editor()
	assert_eq(frueher.open(_kopieren(MINIMAL, ORDNER + "katalog.json")), OK)
	frueher.set_event_field("intel_pentium", &"title", "Pentium kommt")
	frueher.write_backup()
	var anderer := _editor()
	assert_eq(anderer.open(_kopieren(UEBERNAHME, ORDNER + "anderer.json")), OK)
	anderer.set_event_field("intel_pentium", &"title", "Pentium kommt bald")
	anderer.write_backup()
	var kopie := FileAccess.get_file_as_string(anderer.backup_path())

	# Act
	var werkstatt := await _werkstatt("")

	# Assert: angeboten wird die eine, die andere kommt nicht vor.
	var dialog: ConfirmationDialog = _node(werkstatt, "%BackupDialog")
	assert_true(dialog.visible)
	assert_string_contains(dialog.dialog_text, "Sicherungskopie dieses Katalogs vom")
	assert_false(dialog.dialog_text.contains("anderer"), "Von der anderen Kopie steht dort nichts.")

	# Act: „Verwerfen“
	_knopf(dialog, "Verwerfen").pressed.emit()

	# Assert
	assert_false(dialog.visible)
	assert_false(FileAccess.file_exists(frueher.backup_path()), "Verwerfen löscht sie (FR-050).")
	assert_eq(FileAccess.get_file_as_string(anderer.backup_path()), kopie,
		"Die Kopie des anderen Katalogs bleibt unberührt.")
	assert_eq(werkstatt.editor.catalog.get_event("intel_pentium").title, "Intel Pentium erscheint")


func test_verwerfen_in_der_toolbar_loescht_die_kopie() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	werkstatt.editor.set_event_field("intel_pentium", &"date", 3026)
	_node(werkstatt, "%BackupTimer").timeout.emit()
	assert_true(werkstatt.editor.backup_matches(), "Der Timer hat gesichert.")

	# Act
	_node(werkstatt, "%RevertButton").pressed.emit()
	_node(werkstatt, "%RevertDialog").get_ok_button().pressed.emit()

	# Assert
	assert_false(werkstatt.editor.has_backup(), "Nach dem Verwerfen ist die Kopie weg (FR-050).")


func test_spaeter_behaelt_die_kopie_auch_ueber_das_schliessen_hinaus() -> void:
	# Arrange (R23): Eine frühere Sitzung hat gesichert und ist dann abgestürzt.
	var frueher := _editor()
	assert_eq(frueher.open(_kopieren(MINIMAL, ORDNER + "katalog.json")), OK)
	frueher.set_event_field("intel_pentium", &"title", "Pentium kommt")
	frueher.write_backup()
	var kopie := FileAccess.get_file_as_string(frueher.backup_path())

	# Act: „Später“ mit dem Knopf, dann das reguläre Schließen ohne Änderung
	var erste := await _werkstatt("")
	var dialog: ConfirmationDialog = _node(erste, "%BackupDialog")
	assert_true(dialog.visible)
	dialog.get_cancel_button().pressed.emit()
	await wait_process_frames(1)
	erste.prepare_quit()

	# Assert
	assert_false(dialog.visible)
	assert_eq(FileAccess.get_file_as_string(frueher.backup_path()), kopie,
		"Nach „Später“ bleibt die Kopie auch beim Schließen liegen.")

	# Act: der nächste Start, diesmal „Später“ mit Esc
	remove_child(erste)
	var zweite := await _werkstatt("")
	dialog = _node(zweite, "%BackupDialog")
	assert_true(dialog.visible, "Beim nächsten Start ist sie wieder da.")
	get_viewport().push_input(_esc())
	await wait_process_frames(1)
	zweite.prepare_quit()

	# Assert
	assert_false(dialog.visible, "Esc schließt den Dialog wie „Später“.")
	assert_eq(FileAccess.get_file_as_string(frueher.backup_path()), kopie)


func test_cmd_q_bei_offenem_dialog_zur_sicherungskopie_gilt_wie_spaeter() -> void:
	# Arrange (T096, T042): Eine frühere Sitzung hat gesichert und ist abgestürzt. Beim Start ist
	# der Dialog offen, und Klaus drückt Cmd+Q, ohne zu antworten.
	var frueher := _editor()
	assert_eq(frueher.open(_kopieren(MINIMAL, ORDNER + "katalog.json")), OK)
	frueher.set_event_field("intel_pentium", &"title", "Pentium kommt")
	frueher.write_backup()
	var kopie := FileAccess.get_file_as_string(frueher.backup_path())
	var erste := await _werkstatt("")
	var beendet := []
	erste.quit_callback = func() -> void: beendet.append(true)
	var dialog: ConfirmationDialog = _node(erste, "%BackupDialog")
	assert_true(dialog.visible)
	assert_false(erste.editor.is_dirty(), "Ohne Änderung fragt das Schließen nicht nach.")

	# Act: Cmd+Q auf dem Weg, den Godot die Anfrage schickt
	var angekommen := _cmd_q(erste)
	await wait_process_frames(1)

	# Assert: Die Anfrage kommt an, der Dialog geht zu wie mit „Später“, und die Werkstatt endet …
	assert_true(angekommen, "Der offene Dialog hält die Schließanfrage nicht auf.")
	assert_false(dialog.visible, "Der Dialog geht zu.")
	assert_eq(beendet.size(), 1, "Die Werkstatt endet.")
	assert_eq(FileAccess.get_file_as_string(frueher.backup_path()), kopie,
		"Die Kopie bleibt liegen, wie nach „Später“ …")

	# … und beim nächsten Start ist sie wieder da.
	remove_child(erste)
	var zweite := await _werkstatt("")
	assert_true(_node(zweite, "%BackupDialog").visible, "… und der nächste Start bietet sie wieder an.")
	assert_string_contains(_node(zweite, "%BackupDialog").dialog_text,
		"Sicherungskopie dieses Katalogs vom")


func test_cmd_q_kommt_bei_jedem_offenen_dialog_an_und_beendet_ohne_aenderungen() -> void:
	# Arrange (T042): Bei offenem Dialog tat Cmd+Q bisher nichts. Jetzt geht der Dialog zu wie mit
	# „Abbrechen“, und ohne Änderungen endet die Werkstatt. Gilt für jeden Dialog der Werkstatt,
	# auch für die von Liste und Simulator; die Rückfrage zum Schließen kommt im nächsten Test.
	var werkstatt := await _werkstatt()
	var beendet := []
	werkstatt.quit_callback = func() -> void: beendet.append(true)
	var close: ConfirmationDialog = _node(werkstatt, "%CloseDialog")
	var dialoge: Array[AcceptDialog] = []
	dialoge.assign(werkstatt.find_children("*", "AcceptDialog", true, false))
	assert_eq(dialoge.size(), 15, "Neun Dialoge der Werkstatt, „Neu …“ und fünf im Simulator.")

	for dialog in dialoge:
		if dialog == close:
			continue
		# Act
		dialog.popup_centered()
		var vorher := beendet.size()
		var angekommen := _cmd_q(werkstatt)
		await wait_process_frames(1)

		# Assert
		assert_false(dialog.exclusive, "%s sperrt die Schließanfrage nicht." % dialog.name)
		assert_true(angekommen, "%s: Cmd+Q kommt an." % dialog.name)
		assert_false(dialog.visible, "%s geht zu." % dialog.name)
		assert_eq(beendet.size(), vorher + 1, "%s: Die Werkstatt endet." % dialog.name)
		assert_false(close.visible, "%s: Ohne Änderungen fragt niemand nach." % dialog.name)


func test_cmd_q_bei_offenem_dialog_neu_fragt_bei_aenderungen_nach() -> void:
	# Arrange (T042; Gegenprobe zu T096): eine ungespeicherte Änderung, dazu der Dialog „Neu …“
	var werkstatt := await _werkstatt()
	var beendet := []
	werkstatt.quit_callback = func() -> void: beendet.append(true)
	werkstatt.editor.set_event_field("intel_pentium", &"title", "Ungespeichert")
	var liste: EventList = _node(werkstatt, "%EventList")
	(liste.get_node("%NewButton") as Button).pressed.emit()
	var neu: ConfirmationDialog = liste.get_node("%NewDialog")
	var close: ConfirmationDialog = _node(werkstatt, "%CloseDialog")
	assert_true(neu.visible)

	# Act
	assert_true(_cmd_q(werkstatt), "Cmd+Q kommt an.")
	await wait_process_frames(1)

	# Assert: „Neu …“ geht zu wie mit „Abbrechen“, dann die Rückfrage wie ohne Dialog
	assert_false(neu.visible, "„Neu …“ geht zu …")
	assert_eq(werkstatt.editor.catalog.events.size(), 5, "… ohne etwas anzulegen.")
	assert_true(close.visible, "Die Rückfrage zum Schließen kommt.")
	assert_eq(beendet.size(), 0, "Beendet wird erst nach der Antwort.")

	# Act und Assert: Cmd+Q noch einmal, während die Rückfrage offen ist
	assert_true(_cmd_q(werkstatt))
	await wait_process_frames(1)
	assert_true(close.visible, "Die Rückfrage bleibt stehen.")
	assert_eq(beendet.size(), 0)

	# Act und Assert: „Verwerfen“ beendet.
	_knopf(close, "Verwerfen").pressed.emit()
	assert_eq(beendet.size(), 1)


func test_offener_dialog_sperrt_die_werkstatt_auch_ohne_exklusiv() -> void:
	# Arrange (T042): Die Dialoge sind nicht mehr exklusiv; die Werkstatt sperrt selbst. Klaus hat
	# etwas geändert und will ein Ereignis löschen; der Dialog ist offen. Geklickt wird echt.
	var werkstatt := await _werkstatt_im_viewport()
	var viewport := werkstatt.get_viewport()
	werkstatt.editor.set_event_field("intel_pentium", &"title", "Ungespeichert")
	await wait_process_frames(1)
	werkstatt._on_delete_requested("zeitungsartikel")
	var dialog: ConfirmationDialog = _node(werkstatt, "%DeleteDialog")
	await wait_process_frames(1)
	assert_true(dialog.visible)
	var speichern: Button = _node(werkstatt, "%SaveButton")
	var liste := _liste(werkstatt)
	var datei_vorher := _datei()

	# Act: neben dem Dialog auf „Speichern“ und auf eine Zeile der Liste klicken, dann Cmd+S
	_klicken(speichern, speichern.get_global_rect().get_center())
	await wait_process_frames(1)
	_klicken(liste, _mitte_der_zeile(liste, liste.get_root().get_child(0)))
	await wait_process_frames(1)
	viewport.push_input(_taste(KEY_S))
	await wait_process_frames(1)

	# Assert: Nichts davon kommt an, und der Dialog hat den Fokus wieder.
	assert_eq(_datei(), datei_vorher, "Weder der Klick noch Cmd+S haben gespeichert.")
	assert_eq(werkstatt.selected_id, "", "Der Klick in die Liste wählt nichts.")
	assert_true(dialog.visible, "Der Dialog bleibt offen …")
	assert_true(dialog.has_focus(), "… und hat den Fokus.")

	# Act und Assert: Esc geht deshalb an den Dialog, wie vorher.
	viewport.push_input(_esc())
	await wait_process_frames(1)
	assert_false(dialog.visible, "Esc schließt den Dialog wie „Abbrechen“.")
	assert_not_null(werkstatt.editor.catalog.get_event("zeitungsartikel"), "Gelöscht ist nichts.")


func test_sicherung_die_nicht_geht_meldet_die_werkstatt_einmal() -> void:
	# Arrange: Wo der Ordner der Sicherungskopien hin soll, liegt eine Datei.
	var werkstatt := await _werkstatt()
	_schreiben(ORDNER + "keinordner", "Hier ist kein Ordner.")
	werkstatt.editor.backup_folder = ORDNER + "keinordner/"
	werkstatt.editor.set_event_field("intel_pentium", &"date", 3026)
	var timer: Timer = _node(werkstatt, "%BackupTimer")
	var hinweis: AcceptDialog = _node(werkstatt, "%NoticeDialog")

	# Act
	timer.timeout.emit()

	# Assert
	assert_true(hinweis.visible)
	assert_eq(hinweis.title, "Sicherung ging nicht")
	assert_string_contains(hinweis.dialog_text, "lässt sich nicht schreiben")
	assert_string_contains(hinweis.dialog_text, "versucht es alle 2 Minuten wieder")

	# Act und Assert: Beim nächsten Mal versucht sie es still wieder.
	hinweis.hide()
	timer.timeout.emit()
	assert_false(hinweis.visible, "Sie sagt es einmal, nicht alle 2 Minuten.")
	werkstatt.editor.backup_folder = ORDNER
	timer.timeout.emit()
	assert_true(werkstatt.editor.backup_matches(), "Geht es wieder, sichert sie.")
	assert_false(hinweis.visible)
	# Nach einer gelungenen Sicherung meldet sie einen neuen Fehler wieder.
	werkstatt.editor.backup_folder = ORDNER + "keinordner/"
	timer.timeout.emit()
	assert_true(hinweis.visible)
	hinweis.hide()


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

	# Assert: FR-032; solange der Hinweis steht, hat die Kennung die rote Kontur (T093).
	var dialog: ConfirmationDialog = liste.get_node("%NewDialog")
	assert_true(dialog.get_ok_button().disabled, "„Anlegen“ ist gesperrt.")
	assert_string_contains(liste.get_node("%NewHint").text, "gibt es schon")
	assert_eq(kennung.theme_type_variation, &"ErrorLineEdit")
	assert_eq(titel.theme_type_variation, &"", "Der Titel hat keinen Fehler.")
	for falsch: String in ["", "Intel Pentium"]:
		kennung.text = falsch
		kennung.text_changed.emit(kennung.text)
		assert_true(liste.get_node("%NewHint").visible, "„%s“ hat einen Hinweis." % falsch)
		assert_eq(kennung.theme_type_variation, &"ErrorLineEdit", "„%s“ hat die Kontur." % falsch)

	# Act und Assert: Mit einer freien Kennung gehen Hinweis und Kontur.
	kennung.text = "noch_ein_pentium"
	kennung.text_changed.emit(kennung.text)
	assert_false(liste.get_node("%NewHint").visible)
	assert_eq(kennung.theme_type_variation, &"")
	assert_false(dialog.get_ok_button().disabled)
	dialog.hide()


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
	# Die Liste baut ihre Zeilen am Ende des Bilds neu (T076).
	await wait_process_frames(1)

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


func test_liste_baut_nur_neu_wenn_sich_an_ihr_etwas_aendert() -> void:
	# Arrange
	var werkstatt := await _werkstatt()
	var liste := _liste(werkstatt)
	var erste := liste.get_root().get_child(0)

	# Act: Ein neues Datum steht nicht in der Liste. Neu gebaut wird am Ende des Bilds (T076).
	werkstatt.editor.set_event_field("intel_pentium", &"date", 3026)
	await wait_process_frames(1)

	# Assert: dieselben Zeilen, nicht neu gebaut (SC-011)
	assert_same(liste.get_root().get_child(0), erste, "Ein neues Datum baut die Zeilen nicht neu.")

	# Act und Assert: Ein neuer Titel steht drin; die Zeilen sind neu gebaut und sortiert, am Ende
	# des Bilds.
	werkstatt.editor.set_event_field("zeitungsartikel", &"title", "Am Anfang")
	assert_same(liste.get_root().get_child(0), erste, "Bis zum Ende des Bilds die alten Zeilen.")
	await wait_process_frames(1)
	assert_eq(_titel(_node(werkstatt, "%EventList"))[0], "Am Anfang")


func test_zeitstrahl_folgt_suche_art_und_kategorie_der_liste() -> void:
	# Arrange: T074, catalog_minimal mit je einem Ereignis jeder Art in vier Kategorien
	var werkstatt := await _werkstatt()
	var liste: EventList = _node(werkstatt, "%EventList")
	var zeitstrahl: TimelineView = _node(werkstatt, "%TimelineView")
	var suche: LineEdit = liste.get_node("%Search")
	var alle_zeilen := zeitstrahl.row_titles()
	var alle_marken := zeitstrahl.marked_events()
	assert_eq(zeitstrahl.filter_text(), "", "Ohne Filter kein Hinweis.")

	# Act und Assert: Suche
	suche.text = "pentium"
	suche.text_changed.emit(suche.text)
	assert_eq(zeitstrahl.marked_events(), PackedStringArray(["intel_pentium"]))
	assert_eq(zeitstrahl.row_titles(), PackedStringArray(["Hardware"]))
	assert_eq(zeitstrahl.filter_text(), "Filter: 1 von 5")
	# Ein neuer Titel passt nicht mehr: weg aus Liste und Zeitstrahl, Rückgängig holt ihn zurück.
	werkstatt.editor.set_event_field("intel_pentium", &"title", "Prozessor erscheint")
	await wait_process_frames(1)
	assert_eq([_titel(liste).size(), zeitstrahl.marked_events().size()], [0, 0])
	werkstatt.editor.undo()
	assert_eq(zeitstrahl.marked_events(), PackedStringArray(["intel_pentium"]))
	suche.text = ""
	suche.text_changed.emit(suche.text)

	# Act und Assert: Art; „nur als Folge“ passt, hat aber keine Marke und keine Zeile.
	_waehlen(liste.get_node("%KindFilter"), "über Wahrscheinlichkeit")
	assert_eq(zeitstrahl.marked_events(), PackedStringArray(["reklamationswelle"]))
	assert_eq(zeitstrahl.row_titles(), PackedStringArray(["Reklamation"]))
	_waehlen(liste.get_node("%KindFilter"), "nur als Folge")
	assert_eq(zeitstrahl.row_titles().size(), 0)
	assert_eq(zeitstrahl.filter_text(), "Filter: 1 von 5", "Gezählt wird wie in der Liste.")
	_waehlen(liste.get_node("%KindFilter"), "Alle Arten")

	# Act und Assert: Kategorie
	_waehlen(liste.get_node("%CategoryFilter"), "Lokal")
	assert_eq(zeitstrahl.marked_events(), PackedStringArray(["neubaugebiet"]))
	assert_eq(zeitstrahl.row_titles(), PackedStringArray(["Lokal"]))

	# Act und Assert: Filter aufheben stellt alles wieder her.
	_waehlen(liste.get_node("%CategoryFilter"), "Alle Kategorien")
	assert_eq(zeitstrahl.row_titles(), alle_zeilen)
	assert_eq(zeitstrahl.marked_events(), alle_marken)
	assert_eq(zeitstrahl.filter_text(), "")


func test_geloeschte_kategorie_im_filter_hebt_den_filter_auf() -> void:
	# Arrange: eine neue, leere Kategorie im Filter; danach zeigt die Liste nichts.
	var werkstatt := await _werkstatt()
	var liste: EventList = _node(werkstatt, "%EventList")
	var zeitstrahl: TimelineView = _node(werkstatt, "%TimelineView")
	werkstatt.editor.add_category("Messen")
	_waehlen(liste.get_node("%CategoryFilter"), "Messen")
	assert_eq(zeitstrahl.filter_text(), "Filter: 0 von 5")

	# Act: Die Kategorie fällt weg; im Filter gilt wieder „Alle Kategorien“.
	assert_eq(werkstatt.editor.delete_category("messen"), OK)

	# Assert: Liste und Zeitstrahl zeigen wieder alles, die Liste ab dem Ende des Bilds.
	assert_false(liste.is_filtered())
	assert_eq(zeitstrahl.filter_text(), "")
	await wait_process_frames(1)
	assert_eq(_titel(liste).size(), 5)


# --- Zebra in Liste und Prüfung (Phase 7) -----------------------------------------------------

func test_liste_im_zebra_mit_auswahl_in_petrol() -> void:
	# Arrange: Neubaugebiet in Zeile 1 bekommt einen Fehler (V07, Fenster endet vor dem Beginn),
	# die Reklamationswelle in Zeile 2 eine Warnung (V13, Grundchance 0).
	var werkstatt := await _werkstatt()
	werkstatt.editor.set_event_field("neubaugebiet", &"window_to", 0)
	werkstatt.editor.set_event_field("reklamationswelle", &"monthly_chance", 0.0)
	await wait_process_frames(1)
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
	# Die Prüfung baut ihre Zeilen am Ende des Bilds neu (T076).
	await wait_process_frames(1)
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


# --- Klicks mit offener Eingabe (T076, T077, T080) -------------------------------------------
#
# Klaus tippt in ein Feld des Formulars und klickt dann woandershin, ohne Enter. Ein Linksklick
# gibt den Fokus weiter, bevor das Ziel den Klick verarbeitet; das Feld übernimmt dabei seine
# Eingabe, und das löst Neubauten aus. Gemeint ist trotzdem, was beim Klick zu sehen war. Diese
# Tests klicken deshalb echt, über push_input in einen eigenen Viewport in Klaus' Größe: Im
# Haupt-Viewport läge GUTs Oberfläche über allem und finge die Klicks ab (wie in
# test_main_menu.gd).


func test_klick_in_die_liste_trifft_die_zeile_unter_der_maus() -> void:
	# Arrange: Klaus tippt einen neuen Titel, der die Zeitungsartikel ganz nach oben sortiert.
	var werkstatt := await _werkstatt_im_viewport()
	var liste := _liste(werkstatt)
	werkstatt.select_event("zeitungsartikel")
	await wait_process_frames(1)
	var titel: LineEdit = _node(werkstatt, "%EventForm").get_input("title")
	_tippen_in(titel, "AAA steht jetzt oben")
	var erste := liste.get_root().get_child(0)
	assert_eq(erste.get_metadata(EventList.Column.MARK), "intel_pentium", "Oben steht der Pentium.")

	# Act: ohne Enter auf die oberste Zeile
	_klicken(liste, _mitte_der_zeile(liste, erste))
	await wait_process_frames(2)

	# Assert: FR-030, Vertrag „Datenfluss“
	assert_eq(werkstatt.selected_id, "intel_pentium", "Gewählt ist die Zeile unter der Maus.")
	assert_eq(werkstatt.editor.catalog.get_event("zeitungsartikel").title, "AAA steht jetzt oben",
		"Die Eingabe ist trotzdem übernommen.")
	assert_eq(_titel(_node(werkstatt, "%EventList"))[0], "AAA steht jetzt oben",
		"Danach ist die Liste neu sortiert …")
	var gewaehlt := liste.get_selected()
	assert_not_null(gewaehlt)
	if gewaehlt != null:
		assert_eq(gewaehlt.get_metadata(EventList.Column.MARK), "intel_pentium",
			"… und die gewählte Zeile ist noch der Pentium.")
	assert_eq(_node(werkstatt, "%EventForm").get_input("title").text, "Intel Pentium erscheint")


func test_klick_in_die_pruefung_trifft_die_meldung_unter_der_maus() -> void:
	# Arrange: zwei Meldungen, V06 am Pentium und V13 an der Reklamationswelle. Klaus tippt beim
	# Neubaugebiet ein Gewicht, das V11 erzeugt; die neue Meldung käme an die zweite Stelle.
	var werkstatt := await _werkstatt_im_viewport(DATUM_AUSSERHALB)
	werkstatt.editor.set_event_field("reklamationswelle", &"monthly_chance", 0.0)
	werkstatt.select_event("neubaugebiet")
	await wait_process_frames(1)
	var pruefung: IssuesPanel = _node(werkstatt, "%IssuesPanel")
	var zweite := pruefung.get_root().get_child(1)
	assert_eq([zweite.get_text(IssuesPanel.Column.EVENT), zweite.get_text(IssuesPanel.Column.FIELD)],
		["reklamationswelle", "monthly_chance"])
	var gewicht: LineEdit = _node(werkstatt, "%EventForm").get_input("count_weights[0]")
	_tippen_in(gewicht, "10")

	# Act: ohne Enter auf die zweite Meldung
	_klicken(pruefung, _mitte_der_zeile(pruefung, zweite))
	await wait_process_frames(2)

	# Assert: FR-033
	var formular: EventForm = _node(werkstatt, "%EventForm")
	assert_eq(werkstatt.selected_id, "reklamationswelle", "Gesprungen wird zur geklickten Meldung.")
	assert_same(werkstatt.get_viewport().gui_get_focus_owner(), formular.get_input("monthly_chance"),
		"Der Fokus steht in ihrem Feld.")
	assert_eq(werkstatt.editor.catalog.get_event("neubaugebiet").count_weights, [10.0, 70.0],
		"Das Gewicht ist trotzdem übernommen.")
	var felder := []
	for zeile in pruefung.get_root().get_children():
		felder.append(zeile.get_text(IssuesPanel.Column.FIELD))
	assert_eq(felder, ["date", "count_weights", "monthly_chance"],
		"Danach zeigt die Prüfung auch die neue Meldung.")


func test_klick_auf_die_zeile_nach_neuer_kennung_waehlt_das_umbenannte_ereignis() -> void:
	# Arrange: Klaus tippt eine neue Kennung und klickt auf die Zeile des Ereignisses. Bis zum
	# Ende des Bilds trägt die Zeile noch die alte Kennung.
	var werkstatt := await _werkstatt_im_viewport()
	var liste := _liste(werkstatt)
	werkstatt.select_event("zeitungsartikel")
	await wait_process_frames(1)
	_tippen_in(_node(werkstatt, "%EventForm").get_input("id"), "artikel")
	var zeile: TreeItem = null
	for kandidat in liste.get_root().get_children():
		if kandidat.get_metadata(EventList.Column.MARK) == "zeitungsartikel":
			zeile = kandidat
	assert_not_null(zeile)
	if zeile == null:
		return

	# Act
	_klicken(liste, _mitte_der_zeile(liste, zeile))
	await wait_process_frames(2)

	# Assert: gewählt ist das Ereignis unter seiner neuen Kennung, nicht keins.
	assert_null(werkstatt.editor.catalog.get_event("zeitungsartikel"))
	assert_eq(werkstatt.selected_id, "artikel")
	var gewaehlt := liste.get_selected()
	assert_true(gewaehlt != null and gewaehlt.get_metadata(EventList.Column.MARK) == "artikel",
		"Nach dem Neubau ist seine Zeile gewählt.")


func test_rechtsklick_nach_neuer_kennung_meint_das_umbenannte_ereignis() -> void:
	# Arrange: Klaus tippt eine neue Kennung für den Pentium und klickt mit rechts auf dessen Marke.
	var werkstatt := await _werkstatt_im_viewport()
	var zeitstrahl: TimelineView = _node(werkstatt, "%TimelineView")
	werkstatt.select_event("intel_pentium")
	await wait_process_frames(1)
	var marke := _mitte_der_marke(zeitstrahl, "intel_pentium")
	_tippen_in(_node(werkstatt, "%EventForm").get_input("id"), "pentium")

	# Act: Rechtsklick, dann „Duplizieren“
	_klicken(zeitstrahl, marke, MOUSE_BUTTON_RIGHT)
	var menue := _menue(zeitstrahl)
	assert_true(menue != null and menue.visible, "Das Menü ist offen.")
	if menue == null:
		return
	menue.id_pressed.emit(TimelineView.MenuItem.DUPLICATE)
	menue.hide()
	await wait_process_frames(1)

	# Assert: Das Menü galt dem Ereignis unter seiner neuen Kennung.
	assert_not_null(werkstatt.editor.catalog.get_event("pentium"))
	assert_not_null(werkstatt.editor.catalog.get_event("pentium_2"), "Kopiert ist das umbenannte.")
	assert_eq(werkstatt.selected_id, "pentium_2")


func test_rechtsklick_im_zeitstrahl_uebernimmt_die_offene_eingabe() -> void:
	# Arrange: Klaus tippt den Titel des Neubaugebiets und klickt mit rechts auf den Pentium.
	var werkstatt := await _werkstatt_im_viewport()
	var zeitstrahl: TimelineView = _node(werkstatt, "%TimelineView")
	werkstatt.select_event("neubaugebiet")
	await wait_process_frames(1)
	_tippen_in(_node(werkstatt, "%EventForm").get_input("title"), "Neue Siedlung")

	# Act
	_klicken(zeitstrahl, _mitte_der_marke(zeitstrahl, "intel_pentium"), MOUSE_BUTTON_RIGHT)
	await wait_process_frames(1)

	# Assert: FR-039, US4/AC4; vorher blieb der alte Titel.
	assert_eq(werkstatt.editor.catalog.get_event("neubaugebiet").title, "Neue Siedlung")
	assert_eq(werkstatt.selected_id, "intel_pentium", "Der Rechtsklick wählt.")
	var menue := _menue(zeitstrahl)
	assert_true(menue != null and menue.visible, "Das Menü ist offen.")
	if menue != null:
		menue.hide()


func test_rechtsklick_und_duplizieren_kopieren_den_neuen_titel() -> void:
	# Arrange: Klaus tippt den Titel des Pentium und klickt mit rechts auf dessen Marke.
	var werkstatt := await _werkstatt_im_viewport()
	var zeitstrahl: TimelineView = _node(werkstatt, "%TimelineView")
	werkstatt.select_event("intel_pentium")
	await wait_process_frames(1)
	_tippen_in(_node(werkstatt, "%EventForm").get_input("title"), "Pentium kommt")
	_klicken(zeitstrahl, _mitte_der_marke(zeitstrahl, "intel_pentium"), MOUSE_BUTTON_RIGHT)
	var menue := _menue(zeitstrahl)
	assert_true(menue != null and menue.visible, "Das Menü ist offen.")
	if menue == null:
		return

	# Act: „Duplizieren“ aus dem Menü
	menue.id_pressed.emit(TimelineView.MenuItem.DUPLICATE)
	menue.hide()
	await wait_process_frames(1)

	# Assert: Original und Kopie tragen den neuen Titel; vorher beide den alten.
	var katalog := werkstatt.editor.catalog
	assert_eq(katalog.get_event("intel_pentium").title, "Pentium kommt")
	assert_not_null(katalog.get_event("intel_pentium_2"))
	if katalog.get_event("intel_pentium_2") != null:
		assert_eq(katalog.get_event("intel_pentium_2").title, "Pentium kommt")
	assert_eq(werkstatt.selected_id, "intel_pentium_2", "Die Kopie ist gewählt.")


func test_auswahl_im_formular_bleibt_nach_offener_eingabe_offen() -> void:
	# Arrange: Klaus tippt einen Titel und klickt dann auf die Auswahl „Kategorie“.
	var werkstatt := await _werkstatt_im_viewport()
	var formular: EventForm = _node(werkstatt, "%EventForm")
	werkstatt.select_event("intel_pentium")
	await wait_process_frames(1)
	_tippen_in(formular.get_input("title"), "Pentium neu")
	var auswahl: OptionButton = formular.get_input("category")

	# Act: Die Liste geht beim Drücken auf; das Loslassen kommt gleich danach.
	_klicken(auswahl, auswahl.get_global_rect().get_center())
	await wait_process_frames(2)

	# Assert: FR-031; vorher war die Liste nach einem Bild zu.
	assert_same(formular.get_input("category"), auswahl, "Die Auswahl ist noch dieselbe …")
	assert_true(auswahl.get_popup().visible, "… und ihre Liste ist offen.")
	assert_eq(werkstatt.editor.catalog.get_event("intel_pentium").title, "Pentium neu",
		"Der Titel ist übernommen.")

	# Act: Klaus wählt „Lokal“; die Liste geht zu.
	var lokal := -1
	for i in auswahl.item_count:
		if auswahl.get_item_text(i) == "Lokal":
			lokal = i
	assert_gt(lokal, -1, "„Lokal“ steht zur Wahl.")
	auswahl.get_popup().index_pressed.emit(lokal)
	auswahl.get_popup().hide()
	await wait_process_frames(2)

	# Assert: Danach baut das Formular neu, mit beidem.
	assert_eq(werkstatt.editor.catalog.get_event("intel_pentium").category, "lokal")
	assert_ne(formular.get_input("category"), auswahl, "Jetzt ist das Formular neu gebaut.")
	assert_eq(formular.get_input("title").text, "Pentium neu")


func test_rechtsklick_in_den_fahrplan_uebernimmt_die_offene_eingabe() -> void:
	# Arrange (T095): Klaus tippt den Titel des Neubaugebiets und klickt mit rechts auf den Pentium
	# in der Tabelle des Simulators. Die Tabelle wählt auch mit rechts, gibt den Fokus aber nur beim
	# Linksklick weiter; der Titel behält ihn also.
	var werkstatt := await _werkstatt_im_viewport()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	werkstatt.select_event("neubaugebiet")
	await wait_process_frames(2)
	var formular: EventForm = _node(werkstatt, "%EventForm")
	_tippen_in(formular.get_input("title"), "Neue Siedlung")
	var tabelle: Tree = simulator.get_node("%PlanTable")
	var zeile := _zeile_mit(tabelle, "Intel Pentium erscheint")
	tabelle.scroll_to_item(zeile)
	await wait_process_frames(1)

	# Act
	_klicken(tabelle, _mitte_der_zeile(tabelle, zeile), MOUSE_BUTTON_RIGHT)
	await wait_process_frames(2)

	# Assert: FR-031, FR-043; vorher blieb der alte Titel.
	assert_eq(werkstatt.editor.catalog.get_event("neubaugebiet").title, "Neue Siedlung",
		"Die offene Eingabe ist übernommen.")
	assert_eq(werkstatt.selected_id, "intel_pentium", "Der Rechtsklick wählt den Termin.")
	assert_eq(formular.get_input("title").text, "Intel Pentium erscheint",
		"Das Formular zeigt den Pentium.")
	var menue: PopupMenu = simulator.get_node("%PlanMenu")
	assert_true(menue.visible, "Das Menü am Termin ist offen.")
	menue.hide()


func test_rechtsklick_in_den_fahrplan_nach_neuer_kennung_waehlt_den_termin() -> void:
	# Arrange (T095): Klaus tippt eine neue Kennung für das Neubaugebiet und klickt mit rechts auf
	# den Pentium im Fahrplan. Das Umbenennen kommt erst, wenn die Werkstatt schon den Pentium
	# wählt.
	var werkstatt := await _werkstatt_im_viewport()
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	werkstatt.select_event("neubaugebiet")
	await wait_process_frames(2)
	var formular: EventForm = _node(werkstatt, "%EventForm")
	_tippen_in(formular.get_input("id"), "siedlung")
	var tabelle: Tree = simulator.get_node("%PlanTable")
	var zeile := _zeile_mit(tabelle, "Intel Pentium erscheint")
	tabelle.scroll_to_item(zeile)
	await wait_process_frames(1)

	# Act
	_klicken(tabelle, _mitte_der_zeile(tabelle, zeile), MOUSE_BUTTON_RIGHT)
	await wait_process_frames(2)

	# Assert: umbenannt, und gewählt bleibt, was der Rechtsklick meinte, überall dasselbe.
	assert_not_null(werkstatt.editor.catalog.get_event("siedlung"), "Die Kennung ist übernommen.")
	assert_null(werkstatt.editor.catalog.get_event("neubaugebiet"))
	assert_eq(werkstatt.selected_id, "intel_pentium")
	assert_eq(formular.get_input("id").text, "intel_pentium", "Das Formular zeigt den Pentium.")
	var gewaehlt := _liste(werkstatt).get_selected()
	assert_true(gewaehlt != null
		and gewaehlt.get_metadata(EventList.Column.MARK) == "intel_pentium",
		"Die Liste hebt den Pentium hervor.")
	simulator.get_node("%PlanMenu").hide()


func test_wahl_im_menue_am_wirkungsziel_uebernimmt_die_offene_eingabe() -> void:
	# Arrange (T095): Klaus tippt den Titel des Pentium und wählt dann im Menü „…“ neben dem Ziel
	# der ersten Wirkung ein anderes Ziel. Der Knopf „…“ nimmt dem Titel den Fokus nicht.
	var werkstatt := await _werkstatt_im_viewport()
	var formular: EventForm = _node(werkstatt, "%EventForm")
	werkstatt.select_event("intel_pentium")
	await wait_process_frames(2)
	var knopf := _menue_am_ziel(formular)
	_tippen_in(formular.get_input("title"), "Pentium neu")
	_klicken(knopf, knopf.get_global_rect().get_center())
	await wait_process_frames(1)
	assert_true(knopf.get_popup().visible, "Das Menü ist offen.")
	assert_same(werkstatt.get_viewport().gui_get_focus_owner(), formular.get_input("title"),
		"Der Titel hat den Fokus noch.")

	# Act: das Ziel „*“ wählen, wie mit der Maus
	_im_menue_waehlen(knopf.get_popup(), "*")
	await wait_process_frames(2)

	# Assert: beides im Katalog; vorher ging der Titel beim Neubau verloren.
	var pentium := werkstatt.editor.catalog.get_event("intel_pentium")
	assert_eq(pentium.effects[0].target, "*", "Das Ziel ist gewählt …")
	assert_eq(pentium.title, "Pentium neu", "… und der Titel übernommen.")
	assert_eq(formular.get_input("title").text, "Pentium neu")


func test_ungueltige_offene_eingabe_behaelt_beim_neubau_ihren_hinweis() -> void:
	# Arrange (T095, FR-031): Klaus tippt ein Datum, das keins ist, und wählt dann im Menü „…“ ein
	# Ziel. Übernehmen lässt sich die Eingabe nicht; nach dem Neubau steht der alte Wert da, mit
	# dem Hinweis darunter, wie wenn Klaus das Feld verlassen hätte.
	var werkstatt := await _werkstatt_im_viewport()
	var formular: EventForm = _node(werkstatt, "%EventForm")
	werkstatt.select_event("intel_pentium")
	await wait_process_frames(2)
	var knopf := _menue_am_ziel(formular)
	_tippen_in(formular.get_input("date"), "abc")
	_klicken(knopf, knopf.get_global_rect().get_center())
	await wait_process_frames(1)

	# Act
	_im_menue_waehlen(knopf.get_popup(), "*")
	await wait_process_frames(2)

	# Assert
	var datum: LineEdit = formular.get_input("date")
	assert_eq(werkstatt.editor.catalog.get_event("intel_pentium").effects[0].target, "*")
	assert_eq(datum.text, "22.03.1993", "Der alte Wert steht wieder da …")
	assert_true(formular.get_hint("date").visible, "… mit dem Hinweis darunter …")
	assert_string_contains(formular.get_hint("date").text, "kein Datum")
	assert_eq(datum.theme_type_variation, &"ErrorLineEdit", "… und der Kontur (T093).")


# --- Fokuslinie und Vorgabe-Teilung (T094, T101) ---------------------------------------------
#
# In Klaus' Größe, 1920 × 925, ohne gespeicherte Teiler.


func test_fokuslinie_im_formular_bleibt_rundum_zu_sehen() -> void:
	# Arrange (T094; Style-Guide, Rolle „Fokus“): eine Linie von 2 Pixeln mit 2 Pixeln Abstand um
	# das Element. Geprüft wird beim Pentium jedes Element im Formular, das den Fokus bekommen kann;
	# das Formular ist länger als der Bereich und hat eine Rollleiste, weit unten liegende rollt der
	# Bereich mit. Beim kurzen Zeitungsartikel ohne Rollleiste genügen die an den Rändern: Titel und
	# Kennung über die volle Breite, die Farbwahl links, das Feld für eine neue Kategorie unten.
	var werkstatt := await _werkstatt_im_viewport()
	var bereich: ScrollContainer = _node(werkstatt, "%FormScroll")
	var formular: EventForm = _node(werkstatt, "%EventForm")
	for id: String in ["intel_pentium", "zeitungsartikel"]:
		werkstatt.select_event(id)
		await wait_process_frames(2)
		assert_eq(bereich.get_v_scroll_bar().visible, id == "intel_pentium", "%s: Rollleiste" % id)
		var elemente := _fokussierbar(bereich)
		if id == "zeitungsartikel":
			elemente.assign([formular.get_input("title"), formular.get_input("id"),
				formular.get_input("categories[0].color"), formular.get_node("%NewCategoryName")])
		assert_gt(elemente.size(), 3, "%s: Felder, Auswahlen und Knöpfe" % id)
		for element in elemente:
			# Act: Liegt die Linie noch nicht ganz im Bereich, rollt er im nächsten Bild mit.
			element.grab_focus()
			if not _sichtbar(bereich).encloses(_fokuslinie(element)):
				await wait_process_frames(2)

			# Assert: ganz im Bereich, nicht unter der Rollleiste
			var linie := _fokuslinie(element)
			assert_true(_sichtbar(bereich).encloses(linie), "%s, %s %s: Fokuslinie %s, sichtbar %s"
				% [id, element.get_class(), element.name, linie, _sichtbar(bereich)])


func test_tab_und_shift_tab_laufen_durch_das_ganze_formular_bis_anlegen() -> void:
	# Arrange (T041; Quickstart 002, 4.1, T094): Klaus geht beim Pentium mit der Tab-Taste vom Titel
	# durch das ganze Formular bis „Anlegen“ der Kategorien und mit Shift+Tab zurück. Die Tasten
	# gehen wie echte über push_input in den Viewport; nur den Anfang im Titel setzt der Test selbst.
	var werkstatt := await _werkstatt_im_viewport()
	var viewport := werkstatt.get_viewport()
	var bereich: ScrollContainer = _node(werkstatt, "%FormScroll")
	var formular: EventForm = _node(werkstatt, "%EventForm")
	werkstatt.select_event("intel_pentium")
	await wait_process_frames(2)
	var titel: Control = formular.get_input("title")
	var beschreibung: TextEdit = formular.get_input("description")
	var anlegen: Button = formular.get_node("%NewCategoryButton")
	var text_vorher := beschreibung.text
	titel.grab_focus()
	await wait_process_frames(2)

	# Act: Tab, bis „Anlegen“ den Fokus hat
	var vorwaerts: Array[Control] = [titel]
	while vorwaerts[-1] != anlegen and vorwaerts.size() < 200:
		await _tab_druecken(viewport)
		var fokus := viewport.gui_get_focus_owner()
		if fokus == null or fokus == vorwaerts[-1] or not bereich.is_ancestor_of(fokus):
			break
		vorwaerts.append(fokus)

		# Assert: Die Fokuslinie liegt nach jedem Schritt ganz im Bereich, der rollt mit.
		assert_true(_sichtbar(bereich).encloses(_fokuslinie(fokus)), "%s %s: Fokuslinie %s, sichtbar %s"
			% [fokus.get_class(), fokus.name, _fokuslinie(fokus), _sichtbar(bereich)])

	# Assert
	assert_has(vorwaerts, beschreibung, "Tab kommt in die Beschreibung …")
	assert_eq(vorwaerts[-1], anlegen, "… und wieder heraus, bis „Anlegen“ der Kategorien.")
	var farbwahl := vorwaerts.filter(func(element: Control) -> bool:
		return element is OptionButton and formular.get_node("%Categories").is_ancestor_of(element))
	assert_gt(farbwahl.size(), 0, "Unterwegs kommt die Farbwahl der Kategorien.")
	assert_gt(bereich.scroll_vertical, 0, "Der Bereich ist mitgerollt.")
	assert_eq(beschreibung.text, text_vorher, "Tab schreibt kein Tabzeichen in die Beschreibung.")
	assert_eq(werkstatt.editor.catalog.get_event("intel_pentium").description, text_vorher)

	# Act: Shift+Tab, bis der Titel den Fokus hat
	var rueckwaerts: Array[Control] = [anlegen]
	while rueckwaerts[-1] != titel and rueckwaerts.size() < 200:
		await _tab_druecken(viewport, true)
		var fokus := viewport.gui_get_focus_owner()
		if fokus == null or fokus == rueckwaerts[-1] or not bereich.is_ancestor_of(fokus):
			break
		rueckwaerts.append(fokus)

	# Assert: derselbe Weg zurück, auch durch die Beschreibung
	rueckwaerts.reverse()
	assert_eq(rueckwaerts, vorwaerts, "Shift+Tab geht denselben Weg zurück bis zum Titel.")
	assert_eq(beschreibung.text, text_vorher, "Shift+Tab rückt in der Beschreibung nichts aus.")
	assert_false(werkstatt.editor.is_dirty(), "Durchs Formular gehen ändert nichts.")


func test_tabellen_haben_in_der_vorgabe_teilung_vorrang() -> void:
	# Arrange (T101; Klaus, 2026-10-21): Ohne gespeicherte Teiler bekommen die Tabellen den Platz,
	# Verteilung und Begründung darunter nur ihre Mindesthöhe. Die Statistik rechnet erst ohne
	# Eingriffe, dann mit zwei Modifikatoren, die jedes Spiel ablehnt; dann steht die Warnung mit
	# drei Zeilen über der Tabelle.
	var werkstatt := await _werkstatt_im_viewport()
	var tabs: TabContainer = _node(werkstatt, "%Tabs")
	var hoehe := tabs.size.y
	var simulator := _simulator(werkstatt)
	_erzeugen(simulator, "4711")
	_druecken(simulator, "%EndButton")
	await wait_process_frames(2)

	# Assert: Fahrplan
	var fahrplan: Tree = simulator.get_node("%PlanTable")
	var begruendung: Control = simulator.get_node("Scroll/Content/Split/PlanSplit/DetailScroll")
	assert_eq(begruendung.size.y, begruendung.get_combined_minimum_size().y,
		"Die Begründung hat nur ihre Mindesthöhe …")
	assert_gte(_ganze_zeilen(fahrplan), 2, "… und der Fahrplan zeigt mindestens 2 ganze Zeilen.")
	assert_eq(tabs.size.y, hoehe, "Der Simulator passt in seinen Reiter, der Zeitstrahl bleibt.")

	# Act: Statistik ohne Eingriffe
	var statistik: StatisticsPanel = _node(werkstatt, "%StatisticsPanel")
	tabs.current_tab = tabs.get_tab_idx_from_control(statistik)
	var anzahl: LineEdit = statistik.get_node("%CountEdit")
	anzahl.text = "3"
	anzahl.text_changed.emit("3")
	await _rechnen(statistik)

	# Assert: Platz für alle fünf Ereignisse, die Verteilung hat ihre Mindesthöhe.
	var tabelle: Tree = statistik.get_node("%ResultTable")
	var verteilung: Control = statistik.get_node("Scroll/Content/Split/YearBox")
	assert_gte(_ganze_zeilen(tabelle), 5, "Ohne Warnung zeigt die Tabelle alle fünf Zeilen.")
	assert_eq(verteilung.size.y, verteilung.get_combined_minimum_size().y,
		"Die Verteilung hat nur ihre Mindesthöhe, …")
	assert_lte(verteilung.size.y, 88.0, "… Titel und 64 Pixel für Werte, Balken und Jahre.")

	# Arrange: abgelehnte Eingriffe im Eingriffsprotokoll des Simulators
	for kennung: String in ["windig", "zweiter"]:
		simulator.probe.interventions.append({"at_day": -1, "kind": "add_modifier", "modifier": {
			"event_id": "reklamationswelle", "from_day": 0, "id": kennung,
			"reason": "Grund %s" % kennung, "to_day": 3000, "value": 0.05}})
	werkstatt.editor.delete_event("reklamationswelle")
	(statistik.get_node("%WithInterventions") as CheckBox).button_pressed = true

	# Act
	await _rechnen(statistik)

	# Assert: Statistik mit Warnung
	assert_true(statistik.get_node("%RefusedNotice").visible, "Die Warnung steht da.")
	assert_eq(verteilung.size.y, verteilung.get_combined_minimum_size().y,
		"Die Verteilung hat weiter nur ihre Mindesthöhe …")
	assert_gte(_ganze_zeilen(tabelle), 2, "… und die Tabelle zeigt mindestens 2 ganze Zeilen.")
	assert_eq(tabs.size.y, hoehe, "Auch mit der Warnung passt die Statistik in ihren Reiter.")


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


func test_wuerfeln_wuerfelt_aus_rng() -> void:
	# Arrange (Feature 008, T036e; AR-08): Ein Würfel mit demselben Seed sagt voraus, was rng
	# würfelt, wie bei Timeline.rng und GameSession.rng.
	var werkstatt := await _werkstatt()
	var simulator := _simulator(werkstatt)
	var feld: LineEdit = simulator.get_node("%SeedEdit")
	simulator.rng = RandomNumberGenerator.new()
	simulator.rng.seed = 20261029
	var vergleich := RandomNumberGenerator.new()
	vergleich.seed = 20261029
	var erwartet := [str(vergleich.randi_range(0, SimulatorPanel.MAX_SEED)),
		str(vergleich.randi_range(0, SimulatorPanel.MAX_SEED))]

	# Act: zweimal „Würfeln“
	var gewuerfelt := []
	for _i in 2:
		_druecken(simulator, "%RollButton")
		gewuerfelt.append(feld.text)

	# Assert
	assert_eq(gewuerfelt, erwartet, "Beide Seeds kommen der Reihe nach aus rng.")
	assert_eq(vergleich.state, simulator.rng.state, "Je Druck genau eine Zahl.")
	assert_false(simulator.get_node("%GenerateButton").disabled, "Mit Seed lässt sich erzeugen.")


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


# --- Schwierigkeitsgrade (Feature 003, T017) --------------------------------------------------

func test_vierter_reiter_schwierigkeitsgrade() -> void:
	# Arrange und Act
	var werkstatt := await _werkstatt(GRADE)

	# Assert: Die drei bisherigen Reiter behalten ihren Platz.
	var tabs: TabContainer = _node(werkstatt, "%Tabs")
	var titel := []
	for i in tabs.get_tab_count():
		titel.append(tabs.get_tab_title(i))
	assert_eq(titel, ["Prüfung", "Simulator", "Statistik", "Schwierigkeitsgrade"])
	var panel: DifficultyPanel = _node(werkstatt, "%DifficultyPanel")
	assert_eq(tabs.get_tab_idx_from_control(panel), 3)
	assert_same(panel.editor, werkstatt.editor)
	assert_eq(_zeilen(panel.get_node("%Table")).size(), 1, "Leicht steht schon da.")

	# Act und Assert: Die Auswahl der Werkstatt kommt im Panel an, eine Änderung auch.
	werkstatt.select_event("lieferengpass")
	assert_eq(panel.selected_event_id, "lieferengpass")
	werkstatt.editor.add_start_modifier(Difficulty.Level.LEICHT, "lieferengpass")
	await wait_process_frames(1)
	assert_eq(_zeilen(panel.get_node("%Table")).size(), 2)
	assert_eq(panel.get_node("%CountLabel").text, "2 Start-Modifikatoren")


func test_meldung_zu_einem_profil_fuehrt_in_den_reiter_und_ins_feld() -> void:
	# Arrange: Leicht hat einen Start-Modifikator ohne Grund (V29); gewählt ist ein Ereignis.
	var werkstatt := await _werkstatt(GRUND_LEER)
	werkstatt.select_event("intel_pentium")
	var pruefung: IssuesPanel = _node(werkstatt, "%IssuesPanel")
	await wait_process_frames(1)
	var zeile := pruefung.get_root().get_child(0)
	assert_eq([zeile.get_text(IssuesPanel.Column.EVENT), zeile.get_text(IssuesPanel.Column.FIELD)],
		["Profil Leicht", "profiles.leicht[0].reason"])

	# Act: die Zeile wählen und aktivieren, wie mit Enter oder einem Doppelklick
	zeile.select(0)
	pruefung.item_activated.emit()

	# Assert: FR-016
	var tabs: TabContainer = _node(werkstatt, "%Tabs")
	var panel: DifficultyPanel = _node(werkstatt, "%DifficultyPanel")
	assert_eq(tabs.current_tab, tabs.get_tab_idx_from_control(panel), "Der Reiter ist vorn.")
	assert_eq(panel.shown_difficulty(), Difficulty.Level.LEICHT)
	assert_same(get_viewport().gui_get_focus_owner(), panel.get_node("%ReasonEdit"),
		"Der Fokus steht im Grund.")
	assert_eq((panel.get_node("%ReasonEdit") as LineEdit).theme_type_variation, &"ErrorLineEdit")
	assert_eq(werkstatt.selected_id, "intel_pentium", "Die Auswahl des Ereignisses bleibt.")

	# Act und Assert: Eine Meldung zu einem Ereignis geht weiter ans Formular.
	pruefung.issue_activated.emit("intel_pentium", "title")
	assert_same(get_viewport().gui_get_focus_owner(),
		(_node(werkstatt, "%EventForm") as EventForm).get_input("title"))


func test_pruefung_nennt_den_grad_in_der_spalte_ereignis() -> void:
	# Arrange: Schwer hat einen Start-Modifikator auf das Weihnachtsgeschäft (V26).
	var werkstatt := await _werkstatt(JAEHRLICH)
	var pruefung: IssuesPanel = _node(werkstatt, "%IssuesPanel")
	await wait_process_frames(1)

	# Assert: FR-016, CHK009
	var zeile := pruefung.get_root().get_child(0)
	assert_eq([zeile.get_text(IssuesPanel.Column.EVENT), zeile.get_text(IssuesPanel.Column.FIELD)],
		["Profil Schwer", "profiles.schwer[0].event_id"])

	# Act: nach dem zweiten Pfadteil des Felds (Analyse, U4)
	var felder := ["profiles.leicht[2].reason", "profiles.schwer", "profiles", "profiles.mittel",
		"profiles.extrem", "profiles.schwerr[0].reason", "categories[0].color"]
	var meldungen: Array[CatalogIssue] = []
	for feld: String in felder:
		meldungen.append(CatalogIssue.new(CatalogIssue.Severity.ERROR, "V22", "", feld, "Text"))
	meldungen.append(CatalogIssue.new(CatalogIssue.Severity.ERROR, "V06", "intel_pentium", "date",
		"Text"))
	pruefung.show_issues(meldungen)
	await wait_process_frames(1)

	# Assert
	var spalte := []
	for eintrag in pruefung.get_root().get_children():
		spalte.append(eintrag.get_text(IssuesPanel.Column.EVENT))
	assert_eq(spalte, ["Profil Leicht", "Profil Schwer", "Profile", "Profile", "Profile",
		"Profile", "–", "intel_pentium"])


func test_loeschdialog_nennt_ereignisse_und_start_modifikatoren() -> void:
	# Arrange: FR-017. Kundenflucht hat die Reklamationswelle als Bedingung, beide Profile zeigen
	# darauf.
	var werkstatt := await _werkstatt(GRADE)
	var vorher := werkstatt.editor.catalog.to_json()

	# Act
	werkstatt._on_delete_requested("reklamationswelle")

	# Assert
	var dialog: ConfirmationDialog = _node(werkstatt, "%DeleteDialog")
	assert_true(dialog.visible)
	assert_eq(dialog.dialog_text, "„Reklamationswelle“ löschen?\n\nDarauf verweisen: "
		+ "„Kundenflucht“. In den Profilen: Leicht: Nachsichtige Kunden, Schwer: Anspruchsvolle "
		+ "Kunden. Diese Verweise werden mit entfernt.\n\nRückgängig holt alles zurück.")

	# Act und Assert: Löschen entfernt die Start-Modifikatoren mit, Cmd+Z holt alles zurück.
	dialog.get_ok_button().pressed.emit()
	assert_eq(werkstatt.editor.catalog.get_profile(Difficulty.Level.LEICHT).modifiers.size(), 0)
	assert_eq(werkstatt.editor.catalog.get_profile(Difficulty.Level.SCHWER).modifiers.size(), 0)
	await wait_process_frames(1)
	assert_eq(_zeilen(_node(werkstatt, "%DifficultyPanel").get_node("%Table")).size(), 0)
	werkstatt.editor.undo()
	assert_eq(werkstatt.editor.catalog.to_json(), vorher)


func test_loeschdialog_nur_mit_start_modifikatoren() -> void:
	# Arrange: Auf den Lieferengpass verweist kein Ereignis, nur ein Start-Modifikator (Analyse, I3).
	var werkstatt := await _werkstatt(GRADE)
	werkstatt.editor.add_start_modifier(Difficulty.Level.SCHWER, "lieferengpass")
	werkstatt.editor.set_start_modifier_field(Difficulty.Level.SCHWER, 1, &"reason",
		"Engpass bei Speicher")

	# Act
	werkstatt._on_delete_requested("lieferengpass")

	# Assert
	var dialog: ConfirmationDialog = _node(werkstatt, "%DeleteDialog")
	assert_eq(dialog.dialog_text, "„Lieferengpass“ löschen?\n\nIn den Profilen verweisen darauf: "
		+ "Schwer: Engpass bei Speicher. Diese Verweise werden mit entfernt.\n\nRückgängig holt "
		+ "alles zurück.")
	dialog.hide()

	# Act und Assert: ohne jeden Verweis wie bisher
	werkstatt._on_delete_requested("windows_95")
	assert_eq(dialog.dialog_text, "„Windows 95 erscheint“ löschen?\n\nRückgängig holt alles "
		+ "zurück.")
	dialog.hide()


func test_loeschdialog_bei_doppelter_kennung_sagt_dass_die_verweise_bleiben() -> void:
	# Arrange: T037. Vor der Reklamationswelle steht von Hand ein zweites Ereignis mit ihrer Kennung
	# (V02). Es steht in der Liste vorn und wird gelöscht; die Verweise gelten dann der echten.
	var zweites := ("{\"category\": \"reklamation\", \"date\": \"1994-03-07\", \"description\": "
		+ "\"\", \"duration_days\": 0, \"effects\": [], \"follow_ups\": [], \"id\": "
		+ "\"reklamationswelle\", \"kind\": \"fixed\", \"title\": \"Zweite Reklamationswelle\"},")
	_schreiben(ORDNER + "katalog.json", FileAccess.get_file_as_string(GRADE).replace(
		"\"events\": [", "\"events\": [\n\t\t" + zweites))
	var werkstatt := await _werkstatt("")
	assert_not_null(_erste_meldung(werkstatt, "V02"), "Die Kennung gibt es zweimal.")
	var vorher := werkstatt.editor.catalog.to_json()

	# Act
	werkstatt._on_delete_requested("reklamationswelle")

	# Assert
	var dialog: ConfirmationDialog = _node(werkstatt, "%DeleteDialog")
	assert_eq(dialog.dialog_text, "„Zweite Reklamationswelle“ löschen?\n\nDarauf verweisen: "
		+ "„Kundenflucht“. In den Profilen: Leicht: Nachsichtige Kunden, Schwer: Anspruchsvolle "
		+ "Kunden. Diese Verweise bleiben stehen, denn die Kennung „reklamationswelle“ gehört noch "
		+ "zu einem zweiten Ereignis.\n\nRückgängig holt alles zurück.")

	# Act und Assert: Der Dialog sagt, was delete_event() tut.
	dialog.get_ok_button().pressed.emit()
	var katalog := werkstatt.editor.catalog
	assert_eq(katalog.get_event("reklamationswelle").title, "Reklamationswelle",
		"Gelöscht ist das vordere der beiden.")
	assert_eq(katalog.get_event("kundenflucht").conditions.size(), 1, "Die Bedingung bleibt.")
	assert_eq(katalog.get_profile(Difficulty.Level.LEICHT).modifiers.size(), 1)
	assert_eq(katalog.get_profile(Difficulty.Level.SCHWER).modifiers.size(), 1)
	werkstatt.editor.undo()
	assert_eq(werkstatt.editor.catalog.to_json(), vorher)


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
	werkstatt.editor.backup_folder = ORDNER
	werkstatt.settings_path = ORDNER + "einstellungen.cfg"
	add_child_autofree(werkstatt)
	# _start() kommt per call_deferred() am Ende des ersten Bilds.
	await wait_process_frames(2)
	return werkstatt


## Wie _werkstatt(), aber in einem eigenen Viewport von 1920 × 925 Pixeln, der Größe von Klaus'
## Werkstatt; dort lässt sich echt klicken (siehe „Klicks mit offener Eingabe“). Dialoge und Listen
## liegen im selben Viewport.
func _werkstatt_im_viewport(fixture: String = MINIMAL) -> Werkstatt:
	var ziel := _kopieren(fixture, ORDNER + "katalog.json")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 925)
	viewport.gui_embed_subwindows = true
	add_child_autofree(viewport)
	var werkstatt: Werkstatt = SZENE.instantiate()
	werkstatt.catalog_path = ziel
	werkstatt.editor.backup_folder = ORDNER
	werkstatt.settings_path = ORDNER + "einstellungen.cfg"
	viewport.add_child(werkstatt)
	# _start() kommt per call_deferred() am Ende des ersten Bilds; danach ist alles angeordnet.
	await wait_process_frames(3)
	return werkstatt


## Ein Klick wie mit der Maus bei [param ziel], in Koordinaten des Viewports von [param control]:
## hinfahren, drücken, loslassen. Godot gibt dabei selbst den Fokus weiter, beim Linksklick.
func _klicken(control: Control, ziel: Vector2, taste: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var viewport := control.get_viewport()
	var fahren := InputEventMouseMotion.new()
	fahren.position = ziel
	fahren.global_position = ziel
	viewport.push_input(fahren, true)
	for gedrueckt: bool in [true, false]:
		var knopf := InputEventMouseButton.new()
		knopf.button_index = taste
		knopf.button_mask = (1 << (taste - 1)) if gedrueckt else 0
		knopf.pressed = gedrueckt
		knopf.position = ziel
		knopf.global_position = ziel
		viewport.push_input(knopf, true)


## Fokus in [param feld], alles markiert, dann [param text] Zeichen für Zeichen, wie getippt; Enter
## kommt nicht.
func _tippen_in(feld: LineEdit, text: String) -> void:
	feld.grab_focus()
	feld.select_all()
	for zeichen in text:
		var taste := InputEventKey.new()
		taste.unicode = zeichen.unicode_at(0)
		taste.pressed = true
		feld.get_viewport().push_input(taste)
	assert_eq(feld.text, text, "Getippt, noch nicht übernommen.")


## Die Mitte der Zeile [param zeile] in Koordinaten des Viewports.
func _mitte_der_zeile(tabelle: Tree, zeile: TreeItem) -> Vector2:
	return tabelle.get_global_transform_with_canvas() * tabelle.get_item_area_rect(zeile).get_center()


## „Starten“ in der Statistik, dann warten, bis sie fertig ist.
func _rechnen(statistik: StatisticsPanel) -> void:
	statistik.start()
	while statistik.is_running():
		await wait_process_frames(1)
	await wait_process_frames(2)


## Alles unter [param bereich], das den Fokus bekommen kann und zu sehen ist.
func _fokussierbar(bereich: Control) -> Array[Control]:
	var elemente: Array[Control] = []
	for kind in bereich.find_children("*", "Control", true, false):
		var element := kind as Control
		if element.focus_mode in [Control.FOCUS_ALL, Control.FOCUS_CLICK] \
				and element.is_visible_in_tree():
			elemente.append(element)
	return elemente


## Was von [param bereich] zu sehen ist, ohne seine Rollleiste.
func _sichtbar(bereich: ScrollContainer) -> Rect2:
	var sichtbar := bereich.get_global_rect()
	var leiste := bereich.get_v_scroll_bar()
	if leiste.visible:
		sichtbar.end = Vector2(leiste.get_global_rect().position.x, sichtbar.end.y)
	return sichtbar


## Wo die Fokuslinie um [param element] liegt: sein Rechteck, vergrößert um die Ränder, die sein
## Stil „focus“ nach außen zeichnet.
func _fokuslinie(element: Control) -> Rect2:
	var fokus: StyleBoxFlat = element.get_theme_stylebox(&"focus")
	return element.get_global_rect().grow_individual(fokus.expand_margin_left,
		fokus.expand_margin_top, fokus.expand_margin_right, fokus.expand_margin_bottom)


## Wie viele ganze Zeilen in [param tabelle] Platz haben: zwischen den Spaltenköpfen und dem unteren
## Rand, egal wie weit sie gerade gerollt ist.
func _ganze_zeilen(tabelle: Tree) -> int:
	var wurzel := tabelle.get_root()
	if wurzel == null or wurzel.get_child_count() == 0:
		return 0
	var erste := tabelle.get_item_area_rect(wurzel.get_first_child())
	var oben := erste.position.y + tabelle.get_scroll().y
	var unten := tabelle.size.y - tabelle.get_theme_stylebox(&"panel").get_margin(SIDE_BOTTOM)
	return floori((unten - oben) / erste.size.y)


## Der Knopf „…“ neben dem Ziel der ersten Wirkung im Formular.
func _menue_am_ziel(formular: EventForm) -> MenuButton:
	var ziel: LineEdit = formular.get_input("effects[0].target")
	for nachbar in ziel.get_parent().get_children():
		if nachbar is MenuButton:
			return nachbar
	fail_test("Neben dem Ziel steht kein Knopf „…“.")
	return MenuButton.new()


## Wählt in [param menue] den Eintrag [param text], wie mit der Maus; das Menü geht dabei zu.
func _im_menue_waehlen(menue: PopupMenu, text: String) -> void:
	for i in menue.item_count:
		if menue.get_item_text(i) == text:
			menue.index_pressed.emit(i)
			menue.hide()
			return
	fail_test("„%s“ steht nicht im Menü." % text)


## Die erste Zeile von [param tabelle], deren Spalte „Ereignis“ [param titel] zeigt.
func _zeile_mit(tabelle: Tree, titel: String) -> TreeItem:
	for zeile in tabelle.get_root().get_children():
		if zeile.get_text(SimulatorPanel.PlanColumn.EVENT) == titel:
			return zeile
	fail_test("Keine Zeile mit „%s“." % titel)
	return null


## Die Mitte der ersten Marke von [param id] in Koordinaten des Viewports.
func _mitte_der_marke(zeitstrahl: TimelineView, id: String) -> Vector2:
	var marken := zeitstrahl.mark_rects(id)
	assert_gt(marken.size(), 0, "%s hat eine Marke." % id)
	if marken.is_empty():
		return Vector2.ZERO
	return zeitstrahl.get_global_transform_with_canvas() * marken[0].get_center()


## Das Menü des Zeitstrahls; es hängt als internes Kind daran.
func _menue(zeitstrahl: TimelineView) -> PopupMenu:
	for kind in zeitstrahl.get_children(true):
		if kind is PopupMenu:
			return kind
	return null


func _editor() -> CatalogEditor:
	var editor := CatalogEditor.new()
	editor.backup_folder = ORDNER
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


## Der Knopf mit dem Text [param text] in einem Dialog, auch einer, den add_button() dazugetan hat.
func _knopf(dialog: AcceptDialog, text: String) -> Button:
	for kind in dialog.get_ok_button().get_parent().get_children():
		if kind is Button and kind.text == text:
			return kind
	fail_test("Der Dialog %s hat keinen Knopf „%s“." % [dialog.name, text])
	return Button.new()


## Esc, gedrückt, wie von der Tastatur; Godot macht daraus ui_cancel.
func _esc() -> InputEventKey:
	var ereignis := InputEventKey.new()
	ereignis.keycode = KEY_ESCAPE
	ereignis.physical_keycode = KEY_ESCAPE
	ereignis.pressed = true
	return ereignis


## Cmd+Q oder der Fensterknopf, so nah am Weg, den Godot die Anfrage schickt: macOS meldet
## „Beenden“ an applicationShouldTerminate, und Godot gibt das als WINDOW_EVENT_CLOSE_REQUEST an das
## Hauptfenster (Window::_event_callback). Hat das Fenster ein exklusives Kind, also einen offenen
## Dialog mit exclusive und transient, verwirft Godot die Anfrage, und niemand erfährt davon. Sonst
## geht NOTIFICATION_WM_CLOSE_REQUEST an alle Knoten des Fensters, aber nicht in Kind-Fenster wie
## Dialoge hinein (Window::_propagate_window_notification). Hier nur an die Werkstatt und ihre
## Knoten; der Rest des Fensters gehört GUT. Gibt zurück, ob die Anfrage ankam. Im echten Fenster
## prüft das Quickstart 002, 4.1, mit Cmd+Q selbst.
func _cmd_q(werkstatt: Werkstatt) -> bool:
	for fenster: Window in werkstatt.find_children("*", "Window", true, false):
		if fenster.visible and fenster.exclusive and fenster.transient:
			return false
	_an_alle_knoten_des_fensters(werkstatt, NOTIFICATION_WM_CLOSE_REQUEST)
	return true


func _an_alle_knoten_des_fensters(knoten: Node, nachricht: int) -> void:
	knoten.notification(nachricht)
	for kind in knoten.get_children(true):
		if not kind is Window:
			_an_alle_knoten_des_fensters(kind, nachricht)


## Drückt Tab, mit [param shift] Shift+Tab, und lässt die Taste los, wie von der Tastatur, in
## [param viewport]. Godot macht daraus ui_focus_next bzw. ui_focus_prev. Danach zwei Bilder: Im
## ersten rollt die Werkstatt das Formular zum neuen Fokus.
func _tab_druecken(viewport: Viewport, shift: bool = false) -> void:
	for gedrueckt: bool in [true, false]:
		var ereignis := InputEventKey.new()
		ereignis.keycode = KEY_TAB
		ereignis.physical_keycode = KEY_TAB
		ereignis.shift_pressed = shift
		ereignis.pressed = gedrueckt
		viewport.push_input(ereignis)
	await wait_process_frames(2)


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
