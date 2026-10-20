extends Node

## Autoload `Timeline`: die Zeitleiste des Spiels (Feature 002).
##
## Die Hülle um den Lauf (research.md, R1 und R12). Beim Start liest sie den Ereigniskatalog,
## prüft ihn und behält ihn ohne die Ereignisse mit Fehlern. Dann legt sie einen Lauf an
## (TimelineRun), hängt sich an die Spieluhr und macht aus jeder Meldung des Laufs ein Signal.
## Fahrplan, Würfel und Tagesablauf stecken im Lauf; hier wird nur verbunden und gesendet.
##
## Die Zeitleiste wendet keine Wirkung selbst an. Sie meldet nur, über die Signale unten, und
## Wirtschaft, Nachfrage und Ruf hängen sich später daran.

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
## Der geprüfte Katalog ohne die Ereignisse mit Fehlern; leer, wenn die Datei fehlt oder nicht
## lesbar ist.
var catalog: EventCatalog
## Das laufende Spiel; null, bis start_game() es anlegt.
var run: TimelineRun


## Liest und prüft den Katalog, hängt sich an die Uhr und startet das Spiel am Ende des ersten
## Bilds. Ein fehlerfreier Katalog erzeugt keine Ausgabe.
func _ready() -> void:
	_load_catalog()
	if clock == null:
		clock = GameClock
	# connect() mit dem Namen des Signals, denn clock ist nur als Node bekannt; game_clock.gd hat
	# kein class_name.
	clock.connect(&"day_passed", _on_day_passed)
	# call_deferred() führt den Aufruf erst am Ende des Bilds aus, nach dem _ready() der
	# Hauptszene. So hören Abnehmer in der Szene schon den ersten Spieltag (R12).
	start_game.call_deferred()


# Der Parameter heißt laut Vertrag seed, wie die globale Funktion seed(); die Warnung darüber
# ist abgeschaltet, sonst wäre der Start mit -d nicht still.

## Legt einen neuen Lauf an; [param seed] < 0 heißt würfeln, aus 0 bis 2.147.483.647 (FR-014).
## Spielt den ersten Tag ab, den 01.01.1985, und sendet dessen Meldungen. Ein laufendes Spiel
## wird dabei ersetzt.
@warning_ignore("shadowed_global_identifier")
func start_game(seed: int = -1) -> void:
	var game_seed := seed if seed >= 0 else randi_range(0, MAX_SEED)
	run = TimelineRun.new(catalog, game_seed)
	_send(run.begin())


## Der Seed des laufenden Spiels; −1, solange keins läuft.
func get_seed() -> int:
	return run.seed if run != null else -1


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


## Liest den Katalog von catalog_path und behält ihn ohne die Ereignisse mit Fehlern (FR-049).
func _load_catalog() -> void:
	var issues: Array[CatalogIssue] = []
	var loaded := EventCatalog.read_file(catalog_path, issues)
	if loaded == null:
		# Das Spiel startet trotzdem, mit leerer Zeitleiste; die Meldung nennt Datei und Grund.
		for issue in issues:
			push_error("Zeitleiste: %s Die Zeitleiste bleibt leer." % issue.message)
		catalog = EventCatalog.new()
		return
	issues.append_array(CatalogValidator.validate(loaded))
	catalog = loaded.without_faulty(issues)
	# Jede Meldung der Stufe ERROR nennt Ereignis bzw. Kategorie und Grund. Fehlt das Ereignis
	# danach im Katalog, sagt die Meldung das dazu. Warnungen sind für die Werkstatt.
	for issue in issues:
		if issue.severity != CatalogIssue.Severity.ERROR:
			continue
		var text := "Zeitleiste: %s" % issue.message
		if loaded.get_event(issue.event_id) != null and catalog.get_event(issue.event_id) == null:
			text += " Das Ereignis wird übersprungen."
		push_error(text)


## Spielt den Lauf bis zum Tag der Uhr ab. GameClock meldet jeden Tag einzeln; der Lauf käme
## auch mit Sprüngen zurecht.
func _on_day_passed(date: GameDate) -> void:
	if run == null:
		return
	_send(run.advance_to(date.to_day_index()))


## Macht aus jeder Meldung das Signal laut Vertrag, in der Reihenfolge der Meldungen. Eingriffe
## stehen nur im Protokoll des Laufs und werden kein Signal.
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
			TimelineMessage.Kind.INTERVENTION:
				pass
