extends GutTest

## Prüft SelbsttestProtokoll und die Wortlaute aus SelbsttestTexte (Feature 007, T002;
## contracts/protokoll.md; contracts/selbsttest-app.md, „Texte“; CHK033, CHK034, CHK039).
##
## Ein erfundener Lauf mit je einem Schritt OK, FEHLER und NICHT_GELAUFEN ergibt Byte für Byte
## die Erwartungen unter fixtures/selbsttest/. Die Erwartungen sind von Hand nach dem Vertrag
## geschrieben, nicht aus einer Ausgabe kopiert; ändert sich die Form, fällt es hier auf. Dazu die
## Ergebniszeile mit 1 und 37 Schritten, der Dativ und die Maschinenform einzelner Werte.

const FIXTURES := "res://test/fixtures/selbsttest/"
## 28.10.2026, 14:03:12, Ortszeit
const START := {"year": 2026, "month": 10, "day": 28, "hour": 14, "minute": 3, "second": 12}
## 26.10.2026, 20:40:00 UTC, die feste Zeit des Selbsttests (R7)
const FESTE_ZEIT := 1793047200
const ORDNER := ("/Users/klaus/Library/Application Support/Godot/app_userdata/"
	+ "Der Computerladen Selbsttest/selbsttest/2026-10-28_14-03-12")
const NICHT_BESCHREIBBAR := "/Volumes/Schreibgeschuetzt/selbsttest/2026-10-28_14-03-12"
## Alle Schlüssel der Tabelle „Systemdaten“ in data-model.md, abgeschrieben, nicht aus dem Code.
const TABELLE := ["system.os", "system.os_version", "system.cpu", "system.gpu",
	"system.gpu_vendor", "system.gpu_driver", "system.renderer", "system.grafik_api",
	"system.grafik_api_version", "system.bildschirm", "system.bildschirm_skalierung",
	"system.bildschirm_dpi", "system.bildwiederholrate", "system.fenster", "system.fenster_faktor",
	"system.sprache", "system.tastatur", "computerladen.version", "godot.version",
	"selbsttest.version", "selbsttest.gebaut", "lauf.start", "lauf.feste_zeit", "lauf.zeitraffer"]


# --- Byte für Byte -------------------------------------------------------------------------------

func test_protokoll_byte_fuer_byte() -> void:
	# Act
	var text := SelbsttestProtokoll.protokoll(_erfundener_lauf())

	# Assert
	_vergleiche(text, "protokoll_erwartet.txt")


func test_kopieren_byte_fuer_byte() -> void:
	# Act
	var text := SelbsttestProtokoll.kopieren(_erfundener_lauf(), ORDNER)

	# Assert
	_vergleiche(text, "kopieren_erwartet.txt")


func test_kopieren_bei_nicht_beschreibbarem_ordner_byte_fuer_byte() -> void:
	# Arrange: Der Lauf kam nie über das Anlegen hinaus.
	var lauf := _erfundener_lauf(false)
	lauf.dauer_ms = -1

	# Act
	var text := SelbsttestProtokoll.kopieren_nicht_beschreibbar(lauf, NICHT_BESCHREIBBAR)

	# Assert
	_vergleiche(text, "kopieren_nicht_beschreibbar.txt")


func test_erwartungen_sind_utf8_ohne_bom_mit_zeilenende_n() -> void:
	for datei: String in ["protokoll_erwartet.txt", "kopieren_erwartet.txt",
			"kopieren_nicht_beschreibbar.txt"]:
		# Act
		var bytes := FileAccess.get_file_as_bytes(FIXTURES + datei)

		# Assert
		assert_gt(bytes.size(), 3, datei)
		assert_ne(bytes.slice(0, 3), PackedByteArray([0xEF, 0xBB, 0xBF]), "Kein BOM: " + datei)
		assert_false(13 in bytes, "Kein \\r: " + datei)
		assert_eq(bytes[-1], 10, "Endet mit \\n: " + datei)


