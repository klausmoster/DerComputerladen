extends GutTest

## Prüft die Abläufe „neues_spiel“, „laden“, „loeschen“, „easter_egg“, „bedienung“, „liste“ und
## „fenster“ (Feature 007, T019, T021, T058; contracts/ablaeufe.md): Kennungen, baut_auf, Beschreibungen, Eingaben
## und Erwartungen laut Vertrag, ausgeschrieben, damit jede Änderung hier auffällt; dazu Durchläufe
## im echten Titel und Spielbildschirm, ohne Fenster. „fenster“ braucht ein Fenster; hier stehen nur
## seine Wortlaute, laufen lässt ihn die App.
##
## Aufbau wie in test_selbsttest_fahrer.gd: eigene Uhr, Zeitleiste und GameSession mit dem Ordner
## ORDNER, Bildschirme in einem eigenen Viewport von 640 × 360, Eingaben über SelbsttestEingabe an
## push_input() dieses Viewports. Den Wechsel zwischen Titel und Spielbildschirm macht der Test über
## scene_callback selbst; der Communicator fährt ohne Animation. Nach user://spielstaende/ schreibt
## kein Test; after_each() räumt WURZEL ab.

const TITEL := preload("res://scenes/title/title_screen.tscn")
const ABLAUF_NEUES_SPIEL := preload("res://tools/selbsttest/ablaeufe/ablauf_neues_spiel.gd")
const ABLAUF_LADEN := preload("res://tools/selbsttest/ablaeufe/ablauf_laden.gd")
const ABLAUF_LOESCHEN := preload("res://tools/selbsttest/ablaeufe/ablauf_loeschen.gd")
const ABLAUF_EASTER_EGG := preload("res://tools/selbsttest/ablaeufe/ablauf_easter_egg.gd")
const ABLAUF_BEDIENUNG := preload("res://tools/selbsttest/ablaeufe/ablauf_bedienung.gd")
const ABLAUF_FENSTER := preload("res://tools/selbsttest/ablaeufe/ablauf_fenster.gd")
const ABLAUF_LISTE := preload("res://tools/selbsttest/ablaeufe/ablauf_liste.gd")
const SITZUNG := preload("res://core/game_session.gd")
const ZEITLEISTE := preload("res://core/timeline.gd")
const UHR := preload("res://core/game_clock.gd")
const WURZEL := "user://test_selbsttest_ablaeufe/"
const ORDNER := "user://test_selbsttest_ablaeufe/spielstaende/"
const KATALOG := "res://test/fixtures/catalog_us1_grade.json"
## 26.10.2026, 20:40:00 UTC, wie im Selbsttest.
const FESTE_ZEIT := 1793047200
## So lange darf ein Schritt hier auf seinen Zustand warten, in Millisekunden. Ohne Fahrt reicht ein
## Bild; das versteckte Spiel braucht echte Zeit für seinen Schritt von 1/60 s.
const WARTEN_MS := 1000

var _viewport: SubViewport
var _sitzung: SITZUNG
var _eingabe: SelbsttestEingabe
var _fahrer: SelbsttestFahrer
## Der Bildschirm, der gerade im Viewport steht.
var _szene: Node


func before_each() -> void:
	_raeume_auf(WURZEL)
	DirAccess.make_dir_recursive_absolute(ORDNER)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(640, 360)
	add_child_autofree(_viewport)
	_sitzung = _neue_sitzung()
	_eingabe = SelbsttestEingabe.new()
	_eingabe.viewport = _viewport
	_eingabe.senke = func(ereignis: InputEvent) -> void:
		_viewport.push_input(SelbsttestEingabe.fuer_das_spiel(ereignis))
	_fahrer = SelbsttestFahrer.new(get_tree(), _eingabe)
	_fahrer.session = _sitzung
	_fahrer.szenenwechsel = _wechsle
	_szene = null


func after_each() -> void:
	await wait_process_frames(1)
	SaveGame.time_zone_bias = SaveGame.SYSTEM_BIAS
	_raeume_auf(WURZEL)


# --- Wortlaute laut Vertrag -----------------------------------------------------------------------

