extends GutTest

## Prüft Start-Modifikatoren und Profile für sich, ohne Katalogdatei (Feature 003, T003 und T004;
## contracts/zeitleiste.md, „ChanceModifier“ und „DifficultyProfile“):
## - ChanceModifier.from_dict() und to_dict() als Rundreise, jeder Strukturfehler V22 mit dem
##   bloßen Schlüssel als Feld und der Vorgabe aus data-model.md;
## - DifficultyProfile.from_list() mit Stelle und Ort in den Meldungen, to_list(), to_dict(),
##   field_prefix(), place() und faulty_indices();
## - die Chance je Grad und Zeitabschnitt, die das Formular nur zum Lesen zeigt (US2, Szenarien 6
##   und 7).
##
## Wie der Abschnitt „profiles“ in einer ganzen Katalogdatei gelesen wird, prüft
## test_event_catalog.gd.

## 01.01.1985 = 0, 31.12.1999 = 5477; der 01.01.1995 ist Tag 3652, der 01.01.1990 Tag 1826.
const LETZTER_TAG := 5477
const TAG_1990 := 1826
const TAG_1995 := 3652


# --- ChanceModifier lesen und schreiben ---------------------------------------------------------

func test_start_modifikator_hin_und_zurueck() -> void:
	# Arrange: das Beispiel aus contracts/ereigniskatalog.md
	var daten := _eintrag()
	var issues: Array[CatalogIssue] = []

	# Act
	var modifikator := ChanceModifier.from_dict(daten, issues)

	# Assert
	assert_eq(issues.size(), 0, "%s" % [issues])
	assert_eq([modifikator.id, modifikator.event_id, modifikator.reason],
		["reklamationswelle", "reklamationswelle", "Anspruchsvolle Kunden"])
	assert_eq([modifikator.from_day, modifikator.to_day], [0, LETZTER_TAG], "Tage als Tagesindex.")
	assert_eq(modifikator.value, 0.05)
	assert_eq(modifikator.to_dict(), daten, "Zurückgeschrieben steht er da wie in der Datei.")
	assert_eq(ChanceModifier.KEYS, ["event_id", "from_day", "id", "reason", "to_day", "value"])
	var schluessel := modifikator.to_dict().keys()
	schluessel.sort()
	assert_eq(schluessel, ChanceModifier.KEYS, "Genau die Schlüssel aus KEYS.")


func test_wert_steht_auf_vier_nachkommastellen() -> void:
	# Arrange
	var modifikator := ChanceModifier.new()
	modifikator.value = -0.123456
	modifikator.to_day = LETZTER_TAG

	# Act
	var daten := modifikator.to_dict()

	# Assert
	assert_eq(daten["value"], -0.1235, "Schreibregel 3: Anteile auf vier Nachkommastellen.")
	assert_eq([daten["from_day"], daten["to_day"]], ["1985-01-01", "1999-12-31"])


func test_fehlende_schluessel_ergeben_v22_und_die_vorgaben() -> void:
	# Arrange: ein leerer Eintrag
	var issues: Array[CatalogIssue] = []

	# Act
	var modifikator := ChanceModifier.from_dict({}, issues)

	# Assert: je Schlüssel eine Meldung mit dem bloßen Schlüssel als Feld, noch ohne Ort.
	assert_eq(_felder(issues), ["event_id", "from_day", "id", "reason", "to_day", "value"])
	for issue in issues:
		assert_eq([issue.rule, issue.severity, issue.event_id],
			["V22", CatalogIssue.Severity.ERROR, ""])
		assert_eq(issue.message, "Der Schlüssel fehlt.", "Den Ort setzt erst from_list().")
	# Die Vorgaben aus data-model.md: das ganze Spiel, Wert 0, alles Übrige leer.
	assert_eq([modifikator.from_day, modifikator.to_day], [0, LETZTER_TAG],
		"Ohne Ende gilt er bis Spielende, nicht −1.")
	assert_eq([modifikator.value, modifikator.reason, modifikator.event_id, modifikator.id],
		[0.0, "", "", ""])


