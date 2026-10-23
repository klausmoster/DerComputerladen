extends GutTest

## Prüft die Textausgabe fahrplan_ausgabe.gd mit Grad (Feature 003, T012; contracts/zeitleiste.md,
## „Textausgabe“). Sie ist ein Skript für die Kommandozeile, kein Knoten. Der Test startet sie deshalb
## wie quickstart.md, Abschnitt 3: als eigenen Godot-Prozess mit OS.execute(), und vergleicht
## Ausgabe und Exit-Code.
##
## OS.execute() liefert mit read_stderr false nur stdout, mit true stdout und stderr zusammen. Was nur
## im zweiten Aufruf steht, kam also über stderr. Die erwartete Ausgabe rechnet der Test selbst mit
## TimelineRun und ScheduleText, so wird sie als Ganzes verglichen.

const AUSGABE := "res://tools/werkstatt/fahrplan_ausgabe.gd"
const GRADE := "res://test/fixtures/catalog_us1_grade.json"
const KAPUTT := "res://test/fixtures/catalog_us1_profil_kaputt.json"


func test_grad_schwer_in_kopfzeile_fahrplan_und_protokoll() -> void:
	# Arrange
	var erwartet := _lauf(GRADE, 4711, Difficulty.Level.SCHWER)

	# Act
	var fahrplan := _starte(["--seed", "4711", "--grad", "schwer", "--katalog", GRADE])
	var protokoll := _starte(["--seed", "4711", "--grad", "schwer", "--katalog", GRADE,
		"--protokoll"])

	# Assert
	assert_eq(fahrplan["exit"], 0)
	assert_eq(fahrplan["stdout"], _text(ScheduleText.plan_lines(erwartet)), "Der ganze Fahrplan.")
	assert_string_starts_with(fahrplan["stdout"], "# Seed 4711, Grad Schwer, bis 31.12.1999\n")
	assert_eq(fahrplan["stderr"], "", "Ein gültiger Katalog, keine Meldung.")
	assert_eq(protokoll["stdout"], _text(ScheduleText.protocol_lines(erwartet)))
	assert_string_starts_with(protokoll["stdout"], "31.12.1984  Grad  Reklamationswelle: "
		+ "Start-Modifikator „Anspruchsvolle Kunden“ (Schwer) +5 Prozentpunkte vom 01.01.1985 bis "
		+ "31.12.1999\n")


func test_ohne_grad_wie_mittel() -> void:
	# Arrange und Act (FR-006)
	var ohne := _starte(["--seed", "4711", "--katalog", GRADE])
	var mittel := _starte(["--seed", "4711", "--grad", "mittel", "--katalog", GRADE])

	# Assert
	assert_eq([ohne["exit"], mittel["exit"]], [0, 0])
	assert_eq(ohne["stdout"], mittel["stdout"], "Zeichen für Zeichen gleich.")
	assert_eq(ohne["stdout"], _text(ScheduleText.plan_lines(_lauf(GRADE, 4711,
		Difficulty.Level.MITTEL))))
	assert_string_starts_with(ohne["stdout"], "# Seed 4711, Grad Mittel, bis 31.12.1999\n")


func test_kaputtes_profil_nennt_jeden_weggelassenen_start_modifikator_einmal() -> void:
	# Arrange (US1, Szenario 6; FR-013)
	var erwartet := _lauf(KAPUTT, 4711, Difficulty.Level.SCHWER)

	# Act
	var ergebnis := _starte(["--seed", "4711", "--grad", "schwer", "--katalog", KAPUTT])

	# Assert: drei Meldungen auf stderr, jede genau einmal; die Ausgabe läuft mit dem dritten.
	assert_eq(ergebnis["exit"], 1)
	assert_eq(ergebnis["stderr"], "\n".join(PackedStringArray([
		"Fehler: Ereignis „lieferengpass“, Feld „monthly_chance“: Die Grundchance von 150 % liegt "
			+ "außerhalb von 0 % bis 100 %. Das Ereignis fehlt in der Ausgabe.",
		"Fehler: Profil „Schwer“, Start-Modifikator „geisterereignis“, Feld "
			+ "„profiles.schwer[0].event_id“: Das Ereignis „gibt_es_nicht“ gibt es im Katalog "
			+ "nicht. Der Start-Modifikator fehlt in der Ausgabe.",
		"Fehler: Profil „Schwer“, Start-Modifikator „lieferengpass“: Das Ereignis „lieferengpass“ "
			+ "wird übersprungen, deshalb auch dieser Start-Modifikator.",
	])) + "\n")
	assert_eq(ergebnis["stdout"], _text(ScheduleText.plan_lines(erwartet)))
	assert_eq(erwartet.start_modifiers.size(), 1, "Der erwartete Lauf hat nur den dritten.")


