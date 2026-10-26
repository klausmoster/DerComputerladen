extends GutTest

## Prüft den Lauf mit Schwierigkeitsgrad (Feature 003, T010; contracts/zeitleiste.md, „Der Lauf“):
## Die Start-Modifikatoren des Profils gelten vor der ersten Würfelrunde, sie verschieben nur
## Schwellen, Seed und Würfel hängen nicht am Grad, und sie stehen im Protokoll, nicht im
## Eingriffsprotokoll.
##
## Grundlage ist catalog_us1_grade: die Reklamationswelle mit 3 % pro Monat und ihrer Folge, die
## Kundenflucht mit einer Bedingung auf sie, der Lieferengpass mit 4 %, auf den kein Profil zeigt,
## dazu ein fixes, ein jährliches und ein beim Start gesetztes Ereignis. Leicht hat −2, Schwer +5
## Prozentpunkte auf die Reklamationswelle, beide für das ganze Spiel.

const ORDNER := "res://test/fixtures/"
const GRADE := "catalog_us1_grade"
const KAPUTT := "catalog_us1_profil_kaputt"
const LETZTER_TAG := TimelineRun.LAST_DAY
const LEICHT := Difficulty.Level.LEICHT
const MITTEL := Difficulty.Level.MITTEL
const SCHWER := Difficulty.Level.SCHWER
## Die Reklamationswelle und was über Folge oder Bedingung von ihr abhängt, wie VON_REKLAMATION in
## test_schedule_diff.gd. Der Test bildet die Hülle selbst aus dem Katalog und vergleicht sie damit.
const VON_REKLAMATION := ["kundenflucht", "reklamationswelle", "zeitungsartikel_reklamation"]

var _grade: EventCatalog


func before_all() -> void:
	_grade = _katalog(GRADE)


# --- US1, Szenarien 1, 3, 4 und 7 ----------------------------------------------------

func test_szenario_1_schwer_wuerfelt_die_reklamationswelle_mit_acht_prozent() -> void:
	# Arrange
	var run := TimelineRun.new(_grade, 4711, SCHWER)

	# Act
	run.advance_to(LETZTER_TAG)

	# Assert: in jeder Würfelrunde 8 %, und jeder gewürfelte Termin nennt es in der Begründung.
	for monat in TimelineRun.MONTHS:
		var info := run.chance_info("reklamationswelle", _monatserster(monat))
		assert_almost_eq(info["effective"], 0.08, 1e-9, "Monat %d: 3 %% + 5." % monat)
	var termine := _gewuerfelt(run, "reklamationswelle")
	assert_gt(termine.size(), 0, "Mit 8 % kommt in 15 Jahren mindestens ein Termin.")
	for termin in termine:
		assert_almost_eq(termin.threshold, 0.08, 1e-9)
		assert_eq(termin.base_chance, 0.03, "Die Grundchance bleibt die des Katalogs.")
		assert_string_contains(termin.explain(),
			"Schwelle 0,0800 (3 % + Schwer: Anspruchsvolle Kunden +5)")


func test_szenario_3_derselbe_seed_und_grad_ergeben_dasselbe_spiel() -> void:
	# Arrange und Act
	var a := _gespielt(_grade, 4711, SCHWER)
	var b := _gespielt(_grade, 4711, SCHWER)

	# Assert
	assert_eq(_ausgabe(a), _ausgabe(b))
	assert_eq(a.difficulty, SCHWER)


func test_szenario_4_mittel_und_schwer_unterscheiden_sich_nur_bei_abhaengigen() -> void:
	# Arrange
	var mittel := _gespielt(_grade, 4711, MITTEL)
	var schwer := _gespielt(_grade, 4711, SCHWER)

	# Act
	var diff := ScheduleDiff.compare(mittel, schwer)

	# Assert
	var huelle := _huelle(_grade, [SCHWER])
	var markiert := _markiert(diff, schwer)
	assert_gt(markiert.size() + diff.removed.size(), 0,
		"Mit Seed 4711 ändert Schwer etwas; der Vergleich unten sagt also etwas.")
	for zeile: String in markiert:
		assert_true(huelle.has(zeile.get_slice(" ", 1)), "%s hängt von der Reklamationswelle ab."
			% zeile)
	for termin in diff.removed:
		assert_true(huelle.has(termin.event.id), "%s hängt von der Reklamationswelle ab."
			% termin.event.id)


