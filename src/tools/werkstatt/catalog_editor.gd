class_name CatalogEditor
extends RefCounted

## Bearbeitet den Ereigniskatalog für die Werkstatt, ohne eigene Oberfläche (contracts/werkstatt.md,
## „CatalogEditor“; research.md, R15 und R23). Liste, Formular und Zeitstrahl ändern den Katalog
## nie selbst, sie rufen diese Methoden. Jede ändernde Methode ist genau ein Schritt im Verlauf,
## den Cmd+Z zurücknimmt, mit einem Namen wie „Datum von Intel Pentium erscheint“.
##
## Der Verlauf ist ein UndoRedo. Ein Schritt hält nur die Ereignisse oder Kategorien, die er
## betrifft, vorher und nachher, nie den ganzen Katalog. Dafür wird ein Ereignis nicht an Ort und
## Stelle geändert: Eine Kopie mit dem neuen Wert ersetzt es, und das alte Objekt bleibt
## unverändert im Verlauf liegen, bis Rückgängig es wieder einsetzt. Wer ein Ereignis braucht,
## holt es deshalb nach jeder Änderung neu über seine Kennung.
##
## Nach jeder Änderung prüft der Editor den ganzen Katalog neu und meldet catalog_changed und
## issues_changed, erst wenn UndoRedo fertig ist; is_dirty() stimmt dann schon. Wer darauf hört,
## zeichnet neu und ändert den Katalog dabei nicht.

signal catalog_changed()
signal issues_changed(issues: Array[CatalogIssue])

## Format der Sicherungskopie (research.md, R23).
const BACKUP_FORMAT := 1
## Die zehn Kategorien der Übernahme mit ihren Startfarben aus dem Style-Guide, Abschnitt
## „Werkzeuge“: Kennung, Name, Farbe.
const START_CATEGORIES := [
	["hardware", "Hardware", &"nacht-hell"],
	["software", "Software", &"petrol"],
	["tech", "Tech", &"nacht"],
	["wirtschaft", "Wirtschaft", &"kassenrot"],
	["lokal", "Lokal", &"holz-dunkel"],
	["konkurrenz", "Konkurrenz", &"gehaeuse-dunkel"],
	["kunde", "Kunde", &"holz"],
	["reklamation", "Reklamation", &"nacht-hell"],
	["lieferung", "Lieferung", &"petrol"],
	["kalender", "Kalender", &"nacht"],
]
## Was suggest_id() umschreibt, bevor alles außer a–z und 0–9 zum Trenner wird.
const UMLAUTS := [["ä", "ae"], ["ö", "oe"], ["ü", "ue"], ["ß", "ss"]]
## Die Felder, die set_event_field() ändert, mit ihrem Namen im Verlauf. Die Kennung ändert
## rename_event(), weil die Verweise mitwandern, die Art set_event_kind(), weil andere Felder
## gelten, die Listen add_item() und die anderen Methoden für Listen.
const EVENT_FIELDS := {
	&"title": "Titel",
	&"description": "Beschreibung",
	&"category": "Kategorie",
	&"date": "Datum",
	&"duration_days": "Dauer",
	&"yearly_from": "erstes Jahr",
	&"yearly_to": "letztes Jahr",
	&"yearly_start": "Beginn im Jahr",
	&"yearly_end": "Ende im Jahr",
	&"window_from": "Beginn des Zeitfensters",
	&"window_to": "Ende des Zeitfensters",
	&"min_gap_days": "Mindestabstand",
	&"count_min": "Anzahl",
	&"count_weights": "Gewichte",
	&"monthly_chance": "Grundchance",
	&"max_occurrences": "Höchstzahl",
}
## Die Felder jeder Art, wie TimelineEvent.KIND_KEYS, aber mit den Namen der Felder im Code.
## set_event_kind() behält, was beide Arten haben.
const KIND_FIELDS := {
	TimelineEvent.Kind.FIXED: [&"date", &"duration_days"],
	TimelineEvent.Kind.YEARLY: [&"yearly_from", &"yearly_to", &"yearly_start", &"yearly_end"],
	TimelineEvent.Kind.PRESET: [
		&"window_from", &"window_to", &"min_gap_days", &"count_min", &"count_weights",
		&"duration_days", &"conditions",
	],
	TimelineEvent.Kind.CHANCE: [
		&"window_from", &"window_to", &"min_gap_days", &"monthly_chance", &"max_occurrences",
		&"duration_days", &"conditions",
	],
	TimelineEvent.Kind.FOLLOW_ONLY: [&"duration_days", &"conditions"],
}
## Die Listen im Ereignis: wie ein Eintrag heißt, im Nominativ und im Genitiv, und seine Felder
## mit ihrem Namen im Verlauf.
const LISTS := {
	&"effects": {
		"item": "Wirkung",
		"of": "der Wirkung",
		"fields": {
			&"kind": "Art", &"target": "Ziel", &"magnitude": "Stärke",
			&"delay_days": "Verzögerung", &"scope": "Geltung", &"note": "Notiz",
		},
	},
	&"follow_ups": {
		"item": "Folgeereignis",
		"of": "des Folgeereignisses",
		"fields": {
			&"target": "Ziel", &"chance": "Wahrscheinlichkeit",
			&"delay_min": "kürzeste Verzögerung", &"delay_max": "längste Verzögerung",
		},
	},
	&"conditions": {
		"item": "Bedingung",
		"of": "der Bedingung",
		"fields": {&"event": "Ereignis", &"occurred": "Zustand"},
	},
}

var catalog: EventCatalog
var path: String = ""
## Deutscher Text des letzten Fehlers beim Öffnen oder Speichern.
var last_error: String = ""
## Ordner der Sicherungskopien (FR-050, R23), unter user:// und damit außerhalb des Projekts. Jeder
## Katalog hat darin seine eigene Datei, backup_path(); so blockiert die Kopie des einen nie die
## Sicherung des anderen. Tests setzen einen eigenen Ordner.
var backup_folder: String = "user://werkstatt_sicherungen/"

