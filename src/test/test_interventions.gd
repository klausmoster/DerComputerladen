extends GutTest

## Prüft die Eingriffe im Lauf der Zeitleiste (Feature 002, T057; US6, FR-025 bis FR-027):
## Modifikatoren setzen, summieren, begrenzen, ablaufen lassen und entfernen; Termine absagen,
## verschieben und einplanen; die Ablehnungen mit ihrem Grund; das Eingriffsprotokoll und
## apply_intervention(); SC-003.
##
## Die Tests arbeiten mit zwei Test-Katalogen:
## - catalog_us6_schwelle: eine Reklamationswelle mit 3 % ohne Mindestabstand, sodass jeder Treffer
##   der Würfelrunde ein Termin wird, und „Nur mit Aktion“ mit 0 %.
## - catalog_us6_reklamation: die Reklamationswelle mit Folgeereignis (Zeitungsartikel) und einer
##   Kundenflucht, die von ihr abhängt; daneben unabhängige Ereignisse jeder Art, darunter
##   „Konkurrent eröffnet“, beim Start auf den 01.06.1992 gesetzt (US6, Szenario 4).
## Wo der Zufall entscheidet, rechnen die Tests mit denselben Würfeln nach (EventDice).

const ORDNER := "res://test/fixtures/"
const LETZTER_TAG := TimelineRun.LAST_DAY
## SC-003 je Katalog: die Reklamationswelle und die Ereignisse, die über Folgeereignis oder
## Bedingung von ihr abhängen. Alle übrigen dürfen sich durch den Modifikator nicht ändern.
const SC003_FAELLE := [
	["catalog_us6_reklamation",
		["kundenflucht", "reklamationswelle", "zeitungsartikel_reklamation"]],
	["event_catalog_uebernahme", ["reklamationswelle"]],
]


# --- Modifikatoren (FR-025) -----------------------------------------------------------

func test_szenario_1_acht_prozent_von_1990_bis_1993() -> void:
	# Arrange (US6, Szenario 1): „Ware vom windigen Händler: +5 Prozentpunkte vom 01.01.1990 bis
	# 31.12.1993“ auf die Reklamationswelle mit 3 %. Ohne Mindestabstand ist jeder Treffer ein
	# Termin, also lässt sich jeder Monat mit demselben Würfel nachrechnen.
	var catalog := _katalog("catalog_us6_schwelle")
	var januar_1990 := _monat(_tag(1990, 1, 1))
	var dezember_1993 := _monat(_tag(1993, 12, 31))
	var mit_acht := 0
	var mit_drei := 0

	for seed_wert in range(1, 21):
		var run := TimelineRun.new(catalog, seed_wert)

		# Act
		var ergebnis := run.add_modifier(_windiger_haendler())
		run.advance_to(LETZTER_TAG)

		# Assert
		assert_eq(ergebnis, OK)
		var wuerfel := EventDice.make(seed_wert, "chance", "reklamationswelle")
		var erwartet := []
		for monat in TimelineRun.MONTHS:
			var wurf := wuerfel.randf()
			wuerfel.randf()
			var im_zeitraum := monat >= januar_1990 and monat <= dezember_1993
			# Wie im Lauf: Grundchance plus Wert des Modifikators.
			if wurf < (0.03 + 0.05 if im_zeitraum else 0.03):
				erwartet.append(monat)
		var gefunden := []
		for termin in _termine(run, "reklamationswelle"):
			var monat := _monat(termin.day)
			gefunden.append(monat)
			if monat >= januar_1990 and monat <= dezember_1993:
				mit_acht += 1
				assert_almost_eq(termin.threshold, 0.08, 1e-9, "1990 bis 1993 mit 8 %.")
				assert_eq(termin.modifier_notes,
					PackedStringArray(["Ware vom windigen Händler +5"]))
				assert_string_contains(termin.explain(),
					"Schwelle 0,0800 (3 % + Ware vom windigen Händler +5)")
			else:
				mit_drei += 1
				assert_almost_eq(termin.threshold, 0.03, 1e-9, "Davor und danach mit 3 %.")
				assert_eq(termin.modifier_notes.size(), 0)
		assert_eq(gefunden, erwartet, "Seed %d: genau die Monate, deren Wurf trifft." % seed_wert)
	assert_gt(mit_acht, 0, "Über 20 Seeds gibt es Termine mit 8 %.")
	assert_gt(mit_drei, 0, "Über 20 Seeds gibt es Termine mit 3 %.")


func test_szenario_6_modifikator_laeuft_von_selbst_ab() -> void:
	# Arrange (US6, Szenario 6): der Modifikator aus Szenario 1 mit dem Ende 31.12.1993
	var run := TimelineRun.new(_katalog("catalog_us6_schwelle"), 4711)
	assert_eq(run.add_modifier(_windiger_haendler()), OK)
	var letzter := _tag(1993, 12, 31)
	var folgetag := _tag(1994, 1, 1)

	# Act
	run.advance_to(folgetag)

	# Assert
	assert_almost_eq(run.chance_info("reklamationswelle", letzter)["effective"], 0.08, 1e-9,
		"Am 31.12.1993 gilt er noch.")
	var danach := run.chance_info("reklamationswelle", folgetag)
	assert_almost_eq(danach["effective"], 0.03, 1e-9, "Ab dem 01.01.1994 wirkt er nicht mehr.")
	assert_eq(danach["modifiers"].size(), 0)
	assert_eq(run.modifiers.size(), 1, "Niemand hat ihn entfernt; er gilt nur nicht mehr.")
	assert_eq(_arten_im_protokoll(run), [TimelineRun.INTERVENTION_ADD_MODIFIER])
	# Die Würfelrunde am 01.01.1994 lief schon mit 3 %.
	var wuerfel := EventDice.make(4711, "chance", "reklamationswelle")
	for i in 2 * _monat(folgetag):
		wuerfel.randf()
	var januar := _termine(run, "reklamationswelle").filter(
		func(termin: ScheduleEntry) -> bool: return termin.day >= folgetag)
	assert_eq(januar.size(), 1 if wuerfel.randf() < 0.03 else 0)


