class_name SaveStore
extends RefCounted

## Der Ordner der Spielstände (Feature 004, data-model.md, „SaveStore“; research.md, R3 und R4):
## auflisten, die nächste Nummer finden, sicher schreiben und löschen. Tests geben einen eigenen
## Ordner vor, das Spiel nimmt FOLDER.
##
## Zu einem Spielstand gehören nur Dateien nach dem Muster spiel_<N>.json, spiel_<N>.json.neu und
## spiel_<N>.json.alt, N eine Zahl ohne führende Null von 1 bis MAX_NUMBER. Alles andere im Ordner,
## etwa notizen.txt oder spiel_02.json, wird nie gelistet, nie mitgezählt und nie gelöscht.
##
## Geschrieben wird in fünf Schritten über .neu und .alt (R3), damit ein Abbruch an jeder Stelle
## einen lesbaren Stand hinterlässt; welcher dann gilt, regelt die Leseregel in list_slots(). Das
## Spiel überschreibt so nie einen beschädigten oder zu neuen Spielstand: Fortsetzen lässt sich nur
## ein fortsetzbarer, und ein neues Spiel nimmt nur eine Nummer ohne Dateien (FR-013, R4).
##
## last_error ist für das Protokoll und nennt Datei und Schritt, auch mit Godots englischem
## Fehlertext. Den Satz für den Spieler wählt GameSession (spielablauf.md).

const FOLDER := "user://spielstaende/"
## Die größte Nummer: neun Stellen, wie das Muster sie zulässt.
const MAX_NUMBER := 999999999
## Die Endungen einer Nummer, in der Reihenfolge, in der delete() sie löscht.
const SUFFIXES: Array[String] = ["", ".neu", ".alt"]

var folder: String = FOLDER
var last_error: String = ""


func _init(p_folder: String = FOLDER) -> void:
	folder = p_folder


## Alle Spielstände im Ordner, je Nummer einer, geordnet nach R12: erst die fortsetzbaren nach
## „zuletzt gespielt“, das jüngste oben, bei Gleichstand die höhere Nummer zuerst; darunter die
## übrigen nach Nummer absteigend. Fehlt der Ordner, ist die Liste leer.
##
## Welche Datei einer Nummer gilt, regelt R3, „Lesen“ (Analyse, B2):
## - spiel_N.json, wenn sie fortsetzbar oder zu neu ist. Ein zu neuer Spielstand fällt nie auf eine
##   ältere Zwischendatei zurück, sonst überschriebe das nächste Speichern den neueren Stand.
## - sonst die erste fortsetzbare von .neu und .alt, wie nach einem Abbruch in Schritt 3 bis 5;
## - sonst der Zustand von spiel_N.json, ohne sie der von .alt.
## Eine allein stehende .neu, die nicht fortsetzbar ist, ergibt keinen Spielstand: Das erste
## Speichern eines neuen Spiels ist gescheitert, einen Spielstand gab es nie. Gilt .neu oder .alt,
## meldet push_warning() das mit dem Pfad; der Spieler sieht nichts Besonderes (CHK021).
func list_slots() -> Array[SaveSlot]:
	var slots: Array[SaveSlot] = []
	# Nur Dateien: Ein Ordner mit dem Namen einer Datei ist keine Datei eines Spielstands.
	var names := _names_by_number(false)
	for number: int in names:
		var slot := _slot_of(number, names[number])
		if slot != null:
			slots.append(slot)
	slots.sort_custom(_comes_before)
	return slots


## Größte Nummer unter den Dateien eines Spielstands plus 1, auch unter beschädigten, zu neuen und
## übrig gebliebenen .neu und .alt; ohne solche Dateien 1 (R4). Ein Ordner mit dem Namen einer
## solchen Datei zählt mit, denn write() mit is_new weicht auch ihm aus.
func next_number() -> int:
	var largest := 0
	for number: int in _names_by_number(true):
		largest = maxi(largest, number)
	return largest + 1