## Der Verlauf. UndoRedo erbt von Object, nicht von RefCounted, und muss deshalb von Hand
## freigegeben werden (_notification()).
var _undo_redo := UndoRedo.new()
## get_version() beim letzten Öffnen oder Speichern. -1 heißt: Diesen Stand gibt es in keiner
## Datei, etwa nach new_catalog().
var _saved_version := 0
## Meldungen beim Lesen (V22); sie bleiben bis zum nächsten erfolgreichen save() stehen.
var _read_issues: Array[CatalogIssue] = []
## Die letzte Prüfung des ganzen Katalogs.
var _check_issues: Array[CatalogIssue] = []
## Die Datei unter path beim Öffnen oder letzten Speichern: ob es sie gab, ihre Änderungszeit und
## ein Hash ihres Inhalts. Daran erkennt save() eine fremde Änderung.
var _file_existed := false
var _file_time := 0
var _file_hash := ""
## Ob die Datei beim Öffnen kein lesbarer Katalog war.
var _file_unreadable := false
## Kategorie oder Ereignis → sein Text für content_key(), für die Objekte, die beim letzten Aufruf
## im Katalog standen.
var _texts := {}


func _init() -> void:
	_saved_version = _undo_redo.get_version()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_undo_redo.free()


# --- Datei -------------------------------------------------------------------------------------

## Öffnet eine Katalogdatei. Bei einem Parse-Fehler bleibt der bisherige Katalog, last_error
## nennt Zeile und Grund; die Datei wird nicht angefasst (Edge Case „Katalog unlesbar“).
##
## [member path] zeigt danach immer auf [param p_path]. Fehlt die Datei, legt new_catalog() den
## leeren Katalog an, und save() schreibt ihn dorthin. Ist sie unlesbar, gibt save() ohne force
## ERR_FILE_ALREADY_IN_USE, damit sie nur auf ausdrücklichen Wunsch überschrieben wird.
##
## Ergebnis: OK, ERR_FILE_NOT_FOUND, wenn die Datei fehlt, oder ERR_PARSE_ERROR, wenn sie kein
## lesbarer Katalog ist. Erst bei OK leert sich der Verlauf.
func open(p_path: String) -> Error:
	path = p_path
	var found: Array[CatalogIssue] = []
	var loaded := EventCatalog.read_file(p_path, found)
	_remember_file()
	if loaded == null:
		var reasons := PackedStringArray()
		for issue in found:
			reasons.append(issue.message)
		last_error = " ".join(reasons)
		_file_unreadable = _file_existed
		# Der bisherige Katalog steht in keiner Datei unter dem neuen Pfad.
		if catalog != null:
			_saved_version = -1
		return ERR_PARSE_ERROR if _file_existed else ERR_FILE_NOT_FOUND
	_file_unreadable = false
	last_error = ""
	_read_issues = found
	_use_catalog(loaded, true)
	return OK


## Schreibt kanonisch nach path. Ohne force gibt es ERR_FILE_ALREADY_IN_USE, wenn die Datei seit
## dem Öffnen von außen geändert wurde oder beim Öffnen unlesbar war. Die Werkstatt fragt dann
## nach und speichert erst auf ausdrücklichen Wunsch mit force = true. Fehler im Katalog halten
## save() nicht auf; ob trotzdem gespeichert wird, fragt die Werkstatt vorher über has_errors().
##
## Der Verlauf überlebt das Speichern. Die Meldungen beim Lesen sind danach erledigt: Was die Datei
## nicht lesen ließ, steht nicht mehr in ihr. Die Sicherungskopie löscht die Werkstatt danach mit
## discard_backup().
func save(force: bool = false) -> Error:
	if catalog == null:
		last_error = "Es gibt keinen Katalog zum Speichern."
		return ERR_UNCONFIGURED
	if not force and _file_unreadable:
		last_error = ("Die Katalogdatei %s war beim Öffnen nicht lesbar; Speichern würde sie "
			+ "überschreiben.") % path
		return ERR_FILE_ALREADY_IN_USE
	if not force and _changed_outside():
		last_error = "Die Katalogdatei %s wurde geändert, seit die Werkstatt sie gelesen hat." \
			% path
		return ERR_FILE_ALREADY_IN_USE
	var error := catalog.write_file(path)
	if error != OK:
		last_error = "Die Katalogdatei %s lässt sich nicht schreiben: %s." % [path,
			error_string(error)]
		return error
	_remember_file()
	_file_unreadable = false
	_saved_version = _undo_redo.get_version()
	_read_issues.clear()
	last_error = ""
	issues_changed.emit(issues())
	return OK


## Liest path neu, leert den Verlauf und löscht die Sicherungskopie (FR-034, Verwerfen). Lässt sich
## die Datei nicht mehr lesen, bleibt alles, wie es war, auch die Kopie; den Grund nennt
## last_error.
func revert() -> Error:
	var error := open(path)
	if error == OK:
		discard_backup()
	return error


## Leerer Katalog mit den zehn Kategorien der Übernahme, ungespeichert (Edge Case „keine Datei“).
## path bleibt, wie open() ihn gesetzt hat.
func new_catalog() -> void:
	var fresh := EventCatalog.new()
	for entry: Array in START_CATEGORIES:
		var category := EventCategory.new()
		category.id = entry[0]
		category.name = entry[1]
		category.color = entry[2]
		fresh.categories.append(category)
	_read_issues.clear()
	_use_catalog(fresh, false)


## Ob es Änderungen gibt, die in keiner Datei stehen: Die Version des Verlaufs ist eine andere als
## beim letzten Öffnen oder Speichern (research.md, R15). Ein Katalog aus new_catalog() oder
## restore_backup() gilt bis zum Speichern als ungespeichert.
func is_dirty() -> bool:
	return _undo_redo.get_version() != _saved_version


## Meldungen beim Lesen (V22) und die letzte Prüfung, nach jeder Änderung neu. Die Meldungen
## beim Lesen bleiben bis zum nächsten erfolgreichen save() stehen (ereigniskatalog.md, Regel 5).
func issues() -> Array[CatalogIssue]:
	var result: Array[CatalogIssue] = _read_issues.duplicate()
	result.append_array(_check_issues)
	return result


