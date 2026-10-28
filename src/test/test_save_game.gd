extends GutTest

## Prüft SaveGame und SaveSlot (Feature 004, T006 und T007; data-model.md, „SaveGame“ und
## „SaveSlot“; research.md, R1, R2 und R10): den kanonischen Text der Datei, die Rundreise
## Speicher → Text → Speicher, jede Zeile der Tabelle „Zustand“ mit ihrem Grund, die Zeitpunkte in
## UTC und in Ortszeit, und die Fixtures unter fixtures/spielstaende/ mit Zustand und Grund.
##
## Die Gründe stehen hier als ganze Sätze, nicht als Konstanten aus dem Code: So fällt jede
## Änderung an einem Satz für den Spieler hier auf. Kein Grund darf einen Wert aus der Datei oder
## ein Wort aus dem Inneren wie Seed oder Formatversion enthalten (Klaus, 2026-10-26); Feld, Wert
## und genaue Stelle stehen nur in den Einzelheiten für das Protokoll; jeder Fall prüft auch sie.
##
## Die Fixtures liest der Test nicht an Ort und Stelle, sondern kopiert sie unter einem Namen nach
## dem Muster spiel_<N>.json in den eigenen Ordner ORDNER, den after_each() wieder abräumt. Kataloge
## kommen aus fixtures/, nie aus src/data/.

const ORDNER := "user://test_save_game/"
const FIXTURES := "res://test/fixtures/spielstaende/"
const KATALOG := "res://test/fixtures/catalog_alle_arten.json"
## 26.10.2026, 20:40:12 UTC
const ANGELEGT := 1793047212
## 27.10.2026, 18:05:00 UTC
const GESPIELT := 1793124300

const KEIN_JSON := "Lässt sich nicht lesen: Die Datei ist beschädigt."
const ZU_NEU := "Mit einer neueren Version gespeichert."
## Formatversion, Pflichtfeld, Seed, Zeitpunkt, Eingriff und Katalog: Welcher Teil es ist, sagt nur
## das Protokoll.
const TEIL := "Lässt sich nicht lesen: Ein Teil der Datei stimmt nicht."
const GRAD := "Der Schwierigkeitsgrad ist unbekannt."
const DATUM := "Das Spieldatum ist kein Tag von 1985 bis 1999."
## Alle Sätze für den Spieler (data-model.md, „Zustand“). Jeder Grund muss einer davon sein.
const ALLE_GRUENDE := [KEIN_JSON, ZU_NEU, TEIL, GRAD, DATUM]
## Wörter aus dem Inneren, die nur ins Protokoll gehören; klein geschrieben, verglichen wird mit dem
## klein geschriebenen Satz, so fallen auch „Formatversion“ und „Ereigniskatalog“ darunter.
const NUR_IM_PROTOKOLL := ["seed", "format", "eingriff", "katalog"]


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)


func after_each() -> void:
	_raeume_auf(ORDNER)
	# Die Stellschraube gilt für das ganze Programm; ein Test, der sie setzt, darf keinem anderen
	# eine Zeitzone hinterlassen, auch wenn er vorher abbricht (Feature 007, T005).
	SaveGame.time_zone_bias = SaveGame.SYSTEM_BIAS


# --- Name, Text, Rundreise (T006) --------------------------------------------------------------

func test_default_name_ist_spiel_und_nummer() -> void:
	# Act und Assert
	assert_eq(SaveGame.default_name(1), "Spiel 1")
	assert_eq(SaveGame.default_name(9999), "Spiel 9999")


func test_to_json_ist_kanonisch() -> void:
	# Arrange: ein leerer Katalog, damit die Erwartung kurz bleibt, und zwei Eingriffe, einer vor
	# Spielbeginn mit einem Modifikator darin.
	var game := _spielstand()
	var erwartet := "\n".join(PackedStringArray([
		"{",
		"\t\"catalog\": {",
		"\t\t\"categories\": [],",
		"\t\t\"events\": [],",
		"\t\t\"format\": 1,",
		"\t\t\"profiles\": {",
		"\t\t\t\"leicht\": [],",
		"\t\t\t\"schwer\": []",
		"\t\t}",
		"\t},",
		"\t\"created_at\": \"2026-10-26T20:40:12Z\",",
		"\t\"day\": \"1986-03-14\",",
		"\t\"difficulty\": \"schwer\",",
		"\t\"format\": 1,",
		"\t\"game_version\": \"0.1\",",
		"\t\"interventions\": [",
		"\t\t{",
		"\t\t\t\"at_day\": \"1984-12-31\",",
		"\t\t\t\"kind\": \"add_modifier\",",
		"\t\t\t\"modifier\": {",
		"\t\t\t\t\"event_id\": \"reklamationswelle\",",
		"\t\t\t\t\"from_day\": \"1990-01-01\",",
		"\t\t\t\t\"id\": \"windiger_haendler\",",
		"\t\t\t\t\"reason\": \"Ware vom windigen Händler\",",
		"\t\t\t\t\"to_day\": \"1993-12-31\",",
		"\t\t\t\t\"value\": 0.05",
		"\t\t\t}",
		"\t\t},",
		"\t\t{",
		"\t\t\t\"at_day\": \"1986-01-02\",",
		"\t\t\t\"day\": \"1986-06-01\",",
		"\t\t\t\"event_id\": \"reklamationswelle\",",
		"\t\t\t\"kind\": \"cancel\",",
		"\t\t\t\"reason\": \"Kunde abgesprungen\"",
		"\t\t}",
		"\t],",
		"\t\"last_played_at\": \"2026-10-27T18:05:00Z\",",
		"\t\"name\": \"Spiel 2\",",
		"\t\"number\": 2,",
		"\t\"seed\": 4711",
		"}",
		"",
	]))

	# Act
	var text := game.to_json()

	# Assert
	assert_eq(text, erwartet, "Schlüssel alphabetisch, Tabs, Zeilenumbruch am Ende.")
	assert_eq(game.to_json(), text, "Gleicher Spielstand, gleiche Datei.")


