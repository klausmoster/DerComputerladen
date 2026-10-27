extends GutTest

## Prüft GameSession (Feature 004, T014; contracts/spielablauf.md, „GameSession“ und „Tests“;
## data-model.md, „GameSession“; research.md, R4 und R7 bis R9): ein neues Spiel anlegen, mit dem
## Seed aus rng und dem Ausweichen auf die nächste Nummer, fortsetzen, speichern, verlassen und das
## Schließen des Fensters, jeweils auch mit gescheitertem Speichern. Dazu SC-005, das Spieldatum
## nach dem Verlassen auf den Tag, und SC-002, das Fortsetzen eines großen Spielstands.
##
## Wie test_timeline.gd arbeiten die Tests nicht mit den Autoloads. _sitzung() baut je Test eigene
## Uhr, eigene Zeitleiste mit Test-Katalog und eine eigene GameSession mit dem Ordner ORDNER, festen
## Zeiten (_jetzt), rng mit festem Seed und einem eigenen quit_callback, der nur zählt. Nach
## user://spielstaende/ schreibt kein Test; after_each() räumt ORDNER ab und stellt
## auto_accept_quit wieder her, das eine Sitzung mit laufendem Spiel abschaltet.
##
## Speichern scheitert ohne Hilfe im Code (R16): Ein Ordner mit Inhalt an der Stelle der .neu lässt
## sich weder löschen noch beschreiben, und unter einer Datei lässt sich kein Ordner anlegen. Nur
## das zweite Fenster braucht eine Hilfe, OrdnerMitZweitemFenster: Es legt seine Datei genau in dem
## Augenblick an, nachdem die Sitzung nach der nächsten Nummer gefragt hat; mit jedes_mal tut es das
## bei jeder Frage, als nähmen immer neue Fenster jede Nummer.

const SITZUNG := preload("res://core/game_session.gd")
const ZEITLEISTE := preload("res://core/timeline.gd")
const UHR := preload("res://core/game_clock.gd")
const ORDNER := "user://test_game_session/"
const KATALOGE := "res://test/fixtures/"
const FIXTURES := "res://test/fixtures/spielstaende/"
## Die fünf Signale der Zeitleiste.
const SIGNALE := ["event_fired", "effect_applied", "event_ended", "effect_ended", "entry_skipped"]
## 26.10.2026, 20:40:12 UTC
const ANGELEGT := 1793047212
## 27.10.2026, 18:05:00 UTC
const GESPIELT := 1793124300
## Seed des Würfels für neue Spiele.
const WUERFEL_SEED := 20261026
## SC-002: so lange darf das Fortsetzen dauern, so oft wird gemessen.
const FORTSETZEN_MSEC := 1000.0
const LAEUFE := 3

## Die Sätze für den Spieler, hier ausgeschrieben statt als Konstanten aus dem Code: So fällt jede
## Änderung hier auf.
const NICHT_ANGELEGT := "Speichern ging nicht. Es ist kein Spiel angelegt."
const LAEUFT_WEITER := "Speichern ging nicht. Dein Spiel läuft weiter."

## Was now liefert; ein Test stellt die Zeit vor, indem er das hier ändert.
var _jetzt := ANGELEGT
## So oft hat eine Sitzung quit_callback aufgerufen.
var _beendet := 0
var _auto_accept_quit_vorher := true


## Ein zweites Fenster (Analyse, C4): Es legt sein Spiel unter genau der Nummer an, die
## next_number() eben genannt hat, bevor die Sitzung schreibt. So entsteht der Zusammenstoß, dem
## start_new() ausweichen muss; lag die Datei schon vorher da, nennte next_number() gleich die
## nächste.
class OrdnerMitZweitemFenster:
	extends SaveStore

	## Das Spiel des zweiten Fensters; seine Nummer setzt next_number().
	var fremdes_spiel: SaveGame
	## true: Bei jeder Frage nach der nächsten Nummer nimmt ein weiteres Fenster genau diese.
	var jedes_mal := false

	func next_number() -> int:
		var nummer := super.next_number()
		if fremdes_spiel != null and (fremdes_spiel.number == 0 or jedes_mal):
			fremdes_spiel.number = nummer
			fremdes_spiel.name = SaveGame.default_name(nummer)
			SaveStore.new(folder).write(fremdes_spiel, true)
		return nummer


## Eine Sitzung, deren store() immer denselben SaveStore gibt, damit das zweite Fenster darin sitzt.
class SitzungMitOrdner:
	extends "res://core/game_session.gd"

	var ordner: SaveStore

	func store() -> SaveStore:
		return ordner


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ORDNER)
	_jetzt = ANGELEGT
	_beendet = 0
	_auto_accept_quit_vorher = get_tree().auto_accept_quit


func after_each() -> void:
	get_tree().auto_accept_quit = _auto_accept_quit_vorher
	_raeume_auf(ORDNER)


# --- Neues Spiel (FR-006, FR-009) ---------------------------------------------------------------

