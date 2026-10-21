extends GutTest

## Prüft das Formular der Werkstatt (Feature 002, T036; contracts/werkstatt.md, „EventForm“): die
## Felder je Art, Eingaben mit Komma, Punkt und Prozent, Daten auch ohne führende Nullen, den
## Hinweis bei ungültiger Eingabe, das Verteilen der Gewichte, Meldungen am Feld samt roter Kontur
## auch an Auswahlfeldern (T081), die Grenze von 20 Anzahlen (T086), focus_field() und den Bereich
## für Kategorien.
##
## Das Formular steht hier ohne die Werkstatt im Baum, mit einem eigenen CatalogEditor auf einer
## Kopie von catalog_minimal.json. Was die Werkstatt verdrahtet, verdrahtet der Test selbst:
## catalog_changed und issues_changed rufen refresh().

const FORMULAR := preload("res://tools/werkstatt/event_form.tscn")
const THEMA := preload("res://tools/werkstatt/werkstatt_theme.tres")
const ORDNER := "user://test_event_form/"
const MINIMAL := "res://test/fixtures/catalog_minimal.json"
## 01.01.1985 = 0; der 01.03.1993 ist Tag 2981.
const ERSTER_MAERZ_1993 := 2981

## Text, Lesefunktion, erwarteter Wert; null heißt: wird abgelehnt.
const EINGABEN := [
	["3,5", "parse_percent", 0.035],
	["3.5", "parse_percent", 0.035],
	["3,5 %", "parse_percent", 0.035],
	["-30", "parse_percent", -0.3],
	["12,346", "parse_percent", 0.1235],
	["abc", "parse_percent", null],
	["1,2,3", "parse_number", null],
	["14", "parse_whole", 14],
	["-3", "parse_whole", -3],
	["1,5", "parse_whole", null],
	["", "parse_whole", null],
	["1.3.1993", "parse_date", ERSTER_MAERZ_1993],
	["01.03.1993", "parse_date", ERSTER_MAERZ_1993],
	["30.2.1993", "parse_date", null],
	["1993-03-01", "parse_date", null],
	["1.11.", "parse_day_of_year", Vector2i(11, 1)],
	["31.12", "parse_day_of_year", Vector2i(12, 31)],
	["32.1.", "parse_day_of_year", null],
	["33,33", "parse_weight", 33.33],
]

var _editor: CatalogEditor
var _formular: EventForm


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)
	var ziel := ORDNER + "katalog.json"
	var datei := FileAccess.open(ziel, FileAccess.WRITE)
	datei.store_string(FileAccess.get_file_as_string(MINIMAL))
	datei.close()
	_editor = CatalogEditor.new()
	_editor.backup_folder = ORDNER
	assert_eq(_editor.open(ziel), OK)
	_formular = FORMULAR.instantiate()
	_formular.editor = _editor
	add_child_autofree(_formular)
	_editor.catalog_changed.connect(_formular.refresh)
	_editor.issues_changed.connect(func(_issues: Array[CatalogIssue]) -> void: _formular.refresh())


func after_each() -> void:
	_formular = null
	_editor = null
	var ordner := DirAccess.open(ORDNER)
	if ordner != null:
		for datei in ordner.get_files():
			ordner.remove(datei)
	DirAccess.remove_absolute(ORDNER)


# --- Lesen und Zeigen -------------------------------------------------------------------------

func test_eingaben_werden_gelesen(fall: Array = use_parameters(EINGABEN)) -> void:
	# Act: Die Lesefunktionen sind statisch; Callable ruft sie über ihren Namen an der Klasse.
	var gelesen: Array = Callable(EventForm, fall[1]).call(fall[0])

	# Assert: FR-031
	if fall[2] == null:
		assert_false(gelesen[0], "„%s“ muss abgelehnt werden." % fall[0])
		assert_string_contains(gelesen[1], "„", "Der Hinweis nennt die Eingabe.")
	else:
		assert_true(gelesen[0], "„%s“ muss angenommen werden: %s" % [fall[0], gelesen])
		assert_eq(gelesen[1], fall[2])


func test_zahlen_erscheinen_mit_komma() -> void:
	assert_eq(EventForm.format_percent(0.035), "3,5")
	assert_eq(EventForm.format_percent(-0.3), "-30")
	assert_eq(EventForm.format_percent(0.0), "0")
	assert_eq(EventForm.format_number(33.33), "33,33")
	assert_eq(EventForm.format_number(-0.001), "0", "Kein „-0“.")
	assert_eq(EventForm.format_date(ERSTER_MAERZ_1993), "01.03.1993")
	assert_eq(EventForm.format_day_of_year(Vector2i(11, 1)), "01.11.")
	assert_eq(EventForm.format_day_of_year(Vector2i.ZERO), "")


