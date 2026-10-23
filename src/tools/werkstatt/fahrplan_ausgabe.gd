extends SceneTree

## Textausgabe des Fahrplans (FR-046; research.md, R18): spielt einen Lauf ohne Fenster ab und
## schreibt den Fahrplan bis zu einem Tag auf die Konsole, mit --protokoll stattdessen alle
## Meldungen. Aufruf vom Repo-Root aus:
##
## [codeblock]
## Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711
##         [--grad schwer] [--bis 1999-12-31] [--katalog res://…] [--protokoll]
## [/codeblock]
##
## Ohne --seed gilt 1, ohne --grad Mittel, ohne --bis der 31.12.1999, ohne --katalog der echte
## Katalog. --grad nimmt leicht, mittel oder schwer, klein geschrieben (Feature 003, R16). Die
## Ausgabe geht nach stdout, Meldungen nach stderr. Vor der Ausgabe druckt Godot selbst seine
## Kopfzeile „Godot Engine v4.7.2 …“ und eine Leerzeile, außer mit --no-header vor -s. Exit-Code:
## - 0: alles gut;
## - 1: Der Katalog hat Fehler, auch in einem Profil; die Ausgabe läuft trotzdem, ohne die
##   fehlerhaften Ereignisse und Start-Modifikatoren.
## - 1: Der Katalog ist nicht lesbar oder ein Argument stimmt nicht; dann gibt es nur die
##   Meldung.
##
## Das Skript braucht keinen Knoten: Katalog und Lauf sind RefCounted. Deshalb geschieht alles in
## _initialize(), und quit() beendet den Lauf mit dem Exit-Code.

const DEFAULT_SEED := 1
## Der größte Seed (FR-014), wie im Autoload Timeline.
const MAX_SEED := 2147483647
const USAGE := "Aufruf: … -s res://tools/werkstatt/fahrplan_ausgabe.gd -- [--seed 4711] " \
	+ "[--grad leicht|mittel|schwer] [--bis 1999-12-31] [--katalog res://…] [--protokoll]"


func _initialize() -> void:
	quit(_print_schedule(OS.get_cmdline_user_args()))


## Liest die Argumente, spielt den Lauf ab und gibt den Text aus. Gibt den Exit-Code zurück.
func _print_schedule(args: PackedStringArray) -> int:
	var options := _read_options(args)
	if options.has("error"):
		printerr("Fehler: %s" % options["error"])
		printerr(USAGE)
		return 1
	var path: String = options["katalog"]
	var issues: Array[CatalogIssue] = []
	var loaded := EventCatalog.read_file(path, issues)
	if loaded == null:
		# Ohne lesbaren Katalog gibt es nichts auszugeben, nur die Meldung mit Zeile oder Pfad.
		for issue in issues:
			printerr("Fehler: %s" % issue.message)
		return 1
	issues.append_array(CatalogValidator.validate(loaded))
	var catalog := loaded.without_faulty(issues)
	var exit_code := 0
	# Wie im Spiel: Ereignisse und Start-Modifikatoren mit Fehlern fehlen im Lauf, und jede Meldung
	# sagt, warum. Den Zusatz zum Ereignis bekommt nur eine Meldung mit Kennung, wie in der
	# Zeitleiste; sonst träfe er auch Meldungen zu Profilen.
	for issue in issues:
		if issue.severity != CatalogIssue.Severity.ERROR:
			continue
		var text := "Fehler: %s" % issue.message
		if not issue.event_id.is_empty() and loaded.get_event(issue.event_id) != null \
				and catalog.get_event(issue.event_id) == null:
			text += " Das Ereignis fehlt in der Ausgabe."
		elif _at_start_modifier(issue):
			text += " Der Start-Modifikator fehlt in der Ausgabe."
		printerr(text)
		exit_code = 1
	# Wer nur wegfällt, weil sein Ereignis fehlt, hat keine eigene Meldung. So steht jeder
	# weggelassene Start-Modifikator genau einmal auf stderr (FR-013; Analyse, G1).
	for skipped in loaded.skipped_start_modifiers(issues):
		if skipped["by_event"]:
			printerr("Fehler: %s: %s" % [skipped["place"], skipped["reason"]])
			exit_code = 1
	var until_day: int = options["bis"]
	var run := TimelineRun.new(catalog, options["seed"], options["grad"] as Difficulty.Level)
	run.advance_to(until_day)
	var lines := ScheduleText.protocol_lines(run) if options["protokoll"] \
		else ScheduleText.plan_lines(run, until_day)
	for line in lines:
		print(line)
	return exit_code


## Die Optionen nach `--` als Dictionary mit seed, grad, bis, katalog und protokoll, mit den
## Vorgaben für alles, was fehlt. Bei einem falschen Argument steht unter "error" der Grund.
func _read_options(args: PackedStringArray) -> Dictionary:
	var options := {
		"seed": DEFAULT_SEED,
		"grad": Difficulty.DEFAULT,
		"bis": TimelineRun.LAST_DAY,
		"katalog": EventCatalog.DEFAULT_PATH,
		"protokoll": false,
	}
	var index := 0
	while index < args.size():
		var argument := args[index]
		index += 1
		if argument == "--protokoll":
			options["protokoll"] = true
			continue
		if not argument in ["--seed", "--grad", "--bis", "--katalog"]:
			return {"error": "Das Argument %s kennt die Textausgabe nicht." % argument}
		if index >= args.size():
			return {"error": "Nach %s fehlt der Wert." % argument}
		var value := args[index]
		index += 1
		match argument:
			"--seed":
				if not _is_seed(value):
					return {"error": "Der Seed %s ist keine ganze Zahl von 0 bis %d." % [value,
						MAX_SEED]}
				options["seed"] = value.to_int()
			"--grad":
				# Groß- und Kleinschreibung zählt: „Schwer“ ist so falsch wie „extrem“ (FR-011).
				var level := Difficulty.from_key(value)
				if not Difficulty.is_valid(level):
					return {"error": ("Den Schwierigkeitsgrad „%s“ gibt es nicht; erlaubt sind "
						+ "leicht, mittel und schwer.") % value}
				options["grad"] = level
			"--bis":
				var date := GameDate.from_iso(value)
				if date == null or date.to_day_index() < TimelineRun.FIRST_DAY \
						or date.to_day_index() > TimelineRun.LAST_DAY:
					return {"error": ("%s ist kein Tag vom 1985-01-01 bis 1999-12-31 in der Form "
						+ "JJJJ-MM-TT.") % value}
				options["bis"] = date.to_day_index()
			"--katalog":
				options["katalog"] = value
	return options


## Ob [param issue] zur Stelle eines Start-Modifikators gehört, Feld „profiles.schwer[2]“ oder
## „profiles.schwer[2].…“; dieselbe Regel wie in without_faulty() und im Autoload Timeline.
static func _at_start_modifier(issue: CatalogIssue) -> bool:
	var single: Array[CatalogIssue] = [issue]
	for level: int in Difficulty.WITH_PROFILE:
		if not DifficultyProfile.faulty_indices(single, level).is_empty():
			return true
	return false


## Ob [param text] ein Seed ist: nur Ziffern, höchstens 2.147.483.647 (FR-014). „+5“ oder „-1“
## sind keiner. Die Länge kommt zuerst, damit eine sehr lange Zahl to_int() nicht überläuft.
static func _is_seed(text: String) -> bool:
	if text.is_empty() or text.length() > 10 or not text.lstrip("0123456789").is_empty():
		return false
	return text.to_int() <= MAX_SEED
