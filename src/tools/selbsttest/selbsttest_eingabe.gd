class_name SelbsttestEingabe
extends RefCounted

## Maus und Tastatur des Selbsttests (Feature 007, contracts/selbsttest-app.md, „Eingabe“; R4;
## FR-004, FR-010). Jede Eingabe ist ein InputEvent mit device = DEVICE und geht durch
## Input.parse_input_event(), denselben Weg, den Godot für echte Maus und Tastatur nimmt. So
## entstehen Hover, mouse_entered, Fokus und Klicks wie bei einer echten Hand; kein Schritt ruft
## eine Funktion des Spiels auf.
##
## Der Filter sitzt am Fenster: einschalten() ersetzt mit
## DisplayServer.window_set_input_event_callback() den Empfang des Fensters. Godot gibt jedes
## Ereignis, ob echt oder vom Selbsttest, an diese eine Stelle, bevor irgendein Knoten es sieht.
## _empfange() reicht nur Ereignisse mit DEVICE an das Fenster weiter (Window.push_input()), alle
## anderen verwirft es. Ein Knoten mit _input() käme zu spät: Godot rechnet das Hover schon vorher
## aus (R4).
##
## Beim Weiterreichen bekommt ein eigenes Ereignis das Gerät, das Godot 4.7 echten Ereignissen gibt:
## InputEvent.DEVICE_ID_KEYBOARD für Tasten, DEVICE_ID_MOUSE für die Maus (fuer_das_spiel()). Die
## Aktionen wie ui_accept, ui_cancel und ui_focus_next gelten nur für Ereignisse dieses Geräts; mit
## DEVICE löste Enter nichts aus. DEVICE ist nur das Kennzeichen auf dem Weg bis zum Filter.
##
## Positionen kommen im Raster 640 × 360 herein, wie der Fahrer sie liefert, und gehen in
## Fensterpixeln hinaus: mal viewport.get_final_transform(), der Vergrößerung durch Stretch. Drücken
## und Loslassen gehen in zwei aufeinanderfolgenden Bildern hinaus, vor jedem Klick eine Bewegung
## aufs Ziel; verlässt der echte Zeiger das Fenster, löscht Godot das Hover, und erst die Bewegung
## stellt es wieder her (R4). Alle Methoden mit Eingaben sind mit await aufzurufen.
##
## Für Tests ohne Fenster gehen Ereignisse statt an Input an [member senke], etwa über
## fuer_das_spiel() an SubViewport.push_input(); einschalten() braucht es dann nicht.

## Kennung aller Eingaben des Selbsttests. Echte Geräte haben kleine Nummern.
const DEVICE := 4711

## Der Viewport, in dessen Raster die Positionen gemeint sind; einschalten() setzt das Fenster.
## Seine Transformation rechnet Raster in Fensterpixel um, sein Baum gibt die Bilder.
var viewport: Viewport = null
## Wohin die Ereignisse gehen. Vorgabe ist Input.parse_input_event(), der Weg echter Eingaben;
## Tests setzen push_input() ihres Viewports.
var senke: Callable = Input.parse_input_event

var _aktiv := false
## use_accumulated_input vor einschalten(), für ausschalten().
var _gesammelt_vorher := true
## Wann seit merke_beginn() die erste Eingabe hinausging, in ms; -1 heißt noch keine.
var _erste_ms := -1
## Wo die Maus zuletzt stand, in Fensterpixeln; für relative.
var _maus := Vector2.ZERO
## Welche Maustasten gerade unten sind, für button_mask.
var _tasten_maske: int = 0


## Schaltet den Filter am Fenster [param fenster] ein. Ab jetzt kommen nur noch Ereignisse mit
## DEVICE im Spiel an.
##
## Der Empfang ist eine Lambda, die self hält: Godot speichert ihn, und solange er gilt, bleibt
## auch dieses Objekt am Leben. Mit einer gewöhnlichen Methode als Callable hielte Godot nur die
## Kennung des Objekts; wäre es weg, käme keine einzige Eingabe mehr an.
func einschalten(fenster: Window) -> void:
	viewport = fenster
	_aktiv = true
	# Sonst fasst Godot Mausbewegungen eines Bilds zusammen, ohne auf device zu achten (R4).
	_gesammelt_vorher = Input.use_accumulated_input
	Input.use_accumulated_input = false
	DisplayServer.window_set_input_event_callback(
		func(event: InputEvent) -> void: _empfange(event), fenster.get_window_id())


## Hebt den Filter auf: Danach reicht der Empfang alles durch. Den ursprünglichen Empfang des
## Fensters gibt Godot nicht heraus; deshalb bleibt dieser bestehen und lässt alles passieren
## (Analyse, U3).
func ausschalten() -> void:
	_aktiv = false
	Input.use_accumulated_input = _gesammelt_vorher


## Ob der Filter gerade echte Eingaben verwirft.
func ist_aktiv() -> bool:
	return _aktiv


## Ob [param event] beim Spiel ankommen darf: alles, solange der Filter aus ist, sonst nur
## Eingaben des Selbsttests.
func durchlassen(event: InputEvent) -> bool:
	return not _aktiv or event.device == DEVICE