func test_falscher_typ_ergibt_v22_und_die_vorgabe() -> void:
	# Arrange (data-model.md, V22): ein Text als Wert, eine Zahl als Datum, eine Zahl als Kennung
	var daten := _eintrag({"value": "0,05", "from_day": 5, "id": 7, "reason": true})
	var issues: Array[CatalogIssue] = []

	# Act
	var modifikator := ChanceModifier.from_dict(daten, issues)

	# Assert
	assert_eq(_felder(issues), ["from_day", "id", "reason", "value"], "%s" % [issues])
	assert_eq(_texte(issues), [
		"Erwartet wird ein Datum als Text, in der Datei steht die Zahl 5.",
		"Erwartet wird ein Text, in der Datei steht die Zahl 7.",
		"Erwartet wird ein Text, in der Datei steht true.",
		"Erwartet wird eine Zahl, in der Datei steht der Text „0,05“.",
	])
	assert_eq([modifikator.from_day, modifikator.id, modifikator.reason, modifikator.value],
		[0, "", "", 0.0], "Je Feld die Vorgabe.")
	assert_eq(modifikator.event_id, "reklamationswelle", "Was lesbar ist, bleibt.")


func test_datum_ohne_kalendertag_ist_v22() -> void:
	# Arrange: den 30. Februar gibt es nicht, einen Monat 13 auch nicht.
	var daten := _eintrag({"from_day": "1990-02-30", "to_day": "1999-13-01"})
	var issues: Array[CatalogIssue] = []

	# Act
	var modifikator := ChanceModifier.from_dict(daten, issues)

	# Assert
	assert_eq(_felder(issues), ["from_day", "to_day"])
	assert_eq(_texte(issues), [
		"„1990-02-30“ ist kein Kalendertag in der Form JJJJ-MM-TT.",
		"„1999-13-01“ ist kein Kalendertag in der Form JJJJ-MM-TT.",
	])
	assert_eq([modifikator.from_day, modifikator.to_day], [0, LETZTER_TAG])


func test_unbekannter_schluessel_ist_v22_und_faellt_beim_schreiben_weg() -> void:
	# Arrange
	var daten := _eintrag({"farbe": "rot"})
	var issues: Array[CatalogIssue] = []

	# Act
	var modifikator := ChanceModifier.from_dict(daten, issues)

	# Assert
	assert_eq(_felder(issues), ["farbe"])
	assert_eq(_texte(issues), ["Diesen Schlüssel kennt der Katalog nicht."])
	assert_false(modifikator.to_dict().has("farbe"), "Der Katalog behält den Schlüssel nicht.")


# --- Profil lesen und schreiben -----------------------------------------------------------------

func test_profil_hin_und_zurueck() -> void:
	# Arrange: zwei Start-Modifikatoren, absichtlich nicht nach Kennung geordnet
	var konkurrent := _eintrag({"event_id": "konkurrent_eroeffnet", "id": "konkurrent_eroeffnet",
		"from_day": "1995-01-01", "reason": "Die Ketten kommen", "value": 0.03})
	var liste := [_eintrag(), konkurrent]
	var issues: Array[CatalogIssue] = []

	# Act
	var profil := DifficultyProfile.from_list(Difficulty.Level.SCHWER, liste, issues)

	# Assert
	assert_eq(issues.size(), 0, "%s" % [issues])
	assert_eq(profil.level, Difficulty.Level.SCHWER)
	assert_eq(_kennungen(profil), ["reklamationswelle", "konkurrent_eroeffnet"],
		"Die Reihenfolge der Datei bleibt (R2).")
	assert_eq(profil.modifiers[1].from_day, TAG_1995)
	assert_eq(profil.to_list(), liste, "to_list() schreibt die Liste der Datei.")
	assert_eq(profil.to_dict(), {"schwer": liste}, "to_dict() nennt den Grad als Schlüssel.")
	assert_eq(DifficultyProfile.new().to_dict(), {"leicht": []}, "Ein leeres Profil, Leicht.")


