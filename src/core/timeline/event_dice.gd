class_name EventDice
extends RefCounted

## Die Würfel der Zeitleiste (research.md, R5): Jede Zufallsentscheidung bekommt einen eigenen
## RandomNumberGenerator. Sein Startwert hängt nur vom Seed des Spiels, vom Zweck und von einem
## Schlüssel ab, etwa der Kennung des Ereignisses.
##
## So hängt jede Entscheidung nur von Seed, Ereignis und Zeitpunkt ab (FR-015): Ein neues
## Ereignis oder eine geänderte Chance verschiebt die Würfe der anderen nicht, denn kein anderes
## Ereignis zieht Zahlen aus demselben Generator.
##
## Welcher Zweck wann wie oft würfelt, legt der Vertrag fest (contracts/zeitleiste.md, Tabelle
## „Zwecke und Würfe“); TimelineRun hält sich daran.

## Ein Generator je Ereignis über Wahrscheinlichkeit für alle 180 Würfelrunden; Schlüssel ist die
## Kennung.
const PURPOSE_CHANCE := "chance"
## Einmal beim Anlegen des Fahrplans je Ereignis „beim Start gesetzt“; Schlüssel ist die Kennung.
const PURPOSE_PRESET := "preset"
## Je Entscheidung über ein Folgeereignis; Schlüssel ist "<quelle>|<index>|<tag>".
const PURPOSE_FOLLOW := "follow"


# Der Parameter heißt laut Vertrag seed, wie die globale Funktion seed(). Gemeint ist der Seed des
# Spiels; @warning_ignore schaltet die Warnung darüber ab, sonst wäre der Start mit -d nicht still.

## Neuer Generator; Startwert = SHA-256("<seed>|<purpose>|<key>"), erste 8 Byte (R5).
##
## Laut Doku ergeben ähnliche Startwerte bei RandomNumberGenerator ähnliche Folgen; der Hash
## davor mischt sie gründlich. decode_u64() liest die ersten 8 Byte als ganze Zahl. Liegt sie
## über 2^63, ist sie in GDScript negativ; als Startwert ist das gleichgültig.
@warning_ignore("shadowed_global_identifier")
static func make(seed: int, purpose: String, key: String) -> RandomNumberGenerator:
	var dice := RandomNumberGenerator.new()
	dice.seed = ("%d|%s|%s" % [seed, purpose, key]).sha256_buffer().decode_u64(0)
	return dice
