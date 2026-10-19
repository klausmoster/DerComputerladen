extends GutTest

## Prüft den Fensterfaktor (FR-004, data-model.md): der größte ganzzahlige Faktor des
## Oberflächenrasters 640 × 360, der samt Titelleiste in den nutzbaren Bereich des
## Bildschirms passt, mindestens 1.
##
## `best_factor()` ist eine reine Funktion: Sie bekommt die Maße und rechnet. Die Tests
## brauchen deshalb weder ein Fenster noch den Autoload `GameWindow`, sie rufen die
## Funktion am Skript auf.
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


# --- Helfer ---------------------------------------------------------------

## Die Fensterdekoration unter macOS: nur oben eine Titelleiste, links und rechts kein Rand.
func _titelleiste(hoehe: int) -> Vector2i:
	return Vector2i(0, hoehe)
