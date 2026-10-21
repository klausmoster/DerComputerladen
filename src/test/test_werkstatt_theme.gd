extends GutTest

## Prüft das Theme der Werkstatt und seinen Reliefkasten (Feature 002, T031) gegen den Style-Guide,
## Abschnitt „Werkzeuge“: Farben nur aus UiPalette, eckig, ohne Verlauf, weichen Schatten und
## Transparenz, Abstände aus 4, 8 und 16, Schriftgrößen 14, 12 und 16.
##
## Eine .tres-Datei kann keine Konstante aus UiPalette nennen; die Farben stehen dort als Werte.
## Dieser Test ist deshalb die Stelle, die dafür sorgt, dass sie mit der Palette übereinstimmen,
## auch nachdem jemand das Theme im Editor geändert hat.
##
## Wie das Theme wirklich aussieht, prüft Klaus von Hand (quickstart.md, Abschnitt 4.1). Headless
## zeichnet Godot nichts Sichtbares; den Reliefkasten prüfen die Tests deshalb über die Liste der
## Rechtecke, die er zeichnen würde (ReliefStyleBox.layers()).

const THEMA := preload("res://tools/werkstatt/werkstatt_theme.tres")
const MAGENTA := Color(1, 0, 1)
## Konstanten, die keine Abstände sind: ein Schalter, eine Höhe und Lagen eines Symbols.
const KEINE_ABSTAENDE := ["modulate_arrow", "title_height", "close_h_offset", "close_v_offset"]
## Die Farbrollen aus dem Style-Guide, Abschnitt „Werkzeuge“, Tabelle „Farbrollen“.
const FARBROLLEN := {
	&"background": &"papier",
	&"alternate_row": &"endlos-gruen",
	&"surface": &"gehaeuse",
	&"text": &"tusche",
	&"muted_text": &"gehaeuse-dunkel",
	&"hover": &"signalgelb",
	&"selection": &"petrol",
	&"selection_text": &"papier",
	&"error": &"kassenrot",
	&"error_text": &"papier",
	&"warning": &"holz",
	&"drag": &"signalgelb",
	&"focus": &"tusche",
}


# --- Theme ------------------------------------------------------------------------------------

func test_schriftgroessen_und_keine_schriftdatei() -> void:
	# Die Schrift (Open Sans SemiBold aus ThemeDB.fallback_font) setzt die Werkstatt per Code; sie
	# ist eingebaut und hat keine Datei, die das Theme nennen könnte.
	assert_eq(THEMA.default_font_size, 14, "werkzeug-text")
	assert_eq(THEMA.get_font_size(&"font_size", &"TitleLabel"), 16, "werkzeug-titel")
	assert_eq(THEMA.get_font_size(&"font_size", &"SmallLabel"), 12, "werkzeug-klein")
	for groesse: Array in [[&"text", 14], [&"small", 12], [&"title", 16]]:
		assert_eq(THEMA.get_font_size(groesse[0], &"Werkstatt"), groesse[1],
			"Werkstatt/font_sizes/%s für eigenes Zeichnen." % groesse[0])
	assert_false(THEMA.has_default_font(), "Im Theme steht keine Schrift.")
	for typ in THEMA.get_type_list():
		assert_eq(THEMA.get_font_list(typ).size(), 0, "Keine Schrift bei %s." % typ)


func test_alle_farben_stammen_aus_der_palette() -> void:
	var palette := UiPalette.TOKENS.values()
	for typ in THEMA.get_type_list():
		for eintrag in THEMA.get_color_list(typ):
			var farbe := THEMA.get_color(eintrag, typ)
			assert_true(palette.has(farbe), "%s/%s ist keine Farbe der Palette." % [typ, eintrag])
			assert_eq(farbe.a, 1.0, "%s/%s ist durchsichtig." % [typ, eintrag])