func test_neues_spiel_legt_spiel_1_mit_grad_seed_und_01_01_1985_an() -> void:
	# Arrange: Die Uhr steht irgendwo; das neue Spiel setzt sie.
	var sitzung := await _sitzung()
	var uhr := _uhr(sitzung)
	var zeitleiste := _zeitleiste(sitzung)
	uhr.set_date(GameDate.new(1990, 6, 1))
	watch_signals(sitzung)

	# Act
	var ergebnis := sitzung.start_new(Difficulty.Level.SCHWER, 4711)

	# Assert: Spiel, Uhr und Zeitleiste
	assert_eq(ergebnis, OK)
	assert_true(sitzung.is_running())
	assert_eq(sitzung.last_error, "")
	assert_eq(uhr.date.to_iso(), "1985-01-01", "Die Uhr steht am 01.01.1985.")
	assert_eq([zeitleiste.get_seed(), zeitleiste.get_difficulty(), zeitleiste.run.today],
		[4711, Difficulty.Level.SCHWER, TimelineRun.FIRST_DAY], "Der Lauf hat den 01.01.1985 gespielt.")
	assert_false(get_tree().auto_accept_quit, "Solange ein Spiel läuft, schließt erst GameSession.")
	assert_signal_not_emitted(sitzung, "save_failed")
	# Assert: die Datei
	assert_eq(_dateien(), ["spiel_1.json"])
	var slot := _lies(1)
	assert_eq(slot.state, SaveSlot.State.OK, slot.reason)
	var game := slot.game
	assert_eq([game.number, game.name, game.difficulty, game.seed, game.day],
		[1, "Spiel 1", Difficulty.Level.SCHWER, 4711, TimelineRun.FIRST_DAY])
	assert_eq([game.created_at, game.last_played_at], [ANGELEGT, ANGELEGT])
	assert_eq(game.game_version, ProjectSettings.get_setting("application/config/version"))
	assert_ne(game.game_version, "", "Die Version steht in den Projekteinstellungen.")
	assert_eq(game.interventions, [], "Noch kein Eingriff.")
	assert_eq(game.catalog.to_dict(), zeitleiste.catalog.to_dict(), "Der Katalog der Zeitleiste.")
	assert_eq(FileAccess.get_file_as_string(_pfad(1)), sitzung.current.to_json(),
		"Die Datei ist das laufende Spiel.")


func test_zwei_neue_spiele_mit_demselben_grad_haben_verschiedene_seeds() -> void:
	# Arrange (Analyse, C4): Ein Würfel mit demselben Seed sagt voraus, was rng würfelt.
	var sitzung := await _sitzung()
	var vergleich := RandomNumberGenerator.new()
	vergleich.seed = WUERFEL_SEED
	var erwartet := [vergleich.randi_range(0, ZEITLEISTE.MAX_SEED),
		vergleich.randi_range(0, ZEITLEISTE.MAX_SEED)]

	# Act
	assert_eq(sitzung.start_new(Difficulty.Level.MITTEL), OK)
	var erster: int = sitzung.current.seed
	assert_eq(sitzung.leave(), OK)
	assert_eq(sitzung.start_new(Difficulty.Level.MITTEL), OK)
	var zweiter: int = sitzung.current.seed

	# Assert
	assert_eq([erster, zweiter], erwartet, "Gewürfelt mit rng, aus 0 bis 2.147.483.647.")
	assert_ne(erster, zweiter, "Das nächste Spiel hat einen anderen Seed.")
	assert_eq(_zeitleiste(sitzung).get_seed(), zweiter, "Die Zeitleiste spielt mit diesem Seed.")
	assert_eq([_lies(1).game.seed, _lies(2).game.seed], erwartet, "So steht es in den Dateien.")
	assert_eq([_lies(1).game.name, _lies(2).game.name], ["Spiel 1", "Spiel 2"])


func test_nummern_mit_luecken() -> void:
	# Arrange (R4): Spiel 1 und 4, dazu eine übrig gebliebene spiel_6.json.alt
	var sitzung := await _sitzung()
	var vorher := {}
	for nummer: int in [1, 4]:
		assert_eq(sitzung.store().write(_spielstand(nummer)), OK)
	_schreibe(_pfad(6) + ".alt", _spielstand(6).to_json())
	for datei: String in _dateien():
		vorher[datei] = FileAccess.get_file_as_string(ORDNER.path_join(datei))

	# Act
	var ergebnis := sitzung.start_new(Difficulty.Level.LEICHT)

	# Assert: die größte Nummer plus 1; die Lücken bleiben.
	assert_eq(ergebnis, OK)
	assert_eq([sitzung.current.number, sitzung.current.name], [7, "Spiel 7"])
	assert_eq(_dateien(), ["spiel_1.json", "spiel_4.json", "spiel_6.json.alt", "spiel_7.json"])
	for datei: String in vorher:
		assert_eq(FileAccess.get_file_as_string(ORDNER.path_join(datei)), vorher[datei],
			"Unberührt: %s" % datei)


