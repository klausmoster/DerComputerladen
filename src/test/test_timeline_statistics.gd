extends GutTest

## Prüft die Statistik über viele Spiele (Feature 002, T064 und T065; FR-044, FR-045; US7,
## Szenarien 3 bis 6; SC-008): Mittelwert und Anteile über 1.000 Spiele, die Zählung der Beginne
## der Seeds 1 bis N, gleiche Ergebnisse bei Wiederholung, Eingriffe an ihrem Tag, die Obergrenze
## und das Zeitbudget von run_for().
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
