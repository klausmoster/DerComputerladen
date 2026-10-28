extends GutTest

## Prüft die Anrede in den Texten von Spiel und Werkzeugen (KI-Workflow, Schritt 7).
##
## Style-Guide, Sprache › Anrede: Bedienung, Hinweise, Meldungen und Tooltips duzen. Figuren,
## Briefe und Bescheide in der Spielwelt dürfen siezen; solche Texte gibt es heute noch nicht.
##
## Durchsucht werden die Szenen und Skripte unter res://scenes/, res://tools/werkstatt/ und
## res://core/: in .tscn die Werte der Texteigenschaften, in .gd alle Zeichenketten außerhalb von
## Kommentaren. Ein Treffer ist ein Wort der höflichen Anrede als ganzes Wort und großgeschrieben,
## auch ganz in Versalien wie in der Ergebnisanzeige des Spiels auf der Anzeige („SIE“, „IHNEN“;
## Feature 006, Analyse, U7). „sie“ und „ihr“ klein sind die dritte Person und bleiben
## unbeanstandet; „Sieben“ und „Ihringen“ sind keine ganzen Wörter der Anrede.
##
## Großgeschrieben steht „Sie“ auch am Satzanfang, dann meint es oft die Mehrzahl. Solche Stellen
## kommen mit Grund in ERLAUBT. Ein eigener Test meldet Einträge, die es nicht mehr gibt.
##
## Die Prüffunktionen nehmen einen Pfad oder einen Text, damit sich auch eine Kopie außerhalb des
## Projekts prüfen lässt. Der Test schreibt nichts.

const ORDNER := ["res://scenes/", "res://tools/werkstatt/", "res://core/"]
## Eigenschaften in .tscn, deren Wert Text für Menschen ist. Bei Schlüsseln mit Pfad wie
## popup/item_0/text zählt der letzte Teil.
const TEXTEIGENSCHAFTEN := [
	"text", "tooltip_text", "placeholder_text", "title", "dialog_text", "hint", "label",
	"ok_button_text", "cancel_button_text",
]
## Die Wörter der höflichen Anrede als ganzes Wort: weder davor noch danach ein Buchstabe, eine
## Ziffer oder ein Unterstrich. \p{L} schließt Umlaute ein, anders als \b.
## Dieselben Wörter auch ganz in Versalien.
const ANREDE := "(?<![\\p{L}\\p{N}_])" + "(Sie|Ihnen|Ihr|Ihre|Ihrem|Ihren|Ihrer|Ihres" \
	+ "|SIE|IHNEN|IHR|IHRE|IHREM|IHREN|IHRER|IHRES)" + "(?![\\p{L}\\p{N}_])"
## Stellen, an denen ein Wort der Anrede steht, ohne zu siezen: Datei relativ zu res://, ein
## eindeutiger Ausschnitt der Zeichenkette, der das Wort enthält, und der Grund.
const ERLAUBT := [
	{
		"datei": "tools/werkstatt/statistics_panel.gd",
		"ausschnitt": "Keine Obergrenze: Sie gibt es nur bei Ereignissen",
		"grund": "„sie“ meint die Mehrzahl, großgeschrieben nach dem Doppelpunkt.",
	},
]

var _anrede := RegEx.create_from_string(ANREDE)
var _eigenschaft := RegEx.create_from_string("(?m)^([A-Za-z0-9_/]+) = \"")


func test_spiel_und_werkzeuge_siezen_nicht() -> void:
	# Arrange
	var dateien := _dateien()

	# Act
	var unerlaubt := PackedStringArray()
	for treffer in _treffer_in_dateien(dateien):
		if not _ist_erlaubt(treffer):
			unerlaubt.append(_als_zeile(treffer))

	# Assert: Ohne Dateien prüfte der Test nichts.
	var endungen := Array(dateien).map(func(pfad: String) -> String: return pfad.get_extension())
	assert_has(endungen, "tscn", "Keine Szene gefunden.")
	assert_has(endungen, "gd", "Kein Skript gefunden.")
	assert_eq(unerlaubt.size(), 0, "Hier wird gesiezt:\n" + "\n".join(unerlaubt))


func test_jede_erlaubte_stelle_gibt_es_noch() -> void:
	# Arrange
	var alle := _treffer_in_dateien(_dateien())

	# Assert
	for eintrag: Dictionary in ERLAUBT:
		var gefunden := alle.any(func(treffer: Dictionary) -> bool:
			return _passt_zu(treffer, eintrag))
		assert_true(gefunden, "Erlaubte Stelle nicht mehr gefunden, bitte aus ERLAUBT streichen: "
			+ "%s, „%s“" % [eintrag.datei, eintrag.ausschnitt])


