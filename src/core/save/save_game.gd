class_name SaveGame
extends RefCounted

## Ein Spielstand (Feature 004, data-model.md, „SaveGame“; research.md, R1 und R2): alles, was ein
## Spiel braucht, um genau so weiterzulaufen, wie es aufgehört hat. Das sind Seed, Grad, Katalog
## und Eingriffsprotokoll, denn aus ihnen entsteht genau ein Fahrplan; dazu Spieldatum, Name,
## Nummer und die Zeitpunkte für die Liste.
##
## Jeder Spielstand ist eine JSON-Datei spiel_<N>.json. Wie sie sicher geschrieben und welche
## Datei gelesen wird, regelt SaveStore; ob sie sich fortsetzen lässt, SaveSlot. Diese Klasse kennt
## nur den Inhalt: to_json() macht daraus Text, from_data() prüft gelesenes JSON und macht daraus
## wieder einen Spielstand.
##
## Im Speicher sind Tage Tagesindizes wie im Lauf (0 = 01.01.1985), Zeitpunkte Unix-Zeit in UTC.
## In der Datei steht beides lesbar: Tage als „JJJJ-MM-TT“, Zeitpunkte als „2026-10-26T20:40:12Z“.
##
## Die Sätze REASON_* sind für den Hinweis im Spiel. Sie nennen nie ein Feld und nie einen Wert aus
## der Datei: Ein Wert kann beliebig lang sein und den Hinweis sprengen (R10; Analyse, B4). Sie
## nennen auch kein Wort aus dem Inneren wie Seed, Formatversion, Eingriff oder Ereigniskatalog,
## nur, was der Spieler kennt (Klaus, 2026-10-26). Feld, Wert und genaue Stelle stehen nur in den
## Einzelheiten fürs Protokoll.

## Formatversion der Datei (FR-007, FR-014).
const FORMAT := 1
## Der größte Seed (FR-014), wie im Autoload Timeline.
const MAX_SEED := 2147483647
## Steht für „den Versatz des Rechners“, Time.get_time_zone_from_system().bias. Eine echte
## Zeitzone liegt nie so weit weg; so kann ein Test jeden echten Versatz vorgeben (Analyse, C3).
const SYSTEM_BIAS := -100000
## Alle Schlüssel, die eine Datei haben muss (data-model.md, „Pflichtfelder“). Unbekannte Schlüssel
## stören nicht; spätere Features fügen ihre Daten hinzu (Analyse, B3).
const REQUIRED_KEYS := ["catalog", "created_at", "day", "difficulty", "format", "game_version",
	"interventions", "last_played_at", "name", "number", "seed"]

## Gründe für den Hinweis (data-model.md, Tabelle „Zustand“). Die Zeilen „kein gültiges JSON“ und
## „zu neu“ prüft SaveSlot.read() vorher, mit eigenen Sätzen.
## Für alles, was nur das Innere der Datei betrifft: Formatversion fehlt oder stimmt nicht,
## Pflichtfeld fehlt oder hat den falschen Typ, Seed außerhalb, Zeitpunkt nicht lesbar, Eingriff
## falsch oder nach dem Spieldatum, Katalog nicht lesbar. Welche Stelle es ist, sagt nur das
## Protokoll.
const REASON_FILE_PART := "Lässt sich nicht lesen: Ein Teil der Datei stimmt nicht."
## Der Grad ist keiner von leicht, mittel und schwer.
const REASON_DIFFICULTY := "Der Schwierigkeitsgrad ist unbekannt."
## Das Spieldatum ist kein Tag von 1985 bis 1999, auch wenn es sich gar nicht als Datum lesen lässt.
const REASON_DAY := "Das Spieldatum ist kein Tag von 1985 bis 1999."

