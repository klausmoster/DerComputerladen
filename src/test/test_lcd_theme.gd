extends GutTest

## Prüft die Theme-Varianten für Seiten auf der Anzeige des Communicators (Feature 005, T013;
## contracts/communicator.md, „Theme“; Style-Guide, Bausteine Menü und Liste, „Auf der Anzeige“):
## LcdRow und LcdHeader haben die Farben aus UiPalette und dieselben Schriften wie MenuRow und
## MenuHeader.
##
## Eine .tres-Datei kann keine Konstante aus UiPalette nennen; die Farben stehen dort als Werte. Wie
## test_werkstatt_theme.gd sorgt dieser Test dafür, dass sie mit der Palette übereinstimmen, auch
## nachdem jemand das Theme im Editor geändert hat.
##
## Alle Schriftfarben von LcdRow sind tusche, auch beim Überfahren. Die helle Schrift lcd der
## gewählten Zeile kommt nicht aus dem Theme, sondern aus dem Code (research.md, R15): Das Theme
## kennt nur Fokus und Hover, nicht „gewählt“.

const THEMA := preload("res://ui/computerladen_theme.tres")
const SCHRIFTFARBEN: Array[StringName] = [&"font_color", &"font_focus_color", &"font_hover_color",
	&"font_pressed_color", &"font_hover_pressed_color"]
const ZUSTAENDE: Array[StringName] = [&"normal", &"focus", &"hover", &"pressed", &"hover_pressed",
	&"disabled"]


func test_lcd_row_schrift_tusche_gedaempft_gehaeuse_dunkel() -> void:
	assert_eq(THEMA.get_type_variation_base(&"LcdRow"), &"Button", "LcdRow ist ein Button.")
	for eintrag in SCHRIFTFARBEN:
		assert_eq(THEMA.get_color(eintrag, &"LcdRow"), UiPalette.TUSCHE,
			"LcdRow/%s ist tusche, auch unter der Maus." % eintrag)
	assert_eq(THEMA.get_color(&"font_disabled_color", &"LcdRow"), UiPalette.GEHAEUSE_DUNKEL,
		"Nicht verfügbar ist gehaeuse-dunkel.")
	assert_eq(THEMA.get_color_list(&"LcdRow").size(), SCHRIFTFARBEN.size() + 1,
		"Keine weitere Farbe, auch nicht lcd: Die kommt aus dem Code.")


func test_lcd_row_schrift_wie_menu_row() -> void:
	assert_eq(THEMA.get_font(&"font", &"LcdRow"), THEMA.get_font(&"font", &"MenuRow"),
		"Ark Pixel 12 wie auf Papier.")
	assert_eq(THEMA.get_font_size(&"font_size", &"LcdRow"), 12, "menue: 12 Pixel.")


func test_lcd_row_ohne_flaeche_mit_platz_fuer_den_pfeil() -> void:
	for zustand in ZUSTAENDE:
		# Act
		var kasten := THEMA.get_stylebox(zustand, &"LcdRow")

		# Assert: durchsichtig wie MenuRow; die Auswahl malt das Menü, nicht der Button.
		assert_true(kasten is StyleBoxEmpty, "LcdRow/%s ist leer." % zustand)
		assert_eq(kasten.content_margin_left,
			float(MenuPaper.LCD_TEXT_INSET - MenuPaper.LCD_ROW_INSET),
			"LcdRow/%s: Der Text beginnt bei x 16 der Anzeige." % zustand)


func test_lcd_header_wie_menu_header_in_tusche() -> void:
	assert_eq(THEMA.get_type_variation_base(&"LcdHeader"), &"Label")
	assert_eq(THEMA.get_color(&"font_color", &"LcdHeader"), UiPalette.TUSCHE)
	assert_eq(THEMA.get_font(&"font", &"LcdHeader"), THEMA.get_font(&"font", &"MenuHeader"),
		"drucker: Doto mit Laufweite 1 wie auf Papier.")
	assert_eq(THEMA.get_font_size(&"font_size", &"LcdHeader"), 10, "drucker: 10 Pixel.")