func test_die_drei_ablaeufe_bauen_aufeinander_auf() -> void:
	# Act
	var neues_spiel := ABLAUF_NEUES_SPIEL.new() as SelbsttestAblauf
	var laden := ABLAUF_LADEN.new() as SelbsttestAblauf
	var loeschen := ABLAUF_LOESCHEN.new() as SelbsttestAblauf

	# Assert
	assert_eq([neues_spiel.kennung, laden.kennung, loeschen.kennung],
		["neues_spiel", "laden", "loeschen"])
	assert_eq([neues_spiel.name, laden.name, loeschen.name], ["Neues Spiel", "Spiel laden",
		"Löschen"])
	assert_eq([neues_spiel.baut_auf, laden.baut_auf, loeschen.baut_auf], ["", "neues_spiel",
		"laden"])
	assert_eq([neues_spiel.zeitraffer, laden.zeitraffer, loeschen.zeitraffer], [8, 8, 8])


func test_neues_spiel_hat_die_schritte_aus_dem_vertrag() -> void:
	# Act
	var schritte := ABLAUF_NEUES_SPIEL.new().schritte(_fahrer)

	# Assert
	assert_eq(_feld(schritte, "kennung"), ["neues_spiel.01_gradwahl",
		"neues_spiel.02_zurueck_esc", "neues_spiel.03_gradwahl_klick", "neues_spiel.04_grad_mittel",
		"neues_spiel.05_zum_hauptmenue"])
	assert_eq(_feld(schritte, "beschreibung"), [
		"Enter auf „Neues Spiel“ öffnet die Gradwahl",
		"Esc führt zurück ins Hauptmenü",
		"Linksklick auf „Neues Spiel“ öffnet die Gradwahl",
		"Enter auf Mittel beginnt ein neues Spiel",
		"Linksklick auf „Zum Hauptmenü“ speichert, der Titel kommt neu"])
	assert_eq(_feld(schritte, "eingaben_text"), ["Maus über „Neues Spiel“, Enter", "Esc",
		"Linksklick auf „Neues Spiel“", "Enter auf Mittel", "Linksklick auf „Zum Hauptmenü“"])
	assert_eq(_feld(schritte, "erwartet_text"), [
		"Menü steht: SCHWIERIGKEIT, Mittel",
		"Menü steht: HAUPTMENÜ, „Neues Spiel“",
		"Menü steht: SCHWIERIGKEIT, Mittel",
		"Communicator hinausgefahren; Spielbildschirm steht, Hinweis „Speichert Spiel 1 und führt "
			+ "ins Hauptmenü.“; Spielstände: Spiel 1",
		"Titel neu, Menü steht: HAUPTMENÜ, „Weiterspielen“, verfügbar, Hinweis „Weiter mit Spiel 1, "
			+ "Mittel, am 01.01.1985.“; Spielstände: Spiel 1"])
	assert_eq(_feld(schritte, "foto_vergleichbar"), [true, true, true, true, true])


func test_laden_hat_die_schritte_aus_dem_vertrag() -> void:
	# Act
	var schritte := ABLAUF_LADEN.new().schritte(_fahrer)

	# Assert
	assert_eq(_feld(schritte, "kennung"), ["laden.01_weiterspielen", "laden.02_zurueck",
		"laden.03_liste", "laden.04_zeile", "laden.05_zurueck_2"])
	assert_eq(_feld(schritte, "beschreibung"), [
		"Enter auf „Weiterspielen“ setzt Spiel 1 fort",
		"Enter auf „Zum Hauptmenü“ führt zurück ins Hauptmenü",
		"Enter auf „Spiel laden“ zeigt die Liste der Spielstände",
		"Linksklick auf Spiel 1 setzt es fort",
		"Linksklick auf „Zum Hauptmenü“ führt zurück ins Hauptmenü"])
	assert_eq(_feld(schritte, "eingaben_text"), ["Enter auf „Weiterspielen“",
		"Enter auf „Zum Hauptmenü“", "Pfeil runter bis „Spiel laden“, Enter",
		"Linksklick auf Spiel 1", "Linksklick auf „Zum Hauptmenü“"])
	assert_eq(_feld(schritte, "erwartet_text"), [
		"Spielbildschirm steht, Hinweis „Speichert Spiel 1 und führt ins Hauptmenü.“",
		"Menü steht: HAUPTMENÜ, „Weiterspielen“",
		"Menü steht: SPIELSTÄNDE, Spiel 1 mit Mittel, 01.01.1985",
		"Spielbildschirm steht, Hinweis „Speichert Spiel 1 und führt ins Hauptmenü.“",
		"Menü steht: HAUPTMENÜ, „Weiterspielen“"])


