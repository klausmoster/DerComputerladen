extends GutTest

## Prüft die Schwierigkeitsgrade (Feature 003, T002; contracts/zeitleiste.md, „Difficulty“): die
## Namen in Dateien und Texten, den Weg vom Namen zurück zum Grad und die Prüfung einer Zahl.
##
## Eine Aufzählung ist zur Laufzeit eine ganze Zahl. Deshalb gehören auch Zahlen dazu, die kein
## Grad sind, etwa 7 und −1: Sie müssen sicher durch key(), label() und is_valid() gehen.

## Je Grad sein Name in Dateien und sein Name in Texten.
const NAMEN := [
	[Difficulty.Level.LEICHT, "leicht", "Leicht"],
	[Difficulty.Level.MITTEL, "mittel", "Mittel"],
	[Difficulty.Level.SCHWER, "schwer", "Schwer"],
]


func test_drei_grade_mit_vorgabe_mittel() -> void:
	assert_eq(Difficulty.Level.values(), [0, 1, 2], "Genau drei Grade (FR-001).")
	assert_eq(Difficulty.DEFAULT, Difficulty.Level.MITTEL, "Ohne Angabe gilt Mittel (FR-006).")
	assert_eq(Difficulty.WITH_PROFILE, [Difficulty.Level.LEICHT, Difficulty.Level.SCHWER],
		"Profile haben nur Leicht und Schwer, in dieser Reihenfolge (FR-004).")


func test_alle_namen_hin_und_zurueck(fall: Array = use_parameters(NAMEN)) -> void:
	# Arrange
	var grad: int = fall[0]

	# Act
	var name_in_datei := Difficulty.key(grad)

	# Assert
	assert_eq(name_in_datei, fall[1], "Name in Dateien und Argumenten.")
	assert_eq(Difficulty.label(grad), fall[2], "Name in Texten.")
	assert_eq(Difficulty.from_key(name_in_datei), grad, "Vom Namen zurück zum Grad.")
	assert_true(Difficulty.is_valid(grad))


func test_unbekannte_namen_ergeben_minus_eins() -> void:
	# Groß- und Kleinschreibung zählt (FR-011): „Schwer“ mit großem S ist kein Name.
	for text: String in ["Schwer", "extrem", "", " schwer", "MITTEL"]:
		assert_eq(Difficulty.from_key(text), -1, "„%s“ ist kein Grad." % text)


func test_zahlen_die_kein_grad_sind() -> void:
	for zahl: int in [7, -1, 3]:
		assert_false(Difficulty.is_valid(zahl), "%d ist kein Grad." % zahl)
		assert_eq(Difficulty.key(zahl), "", "Ein unbekannter Grad hat keinen Namen in Dateien.")
	assert_eq(Difficulty.label(7), "Grad 7", "Ein unbekannter Grad steht als Zahl im Text.")
	assert_eq(Difficulty.label(-1), "Grad -1")