func test_gewichte_werden_gleich_verteilt_und_ergeben_100() -> void:
	# FR-004: alle gleich auf zwei Stellen, den Rest bekommt das letzte.
	assert_eq(EventForm.spread_weights(1), [100.0])
	assert_eq(EventForm.spread_weights(3), [33.33, 33.33, 33.34])
	assert_eq(EventForm.spread_weights(6), [16.67, 16.67, 16.67, 16.67, 16.67, 16.65])
	for anzahl in range(1, 21):
		var summe := 0.0
		for gewicht in EventForm.spread_weights(anzahl):
			summe += gewicht
		assert_almost_eq(summe, 100.0, 0.000001, "Summe bei %d Anzahlen." % anzahl)


# --- Felder je Art ----------------------------------------------------------------------------

func test_felder_je_art() -> void:
	# FR-031: Die Art bestimmt, welche Felder es gibt.
	var erwartet := {
		"intel_pentium": [["date", "duration_days"],
			["window.from", "monthly_chance", "yearly.start"]],
		"weihnachtsgeschaeft": [["yearly.from", "yearly.to", "yearly.start", "yearly.end"],
			["date", "duration_days", "window.from"]],
		"neubaugebiet": [["window.from", "window.to", "count_min", "count_max", "count_weights",
			"min_gap_days", "duration_days"], ["date", "monthly_chance"]],
		"reklamationswelle": [["window.from", "window.to", "monthly_chance", "max_occurrences",
			"min_gap_days", "duration_days"], ["date", "count_min"]],
		"zeitungsartikel": [["duration_days"], ["date", "window.from", "monthly_chance"]],
	}
	for id: String in erwartet:
		_formular.show_event(id)
		for feld: String in erwartet[id][0]:
			assert_not_null(_formular.get_input(feld), "%s zeigt %s." % [id, feld])
		for feld: String in erwartet[id][1]:
			assert_null(_formular.get_input(feld), "%s zeigt %s nicht." % [id, feld])
		for feld in ["title", "id", "description", "category", "kind"]:
			assert_not_null(_formular.get_input(feld), "Jede Art hat %s." % feld)


func test_bedingungen_nur_bei_den_arten_mit_bedingungen() -> void:
	# FR-006
	_formular.show_event("intel_pentium")
	assert_false(_formular.get_node("%ConditionsBox").visible)
	_formular.show_event("zeitungsartikel")
	assert_true(_formular.get_node("%ConditionsBox").visible)
	assert_not_null(_formular.get_input("conditions[0].event"))


func test_geltung_nur_bei_ereignissen_mit_dauer() -> void:
	# T036: Wirkungen mit scope bei Ereignissen mit Dauer.
	_formular.show_event("weihnachtsgeschaeft")
	assert_not_null(_formular.get_input("effects[0].scope"), "Das Weihnachtsgeschäft hat Dauer.")
	_formular.show_event("intel_pentium")
	assert_null(_formular.get_input("effects[0].scope"), "Der Pentium hat keine Dauer.")


# --- Eingaben ---------------------------------------------------------------------------------

func test_chance_mit_komma_oder_punkt() -> void:
	# Arrange: quickstart.md, Abschnitt 4.1.
	_formular.show_event("reklamationswelle")

	# Act und Assert
	_eingeben("monthly_chance", "3,5")
	assert_eq(_editor.catalog.get_event("reklamationswelle").monthly_chance, 0.035)
	await wait_process_frames(1)
	assert_eq(_text("monthly_chance"), "3,5")
	_eingeben("monthly_chance", "3.5")
	assert_eq(_text("monthly_chance"), "3,5", "Auch der Punkt erscheint als Komma.")
	assert_eq(_editor.undo_name(), "Grundchance von Reklamationswelle",
		"„3.5“ war derselbe Wert und ist kein neuer Schritt.")


