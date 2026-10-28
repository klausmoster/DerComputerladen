extends "res://tools/selbsttest/ablaeufe/ablauf_titel.gd"

## Ablauf „titel_echtzeit“, Name „Titel in Echtzeit“ (contracts/ablaeufe.md, „titel_echtzeit“;
## FR-003a): dieselben Schritte wie „titel“, mit eigenen Kennungen und ohne Zeitraffer, also mit
## Engine.time_scale = 1. Fehler, die nur bei echtem Tempo auftreten, bleiben so sichtbar, und die
## Fotos müssen denen von „titel“ gleichen. Läuft als letzter Ablauf.


func _init() -> void:
	kennung = "titel_echtzeit"
	name = SelbsttestTexte.ablauf_name(kennung)
	zeitraffer = 1