func test_szenario_7_start_modifikator_und_eingriff_addieren_sich() -> void:
	# Arrange: Schwer +5 und später ein Eingriff −6 Prozentpunkte auf die Reklamationswelle
	var run := TimelineRun.new(_grade, 4711, SCHWER)
	run.advance_to(_tag(1990, 1, 15))
	var minus := _modifikator("rueckruf", "reklamationswelle", -0.06, "Rückrufaktion",
		_tag(1990, 2, 1), LETZTER_TAG)

	# Act
	var ergebnis := run.add_modifier(minus)

	# Assert
	assert_eq(ergebnis, OK, run.last_refusal)
	var vorher := run.chance_info("reklamationswelle", _tag(1990, 1, 1))
	var nachher := run.chance_info("reklamationswelle", _tag(1990, 2, 1))
	assert_almost_eq(vorher["effective"], 0.08, 1e-9, "Vor dem Eingriff 3 % + 5.")
	assert_almost_eq(nachher["sum"], 0.02, 1e-9, "+5 und −6 sind −1 Punkt.")
	assert_almost_eq(nachher["effective"], 0.02, 1e-9, "Die wirksame Chance ist 2 %.")


# --- SC-001 und SC-002 --------------------------------------------------------------

func test_sc_001_hundert_wiederholungen_ergeben_denselben_fahrplan() -> void:
	# Arrange
	var erste := _ausgabe(_gespielt(_grade, 4711, SCHWER))
	var gleich := 0

	# Act
	for i in 100:
		if _ausgabe(_gespielt(_grade, 4711, SCHWER)) == erste:
			gleich += 1

	# Assert
	assert_eq(gleich, 100, "100 von 100 Wiederholungen gleichen der ersten.")


func test_sc_002_hundert_seeds_unterscheiden_sich_nur_in_der_huelle() -> void:
	# Arrange: Die Hülle bildet der Test aus dem Katalog (data-model.md, „Abhängige Ereignisse“).
	var huelle := _huelle(_grade, [SCHWER])
	assert_eq(_sortiert(huelle), VON_REKLAMATION,
		"Die Hülle sind die Reklamationswelle, ihre Folge und die Kundenflucht.")
	var mit_unterschied := 0

	for seed_wert in range(1, 101):
		# Act
		var mittel := _gespielt(_grade, seed_wert, MITTEL)
		var schwer := _gespielt(_grade, seed_wert, SCHWER)
		var diff := ScheduleDiff.compare(mittel, schwer)

		# Assert: jede Markierung und jeder weggefallene Termin
		var markiert := _markiert(diff, schwer)
		for zeile: String in markiert:
			assert_true(huelle.has(zeile.get_slice(" ", 1)), "Seed %d: %s." % [seed_wert, zeile])
		for termin in diff.removed:
			assert_true(huelle.has(termin.event.id), "Seed %d: %s weggefallen."
				% [seed_wert, termin.event.id])
		if not markiert.is_empty() or not diff.removed.is_empty():
			mit_unterschied += 1
	assert_gt(mit_unterschied, 50, "In den meisten Seeds ändert Schwer etwas.")