func test_kopie_ist_tief_und_gleich() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []
	var profil := DifficultyProfile.from_list(Difficulty.Level.LEICHT,
		[_eintrag({"value": -0.02})], issues)

	# Act
	var kopie := profil.duplicate_profile()
	kopie.modifiers[0].value = 0.5

	# Assert
	assert_ne(kopie, profil, "Ein neues Objekt.")
	assert_eq(kopie.level, Difficulty.Level.LEICHT)
	assert_eq(profil.modifiers[0].value, -0.02, "Die Kopie teilt keinen Start-Modifikator.")
	assert_eq(profil.duplicate_profile().to_list(), profil.to_list())


func test_meldungen_beim_lesen_nennen_stelle_und_ort() -> void:
	# Arrange: an Stelle 1 ein Wert als Text, an Stelle 2 kein Objekt, an Stelle 3 eine Kennung,
	# die keine ist.
	var liste := [_eintrag(), _eintrag({"value": "fünf"}), 5, _eintrag({"id": 3})]
	var issues: Array[CatalogIssue] = []

	# Act
	var profil := DifficultyProfile.from_list(Difficulty.Level.SCHWER, liste, issues)

	# Assert: das volle Feld wie in der Datei, leeres event_id, der Ort aus place() im Text.
	assert_eq(_felder(issues), ["profiles.schwer[1].value", "profiles.schwer[2]",
		"profiles.schwer[3].id"], "%s" % [issues])
	assert_eq(_texte(issues), [
		"Profil „Schwer“, Start-Modifikator „reklamationswelle“, Feld „profiles.schwer[1].value“: "
			+ "Erwartet wird eine Zahl, in der Datei steht der Text „fünf“.",
		"Profil „Schwer“, Start-Modifikator Nr. 3 ohne Kennung, Feld „profiles.schwer[2]“: "
			+ "Erwartet wird ein Objekt, in der Datei steht die Zahl 5.",
		"Profil „Schwer“, Start-Modifikator Nr. 4 ohne Kennung, Feld „profiles.schwer[3].id“: "
			+ "Erwartet wird ein Text, in der Datei steht die Zahl 3.",
	])
	for issue in issues:
		assert_eq([issue.rule, issue.event_id], ["V22", ""], "Kein Ereignis: %s" % issue)
	# Jeder Eintrag behält seine Stelle, auch der, der kein Objekt war, mit den Vorgaben.
	assert_eq(profil.modifiers.size(), 4, "Die Stellen passen zu den Feldern der Meldungen.")
	var vorgabe := profil.modifiers[2]
	assert_eq([vorgabe.id, vorgabe.event_id, vorgabe.value, vorgabe.reason], ["", "", 0.0, ""])
	assert_eq([vorgabe.from_day, vorgabe.to_day], [0, LETZTER_TAG])


func test_profil_das_keine_liste_ist_bleibt_leer() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []

	# Act
	var profil := DifficultyProfile.from_list(Difficulty.Level.LEICHT, {"a": 1}, issues)

	# Assert
	assert_eq(profil.modifiers.size(), 0)
	assert_eq(_felder(issues), ["profiles.leicht"])
	assert_eq(_texte(issues), ["Profil „Leicht“, Feld „profiles.leicht“: Erwartet wird eine Liste, "
		+ "in der Datei steht ein Objekt."])


