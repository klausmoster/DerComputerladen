class_name WhatIfProbe
extends RefCounted

## Eine Was-wäre-wenn-Probe (FR-051; data-model.md, „WhatIfProbe“; research.md, R22): Seed, Grad
## und Eingriffe eines Laufs aus dem Simulator, unter einem Namen gespeichert, etwa „Windiger
## Händler ab 1990“. Jede Probe ist eine JSON-Datei im Ordner proben/ neben der Werkstatt,
## geschrieben nach denselben Regeln wie der Katalog. Mit tools/ ist der Ordner vom Export
## ausgeschlossen, liegt aber in der Versionsverwaltung; so lässt sich eine Balance-Probe auch nach
## Wochen wiederholen.
##
## Gespeichert wird nicht der Fahrplan, sondern das Eingriffsprotokoll des Laufs
## (TimelineRun.interventions): jeder Eingriff mit dem Tag, an dem er geschah. build_run() spielt
## es nach und baut so denselben Fahrplan wieder auf, auch für gewürfelte Termine und Folgen, die
## erst im Lauf entstehen. Alle Eingriffe vor dem ersten Tag anzuwenden reichte nicht: Die Absage
## eines gewürfelten Termins ginge vorher ins Leere.
##
## Im Speicher sind alle Tage Tagesindizes wie im Lauf; in der Datei stehen sie lesbar als
## „JJJJ-MM-TT“ wie im Katalog, −1 also als „1984-12-31“. Umgesetzt wird nur beim Schreiben und
## Lesen. Alles, was Dateien liest oder schreibt, nimmt den Ordner als Parameter; die Vorgabe ist
## FOLDER. Die Tests schreiben so in einen eigenen Ordner.

## Hier liegen die Proben der Werkstatt.
const FOLDER := "res://tools/werkstatt/proben/"
## Version des Dateiformats, wie beim Katalog. Eine Datei ohne Format oder mit einem anderen liest
## read_file() nicht: Sie stammt aus einer anderen Version, und sie zu lesen und neu zu schreiben,
## könnte sie zerstören.
const FORMAT := 1
## Der größte Seed (FR-014), wie im Autoload Timeline und im Simulator. Eine Probe mit einem Seed
## außerhalb von 0 bis MAX_SEED liest read_file() nicht (T099).
const MAX_SEED := 2147483647
## Die Schlüssel im Eingriffsprotokoll, die Tage sind, auch im Modifikator darin. Dazu kommt
## until_day in der Probe selbst.
const DATE_KEYS := ["at_day", "day", "new_day", "from_day", "to_day"]
## Wie die Arten des Eingriffsprotokolls in not_applicable heißen.
const KIND_LABELS := {
	TimelineRun.INTERVENTION_ADD_MODIFIER: "Modifikator",
	TimelineRun.INTERVENTION_REMOVE_MODIFIER: "Modifikator entfernen",
	TimelineRun.INTERVENTION_CANCEL: "Absage",
	TimelineRun.INTERVENTION_MOVE: "Verschiebung",
	TimelineRun.INTERVENTION_SCHEDULE: "Einplanung",
}

## Kennung = Dateiname ohne „.json“, aus dem Namen erzeugt wie bei Ereignissen.
var id: String = ""
## Anzeigename, etwa „Windiger Händler ab 1990“.
var name: String = ""
# Der Name kommt aus dem Vertrag und ist zugleich der einer globalen Funktion, seed(); die
# Warnung darüber ist abgeschaltet, wie in TimelineRun.
## Seed des Laufs.
@warning_ignore("shadowed_global_identifier")
var seed: int = 0
## Der Grad des Durchlaufs (Feature 003, FR-019, R14). In der Datei steht er als
## "difficulty": "schwer", immer, auch bei Mittel. Eine Probe aus Feature 002 hat ihn nicht; sie
## gilt als Mittel.
var difficulty: Difficulty.Level = Difficulty.DEFAULT
## Bis zu diesem Tag spielt build_run() den Lauf ab; −1 heißt: noch vor dem 01.01.1985. Beim
## Speichern ist das der Tag, auf dem der Lauf stand, mindestens aber der Tag des letzten Eingriffs,
## denn bis dorthin muss build_run() ohnehin spielen.
var until_day: int = -1
## Das Eingriffsprotokoll wie TimelineRun.interventions, mit Tagesindizes, in der Reihenfolge der
## Aktionen im Simulator. So steht es auch in der Datei; nach at_day geordnet wird erst beim
## Nachspielen in build_run().
var interventions: Array[Dictionary] = []
## Je Eingriff, der sich nicht anwenden ließ, ein deutscher Satz. Nach read_file() stehen hier die
## Einträge, die schon beim Lesen wegfielen, weil ein Datum in der Datei nicht stimmt, etwa
## „Absage: Bei „day“ steht „1992-02-30“, kein gültiges Datum JJJJ-MM-TT.“ build_run() füllt die
## Liste neu: erst diese, dann die Eingriffe, die im neuen Lauf nicht passen, etwa „Absage:
## Konkurrent eröffnet hat am 01.06.1992 keinen geplanten Termin im Fahrplan.“
var not_applicable: PackedStringArray = PackedStringArray()