## Schreibt [param game] unter seiner Nummer in fünf Schritten (R3):
## 1. eine übrig gebliebene .neu löschen, den Text von game.to_json() nach .neu schreiben;
## 2. .neu wieder lesen; der Text muss Zeichen für Zeichen gleich sein, sonst Abbruch;
## 3. eine übrig gebliebene .alt löschen, den alten Stand spiel_N.json in .alt umbenennen;
## 4. .neu in spiel_N.json umbenennen;
## 5. .alt löschen.
## Fehlt der Ordner, legt es ihn an. Gibt OK oder den Fehler des Schritts zurück, der scheiterte;
## dann ist der vorige Stand lesbar, und last_error nennt Datei und Schritt.
##
## Mit [param is_new] true, für ein neues Spiel, schreibt es nur, wenn es zu game.number noch keine
## Datei gibt, auch keine .neu oder .alt; sonst ERR_ALREADY_EXISTS, und GameSession versucht es mit
## der nächsten Nummer (CHK002). Schritt 5 ist Aufräumen: Scheitert er, steht der neue Stand
## schon in spiel_N.json. Dann gibt es OK und nur eine Warnung im Protokoll; die .alt räumt das
## nächste Speichern in Schritt 3 ab.
func write(game: SaveGame, is_new: bool = false) -> Error:
	last_error = ""
	if game == null or game.number < 1 or game.number > MAX_NUMBER:
		last_error = "Speichern: Ein Spielstand ohne gültige Nummer lässt sich nicht schreiben."
		return ERR_INVALID_PARAMETER
	if not DirAccess.dir_exists_absolute(folder):
		var made := DirAccess.make_dir_recursive_absolute(folder)
		if made != OK:
			last_error = "Speichern: Der Ordner %s lässt sich nicht anlegen (%s)." % [folder,
				error_string(made)]
			return made
	var target := path_of(game.number)
	var fresh := target + ".neu"
	var old := target + ".alt"
	if is_new:
		# Den Pfad, der wirklich da ist, auch wenn es nur eine .neu, eine .alt oder ein Ordner ist.
		var present := _first_present(game.number)
		if not present.is_empty():
			last_error = "Speichern: Zur Nummer %d gibt es schon eine Datei, etwa %s." % [
				game.number, present]
			return ERR_ALREADY_EXISTS
	var text := game.to_json()

	# Schritt 1
	var error := _remove_if_present(fresh)
	if error != OK:
		return _fail(error, "Schritt 1: Die übrig gebliebene Datei %s lässt sich nicht löschen"
			% fresh)
	error = _store_text(fresh, text)
	if error != OK:
		return _fail(error, "Schritt 1: Die Datei %s lässt sich nicht schreiben" % fresh)
	# Schritt 2
	var written := FileAccess.get_file_as_string(fresh)
	error = FileAccess.get_open_error()
	if error != OK:
		return _fail(error, "Schritt 2: Die Datei %s lässt sich nicht wieder lesen" % fresh)
	if written != text:
		return _fail(ERR_FILE_CORRUPT,
			"Schritt 2: Die Datei %s stimmt nach dem Schreiben nicht mit dem Spielstand überein"
			% fresh)
	# Schritt 3
	error = _remove_if_present(old)
	if error != OK:
		return _fail(error, "Schritt 3: Die übrig gebliebene Datei %s lässt sich nicht löschen"
			% old)
	# Nur eine Datei wandert nach .alt. Liegt dort ein Ordner, scheitert Schritt 4, und .neu bleibt
	# als lesbarer Stand.
	if FileAccess.file_exists(target):
		error = DirAccess.rename_absolute(target, old)
		if error != OK:
			return _fail(error, "Schritt 3: Die Datei %s lässt sich nicht in %s umbenennen"
				% [target, old])
	# Schritt 4
	error = DirAccess.rename_absolute(fresh, target)
	if error != OK:
		return _fail(error, "Schritt 4: Die Datei %s lässt sich nicht in %s umbenennen"
			% [fresh, target])
	# Schritt 5
	error = _remove_if_present(old)
	if error != OK:
		push_warning(("Speichern: Schritt 5: Die Datei %s lässt sich nicht löschen (%s). Der "
			+ "Spielstand ist gespeichert; das nächste Speichern räumt sie ab.") % [old,
			error_string(error)])
	return OK


## Löscht spiel_<N>.json, .neu und .alt der Nummer [param p_number], in dieser Reihenfolge, sonst
## nichts (FR-018). Scheitert eine, hört es dort auf, gibt den Fehler zurück, und last_error nennt
## die Datei; die übrigen bleiben, so ist der Spielstand noch lesbar. Fehlt alles,
## ERR_FILE_NOT_FOUND.
##
## Wie beim Schreiben zählt auch ein Ordner mit dem Namen einer der drei Dateien: Ein leerer lässt
## sich löschen, einer mit Inhalt nicht, dann scheitert das Löschen (R16; Analyse, E2).
func delete(p_number: int) -> Error:
	last_error = ""
	if p_number < 1 or p_number > MAX_NUMBER:
		last_error = "Löschen: Die Nummer %d gehört zu keinem Spielstand." % p_number
		return ERR_INVALID_PARAMETER
	if not _has_any(p_number):
		last_error = "Löschen: Zur Nummer %d gibt es keine Datei in %s." % [p_number, folder]
		return ERR_FILE_NOT_FOUND
	for suffix in SUFFIXES:
		var path := path_of(p_number) + suffix
		var error := _remove_if_present(path)
		if error != OK:
			last_error = "Löschen: Die Datei %s lässt sich nicht löschen (%s)." % [path,
				error_string(error)]
			return error
	return OK


