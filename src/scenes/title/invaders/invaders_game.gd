class_name InvadersGame
extends RefCounted

## Eine Partie Space Invaders auf der Anzeige (research.md, R6; data-model.md, „Partie“). Der Kern
## kennt keine Zeit außer seinen Schritten: Jeder Aufruf von step() ist 1/60 s Spielzeit. Er ist
## kein Node, braucht keinen Szenenbaum und läuft deshalb gleich in der Seite und in den Tests,
## wie der Fahrplan der Zeitleiste (TimelineRun). Zufall gibt es nur für die Bomben, aus einem
## eigenen RandomNumberGenerator mit dem Seed der Partie; gleicher Seed und gleiche Eingaben ergeben
## dieselbe Partie.
##
## Der Kern spielt keine Töne und malt nichts. Er meldet, was in einem Schritt geschah, als Liste
## von Ereignissen, und sagt mit drawables(), was zu sehen ist. Die Seite (InvadersPage) macht daraus
## Töne und Bild.
##
## Ablauf eines Schritts in PLAYING, in dieser Reihenfolge:
## 1. Explosionen altern.
## 2. Die Kanone fährt.
## 3. Der Schuss fliegt; ein neuer Druck schießt, wenn keiner im Feld ist; dann der Treffer.
## 4. Die Bomben fallen; dann der Treffer an der Kanone.
## 5. Der Takt des Blocks: rücken, Bewegungsbild, Bombe, Landung.
## Endet die Partie oder wird die Kanone getroffen, endet der Schritt dort.

enum State { PLAYING, RESPAWN, WON, LOST }
enum LostReason { NONE, HIT, LANDED }
enum Event { SHOT, ALIEN_HIT, MARCH, CANNON_HIT, WON, LOST }

# --- Werte aus dem Style-Guide, Spiel auf der Anzeige ---------------------------------------------
# Alle Maße, Lagen, Tempi, Zeiten und Punkte stehen hier und nur hier. Geändert wird erst im
# Style-Guide, dann hier (research.md, R7). Lagen in Bildpixeln, gezählt einschließlich: Die Kanone
# bei x 75 belegt x 75 bis 83.

## Ein Schritt in Sekunden: 1/60.
const STEP := 1.0 / 60.0
## Größe des Felds in Bildpixeln: 160 × 80 (Style-Guide).
const FIELD := Vector2i(160, 80)
## Innenrand links, rechts und unten; nichts liegt außerhalb von x 2 bis 157 und y 0 bis 77.
const INSET := 2
const LEFT_EDGE := INSET                    # 2, erste erlaubte Spalte
const RIGHT_EDGE := FIELD.x - 1 - INSET     # 157, letzte erlaubte Spalte
const BOTTOM_EDGE := FIELD.y - 1 - INSET    # 77, letzte erlaubte Zeile
## Die Kopfzeile belegt y 0 bis 7; das Feld darunter beginnt bei y 8. Ein Schuss, der in die
## Kopfzeile flöge, ist weg.
const FIELD_TOP := 8

## Der Block: 8 Spalten × 4 Reihen, je 8 × 6, Abstand 4 waagrecht und 3 senkrecht, zusammen 92 × 33.
const COLUMNS := 8
const ROWS := 4
const ALIEN_SIZE := Vector2i(8, 6)
const ALIEN_GAP := Vector2i(4, 3)
## Zu Beginn ab y 12, waagrecht mittig ab x 34.
const BLOCK_START := Vector2i(34, 12)
## Muster und Punkte je Reihe, von oben: alien_a 30, zweimal alien_b 20, alien_c 10; zusammen 640.
const ROW_SPRITES: Array[StringName] = [&"alien_a", &"alien_b", &"alien_b", &"alien_c"]
const ROW_POINTS: Array[int] = [30, 20, 20, 10]

