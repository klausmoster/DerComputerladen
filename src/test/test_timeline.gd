extends GutTest

## Prüft das Autoload Timeline als Hülle um den Lauf (Feature 002, T025): Es lädt einen Katalog,
## hängt sich an eine Uhr und macht aus den Meldungen des Laufs Signale, auch aus den Enden von
## Ereignissen und Wirkungen (T085). Dazu die Eingriffe, die es an den Lauf durchreicht (T058),
## und die Grenze des Seeds (T083). Seit Feature 003 (T011) auch den Start mit Grad und die
## Meldungen zu Start-Modifikatoren, die wegfallen. Seit Feature 004 (T013) beginnt kein Spiel mehr
## von selbst; dazu Fortsetzen mit resume_game() und Beenden mit stop_game().
##
## Wie in test_game_clock.gd arbeiten die Tests nicht mit den Autoloads. Jeder baut sich eine
## eigene Zeitleiste mit Test-Katalog und eigener Uhr. Die Knoten entstehen im Test selbst, nicht
## in before_each(): Nur dann ordnet GUT die erwarteten Fehlermeldungen dem Test zu, und
## assert_push_error() hakt sie als erwartet ab, statt den Test scheitern zu lassen.

const ZEITLEISTE := preload("res://core/timeline.gd")
const UHR := preload("res://core/game_clock.gd")
const ORDNER := "res://test/fixtures/"
## Die fünf Signale der Zeitleiste.
const SIGNALE := ["event_fired", "effect_applied", "event_ended", "effect_ended", "entry_skipped"]


func test_signale_kommen_in_der_reihenfolge_des_tagesablaufs() -> void:
	# Arrange: Am 01.04.1990 wird eine verzögerte Wirkung fällig, dann beginnen zwei fixe, ein
	# gesetzter, ein gewürfelter und zwei Folgetermine (wie in test_timeline_run.gd).
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us1_tagesablauf", uhr)
	var spur := []
	var ereignisse := []
	_mitschreiben(zeitleiste, spur, ereignisse)
	zeitleiste.start_game(4711)

	# Act
	_vorspulen(uhr, _tag(1990, 4, 1))

	# Assert
	assert_eq(zeitleiste.get_seed(), 4711)
	assert_eq(spur.filter(func(zeile: String) -> bool: return zeile.begins_with("01.04.1990")), [
		"01.04.1990 effect_applied a_verzoegert nachfrage ram",
		"01.04.1990 event_fired b_fix",
		"01.04.1990 effect_applied b_fix presse messe",
		"01.04.1990 event_fired z_fix",
		"01.04.1990 event_fired a_preset",
		"01.04.1990 event_fired c_wuerfel",
		"01.04.1990 event_fired zz_folge",
		"01.04.1990 event_fired folge_b",
	])
	# Jede Meldung des Laufs wurde zu genau ihrem Signal, in derselben Reihenfolge.
	assert_eq(spur, _erwartete_signale(zeitleiste.run))
	# Die Signale tragen die Ereignisse des Laufs; get_event() liefert dieselben Objekte.
	assert_same(ereignisse[ereignisse.size() - 1], zeitleiste.get_event("folge_b"))
	assert_eq(zeitleiste.running_entries().size(), 0, "Ohne Dauer läuft nichts.")


func test_enden_kommen_als_event_ended_und_effect_ended() -> void:
	# Arrange (T085; US3, Szenarien 1 und 5): Das Weihnachtsgeschäft 1993 läuft vom 01.11.1993
	# bis zum 31.12.1993, seine Wirkung auf den Kundenstrom gilt nur während. Beide Enden kommen
	# am 01.01.1994.
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us3_kalender", uhr)
	var spur := []
	var ereignisse := []
	_mitschreiben(zeitleiste, spur, ereignisse)
	zeitleiste.start_game(4711)

	# Act
	_vorspulen(uhr, _tag(1994, 1, 1))

	# Assert: erst endet die Wirkung, dann das Ereignis (Tagesablauf, Schritt 1).
	var weihnachten := spur.filter(func(zeile: String) -> bool:
		return zeile.contains("weihnachtsgeschaeft") and (zeile.begins_with("01.11.1993")
			or zeile.begins_with("01.01.1994")))
	assert_eq(weihnachten, [
		"01.11.1993 event_fired weihnachtsgeschaeft",
		"01.11.1993 effect_applied weihnachtsgeschaeft kundenstrom *",
		"01.01.1994 effect_ended weihnachtsgeschaeft kundenstrom *",
		"01.01.1994 event_ended weihnachtsgeschaeft",
	])
	# Jede Meldung des Laufs wurde zu genau ihrem Signal, auch jedes Ende von Herbst und Winter.
	assert_eq(spur, _erwartete_signale(zeitleiste.run))
	var enden := spur.filter(func(zeile: String) -> bool: return zeile.contains("_ended "))
	assert_gt(enden.size(), 30, "Neun Jahre Jahreszeiten und Weihnachtsgeschäft enden.")


