extends Node

## Autoload `Timeline`: die Zeitleiste des Spiels (Feature 002).
##
## Die Hülle um den Lauf (research.md, R1 und R12). Beim Start liest sie den Ereigniskatalog,
## prüft ihn, behält ihn ohne die Ereignisse mit Fehlern und hängt sich an die Spieluhr. Beginnt
## ein Spiel, legt sie einen Lauf an (TimelineRun) und macht aus jeder Meldung des Laufs ein
## Signal. Fahrplan, Würfel und Tagesablauf stecken im Lauf; hier wird nur verbunden und gesendet.
##
## Seit Feature 004 beginnt ein Spiel nicht mehr von selbst (FR-003, research.md, R6): Ein neues
## Spiel beginnt mit start_game(), ein gespeichertes geht mit resume_game() weiter, und
## stop_game() beendet es. Wer das aufruft, ist GameSession; bis dahin sendet die Zeitleiste nichts.
##
## Die Zeitleiste wendet keine Wirkung selbst an. Sie meldet nur, über die Signale unten, und
## Wirtschaft, Nachfrage und Ruf hängen sich später daran.
##
## Seit Feature 003 startet ein Spiel mit einem Schwierigkeitsgrad, Vorgabe Mittel. Der Lauf setzt
## die Start-Modifikatoren seines Profils; die Zeitleiste reicht den Grad nur durch, prüft ihn und
## meldet, was sie aus den Profilen weglassen musste.

## Ein Ereignis beginnt, wie bisher.
signal event_fired(event: TimelineEvent, date: GameDate)
## Eine Wirkung beginnt, wie bisher.
signal effect_applied(effect: EventEffect, source: TimelineEvent, date: GameDate)
## Ein Ereignis mit Dauer endet.
signal event_ended(event: TimelineEvent, date: GameDate)
## Eine Wirkung, die nur während ihres Ereignisses gilt, endet.
signal effect_ended(effect: EventEffect, source: TimelineEvent, date: GameDate)
## Ein Termin entfällt: Eine Bedingung ist nicht erfüllt, das Ereignis läuft noch, oder die
## Kette ist zu lang.
signal entry_skipped(entry: ScheduleEntry, date: GameDate)

const CATALOG_PATH := EventCatalog.DEFAULT_PATH
## Der größte Seed (FR-014): 2.147.483.647, die größte ganze Zahl mit Vorzeichen in 32 Bit.
const MAX_SEED := 2147483647

## Tests setzen einen Test-Katalog, bevor der Knoten in den Baum kommt.
var catalog_path: String = CATALOG_PATH
## Die Uhr, an deren day_passed die Zeitleiste hängt; null heißt das Autoload GameClock. Tests
## setzen eine eigene Uhr, bevor der Knoten in den Baum kommt.
var clock: Node = null
## Würfelt den Seed, wenn start_game() keinen bekommt, statt Godots globalem Würfel (AR-08); Tests
## setzen einen mit festem Seed, wie GameSession.rng.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Der geprüfte Katalog ohne die Ereignisse mit Fehlern; leer, wenn die Datei fehlt oder nicht
## lesbar ist.
var catalog: EventCatalog
## Das laufende Spiel; null, bis start_game() oder resume_game() es anlegt, und wieder null nach
## stop_game().
var run: TimelineRun


## Liest und prüft den Katalog und hängt sich an die Uhr. Ein Spiel beginnt hier nicht mehr; das
## tut GameSession (FR-003). Ein fehlerfreier Katalog erzeugt weiter keine Ausgabe.
func _ready() -> void:
	_load_catalog()
	if clock == null:
		clock = GameClock
	# connect() mit dem Namen des Signals, denn clock ist nur als Node bekannt; game_clock.gd hat
	# kein class_name. Ohne Spiel tut _on_day_passed() nichts.
	clock.connect(&"day_passed", _on_day_passed)


# Der Parameter heißt laut Vertrag seed, wie die globale Funktion seed(); die Warnung darüber
# ist abgeschaltet, sonst wäre der Start mit -d nicht still.

