extends GutTest

## Prüft die Statistik über viele Spiele (Feature 002, T064 und T065; FR-044, FR-045; US7,
## Szenarien 3 bis 6; SC-008): Mittelwert und Anteile über 1.000 Spiele, die Zählung der Beginne
## der Seeds 1 bis N, gleiche Ergebnisse bei Wiederholung, Eingriffe an ihrem Tag, auch außer der
## Reihe gesammelte (T075) und solche ohne lesbaren Tag (R1), abgelehnte Eingriffe, die nicht
## zählen (T082), die Obergrenze und das Zeitbudget von run_for().
##
## Dazu die Grade (Feature 003, T028; FR-020, SC-003; US4, Szenarien 2 bis 4): die Liste der Grade,
## leer oder nur Mittel wie in Feature 002; ein Seed in allen Graden; ein Abbruch mitten im Seed;
## results_for(); Eingriffe in jedem Grad und angenommen oder abgelehnt nach dem ersten Grad.
##
## Die Tests arbeiten mit Test-Katalogen unter fixtures/catalog_us7_*.json und
## catalog_us6_reklamation.json, nie mit dem echten Katalog (R20). Die Eingriffe kommen aus dem
## Eingriffsprotokoll eines echten Laufs, so wie der Simulator sie sammelt.

## Ein Ereignis zu 50 % pro Monat ohne Zeitfenster, Höchstzahl und Mindestabstand.
const HALB := "res://test/fixtures/catalog_us7_halb.json"
## Ein Ereignis „beim Start gesetzt“, zu 30 % keinmal und zu 70 % einmal.
const GESETZT := "res://test/fixtures/catalog_us7_gesetzt.json"
## Eins mit 0 % Grundchance, eins nur als Folge und „Konkurrent eröffnet“ fest am 01.06.1992.
const EINGRIFFE := "res://test/fixtures/catalog_us7_eingriffe.json"
## Je eine Art mit und ohne Obergrenze.
const OBERGRENZE := "res://test/fixtures/catalog_us7_obergrenze.json"
## Viele Arten auf einmal: Folgen, Bedingungen, Dauer, jährlich, fix.
const US6 := "res://test/fixtures/catalog_us6_reklamation.json"
## Termine, die entfallen, weil ihr Ereignis noch läuft (US3, Szenario 6).
const LAEUFT_NOCH := "res://test/fixtures/catalog_us3_laeuft_noch.json"
## Ein Folgetermin, der erst am 04.01.2000 käme und deshalb geplant bleibt.
const SPIELENDE := "res://test/fixtures/catalog_us1_spielende.json"
## Reklamationswelle zu 3 % pro Monat mit „Leicht −2“ und „Schwer +5“, dazu Abhängige und
## Unabhängige, darunter der Lieferengpass zu 4 %, auf den kein Profil zeigt (Feature 003).
const GRADE := "res://test/fixtures/catalog_us1_grade.json"
## Alle drei Grade in der Reihenfolge der Auswahl.
const ALLE_GRADE: Array[int] = [Difficulty.Level.LEICHT, Difficulty.Level.MITTEL,
	Difficulty.Level.SCHWER]
## Die Ereignisse in catalog_us1_grade.json, die kein Profil verändert und die von keinem
## veränderten abhängen (US4, Szenario 3).
const UNABHAENGIGE: Array[String] = ["konkurrent_eroeffnet", "lieferengpass", "weihnachtsgeschaeft",
	"windows_95"]
## So viel darf ein Aufruf von run_for() über Budget und längstem Schritt liegen: Der Rechner
## arbeitet nebenher auch anderes.
const TOLERANZ_MS := 10.0
## So viele Häppchen misst der Test des Zeitbudgets; es zählt ihr Median.
const HAEPPCHEN := 7


# --- Mittelwert und Anteile (SC-008; US7, Szenarien 3 und 6) ----------------------------------

func test_sc_008_halbe_chance_ergibt_im_mittel_rund_90() -> void:
	# Arrange: 50 % pro Monat, 1.000 Spiele mit den Seeds 1 bis 1.000
	var statistik := TimelineStatistics.new(_katalog(HALB), 1000)

	# Act
	_bis_fertig(statistik)

	# Assert: 180 Monate, Erwartung 90 (US7, Szenario 3)
	var ergebnis := _ergebnis(statistik, "jeder_zweite_monat")
	gut.p("Mittelwert bei 50 %% pro Monat über 1.000 Spiele: %.2f" % ergebnis.mean())
	assert_eq([statistik.games_done, ergebnis.games], [1000, 1000])
	assert_between(ergebnis.mean(), 85.5, 94.5, "SC-008")
	assert_lte(float(ergebnis.minimum), ergebnis.mean())
	assert_gte(float(ergebnis.maximum), ergebnis.mean())
	assert_eq(ergebnis.games_without, 0)
	assert_eq(ergebnis.games_at_max, -1, "Ohne Höchstzahl gibt es keine Obergrenze.")
	assert_eq(_summe(ergebnis.per_year), ergebnis.total, "Jeder Beginn steht in einem Jahr.")
	for jahr in EventStatistic.YEARS:
		assert_between(ergebnis.per_year[jahr] / 1000.0, 5.5, 6.5,
			"%d: im Schnitt 6 Beginne je Spiel" % (EventStatistic.FIRST_YEAR + jahr))


