extends GutTest

## Prüft die Prüfregeln V01 bis V24 (Feature 002, T015; SC-006).
##
## Jede Regel hat eine kaputte Fixture unter res://test/fixtures/, die sich vom fehlerfreien
## catalog_minimal.json in genau einer Stelle unterscheidet; V15 und V21 haben je zwei, denn zu
## ihnen gehören Fälle, die nur in von Hand geänderten Dateien vorkommen (T084): eine Bedingung
## auf das eigene Ereignis und eine Kategorie-Kennung mit Großbuchstaben. Die Prüfung muss dann
## genau eine Meldung bringen (bei Kreisen und doppelten Kennungen eine je Ereignis), mit Regel,
## Stufe, Ereignis und Stelle. Fehlerregeln kommen als ERROR, V13, V20 und V23 als WARNING. V22
## entsteht schon beim Lesen; dafür dient catalog_v22_kaputt.json.
##
## Danach Randfälle zu den Entscheidungen aus data-model.md, etwa dass drei gleiche Gewichte von
## 33,33 noch als 100 gelten. Diese Tests ändern eine frisch gelesene Kopie des Grundkatalogs im
## Code, statt für jeden Fall eine weitere Datei anzulegen.
##
## Feature 003 (T007) setzt die Tabelle mit V25 bis V31 für die Start-Modifikatoren in den Profilen
## fort, wieder je Regel mit einer Fixture; V31 warnt nur. Meldungen zu Profilen haben kein
## Ereignis, ihr Text nennt „Profil „Schwer““ und das volle Feld, etwa
## „profiles.schwer[0].event_id“.

const ORDNER := "res://test/fixtures/"
const GRUNDKATALOG := "res://test/fixtures/catalog_minimal.json"

## Je Fall die Fixture und die erwarteten Meldungen als „<Regel> <Stufe> <Kennung> <Feld>“; eine
## leere Kennung steht als „-“.
const FAELLE := [
	["catalog_v01_kennung_leer", ["V01 ERROR - id"]],
	["catalog_v02_kennung_doppelt", ["V02 ERROR intel_pentium id", "V02 ERROR intel_pentium id"]],
	["catalog_v03_kennung_zeichen", ["V03 ERROR Windows-95 id"]],
	["catalog_v04_titel_leer", ["V04 ERROR intel_pentium title"]],
	["catalog_v05_kategorie_unbekannt", ["V05 ERROR intel_pentium category"]],
	["catalog_v06_datum_ausserhalb", ["V06 ERROR intel_pentium date"]],
	["catalog_v07_fenster_umgedreht", ["V07 ERROR reklamationswelle window.to"]],
	["catalog_v08_jahre_ausserhalb", ["V08 ERROR weihnachtsgeschaeft yearly.from"]],
	["catalog_v09_tag_im_jahr", ["V09 ERROR winter yearly.end"]],
	["catalog_v10_preset_zu_eng", ["V10 ERROR neubaugebiet count_weights"]],
	["catalog_v11_gewichte_summe", ["V11 ERROR neubaugebiet count_weights"]],
	["catalog_v12_chance_ueber_eins", ["V12 ERROR reklamationswelle monthly_chance"]],
	["catalog_v13_grundchance_null", ["V13 WARNING reklamationswelle monthly_chance"]],
	["catalog_v14_verzoegerung_negativ", ["V14 ERROR intel_pentium effects[1].delay_days"]],
	["catalog_v15_verweis_unbekannt", ["V15 ERROR reklamationswelle follow_ups[0].target"]],
	["catalog_v15_bedingung_selbst", ["V15 ERROR zeitungsartikel conditions[0].event"]],
	["catalog_v16_folge_auf_fix", ["V16 ERROR reklamationswelle follow_ups[0].target"]],
	["catalog_v17_bedingung_an_fix", ["V17 ERROR intel_pentium conditions"]],
	["catalog_v18_kreis_ohne_verzoegerung",
		["V18 ERROR kreis_a follow_ups[0].target", "V18 ERROR kreis_b follow_ups[0].target"]],
	["catalog_v19_wirkung_nach_ende", ["V19 ERROR weihnachtsgeschaeft effects[0].delay_days"]],
	["catalog_v20_staerke_null", ["V20 WARNING intel_pentium effects[0].magnitude"]],
	["catalog_v21_kategorie_farbe", ["V21 ERROR - categories[3].color"]],
	["catalog_v21_kennung_zeichen", ["V21 ERROR - categories[4].id"]],
	["catalog_v23_kreis_mit_verzoegerung",
		["V23 WARNING kreis_a follow_ups[0].target", "V23 WARNING kreis_b follow_ups[0].target"]],
	["catalog_v24_abstand_kuerzer_als_dauer", ["V24 ERROR neubaugebiet min_gap_days"]],
	["catalog_v25_profil_ereignis_unbekannt", ["V25 ERROR - profiles.schwer[0].event_id"]],
	["catalog_v26_profil_ereignis_jaehrlich", ["V26 ERROR - profiles.schwer[0].event_id"]],
	["catalog_v27_profil_ende_vor_beginn", ["V27 ERROR - profiles.schwer[0].to_day"]],
	["catalog_v28_profil_ausserhalb", ["V28 ERROR - profiles.schwer[0].from_day"]],
	["catalog_v29_profil_grund_leer", ["V29 ERROR - profiles.leicht[0].reason"]],
	["catalog_v30_profil_kennung_doppelt",
		["V30 ERROR - profiles.schwer[0].id", "V30 ERROR - profiles.schwer[1].id"]],
	["catalog_v31_profil_monatsmitte",
		["V31 WARNING - profiles.schwer[0].from_day", "V31 WARNING - profiles.schwer[0].to_day"]],
]
## Regeln, die validate_event() nicht prüft, weil sie den ganzen Katalog brauchen.
const NUR_IM_GANZEN := ["V02", "V18", "V21", "V23"]


