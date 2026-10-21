class_name ChanceModifier
extends RefCounted

## Ein Modifikator (FR-025, data-model.md, „ChanceModifier“): Er verschiebt für eine Zeit die
## Chance eines Ereignisses über Wahrscheinlichkeit um einige Prozentpunkte, etwa „Ware vom
## windigen Händler: +5 Prozentpunkte vom 01.01.1990 bis 31.12.1993“ auf die Reklamationswelle.
##
## Ein Modifikator ändert nur die Schwelle, nie den Wurf (R5), und die Grundchance im Katalog
## bleibt unberührt. Gleichzeitig gültige Modifikatoren addieren sich; das rechnet
## TimelineRun.chance_info(). Abgelaufene werden nicht entfernt, sie gelten nur nicht mehr.

## Kennung, eindeutig im Lauf.
var id: String = ""
## Kennung eines Ereignisses über Wahrscheinlichkeit.
var event_id: String = ""
## Prozentpunkte als Anteil: +0.05 heißt +5 Prozentpunkte. Negativ senkt die Chance; 0 ist
## erlaubt.
var value: float = 0.0
## Lesbarer Grund, nicht leer, etwa „Ware vom windigen Händler“.
var reason: String = ""
## Erster Tag, an dem er gilt. Beim Eingreifen ist die Vorgabe der aktuelle Spieltag, vor
## Spielbeginn 0; dessen Würfelrunde ist dann schon vorbei, er wirkt also ab der nächsten.
var from_day: int = 0
## Letzter Tag, an dem er gilt, eingeschlossen. Das Ende ist Pflicht, „unbegrenzt“ heißt 5477,
## der 31.12.1999. Die Vorgabe −1 heißt „noch nicht gesetzt“; dann gilt er an keinem Tag.
var to_day: int = -1


## Ob er am Tag [param day] gilt: from_day ≤ day ≤ to_day.
func is_active(day: int) -> bool:
	return from_day <= day and day <= to_day
