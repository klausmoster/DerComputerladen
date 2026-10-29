extends Node

## Autoload GameSession: das laufende Spiel (Feature 004, research.md, R7). Hält den Spielstand, zu
## dem es gehört, setzt Uhr und Zeitleiste und speichert über SaveStore. Solange ein Spiel läuft,
## speichert es auch beim Schließen des Fensters und bei Cmd+Q (R8).
##
## Ein Spiel beginnt und endet nur hier: start_new() legt eins an, resume() setzt eins fort, leave()
## beendet es. Die Zeitleiste startet seit Feature 004 nichts mehr von selbst (FR-003), und beim
## Start der App tut auch dieser Knoten nichts: Er liest und schreibt erst, wenn jemand ihn ruft.
##
## Uhr, Zeitleiste und Ordner kennt GameSession über Felder, wie die Zeitleiste ihre Uhr: null heißt
## die Autoloads, Tests setzen eigene Knoten und einen eigenen Ordner. So schreibt kein Test in die
## echten Spielstände.
##
## Die Sätze MESSAGE_* sind für die Meldung im Spiel; was genau scheiterte, Datei und Schritt, steht
## nur im Protokoll, über push_warning() mit SaveStore.last_error.

## Speichern ist gescheitert; [param message] ist der Satz für die Meldung.
signal save_failed(message: String)

## Speichern scheitert beim Fortsetzen, beim Speichern, beim Verlassen oder beim Schließen des
## Fensters; das Spiel läuft weiter. Beim Schließen sagt die Meldung nur den Fehler, nicht, dass ein
## zweites Schließen ohne Speichern beendet (R8).
const MESSAGE_KEEPS_RUNNING := "Speichern ging nicht. Dein Spiel läuft weiter."
## Speichern scheitert beim Anlegen; es gibt kein Spiel.
const MESSAGE_NOT_CREATED := "Speichern ging nicht. Es ist kein Spiel angelegt."
## So viele Nummern probiert ein neues Spiel, bevor es aufgibt. Mehr als eine braucht es nur, wenn
## ein zweites Fenster gerade dieselbe Nummer genommen hat (CHK002); fünf reichen auch für mehrere.
const NEW_GAME_ATTEMPTS := 5

const CLOCK_SCRIPT := preload("res://core/game_clock.gd")
const TIMELINE_SCRIPT := preload("res://core/timeline.gd")

## Ordner der Spielstände; Tests setzen ihren eigenen, bevor der Knoten in den Baum kommt.
var folder: String = SaveStore.FOLDER
## null heißt GameClock bzw. Timeline; Tests setzen eigene Knoten.
var clock: Node = null
var timeline: Node = null
## Liefert die Unix-Zeit für „angelegt“ und „zuletzt gespielt“; Tests geben feste Zeiten vor.
var now: Callable = func() -> int: return int(Time.get_unix_time_from_system())
## Würfelt den Seed eines neuen Spiels; Tests setzen einen mit festem Seed (Analyse, C4).
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Wird beim Beenden aufgerufen; ungültig heißt get_tree().quit(). Tests setzen eine eigene
## Funktion, denn quit() beendete ihren ganzen Lauf (wie Werkstatt.quit_callback).
var quit_callback: Callable
## Das laufende Spiel; null, solange keins läuft. Nur lesen.
var current: SaveGame = null
## Satz zum letzten Fehler, für die Meldung. Nur lesen.
var last_error: String = ""

## Das Speichern beim Schließen ist einmal gescheitert; das nächste Schließen beendet ohne (R8).
var _close_failed := false


## Ob ein Spiel läuft.
func is_running() -> bool:
	return current != null


## Die Spielstände im Ordner, für Hauptmenü und Liste. Jeder Aufruf gibt einen frischen SaveStore
## für folder; er hat keinen Zustand außer last_error.
func store() -> SaveStore:
	return SaveStore.new(folder)


# Der Parameter heißt laut Vertrag seed, wie die globale Funktion seed(); die Warnung darüber ist
# abgeschaltet, wie in Timeline.start_game().

