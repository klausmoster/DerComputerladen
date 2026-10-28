extends GutTest

## Prüft die Folge der Gehäusetasten (Feature 006, T029; contracts/titelbildschirm.md, „Tests“;
## data-model.md, „Folge“): 1-2-3 ist vollständig, jede andere Reihenfolge nicht; ein falscher Druck
## auf die erste Taste zählt als neuer Anfang (FR-003); und 20 zufällige Folgen aus drei Drücken, die
## nicht 1-2-3 sind, sind nie vollständig (SC-005).
##
## Die Tasten heißen im Spiel 1, 2, 3 von links; ihre Plätze in case_keys sind 0, 1, 2.

## Die Folge des Easter Eggs: links, Mitte, rechts.
const FOLGE: Array[int] = [0, 1, 2]
## SC-005: so viele zufällige Folgen, mit festem Seed, damit jeder Lauf dieselben prüft.
const ZUFAELLIGE := 20
const SEED := 20261027


func test_eins_zwei_drei_ist_vollstaendig() -> void:
	# Arrange
	var folge := KeySequence.new(FOLGE)

	# Act
	var ergebnisse := _druecke(folge, [0, 1, 2])

	# Assert
	assert_eq(ergebnisse, [false, false, true], "Erst der dritte Druck macht die Folge voll.")


func test_andere_reihenfolgen_sind_nie_vollstaendig() -> void:
	for druecke: Array in [[1, 0, 2], [0, 2], [2, 1, 0]]:
		# Arrange
		var folge := KeySequence.new(FOLGE)

		# Act
		var ergebnisse := _druecke(folge, druecke)

		# Assert
		assert_false(ergebnisse.has(true), "%s ist nie vollständig." % _als_tasten(druecke))


func test_eins_eins_zwei_drei_ist_vollstaendig() -> void:
	# Arrange
	var folge := KeySequence.new(FOLGE)

	# Act: Die zweite 1 ist falsch, aber die erste der Folge, also ein neuer Anfang.
	var ergebnisse := _druecke(folge, [0, 0, 1, 2])

	# Assert
	assert_eq(ergebnisse, [false, false, false, true], "1-1-2-3 startet (FR-003).")


func test_eins_zwei_zwei_drei_ist_nicht_vollstaendig() -> void:
	# Arrange
	var folge := KeySequence.new(FOLGE)

	# Act
	var ergebnisse := _druecke(folge, [0, 1, 1, 2])

	# Assert
	assert_false(ergebnisse.has(true), "1-2-2-3 startet nicht.")
	assert_eq(folge.progress(), 0, "Die zweite 2 hat zurückgesetzt, die 3 zählt nicht.")


func test_fortschritt_zaehlt_und_nach_der_vollen_folge_beginnt_sie_von_vorn() -> void:
	# Arrange
	var folge := KeySequence.new(FOLGE)
	var staende := []

	# Act
	for taste in FOLGE:
		folge.press(taste)
		staende.append(folge.progress())

	# Assert
	assert_eq(staende, [1, 2, 0], "1, 2, dann voll und wieder bei 0.")
	assert_eq(_druecke(folge, [0, 1, 2]), [false, false, true],
		"Sie lässt sich gleich wieder eingeben.")


func test_falscher_druck_setzt_zurueck_und_reset_beginnt_von_vorn() -> void:
	# Arrange
	var folge := KeySequence.new(FOLGE)

	# Act und Assert
	_druecke(folge, [0, 1])
	assert_eq(folge.progress(), 2)
	folge.press(1)
	assert_eq(folge.progress(), 0, "1-2-2: Die zweite 2 ist falsch und nicht die erste der Folge.")
	_druecke(folge, [0, 1])
	folge.reset()
	assert_eq(folge.progress(), 0, "reset() beginnt von vorn.")
	assert_false(folge.press(2), "Nach reset() zählt die 3 allein nicht.")


func test_sc_005_zwanzig_zufaellige_folgen_aus_drei_druecken_sind_nie_vollstaendig() -> void:
	# Arrange: 20 Folgen aus je drei Drücken auf die Tasten 1 bis 3, außer 1-2-3 selbst.
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = SEED
	var folgen: Array[Array] = []
	while folgen.size() < ZUFAELLIGE:
		var druecke := [wuerfel.randi_range(0, 2), wuerfel.randi_range(0, 2),
			wuerfel.randi_range(0, 2)]
		if druecke != [0, 1, 2]:
			folgen.append(druecke)

	# Act: jede mit einer frischen Folge, wie ein Titel, der neu erscheint.
	var vollstaendig := []
	for druecke in folgen:
		if _druecke(KeySequence.new(FOLGE), druecke).has(true):
			vollstaendig.append(_als_tasten(druecke))

	# Assert
	assert_eq(vollstaendig, [], "Keine der %d Folgen startet." % ZUFAELLIGE)


# --- Helfer ---------------------------------------------------------------

## Gibt jeden Druck aus [param druecke] an [param folge] und sammelt, was press() jeweils meldet.
func _druecke(folge: KeySequence, druecke: Array) -> Array:
	var ergebnisse := []
	for taste: int in druecke:
		ergebnisse.append(folge.press(taste))
	return ergebnisse


## Die Plätze [param druecke] so, wie der Spieler die Tasten zählt: „1-2-3“.
func _als_tasten(druecke: Array) -> String:
	return "-".join(druecke.map(func(taste: int) -> String: return str(taste + 1)))
