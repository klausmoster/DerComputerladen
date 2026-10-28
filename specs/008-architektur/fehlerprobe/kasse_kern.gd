# Probe für den Architektur-Prüfer (Feature 008). Gedachter Ort im Spiel:
# res://core/laden/kasse_kern.gd
class_name KasseKern
extends RefCounted

## Kern der Kasse: rechnet aus, was ein Verkauf einbringt und ob der Kunde handelt. Die Hülle
## ist die Szene Laden; sie ruft verkaufe() und zeigt das Ergebnis.

## Eigener Würfel; die Hülle setzt ihn mit einem Startwert aus dem Seed des Spiels.
var _rng: RandomNumberGenerator
## Umsatz des laufenden Tages in Pfennig.
var umsatz_pf: int = 0


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


## Verkauft eine Ware zum Preis in Pfennig. Ob der Kunde einen Rabatt verlangt, entscheidet der
## eigene Würfel.
func verkaufe(preis_pf: int) -> int:
	var erloes := preis_pf
	if _rng.randf() < 0.2:
		erloes = preis_pf * 95 / 100
	umsatz_pf += erloes
	return erloes


## Tagesabschluss: setzt den Umsatz zurück und gibt ihn zurück. Am Monatsende kommt die Miete dazu.
func tagesabschluss() -> int:
	var tag := umsatz_pf
	umsatz_pf = 0
	if GameClock.date.day == 1:
		tag -= 120000
	return tag
