extends GutTest

## Prüft den Reiter „Schwierigkeitsgrade“ (Feature 003, T016; contracts/werkstatt.md,
## „DifficultyPanel“): die Profile einer Fixture in der Tabelle, die Notiz bei Mittel, das Panel
## ohne Editor, Cmd+Z im frisch gesetzten Feld, „Neu“, „Duplizieren“ und „Löschen“, Felder mit
## Enter und beim Verlassen, ungültige Eingaben, Zeichen, Kontur und Hinweise der Prüfung,
## focus_field() und US2, Szenarien 1 bis 3.
##
## Das Panel steht hier ohne die Werkstatt im Baum, mit einem eigenen CatalogEditor auf einer
## Kopie einer Fixture. Was die Werkstatt verdrahtet, verdrahtet der Test selbst: catalog_changed
## und issues_changed rufen refresh(). Ob alles in den Reiter passt, prüft der Test der Werkstatt.

const PANEL := preload("res://tools/werkstatt/difficulty_panel.tscn")
const ORDNER := "user://test_difficulty_panel/"
const MINIMAL := "res://test/fixtures/catalog_minimal.json"
## Leicht −2 und Schwer +5 auf die Reklamationswelle, je das ganze Spiel.
const GRADE := "res://test/fixtures/catalog_us1_grade.json"
## Schwer: ein Start-Modifikator auf das jährliche Weihnachtsgeschäft (V26).
const JAEHRLICH := "res://test/fixtures/catalog_v26_profil_ereignis_jaehrlich.json"
## Leicht: ein Start-Modifikator ohne Grund (V29).
const GRUND_LEER := "res://test/fixtures/catalog_v29_profil_grund_leer.json"
## Schwer: vom 15.03.1990 bis 15.06.1994, zweimal mitten im Monat (V31).
const MONATSMITTE := "res://test/fixtures/catalog_v31_profil_monatsmitte.json"
## Schwer: ein Start-Modifikator auf ein Ereignis, das es nicht gibt (V25).
const UNBEKANNT := "res://test/fixtures/catalog_v25_profil_ereignis_unbekannt.json"
## 01.01.1985 = 0; der 31.12.1999 ist Tag 5477.
const LETZTER_TAG := 5477

var _editor: CatalogEditor
var _panel: DifficultyPanel


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)


func after_each() -> void:
	_panel = null
	_editor = null
	var ordner := DirAccess.open(ORDNER)
	if ordner != null:
		for datei in ordner.get_files():
			ordner.remove(datei)
	DirAccess.remove_absolute(ORDNER)


# --- Aufbau -----------------------------------------------------------------------------------

func test_profile_einer_fixture_stehen_in_der_tabelle() -> void:
	# Arrange und Act
	await _oeffnen(GRADE)

	# Assert: Vorgabe Leicht, eine Zeile mit allen Spalten
	assert_eq(_panel.shown_difficulty(), Difficulty.Level.LEICHT, "Vorgabe ist Leicht.")
	assert_eq(_zeilen(), [["", "Reklamationswelle", "-2", "01.01.1985", "31.12.1999",
		"Nachsichtige Kunden", "reklamationswelle"]])
	assert_eq(_node("%CountLabel").text, "1 Start-Modifikator")

	# Act und Assert: Schwer, mit Vorzeichen
	_panel.show_difficulty(Difficulty.Level.SCHWER)
	assert_eq(_zeilen(), [["", "Reklamationswelle", "+5", "01.01.1985", "31.12.1999",
		"Anspruchsvolle Kunden", "reklamationswelle"]])
	assert_eq((_node("%DifficultyOption") as OptionButton).selected, Difficulty.Level.SCHWER)


