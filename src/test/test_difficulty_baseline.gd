extends GutTest

## Hält fest, wie die Zeitleiste vor den Schwierigkeitsgraden lief (Feature 003, T001; SC-007;
## research.md, R17). Fahrplan und Protokoll der eingefrorenen Übernahme für die Seeds 1, 4711 und
## 99999 stehen als Grundlinie unter res://test/fixtures/. Erzeugt hat sie die Textausgabe mit dem
## Code auf dem Stand von 994b9f5, bevor sich am Lauf etwas änderte:
##
## [codeblock]
## Godot --headless --no-header --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- \
##         --seed 4711 --katalog res://test/fixtures/event_catalog_uebernahme.json [--protokoll]
## [/codeblock]
##
## Beim Fahrplan fehlt die Kopfzeile „# Seed …“, denn sie nennt mit FR-021 bald auch den Grad. Der
## Test spielt jeden Seed bis zum 31.12.1999 und vergleicht Zeile für Zeile, Zeichen für Zeichen.
## Er muss bis zum Ende des Features grün bleiben: Ohne Profil läuft alles wie in Feature 002.
##
## Ändert ein Godot-Update die Würfel, entstehen die Fixtures mit dem Befehl oben neu (R5 von
## Feature 002); sonst nie.
##
## Seit T010 kennt der Lauf einen Grad. Dieselbe Grundlinie gilt dann für den Lauf ohne Grad, für
## Mittel ausdrücklich und für Leicht und Schwer mit leerem Profil: Die Übernahme hat keinen
## Abschnitt profiles, beide Profile sind also leer (SC-007).

const UEBERNAHME := "res://test/fixtures/event_catalog_uebernahme.json"
const ORDNER := "res://test/fixtures/"
const SEEDS := [1, 4711, 99999]

var _catalog: EventCatalog


func before_all() -> void:
	var issues: Array[CatalogIssue] = []
	_catalog = EventCatalog.read_file(UEBERNAHME, issues)


func test_die_uebernahme_hat_keinen_fehler() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.read_file(UEBERNAHME, issues)
	assert_not_null(catalog, "Die Übernahme muss sich lesen lassen: %s" % [issues])
	if catalog == null:
		return

	# Act
	issues.append_array(CatalogValidator.validate(catalog))

	# Assert: Ein Fehler nähme ein Ereignis aus dem Lauf, und die Grundlinie belegte weniger.
	assert_false(CatalogValidator.has_errors(issues), "Meldungen zur Übernahme: %s" % [issues])


func test_fahrplan_wie_die_grundlinie(seed_wert: int = use_parameters(SEEDS)) -> void:
	# Arrange
	var run := _gespielt(seed_wert)

	# Act: ohne die Kopfzeile, die künftig den Grad nennt
	var zeilen := ScheduleText.plan_lines(run)
	zeilen.remove_at(0)

	# Assert
	_vergleiche(zeilen, ORDNER + "fahrplan_uebernahme_seed_%d.txt" % seed_wert)


func test_protokoll_wie_die_grundlinie(seed_wert: int = use_parameters(SEEDS)) -> void:
	# Arrange
	var run := _gespielt(seed_wert)

	# Act
	var zeilen := ScheduleText.protocol_lines(run)

	# Assert
	_vergleiche(zeilen, ORDNER + "protokoll_uebernahme_seed_%d.txt" % seed_wert)


func test_mittel_ausdruecklich_wie_die_grundlinie(seed_wert: int = use_parameters(SEEDS)) -> void:
	# Arrange
	var run := _gespielt(seed_wert, Difficulty.Level.MITTEL)

	# Act
	var fahrplan := ScheduleText.plan_lines(run)
	fahrplan.remove_at(0)
	var protokoll := ScheduleText.protocol_lines(run)

	# Assert
	assert_eq(run.difficulty, Difficulty.Level.MITTEL)
	_vergleiche(fahrplan, ORDNER + "fahrplan_uebernahme_seed_%d.txt" % seed_wert)
	_vergleiche(protokoll, ORDNER + "protokoll_uebernahme_seed_%d.txt" % seed_wert)


func test_leeres_profil_wie_die_grundlinie(seed_wert: int = use_parameters(SEEDS)) -> void:
	for grad: Difficulty.Level in [Difficulty.Level.SCHWER, Difficulty.Level.LEICHT]:
		# Arrange: Die Übernahme hat keinen Abschnitt profiles, das Profil ist leer.
		assert_eq(_catalog.get_profile(grad).modifiers.size(), 0, "Das Profil ist leer.")
		var run := _gespielt(seed_wert, grad)

		# Act
		var fahrplan := ScheduleText.plan_lines(run)
		fahrplan.remove_at(0)
		var protokoll := ScheduleText.protocol_lines(run)

		# Assert
		assert_eq(run.difficulty, grad)
		assert_eq(run.start_modifiers.size(), 0)
		_vergleiche(fahrplan, ORDNER + "fahrplan_uebernahme_seed_%d.txt" % seed_wert)
		_vergleiche(protokoll, ORDNER + "protokoll_uebernahme_seed_%d.txt" % seed_wert)


# --- Helfer -----------------------------------------------------------------------------------

## Ein Lauf mit der Übernahme und [param seed_wert], gespielt bis zum 31.12.1999. Ohne
## [param grad] wie in Feature 002, TimelineRun.new(catalog, seed); mit Grad ausdrücklich.
func _gespielt(seed_wert: int, grad: int = -1) -> TimelineRun:
	var run: TimelineRun
	if grad < 0:
		run = TimelineRun.new(_catalog, seed_wert)
	else:
		run = TimelineRun.new(_catalog, seed_wert, grad as Difficulty.Level)
	run.advance_to(TimelineRun.LAST_DAY)
	return run


## Vergleicht [param zeilen] Zeichen für Zeichen mit der Datei unter [param pfad]. Die Textausgabe
## schreibt jede Zeile mit print(), also mit einem Zeilenumbruch dahinter, auch hinter der letzten.
## Weicht etwas ab, nennt die Meldung die erste Zeile, die anders ist.
func _vergleiche(zeilen: PackedStringArray, pfad: String) -> void:
	assert_true(FileAccess.file_exists(pfad), "Die Grundlinie %s fehlt." % pfad)
	var erwartet := FileAccess.get_file_as_string(pfad)
	var ist := "\n".join(zeilen) + "\n"
	assert_eq(ist, erwartet, "Wie die Grundlinie %s. %s" % [pfad.get_file(),
		_erste_abweichung(ist, erwartet)])


## „Erste Abweichung in Zeile 12: …“ oder leer, wenn beide Texte gleich sind.
static func _erste_abweichung(ist: String, erwartet: String) -> String:
	if ist == erwartet:
		return ""
	var ist_zeilen := ist.split("\n")
	var erwartet_zeilen := erwartet.split("\n")
	for i in maxi(ist_zeilen.size(), erwartet_zeilen.size()):
		var a := ist_zeilen[i] if i < ist_zeilen.size() else "(keine Zeile)"
		var b := erwartet_zeilen[i] if i < erwartet_zeilen.size() else "(keine Zeile)"
		if a != b:
			return "Erste Abweichung in Zeile %d: ist „%s“, erwartet „%s“." % [i + 1, a, b]
	return ""