func test_szenario_3_plus_vier_und_minus_sechs() -> void:
	# Arrange (US6, Szenario 3): 3 % Grundchance, Modifikatoren +4 und −6 Prozentpunkte
	var catalog := _katalog("catalog_us6_schwelle")
	var run := TimelineRun.new(catalog, 4711)
	var plus := _modifikator("plus", "reklamationswelle", 0.04, "Plus", 0, LETZTER_TAG)
	var minus := _modifikator("minus", "reklamationswelle", -0.06, "Minus", 0, LETZTER_TAG)
	assert_eq([run.add_modifier(plus), run.add_modifier(minus)], [OK, OK])
	var beide := run.chance_info("reklamationswelle", _tag(1990, 1, 1))
	var silvester_1989 := _tag(1989, 12, 31)
	run.advance_to(silvester_1989)

	# Act: +4 entfernen
	var ergebnis := run.remove_modifier("plus")
	var nur_minus := run.chance_info("reklamationswelle", _tag(1990, 1, 1))
	run.advance_to(LETZTER_TAG)

	# Assert
	assert_almost_eq(beide["sum"], 0.01, 1e-9, "3 % + 4 − 6 ergibt 1 %.")
	assert_almost_eq(beide["effective"], 0.01, 1e-9)
	assert_eq(ergebnis, OK)
	assert_eq(_kennungen(run.modifiers), ["minus"], "−6 bleibt bestehen.")
	assert_almost_eq(nur_minus["sum"], -0.03, 1e-9, "Die Summe zeigt −3 %.")
	assert_eq(nur_minus["effective"], 0.0, "Wirksam ist die Chance auf 0 % begrenzt.")
	for termin in _termine(run, "reklamationswelle"):
		assert_lt(termin.day, _tag(1990, 1, 1), "Mit 0 % kommt ab 1990 nichts mehr.")
		assert_almost_eq(termin.threshold, 0.01, 1e-9, "Bis 1989 mit 1 %.")
	var entfernt: Dictionary = run.interventions[2]
	assert_eq([entfernt["kind"], entfernt["at_day"], entfernt["modifier"]["id"]],
		[TimelineRun.INTERVENTION_REMOVE_MODIFIER, silvester_1989, "plus"])
	assert_has(_zeilen(run.protocol),
		"31.12.1989  Eingriff  Reklamationswelle: Modifikator „Plus“ +4 Prozentpunkte entfernt")
	assert_eq(run.catalog.get_event("reklamationswelle").monthly_chance, 0.03,
		"Die Grundchance im Katalog des Laufs bleibt unberührt.")
	assert_eq(catalog.get_event("reklamationswelle").monthly_chance, 0.03,
		"Der Katalog, aus dem der Lauf entstand, ebenso.")


func test_ablehnungen_von_modifikatoren() -> void:
	# Arrange: der Modifikator aus Szenario 1 ist schon gesetzt.
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	assert_eq(run.add_modifier(_windiger_haendler()), OK)
	var von := _tag(1990, 1, 1)
	var bis := _tag(1993, 12, 31)
	var faelle := [
		[_modifikator("rueckwaerts", "reklamationswelle", 0.05, "Test", von, von - 1),
			ERR_INVALID_PARAMETER, "Der Modifikator endet am 31.12.1989, vor seinem Beginn am "
			+ "01.01.1990."],
		[_modifikator("ohne_grund", "reklamationswelle", 0.05, "  ", von, bis),
			ERR_INVALID_PARAMETER, "Der Modifikator braucht einen Grund."],
		[_modifikator("windiger_haendler", "reklamationswelle", 0.02, "Noch einmal", von, bis),
			ERR_ALREADY_EXISTS, "Einen Modifikator mit der Kennung „windiger_haendler“ gibt es "
			+ "schon."],
		[_modifikator("gesetzt", "konkurrent_eroeffnet", 0.05, "Test", von, bis),
			ERR_INVALID_PARAMETER, "Konkurrent eröffnet ist kein Ereignis über "
			+ "Wahrscheinlichkeit; nur dort gibt es Modifikatoren."],
		[_modifikator("fix", "windows_95", 0.05, "Test", von, bis),
			ERR_INVALID_PARAMETER, "Windows 95 erscheint ist kein Ereignis über "
			+ "Wahrscheinlichkeit; nur dort gibt es Modifikatoren."],
		[_modifikator("unbekannt", "gibt_es_nicht", 0.05, "Test", von, bis),
			ERR_DOES_NOT_EXIST, "Das Ereignis „gibt_es_nicht“ gibt es im Katalog nicht."],
		[_modifikator("", "reklamationswelle", 0.05, "Test", von, bis),
			ERR_INVALID_PARAMETER, "Der Modifikator hat keine Kennung."],
		[_modifikator("ohne_ende", "reklamationswelle", 0.05, "Test", 0, -1),
			ERR_INVALID_PARAMETER, "Dem Modifikator fehlt das Ende; „unbegrenzt“ heißt bis "
			+ "31.12.1999."],
	]

	for fall: Array in faelle:
		# Act
		var ergebnis := run.add_modifier(fall[0])

		# Assert
		assert_eq(ergebnis, fall[1], fall[2])
		assert_eq(run.last_refusal, fall[2])
	assert_eq(run.remove_modifier("gibt_es_nicht"), ERR_DOES_NOT_EXIST)
	assert_eq(run.last_refusal, "Einen Modifikator mit der Kennung „gibt_es_nicht“ gibt es nicht.")
	assert_eq(_kennungen(run.modifiers), ["windiger_haendler"], "Nichts Abgelehntes gilt.")
	assert_eq(_arten_im_protokoll(run), [TimelineRun.INTERVENTION_ADD_MODIFIER],
		"Ablehnungen hinterlassen nichts im Eingriffsprotokoll.")
	assert_eq(_eingriffe_im_protokoll(run), 1, "Und keine Meldung im Protokoll.")


func test_lauf_merkt_sich_eine_kopie_des_modifikators() -> void:
	# Arrange
	var run := TimelineRun.new(_katalog("catalog_us6_schwelle"), 4711)
	var modifikator := _windiger_haendler()

	# Act: Nach dem Setzen ändert jemand das Objekt.
	assert_eq(run.add_modifier(modifikator), OK)
	modifikator.value = 0.9
	modifikator.to_day = LETZTER_TAG

	# Assert: Der Lauf und sein Eingriffsprotokoll bleiben, wie es gesetzt wurde.
	assert_almost_eq(run.chance_info("reklamationswelle", _tag(1991, 1, 1))["effective"], 0.08,
		1e-9)
	assert_eq(run.chance_info("reklamationswelle", _tag(1995, 1, 1))["modifiers"].size(), 0)
	assert_eq(run.interventions[0]["modifier"], _windiger_haendler_als_eintrag())
	assert_has(_zeilen(run.protocol), "31.12.1984  Eingriff  Reklamationswelle: Modifikator „Ware "
		+ "vom windigen Händler“ +5 Prozentpunkte vom 01.01.1990 bis 31.12.1993")