# --- Je Regel eine Fixture (SC-006) ---------------------------------------

func test_jede_regel_meldet_sich_an_ihrer_stelle(fall: Array = use_parameters(FAELLE)) -> void:
	# Arrange
	var name_der_fixture: String = fall[0]
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.read_file(ORDNER + name_der_fixture + ".json", issues)
	assert_eq(issues.size(), 0,
		"%s muss sich ohne V22 lesen lassen: %s" % [name_der_fixture, issues])
	if catalog == null:
		return

	# Act
	var gefunden := CatalogValidator.validate(catalog)

	# Assert
	assert_eq(_stellen(gefunden), fall[1], "Meldungen von %s." % name_der_fixture)
	# Jede Meldung nennt im Text das Feld und das Ereignis, die Kategorie bzw. das Profil.
	for issue in gefunden:
		assert_string_contains(issue.message, "Feld „%s“" % issue.field)
		if issue.field.begins_with("categories"):
			assert_string_contains(issue.message, "Kategorie „")
		elif issue.field.begins_with("profiles"):
			assert_string_contains(issue.message, "Profil „")
		else:
			assert_string_contains(issue.message, "Ereignis „")
		if not issue.event_id.is_empty():
			assert_string_contains(issue.message, "„%s“" % issue.event_id)


func test_kaputtes_json_ist_v22_mit_zeile() -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []

	# Act
	var catalog := EventCatalog.read_file(ORDNER + "catalog_v22_kaputt.json", issues)

	# Assert
	assert_null(catalog)
	assert_eq(_stellen(issues), ["V22 ERROR - Zeile 13"], "V22 nennt die Zeile.")


func test_grundkatalog_und_ereignis_ohne_wirkung_melden_nichts() -> void:
	# Arrange
	var catalog := _grundkatalog()

	# Act
	var gefunden := CatalogValidator.validate(catalog)

	# Assert
	assert_eq(gefunden.size(), 0, "Der Grundkatalog ist fehlerfrei: %s" % [gefunden])
	assert_eq(catalog.get_event("zeitungsartikel").effects.size(), 0,
		"Der Grundkatalog enthält ein Ereignis ohne Wirkung, eine reine Meldung.")
	assert_eq(catalog.events.size(), 5, "Jede Art einmal.")


func test_validate_event_meldet_dasselbe_ohne_die_regeln_ueber_den_katalog(
		fall: Array = use_parameters(FAELLE)) -> void:
	# Arrange
	var issues: Array[CatalogIssue] = []
	var catalog := EventCatalog.read_file(ORDNER + str(fall[0]) + ".json", issues)
	if catalog == null:
		fail_test("%s lässt sich nicht lesen." % fall[0])
		return
	var im_ganzen := CatalogValidator.validate(catalog)

	for event in catalog.events:
		# Act: alle Ereignisse mit dieser Kennung, wie validate() sie meldet
		var einzeln: Array[CatalogIssue] = []
		for gleich in catalog.events:
			if gleich.id == event.id:
				einzeln.append_array(CatalogValidator.validate_event(catalog, gleich))
		var erwartet: Array[CatalogIssue] = []
		for issue in im_ganzen:
			if issue.event_id == event.id and not NUR_IM_GANZEN.has(issue.rule) \
					and not issue.field.begins_with("categories"):
				erwartet.append(issue)

		# Assert
		assert_eq(_texte(einzeln), _texte(erwartet),
			"%s, Ereignis „%s“." % [fall[0], event.id])