func test_rundreise_speicher_text_speicher() -> void:
	# Arrange: mit dem Katalog aller Arten, wie ein Spiel ihn speichert
	var game := _spielstand(_katalog())
	var text := game.to_json()

	# Act
	var ergebnis := _lies(JSON.parse_string(text), 2)
	var zurueck: SaveGame = ergebnis[0]

	# Assert
	assert_not_null(zurueck, "Gelesen: %s" % [ergebnis[2]])
	if zurueck == null:
		return
	assert_eq([zurueck.number, zurueck.name, zurueck.difficulty, zurueck.seed, zurueck.day],
		[2, "Spiel 2", Difficulty.Level.SCHWER, 4711, _tag(1986, 3, 14)])
	assert_eq([zurueck.created_at, zurueck.last_played_at, zurueck.game_version],
		[ANGELEGT, GESPIELT, "0.1"])
	assert_eq(zurueck.interventions, game.interventions, "Eingriffe wieder mit Tagesindizes.")
	assert_eq(typeof(zurueck.interventions[1]["day"]), TYPE_INT)
	assert_eq(zurueck.catalog.to_dict(), game.catalog.to_dict(), "Derselbe Katalog.")
	assert_eq(zurueck.to_json(), text, "Wieder geschrieben, Zeichen für Zeichen derselbe Text.")
	assert_eq(ergebnis[1], [], "Kein Grund.")


func test_nummer_kommt_aus_dem_dateinamen() -> void:
	# Arrange: In der Datei steht 7, der Dateiname sagt 3.
	var daten := _gueltige_daten()
	daten["number"] = 7

	# Act
	var game: SaveGame = _lies(daten, 3)[0]

	# Assert
	assert_eq(game.number, 3, "Der Dateiname gilt (R4).")


func test_unbekannte_schluessel_stoeren_nicht() -> void:
	# Arrange: Ein späteres Feature fügt eigene Daten hinzu (Analyse, B3).
	var daten := _gueltige_daten()
	daten["laden"] = {"name": "Computer Müller"}

	# Act
	var ergebnis := _lies(daten)

	# Assert
	assert_not_null(ergebnis[0])
	assert_eq(ergebnis[1], [])


func test_upgrade_laesst_format_1_unveraendert() -> void:
	# Arrange
	var daten := _gueltige_daten()
	var vorher := daten.duplicate(true)

	# Act
	var danach := SaveGame._upgrade(daten, 1)

	# Assert
	assert_eq(danach, vorher, "Mit Format 1 gibt es nichts umzuwandeln (Analyse, E4).")


# --- Zeitpunkte und Datum (T006) ---------------------------------------------------------------

func test_zeitpunkte_stehen_als_utc_in_der_datei() -> void:
	# Arrange
	var daten := _gueltige_daten()

	# Act
	daten["created_at"] = "1970-01-01T00:00:00Z"
	daten["last_played_at"] = "2000-02-29T23:59:59Z"
	var game: SaveGame = _lies(daten)[0]

	# Assert: Die Datei steht in UTC, mit „Z“; ihr Text hängt nicht an der Zeitzone des Rechners.
	assert_eq(_gueltige_daten()["created_at"], "2026-10-26T20:40:12Z")
	assert_eq(_gueltige_daten()["last_played_at"], "2026-10-27T18:05:00Z")
	assert_eq([game.created_at, game.last_played_at], [0, 951868799], "Gelesen als Unix-Zeit.")


func test_ortszeit_mit_vorgegebenem_versatz() -> void:
	# Act und Assert: Versatz in Minuten zu UTC (Analyse, C3)
	assert_eq(SaveGame.time_text(ANGELEGT, 60), "26.10.2026 21:40", "Winterzeit in Deutschland.")
	assert_eq(SaveGame.time_text(ANGELEGT, 0), "26.10.2026 20:40")
	assert_eq(SaveGame.time_text(ANGELEGT, 240), "27.10.2026 00:40", "Über Mitternacht.")
	assert_eq(SaveGame.time_text(ANGELEGT, -300), "26.10.2026 15:40", "Westlich von UTC.")


