class_name MenuPaper
extends RefCounted

## Malt Endlospapier für die Blätter im Titel (Baustein Menü und Baustein Liste im Style-Guide):
## Papier mit pixelschatten, Zeilen im Wechsel papier und endlos-gruen, Lochränder, die gewählte
## Zeile in signalgelb und den Pfeil davor.
##
## Die Klasse hat keine Instanzen, nur Konstanten und statische Funktionen. Das Hauptmenü und die
## Liste der Spielstände rufen sie aus ihrem eigenen `_draw()` auf und geben sich selbst als
## [param canvas] mit; gemalt wird also immer auf dem Control, das gerade zeichnet. So malen beide
## dasselbe Papier, ohne dass eins vom anderen erbt.

## Höhe jeder Zeile, auch der Kopfzeile.
const ROW_HEIGHT := 20
## Links und rechts frei bis zum Innenbereich der Zeilen: Lochrand (8) und Abstand (4).
const ROW_INSET := 12
## Lochränder: Kreise mit Radius 2, Mittelpunkt 4 vom Rand, ab y 10 alle 12 Pixel.
const HOLE_RADIUS := 2
const HOLE_INSET := 4
const HOLE_FIRST_Y := 10
const HOLE_SPACING := 12
## Pfeil vor der gewählten Zeile: ein Pixel-Dreieck, 4 breit und 7 hoch, linke Kante bei x 16.
const ARROW_X := 16
const ARROW_WIDTH := 4
const ARROW_HEIGHT := 7
## pixelschatten: harter Versatz nach rechts unten, ohne Unschärfe.
const SHADOW_OFFSET := 2


## Malt das Papier, [param width] breit und [param row_count] Zeilen hoch, die Kopfzeile
## mitgezählt: zuerst den Schatten, dann die Zeilen, dann die Lochränder.
static func draw_paper(canvas: CanvasItem, width: float, row_count: int) -> void:
	var paper := Rect2(0, 0, width, ROW_HEIGHT * row_count)
	# Zuerst der pixelschatten: dasselbe Rechteck, um 2 nach rechts unten versetzt.
	# Alles, was danach gemalt wird, liegt darüber.
	canvas.draw_rect(Rect2(paper.position + Vector2.ONE * SHADOW_OFFSET, paper.size),
		UiPalette.TUSCHE)
	# Die Zeilen im Wechsel papier / endlos-gruen; die Kopfzeile ist die erste papier-Zeile.
	for row in row_count:
		var color: Color = UiPalette.PAPIER if row % 2 == 0 else UiPalette.ENDLOS_GRUEN
		canvas.draw_rect(Rect2(0, row * ROW_HEIGHT, paper.size.x, ROW_HEIGHT), color)
	# Die Lochränder links und rechts, durchgehend über alle Zeilen. Auf dem Pixelraster
	# ist ein Kreis mit Radius 2 um einen Gitterpunkt ein 4 × 4-Block ohne Ecken.
	for hole_y in hole_centers(paper.size.y):
		canvas.draw_circle(Vector2(HOLE_INSET, hole_y), HOLE_RADIUS, UiPalette.TUSCHE)
		canvas.draw_circle(Vector2(paper.size.x - HOLE_INSET, hole_y), HOLE_RADIUS,
			UiPalette.TUSCHE)


## Die y der Lochmitten auf einem Papier von [param paper_height]: ab HOLE_FIRST_Y alle
## HOLE_SPACING Pixel, solange unter dem Loch noch mindestens ein Pixel Papier bleibt. Ein Loch
## belegt die Pixelreihen y − 2 bis y + 1; berührte es die Unterkante, entfällt es (Style-Guide,
## Bildrahmen, Lochrand). Bei 3, 6 und 9 Zeilen fällt so das unterste Loch weg.
##
## Headless entsteht kein Bild; Tests prüfen die Lochränder über diese Liste.
static func hole_centers(paper_height: float) -> Array[int]:
	var result: Array[int] = []
	var hole_y := HOLE_FIRST_Y
	# Strikt kleiner: Die unterste Reihe des Lochs ist hole_y + HOLE_RADIUS − 1, die unterste des
	# Papiers paper_height − 1. Dazwischen muss noch eine Reihe Papier liegen.
	while hole_y + HOLE_RADIUS < paper_height:
		result.append(hole_y)
		hole_y += HOLE_SPACING
	return result


## Malt die Auswahl auf Zeile [param row] (0 ist die Kopfzeile): signalgelb im Innenbereich,
## davor der Pfeil. [param available] false dämpft den Pfeil wie den Text.
static func draw_selection(canvas: CanvasItem, width: float, row: int, available: bool) -> void:
	var row_top := ROW_HEIGHT * row
	var highlight := Rect2(ROW_INSET, row_top, width - 2 * ROW_INSET, ROW_HEIGHT)
	canvas.draw_rect(highlight, UiPalette.SIGNALGELB)
	# (20 − 7) / 2 geht nicht auf. Abgerundet belegt der Pfeil die Pixelreihen 6 bis 12
	# der Zeile.
	var arrow_top := row_top + floori((ROW_HEIGHT - ARROW_HEIGHT) / 2.0)
	# Bei einem nicht verfügbaren Eintrag ist der Pfeil gedämpft wie sein Text, dem das
	# Theme font_disabled_color in gehaeuse-dunkel gibt. So sieht die Zeile ausgewählt
	# genauso gedämpft aus wie in Ruhe (FR-007 aus Feature 001).
	var arrow_color := UiPalette.TUSCHE if available else UiPalette.GEHAEUSE_DUNKEL
	draw_arrow(canvas, Vector2(ARROW_X, arrow_top), arrow_color)


## Der Pfeil als Pixel-Dreieck: vier Spalten mit den Höhen 7, 5, 3 und 1, jede mittig.
static func draw_arrow(canvas: CanvasItem, top_left: Vector2, color: Color) -> void:
	for column in ARROW_WIDTH:
		var height := ARROW_HEIGHT - 2 * column
		canvas.draw_rect(Rect2(top_left.x + column, top_left.y + column, 1, height), color)