## Legt einen neuen Lauf mit dem Grad [param difficulty] an; [param seed] < 0 heißt würfeln mit
## rng, aus 0 bis 2.147.483.647 (FR-014). Spielt den ersten Tag ab, den 01.01.1985, sendet dessen
## Meldungen und gibt OK zurück. Ein laufendes Spiel wird dabei ersetzt.
##
## Ein Seed über MAX_SEED oder ein unbekannter Grad gehört nicht zum Wertebereich: Es gibt
## ERR_INVALID_PARAMETER und eine Meldung, und ein laufendes Spiel bleibt, wie es ist (FR-011).
## Den Grad prüft die Zeitleiste selbst, denn ein Parameter vom Typ Difficulty.Level nimmt auch
## eine 7 an. Der Seed wird gewürfelt wie bisher, der Grad ändert daran nichts (FR-008).
##
## Seit Feature 004 ruft GameSession das für ein neues Spiel auf, mit dem Seed, den es schon
## gewürfelt und gespeichert hat, und dem Grad aus „Neues Spiel“.
@warning_ignore("shadowed_global_identifier")
func start_game(seed: int = -1, difficulty: Difficulty.Level = Difficulty.DEFAULT) -> Error:
	if seed > MAX_SEED:
		push_error(("Zeitleiste: Der Seed %d ist zu groß, erlaubt sind 0 bis 2.147.483.647. Es "
			+ "beginnt kein neues Spiel.") % seed)
		return ERR_INVALID_PARAMETER
	if not Difficulty.is_valid(difficulty):
		push_error(("Zeitleiste: Den Schwierigkeitsgrad %d gibt es nicht, bekannt sind Leicht, "
			+ "Mittel und Schwer. Es beginnt kein neues Spiel.") % difficulty)
		return ERR_INVALID_PARAMETER
	var game_seed := seed if seed >= 0 else rng.randi_range(0, MAX_SEED)
	run = TimelineRun.new(catalog, game_seed, difficulty)
	# Meist leer: Der Katalog ist schon ohne fehlerhafte Start-Modifikatoren (_load_catalog()).
	for refusal in run.start_refusals:
		push_error("Zeitleiste: %s" % refusal)
	_send(run.begin())
	return OK


## Setzt ein gespeichertes Spiel fort (FR-008, FR-022): prüft [param game_catalog] wie den Katalog
## des Spiels (CatalogValidator, without_faulty(), Meldungen über push_error() wie in
## _load_catalog()), legt darauf einen Lauf mit [param seed] und [param difficulty] an, spielt
## [param interventions] mit TimelineRun.replay() nach und den Lauf bis [param day]. Für diese Tage
## sendet es kein Signal; das erste kommt für den Tag nach [param day]. Ein abgelehnter Eingriff
## kommt als push_warning() mit Grund, der Rest gilt.
##
## ERR_INVALID_PARAMETER und Meldung, wenn Seed, Grad oder Tag außerhalb liegen; ein laufendes
## Spiel bleibt dann, wie es ist.
##
## Still, weil diese Tage schon gespielt sind: Wer sich an die Signale hängt, etwa später die
## Wirtschaft, holt seinen Stand aus dem Spielstand und fragt laufende Termine mit
## running_entries() ab (R6). Die Uhr setzt der Aufrufer selbst auf [param day], mit
## GameClock.set_date(). Ohne Katalog, also mit null, läuft das Spiel wie mit einem leeren.
@warning_ignore("shadowed_global_identifier")
func resume_game(game_catalog: EventCatalog, seed: int, difficulty: Difficulty.Level,
		interventions: Array[Dictionary], day: int) -> Error:
	# Anders als bei start_game() heißt ein negativer Seed hier nicht würfeln: Der Seed steht im
	# Spielstand, und ein anderer gäbe einen anderen Fahrplan.
	if seed < 0 or seed > MAX_SEED:
		push_error(("Zeitleiste: Der Seed %d liegt außerhalb von 0 bis 2.147.483.647. Das Spiel "
			+ "wird nicht fortgesetzt.") % seed)
		return ERR_INVALID_PARAMETER
	if not Difficulty.is_valid(difficulty):
		push_error(("Zeitleiste: Den Schwierigkeitsgrad %d gibt es nicht, bekannt sind Leicht, "
			+ "Mittel und Schwer. Das Spiel wird nicht fortgesetzt.") % difficulty)
		return ERR_INVALID_PARAMETER
	if day < TimelineRun.FIRST_DAY or day > TimelineRun.LAST_DAY:
		push_error(("Zeitleiste: Der Tag %d liegt außerhalb des Spiels, erlaubt sind %d "
			+ "(01.01.1985) bis %d (31.12.1999). Das Spiel wird nicht fortgesetzt.")
			% [day, TimelineRun.FIRST_DAY, TimelineRun.LAST_DAY])
		return ERR_INVALID_PARAMETER
	var issues: Array[CatalogIssue] = []
	var checked := _checked_catalog(
		game_catalog if game_catalog != null else EventCatalog.new(), issues)
	var resumed := TimelineRun.new(checked, seed, difficulty)
	for refusal in resumed.start_refusals:
		push_error("Zeitleiste: %s" % refusal)
	# replay() gibt die Meldungen der nachgespielten Tage nicht zurück, sie landen nur im Protokoll
	# des Laufs. Deshalb geht hier nichts durch _send(), und die Tage bis day bleiben still.
	for refused in resumed.replay(interventions, day):
		push_warning("Zeitleiste: %s Der gespeicherte Eingriff wird übersprungen."
			% refused["reason"])
	run = resumed
	return OK