func test_ortszeit_ohne_vorgabe_nimmt_den_versatz_des_rechners() -> void:
	# Arrange
	var versatz: int = Time.get_time_zone_from_system().get("bias", 0)

	# Act und Assert
	assert_eq(SaveGame.time_text(ANGELEGT), SaveGame.time_text(ANGELEGT, versatz))


# --- Stellschraube für den Zeitzonenversatz (Feature 007, T005; R7) ----------------------------

func test_stellschraube_steht_ohne_selbsttest_auf_dem_rechner() -> void:
	# Act und Assert: Ohne Selbsttest bleibt alles wie vorher.
	assert_eq(SaveGame.time_zone_bias, SaveGame.SYSTEM_BIAS)


func test_stellschraube_gilt_fuer_uhrzeiten_ohne_eigenen_versatz() -> void:
	# Arrange: wie der Selbsttest, UTC+1
	SaveGame.time_zone_bias = 60

	# Act
	var ohne_versatz := SaveGame.time_text(ANGELEGT)
	var westlich := SaveGame.time_text(ANGELEGT, -300)
	SaveGame.time_zone_bias = SaveGame.SYSTEM_BIAS

	# Assert
	assert_eq(ohne_versatz, "26.10.2026 21:40", "Die feste Zeit des Selbsttests, 20:40 UTC.")
	assert_eq(westlich, "26.10.2026 15:40", "Ein ausdrücklicher Versatz geht vor.")


func test_stellschraube_auch_ueber_mitternacht_und_westlich() -> void:
	# Act
	SaveGame.time_zone_bias = 240
	var oestlich := SaveGame.time_text(ANGELEGT)
	SaveGame.time_zone_bias = -300
	var westlich := SaveGame.time_text(ANGELEGT)
	SaveGame.time_zone_bias = 0
	var utc := SaveGame.time_text(ANGELEGT)
	SaveGame.time_zone_bias = SaveGame.SYSTEM_BIAS

	# Assert: 0 ist UTC, nicht „wie der Rechner“.
	assert_eq(oestlich, "27.10.2026 00:40")
	assert_eq(westlich, "26.10.2026 15:40")
	assert_eq(utc, "26.10.2026 20:40")


func test_stellschraube_zurueckgesetzt_nimmt_wieder_den_rechner() -> void:
	# Arrange
	var versatz: int = Time.get_time_zone_from_system().get("bias", 0)
	SaveGame.time_zone_bias = versatz + 180

	# Act
	SaveGame.time_zone_bias = SaveGame.SYSTEM_BIAS

	# Assert
	assert_eq(SaveGame.time_text(ANGELEGT), SaveGame.time_text(ANGELEGT, versatz))


func test_stellschraube_aendert_die_datei_nicht() -> void:
	# Arrange
	var game := _spielstand()
	var vorher := game.to_json()

	# Act
	SaveGame.time_zone_bias = 60
	var danach := game.to_json()
	SaveGame.time_zone_bias = SaveGame.SYSTEM_BIAS

	# Assert: In der Datei steht UTC; die Stellschraube gilt nur für die Anzeige.
	assert_eq(danach, vorher)


func test_day_text_ist_das_spieldatum() -> void:
	# Arrange
	var game := SaveGame.new()

	# Act und Assert
	game.day = _tag(1986, 3, 14)
	assert_eq(game.day_text(), "14.03.1986")
	game.day = TimelineRun.FIRST_DAY
	assert_eq(game.day_text(), "01.01.1985")
	game.day = TimelineRun.LAST_DAY
	assert_eq(game.day_text(), "31.12.1999")


# --- Tabelle „Zustand“ (T006) ------------------------------------------------------------------

func test_formatversion_fehlt_oder_stimmt_nicht() -> void:
	# [Wert, wie das Protokoll ihn zeigt]
	var faelle := [[null, "fehlt"], ["eins", "„eins“"], [0, "0"], [-1, "-1"], [1.5, "1.5"],
		[true, "true"], [[1], "[1]"]]
	for fall: Array in faelle:
		# Arrange
		var daten := _gueltige_daten()
		if fall[0] == null:
			daten.erase("format")
		else:
			daten["format"] = fall[0]

		# Act und Assert
		_erwarte_grund(daten, TEIL, "Die Formatversion „format“ fehlt oder ist keine ganze Zahl "
			+ "ab 1: %s." % fall[1], "format %s" % [fall[0]])
	var als_float := _gueltige_daten()
	als_float["format"] = 1.0
	assert_not_null(_lies(als_float)[0], "Aus JSON kommt 1 als 1.0.")


