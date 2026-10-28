extends GutTest

## Prüft den Fensterfaktor (FR-004, data-model.md): der größte ganzzahlige Faktor des
## Oberflächenrasters 640 × 360, der samt Titelleiste in den nutzbaren Bereich des
## Bildschirms passt, mindestens 1.
##
## Dazu die Lage: samt Titelleiste mittig im nutzbaren Bereich (Feature 007, Klaus).
##
## `best_factor()` und `centered_position()` sind reine Funktionen: Sie bekommen die Maße und
## rechnen. Die Tests brauchen deshalb weder ein Fenster noch den Autoload `GameWindow`, sie
## rufen die Funktionen am Skript auf.
##
## Alle Maße sind Bildschirmpixel. Die Titelleiste von macOS ist 28 Punkte hoch, auf einem
## Retina-Bildschirm also 56 Pixel.

const WINDOW := preload("res://core/game_window.gd")


func test_1080p_ergibt_faktor_2() -> void:
	# Act: Die Breite ließe 3 zu, die Höhe nur (1050 − 28) / 360 = 2,8.
	var factor := WINDOW.best_factor(Vector2i(1920, 1050), _titelleiste(28))

	# Assert
	assert_eq(factor, 2, "Die Höhe begrenzt, und es wird abgerundet, nicht gerundet.")


func test_1440p_ergibt_faktor_3() -> void:
	# Act: (1410 − 28) / 360 = 3,8.
	var factor := WINDOW.best_factor(Vector2i(2560, 1410), _titelleiste(28))

	# Assert
	assert_eq(factor, 3)


func test_4k_mit_retina_titelleiste_ergibt_faktor_5() -> void:
	# Act: (2130 − 56) / 360 = 5,8.
	var factor := WINDOW.best_factor(Vector2i(3840, 2130), _titelleiste(56))

	# Assert
	assert_eq(factor, 5)


func test_macbook_bildschirm_ergibt_faktor_4() -> void:
	# Act: Hier begrenzt die Breite: 3024 / 640 = 4,7, die Höhe ließe 5 zu.
	var factor := WINDOW.best_factor(Vector2i(3024, 1890), _titelleiste(56))

	# Assert
	assert_eq(factor, 4, "Der kleinere Faktor der beiden Achsen gilt.")


func test_zu_kleine_flaeche_ergibt_faktor_1() -> void:
	# Act: Rechnerisch 0, aber kleiner als 1 wird das Fenster nie.
	var factor := WINDOW.best_factor(Vector2i(600, 300), _titelleiste(28))

	# Assert
	assert_eq(factor, 1, "Der Faktor ist immer mindestens 1.")


# --- Lage im nutzbaren Bereich -------------------------------------------

func test_4k_mit_dock_steht_samt_titelleiste_mittig_im_nutzbaren_bereich() -> void:
	# Arrange: gemessen am Mac (Feature 007): 3840 × 2160, Menüleiste 60, Dock unten, also nutzbar
	# ab y 60 mit 1914 Höhe; Fläche 3200 × 1800 bei Faktor 5, Titelleiste 64.
	var nutzbar := Rect2i(0, 60, 3840, 1914)
	var rahmen := Vector2i(3200, 1864)

	# Act
	var lage := WINDOW.centered_position(nutzbar, rahmen, _titelleiste(64))

	# Assert: Rahmen oben bei 60 + (1914 − 1864) / 2 = 85, die Fläche 64 darunter.
	assert_eq(lage, Vector2i(320, 149))


func test_der_rest_eines_ungeraden_randes_faellt_nach_links_oben() -> void:
	# Act
	var lage := WINDOW.centered_position(Rect2i(10, 25, 1281, 781), Vector2i(1280, 776),
		_titelleiste(56))

	# Assert
	assert_eq(lage, Vector2i(10, 83), "Je ein halbes Pixel Rest bleibt rechts und unten.")


func test_ist_der_rahmen_zu_gross_steht_er_links_oben_im_nutzbaren_bereich() -> void:
	# Act: Faktor 1 passt nicht einmal; die Titelleiste muss trotzdem erreichbar bleiben.
	var lage := WINDOW.centered_position(Rect2i(0, 50, 600, 300), Vector2i(640, 416),
		_titelleiste(56))

	# Assert
	assert_eq(lage, Vector2i(0, 106))


# --- Helfer ---------------------------------------------------------------

## Die Fensterdekoration unter macOS: nur oben eine Titelleiste, links und rechts kein Rand.
func _titelleiste(hoehe: int) -> Vector2i:
	return Vector2i(0, hoehe)