func test_seed_bis_zur_grenze_und_darueber() -> void:
	# Arrange (T083; FR-014): ein laufendes Spiel mit Seed 4711 am 01.06.1990
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us1_tagesablauf", uhr)
	assert_eq(zeitleiste.start_game(4711), OK)
	_vorspulen(uhr, _tag(1990, 6, 1))
	var laufendes := zeitleiste.run
	watch_signals(zeitleiste)

	# Act und Assert: ein Seed über 2.147.483.647 wird abgelehnt.
	var zu_gross: Error = zeitleiste.start_game(ZEITLEISTE.MAX_SEED + 1)
	assert_eq(zu_gross, ERR_INVALID_PARAMETER)
	assert_push_error("Zeitleiste: Der Seed 2147483648 ist zu groß, erlaubt sind 0 bis "
		+ "2.147.483.647. Es beginnt kein neues Spiel.", "Die Meldung nennt Seed und Grenze.")
	assert_same(zeitleiste.run, laufendes, "Das laufende Spiel bleibt.")
	assert_eq([zeitleiste.get_seed(), zeitleiste.run.today], [4711, _tag(1990, 6, 1)])
	for signal_name in ["event_fired", "effect_applied", "event_ended", "effect_ended",
			"entry_skipped"]:
		assert_signal_not_emitted(zeitleiste, signal_name, "Kein neuer erster Tag.")

	# Act und Assert: der größte Seed geht.
	assert_eq(zeitleiste.start_game(ZEITLEISTE.MAX_SEED), OK)
	assert_not_same(zeitleiste.run, laufendes, "Ein neues Spiel …")
	assert_eq([zeitleiste.get_seed(), zeitleiste.run.today], [ZEITLEISTE.MAX_SEED, 0],
		"… mit diesem Seed, am 01.01.1985 abgespielt.")
	# Ohne Seed oder mit negativem wird weiter gewürfelt.
	assert_eq(zeitleiste.start_game(-5), OK)
	assert_between(zeitleiste.get_seed(), 0, ZEITLEISTE.MAX_SEED)


func test_ohne_seed_wird_gewuerfelt() -> void:
	# Arrange und Act: start_game() ohne Seed, wie früher beim Selbststart.
	var zeitleiste := await _zeitleiste("catalog_us1_tagesablauf", _uhr())
	zeitleiste.start_game()

	# Assert
	assert_not_null(zeitleiste.run, "Das Spiel hat begonnen.")
	assert_between(zeitleiste.get_seed(), 0, ZEITLEISTE.MAX_SEED)
	assert_eq(zeitleiste.run.today, 0, "Der 01.01.1985 ist abgespielt.")


# --- Schwierigkeitsgrade (Feature 003, T011) ----------------------------------------

func test_ohne_grad_gilt_mittel() -> void:
	# Arrange und Act (US1, Szenario 5): start_game() ohne Argumente, wie früher beim Selbststart.
	var zeitleiste := await _zeitleiste("catalog_us1_grade", _uhr())
	zeitleiste.start_game()

	# Assert
	assert_eq(zeitleiste.get_difficulty(), Difficulty.Level.MITTEL)
	assert_eq(zeitleiste.run.start_modifiers.size(), 0, "Mittel hat keine Start-Modifikatoren.")
	assert_eq(zeitleiste.start_game(4711), OK)
	assert_eq(zeitleiste.get_difficulty(), Difficulty.Level.MITTEL, "Auch mit Seed allein.")


func test_ohne_spiel_ist_der_grad_minus_eins() -> void:
	# Arrange: eine Zeitleiste, die nie in den Baum kam
	var zeitleiste: ZEITLEISTE = autofree(ZEITLEISTE.new())

	# Act und Assert
	assert_eq(zeitleiste.get_difficulty(), -1)


func test_start_mit_schwer_nennt_seed_und_grad_und_sendet_keine_meldung_grad() -> void:
	# Arrange
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us1_grade", uhr)
	var spur := []
	var ereignisse := []
	_mitschreiben(zeitleiste, spur, ereignisse)

	# Act
	var ergebnis: Error = zeitleiste.start_game(4711, Difficulty.Level.SCHWER)
	_vorspulen(uhr, _tag(1990, 1, 1))

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq([zeitleiste.get_seed(), zeitleiste.get_difficulty()],
		[4711, Difficulty.Level.SCHWER], "Die Zeitleiste nennt Seed und Grad (FR-006).")
	assert_eq(zeitleiste.run.start_modifiers.size(), 1)
	assert_eq(zeitleiste.run.protocol[0].kind, TimelineMessage.Kind.START_MODIFIER,
		"Die Meldung steht im Protokoll …")
	assert_eq(spur, _erwartete_signale(zeitleiste.run), "… und wird kein Signal.")
	for zeile: String in spur:
		assert_false(zeile.begins_with("31.12.1984"), zeile)


func test_szenario_2_zwei_starts_ohne_seed_haben_je_einen_eigenen_seed() -> void:
	# Arrange (US1, Szenario 2; CHK027): Der globale Zufall ist festgesetzt, so ist der Test
	# wiederholbar.
	var zeitleiste := await _zeitleiste("catalog_us1_grade", _uhr())
	seed(20261023)

	# Act
	assert_eq(zeitleiste.start_game(-1, Difficulty.Level.SCHWER), OK)
	var erster: int = zeitleiste.get_seed()
	assert_eq(zeitleiste.start_game(-1, Difficulty.Level.SCHWER), OK)
	var zweiter: int = zeitleiste.get_seed()

	# Assert
	assert_ne(erster, zweiter, "Jedes Spiel bekommt seinen eigenen Seed.")
	assert_between(erster, 0, ZEITLEISTE.MAX_SEED)
	assert_between(zweiter, 0, ZEITLEISTE.MAX_SEED)
	assert_eq(zeitleiste.get_difficulty(), Difficulty.Level.SCHWER)


func test_der_gewuerfelte_seed_haengt_nicht_am_grad() -> void:
	# Arrange (FR-008): derselbe globale Zufall vor jedem Start
	var zeitleiste := await _zeitleiste("catalog_us1_grade", _uhr())
	var seeds := []

	# Act
	for grad: Difficulty.Level in [Difficulty.Level.LEICHT, Difficulty.Level.MITTEL,
			Difficulty.Level.SCHWER]:
		seed(4711)
		assert_eq(zeitleiste.start_game(-1, grad), OK)
		seeds.append(zeitleiste.get_seed())

	# Assert
	assert_eq(seeds, [seeds[0], seeds[0], seeds[0]], "In jedem Grad derselbe gewürfelte Seed.")


