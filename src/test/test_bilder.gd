extends GutTest

## Prüft die Bilder in res://assets/images/ gegen die Hauptpalette (KI-Workflow, Schritt 7).
##
## Style-Guide: Szenen und Bilder benutzen nur Farben der Hauptpalette `docs/art/hauptpalette.gpl`.
## Jeder Pixel ist ganz durchsichtig (Alpha 0) oder ganz deckend (Alpha 255) in einer Farbe der
## Palette. Halbtransparenz ist ein Fehler, ebenso deckendes Magenta: Index 0 der Palette steht
## nur für die Transparenz.
##
## Gelesen wird die PNG-Datei selbst, nicht die importierte Textur. Der Import könnte Farben
## verändern (Komprimierung, Mipmaps), und dann prüfte der Test die falsche Sache. Ein neues Bild
## im Ordner wird automatisch mitgeprüft.
##
## Die Prüffunktionen nehmen einen Pfad oder ein Image, damit sich auch eine Kopie außerhalb des
## Projekts prüfen lässt. Der Test schreibt nichts.

const BILDORDNER := "res://assets/images/"
## So viele Fundstellen nennt die Fehlermeldung, dazu die Gesamtzahl.
const ERSTE_FUNDSTELLEN := 5
## Index 0 der Hauptpalette, Magenta, steht für die Transparenz und ist keine deckende Farbe.
const TRANSPARENZ := 0xff00ff


func test_jedes_bild_nur_in_farben_der_hauptpalette() -> void:
	# Arrange
	var erlaubt := _deckende_farben(_lies_palette(_palettenpfad()))
	var bilder := _bilder_im_ordner(BILDORDNER)

	# Assert: Ein leerer Ordner hieße, dass der Test nichts prüft.
	assert_gt(bilder.size(), 0, "Keine PNG-Datei in %s gefunden." % BILDORDNER)
	for pfad in bilder:
		assert_eq(_pruefe_bilddatei(pfad, erlaubt), "", pfad.get_file())


func test_palette_hat_256_farben_und_die_15_der_oberflaeche() -> void:
	# Arrange
	var palette := _lies_palette(_palettenpfad())
	var oberflaeche := []
	for farbe: Color in UiPalette.TOKENS.values():
		oberflaeche.append(_als_zahl(farbe))

	# Assert: Index 0 Transparenz, 1 bis 15 die Oberflächenfarben (Style-Guide), Rest Szenenfarben.
	assert_eq(palette.size(), 256, "Die Hauptpalette hat 256 Einträge.")
	assert_eq(palette[0], TRANSPARENZ, "Index 0 ist Magenta für die Transparenz.")
	for zahl: int in oberflaeche:
		assert_has(palette, zahl, "#%06x aus UiPalette fehlt in der Hauptpalette." % zahl)
	var reserviert := Array(palette.slice(1, 16))
	reserviert.sort()
	oberflaeche.sort()
	assert_eq(reserviert, oberflaeche,
		"Index 1 bis 15 sind für die Farben aus UiPalette reserviert.")


func test_fremder_pixel_und_halbtransparenz_fallen_auf() -> void:
	# Arrange: zwei kleine Bilder in papier, eins mit einem fremden Pixel, eins mit einem halb
	# durchsichtigen Pixel in einer Farbe der Palette.
	var erlaubt := _deckende_farben(_lies_palette(_palettenpfad()))
	var fremd := _bild_in(UiPalette.PAPIER)
	fremd.set_pixel(2, 1, Color8(0x12, 0x34, 0x56))
	var halb := _bild_in(UiPalette.PAPIER)
	halb.set_pixel(3, 0, Color8(0xf5, 0xf0, 0xe2, 128))

	# Act
	var meldung_fremd := _pruefe_bild(fremd, "fremd.png", erlaubt)
	var meldung_halb := _pruefe_bild(halb, "halb.png", erlaubt)

	# Assert
	assert_string_contains(meldung_fremd, "fremd.png")
	assert_string_contains(meldung_fremd, "1 Pixel")
	assert_string_contains(meldung_fremd, "(2, 1) #123456")
	assert_string_contains(meldung_halb, "halb.png")
	assert_string_contains(meldung_halb, "(3, 0) #f5f0e2 Alpha 128")