func test_leicht_gegen_schwer_unterscheidet_sich_nur_in_der_huelle_beider_profile() -> void:
	# Arrange: Bei zwei Graden zählen die Start-Modifikatoren beider Profile.
	var huelle := _huelle(_grade, [LEICHT, SCHWER])

	for seed_wert in range(1, 21):
		# Act
		var schwer := _gespielt(_grade, seed_wert, SCHWER)
		var diff := ScheduleDiff.compare(_gespielt(_grade, seed_wert, LEICHT), schwer)

		# Assert
		for zeile: String in _markiert(diff, schwer):
			assert_true(huelle.has(zeile.get_slice(" ", 1)), "Seed %d: %s." % [seed_wert, zeile])
		for termin in diff.removed:
			assert_true(huelle.has(termin.event.id), "Seed %d: %s." % [seed_wert, termin.event.id])


func test_feste_termine_ausserhalb_der_huelle_sind_in_allen_graden_gleich() -> void:
	# Arrange (FR-003): gesetzt, fix, jährlich und der unabhängige Lieferengpass
	var unabhaengig := ["konkurrent_eroeffnet", "lieferengpass", "weihnachtsgeschaeft",
		"windows_95"]
	var huelle := _huelle(_grade, [LEICHT, SCHWER])
	for kennung: String in unabhaengig:
		assert_false(huelle.has(kennung), "%s liegt außerhalb der Hülle." % kennung)
	var arten := {}

	for seed_wert in [1, 4711, 99999]:
		# Act
		var spuren := []
		for grad: Difficulty.Level in [LEICHT, MITTEL, SCHWER]:
			var run := _gespielt(_grade, seed_wert, grad)
			var spur := []
			for termin in run.entries:
				if unabhaengig.has(termin.event.id):
					spur.append(_spur(termin))
					arten[termin.origin_label()] = true
			spuren.append(spur)

		# Assert
		assert_eq(spuren[0], spuren[1], "Seed %d: Leicht wie Mittel." % seed_wert)
		assert_eq(spuren[2], spuren[1], "Seed %d: Schwer wie Mittel." % seed_wert)
	assert_eq(_sortiert(arten), ["fix", "gesetzt", "gewürfelt", "jährlich"],
		"Der Vergleich deckt alle vier Herkünfte ab.")


# --- Profil, Summe und Zeitraum ----------------------------------------------------------

func test_leeres_profil_ergibt_dasselbe_wie_mittel() -> void:
	# Arrange
	var leer := _grade.duplicate_catalog()
	for profil in leer.profiles:
		profil.modifiers.clear()
	var mittel := _ausgabe(_gespielt(_grade, 4711, MITTEL), false)

	# Act und Assert: gleich bis auf die Kopfzeile, die den Grad nennt
	for grad: Difficulty.Level in [LEICHT, SCHWER]:
		var run := _gespielt(leer, 4711, grad)
		assert_eq(run.start_modifiers.size(), 0)
		assert_eq(_ausgabe(run, false), mittel,
			"%s mit leerem Profil wie Mittel." % Difficulty.label(grad))


func test_ohne_grad_gilt_mittel() -> void:
	# Arrange und Act (US1, Szenario 5)
	var ohne := _gespielt(_grade, 4711)
	var mittel := _gespielt(_grade, 4711, MITTEL)

	# Assert
	assert_eq(ohne.difficulty, MITTEL)
	assert_eq(ohne.start_modifiers.size(), 0, "Mittel hat kein Profil.")
	assert_eq(_ausgabe(ohne), _ausgabe(mittel))


func test_zwei_start_modifikatoren_addieren_sich_und_bleiben_mit_eingriffen_begrenzt() -> void:
	# Arrange: Schwer hat +5 und +4 auf die Reklamationswelle.
	var katalog := _grade.duplicate_catalog()
	katalog.get_profile(SCHWER).modifiers.append(_modifikator("presse", "reklamationswelle", 0.04,
		"Kritische Presse", 0, LETZTER_TAG))
	var run := TimelineRun.new(katalog, 4711, SCHWER)
	var tag := _tag(1990, 1, 1)

	# Act und Assert
	assert_almost_eq(run.chance_info("reklamationswelle", tag)["effective"], 0.12, 1e-9,
		"3 % + 5 + 4.")
	assert_eq(run.add_modifier(_modifikator("viel", "reklamationswelle", 1.0, "Viel", 0,
		LETZTER_TAG)), OK)
	var oben := run.chance_info("reklamationswelle", tag)
	assert_almost_eq(oben["sum"], 1.12, 1e-9)
	assert_eq(oben["effective"], 1.0, "Höchstens 100 %.")
	assert_eq(run.remove_modifier("viel"), OK)
	assert_eq(run.add_modifier(_modifikator("wenig", "reklamationswelle", -2.0, "Wenig", 0,
		LETZTER_TAG)), OK)
	var unten := run.chance_info("reklamationswelle", tag)
	assert_almost_eq(unten["sum"], -1.88, 1e-9)
	assert_eq(unten["effective"], 0.0, "Mindestens 0 %.")