func test_unbekannter_grad_wird_abgelehnt_und_das_laufende_spiel_bleibt() -> void:
	# Arrange (FR-011): ein laufendes Spiel mit Schwer am 01.06.1990
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us1_grade", uhr)
	assert_eq(zeitleiste.start_game(4711, Difficulty.Level.SCHWER), OK)
	_vorspulen(uhr, _tag(1990, 6, 1))
	var laufendes := zeitleiste.run
	watch_signals(zeitleiste)

	# Act
	var ergebnis: Error = zeitleiste.start_game(99, 7 as Difficulty.Level)

	# Assert
	assert_eq(ergebnis, ERR_INVALID_PARAMETER)
	assert_push_error("Zeitleiste: Den Schwierigkeitsgrad 7 gibt es nicht, bekannt sind Leicht, "
		+ "Mittel und Schwer. Es beginnt kein neues Spiel.", "Die Meldung nennt den Grad.")
	assert_same(zeitleiste.run, laufendes, "Das laufende Spiel bleibt.")
	assert_eq([zeitleiste.get_seed(), zeitleiste.get_difficulty(), zeitleiste.run.today],
		[4711, Difficulty.Level.SCHWER, _tag(1990, 6, 1)])
	for signal_name in ["event_fired", "effect_applied", "event_ended", "effect_ended",
			"entry_skipped"]:
		assert_signal_not_emitted(zeitleiste, signal_name, "Kein neuer erster Tag.")
	assert_eq(zeitleiste.start_game(99, -1 as Difficulty.Level), ERR_INVALID_PARAMETER,
		"Auch −1 ist kein Grad.")
	assert_push_error("Den Schwierigkeitsgrad -1 gibt es nicht")
	assert_same(zeitleiste.run, laufendes)


func test_fehlerhafte_start_modifikatoren_werden_uebersprungen_und_je_einmal_gemeldet() -> void:
	# Arrange und Act (US1, Szenario 6; FR-013): In Schwer zeigt der erste Start-Modifikator auf
	# ein Ereignis, das es nicht gibt, der zweite auf den Lieferengpass mit einer Grundchance über
	# 100 % (V12), und der dritte gilt.
	var zeitleiste := await _zeitleiste("catalog_us1_profil_kaputt", _uhr())
	assert_eq(zeitleiste.start_game(4711, Difficulty.Level.SCHWER), OK)

	# Assert: drei Meldungen, jede genau einmal
	assert_push_error("Zeitleiste: Ereignis „lieferengpass“, Feld „monthly_chance“: Die "
		+ "Grundchance von 150 % liegt außerhalb von 0 % bis 100 %. Das Ereignis wird "
		+ "übersprungen.", "Das fehlerhafte Ereignis.")
	assert_push_error("Zeitleiste: Profil „Schwer“, Start-Modifikator „geisterereignis“, Feld "
		+ "„profiles.schwer[0].event_id“: Das Ereignis „gibt_es_nicht“ gibt es im Katalog nicht. "
		+ "Der Start-Modifikator wird übersprungen.", "Mit Grad, Kennung und Fehlergrund.")
	assert_push_error("Zeitleiste: Profil „Schwer“, Start-Modifikator „lieferengpass“: Das "
		+ "Ereignis „lieferengpass“ wird übersprungen, deshalb auch dieser Start-Modifikator.",
		"Der, der nur wegen seines Ereignisses wegfällt.")
	assert_push_error_count(3, "Keine Meldung doppelt, auch nicht beim Start.")
	var kennungen := zeitleiste.run.start_modifiers.map(
		func(modifikator: ChanceModifier) -> String: return modifikator.id)
	assert_eq(kennungen, ["reklamationswelle"], "Der dritte gilt.")
	assert_eq(Array(zeitleiste.run.start_refusals), [], "Der Lauf muss nichts ablehnen.")
	assert_null(zeitleiste.get_event("lieferengpass"))


func test_meldung_zu_einem_profil_bekommt_keinen_zusatz_zum_ereignis() -> void:
	# Arrange (Analyse, U5): ein Katalog mit einem Ereignis ohne Kennung (V01) und einem Profil für
	# Mittel. Beide Meldungen haben ein leeres event_id. Bisher bekam deshalb auch die Meldung zum
	# Profil „Das Ereignis wird übersprungen.“, denn das Ereignis ohne Kennung fällt weg.
	var daten: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(ORDNER + "catalog_v01_kennung_leer.json"))
	daten["profiles"] = {"mittel": []}
	var ordner := "user://test_timeline/"
	var pfad := ordner + "profil_mittel.json"
	DirAccess.make_dir_recursive_absolute(ordner)
	var datei := FileAccess.open(pfad, FileAccess.WRITE)
	datei.store_string(JSON.stringify(daten, "\t", true))
	datei.close()

	# Act
	var zeitleiste := await _zeitleiste(pfad, _uhr())
	zeitleiste.start_game()
	DirAccess.remove_absolute(pfad)
	DirAccess.remove_absolute(ordner)

	# Assert: Die Meldung zum Profil steht ohne Zusatz da. Alle Meldungen sind erwartet.
	var zum_profil := []
	for fehler: GutTrackedError in get_errors():
		var text := "%s %s" % [fehler.code, fehler.rationale]
		if text.contains("profiles.mittel"):
			zum_profil.append(text)
		fehler.handled = true
	assert_eq(zum_profil.size(), 1, "Eine Meldung zum Profil für Mittel.")
	for text: String in zum_profil:
		assert_false(text.contains("übersprungen"), text)
	assert_not_null(zeitleiste.run)