## Pfad der Datei zu einer Nummer, etwa „user://spielstaende/spiel_2.json“.
func path_of(p_number: int) -> String:
	return folder.path_join("spiel_%d.json" % p_number)


## Schreibt [param text] nach [param path] und schließt die Datei. Eine eigene Methode, damit ein
## Test hier einen Datenträger nachstellen kann, der anderes speichert als verlangt (Schritt 2).
func _store_text(path: String, text: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var stored := file.store_string(text)
	file.close()
	return OK if stored else ERR_FILE_CANT_WRITE


## Der Spielstand einer Nummer nach der Leseregel (siehe list_slots()); null, wenn es keinen gibt.
## [param present] sind die Endungen, zu denen es eine Datei gibt.
func _slot_of(number: int, present: Dictionary) -> SaveSlot:
	var main: SaveSlot = null
	if present.has(""):
		main = SaveSlot.read(path_of(number), number)
		if main.state != SaveSlot.State.DAMAGED:
			return main
	var spare: SaveSlot = null
	for suffix: String in [".neu", ".alt"]:
		if not present.has(suffix):
			continue
		var slot := SaveSlot.read(path_of(number) + suffix, number)
		if slot.can_resume():
			_warn_spare(slot)
			return slot
		if suffix == ".alt":
			spare = slot
	if main != null:
		return main
	if spare != null:
		_warn_spare(spare)
	return spare


## Meldet im Protokoll, dass für einen Spielstand eine Zwischendatei gilt (CHK021).
func _warn_spare(slot: SaveSlot) -> void:
	push_warning("Spielstand %d: gelesen aus %s, denn %s fehlt oder ist beschädigt." % [
		slot.number, slot.path, path_of(slot.number)])


## Nummer → { Endung: true } für die Namen im Ordner nach dem Muster, Endung "", ".neu" oder
## ".alt". Mit [param with_folders] zählen auch Ordner mit einem solchen Namen. Fehlt der Ordner,
## leer.
func _names_by_number(with_folders: bool) -> Dictionary:
	var result := {}
	if not DirAccess.dir_exists_absolute(folder):
		return result
	var names := Array(DirAccess.get_files_at(folder))
	if with_folders:
		names.append_array(DirAccess.get_directories_at(folder))
	# Eine Zahl ohne führende Null, höchstens neun Stellen; dahinter .json, .json.neu oder
	# .json.alt.
	var pattern := RegEx.create_from_string("^spiel_([1-9][0-9]{0,8})\\.json(\\.neu|\\.alt)?$")
	for file_name: String in names:
		var found := pattern.search(file_name)
		if found == null:
			continue
		var number := found.get_string(1).to_int()
		if not result.has(number):
			result[number] = {}
		result[number][found.get_string(2)] = true
	return result


## Ob es zur Nummer eine der drei Dateien gibt, auch als Ordner.
func _has_any(p_number: int) -> bool:
	return not _first_present(p_number).is_empty()


## Der Pfad der ersten der drei Dateien zur Nummer, die es gibt, auch als Ordner, in der
## Reihenfolge von SUFFIXES; leer, wenn es keine gibt. So nennt das Protokoll die Datei, die
## wirklich da ist, etwa nur eine übrig gebliebene .neu.
func _first_present(p_number: int) -> String:
	for suffix in SUFFIXES:
		var path := path_of(p_number) + suffix
		if _is_present(path):
			return path
	return ""


## Löscht, was unter [param path] liegt, eine Datei oder einen leeren Ordner; OK, wenn dort nichts
## liegt. Ein Ordner mit Inhalt lässt sich nicht löschen, dann kommt der Fehler zurück (R3).
static func _remove_if_present(path: String) -> Error:
	if not _is_present(path):
		return OK
	return DirAccess.remove_absolute(path)


## Ob unter [param path] eine Datei oder ein Ordner liegt. FileAccess.file_exists() sieht nur
## Dateien.
static func _is_present(path: String) -> bool:
	return FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path)


## Setzt last_error auf „<was>, Fehler“ und gibt [param error] zurück.
func _fail(error: Error, what: String) -> Error:
	last_error = "Speichern: %s (%s)." % [what, error_string(error)]
	return error


## Ordnung der Liste nach R12.
static func _comes_before(a: SaveSlot, b: SaveSlot) -> bool:
	if a.can_resume() != b.can_resume():
		return a.can_resume()
	if a.can_resume() and a.game.last_played_at != b.game.last_played_at:
		return a.game.last_played_at > b.game.last_played_at
	return a.number > b.number