func test_kopieren_unterscheidet_sich_nur_in_den_schritten_ok_und_dem_ordner() -> void:
	# Arrange
	var lauf := _erfundener_lauf()

	# Act
	var datei := SelbsttestProtokoll.protokoll(lauf)
	var kopie := SelbsttestProtokoll.kopieren(lauf, ORDNER)

	# Assert: ohne den Block von titel.01_start und ohne „ordner:“ gleich (FR-014a)
	var block := datei.substr(datei.find("schritt: titel.01_start"))
	block = block.substr(0, block.find("\n\n") + 2)
	assert_eq(kopie.trim_suffix("\nordner: %s\n" % ORDNER), datei.replace(block, ""))


# --- Ergebniszeile -------------------------------------------------------------------------------

func test_alles_in_ordnung_mit_einem_schritt() -> void:
	# Arrange
	var lauf := _lauf_nur_ok(1)

	# Act
	var zeilen := SelbsttestProtokoll.protokoll(lauf).split("\n")

	# Assert: Dativ Einzahl
	assert_eq(zeilen[1], "ergebnis: Alles in Ordnung: 1 von 1 Schritt.")


func test_alles_in_ordnung_mit_37_schritten() -> void:
	# Arrange
	var lauf := _lauf_nur_ok(37)

	# Act
	var datei := SelbsttestProtokoll.protokoll(lauf)
	var kopie := SelbsttestProtokoll.kopieren(lauf, ORDNER)

	# Assert
	assert_eq(datei.split("\n")[1], "ergebnis: Alles in Ordnung: 37 von 37 Schritten.")
	assert_eq(datei.count("\nschritt: "), 37)
	assert_eq(kopie.count("\nschritt: "), 0, "„Kopieren“ lässt Schritte mit OK weg.")
	assert_true(kopie.contains("# Schritte\n\n# Summe\n"), "Die Überschrift bleibt.")
	assert_true(kopie.contains("summe.ok: 37\nsumme.fehler: 0\nsumme.nicht_gelaufen: 0\n"
		+ "summe.gesamt: 37\n"))


func test_summe_in_allen_formen() -> void:
	# Act und Assert: Der erste Teil steht immer, Fehler und nicht gelaufen entfallen bei 0 (CHK033).
	assert_eq(SelbsttestTexte.summe(37, 0, 0), "Alles in Ordnung: 37 von 37 Schritten.")
	assert_eq(SelbsttestTexte.summe(1, 0, 0), "Alles in Ordnung: 1 von 1 Schritt.")
	assert_eq(SelbsttestTexte.summe(35, 1, 1),
		"35 von 37 Schritten in Ordnung, 1 Fehler, 1 nicht gelaufen.")
	assert_eq(SelbsttestTexte.summe(0, 1, 0), "0 von 1 Schritt in Ordnung, 1 Fehler.")
	assert_eq(SelbsttestTexte.summe(1, 2, 0), "1 von 3 Schritten in Ordnung, 2 Fehler.")
	assert_eq(SelbsttestTexte.summe(1, 0, 1), "1 von 2 Schritten in Ordnung, 1 nicht gelaufen.")
	assert_eq(SelbsttestTexte.summe(0, 0, 40), "0 von 40 Schritten in Ordnung, 40 nicht gelaufen.")


# --- Feste Schlüssel -----------------------------------------------------------------------------

func test_jeder_schluessel_der_systemdaten_steht_im_protokoll() -> void:
	# Arrange: ein Lauf ganz ohne Systemdaten
	var lauf := SelbsttestLauf.new(START)

	# Act
	var text := SelbsttestProtokoll.protokoll(lauf)

	# Assert: Ein Schlüssel fehlt nie; was fehlt, heißt „unbekannt“.
	for schluessel: String in TABELLE:
		assert_true(text.contains("\n%s: " % schluessel), schluessel)
	assert_true(text.contains("\nsystem.gpu: unbekannt\n"))
	assert_true(text.contains("\nselbsttest.version: unbekannt\n"))
	assert_true(text.contains("\nlauf.feste_zeit: unbekannt\n"))
	assert_true(text.contains("\nlauf.dauer_ms: unbekannt\n"))