func test_ohne_auswahl_sind_felder_und_knoepfe_gesperrt() -> void:
	# Arrange und Act
	await _oeffnen(GRADE)

	# Assert
	for feld: String in ["%ValueEdit", "%FromEdit", "%ToEdit", "%ReasonEdit", "%IdEdit"]:
		var eingabe: LineEdit = _node(feld)
		assert_false(eingabe.editable, "%s ist ohne Zeile gesperrt." % feld)
		assert_eq(eingabe.text, "", "%s ist leer." % feld)
	assert_true((_node("%EventOption") as OptionButton).disabled)
	assert_true((_node("%DuplicateButton") as Button).disabled)
	assert_true((_node("%DeleteButton") as Button).disabled)
	assert_false((_node("%NewButton") as Button).disabled)

	# Act und Assert: Eine Zeile füllt die Felder.
	_panel.select_row(0)
	assert_true((_node("%ValueEdit") as LineEdit).editable)
	assert_eq(_text("%ValueEdit"), "-2", "Der Wert mit dem einfachen Minus, wie in der Tabelle.")
	assert_eq(_text("%FromEdit"), "01.01.1985")
	assert_eq(_text("%ToEdit"), "31.12.1999")
	assert_eq(_text("%ReasonEdit"), "Nachsichtige Kunden")
	assert_eq(_text("%IdEdit"), "reklamationswelle")
	var auswahl: OptionButton = _node("%EventOption")
	assert_eq(auswahl.get_item_text(auswahl.selected), "Reklamationswelle")
	assert_false(auswahl.fit_to_longest_item, "Die Auswahl richtet sich nicht nach dem längsten.")
	assert_true(auswahl.clip_text, "Lange Titel werden gekürzt.")
	assert_false((_node("%DuplicateButton") as Button).disabled)
	assert_false((_node("%DeleteButton") as Button).disabled)


func test_mittel_zeigt_nur_die_notiz() -> void:
	# Arrange
	await _oeffnen(GRADE)

	# Act
	_panel.show_difficulty(Difficulty.Level.MITTEL)

	# Assert: FR-015
	var notiz: Label = _node("%MittelNote")
	assert_true(notiz.visible)
	assert_eq(notiz.text, "Mittel ist der Katalog ohne Start-Modifikatoren. Seine Chancen sind "
		+ "die Grundchancen der Ereignisse.")
	assert_eq(notiz.theme_type_variation, &"MutedLabel")
	assert_ne(notiz.autowrap_mode, TextServer.AUTOWRAP_OFF, "Die Notiz bricht um.")
	assert_false((_node("%Split") as Control).visible, "Tabelle, Knöpfe und Felder sind weg.")
	assert_false((_node("%CountLabel") as Control).visible)

	# Act und Assert: zurück zu Leicht
	_panel.show_difficulty(Difficulty.Level.LEICHT)
	assert_false(notiz.visible)
	assert_true((_node("%Split") as Control).visible)


func test_ohne_editor_kein_fehler() -> void:
	# Arrange: Die Werkstatt setzt editor erst in ihrem _ready(), nach dem des Panels.
	_panel = PANEL.instantiate()
	add_child_autofree(_panel)
	await wait_process_frames(1)

	# Act
	_panel.refresh()
	_panel.show_difficulty(Difficulty.Level.SCHWER)
	_panel.select_row(0)
	_panel.focus_field("profiles.schwer[0].reason")
	(_node("%NewButton") as Button).pressed.emit()
	await wait_process_frames(1)

	# Assert
	assert_engine_error_count(0, "Ohne Editor tut das Panel nichts.")
	assert_eq(_zeilen(), [])


func test_neu_ohne_ereignis_ueber_wahrscheinlichkeit_ist_gesperrt() -> void:
	# Arrange: ein neuer Katalog hat Kategorien und zwei leere Profile, aber keine Ereignisse.
	_editor = _neuer_editor()
	_editor.new_catalog()
	await _panel_mit(_editor)

	# Assert
	var neu: Button = _node("%NewButton")
	assert_true(neu.disabled)
	assert_eq(neu.tooltip_text, "Der Katalog hat kein Ereignis über Wahrscheinlichkeit.")
	assert_eq(_node("%CountLabel").text, "keine Start-Modifikatoren")


# --- Neu, Duplizieren, Löschen ----------------------------------------------------------------