func test_farbrollen_wie_im_style_guide() -> void:
	assert_eq(THEMA.get_color_list(&"Werkstatt").size(), FARBROLLEN.size(), "Genau die Rollen.")
	for rolle: StringName in FARBROLLEN:
		assert_eq(THEMA.get_color(rolle, &"Werkstatt"), UiPalette.by_token(FARBROLLEN[rolle]),
			"Rolle %s ist %s." % [rolle, FARBROLLEN[rolle]])


func test_kaesten_sind_eckig_ohne_verlauf_und_transparenz() -> void:
	var palette := UiPalette.TOKENS.values()
	for typ in THEMA.get_type_list():
		for eintrag in THEMA.get_stylebox_list(typ):
			var kasten := THEMA.get_stylebox(eintrag, typ)
			var stelle := "%s/%s" % [typ, eintrag]
			if kasten is ReliefStyleBox:
				var relief: ReliefStyleBox = kasten
				assert_true(UiPalette.TOKENS.has(relief.fill),
					"%s: Fläche aus der Palette." % stelle)
				assert_true(UiPalette.TOKENS.has(relief.outline),
					"%s: Kontur aus der Palette." % stelle)
			elif kasten is StyleBoxFlat:
				var flach: StyleBoxFlat = kasten
				assert_false(flach.anti_aliasing,
					"%s: Kantenglättung macht weiche Ränder." % stelle)
				assert_eq(flach.shadow_size, 0, "%s: kein weicher Schatten." % stelle)
				assert_eq(flach.skew, Vector2.ZERO, "%s: nicht schief." % stelle)
				for ecke in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT,
						CORNER_BOTTOM_LEFT]:
					assert_eq(flach.get_corner_radius(ecke), 0, "%s: eckig (ecke-0)." % stelle)
				if flach.draw_center:
					assert_true(palette.has(flach.bg_color), "%s: Fläche aus der Palette." % stelle)
				if _randbreite(flach) > 0:
					assert_true(palette.has(flach.border_color),
						"%s: Rand aus der Palette." % stelle)
			elif kasten is StyleBoxLine:
				assert_true(palette.has((kasten as StyleBoxLine).color), "%s: Linie." % stelle)
			else:
				assert_true(kasten is StyleBoxEmpty,
					"%s: unerwarteter Kasten %s." % [stelle, kasten])


func test_symbole_aus_dem_eigenen_ordner_in_farben_der_palette() -> void:
	# Das Schließen-Kreuz der Dialoge und die Griffe der Split-Container sind eigene SVGs; die
	# Symbole des Standard-Themes sind weiß und auf gehaeuse und papier kaum zu sehen.
	var palette := []
	for farbe: Color in UiPalette.TOKENS.values():
		palette.append("#" + farbe.to_html(false))
	var farbangabe := RegEx.create_from_string("#[0-9a-fA-F]{6}")
	var anzahl := 0
	for typ in THEMA.get_type_list():
		for eintrag in THEMA.get_icon_list(typ):
			var symbol := THEMA.get_icon(eintrag, typ)
			var stelle := "%s/%s" % [typ, eintrag]
			assert_string_starts_with(symbol.resource_path, "res://tools/werkstatt/icons/", stelle)
			var svg := FileAccess.get_file_as_string(symbol.resource_path)
			for treffer in farbangabe.search_all(svg):
				assert_has(palette, treffer.get_string().to_lower(),
					"%s: Farbe der Palette." % stelle)
			anzahl += 1
	assert_eq(anzahl, 6, "Kreuz und gedrücktes Kreuz, dazu vier Griffe.")
	assert_eq(THEMA.get_icon(&"close", &"Window").get_size(), Vector2(16, 16))


func test_abstaende_kommen_aus_dem_raster() -> void:
	for typ in THEMA.get_type_list():
		for eintrag in THEMA.get_constant_list(typ):
			if KEINE_ABSTAENDE.has(eintrag):
				continue
			assert_has([4, 8, 16], THEMA.get_constant(eintrag, typ),
				"%s/%s ist kein Abstand aus raster-4, raster-8 oder raster-16." % [typ, eintrag])