func test_reihenfolge_nach_kennung_dann_regel_kategorien_zuletzt() -> void:
	# Arrange: Fehler bei zwei Ereignissen und einer Kategorie, im Katalog absichtlich verstreut.
	var catalog := _grundkatalog()
	catalog.categories[0].color = &"papier"
	var welle := catalog.get_event("reklamationswelle")
	welle.category = "unbekannt"
	welle.title = ""
	catalog.get_event("intel_pentium").date = GameDate.new(2001, 5, 12).to_day_index()

	# Act
	var gefunden := CatalogValidator.validate(catalog)

	# Assert
	assert_eq(_stellen(gefunden), [
		"V06 ERROR intel_pentium date",
		"V04 ERROR reklamationswelle title",
		"V05 ERROR reklamationswelle category",
		"V21 ERROR - categories[0].color",
	])


func test_has_errors_nur_bei_fehlern() -> void:
	# Arrange
	var warnung := CatalogIssue.new(CatalogIssue.Severity.WARNING, "V13")
	var fehler := CatalogIssue.new(CatalogIssue.Severity.ERROR, "V04")
	var keine: Array[CatalogIssue] = []
	var nur_warnung: Array[CatalogIssue] = [warnung]
	var mit_fehler: Array[CatalogIssue] = [warnung, fehler]

	# Assert
	assert_false(CatalogValidator.has_errors(keine))
	assert_false(CatalogValidator.has_errors(nur_warnung), "Eine Warnung ist kein Fehler.")
	assert_true(CatalogValidator.has_errors(mit_fehler))


# --- Randfälle --------------------------------------------------------------

func test_v09_beginn_braucht_einen_echten_tag_das_ende_nicht() -> void:
	# Arrange: je Fall Beginn, Ende und die erwartete Meldung.
	var catalog := _grundkatalog()
	var weihnachten := catalog.get_event("weihnachtsgeschaeft")
	var beginn := ["V09 ERROR weihnachtsgeschaeft yearly.start"]
	var ende := ["V09 ERROR weihnachtsgeschaeft yearly.end"]
	var faelle := {
		"Beginn Monatsende": [Vector2i(12, 0), Vector2i(12, 0), beginn],
		"Beginn leer": [Vector2i(0, 0), Vector2i(12, 0), beginn],
		"Beginn 29.02.": [Vector2i(2, 29), Vector2i(3, 31), beginn],
		"Ende 29.02.": [Vector2i(12, 1), Vector2i(2, 29), ende],
		"Ende Monatsende": [Vector2i(11, 1), Vector2i(12, 0), []],
		"ohne Dauer": [Vector2i(11, 1), Vector2i(0, 0), []],
		"Ende 28.02.": [Vector2i(12, 1), Vector2i(2, 28), []],
	}
	for fall: String in faelle:
		var werte: Array = faelle[fall]
		weihnachten.yearly_start = werte[0]
		weihnachten.yearly_end = werte[1]

		# Act
		var gefunden := CatalogValidator.validate(catalog)

		# Assert
		assert_eq(_stellen(gefunden), werte[2], fall)


func test_v10_hoechste_anzahl_passt_genau_oder_knapp_nicht() -> void:
	# Arrange: zwei Termine mit 365 Tagen Abstand.
	var catalog := _grundkatalog()
	var neubau := catalog.get_event("neubaugebiet")
	neubau.count_min = 1
	neubau.count_weights.assign([50.0, 50.0])
	neubau.min_gap_days = 365
	neubau.window_from = GameDate.new(1990, 1, 1).to_day_index()

	# Act und Assert: genau 365 Tage vom ersten bis zum letzten Tag des Fensters passen.
	neubau.window_to = neubau.window_from + 365
	assert_eq(_stellen(CatalogValidator.validate(catalog)), [], "Genau passend ist erlaubt.")
	neubau.window_to = neubau.window_from + 364
	assert_eq(_stellen(CatalogValidator.validate(catalog)),
		["V10 ERROR neubaugebiet count_weights"], "Ein Tag zu wenig.")


