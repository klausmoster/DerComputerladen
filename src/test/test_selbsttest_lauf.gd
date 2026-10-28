extends GutTest

## Prüft SelbsttestLauf und die Basisklasse SelbsttestAblauf (Feature 007, T001; data-model.md,
## „Lauf“, „Ablauf“ und „Schritt“; FR-009, FR-010; CHK006, CHK038): Kennung des Laufs, Planen,
## Ergebnisse je Schritt, Summe, Fokusverluste und Abbruch, und die Regeln für nicht gelaufene
## Schritte. Dazu der Rahmen für Szenarien mit einem erfundenen Szenario (T022, R27). Alles ohne
## Fenster, mit erfundenen Abläufen; die Callables der Schritte tun nichts.
##
## Die Gründe stehen hier als ganze Texte, nicht als Aufrufe von SelbsttestTexte: So fällt jede
## Änderung an einem Wortlaut hier auf.

## 28.10.2026, 14:03:12, Ortszeit
const START := {"year": 2026, "month": 10, "day": 28, "hour": 14, "minute": 3, "second": 12}


# --- Lauf ----------------------------------------------------------------------------------------

func test_kennung_aus_datum_und_uhrzeit() -> void:
	# Act
	var lauf := SelbsttestLauf.new(START)

	# Assert
	assert_eq(lauf.id, "2026-10-28_14-03-12")


func test_ohne_start_gilt_jetzt() -> void:
	# Act
	var lauf := SelbsttestLauf.new()

	# Assert: JJJJ-MM-TT_hh-mm-ss
	assert_eq(lauf.id.length(), 19)
	assert_eq(lauf.id[10], "_")
	assert_eq(lauf.id.substr(0, 4), str(Time.get_datetime_dict_from_system()["year"]))


func test_vorgaben_des_laufs() -> void:
	# Act
	var lauf := SelbsttestLauf.new(START)

	# Assert
	assert_eq(lauf.abbruch, "keiner", "CHK038")
	assert_eq(lauf.zeitraffer, 8, "R24")
	assert_eq(lauf.fokusverluste.size(), 0)
	assert_eq(lauf.gesamt(), 0)


func test_planen_haelt_reihenfolge_und_zahl() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)

	# Act
	_plane(lauf, "titel", ["01_start", "02_nicht_verfuegbar", "03_beenden_da"])
	_plane(lauf, "neues_spiel", ["01_gradwahl", "02_zurueck_esc"])

	# Assert
	assert_eq(lauf.gesamt(), 5)
	assert_eq(lauf.nummer("titel.01_start"), 1)
	assert_eq(lauf.nummer("neues_spiel.02_zurueck_esc"), 5)
	assert_eq(lauf.nummer("gibt_es_nicht"), 0)
	for schritt in lauf.schritte:
		assert_eq(schritt.status, SelbsttestLauf.Status.OFFEN, schritt.kennung)
	assert_eq(lauf.schritt("titel.02_nicht_verfuegbar").ablauf, "titel")
	assert_eq(lauf.schritte_von("neues_spiel").size(), 2)
	assert_null(lauf.schritt("gibt_es_nicht"))


func test_planen_uebernimmt_die_angaben_des_schritts() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	var ablauf := _ablauf("easter_egg")
	var schritte: Array[Dictionary] = [ablauf.neuer_schritt("03_start",
		"Gehäusetasten links, Mitte, rechts", "Linksklick auf Gehäusetasten links, Mitte, rechts",
		_nichts, _passt,
		"Seite Invaders sichtbar und aktiv, Hinweis aus", false, 7000)]

	# Act
	lauf.plane(ablauf, schritte)

	# Assert
	var schritt := lauf.schritt("easter_egg.03_start")
	assert_eq(schritt.beschreibung, "Gehäusetasten links, Mitte, rechts")
	assert_eq(schritt.eingaben, "Linksklick auf Gehäusetasten links, Mitte, rechts")
	assert_eq(schritt.erwartet, "Seite Invaders sichtbar und aktiv, Hinweis aus")
	assert_false(schritt.foto_vergleichbar)
	assert_eq(schritt.hoechstzeit_ms, 7000)
	assert_eq(schritt.foto(), "easter_egg.03_start.png")