## Der Versatz zu UTC in Minuten für alle Uhrzeiten, die ohne eigenen Versatz gezeigt werden
## (Feature 007, R7). Vorgabe SYSTEM_BIAS: wie der Rechner, also wie bisher. Nur der Selbsttest
## setzt ihn, auf UTC+1, damit die Liste auf jedem Rechner dieselbe Uhrzeit zeigt und die Fotos
## gleich bleiben. Das Spiel weiß nichts vom Selbsttest; es hat nur diese Stellschraube. Sie gilt,
## solange das Programm läuft, für alle Spielstände; wer sie in einem Test setzt, setzt sie danach
## auf SYSTEM_BIAS zurück.
static var time_zone_bias: int = SYSTEM_BIAS

## Die Nummer aus dem Dateinamen, ab 1; sie steht zusätzlich in der Datei, es gilt aber der
## Dateiname (R4).
var number: int = 0
## Der Name in der Liste, nie leer; beim Anlegen „Spiel N“ (FR-009).
var name: String = ""
var difficulty: Difficulty.Level = Difficulty.DEFAULT
# Der Name kommt aus dem Vertrag und ist zugleich der einer globalen Funktion, seed(); die
# Warnung darüber ist abgeschaltet, wie in TimelineRun.
## Seed des Spiels, 0 bis MAX_SEED.
@warning_ignore("shadowed_global_identifier")
var seed: int = 0
## Spieldatum als Tagesindex, 0 bis TimelineRun.LAST_DAY. Der Lauf hat diesen Tag schon
## abgespielt; das erste Signal nach dem Fortsetzen gehört zum Tag danach (data-model.md).
var day: int = 0
## Unix-Zeit, UTC.
var created_at: int = 0
var last_played_at: int = 0
## Die Version des Spiels, die zuletzt schrieb, etwa „0.1“ (FR-007).
var game_version: String = ""
## Der Katalog, mit dem das Spiel läuft, als eigene Kopie (FR-022).
var catalog: EventCatalog
## Das Eingriffsprotokoll wie TimelineRun.interventions, mit Tagesindizes.
var interventions: Array[Dictionary] = []


## „Spiel 2“: der Name, den ein neues Spiel mit der Nummer [param p_number] bekommt.
static func default_name(p_number: int) -> String:
	return "Spiel %d" % p_number


## Kanonischer Text der Datei, wie Katalog und Proben: Schlüssel alphabetisch, Tabs, ein
## Zeilenumbruch am Ende. Der Katalog steht so darin, wie EventCatalog.to_dict() ihn liefert, die
## Eingriffe so, wie InterventionFile.to_file() sie schreibt. Gleicher Spielstand, gleiche Datei;
## darauf verlässt sich SaveStore beim Prüfen nach dem Schreiben (R3, Schritt 2).
func to_json() -> String:
	var records: Array[Dictionary] = []
	for record in interventions:
		records.append(InterventionFile.to_file(record))
	# Ohne Katalog steht ein leerer darin; so lässt sich die Datei immer wieder lesen.
	var catalog_data := catalog.to_dict() if catalog != null else EventCatalog.new().to_dict()
	var data := {
		"catalog": catalog_data,
		"created_at": _utc_text(created_at),
		"day": GameDate.from_day_index(day).to_iso(),
		"difficulty": Difficulty.key(difficulty),
		"format": FORMAT,
		"game_version": game_version,
		"interventions": records,
		"last_played_at": _utc_text(last_played_at),
		"name": name,
		"number": number,
		"seed": seed,
	}
	# Mit "\t" steht jedes Element auf einer eigenen Zeile, true sortiert die Schlüssel jedes
	# Dictionarys alphabetisch, auch im Katalog und in den Eingriffen.
	return JSON.stringify(data, "\t", true) + "\n"