func test_v11_drei_gleiche_gewichte_liegen_in_der_toleranz() -> void:
	# Arrange: Die Werkstatt verteilt 100 auf drei Anzahlen als je 33,33, zusammen 99,99.
	var catalog := _grundkatalog()
	var neubau := catalog.get_event("neubaugebiet")
	var faelle := {
		"99,99": [[33.33, 33.33, 33.33], []],
		"99,98": [[33.33, 33.33, 33.32], ["V11 ERROR neubaugebiet count_weights"]],
		"negativ": [[110.0, -10.0], ["V11 ERROR neubaugebiet count_weights"]],
	}
	for fall: String in faelle:
		var werte: Array = faelle[fall]
		neubau.count_weights.assign(werte[0])

		# Act
		var gefunden := CatalogValidator.validate(catalog)

		# Assert
		assert_eq(_stellen(gefunden), werte[1], fall)


func test_v17_leere_bedingungsliste_ist_kein_fehler() -> void:
	# Arrange: Steht "conditions": [] an einem fixen Ereignis, bleibt nach dem Lesen eine leere
	# Liste; sie fällt beim Speichern weg.
	var catalog := _grundkatalog()
	var pentium := catalog.get_event("intel_pentium")
	pentium.conditions.clear()
	var leer := CatalogValidator.validate(catalog)
	pentium.conditions.append(EventCondition.new())
	pentium.conditions[0].event = "reklamationswelle"

	# Act
	var mit_bedingung := CatalogValidator.validate(catalog)

	# Assert
	assert_eq(_stellen(leer), [], "Eine leere Liste ist kein Fehler.")
	assert_eq(_stellen(mit_bedingung), ["V17 ERROR intel_pentium conditions"])


func test_v19_grenze_bei_jaehrlichen_und_fixen_ereignissen() -> void:
	# Arrange
	var catalog := _grundkatalog()
	var weihnachten := catalog.get_event("weihnachtsgeschaeft")
	var pentium := catalog.get_event("intel_pentium")
	pentium.duration_days = 7
	pentium.effects[0].scope = EventEffect.Scope.DURING

	# Act und Assert: 01.11. bis 31.12. sind 61 Tage; am 61. Tag nach Beginn kommt das Ende.
	weihnachten.effects[0].delay_days = 60
	pentium.effects[0].delay_days = 6
	assert_eq(_stellen(CatalogValidator.validate(catalog)), [],
		"Eine Wirkung, die am letzten Tag beginnt, ist erlaubt.")
	weihnachten.effects[0].delay_days = 61
	pentium.effects[0].delay_days = 7
	assert_eq(_stellen(CatalogValidator.validate(catalog)), [
		"V19 ERROR intel_pentium effects[0].delay_days",
		"V19 ERROR weihnachtsgeschaeft effects[0].delay_days",
	], "Beginnt sie am Tag des Endes, ist das ein Fehler.")
	pentium.effects[0].scope = EventEffect.Scope.ONCE
	pentium.effects[0].delay_days = 100
	assert_eq(_stellen(CatalogValidator.validate(catalog)),
		["V19 ERROR weihnachtsgeschaeft effects[0].delay_days"],
		"Ein einmaliger Anstoß darf nach dem Ende kommen.")


func test_v19_winter_ueber_den_jahreswechsel_zaehlt_ohne_schalttag() -> void:
	# Arrange: 01.12. bis Ende Februar sind in einem Jahr ohne 29. Februar 90 Tage.
	var catalog := _grundkatalog()
	var weihnachten := catalog.get_event("weihnachtsgeschaeft")
	weihnachten.yearly_start = Vector2i(12, 1)
	weihnachten.yearly_end = Vector2i(2, 0)

	# Act und Assert
	weihnachten.effects[0].delay_days = 89
	assert_eq(_stellen(CatalogValidator.validate(catalog)), [])
	weihnachten.effects[0].delay_days = 90
	assert_eq(_stellen(CatalogValidator.validate(catalog)),
		["V19 ERROR weihnachtsgeschaeft effects[0].delay_days"])


func test_v24_nur_wenn_mehr_als_ein_termin_moeglich_ist() -> void:
	# Arrange: höchstens einmal (0 oder 1), Dauer länger als der Abstand.
	var catalog := _grundkatalog()
	var neubau := catalog.get_event("neubaugebiet")
	neubau.duration_days = 30
	neubau.min_gap_days = 10

	# Act und Assert
	assert_eq(_stellen(CatalogValidator.validate(catalog)), [], "Ein Termin überlappt nie.")
	neubau.count_weights.assign([30.0, 40.0, 30.0])
	assert_eq(_stellen(CatalogValidator.validate(catalog)), ["V24 ERROR neubaugebiet min_gap_days"])


