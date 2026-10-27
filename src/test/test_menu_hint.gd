extends GutTest

## Prüft Hinweis und Meldung (Feature 004, T018; Style-Guide, Bausteine Hinweis und Meldung):
## show_text() und show_warning() stellen den Kasten links neben die Zeile, 4 Pixel davor und oben
## bündig, höchstens 160 breit; der Hinweis hat eine Kontur in tusche, die Meldung in kassenrot.
## Eine Meldung bleibt, bis eine andere Zeile kommt.
##
## Der Hinweis steht in einem eigenen Viewport wie die Tests des Menüs. Die Kontur prüft der Test
## über den Kasten, den das Theme dem Hinweis gerade gibt; wie er aussieht, prüft Klaus mit dem
## Auge.

const HINT_SCENE := preload("res://scenes/title/menu_hint.tscn")
const KURZ := "Noch keine Spielstände."
const LANG := "Einen neuen Laden aufmachen. Los geht es am 01.01.1985."
const MELDUNG := "Löschen ging nicht. Der Spielstand ist noch da."
## Eine Zeile des Hauptmenüs an seiner Stelle im Titel, in globalen Koordinaten.
const ZEILE := Rect2(472, 190, 144, 20)
const ANDERE_ZEILE := Rect2(472, 210, 144, 20)

var _hinweis: MenuHint


func before_each() -> void:
	var eigener_viewport := SubViewport.new()
	eigener_viewport.size = Vector2i(640, 360)
	add_child_autofree(eigener_viewport)
	_hinweis = HINT_SCENE.instantiate() as MenuHint
	eigener_viewport.add_child(_hinweis)
	await wait_process_frames(1)


func test_show_text_steht_links_neben_der_zeile() -> void:
	# Act
	_hinweis.show_text(KURZ, ZEILE)

	# Assert
	assert_true(_hinweis.visible, "Der Hinweis erscheint sofort.")
	assert_eq(_hinweis.global_position.x + _hinweis.size.x, ZEILE.position.x - MenuHint.GAP,
		"Die rechte Kante steht 4 Pixel vor der Zeile.")
	assert_eq(_hinweis.global_position.y, ZEILE.position.y, "Oben bündig mit der Zeile.")
	assert_lt(_hinweis.size.x, 160.0, "Ein kurzer Text braucht nicht die ganze Breite.")
	assert_eq(_text().text, KURZ)
	assert_eq(_text().get_line_count(), 1)


func test_langer_text_bricht_um_und_bleibt_160_breit() -> void:
	# Act
	_hinweis.show_text(LANG, ZEILE)

	# Assert: 160 mit Kontur, 150 für den Text; zwei Zeilen zu 14 und oben und unten je 5.
	assert_eq(_hinweis.size, Vector2(160, 2 * 14 + 10), "Höchstens 160 breit, zwei Zeilen.")
	assert_eq(_text().get_line_count(), 2)
	assert_eq(_hinweis.global_position, Vector2(ZEILE.position.x - MenuHint.GAP - 160,
		ZEILE.position.y))


func test_hinweis_hat_kontur_tusche() -> void:
	# Act
	_hinweis.show_text(KURZ, ZEILE)

	# Assert
	var kasten := _kasten()
	assert_eq(_hinweis.theme_type_variation, &"HintPanel")
	assert_eq(kasten.border_color, UiPalette.TUSCHE)
	assert_eq(kasten.bg_color, UiPalette.PAPIER)


func test_show_for_zeigt_den_hinweis_des_eintrags() -> void:
	# Arrange
	var eintrag := MenuEntry.new()
	eintrag.hint = LANG

	# Act
	_hinweis.show_for(eintrag, ZEILE)

	# Assert
	assert_eq(_text().text, LANG)
	assert_eq(_hinweis.global_position.x + _hinweis.size.x, ZEILE.position.x - MenuHint.GAP)
	assert_eq(_hinweis.theme_type_variation, &"HintPanel")


func test_show_warning_hat_kontur_kassenrot_an_der_stelle_des_hinweises() -> void:
	# Arrange
	_hinweis.show_text(KURZ, ZEILE)

	# Act
	_hinweis.show_warning(MELDUNG, ZEILE)

	# Assert
	var kasten := _kasten()
	assert_eq(_hinweis.theme_type_variation, &"WarningPanel")
	assert_eq(kasten.border_color, UiPalette.KASSENROT, "Nur die Kontur ist rot.")
	assert_eq(kasten.bg_color, UiPalette.PAPIER, "Feld papier wie der Hinweis.")
	assert_eq(_text().get_theme_color(&"font_color"), UiPalette.TUSCHE, "Text bleibt tusche.")
	for seite in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		assert_eq(kasten.get_border_width(seite), 1, "Kontur 1 Pixel.")
		assert_eq(kasten.get_content_margin(seite),
			(_hinweis.get_theme_stylebox(&"panel", &"HintPanel")).get_content_margin(seite),
			"Innenabstand wie beim Hinweis.")
	assert_eq(_text().text, MELDUNG)
	assert_eq(_hinweis.size, Vector2(160, 2 * 14 + 10), "Höchstens 160 breit, zwei Zeilen.")
	assert_eq(_hinweis.global_position.x + _hinweis.size.x, ZEILE.position.x - MenuHint.GAP)
	assert_eq(_hinweis.global_position.y, ZEILE.position.y)


func test_meldung_bleibt_bei_derselben_zeile() -> void:
	# Arrange
	_hinweis.show_warning(MELDUNG, ZEILE)

	# Act: Ein Blatt baut seine Zeilen neu und meldet dieselbe Zeile noch einmal.
	_hinweis.show_text(KURZ, ZEILE)

	# Assert
	assert_eq(_text().text, MELDUNG, "Die Meldung bleibt stehen.")
	assert_eq(_hinweis.theme_type_variation, &"WarningPanel")


func test_andere_zeile_ersetzt_die_meldung_durch_den_hinweis() -> void:
	# Arrange
	_hinweis.show_warning(MELDUNG, ZEILE)

	# Act
	_hinweis.show_text(KURZ, ANDERE_ZEILE)

	# Assert
	assert_eq(_text().text, KURZ)
	assert_eq(_hinweis.theme_type_variation, &"HintPanel")
	assert_eq(_kasten().border_color, UiPalette.TUSCHE)
	assert_eq(_hinweis.global_position.y, ANDERE_ZEILE.position.y)


func test_hide_hint_beendet_die_meldung() -> void:
	# Arrange
	_hinweis.show_warning(MELDUNG, ZEILE)

	# Act
	_hinweis.hide_hint()
	var versteckt := not _hinweis.visible
	_hinweis.show_text(KURZ, ZEILE)

	# Assert
	assert_true(versteckt, "hide_hint() blendet die Meldung aus.")
	assert_eq(_text().text, KURZ, "Danach zeigt dieselbe Zeile wieder ihren Hinweis.")
	assert_eq(_hinweis.theme_type_variation, &"HintPanel")


# --- Helfer ---------------------------------------------------------------

func _text() -> Label:
	return _hinweis.get_node(^"Text") as Label


## Der Kasten, den das Theme dem Hinweis gerade gibt: HintPanel oder WarningPanel.
func _kasten() -> StyleBoxFlat:
	return _hinweis.get_theme_stylebox(&"panel") as StyleBoxFlat