func test_zeitraffer_kommt_aus_dem_ablauf() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	var echtzeit := _ablauf("titel_echtzeit")
	echtzeit.zeitraffer = 1

	# Act
	_plane(lauf, "titel", ["01_start"])
	lauf.plane(echtzeit, [echtzeit.neuer_schritt("01_start", "", "keine", _nichts, _passt, "")])

	# Assert
	assert_eq(lauf.schritt("titel.01_start").zeitraffer, 8)
	assert_eq(lauf.schritt("titel_echtzeit.01_start").zeitraffer, 1)


# --- Ergebnisse ----------------------------------------------------------------------------------

func test_ok_mit_dauer_und_meldungen() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	_plane(lauf, "titel", ["01_start"])

	# Act
	lauf.melde_ok("titel.01_start", 1712, PackedStringArray(["WARNING: etwas"]))

	# Assert
	var schritt := lauf.schritt("titel.01_start")
	assert_eq(schritt.status, SelbsttestLauf.Status.OK)
	assert_eq(schritt.dauer_ms, 1712)
	assert_eq(schritt.meldungen, PackedStringArray(["WARNING: etwas"]))
	assert_eq(schritt.gefunden, "")
	assert_true(schritt.gelaufen())


func test_fehler_setzt_den_rest_des_ablaufs_auf_nicht_gelaufen() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	_plane(lauf, "neues_spiel", ["01_gradwahl", "02_zurueck_esc", "03_gradwahl_klick"])
	_plane(lauf, "easter_egg", ["01_auswahl"])
	lauf.melde_ok("neues_spiel.01_gradwahl", 900)

	# Act
	lauf.melde_fehler("neues_spiel.02_zurueck_esc",
		"Ziel nicht gefunden: HAUPTMENÜ, „Neues Spiel“", 12)

	# Assert
	var fehler := lauf.schritt("neues_spiel.02_zurueck_esc")
	assert_eq(fehler.status, SelbsttestLauf.Status.FEHLER)
	assert_eq(fehler.gefunden, "Ziel nicht gefunden: HAUPTMENÜ, „Neues Spiel“")
	assert_true(fehler.gelaufen(), "Auch bei FEHLER gibt es ein Foto.")
	var rest := lauf.schritt("neues_spiel.03_gradwahl_klick")
	assert_eq(rest.status, SelbsttestLauf.Status.NICHT_GELAUFEN)
	assert_eq(rest.gefunden, "Fehler in Schritt neues_spiel.02_zurueck_esc")
	assert_false(rest.gelaufen())
	assert_eq(lauf.schritt("neues_spiel.01_gradwahl").status, SelbsttestLauf.Status.OK,
		"Was schon lief, bleibt.")
	assert_true(lauf.ist_offen("easter_egg.01_auswahl"), "Ein anderer Ablauf läuft weiter.")
	assert_false(lauf.ablauf_offen("neues_spiel"))
	assert_true(lauf.ablauf_gescheitert("neues_spiel"))


func test_ablauf_auf_gescheitertem_gilt_ganz_als_nicht_gelaufen() -> void:
	# Arrange: wie in contracts/ablaeufe.md
	var lauf := SelbsttestLauf.new(START)
	_plane(lauf, "neues_spiel", ["01_gradwahl", "02_zurueck_esc"])
	_plane(lauf, "laden", ["01_weiterspielen", "02_zurueck"], "neues_spiel")
	_plane(lauf, "loeschen", ["01_liste"], "laden")
	_plane(lauf, "easter_egg", ["01_auswahl"])

	# Act
	lauf.melde_fehler("neues_spiel.01_gradwahl", "Zeit abgelaufen, zuletzt: Menü steht: "
		+ "SCHWIERIGKEIT, Leicht", 5003)

	# Assert: Grund ist der Ablauf mit dem Fehler, auch über zwei Stufen (FR-009, CHK006).
	for kennung: String in ["laden.01_weiterspielen", "laden.02_zurueck", "loeschen.01_liste"]:
		var schritt := lauf.schritt(kennung)
		assert_eq(schritt.status, SelbsttestLauf.Status.NICHT_GELAUFEN, kennung)
		assert_eq(schritt.gefunden, "Fehler in Ablauf neues_spiel", kennung)
	assert_false(lauf.ablauf_offen("laden"), "Der Läufer überspringt ihn.")
	assert_false(lauf.ablauf_offen("loeschen"))
	assert_true(lauf.ablauf_offen("easter_egg"), "Ohne baut_auf beginnt er beim frischen Titel.")