func test_kreise_folge_auf_sich_selbst_wahrscheinlichkeit_und_gemischte_verzoegerung() -> void:
	# Arrange: ein Folgeereignis auf sich selbst, mit 100 % und ohne Verzögerung.
	var catalog := _grundkatalog()
	var artikel := catalog.get_event("zeitungsartikel")
	var auf_sich := FollowUp.new()
	auf_sich.target = "zeitungsartikel"
	artikel.follow_ups.append(auf_sich)
	assert_eq(_stellen(CatalogValidator.validate(catalog)),
		["V18 ERROR zeitungsartikel follow_ups[0].target"], "Auf sich selbst ist auch ein Kreis.")

	# Mit 99 % kann die Kette abbrechen, das ist kein Kreis im Sinn von V18.
	auf_sich.chance = 0.99
	assert_eq(_stellen(CatalogValidator.validate(catalog)), [])

	# Hin ohne, zurück mit Verzögerung: Der Kreis läuft bis Spielende weiter (V23), aber nicht
	# endlos am selben Tag (V18).
	auf_sich.target = "reklamationswelle"
	auf_sich.chance = 1.0
	var welle := catalog.get_event("reklamationswelle")
	welle.follow_ups[0].chance = 1.0
	assert_eq(_stellen(CatalogValidator.validate(catalog)), [
		"V23 WARNING reklamationswelle follow_ups[0].target",
		"V23 WARNING zeitungsartikel follow_ups[0].target",
	])


# --- Randfälle der Profile (Feature 003) ------------------------------------

func test_v25_ereignis_leer_oder_unbekannt() -> void:
	# Arrange
	var catalog := _grundkatalog()
	_setze(catalog, Difficulty.Level.SCHWER, [
		_start_modifikator({"event_id": "", "id": "ohne_ereignis"}),
		_start_modifikator({"event_id": "gibt_es_nicht"}),
	])

	# Act
	var gefunden := CatalogValidator.validate(catalog)

	# Assert
	assert_eq(_stellen(gefunden), ["V25 ERROR - profiles.schwer[0].event_id",
		"V25 ERROR - profiles.schwer[1].event_id"])
	assert_eq(_meldungstexte(gefunden), [
		"Profil „Schwer“, Start-Modifikator „ohne_ereignis“, Feld "
			+ "„profiles.schwer[0].event_id“: Der Start-Modifikator nennt kein Ereignis.",
		"Profil „Schwer“, Start-Modifikator „reklamationswelle“, Feld "
			+ "„profiles.schwer[1].event_id“: Das Ereignis „gibt_es_nicht“ gibt es im "
			+ "Katalog nicht.",
	])


func test_v26_fuer_alle_vier_falschen_arten() -> void:
	# Arrange: Der Grundkatalog hat jede Art einmal; nur die Reklamationswelle kommt über
	# Wahrscheinlichkeit.
	var catalog := _grundkatalog()
	var ziele := ["intel_pentium", "weihnachtsgeschaeft", "neubaugebiet", "zeitungsartikel",
		"reklamationswelle"]
	var modifikatoren: Array[ChanceModifier] = []
	for ziel: String in ziele:
		modifikatoren.append(_start_modifikator({"event_id": ziel, "id": ziel}))
	_setze(catalog, Difficulty.Level.SCHWER, modifikatoren)

	# Act
	var gefunden := CatalogValidator.validate(catalog)

	# Assert
	assert_eq(_stellen(gefunden), ["V26 ERROR - profiles.schwer[0].event_id",
		"V26 ERROR - profiles.schwer[1].event_id", "V26 ERROR - profiles.schwer[2].event_id",
		"V26 ERROR - profiles.schwer[3].event_id"], "Fix, jährlich, gesetzt, nur als Folge.")
	var texte := _meldungstexte(gefunden)
	for i in 4:
		assert_string_contains(texte[i] if i < texte.size() else "",
			"Start-Modifikatoren gehören nur zu Ereignissen über Wahrscheinlichkeit.")
	assert_eq(texte[1] if texte.size() > 1 else "", "Profil „Schwer“, Start-Modifikator "
		+ "„weihnachtsgeschaeft“, Feld „profiles.schwer[1].event_id“: „weihnachtsgeschaeft“ "
		+ "hat die Art „fix, jährlich“; Start-Modifikatoren gehören nur zu Ereignissen über "
		+ "Wahrscheinlichkeit.", "US2, Szenario 2.")