func test_szenario_6_gesetzt_30_zu_70_fehlt_in_rund_30_prozent_der_spiele() -> void:
	# Arrange
	var statistik := TimelineStatistics.new(_katalog(GESETZT), 1000)

	# Act
	_bis_fertig(statistik)

	# Assert
	var ergebnis := _ergebnis(statistik, "neubaugebiet")
	gut.p("Ohne Neubaugebiet: %.1f %%" % (ergebnis.share_without() * 100.0))
	assert_between(ergebnis.share_without(), 0.25, 0.35, "US7, Szenario 6")
	assert_eq([ergebnis.minimum, ergebnis.maximum], [0, 1])
	# Die Obergrenze ist die höchste Anzahl, also 1: erreicht in jedem Spiel mit Termin.
	assert_eq(ergebnis.games_at_max, ergebnis.games - ergebnis.games_without)
	assert_eq(ergebnis.total, ergebnis.games_at_max)
	assert_almost_eq(ergebnis.share_at_max(), 1.0 - ergebnis.share_without(), 0.0001)


# --- Zählweise --------------------------------------------------------------------------------

func test_zaehlt_die_beginne_der_seeds_1_bis_n() -> void:
	# Arrange, Act und Assert je Katalog: Folgen, Bedingungen, Dauer und jährliche Ereignisse
	# (US6); ein Lieferengpass, der beim zweiten Termin noch läuft und deshalb entfällt (US3); ein
	# Folgetermin, der erst nach dem 31.12.1999 käme und deshalb geplant bleibt (US1).
	var uebrig := {"entfallen": 0, "geplant": 0}
	for fall: Array in [[US6, 15], [LAEUFT_NOCH, 3], [SPIELENDE, 2]]:
		var gezaehlt := _pruefe_zaehlung(fall[0], fall[1])
		for zustand: String in uebrig:
			uebrig[zustand] += gezaehlt[zustand]

	# Assert
	assert_gt(uebrig["entfallen"], 0, "Es gab entfallene Termine, und sie haben nicht gezählt.")
	assert_gt(uebrig["geplant"], 0, "Es gab am Ende noch geplante Termine; auch sie zählen nicht.")


func test_angefangenes_spiel_zaehlt_erst_wenn_es_fertig_ist() -> void:
	# Arrange
	var statistik := TimelineStatistics.new(_katalog(HALB), 2)

	# Act: 179 Monate, jeder Aufruf mit dem Budget 0 rechnet genau einen
	for monat in 179:
		statistik.run_for(0)

	# Assert
	var ergebnis := _ergebnis(statistik, "jeder_zweite_monat")
	assert_eq([statistik.games_done, ergebnis.games, ergebnis.total], [0, 0, 0],
		"Nach 179 Monaten ist das erste Spiel noch nicht fertig.")

	# Act und Assert: Der 180. Monat beendet es.
	assert_false(statistik.run_for(0))
	assert_eq([statistik.games_done, _ergebnis(statistik, "jeder_zweite_monat").games], [1, 1])


# --- Wiederholung (US7, Szenario 5) -----------------------------------------------------------

func test_szenario_5_wiederholt_gerechnet_ist_das_ergebnis_gleich() -> void:
	# Arrange: dieselben Einstellungen zweimal, einmal in Häppchen von einem Monat, einmal am Stück
	var katalog := _katalog(US6)
	var haeppchen := TimelineStatistics.new(katalog, 12)
	var am_stueck := TimelineStatistics.new(katalog, 12)

	# Act
	while not haeppchen.run_for(0):
		pass
	_bis_fertig(am_stueck)

	# Assert
	assert_eq(_als_daten(haeppchen.results()), _als_daten(am_stueck.results()),
		"Gleiche Seeds, gleiches Ergebnis, egal in wie vielen Aufrufen.")
	var andere := TimelineStatistics.new(katalog, 12, 13)
	_bis_fertig(andere)
	assert_ne(_als_daten(andere.results()), _als_daten(am_stueck.results()),
		"Andere Seeds ergeben ein anderes Ergebnis; der Vergleich oben sagt also etwas.")


# --- Eingriffe (US7, Szenario 4; FR-045) ------------------------------------------------------

func test_szenario_4_modifikator_aus_dem_protokoll_wirkt_in_jedem_spiel() -> void:
	# Arrange: „Nur mit Aktion“ hat 0 % Grundchance; im Simulator kam vor Spielbeginn ein
	# Modifikator mit +100 Prozentpunkten für 1985 bis 1999 dazu.
	var katalog := _katalog(EINGRIFFE)
	var simulator := TimelineRun.new(katalog, 4711)
	assert_eq(simulator.add_modifier(_modifikator(1.0)), OK)
	var statistik := TimelineStatistics.new(katalog, 5)
	statistik.interventions = simulator.interventions

	# Act
	_bis_fertig(statistik)

	# Assert: in jedem Spiel jeden Monat ein Beginn
	var ergebnis := _ergebnis(statistik, "nur_mit_aktion")
	assert_eq([ergebnis.minimum, ergebnis.maximum, ergebnis.total], [180, 180, 900])
	var ohne := TimelineStatistics.new(katalog, 5)
	_bis_fertig(ohne)
	assert_eq(_ergebnis(ohne, "nur_mit_aktion").total, 0, "Ohne Eingriffe kommt sie nie.")


func test_szenario_4_entfernter_modifikator_wirkt_nur_bis_zu_seinem_tag() -> void:
	# Arrange: gesetzt vor Spielbeginn, im Simulator am 31.12.1989 wieder entfernt
	var katalog := _katalog(EINGRIFFE)
	var simulator := TimelineRun.new(katalog, 4711)
	simulator.add_modifier(_modifikator(1.0))
	simulator.advance_to(_tag(1989, 12, 31))
	assert_eq(simulator.remove_modifier("aktion"), OK)
	var statistik := TimelineStatistics.new(katalog, 10)
	statistik.interventions = simulator.interventions

	# Act
	_bis_fertig(statistik)

	# Assert: 60 Würfelrunden 1985 bis 1989 mit 100 %, danach 0 %
	var ergebnis := _ergebnis(statistik, "nur_mit_aktion")
	assert_eq([ergebnis.minimum, ergebnis.maximum], [60, 60])
	for jahr in EventStatistic.YEARS:
		assert_eq(ergebnis.per_year[jahr], 120 if jahr < 5 else 0,
			"%d" % (EventStatistic.FIRST_YEAR + jahr))