func test_zwei_fenster_das_neue_spiel_weicht_auf_die_naechste_nummer_aus() -> void:
	# Arrange (CHK002; Analyse, C4): Spiel 1 liegt da. Das zweite Fenster legt Spiel 2 an, gleich
	# nachdem die Sitzung nach der nächsten Nummer gefragt hat.
	var ordner := OrdnerMitZweitemFenster.new(ORDNER)
	ordner.fremdes_spiel = _spielstand(0)
	var mit_ordner := SitzungMitOrdner.new()
	mit_ordner.ordner = ordner
	var sitzung := await _sitzung("catalog_us1_grade", mit_ordner)
	assert_eq(SaveStore.new(ORDNER).write(_spielstand(1)), OK)
	var spiel_1 := FileAccess.get_file_as_string(_pfad(1))

	# Act
	var ergebnis := sitzung.start_new(Difficulty.Level.SCHWER, 4711)

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq(ordner.fremdes_spiel.number, 2, "Das zweite Fenster hat die 2 genommen.")
	assert_eq([sitzung.current.number, sitzung.current.name], [3, "Spiel 3"])
	assert_eq(_dateien(), ["spiel_1.json", "spiel_2.json", "spiel_3.json"])
	assert_eq(FileAccess.get_file_as_string(_pfad(2)), ordner.fremdes_spiel.to_json(),
		"Die Datei des zweiten Fensters bleibt unberührt.")
	assert_eq(FileAccess.get_file_as_string(_pfad(1)), spiel_1, "Spiel 1 auch.")
	assert_eq(_lies(3).game.seed, 4711)
	assert_push_warning("Spielstand 2: Speichern: Zur Nummer 2 gibt es schon eine Datei, etwa %s. "
		% _pfad(2) + "Das neue Spiel nimmt die Nummer 3.", "Das Protokoll nennt den Zusammenstoß.")


func test_ist_jede_nummer_vergeben_gibt_das_neue_spiel_nach_fuenf_versuchen_auf() -> void:
	# Arrange: Bei jeder Frage nach der nächsten Nummer nimmt ein weiteres Fenster genau diese.
	var ordner := OrdnerMitZweitemFenster.new(ORDNER)
	ordner.fremdes_spiel = _spielstand(0)
	ordner.jedes_mal = true
	var mit_ordner := SitzungMitOrdner.new()
	mit_ordner.ordner = ordner
	var sitzung := await _sitzung("catalog_us1_grade", mit_ordner)
	watch_signals(_zeitleiste(sitzung))

	# Act
	var ergebnis := sitzung.start_new(Difficulty.Level.SCHWER, 4711)

	# Assert: kein Spiel
	assert_eq(ergebnis, ERR_ALREADY_EXISTS)
	assert_eq(sitzung.last_error, NICHT_ANGELEGT)
	assert_false(sitzung.is_running())
	assert_null(_zeitleiste(sitzung).run, "Die Zeitleiste hat kein Spiel begonnen.")
	for signal_name in SIGNALE:
		assert_signal_not_emitted(_zeitleiste(sitzung), signal_name)
	assert_true(get_tree().auto_accept_quit)
	assert_eq(_dateien(), ["spiel_1.json", "spiel_2.json", "spiel_3.json", "spiel_4.json",
		"spiel_5.json"], "Nur die Dateien der anderen Fenster; die Sitzung hat 1 bis 5 versucht.")
	for nummer in range(1, 6):
		assert_eq(_lies(nummer).game.number, nummer,
			"Spiel %d gehört einem anderen Fenster." % nummer)
	# Assert: Eine nächste Nummer nennt das Protokoll nur, solange noch ein Versuch folgt.
	for nummer in range(1, 5):
		assert_push_warning(("Spielstand %d: Speichern: Zur Nummer %d gibt es schon eine Datei, "
			+ "etwa %s. Das neue Spiel nimmt die Nummer %d.") % [nummer, nummer, _pfad(nummer),
			nummer + 1])
	assert_push_warning("Spielstand: Nach 5 Versuchen bis Nummer 5 war jede Nummer vergeben. "
		+ "Es ist kein Spiel angelegt.", "Die Schlusswarnung nennt letzte Nummer und Versuche.")
	assert_push_warning_count(5, "Keine Warnung zu Nummer 6, die nie versucht wurde.")


func test_ungueltiger_grad_oder_seed_legt_nichts_an() -> void:
	# Arrange
	var sitzung := await _sitzung()

	# Act
	var mit_grad := sitzung.start_new(7 as Difficulty.Level, 4711)
	var mit_seed := sitzung.start_new(Difficulty.Level.MITTEL, ZEITLEISTE.MAX_SEED + 1)

	# Assert
	assert_eq([mit_grad, mit_seed], [ERR_INVALID_PARAMETER, ERR_INVALID_PARAMETER])
	assert_push_error("Spielstand: Seed 4711 oder Schwierigkeitsgrad 7 liegt außerhalb.")
	assert_push_error("Spielstand: Seed 2147483648 oder Schwierigkeitsgrad 1 liegt außerhalb.")
	assert_false(sitzung.is_running())
	assert_null(_zeitleiste(sitzung).run)
	assert_eq(_dateien(), [], "Keine Datei für ein Spiel, das die Zeitleiste ablehnen würde.")


# --- Verlassen und Spieldatum (SC-005, FR-010, FR-020) ------------------------------------------

