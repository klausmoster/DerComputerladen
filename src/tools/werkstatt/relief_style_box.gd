@tool
class_name ReliefStyleBox
extends StyleBox

## Kasten für Knöpfe, Leisten und Menüs der Werkzeuge (Style-Guide, Abschnitt „Werkzeuge“): eine
## Fläche in einer Farbe der Palette mit 1 Pixel Kontur in tusche, dazu wahlweise das Relief der
## Knöpfe und der harte Pixelschatten der Menüs.
##
## StyleBoxFlat reicht dafür nicht. Es kennt nur eine Randfarbe, das Relief braucht aber zwei:
## Licht oben links in gehaeuse-hell, Schatten unten rechts in gehaeuse-dunkel, beim Drücken
## umgekehrt (relief-erhaben, relief-gedrueckt). Und sein Schatten ist weich und halb
## durchsichtig, der Pixelschatten dagegen hart. Ein eigener StyleBox zeichnet deshalb selbst:
## Godot ruft _draw() mit dem Rechteck des Controls auf, wie bei jedem anderen StyleBox.
##
## Die Farben stehen als Token-Namen aus UiPalette in den Eigenschaften, nicht als Farbwerte; so
## kommen sie auch im Theme nur aus der Palette. Die Innenabstände setzt das Theme über
## content_margin_*. Sie rechnen Kontur und Relief ein, beim Pixelschatten rechts und unten auch
## dessen 2 Pixel.
##
## @tool sorgt dafür, dass der Editor den Kasten auch in der Szenenansicht zeichnet.

enum Relief {
	NONE,     ## flach
	RAISED,   ## relief-erhaben: Licht oben links, Schatten unten rechts
	PRESSED,  ## relief-gedrueckt: Schatten oben links, Licht unten rechts
}

## Kontur und Pixelschatten.
const OUTLINE := &"tusche"
## Lichtkante und Schattenkante des Reliefs.
const LIGHT := &"gehaeuse-hell"
const DARK := &"gehaeuse-dunkel"
## Versatz des Pixelschattens nach rechts unten (pixelschatten: 2px 2px 0 tusche).
const SHADOW_OFFSET := 2

## Farbe der Fläche, ein Token aus UiPalette.TOKENS wie &"gehaeuse" oder &"signalgelb". Ein
## unbekanntes Token ergibt Magenta, damit der Tippfehler auffällt.
@export var fill: StringName = &"gehaeuse":
	set(value):
		fill = value
		emit_changed()
@export var relief: Relief = Relief.RAISED:
	set(value):
		relief = value
		emit_changed()
## Harter Schatten von 2 Pixeln nach rechts unten. Er liegt innerhalb des Rechtecks, denn Menüs
## und Tooltips sind eigene Fenster und schneiden ab, was außerhalb liegt. Der Kasten selbst
## wird dafür 2 Pixel schmaler und niedriger.
@export var pixel_shadow: bool = false:
	set(value):
		pixel_shadow = value
		emit_changed()


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	for layer in layers(rect):
		RenderingServer.canvas_item_add_rect(to_canvas_item, layer["rect"], layer["color"])


## Die Rechtecke, die _draw() zeichnet, von unten nach oben, je { "rect": Rect2, "color": Color }.
## Jedes liegt über den vorigen; was davon zu sehen bleibt, ergibt den Kasten. Headless zeichnet
## Godot nichts Sichtbares, deshalb prüfen die Tests den Kasten über diese Liste.
func layers(rect: Rect2) -> Array[Dictionary]:
	# Auf ganze Pixel, sonst lägen die 1-Pixel-Linien zwischen zwei Pixeln und würden verschmiert.
	var start := rect.position.round()
	var box := Rect2(start, rect.end.round() - start)
	var result: Array[Dictionary] = []
	if pixel_shadow:
		box.size -= Vector2(SHADOW_OFFSET, SHADOW_OFFSET)
		_add(result, Rect2(box.position + Vector2(SHADOW_OFFSET, SHADOW_OFFSET), box.size), OUTLINE)
	_add(result, box, OUTLINE)
	var inner := box.grow(-1.0)
	_add(result, inner, fill)
	if relief != Relief.NONE:
		var top_left := LIGHT if relief == Relief.RAISED else DARK
		var bottom_right := DARK if relief == Relief.RAISED else LIGHT
		# Wie im Style-Guide (inset 1px 1px 0 hell, inset -1px -1px 0 dunkel) liegt die Kante oben
		# links über der unten rechts. Die Ecken oben rechts und unten links gehören also zu ihr.
		_add(result, Rect2(inner.position.x, inner.end.y - 1.0, inner.size.x, 1.0), bottom_right)
		_add(result, Rect2(inner.end.x - 1.0, inner.position.y, 1.0, inner.size.y), bottom_right)
		_add(result, Rect2(inner.position, Vector2(inner.size.x, 1.0)), top_left)
		_add(result, Rect2(inner.position, Vector2(1.0, inner.size.y)), top_left)
	return result


## Hängt ein Rechteck in der Farbe [param token] an, wenn es überhaupt Fläche hat; bei einem sehr
## kleinen Control bleibt sonst ein Rechteck mit negativer Größe übrig.
static func _add(result: Array[Dictionary], rect: Rect2, token: StringName) -> void:
	if rect.size.x > 0.0 and rect.size.y > 0.0:
		result.append({"rect": rect, "color": UiPalette.by_token(token)})
