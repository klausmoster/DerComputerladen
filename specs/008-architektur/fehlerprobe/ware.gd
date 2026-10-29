# Probe für den Architektur-Prüfer (Feature 008). Gedachter Ort im Spiel: res://data/ware.gd;
# je Ware eine .tres-Datei unter res://data/waren/, gepflegt im Inspector.
class_name Ware
extends Resource

## Eine Ware im Sortiment: Bezeichnung, Einkaufspreis und empfohlener Verkaufspreis.

@export var id: String = ""
@export var bezeichnung: String = ""
@export var einkauf_pf: int = 0
@export var empfehlung_pf: int = 0
