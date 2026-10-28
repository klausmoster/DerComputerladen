class_name SelbsttestLogger
extends Logger

## Schneidet mit, was Godot und das Spiel während eines Laufs ausgeben (Feature 007, R10;
## contracts/protokoll.md, „Ausgabe“). Angemeldet mit OS.add_logger(), bekommt er jede Zeile aus
## print() und printerr() über _log_message() und jeden Fehler und jede Warnung über
## _log_error(), zusätzlich zu Godots eigener Ausgabe.
##
## Jede Zeile bekommt die Kennung des laufenden Schritts vorangestellt, etwa
## „[neues_spiel.02_zurueck_esc] WARNING: …“; vor dem ersten Schritt „[start]“, nach dem letzten
## „[ende]“. ausgabe() gibt alles als Text für ausgabe.txt. Fehler und Warnungen merkt er sich
## zusätzlich je Schritt; meldungen() gibt sie für „meldung:“ im Protokoll. Dazu zählt alles aus
## Godot, gleich von wem (CHK007), auch printerr(). Eigene Fehler des Selbsttests kommen über
## eigener_fehler() und stehen als „[selbsttest] …“ da.
##
## Zwei Regeln aus R10:
## - Godot ruft die Methoden aus dem Thread, der etwas ausgibt, auch aus fremden Threads. Alles,
##   was sie anfassen, schützt deshalb ein Mutex.
## - Der Logger gibt selbst nichts aus. Ein print() hier riefe ihn selbst wieder auf.

## Kennung vor dem ersten Schritt.
const START := "start"
## Kennung nach dem letzten Schritt.
const ENDE := "ende"
## Kennzeichen eigener Fehler des Selbsttests (CHK007).
const EIGEN := "[selbsttest]"
## Wie Godot die Arten von Fehlern nennt, nach Logger.ErrorType.
const ART := {
	ERROR_TYPE_ERROR: "ERROR",
	ERROR_TYPE_WARNING: "WARNING",
	ERROR_TYPE_SCRIPT: "SCRIPT ERROR",
	ERROR_TYPE_SHADER: "SHADER ERROR",
}

var _mutex := Mutex.new()
var _schritt: String = START
var _zeilen := PackedStringArray()
## Kennung → PackedStringArray der Meldungen.
var _meldungen: Dictionary = {}


## Ab jetzt gehört alles zum Schritt [param kennung].
func setze_schritt(kennung: String) -> void:
	_mutex.lock()
	_schritt = kennung
	_mutex.unlock()


## Die Kennung, zu der gerade alles gehört.
func schritt() -> String:
	_mutex.lock()
	var kennung := _schritt
	_mutex.unlock()
	return kennung


## Nach dem letzten Schritt: Alles Weitere steht unter „[ende]“.
func beende() -> void:
	setze_schritt(ENDE)


## Ein eigener Fehler des Selbsttests im laufenden Schritt: „[selbsttest] [param text]“, in der
## Ausgabe und als Meldung.
func eigener_fehler(text: String) -> void:
	_merke("%s %s" % [EIGEN, text], true)


## Die Meldungen des Schritts [param kennung] in der Reihenfolge ihres Auftretens.
func meldungen(kennung: String) -> PackedStringArray:
	_mutex.lock()
	var liste: PackedStringArray = _meldungen.get(kennung, PackedStringArray()).duplicate()
	_mutex.unlock()
	return liste


## Alles, was bisher kam, als Text für ausgabe.txt, jede Zeile mit "\n".
func ausgabe() -> String:
	_mutex.lock()
	var text := "".join(_zeilen)
	_mutex.unlock()
	return text


## Von Godot für jede Ausgabe aus print() und printerr() (dann ist [param error] wahr).
func _log_message(message: String, error: bool) -> void:
	_merke(message, error)


## Von Godot für jeden Fehler und jede Warnung, auch aus push_error() und push_warning(). Die
## Ausgabe steht wie bei Godot in zwei Zeilen, Art und Text, darunter der Ort; die Meldung für
## das Protokoll in einer: „WARNING: Text · at: _ready (res://…/datei.gd:12)“.
func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	var text := rationale if not rationale.is_empty() else code
	var ort := "%s (%s:%d)" % [function, file, line]
	# Bei push_error() und push_warning() ist der Ort Godots eigene Funktion in C++; wo es im
	# Skript geschah, sagt das oberste Bild des Backtrace.
	for backtrace in script_backtraces:
		if backtrace != null and backtrace.get_frame_count() > 0:
			ort = "%s (%s:%d)" % [backtrace.get_frame_function(0), backtrace.get_frame_file(0),
				backtrace.get_frame_line(0)]
			break
	var kopf := "%s: %s" % [ART.get(error_type, "ERROR"), text]
	_mutex.lock()
	_zeile(kopf)
	_zeile("   at: " + ort)
	_meldung("%s · at: %s" % [kopf, ort])
	_mutex.unlock()


## Ein Text aus print(), printerr() oder eigener_fehler(): je Zeile eine Zeile der Ausgabe, mit
## [param ist_meldung] zusätzlich als eine Meldung des Schritts.
func _merke(text: String, ist_meldung: bool) -> void:
	# print() liefert den Text mit "\n" am Ende; der zählt nicht als eigene leere Zeile.
	var ohne_ende := text.trim_suffix("\n")
	_mutex.lock()
	for teil in ohne_ende.split("\n"):
		_zeile(teil)
	if ist_meldung:
		_meldung(ohne_ende)
	_mutex.unlock()


# Nur mit gesperrtem Mutex aufrufen.
func _zeile(text: String) -> void:
	_zeilen.append("[%s] %s\n" % [_schritt, text])


# Nur mit gesperrtem Mutex aufrufen.
func _meldung(text: String) -> void:
	if not _meldungen.has(_schritt):
		_meldungen[_schritt] = PackedStringArray()
	var liste: PackedStringArray = _meldungen[_schritt]
	liste.append(text)
	_meldungen[_schritt] = liste