func test_start_modifikator_fuer_einen_teil_des_spiels_wirkt_nur_in_seinen_wuerfelrunden() -> void:
	# Arrange (Edge Case; Analyse, G3): +97 Prozentpunkte vom 15.03.1990 bis 15.06.1994. Mit 100 %
	# trifft jede Würfelrunde, in der er gilt; die Reklamationswelle hat keinen Mindestabstand.
	var katalog := _grade.duplicate_catalog()
	katalog.get_profile(SCHWER).modifiers.assign([_modifikator("teil", "reklamationswelle", 0.97,
		"Teilzeitraum", _tag(1990, 3, 15), _tag(1994, 6, 15))])
	var run := TimelineRun.new(katalog, 4711, SCHWER)

	# Act
	run.advance_to(LETZTER_TAG)

	# Assert: die Chance in den Würfelrunden rund um Beginn und Ende
	for paar: Array in [[_tag(1990, 3, 1), 0.03], [_tag(1990, 4, 1), 1.0],
			[_tag(1994, 6, 1), 1.0], [_tag(1994, 7, 1), 0.03]]:
		assert_almost_eq(run.chance_info("reklamationswelle", paar[0])["effective"], paar[1], 1e-9,
			"Würfelrunde am %s." % GameDate.from_day_index(paar[0]))
	# Die Würfelrunden selbst: 100 % genau von April 1990 bis Juni 1994, 51 Monate.
	var mit_hundert := []
	for termin in _gewuerfelt(run, "reklamationswelle"):
		if termin.threshold >= 1.0:
			var datum := GameDate.from_day_index(termin.day)
			mit_hundert.append(datum.year * 100 + datum.month)
	assert_eq(mit_hundert.size(), 51, "Ein Termin in jedem Monat von 04.1990 bis 06.1994.")
	assert_eq(mit_hundert.min(), 199004, "Erst ab der Würfelrunde am 01.04.1990.")
	assert_eq(mit_hundert.max(), 199406, "Zuletzt in der Würfelrunde am 01.06.1994.")


func test_start_modifikator_gilt_schon_in_der_ersten_wuerfelrunde() -> void:
	# Arrange (FR-007): +97 Prozentpunkte ab dem 01.01.1985 machen 100 %.
	var katalog := _grade.duplicate_catalog()
	katalog.get_profile(SCHWER).modifiers.assign([_modifikator("sofort", "reklamationswelle", 0.97,
		"Von Anfang an", 0, LETZTER_TAG)])
	var run := TimelineRun.new(katalog, 4711, SCHWER)
	assert_eq(run.start_modifiers.size(), 1, "Gesetzt schon in new(), vor begin().")

	# Act
	run.begin()

	# Assert: Die Würfelrunde am 01.01.1985 hat getroffen, mit 100 %.
	var januar := _gewuerfelt(run, "reklamationswelle").filter(
		func(termin: ScheduleEntry) -> bool: return termin.day < _tag(1985, 2, 1))
	assert_eq(januar.size(), 1, "Ein Termin im Januar 1985.")
	if januar.size() == 1:
		assert_eq(januar[0].threshold, 1.0)


# --- Protokoll, chance_info() und Eingriffe -----------------------------------------------