func test_neu_nimmt_das_gewaehlte_ereignis_ueber_wahrscheinlichkeit() -> void:
	# Arrange: zwei Ereignisse über Wahrscheinlichkeit; gewählt ist das zweite nach Kennung.
	await _oeffnen(GRADE)
	_panel.selected_event_id = "lieferengpass"

	# Act
	(_node("%NewButton") as Button).pressed.emit()

	# Assert: Vorgaben aus data-model.md, die neue Zeile gewählt, der Fokus im Wert
	var neu := _editor.catalog.get_profile(Difficulty.Level.LEICHT).modifiers[1]
	assert_eq([neu.event_id, neu.id, neu.value, neu.reason, neu.from_day, neu.to_day],
		["lieferengpass", "lieferengpass", 0.0, "", 0, LETZTER_TAG])
	assert_eq(_zeilen().size(), 2, "Die neue Zeile steht sofort da.")
	assert_eq(_gewaehlt(), 1)
	assert_same(get_viewport().gui_get_focus_owner(), _node("%ValueEdit"))
	assert_eq(_text("%ValueEdit"), "+0")
	assert_eq(_editor.undo_name(), "Neuer Start-Modifikator in Leicht")


func test_neu_ohne_passendes_ereignis_nimmt_das_erste_nach_kennung() -> void:
	# Arrange: Gewählt ist das jährliche Weihnachtsgeschäft; die Kennung „reklamationswelle“ gibt
	# es in Leicht schon.
	await _oeffnen(GRADE)
	_panel.selected_event_id = "weihnachtsgeschaeft"

	# Act
	(_node("%NewButton") as Button).pressed.emit()
	(_node("%NewButton") as Button).pressed.emit()

	# Assert: kundenflucht ist das erste nach Kennung.
	var profil := _editor.catalog.get_profile(Difficulty.Level.LEICHT)
	assert_eq(profil.modifiers.size(), 3)
	assert_eq([profil.modifiers[1].event_id, profil.modifiers[1].id], ["kundenflucht",
		"kundenflucht"])
	assert_eq(profil.modifiers[2].id, "kundenflucht_2", "Im Profil eindeutig gemacht.")
	assert_eq(_gewaehlt(), 2)


func test_duplizieren_und_loeschen() -> void:
	# Arrange
	await _oeffnen(GRADE)
	_panel.show_difficulty(Difficulty.Level.SCHWER)
	_panel.select_row(0)

	# Act: Duplizieren legt die Kopie direkt dahinter und wählt sie.
	(_node("%DuplicateButton") as Button).pressed.emit()

	# Assert
	var profil := _editor.catalog.get_profile(Difficulty.Level.SCHWER)
	assert_eq(profil.modifiers.size(), 2)
	assert_eq(profil.modifiers[1].id, "reklamationswelle_2")
	assert_eq(profil.modifiers[1].reason, "Anspruchsvolle Kunden")
	assert_eq(_gewaehlt(), 1)
	assert_eq(_text("%IdEdit"), "reklamationswelle_2")

	# Act: Löschen fragt nicht nach.
	(_node("%DeleteButton") as Button).pressed.emit()

	# Assert: R11
	profil = _editor.catalog.get_profile(Difficulty.Level.SCHWER)
	assert_eq(profil.modifiers.size(), 1)
	assert_eq(profil.modifiers[0].id, "reklamationswelle", "Das Original bleibt.")
	assert_eq(_zeilen().size(), 1)
	assert_eq(_gewaehlt(), -1, "Danach ist keine Zeile gewählt.")
	assert_true((_node("%DeleteButton") as Button).disabled)

	# Act und Assert: Cmd+Z holt ihn zurück.
	_editor.undo()
	await wait_process_frames(1)
	assert_eq(_editor.catalog.get_profile(Difficulty.Level.SCHWER).modifiers.size(), 2)
	assert_eq(_zeilen().size(), 2)


# --- Eingaben ---------------------------------------------------------------------------------