func test_auch_spaeter_eingeplant_gilt_er_als_nicht_gelaufen() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	_plane(lauf, "neues_spiel", ["01_gradwahl"])
	lauf.melde_fehler("neues_spiel.01_gradwahl", "Menü steht: HAUPTMENÜ", 300)

	# Act
	_plane(lauf, "laden", ["01_weiterspielen"], "neues_spiel")

	# Assert
	assert_eq(lauf.schritt("laden.01_weiterspielen").gefunden, "Fehler in Ablauf neues_spiel")


func test_ablauf_auf_gelungenem_laeuft() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	_plane(lauf, "neues_spiel", ["01_gradwahl"])
	_plane(lauf, "laden", ["01_weiterspielen", "02_zurueck"], "neues_spiel")

	# Act
	lauf.melde_ok("neues_spiel.01_gradwahl", 800)
	lauf.melde_fehler("laden.01_weiterspielen", "Menü steht: HAUPTMENÜ", 5001)

	# Assert: Der Fehler in „laden“ nennt den eigenen Schritt, nicht den Ablauf.
	assert_eq(lauf.schritt("laden.02_zurueck").gefunden, "Fehler in Schritt laden.01_weiterspielen")
	assert_false(lauf.ablauf_gescheitert("neues_spiel"))


func test_baut_auf_im_kreis_haengt_nicht() -> void:
	# Arrange: ein Fehler beim Schreiben eines Ablaufs, kein echter Fall
	var lauf := SelbsttestLauf.new(START)
	_plane(lauf, "a", ["01_x"], "b")
	_plane(lauf, "b", ["01_x"], "a")

	# Act und Assert: kommt zurück, beide bleiben offen
	assert_true(lauf.ist_offen("a.01_x"))
	assert_true(lauf.ist_offen("b.01_x"))


func test_nur_offene_schritte_aendern_sich() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	_plane(lauf, "titel", ["01_start", "02_nicht_verfuegbar"])
	lauf.melde_fehler("titel.01_start", "Menü steht: SPIELSTÄNDE", 10)

	# Act
	lauf.melde_ok("titel.01_start", 20)
	lauf.melde_ok("titel.02_nicht_verfuegbar", 30)
	lauf.melde_fehler("gibt_es_nicht", "x", 1)

	# Assert
	assert_eq(lauf.schritt("titel.01_start").status, SelbsttestLauf.Status.FEHLER)
	assert_eq(lauf.schritt("titel.01_start").dauer_ms, 10)
	assert_eq(lauf.schritt("titel.02_nicht_verfuegbar").status,
		SelbsttestLauf.Status.NICHT_GELAUFEN)


# --- Abbruch und Fokus ---------------------------------------------------------------------------

func test_abbruch_vermerkt_den_schritt_und_setzt_den_rest_auf_nicht_gelaufen() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	_plane(lauf, "titel", ["01_start", "02_nicht_verfuegbar"])
	_plane(lauf, "neues_spiel", ["01_gradwahl"])
	lauf.melde_ok("titel.01_start", 1700)

	# Act: Fenster geschlossen während titel.02
	lauf.brich_ab("titel.02_nicht_verfuegbar")

	# Assert (FR-010)
	assert_eq(lauf.abbruch, "titel.02_nicht_verfuegbar")
	assert_eq(lauf.schritt("titel.01_start").status, SelbsttestLauf.Status.OK)
	for kennung: String in ["titel.02_nicht_verfuegbar", "neues_spiel.01_gradwahl"]:
		assert_eq(lauf.schritt(kennung).status, SelbsttestLauf.Status.NICHT_GELAUFEN, kennung)
		assert_eq(lauf.schritt(kennung).gefunden, "Fenster geschlossen", kennung)