## Beginnt ein Spiel am 01.01.1985 mit [param difficulty] und [param seed] (< 0 heißt würfeln mit
## rng), in dieser Reihenfolge (data-model.md, „GameSession“; Analyse, C6): Seed festlegen,
## Spielstand „Spiel N“ anlegen und mit is_new schreiben, dann Uhr setzen und
## Timeline.start_game(seed, difficulty). Gibt es zur Nummer schon eine Datei, etwa aus einem
## zweiten Fenster, nimmt es die nächste (CHK002), höchstens NEW_GAME_ATTEMPTS Nummern. Scheitert
## das Schreiben, beginnt kein Spiel, die Zeitleiste sendet nichts, und last_error ist „Speichern
## ging nicht. Es ist kein Spiel angelegt.“
##
## Erst schreiben, dann starten: So hat die Zeitleiste nie die Meldungen des 01.01.1985 für ein
## Spiel gesendet, das es nicht gibt. Ein Seed über dem größten oder ein unbekannter Grad legt
## nichts an und gibt ERR_INVALID_PARAMETER; die Zeitleiste lehnte beides sonst erst nach dem
## Schreiben ab, und im Ordner läge ein Spielstand, der nie lief.
@warning_ignore("shadowed_global_identifier")
func start_new(difficulty: Difficulty.Level, seed: int = -1) -> Error:
	if seed > TIMELINE_SCRIPT.MAX_SEED or not Difficulty.is_valid(difficulty):
		push_error(("Spielstand: Seed %d oder Schwierigkeitsgrad %d liegt außerhalb. Es wird kein "
			+ "Spiel angelegt.") % [seed, difficulty])
		return ERR_INVALID_PARAMETER
	var game := SaveGame.new()
	game.seed = seed if seed >= 0 else rng.randi_range(0, TIMELINE_SCRIPT.MAX_SEED)
	game.difficulty = difficulty
	game.day = TimelineRun.FIRST_DAY
	# Eine eigene Kopie (FR-022): Der Spielstand behält seinen Katalog, auch wenn die Zeitleiste
	# später einen anderen liest.
	var timeline_catalog: EventCatalog = _timeline().catalog
	game.catalog = timeline_catalog.duplicate_catalog() if timeline_catalog != null \
		else EventCatalog.new()
	game.created_at = now.call()
	game.last_played_at = game.created_at
	game.game_version = _version()

	var saves := store()
	var number := saves.next_number()
	var error := ERR_ALREADY_EXISTS
	for attempt in NEW_GAME_ATTEMPTS:
		game.number = number
		game.name = SaveGame.default_name(number)
		error = saves.write(game, true)
		# Nach dem letzten Versuch nennt das Protokoll keine nächste Nummer, denn keine folgt.
		if error != ERR_ALREADY_EXISTS or attempt == NEW_GAME_ATTEMPTS - 1:
			break
		# Ein zweites Fenster hat die Nummer genommen, seit next_number() sie nannte. Die nächste
		# Nummer fragt der Ordner neu, denn inzwischen kann es mehr Dateien geben.
		var next := maxi(number + 1, saves.next_number())
		push_warning("Spielstand %d: %s Das neue Spiel nimmt die Nummer %d." % [number,
			saves.last_error, next])
		number = next
	if error == ERR_ALREADY_EXISTS:
		push_warning(("Spielstand: Nach %d Versuchen bis Nummer %d war jede Nummer vergeben. "
			+ "Es ist kein Spiel angelegt.") % [NEW_GAME_ATTEMPTS, number])
	elif error != OK:
		push_warning("Spielstand %d: %s Es ist kein Spiel angelegt." % [number, saves.last_error])
	if error != OK:
		last_error = MESSAGE_NOT_CREATED
		return error

	current = game
	last_error = ""
	_close_failed = false
	_clock().set_date(GameDate.from_day_index(TimelineRun.FIRST_DAY))
	_timeline().start_game(game.seed, game.difficulty)
	_update_quit_guard()
	return OK


## Setzt [param slot] fort (FR-016), nur wenn er fortsetzbar ist, sonst ERR_UNAVAILABLE. Speichert
## gleich danach (R9); scheitert das, läuft das Spiel trotzdem: Rückgabe OK, last_error ist
## „Speichern ging nicht. Dein Spiel läuft weiter.“, und save_failed kommt. Der Spielbildschirm
## zeigt die Meldung beim Erscheinen (Analyse, F5).
##
## Die Zeitleiste spielt die Tage bis zum Spieldatum still nach, die Uhr springt ohne Signale
## dorthin. Das erste Signal kommt für den Tag danach, wie in einem Spiel ohne Pause (FR-008).
## Gespeichert wird mit „zuletzt gespielt“ = jetzt und der laufenden Spielversion: So steht das Spiel
## oben in der Liste, auch wenn die App gleich danach abstürzt, und eine ältere Formatversion ist
## danach die aktuelle (FR-014).
func resume(slot: SaveSlot) -> Error:
	if slot == null or not slot.can_resume() or slot.game == null:
		return ERR_UNAVAILABLE
	var game := slot.game
	var interventions: Array[Dictionary] = game.interventions.duplicate(true)
	# Erst die Zeitleiste, dann die Uhr: Lehnt die Zeitleiste ab, bleibt alles, wie es war. Bei
	# einem fortsetzbaren Spielstand kommt das nicht vor, SaveGame.from_data() prüft dieselben
	# Grenzen.
	var error: Error = _timeline().resume_game(game.catalog, game.seed, game.difficulty,
		interventions, game.day)
	if error != OK:
		return error
	_clock().set_date(GameDate.from_day_index(game.day))
	current = game
	last_error = ""
	_close_failed = false
	_update_quit_guard()
	save()
	return OK