func test_felder_uebernehmen_mit_enter_und_beim_verlassen() -> void:
	# Arrange
	await _oeffnen(GRADE)
	_panel.select_row(0)
	var wert: LineEdit = _node("%ValueEdit")

	# Act: Enter übernimmt und gibt den Fokus ab (R15 von Feature 002).
	wert.grab_focus()
	wert.text = "-2.5"
	wert.text_submitted.emit(wert.text)

	# Assert
	assert_false(wert.has_focus(), "Enter gibt den Fokus ab.")
	assert_eq(_modifikator(Difficulty.Level.LEICHT, 0).value, -0.025)
	assert_eq(wert.text, "-2,5", "Mit Komma und dem einfachen Minus.")
	assert_eq(_editor.undo_name(), "Wert von Leicht: reklamationswelle")

	# Act: Verlassen übernimmt, auch Daten ohne führende Nullen.
	var beginn: LineEdit = _node("%FromEdit")
	beginn.text = "1.1.1995"
	beginn.focus_exited.emit()
	await wait_process_frames(1)

	# Assert
	assert_eq(_modifikator(Difficulty.Level.LEICHT, 0).from_day, _tag(1995, 1, 1))
	assert_eq(beginn.text, "01.01.1995")
	assert_eq(_zeilen()[0], ["", "Reklamationswelle", "-2,5", "01.01.1995", "31.12.1999",
		"Nachsichtige Kunden", "reklamationswelle"], "Die Tabelle zeigt beides.")


func test_zwei_aenderungen_nacheinander_kommen_beide_an() -> void:
	# Arrange: Jede Änderung ersetzt das Profil durch eine Kopie (R10). Hielte das Panel das alte
	# Objekt, ginge die zweite Änderung ins Leere.
	await _oeffnen(GRADE)
	_panel.select_row(0)

	# Act
	_eingeben("%ValueEdit", "-3")
	_eingeben("%ReasonEdit", "Sehr nachsichtige Kunden")
	_eingeben("%IdEdit", "nachsicht")

	# Assert
	var modifikator := _modifikator(Difficulty.Level.LEICHT, 0)
	assert_eq([modifikator.value, modifikator.reason, modifikator.id],
		[-0.03, "Sehr nachsichtige Kunden", "nachsicht"])
	assert_eq(_editor.undo_name(), "Kennung von Leicht: reklamationswelle")


func test_ungueltige_zahl_behaelt_den_alten_wert_mit_hinweis() -> void:
	# Arrange
	await _oeffnen(GRADE)
	_panel.select_row(0)

	# Act
	_eingeben("%ValueEdit", "zwei")
	_eingeben("%ToEdit", "31.13.1999")

	# Assert
	assert_eq(_modifikator(Difficulty.Level.LEICHT, 0).value, -0.02, "Der alte Wert bleibt.")
	assert_eq(_modifikator(Difficulty.Level.LEICHT, 0).to_day, LETZTER_TAG)
	assert_eq(_text("%ValueEdit"), "-2", "Im Feld steht wieder der alte Wert.")
	assert_eq(_text("%ToEdit"), "31.12.1999")
	var hinweis: Label = _node("%ValueHint")
	assert_true(hinweis.visible)
	assert_string_contains(hinweis.text, "keine Zahl")
	assert_eq(hinweis.theme_type_variation, &"ErrorLabel")
	assert_eq((_node("%ValueEdit") as LineEdit).theme_type_variation, &"ErrorLineEdit")
	assert_string_contains((_node("%ToHint") as Label).text, "kein Datum")
	assert_false(_editor.can_undo(), "Nichts wurde übernommen.")


func test_cmd_z_im_feld_leert_es_nicht() -> void:
	# Arrange: wie test_cmd_z_im_feld_leert_es_nicht im Formular. Das Panel setzt die Werte in
	# Felder, die bleiben; ein LineEdit merkt sich auch das als Schritt in seinem Verlauf.
	await _oeffnen(GRADE)
	_panel.select_row(0)
	var grund: LineEdit = _node("%ReasonEdit")
	grund.grab_focus()

	# Act
	get_viewport().push_input(_cmd_z())
	grund.release_focus()

	# Assert
	assert_eq(grund.text, "Nachsichtige Kunden")
	assert_eq(_modifikator(Difficulty.Level.LEICHT, 0).reason, "Nachsichtige Kunden")
	assert_false(_editor.can_undo(), "Nichts wurde übernommen.")


