extends GutTest

## Prüft das Autoload Timeline als Hülle um den Lauf (Feature 002, T025): Es lädt einen Katalog,
## hängt sich an eine Uhr und macht aus den Meldungen des Laufs Signale.
##
## Wie in test_game_clock.gd arbeiten die Tests nicht mit den Autoloads. Jeder baut sich eine
## eigene Zeitleiste mit Test-Katalog und eigener Uhr. Die Knoten entstehen im Test selbst, nicht
## in before_each(): Nur dann ordnet GUT die erwarteten Fehlermeldungen dem Test zu, und
## assert_push_error() hakt sie als erwartet ab, statt den Test scheitern zu lassen.

const ZEITLEISTE := preload("res://core/timeline.gd")
const UHR := preload("res://core/game_clock.gd")
const ORDNER := "res://test/fixtures/"


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
	assert_eq(zeitleiste.running_entries().size(), 0, "Ohne Dauer läuft nichts (bis Phase 5).")


func test_ohne_seed_wird_gewuerfelt() -> void:
	# Arrange und Act: start_game() kommt per call_deferred() ohne Seed.
	var zeitleiste := await _zeitleiste("catalog_us1_tagesablauf", _uhr())

	# Assert
	assert_not_null(zeitleiste.run, "Das Spiel startet am Ende des ersten Bilds von selbst.")
	assert_between(zeitleiste.get_seed(), 0, ZEITLEISTE.MAX_SEED)
	assert_eq(zeitleiste.run.today, 0, "Der 01.01.1985 ist abgespielt.")


func test_ereignis_mit_fehler_fehlt_im_lauf_und_wird_gemeldet() -> void:
	# Arrange und Act: Im Test-Katalog hat intel_pentium keinen Titel (V04).
	var zeitleiste := await _zeitleiste("catalog_v04_titel_leer", _uhr())

	# Assert
	assert_push_error("Ereignis „intel_pentium“, Feld „title“: Der Titel ist leer. Das Ereignis "
		+ "wird übersprungen.", "Die Meldung nennt Kennung und Grund (FR-049).")
	assert_null(zeitleiste.get_event("intel_pentium"), "Das Ereignis fehlt im Lauf.")
	assert_not_null(zeitleiste.get_event("reklamationswelle"), "Die übrigen sind da.")
	for termin in zeitleiste.run.entries:
		assert_ne(termin.event.id, "intel_pentium")


func test_fehlender_katalog_ergibt_leeren_lauf_und_fehlermeldung() -> void:
	# Arrange
	var uhr := _uhr()
	var zeitleiste := await _zeitleiste(ORDNER + "gibt_es_nicht.json", uhr)
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


# --- Helfer ----------------------------------------------------------------------

## Eine eigene Uhr im Baum, am 01.01.1985.
func _uhr() -> UHR:
	var uhr := UHR.new()
	add_child_autofree(uhr)
	return uhr


## Eine eigene Zeitleiste mit Test-Katalog und Uhr, im Baum. Wartet zwei Bilder, denn
## start_game() kommt per call_deferred() erst am Ende des ersten.
func _zeitleiste(katalog: String, uhr: UHR) -> ZEITLEISTE:
	var zeitleiste := ZEITLEISTE.new()
	zeitleiste.catalog_path = katalog if katalog.begins_with("res://") \
		else ORDNER + katalog + ".json"
	zeitleiste.clock = uhr
	add_child_autofree(zeitleiste)
	await wait_process_frames(2)
	return zeitleiste


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
			TimelineMessage.Kind.ENTRY_SKIPPED, TimelineMessage.Kind.CHAIN_STOPPED:
				zeilen.append("%s entry_skipped %s" % [datum, meldung.event.id])
	return zeilen


## „<kennung> <art> <ziel>“ einer Wirkung.
func _wirkung(source: TimelineEvent, effect: EventEffect) -> String:
	return "%s %s %s" % [source.id, EventEffect.KIND_NAMES[effect.kind], effect.target]


func _tag(jahr: int, monat: int, tag: int) -> int:
	return GameDate.new(jahr, monat, tag).to_day_index()
