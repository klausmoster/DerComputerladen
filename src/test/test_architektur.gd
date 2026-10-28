extends GutTest

## Prüft die messbaren Regeln des Architektur-Leitfadens `docs/architektur-leitfaden.md`
## (Feature 008, research.md, R6; Vertrag contracts/architektur-tests.md).
##
## - AR-01 und AR-08, Kern ohne Node: Jedes Skript in core/timeline/, core/save/ und in KERNE erbt
##   von RefCounted oder Resource, nennt kein Autoload, ruft weder get_tree() noch
##   Engine.get_main_loop() und keinen globalen Zufall.
## - AR-03, Autoloads sparsam: In project.godot stehen genau die Autoloads aus AUTOLOADS, in dieser
##   Reihenfolge.
## - AR-02, kein Weg nach oben: Kein Skript nennt /root/ oder einen Knotenpfad mit ../, keine Szene
##   ../ oder /root/, außer an den Stellen in ERLAUBT_NACH_OBEN, BIS_BEHEBUNG und VORGEMERKT.
## - AR-14, das Spiel kennt die Werkzeuge nicht: Außerhalb von tools/ verweist nichts auf
##   res://tools/.
##
## Ein kleiner Leser trennt im Quelltext Code, Zeichenketten und Kommentare wie in test_texte.gd.
## Kommentare zählen nie, auch nicht die Zeichenketten in Doku-Kommentaren. Autoloads, get_tree()
## und Zufall zählen nur im Code, Knotenpfade nur in Zeichenketten, res://tools/ in Code und
## Zeichenketten. Eine Zeichenkette mit :// ist ein Dateipfad wie res:// und kein Knotenpfad. In
## Skripten ist eine Zeichenkette nur dann ein Knotenpfad, wenn der Code davor es sagt: ^, $,
## NodePath(, get_node(, get_node_or_null( oder has_node(; "../Resources" in path_join() ist ein
## Dateipfad (Nachprüfung von 007, T035).
##
## Die Prüffunktionen nehmen einen Text, damit die Fehlerprobe sie an erfundenen Texten und an
## Kopien außerhalb des Projekts aufrufen kann. Der Test schreibt nichts.

## Kerne außerhalb von core/timeline/ und core/save/, je mit Grund (AR-01).
const KERNE: Array[String] = [
	"res://core/game_date.gd",
	"res://scenes/title/key_sequence.gd",
	"res://scenes/title/menu_paper.gd",
	"res://scenes/title/title_texts.gd",
	"res://scenes/title/invaders/invaders_game.gd",
	"res://scenes/title/invaders/invaders_sprites.gd",
	"res://ui/ui_palette.gd",
	"res://tools/werkstatt/catalog_editor.gd",
	"res://tools/werkstatt/what_if_probe.gd",
	"res://tools/werkstatt/zebra.gd",
	"res://tools/selbsttest/selbsttest_ablage.gd",
	"res://tools/selbsttest/selbsttest_lauf.gd",
	"res://tools/selbsttest/selbsttest_protokoll.gd",
	"res://tools/selbsttest/selbsttest_texte.gd",
]

## Die Autoloads in dieser Reihenfolge, wie im Leitfaden (AR-03).
const AUTOLOADS: Array[String] = ["GameClock", "Timeline", "GameWindow", "GameSession"]

## Erlaubte Stellen je Prüfung: {"datei": …, "regel": "AR-NN", "grund": …}. Nur begründete
## Ausnahmen aus der Tabelle im Leitfaden.
const ERLAUBT_NACH_OBEN: Array[Dictionary] = [
	{"datei": "res://tools/werkstatt/werkstatt.gd", "regel": "AR-02",
		"grund": "GameWindow über /root/ anhalten; mit -s kennt GDScript den Namen nicht"},
]

## Abweichungen, die Phase 5 behebt. Wird mit Phase 5 leer.
const BIS_BEHEBUNG: Array[Dictionary] = [
	{"datei": "res://tools/selbsttest/selbsttest_ergebnis.gd", "regel": "AR-02",
		"grund": "B1: GameWindow über /root/; Naht kommt in T036a"},
]

## Abweichungen, die Klaus als eigenes Feature vorgemerkt hat: {"datei": …, "regel": "AR-NN",
## "feature": Eintrag in Feature_Ideas.md}. Leert sich mit dem Feature, das sie behebt.
const VORGEMERKT: Array[Dictionary] = []