func test_ereignis_mit_fehler_fehlt_im_lauf_und_wird_gemeldet() -> void:
	# Arrange und Act: Im Test-Katalog hat intel_pentium keinen Titel (V04). Der feste Seed hält
	# den Fahrplan gleich und damit auch die Zahl der Prüfungen in der Schleife unten.
	var zeitleiste := await _zeitleiste("catalog_v04_titel_leer", _uhr())
	zeitleiste.start_game(4711)

	# Assert
	assert_push_error("Ereignis „intel_pentium“, Feld „title“: Der Titel ist leer. Das Ereignis "
		+ "wird übersprungen.", "Die Meldung nennt Kennung und Grund (FR-049).")
	assert_null(zeitleiste.get_event("intel_pentium"), "Das Ereignis fehlt im Lauf.")
	assert_not_null(zeitleiste.get_event("reklamationswelle"), "Die übrigen sind da.")
	# Mit Seed 4711 sind es 16 Termine: das Weihnachtsgeschäft in 15 Jahren und das Neubaugebiet.
	assert_gte(zeitleiste.run.entries.size(), 15, "Die Schleife prüft echte Termine.")
	for termin in zeitleiste.run.entries:
		assert_ne(termin.event.id, "intel_pentium")


func test_fehlender_katalog_ergibt_leeren_lauf_und_fehlermeldung() -> void:
	# Arrange
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste(ORDNER + "gibt_es_nicht.json", uhr)
	zeitleiste.start_game()
	watch_signals(zeitleiste)

	# Act
	_vorspulen(uhr, _tag(1986, 1, 1))

	# Assert
	assert_push_error("Die Katalogdatei res://test/fixtures/gibt_es_nicht.json fehlt. Die "
		+ "Zeitleiste bleibt leer.", "Die Meldung nennt Pfad und Grund (FR-049).")
	assert_not_null(zeitleiste.run, "Das Spiel startet trotzdem.")
	assert_eq(zeitleiste.run.entries.size(), 0, "Der Lauf ist leer.")
	assert_signal_not_emitted(zeitleiste, "event_fired")


func test_unlesbarer_katalog_ergibt_leeren_lauf_und_fehlermeldung() -> void:
	# Arrange und Act: In Zeile 13 fehlt ein Komma.
	var zeitleiste := await _zeitleiste("catalog_v22_kaputt", _uhr())
	zeitleiste.start_game()

	# Assert
	assert_push_error("catalog_v22_kaputt.json: Kein gültiges JSON in Zeile 13",
		"Die Meldung nennt Datei, Zeile und Grund.")
	assert_eq(zeitleiste.run.entries.size(), 0, "Der Lauf ist leer.")


func test_kettenbremse_kommt_als_entry_skipped_mit_warnung() -> void:
	# Arrange: zwei Ketten am 10.05.1990, je das 17. Glied entfällt (R10).
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us1_kette", uhr)
	zeitleiste.start_game(4711)
	watch_signals(zeitleiste)

	# Act
	_vorspulen(uhr, _tag(1990, 5, 10))

	# Assert
	assert_signal_emit_count(zeitleiste, "entry_skipped", 2, "Ein Abbruch je Kette.")
	for i in 2:
		var parameter: Array = get_signal_parameters(zeitleiste, "entry_skipped", i)
		var termin: ScheduleEntry = parameter[0]
		assert_eq(termin.event.id, "kette_16")
		assert_eq(str(parameter[1]), "10.05.1990", "Mit dem Tag des Abbruchs.")
	var warnung := "Zeitleiste: 10.05.1990  Kettenabbruch  Kette 16: Glied 17 einer Kette am " \
		+ "selben Tag, erlaubt sind 16 (Ereignis „kette_16“)"
	assert_push_warning(warnung, "Erste Kette, mit Ereignis und Tag (FR-018).")
	assert_push_warning(warnung, "Zweite Kette.")


func test_eingriffe_reichen_an_den_lauf_durch_und_senden_kein_signal() -> void:
	# Arrange (T058): am 01.01.1992; „Konkurrent eröffnet“ ist auf den 01.06.1992 gesetzt.
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us6_reklamation", uhr)
	zeitleiste.start_game(4711)
	_vorspulen(uhr, _tag(1992, 1, 1))
	var konkurrent := zeitleiste.run.find_planned("konkurrent_eroeffnet", _tag(1992, 6, 1))
	var modifikator := ChanceModifier.new()
	modifikator.id = "windiger_haendler"
	modifikator.event_id = "reklamationswelle"
	modifikator.value = 0.05
	modifikator.reason = "Ware vom windigen Händler"
	modifikator.from_day = _tag(1992, 1, 1)
	modifikator.to_day = _tag(1993, 12, 31)
	watch_signals(zeitleiste)

	# Act: jeder der fünf Eingriffe einmal, dazu eine Ablehnung
	var ergebnisse := [
		zeitleiste.add_modifier(modifikator),
		zeitleiste.remove_modifier("windiger_haendler"),
		zeitleiste.schedule_event("grossauftrag", _tag(1992, 3, 2), "Messeauftrag"),
		zeitleiste.move_entry(konkurrent.serial, _tag(1992, 9, 1), "Bauarbeiten"),
		zeitleiste.cancel_entry(konkurrent.serial, "Laden nebenan selbst gemietet"),
		zeitleiste.cancel_entry(konkurrent.serial, "Noch einmal"),
	]

	# Assert
	assert_eq(ergebnisse, [OK, OK, OK, OK, OK, ERR_UNAVAILABLE])
	assert_eq(zeitleiste.run.last_refusal, "Konkurrent eröffnet am 01.09.1992 ist nicht mehr "
		+ "geplant, sondern abgesagt.", "Den Grund nennt der Lauf.")
	var arten := zeitleiste.run.interventions.map(
		func(eingriff: Dictionary) -> String: return eingriff["kind"])
	assert_eq(arten, ["add_modifier", "remove_modifier", "schedule", "move", "cancel"])
	var letzte := zeitleiste.run.protocol.slice(-5)
	for meldung: TimelineMessage in letzte:
		assert_eq(meldung.kind, TimelineMessage.Kind.INTERVENTION, meldung.to_line())
	for signal_name in ["event_fired", "effect_applied", "event_ended", "effect_ended",
			"entry_skipped"]:
		assert_signal_not_emitted(zeitleiste, signal_name, "Ein Eingriff wird kein Signal.")