func test_loeschen_hat_die_schritte_aus_dem_vertrag() -> void:
	# Act
	var schritte := ABLAUF_LOESCHEN.new().schritte(_fahrer)

	# Assert
	assert_eq(_feld(schritte, "kennung"), ["loeschen.01_liste", "loeschen.02_loeschmodus",
		"loeschen.03_rueckfrage", "loeschen.04_abbrechen", "loeschen.05_rueckfrage_2",
		"loeschen.06_loeschen"])
	assert_eq(_feld(schritte, "beschreibung"), [
		"Linksklick auf „Spiel laden“ zeigt die Liste der Spielstände",
		"Linksklick auf „Löschen …“ schaltet den Löschmodus ein",
		"Linksklick auf Spiel 1 im Löschmodus führt zur Rückfrage",
		"Enter auf „Abbrechen“ führt zurück zur Liste, Spiel 1 bleibt",
		"Linksklick auf Spiel 1 im Löschmodus führt noch einmal zur Rückfrage",
		"Enter auf „Spiel 1 löschen“ löscht den letzten Spielstand"])
	assert_eq(_feld(schritte, "eingaben_text"), ["Linksklick auf „Spiel laden“",
		"Linksklick auf „Löschen …“", "Linksklick auf Spiel 1", "Enter auf „Abbrechen“",
		"Linksklick auf „Löschen …“, Linksklick auf Spiel 1",
		"Pfeil runter bis „Spiel 1 löschen“, Enter"])
	assert_eq(_feld(schritte, "erwartet_text"), [
		"Menü steht: SPIELSTÄNDE, Spiel 1 mit Mittel, 01.01.1985",
		"Menü steht: WELCHES LÖSCHEN?, „Löschen …“, nicht verfügbar",
		"Menü steht: LÖSCHEN?, „Abbrechen“",
		"Menü steht: SPIELSTÄNDE, Spiel 1 mit Mittel, 01.01.1985; Spielstände: Spiel 1",
		"Menü steht: LÖSCHEN?, „Abbrechen“",
		"Menü steht: HAUPTMENÜ, „Neues Spiel“; Spielstände: keine"])


func test_keine_erwartung_sagt_nicht_ausgeloest_und_keine_endet_mit_punkt() -> void:
	for skript: Script in [ABLAUF_NEUES_SPIEL, ABLAUF_LADEN, ABLAUF_LOESCHEN]:
		for schritt in (skript.new() as SelbsttestAblauf).schritte(_fahrer):
			for schluessel: String in ["beschreibung", "eingaben_text", "erwartet_text"]:
				var text: String = schritt[schluessel]
				assert_false(text.contains("nicht ausgelöst"), text)
				assert_false(text.ends_with("."), "%s ohne Schlusspunkt (CHK034)" % text)


