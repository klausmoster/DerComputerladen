class_name KeySequence
extends RefCounted

## Eine Folge von Tastenplätzen, die in genau dieser Reihenfolge kommen muss, etwa die Gehäusetasten
## links, Mitte, rechts für das Easter Egg (Feature 006, contracts/titelbildschirm.md, „KeySequence“;
## research.md, R5; data-model.md, „Folge“).
##
## Ein schlichtes Objekt ohne Node: Es hat keine Lage, malt nichts und braucht weder Baum noch Takt.
## Wer die Tasten hört, gibt jeden Druck mit press() weiter und erfährt, ob die Folge damit voll ist.
## RefCounted gibt es frei, sobald niemand mehr darauf verweist.
##
## Regel (FR-003): Die richtige nächste Taste zählt eins weiter. Eine falsche setzt zurück; ist sie
## die erste der Folge, zählt sie gleich als neuer Anfang. So startet 1-1-2-3, 1-2-2-3 aber nicht.

## Die Folge der Tastenplätze, von links gezählt ab 0.
var _expected: Array[int] = []
## Wie viele der Folge schon richtig kamen, 0 bis _expected.size() - 1.
var _progress := 0


## [param expected]: die Folge der Tastenplätze, hier [0, 1, 2].
func _init(expected: Array[int]) -> void:
	_expected = expected.duplicate()


## Ein Druck auf [param index]. true, wenn die Folge damit vollständig ist; dann beginnt sie von vorn.
## Ein falscher Druck setzt zurück; ist er expected[0], zählt er als neuer Anfang (FR-003).
func press(index: int) -> bool:
	if _expected.is_empty():
		return false
	if index == _expected[_progress]:
		_progress += 1
		if _progress == _expected.size():
			_progress = 0
			return true
		return false
	_progress = 1 if index == _expected[0] else 0
	return false


## Beginnt von vorn.
func reset() -> void:
	_progress = 0


## Wie viele der Folge schon richtig kamen (Tests).
func progress() -> int:
	return _progress