## Die Kanone: 9 × 5 in den Zeilen 73 bis 77, zu Beginn und nach einem Treffer bei x 75 bis 83;
## 1 Bildpixel je Schritt, solange ein Pfeil gehalten wird.
const CANNON_SIZE := Vector2i(9, 5)
const CANNON_Y := 73
const CANNON_START_X := 75
const CANNON_SPEED := 1
const LIVES := 3

## Der Schuss: 1 × 4, aus der Spitze der Kanone (ihrer mittleren Spalte), 2 Bildpixel je Schritt
## nach oben; höchstens einer im Feld.
const SHOT_SIZE := Vector2i(1, 4)
const SHOT_SPEED := 2

## Die Bombe: 2 × 3, aus der Mitte der Unterkante eines Außerirdischen, 1 Bildpixel je zwei
## Schritte nach unten; höchstens 3 im Feld.
const BOMB_SIZE := Vector2i(2, 3)
const BOMB_STEPS_PER_PIXEL := 2
const MAX_BOMBS := 3
## Je Takt fällt mit Chance 1/4 eine Bombe.
const BOMB_CHANCE := 0.25

## Der Takt des Blocks: 2 Bildpixel zur Seite, am Rand 3 tiefer und Richtungswechsel.
const MARCH_STEP_X := 2
const MARCH_STEP_Y := 3
## Abstand der Takte in Schritten bei n Übrigen: 3 + round(27 · (n − 1) / 31), also 30 bei 32 und 3
## bei einem.
const MARCH_INTERVAL_MIN := 3
const MARCH_INTERVAL_RANGE := 27
## Vier Marschtöne im Kreis.
const MARCH_NOTES := 4

## Explosion: 8 × 6, 15 Schritte (0,25 s); hält nichts auf.
const EXPLOSION_SIZE := Vector2i(8, 6)
const EXPLOSION_STEPS := 15
## Pause nach einem Treffer an der Kanone: 60 Schritte (1 s).
const RESPAWN_STEPS := 60

# --- Zustand --------------------------------------------------------------------------------------

## Wo die Partie steht. Nur lesen.
var state: State = State.PLAYING
## Warum sie verloren ging; NONE, solange sie nicht verloren ist.
var lost_reason: LostReason = LostReason.NONE
## Punkte, 0 bis 640. Nur lesen.
var score: int = 0
## Verbleibende Leben, die Kanone im Feld eingeschlossen: 3 zu Beginn. Nur lesen.
var lives: int = LIVES
## Linke Kante der Kanone in Bildpixeln.
var cannon_x: int = CANNON_START_X
## Bewegungsbild des Blocks, 0 oder 1; wechselt mit jedem Takt.
var march_frame: int = 0

## Je Platz im Block, ob der Außerirdische lebt; Index Reihe · COLUMNS + Spalte, Reihe 0 oben.
var _alive: Array[bool] = []
## Linke obere Ecke des Blocks, Platz Reihe 0, Spalte 0, auch wenn dieser nicht mehr lebt.
var _block_origin: Vector2i = BLOCK_START
## +1 nach rechts, −1 nach links.
var _block_dir: int = 1
## Schritte bis zum nächsten Takt.
var _march_timer: int = 0
## Welcher der vier Marschtöne als Nächstes kommt, 0 bis 3.
var _march_note: int = 0
## Ob ein Schuss im Feld ist, und seine linke obere Ecke.
var _has_shot: bool = false
var _shot_pos: Vector2i = Vector2i.ZERO
## Bomben im Feld, je { "pos": Vector2i, "age": int }; age zählt die Schritte seit dem Abwurf.
var _bombs: Array[Dictionary] = []
## Explosionen an getroffenen Außerirdischen, je { "pos": Vector2i, "left": int }.
var _explosions: Array[Dictionary] = []
## Schritte, bis die Kanone nach einem Treffer zurückkommt.
var _respawn_left: int = 0
## Zufall für die Bomben, mit dem Seed der Partie.
var _rng := RandomNumberGenerator.new()


