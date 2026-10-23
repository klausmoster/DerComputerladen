extends GutTest

## Prüft den Lauf der Zeitleiste. Teil 1 (Feature 002, T023): den Fahrplan aus fixen und beim
## Start gesetzten Terminen, die Würfelrunde, Modifikatoren, Bedingungen, Folgeereignisse mit
## Kettenbremse, den Tagesablauf und das Spielende. Dazu die Würfel (T020), Modifikatoren und
## Meldungen (T021). Teil 2 (T042): Ereignisse mit Dauer, Wirkungen „einmal“ und „während“,
## jährliche Ereignisse und die Kalender-Ereignisse (US3).
##
## Die Tests arbeiten mit kleinen Test-Katalogen res://test/fixtures/catalog_us1_*.json und
## catalog_us3_*.json, nie mit dem echten Katalog, und legen jeden Lauf selbst an; die Autoloads
## fassen sie nicht an. Wo ein Ergebnis vom Zufall abhängt, rechnet der Test mit denselben Würfeln
## nach (EventDice), statt eine Zahl festzuschreiben. So prüft er die Regeln aus dem Vertrag,
## Tabelle „Zwecke und Würfe“.

const ORDNER := "res://test/fixtures/"
const LETZTER_TAG := TimelineRun.LAST_DAY
## Kataloge, an denen „Tag für Tag“ gegen „in Sprüngen“ geprüft wird (US1, Szenario 8); die aus
## US3 prüfen dabei auch die Enden.
const KATALOGE_FUER_SPRUENGE := [
	"event_catalog_uebernahme", "catalog_us1_abstand", "catalog_us1_abstand_geplant",
	"catalog_us1_bedingungen", "catalog_us1_folgen", "catalog_us1_kette",
	"catalog_us1_tagesablauf", "catalog_us1_wuerfel", "catalog_us3_dauer",
	"catalog_us3_jaehrlich", "catalog_us3_kalender", "catalog_us3_laeuft_noch",
]


# --- Würfel, Modifikator, Meldung (T020, T021) ------------------------------------

func test_wuerfel_haengt_nur_von_seed_zweck_und_schluessel_ab() -> void:
	# Arrange: der Startwert nach R5, von Hand gerechnet
	var startwert := "4711|chance|reklamationswelle".sha256_buffer().decode_u64(0)

	# Act
	var a := EventDice.make(4711, "chance", "reklamationswelle")
	var b := EventDice.make(4711, "chance", "reklamationswelle")

	# Assert
	assert_eq(a.seed, startwert, "Startwert sind die ersten 8 Byte von SHA-256.")
	var folge_a := []
	var folge_b := []
	for i in 5:
		folge_a.append(a.randf())
		folge_b.append(b.randf())
	assert_eq(folge_a, folge_b, "Gleiche Eingabe, gleiche Folge.")
	var andere := [
		EventDice.make(4712, "chance", "reklamationswelle"),
		EventDice.make(4711, "preset", "reklamationswelle"),
		EventDice.make(4711, "chance", "grosskunde"),
	]
	for wuerfel: RandomNumberGenerator in andere:
		assert_ne(wuerfel.randf(), folge_a[0], "Anderer Seed, Zweck oder Schlüssel, andere Folge.")


func test_modifikator_gilt_vom_ersten_bis_zum_letzten_tag() -> void:
	# Arrange
	var modifikator := ChanceModifier.new()
	assert_false(modifikator.is_active(0), "Ohne Ende gilt er an keinem Tag.")

	# Act: „Ware vom windigen Händler“ vom 01.01.1990 bis 31.12.1993 (US6, Szenario 1)
	modifikator.from_day = _tag(1990, 1, 1)
	modifikator.to_day = _tag(1993, 12, 31)

	# Assert
	assert_false(modifikator.is_active(_tag(1989, 12, 31)))
	assert_true(modifikator.is_active(_tag(1990, 1, 1)), "Der erste Tag zählt mit.")
	assert_true(modifikator.is_active(_tag(1993, 12, 31)), "Der letzte Tag zählt mit.")
	assert_false(modifikator.is_active(_tag(1994, 1, 1)),
		"Ab dem Folgetag wirkt er nicht mehr (US6, Szenario 6).")


func test_meldung_als_zeile_mit_datum_art_und_text() -> void:
	# Arrange
	var meldung := TimelineMessage.new()
	meldung.day = _tag(1993, 3, 22)
	meldung.text = "Intel Pentium erscheint"
	var arten := ["Beginn", "Ende", "Wirkung", "Wirkungsende", "Entfall", "Kettenabbruch",
		"Eingriff", "Grad"]

	# Act und Assert
	assert_eq(meldung.to_line(), "22.03.1993  Beginn  Intel Pentium erscheint")
	assert_eq(TimelineMessage.Kind.size(), arten.size(), "Acht Arten, „Grad“ als achte.")
	assert_eq(TimelineMessage.Kind.START_MODIFIER, 7,
		"Die neue Art steht am Ende; die übrigen behalten ihre Nummern (Feature 003, T009).")
	for art: int in TimelineMessage.Kind.values():
		meldung.kind = art as TimelineMessage.Kind
		assert_eq(meldung.to_line(), "22.03.1993  %s  Intel Pentium erscheint" % arten[art])


# --- Fahrplan beim Anlegen (FR-010) -----------------------------------------------

func test_fixe_termine_stehen_ab_spielbeginn_an_ihrem_tag() -> void:
	# Arrange
	var catalog := _katalog("catalog_us1_tagesablauf")

	# Act: nur angelegt, noch nichts abgespielt
	var run := TimelineRun.new(catalog, 4711)

	# Assert
	assert_eq(run.today, -1)
	assert_eq(run.protocol.size(), 0)
	var fixe := 0
	for event in catalog.events:
		if event.kind != TimelineEvent.Kind.FIXED:
			continue
		fixe += 1
		var termine := _termine(run, event.id)
		assert_eq(termine.size(), 1, "Ein Termin für %s." % event.id)
		if termine.size() != 1:
			continue
		assert_eq(termine[0].day, event.date, "%s an seinem Tag." % event.id)
		assert_eq(termine[0].end_day, event.date, "Ohne Dauer endet er am selben Tag.")
		assert_eq(termine[0].origin_label(), "fix")
		assert_eq(termine[0].state, ScheduleEntry.State.PLANNED)
	assert_eq(fixe, 4, "Der Test-Katalog hat vier fixe Ereignisse.")


func test_gesetzte_termine_liegen_im_fenster_und_halten_den_abstand() -> void:
	# Arrange (US1, Szenario 3): Zeitfenster 1987 bis 1996, Anzahl 1 bis 2, Mindestabstand
	# 3 Jahre (1095 Tage)
	var catalog := _katalog("catalog_us1_preset")
	var neubau := catalog.get_event("neubaugebiet_am_stadtrand")
	var anzahlen := {}

	for seed_wert in range(1, 101):
		# Act
		var run := TimelineRun.new(catalog, seed_wert)
		var termine := _termine(run, neubau.id)

		# Assert
		anzahlen[termine.size()] = true
		assert_between(termine.size(), 1, 2, "Seed %d: ein oder zwei Termine." % seed_wert)
		for termin in termine:
			assert_between(termin.day, neubau.window_from, neubau.window_to,
				"Seed %d: im Zeitfenster." % seed_wert)
			assert_eq(termin.origin_label(), "gesetzt")
			assert_eq(termin.state, ScheduleEntry.State.PLANNED, "Steht ab Spielbeginn fest.")
		if termine.size() == 2:
			assert_gte(termine[1].day - termine[0].day, 1095, "Seed %d: Abstand." % seed_wert)
	assert_eq(anzahlen.size(), 2, "Über 100 Seeds kommen beide Anzahlen vor.")


func test_gesetzte_termine_unterscheiden_sich_je_seed_und_wiederholen_sich() -> void:
	# Arrange (US1, Szenario 4)
	var catalog := _katalog("catalog_us1_preset")
	var kennung := "neubaugebiet_am_stadtrand"

	# Act
	var seed_1 := _tage(TimelineRun.new(catalog, 1), kennung)
	var seed_2 := _tage(TimelineRun.new(catalog, 2), kennung)
	var abgespielt := TimelineRun.new(catalog, 2)
	abgespielt.advance_to(LETZTER_TAG)

	# Assert
	assert_ne(seed_1, seed_2, "Seed 1 und Seed 2 ergeben andere Termine.")
	assert_eq(_tage(TimelineRun.new(catalog, 1), kennung), seed_1, "Seed 1 wiederholt sich.")
	assert_eq(_tage(TimelineRun.new(catalog, 2), kennung), seed_2, "Seed 2 wiederholt sich.")
	assert_eq(_tage(abgespielt, kennung), seed_2, "Abspielen ändert die gesetzten Termine nicht.")
	for termin in _termine(abgespielt, kennung):
		assert_eq(termin.state, ScheduleEntry.State.OCCURRED)