func test_v27_und_v28_und_dann_keine_warnung_v31() -> void:
	# Arrange: alle Tage mitten im Monat, damit V31 sich melden könnte.
	var catalog := _grundkatalog()
	_setze(catalog, Difficulty.Level.SCHWER, [
		_start_modifikator({"id": "umgedreht", "from_day": _tag(1995, 3, 15),
			"to_day": _tag(1990, 6, 15)}),
		_start_modifikator({"id": "zu_frueh", "from_day": _tag(1984, 3, 15),
			"to_day": _tag(1994, 6, 15)}),
		_start_modifikator({"id": "zu_spaet", "from_day": _tag(1990, 3, 15),
			"to_day": _tag(2000, 6, 15)}),
		_start_modifikator({"id": "beides", "from_day": _tag(1984, 1, 1),
			"to_day": _tag(2000, 12, 31)}),
	])

	# Act
	var gefunden := CatalogValidator.validate(catalog)

	# Assert: V31 prüft nicht, wenn V27 oder V28 gilt (Analyse, U7).
	assert_eq(_stellen(gefunden), [
		"V27 ERROR - profiles.schwer[0].to_day",
		"V28 ERROR - profiles.schwer[1].from_day",
		"V28 ERROR - profiles.schwer[2].to_day",
		"V28 ERROR - profiles.schwer[3].from_day",
		"V28 ERROR - profiles.schwer[3].to_day",
	])
	var texte := _meldungstexte(gefunden)
	assert_string_ends_with(texte[0] if not texte.is_empty() else "",
		"Feld „profiles.schwer[0].to_day“: Der Start-Modifikator endet am 15.06.1990, vor seinem "
		+ "Beginn am 15.03.1995.")
	assert_string_ends_with(texte[1] if texte.size() > 1 else "",
		"Feld „profiles.schwer[1].from_day“: Der Beginn 15.03.1984 liegt außerhalb von 01.01.1985 "
		+ "bis 31.12.1999.")


func test_v29_grund_aus_leerzeichen() -> void:
	# Arrange
	var catalog := _grundkatalog()
	_setze(catalog, Difficulty.Level.LEICHT, [
		_start_modifikator({"reason": "   ", "id": "leerzeichen"}),
		_start_modifikator({"reason": "\t", "id": "tab"}),
		_start_modifikator({"reason": " x ", "id": "mit_text"}),
	])

	# Act und Assert
	assert_eq(_stellen(CatalogValidator.validate(catalog)),
		["V29 ERROR - profiles.leicht[0].reason", "V29 ERROR - profiles.leicht[1].reason"])


func test_v30_leer_falsche_zeichen_und_doppelt_bei_jedem_eintrag() -> void:
	# Arrange: „welle“ dreimal in Schwer und einmal in Leicht; doppelt zählt nur im selben Profil.
	var catalog := _grundkatalog()
	_setze(catalog, Difficulty.Level.SCHWER, [
		_start_modifikator({"id": ""}),
		_start_modifikator({"id": "Reklamations-Welle"}),
		_start_modifikator({"id": "welle"}),
		_start_modifikator({"id": "welle"}),
		_start_modifikator({"id": "einmal"}),
		_start_modifikator({"id": "welle"}),
	])
	_setze(catalog, Difficulty.Level.LEICHT, [_start_modifikator({"id": "welle"})])

	# Act
	var gefunden := CatalogValidator.validate(catalog)

	# Assert
	assert_eq(_stellen(gefunden), [
		"V30 ERROR - profiles.schwer[0].id",
		"V30 ERROR - profiles.schwer[1].id",
		"V30 ERROR - profiles.schwer[2].id",
		"V30 ERROR - profiles.schwer[3].id",
		"V30 ERROR - profiles.schwer[5].id",
	], "Eine Dublette bei jedem Start-Modifikator mit dieser Kennung.")
	assert_eq(_meldungstexte(gefunden).slice(0, 3), [
		"Profil „Schwer“, Start-Modifikator Nr. 1 ohne Kennung, Feld „profiles.schwer[0].id“: Die "
			+ "Kennung ist leer.",
		"Profil „Schwer“, Start-Modifikator „Reklamations-Welle“, Feld „profiles.schwer[1].id“: "
			+ "Die Kennung „Reklamations-Welle“ enthält andere Zeichen als a–z, 0–9 und _.",
		"Profil „Schwer“, Start-Modifikator „welle“, Feld „profiles.schwer[2].id“: Die Kennung "
			+ "„welle“ gibt es in diesem Profil mehrfach.",
	])