func test_sc_005_verlassen_speichert_das_spieldatum_auf_den_tag() -> void:
	# Arrange
	var sitzung := await _sitzung()
	var uhr := _uhr(sitzung)
	var zeitleiste := _zeitleiste(sitzung)
	var tage := [[1985, 1, 1], [1985, 2, 15], [1986, 3, 14], [1999, 12, 31]]

	for i in tage.size():
		var datum: Array = tage[i]
		var tag := _tag(datum[0], datum[1], datum[2])
		assert_eq(sitzung.start_new(Difficulty.Level.LEICHT), OK)
		assert_false(get_tree().auto_accept_quit)

		# Act: mit der eigenen Uhr vorspulen, dann verlassen
		_vorspulen(uhr, tag)
		var ergebnis := sitzung.leave()

		# Assert: der Tag in der Datei
		var text := "%02d.%02d.%04d" % [datum[2], datum[1], datum[0]]
		assert_eq(ergebnis, OK, text)
		var slot := _lies(i + 1)
		assert_eq(slot.state, SaveSlot.State.OK, slot.reason)
		assert_eq([slot.game.day, slot.game.day_text()], [tag, text], "Gespeichert am %s." % text)
		# Assert: Das Spiel ist beendet.
		assert_false(sitzung.is_running())
		assert_null(sitzung.current)
		assert_false(zeitleiste.is_running(), "Die Zeitleiste sendet nichts mehr.")
		assert_eq(uhr.date.to_iso(), "1985-01-01", "Die Uhr steht wieder am 01.01.1985.")
		assert_true(get_tree().auto_accept_quit, "Ohne Spiel schließt das Fenster wieder sofort.")
		assert_eq(sitzung.last_error, "")


func test_nach_dem_spielende_ist_das_spieldatum_der_31_12_1999() -> void:
	# Arrange (Analyse, C11): Nach dem Spielende steht die Uhr am 01.01.2000.
	var sitzung := await _sitzung()
	var uhr := _uhr(sitzung)
	assert_eq(sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)
	_vorspulen(uhr, TimelineRun.LAST_DAY + 1)
	assert_true(uhr.is_finished())
	assert_eq(uhr.date.to_iso(), "2000-01-01")

	# Act
	var ergebnis := sitzung.save()

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq(_lies(1).game.day_text(), "31.12.1999", "Höchstens der letzte Spieltag.")


func test_speichern_nimmt_tag_eingriffe_und_zeit_und_laesst_das_spiel_laufen() -> void:
	# Arrange: ein Eingriff am 01.02.1986
	var sitzung := await _sitzung()
	var uhr := _uhr(sitzung)
	var zeitleiste := _zeitleiste(sitzung)
	assert_eq(sitzung.start_new(Difficulty.Level.SCHWER, 4711), OK)
	_vorspulen(uhr, _tag(1986, 2, 1))
	assert_eq(zeitleiste.schedule_event("lieferengpass", _tag(1986, 5, 2), "Zulieferer pleite"),
		OK)
	_vorspulen(uhr, _tag(1986, 3, 14))
	_jetzt = GESPIELT

	# Act
	var ergebnis := sitzung.save()

	# Assert
	assert_eq(ergebnis, OK)
	var game := _lies(1).game
	assert_eq([game.day_text(), game.created_at, game.last_played_at],
		["14.03.1986", ANGELEGT, GESPIELT])
	assert_eq(game.interventions, zeitleiste.run.interventions, "Die Eingriffe des Laufs.")
	assert_eq(game.interventions.size(), 1)
	assert_true(sitzung.is_running(), "Speichern beendet nichts.")
	assert_true(zeitleiste.is_running())
	assert_eq(uhr.date.to_iso(), "1986-03-14")
	# Eine Kopie: Ein weiterer Eingriff ändert den Spielstand erst beim nächsten Speichern.
	assert_eq(zeitleiste.schedule_event("lieferengpass", _tag(1986, 8, 1), "Noch einer"), OK)
	assert_eq(sitzung.current.interventions.size(), 1)


# --- Fortsetzen (FR-016, FR-022, R9) ------------------------------------------------------------

func test_fortsetzen_setzt_uhr_lauf_und_zuletzt_gespielt() -> void:
	# Arrange: ein Spiel mit einem Eingriff, verlassen am 14.03.1986
	var erste := await _sitzung()
	var erste_uhr := _uhr(erste)
	var erste_zeitleiste := _zeitleiste(erste)
	assert_eq(erste.start_new(Difficulty.Level.SCHWER, 4711), OK)
	_vorspulen(erste_uhr, _tag(1986, 2, 1))
	assert_eq(erste_zeitleiste.schedule_event("lieferengpass", _tag(1986, 5, 2),
		"Zulieferer pleite"), OK)
	_vorspulen(erste_uhr, _tag(1986, 3, 14))
	var lauf_vorher := erste_zeitleiste.run
	assert_eq(erste.leave(), OK)
	# Später, nach einem Neustart: eigene Uhr, Zeitleiste und Sitzung
	_jetzt = GESPIELT
	var sitzung := await _sitzung()
	var uhr := _uhr(sitzung)
	var zeitleiste := _zeitleiste(sitzung)
	var slot := sitzung.store().list_slots()[0]
	watch_signals(zeitleiste)
	watch_signals(sitzung)

	# Act
	var ergebnis := sitzung.resume(slot)

	# Assert: Uhr und Lauf
	assert_eq(ergebnis, OK)
	assert_true(sitzung.is_running())
	assert_same(sitzung.current, slot.game, "Das laufende Spiel ist der gelesene Spielstand.")
	assert_eq(uhr.date.to_iso(), "1986-03-14")
	assert_eq([zeitleiste.get_seed(), zeitleiste.get_difficulty(), zeitleiste.run.today],
		[4711, Difficulty.Level.SCHWER, _tag(1986, 3, 14)])
	assert_eq(zeitleiste.run.interventions, lauf_vorher.interventions, "Der Eingriff gilt.")
	assert_eq(_fahrplan(zeitleiste.run), _fahrplan(lauf_vorher), "Derselbe Fahrplan, Tag für Tag.")
	for signal_name in SIGNALE:
		assert_signal_not_emitted(zeitleiste, signal_name, "Fortsetzen ist still.")
	assert_false(get_tree().auto_accept_quit)
	# Assert: gleich gespeichert, mit „zuletzt gespielt“ = jetzt (R9)
	assert_eq(sitzung.last_error, "")
	assert_signal_not_emitted(sitzung, "save_failed")
	var game := _lies(1).game
	assert_eq([game.created_at, game.last_played_at, game.day_text()],
		[ANGELEGT, GESPIELT, "14.03.1986"])
	assert_eq(game.game_version, ProjectSettings.get_setting("application/config/version"))
	# Assert: Das erste Signal kommt für den 15.03.1986 oder später.
	_vorspulen(uhr, _tag(1986, 12, 31))
	assert_signal_emitted(zeitleiste, "event_fired", "Danach geht das Spiel weiter.")