func test_refresh_laesst_das_feld_mit_dem_fokus_stehen() -> void:
	# Arrange: Klaus tippt im Grund, da kommt eine Änderung von anderswo, etwa aus dem Formular.
	await _oeffnen(GRADE)
	_panel.select_row(0)
	var grund: LineEdit = _node("%ReasonEdit")
	grund.grab_focus()
	grund.text = "Kunden mit Geduld"

	# Act: refresh() über catalog_changed und issues_changed
	_editor.set_start_modifier_field(Difficulty.Level.LEICHT, 0, &"value", -0.03)

	# Assert
	assert_eq(grund.text, "Kunden mit Geduld", "Was Klaus tippt, bleibt stehen.")
	assert_eq(_text("%ValueEdit"), "-3", "Die übrigen Felder zeigen den neuen Stand.")

	# Act und Assert: Verlassen übernimmt die Eingabe.
	grund.release_focus()
	assert_eq(_modifikator(Difficulty.Level.LEICHT, 0).reason, "Kunden mit Geduld")


func test_offene_eingabe_gilt_beim_wechsel_der_bisher_gezeigten_zeile() -> void:
	# Arrange: zwei Zeilen in Schwer; Klaus tippt im Grund der ersten, ohne das Feld zu verlassen.
	await _oeffnen(GRADE)
	_panel.show_difficulty(Difficulty.Level.SCHWER)
	_panel.select_row(0)
	(_node("%DuplicateButton") as Button).pressed.emit()
	_panel.select_row(0)
	var grund: LineEdit = _node("%ReasonEdit")
	grund.grab_focus()
	grund.text = "Kunden mit Anwalt"

	# Act: andere Zeile, dann anderer Grad
	_panel.select_row(1)

	# Assert
	assert_eq(_modifikator(Difficulty.Level.SCHWER, 0).reason, "Kunden mit Anwalt")
	assert_eq(_modifikator(Difficulty.Level.SCHWER, 1).reason, "Anspruchsvolle Kunden",
		"Die zweite Zeile bleibt, wie sie war.")
	assert_eq(grund.text, "Anspruchsvolle Kunden", "Das Feld zeigt jetzt die zweite Zeile.")

	# Act und Assert: auch beim Wechsel des Grads
	grund.text = "Kunden mit Zeit"
	_panel.show_difficulty(Difficulty.Level.LEICHT)
	assert_eq(_modifikator(Difficulty.Level.SCHWER, 1).reason, "Kunden mit Zeit")
	assert_eq(_modifikator(Difficulty.Level.LEICHT, 0).reason, "Nachsichtige Kunden")


func test_ereignis_waehlen_und_ein_unbekanntes_ziel_steht_oben() -> void:
	# Arrange: V25, das Ziel konkurrent_eroeffnet gibt es im Katalog nicht.
	await _oeffnen(UNBEKANNT)
	_panel.show_difficulty(Difficulty.Level.SCHWER)
	_panel.select_row(0)
	var auswahl: OptionButton = _node("%EventOption")

	# Assert
	assert_eq(_zeilen()[0][DifficultyPanel.Column.EVENT], "konkurrent_eroeffnet (unbekannt)")
	assert_eq(auswahl.selected, 0)
	assert_eq(auswahl.get_item_text(0), "konkurrent_eroeffnet (unbekannt)")
	assert_eq(auswahl.get_item_text(1), "Reklamationswelle", "Danach die über Wahrscheinlichkeit.")
	assert_eq(auswahl.item_count, 2)
	assert_eq(auswahl.theme_type_variation, &"ErrorOptionButton")

	# Act
	auswahl.select(1)
	auswahl.item_selected.emit(1)

	# Assert
	assert_eq(_modifikator(Difficulty.Level.SCHWER, 0).event_id, "reklamationswelle")
	assert_eq(auswahl.item_count, 1, "Das unbekannte Ziel ist weg.")
	assert_eq(auswahl.theme_type_variation, &"")


# --- Prüfung ----------------------------------------------------------------------------------

