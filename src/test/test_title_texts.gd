extends GutTest

## Prüft die Texte aus TitleTexts (Feature 004, T019): Jeder Hinweis und jede Meldung passt mit den
## längsten Platzhaltern in höchstens zwei Zeilen des Hinweises; ebenso die Meldungen zum Speichern
## aus GameSession und die Gründe aus SaveGame und SaveSlot (Analyse, C10). Dazu passen Einträge,
## Kopfzeilen und die Zustandswörter in ihre Felder, und die Funktionen füllen die Vorlagen.
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
	"zustand": "neuere Version",
	"datum": "14.03.1986",
	"uhrzeit": "21:40",
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

	# Assert: Ohne Texte prüfte der Test nichts. 23 aus TitleTexts, 2 aus GameSession, 3 aus
	# SaveGame, 2 aus SaveSlot.
	assert_eq(texte.size(), 30, "Alle Hinweise und Meldungen gefunden: %s" % [texte.keys()])
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
	for zustand: String in [TitleTexts.STATE_DAMAGED, TitleTexts.STATE_TOO_NEW]:
		assert_true(breite.call(LAENGSTE.zustand) >= breite.call(zustand), zustand)
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


# --- Vorlagen füllen ------------------------------------------------------

func test_funktionen_fuellen_die_vorlagen_wie_im_vertrag() -> void:
	assert_eq(TitleTexts.continue_hint("Spiel 2", "Schwer", "14.03.1986"),
		"Weiter mit Spiel 2, Schwer, am 14.03.1986.")
	assert_eq(TitleTexts.slot_hint("26.10.2026", "21:40"),
		"Zuletzt gespielt am 26.10.2026 um 21:40 Uhr.")
	assert_eq(TitleTexts.slot_delete_hint("Spiel 2"),
		"Spiel 2 wird gelöscht. Vorher fragt das Spiel nach.")
	assert_eq(TitleTexts.delete_label("Spiel 2"), "Spiel 2 löschen")
	assert_eq(TitleTexts.confirm_cancel_hint("Spiel 2", "Schwer", "14.03.1986"),
		"Spiel 2 bleibt: Schwer, 14.03.1986. Esc geht auch.")
	assert_eq(TitleTexts.confirm_delete_hint("Spiel 2", "Schwer", "14.03.1986"),
		"Spiel 2 ist danach weg: Schwer, 14.03.1986. Für immer.")
	assert_eq(TitleTexts.confirm_cancel_hint_unresumable("Spiel 3", TitleTexts.STATE_DAMAGED),
		"Spiel 3, beschädigt, bleibt. Esc geht auch.")
	assert_eq(TitleTexts.confirm_delete_hint_unresumable("Spiel 3", TitleTexts.STATE_TOO_NEW),
		"Spiel 3, neuere Version, ist danach weg. Für immer.")
	assert_eq(TitleTexts.leave_hint("Spiel 2"), "Speichert Spiel 2 und führt ins Hauptmenü.")


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


## Zeigt [param text] im Hinweis und zählt seine Zeilen, wie das Label sie umbricht.
func _zeilen(text: String) -> int:
	_hinweis.show_text(text, ZEILE)
	return (_hinweis.get_node(^"Text") as Label).get_line_count()