func test_easter_egg_hat_die_schritte_aus_dem_vertrag() -> void:
	# Act
	var ablauf := ABLAUF_EASTER_EGG.new() as SelbsttestAblauf
	var schritte := ablauf.schritte(_fahrer)

	# Assert
	assert_eq([ablauf.name, ablauf.baut_auf, ablauf.zeitraffer], ["Easter Egg", "", 8])
	assert_eq(_feld(schritte, "kennung"), ["easter_egg.01_auswahl", "easter_egg.02_falsche_folge",
		"easter_egg.03_start", "easter_egg.04_spielen", "easter_egg.05_ende_esc"])
	assert_eq(_feld(schritte, "beschreibung"), [
		"Pfeil runter bis „Spiel laden“ wählt, hierher kehrt die Auswahl nach Invaders zurück",
		"Gehäusetasten in falscher Folge starten Invaders nicht",
		"Gehäusetasten links, Mitte, rechts starten Invaders",
		"Pfeil rechts fährt die Kanone, Leertaste schießt",
		"Esc beendet Invaders, „Spiel laden“ steht wieder da"])
	assert_eq(_feld(schritte, "eingaben_text"), ["Pfeil runter bis „Spiel laden“",
		"Linksklick auf Gehäusetasten Mitte, links, rechts",
		"Linksklick auf Gehäusetasten links, Mitte, rechts",
		"Pfeil rechts halten 0,5 s, Leertaste", "Esc"])
	assert_eq(_feld(schritte, "erwartet_text"), [
		"Menü steht: HAUPTMENÜ, „Spiel laden“, nicht verfügbar",
		"Seite Invaders nicht sichtbar, Menü steht: HAUPTMENÜ, „Spiel laden“, nicht verfügbar",
		"Seite Invaders sichtbar und aktiv, Hinweis aus",
		"Kanone weiter rechts als beim Start; ein Schuss unterwegs oder ein Treffer gezählt",
		"Menü steht: HAUPTMENÜ, „Spiel laden“, nicht verfügbar, Hinweis „Noch keine "
			+ "Spielstände.“; Spielstände: keine"])
	assert_eq(_feld(schritte, "foto_vergleichbar"), [true, true, false, false, true],
		"Das Spiel rechnet nach Zeit (R7).")


func test_bedienung_hat_die_schritte_aus_dem_vertrag() -> void:
	# Act
	var ablauf := ABLAUF_BEDIENUNG.new() as SelbsttestAblauf
	var schritte := ablauf.schritte(_fahrer)

	# Assert
	assert_eq([ablauf.name, ablauf.baut_auf, ablauf.zeitraffer], ["Bedienung", "", 8])
	assert_eq(_feld(schritte, "kennung"), ["bedienung.01_pfeile", "bedienung.02_tab",
		"bedienung.03_rechtsklick", "bedienung.04_leertaste", "bedienung.05_zurueck_klick",
		"bedienung.06_mausrad"])
	assert_eq(_feld(schritte, "beschreibung"), [
		"Pfeiltasten wählen, am Anfang geht es am Ende weiter",
		"Tab wählt die nächste Zeile, Umschalt+Tab die vorige",
		"Rechtsklick auf „Neues Spiel“ wählt, ohne auszulösen",
		"Leertaste auf „Neues Spiel“ öffnet die Gradwahl",
		"Linksklick auf „Zurück“ führt zurück ins Hauptmenü",
		"Mausrad runter rollt die Liste um 1 Zeile"])
	assert_eq(_feld(schritte, "eingaben_text"), [
		"Pfeil runter, Pfeil hoch, Pfeil hoch, Pfeil hoch", "Tab, Umschalt+Tab",
		"Rechtsklick auf „Neues Spiel“", "Leertaste auf „Neues Spiel“", "Linksklick auf „Zurück“",
		"Vorbereitung: 7 Spielstände; Linksklick auf „Spiel laden“, Mausrad runter über Spiel 1"])
	assert_eq(_feld(schritte, "erwartet_text"), [
		"Auswahl wandert: „Spiel laden“, „Neues Spiel“, „Weiterspielen“, „Beenden“; Menü steht: "
			+ "HAUPTMENÜ, „Beenden“",
		"Auswahl wandert: „Weiterspielen“, „Beenden“; Menü steht: HAUPTMENÜ, „Beenden“",
		"Menü steht: HAUPTMENÜ, „Neues Spiel“; nichts ausgelöst",
		"Menü steht: SCHWIERIGKEIT, Mittel",
		"Menü steht: HAUPTMENÜ, „Neues Spiel“",
		"Liste oben bei Spiel 2, Rollmarke oben sichtbar; Menü steht: SPIELSTÄNDE, Spiel 2 mit "
			+ "Mittel, 01.01.1985"])