## Ein Spielstand aus gelesenem JSON; [param p_number] ist die Nummer aus dem Dateinamen. Stimmt
## etwas nicht, gibt es null, einen Satz für den Hinweis in [param problems] und, wenn übergeben,
## in [param details] Feld und Wert für das Protokoll. Geprüft wird in der Reihenfolge der Tabelle
## „Zustand“ in data-model.md; der erste Treffer gilt.
##
## Die Zeile „Formatversion größer als 1“ prüft SaveSlot.read() vorher und setzt dann TOO_NEW.
## Kommt eine solche Datei trotzdem hier an, gibt es null mit SaveSlot.REASON_TOO_NEW: Einen
## Spielstand aus einer neueren Version nimmt diese Funktion nie an.
##
## Ereignisse mit Fehlern im Katalog machen den Spielstand nicht kaputt (R2); die nimmt erst das
## Fortsetzen heraus. Beschädigt ist er nur, wenn sich der Katalog gar nicht lesen lässt. Strenger
## als EventCatalog.from_data() gilt hier: Steht im Katalog eine Formatversion, muss es die ganze
## Zahl 1 sein (Claude, 2026-10-26); fehlt sie, gilt 1 wie beim Katalog.
static func from_data(data: Dictionary, p_number: int, problems: Array[String],
		details: Array[String] = []) -> SaveGame:
	var raw_format: Variant = data.get("format")
	if not InterventionFile.is_whole_number(raw_format) or raw_format < 1:
		return _refuse(problems, REASON_FILE_PART, details, "Die Formatversion „format“ fehlt oder "
			+ "ist keine ganze Zahl ab 1: %s." % _shown(raw_format))
	var format := int(raw_format)
	if format > FORMAT:
		return _refuse(problems, SaveSlot.REASON_TOO_NEW, details,
			"Formatversion %d, diese Version liest höchstens %d." % [format, FORMAT])
	data = _upgrade(data, format)

	var missing := _missing_key(data)
	if not missing.is_empty():
		return _refuse(problems, REASON_FILE_PART, details, missing)
	var level := Difficulty.from_key(data["difficulty"])
	if level == -1:
		return _refuse(problems, REASON_DIFFICULTY, details,
			"Schwierigkeitsgrad %s." % _shown(data["difficulty"]))
	if data["seed"] < 0 or data["seed"] > MAX_SEED:
		return _refuse(problems, REASON_FILE_PART, details, "Seed %s." % _shown(data["seed"]))
	var date := GameDate.from_iso(data["day"])
	var game_day := date.to_day_index() if date != null else -1
	if game_day < TimelineRun.FIRST_DAY or game_day > TimelineRun.LAST_DAY:
		return _refuse(problems, REASON_DAY, details, "Spieldatum %s." % _shown(data["day"]))
	for key: String in ["created_at", "last_played_at"]:
		var unix: Variant = _unix_from_text(data[key])
		# „zuletzt gespielt“ ordnet die Liste; vor 1970 kann es nicht liegen (data-model.md).
		if unix == null or (key == "last_played_at" and unix < 0):
			return _refuse(problems, REASON_FILE_PART, details,
				"Zeitpunkt „%s“: %s." % [key, _shown(data[key])])
	var records: Array = data["interventions"]
	for i in records.size():
		var record: Variant = records[i]
		if typeof(record) != TYPE_DICTIONARY:
			return _refuse(problems, REASON_FILE_PART, details,
				"Eingriff %d ist kein Objekt: %s." % [i + 1, _shown(record)])
		var wrong := InterventionFile.wrong_date(record)
		if not wrong.is_empty():
			return _refuse(problems, REASON_FILE_PART, details,
				"Eingriff %d: %s" % [i + 1, wrong])
		# Ein Eingriff nach dem Spieldatum schöbe den Lauf beim Fortsetzen über dieses hinaus, und
		# die Tage dazwischen kämen nie als Signal (replay()). Das Spiel schreibt so etwas nie; steht
		# es in der Datei, ist sie verändert (Claude, 2026-10-26). Ohne at_day gilt der Eingriff
		# dort, wo der Lauf gerade steht, und bleibt erlaubt.
		var at_day: Variant = (record as Dictionary).get("at_day")
		if at_day != null and GameDate.from_iso(at_day).to_day_index() > game_day:
			return _refuse(problems, REASON_FILE_PART, details,
				"Eingriff %d am %s liegt nach dem Spieldatum %s." % [i + 1, _shown(at_day),
				_shown(data["day"])])
	var catalog_details: Array[String] = []
	var read_catalog := _read_catalog(data["catalog"], catalog_details)
	if read_catalog == null:
		return _refuse(problems, REASON_FILE_PART, details, catalog_details[0])

	var game := SaveGame.new()
	game.number = p_number
	game.name = data["name"]
	game.difficulty = level as Difficulty.Level
	game.seed = int(data["seed"])
	game.day = game_day
	game.created_at = int(_unix_from_text(data["created_at"]))
	game.last_played_at = int(_unix_from_text(data["last_played_at"]))
	game.game_version = data["game_version"]
	game.catalog = read_catalog
	for record: Dictionary in records:
		game.interventions.append(InterventionFile.from_file(record))
	return game