func test_knoepfe_haben_relief_und_gleiche_innenabstaende() -> void:
	# Arrange
	var ruhe: ReliefStyleBox = THEMA.get_stylebox(&"normal", &"Button")
	var ueber: ReliefStyleBox = THEMA.get_stylebox(&"hover", &"Button")
	var gedrueckt: ReliefStyleBox = THEMA.get_stylebox(&"pressed", &"Button")
	var aus: StyleBoxFlat = THEMA.get_stylebox(&"disabled", &"Button")

	# Assert: relief-erhaben in Ruhe und beim Überfahren, relief-gedrueckt beim Drücken
	assert_eq([ruhe.fill, ruhe.relief], [&"gehaeuse", ReliefStyleBox.Relief.RAISED])
	assert_eq([ueber.fill, ueber.relief], [&"signalgelb", ReliefStyleBox.Relief.RAISED])
	assert_eq([gedrueckt.fill, gedrueckt.relief], [&"gehaeuse", ReliefStyleBox.Relief.PRESSED])
	assert_eq(aus.bg_color, UiPalette.PAPIER, "Gedämpfter Text steht nur auf papier.")
	assert_eq(THEMA.get_color(&"font_disabled_color", &"Button"), UiPalette.GEHAEUSE_DUNKEL)
	# Gleiche Innenabstände, sonst springt der Knopf beim Überfahren in der Größe.
	for kasten: StyleBox in [ueber, gedrueckt, aus]:
		for seite in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			assert_eq(kasten.get_content_margin(seite), ruhe.get_content_margin(seite))


func test_feld_mit_fehler_hat_eine_kontur_von_2_pixeln_in_kassenrot() -> void:
	# Style-Guide, „Bedienelemente“: „Ein Feld mit Fehler, ob Eingabe- oder Auswahlfeld, bekommt
	# eine Kontur von 2 Pixeln in kassenrot“ (T081).
	for typ: StringName in [&"ErrorLineEdit", &"ErrorTextEdit"]:
		var feld: StyleBoxFlat = THEMA.get_stylebox(&"normal", typ)
		assert_eq(feld.border_color, UiPalette.KASSENROT, "%s in kassenrot" % typ)
		for seite in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			assert_eq(feld.get_border_width(seite), 2, "%s: 2 Pixel" % typ)
		assert_eq(feld.bg_color, UiPalette.PAPIER, "%s: Eingabefelder auf papier" % typ)
	assert_eq(THEMA.get_type_variation_base(&"ErrorLineEdit"), &"LineEdit")
	assert_eq(THEMA.get_type_variation_base(&"ErrorTextEdit"), &"TextEdit")
	# Auswahlfelder sind Knöpfe mit Relief; nur ihre Kontur wird rot und breiter, Fläche, Relief und
	# Innenabstände bleiben, damit der Text nicht springt.
	assert_eq(THEMA.get_type_variation_base(&"ErrorOptionButton"), &"OptionButton")
	for zustand: StringName in [&"normal", &"hover", &"pressed"]:
		var knopf: ReliefStyleBox = THEMA.get_stylebox(zustand, &"Button")
		var fehler: ReliefStyleBox = THEMA.get_stylebox(zustand, &"ErrorOptionButton")
		assert_eq([fehler.outline, fehler.outline_width], [&"kassenrot", 2], String(zustand))
		assert_eq([fehler.fill, fehler.relief], [knopf.fill, knopf.relief], String(zustand))
		for seite in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			assert_eq(fehler.get_content_margin(seite), knopf.get_content_margin(seite))
	# Die Fokuslinie in tusche kommt weiter vom Knopf.
	assert_false(THEMA.has_stylebox(&"focus", &"ErrorOptionButton"))
	assert_false(THEMA.has_stylebox(&"focus", &"ErrorTextEdit"))