func test_liste_hat_die_schritte_aus_dem_vertrag() -> void:
	# Act
	var ablauf := ABLAUF_LISTE.new() as SelbsttestAblauf
	var schritte := ablauf.schritte(_fahrer)

	# Assert
	assert_eq([ablauf.name, ablauf.baut_auf, ablauf.zeitraffer], ["Liste", "", 8])
	assert_eq(_feld(schritte, "kennung"), ["liste.01_oeffnen", "liste.02_esc", "liste.03_zurueck",
		"liste.04_loeschmodus_esc", "liste.05_rueckfrage_esc", "liste.06_loeschen"])
	assert_eq(_feld(schritte, "beschreibung"), [
		"Linksklick auf „Spiel laden“ zeigt die Liste der Spielstände",
		"Esc in der Liste führt zurück ins Hauptmenü",
		"Linksklick auf „Zurück“ führt zurück ins Hauptmenü",
		"Esc schaltet den Löschmodus aus, die Liste bleibt",
		"Esc in der Rückfrage führt zurück zur Liste, Spiel 1 bleibt",
		"Linksklick auf „Spiel 1 löschen“ löscht Spiel 1, die Auswahl springt auf Spiel 2"])
	assert_eq(_feld(schritte, "eingaben_text"), [
		"Vorbereitung: 2 Spielstände; Linksklick auf „Spiel laden“",
		"Esc",
		"Linksklick auf „Spiel laden“, Linksklick auf „Zurück“",
		"Linksklick auf „Spiel laden“, Linksklick auf „Löschen …“, Esc",
		"Linksklick auf „Löschen …“, Linksklick auf Spiel 1, Esc",
		"Linksklick auf „Löschen …“, Linksklick auf Spiel 1, Linksklick auf „Spiel 1 löschen“"])
	assert_eq(_feld(schritte, "erwartet_text"), [
		"Menü steht: SPIELSTÄNDE, Spiel 1 mit Mittel, 01.01.1985; Spielstände: Spiel 1, Spiel 2",
		"Menü steht: HAUPTMENÜ, „Spiel laden“",
		"Menü steht: HAUPTMENÜ, „Spiel laden“",
		"Menü steht: SPIELSTÄNDE, „Löschen …“, verfügbar",
		"Menü steht: SPIELSTÄNDE, Spiel 1 mit Mittel, 01.01.1985; Spielstände: Spiel 1, Spiel 2",
		"Menü steht: SPIELSTÄNDE, Spiel 2 mit Mittel, 01.01.1985; Spielstände: Spiel 2"])
	assert_eq(_feld(schritte, "foto_vergleichbar"), [true, true, true, true, true, true])


func test_fenster_hat_die_schritte_aus_dem_vertrag() -> void:
	# Act: ohne Fenster ist der größte Faktor 1; die App nennt die Zahlen ihres Bildschirms.
	var ablauf := ABLAUF_FENSTER.new() as SelbsttestAblauf
	var schritte := ablauf.schritte(_fahrer)
	var start := "Fenster %d × %d, Bild Faktor %d, ohne Rand" % [640 * _fahrer.bester_faktor(),
		360 * _fahrer.bester_faktor(), _fahrer.bester_faktor()]

	# Assert
	assert_eq([ablauf.name, ablauf.baut_auf, ablauf.zeitraffer], ["Fenster", "", 1])
	assert_eq(_feld(schritte, "kennung"), ["fenster.01_start", "fenster.02_faktor_1",
		"fenster.03_krumm", "fenster.04_zurueck"])
	assert_eq(_feld(schritte, "beschreibung"), [
		"Start mit dem größten Faktor, der passt, Fenster mittig im nutzbaren Bereich",
		"Bild mit Faktor 1 ohne Rand",
		"Bild mit ganzem Faktor mittig im krummen Fenster, Rand ringsum",
		"Bild mit dem Startfaktor ohne Rand, Fenster wieder in Startgröße und -lage"])
	assert_eq(_feld(schritte, "eingaben_text"), ["keine", "Fenster auf 640 × 360",
		"Fenster auf 1318 × 742", "Fenster auf die Startgröße"])
	assert_eq(_feld(schritte, "erwartet_text"), [
		start + "; mittig im nutzbaren Bereich, auf 1 Pixel genau",
		"Fenster 640 × 360, Bild Faktor 1, ohne Rand",
		"Fenster 1318 × 742, Bild Faktor 2, mittig, Rand ringsum, ganze Pixel",
		start])