## Ab jetzt zählt erste_eingabe_ms() neu; der Läufer ruft es zu Beginn jedes Schritts.
func merke_beginn() -> void:
	_erste_ms = -1


## Wann seit merke_beginn() die erste Eingabe hinausging, nach Time.get_ticks_msec(); -1, wenn
## noch keine. Davon zählt dauer_ms eines Schritts (Analyse, I1).
func erste_eingabe_ms() -> int:
	return _erste_ms


## Fährt die Maus auf [param punkt_raster]: eine Bewegung.
func maus_zu(punkt_raster: Vector2) -> void:
	var ziel := ins_fenster(punkt_raster)
	var bewegung := InputEventMouseMotion.new()
	bewegung.position = ziel
	bewegung.global_position = ziel
	bewegung.relative = ziel - _maus
	bewegung.button_mask = _tasten_maske
	_maus = ziel
	_sende(bewegung)
	await _naechstes_bild()


## Klickt auf [param punkt_raster]: Bewegung dorthin, Drücken, im nächsten Bild Loslassen.
func klick(punkt_raster: Vector2, taste: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await maus_zu(punkt_raster)
	_sende(_maustaste(taste, true))
	await _naechstes_bild()
	_sende(_maustaste(taste, false))
	await _naechstes_bild()


## Dreht das Mausrad über [param punkt_raster] um eine Raste, [param richtung] ist
## MOUSE_BUTTON_WHEEL_UP oder MOUSE_BUTTON_WHEEL_DOWN.
func rad(punkt_raster: Vector2, richtung: MouseButton) -> void:
	await klick(punkt_raster, richtung)


## Drückt [param keycode], mit [param shift] zusammen mit Umschalt; im nächsten Bild loslassen.
func taste(keycode: Key, shift: bool = false) -> void:
	_sende(_taste(keycode, true, false, shift))
	await _naechstes_bild()
	_sende(_taste(keycode, false, false, shift))
	await _naechstes_bild()


## Hält [param keycode] [param ms] Millisekunden echter Zeit; jedes Bild kommt die Taste als
## Wiederholung erneut, wie bei einer gehaltenen echten Taste (R4, R24).
func taste_halten(keycode: Key, ms: int) -> void:
	var ende := Time.get_ticks_msec() + ms
	_sende(_taste(keycode, true, false, false))
	await _naechstes_bild()
	while Time.get_ticks_msec() < ende:
		_sende(_taste(keycode, true, true, false))
		await _naechstes_bild()
	_sende(_taste(keycode, false, false, false))
	await _naechstes_bild()


## [param punkt_raster] aus dem Raster 640 × 360 in Pixeln von [member viewport]; ohne Viewport
## unverändert.
func ins_fenster(punkt_raster: Vector2) -> Vector2:
	if viewport == null:
		return punkt_raster
	return umrechnen(punkt_raster, viewport.get_final_transform())


## [param punkt_raster] mit [param transform], der Vergrößerung von Raster zu Fenster.
static func umrechnen(punkt_raster: Vector2, transform: Transform2D) -> Vector2:
	return transform * punkt_raster


## [param event] so, wie das Spiel es sehen soll: ein eigenes Ereignis als Kopie mit dem Gerät
## echter Tasten oder echter Maus, jedes andere unverändert.
static func fuer_das_spiel(event: InputEvent) -> InputEvent:
	if event.device != DEVICE:
		return event
	var kopie := event.duplicate() as InputEvent
	kopie.device = InputEvent.DEVICE_ID_MOUSE if event is InputEventMouse \
		else InputEvent.DEVICE_ID_KEYBOARD
	return kopie


## Empfang am Fenster: Eigene Ereignisse gehen an das Fenster weiter, echte nicht.
func _empfange(event: InputEvent) -> void:
	if durchlassen(event) and viewport != null:
		viewport.push_input(fuer_das_spiel(event))


func _sende(event: InputEvent) -> void:
	event.device = DEVICE
	if _erste_ms < 0:
		_erste_ms = Time.get_ticks_msec()
	senke.call(event)


func _maustaste(taste: MouseButton, gedrueckt: bool) -> InputEventMouseButton:
	# Die Maske nennt gehaltene Tasten, links 1, rechts 2, Mitte 4; ein Rad hält man nicht.
	var bit := 0 if taste in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN,
		MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT] else 1 << (int(taste) - 1)
	if gedrueckt:
		_tasten_maske |= bit
	else:
		_tasten_maske &= ~bit
	var knopf := InputEventMouseButton.new()
	knopf.button_index = taste
	knopf.pressed = gedrueckt
	knopf.button_mask = _tasten_maske
	knopf.position = _maus
	knopf.global_position = _maus
	knopf.factor = 1.0
	return knopf


static func _taste(keycode: Key, gedrueckt: bool, wiederholung: bool,
		shift: bool) -> InputEventKey:
	var ereignis := InputEventKey.new()
	ereignis.keycode = keycode
	ereignis.physical_keycode = keycode
	ereignis.key_label = keycode
	ereignis.unicode = 32 if keycode == KEY_SPACE else 0
	ereignis.pressed = gedrueckt
	ereignis.echo = wiederholung
	ereignis.shift_pressed = shift
	return ereignis


func _naechstes_bild() -> void:
	await viewport.get_tree().process_frame