func has_errors() -> bool:
	return CatalogValidator.has_errors(issues())


## Der Inhalt des Katalogs als Text, zum Vergleichen: Zwei Stände ergeben genau dann denselben
## Text, wenn to_json() für beide denselben ergäbe. Simulator und Statistik erkennen daran, ob ein
## neuer Lauf mit einem anderen Katalog rechnen würde (FR-042), auch nach Rückgängig wieder mit
## demselben. Leer ohne Katalog.
##
## Schneller als to_json(), weil der Editor ein Ereignis nie an Ort und Stelle ändert, sondern
## durch eine Kopie ersetzt (siehe oben). Der Text eines Objekts gilt deshalb, solange es im
## Katalog steht; nach einer Änderung entsteht er nur für die neuen Objekte. Mit 500 Ereignissen
## sind das statt 14 ms für to_json() Bruchteile einer Millisekunde. Die Ereignisse stehen nach
## Kennung sortiert im Katalog wie in der Datei: Lesen sortiert sie, und jeder Schritt setzt sie
## an ihre Stelle.
func content_key() -> String:
	if catalog == null:
		return ""
	var texts := {}
	var parts := PackedStringArray()
	for category in catalog.categories:
		parts.append(_text_of(category, texts))
	# Eine leere Zeile trennt die Kategorien von den Ereignissen.
	parts.append("")
	for event in catalog.events:
		parts.append(_text_of(event, texts))
	# Nur die Objekte von jetzt behalten; ersetzte fallen aus dem Zwischenspeicher.
	_texts = texts
	return "\n".join(parts)


# --- Sicherungskopie ---------------------------------------------------------------------------
#
# Je Katalog eine Datei im backup_folder, benannt nach seinem Pfad (backup_name()): Der echte
# Katalog und catalog_500.json haben also zwei Kopien, und keine stört die andere. Alle Methoden
# hier meinen die Datei des geöffneten Katalogs, backup_path(). Darin steht wie bisher auch der
# Pfad des Katalogs; eine Datei, die nicht lesbar ist oder zu einem anderen Pfad gehört, bietet die
# Werkstatt nicht an, und die nächste Sicherung ersetzt sie.


## Die Sicherungsdatei des geöffneten Katalogs: backup_folder und backup_name(path).
func backup_path() -> String:
	return backup_folder.path_join(backup_name(path))


## Der Name der Sicherungsdatei für den Katalog unter [param catalog_path]: der Dateiname des
## Katalogs als Kennung, dazu die ersten zwölf Zeichen des SHA-256 seines Pfads nach
## normalized_path(), etwa event_catalog_6d0c5a1e8b2f.json. Derselbe Katalog hat so immer
## denselben Namen, auch wenn sein Pfad einmal als res://… und einmal absolut kommt; zwei
## verschiedene Kataloge haben nie denselben, auch zwei event_catalog.json in zwei Ordnern nicht.
static func backup_name(catalog_path: String) -> String:
	var normal := normalized_path(catalog_path)
	var base := id_from(normal.get_file().get_basename(), "katalog")
	return "%s_%s.json" % [base, normal.sha256_text().left(12)]


## [param p_path] als absoluter Pfad ohne „.“, „..“ und doppelte „/“: res:// und user:// werden
## zum Pfad auf der Platte, ein relativer Pfad gilt ab dem Arbeitsordner, wie bei FileAccess. So
## ergeben res://data/event_catalog.json und …/src/data/event_catalog.json denselben Text.
## Verknüpfungen (Symlinks) und Groß- und Kleinschreibung gleicht das nicht an.
static func normalized_path(p_path: String) -> String:
	var absolute := ProjectSettings.globalize_path(p_path)
	if absolute.is_relative_path():
		var here := DirAccess.open(".")
		if here != null:
			absolute = here.get_current_dir().path_join(absolute)
	return absolute.simplify_path()