func test_unbekannter_grad_ist_ein_falsches_argument() -> void:
	# Arrange (FR-011): ein unbekannter Name, einer mit großem S und einer ohne Wert
	var faelle := {
		"extrem": "Fehler: Den Schwierigkeitsgrad „extrem“ gibt es nicht; erlaubt sind leicht, "
			+ "mittel und schwer.",
		"Schwer": "Fehler: Den Schwierigkeitsgrad „Schwer“ gibt es nicht; erlaubt sind leicht, "
			+ "mittel und schwer.",
		"": "Fehler: Nach --grad fehlt der Wert.",
	}

	for wert: String in faelle:
		# Act
		var argumente := ["--seed", "4711", "--katalog", GRADE, "--grad"]
		if not wert.is_empty():
			argumente.append(wert)
		var ergebnis := _starte(argumente)

		# Assert: Meldung und Aufrufhilfe mit --grad, kein Fahrplan
		assert_eq(ergebnis["exit"], 1, "„%s“: Exit-Code 1." % wert)
		assert_eq(ergebnis["stdout"], "", "„%s“: keine Ausgabe." % wert)
		var zeilen: PackedStringArray = ergebnis["stderr"].split("\n", false)
		assert_eq(zeilen.size(), 2, "„%s“: Meldung und Aufrufhilfe." % wert)
		if zeilen.size() == 2:
			assert_eq(zeilen[0], faelle[wert])
			assert_string_contains(zeilen[1], "[--grad leicht|mittel|schwer]")


# --- Helfer ---------------------------------------------------------------------------

## Startet die Textausgabe mit [param argumente] nach „--“ und gibt { "exit": int,
## "stdout": String, "stderr": String } zurück. Zweimal gestartet: einmal nur stdout, einmal mit
## stderr dazu; stderr ist, was der zweite Aufruf mehr hat. Die Textausgabe schreibt erst alle
## Meldungen, dann den Fahrplan, deshalb steht stderr vorn.
func _starte(argumente: Array) -> Dictionary:
	var aufruf := PackedStringArray(["--headless", "--no-header", "--path",
		ProjectSettings.globalize_path("res://"), "-s", AUSGABE, "--"])
	aufruf.append_array(PackedStringArray(argumente))
	var nur_stdout := []
	var exit := OS.execute(OS.get_executable_path(), aufruf, nur_stdout, false)
	var beides := []
	OS.execute(OS.get_executable_path(), aufruf, beides, true)
	var stdout: String = nur_stdout[0] if not nur_stdout.is_empty() else ""
	var zusammen: String = beides[0] if not beides.is_empty() else ""
	var stderr := zusammen.trim_suffix(stdout) if zusammen.ends_with(stdout) else zusammen
	return {"exit": exit, "stdout": stdout, "stderr": stderr}


## Der Lauf, den die Textausgabe rechnet: Katalog ohne Fehlerhaftes, bis zum 31.12.1999.
func _lauf(pfad: String, seed_wert: int, grad: Difficulty.Level) -> TimelineRun:
	var meldungen: Array[CatalogIssue] = []
	var katalog := EventCatalog.read_file(pfad, meldungen)
	meldungen.append_array(CatalogValidator.validate(katalog))
	var run := TimelineRun.new(katalog.without_faulty(meldungen), seed_wert, grad)
	run.advance_to(TimelineRun.LAST_DAY)
	return run


## Zeilen, wie print() sie schreibt: jede mit einem Zeilenumbruch dahinter.
func _text(zeilen: PackedStringArray) -> String:
	return "\n".join(zeilen) + "\n"
