extends GutTest

## Prüft FieldHelpers, die gemeinsamen Hilfen der Panels der Werkstatt (Feature 008, T036b, L16):
## den Grund einer Prüfmeldung ohne Ort, die Kontur eines Felds mit Fehler je Art und den Namen
## einer Kategorie. Lesen und Zeigen von Zahlen und Daten prüft test_event_form.gd, wo die
## Funktionen bis Feature 008 standen.


func test_der_grund_einer_meldung_steht_ohne_ort_davor() -> void:
	# Arrange: wie CatalogIssue.locate() den Ort vor die Meldung setzt
	var mit_ort := CatalogIssue.new(CatalogIssue.Severity.ERROR, "V06", "intel_pentium", "date",
		"Ereignis „intel_pentium“, Feld „date“: Das Datum liegt vor 1985.")
	var ohne_ort := CatalogIssue.new(CatalogIssue.Severity.WARNING, "V13", "", "",
		"Der Katalog hat keine Ereignisse.")

	# Act und Assert
	assert_eq(FieldHelpers.reason(mit_ort), "Das Datum liegt vor 1985.")
	assert_eq(FieldHelpers.reason(ohne_ort), "Der Katalog hat keine Ereignisse.",
		"Ohne Ort bleibt die Meldung, wie sie ist.")


func test_ein_feld_mit_fehler_bekommt_die_variante_seiner_art() -> void:
	# Arrange
	var faelle := [
		[LineEdit.new(), &"ErrorLineEdit"],
		[OptionButton.new(), &"ErrorOptionButton"],
		[TextEdit.new(), &"ErrorTextEdit"],
		[Button.new(), &""],
	]

	for fall: Array in faelle:
		var feld: Control = fall[0]

		# Act
		FieldHelpers.mark_error(feld)

		# Assert: Ein Knopf ist kein Feld und bleibt, wie er ist.
		assert_eq(feld.theme_type_variation, fall[1], feld.get_class())
		feld.free()


func test_eine_kategorie_heisst_wie_ihr_name_sonst_wie_ihre_kennung() -> void:
	# Arrange
	var mit_namen := EventCategory.new()
	mit_namen.id = "technik"
	mit_namen.name = "Technik"
	var ohne_namen := EventCategory.new()
	ohne_namen.id = "presse"
	ohne_namen.name = "  "

	# Act und Assert
	assert_eq(FieldHelpers.category_label(mit_namen), "Technik")
	assert_eq(FieldHelpers.category_label(ohne_namen), "presse", "Nur Leerzeichen zählt als leer.")