func test_einplanung_gilt_in_jedem_spiel_absage_und_verschiebung_nicht() -> void:
	# Arrange: Im Simulator stand der Lauf am 01.01.1990. Dort kam „Großauftrag“ für den
	# 15.03.1991 dazu, und „Konkurrent eröffnet“ wurde auf 1993 verschoben und dann abgesagt.
	var katalog := _katalog(EINGRIFFE)
	var simulator := TimelineRun.new(katalog, 4711)
	simulator.advance_to(_tag(1990, 1, 1))
	assert_eq(simulator.schedule_event("grossauftrag", _tag(1991, 3, 15), "Messeauftrag"), OK)
	var konkurrent := simulator.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	assert_eq(simulator.move_entry(konkurrent.serial, _tag(1993, 6, 1), "Bauamt"), OK)
	assert_eq(simulator.cancel_entry(konkurrent.serial, "Laden nebenan gemietet"), OK)
	var protokoll := simulator.interventions.duplicate(true)
	var statistik := TimelineStatistics.new(katalog, 10)
	statistik.interventions = simulator.interventions

	# Act
	_bis_fertig(statistik)

	# Assert: der Großauftrag in jedem Spiel 1991; der Konkurrent wie im Katalog am 01.06.1992
	var auftrag := _ergebnis(statistik, "grossauftrag")
	assert_eq([auftrag.minimum, auftrag.maximum, auftrag.per_year[1991 - 1985]], [1, 1, 10])
	var eroeffnet := _ergebnis(statistik, "konkurrent_eroeffnet")
	assert_eq([eroeffnet.minimum, eroeffnet.maximum], [1, 1], "Die Absage gilt nicht.")
	assert_eq(eroeffnet.per_year[1992 - 1985], 10, "Die Verschiebung gilt nicht.")
	assert_eq(statistik.interventions, protokoll, "Das Protokoll selbst bleibt, wie es war.")


func test_eingriffe_ausser_der_reihe_gelten_an_ihrem_tag() -> void:
	# Arrange (T075): So sammelt der Simulator, wenn nach „Fahrplan erzeugen“ ein Eingriff vor
	# Spielbeginn dazukommt: erst am 01.01.1992 der Großauftrag für den 15.03.1993, dann vor
	# Spielbeginn +100 Prozentpunkte auf „Nur mit Aktion“.
	var katalog := _katalog(EINGRIFFE)
	var erster_lauf := TimelineRun.new(katalog, 4711)
	erster_lauf.advance_to(_tag(1992, 1, 1))
	assert_eq(erster_lauf.schedule_event("grossauftrag", _tag(1993, 3, 15), "Messeauftrag"), OK)
	var zweiter_lauf := TimelineRun.new(katalog, 4711)
	assert_eq(zweiter_lauf.add_modifier(_modifikator(1.0)), OK)
	var protokoll: Array[Dictionary] = [erster_lauf.interventions[0], zweiter_lauf.interventions[0]]
	var vorher := protokoll.duplicate(true)
	var statistik := TimelineStatistics.new(katalog, 5)
	statistik.interventions = protokoll

	# Act
	_bis_fertig(statistik)

	# Assert: Der Modifikator gilt ab Januar 1985, nicht erst ab Februar 1992.
	var aktion := _ergebnis(statistik, "nur_mit_aktion")
	assert_eq([aktion.minimum, aktion.maximum], [180, 180])
	var auftrag := _ergebnis(statistik, "grossauftrag")
	assert_eq([auftrag.minimum, auftrag.maximum, auftrag.per_year[1993 - 1985]], [1, 1, 5])
	assert_eq(statistik.interventions, vorher, "Das Protokoll bleibt in seiner Reihenfolge.")


func test_eintrag_ohne_tag_gilt_hinter_seinem_vorgaenger_im_ganzen_protokoll() -> void:
	# Arrange (R1): Einplanung am Tag 100, Absage am Tag 3000 (20.03.1993), dann ein Modifikator
	# ohne lesbaren Tag. Die Absage gilt in der Statistik nicht, ihr Tag zählt trotzdem: Der
	# Modifikator gilt wie im Simulator ab dem Tag 3000, nicht ab dem Tag 100.
	var katalog := _katalog(EINGRIFFE)
	var protokoll: Array[Dictionary] = [
		{"at_day": 100, "kind": TimelineRun.INTERVENTION_SCHEDULE, "event_id": "grossauftrag",
			"day": 200, "reason": "Messeauftrag"},
		{"at_day": 3000, "kind": TimelineRun.INTERVENTION_CANCEL,
			"event_id": "konkurrent_eroeffnet", "day": _tag(1992, 6, 1), "reason": "Bauamt"},
		{"kind": TimelineRun.INTERVENTION_ADD_MODIFIER,
			"modifier": _als_eintrag(_modifikator(1.0))},
	]
	var statistik := TimelineStatistics.new(katalog, 3)
	statistik.interventions = protokoll

	# Act
	_bis_fertig(statistik)

	# Assert: Gewürfelt wird mit 100 % ab dem 01.04.1993, 81 Monate lang, wie im Simulator.
	var aktion := _ergebnis(statistik, "nur_mit_aktion")
	assert_eq([aktion.minimum, aktion.maximum], [81, 81], "Ab dem Tag 3000, nicht ab dem Tag 100.")
	for jahr in EventStatistic.YEARS:
		var erwartet := 0
		if jahr == 1993 - EventStatistic.FIRST_YEAR:
			erwartet = 9 * 3
		elif jahr > 1993 - EventStatistic.FIRST_YEAR:
			erwartet = 12 * 3
		assert_eq(aktion.per_year[jahr], erwartet, "%d" % (EventStatistic.FIRST_YEAR + jahr))
	var probe := WhatIfProbe.new()
	probe.seed = 1
	probe.until_day = TimelineRun.LAST_DAY
	probe.interventions = protokoll
	var simulator := probe.build_run(katalog)
	var beginne := 0
	for termin in simulator.entries:
		if termin.event.id == "nur_mit_aktion" and termin.state == ScheduleEntry.State.OCCURRED:
			beginne += 1
	assert_eq(beginne, 81, "Der Simulator spielt dasselbe Protokoll genauso nach.")
	assert_eq(statistik.accepted, 2, "Einplanung und Modifikator gelten, die Absage zählt nicht.")