func test_v31_beginn_ende_beide_und_wirkt_nie() -> void:
	# Arrange (R8): Gewürfelt wird am Monatsersten.
	var catalog := _grundkatalog()
	_setze(catalog, Difficulty.Level.SCHWER, [
		_start_modifikator({"from_day": _tag(1990, 3, 15)}),
		_start_modifikator({"to_day": _tag(1994, 6, 15)}),
		_start_modifikator({"from_day": _tag(1990, 3, 15), "to_day": _tag(1994, 6, 15)}),
		_start_modifikator({"from_day": _tag(1990, 3, 2), "to_day": _tag(1990, 3, 31)}),
		_start_modifikator({"from_day": _tag(1990, 3, 2), "to_day": _tag(1990, 3, 15)}),
		_start_modifikator({"from_day": _tag(1999, 12, 15), "to_day": _tag(1999, 12, 31)}),
	])
	for i in 6:
		catalog.get_profile(Difficulty.Level.SCHWER).modifiers[i].id = "nr_%d" % i

	# Act
	var gefunden := CatalogValidator.validate(catalog)

	# Assert
	assert_eq(_stellen(gefunden), [
		"V31 WARNING - profiles.schwer[0].from_day",
		"V31 WARNING - profiles.schwer[1].to_day",
		"V31 WARNING - profiles.schwer[2].from_day",
		"V31 WARNING - profiles.schwer[2].to_day",
		"V31 WARNING - profiles.schwer[3].from_day",
		"V31 WARNING - profiles.schwer[4].from_day",
		"V31 WARNING - profiles.schwer[5].from_day",
	], "Beginn, Ende, beide, und dreimal „wirkt nie“ mit nur einer Warnung.")
	var gruende := _gruende(gefunden)
	assert_eq(gruende.slice(0, 2), [
		"Der Beginn 15.03.1990 ist kein Monatserster; der Start-Modifikator wirkt ab der "
			+ "Würfelrunde am 01.04.1990.",
		"Das Ende 15.06.1994 ist kein Monatsletzter; der Start-Modifikator wirkt noch in der "
			+ "Würfelrunde am 01.06.1994.",
	])
	var nie := "Zwischen %s und %s liegt keine Würfelrunde; der Start-Modifikator wirkt nie."
	assert_eq(gruende.slice(4), [
		nie % ["02.03.1990", "31.03.1990"],
		nie % ["02.03.1990", "15.03.1990"],
		nie % ["15.12.1999", "31.12.1999"],
	])
	assert_false(CatalogValidator.has_errors(gefunden), "V31 ist nur eine Warnung.")


func test_v31_zeitraum_mit_genau_einem_monatsersten_wirkt_in_dieser_wuerfelrunde() -> void:
	# Arrange: Beide liegen auf einem Monatsersten oder schließen ihn ein; der erste besteht nur
	# aus diesem einen Tag. Sie wirken also, und es warnt nur das Ende.
	var catalog := _grundkatalog()
	_setze(catalog, Difficulty.Level.SCHWER, [
		_start_modifikator({"id": "ein_tag", "from_day": _tag(1993, 2, 1),
			"to_day": _tag(1993, 2, 1)}),
		_start_modifikator({"id": "fuenf_tage", "from_day": _tag(1990, 3, 1),
			"to_day": _tag(1990, 3, 5)}),
	])

	# Act
	var gefunden := CatalogValidator.validate(catalog)

	# Assert
	assert_eq(_stellen(gefunden), ["V31 WARNING - profiles.schwer[0].to_day",
		"V31 WARNING - profiles.schwer[1].to_day"], "Kein „wirkt nie“.")
	assert_eq(_gruende(gefunden), [
		"Das Ende 01.02.1993 ist kein Monatsletzter; der Start-Modifikator wirkt noch in der "
			+ "Würfelrunde am 01.02.1993.",
		"Das Ende 05.03.1990 ist kein Monatsletzter; der Start-Modifikator wirkt noch in der "
			+ "Würfelrunde am 01.03.1990.",
	])


func test_ganzes_spiel_und_ganze_monate_ohne_meldung() -> void:
	# Arrange: 01.01.1985 bis 31.12.1999, ein März, ein Februar im Schaltjahr und einer ohne
	var catalog := _grundkatalog()
	_setze(catalog, Difficulty.Level.SCHWER, [
		_start_modifikator({"id": "ganz"}),
		_start_modifikator({"id": "maerz", "from_day": _tag(1990, 3, 1),
			"to_day": _tag(1990, 3, 31)}),
		_start_modifikator({"id": "schalt", "from_day": _tag(1992, 2, 1),
			"to_day": _tag(1992, 2, 29)}),
		_start_modifikator({"id": "februar", "from_day": _tag(1993, 2, 1),
			"to_day": _tag(1993, 2, 28)}),
	])
	_setze(catalog, Difficulty.Level.LEICHT, [_start_modifikator({"value": 0.0})])

	# Act und Assert
	assert_eq(_stellen(CatalogValidator.validate(catalog)), [], "Auch ein Wert von 0 ist erlaubt.")