func test_fehler_mit_zeichen_und_kontur_szenario_2() -> void:
	# Arrange und Act: US2, Szenario 2, Start-Modifikator auf das Weihnachtsgeschäft
	await _oeffnen(JAEHRLICH)
	_panel.show_difficulty(Difficulty.Level.SCHWER)
	_panel.select_row(0)

	# Assert
	assert_eq(_zeilen()[0][DifficultyPanel.Column.MARK], "!", "Die Zeile trägt das Zeichen.")
	var auswahl: OptionButton = _node("%EventOption")
	assert_eq(auswahl.get_item_text(0), "Weihnachtsgeschäft (fix, jährlich)")
	assert_eq(auswahl.selected, 0)
	assert_eq(auswahl.theme_type_variation, &"ErrorOptionButton")
	var hinweis: Label = _node("%EventHint")
	assert_true(hinweis.visible)
	assert_string_contains(hinweis.text, "nur zu Ereignissen über Wahrscheinlichkeit")
	assert_false(hinweis.text.contains("Profil „Schwer“"), "Der Ort steht nicht am Feld.")


func test_ende_vor_beginn_und_ohne_grund_szenario_3() -> void:
	# Arrange: US2, Szenario 3, ohne Grund aus der Datei
	await _oeffnen(GRUND_LEER)
	_panel.select_row(0)

	# Assert: Grund
	assert_eq(_zeilen()[0][DifficultyPanel.Column.MARK], "!")
	assert_string_contains((_node("%ReasonHint") as Label).text, "Der Grund ist leer.")
	assert_eq((_node("%ReasonEdit") as LineEdit).theme_type_variation, &"ErrorLineEdit")
	var meldung := _meldung("V29")
	assert_string_contains(meldung.message, "Profil „Leicht“, Start-Modifikator „reklamationswelle“",
		"Die Prüfung nennt Grad und Start-Modifikator.")

	# Act: Ende vor dem Beginn
	_eingeben("%ToEdit", "1.1.1990")
	_eingeben("%FromEdit", "1.1.1995")

	# Assert
	assert_string_contains((_node("%ToHint") as Label).text, "vor seinem Beginn")
	assert_eq((_node("%ToEdit") as LineEdit).theme_type_variation, &"ErrorLineEdit")
	assert_string_contains(_meldung("V27").message, "Profil „Leicht“, Start-Modifikator")


func test_warnung_v31_nur_als_hinweis_ohne_kontur() -> void:
	# Arrange und Act: Beginn und Ende mitten im Monat
	await _oeffnen(MONATSMITTE)
	_panel.show_difficulty(Difficulty.Level.SCHWER)
	_panel.select_row(0)

	# Assert
	assert_eq(_zeilen()[0][DifficultyPanel.Column.MARK], "?", "Eine Warnung ist ein „?“.")
	for feld: String in ["From", "To"]:
		var hinweis: Label = _node("%%%sHint" % feld)
		assert_true(hinweis.visible, "%s hat einen Hinweis." % feld)
		assert_eq(hinweis.theme_type_variation, &"WarningLabel", "%s in der Warnfarbe." % feld)
		assert_true(hinweis.text.begins_with("? "), "%s mit dem Zeichen der Warnung." % feld)
		assert_eq((_node("%%%sEdit" % feld) as LineEdit).theme_type_variation, &"",
			"%s ohne Fehlerkontur." % feld)


func test_focus_field_waehlt_grad_zeile_und_feld() -> void:
	# Arrange
	await _oeffnen(GRADE)

	# Act
	_panel.focus_field("profiles.schwer[0].reason")

	# Assert
	assert_eq(_panel.shown_difficulty(), Difficulty.Level.SCHWER)
	assert_eq(_gewaehlt(), 0)
	assert_same(get_viewport().gui_get_focus_owner(), _node("%ReasonEdit"))

	# Act und Assert: ohne Stelle nur der Grad, bei „profiles“ allein und „profiles.schwerr“
	# nichts weiter
	_panel.focus_field("profiles.mittel")
	assert_eq(_panel.shown_difficulty(), Difficulty.Level.MITTEL)
	_panel.focus_field("profiles")
	_panel.focus_field("profiles.schwerr[0].reason")
	assert_eq(_panel.shown_difficulty(), Difficulty.Level.MITTEL)
	_panel.focus_field("profiles.leicht[0].event_id")
	assert_eq(_panel.shown_difficulty(), Difficulty.Level.LEICHT)
	assert_same(get_viewport().gui_get_focus_owner(), _node("%EventOption"))