func test_neuere_formatversion_nimmt_from_data_nie_an() -> void:
	# Arrange: SaveSlot prüft das vorher; kommt so eine Datei trotzdem hier an, gibt es keinen
	# Spielstand.
	var daten := _gueltige_daten()
	daten["format"] = 2

	# Act und Assert
	_erwarte_grund(daten, ZU_NEU, "Formatversion 2, diese Version liest höchstens 1.", "format 2")


func test_jedes_fehlende_pflichtfeld() -> void:
	for feld: String in SaveGame.REQUIRED_KEYS:
		# Arrange
		var daten := _gueltige_daten()
		daten.erase(feld)

		# Act und Assert: Ohne format greift die Zeile davor; gleicher Satz, andere Stelle.
		var stelle := "Die Formatversion „format“ fehlt" if feld == "format" \
			else "Das Feld „%s“ fehlt." % feld
		_erwarte_grund(daten, TEIL, stelle, "ohne %s" % feld)
	assert_eq(SaveGame.REQUIRED_KEYS, ["catalog", "created_at", "day", "difficulty", "format",
		"game_version", "interventions", "last_played_at", "name", "number", "seed"],
		"Alle Schlüssel aus data-model.md, „Pflichtfelder“.")


func test_leerer_name_zaehlt_wie_ein_fehlender() -> void:
	for wert: String in ["", "   ", "\t"]:
		# Arrange
		var daten := _gueltige_daten()
		daten["name"] = wert

		# Act und Assert
		_erwarte_grund(daten, TEIL, "Das Feld „name“ ist leer.", "name „%s“" % wert)


func test_pflichtfeld_mit_falschem_typ() -> void:
	var faelle := [
		["name", 2], ["difficulty", 2], ["day", 437], ["created_at", ANGELEGT],
		["last_played_at", null], ["game_version", 0.1], ["number", "2"], ["number", 2.5],
		["seed", "4711"], ["seed", 4711.5], ["interventions", {}], ["interventions", "keine"],
	]
	for fall: Array in faelle:
		# Arrange
		var daten := _gueltige_daten()
		daten[fall[0]] = fall[1]

		# Act und Assert: „ist kein Text“, „ist keine ganze Zahl“ oder „ist keine Liste“
		_erwarte_grund(daten, TEIL, "Das Feld „%s“ ist kein" % fall[0],
			"%s = %s" % [fall[0], fall[1]])


func test_grad_unbekannt() -> void:
	for wert: String in ["extrem", "Schwer", ""]:
		# Arrange
		var daten := _gueltige_daten()
		daten["difficulty"] = wert

		# Act und Assert
		_erwarte_grund(daten, GRAD, "Schwierigkeitsgrad „%s“." % wert, "Grad „%s“" % wert)
	for grad: String in ["leicht", "mittel", "schwer"]:
		var daten := _gueltige_daten()
		daten["difficulty"] = grad
		var game: SaveGame = _lies(daten)[0]
		assert_eq(Difficulty.key(game.difficulty), grad, "Bekannt: %s." % grad)


func test_seed_ausserhalb() -> void:
	# [Wert, wie das Protokoll ihn zeigt]
	for fall: Array in [[-1, "-1"], [2147483648.0, "2147483648"], [-2147483649, "-2147483649"]]:
		# Arrange
		var daten := _gueltige_daten()
		daten["seed"] = fall[0]

		# Act und Assert
		_erwarte_grund(daten, TEIL, "Seed %s." % fall[1], "Seed %s" % fall[1])
	for wert: Variant in [0, 2147483647.0]:
		var daten := _gueltige_daten()
		daten["seed"] = wert
		assert_eq(_lies(daten)[0].seed, int(wert), "Am Rand erlaubt: %s." % wert)


func test_spieldatum_ausserhalb() -> void:
	for wert: String in ["2000-01-01", "1984-12-31", "1986-02-30", "14.03.1986", "1986-3-14", ""]:
		# Arrange
		var daten := _gueltige_daten()
		daten["day"] = wert

		# Act und Assert
		_erwarte_grund(daten, DATUM, "Spieldatum „%s“." % wert, "Datum „%s“" % wert)
	for wert: String in ["1985-01-01", "1999-12-31"]:
		var daten := _gueltige_daten()
		daten["day"] = wert
		# Nur der Eingriff vor Spielbeginn: Der vom 02.01.1986 läge nach dem 01.01.1985 und machte
		# den Spielstand beschädigt (test_eingriff_nach_dem_spieldatum).
		daten["interventions"] = (daten["interventions"] as Array).slice(0, 1)
		assert_eq(_lies(daten)[0].day_text(), GameDate.from_iso(wert).to_string(),
			"Am Rand erlaubt: %s." % wert)