func test_durchsichtige_und_deckende_palettenpixel_sind_in_ordnung() -> void:
	# Arrange: Ein ganz durchsichtiger Pixel darf jede Farbe tragen, man sieht sie nicht.
	var erlaubt := _deckende_farben(_lies_palette(_palettenpfad()))
	var bild := _bild_in(UiPalette.TUSCHE)
	bild.set_pixel(0, 0, Color8(0x12, 0x34, 0x56, 0))
	bild.set_pixel(1, 0, UiPalette.SIGNALGELB)
	var magenta := _bild_in(UiPalette.TUSCHE)
	magenta.set_pixel(0, 1, Color8(0xff, 0x00, 0xff))

	# Assert
	assert_eq(_pruefe_bild(bild, "gut.png", erlaubt), "")
	assert_string_contains(_pruefe_bild(magenta, "magenta.png", erlaubt), "(0, 1) #ff00ff",
		"Deckendes Magenta ist die Transparenzfarbe und gehört nicht ins Bild.")


# --- Helfer ---------------------------------------------------------------

## Pfad der Hauptpalette im Dateisystem: Sie liegt außerhalb des Godot-Projekts, eine Ebene über
## res:// im Repo, unter docs/art/.
func _palettenpfad() -> String:
	var repo := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	return repo.path_join("docs/art/hauptpalette.gpl")


## Die Farben einer GIMP-Palette als Zahlen 0xRRGGBB, in der Reihenfolge der Datei.
func _lies_palette(pfad: String) -> PackedInt32Array:
	var farben := PackedInt32Array()
	var eintrag := RegEx.create_from_string("^\\s*(\\d+)\\s+(\\d+)\\s+(\\d+)")
	for zeile in FileAccess.get_file_as_string(pfad).split("\n"):
		var treffer := eintrag.search(zeile)
		if treffer:
			farben.append(treffer.get_string(1).to_int() << 16
				| treffer.get_string(2).to_int() << 8 | treffer.get_string(3).to_int())
	return farben


## Die Farben, die ein deckender Pixel haben darf: alle der Palette außer der Transparenz.
func _deckende_farben(palette: PackedInt32Array) -> Dictionary:
	var erlaubt := {}
	for zahl in palette:
		erlaubt[zahl] = true
	erlaubt.erase(TRANSPARENZ)
	return erlaubt


## Alle PNG-Dateien im Ordner, sortiert, als res://-Pfade.
func _bilder_im_ordner(ordner: String) -> PackedStringArray:
	var bilder := PackedStringArray()
	for datei in DirAccess.get_files_at(ordner):
		if datei.get_extension().to_lower() == "png":
			bilder.append(ordner.path_join(datei))
	bilder.sort()
	return bilder


## Prüft eine PNG-Datei (res:// oder absoluter Pfad). Leer heißt in Ordnung, sonst die Meldung.
func _pruefe_bilddatei(pfad: String, erlaubt: Dictionary) -> String:
	var bild := Image.load_from_file(ProjectSettings.globalize_path(pfad))
	if bild == null or bild.is_empty():
		return "%s lässt sich nicht lesen." % pfad.get_file()
	return _pruefe_bild(bild, pfad.get_file(), erlaubt)


## Prüft jeden Pixel, zeilenweise von oben links. Leer heißt in Ordnung, sonst nennt die Meldung
## die ersten Fundstellen mit Farbe als Hex (und Alpha, wenn halb durchsichtig) und die Gesamtzahl.
func _pruefe_bild(bild: Image, name: String, erlaubt: Dictionary) -> String:
	var rgba := bild.duplicate() as Image
	rgba.convert(Image.FORMAT_RGBA8)
	# Die Rohdaten sind vier Bytes je Pixel (R, G, B, A), Zeile für Zeile. Sie zu lesen ist viel
	# schneller als get_pixel(), das für jeden Pixel ein Color-Objekt baut.
	var daten := rgba.get_data()
	var fundstellen := PackedStringArray()
	var anzahl := 0
	var i := 0
	for y in rgba.get_height():
		for x in rgba.get_width():
			var alpha := daten[i + 3]
			var zahl := daten[i] << 16 | daten[i + 1] << 8 | daten[i + 2]
			i += 4
			if alpha == 0 or (alpha == 255 and erlaubt.has(zahl)):
				continue
			anzahl += 1
			if fundstellen.size() < ERSTE_FUNDSTELLEN:
				var stelle := "(%d, %d) #%06x" % [x, y, zahl]
				if alpha != 255:
					stelle += " Alpha %d" % alpha
				fundstellen.append(stelle)
	if anzahl == 0:
		return ""
	return "%s: %d Pixel nicht in der Hauptpalette, zuerst %s" % [
		name, anzahl, ", ".join(fundstellen)]


func _bild_in(farbe: Color) -> Image:
	var bild := Image.create_empty(4, 2, false, Image.FORMAT_RGBA8)
	bild.fill(farbe)
	return bild


func _als_zahl(farbe: Color) -> int:
	return farbe.r8 << 16 | farbe.g8 << 8 | farbe.b8