## Ordner, deren Skripte immer Kerne sind (AR-01).
const KERNORDNER: Array[String] = ["res://core/timeline/", "res://core/save/"]
## Was keine Prüfung durchsucht: GUT und die Tests selbst (Leitfaden, „Geltung“).
const NICHT_GEPRUEFT: Array[String] = ["res://addons", "res://test"]
## Die Werkzeuge; AR-14 gilt für alles außerhalb.
const WERKZEUGE := "res://tools"
## Der Leitfaden liegt außerhalb des Godot-Projekts, eine Ebene über res:// im Repo.
const LEITFADEN := "docs/architektur-leitfaden.md"
## Die Basisklassen, von denen ein Kern erben darf (AR-01).
const KERN_BASIS: Array[String] = ["RefCounted", "Resource"]
## Ohne Objekt davor sind diese Aufrufe globaler Zufall (AR-08).
const GLOBALER_ZUFALL: Array[String] = [
	"randi", "randf", "randi_range", "randf_range", "randfn", "randomize",
]
## Was im Code direkt vor dem öffnenden Anführungszeichen einen Knotenpfad ankündigt (AR-02).
const KNOTENPFAD_DAVOR: Array[String] = ["NodePath", "get_node", "get_node_or_null", "has_node"]
## So beginnt jede Szene im Textformat; daran erkennt wege_nach_oben() eine Szene.
const SZENENKOPF := "[gd_scene"
## Vor und nach einem ganzen Bezeichner steht weder Buchstabe noch Ziffer noch Unterstrich.
## \p{L} schließt Umlaute ein, anders als \b.
const WORTANFANG := "(?<![\\p{L}\\p{N}_])"
const WORTENDE := "(?![\\p{L}\\p{N}_])"

## Das nächste Zeichen, an dem eine Zeichenkette oder ein Kommentar beginnt.
var _naechstes := RegEx.create_from_string("[\"'#]")
## Eine Zeichenkette ab der Suchstelle (\G): " oder ', auch dreifach; \ schützt das Zeichen danach.
var _zeichenkette := RegEx.create_from_string("\\G(?:\"\"\"(?:[^\\\\]|\\\\[\\s\\S])*?\"\"\"" \
	+ "|'''(?:[^\\\\]|\\\\[\\s\\S])*?'''" \
	+ "|\"(?:[^\"\\\\\\n]|\\\\[\\s\\S])*\"" \
	+ "|'(?:[^'\\\\\\n]|\\\\[\\s\\S])*')")
var _kein_umbruch := RegEx.create_from_string("[^\\n]")
## extends mit dem Namen oder Pfad der Basisklasse in Gruppe 1.
var _erbt := RegEx.create_from_string(WORTANFANG
	+ "extends[ \\t]+(\"[^\"\\n]*\"|'[^'\\n]*'|[\\p{L}\\p{N}_.]+)")
var _autoload := RegEx.create_from_string(WORTANFANG + "(" + "|".join(AUTOLOADS) + ")" + WORTENDE)
var _szenenbaum := RegEx.create_from_string(WORTANFANG
	+ "(get_tree|Engine\\s*\\.\\s*get_main_loop)\\s*\\(")
var _zufall := RegEx.create_from_string(WORTANFANG + "(" + "|".join(GLOBALER_ZUFALL) + ")\\s*\\(")
var _mischen := RegEx.create_from_string("\\.\\s*(shuffle|pick_random)\\s*\\(")
## Das öffnende Anführungszeichen eines Knotenpfads im Code: direkt nach ^ oder $, oder als erstes
## Argument von NodePath(, get_node(, get_node_or_null( oder has_node(.
var _knotenpfad := RegEx.create_from_string("(?:[\\^$]|" + WORTANFANG
	+ "(?:" + "|".join(KNOTENPFAD_DAVOR) + ")\\s*\\(\\s*)[\"']")


# --- Die Regeln am Bestand -----------------------------------------------

func test_kerne_ohne_node() -> void:
	# Arrange
	var in_kernordnern := PackedStringArray()
	for ordner in KERNORDNER:
		in_kernordnern.append_array(_dateien(ordner, ["gd"], []))
	var dateien := in_kernordnern.duplicate()
	for pfad in KERNE:
		if pfad not in dateien:
			dateien.append(pfad)

	# Act
	var meldungen := PackedStringArray()
	for pfad in dateien:
		for grund in kern_verstoesse(FileAccess.get_file_as_string(pfad)):
			meldungen.append("%s, %s" % [pfad, grund])

	# Assert: Ohne Dateien prüfte der Test nichts.
	assert_gt(in_kernordnern.size(), 0, "Kein Skript in %s gefunden." % " und ".join(KERNORDNER))
	assert_eq(meldungen.size(), 0, "Diese Kerne verletzen AR-01 oder AR-08:\n"
		+ "\n".join(meldungen))