func test_szenario_1_anlegen_speichern_und_wieder_oeffnen() -> void:
	# Arrange: US2, Szenario 1, das Profil Leicht ist leer.
	await _oeffnen(MINIMAL)
	_panel.selected_event_id = "reklamationswelle"

	# Act: anlegen, Wert und Grund eintippen, speichern
	(_node("%NewButton") as Button).pressed.emit()
	_eingeben("%ValueEdit", "-2")
	_eingeben("%ReasonEdit", "Nachsichtige Kunden")
	assert_eq(_editor.save(), OK)
	var zweiter := _neuer_editor()
	assert_eq(zweiter.open(ORDNER + "katalog.json"), OK)

	# Assert: Er steht nach dem Neustart im Profil Leicht, das ganze Spiel lang.
	var profil := zweiter.catalog.get_profile(Difficulty.Level.LEICHT)
	assert_eq(profil.modifiers.size(), 1)
	var modifikator := profil.modifiers[0]
	assert_eq([modifikator.event_id, modifikator.value, modifikator.reason, modifikator.from_day,
		modifikator.to_day], ["reklamationswelle", -0.02, "Nachsichtige Kunden", 0, LETZTER_TAG])
	assert_eq(zweiter.issues().size(), 0, "Keine Meldungen.")


# --- Helfer -----------------------------------------------------------------------------------

## Öffnet eine Kopie von [param fixture] und stellt das Panel dazu in den Baum.
func _oeffnen(fixture: String) -> void:
	var ziel := ORDNER + "katalog.json"
	var datei := FileAccess.open(ziel, FileAccess.WRITE)
	datei.store_string(FileAccess.get_file_as_string(fixture))
	datei.close()
	_editor = _neuer_editor()
	assert_eq(_editor.open(ziel), OK)
	await _panel_mit(_editor)


## Das Panel im Baum, verdrahtet wie in der Werkstatt.
func _panel_mit(editor: CatalogEditor) -> void:
	_panel = PANEL.instantiate()
	add_child_autofree(_panel)
	_panel.editor = editor
	editor.catalog_changed.connect(_panel.refresh)
	editor.issues_changed.connect(func(_issues: Array[CatalogIssue]) -> void: _panel.refresh())
	_panel.refresh()
	await wait_process_frames(1)


func _neuer_editor() -> CatalogEditor:
	var editor := CatalogEditor.new()
	editor.backup_folder = ORDNER
	return editor


func _node(pfad: String) -> Node:
	return _panel.get_node(pfad)


func _text(pfad: String) -> String:
	return (_node(pfad) as LineEdit).text


## Tippt [param text] in das Feld [param pfad] und verlässt es, wie Klaus mit Tab.
func _eingeben(pfad: String, text: String) -> void:
	var eingabe: LineEdit = _node(pfad)
	eingabe.text = text
	eingabe.focus_exited.emit()


## Die Zeilen der Tabelle, je Zeile die Texte ihrer Spalten.
func _zeilen() -> Array:
	var tabelle: Tree = _node("%Table")
	var zeilen := []
	if tabelle.get_root() == null:
		return zeilen
	for zeile in tabelle.get_root().get_children():
		var texte := []
		for spalte in tabelle.columns:
			texte.append(zeile.get_text(spalte))
		zeilen.append(texte)
	return zeilen


## Die Stelle der gewählten Zeile in der Tabelle; −1 ohne.
func _gewaehlt() -> int:
	var zeile := (_node("%Table") as Tree).get_selected()
	return zeile.get_index() if zeile != null else -1


func _modifikator(grad: Difficulty.Level, stelle: int) -> ChanceModifier:
	return _editor.catalog.get_profile(grad).modifiers[stelle]


func _meldung(regel: String) -> CatalogIssue:
	for meldung in _editor.issues():
		if meldung.rule == regel:
			return meldung
	fail_test("Keine Meldung %s." % regel)
	return CatalogIssue.new()


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()


func _cmd_z() -> InputEventKey:
	var taste := InputEventKey.new()
	taste.keycode = KEY_Z
	taste.command_or_control_autoremap = true
	taste.pressed = true
	return taste
