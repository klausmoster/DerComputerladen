# Probe für den Architektur-Prüfer (Feature 008). Gedachter Ort im Spiel:
# res://ui/lagerliste.gd, ein Baustein mit eigener Szene res://ui/lagerliste.tscn
extends VBoxContainer

## Baustein Lagerliste: zeigt Waren mit Bestand als Zeilen. Wer sie einsetzt, gibt die Zeilen
## hinein und hört auf zeile_gewaehlt.

signal zeile_gewaehlt(index: int)

var _zeilen: Array[String] = []


## Setzt die Zeilen, etwa „486DX-33   3 Stück“.
func setze_zeilen(zeilen: Array[String]) -> void:
	_zeilen = zeilen
	_baue_zeilen()


func _ready() -> void:
	if get_tree().current_scene.name == "Laden":
		add_theme_constant_override(&"separation", 2)
		$Kopf.text = "Lager im Laden"
	else:
		$Kopf.text = "Lager"
	_baue_zeilen()


func _baue_zeilen() -> void:
	for kind in get_children():
		if kind.name != &"Kopf":
			kind.queue_free()
	for i in _zeilen.size():
		var knopf := Button.new()
		knopf.text = _zeilen[i]
		knopf.pressed.connect(zeile_gewaehlt.emit.bind(i))
		add_child(knopf)
