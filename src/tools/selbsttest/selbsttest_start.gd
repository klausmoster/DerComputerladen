extends Node

## Startszene der Selbsttest-App (Feature 007, contracts/selbsttest-app.md, „Start“; R3, R4, R7).
## Die App startet hier, weil project.godot für den Feature-Tag „selbsttest“ eine eigene
## Hauptszene nennt (application/run/main_scene.selbsttest); das Spiel selbst weiß nichts davon.
##
## Sie richtet den Lauf ein und tritt dann ab:
## 1. Ablage für den Lauf anlegen. Lässt sich dort nicht schreiben, erhebt sie nur die Systemdaten
##    und wechselt gleich zur Zusammenfassung mit der Meldung und dem Pfad (CHK020). Am Spiel
##    ändert sich dann nichts, und kein Ablauf läuft.
## 2. Logger anmelden, Systemdaten erheben, sobald das Fenster seine Größe hat (Analyse, I6).
## 3. GameSession auf den eigenen Ordner, die feste Zeit und den festen Seed stellen, SaveGame auf
##    die feste Zeitzone (FR-008). Dafür gibt es diese Felder schon; am Spiel ändert sich nichts.
##    Die Startszene ist die einzige Stelle, die die Sitzung so einrichtet; sie kommt über die Naht
##    session wie bei Läufer und Fahrer (AR-12).
## 4. Den Filter der Eingabe einschalten.
## 5. Den Läufer an die Wurzel hängen, damit er Szenenwechsel überlebt, und zum Titel wechseln.

## Ordner der Spielstände im Selbsttest, im Ordner der App (SelbsttestAblage.BASIS); echte
## Spielstände liegen in user://spielstaende/.
const SPIELSTAENDE := SelbsttestAblage.BASIS + "spielstaende/"
## Die feste Uhrzeit, mit der das Spiel rechnet: 26.10.2026, 20:40 UTC, als Unix-Zeit (R7).
const FESTE_ZEIT := 1793047200
## Zeitzone UTC+1 in Minuten, für SaveGame.time_zone_bias (R7).
const ZEITZONE_MINUTEN := 60
## So viele Bilder, bis GameWindow dem Fenster seine Größe gegeben hat; es tut das im ersten Bild.
const BILDER_BIS_ZUR_FENSTERGROESSE := 3

## GameSession hat als Autoload keinen class_name; den Typ gibt sein Skript.
const SESSION_SCRIPT := preload("res://core/game_session.gd")

## null heißt das Autoload GameSession; Tests setzen eine eigene, bevor die Szene in den Baum kommt.
var session: Node = null


func _ready() -> void:
	var lauf := SelbsttestLauf.new()
	var ablage := SelbsttestAblage.new(lauf.id)
	if ablage.lege_an() != OK:
		# Auch im Terminal zu lesen, etwa wenn die App unter Linux aus der Konsole startet.
		printerr(SelbsttestTexte.kein_protokoll(ablage.ordner()))
		var nur_system := await _erhebe_system()
		nur_system.hole_treiber()
		_trage_ein(lauf, nur_system)
		get_tree().change_scene_to_node(SelbsttestErgebnis.erstelle(lauf, ablage.ordner(),
			ablage.zip_pfad(), false))
		return

	var logger := SelbsttestLogger.new()
	OS.add_logger(logger)

	# Die Lambda nimmt die Zeit aus einer lokalen Variable und nicht über self: Diese Szene ist nach
	# dem Wechsel zum Titel weg, die Lambda lebt in GameSession weiter.
	var zeit := FESTE_ZEIT
	var sitzung := _session()
	sitzung.folder = SPIELSTAENDE
	sitzung.now = func() -> int: return zeit
	var wuerfel := RandomNumberGenerator.new()
	wuerfel.seed = SelbsttestFahrer.SEED
	sitzung.rng = wuerfel
	# Auch Godots globaler Würfel startet fest: Das versteckte Spiel nimmt seinen Seed aus randi().
	# Im Zeitraffer macht es je Bild genau 4 Schritte, so fallen die Bomben in jedem Lauf gleich.
	seed(SelbsttestFahrer.SEED)
	SaveGame.time_zone_bias = ZEITZONE_MINUTEN

	var eingabe := SelbsttestEingabe.new()
	eingabe.einschalten(get_window())
	var fahrer := SelbsttestFahrer.new(get_tree(), eingabe)
	fahrer.session = session

	var system := await _erhebe_system()
	_trage_ein(lauf, system)

	var laeufer := SelbsttestLaeufer.new()
	laeufer.name = "SelbsttestLaeufer"
	laeufer.fahrer = fahrer
	laeufer.eingabe = eingabe
	laeufer.ablage = ablage
	laeufer.logger = logger
	laeufer.logger_angemeldet = true
	laeufer.system = system
	laeufer.session = session
	# Zeitversetzt, wie der Vertrag es sagt: Beide Aufrufe laufen am Ende dieses Bilds in dieser
	# Reihenfolge, erst einhängen, dann starten. Der Läufer wartet dann, bis der Titel steht.
	get_tree().root.add_child.call_deferred(laeufer)
	laeufer.starte.call_deferred(lauf, SelbsttestLaeufer.ablaeufe())
	get_tree().change_scene_to_file(SelbsttestFahrer.TITEL)


func _session() -> SESSION_SCRIPT:
	return (session if session != null else GameSession) as SESSION_SCRIPT


## Die Systemdaten, sobald das Fenster seine Größe hat: system.fenster soll die Größe nach dem Start
## nennen (Analyse, I6).
func _erhebe_system() -> SelbsttestSystem:
	for bild in BILDER_BIS_ZUR_FENSTERGROESSE:
		await get_tree().process_frame
	var system := SelbsttestSystem.new()
	system.erhebe()
	return system


## Was der Lauf vom Start an weiß: Systemdaten, Version der Abläufe, feste Zeit und Zeitraffer. Auch
## ohne beschreibbaren Ordner, denn „Kopieren“ legt dann „# Lauf“ und „# System“ ab.
func _trage_ein(lauf: SelbsttestLauf, system: SelbsttestSystem) -> void:
	lauf.system = system.werte
	lauf.version = SelbsttestLaeufer.VERSION
	lauf.feste_zeit = FESTE_ZEIT
	lauf.feste_zeitzone = ZEITZONE_MINUTEN
	lauf.zeitraffer = SelbsttestAblauf.ZEITRAFFER