# --- Abgelehnte Eingriffe (T082) --------------------------------------------------------------

func test_abgelehnte_eingriffe_zaehlen_nicht_und_stehen_mit_grund_da() -> void:
	# Arrange: ein Modifikator auf ein Ereignis, das es nicht mehr gibt, dazu das Entfernen
	# desselben Modifikators und eine gültige Einplanung. Absage und Verschiebung gelten in der
	# Statistik ohnehin nicht und sind deshalb auch nicht abgelehnt.
	var katalog := _katalog(EINGRIFFE)
	var weg := _modifikator(0.5)
	weg.id = "weg"
	weg.event_id = "geloescht"
	var protokoll: Array[Dictionary] = [
		{"at_day": -1, "kind": TimelineRun.INTERVENTION_ADD_MODIFIER,
			"modifier": _als_eintrag(weg)},
		{"at_day": 1000, "kind": TimelineRun.INTERVENTION_SCHEDULE, "event_id": "grossauftrag",
			"day": 1500, "reason": "Messeauftrag"},
		{"at_day": 1200, "kind": TimelineRun.INTERVENTION_CANCEL,
			"event_id": "konkurrent_eroeffnet", "day": _tag(1992, 6, 1), "reason": "Bauamt"},
		{"at_day": 2000, "kind": TimelineRun.INTERVENTION_REMOVE_MODIFIER,
			"modifier": _als_eintrag(weg)},
	]
	var statistik := TimelineStatistics.new(katalog, 4)
	statistik.interventions = protokoll

	# Act
	_bis_fertig(statistik)

	# Assert: gezählt wird nur die Einplanung; die beiden abgelehnten stehen mit Grund da.
	assert_eq(statistik.accepted, 1)
	var gruende := []
	for ablehnung in statistik.refused:
		gruende.append([ablehnung["record"]["kind"], ablehnung["reason"]])
	assert_eq(gruende, [
		[TimelineRun.INTERVENTION_ADD_MODIFIER, "Das Ereignis „geloescht“ gibt es im Katalog nicht."],
		[TimelineRun.INTERVENTION_REMOVE_MODIFIER,
			"Einen Modifikator mit der Kennung „weg“ gibt es nicht."],
	], "In der Reihenfolge des Nachspielens, einmal, nicht je Spiel.")
	var auftrag := _ergebnis(statistik, "grossauftrag")
	assert_eq([auftrag.minimum, auftrag.maximum], [1, 1], "Die Einplanung gilt in jedem Spiel.")


func test_ablehnung_haengt_nicht_am_seed() -> void:
	# Arrange: dasselbe Protokoll mit anderem ersten Seed; ein Modifikator auf ein Ereignis, das
	# nicht über Wahrscheinlichkeit kommt, und einer, der gilt.
	var katalog := _katalog(EINGRIFFE)
	var falsch := _modifikator(0.5)
	falsch.id = "falsch"
	falsch.event_id = "konkurrent_eroeffnet"
	var protokoll: Array[Dictionary] = [
		{"at_day": -1, "kind": TimelineRun.INTERVENTION_ADD_MODIFIER,
			"modifier": _als_eintrag(falsch)},
		{"at_day": -1, "kind": TimelineRun.INTERVENTION_ADD_MODIFIER,
			"modifier": _als_eintrag(_modifikator(1.0))},
	]
	var ergebnisse := []

	# Act
	for erster_seed in [1, 4711, 99999]:
		var statistik := TimelineStatistics.new(katalog, 2, erster_seed)
		statistik.interventions = protokoll
		_bis_fertig(statistik)
		ergebnisse.append([statistik.accepted, statistik.refused.size(),
			_ergebnis(statistik, "nur_mit_aktion").minimum])

	# Assert
	assert_eq(ergebnisse, [[1, 1, 180], [1, 1, 180], [1, 1, 180]])


# --- Obergrenze (FR-044) ----------------------------------------------------------------------

