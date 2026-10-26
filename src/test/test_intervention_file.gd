extends GutTest

## Prüft InterventionFile (Feature 004, T003; research.md, R5): die Umrechnung der Einträge im
## Eingriffsprotokoll zwischen Speicher und Datei, die Prüfung auf falsche Daten und die beiden
## Hilfen für Zahlen und Meldungen. Spielstand und Was-wäre-wenn-Probe schreiben Eingriffe beide
## hierüber; dass die Proben dabei Byte für Byte gleich bleiben, prüft test_what_if_probe.gd.
##
## Die Tests brauchen weder Katalog noch Lauf noch Dateien: Ein Eintrag ist ein Dictionary.

## Tag −1: vor Spielbeginn, in der Datei der 31.12.1984.
const VOR_DEM_START := -1


# --- Umrechnung -----------------------------------------------------------------------

func test_rundreise_speicher_datei_speicher() -> void:
	# Arrange: eine Verschiebung am 01.01.1992 und ein Modifikator vor Spielbeginn, wie sie in
	# TimelineRun.interventions stehen, mit Tagesindizes.
	var verschiebung := {"at_day": _tag(1992, 1, 1), "day": _tag(1992, 6, 1),
		"event_id": "konkurrent_eroeffnet", "kind": "move", "new_day": _tag(1992, 9, 1),
		"reason": "Bauarbeiten"}
	var modifikator := {"at_day": VOR_DEM_START, "kind": "add_modifier", "modifier": {
		"event_id": "reklamationswelle", "from_day": _tag(1990, 1, 1), "id": "windiger_haendler",
		"reason": "Ware vom windigen Händler", "to_day": _tag(1993, 12, 31), "value": 0.05}}
	var vorher := [verschiebung.duplicate(true), modifikator.duplicate(true)]

	# Act
	var datei_verschiebung := InterventionFile.to_file(verschiebung)
	var datei_modifikator := InterventionFile.to_file(modifikator)
	var zurueck := [InterventionFile.from_file(datei_verschiebung),
		InterventionFile.from_file(datei_modifikator)]

	# Assert: In der Datei stehen Tage als „JJJJ-MM-TT“, alles andere bleibt.
	assert_eq(datei_verschiebung, {"at_day": "1992-01-01", "day": "1992-06-01",
		"event_id": "konkurrent_eroeffnet", "kind": "move", "new_day": "1992-09-01",
		"reason": "Bauarbeiten"})
	assert_eq(datei_modifikator, {"at_day": "1984-12-31", "kind": "add_modifier", "modifier": {
		"event_id": "reklamationswelle", "from_day": "1990-01-01", "id": "windiger_haendler",
		"reason": "Ware vom windigen Händler", "to_day": "1993-12-31", "value": 0.05}},
		"Auch die Tage im Modifikator.")
	assert_eq(zurueck, [verschiebung, modifikator], "Zurück ergibt dieselben Einträge.")
	assert_eq(typeof(zurueck[0]["day"]), TYPE_INT, "Wieder als ganze Zahl.")
	assert_eq([verschiebung, modifikator], vorher, "Die Einträge selbst bleiben, wie sie waren.")


func test_minus_eins_steht_als_31_12_1984() -> void:
	# Act
	var datei := InterventionFile.to_file({"at_day": VOR_DEM_START, "kind": "cancel"})

	# Assert
	assert_eq(datei["at_day"], "1984-12-31", "−1 ist der Tag vor dem 01.01.1985.")
	assert_eq(InterventionFile.from_file(datei)["at_day"], VOR_DEM_START)
	assert_eq(InterventionFile.to_file({"at_day": 2556.0})["at_day"], "1992-01-01",
		"Ein Tag aus einer Datei kommt als float; als ganze Zahl wird er umgerechnet.")


func test_was_kein_tag_ist_bleibt_beim_schreiben_stehen() -> void:
	# Arrange: ein Tag als Text oder mit Nachkomma, dazu ein unbekannter Schlüssel. Umrechnen lässt
	# sich nur eine ganze Zahl; den Rest lehnt apply_intervention() ab.
	var eintrag := {"at_day": "gestern", "day": 400.5, "nr": 7}

	# Act
	var datei := InterventionFile.to_file(eintrag)

	# Assert
	assert_eq(datei, {"at_day": "gestern", "day": 400.5, "nr": 7})


func test_wert_steht_auf_vier_nachkommastellen() -> void:
	# Arrange: ein Anteil mit mehr Stellen, wie im Katalog auf vier gerundet
	var eintrag := {"at_day": VOR_DEM_START, "kind": "add_modifier",
		"modifier": {"id": "krumm", "value": 0.123456}}

	# Act
	var datei := InterventionFile.to_file(eintrag)

	# Assert
	assert_eq(datei["modifier"]["value"], 0.1235, "Auf vier Nachkommastellen gerundet.")
	assert_eq(eintrag["modifier"]["value"], 0.123456, "Gerundet wird nur in der Kopie.")
	assert_eq(typeof(InterventionFile.to_file({"value": 1})["value"]), TYPE_FLOAT,
		"Ein Wert ist ein Anteil, also immer eine Kommazahl.")
	assert_eq(InterventionFile.to_file({"value": "0,05"})["value"], "0,05",
		"Ein Text bleibt; ihn lehnt apply_intervention() ab.")