func test_genau_diese_autoloads() -> void:
	# Arrange
	var pfad := "res://project.godot"
	var projekt := FileAccess.get_file_as_string(pfad)

	# Act
	var autoloads := autoloads_aus(projekt)

	# Assert
	var abschnitt := projekt.find("[autoload]")
	assert_ne(abschnitt, -1, "%s: Abschnitt [autoload] nicht gefunden (AR-03)." % pfad)
	assert_eq(autoloads, AUTOLOADS, "%s:%d: Autoloads %s statt %s; jede Abweichung braucht "
		% [pfad, _zeile(projekt, abschnitt), autoloads, AUTOLOADS]
		+ "Klaus' Freigabe im Plan und eine Zeile in AR-03.")


func test_kein_weg_nach_oben() -> void:
	# Arrange
	var dateien := _dateien("res://", ["gd", "tscn"], NICHT_GEPRUEFT)

	# Act
	var meldungen := PackedStringArray()
	for pfad in dateien:
		var quelltext := FileAccess.get_file_as_string(pfad)
		var zeilen := wege_nach_oben(quelltext)
		var erlaubt := _ausnahmen_nach_oben(pfad).size()
		if zeilen.size() <= erlaubt:
			continue
		var zusatz := ""
		if erlaubt == 1:
			zusatz = ", erlaubt ist 1 Stelle"
		elif erlaubt > 1:
			zusatz = ", erlaubt sind %d Stellen" % erlaubt
		for zeile in zeilen:
			meldungen.append("%s:%d: Weg nach oben über ../ oder /root/%s (AR-02): %s"
				% [pfad, zeile, zusatz, _zeilentext(quelltext, zeile)])

	# Assert
	_assert_skripte_und_szenen(dateien)
	assert_has(dateien, "res://tools/werkstatt/werkstatt.gd", "Die Werkzeuge gehören dazu.")
	assert_eq(meldungen.size(), 0, "Hier greift ein Baustein nach oben:\n" + "\n".join(meldungen))


func test_spiel_kennt_werkzeuge_nicht() -> void:
	# Arrange
	var ausser: Array[String] = [WERKZEUGE]
	ausser.append_array(NICHT_GEPRUEFT)
	var dateien := _dateien("res://", ["gd", "tscn"], ausser)

	# Act
	var meldungen := PackedStringArray()
	for pfad in dateien:
		var quelltext := FileAccess.get_file_as_string(pfad)
		for zeile in verweise_auf_werkzeuge(quelltext):
			meldungen.append("%s:%d: verweist auf res://tools/ (AR-14): %s"
				% [pfad, zeile, _zeilentext(quelltext, zeile)])

	# Assert
	_assert_skripte_und_szenen(dateien)
	assert_eq(meldungen.size(), 0, "Das Spiel kennt hier ein Werkzeug:\n" + "\n".join(meldungen))


func test_listen_ohne_leichen() -> void:
	# Arrange
	var listen := {
		"ERLAUBT_NACH_OBEN": ERLAUBT_NACH_OBEN,
		"BIS_BEHEBUNG": BIS_BEHEBUNG,
		"VORGEMERKT": VORGEMERKT,
	}

	# Act
	var meldungen := PackedStringArray()
	for pfad in KERNE:
		if not FileAccess.file_exists(pfad):
			meldungen.append("KERNE: %s gibt es nicht mehr, bitte streichen (AR-01)." % pfad)
	for liste: String in listen:
		for eintrag: Dictionary in listen[liste]:
			var pfad: String = eintrag.datei
			var regel: String = eintrag.regel
			if not FileAccess.file_exists(pfad):
				meldungen.append("%s: %s gibt es nicht mehr, bitte streichen (%s)."
					% [liste, pfad, regel])
			elif regel != "AR-02":
				meldungen.append("%s: %s steht mit %s da; die Liste gilt nur für AR-02."
					% [liste, pfad, regel])
			else:
				var stellen := wege_nach_oben(FileAccess.get_file_as_string(pfad)).size()
				var eintraege := _ausnahmen_nach_oben(pfad).size()
				if eintraege > stellen:
					meldungen.append("%s: %s, Einträge in den Listen: %d, Wege nach oben: %d; "
						% [liste, pfad, eintraege, stellen] + "bitte überzählige streichen (AR-02).")

	# Assert
	assert_eq(meldungen.size(), 0, "Listen mit Leichen:\n" + "\n".join(meldungen))