func test_meldungen_start_modifier_stehen_am_tag_minus_eins_nur_im_protokoll() -> void:
	# Arrange
	var run := TimelineRun.new(_grade, 4711, SCHWER)

	# Act
	var am_ersten_tag := run.begin()

	# Assert
	var grad := run.protocol.filter(func(meldung: TimelineMessage) -> bool:
		return meldung.kind == TimelineMessage.Kind.START_MODIFIER)
	assert_eq(grad.size(), 1)
	if grad.size() == 1:
		var meldung: TimelineMessage = grad[0]
		assert_same(run.protocol[0], meldung, "Die erste Meldung des Protokolls.")
		assert_eq(meldung.day, -1)
		assert_eq(meldung.event.id, "reklamationswelle")
		assert_null(meldung.entry, "Kein Termin.")
		assert_eq(meldung.to_line(), "31.12.1984  Grad  Reklamationswelle: Start-Modifikator "
			+ "„Anspruchsvolle Kunden“ (Schwer) +5 Prozentpunkte vom 01.01.1985 bis 31.12.1999")
	for meldung in am_ersten_tag:
		assert_ne(meldung.kind, TimelineMessage.Kind.START_MODIFIER, "Nicht in der Rückgabe.")
	run.advance_to(LETZTER_TAG)
	assert_eq(run.interventions.size(), 0, "Nicht im Eingriffsprotokoll.")
	assert_eq(run.modifiers.size(), 0, "Nicht unter den Modifikatoren aus Eingriffen.")
	var leicht := TimelineRun.new(_grade, 4711, LEICHT)
	assert_eq(leicht.protocol[0].to_line(), "31.12.1984  Grad  Reklamationswelle: "
		+ "Start-Modifikator „Nachsichtige Kunden“ (Leicht) -2 Prozentpunkte vom 01.01.1985 bis "
		+ "31.12.1999")


func test_chance_info_und_begruendung_nennen_den_grad_vor_den_eingriffen() -> void:
	# Arrange: Schwer und dazu „Ware vom windigen Händler +5“ als Eingriff
	var run := TimelineRun.new(_grade, 4711, SCHWER)
	assert_eq(run.add_modifier(_modifikator("windiger_haendler", "reklamationswelle", 0.05,
		"Ware vom windigen Händler", 0, LETZTER_TAG)), OK)
	var tag := _tag(1990, 1, 1)

	# Act
	var info := run.chance_info("reklamationswelle", tag)
	run.advance_to(LETZTER_TAG)

	# Assert
	var aus_profil: Array[ChanceModifier] = info["start_modifiers"]
	var aus_eingriffen: Array[ChanceModifier] = info["modifiers"]
	assert_eq(aus_profil.size(), 1)
	assert_eq(aus_profil[0].reason, "Anspruchsvolle Kunden")
	assert_eq(aus_eingriffen.size(), 1, "„modifiers“ bleiben die Eingriffe.")
	assert_eq(aus_eingriffen[0].id, "windiger_haendler")
	assert_almost_eq(info["sum"], 0.13, 1e-9, "Beide zählen zur Summe.")
	assert_eq(run.chance_info("lieferengpass", tag)["start_modifiers"].size(), 0,
		"Auf den Lieferengpass zeigt kein Profil.")
	var termine := _gewuerfelt(run, "reklamationswelle")
	assert_gt(termine.size(), 0)
	for termin in termine:
		assert_eq(termin.modifier_notes, PackedStringArray(["Schwer: Anspruchsvolle Kunden +5",
			"Ware vom windigen Händler +5"]), "Erst der Grad, dann der Eingriff.")