func test_fokusverluste_mit_schritt_und_zeit() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)

	# Act
	lauf.vermerke_fokusverlust("titel.01_start", 412)
	lauf.vermerke_fokusverlust("laden.03_liste", 20044)

	# Assert
	assert_eq(lauf.fokusverluste, [{"kennung": "titel.01_start", "ms": 412},
		{"kennung": "laden.03_liste", "ms": 20044}] as Array[Dictionary])


# --- Summe ---------------------------------------------------------------------------------------

func test_summe_zaehlt_je_ergebnis() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	_plane(lauf, "titel", ["01_start", "02_nicht_verfuegbar", "03_beenden_da"])
	_plane(lauf, "neues_spiel", ["01_gradwahl", "02_zurueck_esc"])

	# Act
	lauf.melde_ok("titel.01_start", 1)
	lauf.melde_ok("titel.02_nicht_verfuegbar", 1)
	lauf.melde_ok("titel.03_beenden_da", 1)
	lauf.melde_fehler("neues_spiel.01_gradwahl", "x", 1)

	# Assert
	assert_eq(lauf.summe(), {"ok": 3, "fehler": 1, "nicht_gelaufen": 1, "gesamt": 5})
	assert_eq(lauf.summe_text(), "3 von 5 Schritten in Ordnung, 1 Fehler, 1 nicht gelaufen.")
	assert_false(lauf.alles_in_ordnung())
	var kennungen: Array[String] = []
	for schritt in lauf.nicht_in_ordnung():
		kennungen.append(schritt.kennung)
	assert_eq(kennungen, ["neues_spiel.01_gradwahl", "neues_spiel.02_zurueck_esc"] as Array[String])


func test_offener_schritt_zaehlt_als_nicht_gelaufen() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	_plane(lauf, "titel", ["01_start", "02_nicht_verfuegbar"])

	# Act
	lauf.melde_ok("titel.01_start", 1)

	# Assert: Im Protokoll gibt es OFFEN nicht.
	assert_eq(lauf.summe(), {"ok": 1, "fehler": 0, "nicht_gelaufen": 1, "gesamt": 2})
	assert_eq(SelbsttestLauf.STATUS_TEXT[SelbsttestLauf.Status.OFFEN], "NICHT_GELAUFEN")


func test_alles_in_ordnung() -> void:
	# Arrange
	var lauf := SelbsttestLauf.new(START)
	_plane(lauf, "titel", ["01_start", "02_nicht_verfuegbar"])

	# Act
	lauf.melde_ok("titel.01_start", 1)
	lauf.melde_ok("titel.02_nicht_verfuegbar", 1)

	# Assert
	assert_true(lauf.alles_in_ordnung())
	assert_eq(lauf.summe_text(), "Alles in Ordnung: 2 von 2 Schritten.")
	assert_eq(lauf.nicht_in_ordnung().size(), 0)


# --- Ablauf --------------------------------------------------------------------------------------

func test_basisklasse_hat_keine_schritte_und_die_vorgaben() -> void:
	# Act
	var ablauf := SelbsttestAblauf.new()

	# Assert
	assert_eq(ablauf.schritte(null).size(), 0)
	assert_eq(ablauf.baut_auf, "")
	assert_eq(ablauf.zeitraffer, 8)
	assert_eq(SelbsttestAblauf.HOECHSTZEIT_MS, 5000, "R6")