func test_ausnahmen_wie_im_leitfaden() -> void:
	# Arrange
	var pfad := ProjectSettings.globalize_path("res://").path_join("..").simplify_path() \
		.path_join(LEITFADEN)
	var leitfaden := FileAccess.get_file_as_string(pfad)

	# Act
	var tabelle := _ausnahmen_im_leitfaden(leitfaden)

	# Assert
	assert_gt(leitfaden.length(), 0, "%s nicht gelesen." % pfad)
	assert_gt(tabelle.size(), 0, "%s: Tabelle „Ausnahmen“ nicht gefunden." % LEITFADEN)
	var abschnitt := _zeile(leitfaden, leitfaden.find("\n## Ausnahmen") + 1)
	for eintrag: Dictionary in ERLAUBT_NACH_OBEN:
		var ort := "`src/%s`" % String(eintrag.datei).trim_prefix("res://")
		var steht_da := tabelle.any(func(zeile: Dictionary) -> bool:
			return String(zeile.ort).contains(ort) and zeile.regel == eintrag.regel)
		assert_true(steht_da, "%s:%d: In der Tabelle „Ausnahmen“ fehlt %s (%s)."
			% [LEITFADEN, abschnitt, ort, eintrag.regel])


# --- Fehlerprobe: Jede Prüffunktion findet den Verstoß, nicht die erlaubte Stelle daneben ---

func test_kern_mit_node_und_autoload_faellt_auf() -> void:
	# Arrange: Verstöße in Zeile 2, 5 und 8; der Kommentar, die Zeichenkette und TimelineRun
	# daneben sind erlaubt.
	var kern := "class_name Probe\n" \
		+ "extends Node\n" \
		+ "## Fragt GameSession nach dem Tag, \"GameSession.date\".\n" \
		+ "func tag() -> int:\n" \
		+ "\treturn GameSession.date.day  # nicht über GameClock\n" \
		+ "func lauf() -> TimelineRun:\n" \
		+ "\tvar name := \"Timeline\"\n" \
		+ "\treturn get_tree().root.get_meta(name)\n"
	var erlaubt := "class_name Probe extends RefCounted\n" \
		+ "## Bekommt den Tag hineingereicht, statt GameClock.date zu lesen.\n" \
		+ "func lauf(run: TimelineRun, wert: GameSessionX) -> int:\n" \
		+ "\treturn run.day + wert.day\n"

	# Act
	var gruende := kern_verstoesse(kern)

	# Assert
	assert_eq(gruende, [
		"Zeile 2: erbt von Node statt von RefCounted oder Resource (AR-01)",
		"Zeile 5: nennt das Autoload GameSession (AR-01)",
		"Zeile 8: ruft get_tree() (AR-01)",
	])
	assert_eq(kern_verstoesse(erlaubt), [],
		"class_name und extends RefCounted in einer Zeile sind ein Kern.")
	assert_eq(kern_verstoesse("class_name Probe\nextends Resource\n"), [])
	assert_eq(kern_verstoesse("var schleife := Engine.get_main_loop()\n"),
		["Zeile 1: ruft Engine.get_main_loop() (AR-01)"])


func test_globaler_zufall_im_kern_faellt_auf() -> void:
	# Arrange: Globaler Zufall in Zeile 5, 6, 7, 8 und 10; Würfe aus einem eigenen Würfel in
	# Zeile 4, im Kommentar und in der Zeichenkette sind erlaubt.
	var kern := "extends RefCounted\n" \
		+ "var _rng := RandomNumberGenerator.new()\n" \
		+ "func wurf(dice: RandomNumberGenerator, werte: Array) -> float:\n" \
		+ "\tvar a := _rng.randf() + dice.randi_range(1, 6) + dice . randfn()\n" \
		+ "\tvar b := randf()\n" \
		+ "\trandomize()  # randf() im Kommentar\n" \
		+ "\twerte.shuffle()\n" \
		+ "\tvar c = werte.pick_random()\n" \
		+ "\tvar d := \"randi()\"\n" \
		+ "\treturn a + b + randi_range(1, 6) + c + d.length()\n"

	# Act
	var gruende := kern_verstoesse(kern)

	# Assert
	assert_eq(gruende, [
		"Zeile 5: ruft globalen Zufall randf() ohne eigenen Würfel (AR-08)",
		"Zeile 6: ruft globalen Zufall randomize() ohne eigenen Würfel (AR-08)",
		"Zeile 7: mischt mit globalem Zufall: .shuffle() (AR-08)",
		"Zeile 8: mischt mit globalem Zufall: .pick_random() (AR-08)",
		"Zeile 10: ruft globalen Zufall randi_range() ohne eigenen Würfel (AR-08)",
	])