func test_eingriffe_ohne_spiel_ergeben_err_unconfigured() -> void:
	# Arrange: eine Zeitleiste, die nie in den Baum kam; sie hat keinen Lauf.
	var zeitleiste: ZEITLEISTE = autofree(ZEITLEISTE.new())

	# Act und Assert
	assert_null(zeitleiste.run)
	assert_eq(zeitleiste.add_modifier(ChanceModifier.new()), ERR_UNCONFIGURED)
	assert_eq(zeitleiste.remove_modifier("x"), ERR_UNCONFIGURED)
	assert_eq(zeitleiste.cancel_entry(1, "Grund"), ERR_UNCONFIGURED)
	assert_eq(zeitleiste.move_entry(1, 100, "Grund"), ERR_UNCONFIGURED)
	assert_eq(zeitleiste.schedule_event("x", 100, "Grund"), ERR_UNCONFIGURED)


# --- Spielablauf (Feature 004, T013) ------------------------------------------------

func test_ohne_beginn_laeuft_kein_spiel_und_uhrtage_senden_nichts() -> void:
	# Arrange (FR-003; US1, Szenario 5): _ready() ist gelaufen, und zwei Bilder sind vergangen.
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us1_tagesablauf", uhr)
	watch_signals(zeitleiste)

	# Act: bis zum 01.04.1990, an dem ein Spiel mit diesem Katalog acht Signale hätte
	_vorspulen(uhr, _tag(1990, 4, 1))

	# Assert
	assert_null(zeitleiste.run, "Ohne Beginn läuft kein Spiel.")
	assert_false(zeitleiste.is_running())
	assert_eq([zeitleiste.get_seed(), zeitleiste.get_difficulty()], [-1, -1])
	for signal_name in SIGNALE:
		assert_signal_not_emitted(zeitleiste, signal_name, "Uhrtage ohne Spiel senden nichts.")
	assert_not_null(zeitleiste.get_event("b_fix"), "Den Katalog hat sie trotzdem gelesen.")


func test_fortsetzen_am_14_03_1986_ist_still_und_geht_weiter_wie_ohne_pause() -> void:
	# Arrange (US3, Szenario 4; FR-008): ein Spiel ohne Pause, Seed 4711, Schwer, mit zwei
	# Eingriffen vor dem 14.03.1986. Der zweite plant einen Termin nach dem 14.03.1986 ein.
	var uhr_ohne_pause := _uhr()
	var ohne_pause := await _zeitleiste("catalog_us1_grade", uhr_ohne_pause)
	var spur_ohne_pause := []
	_mitschreiben(ohne_pause, spur_ohne_pause, [])
	assert_eq(ohne_pause.start_game(4711, Difficulty.Level.SCHWER), OK)
	_vorspulen(uhr_ohne_pause, _tag(1985, 6, 1))
	assert_eq(ohne_pause.add_modifier(_modifikator("kundenflucht", 0.2, _tag(1985, 6, 1),
		_tag(1986, 12, 31))), OK)
	_vorspulen(uhr_ohne_pause, _tag(1986, 2, 1))
	assert_eq(ohne_pause.schedule_event("lieferengpass", _tag(1986, 5, 2), "Zulieferer pleite"), OK)
	_vorspulen(uhr_ohne_pause, _tag(1986, 3, 14))
	# Dasselbe Spiel, gespeichert am 14.03.1986: eine zweite Zeitleiste an einer zweiten Uhr, die
	# wie beim Fortsetzen ohne Signale auf den Tag springt.
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us1_grade", uhr)
	var spur := []
	_mitschreiben(zeitleiste, spur, [])
	uhr.set_date(GameDate.new(1986, 3, 14))
	var eingriffe: Array[Dictionary] = ohne_pause.run.interventions.duplicate(true)

	# Act
	var ergebnis: Error = zeitleiste.resume_game(zeitleiste.catalog, 4711,
		Difficulty.Level.SCHWER, eingriffe, _tag(1986, 3, 14))

	# Assert: für den 14.03.1986 und davor nichts
	assert_eq(ergebnis, OK)
	assert_eq(spur, [], "Die Tage bis zum 14.03.1986 sind gespielt und bleiben still.")
	assert_eq(zeitleiste.run.today, _tag(1986, 3, 14), "Der Lauf hat den 14.03.1986 abgespielt.")
	assert_eq(zeitleiste.run.interventions, ohne_pause.run.interventions, "Beide Eingriffe gelten.")
	# Ab dem 15.03.1986 Tag für Tag dasselbe bis zum 31.12.1986, je Tag eine Liste
	var tage_ohne_pause := []
	var tage := []
	while uhr.date.to_day_index() < _tag(1986, 12, 31):
		var vorher_ohne_pause := spur_ohne_pause.size()
		var vorher := spur.size()
		uhr_ohne_pause.advance_day()
		uhr.advance_day()
		tage_ohne_pause.append(spur_ohne_pause.slice(vorher_ohne_pause))
		tage.append(spur.slice(vorher))
	assert_eq(tage.size(), 292, "Vom 15.03. bis zum 31.12.1986 sind es 292 Tage.")
	assert_eq(tage, tage_ohne_pause, "Jeden Tag dieselben Signale in derselben Reihenfolge.")
	var anzahl: int = tage.reduce(func(summe: int, tag: Array) -> int: return summe + tag.size(), 0)
	assert_gt(anzahl, 5, "Der Vergleich prüft echte Signale.")