func test_obergrenze_ist_hoechstzahl_oder_hoechste_anzahl_sonst_minus_eins() -> void:
	# Arrange
	var katalog := _katalog(OBERGRENZE)
	var statistik := TimelineStatistics.new(katalog, 40)

	# Act
	_bis_fertig(statistik)

	# Assert: Höchstzahl 3 bei 100 % pro Monat, in jedem Spiel erreicht
	var grenzen := {}
	for event in katalog.events:
		grenzen[event.id] = TimelineStatistics.upper_limit(event)
	assert_eq(grenzen, {"cebit": -1, "drei_mal": 3, "ein_oder_zwei": 2, "nur_als_folge": -1,
		"ohne_grenze": -1, "windows_95": -1})
	var drei := _ergebnis(statistik, "drei_mal")
	assert_eq([drei.minimum, drei.maximum, drei.games_at_max, drei.share_at_max()],
		[3, 3, 40, 1.0])
	# Die höchste Anzahl 2: erreicht in den Spielen mit zwei Terminen.
	var gesetzt := _ergebnis(statistik, "ein_oder_zwei")
	assert_eq(gesetzt.games_at_max, gesetzt.total - gesetzt.games)
	assert_between(gesetzt.share_at_max(), 0.25, 0.75)
	# Ohne Obergrenze −1, auch beim Anteil; die Werkstatt zeigt dort „–“.
	for kennung: String in ["cebit", "nur_als_folge", "ohne_grenze", "windows_95"]:
		var ergebnis := _ergebnis(statistik, kennung)
		assert_eq([ergebnis.games_at_max, ergebnis.share_at_max()], [-1, -1.0], kennung)
	var folge := _ergebnis(statistik, "nur_als_folge")
	assert_eq([folge.games_without, folge.share_without(), folge.mean()], [40, 1.0, 0.0])


# --- Zeitbudget (R17) -------------------------------------------------------------------------

func test_run_for_haelt_sein_budget_ungefaehr_ein() -> void:
	# Arrange: Wie lange ein einzelner Schritt höchstens dauert, ein Monat samt Start oder Ende
	# eines Spiels, misst run_for(0) über gut zwei Spiele.
	var katalog := _katalog(US6)
	var schritte := TimelineStatistics.new(katalog, 1000)
	var laengster_schritt := 0.0
	for schritt in 400:
		var vorher := Time.get_ticks_usec()
		schritte.run_for(0)
		laengster_schritt = maxf(laengster_schritt, (Time.get_ticks_usec() - vorher) / 1000.0)
	var statistik := TimelineStatistics.new(katalog, 1000)
	var dauern: Array[float] = []

	# Act: sieben Häppchen zu 15 ms, wie die Werkstatt sie je Bild rechnet
	for haeppchen in HAEPPCHEN:
		var vorher := Time.get_ticks_usec()
		var fertig := statistik.run_for(15)
		dauern.append((Time.get_ticks_usec() - vorher) / 1000.0)
		assert_false(fertig, "1.000 Spiele passen nicht in 15 ms.")

	# Assert: nie vor dem Budget. Höchstens um einen Schritt später gilt für das gewöhnliche
	# Häppchen, den Median: Hält das Betriebssystem den Prozess mitten in einem Häppchen an, wird
	# eben dieses länger, ohne dass run_for() etwas falsch macht.
	gut.p("run_for(15): %s ms; längster Schritt %.2f ms" % [str(dauern), laengster_schritt])
	for dauer: float in dauern:
		assert_gte(dauer, 15.0, "Das Budget ist verbraucht.")
	var sortiert := dauern.duplicate()
	sortiert.sort()
	assert_lte(sortiert[floori(sortiert.size() / 2.0)], 15.0 + laengster_schritt + TOLERANZ_MS,
		"Höchstens ein Schritt mehr.")

	# Act und Assert: Häppchen für Häppchen werden Spiele fertig; wie viele Häppchen es dafür
	# braucht, hängt am Rechner.
	var weitere := 0
	while statistik.games_done == 0 and weitere < 1000:
		statistik.run_for(15)
		weitere += 1
	assert_gt(statistik.games_done, 0, "Spiele werden über mehrere Aufrufe fertig.")


# --- Grade (Feature 003, T028; FR-020) --------------------------------------------------------

func test_leere_liste_und_nur_mittel_rechnen_wie_feature_002() -> void:
	# Arrange: ohne Liste, mit leerer Liste und mit nur Mittel, je 12 Spiele
	var katalog := _katalog(GRADE)
	var ohne := TimelineStatistics.new(katalog, 12)
	var leer := TimelineStatistics.new(katalog, 12, 1, [] as Array[int])
	var mittel := TimelineStatistics.new(katalog, 12, 1, [Difficulty.Level.MITTEL] as Array[int])

	# Act: Häppchen von einem Monat; gezählt wird, wann jedes Spiel fertig ist
	var verlaeufe := []
	for statistik in [ohne, leer, mittel]:
		var fertig_nach := []
		var schritte := 0
		while not statistik.run_for(0):
			schritte += 1
			if fertig_nach.size() < statistik.games_done:
				fertig_nach.append(schritte)
		verlaeufe.append(fertig_nach)

	# Assert
	assert_eq([ohne.difficulties, leer.difficulties], [[Difficulty.DEFAULT], [Difficulty.DEFAULT]],
		"Leer heißt nur Mittel.")
	assert_eq(verlaeufe[1], verlaeufe[0], "Leere Liste: jedes Spiel nach 180 Monaten fertig.")
	assert_eq(verlaeufe[2], verlaeufe[0], "Nur Mittel: ebenso.")
	assert_eq(verlaeufe[0].slice(0, 2), [180, 360])
	assert_eq(_als_daten(leer.results()), _als_daten(ohne.results()))
	assert_eq(_als_daten(mittel.results()), _als_daten(ohne.results()))
	assert_eq(_als_daten(mittel.results_for(Difficulty.Level.MITTEL)), _als_daten(ohne.results()))


