class_name InvadersSprites
extends RefCounted

## Die Pixelmuster des Spiels auf der Anzeige als Daten (research.md, R8). Jedes Muster ist eine
## Liste von Bildern, jedes Bild eine Liste gleich langer Strings, von oben nach unten; "#" ist
## tusche, "." leer. Gemalt wird jedes "#" als ein Bildpixel, gezeigt als 2 × 2 Oberflächenpixel.
##
## Die Muster stammen Zeichen für Zeichen aus dem Style-Guide, Baustein „Spiel auf der Anzeige“,
## Abschnitt „Pixelmuster“; geändert wird erst dort, dann hier. Es sind eigene Entwürfe, keine
## Kopien des Vorbilds.
##
## Die Klasse hat nur Konstanten und statische Funktionen; niemand legt eine Instanz an.

## Je Muster die Bilder. Die Außerirdischen haben zwei Bewegungsbilder, alles andere eines.
## Welche Art in welcher Reihe steht, sagt InvadersGame (oben alien_a, Mitte alien_b, unten
## alien_c).
const PATTERNS := {
	&"alien_a": [
		["...##...", "..####..", ".##..##.", "########", "..#..#..", ".#.##.#."],
		["...##...", "..####..", ".##..##.", "########", ".#....#.", "#......#"],
	],
	&"alien_b": [
		[".#....#.", "..####..", ".#.##.#.", "########", "#.#..#.#", "...##..."],
		[".#....#.", "#.####.#", "##.##.##", "########", "..#..#..", ".#....#."],
	],
	&"alien_c": [
		["..####..", ".######.", "##.##.##", "########", ".##..##.", "#......#"],
		["..####..", ".######.", "##.##.##", "########", "..#..#..", ".#.##.#."],
	],
	&"cannon": [
		["....#....", "...###...", ".#######.", "#########", "#########"],
	],
	&"shot": [
		["#", "#", "#", "#"],
	],
	&"bomb": [
		["#.", ".#", "#."],
	],
	&"explosion": [
		["#..##..#", ".#....#.", "..#..#..", "##....##", "..#..#..", ".#.##.#."],
	],
	&"life": [
		["...#...", "..###..", ".#####.", "#######"],
	],
}


## Die gesetzten Pixel von [param sprite], Bild [param frame], relativ zur linken oberen Ecke,
## zeilenweise von oben links. Ein Bild über die Zahl der Bilder hinaus zählt im Kreis weiter
## (Bild 1 eines Musters mit einem Bild ist Bild 0). Ein unbekanntes Muster hat keine Pixel.
static func pixels(sprite: StringName, frame: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not PATTERNS.has(sprite):
		return result
	var frames: Array = PATTERNS[sprite]
	var rows: Array = frames[posmod(frame, frames.size())]
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				result.append(Vector2i(x, y))
	return result


## Größe von [param sprite] in Bildpixeln, aus dem ersten Bild; Vector2i.ZERO, wenn es das Muster
## nicht gibt.
static func size_of(sprite: StringName) -> Vector2i:
	if not PATTERNS.has(sprite):
		return Vector2i.ZERO
	var rows: Array = PATTERNS[sprite][0]
	var first: String = rows[0]
	return Vector2i(first.length(), rows.size())