func test_schluessel_in_fester_reihenfolge() -> void:
	# Act
	var schluessel := _schluessel(SelbsttestProtokoll.protokoll(SelbsttestLauf.new(START)))

	# Assert: wie im Vertrag, auch ohne Schritte
	assert_eq(schluessel, ["ergebnis", "lauf.start", "lauf.dauer_ms", "lauf.feste_zeit",
		"lauf.zeitraffer", "lauf.abbruch", "selbsttest.version", "selbsttest.gebaut",
		"computerladen.version", "godot.version", "system.os", "system.os_version", "system.cpu",
		"system.gpu", "system.gpu_vendor", "system.gpu_driver", "system.renderer",
		"system.grafik_api", "system.grafik_api_version", "system.bildschirm",
		"system.bildschirm_skalierung", "system.bildschirm_dpi", "system.bildwiederholrate",
		"system.fenster", "system.fenster_faktor", "system.sprache", "system.tastatur",
		"fokus.verluste", "summe.ok", "summe.fehler", "summe.nicht_gelaufen", "summe.gesamt"])


func test_jede_zeile_ist_leer_ueberschrift_oder_angabe() -> void:
	# Arrange
	var lauf := _erfundener_lauf()

	for text: String in [SelbsttestProtokoll.protokoll(lauf),
			SelbsttestProtokoll.kopieren(lauf, ORDNER),
			SelbsttestProtokoll.kopieren_nicht_beschreibbar(lauf, NICHT_BESCHREIBBAR)]:
		var zeilen := text.trim_suffix("\n").split("\n")
		for zeile in zeilen:
			# Assert: Schlüssel klein, ASCII, mit Punkten gegliedert; Wert nie leer
			if zeile.is_empty() or zeile.begins_with("# "):
				continue
			var trenner := zeile.find(": ")
			assert_gt(trenner, 0, zeile)
			var schluessel := zeile.substr(0, trenner)
			assert_true(_ist_schluessel(schluessel), "Schlüssel: " + zeile)
			assert_false(zeile.substr(trenner + 2).is_empty(), "Wert: " + zeile)


func test_werte_ohne_schlusspunkt_ausser_ergebnis() -> void:
	# Arrange
	var lauf := _erfundener_lauf()

	for text: String in [SelbsttestProtokoll.protokoll(lauf),
			SelbsttestProtokoll.kopieren_nicht_beschreibbar(lauf, NICHT_BESCHREIBBAR)]:
		for zeile in text.split("\n"):
			# Assert (CHK034)
			if zeile.begins_with("ergebnis: "):
				assert_true(zeile.ends_with("."), zeile)
			elif not zeile.is_empty():
				assert_false(zeile.ends_with("."), zeile)


# --- Einzelne Werte ------------------------------------------------------------------------------

func test_maschinenform_der_werte() -> void:
	# Act und Assert (CHK039)
	assert_eq(SelbsttestProtokoll.wert(Vector2i(3024, 1964)), "3024x1964")
	assert_eq(SelbsttestProtokoll.wert(2.0), "2.0")
	assert_eq(SelbsttestProtokoll.wert(1.25), "1.25")
	assert_eq(SelbsttestProtokoll.wert(59.94000244140625), "59.94")
	assert_eq(SelbsttestProtokoll.wert(120), "120")
	assert_eq(SelbsttestProtokoll.wert("de_DE"), "de_DE")
	assert_eq(SelbsttestProtokoll.zeit_text(START), "2026-10-28 14:03:12")
	assert_eq(SelbsttestProtokoll.zeit_text(START, false), "2026-10-28 14:03")


func test_fehlender_wert_heisst_unbekannt() -> void:
	# Act und Assert
	assert_eq(SelbsttestProtokoll.wert(null), "unbekannt")
	assert_eq(SelbsttestProtokoll.wert(""), "unbekannt")


func test_zeilenumbruch_im_wert_wird_zeichen() -> void:
	# Act und Assert
	assert_eq(SelbsttestProtokoll.wert("eins\nzwei"), "eins⏎zwei")
	assert_eq(SelbsttestProtokoll.wert("eins\r\nzwei\rdrei"), "eins⏎zwei⏎drei")


func test_feste_zeit_mit_versatz() -> void:
	# Act und Assert
	assert_eq(SelbsttestProtokoll.feste_zeit_text(FESTE_ZEIT, 60), "2026-10-26 21:40 UTC+01:00")
	assert_eq(SelbsttestProtokoll.feste_zeit_text(FESTE_ZEIT, 0), "2026-10-26 20:40 UTC+00:00")
	assert_eq(SelbsttestProtokoll.feste_zeit_text(FESTE_ZEIT, -330), "2026-10-26 15:10 UTC-05:30")


