class_name EventEffect
extends Resource

## Eine einzelne Auswirkung (Kettenreaktion) eines Timeline-Ereignisses auf ein
## anderes Spielsystem. Die Engine wendet den Effekt nicht selbst an, sondern
## meldet ihn per Signal – Wirtschaft, Nachfrage, Reputation usw. hängen sich
## später an `Timeline.effect_applied` und reagieren auf `kind`/`target`.

enum Kind {
	PREIS,         ## Preisänderung eines Produkts/einer Kategorie (magnitude = relativ)
	NACHFRAGE,     ## Nachfrageänderung
	REPUTATION,    ## Ruf des Ladens
	KUNDENSTROM,   ## Laufkundschaft / neue Kundenschicht
	PRESSE,        ## Fachpresse berichtet (reiner Info-Effekt)
	SPAWN,         ## Löst ein weiteres Ereignis aus (target = Ereignis-Id)
}

@export var kind: Kind = Kind.PRESSE
## Bezugsobjekt, z.B. "cpu_486", "ram", "modem", "maus", "*" für alles.
@export var target: String = ""
## Relative Stärke, z.B. -0.30 = -30 %. Bei reinen Info-Effekten 0.
@export var magnitude: float = 0.0
## Verzögerung in Tagen, bevor der Effekt greift (0 = sofort).
@export var delay_days: int = 0
@export_multiline var note: String = ""


func kind_label() -> String:
	return Kind.keys()[kind].capitalize()


func describe() -> String:
	var parts := [kind_label()]
	if not target.is_empty():
		parts.append(target)
	if magnitude != 0.0:
		parts.append("%+.0f%%" % (magnitude * 100.0))
	var head := " · ".join(parts)
	return "%s — %s" % [head, note] if not note.is_empty() else head
