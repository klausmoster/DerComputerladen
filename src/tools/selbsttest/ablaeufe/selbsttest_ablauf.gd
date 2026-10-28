class_name SelbsttestAblauf
extends RefCounted

## Ein Ablauf des Selbsttests (Feature 007, contracts/selbsttest-app.md, „Ablauf“;
## data-model.md, „Ablauf“): eine feste Folge von Schritten durch das Spiel, etwa „Neues Spiel“.
## Jeder Ablauf ist ein eigenes Skript, das von dieser Klasse erbt und schritte() überschreibt;
## welche es gibt und was sie tun, steht in contracts/ablaeufe.md.
##
## Ein Ablauf ist kein Node. Er beschreibt nur, was geschehen soll; ausführen tut es der Läufer,
## und SelbsttestLauf hält die Ergebnisse fest. So lässt sich ein Ablauf auch ohne Fenster ansehen,
## etwa im Test.
##
## Ein Schritt ist ein Dictionary mit den Schlüsseln aus dem Vertrag:
## kennung, beschreibung, eingaben (Callable, mit await aufrufbar), erwartet (Callable, gibt ""
## zurück, wenn der Zustand stimmt, sonst den gefundenen Zustand als Text), erwartet_text,
## hoechstzeit_ms und foto_vergleichbar. neuer_schritt() baut es mit den Vorgaben.

## Faktor für Engine.time_scale in Abläufen im Zeitraffer (R24).
const ZEITRAFFER := 8
## Millisekunden echter Zeit, bis ein Schritt mit „Zeit abgelaufen“ scheitert (R6).
const HOECHSTZEIT_MS := 5000

## Kurz, klein, ohne Leerzeichen, etwa „neues_spiel“; Anfang jeder Schritt-Kennung.
var kennung: String = ""
## Für Menschen, etwa „Spiel laden“; die Wortlaute stehen in SelbsttestTexte.ABLAUF_NAMEN.
var name: String = ""
## Leer, oder die Kennung des Ablaufs, dessen Ende dieser voraussetzt, etwa „neues_spiel“ für
## „laden“. Ist jener gescheitert, gilt dieser ganz als nicht gelaufen (FR-009).
var baut_auf: String = ""
## Faktor für die Zeit im Spiel; 1 für „titel_echtzeit“ und „fenster“ (data-model.md, R24).
var zeitraffer: int = ZEITRAFFER


## Die Schritte in fester Reihenfolge. Die Basisklasse hat keine; jeder Ablauf überschreibt das.
## [param _fahrer] ist der SelbsttestFahrer, über den die Schritte Ziele finden und Zustände lesen.
## Den Fahrer gibt es erst ab Phase 2 (T013); bis dahin ist der Typ RefCounted, die Oberklasse
## des Fahrers.
func schritte(_fahrer: RefCounted) -> Array[Dictionary]:
	return []


## Ein Schritt mit der Kennung „<ablauf>.<nn_kurz>“, etwa aus „01_gradwahl“ in „neues_spiel“
## „neues_spiel.01_gradwahl“, und den Vorgaben für Höchstzeit und Foto.
func neuer_schritt(nn_kurz: String, beschreibung: String, eingaben: Callable,
		erwartet: Callable, erwartet_text: String, foto_vergleichbar: bool = true,
		hoechstzeit_ms: int = HOECHSTZEIT_MS) -> Dictionary:
	return {
		"kennung": "%s.%s" % [kennung, nn_kurz],
		"beschreibung": beschreibung,
		"eingaben": eingaben,
		"erwartet": erwartet,
		"erwartet_text": erwartet_text,
		"hoechstzeit_ms": hoechstzeit_ms,
		"foto_vergleichbar": foto_vergleichbar,
	}