func test_jeder_grad_rechnet_dieselben_seeds_wie_eine_statistik_nur_fuer_ihn() -> void:
	# Arrange: der Vergleich und je Grad eine eigene Statistik, alle mit den Seeds 5 bis 24
	var katalog := _katalog(GRADE)
	var vergleich := TimelineStatistics.new(katalog, 20, 5, ALLE_GRADE)

	# Act
	_bis_fertig(vergleich)

	# Assert
	assert_eq(vergleich.games_done, 20)
	for grad in ALLE_GRADE:
		var einzeln := TimelineStatistics.new(katalog, 20, 5, [grad] as Array[int])
		_bis_fertig(einzeln)
		assert_eq(_als_daten(vergleich.results_for(grad)), _als_daten(einzeln.results()),
			Difficulty.label(grad))
	assert_ne(_als_daten(vergleich.results_for(Difficulty.Level.LEICHT)),
		_als_daten(vergleich.results_for(Difficulty.Level.SCHWER)),
		"Die Grade unterscheiden sich; der Vergleich oben sagt also etwas.")


func test_abbruch_mitten_im_seed_laesst_alle_grade_gleich() -> void:
	# Arrange: drei Grade, zwei Spiele
	var statistik := TimelineStatistics.new(_katalog(GRADE), 2, 1, ALLE_GRADE)

	# Act: der erste Seed in allen drei Graden, dann 180 Monate des zweiten, also Leicht fertig
	# und Mittel noch nicht begonnen; danach noch 179 Monate, also Mittel fast fertig
	for monat in 180 * 3 - 1:
		statistik.run_for(0)
	var vor_dem_ersten := statistik.games_done
	statistik.run_for(0)
	var nach_dem_ersten := statistik.games_done
	var spiele := []
	for monate: int in [180, 179]:
		for monat in monate:
			assert_false(statistik.run_for(0))
		spiele.append(_spiele_je_grad(statistik))

	# Assert: Gezählt wird der Seed erst nach dem letzten Grad, dann in allen.
	assert_eq([vor_dem_ersten, nach_dem_ersten], [0, 1])
	assert_eq(spiele, [[1, 1, 1], [1, 1, 1]], "Der angefangene Seed zählt in keinem Grad.")
	assert_eq(statistik.games_done, 1)


func test_results_for_liefert_den_grad_und_results_den_ersten() -> void:
	# Arrange: Schwer vor Leicht, ohne Mittel
	var katalog := _katalog(GRADE)
	var reihenfolge: Array[int] = [Difficulty.Level.SCHWER, Difficulty.Level.LEICHT]
	var statistik := TimelineStatistics.new(katalog, 30, 1, reihenfolge)
	var schwer := TimelineStatistics.new(katalog, 30, 1, [Difficulty.Level.SCHWER] as Array[int])
	var leicht := TimelineStatistics.new(katalog, 30, 1, [Difficulty.Level.LEICHT] as Array[int])

	# Act
	for einzeln in [statistik, schwer, leicht]:
		_bis_fertig(einzeln)

	# Assert
	assert_eq(statistik.difficulties, reihenfolge)
	assert_eq(_als_daten(statistik.results()), _als_daten(schwer.results()), "Der erste Grad.")
	assert_eq(_als_daten(statistik.results_for(Difficulty.Level.SCHWER)),
		_als_daten(schwer.results()))
	assert_eq(_als_daten(statistik.results_for(Difficulty.Level.LEICHT)),
		_als_daten(leicht.results()))
	assert_eq(statistik.results_for(Difficulty.Level.MITTEL).size(), 0, "Nicht in der Liste.")
	assert_eq(statistik.results_for(7).size(), 0, "Kein Grad.")
	var kopie := statistik.results_for(Difficulty.Level.LEICHT)
	kopie[0].games = -5
	assert_eq(statistik.results_for(Difficulty.Level.LEICHT)[0].games, 30,
		"Jeder Aufruf liefert neue Objekte.")


func test_sc_003_reklamationswelle_bei_mittel_und_schwer() -> void:
	# Arrange: 3 % pro Monat, „Leicht −2“ und „Schwer +5“; 1.000 Spiele in allen drei Graden
	var statistik := TimelineStatistics.new(_katalog(GRADE), 1000, 1, ALLE_GRADE)

	# Act
	_bis_fertig(statistik)

	# Assert: 180 Monate, Erwartung 1,8, 5,4 und 14,4
	var mittelwerte := {}
	for grad in ALLE_GRADE:
		var ergebnis := _ergebnis_fuer(statistik, grad, "reklamationswelle")
		assert_eq(ergebnis.games, 1000, Difficulty.label(grad))
		mittelwerte[Difficulty.label(grad)] = ergebnis.mean()
	gut.p("Reklamationswelle über 1.000 Spiele: Leicht %.3f, Mittel %.3f, Schwer %.3f"
		% [mittelwerte["Leicht"], mittelwerte["Mittel"], mittelwerte["Schwer"]])
	assert_between(mittelwerte["Mittel"], 4.9, 5.9, "SC-003, Mittel")
	assert_between(mittelwerte["Schwer"], 13.4, 15.4, "SC-003, Schwer")
	assert_lt(mittelwerte["Leicht"], mittelwerte["Mittel"], "Leicht −2 kommt seltener.")


func test_us4_szenario_2_zweimal_gerechnet_ist_der_vergleich_gleich() -> void:
	# Arrange: derselbe Vergleich zweimal, einmal in Häppchen von einem Monat
	var katalog := _katalog(GRADE)
	var haeppchen := TimelineStatistics.new(katalog, 10, 1, ALLE_GRADE)
	var am_stueck := TimelineStatistics.new(katalog, 10, 1, ALLE_GRADE)

	# Act
	while not haeppchen.run_for(0):
		pass
	_bis_fertig(am_stueck)

	# Assert
	for grad in ALLE_GRADE:
		assert_eq(_als_daten(haeppchen.results_for(grad)), _als_daten(am_stueck.results_for(grad)),
			Difficulty.label(grad))


