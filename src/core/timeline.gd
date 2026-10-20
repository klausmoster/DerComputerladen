extends Node

## Autoload `Timeline`: die Zeitleiste des Spiels (Feature 002).
##
## Noch ist sie eine stille Hülle. Beim Start liest sie den Ereigniskatalog, prüft ihn und
## behält ihn ohne die Ereignisse mit Fehlern. Abgespielt wird noch nichts: Den Lauf
## (`TimelineRun`), die Verbindung zur Spieluhr und das Senden der Signale baut T024 in Phase 3.
##
## Die Zeitleiste wendet keine Wirkung selbst an. Sie meldet nur, über die Signale unten, und
## Wirtschaft, Nachfrage und Ruf hängen sich später daran.

# Die Signale stehen schon jetzt mit ihren Typen fest, damit sich Abnehmer daran anschließen
# können. Gesendet werden sie erst mit dem Lauf (T024). Bis dahin unterdrückt
# @warning_ignore die Warnung „nie benutzt“, sonst wäre der Start mit -d nicht mehr still.

## Ein Ereignis beginnt, wie bisher.
@warning_ignore("unused_signal")
signal event_fired(event: TimelineEvent, date: GameDate)
## Eine Wirkung beginnt, wie bisher.
@warning_ignore("unused_signal")
signal effect_applied(effect: EventEffect, source: TimelineEvent, date: GameDate)
## Ein Ereignis mit Dauer endet.
@warning_ignore("unused_signal")
signal event_ended(event: TimelineEvent, date: GameDate)
## Eine Wirkung, die nur während ihres Ereignisses gilt, endet.
@warning_ignore("unused_signal")
signal effect_ended(effect: EventEffect, source: TimelineEvent, date: GameDate)
## Ein Termin entfällt: Eine Bedingung ist nicht erfüllt, das Ereignis läuft noch, oder die
## Kette ist zu lang.
@warning_ignore("unused_signal")
signal entry_skipped(entry: ScheduleEntry, date: GameDate)

const CATALOG_PATH := EventCatalog.DEFAULT_PATH

## Tests setzen einen Test-Katalog, bevor der Knoten in den Baum kommt.
var catalog_path: String = CATALOG_PATH
## Der geprüfte Katalog ohne die Ereignisse mit Fehlern; leer, wenn die Datei fehlt oder nicht
## lesbar ist.
var catalog: EventCatalog


## Liest und prüft den Katalog. Ein fehlerfreier Katalog erzeugt keine Ausgabe.
func _ready() -> void:
	var issues: Array[CatalogIssue] = []
	var loaded := EventCatalog.read_file(catalog_path, issues)
	if loaded == null:
		# FR-049: Das Spiel startet trotzdem, mit leerer Zeitleiste; die Meldung nennt Datei
		# und Grund.
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