func test_fokus_ist_eine_linie_von_2_pixeln_mit_2_pixeln_abstand() -> void:
	for stelle: Array in [[&"focus", &"Button"], [&"focus", &"LineEdit"], [&"focus", &"TextEdit"],
			[&"focus", &"ItemList"], [&"focus", &"Tree"], [&"tab_focus", &"TabContainer"],
			[&"focus", &"CheckBox"]]:
		var fokus: StyleBoxFlat = THEMA.get_stylebox(stelle[0], stelle[1])
		assert_false(fokus.draw_center, "%s: nur die Linie." % [stelle])
		assert_eq(fokus.border_color, UiPalette.TUSCHE)
		for seite in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			assert_eq(fokus.get_border_width(seite), 2, "%s: 2 Pixel breit." % [stelle])
			# Die Linie liegt außen auf dem um 4 Pixel vergrößerten Rechteck; zwischen ihr und
			# dem Element bleiben 2 Pixel frei.
			assert_eq(fokus.get_expand_margin(seite), 4.0, "%s: 2 Pixel Abstand." % [stelle])


func test_menues_und_tooltips_auf_papier_mit_pixelschatten() -> void:
	for typ: StringName in [&"PopupMenu", &"TooltipPanel"]:
		var kasten: ReliefStyleBox = THEMA.get_stylebox(&"panel", typ)
		assert_eq(kasten.fill, &"papier", "%s auf papier." % typ)
		assert_eq(kasten.relief, ReliefStyleBox.Relief.NONE)
		assert_true(kasten.pixel_shadow, "%s mit pixelschatten." % typ)
		# Der Schatten nimmt rechts und unten 2 Pixel; um so viel sind die Innenabstände größer.
		assert_eq(kasten.content_margin_right - kasten.content_margin_left, 2.0)
		assert_eq(kasten.content_margin_bottom - kasten.content_margin_top, 2.0)
	assert_eq(THEMA.get_type_variation_base(&"TooltipPanel"), &"PopupPanel")


func test_auswahl_in_petrol_mit_text_in_papier() -> void:
	for typ: StringName in [&"ItemList", &"Tree"]:
		var auswahl: StyleBoxFlat = THEMA.get_stylebox(&"selected_focus", typ)
		assert_eq(auswahl.bg_color, UiPalette.PETROL)
		assert_eq(THEMA.get_color(&"font_selected_color", typ), UiPalette.PAPIER)
		var ueber: StyleBoxFlat = THEMA.get_stylebox(&"hovered", typ)
		assert_eq(ueber.bg_color, UiPalette.SIGNALGELB, "Überfahren ist signalgelb.")
	var reiter: StyleBoxFlat = THEMA.get_stylebox(&"tab_selected", &"TabContainer")
	assert_eq(reiter.bg_color, UiPalette.PETROL, "Der aktive Reiter ist petrol.")
	assert_eq(THEMA.get_color(&"font_selected_color", &"TabContainer"), UiPalette.PAPIER)


# --- Reliefkasten -----------------------------------------------------------------------------