func test_us4_szenario_3_unveraenderte_ereignisse_sind_in_allen_graden_gleich() -> void:
	# Arrange
	var statistik := TimelineStatistics.new(_katalog(GRADE), 200, 1, ALLE_GRADE)

	# Act
	_bis_fertig(statistik)

	# Assert: die Unabhängigen gleich, die Reklamationswelle nicht
	for kennung in UNABHAENGIGE:
		var mittel := _als_daten([_ergebnis_fuer(statistik, Difficulty.Level.MITTEL, kennung)])
		for grad: int in [Difficulty.Level.LEICHT, Difficulty.Level.SCHWER]:
			assert_eq(_als_daten([_ergebnis_fuer(statistik, grad, kennung)]), mittel,
				"%s bei %s" % [kennung, Difficulty.label(grad)])
	var welle := []
	for grad in ALLE_GRADE:
		welle.append(_ergebnis_fuer(statistik, grad, "reklamationswelle").total)
	assert_true(welle[0] < welle[1] and welle[1] < welle[2], "Reklamationswelle: %s" % str(welle))


func test_us4_szenario_4_eingriff_gilt_in_allen_graden() -> void:
	# Arrange: im Simulator „Lieferengpass −4 Prozentpunkte ab 01.01.1990“, also 0 % ab 1990
	var katalog := _katalog(GRADE)
	var simulator := TimelineRun.new(katalog, 4711)
	assert_eq(simulator.add_modifier(_engpass(-0.04)), OK)
	var statistik := TimelineStatistics.new(katalog, 100, 1, ALLE_GRADE)
	statistik.interventions = simulator.interventions
	var ohne := TimelineStatistics.new(katalog, 100, 1, ALLE_GRADE)

	# Act
	_bis_fertig(statistik)
	_bis_fertig(ohne)

	# Assert: in jedem Grad ab 1990 kein Lieferengpass mehr, und überall dieselben Werte
	var mittel := _ergebnis_fuer(statistik, Difficulty.Level.MITTEL, "lieferengpass")
	for grad in ALLE_GRADE:
		var engpass := _ergebnis_fuer(statistik, grad, "lieferengpass")
		assert_eq(_als_daten([engpass]), _als_daten([mittel]), Difficulty.label(grad))
		assert_eq(_summe(Array(engpass.per_year).slice(1990 - EventStatistic.FIRST_YEAR)), 0,
			"%s: ab 1990 kein Lieferengpass" % Difficulty.label(grad))
		assert_lt(engpass.total, _ergebnis_fuer(ohne, grad, "lieferengpass").total,
			"%s: Ohne Eingriff kommt er öfter." % Difficulty.label(grad))
	assert_eq([statistik.accepted, statistik.refused.size()], [1, 0], "Einmal, nicht je Grad.")


func test_angenommen_und_abgelehnt_nach_dem_ersten_grad() -> void:
	# Arrange: „reklamationswelle“ entfernen. Bei Schwer ist das ein Start-Modifikator, bei Mittel
	# gibt es den Modifikator nicht; beide lehnen ab, mit verschiedenem Grund. Dazu eine gültige
	# Einplanung.
	var katalog := _katalog(GRADE)
	var protokoll: Array[Dictionary] = [
		{"at_day": 100, "kind": TimelineRun.INTERVENTION_SCHEDULE, "event_id": "lieferengpass",
			"day": 200, "reason": "Spediteur streikt"},
		{"at_day": 300, "kind": TimelineRun.INTERVENTION_REMOVE_MODIFIER,
			"modifier": {"event_id": "reklamationswelle", "from_day": TimelineRun.FIRST_DAY,
				"id": "reklamationswelle", "reason": "Anspruchsvolle Kunden",
				"to_day": TimelineRun.LAST_DAY, "value": 0.05}},
	]
	var gruende := {}

	# Act
	for reihenfolge: Array[int] in [
			[Difficulty.Level.MITTEL, Difficulty.Level.SCHWER] as Array[int],
			[Difficulty.Level.SCHWER, Difficulty.Level.MITTEL] as Array[int]]:
		var statistik := TimelineStatistics.new(katalog, 3, 1, reihenfolge)
		statistik.interventions = protokoll
		_bis_fertig(statistik)
		assert_eq([statistik.accepted, statistik.refused.size()], [1, 1],
			"Einmal gezählt, nicht je Grad oder Spiel.")
		gruende[Difficulty.label(reihenfolge[0])] = statistik.refused[0]["reason"]

	# Assert: Der Grund kommt aus dem ersten Grad der Liste.
	assert_eq(gruende, {
		"Mittel": "Einen Modifikator mit der Kennung „reklamationswelle“ gibt es nicht.",
		"Schwer": "„reklamationswelle“ ist ein Start-Modifikator von Schwer und lässt sich im "
			+ "laufenden Spiel nicht entfernen.",
	})


# --- Helfer -----------------------------------------------------------------------------------

func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()


## Liest einen Test-Katalog und nimmt fehlerhafte Ereignisse aus, wie die Werkstatt es tut; die
## Test-Kataloge haben keine.
func _katalog(pfad: String) -> EventCatalog:
	var meldungen: Array[CatalogIssue] = []
	var katalog := EventCatalog.read_file(pfad, meldungen)
	meldungen.append_array(CatalogValidator.validate(katalog))
	assert_false(CatalogValidator.has_errors(meldungen), "%s hat keinen Fehler." % pfad)
	return katalog.without_faulty(meldungen)


func _bis_fertig(statistik: TimelineStatistics) -> void:
	while not statistik.run_for(1000):
		pass