## „14.03.1986“: das Spieldatum für Liste und Hinweise.
func day_text() -> String:
	return str(GameDate.from_day_index(day))


## „26.10.2026 21:40“ in Ortszeit, für die Spalte „zuletzt gespielt“ der Liste (R12).
## [param bias_minutes] ist der Versatz zu UTC in Minuten; SYSTEM_BIAS heißt der aus
## [member time_zone_bias], und ohne den der des Rechners.
## Der Versatz gilt für heute: Ein Zeitpunkt aus dem Sommer erscheint im Winter eine Stunde früher.
## Das reicht für „zuletzt gespielt“ (data-model.md, „Zeitpunkte“).
static func time_text(unix: int, bias_minutes: int = SYSTEM_BIAS) -> String:
	var local := _local_time(unix, bias_minutes)
	return "%02d.%02d.%04d %02d:%02d" % [local["day"], local["month"], local["year"],
		local["hour"], local["minute"]]


## Bringt gelesene Daten einer älteren Formatversion Schritt für Schritt auf FORMAT (FR-014): Für
## Format 2 käme hier ein Schritt „von 1 auf 2“ dazu, der eine Kopie umbaut. Mit Format 1 gibt es
## nichts umzuwandeln, [param data] kommt unverändert zurück (Analyse, E4).
static func _upgrade(data: Dictionary, from_format: int) -> Dictionary:
	var upgraded := data
	var version := from_format
	while version < FORMAT:
		# Hier steht später je Version ein Schritt, etwa: if version == 1: upgraded = _from_1(…)
		version += 1
	return upgraded


## Was an den Pflichtfeldern nicht stimmt, für das Protokoll; leer, wenn jedes da ist und den
## richtigen Typ hat. Den Wert prüfen erst die Zeilen danach; den Katalog prüft _catalog_problem(),
## denn ein Katalog, der kein Objekt ist, hat dort seinen eigenen Grund.
static func _missing_key(data: Dictionary) -> String:
	for key: String in REQUIRED_KEYS:
		if not data.has(key):
			return "Das Feld „%s“ fehlt." % key
	for key: String in ["created_at", "day", "difficulty", "game_version", "last_played_at",
			"name"]:
		if typeof(data[key]) != TYPE_STRING:
			return "Das Feld „%s“ ist kein Text: %s." % [key, _shown(data[key])]
	# Ein Name nur aus Leerzeichen erschiene in der Liste als leere Zeile; er zählt wie ein leerer.
	if (data["name"] as String).strip_edges().is_empty():
		return "Das Feld „name“ ist leer."
	for key: String in ["number", "seed"]:
		if not InterventionFile.is_whole_number(data[key]):
			return "Das Feld „%s“ ist keine ganze Zahl: %s." % [key, _shown(data[key])]
	if typeof(data["interventions"]) != TYPE_ARRAY:
		return "Das Feld „interventions“ ist keine Liste: %s." % _shown(data["interventions"])
	return ""