func test_nur_ein_fortsetzbarer_spielstand_laesst_sich_fortsetzen() -> void:
	# Arrange: ein beschädigter und ein zu neuer Spielstand
	var sitzung := await _sitzung()
	_kopiere("spiel_kein_json.json", 1)
	_kopiere("spiel_format_2.json", 2)
	var vorher := [FileAccess.get_file_as_string(_pfad(1)), FileAccess.get_file_as_string(_pfad(2))]
	var slots := sitzung.store().list_slots()
	assert_eq(slots.size(), 2)

	# Act und Assert
	for slot in slots:
		assert_eq(sitzung.resume(slot), ERR_UNAVAILABLE, slot.reason)
	assert_eq(sitzung.resume(null), ERR_UNAVAILABLE, "Ohne Spielstand.")
	assert_false(sitzung.is_running())
	assert_null(_zeitleiste(sitzung).run)
	assert_true(get_tree().auto_accept_quit)
	assert_eq([FileAccess.get_file_as_string(_pfad(1)), FileAccess.get_file_as_string(_pfad(2))],
		vorher, "Nicht fortsetzbare werden nie überschrieben.")


func test_katalog_tauschen_und_fortsetzen_nimmt_den_gespeicherten() -> void:
	# Arrange (FR-022; Analyse, E1): ein Spiel mit Katalog A, verlassen am 01.01.1990
	var sitzung := await _sitzung("catalog_us1_tagesablauf")
	var uhr := _uhr(sitzung)
	var zeitleiste := _zeitleiste(sitzung)
	var katalog_a := zeitleiste.catalog
	assert_eq(sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)
	_vorspulen(uhr, _tag(1990, 1, 1))
	assert_eq(sitzung.leave(), OK)
	# Der Katalog der Zeitleiste wird B, etwa nach einem Update des Spiels.
	zeitleiste.catalog = _katalog("catalog_us3_kalender")

	# Act
	var ergebnis := sitzung.resume(_lies(1))

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq(_kennungen(zeitleiste.run.catalog), _kennungen(katalog_a), "Die Ereignisse von A.")
	assert_null(zeitleiste.get_event("cebit"), "Keins aus B.")
	var ohne_pause := TimelineRun.new(katalog_a, 4711, Difficulty.Level.MITTEL)
	ohne_pause.advance_to(_tag(1990, 1, 1))
	assert_eq(_fahrplan(zeitleiste.run), _fahrplan(ohne_pause), "Der Fahrplan des Katalogs A.")
	assert_eq(_kennungen(_lies(1).game.catalog), _kennungen(katalog_a),
		"Gespeichert bleibt Katalog A.")


func test_fortsetzen_nach_loeschen_von_aussen_schreibt_den_gelesenen_stand_wieder() -> void:
	# Arrange (Edge Case „Datei ändert sich von außen“; Analyse, E3)
	var sitzung := await _sitzung()
	assert_eq(sitzung.start_new(Difficulty.Level.SCHWER, 4711), OK)
	_vorspulen(_uhr(sitzung), _tag(1986, 3, 14))
	assert_eq(sitzung.leave(), OK)
	var slot := sitzung.store().list_slots()[0]
	assert_eq(DirAccess.remove_absolute(_pfad(1)), OK)
	assert_eq(_dateien(), [], "Von außen gelöscht.")
	_jetzt = GESPIELT

	# Act
	var ergebnis := sitzung.resume(slot)

	# Assert
	assert_eq(ergebnis, OK)
	assert_eq(sitzung.last_error, "")
	assert_eq(_dateien(), ["spiel_1.json"], "Wieder da.")
	var game := _lies(1).game
	assert_eq([game.name, game.seed, game.difficulty, game.day_text()],
		["Spiel 1", 4711, Difficulty.Level.SCHWER, "14.03.1986"])
	assert_eq([game.created_at, game.last_played_at], [ANGELEGT, GESPIELT])