## Die Sätze zu den Einträgen, die read_file() wegen eines falschen Datums nicht übernommen hat.
## Sie stehen nach jedem build_run() wieder vorn in not_applicable, damit die Werkstatt sie mit den
## übrigen nennt, statt sie still wegzulassen (FR-051).
var _read_problems: PackedStringArray = PackedStringArray()


## Alle Proben im Ordner, nach Name; Groß- und Kleinschreibung zählt dabei nicht. Gelesen werden die
## Dateien mit der Endung .json. Eine unlesbare Datei meldet read_file() und fehlt in der Liste.
static func list_probes(folder: String = FOLDER) -> Array[WhatIfProbe]:
	var probes: Array[WhatIfProbe] = []
	if not DirAccess.dir_exists_absolute(folder):
		return probes
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() != "json":
			continue
		var probe := read_file(folder.path_join(file))
		if probe != null:
			probes.append(probe)
	probes.sort_custom(_comes_before)
	return probes


## Liest eine Probe. Fehlt die Datei oder ist sie keine Probe dieses Formats, gibt es null und eine
## Meldung über push_error() mit Pfad und Grund. Die Kennung ist der Dateiname, wie beim Schreiben.
##
## Fehlt "difficulty", gilt Mittel, wie bei einer Probe aus Feature 002. Ist der Wert kein Text oder
## kein Grad, auch „Schwer“ mit großem S, gibt es null und eine Meldung wie „Die Probe <Pfad> nennt
## den Schwierigkeitsgrad „extrem“, den es nicht gibt.“ Unter einem geratenen Grad zeigte die Probe
## ein anderes Spiel als das gespeicherte (R14).
##
## Ein Eintrag mit einem Datum, das kein Kalendertag in der Form „JJJJ-MM-TT“ ist, kommt nicht ins
## Eingriffsprotokoll; not_applicable nennt ihn, und die übrigen Einträge gelten. So kostet ein
## Tippfehler beim Bearbeiten von Hand nicht die ganze Probe.
static func read_file(path: String) -> WhatIfProbe:
	if not FileAccess.file_exists(path):
		push_error("Die Probe %s fehlt." % path)
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() zählt ab 0, Texteditoren zählen ab 1.
		push_error("Die Probe %s ist kein gültiges JSON, Zeile %d: %s." % [path,
			json.get_error_line() + 1, json.get_error_message()])
		return null
	var problem := _structure_problem(json.data)
	if not problem.is_empty():
		push_error("Die Probe %s lässt sich nicht lesen: %s" % [path, problem])
		return null
	var data: Dictionary = json.data
	var level := _read_difficulty(data)
	if level == -1:
		push_error("Die Probe %s nennt den Schwierigkeitsgrad %s, den es nicht gibt." % [path,
			_shown(data["difficulty"])])
		return null
	var probe := WhatIfProbe.new()
	probe.id = path.get_file().get_basename()
	probe.name = data["name"]
	probe.seed = int(data["seed"])
	probe.difficulty = level as Difficulty.Level
	probe.until_day = GameDate.from_iso(data["until_day"]).to_day_index()
	for record: Dictionary in data["interventions"]:
		var wrong := _wrong_date(record)
		if wrong.is_empty():
			probe.interventions.append(_from_file(record))
		else:
			probe._read_problems.append("%s: %s" % [_label(record), wrong])
	probe.not_applicable = probe._read_problems.duplicate()
	return probe