func test_fortsetzen_nimmt_die_uebergebene_kopie_nicht_den_katalog_der_zeitleiste() -> void:
	# Arrange (FR-022): Die Zeitleiste hat Katalog A, der Spielstand bringt Kopie B mit.
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us1_tagesablauf", uhr)
	var kopie := _katalog("catalog_us3_kalender")
	var spur := []
	var ereignisse := []
	_mitschreiben(zeitleiste, spur, ereignisse)
	uhr.set_date(GameDate.new(1990, 1, 1))

	# Act
	var ergebnis: Error = zeitleiste.resume_game(kopie, 4711, Difficulty.Level.MITTEL,
		_keine_eingriffe(), _tag(1990, 1, 1))
	_vorspulen(uhr, _tag(1994, 1, 1))

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq(_kennungen(zeitleiste.run.catalog), _kennungen(kopie),
		"Die Ereignisse sind die von B.")
	assert_null(zeitleiste.get_event("b_fix"), "Keins aus A.")
	var gesendet := {}
	for ereignis: TimelineEvent in ereignisse:
		gesendet[ereignis.id] = true
	assert_true(gesendet.has("weihnachtsgeschaeft"), "Die Signale tragen Ereignisse aus B …")
	assert_eq(gesendet.keys().filter(func(kennung: String) -> bool:
		return kopie.get_event(kennung) == null), [], "… und nur solche.")
	assert_not_null(zeitleiste.catalog.get_event("b_fix"),
		"Der Katalog der Zeitleiste bleibt A, für das nächste neue Spiel.")


func test_fortsetzen_prueft_die_kopie_wie_den_katalog_des_spiels() -> void:
	# Arrange (R2): dieselbe Kopie wie in
	# test_fehlerhafte_start_modifikatoren_werden_uebersprungen_und_je_einmal_gemeldet, dort als
	# Katalog des Spiels gelesen. Lieferengpass hat eine Grundchance über 100 %, und zwei der drei
	# Start-Modifikatoren in Schwer fallen weg.
	var zeitleiste := await _zeitleiste("catalog_us1_tagesablauf", _uhr())
	var kopie := _katalog("catalog_us1_profil_kaputt")

	# Act
	var ergebnis: Error = zeitleiste.resume_game(kopie, 4711, Difficulty.Level.SCHWER,
		_keine_eingriffe(), _tag(1986, 3, 14))

	# Assert: dieselben drei Meldungen wie beim Start mit diesem Katalog, jede genau einmal
	assert_eq(ergebnis, OK)
	assert_push_error("Zeitleiste: Ereignis „lieferengpass“, Feld „monthly_chance“: Die "
		+ "Grundchance von 150 % liegt außerhalb von 0 % bis 100 %. Das Ereignis wird "
		+ "übersprungen.", "Das fehlerhafte Ereignis.")
	assert_push_error("Zeitleiste: Profil „Schwer“, Start-Modifikator „geisterereignis“, Feld "
		+ "„profiles.schwer[0].event_id“: Das Ereignis „gibt_es_nicht“ gibt es im Katalog nicht. "
		+ "Der Start-Modifikator wird übersprungen.", "Mit Grad, Kennung und Fehlergrund.")
	assert_push_error("Zeitleiste: Profil „Schwer“, Start-Modifikator „lieferengpass“: Das "
		+ "Ereignis „lieferengpass“ wird übersprungen, deshalb auch dieser Start-Modifikator.",
		"Der, der nur wegen seines Ereignisses wegfällt.")
	assert_push_error_count(3, "Keine Meldung doppelt.")
	var kennungen := zeitleiste.run.start_modifiers.map(
		func(modifikator: ChanceModifier) -> String: return modifikator.id)
	assert_eq(kennungen, ["reklamationswelle"], "Der dritte gilt.")
	assert_null(zeitleiste.get_event("lieferengpass"), "Das Ereignis fehlt im Lauf …")
	assert_not_null(kopie.get_event("lieferengpass"), "… die übergebene Kopie bleibt, wie sie ist.")


func test_abgelehnter_eingriff_kommt_als_warnung_und_der_rest_gilt() -> void:
	# Arrange: zwei Eingriffe aus einer Datei, Zahlen also als float; der erste nennt ein
	# Ereignis, das es im Katalog nicht gibt.
	var zeitleiste := await _zeitleiste("catalog_us1_grade", _uhr())
	var eingriffe: Array[Dictionary] = [
		{"kind": "schedule", "event_id": "gibt_es_nicht", "day": 100.0, "reason": "Messe",
			"at_day": 50.0},
		{"kind": "schedule", "event_id": "lieferengpass", "day": 200.0,
			"reason": "Zulieferer pleite", "at_day": 50.0},
	]

	# Act
	var ergebnis: Error = zeitleiste.resume_game(zeitleiste.catalog, 4711,
		Difficulty.Level.MITTEL, eingriffe, _tag(1986, 3, 14))

	# Assert
	assert_eq(ergebnis, OK, "Ein abgelehnter Eingriff hält das Fortsetzen nicht auf.")
	assert_push_warning("Zeitleiste: Das Ereignis „gibt_es_nicht“ gibt es im Katalog nicht. Der "
		+ "gespeicherte Eingriff wird übersprungen.", "Die Warnung nennt den Grund.")
	assert_push_warning_count(1)
	assert_eq(zeitleiste.run.interventions.size(), 1, "Der zweite gilt.")
	assert_eq(zeitleiste.run.interventions[0]["event_id"], "lieferengpass")