func test_zeitpunkt_nicht_lesbar() -> void:
	var falsch := ["gestern", "2026-10-26T20:40:12", "2026-10-26 20:40:12Z", "2026-10-26",
		"2026-10-26T24:00:00Z", "2026-10-26T20:60:00Z", "2026-02-30T20:40:12Z",
		"2026-10-26T2a:40:12Z", "2026-10-26T20:40:12+01:00", ""]
	for feld: String in ["created_at", "last_played_at"]:
		for wert: String in falsch:
			# Arrange
			var daten := _gueltige_daten()
			daten[feld] = wert

			# Act und Assert
			_erwarte_grund(daten, TEIL, "Zeitpunkt „%s“: „%s“." % [feld, wert],
				"%s „%s“" % [feld, wert])
	var vor_1970 := _gueltige_daten()
	vor_1970["last_played_at"] = "1969-12-31T23:59:59Z"
	_erwarte_grund(vor_1970, TEIL, "Zeitpunkt „last_played_at“: „1969-12-31T23:59:59Z“.",
		"zuletzt gespielt vor 1970, also unter 0")


func test_eingriff_mit_falschem_datum_oder_kein_objekt() -> void:
	# [Eingriffe, Stelle im Protokoll]
	var faelle := [
		[[5], "Eingriff 1 ist kein Objekt: 5."],
		[["Absage"], "Eingriff 1 ist kein Objekt: „Absage“."],
		[[{"at_day": "1986-01-02", "day": "1992-02-30", "kind": "cancel"}],
			"Eingriff 1: Bei „day“ steht „1992-02-30“"],
		[[{"at_day": "1986-01-02", "kind": "add_modifier", "modifier": {"from_day": "1990-13-01"}}],
			"Eingriff 1: Bei „from_day“ steht „1990-13-01“"],
		[[{"at_day": 2556, "kind": "cancel"}], "Eingriff 1: Bei „at_day“ steht 2556"],
		[[_eingriff_aus_der_datei(), 7], "Eingriff 2 ist kein Objekt: 7."],
	]
	for fall: Array in faelle:
		# Arrange
		var daten := _gueltige_daten()
		daten["interventions"] = fall[0]

		# Act und Assert
		_erwarte_grund(daten, TEIL, fall[1], "Eingriffe %s" % [fall[0]])


func test_eingriff_nach_dem_spieldatum() -> void:
	# Arrange (Feature 004, Phase 3; data-model.md, „Zustand“): Spieldatum 14.03.1986. Ein
	# Eingriff vom Tag danach schöbe den Lauf beim Fortsetzen über das Spieldatum hinaus.
	var danach := _gueltige_daten()
	danach["interventions"] = [_eingriff_aus_der_datei(), {"at_day": "1986-03-15",
		"day": "1986-06-01", "event_id": "reklamationswelle", "kind": "cancel", "reason": "Test"}]
	var am_tag := _gueltige_daten()
	am_tag["interventions"] = [{"at_day": "1986-03-14", "day": "1986-06-01",
		"event_id": "reklamationswelle", "kind": "cancel", "reason": "Test"}]
	var ohne_tag := _gueltige_daten()
	ohne_tag["interventions"] = [{"day": "1986-06-01", "event_id": "reklamationswelle",
		"kind": "cancel", "reason": "Test"}]

	# Act und Assert: beschädigt, die Einzelheit nur im Protokoll
	_erwarte_grund(danach, TEIL, "Eingriff 2 am „1986-03-15“ liegt nach dem Spieldatum "
		+ "„1986-03-14“.", "Eingriff am Tag nach dem Spieldatum")
	var gelesen := _lies(am_tag)
	assert_not_null(gelesen[0], "Ein Eingriff am Spieldatum selbst gilt: %s" % [gelesen[2]])
	gelesen = _lies(ohne_tag)
	assert_not_null(gelesen[0], "Ohne at_day gilt er, wo der Lauf steht: %s" % [gelesen[2]])


func test_katalog_nicht_lesbar() -> void:
	# Arrange: Zahl, Text und Liste statt Objekt; eine Formatversion, die nicht die ganze Zahl 1
	# ist (Claude, 2026-10-26: strenger als EventCatalog.from_data()).
	var kein_objekt := "Im Abschnitt „catalog“: Katalog: Erwartet wird ein Objekt"
	var formatversion := "Katalog mit der Formatversion %s, gelesen wird nur 1."
	# [Katalog, Stelle im Protokoll]
	var faelle := [[5, kein_objekt], ["Katalog", kein_objekt], [[], kein_objekt],
		[{"format": "zwei"}, formatversion % "„zwei“"], [{"format": 2}, formatversion % "2"],
		[{"format": 1.5}, formatversion % "1.5"], [{"format": null}, formatversion % "fehlt"]]
	for fall: Array in faelle:
		var daten := _gueltige_daten()
		daten["catalog"] = fall[0]

		# Act und Assert
		_erwarte_grund(daten, TEIL, fall[1], "Katalog %s" % [fall[0]])