func test_fuenftes_autoload_faellt_auf() -> void:
	# Arrange: ein fünftes Autoload „Sound“; das auskommentierte „Lager“ und die Einstellung im
	# nächsten Abschnitt sind keine Autoloads.
	var projekt := "[application]\n\nconfig/name=\"Probe\"\n\n[autoload]\n\n" \
		+ "GameClock=\"*res://core/game_clock.gd\"\n" \
		+ "Timeline=\"*res://core/timeline.gd\"\n" \
		+ "GameWindow=\"*res://core/game_window.gd\"\n" \
		+ "; Lager=\"*res://core/lager.gd\"\n" \
		+ "GameSession=\"*res://core/game_session.gd\"\n" \
		+ "Sound=\"*res://core/sound.gd\"\n\n" \
		+ "[display]\n\nwindow/size/viewport_width=640\n"

	# Act
	var autoloads := autoloads_aus(projekt)

	# Assert
	assert_eq(autoloads, ["GameClock", "Timeline", "GameWindow", "GameSession", "Sound"])
	assert_ne(autoloads, AUTOLOADS)
	assert_eq(autoloads_aus(projekt.replace("Sound=\"*res://core/sound.gd\"\n", "")), AUTOLOADS)


func test_weg_nach_oben_faellt_auf() -> void:
	# Arrange: Wege nach oben in Zeile 3, 5, 7 und 8. Ein Pfad nach unten, res:// und Kommentare
	# sind erlaubt; das # in der Zeichenkette in Zeile 8 beginnt keinen Kommentar.
	var skript := "extends Node\n" \
		+ "func _ready() -> void:\n" \
		+ "\tvar kasse := get_node(\"../Kasse\")\n" \
		+ "\tvar regal := get_node(\"Regal\")  # get_node(\"../Kasse\")\n" \
		+ "\tvar fenster := get_node(^\"/root/GameWindow\")\n" \
		+ "\tvar szene := load(\"res://scenes/game/../game/game_screen.tscn\")\n" \
		+ "\tvar theke := $\"../Theke\"\n" \
		+ "\tprint(\"Taste \\\"#\\\"\"); get_node(\"../Lager\")\n" \
		+ "## Nicht hier: \"../Kasse\" und \"/root/Timeline\"\n"
	var szene := "[gd_scene format=3]\n\n" \
		+ "[ext_resource type=\"Script\" path=\"res://scenes/game/game_screen.gd\" id=\"1\"]\n\n" \
		+ "[node name=\"Regal\" type=\"Node\" parent=\".\"]\n" \
		+ "ziel = NodePath(\"../Kasse\")\n" \
		+ "kind = NodePath(\"Fach/Schraube\")\n"

	# Act
	var im_skript := wege_nach_oben(skript)
	var in_der_szene := wege_nach_oben(szene)

	# Assert
	assert_eq(im_skript, [3, 5, 7, 8])
	assert_eq(in_der_szene, [6])


func test_nur_knotenpfade_greifen_nach_oben() -> void:
	# Arrange: Im Skript greifen die Knotenpfade in Zeile 3 bis 9 nach oben, /root/ als bloße
	# Zeichenkette in Zeile 10. Die Dateipfade in Zeile 11 bis 13 sind erlaubt. In der Szene zählt
	# ../ in Zeile 4 und 5 in jeder Zeichenkette; nur der Dateipfad in Zeile 6 nicht.
	var skript := "extends Node\n" \
		+ "func _ready() -> void:\n" \
		+ "\tvar a := get_node(\"../Kasse\")\n" \
		+ "\tvar b := get_node_or_null(\"../Kasse\")\n" \
		+ "\tvar c := has_node(\"../Kasse\")\n" \
		+ "\tvar d := $\"../Kasse\"\n" \
		+ "\tvar e := ^\"../Kasse\"\n" \
		+ "\tvar f := NodePath(\"../Kasse\")\n" \
		+ "\tvar g := get_node( '../Lager' )\n" \
		+ "\tvar h := \"/root/GameWindow\"\n" \
		+ "\tvar i := OS.get_executable_path().get_base_dir().path_join(\"../Resources\")\n" \
		+ "\tvar ordner := \"../daten\"\n" \
		+ "\tvar j := load(\"res://../x\")\n"
	var szene := "[gd_scene format=3]\n\n" \
		+ "[node name=\"Regal\" type=\"Node\" parent=\".\"]\n" \
		+ "node_path = NodePath(\"../Kasse\")\n" \
		+ "text = \"../daten\"\n" \
		+ "bild = \"res://../x\"\n"

	# Act
	var im_skript := wege_nach_oben(skript)
	var in_der_szene := wege_nach_oben(szene)
	# Ohne den Kopf [gd_scene liest die Funktion denselben Text als Skript.
	var ohne_kopf := wege_nach_oben(szene.replace("[gd_scene format=3]", ""))

	# Assert
	assert_eq(im_skript, [3, 4, 5, 6, 7, 8, 9, 10])
	assert_eq(in_der_szene, [4, 5])
	assert_eq(ohne_kopf, [4])