## Rechnet die Statistik über [param spiele] Spiele und prüft sie gegen ebenso viele einzelne Läufe
## mit den Seeds 1 bis [param spiele]: Gezählt wird, was läuft, eingetreten oder beendet ist;
## entfallen und geplant zählt nicht. Gibt zurück, wie viele Termine dabei entfallen und wie viele
## am Ende noch geplant sind, als {"entfallen": int, "geplant": int}.
func _pruefe_zaehlung(pfad: String, spiele: int) -> Dictionary:
	var katalog := _katalog(pfad)
	var statistik := TimelineStatistics.new(katalog, spiele)
	_bis_fertig(statistik)
	var anzahlen := {}    # Kennung → Beginne je Spiel
	var jahre := {}       # Kennung → Beginne je Jahr über alle Spiele
	for event in katalog.events:
		anzahlen[event.id] = []
		var leer := []
		leer.resize(EventStatistic.YEARS)
		leer.fill(0)
		jahre[event.id] = leer
	var uebrig := {"entfallen": 0, "geplant": 0}
	for startwert in range(1, spiele + 1):
		var lauf := TimelineRun.new(katalog, startwert)
		lauf.advance_to(TimelineRun.LAST_DAY)
		var anzahl := {}
		for termin in lauf.entries:
			if termin.state == ScheduleEntry.State.SKIPPED:
				uebrig["entfallen"] += 1
			if termin.state == ScheduleEntry.State.PLANNED:
				uebrig["geplant"] += 1
			if termin.state in [ScheduleEntry.State.RUNNING, ScheduleEntry.State.OCCURRED,
					ScheduleEntry.State.ENDED]:
				anzahl[termin.event.id] = anzahl.get(termin.event.id, 0) + 1
				var jahr := GameDate.from_day_index(termin.day).year - EventStatistic.FIRST_YEAR
				jahre[termin.event.id][jahr] += 1
		for kennung: String in anzahlen:
			anzahlen[kennung].append(anzahl.get(kennung, 0))
	var kennungen := []
	for ergebnis in statistik.results():
		kennungen.append(ergebnis.event_id)
		var je_spiel: Array = anzahlen[ergebnis.event_id]
		var stelle := "%s in %s" % [ergebnis.event_id, pfad.get_file()]
		assert_eq([ergebnis.games, ergebnis.total, ergebnis.minimum, ergebnis.maximum,
			ergebnis.games_without], [spiele, _summe(je_spiel), je_spiel.min(), je_spiel.max(),
			je_spiel.count(0)], stelle)
		assert_eq(Array(ergebnis.per_year), jahre[ergebnis.event_id], stelle)
	var sortiert := kennungen.duplicate()
	sortiert.sort()
	assert_eq(kennungen, sortiert, "results() ist nach Kennung sortiert.")
	assert_eq(kennungen.size(), katalog.events.size(), "Jedes Ereignis hat eine Zeile.")
	return uebrig


func _ergebnis(statistik: TimelineStatistics, kennung: String) -> EventStatistic:
	for ergebnis in statistik.results():
		if ergebnis.event_id == kennung:
			return ergebnis
	fail_test("Keine Statistik für %s." % kennung)
	return EventStatistic.new()


func _ergebnis_fuer(statistik: TimelineStatistics, grad: int, kennung: String) -> EventStatistic:
	for ergebnis in statistik.results_for(grad):
		if ergebnis.event_id == kennung:
			return ergebnis
	fail_test("Keine Statistik für %s bei %s." % [kennung, Difficulty.label(grad)])
	return EventStatistic.new()


## Wie viele Spiele je Grad der Liste gezählt sind, am ersten Ereignis abgelesen.
func _spiele_je_grad(statistik: TimelineStatistics) -> Array:
	var spiele := []
	for grad in statistik.difficulties:
		spiele.append(statistik.results_for(grad)[0].games)
	return spiele


## [param wert] als Anteil auf den Lieferengpass, vom 01.01.1990 bis 31.12.1999.
func _engpass(wert: float) -> ChanceModifier:
	var modifikator := ChanceModifier.new()
	modifikator.id = "engpass"
	modifikator.event_id = "lieferengpass"
	modifikator.value = wert
	modifikator.reason = "Zweiter Großhändler"
	modifikator.from_day = _tag(1990, 1, 1)
	modifikator.to_day = TimelineRun.LAST_DAY
	return modifikator


## +[param wert] als Anteil auf „Nur mit Aktion“, vom 01.01.1985 bis 31.12.1999.
func _modifikator(wert: float) -> ChanceModifier:
	var modifikator := ChanceModifier.new()
	modifikator.id = "aktion"
	modifikator.event_id = "nur_mit_aktion"
	modifikator.value = wert
	modifikator.reason = "Aktion im Laden"
	modifikator.from_day = TimelineRun.FIRST_DAY
	modifikator.to_day = TimelineRun.LAST_DAY
	return modifikator


## Ein Modifikator, wie er im Eingriffsprotokoll unter "modifier" steht.
func _als_eintrag(modifikator: ChanceModifier) -> Dictionary:
	return {"event_id": modifikator.event_id, "from_day": modifikator.from_day,
		"id": modifikator.id, "reason": modifikator.reason, "to_day": modifikator.to_day,
		"value": modifikator.value}


func _summe(zahlen: Variant) -> int:
	var summe := 0
	for zahl: int in zahlen:
		summe += zahl
	return summe


## Die Ergebnisse als reine Daten, damit assert_eq() sie Feld für Feld vergleicht.
func _als_daten(ergebnisse: Array[EventStatistic]) -> Array:
	var daten := []
	for ergebnis in ergebnisse:
		daten.append([ergebnis.event_id, ergebnis.title, ergebnis.games, ergebnis.total,
			ergebnis.minimum, ergebnis.maximum, ergebnis.games_without, ergebnis.games_at_max,
			ergebnis.per_year])
	return daten