func test_beginn_in_der_vergangenheit_und_der_wert_null_sind_erlaubt() -> void:
	# Arrange: „Nur mit Aktion“ hat 0 % Grundchance (Warnung V13, aber erlaubt). Am 15.03.1990
	# bringt eine Aktion +100 Prozentpunkte vom 01.01.1990 bis 31.12.1990.
	var catalog := _katalog("catalog_us6_schwelle")
	var run := TimelineRun.new(catalog, 4711)
	var ohne := TimelineRun.new(catalog, 4711)
	var aktion := _modifikator("aktion", "nur_mit_aktion", 1.0, "Aktion", _tag(1990, 1, 1),
		_tag(1990, 12, 31))
	var null_punkte := _modifikator("null", "reklamationswelle", 0.0, "Ohne Wirkung", 0,
		LETZTER_TAG)
	run.advance_to(_tag(1990, 3, 15))

	# Act
	var ergebnisse := [run.add_modifier(aktion), run.add_modifier(null_punkte)]
	run.advance_to(LETZTER_TAG)
	ohne.advance_to(LETZTER_TAG)

	# Assert
	assert_eq(ergebnisse, [OK, OK], "Ein Beginn in der Vergangenheit und der Wert 0 gehen.")
	var monate := []
	for termin in _termine(run, "nur_mit_aktion"):
		monate.append(_monat(termin.day))
	assert_eq(monate, range(_monat(_tag(1990, 4, 1)), _monat(_tag(1990, 12, 1)) + 1),
		"Die Würfelrunden bis März waren schon gelaufen; er wirkt ab der nächsten, im April.")
	assert_eq(_termine(ohne, "nur_mit_aktion").size(), 0, "Ohne Modifikator kommt es nie.")
	assert_almost_eq(run.chance_info("reklamationswelle", _tag(1995, 1, 1))["sum"], 0.03, 1e-9,
		"Der Wert 0 ändert die Chance nicht.")


func test_modifikatoren_ueber_hundert_prozent_werden_begrenzt() -> void:
	# Arrange: +200 Prozentpunkte auf die Reklamationswelle, nur 1990
	var run := TimelineRun.new(_katalog("catalog_us6_schwelle"), 4711)
	var ansturm := _modifikator("ansturm", "reklamationswelle", 2.0, "Großer Ansturm",
		_tag(1990, 1, 1), _tag(1990, 12, 31))

	# Act
	var ergebnis := run.add_modifier(ansturm)
	run.advance_to(_tag(1990, 12, 31))

	# Assert
	assert_eq(ergebnis, OK)
	var info := run.chance_info("reklamationswelle", _tag(1990, 6, 1))
	assert_almost_eq(info["sum"], 2.03, 1e-9, "Die Summe bleibt unbegrenzt sichtbar.")
	assert_eq(info["effective"], 1.0, "Gewürfelt wird mit höchstens 100 %.")
	var in_1990 := _termine(run, "reklamationswelle").filter(
		func(termin: ScheduleEntry) -> bool: return termin.day >= _tag(1990, 1, 1))
	assert_eq(in_1990.size(), 12, "Mit 100 % trifft jeder Monat.")
	for termin: ScheduleEntry in in_1990:
		assert_eq(termin.threshold, 1.0)
		assert_string_contains(termin.explain(), "Schwelle 1,0000 (3 % + Großer Ansturm +200)")


# --- Termine: absagen, verschieben, einplanen (FR-026) --------------------------------

func test_szenario_4_konkurrent_wird_abgesagt() -> void:
	# Arrange (US6, Szenario 4): „Konkurrent eröffnet“ ist beim Start auf den 01.06.1992 gesetzt.
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	run.advance_to(_tag(1992, 1, 1))
	var termin := run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	assert_not_null(termin, "Voraussetzung: der gesetzte Termin am 01.06.1992.")
	if termin == null:
		return

	# Act: am 01.01.1992
	var ergebnis := run.cancel_entry(termin.serial, "Laden nebenan selbst gemietet")
	run.advance_to(LETZTER_TAG)

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq([termin.state_label(), termin.note], ["abgesagt", "Laden nebenan selbst gemietet"])
	assert_eq(termin.explain(), "Beim Spielstart gesetzt; abgesagt: Laden nebenan selbst gemietet")
	assert_eq(_meldungen_zu(run, "konkurrent_eroeffnet"), ["01.01.1992  Eingriff  Konkurrent "
		+ "eröffnet: Termin am 01.06.1992 abgesagt, Grund: Laden nebenan selbst gemietet"],
		"Er tritt nicht ein; im Protokoll steht nur der Eingriff, mit Tag und Grund.")
	assert_eq(_termine(run, "konkurrent_schliesst").size(), 0,
		"Ohne Eröffnung schließt auch keiner: Die Bedingung ist nie erfüllt.")
	assert_has(ScheduleText.plan_lines(run), "01.06.1992                  konkurrent_eroeffnet"
		+ "          gesetzt       abgesagt      Konkurrent eröffnet")
	var eingriff: Dictionary = run.interventions[0]
	assert_eq(eingriff, {"at_day": _tag(1992, 1, 1), "day": _tag(1992, 6, 1),
		"event_id": "konkurrent_eroeffnet", "kind": TimelineRun.INTERVENTION_CANCEL,
		"reason": "Laden nebenan selbst gemietet"}, "Ereignis und Tag statt laufender Nummer.")