# Der Name kommt aus dem Vertrag und ist zugleich der einer globalen Funktion, seed(); die Warnung
# darüber ist abgeschaltet, sonst wäre der Start mit -d nicht still.
## Neue Partie mit [param seed] für die Bomben.
@warning_ignore("shadowed_global_identifier")
func _init(seed: int) -> void:
	_rng.seed = seed
	_alive.resize(COLUMNS * ROWS)
	_alive.fill(true)
	_march_timer = _march_interval()


## Ein Schritt. [param left], [param right]: gehalten; [param fire]: neuer Druck in diesem Schritt.
## Gibt die Ereignisse dieses Schritts zurück, je als { "event": Event, ... } (MARCH mit "note" 0–3,
## ALIEN_HIT mit "row" und "points"). In WON und LOST ändert sich nichts mehr, die Liste ist leer.
func step(left: bool, right: bool, fire: bool) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if state == State.WON or state == State.LOST:
		return events
	_age_explosions()
	if state == State.RESPAWN:
		# Der Block steht, es fällt nichts, die Kanone ist weg; nur die Zeit läuft.
		_respawn_left -= 1
		if _respawn_left <= 0:
			cannon_x = CANNON_START_X
			state = State.PLAYING
		return events

	_move_cannon(left, right)
	_update_shot(fire, events)
	if state == State.WON:
		return events
	_update_bombs(events)
	if state != State.PLAYING:
		return events
	_march_timer -= 1
	if _march_timer <= 0:
		_march(events)
	return events


## Alles, was zu malen ist, je als { "sprite": StringName, "frame": int, "pos": Vector2i } mit pos
## als linker oberer Ecke in Bildpixeln: Außerirdische, Kanone (nicht in RESPAWN; dort und nach dem
## letzten Treffer die Explosion an ihrer Stelle), Schuss, Bomben, Explosionen. Die Kopfzeile malt
## die Seite selbst aus score und lives.
func drawables() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in ROWS:
		for column in COLUMNS:
			if _alive[row * COLUMNS + column]:
				result.append({
					"sprite": ROW_SPRITES[row],
					"frame": march_frame,
					"pos": _alien_pos(row, column),
				})
	if _cannon_exploded():
		result.append({ "sprite": &"explosion", "frame": 0, "pos": _cannon_explosion_pos() })
	else:
		result.append({ "sprite": &"cannon", "frame": 0, "pos": Vector2i(cannon_x, CANNON_Y) })
	if _has_shot:
		result.append({ "sprite": &"shot", "frame": 0, "pos": _shot_pos })
	for bomb in _bombs:
		result.append({ "sprite": &"bomb", "frame": 0, "pos": bomb["pos"] })
	for explosion in _explosions:
		result.append({ "sprite": &"explosion", "frame": 0, "pos": explosion["pos"] })
	return result


## Wie viele Außerirdische übrig sind.
func aliens_left() -> int:
	return _alive.count(true)


# --- Schritte -------------------------------------------------------------------------------------

func _age_explosions() -> void:
	for i in range(_explosions.size() - 1, -1, -1):
		_explosions[i]["left"] -= 1
		if _explosions[i]["left"] <= 0:
			_explosions.remove_at(i)


## Links und rechts zugleich heben sich auf. Die Kanone bleibt im Innenrand.
func _move_cannon(left: bool, right: bool) -> void:
	var direction := int(right) - int(left)
	cannon_x = clampi(cannon_x + direction * CANNON_SPEED, LEFT_EDGE,
			RIGHT_EDGE - CANNON_SIZE.x + 1)


## Erst fliegt ein Schuss, der schon im Feld ist; dann darf ein neuer Druck schießen, wenn keiner
## mehr da ist. Der neue Schuss steht direkt über der Spitze und fliegt ab dem nächsten Schritt.
## Zuletzt der Treffer, für den alten wie den neuen Schuss.
func _update_shot(fire: bool, events: Array[Dictionary]) -> void:
	if _has_shot:
		_shot_pos.y -= SHOT_SPEED
		if _shot_pos.y < FIELD_TOP:
			_has_shot = false
	if fire and not _has_shot:
		_has_shot = true
		_shot_pos = Vector2i(cannon_x + floori(CANNON_SIZE.x / 2.0), CANNON_Y - SHOT_SIZE.y)
		events.append({ "event": Event.SHOT })
	if _has_shot:
		_hit_alien(events)