## Schreibt die Sicherungskopie dieses Katalogs nach backup_path(), aber nur, wenn es
## ungespeicherte Änderungen gibt; sonst geschieht nichts, und das Ergebnis ist OK. Die Werkstatt
## ruft das alle 120 Sekunden auf. Eine Datei, die dort schon liegt, ersetzt die neue Kopie, auch
## eine unlesbare. Fehlt der Ordner, legt sie ihn an. Geht das Schreiben nicht, kommt der Fehler
## zurück; die Werkstatt sagt es dann.
func write_backup() -> Error:
	if catalog == null or not is_dirty():
		return OK
	if not DirAccess.dir_exists_absolute(backup_folder):
		var made := DirAccess.make_dir_recursive_absolute(backup_folder)
		if made != OK:
			return made
	# Der Katalog als Dictionary wie in der Datei, mit den Profilen (Feature 003, R10). Nicht als
	# Text aus to_json(): JSON.parse_string() machte daraus jede ganze Zahl zu einer Kommazahl
	# (14 → 14.0), und die Kopie wäre nicht mehr kanonisch.
	var data := {
		"catalog": catalog.to_dict(),
		"format": BACKUP_FORMAT,
		"path": path,
		"saved": int(Time.get_unix_time_from_system()),
	}
	var file := FileAccess.open(backup_path(), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var stored := file.store_string(JSON.stringify(data, "\t", true) + "\n")
	file.close()
	return OK if stored else ERR_FILE_CANT_WRITE


## Ob unter backup_path() eine Datei liegt, ob lesbar oder nicht.
func has_backup() -> bool:
	return FileAccess.file_exists(backup_path())


## Ob unter backup_path() eine lesbare Kopie dieses Katalogs liegt: Ihr "path" ist nach
## normalized_path() derselbe wie path. Nur sie bietet die Werkstatt beim Start an.
func backup_matches() -> bool:
	var data := _read_backup()
	return not data.is_empty() and _same_catalog(data["path"])


## { "path": String, "saved": int, "catalog_modified": int }: zu welchem Katalog die Kopie gehört,
## wann sie geschrieben wurde und wann dieser Katalog zuletzt geändert wurde, beide Zeiten in
## Sekunden seit 1970 (Unix-Zeit); 0, wenn die Katalogdatei fehlt. Leer ohne lesbare Kopie.
func backup_info() -> Dictionary:
	var data := _read_backup()
	if data.is_empty():
		return {}
	var backup_of: String = data["path"]
	var modified := 0
	if FileAccess.file_exists(backup_of):
		modified = FileAccess.get_modified_time(backup_of)
	return {"path": backup_of, "saved": int(data["saved"]), "catalog_modified": modified}


## Übernimmt die Kopie als ungespeicherten Stand: Der Katalog ist danach der aus der Kopie, der
## Verlauf leer, und is_dirty() bleibt wahr, bis gespeichert wird. Die Kopie selbst bleibt liegen,
## bis die Werkstatt sie nach dem Speichern löscht. Eine Kopie, die zu einem anderen Katalog
## gehört, übernimmt es nicht (ERR_INVALID_DATA).
func restore_backup() -> Error:
	var data := _read_backup()
	if data.is_empty():
		last_error = "Die Sicherungskopie %s fehlt oder ist nicht lesbar." % backup_path()
		return ERR_PARSE_ERROR if has_backup() else ERR_FILE_NOT_FOUND
	if not _same_catalog(data["path"]):
		last_error = "Die Sicherungskopie gehört zum Katalog %s, nicht zu %s." % [data["path"],
			path]
		return ERR_INVALID_DATA
	var found: Array[CatalogIssue] = []
	var restored := EventCatalog.from_json(JSON.stringify(data["catalog"]), found)
	if restored == null:
		last_error = "Der Katalog in der Sicherungskopie %s ist nicht lesbar." % backup_path()
		return ERR_PARSE_ERROR
	# Die Meldungen beim Lesen gelten der Datei unter path; sie bleiben, bis gespeichert wird.
	_read_issues.append_array(found)
	last_error = ""
	_use_catalog(restored, false)
	return OK


## Löscht die Sicherungskopie dieses Katalogs, was immer unter backup_path() liegt, auch eine
## unlesbare Datei. Die Kopien anderer Kataloge liegen in eigenen Dateien und bleiben unberührt.
func discard_backup() -> void:
	if has_backup():
		DirAccess.remove_absolute(backup_path())


# --- Ereignisse --------------------------------------------------------------------------------

## Kennung aus einem Titel nach id_from(); gibt es sie im Katalog schon, kommt _2, _3 … dazu.
## „Neubaugebiet am Stadtrand“ ergibt neubaugebiet_am_stadtrand. Ohne Buchstaben und Ziffern heißt
## der Vorschlag „ereignis“.
func suggest_id(title: String) -> String:
	return unique_id(id_from(title, "ereignis"), _event_ids())


## Kennung aus einem Text, die Regel für alle Kennungen der Werkstatt (FR-032): klein, ä → ae,
## ö → oe, ü → ue, ß → ss, jedes andere Zeichen außer a–z und 0–9 trennt, doppelte und
## randständige _ entfallen. „Ware vom windigen Händler!“ ergibt ware_vom_windigen_haendler. Ohne
## Buchstaben und Ziffern [param fallback].
##
## Statisch, damit auch Teile ohne CatalogEditor die Regel nutzen, etwa WhatIfProbe für die
## Dateinamen der Proben. So steht sie an einer Stelle.
static func id_from(text: String, fallback: String) -> String:
	var lower := text.to_lower()
	for pair: Array in UMLAUTS:
		lower = lower.replace(pair[0], pair[1])
	var words := PackedStringArray()
	var word := ""
	for character: String in lower:
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9"):
			word += character
		elif not word.is_empty():
			words.append(word)
			word = ""
	if not word.is_empty():
		words.append(word)
	if words.is_empty():
		return fallback
	return "_".join(words)


## [param base], wenn es unter den Schlüsseln von [param taken] noch nicht vorkommt, sonst mit
## _2, _3 … dahinter, bis es frei ist: Gibt es intel_pentium schon, ergibt sich intel_pentium_2.
static func unique_id(base: String, taken: Dictionary) -> String:
	if not taken.has(base):
		return base
	var number := 2
	while taken.has("%s_%d" % [base, number]):
		number += 1
	return "%s_%d" % [base, number]


## Legt ein Ereignis mit den Vorgaben seiner Art an (data-model.md, „Vorgaben“); leere Kennung
## heißt suggest_id(title), day ≥ 0 setzt bei fixen Ereignissen das Datum. Doppelte Kennungen
## lässt der Editor nicht zu (FR-032): Gibt es die Kennung schon, entsteht nichts, und das
## Ergebnis ist null.
func add_event(kind: TimelineEvent.Kind, title: String, category: String, day: int = -1,
		id: String = "") -> TimelineEvent:
	var new_id := id if not id.is_empty() else suggest_id(title)
	if catalog.get_event(new_id) != null:
		return null
	var event := TimelineEvent.new()
	event.id = new_id
	event.title = title
	event.category = category
	event.kind = kind
	if kind == TimelineEvent.Kind.FIXED and day >= 0:
		event.date = day
	_commit("%s anlegen" % _event_name(event), [_insertion(event)])
	return event


## Kopie eines Ereignisses unter neuer Kennung, der alten mit _2, _3 …; alles andere bleibt gleich,
## auch der Titel.
func duplicate_event(id: String) -> TimelineEvent:
	var original := _event(id)
	if original == null:
		return null
	var copy: TimelineEvent = _copy(original)
	var base := original.id if not original.id.is_empty() else id_from(original.title, "ereignis")
	copy.id = unique_id(base, _event_ids())
	_commit("%s duplizieren" % _event_name(original), [_insertion(copy)])
	return copy


## Kennungen, die per Folge oder Bedingung darauf zeigen, sortiert und jede einmal. Das Ereignis
## selbst zählt nicht mit, auch wenn es auf sich selbst zeigt: Es verschwindet beim Löschen ohnehin.
func references_to(id: String) -> PackedStringArray:
	var result := PackedStringArray()
	for event in catalog.events:
		if event.id != id and _points_to(event, id) and not result.has(event.id):
			result.append(event.id)
	return result


## Entfernt das Ereignis samt der Folgeereignisse und Bedingungen, die darauf zeigen, in einem
## Schritt (FR-036). Haben zwei Ereignisse dieselbe Kennung (V02), bleiben die Verweise stehen,
## denn sie gelten dann dem anderen.
func delete_event(id: String) -> void:
	var event := _event(id)
	if event == null:
		return
	var steps := []
	if _count_events(id) == 1:
		for other in catalog.events:
			if other != event and _points_to(other, id):
				steps.append([&"replace", other, _redirected(other, id, "")])
	steps.append([&"remove", event, catalog.events.find(event)])
	_commit("%s löschen" % _event_name(event), steps)


## Gibt dem Ereignis eine neue Kennung und zieht alle Verweise nach, in einem Schritt (FR-032).
## ERR_ALREADY_EXISTS bei einer Dublette, ERR_DOES_NOT_EXIST bei unbekannter alter Kennung,
## ERR_INVALID_PARAMETER bei leerer neuer. Zeichen außer a–z, 0–9 und _ meldet danach die Prüfung
## (V03). Die neue Kennung sortiert das Ereignis an seine neue Stelle.
func rename_event(old_id: String, new_id: String) -> Error:
	var event := catalog.get_event(old_id)
	if event == null:
		return ERR_DOES_NOT_EXIST
	if new_id == old_id:
		return OK
	if new_id.is_empty():
		return ERR_INVALID_PARAMETER
	if catalog.get_event(new_id) != null:
		return ERR_ALREADY_EXISTS
	var steps := []
	# Bei doppelter Kennung (V02) gelten die Verweise weiter dem anderen Ereignis.
	var follow := _count_events(old_id) == 1
	if follow:
		for other in catalog.events:
			if other != event and _points_to(other, old_id):
				steps.append([&"replace", other, _redirected(other, old_id, new_id)])
	var renamed: TimelineEvent = _redirected(event, old_id, new_id) if follow else _copy(event)
	renamed.id = new_id
	steps.append([&"remove", event, catalog.events.find(event)])
	steps.append([&"insert", renamed, _sorted_index(new_id, event)])
	_commit("Kennung von %s" % _event_name(event), steps)
	return OK


## Ändert ein Feld, benannt wie in TimelineEvent, etwa &"date" oder &"window_from". Zahlen dürfen
## als int oder float kommen, Listen wie count_weights auch untypisiert. Ist der Wert schon der
## alte, entsteht kein Schritt.
func set_event_field(id: String, field: StringName, value: Variant) -> void:
	set_event_fields(id, {field: value})


## Mehrere Felder in einer Aktion, etwa Anzahl von–bis samt neu verteilten Gewichten.
func set_event_fields(id: String, changes: Dictionary) -> void:
	var event := _event(id)
	if event == null:
		return
	var changed: TimelineEvent = _copy(event)
	var labels := PackedStringArray()
	for key: Variant in changes:
		var field := StringName(key)
		if not EVENT_FIELDS.has(field):
			push_error("CatalogEditor: Das Feld „%s“ ändert set_event_field() nicht." % field)
			return
		var value: Variant = _coerce(event.get(field), changes[key])
		if value == null:
			push_error("CatalogEditor: %s passt nicht in das Feld „%s“." % [changes[key], field])
			return
		if value != event.get(field):
			changed.set(field, value)
			labels.append(EVENT_FIELDS[field])
	if labels.is_empty():
		return
	_commit("%s von %s" % [_joined(labels), _event_name(event)], [[&"replace", event, changed]])


## Behält Werte, die auch die neue Art hat (Zeitfenster, Mindestabstand, Dauer), setzt die übrigen
## Felder der neuen Art auf Vorgaben, verwirft die der alten (FR-031). Rückgängig setzt das alte
## Ereignis mit allen Werten wieder ein.
func set_event_kind(id: String, kind: TimelineEvent.Kind) -> void:
	var event := _event(id)
	if event == null or event.kind == kind:
		return
	# Ein neues Ereignis hat überall die Vorgaben; übernommen wird nur, was bleiben soll.
	var changed := TimelineEvent.new()
	for field: StringName in [&"id", &"title", &"description", &"category", &"effects",
			&"follow_ups"]:
		changed.set(field, _copy_value(event.get(field)))
	changed.kind = kind
	var old_fields: Array = KIND_FIELDS[event.kind]
	for field: StringName in KIND_FIELDS[kind]:
		if old_fields.has(field):
			changed.set(field, _copy_value(event.get(field)))
	_commit("Art von %s" % _event_name(event), [[&"replace", event, changed]])


# --- Listen im Ereignis ------------------------------------------------------------------------

## Hängt an die Liste [param list] (&"effects", &"follow_ups" oder &"conditions") einen Eintrag
## mit Vorgaben an (data-model.md, „Vorgaben“). Eine neue Wirkung gilt bei Ereignissen mit Dauer
## nur während, sonst einmal (FR-007).
func add_item(id: String, list: StringName) -> void:
	var event := _event(id)
	if event == null or not _is_list(list):
		return
	var changed: TimelineEvent = _copy(event)
	var items: Array = changed.get(list)
	items.append(_new_item(list, event))
	_commit("%s zu %s hinzufügen" % [LISTS[list]["item"], _event_name(event)],
		[[&"replace", event, changed]])


func remove_item(id: String, list: StringName, index: int) -> void:
	var event := _event(id)
	if event == null or not _is_list(list) or not _is_index(event, list, index):
		return
	var changed: TimelineEvent = _copy(event)
	var items: Array = changed.get(list)
	items.remove_at(index)
	_commit("%s %d von %s entfernen" % [LISTS[list]["item"], index + 1, _event_name(event)],
		[[&"replace", event, changed]])


## Ändert ein Feld eines Listeneintrags, benannt wie in EventEffect, FollowUp oder EventCondition,
## etwa &"delay_days". Ist der Wert schon der alte, entsteht kein Schritt.
func set_item_field(id: String, list: StringName, index: int, field: StringName,
		value: Variant) -> void:
	var event := _event(id)
	if event == null or not _is_list(list) or not _is_index(event, list, index):
		return
	var fields: Dictionary = LISTS[list]["fields"]
	if not fields.has(field):
		push_error("CatalogEditor: Einträge in „%s“ haben kein Feld „%s“." % [list, field])
		return
	var items: Array = event.get(list)
	var item: Object = items[index]
	var converted: Variant = _coerce(item.get(field), value)
	if converted == null:
		push_error("CatalogEditor: %s passt nicht in das Feld „%s“." % [value, field])
		return
	if converted == item.get(field):
		return
	var changed: TimelineEvent = _copy(event)
	var changed_items: Array = changed.get(list)
	var changed_item: Object = changed_items[index]
	changed_item.set(field, converted)
	_commit("%s %s %d von %s" % [fields[field], LISTS[list]["of"], index + 1, _event_name(event)],
		[[&"replace", event, changed]])


# --- Kategorien --------------------------------------------------------------------------------

## Neue Kategorie am Ende, also als unterste Zeile im Zeitstrahl. Die Kennung entsteht aus dem
## Namen und bleibt danach fest. Die Farbe ist das erste noch freie Token aus
## UiPalette.CATEGORY_TOKENS; sind alle vergeben, das am seltensten benutzte, bei Gleichstand das
## frühere (FR-031).
func add_category(name: String) -> EventCategory:
	var category := EventCategory.new()
	category.id = unique_id(id_from(name, "kategorie"), _category_ids())
	category.name = name
	category.color = _free_color()
	_commit("Kategorie %s anlegen" % _category_name(category),
		[[&"insert", category, catalog.categories.size()]])
	return category


## Ändert &"name" oder &"color" einer Kategorie; die Kennung bleibt fest.
func set_category_field(id: String, field: StringName, value: Variant) -> void:
	var category := catalog.get_category(id)
	if category == null:
		push_error("CatalogEditor: Die Kategorie „%s“ gibt es nicht." % id)
		return
	if field != &"name" and field != &"color":
		push_error("CatalogEditor: Bei Kategorien ändern sich nur Name und Farbe, nicht „%s“."
			% field)
		return
	var converted: Variant = _coerce(category.get(field), value)
	if converted == null:
		push_error("CatalogEditor: %s passt nicht in das Feld „%s“." % [value, field])
		return
	if converted == category.get(field):
		return
	var changed: EventCategory = _copy(category)
	changed.set(field, converted)
	var label := "Name" if field == &"name" else "Farbe"
	_commit("%s der Kategorie %s" % [label, _category_name(category)],
		[[&"replace", category, changed]])


## ERR_UNAVAILABLE, solange Ereignisse dazugehören; ERR_DOES_NOT_EXIST bei unbekannter Kennung.
func delete_category(id: String) -> Error:
	var category := catalog.get_category(id)
	if category == null:
		return ERR_DOES_NOT_EXIST
	for event in catalog.events:
		if event.category == id:
			return ERR_UNAVAILABLE
	_commit("Kategorie %s löschen" % _category_name(category),
		[[&"remove", category, catalog.categories.find(category)]])
	return OK


# --- Verlauf -----------------------------------------------------------------------------------

func undo() -> bool:
	var done := _undo_redo.undo()
	if done:
		_announce()
	return done


func redo() -> bool:
	var done := _undo_redo.redo()
	if done:
		_announce()
	return done


func can_undo() -> bool:
	return _undo_redo.has_undo()


func can_redo() -> bool:
	return _undo_redo.has_redo()


## Name der Aktion, die undo() als Nächstes zurücknimmt, etwa „Datum von Intel Pentium
## erscheint“; leer, wenn es keine gibt. Für die Tooltips der Knöpfe.
func undo_name() -> String:
	if not _undo_redo.has_undo():
		return ""
	return _undo_redo.get_current_action_name()


## Name der Aktion, die redo() als Nächstes wiederholt; leer, wenn es keine gibt. Die Aktionen
## sind durchnummeriert; die nächste steht direkt hinter der aktuellen.
func redo_name() -> String:
	if not _undo_redo.has_redo():
		return ""
	return _undo_redo.get_action_name(_undo_redo.get_current_action() + 1)


# --- Schritte im Verlauf -----------------------------------------------------------------------
#
# Ein Schritt ist eine Liste kleiner Bewegungen an den Listen des Katalogs, je ein Array:
# - [&"replace", alt, neu]: neu tritt an die Stelle von alt;
# - [&"insert", objekt, stelle]: objekt kommt an diese Stelle;
# - [&"remove", objekt, stelle]: objekt fällt weg, stelle ist, wo es stand.
# Ob die Bewegung Ereignisse oder Kategorien betrifft, zeigt die Klasse des Objekts. Rückgängig
# sind dieselben Bewegungen umgekehrt und in umgekehrter Folge (_inverse()). Weil Tun und
# Rückgängig immer im Stand davor laufen, stimmen die gemerkten Stellen.


## Führt [param steps] als eine Aktion namens [param action_name] aus.
func _commit(action_name: String, steps: Array) -> void:
	# Wer nach Rückgängig etwas Neues tut, verwirft die Schritte danach. Lag der gespeicherte Stand
	# dort, gibt es ihn im Verlauf nicht mehr. get_version() allein merkte das nicht: Nach
	# Rückgängig und einer neuen Aktion hat sie dieselbe Zahl wie vor dem Rückgängig.
	if _undo_redo.get_version() < _saved_version:
		_saved_version = -1
	# UndoRedo hält das Objekt hinter jeder Methode fest, die es aufrufen soll. Riefe es den
	# Editor selbst auf, hielte der eigene Verlauf ihn am Leben, und NOTIFICATION_PREDELETE käme
	# nie. _replay() ist statisch und gehört zur Klasse; den Editor bekommt es als WeakRef, die
	# ihn nicht festhält.
	var me: WeakRef = weakref(self)
	_undo_redo.create_action(action_name)
	_undo_redo.add_do_method(_replay.bind(me, steps))
	_undo_redo.add_undo_method(_replay.bind(me, _inverse(steps)))
	_undo_redo.commit_action()
	_announce()


## Ziel aller Aktionen im Verlauf, siehe _commit().
static func _replay(editor: WeakRef, steps: Array) -> void:
	var target: CatalogEditor = editor.get_ref()
	if target != null:
		target._run(steps)


## Führt die Bewegungen eines Schritts aus, beim Tun wie beim Rückgängig, und prüft neu. Melden
## dürfen erst die Aufrufer, wenn UndoRedo fertig ist: Es zählt seine Version erst nach dieser
## Methode weiter, und is_dirty() hinge sonst einen Schritt hinterher.
func _run(steps: Array) -> void:
	for step: Array in steps:
		var item: Object = step[1]
		var list: Array = catalog.categories
		if item is TimelineEvent:
			list = catalog.events
		if step[0] == &"insert":
			list.insert(step[2], item)
			continue
		# find() vergleicht Objekte nach ihrer Identität, nicht nach ihrem Inhalt.
		var index := list.find(item)
		if index < 0:
			# Das geschieht nur, wenn jemand am Editor vorbei den Katalog geändert hat.
			push_error("CatalogEditor: Der Verlauf passt nicht mehr zum Katalog.")
			continue
		if step[0] == &"replace":
			list[index] = step[2]
		else:
			list.remove_at(index)
	_check_issues = CatalogValidator.validate(catalog)


## Die Bewegungen, die [param steps] zurücknehmen.
static func _inverse(steps: Array) -> Array:
	var result := []
	for i in range(steps.size() - 1, -1, -1):
		var step: Array = steps[i]
		match step[0]:
			&"replace":
				result.append([&"replace", step[2], step[1]])
			&"insert":
				result.append([&"remove", step[1], step[2]])
			&"remove":
				result.append([&"insert", step[1], step[2]])
	return result


## Prüft neu und meldet die Änderung; für alles, was nicht über den Verlauf geht.
func _changed() -> void:
	_check_issues = CatalogValidator.validate(catalog)
	_announce()


func _announce() -> void:
	catalog_changed.emit()
	issues_changed.emit(issues())


## Setzt einen ganz neuen Katalog ein, mit leerem Verlauf; [param saved] sagt, ob er so in der
## Datei steht.
func _use_catalog(fresh: EventCatalog, saved: bool) -> void:
	catalog = fresh
	_undo_redo.clear_history()
	_saved_version = _undo_redo.get_version() if saved else -1
	_changed()


## Bewegung, die ein neues Ereignis an seine Stelle in der sortierten Liste setzt.
func _insertion(event: TimelineEvent) -> Array:
	return [&"insert", event, _sorted_index(event.id)]


## Stelle für ein Ereignis mit [param id] in der nach Kennung sortierten Liste: hinter allen mit
## kleinerer oder gleicher Kennung. [param leaving] zählt nicht mit, weil es im selben Schritt
## herausgenommen wird.
func _sorted_index(id: String, leaving: TimelineEvent = null) -> int:
	var index := 0
	for event in catalog.events:
		if event != leaving and event.id <= id:
			index += 1
	return index


# --- Hilfen zu Ereignissen ---------------------------------------------------------------------

## Das Ereignis mit dieser Kennung oder null mit Fehlermeldung. Liste, Formular und Zeitstrahl
## kennen nur Kennungen aus dem Katalog; eine unbekannte ist ein Fehler im Aufrufer.
func _event(id: String) -> TimelineEvent:
	var event := catalog.get_event(id)
	if event == null:
		push_error("CatalogEditor: Das Ereignis „%s“ gibt es nicht." % id)
	return event


func _event_ids() -> Dictionary:
	var ids := {}
	for event in catalog.events:
		ids[event.id] = true
	return ids


func _category_ids() -> Dictionary:
	var ids := {}
	for category in catalog.categories:
		ids[category.id] = true
	return ids


func _count_events(id: String) -> int:
	var count := 0
	for event in catalog.events:
		if event.id == id:
			count += 1
	return count


## Ob [param event] per Folgeereignis oder Bedingung auf [param id] zeigt.
static func _points_to(event: TimelineEvent, id: String) -> bool:
	for follow_up in event.follow_ups:
		if follow_up.target == id:
			return true
	for condition in event.conditions:
		if condition.event == id:
			return true
	return false


## Kopie von [param event], deren Verweise auf [param old_id] auf [param new_id] zeigen; mit
## leerem [param new_id] fallen sie weg.
static func _redirected(event: TimelineEvent, old_id: String, new_id: String) -> TimelineEvent:
	var copy: TimelineEvent = _copy(event)
	var follow_ups: Array[FollowUp] = []
	for follow_up in copy.follow_ups:
		if follow_up.target != old_id:
			follow_ups.append(follow_up)
		elif not new_id.is_empty():
			follow_up.target = new_id
			follow_ups.append(follow_up)
	copy.follow_ups = follow_ups
	var conditions: Array[EventCondition] = []
	for condition in copy.conditions:
		if condition.event != old_id:
			conditions.append(condition)
		elif not new_id.is_empty():
			condition.event = new_id
			conditions.append(condition)
	copy.conditions = conditions
	return copy


func _new_item(list: StringName, event: TimelineEvent) -> RefCounted:
	match list:
		&"effects":
			var effect := EventEffect.new()
			effect.scope = EventEffect.Scope.ONCE
			if event.has_duration():
				effect.scope = EventEffect.Scope.DURING
			return effect
		&"follow_ups":
			return FollowUp.new()
	return EventCondition.new()


func _is_list(list: StringName) -> bool:
	if LISTS.has(list):
		return true
	push_error("CatalogEditor: Eine Liste „%s“ hat ein Ereignis nicht." % list)
	return false


func _is_index(event: TimelineEvent, list: StringName, index: int) -> bool:
	var items: Array = event.get(list)
	if index >= 0 and index < items.size():
		return true
	push_error("CatalogEditor: „%s“ von „%s“ hat keinen Eintrag %d." % [list, event.id, index])
	return false


## Das Ereignis im Namen einer Aktion: sein Titel, ohne Titel seine Kennung.
static func _event_name(event: TimelineEvent) -> String:
	if not event.title.strip_edges().is_empty():
		return event.title
	if not event.id.is_empty():
		return event.id
	return "Ereignis ohne Kennung"


static func _category_name(category: EventCategory) -> String:
	if not category.name.strip_edges().is_empty():
		return category.name
	return category.id


## „Anzahl“, „Anzahl und Gewichte“, „A, B und C“.
static func _joined(labels: PackedStringArray) -> String:
	if labels.size() == 1:
		return labels[0]
	var last := labels[labels.size() - 1]
	return "%s und %s" % [", ".join(labels.slice(0, labels.size() - 1)), last]


## Erstes noch freies Token aus UiPalette.CATEGORY_TOKENS; sind alle vergeben, das am seltensten
## benutzte, bei Gleichstand das frühere (FR-031).
func _free_color() -> StringName:
	var uses := {}
	for token in UiPalette.CATEGORY_TOKENS:
		uses[token] = 0
	for category in catalog.categories:
		if uses.has(category.color):
			uses[category.color] += 1
	var best: StringName = UiPalette.CATEGORY_TOKENS[0]
	for token in UiPalette.CATEGORY_TOKENS:
		if uses[token] < uses[best]:
			best = token
	return best


# --- Kopien und Werte --------------------------------------------------------------------------

## Genaue Kopie eines Ereignisses, einer Kategorie oder eines Listeneintrags: jedes Feld, Listen
## samt neuer Einträge. TimelineEvent.duplicate_event() kopiert dagegen über die Datei und ließe
## weg, was dort nicht stünde, etwa die Werte anderer Arten.
##
## Die Felder findet get_property_list(): Jede var eines Skripts trägt dort das Kennzeichen
## PROPERTY_USAGE_SCRIPT_VARIABLE. So bleibt die Kopie vollständig, auch wenn eine Klasse ein
## Feld dazubekommt.
static func _copy(original: Object) -> Object:
	var script: GDScript = original.get_script()
	var copy: Object = script.new()
	for property in original.get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			copy.set(property["name"], _copy_value(original.get(property["name"])))
	return copy


static func _copy_value(value: Variant) -> Variant:
	if value is Array:
		# duplicate() behält den Typ der Liste, etwa Array[EventEffect]; die Einträge selbst
		# wären aber noch dieselben Objekte.
		var list: Array = value.duplicate()
		for i in list.size():
			if list[i] is Object:
				list[i] = _copy(list[i])
		return list
	return value


## [param value] im Typ von [param current], oder null, wenn er nicht passt. Ganze Zahlen werden
## zu Kommazahlen, Kommazahlen ohne Nachkommastellen zu ganzen Zahlen, Text zu StringName und
## zurück, Listen zum Typ der vorhandenen Liste, etwa [30, 70] zu Array[float] mit 30.0 und 70.0.
static func _coerce(current: Variant, value: Variant) -> Variant:
	var want := typeof(current)
	var have := typeof(value)
	if want == TYPE_ARRAY and have == TYPE_ARRAY:
		var typed: Array = (current as Array).duplicate()
		typed.clear()
		typed.assign(value)
		return typed
	if want == have:
		return value
	if want == TYPE_FLOAT and have == TYPE_INT:
		return float(value)
	if want == TYPE_INT and have == TYPE_FLOAT and value == floorf(value):
		return int(value)
	if want == TYPE_STRING_NAME and have == TYPE_STRING:
		return StringName(value)
	if want == TYPE_STRING and have == TYPE_STRING_NAME:
		return String(value)
	return null


# --- Datei und Sicherung -----------------------------------------------------------------------

## Merkt sich, wie die Datei unter path gerade aussieht.
func _remember_file() -> void:
	_file_existed = FileAccess.file_exists(path)
	_file_time = FileAccess.get_modified_time(path) if _file_existed else 0
	_file_hash = FileAccess.get_sha256(path) if _file_existed else ""


## Ob die Datei seit dem Öffnen oder Speichern von außen geändert wurde. get_modified_time() zählt
## nur ganze Sekunden; eine Änderung in derselben Sekunde verrät erst der Inhalt.
func _changed_outside() -> bool:
	var exists := FileAccess.file_exists(path)
	if exists != _file_existed:
		return true
	if not exists:
		return false
	return FileAccess.get_modified_time(path) != _file_time \
		or FileAccess.get_sha256(path) != _file_hash


## Der Text einer Kategorie oder eines Ereignisses für content_key(): to_dict() mit sortierten
## Schlüsseln in einer Zeile, wie es auch to_json() schreibt. Ein Dictionary mit Objekten als
## Schlüssel vergleicht nach der Identität des Objekts, nicht nach dem Inhalt; genau das braucht
## der Zwischenspeicher.
func _text_of(item: Object, texts: Dictionary) -> String:
	var text: String = _texts.get(item, "")
	if text.is_empty():
		# EventCategory und TimelineEvent haben beide to_dict(); call() ruft es über den Namen.
		text = JSON.stringify(item.call(&"to_dict"), "", true)
	texts[item] = text
	return text


## Ob [param backup_of], der Pfad aus einer Sicherungskopie, derselbe Katalog ist wie path.
func _same_catalog(backup_of: String) -> bool:
	return normalized_path(backup_of) == normalized_path(path)


## Die Sicherungskopie unter backup_path() als Dictionary; leer, wenn sie fehlt oder nicht die
## erwartete Form hat.
func _read_backup() -> Dictionary:
	if not has_backup():
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(backup_path())) != OK:
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = json.data
	if typeof(data.get("catalog")) != TYPE_DICTIONARY or typeof(data.get("path")) != TYPE_STRING:
		return {}
	if typeof(data.get("saved")) != TYPE_FLOAT and typeof(data.get("saved")) != TYPE_INT:
		return {}
	if data.get("format") != BACKUP_FORMAT:
		return {}
	return data