func test_katalog_ohne_formatversion_und_mit_fehlerhaften_ereignissen_ist_lesbar() -> void:
	# Arrange: Fehlt „format“, gilt 1 wie beim Katalog. Ereignisse mit Fehlern machen den Spielstand
	# nicht kaputt; die nimmt erst das Fortsetzen heraus (R2).
	var ohne_format := _gueltige_daten()
	ohne_format["catalog"] = {"categories": [], "events": []}
	var mit_fehlern := _gueltige_daten()
	mit_fehlern["catalog"] = {"events": [{"id": "", "kind": "zaubern"}], "format": 1.0}

	# Act
	var a := _lies(ohne_format)
	var b := _lies(mit_fehlern)

	# Assert
	assert_not_null(a[0], "Ohne Formatversion: %s" % [a[2]])
	assert_not_null(b[0], "Mit fehlerhaftem Ereignis: %s" % [b[2]])
	if b[0] != null:
		assert_eq(b[0].catalog.events.size(), 1, "Das Ereignis steht im Katalog des Spielstands.")


func test_erster_treffer_gilt() -> void:
	# Arrange: mehrere Fehler auf einmal
	var a := _gueltige_daten()
	a.erase("format")
	a.erase("name")
	var b := _gueltige_daten()
	b["difficulty"] = "extrem"
	b["seed"] = -1
	b["catalog"] = 5
	var c := _gueltige_daten()
	c["day"] = "2000-01-01"
	c["created_at"] = "gestern"
	c["interventions"] = [5]

	# Act und Assert: in der Reihenfolge der Tabelle
	_erwarte_grund(a, TEIL, "Die Formatversion „format“ fehlt", "Format vor Pflichtfeld")
	_erwarte_grund(b, GRAD, "Schwierigkeitsgrad „extrem“.", "Grad vor Seed und Katalog")
	_erwarte_grund(c, DATUM, "Spieldatum „2000-01-01“.", "Datum vor Zeitpunkt und Eingriff")


func test_kein_wert_aus_der_datei_im_grund_aber_im_protokoll() -> void:
	# Arrange: Werte, die man im Grund wiedererkennen würde
	var daten := _gueltige_daten()
	daten["difficulty"] = "Grad mit sehr langem Namen, der den Hinweis sprengen würde"

	# Act
	var ergebnis := _lies(daten)

	# Assert
	assert_eq(ergebnis[1], [GRAD])
	assert_eq(ergebnis[2], ["Schwierigkeitsgrad „Grad mit sehr langem Namen, der den Hinweis "
		+ "sprengen würde“."], "Feld und Wert stehen nur in den Einzelheiten fürs Protokoll.")
	for grund: String in ALLE_GRUENDE:
		assert_false(grund.contains("seed") or grund.contains("difficulty")
			or grund.contains("format") or grund.contains("„"), "Kein Feldname und kein Wert: %s"
			% grund)


func test_kein_wort_aus_dem_inneren_in_einem_satz_fuer_den_spieler() -> void:
	# Arrange: die Sätze aus dem Code, alle Konstanten REASON_* beider Klassen, damit auch ein
	# später hinzugefügter Satz geprüft wird
	var aus_dem_code: Array[String] = []
	for pfad: String in ["res://core/save/save_game.gd", "res://core/save/save_slot.gd"]:
		var konstanten := (load(pfad) as Script).get_script_constant_map()
		for konstante: String in konstanten:
			if konstante.begins_with("REASON_"):
				aus_dem_code.append(konstanten[konstante])

	# Act und Assert: Der Spieler kennt Datei, Version, Grad und Spieldatum, nicht das Innere
	# (Klaus, 2026-10-26).
	aus_dem_code.sort()
	var erwartet := ALLE_GRUENDE.duplicate()
	erwartet.sort()
	assert_eq(aus_dem_code, erwartet, "Der Code hat genau die Sätze aus data-model.md.")
	for grund: String in ALLE_GRUENDE + aus_dem_code:
		for wort: String in NUR_IM_PROTOKOLL:
			assert_false(grund.to_lower().contains(wort),
				"„%s“ steht nicht in „%s“." % [wort, grund])


func test_ohne_einzelheiten_aufrufbar_wie_im_vertrag() -> void:
	# Arrange
	var daten := _gueltige_daten()
	daten["seed"] = -1
	var gruende: Array[String] = []

	# Act
	var game := SaveGame.from_data(daten, 2, gruende)

	# Assert
	assert_null(game)
	assert_eq(gruende, [TEIL])


# --- SaveSlot und Fixtures (T007) --------------------------------------------------------------