func test_sc_002_fortsetzen_mit_500_ereignissen_vom_31_12_1999_in_hoechstens_einer_sekunde() -> void:
	# Arrange (R16; CHK024): ein Spielstand mit catalog_500.json am 31.12.1999
	var sitzung := await _sitzung()
	var spiel := _spielstand(1, _katalog("catalog_500"))
	spiel.day = TimelineRun.LAST_DAY
	assert_eq(spiel.catalog.events.size(), 500)
	assert_eq(sitzung.store().write(spiel), OK)
	var zeiten: Array[float] = []

	# Act: je Lauf frisch gelesen und gemessen nur das Fortsetzen, samt Speichern
	for lauf in LAEUFE:
		var slot := _lies(1)
		var beginn := Time.get_ticks_usec()
		var ergebnis := sitzung.resume(slot)
		zeiten.append((Time.get_ticks_usec() - beginn) / 1000.0)
		assert_eq(ergebnis, OK)
		assert_eq(_zeitleiste(sitzung).run.today, TimelineRun.LAST_DAY)
		assert_eq(_uhr(sitzung).date.to_iso(), "1999-12-31")
		assert_eq(sitzung.leave(), OK)

	# Assert
	var sortiert := zeiten.duplicate()
	sortiert.sort()
	var median: float = sortiert[floori(sortiert.size() / 2.0)]
	gut.p("SC-002, Fortsetzen mit 500 Ereignissen am 31.12.1999: Median %.1f ms aus %s" % [
		median, zeiten])
	assert_lt(median, FORTSETZEN_MSEC, "SC-002: fortgesetzt in höchstens einer Sekunde.")


# --- Speichern scheitert (FR-011, SC-004) -------------------------------------------------------

func test_speichern_scheitert_beim_anlegen_dann_gibt_es_kein_spiel() -> void:
	# Arrange: Der Ordner liegt unter einer Datei und lässt sich nicht anlegen. Die Uhr steht am
	# 01.03.1990; am 01.04.1990 hätte ein Spiel mit diesem Katalog acht Signale.
	var sitzung := await _sitzung("catalog_us1_tagesablauf")
	var uhr := _uhr(sitzung)
	var zeitleiste := _zeitleiste(sitzung)
	_schreibe(ORDNER.path_join("datei"), "keine Ordner hier")
	sitzung.folder = ORDNER.path_join("datei/spielstaende/")
	uhr.set_date(GameDate.new(1990, 3, 1))
	watch_signals(zeitleiste)
	watch_signals(sitzung)

	# Act
	var ergebnis := sitzung.start_new(Difficulty.Level.MITTEL, 4711)
	var uhr_danach := uhr.date.to_iso()
	_vorspulen(uhr, _tag(1990, 4, 1))

	# Assert
	assert_ne(ergebnis, OK)
	assert_eq(sitzung.last_error, NICHT_ANGELEGT)
	assert_false(sitzung.is_running())
	assert_null(sitzung.current)
	assert_null(zeitleiste.run, "Die Zeitleiste hat kein Spiel begonnen.")
	assert_eq(uhr_danach, "1990-03-01", "Die Uhr bleibt, wo sie war.")
	for signal_name in SIGNALE:
		assert_signal_not_emitted(zeitleiste, signal_name, "Die Zeitleiste sendet nichts.")
	assert_signal_not_emitted(sitzung, "save_failed", "Die Meldung kommt über den Rückgabewert.")
	assert_true(get_tree().auto_accept_quit, "Ohne Spiel bleibt das Fenster, wie es war.")
	assert_push_warning("Speichern: Der Ordner %s lässt sich nicht anlegen" % sitzung.folder,
		"Das Protokoll nennt Ordner und Schritt.")
	# Godot meldet selbst, dass sich unter einer Datei kein Ordner anlegen lässt.
	assert_engine_error("Method/function failed")
	assert_eq(_dateien(), ["datei"], "Kein Spielstand.")


func test_speichern_scheitert_beim_fortsetzen_das_spiel_laeuft_trotzdem() -> void:
	# Arrange (Analyse, F5): ein Spielstand, an der Stelle seiner .neu ein Ordner mit Inhalt
	var sitzung := await _sitzung()
	assert_eq(sitzung.start_new(Difficulty.Level.LEICHT, 4711), OK)
	_vorspulen(_uhr(sitzung), _tag(1986, 3, 14))
	assert_eq(sitzung.leave(), OK)
	var vorher := FileAccess.get_file_as_string(_pfad(1))
	_hindernis(1)
	var slot := sitzung.store().list_slots()[0]
	_jetzt = GESPIELT
	watch_signals(sitzung)

	# Act
	var ergebnis := sitzung.resume(slot)

	# Assert
	assert_eq(ergebnis, OK, "Das Spiel läuft trotzdem.")
	assert_true(sitzung.is_running())
	assert_true(_zeitleiste(sitzung).is_running())
	assert_eq(_uhr(sitzung).date.to_iso(), "1986-03-14")
	assert_eq(sitzung.last_error, LAEUFT_WEITER)
	assert_signal_emitted_with_parameters(sitzung, "save_failed", [LAEUFT_WEITER])
	assert_false(get_tree().auto_accept_quit)
	assert_push_warning("Spielstand 1: Speichern: Schritt 1")
	assert_eq(FileAccess.get_file_as_string(_pfad(1)), vorher, "Der alte Stand ist unberührt.")