func test_fortsetzen_mit_seed_grad_oder_tag_ausserhalb_wird_abgelehnt() -> void:
	# Arrange: ein laufendes Spiel mit Schwer am 01.06.1990
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us1_grade", uhr)
	assert_eq(zeitleiste.start_game(4711, Difficulty.Level.SCHWER), OK)
	_vorspulen(uhr, _tag(1990, 6, 1))
	var laufendes := zeitleiste.run
	watch_signals(zeitleiste)
	var mittel := Difficulty.Level.MITTEL
	# Je Fall Seed, Grad, Tag und die Meldung
	var faelle := [
		[ZEITLEISTE.MAX_SEED + 1, mittel, 0, "Zeitleiste: Der Seed 2147483648 liegt außerhalb von "
			+ "0 bis 2.147.483.647. Das Spiel wird nicht fortgesetzt."],
		[-1, mittel, 0, "Zeitleiste: Der Seed -1 liegt außerhalb von 0 bis 2.147.483.647."],
		[4711, 7, 0, "Zeitleiste: Den Schwierigkeitsgrad 7 gibt es nicht, bekannt sind Leicht, "
			+ "Mittel und Schwer. Das Spiel wird nicht fortgesetzt."],
		[4711, -1, 0, "Zeitleiste: Den Schwierigkeitsgrad -1 gibt es nicht"],
		[4711, mittel, -1, "Zeitleiste: Der Tag -1 liegt außerhalb des Spiels, erlaubt sind 0 "
			+ "(01.01.1985) bis 5477 (31.12.1999). Das Spiel wird nicht fortgesetzt."],
		[4711, mittel, TimelineRun.LAST_DAY + 1, "Zeitleiste: Der Tag 5478 liegt außerhalb"],
	]

	# Act und Assert: jeder Fall abgelehnt, das laufende Spiel bleibt.
	for fall: Array in faelle:
		var ergebnis: Error = zeitleiste.resume_game(zeitleiste.catalog, fall[0],
			fall[1] as Difficulty.Level, _keine_eingriffe(), fall[2])
		assert_eq(ergebnis, ERR_INVALID_PARAMETER, fall[3])
		assert_push_error(fall[3])
		assert_same(zeitleiste.run, laufendes, "Das laufende Spiel bleibt.")
	assert_push_error_count(faelle.size(), "Je Fall eine Meldung, keine aus der Prüfung der Kopie.")
	assert_eq([zeitleiste.get_seed(), zeitleiste.get_difficulty(), zeitleiste.run.today],
		[4711, Difficulty.Level.SCHWER, _tag(1990, 6, 1)])

	# Act und Assert: die Grenzen selbst gehen.
	assert_eq(zeitleiste.resume_game(zeitleiste.catalog, 0, Difficulty.Level.LEICHT,
		_keine_eingriffe(), TimelineRun.FIRST_DAY), OK)
	assert_eq([zeitleiste.get_seed(), zeitleiste.get_difficulty(), zeitleiste.run.today],
		[0, Difficulty.Level.LEICHT, TimelineRun.FIRST_DAY], "Seed 0 am 01.01.1985.")
	assert_eq(zeitleiste.resume_game(zeitleiste.catalog, ZEITLEISTE.MAX_SEED,
		Difficulty.Level.SCHWER, _keine_eingriffe(), TimelineRun.LAST_DAY), OK)
	assert_eq([zeitleiste.get_seed(), zeitleiste.get_difficulty(), zeitleiste.run.today],
		[ZEITLEISTE.MAX_SEED, Difficulty.Level.SCHWER, TimelineRun.LAST_DAY],
		"Der größte Seed am 31.12.1999.")
	for signal_name in SIGNALE:
		assert_signal_not_emitted(zeitleiste, signal_name, "Fortsetzen sendet nichts.")


func test_nach_stop_game_kommt_kein_signal_mehr() -> void:
	# Arrange: ein Spiel am 01.01.1990
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste("catalog_us1_tagesablauf", uhr)
	assert_eq(zeitleiste.start_game(4711), OK)
	assert_true(zeitleiste.is_running())
	_vorspulen(uhr, _tag(1990, 1, 1))
	watch_signals(zeitleiste)

	# Act: beenden, dann bis zum 01.04.1990, der acht Signale hätte
	zeitleiste.stop_game()
	_vorspulen(uhr, _tag(1990, 4, 1))

	# Assert
	assert_null(zeitleiste.run)
	assert_false(zeitleiste.is_running())
	assert_eq([zeitleiste.get_seed(), zeitleiste.get_difficulty()], [-1, -1])
	assert_eq(zeitleiste.running_entries().size(), 0)
	assert_eq(zeitleiste.add_modifier(ChanceModifier.new()), ERR_UNCONFIGURED, "Kein Eingriff.")
	for signal_name in SIGNALE:
		assert_signal_not_emitted(zeitleiste, signal_name, "Nach dem Ende sendet sie nichts.")
	zeitleiste.stop_game()
	assert_null(zeitleiste.run, "Ein zweites Beenden ohne Spiel schadet nicht.")
	assert_eq(zeitleiste.start_game(4711), OK)
	assert_true(zeitleiste.is_running(), "Danach kann ein neues Spiel beginnen.")


# --- Helfer ----------------------------------------------------------------------