func test_foto_nicht_vergleichbar_und_abbruch() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	var ablauf := SelbsttestAblauf.new()
	ablauf.kennung = "easter_egg"
	var nichts := func() -> void: pass
	var passt := func() -> String: return ""
	lauf.plane(ablauf, [ablauf.neuer_schritt("03_start", "Gehäusetasten links, Mitte, rechts", "",
		nichts, passt, "Seite Invaders sichtbar und aktiv, Hinweis aus", false),
		ablauf.neuer_schritt("04_spielen", "Pfeil rechts halten 0,5 s, Leertaste", "", nichts, passt,
		"x", false)] as Array[Dictionary])
	lauf.melde_ok("easter_egg.03_start", 210)

	# Act
	lauf.brich_ab("easter_egg.04_spielen")
	var text := SelbsttestProtokoll.protokoll(lauf)

	# Assert
	assert_true(text.contains("\nfoto: easter_egg.03_start.png\nfoto_vergleichbar: nein\n"))
	assert_true(text.contains("\nlauf.abbruch: easter_egg.04_spielen\n"))
	assert_true(text.contains("\nschritt: easter_egg.04_spielen\nablauf: easter_egg\n"
		+ "status: NICHT_GELAUFEN\ngefunden: Fenster geschlossen\n"))
	assert_true(text.contains("\neingaben: unbekannt\n"), "Ohne Eingaben in Worten: unbekannt.")


# --- Wortlaute -----------------------------------------------------------------------------------

func test_wortlaute_aus_dem_vertrag() -> void:
	# Act und Assert (contracts/selbsttest-app.md, „Texte“)
	assert_eq(SelbsttestTexte.KOPF, "# Der Computerladen Selbsttest")
	assert_eq(SelbsttestTexte.fenstertitel(12, 40, "Neues Spiel"),
		"Selbsttest · Schritt 12 von 40: Neues Spiel")
	assert_eq(SelbsttestTexte.FENSTERTITEL_DANACH, "Der Computerladen Selbsttest")
	assert_eq(SelbsttestTexte.ueberschrift(START), "Selbsttest vom 28.10.2026, 14:03 Uhr")
	assert_eq(SelbsttestTexte.systemzeile({"system.os": "macOS", "system.os_version": "26.0.0",
		"system.gpu": "Apple M3 Pro", "system.grafik_api": "Metal"}),
		"macOS 26.0.0 · Apple M3 Pro · Metal")
	assert_eq(SelbsttestTexte.systemzeile({}), "unbekannt unbekannt · unbekannt · unbekannt")
	assert_eq(SelbsttestTexte.BEREICHSTITEL, "Was nicht stimmt")
	assert_eq(SelbsttestTexte.eintrag("laden.03_liste", "Spiel laden"),
		"laden.03_liste · Spiel laden")
	assert_eq(SelbsttestTexte.erwartet("Menü steht: SPIELSTÄNDE, Spiel 1"),
		"Erwartet: Menü steht: SPIELSTÄNDE, Spiel 1")
	assert_eq(SelbsttestTexte.gefunden("Menü steht: HAUPTMENÜ"), "Gefunden: Menü steht: HAUPTMENÜ")
	assert_eq(SelbsttestTexte.nicht_gelaufen("Fenster geschlossen"),
		"Nicht gelaufen: Fenster geschlossen")
	assert_eq(SelbsttestTexte.pfad("/tmp/x"), "Protokoll und Fotos liegen hier: /tmp/x")
	assert_eq([SelbsttestTexte.KNOPF_KOPIEREN, SelbsttestTexte.KNOPF_ORDNER_ZEIGEN,
		SelbsttestTexte.KNOPF_BEENDEN], ["Kopieren", "Ordner zeigen", "Beenden"])
	assert_eq([SelbsttestTexte.TOOLTIP_KOPIEREN, SelbsttestTexte.TOOLTIP_ORDNER_ZEIGEN,
		SelbsttestTexte.TOOLTIP_BEENDEN], ["Legt das Ergebnis als Text in die Zwischenablage.",
		"Zeigt das Zip dieses Laufs im Dateimanager.", "Beendet den Selbsttest."])
	assert_eq(SelbsttestTexte.BESTAETIGUNG, "Kopiert.")
	assert_eq(SelbsttestTexte.BESTAETIGUNG_LINUX, "Kopiert. Erst einfügen, dann beenden.")
	assert_eq(SelbsttestTexte.kein_protokoll("/x"), "Kein Protokoll: In /x lässt sich nicht schreiben.")