func test_datum_ohne_fuehrende_nullen_und_ungueltige_eingabe() -> void:
	# Arrange
	_formular.show_event("intel_pentium")

	# Act und Assert
	_eingeben("date", "1.3.1993")
	assert_eq(_editor.catalog.get_event("intel_pentium").date, ERSTER_MAERZ_1993)
	await wait_process_frames(1)
	assert_eq(_text("date"), "01.03.1993")
	_eingeben("date", "abc")
	assert_eq(_editor.catalog.get_event("intel_pentium").date, ERSTER_MAERZ_1993,
		"Ungültiges wird nicht übernommen.")
	assert_eq(_text("date"), "01.03.1993", "Der alte Wert steht wieder da.")
	assert_true(_hinweis("date").visible)
	assert_string_contains(_hinweis("date").text, "kein Datum")


func test_ungueltige_eingabe_hat_die_rote_kontur_bis_zum_naechsten_neubau() -> void:
	# Arrange (T093): Wie bei den Meldungen der Prüfung bekommt auch ein Feld, dessen Eingabe
	# nicht ging, die Kontur, solange der Hinweis darunter steht.
	_formular.show_event("intel_pentium")

	# Act
	_eingeben("date", "abc")

	# Assert
	assert_true(_hinweis("date").visible)
	assert_eq(_formular.get_input("date").theme_type_variation, &"ErrorLineEdit")
	assert_eq(_formular.get_input("title").theme_type_variation, &"", "Nur das Feld mit Hinweis.")

	# Act und Assert: Eine gültige Eingabe baut neu, Hinweis und Kontur gehen.
	_eingeben("date", "1.3.1993")
	await wait_process_frames(1)
	assert_false(_hinweis("date").visible)
	assert_eq(_formular.get_input("date").theme_type_variation, &"")

	# Act und Assert: auch bei „bis“ der Anzahl und bei einer Kennung, die es schon gibt
	_formular.show_event("neubaugebiet")
	_eingeben("count_max", "-1")
	assert_eq(_formular.get_input("count_max").theme_type_variation, &"ErrorLineEdit")
	_eingeben("id", "intel_pentium")
	assert_string_contains(_hinweis("id").text, "gibt es schon")
	assert_eq(_formular.get_input("id").theme_type_variation, &"ErrorLineEdit")


func test_meldung_der_pruefung_steht_am_feld() -> void:
	# Arrange: US2, Szenario 3.
	_formular.show_event("intel_pentium")

	# Act
	_eingeben("date", "12.05.2001")
	await wait_process_frames(1)

	# Assert
	assert_string_contains(_hinweis("date").text, "außerhalb von 01.01.1985 bis 31.12.1999")
	assert_eq(_formular.get_input("date").theme_type_variation, &"ErrorLineEdit")
	assert_eq(_hinweis("date").theme_type_variation, &"ErrorLabel")


func test_auswahlfeld_mit_fehler_bekommt_die_rote_kontur() -> void:
	# Arrange (T081): Die Kategorie des Pentium gibt es nicht (V05), das Folgeereignis der
	# Reklamationswelle auch nicht (V15). Das Theme der Werkstatt hängt sonst an der Werkstatt.
	_formular.theme = THEMA
	_editor.set_event_field("intel_pentium", &"category", "grafik")
	_editor.set_item_field("reklamationswelle", &"follow_ups", 0, &"target", "gibt_es_nicht")

	# Act
	_formular.show_event("intel_pentium")

	# Assert: Style-Guide, „Bedienelemente“: Kontur von 2 Pixeln in kassenrot, darunter der Hinweis
	var auswahl: OptionButton = _formular.get_input("category")
	assert_eq(auswahl.theme_type_variation, &"ErrorOptionButton")
	assert_eq(_hinweis("category").theme_type_variation, &"ErrorLabel")
	var kasten: ReliefStyleBox = auswahl.get_theme_stylebox(&"normal")
	assert_eq([kasten.outline, kasten.outline_width], [&"kassenrot", 2])
	var fokus: StyleBoxFlat = auswahl.get_theme_stylebox(&"focus")
	assert_eq(fokus.border_color, UiPalette.TUSCHE, "Die Fokuslinie in tusche bleibt.")
	assert_eq(_formular.get_input("kind").theme_type_variation, &"", "Ohne Fehler wie immer.")
	_formular.show_event("reklamationswelle")
	assert_eq(_formular.get_input("follow_ups[0].target").theme_type_variation,
		&"ErrorOptionButton", "Auch das Ziel einer Folge.")