func test_gesetzte_termine_nach_r7() -> void:
	# Arrange
	var catalog := _katalog("catalog_us1_preset")
	var neubau := catalog.get_event("neubaugebiet_am_stadtrand")
	var abstand := neubau.min_gap_days

	for seed_wert in range(1, 21):
		# Derselbe Würfel wie im Lauf: erst die Anzahl, dann k Zahlen, aufsteigend sortiert.
		var wuerfel := EventDice.make(seed_wert, "preset", neubau.id)
		var anzahl := neubau.count_min \
			+ wuerfel.rand_weighted(PackedFloat32Array(neubau.count_weights))
		var spielraum := neubau.window_to - neubau.window_from - (anzahl - 1) * abstand
		var zahlen := []
		for i in anzahl:
			zahlen.append(wuerfel.randi_range(0, spielraum))
		zahlen.sort()
		var erwartet := []
		for i in anzahl:
			erwartet.append(neubau.window_from + zahlen[i] + i * abstand)

		# Act
		var tage := _tage(TimelineRun.new(catalog, seed_wert), neubau.id)

		# Assert
		assert_eq(tage, erwartet, "Seed %d nach R7." % seed_wert)


# --- Würfelrunde (R8) ------------------------------------------------------------

func test_hundert_prozent_tritt_schon_im_januar_1985_ein() -> void:
	# Arrange (US1, Szenario 6)
	var run := TimelineRun.new(_katalog("catalog_us1_wuerfel"), 4711)

	# Act
	var meldungen := run.advance_to(_tag(1985, 1, 31))

	# Assert
	var termine := _termine(run, "immer")
	assert_eq(termine.size(), 1, "Genau ein Termin im Januar 1985.")
	if termine.size() != 1:
		return
	var termin := termine[0]
	assert_between(termin.day, _tag(1985, 1, 1), _tag(1985, 1, 31))
	assert_eq(termin.state, ScheduleEntry.State.OCCURRED)
	assert_has(_zeilen(meldungen), "%s  Beginn  Jeden Monat" % GameDate.from_day_index(termin.day))
	# Szenario 7: Herkunft „gewürfelt“, mit Würfelwert und der Schwelle, die er unterschreiten
	# musste.
	assert_eq(termin.origin_label(), "gewürfelt")
	assert_eq([termin.threshold, termin.base_chance], [1.0, 1.0])
	assert_true(termin.roll >= 0.0 and termin.roll < termin.threshold, "Wurf unter der Schwelle.")
	assert_eq(termin.explain(),
		"Würfel %s < Schwelle 1,0000 (100 %%)" % _vier_stellen_abgerundet(termin.roll))


func test_jeder_monat_wuerfelt_genau_zweimal_auch_ohne_chance() -> void:
	# Arrange: „Nur Mitte März 1990“ kommt nur im Monat 62 in Frage, vom 10. bis 20. März. Zieht
	# der Würfel in jedem Monat davor genau zwei Zahlen, sind Wurf und Tag die 125. und 126.
	# Zahl, egal ob das Ereignis vorher in Frage kam.
	var maerz_1990 := (1990 - 1985) * 12 + 2
	var wuerfel := EventDice.make(4711, "chance", "teilmonat")
	for i in 2 * maerz_1990:
		wuerfel.randf()
	var wurf := wuerfel.randf()
	var anteil := wuerfel.randf()
	var erster := _tag(1990, 3, 10)
	var run := TimelineRun.new(_katalog("catalog_us1_wuerfel"), 4711)

	# Act
	run.advance_to(LETZTER_TAG)

	# Assert
	var termine := _termine(run, "teilmonat")
	assert_eq(termine.size(), 1, "Nur im März 1990.")
	if termine.size() == 1:
		assert_eq(termine[0].roll, wurf, "Der Wurf ist der aus Monat 62.")
		assert_eq(termine[0].day, erster + mini(int(anteil * 11), 10),
			"Der Tag ist der gewürfelte Teil der 11 Tage im Fenster.")
		assert_between(termine[0].day, erster, _tag(1990, 3, 20))
	# „Jeden Monat“ kommt in jedem der 180 Monate, mit dem ersten Wurf des Monats.
	var immer := _termine(run, "immer")
	var jeder_monat := EventDice.make(4711, "chance", "immer")
	assert_eq(immer.size(), TimelineRun.MONTHS)
	for monat in mini(immer.size(), TimelineRun.MONTHS):
		assert_eq(_monat(immer[monat].day), monat)
		assert_eq(immer[monat].roll, jeder_monat.randf(), "Wurf in Monat %d." % monat)
		jeder_monat.randf()


func test_hoechstzahl_begrenzt_die_termine() -> void:
	# Arrange: 100 % pro Monat, höchstens dreimal
	var run := TimelineRun.new(_katalog("catalog_us1_wuerfel"), 4711)

	# Act
	run.advance_to(LETZTER_TAG)

	# Assert
	var monate := []
	for termin in _termine(run, "dreimal"):
		monate.append(_monat(termin.day))
	assert_eq(monate, [0, 1, 2], "Januar bis März 1985, danach nicht mehr.")


func test_hundert_prozent_trifft_auch_mit_dem_wurf_eins() -> void:
	# Arrange: Mit Seed 102559 würfelt „Jeden Monat“ im April 1997 genau 1,0. randf() kann das
	# liefern; mit „Wurf < Schwelle“ allein fiele dieser Termin weg (R8). Der Seed ist gesucht und
	# gilt für Godot 4.7.2; die erste Prüfung sagt, falls sich das ändert.
	var april_1997 := (1997 - 1985) * 12 + 3
	var wuerfel := EventDice.make(102559, "chance", "immer")
	for i in 2 * april_1997:
		wuerfel.randf()
	assert_eq(wuerfel.randf(), 1.0, "Voraussetzung: Seed 102559 würfelt im April 1997 genau 1,0.")
	var run := TimelineRun.new(_katalog("catalog_us1_wuerfel"), 102559)

	# Act
	run.advance_to(LETZTER_TAG)

	# Assert
	var termine := _termine(run, "immer")
	assert_eq(termine.size(), TimelineRun.MONTHS, "Ein Termin in jedem Monat, auch im April 1997.")
	var april: Array[ScheduleEntry] = []
	for termin in termine:
		if _monat(termin.day) == april_1997:
			april.append(termin)
	assert_eq(april.size(), 1)
	if april.size() == 1:
		assert_eq([april[0].roll, april[0].threshold], [1.0, 1.0])
		assert_eq(april[0].explain(), "Würfel 1,0000 ≤ Schwelle 1,0000 (100 %)")


func test_modifikator_verschiebt_die_schwelle_nicht_den_wurf() -> void:
	# Arrange: „Selten“ hat 3 %; zwei Modifikatoren bringen 1990 +50 und −2,5 Prozentpunkte.
	var catalog := _katalog("catalog_us1_wuerfel")
	var ohne := TimelineRun.new(catalog, 4711)
	var mit := TimelineRun.new(catalog, 4711)
	mit.modifiers.append(_modifikator("test", "selten", 0.5, "Testmodifikator",
		_tag(1990, 1, 1), _tag(1990, 12, 31)))
	mit.modifiers.append(_modifikator("abzug", "selten", -0.025, "Abzug",
		_tag(1990, 1, 1), _tag(1990, 12, 31)))

	# Act
	ohne.advance_to(LETZTER_TAG)
	mit.advance_to(LETZTER_TAG)

	# Assert: Außerhalb von 1990 ist alles gleich, Termine, Würfe und Schwellen.
	assert_eq(_spuren(mit, "selten", false), _spuren(ohne, "selten", false))
	# 1990 kommt ein Termin in jedem Monat, dessen Wurf unter 50,5 % lag.
	var wuerfel := EventDice.make(4711, "chance", "selten")
	var erwartet := []
	for monat in TimelineRun.MONTHS:
		var wurf := wuerfel.randf()
		wuerfel.randf()
		if monat >= 60 and monat < 72 and wurf < 0.03 + 0.5 - 0.025:
			erwartet.append(monat)
	var gefunden := []
	for termin in _termine(mit, "selten"):
		if GameDate.from_day_index(termin.day).year != 1990:
			continue
		gefunden.append(_monat(termin.day))
		assert_almost_eq(termin.threshold, 0.505, 1e-9, "Schwelle mit Modifikatoren.")
		assert_eq(termin.base_chance, 0.03, "Die Grundchance bleibt.")
		assert_eq(termin.modifier_notes, PackedStringArray(["Testmodifikator +50", "Abzug -2,5"]),
			"Je Modifikator Grund und Wert in Prozentpunkten.")
		assert_string_contains(termin.explain(), "(3 % + Testmodifikator +50 + Abzug -2,5)")
	assert_gt(erwartet.size(), 0, "Mit 50,5 % kommt 1990 mindestens ein Termin.")
	assert_eq(gefunden, erwartet)