func test_jede_fixture_mit_zustand_und_grund() -> void:
	# Arrange: Fixture → [Nummer, Zustand, Grund, Anfang der Einzelheit im Protokoll]
	var faelle := {
		"spiel_kein_json.json": [11, SaveSlot.State.DAMAGED, KEIN_JSON,
			"kein gültiges JSON in Zeile"],
		"spiel_format_2.json": [12, SaveSlot.State.TOO_NEW, ZU_NEU,
			"Formatversion 2, diese Version liest höchstens 1."],
		"spiel_ohne_format.json": [13, SaveSlot.State.DAMAGED, TEIL,
			"Die Formatversion „format“ fehlt"],
		"spiel_grad_extrem.json": [14, SaveSlot.State.DAMAGED, GRAD,
			"Schwierigkeitsgrad „extrem“."],
		"spiel_seed_negativ.json": [15, SaveSlot.State.DAMAGED, TEIL, "Seed -1."],
		"spiel_seed_zu_gross.json": [16, SaveSlot.State.DAMAGED, TEIL, "Seed 2147483648."],
		"spiel_datum_2000.json": [17, SaveSlot.State.DAMAGED, DATUM, "Spieldatum „2000-01-01“."],
		"spiel_eingriff_datum.json": [18, SaveSlot.State.DAMAGED, TEIL,
			"Eingriff 1: Bei „day“ steht „1992-02-30“"],
		"spiel_katalog_zahl.json": [19, SaveSlot.State.DAMAGED, TEIL,
			"Im Abschnitt „catalog“: Katalog: Erwartet wird ein Objekt"],
	}
	for fixture: String in faelle:
		var nummer: int = faelle[fixture][0]
		var pfad := _kopiere(fixture, nummer)

		# Act
		var slot := SaveSlot.read(pfad, nummer)

		# Assert
		assert_eq([slot.number, slot.state, slot.reason, slot.path],
			[nummer, faelle[fixture][1], faelle[fixture][2], pfad], fixture)
		assert_null(slot.game, "Kein Spielstand: %s" % fixture)
		assert_false(slot.can_resume(), fixture)
		assert_eq(slot.display_name(), "Spiel %d" % nummer, "Der Name aus der Nummer: %s" % fixture)
		# Jede Warnung zählt in GUT nur für eine Prüfung; deshalb Pfad und Einzelheit in einer.
		assert_push_warning("Spielstand %s: %s" % [pfad, faelle[fixture][3]],
			"Pfad, Feld und Stelle im Protokoll: %s" % fixture)


func test_gueltige_fixture_laesst_sich_fortsetzen() -> void:
	# Arrange
	var pfad := _kopiere("spiel_gueltig.json", 3)

	# Act
	var slot := SaveSlot.read(pfad, 3)

	# Assert
	assert_eq([slot.state, slot.reason, slot.path], [SaveSlot.State.OK, "", pfad])
	assert_true(slot.can_resume())
	assert_push_warning_count(0, "Ein gültiger Spielstand meldet nichts.")
	if slot.game == null:
		fail_test("Kein Spielstand gelesen.")
		return
	var game := slot.game
	assert_eq(slot.display_name(), "Spiel 3")
	assert_eq([game.number, game.difficulty, game.seed, game.day_text(), game.game_version],
		[3, Difficulty.Level.SCHWER, 4711, "14.03.1986", "0.1"])
	assert_eq([game.created_at, game.last_played_at], [ANGELEGT, GESPIELT])
	assert_eq(game.catalog.to_dict(), _katalog().to_dict(), "Der Katalog aller Arten.")
	assert_eq(game.interventions.size(), 1, "Ein Eingriff.")
	assert_eq(game.interventions[0]["at_day"], -1, "Vor Spielbeginn.")
	assert_eq(game.to_json(), FileAccess.get_file_as_string(pfad), "Die Fixture ist kanonisch.")


func test_display_name_bei_ok_aus_der_datei() -> void:
	# Arrange: Später hat der Laden einen eigenen Namen (05 Standort), die Nummer bleibt.
	var game := _spielstand()
	game.name = "Computer Müller"
	var pfad := ORDNER.path_join("spiel_2.json")
	_schreibe(pfad, game.to_json())

	# Act
	var slot := SaveSlot.read(pfad, 2)

	# Assert
	assert_eq(slot.display_name(), "Computer Müller")


func test_fehlende_oder_nicht_lesbare_datei_gibt_nie_null() -> void:
	# Arrange
	var fehlt := ORDNER.path_join("spiel_5.json")
	var liste := ORDNER.path_join("spiel_6.json")
	_schreibe(liste, "[1, 2, 3]\n")
	var leer := ORDNER.path_join("spiel_7.json")
	_schreibe(leer, "")

	# Act
	var slots := [SaveSlot.read(fehlt, 5), SaveSlot.read(liste, 6), SaveSlot.read(leer, 7)]

	# Assert
	for slot: SaveSlot in slots:
		assert_not_null(slot)
		assert_eq([slot.state, slot.reason], [SaveSlot.State.DAMAGED, KEIN_JSON], slot.path)
	assert_push_warning("Die Datei fehlt.")
	assert_push_warning("kein Objekt")