func test_verweis_auf_werkzeug_faellt_auf() -> void:
	# Arrange: Verweise auf ein Werkzeug in Zeile 5 des Skripts und Zeile 3 der Szene. Der
	# Doku-Kommentar, ein Kern unter core/ und ein Ordner, der nur ähnlich heißt, sind erlaubt.
	var skript := "extends Node\n" \
		+ "## Lädt nicht res://tools/werkstatt/zebra.gd, sondern ein Datum.\n" \
		+ "const DATUM := preload(\"res://core/game_date.gd\")\n" \
		+ "func _ready() -> void:\n" \
		+ "\tvar zebra = load(\"res://tools/werkstatt/zebra.gd\")\n" \
		+ "\tvar ort := \"res://toolsammlung/\"\n"
	var szene := "[gd_scene format=3]\n\n" \
		+ "[ext_resource type=\"Script\" path=\"res://tools/werkstatt/zebra.gd\" id=\"1\"]\n" \
		+ "[ext_resource type=\"Script\" path=\"res://core/game_date.gd\" id=\"2\"]\n"

	# Act
	var im_skript := verweise_auf_werkzeuge(skript)
	var in_der_szene := verweise_auf_werkzeuge(szene)

	# Assert
	assert_eq(im_skript, [5])
	assert_eq(in_der_szene, [3])


# --- Prüffunktionen --------------------------------------------------------

## Gründe, warum [param quelltext] kein Kern ist, je als „Zeile N: … (AR-NN)“ und nach Zeilen
## sortiert; leer heißt Kern (AR-01, AR-08). Ein Skript ohne extends erbt von RefCounted. Würfe
## mit einem Objekt davor wie dice.randf() kommen aus einem eigenen Würfel und sind erlaubt.
func kern_verstoesse(quelltext: String) -> Array[String]:
	var code: String = _lies(quelltext).code
	var funde: Array[Dictionary] = []
	for erbt in _erbt.search_all(code):
		# Im Code ist der Inhalt einer Zeichenkette leer; den Pfad liest die Meldung im Original.
		var basis := quelltext.substr(erbt.get_start(1), erbt.get_end(1) - erbt.get_start(1))
		if basis not in KERN_BASIS:
			funde.append(_fund(erbt.get_start(),
				"erbt von %s statt von RefCounted oder Resource (AR-01)" % basis))
	for autoload in _autoload.search_all(code):
		funde.append(_fund(autoload.get_start(),
			"nennt das Autoload %s (AR-01)" % autoload.get_string()))
	for aufruf in _szenenbaum.search_all(code):
		var welcher := "get_tree()" if aufruf.get_string(1) == "get_tree" \
			else "Engine.get_main_loop()"
		funde.append(_fund(aufruf.get_start(), "ruft %s (AR-01)" % welcher))
	for aufruf in _zufall.search_all(code):
		var davor := _davor(code, aufruf.get_start())
		var global := davor.ends_with("@GlobalScope.") or not davor.ends_with(".")
		if global and not davor.ends_with("func"):
			funde.append(_fund(aufruf.get_start(), "ruft globalen Zufall %s() ohne eigenen Würfel "
				% aufruf.get_string(1) + "(AR-08)"))
	for aufruf in _mischen.search_all(code):
		funde.append(_fund(aufruf.get_start(),
			"mischt mit globalem Zufall: .%s() (AR-08)" % aufruf.get_string(1)))
	funde.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.stelle < b.stelle)
	var gruende: Array[String] = []
	for fund in funde:
		gruende.append("Zeile %d: %s" % [_zeile(code, fund.stelle), fund.grund])
	return gruende