func test_anrede_wird_in_skript_und_szene_gefunden() -> void:
	# Arrange
	var skript := "func _ready() -> void:\n\tvar a := \"Bitte wählen Sie eine Ware\"\n" \
		+ "\tvar b := tr('Geben Sie den Preis ein')\n"
	var szene := "[node name=\"Konto\" type=\"Label\" parent=\".\"]\ntext = \"Ihr Konto\"\n"

	# Act
	var im_skript := _treffer_im_skript(skript, "probe.gd")
	var in_der_szene := _treffer_in_der_szene(szene, "probe.tscn")

	# Assert
	assert_eq(im_skript.map(func(t: Dictionary) -> Array: return [t.zeile, t.wort]),
		[[2, "Sie"], [3, "Sie"]])
	assert_eq(in_der_szene.map(func(t: Dictionary) -> Array: return [t.zeile, t.wort]),
		[[2, "Ihr"]])
	assert_string_contains(_als_zeile(in_der_szene[0]), "probe.tscn:2")
	assert_string_contains(_als_zeile(in_der_szene[0]), "Ihr Konto")


func test_anrede_in_versalien_wird_gefunden() -> void:
	# Arrange: Versalien wie in der Ergebnisanzeige; „SIE SIND GELANDET.“ war ein früherer Wortlaut
	# und las sich wie die Anrede (R10). Dazu Wörter, die nur so anfangen.
	var skript := "var a := \"SIE SIND GELANDET.\"\nvar b := \"DANKE IHNEN.\"\n" \
		+ "var c := \"IHR LADEN, IHRE KASSE\"\nvar d := \"SIEBEN SIEGER, ALLE ERWISCHT.\"\n"
	var szene := "text = \"GAME OVER\"\ntooltip_text = \"IHRES ZEICHENS\"\n"

	# Act
	var im_skript := _treffer_im_skript(skript, "probe.gd")
	var in_der_szene := _treffer_in_der_szene(szene, "probe.tscn")

	# Assert
	assert_eq(im_skript.map(func(t: Dictionary) -> Array: return [t.zeile, t.wort]),
		[[1, "SIE"], [2, "IHNEN"], [3, "IHR"], [3, "IHRE"]])
	assert_eq(in_der_szene.map(func(t: Dictionary) -> Array: return [t.zeile, t.wort]),
		[[2, "IHRES"]])


func test_harmlose_saetze_bleiben_unbeanstandet() -> void:
	# Arrange
	var skript := "var a := [\"Die Lieferung ist da\", \"Sieben Kartons\", \"Ihringen\"]\n"
	var szene := "text = \"Die Lieferung ist da\"\n" \
		+ "tooltip_text = \"Sieben Kartons nach Ihringen\"\n"

	# Assert
	assert_eq(_treffer_im_skript(skript, "probe.gd"), [])
	assert_eq(_treffer_in_der_szene(szene, "probe.tscn"), [])


func test_kommentare_zaehlen_nicht_zeichenketten_ueber_mehrere_zeilen_schon() -> void:
	# Arrange: Kommentare mit Anführungszeichen, ein # in einer Zeichenkette, eine Zeichenkette
	# über drei Zeilen und ein Zeilenumbruch als \n direkt vor dem Wort.
	var skript := "## Sie liest die Datei.\n# \"Sie\" im Kommentar\nvar f := \"#Farbe\" # Ihr\n" \
		+ "var g := \"\"\"Erste Zeile\nzweite Zeile\nIhre Ware\"\"\"\nvar h := \"Hallo\\nSie da\"\n"
	var szene := "title = \"Erste Zeile\nSie sind dran\"\nname = \"Sie\"\n"

	# Act
	var im_skript := _treffer_im_skript(skript, "probe.gd")
	var in_der_szene := _treffer_in_der_szene(szene, "probe.tscn")

	# Assert: name ist keine Texteigenschaft.
	assert_eq(im_skript.map(func(t: Dictionary) -> Array: return [t.zeile, t.wort]),
		[[6, "Ihre"], [7, "Sie"]])
	assert_eq(in_der_szene.map(func(t: Dictionary) -> Array: return [t.zeile, t.wort]),
		[[2, "Sie"]])


# --- Helfer ---------------------------------------------------------------

## Alle .gd- und .tscn-Dateien unter ORDNER, rekursiv und sortiert, als res://-Pfade.
func _dateien() -> PackedStringArray:
	var dateien := PackedStringArray()
	for ordner: String in ORDNER:
		_sammle(ordner, dateien)
	dateien.sort()
	return dateien


func _sammle(ordner: String, dateien: PackedStringArray) -> void:
	for datei in DirAccess.get_files_at(ordner):
		if datei.get_extension() in ["gd", "tscn"]:
			dateien.append(ordner.path_join(datei))
	for unterordner in DirAccess.get_directories_at(ordner):
		_sammle(ordner.path_join(unterordner), dateien)


func _treffer_in_dateien(dateien: PackedStringArray) -> Array[Dictionary]:
	var alle: Array[Dictionary] = []
	for pfad in dateien:
		alle.append_array(_treffer_in_datei(pfad, pfad.trim_prefix("res://")))
	return alle


