class_name EventEffect
extends RefCounted

## Eine einzelne Wirkung eines Ereignisses auf ein anderes Spielsystem (FR-007, data-model.md,
## „EventEffect“). Die Zeitleiste wendet die Wirkung nicht selbst an, sondern meldet sie per
## Signal; Wirtschaft, Nachfrage, Reputation usw. hängen sich später an
## `Timeline.effect_applied` und reagieren auf [member kind] und [member target].
##
## Folgeereignisse sind keine Wirkung mehr, sondern ein eigener Teil des Ereignisses
## (`FollowUp`); die frühere Art SPAWN entfällt deshalb.

enum Kind {
	PREIS,         ## Preisänderung eines Produkts oder einer Warengruppe (magnitude relativ)
	NACHFRAGE,     ## Nachfrageänderung
	REPUTATION,    ## Ruf des Ladens
	KUNDENSTROM,   ## Laufkundschaft, neue Kundenschicht
	PRESSE,        ## Fachpresse berichtet (reine Meldung, magnitude 0)
}

enum Scope {
	ONCE,          ## einmaliger Anstoß: wird einmal gemeldet
	DURING,        ## gilt nur während des Ereignisses: Beginn und Ende werden gemeldet
}

## Namen in der Datei, in der Reihenfolge von Kind und Scope (contracts/ereigniskatalog.md).
const KIND_NAMES: Array[String] = ["preis", "nachfrage", "reputation", "kundenstrom", "presse"]
const SCOPE_NAMES: Array[String] = ["once", "during"]
## Anzeige in der Reihenfolge von Kind; REPUTATION heißt im Spiel „Ruf“.
const KIND_LABELS: Array[String] = ["Preis", "Nachfrage", "Ruf", "Kundenstrom", "Presse"]
## Schlüssel einer Wirkung in der Datei.
const KEYS := ["delay_days", "kind", "magnitude", "note", "scope", "target"]

var kind: Kind = Kind.PRESSE
## Bezugsobjekt, z. B. "cpu_486", "ram", "modem", "maus" oder "*" für alles.
var target: String = "*"
## Relative Stärke, z. B. -0.30 = -30 %. Bei reinen Meldungen 0.
var magnitude: float = 0.0
## Verzögerung in Tagen ab Beginn des Ereignisses (0 = sofort).
var delay_days: int = 0
## Ob die Wirkung einmal angestoßen wird oder nur während des Ereignisses gilt. Bei Ereignissen
## ohne Dauer wirkt DURING wie ONCE (FR-021).
var scope: Scope = Scope.ONCE
var note: String = ""


## Liest eine Wirkung aus ihrem Dictionary in der Datei. Strukturfehler hängt es als V22 an
## [param issues] an; zu welchem Ereignis sie gehören, setzt `TimelineEvent.from_dict()`.
##
## Fehlt [member scope], bleibt hier ONCE stehen. Die Vorgabe hängt an der Dauer des Ereignisses,
## deshalb setzt sie `TimelineEvent.from_dict()`.
static func from_dict(data: Dictionary, issues: Array[CatalogIssue]) -> EventEffect:
	var effect := EventEffect.new()
	CatalogIssue.check_keys(data, KEYS, issues)
	effect.delay_days = CatalogIssue.read_int(data, "delay_days", issues, effect.delay_days)
	effect.kind = CatalogIssue.read_choice(data, "kind", KIND_NAMES, issues, effect.kind) as Kind
	effect.magnitude = CatalogIssue.read_float(data, "magnitude", issues, effect.magnitude)
	effect.note = CatalogIssue.read_string(data, "note", issues, effect.note)
	effect.scope = CatalogIssue.read_choice(data, "scope", SCOPE_NAMES, issues,
		effect.scope) as Scope
	effect.target = CatalogIssue.read_string(data, "target", issues, effect.target)
	return effect


func to_dict() -> Dictionary:
	return {
		"delay_days": delay_days,
		"kind": KIND_NAMES[kind],
		# Anteile stehen auf vier Nachkommastellen in der Datei (Schreibregel 3).
		"magnitude": roundf(magnitude * 10000.0) / 10000.0,
		"note": note,
		"scope": SCOPE_NAMES[scope],
		"target": target,
	}


func kind_label() -> String:
	return KIND_LABELS[kind]


func describe() -> String:
	var parts := [kind_label()]
	if not target.is_empty():
		parts.append(target)
	if magnitude != 0.0:
		parts.append("%+.0f%%" % (magnitude * 100.0))
	var head := " · ".join(parts)
	return "%s — %s" % [head, note] if not note.is_empty() else head
