extends GutTest

## Prüft die Pixelmuster des Spiels auf der Anzeige (Feature 006, T010; contracts/invaders.md,
## „Tests“): gleich lange Zeilen, die Größen aus dem Style-Guide, nur "#" und ".", zwei
## verschiedene Bilder je Außerirdischem, und dass pixels() und size_of() die Muster richtig lesen.

## Größe je Muster in Bildpixeln, aus dem Style-Guide, Baustein „Spiel auf der Anzeige“.
const GROESSEN := {
	&"alien_a": Vector2i(8, 6),
	&"alien_b": Vector2i(8, 6),
	&"alien_c": Vector2i(8, 6),
	&"cannon": Vector2i(9, 5),
	&"shot": Vector2i(1, 4),
	&"bomb": Vector2i(2, 3),
	&"explosion": Vector2i(8, 6),
	&"life": Vector2i(7, 4),
}
const AUSSERIRDISCHE: Array[StringName] = [&"alien_a", &"alien_b", &"alien_c"]


func test_genau_die_muster_aus_dem_style_guide() -> void:
	var namen := InvadersSprites.PATTERNS.keys()
	namen.sort()
	var erwartet := GROESSEN.keys()
	erwartet.sort()
	assert_eq(namen, erwartet, "Acht Muster, keins mehr und keins weniger.")


func test_jedes_bild_hat_die_groesse_aus_dem_style_guide() -> void:
	for muster: StringName in GROESSEN:
		var groesse: Vector2i = GROESSEN[muster]
		assert_eq(InvadersSprites.size_of(muster), groesse, "size_of(%s)" % muster)
		var bilder: Array = InvadersSprites.PATTERNS[muster]
		for nummer in bilder.size():
			var zeilen: Array = bilder[nummer]
			assert_eq(zeilen.size(), groesse.y, "%s, Bild %d: Zahl der Zeilen" % [muster, nummer])
			for zeile: String in zeilen:
				assert_eq(zeile.length(), groesse.x,
						"%s, Bild %d: Zeile „%s“ hat die volle Breite" % [muster, nummer, zeile])


func test_nur_raute_und_punkt() -> void:
	var erlaubt := RegEx.create_from_string("^[#.]+$")
	for muster: StringName in InvadersSprites.PATTERNS:
		for zeilen: Array in InvadersSprites.PATTERNS[muster]:
			for zeile: String in zeilen:
				assert_not_null(erlaubt.search(zeile), "%s: „%s“ hat nur # und ." % [muster, zeile])


func test_ausserirdische_haben_zwei_verschiedene_bilder() -> void:
	for muster in AUSSERIRDISCHE:
		var bilder: Array = InvadersSprites.PATTERNS[muster]
		assert_eq(bilder.size(), 2, "%s hat zwei Bewegungsbilder." % muster)
		assert_ne(bilder[0], bilder[1], "%s: Bild 0 und 1 unterscheiden sich." % muster)
		assert_ne(InvadersSprites.pixels(muster, 0), InvadersSprites.pixels(muster, 1),
				"%s: auch als Pixel." % muster)


func test_alles_andere_hat_ein_bild() -> void:
	for muster: StringName in GROESSEN:
		if muster in AUSSERIRDISCHE:
			continue
		assert_eq(InvadersSprites.PATTERNS[muster].size(), 1, "%s hat ein Bild." % muster)


func test_pixels_liest_zeilenweise_von_oben_links() -> void:
	assert_eq(InvadersSprites.pixels(&"shot", 0),
			[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)] as Array[Vector2i],
			"Der Schuss ist eine Spalte, vier hoch.")
	assert_eq(InvadersSprites.pixels(&"bomb", 0),
			[Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 2)] as Array[Vector2i],
			"Die Bombe im Zickzack: #. / .# / #.")
	var kanone := InvadersSprites.pixels(&"cannon", 0)
	assert_eq(kanone[0], Vector2i(4, 0), "Die Spitze der Kanone ist ihre mittlere Spalte.")


func test_pixels_zaehlt_jede_raute_einmal() -> void:
	for muster: StringName in InvadersSprites.PATTERNS:
		var bilder: Array = InvadersSprites.PATTERNS[muster]
		for nummer in bilder.size():
			var rauten := 0
			for zeile: String in bilder[nummer]:
				rauten += zeile.count("#")
			var pixel := InvadersSprites.pixels(muster, nummer)
			assert_eq(pixel.size(), rauten, "%s, Bild %d" % [muster, nummer])
			var groesse := InvadersSprites.size_of(muster)
			for p in pixel:
				assert_true(Rect2i(Vector2i.ZERO, groesse).has_point(p),
						"%s, Bild %d: %s liegt im Muster" % [muster, nummer, p])


func test_bild_zaehlt_im_kreis() -> void:
	assert_eq(InvadersSprites.pixels(&"alien_a", 2), InvadersSprites.pixels(&"alien_a", 0),
			"Bild 2 eines Musters mit zwei Bildern ist Bild 0.")
	assert_eq(InvadersSprites.pixels(&"cannon", 1), InvadersSprites.pixels(&"cannon", 0),
			"Die Kanone hat ein Bild; Bild 1 ist dasselbe.")


func test_unbekanntes_muster_ist_leer() -> void:
	assert_eq(InvadersSprites.pixels(&"ufo", 0), [] as Array[Vector2i],
			"Kein Ufo (Style-Guide, Nicht).")
	assert_eq(InvadersSprites.size_of(&"ufo"), Vector2i.ZERO)