func test_chance_info_summiert_und_begrenzt() -> void:
	# Arrange (US6, Szenario 3): 3 % Grundchance, Modifikatoren +4 und −6 Prozentpunkte
	var run := TimelineRun.new(_katalog("catalog_us1_wuerfel"), 4711)
	var plus := _modifikator("plus", "selten", 0.04, "Plus", 0, LETZTER_TAG)
	var minus := _modifikator("minus", "selten", -0.06, "Minus", 0, LETZTER_TAG)
	run.modifiers.assign([plus, minus])
	var tag := _tag(1990, 6, 1)

	# Act
	var beide := run.chance_info("selten", tag)
	run.modifiers.erase(plus)
	var nur_minus := run.chance_info("selten", tag)
	minus.from_day = _tag(1991, 1, 1)
	var noch_nicht := run.chance_info("selten", tag)

	# Assert
	assert_almost_eq(beide["base"], 0.03, 1e-9)
	assert_almost_eq(beide["sum"], 0.01, 1e-9, "3 % + 4 − 6 ergibt 1 %.")
	assert_almost_eq(beide["effective"], 0.01, 1e-9)
	assert_eq(beide["modifiers"].size(), 2)
	assert_almost_eq(nur_minus["sum"], -0.03, 1e-9, "Die Summe zeigt −3 %.")
	assert_eq(nur_minus["effective"], 0.0, "Wirksam ist sie auf 0 % begrenzt.")
	assert_eq(nur_minus["modifiers"].size(), 1)
	assert_almost_eq(noch_nicht["sum"], 0.03, 1e-9, "Vor seinem Beginn gilt er nicht.")
	assert_eq(noch_nicht["modifiers"].size(), 0)
	assert_eq(run.chance_info("gibt_es_nicht", tag)["base"], 0.0, "Unbekannt heißt 0.")


# --- Tag für Tag oder in Sprüngen (US1, Szenario 8) ------------------------------

func test_tag_fuer_tag_ergibt_dasselbe_wie_spruenge(
		datei: String = use_parameters(KATALOGE_FUER_SPRUENGE)) -> void:
	# Arrange
	var catalog := _katalog(datei)
	var am_stueck := TimelineRun.new(catalog, 4711)
	var taeglich := TimelineRun.new(catalog, 4711)
	var in_spruengen := TimelineRun.new(catalog, 4711)
	var rueckgaben: Array[TimelineMessage] = []

	# Act
	am_stueck.advance_to(LETZTER_TAG)
	for tag in range(0, LETZTER_TAG + 1):
		rueckgaben.append_array(taeglich.advance_to(tag))
	_in_spruengen(in_spruengen)

	# Assert
	var protokoll := _zeilen(am_stueck.protocol)
	assert_gt(protokoll.size(), 0, "%s meldet etwas." % datei)
	assert_eq(_zeilen(taeglich.protocol), protokoll, "%s Tag für Tag." % datei)
	assert_eq(_zeilen(rueckgaben), protokoll, "Die Rückgaben ergeben zusammen das Protokoll.")
	assert_eq(_zeilen(in_spruengen.protocol), protokoll, "%s in Sprüngen." % datei)
	assert_eq(_fahrplan(taeglich), _fahrplan(am_stueck))
	assert_eq(_fahrplan(in_spruengen), _fahrplan(am_stueck))


# --- Unabhängige Würfel (FR-015) -------------------------------------------------

func test_fr015_geaenderte_chance_aendert_nur_das_ereignis_und_abhaengige() -> void:
	for seed_wert in [1, 2, 3, 4711]:
		# Arrange: folge_d und bedingt_e hängen von wuerfel_d ab, die anderen nicht.
		var vorher := _spuren_je_ereignis(_katalog("catalog_us1_unabhaengig"), seed_wert)
		var geaendert := _katalog("catalog_us1_unabhaengig")
		geaendert.get_event("wuerfel_d").monthly_chance = 0.5

		# Act
		var nachher := _spuren_je_ereignis(geaendert, seed_wert)

		# Assert
		for kennung: String in ["fest_a", "gesetzt_b", "wuerfel_c"]:
			assert_eq(nachher[kennung], vorher[kennung], "Seed %d: %s." % [seed_wert, kennung])
		assert_ne(nachher["wuerfel_d"], vorher["wuerfel_d"], "Das geänderte Ereignis ändert sich.")


func test_fr015_neues_ereignis_aendert_keine_anderen_termine() -> void:
	for seed_wert in [1, 2, 3, 4711]:
		# Arrange: ein neues Ereignis über Wahrscheinlichkeit, dessen Kennung vor allen anderen
		# steht, und ein neues fixes am Tag von „Fest A“
		var vorher := _spuren_je_ereignis(_katalog("catalog_us1_unabhaengig"), seed_wert)
		var erweitert := _katalog("catalog_us1_unabhaengig")
		var neu := erweitert.get_event("wuerfel_c").duplicate_event()
		neu.id = "aaa_neu"
		neu.monthly_chance = 0.5
		var auch_neu := erweitert.get_event("fest_a").duplicate_event()
		auch_neu.id = "zzz_neu"
		erweitert.events.append_array([neu, auch_neu])

		# Act
		var nachher := _spuren_je_ereignis(erweitert, seed_wert)

		# Assert
		assert_gt(nachher["aaa_neu"].size(), 0, "Das neue Ereignis kommt vor.")
		for kennung: String in vorher:
			assert_eq(nachher[kennung], vorher[kennung], "Seed %d: %s." % [seed_wert, kennung])


func test_fr015_geloeschtes_ereignis_aendert_keine_anderen_termine() -> void:
	for seed_wert in [1, 2, 3, 4711]:
		# Arrange
		var vorher := _spuren_je_ereignis(_katalog("catalog_us1_unabhaengig"), seed_wert)
		var gekuerzt := _katalog("catalog_us1_unabhaengig")
		gekuerzt.events.erase(gekuerzt.get_event("wuerfel_c"))

		# Act
		var nachher := _spuren_je_ereignis(gekuerzt, seed_wert)

		# Assert
		assert_false(nachher.has("wuerfel_c"))
		for kennung: String in ["bedingt_e", "fest_a", "folge_d", "gesetzt_b", "wuerfel_d"]:
			assert_eq(nachher[kennung], vorher[kennung], "Seed %d: %s." % [seed_wert, kennung])


# --- Mindestabstand und Höchstzahl (FR-005) --------------------------------------

func test_mindestabstand_zaehlt_nur_termine_die_nicht_entfallen_sind() -> void:
	# Arrange: „Start Z“ am 05.03.1990 bringt X als Folge am selben Tag. X braucht W, das erst am
	# 20.03. eintritt, also entfällt der Folgetermin. X hat 100 % und 60 Tage Mindestabstand.
	var run := TimelineRun.new(_katalog("catalog_us1_abstand"), 4711)
	var frueher := _katalog("catalog_us1_abstand")
	frueher.get_event("w_bedingung").date = _tag(1990, 3, 1)
	var gegenprobe := TimelineRun.new(frueher, 4711)

	# Act
	run.advance_to(_tag(1990, 4, 30))
	gegenprobe.advance_to(_tag(1990, 4, 30))

	# Assert: Der entfallene Termin zählt nicht, X kommt im April.
	var termine := _termine(run, "x_wuerfel")
	assert_eq(termine.size(), 2, "Der entfallene Folgetermin und einer im April.")
	if termine.size() == 2:
		assert_eq(termine[0].day, _tag(1990, 3, 5))
		assert_eq(termine[0].state_label(), "entfallen")
		assert_eq(termine[0].note,
			"Bedingung nicht erfüllt, „Bedingung W“ ist noch nicht eingetreten")
		assert_eq(termine[1].origin_label(), "gewürfelt")
		assert_eq(_monat(termine[1].day), _monat(_tag(1990, 4, 1)))
		assert_eq(termine[1].state, ScheduleEntry.State.OCCURRED)
	# Gegenprobe: Tritt W schon am 01.03. ein, beginnt der Folgetermin, und im April ist der
	# Abstand zu ihm kürzer als 60 Tage. Vor dem März würfelt X gar nicht, die Bedingung fehlt.
	var gegen := _termine(gegenprobe, "x_wuerfel")
	assert_eq(gegen.size(), 1, "Nur der Folgetermin.")
	if gegen.size() == 1:
		assert_eq(gegen[0].state_label(), "eingetreten")
		assert_eq(gegen[0].origin_label(), "Folge von Start Z")


func test_mindestabstand_gilt_auch_zu_einem_geplanten_termin() -> void:
	# Arrange: „Start Z“ plant am 05.01.1990 X als Folge für den 15.04.1990. X würfelt von
	# Februar bis Dezember 1990 mit 100 % und hat 20 Tage Mindestabstand, in beide Richtungen.
	var catalog := _katalog("catalog_us1_abstand_geplant")
	var geplant := _tag(1990, 4, 15)
	var februar := _monat(_tag(1990, 2, 1))
	var april := _monat(_tag(1990, 4, 1))

	for seed_wert in range(1, 21):
		# Act
		var run := TimelineRun.new(catalog, seed_wert)
		run.advance_to(LETZTER_TAG)

		# Assert: Der Februar liegt ganz mindestens 20 Tage vor dem geplanten Termin, jeder Tag
		# im April zu nah daran.
		var tage := _tage(run, "x_wuerfel")
		var gewuerfelt := []
		for termin in _termine(run, "x_wuerfel"):
			if termin.origin == ScheduleEntry.Origin.ROLLED:
				gewuerfelt.append(_monat(termin.day))
		assert_has(tage, geplant, "Seed %d: Der geplante Termin bleibt." % seed_wert)
		assert_has(gewuerfelt, februar, "Seed %d: Im Februar ist Platz." % seed_wert)
		assert_does_not_have(gewuerfelt, april, "Seed %d: Im April ist kein Platz." % seed_wert)
		for i in tage.size():
			for j in range(i + 1, tage.size()):
				assert_gte(absi(tage[j] - tage[i]), 20, "Seed %d: 20 Tage Abstand." % seed_wert)
	# Mindestabstand 0 heißt keine Prüfung: Dann wird auch im April gewürfelt.
	catalog.get_event("x_wuerfel").min_gap_days = 0
	var ohne_abstand := TimelineRun.new(catalog, 1)
	ohne_abstand.advance_to(LETZTER_TAG)
	var im_april := []
	for termin in _termine(ohne_abstand, "x_wuerfel"):
		if _monat(termin.day) == april:
			im_april.append(termin.origin_label())
	im_april.sort()
	assert_eq(im_april, ["Folge von Start Z", "gewürfelt"])