## Der Abschnitt „catalog“ als Katalog, gelesen mit EventCatalog.from_data(). Lässt er sich nicht
## lesen: null und in [param details] der Grund für das Protokoll. Die Meldungen zu einzelnen
## Einträgen zählen hier nicht; solche Ereignisse nimmt erst das Fortsetzen heraus (R2).
static func _read_catalog(section: Variant, details: Array[String]) -> EventCatalog:
	if typeof(section) == TYPE_DICTIONARY:
		var by_key: Dictionary = section
		var format: Variant = by_key.get("format", EventCatalog.FORMAT)
		if not InterventionFile.is_whole_number(format) or int(format) != EventCatalog.FORMAT:
			details.append("Katalog mit der Formatversion %s, gelesen wird nur %d." % [
				_shown(format), EventCatalog.FORMAT])
			return null
	var issues: Array[CatalogIssue] = []
	var read := EventCatalog.from_data(section, issues)
	if read == null:
		var messages := PackedStringArray()
		for issue in issues:
			messages.append(issue.message)
		details.append("Im Abschnitt „catalog“: %s" % " ".join(messages))
	return read


## Unix-Zeit aus „2026-10-26T20:40:12Z“, genau in dieser Form, sonst null. Godots eigene Funktion
## dafür nimmt auch Halbes an, etwa ein Datum ohne Uhrzeit; dann stünde nach dem nächsten Speichern
## still etwas anderes in der Datei.
static func _unix_from_text(value: Variant) -> Variant:
	if typeof(value) != TYPE_STRING:
		return null
	var text: String = value
	if text.length() != 20 or text[10] != "T" or text[13] != ":" or text[16] != ":" \
			or text[19] != "Z":
		return null
	var date := GameDate.from_iso(text.substr(0, 10))
	if date == null:
		return null
	var parts: Array[int] = []
	for start: int in [11, 14, 17]:
		var two := text.substr(start, 2)
		# Ein einzelnes Zeichen ist nur als Ziffer eine Zahl; „+“ und „-“ fallen so heraus.
		if not (two[0].is_valid_int() and two[1].is_valid_int()):
			return null
		parts.append(two.to_int())
	if parts[0] > 23 or parts[1] > 59 or parts[2] > 59:
		return null
	return Time.get_unix_time_from_datetime_dict({"year": date.year, "month": date.month,
		"day": date.day, "hour": parts[0], "minute": parts[1], "second": parts[2]})


## „2026-10-26T20:40:12Z“: Unix-Zeit als UTC, das „Z“ sagt es.
static func _utc_text(unix: int) -> String:
	return Time.get_datetime_string_from_unix_time(unix) + "Z"


## Datum und Uhrzeit in Ortszeit: Unix-Zeit plus Versatz, wie die Werkstatt ihre Sicherungskopien
## zeigt (werkstatt.gd, _time_text()). Ein ausdrücklicher Versatz geht vor; dann kommt
## time_zone_bias, dann der Rechner.
static func _local_time(unix: int, bias_minutes: int) -> Dictionary:
	var bias := bias_minutes
	if bias == SYSTEM_BIAS:
		bias = time_zone_bias
	if bias == SYSTEM_BIAS:
		bias = Time.get_time_zone_from_system().get("bias", 0)
	return Time.get_datetime_dict_from_unix_time(unix + bias * 60)


## Ein Wert aus der Datei für das Protokoll; „fehlt“, wenn es ihn nicht gibt.
static func _shown(value: Variant) -> String:
	if value == null:
		return "fehlt"
	return InterventionFile.shown(value)


## null, den Satz [param reason] in [param problems] und [param detail] in [param details].
static func _refuse(problems: Array[String], reason: String, details: Array[String],
		detail: String) -> SaveGame:
	problems.append(reason)
	details.append(detail)
	return null
