extends GutTest

## Prüft den echten Ereigniskatalog res://data/event_catalog.json mit denselben Regeln wie die
## Werkstatt (FR-048): Er darf keine Meldung der Stufe ERROR haben, weder beim Lesen (V22) noch
## bei der Prüfung. Warnungen sind erlaubt, die zeigt die Werkstatt.
##
## Mehr prüft dieser Test am echten Katalog bewusst nicht. Klaus ändert ihn in der Werkstatt, und
## ein Test, der einzelne Werte festschreibt, bräche bei jeder Änderung. Dazu kommen später nur
## die Kalender-Ereignisse (T045). Was die Übernahme enthielt, prüft test_uebernahme.gd an einer
## eingefrorenen Kopie.


func test_echter_katalog_hat_keine_fehler() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.read_file(EventCatalog.DEFAULT_PATH, issues)
	if catalog != null:
		issues.append_array(CatalogValidator.validate(catalog))

	# Assert
	assert_not_null(catalog, "Der Katalog muss sich lesen lassen: %s" % [issues])
	assert_false(CatalogValidator.has_errors(issues), "Meldungen zum Katalog: %s" % [issues])