func test_wortlaute_fuer_gefunden_und_gruende() -> void:
	# Act und Assert (CHK034)
	assert_eq(SelbsttestTexte.zeit_abgelaufen("Menü steht: SCHWIERIGKEIT, Leicht"),
		"Zeit abgelaufen, zuletzt: Menü steht: SCHWIERIGKEIT, Leicht")
	assert_eq(SelbsttestTexte.ziel_nicht_gefunden("HAUPTMENÜ, „Neues Spiel“"),
		"Ziel nicht gefunden: HAUPTMENÜ, „Neues Spiel“")
	assert_eq(SelbsttestTexte.spielstaende_anzahl(1), "1 Spielstand", "Zahlwort nach der Zahl (N5).")
	assert_eq(SelbsttestTexte.spielstaende_anzahl(7), "7 Spielstände")
	assert_eq(SelbsttestTexte.fehler_in_schritt("titel.01_start"), "Fehler in Schritt titel.01_start")
	assert_eq(SelbsttestTexte.fehler_in_ablauf("neues_spiel"), "Fehler in Ablauf neues_spiel")
	assert_eq(SelbsttestTexte.FENSTER_GESCHLOSSEN, "Fenster geschlossen")
	assert_eq(SelbsttestTexte.UHR_NICHT_BEDIENBAR,
		"Die Uhr lässt sich im Spielbildschirm noch nicht bedienen")


func test_namen_der_ablaeufe() -> void:
	# Act und Assert (data-model.md, „Ablauf“; CHK037)
	var namen: Array[String] = []
	for kennung: String in ["titel", "neues_spiel", "laden", "loeschen", "easter_egg", "bedienung",
			"fenster", "titel_echtzeit"]:
		namen.append(SelbsttestTexte.ablauf_name(kennung))
	assert_eq(namen, ["Titel", "Neues Spiel", "Spiel laden", "Löschen", "Easter Egg", "Bedienung",
		"Fenster", "Titel in Echtzeit"] as Array[String])
	assert_eq(SelbsttestTexte.ablauf_name("szenario_x"), "szenario_x")


# --- Hilfen --------------------------------------------------------------------------------------

