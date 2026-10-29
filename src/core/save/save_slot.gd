class_name SaveSlot
extends RefCounted

## Ein Eintrag der Liste der Spielstände (Feature 004, data-model.md, „SaveSlot“): was die Liste
## über eine Nummer weiß, auch wenn sich die Datei nicht lesen lässt. So kann die Liste einen
## beschädigten oder zu neuen Spielstand zeigen und den Grund nennen, statt ihn zu verschweigen
## (FR-013).
##
## read() liest eine Datei und prüft sie in der Reihenfolge der Tabelle „Zustand“: erst, ob sie ein
## JSON-Objekt ist, dann, ob sie aus einer neueren Version stammt; alles Weitere prüft
## SaveGame.from_data(). Der erste Treffer gilt. Welche der Dateien einer Nummer gelesen wird,
## .json, .json.neu oder .json.alt, entscheidet SaveStore.
##
## reason ist ein Satz für den Hinweis im Spiel, ohne Feldnamen, Werte aus der Datei, Godots
## englische Fehlertexte und Wörter aus dem Inneren wie Seed oder Formatversion (R10; Analyse, B4).
## Das alles steht nur im Protokoll, über push_warning() mit dem Pfad der Datei.

enum State { OK, DAMAGED, TOO_NEW }

## Grund, wenn die Datei kein gültiges JSON-Objekt ist oder sich gar nicht lesen lässt.
const REASON_UNREADABLE := "Lässt sich nicht lesen: Die Datei ist beschädigt."
## Grund, wenn „format“ eine ganze Zahl größer als SaveGame.FORMAT ist.
const REASON_TOO_NEW := "Mit einer neueren Version gespeichert."

## Die Nummer aus dem Dateinamen. Nur lesen.
var number: int = 0
## Ob sich der Spielstand fortsetzen lässt (OK) oder warum nicht. Nur lesen.
var state: State = State.DAMAGED
## Leer bei OK; sonst ein Satz für den Hinweis, höchstens zwei Zeilen (R10). Nur lesen.
var reason: String = ""
## Nur bei OK, sonst null. Nur lesen.
var game: SaveGame = null
## Die Datei, die gelesen wurde: .json, .json.neu oder .json.alt.
var path: String = ""


## Liest die Datei [param p_path] mit der Nummer [param p_number] und prüft sie (data-model.md,
## „Zustand“). Gibt nie null zurück: Eine Datei, die fehlt oder sich nicht lesen lässt, ergibt
## DAMAGED mit Grund. Jeder Grund außer OK kommt zusätzlich mit Pfad, Feld und Stelle ins
## Protokoll, etwa „Spielstand user://spielstaende/spiel_3.json: Schwierigkeitsgrad „extrem“.“
static func read(p_path: String, p_number: int) -> SaveSlot:
	var slot := SaveSlot.new()
	slot.number = p_number
	slot.path = p_path
	# Ohne diese Prüfung meldete get_file_as_string() einen Fehler der Engine.
	if not FileAccess.file_exists(p_path):
		return slot._fail(State.DAMAGED, REASON_UNREADABLE, "Die Datei fehlt.")
	var text := FileAccess.get_file_as_string(p_path)
	var error := FileAccess.get_open_error()
	if error != OK:
		return slot._fail(State.DAMAGED, REASON_UNREADABLE,
			"Die Datei lässt sich nicht öffnen: %s." % error_string(error))
	var json := JSON.new()
	if json.parse(text) != OK:
		# get_error_line() zählt ab 0, Texteditoren zählen ab 1. Godots Text endet ohne Punkt.
		return slot._fail(State.DAMAGED, REASON_UNREADABLE, "kein gültiges JSON in Zeile %d: %s."
			% [json.get_error_line() + 1, json.get_error_message()])
	if typeof(json.data) != TYPE_DICTIONARY:
		return slot._fail(State.DAMAGED, REASON_UNREADABLE, "Die Datei enthält kein Objekt { … }.")
	var data: Dictionary = json.data
	# Zu neu geht vor allem anderen: In einer neueren Version können alle übrigen Schlüssel anders
	# aussehen, und beschädigt ist die Datei deshalb nicht.
	var format: Variant = data.get("format")
	if InterventionFile.is_whole_number(format) and format > SaveGame.FORMAT:
		return slot._fail(State.TOO_NEW, REASON_TOO_NEW,
			"Formatversion %d, diese Version liest höchstens %d." % [int(format), SaveGame.FORMAT])
	var problems: Array[String] = []
	var details: Array[String] = []
	var read_game := SaveGame.from_data(data, p_number, problems, details)
	if read_game == null:
		return slot._fail(State.DAMAGED, problems[0], details[0])
	slot.state = State.OK
	slot.game = read_game
	return slot


## Ob sich der Spielstand fortsetzen lässt.
func can_resume() -> bool:
	return state == State.OK


## Der Name in der Liste: game.name bei OK, sonst „Spiel N“. Ein Name aus einer Datei, die nicht
## stimmt, wäre ungeprüft.
func display_name() -> String:
	if state == State.OK and game != null:
		return game.name
	return SaveGame.default_name(number)


## Setzt Zustand und Grund, meldet [param detail] mit dem Pfad im Protokoll und gibt sich selbst
## zurück, damit read() in einer Zeile aufhören kann.
func _fail(p_state: State, p_reason: String, detail: String) -> SaveSlot:
	state = p_state
	reason = p_reason
	game = null
	push_warning("Spielstand %s: %s" % [path, detail])
	return self