func test_erhaben_hat_licht_oben_links_und_schatten_unten_rechts() -> void:
	# Arrange: ein Knopf von 10 × 6 Pixeln. Innen liegt die Fläche von (1, 1) bis (8, 4).
	var kasten := _kasten(&"gehaeuse", ReliefStyleBox.Relief.RAISED)
	var flaeche := Rect2(0, 0, 10, 6)

	# Assert
	assert_eq(_farbe(kasten, flaeche, 0, 0), UiPalette.TUSCHE, "Kontur oben links")
	assert_eq(_farbe(kasten, flaeche, 9, 5), UiPalette.TUSCHE, "Kontur unten rechts")
	assert_eq(_farbe(kasten, flaeche, 1, 1), UiPalette.GEHAEUSE_HELL, "Licht oben links")
	assert_eq(_farbe(kasten, flaeche, 8, 1), UiPalette.GEHAEUSE_HELL,
		"Die Ecke oben rechts gehört zur Kante oben, wie in relief-erhaben.")
	assert_eq(_farbe(kasten, flaeche, 1, 4), UiPalette.GEHAEUSE_HELL, "Ecke unten links")
	assert_eq(_farbe(kasten, flaeche, 8, 4), UiPalette.GEHAEUSE_DUNKEL, "Schatten unten rechts")
	assert_eq(_farbe(kasten, flaeche, 5, 4), UiPalette.GEHAEUSE_DUNKEL, "Kante unten")
	assert_eq(_farbe(kasten, flaeche, 8, 2), UiPalette.GEHAEUSE_DUNKEL, "Kante rechts")
	assert_eq(_farbe(kasten, flaeche, 4, 2), UiPalette.GEHAEUSE, "Fläche")
	assert_null(_farbe(kasten, flaeche, 10, 3), "Außerhalb zeichnet der Kasten nichts.")


func test_gedrueckt_ist_umgekehrt() -> void:
	# Arrange
	var kasten := _kasten(&"gehaeuse", ReliefStyleBox.Relief.PRESSED)
	var flaeche := Rect2(0, 0, 10, 6)

	# Assert: relief-gedrueckt
	assert_eq(_farbe(kasten, flaeche, 1, 1), UiPalette.GEHAEUSE_DUNKEL)
	assert_eq(_farbe(kasten, flaeche, 8, 1), UiPalette.GEHAEUSE_DUNKEL)
	assert_eq(_farbe(kasten, flaeche, 1, 4), UiPalette.GEHAEUSE_DUNKEL)
	assert_eq(_farbe(kasten, flaeche, 8, 4), UiPalette.GEHAEUSE_HELL)
	assert_eq(_farbe(kasten, flaeche, 4, 2), UiPalette.GEHAEUSE)


func test_kontur_von_2_pixeln_in_kassenrot_mit_relief_innen() -> void:
	# Arrange (T081): ein Auswahlfeld mit Fehler, 12 × 8 Pixel. Innen liegt die Fläche von (2, 2)
	# bis (9, 5).
	var kasten := _kasten(&"gehaeuse", ReliefStyleBox.Relief.RAISED)
	kasten.outline = &"kassenrot"
	kasten.outline_width = 2
	var flaeche := Rect2(0, 0, 12, 8)

	# Assert
	for punkt: Vector2i in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(11, 7), Vector2i(10, 6),
			Vector2i(1, 4), Vector2i(6, 6)]:
		assert_eq(_farbe(kasten, flaeche, punkt.x, punkt.y), UiPalette.KASSENROT,
			"Kontur bei %s" % punkt)
	assert_eq(_farbe(kasten, flaeche, 2, 2), UiPalette.GEHAEUSE_HELL, "Licht oben links")
	assert_eq(_farbe(kasten, flaeche, 9, 5), UiPalette.GEHAEUSE_DUNKEL, "Schatten unten rechts")
	assert_eq(_farbe(kasten, flaeche, 5, 3), UiPalette.GEHAEUSE, "Fläche")


func test_pixelschatten_liegt_hart_2_pixel_rechts_unten() -> void:
	# Arrange: Rechteck 12 × 8; der Kasten wird 10 × 6, der Schatten liegt um 2 Pixel versetzt.
	var kasten := _kasten(&"papier", ReliefStyleBox.Relief.NONE, true)
	var flaeche := Rect2(0, 0, 12, 8)

	# Assert
	assert_eq(_farbe(kasten, flaeche, 9, 5), UiPalette.TUSCHE, "Kontur unten rechts")
	assert_eq(_farbe(kasten, flaeche, 4, 2), UiPalette.PAPIER, "Fläche, ohne Relief")
	assert_eq(_farbe(kasten, flaeche, 1, 1), UiPalette.PAPIER)
	for punkt: Vector2i in [Vector2i(10, 2), Vector2i(11, 7), Vector2i(2, 6), Vector2i(11, 4)]:
		assert_eq(_farbe(kasten, flaeche, punkt.x, punkt.y), UiPalette.TUSCHE,
			"Schatten bei %s" % punkt)
	for punkt: Vector2i in [Vector2i(10, 0), Vector2i(11, 1), Vector2i(0, 6), Vector2i(1, 7)]:
		assert_null(_farbe(kasten, flaeche, punkt.x, punkt.y),
			"Bei %s bleibt der Grund sichtbar, wie bei pixelschatten." % punkt)