## Speichert das laufende Spiel; ERR_UNCONFIGURED ohne Spiel. Der Tag kommt von der Uhr, höchstens
## TimelineRun.LAST_DAY (Analyse, C11). Bei einem Fehler save_failed; nach einem gelungenen
## Speichern ist last_error leer.
func save() -> Error:
	if current == null:
		return ERR_UNCONFIGURED
	var error := _write_current()
	if error != OK:
		_report(MESSAGE_KEEPS_RUNNING)
		return error
	last_error = ""
	return OK


## Speichert und beendet das laufende Spiel (FR-020). Scheitert das Speichern, läuft es weiter.
##
## Beendet heißt: Die Zeitleiste sendet nichts mehr, die Uhr steht wieder am 01.01.1985, und das
## Fenster schließt wieder ohne Umweg über _notification().
func leave() -> Error:
	if current == null:
		return ERR_UNCONFIGURED
	var error := save()
	if error != OK:
		return error
	_timeline().stop_game()
	_clock().set_date(GameDate.from_day_index(TimelineRun.FIRST_DAY))
	current = null
	_close_failed = false
	_update_quit_guard()
	return OK


## Fängt NOTIFICATION_WM_CLOSE_REQUEST ab, solange ein Spiel läuft: speichern und beenden; scheitert
## das Speichern, bleibt das Fenster offen mit der Meldung „Speichern ging nicht. Dein Spiel läuft
## weiter.“, und ein zweites Schließen beendet ohne Speichern (R8).
##
## Die Benachrichtigung bekommt jeder Knoten im Baum, auch in der Werkstatt. Ohne Spiel tut dieser
## Knoten deshalb nichts; dann schließt das Fenster über auto_accept_quit, oder die Werkstatt regelt
## es selbst.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST or current == null:
		return
	if _close_failed:
		_quit()
		return
	if _write_current() == OK:
		last_error = ""
		_quit()
		return
	_close_failed = true
	_report(MESSAGE_KEEPS_RUNNING)


## Schreibt das laufende Spiel mit dem Stand von Uhr und Zeitleiste: Tag, Eingriffe, „zuletzt
## gespielt“ und Spielversion. Gibt den Fehler von SaveStore.write() zurück und meldet ihn mit
## Datei und Schritt im Protokoll; den Satz für den Spieler wählt der Aufrufer.
func _write_current() -> Error:
	# Nach dem Spielende steht die Uhr am 01.01.2000; gespeichert wird der letzte Spieltag.
	current.day = clampi(_clock().date.to_day_index(), TimelineRun.FIRST_DAY, TimelineRun.LAST_DAY)
	var run := _timeline().run
	if run != null:
		# Eine Kopie: Weitere Eingriffe im Lauf ändern den Spielstand erst beim nächsten Speichern.
		current.interventions = run.interventions.duplicate(true)
	current.last_played_at = now.call()
	current.game_version = _version()
	var saves := store()
	var error := saves.write(current)
	if error != OK:
		push_warning("Spielstand %d: %s" % [current.number, saves.last_error])
	return error


## Setzt last_error auf [param message] und sendet save_failed.
func _report(message: String) -> void:
	last_error = message
	save_failed.emit(message)


## Solange ein Spiel läuft, schließt das Fenster erst nach dem Speichern in _notification() (R8).
## Umgeschaltet wird nur hier, beim Beginnen und Beenden eines Spiels; ohne Spiel bleibt, was die
## Szene eingestellt hat, etwa die Werkstatt.
func _update_quit_guard() -> void:
	if is_inside_tree():
		get_tree().auto_accept_quit = current == null


## Beendet die App: quit_callback, ungültig get_tree().quit().
func _quit() -> void:
	if quit_callback.is_valid():
		quit_callback.call()
	else:
		get_tree().quit()


## Die Uhr: clock oder das Autoload GameClock.
func _clock() -> CLOCK_SCRIPT:
	return (clock if clock != null else GameClock) as CLOCK_SCRIPT


## Die Zeitleiste: timeline oder das Autoload Timeline.
func _timeline() -> TIMELINE_SCRIPT:
	return (timeline if timeline != null else Timeline) as TIMELINE_SCRIPT


## Die Version des Spiels aus den Projekteinstellungen, heute „0.1“ (FR-007).
static func _version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))