func test_feldanfang_und_ort() -> void:
	# Arrange
	var mit_kennung := ChanceModifier.new()
	mit_kennung.id = "reklamationswelle"
	var ohne_kennung := ChanceModifier.new()

	# Assert
	assert_eq(DifficultyProfile.field_prefix(Difficulty.Level.SCHWER, 2), "profiles.schwer[2].")
	assert_eq(DifficultyProfile.field_prefix(Difficulty.Level.LEICHT, 0), "profiles.leicht[0].")
	assert_eq(DifficultyProfile.place(Difficulty.Level.SCHWER, 2, mit_kennung),
		"Profil „Schwer“, Start-Modifikator „reklamationswelle“")
	assert_eq(DifficultyProfile.place(Difficulty.Level.SCHWER, 2, ohne_kennung),
		"Profil „Schwer“, Start-Modifikator Nr. 3 ohne Kennung", "Gezählt ab 1.")
	assert_eq(DifficultyProfile.place(Difficulty.Level.LEICHT, 0, null),
		"Profil „Leicht“, Start-Modifikator Nr. 1 ohne Kennung")


# --- Fehlerhafte Stellen ------------------------------------------------------------------------

func test_fehlerhafte_stellen_nach_ganzen_pfadteilen() -> void:
	# Arrange: je eine Meldung an einem Feld, an einem ganzen Eintrag, an einem Feld mit Punkt, an
	# einem Tippfehler im Grad, am Profil und an Leicht, dazu eine Warnung.
	var issues: Array[CatalogIssue] = [
		_meldung("profiles.schwer[2].reason"),
		_meldung("profiles.schwer[0]"),
		_meldung("profiles.schwer[11].window.from"),
		_meldung("profiles.schwerr[1].value"),
		_meldung("profiles.schwer"),
		_meldung("profiles.schwer[3]x"),
		_meldung("profiles.schwer[04].value"),
		_meldung("profiles.leicht[5].value"),
		_meldung("profiles.schwer[7].from_day", CatalogIssue.Severity.WARNING),
	]

	# Act
	var schwer := DifficultyProfile.faulty_indices(issues, Difficulty.Level.SCHWER)
	var leicht := DifficultyProfile.faulty_indices(issues, Difficulty.Level.LEICHT)

	# Assert
	assert_eq(_sortiert(schwer.keys()), [0, 2, 11], "Feld, ganzer Eintrag und tieferes Feld.")
	assert_eq(schwer.get(0), true, "Je Stelle { index: true }.")
	assert_eq(leicht.keys(), [5], "Meldungen zu Schwer zählen für Leicht nicht.")
	assert_eq(DifficultyProfile.faulty_indices(issues, Difficulty.Level.MITTEL), {},
		"Mittel hat kein Profil.")


# --- Chance je Zeitabschnitt --------------------------------------------------------------------

func test_us2_szenario_6_chance_je_grad() -> void:
	# Arrange: Reklamationswelle mit 3 %, Leicht −2 und Schwer +5, beide das ganze Spiel.
	var welle := _ereignis(0.03)
	var leicht := _profil(Difficulty.Level.LEICHT, [_modifikator(-0.02)])
	var schwer := _profil(Difficulty.Level.SCHWER, [_modifikator(0.05)])

	# Act und Assert
	assert_eq(_beschreibung(welle, leicht), "1 %")
	assert_eq(_beschreibung(welle, null), "3 %", "Mittel ist die Grundchance.")
	assert_eq(_beschreibung(welle, schwer), "8 %")
	var abschnitte := DifficultyProfile.chance_periods(welle, null)
	assert_eq(abschnitte.size(), 1, "Mittel hat einen Abschnitt.")
	assert_eq([abschnitte[0]["from_day"], abschnitte[0]["to_day"]], [0, LETZTER_TAG])
	assert_almost_eq(float(abschnitte[0]["chance"]), 0.03, 1e-9)


func test_us2_szenario_7_chance_ab_1995() -> void:
	# Arrange: Konkurrent eröffnet mit 3 %, Schwer +3 vom 01.01.1995 bis 31.12.1999.
	var konkurrent := _ereignis(0.03)
	var schwer := _profil(Difficulty.Level.SCHWER, [_modifikator(0.03, TAG_1995)])

	# Act
	var abschnitte := DifficultyProfile.chance_periods(konkurrent, schwer)

	# Assert
	assert_eq(DifficultyProfile.describe_periods(abschnitte),
		"3 % bis 31.12.1994, 6 % ab 01.01.1995")
	assert_eq(abschnitte.size(), 2)
	assert_eq([abschnitte[0]["from_day"], abschnitte[0]["to_day"]], [0, TAG_1995 - 1])
	assert_eq([abschnitte[1]["from_day"], abschnitte[1]["to_day"]], [TAG_1995, LETZTER_TAG])