func test_hoechstzahl_zaehlt_entfallene_termine_nicht() -> void:
	# Arrange: wie oben, aber ohne Mindestabstand und mit Höchstzahl 2
	var catalog := _katalog("catalog_us1_abstand")
	var x := catalog.get_event("x_wuerfel")
	x.min_gap_days = 0
	x.max_occurrences = 2
	var run := TimelineRun.new(catalog, 4711)
	catalog.get_event("w_bedingung").date = _tag(1990, 3, 1)
	var gegenprobe := TimelineRun.new(catalog, 4711)

	# Act
	run.advance_to(LETZTER_TAG)
	gegenprobe.advance_to(LETZTER_TAG)

	# Assert
	assert_eq(_kurz(run, "x_wuerfel"), [
		"03.1990 Folge von Start Z entfallen",
		"04.1990 gewürfelt eingetreten",
		"05.1990 gewürfelt eingetreten",
	], "Der entfallene Termin zählt nicht: zwei gewürfelte.")
	assert_eq(_kurz(gegenprobe, "x_wuerfel"), [
		"03.1990 Folge von Start Z eingetreten",
		"04.1990 gewürfelt eingetreten",
	], "Der eingetretene Folgetermin zählt mit.")


# --- Bedingungen (FR-006) --------------------------------------------------------

func test_bedingung_eingetreten_heisst_bis_zum_vortag_begonnen() -> void:
	# Arrange: „Basis“ beginnt am 10.05.1990. Folgetermine von „Start“ fragen am 01., 10. und
	# 11.05. danach, dazu zwei gesetzte Termine am 10. und 11.05.
	var run := TimelineRun.new(_katalog("catalog_us1_bedingungen"), 4711)
	run.advance_to(_tag(1990, 5, 9))

	# Act
	var am_basistag := run.advance_to(_tag(1990, 5, 10))
	run.advance_to(_tag(1990, 5, 31))

	# Assert
	assert_eq(_zustaende(run, "braucht_basis"),
		["01.05.1990 entfallen", "10.05.1990 entfallen", "11.05.1990 eingetreten"],
		"Schon eingetreten: erst ab dem Tag nach dem Beginn.")
	assert_eq(_zustaende(run, "ohne_basis"), ["10.05.1990 eingetreten", "11.05.1990 entfallen"],
		"Noch nicht eingetreten: am Tag des Beginns noch wahr.")
	assert_eq(_zustaende(run, "gesetzt_am_basistag"), ["10.05.1990 entfallen"])
	assert_eq(_zustaende(run, "gesetzt_danach"), ["11.05.1990 eingetreten"])
	assert_eq(_zeilen(am_basistag), [
		"10.05.1990  Beginn  Basis",
		"10.05.1990  Entfall  Gesetzt am Basistag: Bedingung nicht erfüllt, „Basis“ ist noch "
			+ "nicht eingetreten",
		"10.05.1990  Entfall  Braucht Basis: Bedingung nicht erfüllt, „Basis“ ist noch nicht "
			+ "eingetreten",
		"10.05.1990  Beginn  Nur ohne Basis",
	], "Die Reihenfolge am Tag entscheidet nichts: Basis beginnt zuerst und zählt trotzdem nicht.")
	var spaeter := _termine(run, "ohne_basis")[1]
	assert_eq(spaeter.explain(), "Würfel %s < 100 %%, Folge von Start; entfallen: Bedingung "
		% _vier_stellen_abgerundet(spaeter.roll) + "nicht erfüllt, „Basis“ ist schon eingetreten")


# --- Folgeereignisse und Kettenbremse (R10) --------------------------------------

func test_folgeereignis_wuerfelt_chance_und_verzoegerung_mit_eigenem_wuerfel() -> void:
	# Arrange: „Auslöser“ am 10.05.1990 bringt „Folge mit Spanne“ zu 50 %, 7 bis 21 Tage später.
	var catalog := _katalog("catalog_us1_folgen")
	var tag := _tag(1990, 5, 10)
	var mit_folge := 0
	var ohne_folge := 0

	for seed_wert in range(1, 31):
		# Derselbe Würfel wie im Lauf, Schlüssel "<quelle>|<index>|<tag>"
		var wuerfel := EventDice.make(seed_wert, "follow", "ausloeser|0|%d" % tag)
		var wurf := wuerfel.randf()
		var verzoegerung := wuerfel.randi_range(7, 21)
		var run := TimelineRun.new(catalog, seed_wert)

		# Act: bis zum Tag des Auslösers; die Entscheidung steht dann schon im Fahrplan (FR-011)
		run.advance_to(tag)

		# Assert
		var termine := _termine(run, "folge")
		if wurf >= 0.5:
			ohne_folge += 1
			assert_eq(termine.size(), 0, "Seed %d: Wurf %f, keine Folge." % [seed_wert, wurf])
			continue
		mit_folge += 1
		assert_eq(termine.size(), 1, "Seed %d: Wurf %f, eine Folge." % [seed_wert, wurf])
		if termine.size() != 1:
			continue
		var termin := termine[0]
		assert_eq(termin.day, tag + verzoegerung, "Seed %d: Tag aus der Spanne." % seed_wert)
		assert_eq(termin.state, ScheduleEntry.State.PLANNED, "Geplant vor seinem Tag.")
		assert_eq([termin.roll, termin.threshold, termin.base_chance], [wurf, 0.5, 0.5])
		assert_eq([termin.source_event_id, termin.origin_label()],
			["ausloeser", "Folge von Auslöser"])
		assert_eq(termin.explain(),
			"Würfel %s < 50 %%, Folge von Auslöser" % _vier_stellen_abgerundet(wurf))
		run.advance_to(LETZTER_TAG)
		assert_eq(termin.state, ScheduleEntry.State.OCCURRED, "An seinem Tag tritt er ein.")
	assert_gt(mit_folge, 0, "Unter 30 Seeds kommt die Folge mal.")
	assert_gt(ohne_folge, 0, "Unter 30 Seeds bleibt sie auch mal aus.")


func test_folge_mit_hundert_prozent_kommt_auch_mit_dem_wurf_eins() -> void:
	# Arrange: Mit Seed 5078961 würfelt die Folge des Auslösers am 10.05.1990 genau 1,0; ihre
	# Wahrscheinlichkeit steht hier auf 100 % (R10). Der Seed ist gesucht und gilt für Godot 4.7.2.
	var tag := _tag(1990, 5, 10)
	var wuerfel := EventDice.make(5078961, "follow", "ausloeser|0|%d" % tag)
	assert_eq(wuerfel.randf(), 1.0, "Voraussetzung: Seed 5078961 würfelt die Folge mit 1,0.")
	var catalog := _katalog("catalog_us1_folgen")
	catalog.get_event("ausloeser").follow_ups[0].chance = 1.0
	var run := TimelineRun.new(catalog, 5078961)

	# Act
	run.advance_to(tag)

	# Assert
	var termine := _termine(run, "folge")
	assert_eq(termine.size(), 1, "Mit 100 % kommt die Folge immer.")
	if termine.size() == 1:
		assert_eq([termine[0].roll, termine[0].threshold], [1.0, 1.0])
		assert_eq(termine[0].explain(), "Würfel 1,0000 ≤ 100 %, Folge von Auslöser")


func test_kettenbremse_zaehlt_je_kette() -> void:
	# Arrange: „Start A“ und „Start B“ beginnen am 10.05.1990 je eine Kette Kette 01 → Kette 02 →
	# …, alle mit 100 % und ohne Verzögerung. Der Start ist das erste Glied, Kette 15 das 16.
	var run := TimelineRun.new(_katalog("catalog_us1_kette"), 4711)

	# Act
	var meldungen := run.advance_to(_tag(1990, 5, 10))

	# Assert
	var beginne := 0
	var abbrueche: Array[TimelineMessage] = []
	for meldung in meldungen:
		if meldung.kind == TimelineMessage.Kind.EVENT_STARTED:
			beginne += 1
		elif meldung.kind == TimelineMessage.Kind.CHAIN_STOPPED:
			abbrueche.append(meldung)
	assert_eq(beginne, 32, "Je Kette 16 Glieder: der Start und Kette 01 bis 15.")
	assert_eq(abbrueche.size(), 2, "In jeder Kette entfällt das 17. Glied, nicht schon das 17. "
		+ "Glied des Tags.")
	for meldung in abbrueche:
		assert_eq(meldung.event.id, "kette_16")
		assert_eq(meldung.entry.state, ScheduleEntry.State.SKIPPED)
		assert_eq(meldung.to_line(), "10.05.1990  Kettenabbruch  Kette 16: Glied 17 einer Kette "
			+ "am selben Tag, erlaubt sind 16")
	for nummer in range(1, 17):
		assert_eq(_termine(run, "kette_%02d" % nummer).size(), 2, "Kette %02d je Kette." % nummer)
	assert_eq(_termine(run, "kette_17").size(), 0, "Nach dem Abbruch kommt nichts mehr.")