## Beendet das laufende Spiel: run wird null. Danach kommt kein Signal mehr, bis ein Spiel beginnt.
func stop_game() -> void:
	run = null


## Ob ein Spiel läuft.
func is_running() -> bool:
	return run != null


## Der Seed des laufenden Spiels; −1, solange keins läuft.
func get_seed() -> int:
	return run.seed if run != null else -1


## Der Grad des laufenden Spiels; −1, solange keins läuft (FR-006).
func get_difficulty() -> int:
	return run.difficulty if run != null else -1


## Ein Ereignis des laufenden Spiels; null, wenn es die Kennung nicht gibt. Es ist dasselbe
## Objekt, das die Signale tragen, denn der Lauf arbeitet auf einer eigenen Kopie des Katalogs.
func get_event(id: String) -> TimelineEvent:
	if run != null:
		return run.catalog.get_event(id)
	return catalog.get_event(id) if catalog != null else null


## Die Termine, die gerade laufen (R12): So fragt ein Abnehmer, der später dazukommt, den Stand
## ab, statt auf die nächste Meldung zu warten.
func running_entries() -> Array[ScheduleEntry]:
	if run != null:
		return run.running_entries()
	var none: Array[ScheduleEntry] = []
	return none


# --- Eingriffe (FR-025 bis FR-027) ---------------------------------------------------
#
# Später greifen Spielteile hierüber in die Zeitleiste ein, etwa „Laden nebenan gemietet“ als
# Absage. Die Methoden haben dieselben Signaturen wie im Lauf und reichen nur durch; die Regeln
# und das Eingriffsprotokoll stecken in TimelineRun. Den Grund einer Ablehnung nennt
# run.last_refusal. Solange kein Spiel läuft, gibt es ERR_UNCONFIGURED. Ein Eingriff wird kein
# Signal: Er steht nur als Meldung INTERVENTION im Protokoll des Laufs.


## Setzt einen Modifikator; siehe TimelineRun.add_modifier().
func add_modifier(modifier: ChanceModifier) -> Error:
	if run == null:
		return ERR_UNCONFIGURED
	return run.add_modifier(modifier)


## Entfernt einen Modifikator; siehe TimelineRun.remove_modifier().
func remove_modifier(id: String) -> Error:
	if run == null:
		return ERR_UNCONFIGURED
	return run.remove_modifier(id)


## Sagt einen geplanten Termin ab; siehe TimelineRun.cancel_entry().
func cancel_entry(serial: int, reason: String) -> Error:
	if run == null:
		return ERR_UNCONFIGURED
	return run.cancel_entry(serial, reason)


## Verschiebt einen geplanten Termin; siehe TimelineRun.move_entry().
func move_entry(serial: int, new_day: int, reason: String) -> Error:
	if run == null:
		return ERR_UNCONFIGURED
	return run.move_entry(serial, new_day, reason)


## Plant ein Ereignis als neuen Termin ein; siehe TimelineRun.schedule_event().
func schedule_event(event_id: String, day: int, reason: String) -> Error:
	if run == null:
		return ERR_UNCONFIGURED
	return run.schedule_event(event_id, day, reason)


## Liest den Katalog von catalog_path und behält ihn ohne die Ereignisse mit Fehlern (FR-049)
## und ohne die fehlerhaften Start-Modifikatoren (FR-013 von Feature 003).
func _load_catalog() -> void:
	var issues: Array[CatalogIssue] = []
	var loaded := EventCatalog.read_file(catalog_path, issues)
	if loaded == null:
		# Das Spiel startet trotzdem, mit leerer Zeitleiste; die Meldung nennt Datei und Grund.
		for issue in issues:
			push_error("Zeitleiste: %s Die Zeitleiste bleibt leer." % issue.message)
		catalog = EventCatalog.new()
		return
	catalog = _checked_catalog(loaded, issues)


