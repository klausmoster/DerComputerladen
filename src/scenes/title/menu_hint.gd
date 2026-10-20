class_name MenuHint
extends PanelContainer

## Der Hinweis zur gewählten Zeile des Hauptmenüs (Baustein Hinweis im Style-Guide).
##
## Er steht links neben der Zeile, 4 Pixel davor und oben bündig, erscheint ohne
## Verzögerung und bleibt stehen, bis `show_for()` mit einer anderen Zeile kommt.
## Godots eingebauter Tooltip passt dafür nicht: Er erscheint nur für die Maus und erst
## nach einer Wartezeit (research.md, R10).
##
## Feld, Kontur und Innenabstand kommen aus der Theme-Variante `HintPanel`, die Schrift
## aus `HintLabel`. Den pixelschatten malt `_draw()`, denn der Schatten einer
## StyleBoxFlat ist weich.

## Abstand zwischen der rechten Kante des Hinweises und der Zeile.
const GAP := 4
## Größte Breite des Textes; längere Hinweise brechen um. Der ganze Kasten ist höchstens
## 160 breit, davon gehen links und rechts je 5 ab (1 Kontur und 4 Innenabstand, siehe
## content_margin der Theme-Variante HintPanel).
const MAX_TEXT_WIDTH := 150
## pixelschatten: harter Versatz nach rechts unten, ohne Unschärfe.
const SHADOW_OFFSET := 2

@onready var _text: Label = $Text


func _ready() -> void:
	# Wächst der Hinweis, dann nach links, und die rechte Kante bleibt vor der Zeile. Das
	# steht auch in menu_hint.tscn, hält dort aber nicht: layout_mode = 0 an einer Instanz
	# setzt die Wuchsrichtung beim Laden zurück. _ready() kommt danach und gilt immer.
	grow_horizontal = GROW_DIRECTION_BEGIN


func _draw() -> void:
	# Der Schatten gehört unter das Feld, _draw() malt aber nach dem Feld. Deshalb nur
	# der Teil, der rechts und unten herausschaut: zwei Streifen, zusammen ein L.
	draw_rect(Rect2(size.x, SHADOW_OFFSET, SHADOW_OFFSET, size.y), UiPalette.TUSCHE)
	draw_rect(Rect2(SHADOW_OFFSET, size.y, size.x, SHADOW_OFFSET), UiPalette.TUSCHE)


## Zeigt den Hinweis von [param entry] links neben [param row_rect]: die rechte Kante
## 4 Pixel vor der Zeile, die Oberkanten bündig. [param row_rect] ist global.
func show_for(entry: MenuEntry, row_rect: Rect2) -> void:
	_set_text(entry.hint)
	reset_size()
	global_position = Vector2(row_rect.position.x - GAP - size.x, row_rect.position.y)
	show()


func hide_hint() -> void:
	hide()


## Setzt den Text und seine Breite: so breit wie der Text in einer Zeile, höchstens
## [constant MAX_TEXT_WIDTH].
func _set_text(text: String) -> void:
	var font := _text.get_theme_font(&"font")
	var font_size := _text.get_theme_font_size(&"font_size")
	var line_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var width := minf(ceilf(line_width), MAX_TEXT_WIDTH)
	# Erst die Breite, dann der Text. Ein umbrechendes Label rechnet seine Höhe mit
	# seiner aktuellen Breite, und die setzt der PanelContainer erst beim nächsten
	# Anordnen. Käme der Text zuerst, bekäme reset_size() in show_for() die Höhe für
	# die alte Breite, und der Hinweis wäre zu hoch.
	_text.custom_minimum_size.x = width
	_text.size.x = width
	_text.text = text