func test_folge_mit_verzoegerung_beginnt_eine_neue_kette() -> void:
	# Arrange: Kette 15 ist das 16. Glied. Ihr Folgeereignis „Danach“ kommt einen Tag später und
	# ist dort das erste Glied einer neuen Kette.
	var run := TimelineRun.new(_katalog("catalog_us1_kette"), 4711)
	run.advance_to(_tag(1990, 5, 10))

	# Act
	var meldungen := run.advance_to(_tag(1990, 5, 11))

	# Assert
	var zeile := "11.05.1990  Beginn  Danach, mit einem Tag Verzögerung"
	assert_eq(_zeilen(meldungen), [zeile, zeile], "Einmal je Kette.")


# --- Tagesablauf (FR-016) --------------------------------------------------------

func test_tagesablauf_wirkungen_dann_beginne_nach_herkunft_kennung_und_nummer() -> void:
	# Arrange: Am 01.04.1990 wird eine Wirkung von „A mit Verzögerung“ fällig. Es beginnen zwei
	# fixe Termine, ein gesetzter, ein gewürfelter und eine Folge von „ZZ vorher“; „B fix“ bringt
	# eine Folge ohne Verzögerung.
	var run := TimelineRun.new(_katalog("catalog_us1_tagesablauf"), 4711)
	var tag := _tag(1990, 4, 1)
	run.advance_to(tag - 1)

	# Act
	var meldungen := run.advance_to(tag)

	# Assert: erst die verzögerte Wirkung, dann die Beginne nach Herkunft und Kennung, die
	# Folge von heute hinten an, auch hinter „ZZ Folge“.
	assert_eq(_zeilen(meldungen), [
		"01.04.1990  Wirkung  A mit Verzögerung: Nachfrage · ram · +10% — Kommt zwei Wochen "
			+ "später.",
		"01.04.1990  Beginn  B fix",
		"01.04.1990  Wirkung  B fix: Presse · messe — Sofort.",
		"01.04.1990  Beginn  Z fix",
		"01.04.1990  Beginn  A gesetzt",
		"01.04.1990  Beginn  C gewürfelt",
		"01.04.1990  Beginn  ZZ Folge",
		"01.04.1990  Beginn  Folge von B",
	])
	# Der Fahrplan zeigt den Tag in derselben Reihenfolge.
	var am_tag := []
	for termin in run.entries:
		if termin.day == tag:
			am_tag.append(termin.event.id)
	assert_eq(am_tag, ["b_fix", "z_fix", "a_preset", "c_wuerfel", "zz_folge", "folge_b"])


# --- Spielende (FR-019) und Abfragen ---------------------------------------------

func test_nach_dem_31_12_1999_kommt_keine_meldung_mehr() -> void:
	# Arrange: „Spät im Jahr“ am 25.12.1999 hätte eine Wirkung am 08.01.2000 und eine Folge am
	# 04.01.2000.
	var run := TimelineRun.new(_katalog("catalog_us1_spielende"), 4711)

	# Act: weit über das Spielende hinaus
	var meldungen := run.advance_to(LETZTER_TAG + 400)

	# Assert
	assert_true(run.is_finished())
	assert_eq(run.today, LETZTER_TAG, "Der Lauf hört am 31.12.1999 auf.")
	assert_eq(_zeilen(meldungen), [
		"25.12.1999  Beginn  Spät im Jahr",
		"25.12.1999  Wirkung  Spät im Jahr: Presse · jahresende — Sofort.",
		"31.12.1999  Beginn  Silvester 1999",
	], "Wirkung und Folge im Januar 2000 werden nicht mehr gemeldet.")
	assert_eq(run.advance_to(LETZTER_TAG + 1000).size(), 0)
	assert_eq(run.begin().size(), 0)
	# Entschieden ist die Folge trotzdem: Sie steht mit ihrem Tag im Fahrplan, die verzögerte
	# Wirkung beim Termin (FR-011, FR-013).
	var nachspiel := _termine(run, "nachspiel")
	assert_eq(nachspiel.size(), 1)
	if nachspiel.size() == 1:
		assert_eq(nachspiel[0].day, _tag(2000, 1, 4))
		assert_eq(nachspiel[0].state, ScheduleEntry.State.PLANNED)
	var spaet := _termine(run, "spaet")
	if spaet.size() == 1:
		assert_eq(spaet[0].due_effects()[0]["day"], _tag(2000, 1, 8))


func test_begin_spielt_den_ersten_tag_nur_einmal() -> void:
	# Arrange
	var catalog := _katalog("catalog_us1_wuerfel")
	var run := TimelineRun.new(catalog, 4711)
	var vergleich := TimelineRun.new(catalog, 4711)

	# Act und Assert
	assert_eq(run.advance_to(-1).size(), 0, "Vor dem 01.01.1985 gibt es nichts abzuspielen.")
	assert_eq(run.today, -1)
	run.begin()
	assert_eq(run.today, 0)
	assert_eq(_termine(run, "immer").size(), 1, "Die Würfelrunde für Januar 1985 lief mit.")
	var termine := run.entries.size()
	var meldungen := run.protocol.size()
	assert_eq(run.begin().size(), 0, "Ein zweites begin() spielt nichts ab.")
	assert_eq([run.entries.size(), run.protocol.size()], [termine, meldungen])
	run.advance_to(_tag(1985, 6, 30))
	vergleich.advance_to(_tag(1985, 6, 30))
	assert_eq(_zeilen(vergleich.protocol), _zeilen(run.protocol), "advance_to() ruft begin().")


func test_fahrplan_nach_tag_sortiert_und_nummern_eindeutig() -> void:
	# Arrange
	var run := TimelineRun.new(_katalog("event_catalog_uebernahme"), 4711)

	# Act
	run.advance_to(LETZTER_TAG)

	# Assert
	var anzahl := run.entries.size()
	var nummern := []
	for i in anzahl:
		nummern.append(run.entries[i].serial)
		if i > 0:
			assert_lte(run.entries[i - 1].day, run.entries[i].day, "Nach Tag sortiert.")
	nummern.sort()
	assert_eq(nummern, range(1, anzahl + 1), "Jede Nummer genau einmal.")
	for nummer in range(1, anzahl + 1):
		assert_eq(run.get_entry(nummer).serial, nummer)
	assert_null(run.get_entry(0))
	assert_null(run.get_entry(anzahl + 1))
	# Alles, was beginnt, steht im Fahrplan, mit dem Tag der Meldung (FR-011).
	for meldung in run.protocol:
		if meldung.kind == TimelineMessage.Kind.EVENT_STARTED:
			assert_same(run.get_entry(meldung.entry.serial), meldung.entry)
			assert_eq(meldung.entry.day, meldung.day)
	assert_eq(run.running_entries().size(), 0, "Ohne Dauer läuft nichts.")


# --- Jährliche Ereignisse und Kalender (T042, US3) --------------------------------

func test_weihnachtsgeschaeft_beginnt_am_ersten_november_und_endet_am_ersten_januar() -> void:
	# Arrange (US3, Szenario 1)
	var run := TimelineRun.new(_katalog("catalog_us3_kalender"), 4711)
	run.advance_to(_tag(1993, 10, 31))

	# Act
	var beginn := run.advance_to(_tag(1993, 11, 1))
	run.advance_to(_tag(1993, 12, 31))
	var ende := run.advance_to(_tag(1994, 1, 1))

	# Assert
	var wirkung := "Weihnachtsgeschäft: Kundenstrom · * · +30% — Startwert."
	assert_eq(_zeilen(beginn), [
		"01.11.1993  Beginn  Weihnachtsgeschäft",
		"01.11.1993  Wirkung  " + wirkung,
	])
	assert_eq(_zeilen(ende), [
		"01.01.1994  Wirkungsende  " + wirkung,
		"01.01.1994  Ende  Weihnachtsgeschäft",
	], "Erst endet die Wirkung, die nur während gilt, dann das Ereignis.")
	var termin := _termin_am(run, "weihnachtsgeschaeft", _tag(1993, 11, 1))
	assert_not_null(termin)
	if termin != null:
		assert_eq(termin.end_day, _tag(1994, 1, 1), "Der letzte Tag ist der 31.12.1993.")
		assert_eq([termin.origin_label(), termin.state_label()], ["jährlich", "beendet"])