func test_drei_abschnitte_und_gleiche_nachbarn_zusammengelegt() -> void:
	# Arrange: +2 von 1990 bis 1994, dazu zwei Modifikatoren, die sich genau aufheben, und einer
	# auf ein anderes Ereignis.
	var welle := _ereignis(0.03)
	var anderes := _modifikator(0.4, 0, LETZTER_TAG)
	anderes.event_id = "lieferengpass"
	var schwer := _profil(Difficulty.Level.SCHWER, [
		_modifikator(0.02, TAG_1990, TAG_1995 - 1),
		_modifikator(0.01, 100, 200),
		_modifikator(-0.01, 100, 200),
		anderes,
	])

	# Act
	var abschnitte := DifficultyProfile.chance_periods(welle, schwer)

	# Assert
	assert_eq(DifficultyProfile.describe_periods(abschnitte),
		"3 % bis 31.12.1989, 5 % vom 01.01.1990 bis 31.12.1994, 3 % ab 01.01.1995")
	assert_eq(abschnitte.size(), 3, "Nur echte Wechsel; +1 und −1 ergeben keinen.")


func test_mehrere_addieren_sich_mit_teilweise_ueberlappenden_zeitraeumen() -> void:
	# Arrange: +1 ab 1990, +1,5 ab 1995; ab 1995 gelten beide.
	var welle := _ereignis(0.025)
	var schwer := _profil(Difficulty.Level.SCHWER, [
		_modifikator(0.01, TAG_1990),
		_modifikator(0.015, TAG_1995),
	])

	# Act und Assert
	assert_eq(_beschreibung(welle, schwer),
		"2,5 % bis 31.12.1989, 3,5 % vom 01.01.1990 bis 31.12.1994, 5 % ab 01.01.1995",
		"Deutsches Komma, höchstens zwei Nachkommastellen.")


func test_begrenzt_auf_0_und_100_prozent() -> void:
	# Arrange
	var welle := _ereignis(0.03)
	var leicht := _profil(Difficulty.Level.LEICHT, [_modifikator(-0.05)])
	var schwer := _profil(Difficulty.Level.SCHWER, [_modifikator(0.6), _modifikator(0.6)])

	# Act und Assert
	assert_eq(_beschreibung(welle, leicht), "0 %", "Nie unter 0 %.")
	assert_eq(_beschreibung(welle, schwer), "100 %", "Nie über 100 %.")


func test_zeitraum_ausserhalb_des_spiels_ist_begrenzt() -> void:
	# Arrange: vor 1985 bis 1989 und von 1995 bis nach 1999
	var welle := _ereignis(0.03)
	var schwer := _profil(Difficulty.Level.SCHWER, [
		_modifikator(0.01, -400, TAG_1990 - 1),
		_modifikator(0.02, TAG_1995, LETZTER_TAG + 400),
	])

	# Act
	var abschnitte := DifficultyProfile.chance_periods(welle, schwer)

	# Assert
	assert_eq(abschnitte[0]["from_day"], 0, "Der erste Abschnitt beginnt am 01.01.1985.")
	assert_eq(abschnitte[-1]["to_day"], LETZTER_TAG, "Der letzte endet am 31.12.1999.")
	assert_eq(DifficultyProfile.describe_periods(abschnitte),
		"4 % bis 31.12.1989, 3 % vom 01.01.1990 bis 31.12.1994, 5 % ab 01.01.1995")


