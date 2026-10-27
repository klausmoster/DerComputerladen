class_name UiPalette
extends RefCounted

## Die 16 Oberflächenfarben aus dem Style-Guide, Namen wie die Tokens in `tokens.json`.
##
## Die Werte kommen unverändert aus dem Style-Guide. Die ersten 15 stehen genauso in der
## Hauptpalette `docs/art/hauptpalette.gpl` (Index 1 bis 15). Die 16., `lcd`, steht nicht in der
## Hauptpalette: Sie gibt es nur in der Oberfläche, nie in einem Bild, und die Hauptpalette bleibt
## eingefroren (Feature 005, research.md, R1). Farben der Oberfläche kommen nur von hier oder aus
## dem Theme, nie frei gewählt.
##
## Die Klasse wird nie instanziiert: Konstanten und statische Funktionen hängen an der
## Klasse selbst, deshalb gehen `UiPalette.TUSCHE` und `UiPalette.by_token(&"petrol")`
## überall, ohne Autoload und ohne `new()`.

const TUSCHE := Color("1d1916")
const NACHT := Color("18233b")
const NACHT_HELL := Color("2c3d63")
const GEHAEUSE_DUNKEL := Color("6f6654")
const GEHAEUSE := Color("bdb39a")
const GEHAEUSE_HELL := Color("e4dcc6")
const PAPIER := Color("f5f0e2")
const ENDLOS_GRUEN := Color("cfe2c3")
const ANZEIGE_GRUND := Color("0d1716")
const ANZEIGE := Color("6ff0cf")
const KASSENROT := Color("c0392b")
const SIGNALGELB := Color("f2bf2f")
const PETROL := Color("1f6f75")
const HOLZ := Color("8b5a34")
const HOLZ_DUNKEL := Color("57351d")
## Grund der Anzeige des Communicators beim Organizer, ein graugrünes LCD-Grau (Style-Guide,
## Baustein Communicator). Nur Oberfläche, nicht in der Hauptpalette.
const LCD := Color("b8c4a8")

## Token-Name aus dem Style-Guide → Farbe, für alle 16 Farben, z. B. &"gehaeuse-hell".
## Daten wie der Ereigniskatalog nennen Farben über diese Namen statt über Farbwerte.
const TOKENS := {
	&"tusche": TUSCHE,
	&"nacht": NACHT,
	&"nacht-hell": NACHT_HELL,
	&"gehaeuse-dunkel": GEHAEUSE_DUNKEL,
	&"gehaeuse": GEHAEUSE,
	&"gehaeuse-hell": GEHAEUSE_HELL,
	&"papier": PAPIER,
	&"endlos-gruen": ENDLOS_GRUEN,
	&"anzeige-grund": ANZEIGE_GRUND,
	&"anzeige": ANZEIGE,
	&"kassenrot": KASSENROT,
	&"signalgelb": SIGNALGELB,
	&"petrol": PETROL,
	&"holz": HOLZ,
	&"holz-dunkel": HOLZ_DUNKEL,
	&"lcd": LCD,
}

## Tokens, die der Style-Guide für Kategorien erlaubt, in seiner Reihenfolge; jedes mit
## mindestens 3 : 1 Kontrast zu papier und endlos-gruen, den Gründen des Zeitstrahls (R14).
const CATEGORY_TOKENS: Array[StringName] = [
	&"nacht-hell", &"petrol", &"nacht", &"kassenrot", &"holz-dunkel", &"gehaeuse-dunkel", &"holz",
]


## Farbe zum Token; Color(1, 0, 1) (Magenta) für unbekannte Tokens, damit Fehler auffallen.
static func by_token(token: StringName) -> Color:
	var color: Color = TOKENS.get(token, Color(1, 0, 1))
	return color