func test_weihnachtsgeschaeft_liegt_in_allen_15_jahren_vom_01_11_bis_31_12() -> void:
	# Arrange
	var run := TimelineRun.new(_katalog("catalog_us3_kalender"), 4711)

	# Act
	run.advance_to(LETZTER_TAG)

	# Assert
	var jahre := []
	for termin in _termine(run, "weihnachtsgeschaeft"):
		var jahr := GameDate.from_day_index(termin.day).year
		jahre.append(jahr)
		assert_eq(termin.day, _tag(jahr, 11, 1), "Beginn am 01.11.%d." % jahr)
		assert_eq(termin.end_day - 1, _tag(jahr, 12, 31), "Letzter Tag 31.12.%d." % jahr)
		var zustand := "läuft" if jahr == 1999 else "beendet"
		assert_eq(termin.state_label(), zustand, "%d: Nur 1999 läuft bis zum Schluss." % jahr)
	assert_eq(jahre, range(1985, 2000), "Je Spieljahr ein Termin, keiner aus 1984.")
	# Die Zeile für 1999 wie im Vertrag, Abschnitt Textausgabe.
	assert_has(ScheduleText.plan_lines(run), "01.11.1999  bis 31.12.1999  weihnachtsgeschaeft"
		+ "           jährlich      läuft         Weihnachtsgeschäft (Ende nach Spielende)")


func test_winter_laeuft_ab_dem_ersten_spieltag_und_endet_vor_dem_fruehling() -> void:
	# Arrange (US3, Szenario 2): Der Winter 1984/85 begann am 01.12.1984, vor dem Spiel.
	var run := TimelineRun.new(_katalog("catalog_us3_kalender"), 4711)

	# Act
	var erster_tag := run.begin()
	run.advance_to(_tag(1985, 2, 28))
	var erster_maerz := run.advance_to(_tag(1985, 3, 1))

	# Assert
	assert_eq(_zeilen(erster_tag), ["01.01.1985  Beginn  Winter"],
		"Er gilt ab Spielbeginn als laufend und wird am ersten Spieltag gemeldet.")
	assert_eq(_zeilen(erster_maerz), ["01.03.1985  Ende  Winter", "01.03.1985  Beginn  Frühling"],
		"Erst das Ende des Winters, dann der Beginn des Frühlings (FR-016).")
	var winter := _termine(run, "winter")[0]
	assert_eq([winter.day, winter.end_day], [0, _tag(1985, 3, 1)], "Tag 0 bis 28.02.1985.")
	assert_true(winter.started_before_game, "Er lief schon vor Spielbeginn.")
	assert_eq(winter.state_label(), "beendet")
	assert_eq(winter.explain(), "Jedes Jahr laut Katalog, lief schon vor Spielbeginn")
	assert_string_ends_with(_zeile_mit(ScheduleText.plan_lines(run, _tag(1985, 3, 1)),
		"01.01.1985  bis 28.02.1985  winter "), "Winter (lief schon vor Spielbeginn)")


func test_winter_reicht_bis_zum_29_februar_und_der_letzte_ins_jahr_2000() -> void:
	# Arrange
	var run := TimelineRun.new(_katalog("catalog_us3_kalender"), 4711)

	# Act: weit über das Spielende hinaus
	run.advance_to(LETZTER_TAG + 400)

	# Assert
	var winter := _termine(run, "winter")
	var letzte_tage := []
	for termin in winter:
		letzte_tage.append(str(GameDate.from_day_index(termin.end_day - 1)))
	assert_eq(letzte_tage.size(), 16, "Vom Winter 1984/85 bis zum Winter 1999/2000.")
	assert_has(letzte_tage, "29.02.1988", "Der Winter 1987/88 reicht bis zum Schalttag.")
	assert_has(letzte_tage, "28.02.1989", "1989 ist kein Schaltjahr.")
	assert_eq(letzte_tage.back(), "29.02.2000", "Der letzte Winter reicht bis zum 29.02.2000.")
	var enden := []
	for meldung in run.protocol:
		if meldung.kind == TimelineMessage.Kind.EVENT_ENDED and meldung.event.id == "winter":
			enden.append(str(GameDate.from_day_index(meldung.day)))
	assert_eq(enden.size(), 15, "Ein Ende je März, von 1985 bis 1999.")
	assert_does_not_have(enden, "01.03.2000", "Das Ende des letzten Winters wird nicht gemeldet.")
	var letzter: ScheduleEntry = winter.back()
	assert_eq(letzter.state_label(), "läuft", "Er läuft bis zum Schluss.")
	assert_string_ends_with(_zeile_mit(ScheduleText.plan_lines(run),
		"01.12.1999  bis 29.02.2000  winter "), "Winter (Ende nach Spielende)")


func test_cebit_ab_1986_hat_1985_kein_vorkommen() -> void:
	# Arrange: die CeBIT vom 15. bis 21. März, ab 1986, mit einer Pressemeldung als einmaligem
	# Anstoß
	var run := TimelineRun.new(_katalog("catalog_us3_kalender"), 4711)

	# Act
	run.advance_to(LETZTER_TAG)

	# Assert
	var jahre := []
	for termin in _termine(run, "cebit"):
		var jahr := GameDate.from_day_index(termin.day).year
		jahre.append(jahr)
		assert_eq([termin.day, termin.end_day], [_tag(jahr, 3, 15), _tag(jahr, 3, 22)],
			"%d: vom 15. bis 21. März, das Ende kommt am 22." % jahr)
	assert_eq(jahre, range(1986, 2000), "Kein Vorkommen im März 1985.")
	assert_eq(_arten(run, "cebit"), {"Beginn": 14, "Wirkung": 14, "Ende": 14},
		"Die Pressemeldung ist ein einmaliger Anstoß und hat kein Ende (US3, Szenario 4).")


func test_laufende_termine_in_der_reihenfolge_des_fahrplans() -> void:
	# Arrange
	var run := TimelineRun.new(_katalog("catalog_us3_kalender"), 4711)

	# Act
	run.advance_to(_tag(1993, 11, 15))
	var im_november := _kennungen(run.running_entries())
	run.advance_to(_tag(1994, 1, 15))
	var im_januar := _kennungen(run.running_entries())

	# Assert
	assert_eq(im_november, ["herbst", "weihnachtsgeschaeft"])
	assert_eq(im_januar, ["winter"])


func test_jaehrlich_ohne_dauer_ab_spielbeginn_und_ab_einem_spaeteren_jahr() -> void:
	# Arrange
	var run := TimelineRun.new(_katalog("catalog_us3_jaehrlich"), 4711)
	var erste_januare := []
	for jahr in range(1985, 2000):
		erste_januare.append(_tag(jahr, 1, 1))

	# Act
	run.advance_to(LETZTER_TAG)

	# Assert: „Neujahr“ hat als Ende (0, 0) und ist jedes Jahr ein Augenblick.
	assert_eq(_tage(run, "neujahr"), erste_januare)
	for termin in _termine(run, "neujahr"):
		assert_eq(termin.end_day, termin.day, "Ohne Dauer endet nichts.")
		assert_eq(termin.state_label(), "eingetreten")
	assert_eq(_arten(run, "neujahr"), {"Beginn": 15}, "Nur Beginne, kein Ende.")
	# „Januarflaute“ beginnt 1985 genau am ersten Spieltag, also nicht schon davor.
	assert_eq(_tage(run, "januarflaute"), erste_januare)
	var januar_1985 := _termine(run, "januarflaute")[0]
	assert_false(januar_1985.started_before_game)
	assert_eq(januar_1985.end_day, _tag(1985, 2, 1))
	# „Winter ab 1990“ gilt 1990 bis 1995. Das Vorkommen ab dem 01.12.1989 reicht in den Januar
	# 1990 und gehört deshalb dazu, ungekürzt; das letzte reicht bis zum 29.02.1996.
	var winter := _termine(run, "winter_ab_1990")
	assert_eq(winter.size(), 7, "Winter 1989/90 bis 1995/96.")
	if winter.size() == 7:
		assert_eq(winter[0].day, _tag(1989, 12, 1))
		assert_false(winter[0].started_before_game)
		assert_eq(winter[6].end_day - 1, _tag(1996, 2, 29))


func test_jaehrliche_vorkommen_fuer_fahrplan_und_zeitstrahl() -> void:
	# Arrange: yearly_occurrences() ist die Regel, nach der Fahrplan und Zeitstrahl der Werkstatt
	# die jährlichen Vorkommen bilden (T047).
	var katalog := _katalog("catalog_us3_kalender")
	var run := TimelineRun.new(katalog, 4711)

	# Act und Assert: je Ereignis dieselben Beginne wie im Fahrplan; dort beginnt, was vor 1985
	# anfing, am Tag 0.
	for ereignis in katalog.events:
		var beginne := []
		for vorkommen in TimelineRun.yearly_occurrences(ereignis):
			beginne.append(maxi(vorkommen.x, TimelineRun.FIRST_DAY))
		assert_eq(beginne, _tage(run, ereignis.id), "%s wie im Fahrplan" % ereignis.id)
	var winter := TimelineRun.yearly_occurrences(katalog.get_event("winter"))
	assert_eq(winter[0], Vector2i(_tag(1984, 12, 1), _tag(1985, 2, 28)),
		"Der Winter 1984/85 mit seinem echten Beginn vor dem Spiel.")
	assert_eq(winter[winter.size() - 1].y, _tag(2000, 2, 29))
	# Unsinnige Jahre, wie sie bis zur Korrektur in der Werkstatt stehen können (V08), halten
	# nicht auf; es bleiben die Vorkommen im Spielzeitraum.
	var unsinn := katalog.get_event("winter")
	unsinn.yearly_from = -999999999
	unsinn.yearly_to = 999999999
	assert_eq(TimelineRun.yearly_occurrences(unsinn).size(), 16)