# --- Falsches Datum -------------------------------------------------------------------

func test_falsches_datum_mit_satz() -> void:
	# Arrange: je Fall der Eintrag aus der Datei und der Satz dazu
	var faelle := [
		[{"at_day": "1992-01-01", "day": "1992-02-30", "kind": "cancel"},
			"Bei „day“ steht „1992-02-30“, kein gültiges Datum JJJJ-MM-TT."],
		[{"at_day": "1985-01-01", "day": 400.0, "kind": "schedule"},
			"Bei „day“ steht 400, kein gültiges Datum JJJJ-MM-TT."],
		[{"at_day": "1992-1-1", "kind": "cancel"},
			"Bei „at_day“ steht „1992-1-1“, kein gültiges Datum JJJJ-MM-TT."],
		[{"new_day": 1.5}, "Bei „new_day“ steht 1.5, kein gültiges Datum JJJJ-MM-TT."],
	]

	# Act und Assert
	for fall: Array in faelle:
		assert_eq(InterventionFile.wrong_date(fall[0]), fall[1], "%s" % [fall[0]])


func test_falsches_datum_im_modifikator() -> void:
	# Arrange: Der Eintrag selbst stimmt, nur Beginn bzw. Ende des Modifikators darin nicht.
	var ohne_beginn := {"at_day": "1984-12-31", "kind": "add_modifier",
		"modifier": {"from_day": true, "id": "krumm", "to_day": "1999-12-31", "value": 0.05}}
	var ende_im_februar := {"at_day": "1984-12-31", "kind": "add_modifier",
		"modifier": {"from_day": "1990-01-01", "id": "krumm", "to_day": "1993-02-29"}}

	# Act und Assert
	assert_eq(InterventionFile.wrong_date(ohne_beginn),
		"Bei „from_day“ steht true, kein gültiges Datum JJJJ-MM-TT.")
	assert_eq(InterventionFile.wrong_date(ende_im_februar),
		"Bei „to_day“ steht „1993-02-29“, kein gültiges Datum JJJJ-MM-TT.",
		"1993 ist kein Schaltjahr.")


func test_richtige_und_fehlende_daten_sind_kein_fehler() -> void:
	# Arrange: Ein fehlender Tag ist kein falsches Datum; über ihn entscheidet apply_intervention().
	# Zahlen unter anderen Schlüsseln sind keine Tage.
	var richtig := {"at_day": "1984-12-31", "day": "1992-02-29", "kind": "schedule", "value": 3,
		"modifier": {"from_day": "1990-01-01", "to_day": "1999-12-31", "value": 0.05}}

	# Act und Assert
	assert_eq(InterventionFile.wrong_date(richtig), "")
	assert_eq(InterventionFile.wrong_date({"kind": "cancel"}), "", "Ohne Tage.")
	assert_eq(InterventionFile.wrong_date({}), "")


# --- Hilfen ---------------------------------------------------------------------------

func test_is_date_nur_fuer_kalendertage_als_text() -> void:
	assert_eq(InterventionFile.DATE_KEYS, ["at_day", "day", "new_day", "from_day", "to_day"])
	assert_true(InterventionFile.is_date("1992-02-29"), "1992 ist ein Schaltjahr.")
	assert_true(InterventionFile.is_date("1984-12-31"), "Auch vor 1985.")
	assert_false(InterventionFile.is_date("1993-02-29"))
	assert_false(InterventionFile.is_date("1992-2-29"), "Nur mit zwei Stellen für den Monat.")
	assert_false(InterventionFile.is_date(2556), "Ein Tagesindex ist kein Datum.")
	assert_false(InterventionFile.is_date(null))


func test_is_whole_number_auch_als_float_ohne_nachkomma() -> void:
	assert_true(InterventionFile.is_whole_number(3))
	assert_true(InterventionFile.is_whole_number(3.0), "Aus JSON kommt jede Zahl als float.")
	assert_true(InterventionFile.is_whole_number(-1.0))
	assert_false(InterventionFile.is_whole_number(3.5))
	assert_false(InterventionFile.is_whole_number(1e16), "Zu groß für verlässliche Stellen.")
	assert_false(InterventionFile.is_whole_number("3"), "Ein Text ist keine Zahl.")
	assert_false(InterventionFile.is_whole_number(true))
	assert_false(InterventionFile.is_whole_number(null))


func test_shown_zeigt_text_in_anfuehrungszeichen_und_ganze_zahlen_ohne_nachkomma() -> void:
	assert_eq(InterventionFile.shown("extrem"), "„extrem“")
	assert_eq(InterventionFile.shown(400.0), "400")
	assert_eq(InterventionFile.shown(-1), "-1")
	assert_eq(InterventionFile.shown(1.5), "1.5")
	assert_eq(InterventionFile.shown(true), "true")


# --- Helfer ---------------------------------------------------------------------------

## Tagesindex eines Datums.
func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()