func test_beschreibung_mit_fehler_bekommt_die_rote_kontur() -> void:
	# Arrange (T081): In der Datei steht als Beschreibung eine Zahl (V22).
	var ziel := ORDNER + "beschreibung.json"
	var text := FileAccess.get_file_as_string(MINIMAL).replace(
		"\"description\": \"Superskalare P5-Architektur, 64-Bit-Bus.\"", "\"description\": 5")
	_schreiben(ziel, text)
	assert_eq(_editor.open(ziel), OK)
	_formular.theme = THEMA

	# Act
	_formular.show_event("intel_pentium")

	# Assert
	var feld: TextEdit = _formular.get_input("description")
	assert_eq(feld.theme_type_variation, &"ErrorTextEdit")
	var kasten: StyleBoxFlat = feld.get_theme_stylebox(&"normal")
	assert_eq([kasten.border_color, kasten.border_width_left], [UiPalette.KASSENROT, 2])
	assert_string_contains(_hinweis("description").text, "die Zahl 5")


func test_enter_uebernimmt_und_gibt_den_fokus_ab() -> void:
	# Arrange: R15, damit das nächste Cmd+Z den Katalog erreicht.
	_formular.show_event("intel_pentium")
	var titel: LineEdit = _formular.get_input("title")
	titel.grab_focus()
	titel.text = "Pentium kommt"

	# Act
	titel.text_submitted.emit(titel.text)

	# Assert
	assert_false(titel.has_focus(), "Enter gibt den Fokus ab.")
	assert_eq(_editor.catalog.get_event("intel_pentium").title, "Pentium kommt")


func test_cmd_z_im_feld_leert_es_nicht() -> void:
	# Arrange: Ein LineEdit merkt sich auch das Setzen des Texts als Schritt in seinem Verlauf; ein
	# Cmd+Z im frisch gebauten Feld stellte sonst den leeren Anfang wieder her.
	_formular.show_event("intel_pentium")
	var titel: LineEdit = _formular.get_input("title")
	titel.grab_focus()
	var taste := InputEventKey.new()
	taste.keycode = KEY_Z
	taste.command_or_control_autoremap = true
	taste.pressed = true

	# Act
	get_viewport().push_input(taste)
	titel.release_focus()

	# Assert
	assert_eq(titel.text, "Intel Pentium erscheint")
	assert_eq(_editor.catalog.get_event("intel_pentium").title, "Intel Pentium erscheint")
	assert_false(_editor.can_undo(), "Nichts wurde übernommen.")


func test_fokus_bleibt_nach_dem_neubau_im_naechsten_feld() -> void:
	# Arrange: Klaus wechselt mit Tab vom Titel in die Kennung. Das Übernehmen des Titels baut das
	# Formular neu; die Kennung muss den Fokus trotzdem behalten.
	_formular.show_event("intel_pentium")
	var titel: LineEdit = _formular.get_input("title")
	titel.grab_focus()
	titel.text = "Pentium kommt"

	# Act
	_formular.get_input("id").grab_focus()
	await wait_process_frames(1)

	# Assert
	assert_eq(_editor.catalog.get_event("intel_pentium").title, "Pentium kommt")
	assert_ne(_formular.get_input("title"), titel, "Das Formular ist neu gebaut.")
	assert_same(get_viewport().gui_get_focus_owner(), _formular.get_input("id"))


func test_anzahl_verteilt_die_gewichte_in_einem_schritt() -> void:
	# Arrange: FR-004. Das Neubaugebiet kommt 0- oder 1-mal, mit 30 und 70 %.
	_formular.show_event("neubaugebiet")

	# Act
	_eingeben("count_max", "3")

	# Assert
	var neubau := _editor.catalog.get_event("neubaugebiet")
	assert_eq([neubau.count_min, neubau.count_weights], [0, [25.0, 25.0, 25.0, 25.0]])
	assert_eq(_editor.undo_name(), "Gewichte von Neubaugebiet am Stadtrand")
	_editor.undo()
	assert_eq(_editor.catalog.get_event("neubaugebiet").count_weights, [30.0, 70.0],
		"Ein Rückgängig nimmt Anzahl und Gewichte zusammen zurück.")


func test_anzahl_bis_vor_von_wird_abgelehnt() -> void:
	# Arrange
	_formular.show_event("neubaugebiet")

	# Act
	_eingeben("count_max", "-1")

	# Assert
	assert_false(_editor.can_undo())
	assert_eq(_text("count_max"), "1")
	assert_string_contains(_hinweis("count_max").text, "„bis“")


func test_bis_zu_20_anzahlen_ohne_hinweis() -> void:
	# Act
	_formular.show_event("neubaugebiet")

	# Assert
	assert_null(_formular.get_hint(EventForm.COUNT_LIMIT_HINT))