## Der erfundene Lauf der Erwartungen: titel.01_start OK, neues_spiel.01_gradwahl FEHLER mit zwei
## Meldungen, eine davon über zwei Zeilen, neues_spiel.02_zurueck_esc dadurch NICHT_GELAUFEN; ein
## Fokusverlust; system.gpu_driver fehlt ganz. Mit [param mit_schritten] false ohne Abläufe.
func _erfundener_lauf(mit_schritten: bool = true) -> SelbsttestLauf:
	var lauf := SelbsttestLauf.new(START)
	lauf.version = 1
	lauf.zeitraffer = 8
	lauf.feste_zeit = FESTE_ZEIT
	lauf.feste_zeitzone = 60
	lauf.dauer_ms = 84213
	lauf.system = {
		"system.os": "macOS",
		"system.os_version": "26.0.0",
		"system.cpu": "Apple M3 Pro",
		"system.gpu": "Apple M3 Pro",
		"system.gpu_vendor": "Apple",
		"system.renderer": "forward_plus",
		"system.grafik_api": "Metal",
		"system.grafik_api_version": "4.0",
		"system.bildschirm": Vector2i(3024, 1964),
		"system.bildschirm_skalierung": 2.0,
		"system.bildschirm_dpi": 254,
		"system.bildwiederholrate": 120,
		"system.fenster": Vector2i(1920, 1080),
		"system.fenster_faktor": 3,
		"system.sprache": "de_DE",
		"system.tastatur": "German",
		"computerladen.version": "0.1",
		"godot.version": "4.7.2.stable.official",
		"selbsttest.gebaut": "2026-10-28 13:58",
	}
	if not mit_schritten:
		return lauf

	var nichts := func() -> void: pass
	var passt := func() -> String: return ""
	var titel := SelbsttestAblauf.new()
	titel.kennung = "titel"
	lauf.plane(titel, [titel.neuer_schritt("01_start", "Start, der Communicator fährt herein",
		"keine", nichts, passt, "Menü steht: HAUPTMENÜ, „Neues Spiel“; Spielstände: keine")]
		as Array[Dictionary])
	var neues_spiel := SelbsttestAblauf.new()
	neues_spiel.kennung = "neues_spiel"
	lauf.plane(neues_spiel, [
		neues_spiel.neuer_schritt("01_gradwahl", "Enter auf „Neues Spiel“ öffnet die Gradwahl",
			"Maus über „Neues Spiel“, Enter", nichts, passt,
			"Menü steht: SCHWIERIGKEIT, Mittel"),
		neues_spiel.neuer_schritt("02_zurueck_esc", "Esc", "Esc", nichts, passt,
			"Menü steht: HAUPTMENÜ, „Neues Spiel“"),
	] as Array[Dictionary])

	lauf.melde_ok("titel.01_start", 1712)
	lauf.vermerke_fokusverlust("neues_spiel.01_gradwahl", 2210)
	lauf.melde_fehler("neues_spiel.01_gradwahl",
		"Zeit abgelaufen, zuletzt: Menü steht: SCHWIERIGKEIT, Leicht", 5003, PackedStringArray([
			"WARNING: Seite fehlt · at: _ready (res://scenes/title/title_screen.gd:42)",
			"[selbsttest] Foto ging nicht\nzweiter Versuch auch nicht",
		]))
	return lauf


## Ein Lauf mit [param anzahl] Schritten, alle in Ordnung.
func _lauf_nur_ok(anzahl: int) -> SelbsttestLauf:
	var lauf := SelbsttestLauf.new(START)
	var ablauf := SelbsttestAblauf.new()
	ablauf.kennung = "titel"
	var schritte: Array[Dictionary] = []
	var nichts := func() -> void: pass
	var passt := func() -> String: return ""
	for i in anzahl:
		schritte.append(ablauf.neuer_schritt("%02d_schritt" % (i + 1), "Schritt", "keine", nichts,
			passt, "Menü steht: HAUPTMENÜ"))
	lauf.plane(ablauf, schritte)
	for schritt in lauf.schritte:
		lauf.melde_ok(schritt.kennung, 100)
	return lauf


## Vergleicht [param text] als UTF-8 Byte für Byte mit der Erwartung [param datei]. Steht es nicht
## gleich, nennt die Meldung die erste abweichende Zeile.
func _vergleiche(text: String, datei: String) -> void:
	var erwartet := FileAccess.get_file_as_bytes(FIXTURES + datei)
	var ist := text.to_utf8_buffer()
	if ist == erwartet:
		assert_eq(ist, erwartet, datei)
		return
	var zeilen_ist := text.split("\n")
	var zeilen_erwartet := erwartet.get_string_from_utf8().split("\n")
	for i in maxi(zeilen_ist.size(), zeilen_erwartet.size()):
		var a: String = zeilen_ist[i] if i < zeilen_ist.size() else "<fehlt>"
		var b: String = zeilen_erwartet[i] if i < zeilen_erwartet.size() else "<fehlt>"
		if a != b:
			fail_test("%s, Zeile %d: ist „%s“, erwartet „%s“" % [datei, i + 1, a, b])
			return
	fail_test("%s: gleiche Zeilen, aber andere Bytes" % datei)


## Die Schlüssel aller Angaben in ihrer Reihenfolge.
func _schluessel(text: String) -> Array[String]:
	var liste: Array[String] = []
	for zeile in text.split("\n"):
		var trenner := zeile.find(": ")
		if trenner > 0 and not zeile.begins_with("#"):
			liste.append(zeile.substr(0, trenner))
	return liste


## Klein, ASCII, Wörter mit „_“, gegliedert mit „.“.
func _ist_schluessel(schluessel: String) -> bool:
	var muster := RegEx.create_from_string("^[a-z0-9_]+(\\.[a-z0-9_]+)*$")
	return muster.search(schluessel) != null