func test_keine_erwartung_der_uebrigen_sagt_nicht_ausgeloest_oder_endet_mit_punkt() -> void:
	for skript: Script in [ABLAUF_EASTER_EGG, ABLAUF_BEDIENUNG, ABLAUF_LISTE, ABLAUF_FENSTER]:
		for schritt in (skript.new() as SelbsttestAblauf).schritte(_fahrer):
			for schluessel: String in ["beschreibung", "eingaben_text", "erwartet_text"]:
				var text: String = schritt[schluessel]
				assert_false(text.contains("nicht ausgelöst"), text)
				assert_false(text.ends_with("."), "%s ohne Schlusspunkt (CHK034)" % text)


# --- Durchlauf ------------------------------------------------------------------------------------

func test_die_drei_ablaeufe_laufen_nacheinander_im_echten_titel_durch() -> void:
	# Arrange: frischer Titel; die Abläufe hält der Test, wie in der App der Läufer.
	SaveGame.time_zone_bias = 60
	_wechsle(TITEL.resource_path)
	await wait_process_frames(2)
	var ablaeufe: Array[SelbsttestAblauf] = [ABLAUF_NEUES_SPIEL.new(), ABLAUF_LADEN.new(),
		ABLAUF_LOESCHEN.new()]

	for ablauf in ablaeufe:
		for schritt in ablauf.schritte(_fahrer):
			# Act
			var antwort: Variant = await (schritt["eingaben"] as Callable).call()
			var zustand := await _warte_auf(schritt["erwartet"])

			# Assert
			assert_eq(antwort, "", schritt["kennung"])
			assert_eq(zustand, "", "%s: %s" % [schritt["kennung"], zustand])

	assert_eq(_fahrer.spielstaende(), PackedInt32Array(), "Spiel 1 ist am Ende gelöscht.")
	assert_eq(_fahrer.beenden_ausgeloest(), 0)
	assert_false(_sitzung.is_running())


func test_easter_egg_laeuft_im_echten_titel_durch() -> void:
	# Arrange
	_wechsle(TITEL.resource_path)
	await wait_process_frames(2)

	# Act
	var fehler := await _spiele(ABLAUF_EASTER_EGG.new())

	# Assert
	assert_eq(fehler, PackedStringArray())
	assert_eq(_fahrer.beenden_ausgeloest(), 0)


func test_bedienung_laeuft_durch_und_raeumt_die_spielstaende_weg() -> void:
	# Arrange
	SaveGame.time_zone_bias = 60
	_wechsle(TITEL.resource_path)
	await wait_process_frames(2)

	# Act
	var fehler := await _spiele(ABLAUF_BEDIENUNG.new())

	# Assert
	assert_eq(fehler, PackedStringArray())
	assert_eq(_fahrer.spielstaende(), PackedInt32Array(), "Die sieben sind wieder weg.")
	assert_eq(_fahrer.beenden_ausgeloest(), 0)


func test_liste_laeuft_durch_und_raeumt_die_spielstaende_weg() -> void:
	# Arrange
	SaveGame.time_zone_bias = 60
	_wechsle(TITEL.resource_path)
	await wait_process_frames(2)

	# Act
	var fehler := await _spiele(ABLAUF_LISTE.new())

	# Assert
	assert_eq(fehler, PackedStringArray())
	assert_eq(_fahrer.spielstaende(), PackedInt32Array(), "Spiel 2 ist wieder weg.")
	assert_eq(_fahrer.beenden_ausgeloest(), 0)
	assert_false(_sitzung.is_running(), "Kein Weg der Liste setzt ein Spiel fort.")


