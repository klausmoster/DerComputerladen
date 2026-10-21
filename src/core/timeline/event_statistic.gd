class_name EventStatistic
extends RefCounted

## Die Statistik eines Ereignisses über viele Spiele (FR-044; data-model.md, „EventStatistic“):
## wie oft es im Schnitt beginnt, wie oft mindestens und höchstens, in wie vielen Spielen gar
## nicht oder bis zu seiner Obergrenze, und in welchen Jahren.
##
## Gezählt werden Beginne, also Termine, die laufen, eingetreten oder beendet sind. Entfallene und
## abgesagte Termine haben nie begonnen und zählen nicht; ebenso wenig Termine, die am Spielende
## noch geplant sind.
##
## Die Felder füllt TimelineStatistics, Spiel für Spiel; diese Klasse rechnet daraus nur den
## Mittelwert und die beiden Anteile. Die Werkstatt zeigt sie im Reiter „Statistik“.

## Das erste Jahr in per_year und die Zahl der Jahre bis 1999.
const FIRST_YEAR := 1985
const YEARS := 15

var event_id: String = ""
var title: String = ""
## Zahl der gerechneten Spiele.
var games: int = 0
## Beginne über alle Spiele.
var total: int = 0
## Kleinste und größte Anzahl an Beginnen in einem Spiel; beide 0, solange kein Spiel gerechnet
## ist.
var minimum: int = 0
var maximum: int = 0
## Spiele, in denen das Ereignis nie begann.
var games_without: int = 0
## Spiele, in denen es seine Obergrenze erreichte: die Höchstzahl bei Ereignissen über
## Wahrscheinlichkeit, die höchste Anzahl bei gesetzten (TimelineStatistics.upper_limit()). −1 bei
## Ereignissen ohne Obergrenze.
var games_at_max: int = -1
## Beginne je Jahr von 1985 bis 1999 über alle Spiele; Stelle 0 ist 1985.
var per_year: PackedInt32Array = PackedInt32Array()


func _init() -> void:
	per_year.resize(YEARS)
	per_year.fill(0)


## Beginne im Schnitt je Spiel: total / games; 0, solange kein Spiel gerechnet ist.
func mean() -> float:
	if games <= 0:
		return 0.0
	return float(total) / games


## Anteil der Spiele ohne Beginn, von 0 bis 1.
func share_without() -> float:
	if games <= 0:
		return 0.0
	return float(games_without) / games


## Anteil der Spiele, in denen die Obergrenze erreicht wurde, von 0 bis 1; −1 bei Ereignissen ohne
## Obergrenze, damit die Werkstatt dort „–“ zeigen kann.
func share_at_max() -> float:
	if games_at_max < 0:
		return -1.0
	if games <= 0:
		return 0.0
	return float(games_at_max) / games