func test_mehr_als_20_anzahlen_zeigt_einen_hinweis_und_kuerzt_nichts() -> void:
	# Arrange (T086): In der Datei hat das Neubaugebiet 25 Anzahlen, 0 bis 24, je 4 %.
	var meldungen: Array[CatalogIssue] = []
	var katalog := EventCatalog.read_file(MINIMAL, meldungen)
	var gewichte: Array[float] = []
	for i in 25:
		gewichte.append(4.0)
	katalog.get_event("neubaugebiet").count_weights = gewichte
	var ziel := ORDNER + "anzahlen.json"
	assert_eq(katalog.write_file(ziel), OK)
	assert_eq(_editor.open(ziel), OK)

	# Act
	_formular.show_event("neubaugebiet")

	# Assert: ein Hinweis als Warnung, die ersten 20 Gewichte, „bis“ und Summe über alle
	var hinweis := _formular.get_hint(EventForm.COUNT_LIMIT_HINT)
	assert_not_null(hinweis)
	if hinweis == null:
		return
	assert_true(hinweis.visible)
	assert_eq(hinweis.theme_type_variation, &"WarningLabel")
	assert_eq(hinweis.text, "? Das Ereignis hat 25 Anzahlen, das Formular zeigt höchstens 20. "
		+ "Die übrigen Gewichte änderst du in der Katalogdatei.")
	assert_not_null(_formular.get_input("count_weights[19]"))
	assert_null(_formular.get_input("count_weights[20]"), "Mehr als 20 Felder legt es nicht an.")
	assert_eq(_text("count_max"), "24")

	# Act und Assert: Ein Gewicht ändern ersetzt nur dieses eine.
	_eingeben("count_weights[3]", "8")
	var neubau := _editor.catalog.get_event("neubaugebiet")
	assert_eq(neubau.count_weights.size(), 25, "Gekürzt wird nichts.")
	assert_eq([neubau.count_weights[3], neubau.count_weights[24]], [8.0, 4.0])
	# Ein „von“, das mehr als 20 Anzahlen ergäbe, lehnt es mit Hinweis ab.
	_eingeben("count_min", "1")
	assert_eq(_editor.catalog.get_event("neubaugebiet").count_min, 0)
	assert_string_contains(_hinweis("count_min").text, "Höchstens 20")
	await wait_process_frames(1)
	assert_not_null(_formular.get_hint(EventForm.COUNT_LIMIT_HINT), "Nach dem Neubau wieder da.")

	# Act und Assert: auch beim Speichern nicht
	assert_eq(_editor.save(), OK)
	var gespeichert := EventCatalog.read_file(ziel, meldungen)
	assert_eq(gespeichert.get_event("neubaugebiet").count_weights.size(), 25)
	assert_eq(gespeichert.get_event("neubaugebiet").count_weights[3], 8.0)


func test_artwechsel_im_formular() -> void:
	# Arrange
	_formular.show_event("reklamationswelle")
	var art: OptionButton = _formular.get_input("kind")

	# Act
	art.select(TimelineEvent.Kind.PRESET)
	art.item_selected.emit(TimelineEvent.Kind.PRESET)
	await wait_process_frames(1)

	# Assert: FR-031
	assert_eq(_editor.catalog.get_event("reklamationswelle").kind, TimelineEvent.Kind.PRESET)
	assert_not_null(_formular.get_input("count_weights"), "Jetzt mit Gewichten je Anzahl.")
	assert_null(_formular.get_input("monthly_chance"))


func test_wirkung_hinzufuegen_und_ziel_eingeben() -> void:
	# Arrange
	_formular.show_event("intel_pentium")

	# Act und Assert
	_formular.get_node("%AddEffect").pressed.emit()
	await wait_process_frames(1)
	assert_eq(_editor.catalog.get_event("intel_pentium").effects.size(), 3)
	assert_not_null(_formular.get_input("effects[2].kind"))
	_eingeben("effects[2].target", "maus")
	assert_eq(_editor.catalog.get_event("intel_pentium").effects[2].target, "maus")


func test_langer_titel_in_der_auswahl_macht_das_formular_nicht_breiter() -> void:
	# Arrange: Die Reklamationswelle hat ein Folgeereignis; zur Wahl stehen die Ereignisse, die
	# Folge sein dürfen, darunter das Neubaugebiet.
	_formular.show_event("reklamationswelle")
	var vorher := _formular.get_combined_minimum_size().x

	# Act
	_editor.set_event_field("neubaugebiet", &"title", "Ein sehr langer Titel ".repeat(12))
	await wait_process_frames(1)

	# Assert: Der lange Titel steht zur Wahl, wird aber abgeschnitten (clip_text).
	var auswahl: OptionButton = _formular.get_input("follow_ups[0].target")
	var texte := []
	for i in auswahl.item_count:
		texte.append(auswahl.get_item_text(i))
	assert_true(texte.any(func(text: String) -> bool: return text.begins_with("Ein sehr lang")))
	assert_eq(_formular.get_combined_minimum_size().x, vorher, "Das Formular bleibt so breit.")