func test_liste_06_meldet_eine_falsche_auswahl_in_der_form_der_erwartung() -> void:
	# Arrange: die Liste mit Spiel 1 und 2, aber Spiel 1 gewählt statt Spiel 2.
	SaveGame.time_zone_bias = 60
	_wechsle(TITEL.resource_path)
	await wait_process_frames(2)
	var ablauf := ABLAUF_LISTE.new() as SelbsttestAblauf
	var schritte := ablauf.schritte(_fahrer)
	await (schritte[0]["eingaben"] as Callable).call()

	# Act
	var gefunden: String = (schritte[5]["erwartet"] as Callable).call()
	ablauf.aufraeumen(_fahrer)

	# Assert: Erwartung und Befund beginnen gleich und gehen am Spielstand auseinander.
	assert_string_starts_with(gefunden, "Menü steht: SPIELSTÄNDE, Spiel 1 mit Mittel, 01.01.1985, "
		+ "Hinweis „")
	assert_string_ends_with(gefunden, "; Spielstände: Spiel 1, Spiel 2")


func test_bedienung_01_meldet_den_weg_in_der_form_der_erwartung() -> void:
	# Arrange: „Weiterspielen“ vorgewählt, weil ein Spielstand da ist; der Weg geht dann anders.
	_lege_an(1)
	_wechsle(TITEL.resource_path)
	await wait_process_frames(2)
	var ablauf := ABLAUF_BEDIENUNG.new() as SelbsttestAblauf
	var schritte := ablauf.schritte(_fahrer)

	# Act
	await (schritte[0]["eingaben"] as Callable).call()
	var gefunden: String = (schritte[0]["erwartet"] as Callable).call()

	# Assert: Weg und Menü stehen in derselben Folge wie in der Erwartung.
	assert_string_starts_with(gefunden, "Auswahl wandert: „Neues Spiel“, „Weiterspielen“, "
		+ "„Beenden“, „Einstellungen“; Menü steht: HAUPTMENÜ, „Einstellungen“, nicht verfügbar, ")


func test_ein_falscher_grad_steht_in_gefunden_in_der_form_der_erwartung() -> void:
	# Arrange: Gradwahl offen, aber Leicht gewählt statt Mittel.
	_wechsle(TITEL.resource_path)
	await wait_process_frames(2)
	var ablauf := ABLAUF_NEUES_SPIEL.new() as SelbsttestAblauf
	var schritte := ablauf.schritte(_fahrer)
	await (schritte[0]["eingaben"] as Callable).call()
	await _eingabe.maus_zu(_fahrer.ziel_eintrag(SelbsttestFahrer.SEITE_GRADWAHL, &"easy")
		.get_center())

	# Act
	var gefunden: String = (schritte[0]["erwartet"] as Callable).call()

	# Assert: Erwartung und Befund beginnen gleich und gehen am Grad auseinander.
	assert_eq(schritte[0]["erwartet_text"], "Menü steht: SCHWIERIGKEIT, Mittel")
	assert_eq(gefunden, "Menü steht: SCHWIERIGKEIT, Leicht, Hinweis „Das Glück ist eher auf "
		+ "deiner Seite.“; Spielstände: keine")


func test_ohne_fahrt_hinaus_sagt_gefunden_das_an_derselben_stelle() -> void:
	# Arrange: ein Spiel läuft, aber der Spielbildschirm kam ohne Fahrt hinaus.
	_wechsle(TITEL.resource_path)
	await wait_process_frames(2)
	assert_eq(_sitzung.start_new(Difficulty.Level.MITTEL), OK)
	_wechsle(TitleScreen.GAME_SCENE)
	await wait_process_frames(2)
	var ablauf := ABLAUF_NEUES_SPIEL.new() as SelbsttestAblauf
	var schritte := ablauf.schritte(_fahrer)

	# Act
	var gefunden: String = (schritte[3]["erwartet"] as Callable).call()

	# Assert
	assert_eq(gefunden, "Communicator nicht hinausgefahren; Spielbildschirm steht, Hinweis "
		+ "„Speichert Spiel 1 und führt ins Hauptmenü.“; Spielstände: Spiel 1")
	assert_eq(_sitzung.leave(), OK)


# --- Hilfen ---------------------------------------------------------------------------------------