func test_krumme_rechtecke_landen_auf_ganzen_pixeln() -> void:
	# Arrange
	var kasten := _kasten(&"gehaeuse", ReliefStyleBox.Relief.RAISED)

	# Act
	var ebenen := kasten.layers(Rect2(0.4, 0.6, 9.8, 5.8))

	# Assert
	assert_eq(ebenen[0]["rect"], Rect2(0, 1, 10, 5), "Anfang und Ende werden gerundet.")
	for ebene in ebenen:
		var rechteck: Rect2 = ebene["rect"]
		assert_eq(rechteck.position, rechteck.position.round())
		assert_eq(rechteck.size, rechteck.size.round())


func test_winziger_kasten_zeichnet_nur_was_platz_hat() -> void:
	# Act
	var ebenen := _kasten(&"gehaeuse", ReliefStyleBox.Relief.RAISED).layers(Rect2(0, 0, 1, 1))

	# Assert
	assert_eq(ebenen.size(), 1, "Nur die Kontur, kein Rechteck mit negativer Größe.")


func test_unbekanntes_token_faellt_als_magenta_auf() -> void:
	# Arrange
	var kasten := _kasten(&"petrool", ReliefStyleBox.Relief.NONE)

	# Assert
	assert_eq(_farbe(kasten, Rect2(0, 0, 10, 6), 4, 2), MAGENTA)


func test_aenderung_einer_eigenschaft_meldet_changed() -> void:
	# Arrange: Controls und Theme zeichnen neu, wenn ein StyleBox changed sendet; so wirkt eine
	# Änderung im Inspektor sofort.
	var kasten := _kasten(&"gehaeuse", ReliefStyleBox.Relief.RAISED)
	watch_signals(kasten)

	# Act
	kasten.fill = &"signalgelb"
	kasten.relief = ReliefStyleBox.Relief.PRESSED
	kasten.pixel_shadow = true
	kasten.outline = &"kassenrot"
	kasten.outline_width = 2

	# Assert
	assert_signal_emit_count(kasten, "changed", 5)


# --- Helfer -----------------------------------------------------------------------------------

func _kasten(fill: StringName, relief: ReliefStyleBox.Relief,
		pixel_shadow: bool = false) -> ReliefStyleBox:
	var kasten := ReliefStyleBox.new()
	kasten.fill = fill
	kasten.relief = relief
	kasten.pixel_shadow = pixel_shadow
	return kasten


## Die Farbe, die der Kasten im Rechteck [param flaeche] am Pixel ([param x], [param y]) zeigt:
## die des obersten Rechtecks, das den Pixel enthält, oder null, wenn er dort nichts zeichnet.
func _farbe(kasten: ReliefStyleBox, flaeche: Rect2, x: int, y: int) -> Variant:
	var mitte := Vector2(x + 0.5, y + 0.5)
	var farbe: Variant = null
	for ebene in kasten.layers(flaeche):
		var rechteck: Rect2 = ebene["rect"]
		if rechteck.has_point(mitte):
			farbe = ebene["color"]
	return farbe


func _randbreite(kasten: StyleBoxFlat) -> int:
	var summe := 0
	for seite in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		summe += kasten.get_border_width(seite)
	return summe
