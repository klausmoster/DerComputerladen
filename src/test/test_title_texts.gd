extends GutTest

## Prüft die Texte aus TitleTexts (Feature 004, T019): Jeder Hinweis und jede Meldung passt mit den
## längsten Platzhaltern in höchstens zwei Zeilen des Hinweises; ebenso die Meldungen zum Speichern
## aus GameSession und die Gründe aus SaveGame und SaveSlot (Analyse, C10). Dazu passen Einträge,
## Kopfzeilen und die Zustandswörter in ihre Felder, und die Funktionen füllen die Vorlagen. Seit
## Feature 006 passen auch die Zeilen der Ergebnisanzeige auf die Anzeige und die Punkte neben die
## Leben in der Kopfzeile des Spiels.
##
## Gemessen wird mit dem echten Hinweis aus menu_hint.tscn: dieselbe Schrift aus dem Theme
## (HintLabel), dieselben 150 Pixel für den Text und derselbe Umbruch wie im Spiel. Die Texte holt
## der Test über get_script_constant_map() aus den Skripten, statt sie abzuschreiben; ein neuer
## Hinweis wird also ohne Änderung hier mitgeprüft.

const HINT_SCENE := preload("res://scenes/title/menu_hint.tscn")
const THEMA := preload("res://ui/computerladen_theme.tres")
const TEXTE := preload("res://scenes/title/title_texts.gd")
## GameSession ist ein Autoload ohne class_name; sein Skript kommt über den Pfad.
const SITZUNG := preload("res://core/game_session.gd")
## Die längsten Werte je Platzhalter. Dass sie wirklich die längsten sind, prüft
## test_die_platzhalter_sind_die_laengsten().
const LAENGSTE := {
	"name": "Spiel 9999",
	"grad": "Schwer",
	"datum": "14.03.1986",
	"spieldatum": "14.03.1986",
	"uhrzeit": "21:40",
	"angaben": "Schwer, 14.03.1986",
}
## Style-Guide, Baustein Hinweis: höchstens zwei Zeilen.
const MAX_ZEILEN := 2
## Style-Guide, Baustein Liste: Die Spalten Grad und Spieldatum beginnen bei 64 und 108, die
## nächste bei 172. Ein Zustandswort steht in beiden zusammen.
const ZUSTAND_BREITE := 172 - 64
## Eine beliebige Zeile im Titel, neben die der Hinweis kommt.
const ZEILE := Rect2(472, 170, 144, 20)

var _hinweis: MenuHint


func before_each() -> void:
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	_hinweis = HINT_SCENE.instantiate() as MenuHint
	eigener_viewport.add_child(_hinweis)
	await wait_process_frames(1)


# --- Hinweise und Meldungen -----------------------------------------------

func test_jeder_hinweis_und_jede_meldung_passt_in_zwei_zeilen() -> void:
	# Arrange
	var texte := _hinweise_und_meldungen()

	# Assert: Ohne Texte prüfte der Test nichts. 22 aus TitleTexts, 2 aus GameSession, 3 aus
	# SaveGame, 2 aus SaveSlot.
	assert_eq(texte.size(), 28, "Alle Hinweise und Meldungen gefunden: %s" % [texte.keys()])
	for herkunft: String in texte:
		var text: String = texte[herkunft]
		var zeilen := _zeilen(text)
		assert_false(text.contains("{"), "%s: Platzhalter ungefüllt: „%s“" % [herkunft, text])
		assert_true(zeilen >= 1 and zeilen <= MAX_ZEILEN,
			"%s: „%s“ braucht %d Zeilen." % [herkunft, text, zeilen])
		assert_true(_hinweis.size.x <= 160.0, "%s: höchstens 160 breit." % herkunft)