## Ersetzt den Bildschirm im Viewport durch die Szene [param pfad], wie change_scene_to_file() in
## der App. Titel und Spielbildschirm rufen das über ihren scene_callback; dann erst nach dem
## laufenden Signal, denn der alte Bildschirm meldet gerade selbst.
func _wechsle(pfad: String) -> void:
	if _szene != null:
		_viewport.remove_child(_szene)
		_szene.queue_free()
	var neu := (load(pfad) as PackedScene).instantiate()
	neu.set(&"session", _sitzung)
	neu.set(&"scene_callback", func(ziel: String) -> void: _wechsle.call_deferred(ziel))
	if neu is TitleScreen:
		(neu.get_node("Communicator") as Communicator).animate = false
	_viewport.add_child(neu)
	_szene = neu
	_fahrer.szene = neu
	# Wie test_title_screen.gd: Die Maus steht im Viewport, sonst gibt er Bewegungen nicht weiter.
	_viewport.notification(Node.NOTIFICATION_VP_MOUSE_ENTER)


## Ruft [param pruefung] jedes Bild, bis sie "" gibt, höchstens WARTEN_MS; gibt den letzten
## Zustand.
func _warte_auf(pruefung: Callable) -> String:
	var frist := Time.get_ticks_msec() + WARTEN_MS
	var zustand: String = pruefung.call()
	while not zustand.is_empty() and Time.get_ticks_msec() < frist:
		await wait_process_frames(1)
		zustand = pruefung.call()
	return zustand


## Spielt alle Schritte von [param ablauf] wie der Läufer: Eingaben, warten, dann aufräumen. Gibt je
## Schritt „kennung: Antwort | Zustand“ zurück, wenn etwas nicht stimmt.
func _spiele(ablauf: SelbsttestAblauf) -> PackedStringArray:
	var fehler := PackedStringArray()
	for schritt in ablauf.schritte(_fahrer):
		var antwort: Variant = await (schritt["eingaben"] as Callable).call()
		var zustand := await _warte_auf(schritt["erwartet"])
		if antwort != null and antwort != "" or not zustand.is_empty():
			fehler.append("%s: %s | %s" % [schritt["kennung"], antwort, zustand])
	ablauf.aufraeumen(_fahrer)
	return fehler


func _neue_sitzung() -> SITZUNG:
	var uhr := UHR.new()
	add_child_autofree(uhr)
	var zeitleiste := ZEITLEISTE.new()
	zeitleiste.catalog_path = KATALOG
	zeitleiste.clock = uhr
	add_child_autofree(zeitleiste)
	var sitzung := SITZUNG.new()
	sitzung.folder = ORDNER
	sitzung.clock = uhr
	sitzung.timeline = zeitleiste
	sitzung.now = func() -> int: return FESTE_ZEIT
	sitzung.quit_callback = func() -> void: pass
	add_child_autofree(sitzung)
	return sitzung


## Legt im Testordner Spiel [param nummer] an, Mittel, am 01.01.1985.
func _lege_an(nummer: int) -> void:
	var meldungen: Array[CatalogIssue] = []
	var game := SaveGame.new()
	game.number = nummer
	game.name = SaveGame.default_name(nummer)
	game.difficulty = Difficulty.Level.MITTEL
	game.seed = 4711
	game.day = TimelineRun.FIRST_DAY
	game.created_at = FESTE_ZEIT
	game.last_played_at = FESTE_ZEIT
	game.game_version = "0.1"
	game.catalog = EventCatalog.read_file(KATALOG, meldungen)
	assert_eq(SaveStore.new(ORDNER).write(game, true), OK, "Spiel %d angelegt." % nummer)


## Die Werte von [param schluessel] aus allen [param schritte].
static func _feld(schritte: Array[Dictionary], schluessel: String) -> Array:
	var werte := []
	for schritt in schritte:
		werte.append(schritt[schluessel])
	return werte


func _raeume_auf(pfad: String) -> void:
	var ordner := DirAccess.open(pfad)
	if ordner == null:
		return
	for datei in ordner.get_files():
		ordner.remove(datei)
	for unterordner in ordner.get_directories():
		_raeume_auf(pfad.path_join(unterordner))
	DirAccess.remove_absolute(pfad)
