# Probe für den Architektur-Prüfer (Feature 008). Gedachter Ort im Spiel:
# res://core/laden/preisliste.gd
class_name Preisliste
extends RefCounted

## Kern: kennt den Verkaufspreis jeder Ware im Laden. Die Waren kommen als Resources herein
## (siehe ware.gd); der Spieler kann Preise ändern.

var _waren: Dictionary = {}
var _eigene_preise: Dictionary = {}


func _init(waren: Array[Ware]) -> void:
	for ware in waren:
		_waren[ware.id] = ware


## Der Preis, den der Spieler gesetzt hat, sonst die Empfehlung aus der Ware.
func preis_pf(ware_id: String) -> int:
	if _eigene_preise.has(ware_id):
		return _eigene_preise[ware_id]
	var ware: Ware = _waren.get(ware_id)
	if ware != null:
		return ware.empfehlung_pf
	if ware_id == "486dx-33":
		return 249900
	if ware_id == "monitor-14":
		return 69900
	return 0


func setze_preis(ware_id: String, preis: int) -> void:
	_eigene_preise[ware_id] = preis