# --- Dauer, Wirkungen und Ereignisse, die noch laufen (T042, US3) -----------------

func test_ereignis_mit_42_tagen_dauer_endet_am_tag_nach_seinem_letzten_tag() -> void:
	# Arrange (US3, Szenarien 3 und 4): „Sonderaktion“ beginnt am 10.03.1994 und dauert 42 Tage.
	# Zwei Wirkungen gelten nur während, eine davon kommt zwei Wochen später; die Pressemeldung
	# ist ein einmaliger Anstoß.
	var run := TimelineRun.new(_katalog("catalog_us3_dauer"), 4711)
	run.advance_to(_tag(1994, 3, 9))

	# Act
	var bis_zum_letzten_tag := run.advance_to(_tag(1994, 4, 20))
	var laufend_am_letzten_tag := _kennungen(run.running_entries())
	var am_ende := run.advance_to(_tag(1994, 4, 21))

	# Assert
	var nachfrage := "Sonderaktion: Nachfrage · * · +10% — Gilt, solange die Aktion läuft."
	var kundenstrom := "Sonderaktion: Kundenstrom · * · +5% — Spricht sich nach zwei Wochen herum."
	assert_eq(_zeilen(bis_zum_letzten_tag), [
		"10.03.1994  Beginn  Sonderaktion",
		"10.03.1994  Wirkung  " + nachfrage,
		"10.03.1994  Wirkung  Sonderaktion: Presse · lokal — Die Lokalzeitung berichtet.",
		"24.03.1994  Wirkung  " + kundenstrom,
	])
	assert_eq(laufend_am_letzten_tag, ["sonderaktion"], "Am 20.04.1994 läuft sie noch.")
	assert_eq(_zeilen(am_ende), [
		"21.04.1994  Wirkungsende  " + nachfrage,
		"21.04.1994  Wirkungsende  " + kundenstrom,
		"21.04.1994  Ende  Sonderaktion",
	], "Die verzögerte Wirkung endet mit dem Ereignis, die Pressemeldung hat kein Ende.")
	var termin := _termine(run, "sonderaktion")[0]
	assert_eq(termin.end_day, termin.day + 42, "Das Ende ist der Beginn plus Dauer.")
	assert_eq(termin.state_label(), "beendet")
	assert_eq(run.running_entries().size(), 0)


func test_waehrend_wirkt_ohne_dauer_wie_ein_einmaliger_anstoss() -> void:
	# Arrange (FR-021): „Kurzmeldung“ am 01.06.1994 hat keine Dauer, aber zwei Wirkungen
	# „während“, eine sofort und eine eine Woche später.
	var run := TimelineRun.new(_katalog("catalog_us3_dauer"), 4711)
	run.advance_to(_tag(1994, 5, 31))

	# Act
	var meldungen := run.advance_to(_tag(1994, 12, 31))

	# Assert
	assert_eq(_zeilen(meldungen), [
		"01.06.1994  Beginn  Kurzmeldung",
		"01.06.1994  Wirkung  Kurzmeldung: Nachfrage · * · +5% — Sofort.",
		"08.06.1994  Wirkung  Kurzmeldung: Nachfrage · * · +5% — Eine Woche später.",
	], "Kein Ende, weder für das Ereignis noch für seine Wirkungen.")
	assert_eq(_zustaende(run, "kurzmeldung"), ["01.06.1994 eingetreten"])


func test_wirkung_waehrend_die_erst_mit_dem_ende_begaenne_beginnt_nie() -> void:
	# Arrange: Mit 42 Tagen Verzögerung bei 42 Tagen Dauer begänne die Wirkung am Tag des Endes.
	# Die Prüfung meldet das als V19, und das Spiel nimmt so ein Ereignis aus. Läuft es trotzdem,
	# beginnt die Wirkung nie und endet deshalb auch nicht.
	var catalog := _katalog("catalog_us3_dauer")
	catalog.get_event("sonderaktion").effects[1].delay_days = 42
	var issues := CatalogValidator.validate(catalog)
	assert_true(issues.size() == 1 and issues[0].rule == "V19", "Voraussetzung: %s" % [issues])
	var run := TimelineRun.new(catalog, 4711)

	# Act
	run.advance_to(LETZTER_TAG)

	# Assert
	var nachfrage := "Sonderaktion: Nachfrage · * · +10% — Gilt, solange die Aktion läuft."
	var wirkungen := []
	for meldung in run.protocol:
		if meldung.event.id == "sonderaktion" and meldung.effect != null:
			wirkungen.append(meldung.to_line())
	assert_eq(wirkungen, [
		"10.03.1994  Wirkung  " + nachfrage,
		"10.03.1994  Wirkung  Sonderaktion: Presse · lokal — Die Lokalzeitung berichtet.",
		"21.04.1994  Wirkungsende  " + nachfrage,
	])
	var termin := _termine(run, "sonderaktion")[0]
	assert_eq(termin.due_effects().size(), 0,
		"Der Fahrplan zeigt die Wirkung nicht, die nie beginnt (T079).")


func test_wirkung_waehrend_im_gekuerzten_winter_steht_nicht_im_fahrplan() -> void:
	# Arrange (T079): Der Winter bekommt eine Wirkung „während“, 70 Tage verzögert. Ein voller
	# Winter dauert 90 Tage, die Prüfung (V19) lässt sie deshalb durch. Der Winter 1984/85 beginnt
	# im Fahrplan aber erst am 01.01.1985 und endet am 01.03.1985, nach 59 Tagen; die Wirkung käme
	# am 12.03.1985.
	var catalog := _katalog("catalog_us3_kalender")
	var nachfrage := EventEffect.new()
	nachfrage.kind = EventEffect.Kind.NACHFRAGE
	nachfrage.magnitude = 0.1
	nachfrage.delay_days = 70
	nachfrage.scope = EventEffect.Scope.DURING
	catalog.get_event("winter").effects.append(nachfrage)
	var issues := CatalogValidator.validate(catalog)
	var run := TimelineRun.new(catalog, 4711)

	# Act
	run.advance_to(_tag(1986, 3, 1))

	# Assert: Die Prüfung meldet nichts. Jährliche Termine stehen von Anfang an im Fahrplan, vorn
	# der gekürzte Winter 1984/85 und der volle 1985/86.
	assert_eq(issues.size(), 0, "V19 rechnet mit der vollen Dauer: %s" % [issues])
	var winter := _termine(run, "winter")
	assert_eq(winter.size(), 16, "Vom Winter 1984/85 bis zum Winter 1999/2000.")
	if winter.size() < 2:
		return
	var gekuerzt := winter[0]
	var voll := winter[1]
	assert_eq([gekuerzt.day, gekuerzt.end_day], [0, _tag(1985, 3, 1)])
	assert_eq([voll.day, voll.end_day], [_tag(1985, 12, 1), _tag(1986, 3, 1)], "90 Tage.")
	# Im gekürzten Winter nennt der Fahrplan die Wirkung nicht, im vollen am 09.02.1986. Der Lauf
	# arbeitet auf einer Kopie des Katalogs; verglichen wird deshalb die Beschreibung.
	assert_eq(gekuerzt.due_effects().size(), 0, "Sie begänne nach dem Ende und beginnt nie.")
	var faellig := voll.due_effects()
	assert_eq(faellig.size(), 1)
	if faellig.size() == 1:
		var wirkung: EventEffect = faellig[0]["effect"]
		assert_eq([wirkung.describe(), faellig[0]["day"]],
			[nachfrage.describe(), _tag(1986, 2, 9)])
	# Der Lauf meldet sie nur im vollen Winter, mit Beginn und Ende.
	var meldungen := []
	for meldung in run.protocol:
		if meldung.event.id == "winter" and meldung.effect != null:
			meldungen.append(meldung.to_line())
	assert_eq(meldungen, [
		"09.02.1986  Wirkung  Winter: Nachfrage · * · +10%",
		"01.03.1986  Wirkungsende  Winter: Nachfrage · * · +10%",
	])
	# Die Textausgabe zeigt nur, was auch gemeldet wird.
	var zeilen := ScheduleText.plan_lines(run, _tag(1986, 3, 1))
	var wirkungszeilen := []
	for zeile in zeilen:
		if zeile.contains("└"):
			wirkungszeilen.append(zeile)
	assert_eq(wirkungszeilen, ["09.02.1986    └ Nachfrage · * · +10%"],
		"Kein „12.03.1985 └ …“ unter dem Winter, der am 28.02.1985 endet.")