## Eine eigene Uhr im Baum, am 01.01.1985.
func _uhr() -> UHR:
	var uhr := UHR.new()
	add_child_autofree(uhr)
	return uhr


## Eine eigene Zeitleiste mit Test-Katalog und Uhr, im Baum, ohne Spiel: Seit Feature 004 beginnt
## keins von selbst, das tut der Test mit start_game() oder resume_game(). Wartet trotzdem zwei
## Bilder wie früher bis zum Selbststart; so zeigt sich, dass auch am Ende des ersten Bilds nichts
## beginnt.
func _zeitleiste(katalog: String, uhr: UHR) -> ZEITLEISTE:
	var zeitleiste := ZEITLEISTE.new()
	zeitleiste.catalog_path = katalog if katalog.contains("://") else ORDNER + katalog + ".json"
	zeitleiste.clock = uhr
	add_child_autofree(zeitleiste)
	await wait_process_frames(2)
	return zeitleiste


## Ein Test-Katalog aus [constant ORDNER], gelesen, aber ungeprüft, wie die Kopie in einem
## Spielstand.
func _katalog(name: String) -> EventCatalog:
	var meldungen: Array[CatalogIssue] = []
	var katalog := EventCatalog.read_file(ORDNER + name + ".json", meldungen)
	assert_not_null(katalog, name)
	return katalog


## Die Kennungen der Ereignisse in [param katalog], sortiert.
func _kennungen(katalog: EventCatalog) -> Array:
	var kennungen := katalog.events.map(func(ereignis: TimelineEvent) -> String: return ereignis.id)
	kennungen.sort()
	return kennungen


## Ein leeres Eingriffsprotokoll; resume_game() verlangt den Typ Array[Dictionary].
func _keine_eingriffe() -> Array[Dictionary]:
	var keine: Array[Dictionary] = []
	return keine


## Ein Modifikator auf [param ereignis] um [param wert] vom Tag [param von] bis [param bis].
func _modifikator(ereignis: String, wert: float, von: int, bis: int) -> ChanceModifier:
	var modifikator := ChanceModifier.new()
	modifikator.id = "test_%s" % ereignis
	modifikator.event_id = ereignis
	modifikator.value = wert
	modifikator.reason = "Test"
	modifikator.from_day = von
	modifikator.to_day = bis
	return modifikator


## Schaltet die Uhr Tag für Tag bis zum Tag [param bis] weiter.
func _vorspulen(uhr: UHR, bis: int) -> void:
	while uhr.date.to_day_index() < bis and not uhr.is_finished():
		uhr.advance_day()


## Schreibt jedes Signal der Zeitleiste als Zeile in [param spur] mit, in der Reihenfolge, in der
## es kommt; die Ereignisse der Beginne zusätzlich in [param ereignisse]. bind() hängt die beiden
## Listen hinter die Parameter des Signals.
func _mitschreiben(zeitleiste: ZEITLEISTE, spur: Array, ereignisse: Array) -> void:
	zeitleiste.event_fired.connect(_beginn.bind(spur, ereignisse))
	zeitleiste.effect_applied.connect(_wirkung_beginnt.bind(spur))
	zeitleiste.event_ended.connect(_ende.bind(spur))
	zeitleiste.effect_ended.connect(_wirkung_endet.bind(spur))
	zeitleiste.entry_skipped.connect(_entfall.bind(spur))


func _beginn(event: TimelineEvent, date: GameDate, spur: Array, ereignisse: Array) -> void:
	spur.append("%s event_fired %s" % [date, event.id])
	ereignisse.append(event)


func _wirkung_beginnt(effect: EventEffect, source: TimelineEvent, date: GameDate,
		spur: Array) -> void:
	spur.append("%s effect_applied %s" % [date, _wirkung(source, effect)])


func _ende(event: TimelineEvent, date: GameDate, spur: Array) -> void:
	spur.append("%s event_ended %s" % [date, event.id])


func _wirkung_endet(effect: EventEffect, source: TimelineEvent, date: GameDate,
		spur: Array) -> void:
	spur.append("%s effect_ended %s" % [date, _wirkung(source, effect)])


func _entfall(entry: ScheduleEntry, date: GameDate, spur: Array) -> void:
	spur.append("%s entry_skipped %s" % [date, entry.event.id])


## Die Signale, die laut Vertrag zu den Meldungen des Laufs gehören, als Zeilen wie in
## _mitschreiben().
func _erwartete_signale(run: TimelineRun) -> Array:
	var zeilen := []
	for meldung in run.protocol:
		var datum := GameDate.from_day_index(meldung.day)
		match meldung.kind:
			TimelineMessage.Kind.EVENT_STARTED:
				zeilen.append("%s event_fired %s" % [datum, meldung.event.id])
			TimelineMessage.Kind.EFFECT_STARTED:
				zeilen.append("%s effect_applied %s" % [datum,
					_wirkung(meldung.event, meldung.effect)])
			TimelineMessage.Kind.EVENT_ENDED:
				zeilen.append("%s event_ended %s" % [datum, meldung.event.id])
			TimelineMessage.Kind.EFFECT_ENDED:
				zeilen.append("%s effect_ended %s" % [datum,
					_wirkung(meldung.event, meldung.effect)])
			TimelineMessage.Kind.ENTRY_SKIPPED, TimelineMessage.Kind.CHAIN_STOPPED:
				zeilen.append("%s entry_skipped %s" % [datum, meldung.event.id])
	return zeilen


## „<kennung> <art> <ziel>“ einer Wirkung.
func _wirkung(source: TimelineEvent, effect: EventEffect) -> String:
	return "%s %s %s" % [source.id, EventEffect.KIND_NAMES[effect.kind], effect.target]


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()