# --- focus_field ------------------------------------------------------------------------------

func test_focus_field_findet_felder_auch_in_den_listen() -> void:
	# Arrange
	_formular.show_event("intel_pentium")

	# Act
	_formular.focus_field("effects[1].delay_days")

	# Assert: FR-033
	assert_same(get_viewport().gui_get_focus_owner(), _formular.get_input("effects[1].delay_days"))


func test_unbekanntes_feld_laesst_den_fokus() -> void:
	# Arrange: etwa ein unbekannter Schlüssel aus der Datei (V22)
	_formular.show_event("intel_pentium")
	var titel: LineEdit = _formular.get_input("title")
	titel.grab_focus()

	# Act
	_formular.focus_field("farbe")

	# Assert
	assert_same(get_viewport().gui_get_focus_owner(), titel)


# --- Kategorien -------------------------------------------------------------------------------

func test_belegte_kategorie_laesst_sich_nicht_loeschen() -> void:
	# Arrange: FR-031. Ein Ereignis gehört zu hardware.
	_formular.show_event("")
	_editor.add_category("Leer")
	await wait_process_frames(1)

	# Act
	var knoepfe := _loeschknoepfe()

	# Assert
	assert_true(knoepfe["hardware"].disabled)
	assert_eq(knoepfe["hardware"].tooltip_text, "Gehört noch zu 1 Ereignis.")
	assert_false(knoepfe["leer"].disabled)
	knoepfe["leer"].pressed.emit()
	assert_null(_editor.catalog.get_category("leer"))


func test_kategorie_anlegen_umbenennen_und_farbe_waehlen() -> void:
	# Arrange
	var name_feld: LineEdit = _formular.get_node("%NewCategoryName")
	name_feld.text = "Presse"
	name_feld.text_changed.emit(name_feld.text)

	# Act
	_formular.get_node("%NewCategoryButton").pressed.emit()
	await wait_process_frames(1)
	var stelle := _editor.catalog.categories.size() - 1
	_eingeben("categories[%d].name" % stelle, "Lokalpresse")
	var farbe: OptionButton = _formular.get_input("categories[%d].color" % stelle)
	farbe.select(UiPalette.CATEGORY_TOKENS.find(&"holz"))
	farbe.item_selected.emit(UiPalette.CATEGORY_TOKENS.find(&"holz"))

	# Assert
	var presse := _editor.catalog.get_category("presse")
	assert_not_null(presse, "Die Kennung entsteht aus dem Namen.")
	assert_eq(presse.name, "Lokalpresse", "Umbenennen ändert nur den Namen.")
	assert_eq(presse.color, &"holz")
	assert_eq(name_feld.text, "", "Das Feld für den Namen ist wieder leer.")


# --- Helfer -----------------------------------------------------------------------------------

## Tippt [param text] in das Feld [param feld] und verlässt es, wie Klaus mit Tab.
func _eingeben(feld: String, text: String) -> void:
	var eingabe: LineEdit = _formular.get_input(feld)
	assert_not_null(eingabe, "Das Feld %s fehlt." % feld)
	if eingabe == null:
		return
	eingabe.text = text
	eingabe.focus_exited.emit()


func _schreiben(ziel: String, text: String) -> void:
	var datei := FileAccess.open(ziel, FileAccess.WRITE)
	datei.store_string(text)
	datei.close()


func _text(feld: String) -> String:
	var eingabe: LineEdit = _formular.get_input(feld)
	return eingabe.text


func _hinweis(feld: String) -> Label:
	return _formular.get_hint(feld)


## Kennung der Kategorie → ihr Knopf „Löschen“.
func _loeschknoepfe() -> Dictionary:
	var knoepfe := {}
	for i in _editor.catalog.categories.size():
		var name_feld: LineEdit = _formular.get_input("categories[%d].name" % i)
		for kind in name_feld.get_parent().get_children():
			if kind is Button and kind.text == "Löschen":
				knoepfe[_editor.catalog.categories[i].id] = kind
	return knoepfe