func test_speichern_scheitert_beim_verlassen_das_spiel_laeuft_weiter() -> void:
	# Arrange
	var sitzung := await _sitzung()
	var uhr := _uhr(sitzung)
	assert_eq(sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)
	_vorspulen(uhr, _tag(1985, 2, 15))
	_hindernis(1)
	watch_signals(sitzung)

	# Act
	var ergebnis := sitzung.leave()

	# Assert: Das Spiel läuft weiter, wo es war.
	assert_ne(ergebnis, OK)
	assert_true(sitzung.is_running())
	assert_true(_zeitleiste(sitzung).is_running())
	assert_eq(uhr.date.to_iso(), "1985-02-15")
	assert_eq(sitzung.last_error, LAEUFT_WEITER)
	assert_signal_emitted_with_parameters(sitzung, "save_failed", [LAEUFT_WEITER])
	assert_false(get_tree().auto_accept_quit)
	assert_push_warning("Spielstand 1: Speichern: Schritt 1")
	assert_eq(_lies(1).game.day_text(), "01.01.1985", "In der Datei steht der Stand vom Anlegen.")

	# Act und Assert: Das Hindernis ist weg, der zweite Versuch gelingt.
	_hindernis_weg(1)
	assert_eq(sitzung.leave(), OK)
	assert_eq(sitzung.last_error, "", "Nach einem gelungenen Speichern ist last_error leer.")
	assert_false(sitzung.is_running())
	assert_true(get_tree().auto_accept_quit)
	assert_eq(_lies(1).game.day_text(), "15.02.1985")


# --- Schließen des Fensters (R8) ----------------------------------------------------------------

func test_schliessen_mit_spiel_speichert_und_beendet() -> void:
	# Arrange
	var sitzung := await _sitzung()
	assert_eq(sitzung.start_new(Difficulty.Level.SCHWER, 4711), OK)
	_vorspulen(_uhr(sitzung), _tag(1985, 2, 15))
	_jetzt = GESPIELT

	# Act: wie Fensterknopf oder Cmd+Q
	sitzung.notification(NOTIFICATION_WM_CLOSE_REQUEST)

	# Assert
	assert_eq(_beendet, 1, "quit_callback einmal.")
	var game := _lies(1).game
	assert_eq([game.day_text(), game.last_played_at], ["15.02.1985", GESPIELT])
	assert_eq(sitzung.last_error, "")


func test_schliessen_scheitert_dann_beendet_das_zweite_ohne_speichern() -> void:
	# Arrange
	var sitzung := await _sitzung()
	var uhr := _uhr(sitzung)
	assert_eq(sitzung.start_new(Difficulty.Level.SCHWER, 4711), OK)
	_vorspulen(uhr, _tag(1985, 2, 15))
	_hindernis(1)
	watch_signals(sitzung)

	# Act: das erste Schließen
	sitzung.notification(NOTIFICATION_WM_CLOSE_REQUEST)

	# Assert: Das Fenster bleibt offen, das Spiel läuft.
	assert_eq(_beendet, 0, "Nicht beendet.")
	assert_true(sitzung.is_running())
	assert_eq(sitzung.last_error, LAEUFT_WEITER, "Die Meldung sagt nur den Fehler.")
	assert_signal_emitted_with_parameters(sitzung, "save_failed", [LAEUFT_WEITER])
	assert_push_warning("Spielstand 1: Speichern: Schritt 1")
	assert_false(get_tree().auto_accept_quit)

	# Act: Das Hindernis ist weg, die Zeit läuft weiter, dann das zweite Schließen.
	_hindernis_weg(1)
	var vorher := FileAccess.get_file_as_string(_pfad(1))
	_vorspulen(uhr, _tag(1985, 3, 1))
	_jetzt = GESPIELT
	sitzung.notification(NOTIFICATION_WM_CLOSE_REQUEST)

	# Assert: beendet, ohne zu speichern
	assert_eq(_beendet, 1, "Das zweite Schließen beendet.")
	assert_eq(FileAccess.get_file_as_string(_pfad(1)), vorher, "Ohne Speichern.")
	assert_eq(_dateien(), ["spiel_1.json"])


func test_ohne_spiel_wird_nichts_gespeichert_und_nichts_umgeschaltet() -> void:
	# Arrange: wie in der Werkstatt, die das Schließen selbst regelt
	var sitzung := await _sitzung()
	get_tree().auto_accept_quit = false
	watch_signals(sitzung)

	# Act
	sitzung.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	var gespeichert := sitzung.save()
	var verlassen := sitzung.leave()

	# Assert
	assert_eq(_beendet, 0, "Ohne Spiel beendet GameSession nichts.")
	assert_eq([gespeichert, verlassen], [ERR_UNCONFIGURED, ERR_UNCONFIGURED])
	assert_false(get_tree().auto_accept_quit, "Die Einstellung der Szene bleibt.")
	assert_signal_not_emitted(sitzung, "save_failed")
	assert_eq(_dateien(), [], "Nichts gespeichert.")
	assert_false(sitzung.is_running())

	# Act und Assert: nach dem Verlassen eines Spiels genauso
	get_tree().auto_accept_quit = true
	assert_eq(sitzung.start_new(Difficulty.Level.MITTEL, 4711), OK)
	assert_eq(sitzung.leave(), OK)
	var nach_dem_verlassen := FileAccess.get_file_as_string(_pfad(1))
	_jetzt = GESPIELT
	sitzung.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(_beendet, 0)
	assert_true(get_tree().auto_accept_quit, "Nach leave() ist auto_accept_quit wieder an.")
	assert_eq(FileAccess.get_file_as_string(_pfad(1)), nach_dem_verlassen, "Nichts gespeichert.")