func test_zu_neu_geht_vor_jedem_anderen_fehler() -> void:
	# Arrange: Format 3 und sonst fast nichts; eine neuere Version darf alles anders machen.
	var pfad := ORDNER.path_join("spiel_8.json")
	_schreibe(pfad, "{\"format\": 3, \"difficulty\": \"extrem\"}\n")
	var halb := ORDNER.path_join("spiel_9.json")
	_schreibe(halb, "{\"format\": 2.5, \"difficulty\": \"schwer\"}\n")

	# Act
	var slot := SaveSlot.read(pfad, 8)
	var kaputt := SaveSlot.read(halb, 9)

	# Assert
	assert_eq([slot.state, slot.reason], [SaveSlot.State.TOO_NEW, ZU_NEU])
	assert_eq([kaputt.state, kaputt.reason], [SaveSlot.State.DAMAGED, TEIL],
		"2,5 ist keine ganze Zahl, also keine Formatversion.")
	assert_push_warning("Spielstand %s: Formatversion 3, diese Version liest höchstens 1." % pfad)
	assert_push_warning("Spielstand %s: Die Formatversion „format“ fehlt oder ist keine ganze Zahl "
		% halb + "ab 1: 2.5.")


# --- Hilfen ---------------------------------------------------------------------------------

## Ein kleiner Spielstand „Spiel 2“ mit zwei Eingriffen; ohne Katalog ein leerer.
func _spielstand(katalog: EventCatalog = null) -> SaveGame:
	var game := SaveGame.new()
	game.number = 2
	game.name = SaveGame.default_name(2)
	game.difficulty = Difficulty.Level.SCHWER
	game.seed = 4711
	game.day = _tag(1986, 3, 14)
	game.created_at = ANGELEGT
	game.last_played_at = GESPIELT
	game.game_version = "0.1"
	game.catalog = katalog if katalog != null else EventCatalog.new()
	game.interventions.append({"at_day": -1, "kind": "add_modifier", "modifier": {
		"event_id": "reklamationswelle", "from_day": _tag(1990, 1, 1), "id": "windiger_haendler",
		"reason": "Ware vom windigen Händler", "to_day": _tag(1993, 12, 31), "value": 0.05}})
	game.interventions.append({"at_day": _tag(1986, 1, 2), "day": _tag(1986, 6, 1),
		"event_id": "reklamationswelle", "kind": "cancel", "reason": "Kunde abgesprungen"})
	return game


## Gelesenes JSON eines gültigen Spielstands, wie es aus der Datei kommt.
func _gueltige_daten() -> Dictionary:
	return JSON.parse_string(_spielstand().to_json())


## Ein Eingriff, wie er in der Datei steht.
func _eingriff_aus_der_datei() -> Dictionary:
	return {"at_day": "1986-01-02", "day": "1986-06-01", "event_id": "reklamationswelle",
		"kind": "cancel", "reason": "Kunde abgesprungen"}


## [Spielstand oder null, Gründe, Einzelheiten]
func _lies(daten: Dictionary, nummer: int = 2) -> Array:
	var gruende: Array[String] = []
	var einzelheiten: Array[String] = []
	var game := SaveGame.from_data(daten, nummer, gruende, einzelheiten)
	return [game, gruende, einzelheiten]


## Prüft den Satz für den Spieler [param grund] und, dass die Einzelheit fürs Protokoll die genaue
## [param stelle] nennt.
func _erwarte_grund(daten: Dictionary, grund: String, stelle: String, fall: String) -> void:
	var ergebnis := _lies(daten)
	assert_null(ergebnis[0], "Kein Spielstand: %s." % fall)
	assert_eq(ergebnis[1], [grund], "Grund: %s." % fall)
	assert_eq(ergebnis[2].size(), 1, "Eine Einzelheit fürs Protokoll: %s." % fall)
	if ergebnis[2].size() == 1:
		assert_string_contains(ergebnis[2][0], stelle)


func _katalog() -> EventCatalog:
	var issues: Array[CatalogIssue] = []
	return EventCatalog.read_file(KATALOG, issues)


## Kopiert eine Fixture als spiel_<nummer>.json in den Testordner und gibt den Pfad zurück.
func _kopiere(fixture: String, nummer: int) -> String:
	var ziel := ORDNER.path_join("spiel_%d.json" % nummer)
	assert_eq(DirAccess.copy_absolute(FIXTURES.path_join(fixture), ziel), OK,
		"Kopiert: %s" % fixture)
	return ziel


func _schreibe(pfad: String, text: String) -> void:
	var datei := FileAccess.open(pfad, FileAccess.WRITE)
	datei.store_string(text)
	datei.close()


func _raeume_auf(pfad: String) -> void:
	var ordner := DirAccess.open(pfad)
	if ordner == null:
		return
	for datei in ordner.get_files():
		ordner.remove(datei)
	for unterordner in ordner.get_directories():
		_raeume_auf(pfad.path_join(unterordner))
	DirAccess.remove_absolute(pfad)


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()