## Schreibt die Probe nach folder + id + ".json", kanonisch wie den Katalog: Schlüssel
## alphabetisch, Tabs, ganze Zahlen als int, Tage als „JJJJ-MM-TT“, der Wert eines Modifikators auf
## vier Nachkommastellen gerundet wie die Anteile im Katalog, ein Zeilenumbruch am Ende, dazu
## "format": 1. Gleiche Probe, gleiche Datei.
##
## Der Grad steht immer darin, auch Mittel als "difficulty": "mittel"; so hat jeder Grad genau eine
## Form in den Dateien (R14). Alphabetisch ist er der erste Schlüssel.
##
## Eine Datei mit dieser Kennung wird überschrieben; ob es sie schon gibt, sagt list_probes().
## Fehlt der Ordner, legt write_file() ihn an. Eine Kennung mit anderen Zeichen als a–z, 0–9 und _
## lehnt es mit ERR_INVALID_PARAMETER ab, damit keine Datei außerhalb des Ordners entsteht. Ebenso
## einen unbekannten Grad wie 7: Die Datei ließe sich nicht wieder lesen.
func write_file(folder: String = FOLDER) -> Error:
	if not _is_valid_id(id) or not Difficulty.is_valid(difficulty):
		return ERR_INVALID_PARAMETER
	if not DirAccess.dir_exists_absolute(folder):
		var made := DirAccess.make_dir_recursive_absolute(folder)
		if made != OK:
			return made
	var records: Array[Dictionary] = []
	for record in interventions:
		records.append(_to_file(record))
	var data := {
		"difficulty": Difficulty.key(difficulty),
		"format": FORMAT,
		"id": id,
		"interventions": records,
		"name": name,
		"seed": seed,
		"until_day": GameDate.from_day_index(until_day).to_iso(),
	}
	var file := FileAccess.open(folder.path_join(id + ".json"), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	# Mit "\t" steht jedes Element auf einer eigenen Zeile, true sortiert die Schlüssel.
	var stored := file.store_string(JSON.stringify(data, "\t", true) + "\n")
	file.close()
	return OK if stored else ERR_FILE_CANT_WRITE


## Löscht die Datei der Probe, „Probe löschen“ (FR-051). Fehlt sie, ERR_FILE_NOT_FOUND.
func delete_file(folder: String = FOLDER) -> Error:
	var path := folder.path_join(id + ".json")
	if not _is_valid_id(id) or not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	return DirAccess.remove_absolute(path)


# Der Parameter heißt laut Vertrag name, wie das Feld; die Warnung darüber ist abgeschaltet.

## Neue Probe aus einem Lauf: Seed, Grad, der Tag, bis zu dem er abgespielt ist, und eine Kopie
## seines Eingriffsprotokolls. Die Start-Modifikatoren des Grads stehen dort nie; build_run() setzt
## sie aus dem Profil neu. Die Kennung entsteht aus dem Namen wie bei Ereignissen: „Windiger Händler
## ab 1990“ ergibt windiger_haendler_ab_1990, ohne Buchstaben und Ziffern „probe“.
@warning_ignore("shadowed_variable")
static func from_run(name: String, run: TimelineRun) -> WhatIfProbe:
	var probe := WhatIfProbe.new()
	probe.name = name
	# Dieselbe Regel wie für die Kennungen von Ereignissen, an einer Stelle.
	probe.id = CatalogEditor.id_from(name, "probe")
	probe.seed = run.seed
	probe.difficulty = run.difficulty
	probe.until_day = run.today
	# duplicate(true) kopiert auch die Dictionaries darin: Ändert sich der Lauf danach, bleibt
	# die Probe, wie sie war.
	probe.interventions = run.interventions.duplicate(true)
	return probe


## Neuer Lauf mit [member seed] und [member difficulty] auf [param catalog]; spielt das
## Eingriffsprotokoll nach und dann bis [member until_day] (data-model.md, „Neu abspielen“). Je
## Eingriff spielt er den Lauf bis zu dessen at_day ab, bei −1 gar nicht, und wendet ihn dort mit
## TimelineRun.apply_intervention() an. So entsteht derselbe Fahrplan wie beim Speichern.
##
## Nachgespielt wird nach at_day (TimelineRun.in_replay_order()), nicht in der Reihenfolge des
## Protokolls: Nach „Fahrplan erzeugen“ kann ein Eingriff vor Spielbeginn hinter einem vom
## 01.01.1992 stehen. Der Reihe nach gespielt, gälte er erst 1992, denn ein Lauf spielt nie
## zurück.
##
## Hat sich der Katalog seitdem geändert, passt vielleicht ein Eingriff nicht mehr, etwa weil der
## abgesagte Termin fehlt. Er wird übersprungen, die übrigen gelten, und not_applicable nennt ihn
## mit dem Grund aus TimelineRun.last_refusal (FR-051), nach den Einträgen, die schon beim Lesen
## wegfielen, und in der Reihenfolge des Nachspielens. Der Katalog selbst bleibt unberührt; der
## Lauf arbeitet auf einer Kopie.
##
## Die Start-Modifikatoren des Grads setzt der Lauf selbst, aus dem Profil im Katalog, wie er jetzt
## dasteht (Feature 003, R5). Mit Mittel entsteht derselbe Fahrplan wie in Feature 002.
func build_run(catalog: EventCatalog) -> TimelineRun:
	not_applicable = _read_problems.duplicate()
	var run := TimelineRun.new(catalog, seed, difficulty)
	for record in TimelineRun.in_replay_order(interventions):
		# Ohne lesbaren Tag ist der Tag −1: Der Lauf spielt nichts ab, und der Eingriff gilt dort,
		# wo der Lauf gerade steht.
		run.advance_to(TimelineRun.intervention_day(record))
		if run.apply_intervention(record) != OK:
			not_applicable.append("%s: %s" % [_label(record), run.last_refusal])
	run.advance_to(until_day)
	return run


## Reihenfolge der Liste: nach Name ohne Rücksicht auf Groß- und Kleinschreibung, Zahlen darin
## nach ihrem Wert („Probe 2“ vor „Probe 10“); bei gleichem Namen nach Kennung.
static func _comes_before(a: WhatIfProbe, b: WhatIfProbe) -> bool:
	var order := a.name.naturalnocasecmp_to(b.name)
	if order != 0:
		return order < 0
	return a.id < b.id


## Der Grad aus einer gelesenen Datei, die _structure_problem() durchgelassen hat: Mittel, wenn
## "difficulty" fehlt; −1, wenn der Wert kein Text oder kein Name aus Difficulty ist.
static func _read_difficulty(data: Dictionary) -> int:
	if not data.has("difficulty"):
		return Difficulty.DEFAULT
	var value: Variant = data["difficulty"]
	if typeof(value) != TYPE_STRING:
		return -1
	return Difficulty.from_key(value)


## Was an einer gelesenen Datei nicht stimmt; leer, wenn sie eine Probe dieses Formats ist. Das
## Format kommt zuerst: In einer anderen Version können alle übrigen Schlüssel anders aussehen. Die
## Einträge des Eingriffsprotokolls prüfen erst _wrong_date() und apply_intervention(); hier zählt
## nur, dass es Objekte sind.
static func _structure_problem(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return "Die Datei enthält kein Objekt { … }."
	var probe: Dictionary = data
	if not probe.has("format"):
		return "Das Format („format“) fehlt; diese Version liest nur Format %d." % FORMAT
	if not _is_whole_number(probe["format"]) or int(probe["format"]) != FORMAT:
		return "Das Format %s kennt diese Version nicht, sie liest nur %d." % [
			_shown(probe["format"]), FORMAT]
	if typeof(probe.get("name")) != TYPE_STRING:
		return "Der Name („name“) fehlt oder ist kein Text."
	if not _is_whole_number(probe.get("seed")):
		return "„seed“ fehlt oder ist keine ganze Zahl."
	# Einen anderen Seed hat kein Spiel (FR-014); der Simulator nimmt ihn im Feld gar nicht an.
	if probe["seed"] < 0 or probe["seed"] > MAX_SEED:
		return "„seed“ liegt außerhalb von 0 bis 2.147.483.647."
	if not _is_date(probe.get("until_day")):
		return "„until_day“ fehlt oder ist kein gültiges Datum JJJJ-MM-TT."
	if typeof(probe.get("interventions")) != TYPE_ARRAY:
		return "Die Eingriffe („interventions“) fehlen oder sind keine Liste."
	for record: Variant in probe["interventions"]:
		if typeof(record) != TYPE_DICTIONARY:
			return "Ein Eintrag in „interventions“ ist kein Objekt."
	return ""


## Warum ein Eintrag aus der Datei kein gültiges Datum hat, als Satz; leer, wenn jeder Tag darin,
## auch im Modifikator, ein Kalendertag „JJJJ-MM-TT“ ist. Ein fehlender Tag ist hier kein Fehler;
## über den entscheidet apply_intervention(), wie bei jedem anderen fehlenden Feld.
static func _wrong_date(record: Dictionary) -> String:
	for key: Variant in record:
		var value: Variant = record[key]
		if typeof(value) == TYPE_DICTIONARY:
			var inner := _wrong_date(value)
			if not inner.is_empty():
				return inner
		elif DATE_KEYS.has(key) and not _is_date(value):
			return "Bei „%s“ steht %s, kein gültiges Datum JJJJ-MM-TT." % [key, _shown(value)]
	return ""


## Kopie eines Eintrags aus der Datei mit Tagesindizes statt „JJJJ-MM-TT“, auch im Modifikator
## darin. Nur für Einträge, die _wrong_date() durchgelassen hat.
static func _from_file(record: Dictionary) -> Dictionary:
	var result := {}
	for key: Variant in record:
		var value: Variant = record[key]
		if typeof(value) == TYPE_DICTIONARY:
			value = _from_file(value)
		elif DATE_KEYS.has(key):
			value = GameDate.from_iso(value).to_day_index()
		result[key] = value
	return result


## Kopie eines Eintrags für die Datei: Tage als „JJJJ-MM-TT“, auch vor 1985 (−1 ist der
## 31.12.1984). Der Wert eines Modifikators ist ein Anteil und wird wie die Anteile im Katalog auf
## vier Nachkommastellen gerundet (ereigniskatalog.md, Schreibregel 3); +5 Prozentpunkte stehen
## als 0.05 darin.
static func _to_file(record: Dictionary) -> Dictionary:
	var result := {}
	for key: Variant in record:
		var value: Variant = record[key]
		if typeof(value) == TYPE_DICTIONARY:
			value = _to_file(value)
		elif DATE_KEYS.has(key) and _is_whole_number(value):
			value = GameDate.from_day_index(int(value)).to_iso()
		elif key == "value" and (typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT):
			value = roundf(float(value) * 10000.0) / 10000.0
		result[key] = value
	return result


## Wie die Art eines Eintrags in not_applicable heißt; „Eingriff“, wenn sie unbekannt ist.
static func _label(record: Dictionary) -> String:
	return KIND_LABELS.get(record.get("kind"), "Eingriff")


## Ob [param value] ein Kalendertag in der Form „JJJJ-MM-TT“ ist, wie die Daten im Katalog.
static func _is_date(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and GameDate.from_iso(value) != null


## Ob [param value] eine ganze Zahl ist, als int oder als float ohne Nachkommastellen.
static func _is_whole_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return typeof(value) == TYPE_FLOAT and value == floorf(value) and absf(value) < 1e15


## Ein Wert aus der Datei für Meldungen: Text in „…“, eine ganze Zahl ohne Nachkomma.
static func _shown(value: Variant) -> String:
	if typeof(value) == TYPE_STRING:
		return "„%s“" % value
	if _is_whole_number(value):
		return str(int(value))
	return str(value)


## Ob [param text] als Kennung und Dateiname taugt: nicht leer, nur a–z, 0–9 und _.
static func _is_valid_id(text: String) -> bool:
	if text.is_empty():
		return false
	for character in text:
		var allowed := (character >= "a" and character <= "z") \
			or (character >= "0" and character <= "9") or character == "_"
		if not allowed:
			return false
	return true