func test_neuer_schritt_hat_die_schluessel_aus_dem_vertrag() -> void:
	# Arrange
	var ablauf := _ablauf("neues_spiel")

	# Act
	var schritt := ablauf.neuer_schritt("04_grad_mittel", "Enter", "Enter", _nichts, _passt,
		"Communicator hinausgefahren; Spielbildschirm steht; Spielstände: Spiel 1")

	# Assert
	assert_eq(schritt.keys(), ["kennung", "beschreibung", "eingaben_text", "eingaben", "erwartet",
		"erwartet_text", "hoechstzeit_ms", "foto_vergleichbar"])
	assert_eq(schritt["eingaben_text"], "Enter")
	assert_eq(schritt["kennung"], "neues_spiel.04_grad_mittel")
	assert_eq(schritt["hoechstzeit_ms"], 5000)
	assert_true(schritt["foto_vergleichbar"])
	assert_eq((schritt["erwartet"] as Callable).call(), "", "„“ heißt: Der Zustand stimmt.")


func test_abgeleiteter_ablauf_liefert_seine_schritte() -> void:
	# Arrange
	var ablauf := ErfundenerAblauf.new()

	# Act
	var schritte := ablauf.schritte(null)

	# Assert
	assert_eq(schritte.size(), 2)
	assert_eq(schritte[1]["kennung"], "erfunden.02_zwei")


# --- Szenario (R27) ------------------------------------------------------------------------------

func test_szenario_macht_aus_start_entscheidungen_und_pruefpunkten_schritte_nach_datum() -> void:
	# Arrange
	var szenario := ErfundenesSzenario.new()

	# Act
	var schritte := szenario.schritte(SelbsttestFahrer.new(get_tree()))

	# Assert: erst der Start, dann nach Datum; am selben Tag die Entscheidung vor dem Prüfpunkt.
	assert_true(szenario is SelbsttestAblauf, "Ein Szenario ist ein Ablauf.")
	assert_eq(_feld(schritte, "kennung"), ["leicht_1987.00_start",
		"leicht_1987.01_entscheidung", "leicht_1987.02_lager", "leicht_1987.03_kontostand"])
	assert_eq(_feld(schritte, "beschreibung"), ["Spiel 1 beginnt mit Leicht, Seed 4711",
		"Entscheidung am 01.03.1985", "Prüfpunkt am 01.03.1985", "Prüfpunkt am 01.03.1987"])
	assert_eq(_feld(schritte, "eingaben_text"), ["Vorbereitung: Spiel 1 mit Leicht, Seed 4711",
		"Uhr bis 01.03.1985, Linksklick auf „Bestellen“", "Uhr bis 01.03.1985",
		"Uhr bis 01.03.1987"])
	assert_eq(_feld(schritte, "erwartet_text"), [
		"Spielbildschirm steht, Hinweis „Speichert Spiel 1 und führt ins Hauptmenü.“",
		"keine", "Lager voll", "Kontostand 1000 DM"], "Ohne Erwartung „keine“ (Lücke 5).")


func test_szenario_ohne_bedienung_der_uhr_scheitert_beim_ersten_datum() -> void:
	# Arrange: Der Start gelang; das erste Datum braucht die Uhr.
	var szenario := ErfundenesSzenario.new()
	var schritte := szenario.schritte(SelbsttestFahrer.new(get_tree()))
	var lauf := SelbsttestLauf.new(START)
	lauf.plane(szenario, schritte)
	lauf.melde_ok("leicht_1987.00_start", 300)

	# Act: wie der Läufer, ohne Fenster
	var antwort: Variant = await (schritte[1]["eingaben"] as Callable).call()
	lauf.melde_fehler("leicht_1987.01_entscheidung", antwort, 0)

	# Assert
	assert_eq(antwort, "Die Uhr lässt sich im Spielbildschirm noch nicht bedienen")
	assert_eq(szenario.entschieden, 0, "Ohne Uhr geht die Entscheidung nicht hinaus.")
	assert_eq(lauf.schritt("leicht_1987.03_kontostand").status,
		SelbsttestLauf.Status.NICHT_GELAUFEN)
	assert_eq(lauf.schritt("leicht_1987.03_kontostand").gefunden,
		"Fehler in Schritt leicht_1987.01_entscheidung")
	assert_eq(lauf.summe_text(), "1 von 4 Schritten in Ordnung, 1 Fehler, 2 nicht gelaufen.")