## Ein Schuss trifft höchstens einen: Überschneiden sich mehrere, zählt der unterste, denn auf ihn
## trifft der Schuss von unten zuerst.
func _hit_alien(events: Array[Dictionary]) -> void:
	var shot_rect := Rect2i(_shot_pos, SHOT_SIZE)
	for row in range(ROWS - 1, -1, -1):
		for column in COLUMNS:
			var index := row * COLUMNS + column
			if not _alive[index]:
				continue
			var pos := _alien_pos(row, column)
			if not shot_rect.intersects(Rect2i(pos, ALIEN_SIZE)):
				continue
			_alive[index] = false
			_has_shot = false
			score += ROW_POINTS[row]
			_explosions.append({ "pos": pos, "left": EXPLOSION_STEPS })
			events.append({ "event": Event.ALIEN_HIT, "row": row, "points": ROW_POINTS[row] })
			if aliens_left() == 0:
				state = State.WON
				events.append({ "event": Event.WON })
				return
			# Weniger Übrige, kürzerer Abstand: gilt schon für den laufenden Takt.
			_march_timer = mini(_march_timer, _march_interval())
			return


## Bomben fallen 1 Bildpixel je zwei Schritte, den ersten im zweiten Schritt nach dem Abwurf. Eine
## Bombe, deren Rechteck das der Kanone überschneidet, trifft. Eine, die unten aus dem Innenrand
## fiele, ist weg. Den Schuss beachten sie nicht.
func _update_bombs(events: Array[Dictionary]) -> void:
	var cannon_rect := Rect2i(Vector2i(cannon_x, CANNON_Y), CANNON_SIZE)
	for i in range(_bombs.size() - 1, -1, -1):
		var bomb: Dictionary = _bombs[i]
		bomb["age"] += 1
		if bomb["age"] % BOMB_STEPS_PER_PIXEL == 0:
			bomb["pos"].y += 1
		if bomb["pos"].y + BOMB_SIZE.y - 1 > BOTTOM_EDGE:
			_bombs.remove_at(i)
	for bomb in _bombs:
		if cannon_rect.intersects(Rect2i(bomb["pos"], BOMB_SIZE)):
			_hit_cannon(events)
			return


## Ein Leben weniger. Mit Leben übrig 1 s Pause: alle Bomben und der Schuss weg, der Block steht,
## an der Kanone die Explosion. Ohne Leben ist die Partie verloren.
func _hit_cannon(events: Array[Dictionary]) -> void:
	lives -= 1
	_bombs.clear()
	_has_shot = false
	events.append({ "event": Event.CANNON_HIT })
	if lives <= 0:
		state = State.LOST
		lost_reason = LostReason.HIT
		events.append({ "event": Event.LOST })
		return
	state = State.RESPAWN
	_respawn_left = RESPAWN_STEPS


## Ein Takt. Steht die Außenkante der lebenden Außerirdischen in Fahrtrichtung schon am Innenrand,
## rückt der Block 3 tiefer und kehrt um; sonst 2 zur Seite. Danach Bewegungsbild, Marschton,
## vielleicht eine Bombe und die Prüfung, ob er gelandet ist.
func _march(events: Array[Dictionary]) -> void:
	var at_edge := false
	if _block_dir > 0:
		at_edge = _living_right_edge() >= RIGHT_EDGE
	else:
		at_edge = _living_left_edge() <= LEFT_EDGE
	if at_edge:
		_block_origin.y += MARCH_STEP_Y
		_block_dir = -_block_dir
	else:
		_block_origin.x += _block_dir * MARCH_STEP_X
	march_frame = 1 - march_frame
	events.append({ "event": Event.MARCH, "note": _march_note })
	_march_note = (_march_note + 1) % MARCH_NOTES
	_march_timer = _march_interval()
	_maybe_drop_bomb()
	if _living_bottom_row() >= CANNON_Y:
		state = State.LOST
		lost_reason = LostReason.LANDED
		events.append({ "event": Event.LOST })


