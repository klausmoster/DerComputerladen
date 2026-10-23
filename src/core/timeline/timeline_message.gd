class_name TimelineMessage
extends RefCounted

## Eine Meldung der Zeitleiste (data-model.md, „TimelineMessage“): was an einem Tag geschieht,
## etwa der Beginn eines Ereignisses oder eine fällige Wirkung.
##
## Der Lauf (TimelineRun) gibt die Meldungen jedes Aufrufs als Liste zurück und sammelt alle im
## Protokoll. Das Autoload Timeline macht daraus Signale, die Werkstatt und die Textausgabe
## zeigen sie als Zeile. Eingriffe und Start-Modifikatoren stehen nur im Protokoll; sie kommen in
## keiner Rückgabe vor und werden kein Signal.

enum Kind {
	EVENT_STARTED,   ## ein Termin beginnt
	EVENT_ENDED,     ## ein Termin mit Dauer endet
	EFFECT_STARTED,  ## eine Wirkung beginnt, sofort oder verzögert
	EFFECT_ENDED,    ## eine Wirkung, die nur während des Ereignisses gilt, endet
	ENTRY_SKIPPED,   ## ein Termin entfällt, etwa weil eine Bedingung nicht erfüllt ist
	CHAIN_STOPPED,   ## ein Termin entfällt, weil seine Kette am selben Tag zu lang ist (R10)
	INTERVENTION,    ## ein Eingriff, etwa eine Absage
	START_MODIFIER,  ## ein Start-Modifikator des Grads gilt ab Spielbeginn (Feature 003, R6)
}

## Spalte „Art“ der Protokollzeile, in der Reihenfolge von Kind. Neue Arten kommen ans Ende, damit
## die übrigen ihre Nummern behalten.
const KIND_LABELS: Array[String] = [
	"Beginn", "Ende", "Wirkung", "Wirkungsende", "Entfall", "Kettenabbruch", "Eingriff", "Grad",
]

## Tag der Meldung als Tagesindex.
var day: int = 0
var kind: Kind = Kind.EVENT_STARTED
## Betroffenes Ereignis, falls vorhanden.
var event: TimelineEvent
## Bei Wirkungsmeldungen die Wirkung.
var effect: EventEffect
## Betroffener Termin, falls vorhanden.
var entry: ScheduleEntry
## Was geschah, als deutscher Text ohne Datum und Art: der Titel des Ereignisses, bei Wirkungen
## dahinter die Wirkung, bei Entfall und Kettenabbruch der Grund. Den Text setzt der Lauf.
var text: String = ""


## Die Zeile fürs Protokoll, „TT.MM.JJJJ  <Art>  <Text>“, etwa
## „22.03.1993  Beginn  Intel Pentium erscheint“ oder
## „22.03.1993  Wirkung  Intel Pentium erscheint: Preis · cpu_486 · -30% — …“.
##
## Sie entsteht nur aus Tag, Art und Text. Gleiche Meldungen ergeben deshalb immer dieselbe
## Zeile, und zwei Läufe lassen sich Zeile für Zeile vergleichen (SC-002).
func to_line() -> String:
	return "%s  %s  %s" % [GameDate.from_day_index(day), KIND_LABELS[kind], text]