func test_szenario_5_fix_und_jaehrlich_lassen_sich_nicht_absagen_noch_verschieben() -> void:
	# Arrange (US6, Szenario 5): „Windows 95“ und das Weihnachtsgeschäft
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	run.advance_to(_tag(1995, 1, 1))
	var windows := run.find_planned("windows_95", _tag(1995, 8, 24))
	var weihnachten := run.find_planned("weihnachtsgeschaeft", _tag(1995, 11, 1))
	var tag := _tag(1995, 9, 1)
	var fix := "Windows 95 erscheint ist fix und lässt sich weder absagen noch verschieben."
	var jaehrlich := "Weihnachtsgeschäft ist jährlich und lässt sich weder absagen noch " \
		+ "verschieben."

	# Act und Assert
	assert_eq(run.cancel_entry(windows.serial, "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, fix)
	assert_eq(run.move_entry(windows.serial, tag, "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, fix)
	assert_eq(run.cancel_entry(weihnachten.serial, "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, jaehrlich)
	assert_eq(run.move_entry(weihnachten.serial, tag, "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, jaehrlich)
	assert_eq(run.schedule_event("windows_95", tag, "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, "Windows 95 erscheint ist fix; einplanen lassen sich nur "
		+ "Ereignisse, die weder fix noch jährlich sind.")
	assert_eq(run.schedule_event("weihnachtsgeschaeft", tag, "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, "Weihnachtsgeschäft ist jährlich; einplanen lassen sich nur "
		+ "Ereignisse, die weder fix noch jährlich sind.")
	assert_eq([windows.state, weihnachten.state, windows.day],
		[ScheduleEntry.State.PLANNED, ScheduleEntry.State.PLANNED, _tag(1995, 8, 24)])
	assert_eq(run.interventions.size(), 0, "Ablehnungen hinterlassen nichts.")
	assert_eq(_eingriffe_im_protokoll(run), 0)


func test_absagen_nur_fuer_geplante_termine() -> void:
	# Arrange: am 01.01.1992; der erste gewürfelte Termin ist längst eingetreten.
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	run.advance_to(_tag(1992, 1, 1))
	var eingetreten := _erster(run, ScheduleEntry.Origin.ROLLED, ScheduleEntry.State.OCCURRED)
	var konkurrent := run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))

	# Act und Assert
	assert_eq(run.cancel_entry(eingetreten.serial, "Zu spät"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, "%s am %s ist nicht mehr geplant, sondern eingetreten."
		% [eingetreten.event.title, GameDate.from_day_index(eingetreten.day)])
	assert_eq(run.cancel_entry(9999, "Gibt es nicht"), ERR_DOES_NOT_EXIST)
	assert_eq(run.last_refusal, "Einen Termin mit der Nummer 9999 gibt es nicht.")
	assert_eq(run.cancel_entry(konkurrent.serial, ""), ERR_INVALID_PARAMETER)
	assert_eq(run.last_refusal, "Die Absage braucht einen Grund.")
	assert_eq(run.cancel_entry(konkurrent.serial, "Laden gemietet"), OK)
	assert_eq(run.last_refusal, "Die Absage braucht einen Grund.",
		"Der Grund bleibt bis zur nächsten Ablehnung; ob es geklappt hat, sagt die Rückgabe.")
	assert_eq(run.cancel_entry(konkurrent.serial, "Noch einmal"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, "Konkurrent eröffnet am 01.06.1992 ist nicht mehr geplant, sondern "
		+ "abgesagt.")
	assert_eq(_arten_im_protokoll(run), [TimelineRun.INTERVENTION_CANCEL])
	assert_eq(konkurrent.note, "Laden gemietet", "Die zweite Absage hat nichts geändert.")


func test_termin_nach_spielende_laesst_sich_nicht_aendern() -> void:
	# Arrange: In catalog_us1_spielende bringt „Spät im Jahr“ am 25.12.1999 ein „Nachspiel“ am
	# 04.01.2000. Es steht als geplant im Fahrplan, wird aber nie mehr abgespielt.
	var run := TimelineRun.new(_katalog("catalog_us1_spielende"), 4711)
	run.advance_to(_tag(1999, 12, 25))
	var nachspiel := run.find_planned("nachspiel", _tag(2000, 1, 4))
	var grund := "Nachspiel: Der 04.01.2000 liegt nach dem Spielende am 31.12.1999."

	# Act und Assert
	assert_eq(run.cancel_entry(nachspiel.serial, "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, grund)
	assert_eq(run.move_entry(nachspiel.serial, _tag(1999, 12, 30), "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, grund)
	assert_eq(run.interventions.size(), 0)


func test_verschieben_nur_auf_tage_nach_heute() -> void:
	# Arrange: am 01.01.1992, „Konkurrent eröffnet“ ist auf den 01.06.1992 gesetzt.
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	var heute := _tag(1992, 1, 1)
	run.advance_to(heute)
	var termin := run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	var schon_gespielt := "Der %s ist schon abgespielt; frühestens geht der 02.01.1992."

	# Act und Assert: heute, gestern, nach Spielende, derselbe Tag, ohne Grund
	assert_eq(run.move_entry(termin.serial, heute, "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, schon_gespielt % "01.01.1992")
	assert_eq(run.move_entry(termin.serial, heute - 1, "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, schon_gespielt % "31.12.1991")
	assert_eq(run.move_entry(termin.serial, LETZTER_TAG + 1, "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, "Der 01.01.2000 liegt nach dem Spielende am 31.12.1999.")
	assert_eq(run.move_entry(termin.serial, _tag(1992, 6, 1), "Test"), ERR_INVALID_PARAMETER)
	assert_eq(run.last_refusal, "Konkurrent eröffnet liegt schon am 01.06.1992.")
	assert_eq(run.move_entry(termin.serial, heute + 1, " "), ERR_INVALID_PARAMETER)
	assert_eq(run.last_refusal, "Die Verschiebung braucht einen Grund.")
	assert_eq(run.interventions.size(), 0)
	# Der nächste Tag geht, und dort tritt der Termin dann auch ein.
	assert_eq(run.move_entry(termin.serial, heute + 1, "Eröffnung vorgezogen"), OK)
	var morgen := run.advance_to(heute + 1)
	assert_has(_zeilen(morgen), "02.01.1992  Beginn  Konkurrent eröffnet")
	run.advance_to(LETZTER_TAG)
	assert_eq(_tage(run, "konkurrent_eroeffnet"), [heute + 1])


func test_erstes_verschieben_merkt_den_alten_tag() -> void:
	# Arrange
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	run.advance_to(_tag(1992, 1, 1))
	var termin := run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))

	# Act: zweimal verschieben
	var erstes := run.move_entry(termin.serial, _tag(1992, 9, 1), "Bauarbeiten")
	var zweites := run.move_entry(termin.serial, _tag(1992, 10, 1), "Noch mehr Bauarbeiten")

	# Assert
	assert_eq([erstes, zweites], [OK, OK])
	assert_eq(termin.moved_from_day, _tag(1992, 6, 1), "Das erste Verschieben merkt den Tag.")
	assert_eq([termin.day, termin.end_day], [_tag(1992, 10, 1), _tag(1992, 10, 1)])
	assert_eq(termin.explain(),
		"Beim Spielstart gesetzt, verschoben vom 01.06.1992; Grund: Noch mehr Bauarbeiten")
	assert_null(run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1)))
	assert_same(run.find_planned("konkurrent_eroeffnet", _tag(1992, 10, 1)), termin)
	for i in range(1, run.entries.size()):
		assert_lte(run.entries[i - 1].day, run.entries[i].day, "Der Fahrplan bleibt sortiert.")
	var verschiebungen := run.interventions.map(
		func(eingriff: Dictionary) -> Array: return [eingriff["day"], eingriff["new_day"]])
	assert_eq(verschiebungen, [[_tag(1992, 6, 1), _tag(1992, 9, 1)],
		[_tag(1992, 9, 1), _tag(1992, 10, 1)]], "Je Eingriff der Tag davor und der neue Tag.")
	run.advance_to(LETZTER_TAG)
	assert_eq(_meldungen_zu(run, "konkurrent_eroeffnet"), [
		"01.01.1992  Eingriff  Konkurrent eröffnet: Termin vom 01.06.1992 auf den 01.09.1992 "
			+ "verschoben, Grund: Bauarbeiten",
		"01.01.1992  Eingriff  Konkurrent eröffnet: Termin vom 01.09.1992 auf den 01.10.1992 "
			+ "verschoben, Grund: Noch mehr Bauarbeiten",
		"01.10.1992  Beginn  Konkurrent eröffnet",
	])


func test_verschieben_behaelt_die_dauer() -> void:
	# Arrange: ein Lieferengpass mit 30 Tagen Dauer, eingeplant für den 10.06.1991
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	run.advance_to(_tag(1991, 6, 1))
	assert_eq(run.schedule_event("lieferengpass", _tag(1991, 6, 10), "Lager leer"), OK)
	var termin := run.find_planned("lieferengpass", _tag(1991, 6, 10))

	# Act
	var ergebnis := run.move_entry(termin.serial, _tag(1991, 6, 20), "Lieferung kam noch")
	run.advance_to(_tag(1991, 12, 31))

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq([termin.day, termin.end_day], [_tag(1991, 6, 20), _tag(1991, 7, 20)])
	var zum_termin := []
	for meldung in run.protocol:
		if meldung.entry == termin and meldung.kind != TimelineMessage.Kind.INTERVENTION:
			zum_termin.append(meldung.to_line())
	assert_eq(zum_termin, [
		"20.06.1991  Beginn  Lieferengpass",
		"20.06.1991  Wirkung  Lieferengpass: Preis · * · +10% — Knappe Ware wird teurer.",
		"20.07.1991  Wirkungsende  Lieferengpass: Preis · * · +10% — Knappe Ware wird teurer.",
		"20.07.1991  Ende  Lieferengpass",
	])


func test_einplanen_nur_auf_tage_nach_heute() -> void:
	# Arrange: am 01.01.1992
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	var heute := _tag(1992, 1, 1)
	run.advance_to(heute)

	# Act und Assert
	assert_eq(run.schedule_event("zeitungsartikel_reklamation", heute, "Test"), ERR_UNAVAILABLE)
	assert_eq(run.last_refusal, "Der 01.01.1992 ist schon abgespielt; frühestens geht der "
		+ "02.01.1992.")
	assert_eq(run.schedule_event("zeitungsartikel_reklamation", LETZTER_TAG + 1, "Test"),
		ERR_UNAVAILABLE)
	assert_eq(run.schedule_event("zeitungsartikel_reklamation", heute + 1, ""),
		ERR_INVALID_PARAMETER)
	assert_eq(run.last_refusal, "Die Einplanung braucht einen Grund.")
	assert_eq(run.schedule_event("gibt_es_nicht", heute + 1, "Test"), ERR_DOES_NOT_EXIST)
	assert_eq(run.last_refusal, "Das Ereignis „gibt_es_nicht“ gibt es im Katalog nicht.")
	assert_eq(run.interventions.size(), 0)
	assert_eq(run.schedule_event("zeitungsartikel_reklamation", LETZTER_TAG, "Silvesterbericht"),
		OK, "Der 31.12.1999 ist der letzte mögliche Tag.")
	run.advance_to(LETZTER_TAG)
	assert_has(_zeilen(run.protocol), "31.12.1999  Beginn  Zeitungsartikel über Reklamationen")


func test_eingeplanter_termin_gilt_wie_jeder_geplante() -> void:
	# Arrange: vor dem ersten Tag
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	var messe := _tag(1986, 3, 10)

	# Act: ein Großkunde mit seinem Folgeereignis und eine Schließung, deren Bedingung fehlt
	var ergebnisse := [
		run.schedule_event("grosskunde", messe, "Messekontakt"),
		run.schedule_event("konkurrent_schliesst", _tag(1990, 3, 1), "Gerücht"),
	]
	run.advance_to(_tag(1990, 12, 31))

	# Assert
	assert_eq(ergebnisse, [OK, OK])
	var grosskunde := _termin_am(run, "grosskunde", messe)
	assert_eq([grosskunde.origin_label(), grosskunde.state_label()], ["Eingriff", "eingetreten"])
	assert_eq(grosskunde.explain(), "Per Eingriff eingeplant; Grund: Messekontakt")
	var folgen := _termine(run, "grossauftrag").filter(
		func(termin: ScheduleEntry) -> bool: return termin.source_event_id == "grosskunde" \
			and termin.day >= messe and termin.day <= messe + 30)
	assert_eq(folgen.size(), 1, "Sein Folgeereignis kommt wie bei jedem Beginn.")
	var schliessung := _termin_am(run, "konkurrent_schliesst", _tag(1990, 3, 1))
	assert_eq([schliessung.state_label(), schliessung.note], ["entfallen",
		"Bedingung nicht erfüllt, „Konkurrent eröffnet“ ist noch nicht eingetreten"],
		"Bedingungen gelten auch für eingeplante Termine (FR-006).")
	assert_has(ScheduleText.plan_lines(run), "10.03.1986                  grosskunde"
		+ "                    Eingriff      eingetreten   Großkunde")


func test_eingriffe_vor_dem_ersten_tag() -> void:
	# Arrange: Der Lauf steht vor dem 01.01.1985, today ist −1.
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	var januar := _modifikator("januar", "grosskunde", 1.0, "Eröffnungsangebot", 0, 30)
	var konkurrent := run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))

	# Act
	var ergebnisse := [
		run.schedule_event("zeitungsartikel_reklamation", 0, "Bericht zur Eröffnung"),
		run.schedule_event("zeitungsartikel_reklamation", -1, "Zu früh"),
		run.add_modifier(januar),
		run.cancel_entry(konkurrent.serial, "Laden nebenan selbst gemietet"),
	]
	var abgelehnt := run.last_refusal
	var erster_tag := run.begin()

	# Assert
	assert_eq(ergebnisse, [OK, ERR_UNAVAILABLE, OK, OK])
	assert_eq(abgelehnt, "Der 31.12.1984 liegt vor dem Spielbeginn am 01.01.1985.")
	for eingriff in run.interventions:
		assert_eq(eingriff["at_day"], -1, "Vor Spielbeginn ist at_day −1.")
	assert_eq(_zeilen(run.protocol).slice(0, 3).map(
		func(zeile: String) -> String: return zeile.substr(0, 22)), [
		"31.12.1984  Eingriff  ", "31.12.1984  Eingriff  ", "31.12.1984  Eingriff  "])
	assert_has(_zeilen(erster_tag), "01.01.1985  Beginn  Zeitungsartikel über Reklamationen",
		"Ein Eingriff vor Spielbeginn wirkt ab dem 01.01.1985 (FR-027).")
	var im_januar := _termine(run, "grosskunde")
	assert_eq(im_januar.size(), 1, "Die Würfelrunde am 01.01.1985 lief schon mit 100 %.")
	if im_januar.size() == 1:
		assert_eq(im_januar[0].threshold, 1.0)
		assert_eq(im_januar[0].modifier_notes, PackedStringArray(["Eröffnungsangebot +100"]))
	assert_eq(konkurrent.state, ScheduleEntry.State.CANCELLED)


# --- Eingriffsprotokoll und apply_intervention() -------------------------------------

func test_find_planned_findet_nur_geplante_termine() -> void:
	# Arrange: „Konkurrent eröffnet“ ist auf den 01.06.1992 gesetzt; ein zweiter wird für
	# denselben Tag eingeplant.
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	var tag := _tag(1992, 6, 1)
	var gesetzt := _termin_am(run, "konkurrent_eroeffnet", tag)
	assert_eq(run.schedule_event("konkurrent_eroeffnet", tag, "Zweiter Laden"), OK)

	# Act und Assert
	assert_same(run.find_planned("konkurrent_eroeffnet", tag), gesetzt,
		"Bei zweien am selben Tag der erste im Fahrplan, hier der gesetzte.")
	assert_null(run.find_planned("konkurrent_eroeffnet", tag + 1), "Anderer Tag.")
	assert_null(run.find_planned("gibt_es_nicht", tag), "Unbekanntes Ereignis.")
	assert_eq(run.cancel_entry(gesetzt.serial, "Laden gemietet"), OK)
	var eingeplant := run.find_planned("konkurrent_eroeffnet", tag)
	assert_eq(eingeplant.origin_label(), "Eingriff", "Ein abgesagter Termin ist nicht geplant.")
	run.advance_to(tag)
	assert_eq(eingeplant.state_label(), "eingetreten")
	assert_null(run.find_planned("konkurrent_eroeffnet", tag), "Ein eingetretener auch nicht.")


func test_eingriffsprotokoll_nachgespielt_ergibt_denselben_fahrplan() -> void:
	# Arrange: ein Lauf mit Eingriffen an verschiedenen Tagen, darunter eine Ablehnung und die
	# Absage eines gewürfelten Termins, der erst im Lauf entstand.
	var catalog := _katalog("catalog_us6_reklamation")
	var run := TimelineRun.new(catalog, 4711)
	var tage := []
	assert_eq(run.add_modifier(_windiger_haendler()), OK)
	tage.append(run.today)
	assert_eq(run.schedule_event("grossauftrag", _tag(1986, 3, 10), "Messeauftrag"), OK)
	tage.append(run.today)
	run.advance_to(_tag(1989, 12, 31))
	assert_eq(run.add_modifier(_windiger_haendler()), ERR_ALREADY_EXISTS, "Wird abgelehnt.")
	var konkurrent := run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	assert_eq(run.move_entry(konkurrent.serial, _tag(1992, 9, 1), "Bauarbeiten"), OK)
	tage.append(run.today)
	run.advance_to(_tag(1991, 6, 30))
	var abzug := _modifikator("abzug", "lieferengpass", -0.02, "Zweiter Lieferant",
		_tag(1991, 7, 1), _tag(1995, 12, 31))
	assert_eq(run.add_modifier(abzug), OK)
	tage.append(run.today)
	run.advance_to(_tag(1992, 1, 1))
	assert_eq(run.cancel_entry(konkurrent.serial, "Laden nebenan selbst gemietet"), OK)
	tage.append(run.today)
	run.advance_to(_tag(1993, 6, 30))
	assert_eq(run.remove_modifier("windiger_haendler"), OK)
	tage.append(run.today)
	var gewuerfelt := _naechster_geplanter_gewuerfelter(run, _tag(1994, 1, 1))
	assert_not_null(gewuerfelt,
		"Voraussetzung: ab 1994 ein gewürfelter Termin, der noch geplant ist.")
	if gewuerfelt == null:
		return
	assert_eq(run.cancel_entry(gewuerfelt.serial, "Kunde abgesprungen"), OK)
	tage.append(run.today)
	run.advance_to(LETZTER_TAG)

	# Act: ein frischer Lauf spielt das Protokoll an den Tagen nach.
	var frisch := TimelineRun.new(catalog, 4711)
	var ergebnisse := []
	for eingriff in run.interventions:
		frisch.advance_to(eingriff["at_day"])
		ergebnisse.append(frisch.apply_intervention(eingriff))
	frisch.advance_to(LETZTER_TAG)

	# Assert
	var arten := run.interventions.map(
		func(eingriff: Dictionary) -> String: return eingriff["kind"])
	assert_eq(arten, [
		TimelineRun.INTERVENTION_ADD_MODIFIER, TimelineRun.INTERVENTION_SCHEDULE,
		TimelineRun.INTERVENTION_MOVE, TimelineRun.INTERVENTION_ADD_MODIFIER,
		TimelineRun.INTERVENTION_CANCEL, TimelineRun.INTERVENTION_REMOVE_MODIFIER,
		TimelineRun.INTERVENTION_CANCEL,
	], "Jeder angenommene Eingriff, die Ablehnung nicht.")
	assert_eq(run.interventions.map(func(eingriff: Dictionary) -> int: return eingriff["at_day"]),
		tage, "Jeder mit dem Tag, an dem er geschah.")
	assert_eq(_eingriffe_im_protokoll(run), run.interventions.size(), "Je Eingriff eine Meldung.")
	assert_eq(ergebnisse, [OK, OK, OK, OK, OK, OK, OK])
	assert_eq(_fahrplan(frisch), _fahrplan(run), "Derselbe Fahrplan, Termin für Termin.")
	assert_eq(_zeilen(frisch.protocol), _zeilen(run.protocol), "Dasselbe Protokoll.")
	assert_eq(frisch.interventions, run.interventions, "Dasselbe Eingriffsprotokoll.")
	assert_eq(gewuerfelt.state, ScheduleEntry.State.CANCELLED)


func test_apply_intervention_liest_eintraege_aus_einer_datei() -> void:
	# Arrange: Aus JSON kommt jede Zahl als float. Dazu Einträge, die nicht passen.
	var run := TimelineRun.new(_katalog("catalog_us6_reklamation"), 4711)
	var aus_datei := {"at_day": -1.0, "day": 400.0, "event_id": "grossauftrag",
		"kind": "schedule", "reason": "Messeauftrag"}
	var modifikator := {"at_day": -1.0, "kind": "add_modifier", "modifier": {
		"event_id": "reklamationswelle", "from_day": 1826.0, "id": "windiger_haendler",
		"reason": "Ware vom windigen Händler", "to_day": 3286.0, "value": 0.05}}

	# Act und Assert
	assert_eq(run.apply_intervention(aus_datei), OK)
	assert_eq(run.apply_intervention(modifikator), OK)
	assert_eq(run.interventions[0], {"at_day": -1, "day": 400, "event_id": "grossauftrag",
		"kind": "schedule", "reason": "Messeauftrag"}, "Zurück in ganzen Zahlen.")
	assert_eq(run.interventions[1]["modifier"], _windiger_haendler_als_eintrag())
	assert_eq(run.apply_intervention({"kind": "zaubern"}), ERR_INVALID_PARAMETER)
	assert_eq(run.last_refusal, "Einen Eingriff der Art „zaubern“ gibt es nicht.")
	assert_eq(run.apply_intervention({"kind": "add_modifier"}), ERR_INVALID_PARAMETER)
	assert_eq(run.last_refusal, "Dem Eingriff fehlt der Modifikator.")
	assert_eq(run.apply_intervention({"day": _tag(1992, 6, 2), "event_id": "konkurrent_eroeffnet",
		"kind": "cancel", "reason": "Test"}), ERR_DOES_NOT_EXIST)
	assert_eq(run.last_refusal,
		"Konkurrent eröffnet hat am 02.06.1992 keinen geplanten Termin im Fahrplan.")
	assert_eq(run.apply_intervention({"day": 100, "event_id": "weg", "kind": "move",
		"new_day": 200, "reason": "Test"}), ERR_DOES_NOT_EXIST)
	assert_eq(run.last_refusal, "Das Ereignis „weg“ gibt es im Katalog nicht.")
	assert_eq(run.apply_intervention({"day": _tag(1992, 6, 1), "event_id": "konkurrent_eroeffnet",
		"kind": "move", "new_day": _tag(1992, 9, 1), "reason": "Bauarbeiten"}), OK,
		"Verschiebungen finden ihren Termin über Ereignis und Tag.")
	assert_eq(run.interventions.size(), 3)


# --- SC-003 ---------------------------------------------------------------------------

func test_sc003_modifikator_aendert_keinen_fremden_termin(
		fall: Array = use_parameters(SC003_FAELLE)) -> void:
	# Arrange (SC-003): der Modifikator aus US6, Szenario 1, für die Seeds 1 bis 100
	var catalog := _katalog(fall[0])
	var abhaengig: Array = fall[1]
	var wirkt := 0

	for seed_wert in range(1, 101):
		var ohne := TimelineRun.new(catalog, seed_wert)
		var mit := TimelineRun.new(catalog, seed_wert)
		if mit.add_modifier(_windiger_haendler()) != OK:
			fail_test("Seed %d: %s" % [seed_wert, mit.last_refusal])
			return

		# Act
		ohne.advance_to(LETZTER_TAG)
		mit.advance_to(LETZTER_TAG)

		# Assert: Termine und Meldungen jedes Ereignisses, das nicht abhängt, sind gleich.
		var vorher := _spuren_je_ereignis(ohne)
		var nachher := _spuren_je_ereignis(mit)
		var fremd_vorher := {}
		var fremd_nachher := {}
		for event in catalog.events:
			if not abhaengig.has(event.id):
				fremd_vorher[event.id] = vorher.get(event.id, [])
				fremd_nachher[event.id] = nachher.get(event.id, [])
		assert_eq(fremd_nachher, fremd_vorher, "%s, Seed %d." % [fall[0], seed_wert])
		if nachher.get("reklamationswelle") != vorher.get("reklamationswelle"):
			wirkt += 1
	assert_gt(wirkt, 0, "Der Modifikator ändert die Reklamationswelle überhaupt.")


# --- Helfer ---------------------------------------------------------------------------

## Liest einen Test-Katalog aus res://test/fixtures/; er muss ohne Fehler sein, Warnungen gehen.
func _katalog(datei: String) -> EventCatalog:
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.read_file(ORDNER + datei + ".json", issues)
	if catalog == null:
		fail_test("%s lässt sich nicht lesen: %s" % [datei, issues])
		return EventCatalog.new()
	issues.append_array(CatalogValidator.validate(catalog))
	assert_false(CatalogValidator.has_errors(issues), "%s ist fehlerfrei: %s" % [datei, issues])
	return catalog


## „Ware vom windigen Händler: +5 Prozentpunkte vom 01.01.1990 bis 31.12.1993“ auf die
## Reklamationswelle (US6, Szenario 1).
func _windiger_haendler() -> ChanceModifier:
	return _modifikator("windiger_haendler", "reklamationswelle", 0.05,
		"Ware vom windigen Händler", _tag(1990, 1, 1), _tag(1993, 12, 31))


## Derselbe Modifikator, wie er im Eingriffsprotokoll steht.
func _windiger_haendler_als_eintrag() -> Dictionary:
	return {"event_id": "reklamationswelle", "from_day": _tag(1990, 1, 1),
		"id": "windiger_haendler", "reason": "Ware vom windigen Händler",
		"to_day": _tag(1993, 12, 31), "value": 0.05}


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


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()


## Nummer des Monats, 0 für Januar 1985 bis 179 für Dezember 1999.
func _monat(tag: int) -> int:
	var datum := GameDate.from_day_index(tag)
	return (datum.year - GameDate.EPOCH_YEAR) * 12 + datum.month - 1


## Die Termine eines Ereignisses in der Reihenfolge des Fahrplans.
func _termine(run: TimelineRun, kennung: String) -> Array[ScheduleEntry]:
	var gefunden: Array[ScheduleEntry] = []
	for termin in run.entries:
		if termin.event.id == kennung:
			gefunden.append(termin)
	return gefunden


## Die Tage der Termine eines Ereignisses.
func _tage(run: TimelineRun, kennung: String) -> Array:
	var tage := []
	for termin in _termine(run, kennung):
		tage.append(termin.day)
	return tage


## Der Termin des Ereignisses, der an [param tag] beginnt; null, wenn es keinen gibt.
func _termin_am(run: TimelineRun, kennung: String, tag: int) -> ScheduleEntry:
	for termin in _termine(run, kennung):
		if termin.day == tag:
			return termin
	return null


## Der erste Termin im Fahrplan mit dieser Herkunft und diesem Zustand.
func _erster(run: TimelineRun, herkunft: ScheduleEntry.Origin,
		zustand: ScheduleEntry.State) -> ScheduleEntry:
	for termin in run.entries:
		if termin.origin == herkunft and termin.state == zustand:
			return termin
	return null


## Spielt den Lauf von Monatserstem zu Monatserstem ab [param ab] und gibt den ersten gewürfelten
## Termin zurück, der danach noch geplant ist; der Lauf steht dann auf diesem Monatsersten. Null,
## wenn es bis zum Spielende keinen gibt.
func _naechster_geplanter_gewuerfelter(run: TimelineRun, ab: int) -> ScheduleEntry:
	var datum := GameDate.from_day_index(ab)
	var monat := GameDate.new(datum.year, datum.month, 1)
	while monat.to_day_index() <= LETZTER_TAG:
		run.advance_to(monat.to_day_index())
		for termin in run.entries:
			if termin.origin == ScheduleEntry.Origin.ROLLED \
					and termin.state == ScheduleEntry.State.PLANNED and termin.day > run.today:
				return termin
		monat = GameDate.new(monat.year + (1 if monat.month == 12 else 0),
			1 if monat.month == 12 else monat.month + 1, 1)
	return null


## Die Kennungen von Modifikatoren.
func _kennungen(modifikatoren: Array[ChanceModifier]) -> Array:
	var kennungen := []
	for modifikator in modifikatoren:
		kennungen.append(modifikator.id)
	return kennungen


## Die Arten im Eingriffsprotokoll, in seiner Reihenfolge.
func _arten_im_protokoll(run: TimelineRun) -> Array:
	var arten := []
	for eingriff in run.interventions:
		arten.append(eingriff["kind"])
	return arten


## Wie viele Meldungen INTERVENTION im Protokoll stehen.
func _eingriffe_im_protokoll(run: TimelineRun) -> int:
	var anzahl := 0
	for meldung in run.protocol:
		if meldung.kind == TimelineMessage.Kind.INTERVENTION:
			anzahl += 1
	return anzahl


## Die Zeilen der Meldungen zu einem Ereignis, in der Reihenfolge des Protokolls.
func _meldungen_zu(run: TimelineRun, kennung: String) -> Array:
	var zeilen := []
	for meldung in run.protocol:
		if meldung.event != null and meldung.event.id == kennung:
			zeilen.append(meldung.to_line())
	return zeilen


## Die Zeilen von Meldungen.
func _zeilen(meldungen: Array[TimelineMessage]) -> Array:
	var zeilen := []
	for meldung in meldungen:
		zeilen.append(meldung.to_line())
	return zeilen


## Ein Termin als Text für Vergleiche, mit allem, was ihn ausmacht, außer der laufenden Nummer.
func _spur(termin: ScheduleEntry) -> String:
	return "%s %s %s %s %s %.6f %.6f %.6f %s %s %d %s" % [GameDate.from_day_index(termin.day),
		GameDate.from_day_index(termin.end_day), termin.event.id, termin.origin_label(),
		termin.state_label(), termin.roll, termin.threshold, termin.base_chance,
		",".join(termin.modifier_notes), termin.source_event_id, termin.moved_from_day,
		termin.note]


## Der ganze Fahrplan, je Termin laufende Nummer und Spur, in seiner Reihenfolge.
func _fahrplan(run: TimelineRun) -> Array:
	var spuren := []
	for termin in run.entries:
		spuren.append("%d %s" % [termin.serial, _spur(termin)])
	return spuren


## Je Ereignis seine Termine und Meldungen als Text, Kennung → Liste; Eingriffe zählen nicht mit.
func _spuren_je_ereignis(run: TimelineRun) -> Dictionary:
	var je_ereignis := {}
	for termin in run.entries:
		if not je_ereignis.has(termin.event.id):
			je_ereignis[termin.event.id] = []
		je_ereignis[termin.event.id].append(_spur(termin))
	for meldung in run.protocol:
		if meldung.kind == TimelineMessage.Kind.INTERVENTION:
			continue
		if not je_ereignis.has(meldung.event.id):
			je_ereignis[meldung.event.id] = []
		je_ereignis[meldung.event.id].append(meldung.to_line())
	return je_ereignis