## Die Namen der Autoloads im Abschnitt [autoload] von [param project_godot], in ihrer
## Reihenfolge (AR-03). Zeilen mit ; oder # am Anfang sind Kommentare.
func autoloads_aus(project_godot: String) -> Array[String]:
	var namen: Array[String] = []
	var im_abschnitt := false
	for zeile in project_godot.split("\n"):
		var text := zeile.strip_edges()
		if text.begins_with("["):
			im_abschnitt = text == "[autoload]"
		elif im_abschnitt and text.contains("=") and not text.begins_with(";") \
				and not text.begins_with("#"):
			namen.append(text.left(text.find("=")).strip_edges())
	return namen


## Zeilen, in denen [param quelltext] nach oben greift, sortiert (AR-02). Zeichenketten mit :// sind
## Dateipfade wie res:// und zählen nie.
## - In einem Skript zählt /root/ in jeder Zeichenkette, ../ nur in einem Knotenpfad: einer
##   Zeichenkette direkt nach ^ oder $ oder als Argument von NodePath(), get_node(),
##   get_node_or_null() und has_node(). "../Resources" in path_join() ist ein Dateipfad.
## - In einer Szene, einem Text, der mit [gd_scene beginnt, zählen ../ und /root/ in jeder
##   Zeichenkette ohne ://, wie bisher.
func wege_nach_oben(quelltext: String) -> Array[int]:
	var gelesen := _lies(quelltext)
	var ist_szene := quelltext.begins_with(SZENENKOPF)
	var knotenpfade := {}
	for fund in _knotenpfad.search_all(gelesen.code):
		knotenpfade[fund.get_end() - 1] = true
	var zeilen: Array[int] = []
	for kette: Dictionary in gelesen.ketten:
		var text: String = kette.text
		if text.contains("://"):
			continue
		var gesucht: Array[String] = ["/root/"]
		if ist_szene or knotenpfade.has(kette.oeffnet):
			gesucht.push_front("../")
		for muster in gesucht:
			var stelle := text.find(muster)
			while stelle != -1:
				var zeile := _zeile(quelltext, kette.anfang + stelle)
				if zeile not in zeilen:
					zeilen.append(zeile)
				stelle = text.find(muster, stelle + 1)
	zeilen.sort()
	return zeilen


## Zeilen mit res://tools/ außerhalb von Kommentaren, sortiert (AR-14).
func verweise_auf_werkzeuge(quelltext: String) -> Array[int]:
	var text: String = _lies(quelltext).ohne_kommentare
	var zeilen: Array[int] = []
	var stelle := text.find("res://tools/")
	while stelle != -1:
		var zeile := _zeile(text, stelle)
		if zeile not in zeilen:
			zeilen.append(zeile)
		stelle = text.find("res://tools/", stelle + 1)
	return zeilen


# --- Helfer ---------------------------------------------------------------

## Der kleine Leser: zerlegt [param quelltext] in
## - "code": Kommentare und der Inhalt jeder Zeichenkette sind Leerzeichen, die Anführungszeichen
##   bleiben stehen,
## - "ohne_kommentare": nur die Kommentare sind Leerzeichen,
## - "ketten": je Zeichenkette ihr Inhalt ("text"), wo er im Quelltext beginnt ("anfang") und wo
##   das öffnende Anführungszeichen steht ("oeffnet").
## Zeilenumbrüche bleiben überall stehen; eine Stelle hat in allen Fassungen dieselbe Zeile. Ein #
## außerhalb einer Zeichenkette beginnt einen Kommentar bis zum Zeilenende, wie in test_texte.gd.
func _lies(quelltext: String) -> Dictionary:
	var code := PackedStringArray()
	var ohne_kommentare := PackedStringArray()
	var ketten: Array[Dictionary] = []
	var i := 0
	while i < quelltext.length():
		var fund := _naechstes.search(quelltext, i)
		var stelle := quelltext.length() if fund == null else fund.get_start()
		code.append(quelltext.substr(i, stelle - i))
		ohne_kommentare.append(quelltext.substr(i, stelle - i))
		if fund == null:
			break
		if quelltext[stelle] == "#":
			var ende := quelltext.find("\n", stelle)
			if ende == -1:
				ende = quelltext.length()
			var leer := " ".repeat(ende - stelle)
			code.append(leer)
			ohne_kommentare.append(leer)
			i = ende
			continue
		var kette := _zeichenkette.search(quelltext, stelle)
		if kette == null:
			# Ohne Ende ist das Anführungszeichen keine Zeichenkette; es zählt als Code.
			code.append(quelltext[stelle])
			ohne_kommentare.append(quelltext[stelle])
			i = stelle + 1
			continue
		var roh := kette.get_string()
		var breite := 3 if roh.length() >= 6 and roh.begins_with(roh[0].repeat(3)) else 1
		var inhalt := roh.substr(breite, roh.length() - 2 * breite)
		ketten.append({"text": inhalt, "anfang": stelle + breite, "oeffnet": stelle})
		code.append(roh.left(breite) + _kein_umbruch.sub(inhalt, " ", true) + roh.right(breite))
		ohne_kommentare.append(roh)
		i = stelle + roh.length()
	return {"code": "".join(code), "ohne_kommentare": "".join(ohne_kommentare), "ketten": ketten}