func test_die_platzhalter_sind_die_laengsten() -> void:
	# Arrange
	var schrift := THEMA.get_font(&"font", &"HintLabel")
	var groesse := THEMA.get_font_size(&"font_size", &"HintLabel")
	var breite := func(text: String) -> float:
		return schrift.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x

	# Assert
	for grad: int in [Difficulty.Level.LEICHT, Difficulty.Level.MITTEL, Difficulty.Level.SCHWER]:
		assert_true(breite.call(LAENGSTE.grad) >= breite.call(Difficulty.label(grad)),
			"„%s“ ist nicht schmaler als „%s“." % [LAENGSTE.grad, Difficulty.label(grad)])
	# Die Angaben in der Rückfrage: Grad und Spieldatum oder ein Zustand.
	assert_eq(LAENGSTE.angaben, TitleTexts.CONFIRM_DETAILS.format(LAENGSTE),
		"Die längsten Angaben sind der längste Grad mit einem Datum.")
	for zustand: String in [TitleTexts.STATE_DAMAGED, TitleTexts.STATE_TOO_NEW]:
		assert_true(breite.call(LAENGSTE.angaben) >= breite.call(zustand), zustand)
	# Alle Ziffern sind gleich breit; jedes Datum und jede Uhrzeit misst also gleich.
	for ziffer in "0123456789":
		assert_eq(breite.call(ziffer), breite.call("9"), "Ziffer %s" % ziffer)


# --- Felder im Menü -------------------------------------------------------

func test_eintraege_passen_in_die_zeile_des_menues() -> void:
	# Arrange: Text ab 24 vom Rand des Papiers, rechts 12 frei (Style-Guide, Baustein Liste;
	# research.md, R11); im Hauptmenü also 108.
	var schrift := THEMA.get_font(&"font", &"MenuRow")
	var groesse := THEMA.get_font_size(&"font_size", &"MenuRow")
	var platz := MainMenu.PAPER_WIDTH - 2 * MainMenu.ROW_INSET \
		- THEMA.get_stylebox(&"normal", &"MenuRow").get_content_margin(SIDE_LEFT)
	var eintraege := _gefuellt("LABEL_")
	# Der Knopf „Zum Hauptmenü“ steht in keinem Menü; seine Größe prüft test_knopf.gd.
	eintraege.erase("TitleTexts.LABEL_LEAVE")
	for grad: int in [Difficulty.Level.LEICHT, Difficulty.Level.MITTEL, Difficulty.Level.SCHWER]:
		eintraege["Difficulty.label(%d)" % grad] = Difficulty.label(grad)

	# Assert
	assert_eq(platz, 108.0, "Voraussetzung: 108 Pixel für den Text.")
	assert_eq(eintraege.size(), 12, "Alle Einträge gefunden: %s" % [eintraege.keys()])
	for herkunft: String in eintraege:
		var breite := schrift.get_string_size(eintraege[herkunft], HORIZONTAL_ALIGNMENT_LEFT, -1,
			groesse).x
		assert_true(breite <= platz,
			"%s: „%s“ ist %d breit." % [herkunft, eintraege[herkunft], breite])


func test_kopfzeilen_passen_ins_blatt() -> void:
	# Arrange: zwischen den Lochrändern eines Blatts von 144, wie die Kopfzeile im Menü.
	var schrift := THEMA.get_font(&"font", &"MenuHeader")
	var groesse := THEMA.get_font_size(&"font_size", &"MenuHeader")
	var platz := MainMenu.PAPER_WIDTH - 2 * MainMenu.ROW_INSET
	var kopfzeilen := _gefuellt("HEADER_")

	# Assert
	assert_eq(kopfzeilen.size(), 5)
	for herkunft: String in kopfzeilen:
		var breite := schrift.get_string_size(kopfzeilen[herkunft], HORIZONTAL_ALIGNMENT_LEFT, -1,
			groesse).x
		assert_true(breite <= platz,
			"%s: „%s“ ist %d breit." % [herkunft, kopfzeilen[herkunft], breite])