func test_entscheidung_ohne_eingaben_text_nennt_nur_die_uhr() -> void:
	# Arrange
	var szenario := ErfundenesSzenario.new()
	szenario.ohne_text = true

	# Act
	var schritte := szenario.schritte(null)

	# Assert (B17)
	assert_eq(schritte[1]["eingaben_text"], "Uhr bis 01.03.1985")


func test_szenario_ohne_eintraege_hat_nur_den_start() -> void:
	# Arrange
	var szenario := SelbsttestSzenario.new()
	szenario.kennung = "leer"

	# Act
	var schritte := szenario.schritte(null)

	# Assert
	assert_eq(_feld(schritte, "kennung"), ["leer.00_start"])
	assert_eq(szenario.grad, Difficulty.Level.MITTEL)


# --- Hilfen --------------------------------------------------------------------------------------

## Ein Szenario, wie ein späteres Feature es unter szenarien/ anlegt: Leicht, Seed 4711, eine
## Entscheidung und zwei Prüfpunkte, absichtlich nicht nach Datum geordnet.
class ErfundenesSzenario:
	extends SelbsttestSzenario

	var entschieden := 0
	var ohne_text := false

	func _init() -> void:
		kennung = "leicht_1987"
		name = "Leicht bis 1987"
		grad = Difficulty.Level.LEICHT
		seed = 4711

	func entscheidungen(_fahrer: SelbsttestFahrer) -> Array[Dictionary]:
		var entscheidung := {"datum": GameDate.new(1985, 3, 1), "eingaben": _entscheide}
		if not ohne_text:
			entscheidung["eingaben_text"] = "Linksklick auf „Bestellen“"
		return [entscheidung]

	func pruefpunkte(_fahrer: SelbsttestFahrer) -> Array[Dictionary]:
		var passt := func() -> String: return ""
		return [{"kennung": "03_kontostand", "datum": GameDate.new(1987, 3, 1), "erwartet": passt,
			"erwartet_text": "Kontostand 1000 DM"},
			{"kennung": "02_lager", "datum": GameDate.new(1985, 3, 1), "erwartet": passt,
			"erwartet_text": "Lager voll"}]

	func _entscheide() -> String:
		entschieden += 1
		return ""


## Die Werte von [param schluessel] aus allen [param schritte].
static func _feld(schritte: Array[Dictionary], schluessel: String) -> Array:
	var werte := []
	for schritt in schritte:
		werte.append(schritt[schluessel])
	return werte


## Ein Ablauf wie die echten ab Phase 2: erbt und überschreibt schritte().
class ErfundenerAblauf:
	extends SelbsttestAblauf

	func _init() -> void:
		kennung = "erfunden"
		name = "Erfunden"

	func schritte(_fahrer: SelbsttestFahrer) -> Array[Dictionary]:
		var nichts := func() -> void: pass
		var passt := func() -> String: return ""
		return [neuer_schritt("01_eins", "eins", "keine", nichts, passt, "eins"),
			neuer_schritt("02_zwei", "zwei", "keine", nichts, passt, "zwei")]


func _ablauf(kennung: String, baut_auf: String = "") -> SelbsttestAblauf:
	var ablauf := SelbsttestAblauf.new()
	ablauf.kennung = kennung
	ablauf.name = SelbsttestTexte.ablauf_name(kennung)
	ablauf.baut_auf = baut_auf
	return ablauf


func _plane(lauf: SelbsttestLauf, kennung: String, kurz: Array, baut_auf: String = "") -> void:
	var ablauf := _ablauf(kennung, baut_auf)
	var schritte: Array[Dictionary] = []
	for nn_kurz: String in kurz:
		schritte.append(ablauf.neuer_schritt(nn_kurz, "Beschreibung %s" % nn_kurz, "keine", _nichts,
			_passt, "Erwartet %s" % nn_kurz))
	lauf.plane(ablauf, schritte)


func _nichts() -> void:
	pass


func _passt() -> String:
	return ""