## Mit Chance 1/4 wirft der unterste lebende Außerirdische einer zufälligen Spalte eine Bombe, wenn
## weniger als 3 im Feld sind. Gewürfelt wird in jedem Takt, damit die Folge der Würfe nicht von den
## Bomben im Feld abhängt.
func _maybe_drop_bomb() -> void:
	var drops := _rng.randf() < BOMB_CHANCE
	if not drops or _bombs.size() >= MAX_BOMBS:
		return
	var bottoms: Array[Vector2i] = []
	for column in COLUMNS:
		for row in range(ROWS - 1, -1, -1):
			if _alive[row * COLUMNS + column]:
				bottoms.append(_alien_pos(row, column))
				break
	if bottoms.is_empty():
		return
	var alien: Vector2i = bottoms[_rng.randi_range(0, bottoms.size() - 1)]
	var pos := Vector2i(alien.x + floori((ALIEN_SIZE.x - BOMB_SIZE.x) / 2.0),
			alien.y + ALIEN_SIZE.y)
	_bombs.append({ "pos": pos, "age": 0 })


# --- Hilfen ---------------------------------------------------------------------------------------

## Abstand der Takte in Schritten bei den jetzt Übrigen: 3 + round(27 · (n − 1) / 31).
func _march_interval() -> int:
	var n := maxi(aliens_left(), 1)
	return MARCH_INTERVAL_MIN + roundi(
			float(MARCH_INTERVAL_RANGE * (n - 1)) / float(COLUMNS * ROWS - 1))


func _alien_pos(row: int, column: int) -> Vector2i:
	return _block_origin + Vector2i(column * (ALIEN_SIZE.x + ALIEN_GAP.x),
			row * (ALIEN_SIZE.y + ALIEN_GAP.y))


## Linke Spalte des am weitesten links lebenden Außerirdischen.
func _living_left_edge() -> int:
	for column in COLUMNS:
		for row in ROWS:
			if _alive[row * COLUMNS + column]:
				return _alien_pos(row, column).x
	return _block_origin.x


## Rechte Spalte des am weitesten rechts lebenden Außerirdischen, einschließlich.
func _living_right_edge() -> int:
	for column in range(COLUMNS - 1, -1, -1):
		for row in ROWS:
			if _alive[row * COLUMNS + column]:
				return _alien_pos(row, column).x + ALIEN_SIZE.x - 1
	return _block_origin.x


## Unterste Zeile des am tiefsten lebenden Außerirdischen, einschließlich; −1 ohne Lebende.
func _living_bottom_row() -> int:
	for row in range(ROWS - 1, -1, -1):
		for column in COLUMNS:
			if _alive[row * COLUMNS + column]:
				return _alien_pos(row, column).y + ALIEN_SIZE.y - 1
	return -1


func _cannon_exploded() -> bool:
	return state == State.RESPAWN or (state == State.LOST and lost_reason == LostReason.HIT)


## Die Explosion an der Kanone liegt mittig über ihr: waagrecht ab ihrer linken Kante (9 breit gegen
## 8, der halbe Pixel fällt nach links), senkrecht mit der Unterkante auf der Zeile 77, damit sie
## nicht aus dem Innenrand ragt.
func _cannon_explosion_pos() -> Vector2i:
	return Vector2i(cannon_x + floori((CANNON_SIZE.x - EXPLOSION_SIZE.x) / 2.0),
			CANNON_Y + CANNON_SIZE.y - EXPLOSION_SIZE.y)