func test_zustandswoerter_passen_in_die_spalten_grad_und_spieldatum() -> void:
	var schrift := THEMA.get_font(&"font", &"MenuRow")
	var groesse := THEMA.get_font_size(&"font_size", &"MenuRow")
	for zustand: String in [TitleTexts.STATE_DAMAGED, TitleTexts.STATE_TOO_NEW]:
		var breite := schrift.get_string_size(zustand, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x
		assert_true(breite <= ZUSTAND_BREITE, "„%s“ ist %d breit." % [zustand, breite])


# --- Spiel auf der Anzeige (Feature 006, T016) ----------------------------

func test_zeilen_der_ergebnisanzeige_passen_in_die_anzeige() -> void:
	# Arrange: die Breite der Anzeige ohne den Innenrand von 2 Bildpixeln je Seite (Style-Guide,
	# Spiel auf der Anzeige), also 312. Die Punkte mit drei Stellen, mehr gibt es nicht (640).
	var platz := Communicator.DISPLAY_SIZE.x - 2 * InvadersGame.INSET * InvadersPage.PIXEL
	var zeilen := [
		["Zeile 1, gewonnen", TitleTexts.INVADERS_WON, &"LcdHeader"],
		["Zeile 1, verloren", TitleTexts.INVADERS_LOST, &"LcdHeader"],
		["Zeile 2", TitleTexts.INVADERS_POINTS % 640, &"LcdHeader"],
		["Zeile 3", TitleTexts.INVADERS_CONTINUE, &"LcdRow"],
	]

	# Assert
	assert_eq(platz, 312, "Voraussetzung: 312 Pixel für den Text.")
	for zeile: Array in zeilen:
		var breite := _breite(zeile[1], zeile[2])
		assert_true(breite <= platz, "%s: „%s“ ist %d breit." % [zeile[0], zeile[1], breite])


func test_die_schriften_der_ergebnisanzeige_sind_drucker_und_menue() -> void:
	# Zeilen 1 und 2 wie eine Kopfzeile, Zeile 3 wie ein Eintrag (R10).
	assert_eq(InvadersPage.RESULT_THEME_TYPES,
		[&"LcdHeader", &"LcdHeader", &"LcdRow"] as Array[StringName])
	assert_eq(THEMA.get_font(&"font", &"LcdHeader"), THEMA.get_font(&"font", &"MenuHeader"),
		"drucker wie die Kopfzeilen.")
	assert_eq(THEMA.get_font(&"font", &"LcdRow"), THEMA.get_font(&"font", &"MenuRow"),
		"menue wie die Einträge.")


func test_kopfzeile_mit_den_meisten_punkten_passt_links_neben_drei_leben() -> void:
	# Arrange: die Punkte ab x 2, das erste von drei Leben; beides in Oberflächenpixeln.
	var text := TitleTexts.INVADERS_SCORE % 640
	var anfang := InvadersPage.SCORE_POS.x * InvadersPage.PIXEL
	var erstes_leben := InvadersPage.life_pos(0, InvadersGame.LIVES).x * InvadersPage.PIXEL

	# Assert
	assert_eq(text, "PUNKTE 0640")
	assert_true(anfang + _breite(text, &"LcdHeader") <= erstes_leben,
		"„%s“ endet bei %d, das erste Leben beginnt bei %d."
		% [text, anfang + _breite(text, &"LcdHeader"), erstes_leben])


func test_punkte_mit_und_ohne_fuehrende_nullen() -> void:
	# Führende Nullen nur in der Kopfzeile, wo die Stellenzahl fest ist (R10).
	assert_eq(TitleTexts.INVADERS_SCORE % 0, "PUNKTE 0000")
	assert_eq(TitleTexts.INVADERS_SCORE % 380, "PUNKTE 0380")
	assert_eq(TitleTexts.INVADERS_POINTS % 380, "380 PUNKTE")
	assert_eq(TitleTexts.INVADERS_POINTS % 0, "0 PUNKTE")


# --- Vorlagen füllen ------------------------------------------------------

func test_funktionen_fuellen_die_vorlagen_wie_im_vertrag() -> void:
	assert_eq(TitleTexts.continue_hint("Spiel 2", "Schwer", "14.03.1986"),
		"Weiter mit Spiel 2, Schwer, am 14.03.1986.")
	assert_eq(TitleTexts.slot_hint("13.07.1985", "25.10.2026", "18:40"),
		"Steht am 13.07.1985. Gespielt am 25.10.2026, 18:40 Uhr.")
	assert_eq(TitleTexts.slot_delete_hint("Spiel 2"),
		"Spiel 2 wird gelöscht. Vorher kommt eine Rückfrage.")
	assert_eq(TitleTexts.HINT_DELETE_MODE, "Einen Spielstand löschen. Vorher kommt eine Rückfrage.")
	assert_eq(TitleTexts.delete_label("Spiel 2"), "Spiel 2 löschen")
	assert_eq(TitleTexts.confirm_cancel_hint("Spiel 2", "Schwer", "14.03.1986"),
		"Spiel 2 bleibt: Schwer, 14.03.1986. Esc geht auch.")
	assert_eq(TitleTexts.confirm_delete_hint("Spiel 2", "Schwer", "14.03.1986"),
		"Spiel 2 ist danach weg: Schwer, 14.03.1986. Für immer.")
	assert_eq(TitleTexts.confirm_cancel_hint_unresumable("Spiel 4", TitleTexts.STATE_DAMAGED),
		"Spiel 4 bleibt: beschädigt. Esc geht auch.")
	assert_eq(TitleTexts.confirm_delete_hint_unresumable("Spiel 4", TitleTexts.STATE_DAMAGED),
		"Spiel 4 ist danach weg: beschädigt. Für immer.")
	assert_eq(TitleTexts.confirm_cancel_hint_unresumable("Spiel 9", TitleTexts.STATE_TOO_NEW),
		"Spiel 9 bleibt: neuere Version. Esc geht auch.")
	assert_eq(TitleTexts.confirm_delete_hint_unresumable("Spiel 9", TitleTexts.STATE_TOO_NEW),
		"Spiel 9 ist danach weg: neuere Version. Für immer.")
	assert_eq(TitleTexts.leave_hint("Spiel 2"), "Speichert Spiel 2 und führt ins Hauptmenü.")
	# Feature 008 (S3): Titelbild
	assert_eq(TitleTexts.version_line("0.1"), "V0.1 · PROTOTYP")
	assert_eq(TitleTexts.SUBTITLE, "WIRTSCHAFTSSIMULATION · 1985–1999")
	assert_eq(TitleTexts.STAGE, "PROTOTYP")


func test_saetze_zu_den_graden() -> void:
	# Klaus, 2026-10-26 (research.md, R18, Vorschlag A)
	assert_eq(TitleTexts.difficulty_hint(Difficulty.Level.LEICHT),
		"Das Glück ist eher auf deiner Seite.")
	assert_eq(TitleTexts.difficulty_hint(Difficulty.Level.MITTEL), "Das Glück hält sich raus.")
	assert_eq(TitleTexts.difficulty_hint(Difficulty.Level.SCHWER),
		"Das Glück ist eher auf der Seite der anderen.")
	assert_eq(TitleTexts.difficulty_hint(7), "", "Unbekannter Grad: kein Satz.")


# --- Helfer ---------------------------------------------------------------

## Alle Hinweise und Meldungen mit den längsten Platzhaltern: aus TitleTexts die Konstanten HINT_*
## und MESSAGE_*, aus GameSession MESSAGE_*, aus SaveGame und SaveSlot REASON_*. Schlüssel ist die
## Herkunft, etwa „SaveSlot.REASON_TOO_NEW“.
func _hinweise_und_meldungen() -> Dictionary:
	var texte := _gefuellt("HINT_")
	texte.merge(_gefuellt("MESSAGE_"))
	for quelle: Array in [["GameSession", SITZUNG, "MESSAGE_"], ["SaveGame", SaveGame, "REASON_"],
			["SaveSlot", SaveSlot, "REASON_"]]:
		texte.merge(_konstanten(quelle[0], quelle[1], quelle[2]))
	return texte


## Die Texte aus TitleTexts, deren Name mit [param praefix] beginnt, gefüllt mit LAENGSTE.
func _gefuellt(praefix: String) -> Dictionary:
	var texte := _konstanten("TitleTexts", TEXTE, praefix)
	for herkunft: String in texte.keys():
		texte[herkunft] = (texte[herkunft] as String).format(LAENGSTE)
	return texte


## Die Konstanten vom Typ String aus [param skript], deren Name mit [param praefix] beginnt.
func _konstanten(klasse: String, skript: Script, praefix: String) -> Dictionary:
	var texte := {}
	var alle := skript.get_script_constant_map()
	for konstante: String in alle:
		if konstante.begins_with(praefix) and alle[konstante] is String:
			texte["%s.%s" % [klasse, konstante]] = alle[konstante]
	return texte


## Breite von [param text] in der Schrift der Theme-Variante [param variante], ganze Pixel.
func _breite(text: String, variante: StringName) -> int:
	var schrift := THEMA.get_font(&"font", variante)
	var groesse := THEMA.get_font_size(&"font_size", variante)
	return ceili(schrift.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x)


## Zeigt [param text] im Hinweis und zählt seine Zeilen, wie das Label sie umbricht.
func _zeilen(text: String) -> int:
	_hinweis.show_text(text, ZEILE)
	return (_hinweis.get_node(^"Text") as Label).get_line_count()