func test_nach_dem_31_12_1999_kommt_kein_ende_mehr() -> void:
	# Arrange: Beide beginnen am 21.12.1999. Das eine endet nach 10 Tagen am 31.12.1999, das
	# andere läuft bis zum 31.12.1999 und endete erst am 01.01.2000.
	var run := TimelineRun.new(_katalog("catalog_us3_dauer"), 4711)
	run.advance_to(_tag(1999, 12, 30))

	# Act: weit über das Spielende hinaus
	var meldungen := run.advance_to(LETZTER_TAG + 400)

	# Assert
	assert_eq(_zeilen(meldungen), [
		"31.12.1999  Wirkungsende  Endet am letzten Tag: Kundenstrom · * · +10% — Gilt, solange "
			+ "es läuft.",
		"31.12.1999  Ende  Endet am letzten Tag",
	], "Ein Ende am 31.12.1999 wird gemeldet, eines danach nicht mehr (FR-019).")
	var spaet := _termine(run, "endet_nach_spielende")[0]
	assert_eq(spaet.end_day, LETZTER_TAG + 1)
	assert_eq(_kennungen(run.running_entries()), ["endet_nach_spielende"],
		"Was nach Spielende endete, läuft bis zum Schluss.")
	assert_eq(run.advance_to(LETZTER_TAG + 1000).size(), 0)


func test_laufender_lieferengpass_entfaellt_beim_zweiten_termin() -> void:
	# Arrange (US3, Szenario 6): Der Lieferengpass kommt im Januar und im Februar 1990 sicher und
	# dauert 60 Tage. Der Termin im Februar fällt bei jedem Seed in die Zeit, in der der erste
	# noch läuft.
	var catalog := _katalog("catalog_us3_laeuft_noch")

	for seed_wert in range(1, 21):
		# Act
		var run := TimelineRun.new(catalog, seed_wert)
		run.advance_to(LETZTER_TAG)

		# Assert
		var termine := _termine(run, "lieferengpass")
		assert_eq(termine.size(), 2, "Seed %d: im Januar und im Februar." % seed_wert)
		if termine.size() != 2:
			continue
		var erster := termine[0]
		var zweiter := termine[1]
		var bis := GameDate.from_day_index(erster.end_day - 1)
		assert_eq(erster.end_day, erster.day + 60)
		assert_eq(erster.state_label(), "beendet")
		assert_eq(zweiter.state_label(), "entfallen", "Seed %d: Er läuft noch." % seed_wert)
		assert_eq(zweiter.note, "läuft noch bis %s" % bis)
		assert_eq(zweiter.explain(), "Würfel %s < Schwelle 1,0000 (100 %%); entfallen: läuft noch "
			% _vier_stellen_abgerundet(zweiter.roll) + "bis %s" % bis)
		var zum_zweiten := []
		for meldung in run.protocol:
			if meldung.entry == zweiter:
				zum_zweiten.append(meldung.to_line())
		assert_eq(zum_zweiten, ["%s  Entfall  Lieferengpass: läuft noch bis %s"
			% [GameDate.from_day_index(zweiter.day), bis]], "Weder Beginn noch Ende.")


func test_folge_die_noch_laeuft_entfaellt_und_beginnt_nach_dem_ende_neu() -> void:
	# Arrange: Die Aufträge A, B und C am 01.06., 20.06. und 01.07.1990 bringen sofort je eine
	# „Sonderschicht“ von 30 Tagen. Die erste läuft vom 01.06. bis zum 30.06.1990.
	var run := TimelineRun.new(_katalog("catalog_us3_laeuft_noch"), 4711)

	# Act
	var juni := run.advance_to(_tag(1990, 6, 30))
	var erster_juli := run.advance_to(_tag(1990, 7, 1))

	# Assert
	assert_has(_zeilen(juni), "20.06.1990  Entfall  Sonderschicht: läuft noch bis 30.06.1990")
	assert_eq(_zeilen(erster_juli), [
		"01.07.1990  Ende  Sonderschicht",
		"01.07.1990  Beginn  Auftrag C",
		"01.07.1990  Beginn  Sonderschicht",
	], "Was am selben Tag endet, hält den neuen Termin nicht auf.")
	assert_eq(_zustaende(run, "sonderschicht"),
		["01.06.1990 beendet", "20.06.1990 entfallen", "01.07.1990 läuft"])


# --- Helfer ----------------------------------------------------------------------

## Liest einen Test-Katalog aus res://test/fixtures/; er muss fehlerfrei sein.
func _katalog(datei: String) -> EventCatalog:
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.read_file(ORDNER + datei + ".json", issues)
	if catalog == null:
		fail_test("%s lässt sich nicht lesen: %s" % [datei, issues])
		return EventCatalog.new()
	issues.append_array(CatalogValidator.validate(catalog))
	assert_false(CatalogValidator.has_errors(issues), "%s ist fehlerfrei: %s" % [datei, issues])
	return catalog


## Tagesindex eines Datums.
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


## Die Kennungen der Ereignisse von Terminen, in deren Reihenfolge.
func _kennungen(termine: Array[ScheduleEntry]) -> Array:
	var kennungen := []
	for termin in termine:
		kennungen.append(termin.event.id)
	return kennungen


## Die Meldungen eines Ereignisses, gezählt je Art, etwa {"Beginn": 14, "Ende": 14}.
func _arten(run: TimelineRun, kennung: String) -> Dictionary:
	var arten := {}
	for meldung in run.protocol:
		if meldung.event.id == kennung:
			var art := TimelineMessage.KIND_LABELS[meldung.kind]
			arten[art] = int(arten.get(art, 0)) + 1
	return arten


## Die erste Zeile, die mit [param anfang] beginnt; leer, wenn es keine gibt.
func _zeile_mit(zeilen: PackedStringArray, anfang: String) -> String:
	for zeile in zeilen:
		if zeile.begins_with(anfang):
			return zeile
	return ""


## Je Termin des Ereignisses „TT.MM.JJJJ <zustand>“.
func _zustaende(run: TimelineRun, kennung: String) -> Array:
	var zustaende := []
	for termin in _termine(run, kennung):
		zustaende.append("%s %s" % [GameDate.from_day_index(termin.day), termin.state_label()])
	return zustaende


## Je Termin des Ereignisses „MM.JJJJ <herkunft> <zustand>“.
func _kurz(run: TimelineRun, kennung: String) -> Array:
	var kurz := []
	for termin in _termine(run, kennung):
		var datum := GameDate.from_day_index(termin.day)
		kurz.append("%02d.%d %s %s" % [datum.month, datum.year, termin.origin_label(),
			termin.state_label()])
	return kurz


## Ein Termin als Text für Vergleiche: Tag, Ereignis, Herkunft, Zustand, Wurf, Schwelle, Grund.
func _spur(termin: ScheduleEntry) -> String:
	return "%s %s %s %s %.6f %.6f %s" % [GameDate.from_day_index(termin.day), termin.event.id,
		termin.origin_label(), termin.state_label(), termin.roll, termin.threshold, termin.note]


## Die Spuren der Termine eines Ereignisses, nur 1990 (true) oder nur außerhalb (false).
func _spuren(run: TimelineRun, kennung: String, nur_1990: bool) -> Array:
	var spuren := []
	for termin in _termine(run, kennung):
		if (GameDate.from_day_index(termin.day).year == 1990) == nur_1990:
			spuren.append(_spur(termin))
	return spuren


## Der ganze Fahrplan als Spuren, in seiner Reihenfolge.
func _fahrplan(run: TimelineRun) -> Array:
	var spuren := []
	for termin in run.entries:
		spuren.append(_spur(termin))
	return spuren


## Spielt einen Lauf bis zum Ende und gibt je Ereignis seine Termine und Meldungen als Text
## zurück: Kennung → Liste.
func _spuren_je_ereignis(catalog: EventCatalog, seed_wert: int) -> Dictionary:
	var run := TimelineRun.new(catalog, seed_wert)
	run.advance_to(LETZTER_TAG)
	var je_ereignis := {}
	for event in catalog.events:
		je_ereignis[event.id] = []
	for termin in run.entries:
		je_ereignis[termin.event.id].append(_spur(termin))
	for meldung in run.protocol:
		je_ereignis[meldung.event.id].append(meldung.to_line())
	return je_ereignis


## Die Zeilen von Meldungen.
func _zeilen(meldungen: Array[TimelineMessage]) -> Array:
	var zeilen := []
	for meldung in meldungen:
		zeilen.append(meldung.to_line())
	return zeilen


## Spielt einen Lauf in Sprüngen bis zum Spielende ab: bis 1989 von Monatserstem zu
## Monatserstem wie „+1 Monat“, dann bis 1995 Jahr für Jahr wie „+1 Jahr“, danach in krummen
## Sprüngen von 37 Tagen.
func _in_spruengen(run: TimelineRun) -> void:
	var ziele: Array[int] = []
	for jahr in range(1985, 1990):
		for monat in range(1, 13):
			ziele.append(_tag(jahr, monat, 1))
	for jahr in range(1990, 1996):
		ziele.append(_tag(jahr, 1, 1))
	var tag := _tag(1996, 1, 1)
	while tag < LETZTER_TAG:
		ziele.append(tag)
		tag += 37
	ziele.append(LETZTER_TAG)
	for ziel in ziele:
		run.advance_to(ziel)


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


## Würfel auf vier Nachkommastellen abgerundet, mit deutschem Komma, wie in
## ScheduleEntry.explain().
func _vier_stellen_abgerundet(wert: float) -> String:
	return ("%.4f" % (floorf(wert * 10000.0 + 1e-11) / 10000.0)).replace(".", ",")