# --- Hilfen ---------------------------------------------------------------------------------

## Eigene Uhr, Zeitleiste mit dem Test-Katalog [param katalog] und eine GameSession, alle im Baum.
## [param sitzung] ist eine vorbereitete Sitzung, etwa eine Unterklasse; ohne eine neue. Wartet wie
## test_timeline.gd zwei Bilder: So zeigt sich, dass ohne start_new() nichts beginnt.
func _sitzung(katalog: String = "catalog_us1_grade", sitzung: Node = null) -> SITZUNG:
	var uhr := UHR.new()
	add_child_autofree(uhr)
	var zeitleiste := ZEITLEISTE.new()
	zeitleiste.catalog_path = KATALOGE + katalog + ".json"
	zeitleiste.clock = uhr
	add_child_autofree(zeitleiste)
	var neue := (sitzung if sitzung != null else SITZUNG.new()) as SITZUNG
	neue.folder = ORDNER
	neue.clock = uhr
	neue.timeline = zeitleiste
	neue.now = func() -> int: return _jetzt
	neue.rng = RandomNumberGenerator.new()
	neue.rng.seed = WUERFEL_SEED
	neue.quit_callback = func() -> void: _beendet += 1
	add_child_autofree(neue)
	await wait_process_frames(2)
	assert_false(neue.is_running(), "Ohne start_new() läuft kein Spiel.")
	assert_null(zeitleiste.run)
	return neue


func _uhr(sitzung: SITZUNG) -> UHR:
	return sitzung.clock as UHR


func _zeitleiste(sitzung: SITZUNG) -> ZEITLEISTE:
	return sitzung.timeline as ZEITLEISTE


## Ein Spielstand mit der Nummer [param nummer], am 15.02.1985, mit dem Katalog [param katalog]
## oder catalog_us1_grade.json.
func _spielstand(nummer: int, katalog: EventCatalog = null) -> SaveGame:
	var game := SaveGame.new()
	game.number = nummer
	game.name = SaveGame.default_name(nummer)
	game.difficulty = Difficulty.Level.SCHWER
	game.seed = 4711
	game.day = _tag(1985, 2, 15)
	game.created_at = ANGELEGT
	game.last_played_at = ANGELEGT
	game.game_version = "0.1"
	game.catalog = katalog if katalog != null else _katalog("catalog_us1_grade")
	return game


## Ein Test-Katalog aus fixtures/, gelesen.
func _katalog(name: String) -> EventCatalog:
	var meldungen: Array[CatalogIssue] = []
	var katalog := EventCatalog.read_file(KATALOGE + name + ".json", meldungen)
	assert_not_null(katalog, name)
	return katalog


## Liest spiel_<nummer>.json im Testordner.
func _lies(nummer: int) -> SaveSlot:
	return SaveSlot.read(_pfad(nummer), nummer)


func _pfad(nummer: int) -> String:
	return ORDNER.path_join("spiel_%d.json" % nummer)


## Ein Ordner mit Inhalt an der Stelle von spiel_<nummer>.json.neu: Speichern scheitert dort in
## Schritt 1 (R16).
func _hindernis(nummer: int) -> void:
	DirAccess.make_dir_recursive_absolute(_pfad(nummer) + ".neu/inhalt")


func _hindernis_weg(nummer: int) -> void:
	_raeume_auf(_pfad(nummer) + ".neu")


## Der Fahrplan als Zeilen „Tag Kennung Zustand“, zum Vergleich zweier Läufe.
func _fahrplan(run: TimelineRun) -> Array:
	return run.entries.map(func(entry: ScheduleEntry) -> String:
		return "%d %s %d" % [entry.day, entry.event.id, entry.state])


## Die Kennungen der Ereignisse in [param katalog], sortiert.
func _kennungen(katalog: EventCatalog) -> Array:
	var kennungen := katalog.events.map(func(ereignis: TimelineEvent) -> String: return ereignis.id)
	kennungen.sort()
	return kennungen


## Schaltet die Uhr Tag für Tag bis zum Tag [param bis] weiter.
func _vorspulen(uhr: UHR, bis: int) -> void:
	while uhr.date.to_day_index() < bis and not uhr.is_finished():
		uhr.advance_day()


## Die Dateien und Ordner im Testordner, sortiert.
func _dateien() -> Array:
	var namen := Array(DirAccess.get_files_at(ORDNER))
	namen.append_array(DirAccess.get_directories_at(ORDNER))
	namen.sort()
	return namen


## Kopiert eine Fixture als spiel_<nummer>.json in den Testordner.
func _kopiere(fixture: String, nummer: int) -> void:
	assert_eq(DirAccess.copy_absolute(FIXTURES.path_join(fixture), _pfad(nummer)), OK,
		"Kopiert: %s" % fixture)


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