## Treffer in einer Datei (res:// oder absoluter Pfad); [param name] steht in den Meldungen.
func _treffer_in_datei(pfad: String, name: String) -> Array[Dictionary]:
	var inhalt := FileAccess.get_file_as_string(pfad)
	if pfad.get_extension() == "tscn":
		return _treffer_in_der_szene(inhalt, name)
	return _treffer_im_skript(inhalt, name)


## Treffer in den Zeichenketten eines Skripts. Ein # außerhalb einer Zeichenkette beginnt einen
## Kommentar bis zum Zeilenende; der Rest der Zeile zählt nicht.
func _treffer_im_skript(quelltext: String, name: String) -> Array[Dictionary]:
	var treffer: Array[Dictionary] = []
	var i := 0
	var zeile := 1
	while i < quelltext.length():
		var zeichen := quelltext[i]
		if zeichen == "\n":
			zeile += 1
			i += 1
		elif zeichen == "#":
			var ende := quelltext.find("\n", i)
			i = quelltext.length() if ende == -1 else ende
		elif zeichen == "\"" or zeichen == "'":
			var kette := _lies_zeichenkette(quelltext, i)
			treffer.append_array(_treffer_im_text(kette.text, name, zeile))
			zeile += kette.zeilen
			i = kette.ende
		else:
			i += 1
	return treffer


## Treffer in den Texteigenschaften einer Szene. Godot schreibt sie als Zeile `schluessel = "…"`;
## der Wert darf echte Zeilenumbrüche enthalten.
func _treffer_in_der_szene(quelltext: String, name: String) -> Array[Dictionary]:
	# Der Reihe nach: Nach jedem Wert geht die Suche hinter seinem Ende weiter, damit eine Zeile
	# mitten in einem mehrzeiligen Wert nie als neue Eigenschaft gilt.
	var treffer: Array[Dictionary] = []
	var eigenschaft := _eigenschaft.search(quelltext)
	while eigenschaft:
		var anfang := eigenschaft.get_end() - 1
		var kette := _lies_zeichenkette(quelltext, anfang)
		if eigenschaft.get_string(1).get_file() in TEXTEIGENSCHAFTEN:
			var zeile := quelltext.substr(0, anfang).count("\n") + 1
			treffer.append_array(_treffer_im_text(kette.text, name, zeile))
		eigenschaft = _eigenschaft.search(quelltext, kette.ende)
	return treffer


## Liest die Zeichenkette, deren Anführungszeichen bei [param anfang] steht: " oder ', auch
## dreifach. Ergebnis: Inhalt, Zahl der Zeilenumbrüche darin und die Stelle hinter dem Ende.
## Ein Escape wie \n oder \t wird zu einem Leerzeichen, damit das Wort danach als ganzes Wort
## zählt und die Zeilen im Inhalt die Zeilen der Datei bleiben.
func _lies_zeichenkette(quelltext: String, anfang: int) -> Dictionary:
	var zeichen := quelltext[anfang]
	var ende_zeichen := zeichen.repeat(3) if quelltext.substr(anfang, 3) == zeichen.repeat(3) \
		else zeichen
	var i := anfang + ende_zeichen.length()
	var text := ""
	while i < quelltext.length() and quelltext.substr(i, ende_zeichen.length()) != ende_zeichen:
		var c := quelltext[i]
		if c == "\\" and i + 1 < quelltext.length():
			var folgt := quelltext[i + 1]
			text += folgt if folgt in ["\\", "\"", "'", "\n"] else " "
			i += 2
		else:
			text += c
			i += 1
	return {"text": text, "zeilen": text.count("\n"), "ende": i + ende_zeichen.length()}


## Die Wörter der Anrede in [param text], der in Zeile [param erste_zeile] beginnt.
func _treffer_im_text(text: String, name: String, erste_zeile: int) -> Array[Dictionary]:
	var treffer: Array[Dictionary] = []
	for wort in _anrede.search_all(text):
		treffer.append({
			"datei": name,
			"zeile": erste_zeile + text.substr(0, wort.get_start()).count("\n"),
			"wort": wort.get_string(),
			"text": text,
			"stelle": wort.get_start(),
		})
	return treffer


func _ist_erlaubt(treffer: Dictionary) -> bool:
	return ERLAUBT.any(func(eintrag: Dictionary) -> bool: return _passt_zu(treffer, eintrag))


## Ob das Wort des Treffers im Ausschnitt des Eintrags steht, nicht nur irgendwo in derselben
## Zeichenkette.
func _passt_zu(treffer: Dictionary, eintrag: Dictionary) -> bool:
	if treffer.datei != eintrag.datei:
		return false
	var ausschnitt: String = eintrag.ausschnitt
	var stelle: int = treffer.text.find(ausschnitt)
	while stelle != -1:
		if stelle <= treffer.stelle and treffer.stelle < stelle + ausschnitt.length():
			return true
		stelle = treffer.text.find(ausschnitt, stelle + 1)
	return false


func _als_zeile(treffer: Dictionary) -> String:
	return "%s:%d: „%s“ (%s)" % [treffer.datei, treffer.zeile, treffer.text, treffer.wort]