## Die Zeile (ab 1) der Stelle [param stelle] in [param text].
func _zeile(text: String, stelle: int) -> int:
	return text.substr(0, stelle).count("\n") + 1


func _zeilentext(quelltext: String, zeile: int) -> String:
	return quelltext.split("\n")[zeile - 1].strip_edges()


## Der Code direkt vor [param stelle], ohne Leerraum am Ende; genug, um ein Objekt mit Punkt,
## @GlobalScope. oder func davor zu erkennen.
func _davor(code: String, stelle: int) -> String:
	var anfang := maxi(stelle - 20, 0)
	return code.substr(anfang, stelle - anfang).strip_edges(false, true)


func _fund(stelle: int, grund: String) -> Dictionary:
	return {"stelle": stelle, "grund": grund}


## Alle Dateien mit diesen Endungen unter [param ordner], rekursiv und sortiert, als res://-Pfade.
## Ordner in [param ausser] und versteckte wie .godot bleiben draußen.
func _dateien(ordner: String, endungen: Array[String], ausser: Array[String]) -> PackedStringArray:
	var dateien := PackedStringArray()
	_sammle(ordner, endungen, ausser, dateien)
	dateien.sort()
	return dateien


func _sammle(ordner: String, endungen: Array[String], ausser: Array[String],
		dateien: PackedStringArray) -> void:
	for datei in DirAccess.get_files_at(ordner):
		if datei.get_extension() in endungen:
			dateien.append(ordner.path_join(datei))
	for unterordner in DirAccess.get_directories_at(ordner):
		var pfad := ordner.path_join(unterordner)
		if not unterordner.begins_with(".") and pfad not in ausser:
			_sammle(pfad, endungen, ausser, dateien)


## Die Einträge aus ERLAUBT_NACH_OBEN, BIS_BEHEBUNG und VORGEMERKT zu AR-02 für diese Datei. Jeder
## Eintrag erlaubt eine Stelle.
func _ausnahmen_nach_oben(pfad: String) -> Array[Dictionary]:
	var alle: Array[Dictionary] = []
	for liste: Array[Dictionary] in [ERLAUBT_NACH_OBEN, BIS_BEHEBUNG, VORGEMERKT]:
		for eintrag in liste:
			if eintrag.datei == pfad and eintrag.regel == "AR-02":
				alle.append(eintrag)
	return alle


## Die Zeilen der Tabelle unter „## Ausnahmen“ im Leitfaden: je Zeile "ort" und "regel", ohne
## Kopf und Trennlinie.
func _ausnahmen_im_leitfaden(leitfaden: String) -> Array[Dictionary]:
	var zeilen: Array[Dictionary] = []
	var im_abschnitt := false
	for zeile in leitfaden.split("\n"):
		if zeile.begins_with("## "):
			im_abschnitt = zeile.strip_edges() == "## Ausnahmen"
		elif im_abschnitt and zeile.begins_with("|"):
			var zellen := zeile.split("|")
			var ort := zellen[1].strip_edges()
			if zellen.size() > 3 and ort != "Ort" and not ort.begins_with("---"):
				zeilen.append({"ort": ort, "regel": zellen[2].strip_edges()})
	return zeilen


func _assert_skripte_und_szenen(dateien: PackedStringArray) -> void:
	var endungen := Array(dateien).map(func(pfad: String) -> String: return pfad.get_extension())
	assert_has(endungen, "tscn", "Keine Szene gefunden.")
	assert_has(endungen, "gd", "Kein Skript gefunden.")