func test_fehlerhafte_zaehlen_nicht() -> void:
	# Arrange: Stelle 1 hat einen Fehler, etwa einen leeren Grund (V29); das Formular gibt dafür
	# faulty_indices() mit.
	var welle := _ereignis(0.03)
	var schwer := _profil(Difficulty.Level.SCHWER, [_modifikator(0.05), _modifikator(0.2)])
	var issues: Array[CatalogIssue] = [_meldung("profiles.schwer[1].reason")]
	var fehlerhaft := DifficultyProfile.faulty_indices(issues, Difficulty.Level.SCHWER)

	# Act
	var abschnitte := DifficultyProfile.chance_periods(welle, schwer, fehlerhaft)

	# Assert
	assert_eq(DifficultyProfile.describe_periods(abschnitte), "8 %", "Wie im Spiel: nur Stelle 0.")
	assert_eq(_beschreibung(welle, schwer), "28 %", "Ohne skip zählt auch Stelle 1.")


func test_ohne_abschnitte_kein_text() -> void:
	var keine: Array[Dictionary] = []
	assert_eq(DifficultyProfile.describe_periods(keine), "")
	assert_eq(DifficultyProfile.chance_periods(null, null).size(), 0, "Ohne Ereignis nichts.")


# --- Helfer -----------------------------------------------------------------------------------

## Ein Start-Modifikator, wie er in der Datei steht: Schwer +5 auf die Reklamationswelle, das ganze
## Spiel. [param overrides] ersetzt oder ergänzt Schlüssel.
func _eintrag(overrides: Dictionary = {}) -> Dictionary:
	var daten := {
		"event_id": "reklamationswelle", "from_day": "1985-01-01", "id": "reklamationswelle",
		"reason": "Anspruchsvolle Kunden", "to_day": "1999-12-31", "value": 0.05,
	}
	daten.merge(overrides, true)
	return daten


## Ein Ereignis über Wahrscheinlichkeit mit der Kennung reklamationswelle.
func _ereignis(grundchance: float) -> TimelineEvent:
	var event := TimelineEvent.new()
	event.id = "reklamationswelle"
	event.kind = TimelineEvent.Kind.CHANCE
	event.monthly_chance = grundchance
	return event


## Ein Start-Modifikator auf die Reklamationswelle; ohne Zeitraum das ganze Spiel.
func _modifikator(wert: float, von: int = 0, bis: int = LETZTER_TAG) -> ChanceModifier:
	var modifikator := ChanceModifier.new()
	modifikator.id = "welle_%d" % von
	modifikator.event_id = "reklamationswelle"
	modifikator.reason = "Test"
	modifikator.value = wert
	modifikator.from_day = von
	modifikator.to_day = bis
	return modifikator


func _profil(grad: Difficulty.Level, modifikatoren: Array[ChanceModifier]) -> DifficultyProfile:
	var profil := DifficultyProfile.new(grad)
	profil.modifiers = modifikatoren
	return profil


func _beschreibung(event: TimelineEvent, profil: DifficultyProfile) -> String:
	return DifficultyProfile.describe_periods(DifficultyProfile.chance_periods(event, profil))


## Eine Meldung V22 an [param feld], wie sie beim Lesen oder Prüfen entsteht.
func _meldung(feld: String,
		stufe: CatalogIssue.Severity = CatalogIssue.Severity.ERROR) -> CatalogIssue:
	return CatalogIssue.new(stufe, "V22", "", feld, "Test")


func _kennungen(profil: DifficultyProfile) -> Array:
	return profil.modifiers.map(func(modifikator: ChanceModifier) -> String: return modifikator.id)


func _felder(issues: Array[CatalogIssue]) -> Array:
	var felder := []
	for issue in issues:
		felder.append(issue.field)
	return felder


func _texte(issues: Array[CatalogIssue]) -> Array:
	var texte := []
	for issue in issues:
		texte.append(issue.message)
	return texte


func _sortiert(werte: Array) -> Array:
	var kopie := werte.duplicate()
	kopie.sort()
	return kopie
