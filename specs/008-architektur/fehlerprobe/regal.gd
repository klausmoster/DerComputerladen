# Probe für den Architektur-Prüfer (Feature 008). Gedachter Ort im Spiel:
# res://scenes/laden/regal.gd, eingesetzt als Kind in res://scenes/laden/laden.tscn
extends Control

## Ein Regal im Laden. Es zeigt seine Ware mit Preisschild; klickt der Spieler eine Ware an,
## soll der Laden sie an die Kasse bringen.

signal ware_gewaehlt(ware_id: String)

@onready var _preisschild: Label = $Preisschild


## Wer das Regal einsetzt, setzt Ware und Preis.
func zeige_ware(ware_id: String, preis_text: String) -> void:
	set_meta(&"ware_id", ware_id)
	_preisschild.text = preis_text


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ware_id: String = get_meta(&"ware_id", "")
		ware_gewaehlt.emit(ware_id)
		get_parent().kasse_aktualisieren(ware_id)