## Prüft [param loaded] mit CatalogValidator und gibt eine Kopie ohne die Ereignisse mit Fehlern
## und ohne die fehlerhaften Start-Modifikatoren zurück; [param loaded] bleibt, wie es ist. Jeden
## Fehler meldet es über push_error(). [param issues] bringt die Meldungen vom Lesen mit, falls es
## welche gibt, und bekommt die der Prüfung dazu.
##
## Der Katalog des Spiels (_load_catalog()) und die Kopie aus einem Spielstand (resume_game())
## gehen beide hier durch: So fällt beim Fortsetzen genau das weg, was auch beim Start wegfiele,
## mit denselben Meldungen (Feature 004, R2).
static func _checked_catalog(loaded: EventCatalog, issues: Array[CatalogIssue]) -> EventCatalog:
	issues.append_array(CatalogValidator.validate(loaded))
	var checked := loaded.without_faulty(issues)
	# Jede Meldung der Stufe ERROR nennt Ereignis, Kategorie oder Start-Modifikator und Grund.
	# Fehlt das Ereignis danach im Katalog, sagt die Meldung das dazu; den Zusatz bekommt nur eine
	# Meldung mit Kennung, sonst träfe er auch Meldungen zu Profilen (Analyse, U5). Eine Meldung an
	# der Stelle eines Start-Modifikators sagt, dass er wegfällt. Warnungen sind für die Werkstatt.
	for issue in issues:
		if issue.severity != CatalogIssue.Severity.ERROR:
			continue
		var text := "Zeitleiste: %s" % issue.message
		if not issue.event_id.is_empty() and loaded.get_event(issue.event_id) != null \
				and checked.get_event(issue.event_id) == null:
			text += " Das Ereignis wird übersprungen."
		elif _at_start_modifier(issue):
			text += " Der Start-Modifikator wird übersprungen."
		push_error(text)
	# Wer nur wegfällt, weil sein Ereignis ausgenommen ist, hat keine eigene Meldung. So steht jeder
	# weggelassene Start-Modifikator genau einmal da (FR-013; Analyse, G1).
	for skipped in loaded.skipped_start_modifiers(issues):
		if skipped["by_event"]:
			push_error("Zeitleiste: %s: %s" % [skipped["place"], skipped["reason"]])
	return checked


## Ob [param issue] zur Stelle eines Start-Modifikators gehört, Feld „profiles.schwer[2]“ oder
## „profiles.schwer[2].…“. Die Regel steht in DifficultyProfile.faulty_indices(), dieselbe wie in
## without_faulty(); eine Meldung zum ganzen Abschnitt oder zu einem unbekannten Grad gehört zu
## keiner Stelle.
static func _at_start_modifier(issue: CatalogIssue) -> bool:
	var single: Array[CatalogIssue] = [issue]
	for level: int in Difficulty.WITH_PROFILE:
		if not DifficultyProfile.faulty_indices(single, level).is_empty():
			return true
	return false


## Spielt den Lauf bis zum Tag der Uhr ab. GameClock meldet jeden Tag einzeln; der Lauf käme
## auch mit Sprüngen zurecht.
func _on_day_passed(date: GameDate) -> void:
	if run == null:
		return
	_send(run.advance_to(date.to_day_index()))


## Macht aus jeder Meldung das Signal laut Vertrag, in der Reihenfolge der Meldungen. Eingriffe
## und Start-Modifikatoren stehen nur im Protokoll des Laufs und werden kein Signal.
func _send(messages: Array[TimelineMessage]) -> void:
	for message in messages:
		var date := GameDate.from_day_index(message.day)
		match message.kind:
			TimelineMessage.Kind.EVENT_STARTED:
				event_fired.emit(message.event, date)
			TimelineMessage.Kind.EFFECT_STARTED:
				effect_applied.emit(message.effect, message.event, date)
			TimelineMessage.Kind.EVENT_ENDED:
				event_ended.emit(message.event, date)
			TimelineMessage.Kind.EFFECT_ENDED:
				effect_ended.emit(message.effect, message.event, date)
			TimelineMessage.Kind.ENTRY_SKIPPED:
				entry_skipped.emit(message.entry, date)
			TimelineMessage.Kind.CHAIN_STOPPED:
				# Eine Kette, die so lang wird, ist fast immer ein Fehler im Katalog; deshalb
				# zusätzlich eine Warnung mit Ereignis und Tag (FR-018).
				push_warning("Zeitleiste: %s (Ereignis „%s“)" % [message.to_line(),
					message.event.id])
				entry_skipped.emit(message.entry, date)
			TimelineMessage.Kind.INTERVENTION, TimelineMessage.Kind.START_MODIFIER:
				pass