func test_start_modifikator_laesst_sich_nicht_entfernen() -> void:
	# Arrange
	var run := TimelineRun.new(_grade, 4711, SCHWER)
	run.advance_to(_tag(1990, 1, 1))

	# Act und Assert (FR-010)
	assert_eq(run.remove_modifier("reklamationswelle"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, "„reklamationswelle“ ist ein Start-Modifikator von Schwer und "
		+ "lässt sich im laufenden Spiel nicht entfernen.")
	assert_eq(run.start_modifiers.size(), 1, "Er bleibt.")
	assert_eq(run.interventions.size(), 0, "Eine Ablehnung hinterlässt nichts.")
	assert_eq(run.remove_modifier("gibt_es_nicht"), ERR_DOES_NOT_EXIST)


func test_eingriff_mit_der_kennung_eines_start_modifikators_wird_angenommen() -> void:
	# Arrange (R5): Kennungen sind je Liste eindeutig.
	var run := TimelineRun.new(_grade, 4711, SCHWER)
	var gleich := _modifikator("reklamationswelle", "reklamationswelle", 0.01, "Gleiche Kennung", 0,
		LETZTER_TAG)

	# Act und Assert
	assert_eq(run.add_modifier(gleich), OK, run.last_refusal)
	assert_eq(run.modifiers.size(), 1)
	assert_eq(run.remove_modifier("reklamationswelle"), OK, "Entfernt wird der Eingriff.")
	assert_eq(run.modifiers.size(), 0)
	assert_eq(run.start_modifiers.size(), 1, "Der Start-Modifikator bleibt.")
	assert_eq(run.remove_modifier("reklamationswelle"), ERR_UNAVAILABLE)
	var arten := run.interventions.map(func(eingriff: Dictionary) -> String: return eingriff["kind"])
	assert_eq(arten, ["add_modifier", "remove_modifier"])


func test_ungepruefter_katalog_ergibt_start_refusals() -> void:
	# Arrange: catalog_us1_profil_kaputt ohne without_faulty(); in Schwer zeigt der erste
	# Start-Modifikator auf ein Ereignis, das es nicht gibt.
	var katalog := _katalog(KAPUTT)

	# Act
	var ungeprueft := TimelineRun.new(katalog, 4711, SCHWER)
	var issues := CatalogValidator.validate(katalog)
	var geprueft := TimelineRun.new(katalog.without_faulty(issues), 4711, SCHWER)

	# Assert
	assert_eq(Array(ungeprueft.start_refusals), ["Profil „Schwer“, Start-Modifikator "
		+ "„geisterereignis“: Das Ereignis „gibt_es_nicht“ gibt es im Katalog nicht."])
	assert_eq(_kennungen(ungeprueft.start_modifiers), ["lieferengpass", "reklamationswelle"],
		"Ohne Prüfung gilt auch der auf den fehlerhaften Lieferengpass.")
	assert_eq(Array(geprueft.start_refusals), [], "Mit without_faulty() bleibt die Liste leer.")
	assert_eq(_kennungen(geprueft.start_modifiers), ["reklamationswelle"], "Nur der dritte gilt.")


func test_jede_pruefung_wie_add_modifier_lehnt_ab() -> void:
	# Arrange: je Prüfung ein Start-Modifikator, der an ihr scheitert, und einer, der gilt
	var katalog := _grade.duplicate_catalog()
	katalog.get_profile(SCHWER).modifiers.assign([
		_modifikator("fix", "windows_95", 0.05, "Fixes Ereignis", 0, LETZTER_TAG),
		_modifikator("", "lieferengpass", 0.05, "Ohne Kennung", 0, LETZTER_TAG),
		_modifikator("doppelt", "lieferengpass", 0.01, "Erster", 0, LETZTER_TAG),
		_modifikator("doppelt", "lieferengpass", 0.02, "Zweiter", 0, LETZTER_TAG),
		_modifikator("ohne_grund", "lieferengpass", 0.05, "  ", 0, LETZTER_TAG),
		_modifikator("ohne_ende", "lieferengpass", 0.05, "Ohne Ende", 0, -1),
		_modifikator("umgedreht", "lieferengpass", 0.05, "Umgedreht", _tag(1995, 1, 1),
			_tag(1990, 1, 1)),
		_modifikator("gut", "reklamationswelle", 0.05, "Gilt", 0, LETZTER_TAG),
	])

	# Act
	var run := TimelineRun.new(katalog, 4711, SCHWER)

	# Assert
	assert_eq(Array(run.start_refusals), [
		"Profil „Schwer“, Start-Modifikator „fix“: Windows 95 erscheint ist kein Ereignis über "
			+ "Wahrscheinlichkeit; nur dort gibt es Start-Modifikatoren.",
		"Profil „Schwer“, Start-Modifikator Nr. 2 ohne Kennung: Der Start-Modifikator hat keine "
			+ "Kennung.",
		"Profil „Schwer“, Start-Modifikator „doppelt“: Die Kennung „doppelt“ gibt es in diesem "
			+ "Profil mehrfach.",
		"Profil „Schwer“, Start-Modifikator „doppelt“: Die Kennung „doppelt“ gibt es in diesem "
			+ "Profil mehrfach.",
		"Profil „Schwer“, Start-Modifikator „ohne_grund“: Der Start-Modifikator braucht einen "
			+ "Grund.",
		"Profil „Schwer“, Start-Modifikator „ohne_ende“: Dem Start-Modifikator fehlt das Ende; "
			+ "„unbegrenzt“ heißt bis 31.12.1999.",
		"Profil „Schwer“, Start-Modifikator „umgedreht“: Der Start-Modifikator endet am "
			+ "01.01.1990, vor seinem Beginn am 01.01.1995.",
	])
	assert_eq(_kennungen(run.start_modifiers), ["gut"])
	assert_eq(run.protocol.size(), 1, "Eine Meldung, nur für den, der gilt.")


func test_unbekannter_grad_gilt_als_mittel_und_steht_in_start_refusals() -> void:
	# Arrange und Act: Ein Parameter vom Typ Difficulty.Level nimmt auch eine 7 an.
	var run := _gespielt(_grade, 4711, 7 as Difficulty.Level)

	# Assert
	assert_eq(run.difficulty, MITTEL)
	assert_eq(Array(run.start_refusals),
		["Den Schwierigkeitsgrad 7 gibt es nicht; das Spiel läuft mit Mittel."])
	assert_eq(run.start_modifiers.size(), 0)
	assert_eq(_ausgabe(run), _ausgabe(_gespielt(_grade, 4711, MITTEL)), "Wie Mittel.")


func test_der_lauf_aendert_das_profil_des_katalogs_nicht() -> void:
	# Arrange
	var vorher := _grade.get_profile(SCHWER).to_list()

	# Act
	var run := TimelineRun.new(_grade, 4711, SCHWER)
	run.start_modifiers[0].value = 0.5

	# Assert: Die Start-Modifikatoren sind Kopien.
	assert_eq(_grade.get_profile(SCHWER).to_list(), vorher)
	assert_eq(run.catalog.get_profile(SCHWER).modifiers[0].value, 0.05)


# --- Helfer ---------------------------------------------------------------------------

## Liest einen Test-Katalog aus res://test/fixtures/.
func _katalog(datei: String) -> EventCatalog:
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.read_file(ORDNER + datei + ".json", issues)
	if catalog == null:
		fail_test("%s lässt sich nicht lesen: %s" % [datei, issues])
		return EventCatalog.new()
	return catalog


## Ein Lauf bis zum 31.12.1999.
func _gespielt(catalog: EventCatalog, seed_wert: int,
		grad: Difficulty.Level = Difficulty.DEFAULT) -> TimelineRun:
	var run := TimelineRun.new(catalog, seed_wert, grad)
	run.advance_to(LETZTER_TAG)
	return run


## Fahrplan und Protokoll eines Laufs als ein Text; mit [param kopfzeile] false ohne die Kopfzeile
## „# Seed …, Grad …“, für Vergleiche zwischen Graden.
func _ausgabe(run: TimelineRun, kopfzeile: bool = true) -> String:
	var fahrplan := ScheduleText.plan_lines(run)
	if not kopfzeile:
		fahrplan.remove_at(0)
	return "\n".join(fahrplan) + "\n--\n" + "\n".join(ScheduleText.protocol_lines(run))


## Die Hülle der abhängigen Ereignisse (data-model.md, „Abhängige Ereignisse“) als
## { kennung: true }: die Ereignisse, auf die ein Start-Modifikator der Grade [param grade] zeigt,
## und alles, was von ihnen aus erreichbar ist, über Folgen von der Quelle zur Folge und über
## Bedingungen vom Ereignis in der Bedingung zum bedingten Ereignis.
func _huelle(catalog: EventCatalog, grade: Array) -> Dictionary:
	var kanten := {}
	for event in catalog.events:
		for folge in event.follow_ups:
			if not kanten.has(event.id):
				kanten[event.id] = []
			kanten[event.id].append(folge.target)
		for bedingung in event.conditions:
			if not kanten.has(bedingung.event):
				kanten[bedingung.event] = []
			kanten[bedingung.event].append(event.id)
	var huelle := {}
	var offen := []
	for grad: int in grade:
		for modifikator in catalog.get_profile(grad).modifiers:
			offen.append(modifikator.event_id)
	while not offen.is_empty():
		var kennung: String = offen.pop_back()
		if huelle.has(kennung):
			continue
		huelle[kennung] = true
		offen.append_array(kanten.get(kennung, []))
	return huelle


## Die markierten Termine des zweiten Laufs, je „<Mark> <kennung> <TT.MM.JJJJ>“; NONE fehlt.
func _markiert(diff: ScheduleDiff, mit: TimelineRun) -> Array:
	var zeilen := []
	for termin in mit.entries:
		var markierung: ScheduleDiff.Mark = diff.marks.get(termin.serial, ScheduleDiff.Mark.NONE)
		if markierung != ScheduleDiff.Mark.NONE:
			zeilen.append("%s %s %s" % [ScheduleDiff.Mark.keys()[markierung], termin.event.id,
				GameDate.from_day_index(termin.day)])
	return zeilen


## Die gewürfelten Termine eines Ereignisses.
func _gewuerfelt(run: TimelineRun, kennung: String) -> Array[ScheduleEntry]:
	var gefunden: Array[ScheduleEntry] = []
	for termin in run.entries:
		if termin.event.id == kennung and termin.origin == ScheduleEntry.Origin.ROLLED:
			gefunden.append(termin)
	return gefunden


## Ein Termin als Text für Vergleiche: Tag, Ereignis, Herkunft, Zustand, Wurf, Schwelle.
func _spur(termin: ScheduleEntry) -> String:
	return "%s %s %s %s %.6f %.6f" % [GameDate.from_day_index(termin.day), termin.event.id,
		termin.origin_label(), termin.state_label(), termin.roll, termin.threshold]


## Ein Modifikator mit allen Feldern.
func _modifikator(kennung: String, ereignis: String, wert: float, grund: String, von: int,
		bis: int) -> ChanceModifier:
	var modifikator := ChanceModifier.new()
	modifikator.id = kennung
	modifikator.event_id = ereignis
	modifikator.value = wert
	modifikator.reason = grund
	modifikator.from_day = von
	modifikator.to_day = bis
	return modifikator


func _kennungen(modifikatoren: Array[ChanceModifier]) -> Array:
	var kennungen := []
	for modifikator in modifikatoren:
		kennungen.append(modifikator.id)
	return kennungen


## Die Schlüssel eines Dictionarys, sortiert.
func _sortiert(menge: Dictionary) -> Array:
	var schluessel := menge.keys()
	schluessel.sort()
	return schluessel


## Der Tag des Ersten von Monat [param monat], gezählt ab Januar 1985 = 0.
func _monatserster(monat: int) -> int:
	return _tag(1985 + floori(monat / 12.0), monat % 12 + 1, 1)


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()