func test_reihenfolge_ereignisse_kategorien_dann_profile() -> void:
	# Arrange: ein Fehler am Ereignis, einer an der Kategorie; in Schwer an Stelle 1 zwei Regeln,
	# an Stelle 0 eine Warnung, in Leicht an Stelle 0 eine leere Kennung.
	var catalog := _grundkatalog()
	catalog.categories[0].color = &"papier"
	catalog.get_event("intel_pentium").date = _tag(2001, 5, 12)
	_setze(catalog, Difficulty.Level.SCHWER, [
		_start_modifikator({"from_day": _tag(1990, 3, 15)}),
		_start_modifikator({"event_id": "", "reason": "", "id": "zweiter"}),
	])
	_setze(catalog, Difficulty.Level.LEICHT, [_start_modifikator({"id": ""})])

	# Act
	var gefunden := CatalogValidator.validate(catalog)

	# Assert: Leicht vor Schwer, je Profil nach Stelle, je Start-Modifikator nach Regel.
	var profile := [
		"V30 ERROR - profiles.leicht[0].id",
		"V31 WARNING - profiles.schwer[0].from_day",
		"V25 ERROR - profiles.schwer[1].event_id",
		"V29 ERROR - profiles.schwer[1].reason",
	]
	var vorne := ["V06 ERROR intel_pentium date", "V21 ERROR - categories[0].color"]
	assert_eq(_stellen(gefunden), vorne + profile, "Ereignisse, Kategorien, dann die Profile.")
	assert_eq(_stellen(CatalogValidator.validate_profiles(catalog)), profile,
		"validate_profiles() bringt nur die Profile.")
	for issue in CatalogValidator.validate_profiles(catalog):
		assert_eq(issue.event_id, "", "Kein Ereignis, auch wenn er auf eines zeigt: %s" % issue)


# --- Helfer ---------------------------------------------------------------

## Eine frisch gelesene Kopie des fehlerfreien Grundkatalogs.
func _grundkatalog() -> EventCatalog:
	var issues: Array[CatalogIssue] = []
	return EventCatalog.read_file(GRUNDKATALOG, issues)


## Ein gültiger Start-Modifikator: +5 auf die Reklamationswelle, das ganze Spiel. [param felder]
## setzt einzelne Felder, etwa {"reason": ""}.
func _start_modifikator(felder: Dictionary = {}) -> ChanceModifier:
	var modifikator := ChanceModifier.new()
	modifikator.id = "reklamationswelle"
	modifikator.event_id = "reklamationswelle"
	modifikator.reason = "Anspruchsvolle Kunden"
	modifikator.value = 0.05
	modifikator.from_day = TimelineRun.FIRST_DAY
	modifikator.to_day = TimelineRun.LAST_DAY
	for feld: String in felder:
		modifikator.set(feld, felder[feld])
	return modifikator


## Setzt die Start-Modifikatoren des Profils von [param grad] im Katalog.
func _setze(catalog: EventCatalog, grad: Difficulty.Level,
		modifikatoren: Array[ChanceModifier]) -> void:
	catalog.get_profile(grad).modifiers = modifikatoren


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()


## Die Texte der Meldungen in ihrer Reihenfolge.
func _meldungstexte(issues: Array[CatalogIssue]) -> Array:
	var texte := []
	for issue in issues:
		texte.append(issue.message)
	return texte


## Der Grund jeder Meldung: ihr Text hinter dem Feld.
func _gruende(issues: Array[CatalogIssue]) -> Array:
	var gruende := []
	for issue in issues:
		gruende.append(issue.message.get_slice("“: ", 1))
	return gruende


## Die Meldungen als „<Regel> <Stufe> <Kennung> <Feld>“, in ihrer Reihenfolge.
func _stellen(issues: Array[CatalogIssue]) -> Array:
	var stellen := []
	for issue in issues:
		var kennung := issue.event_id if not issue.event_id.is_empty() else "-"
		stellen.append("%s %s %s %s"
			% [issue.rule, CatalogIssue.Severity.keys()[issue.severity], kennung, issue.field])
	return stellen


## Die Meldungen ganz, mit Text, für den Vergleich von validate_event() und validate().
func _texte(issues: Array[CatalogIssue]) -> Array:
	var texte := []
	for issue in issues:
		texte.append(str(issue))
	return texte
