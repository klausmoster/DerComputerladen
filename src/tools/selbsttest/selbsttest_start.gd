extends Node

## Startszene der Selbsttest-App (Feature 007, contracts/selbsttest-app.md, „Start“; R3, R4, R7).
## Die App startet hier, weil project.godot für den Feature-Tag „selbsttest“ eine eigene
## Hauptszene nennt (application/run/main_scene.selbsttest); das Spiel selbst weiß nichts davon.
##
## Sie richtet den Lauf ein und tritt dann ab:
## 1. Ablage für den Lauf anlegen. Lässt sich dort nicht schreiben, gibt sie die Meldung aus und
##    beendet; die Zusammenfassung, die sie zeigen soll, kommt erst in Phase 4.
## 2. Logger anmelden, Systemdaten erheben, sobald das Fenster seine Größe hat (Analyse, I6).
## 3. GameSession auf den eigenen Ordner, die feste Zeit und den festen Seed stellen, SaveGame auf
##    die feste Zeitzone (FR-008). Dafür gibt es diese Felder schon; am Spiel ändert sich nichts.
## 4. Den Filter der Eingabe einschalten.
## 5. Den Läufer an die Wurzel hängen, damit er Szenenwechsel überlebt, und zum Titel wechseln.

## Der Titel, zu dem die Startszene wechselt.
const TITEL := "res://scenes/title/title_screen.tscn"
## Ordner der Spielstände im Selbsttest; echte Spielstände liegen in user://spielstaende/.
const SPIELSTAENDE := "user://selbsttest/spielstaende/"
## Die feste Uhrzeit, mit der das Spiel rechnet: 26.10.2026, 20:40 UTC, als Unix-Zeit (R7).
const FESTE_ZEIT := 1793047200
## Seed des Würfels für neue Spiele (R7).
const SEED := 4711
## Zeitzone UTC+1 in Minuten, für SaveGame.time_zone_bias (R7).
const ZEITZONE_MINUTEN := 60
## So viele Bilder, bis GameWindow dem Fenster seine Größe gegeben hat; es tut das im ersten Bild.
const BILDER_BIS_ZUR_FENSTERGROESSE := 3


func _ready() -> void:
	var lauf := SelbsttestLauf.new()
	var ablage := SelbsttestAblage.new(lauf.id)
	if ablage.lege_an() != OK:
		printerr(SelbsttestTexte.kein_protokoll(ablage.ordner()))
		get_tree().quit(1)
		return

	var logger := SelbsttestLogger.new()
	OS.add_logger(logger)

	# Die Lambda nimmt die Zeit aus einer lokalen Variable und nicht über self: Diese Szene ist nach
	# dem Wechsel zum Titel weg, die Lambda lebt in GameSession weiter.
	var zeit := FESTE_ZEIT
	GameSession.folder = SPIELSTAENDE
	GameSession.now = func() -> int: return zeit
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = SEED
	GameSession.rng = wuerfel
	SaveGame.time_zone_bias = ZEITZONE_MINUTEN

	var eingabe := SelbsttestEingabe.new()
	eingabe.einschalten(get_window())
	var fahrer := SelbsttestFahrer.new(get_tree(), eingabe)

	# system.fenster soll die Größe nach dem Start nennen (Analyse, I6).
	for bild in BILDER_BIS_ZUR_FENSTERGROESSE:
		await get_tree().process_frame
	var system := SelbsttestSystem.new()
	system.erhebe()

	lauf.system = system.werte
	lauf.version = SelbsttestLaeufer.VERSION
	lauf.feste_zeit = FESTE_ZEIT
	lauf.feste_zeitzone = ZEITZONE_MINUTEN
	lauf.zeitraffer = SelbsttestAblauf.ZEITRAFFER

	var laeufer := SelbsttestLaeufer.new()
	laeufer.name = "SelbsttestLaeufer"
	laeufer.fahrer = fahrer
	laeufer.eingabe = eingabe
	laeufer.ablage = ablage
	laeufer.logger = logger
	laeufer.logger_angemeldet = true
	laeufer.system = system
	# Zeitversetzt, wie der Vertrag es sagt: Beide Aufrufe laufen am Ende dieses Bilds in dieser
	# Reihenfolge, erst einhängen, dann starten. Der Läufer wartet dann, bis der Titel steht.
	get_tree().root.add_child.call_deferred(laeufer)
	laeufer.starte.call_deferred(lauf, SelbsttestLaeufer.ablaeufe())
	get_tree().change_scene_to_file(TITEL)
