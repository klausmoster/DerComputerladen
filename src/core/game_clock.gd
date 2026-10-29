extends Node

## Autoload-Singleton: die Spieluhr.
##
## Hält das aktuelle In-Game-Datum (1985-01-01 bis 1999-12-31) und treibt die
## Zeit voran – entweder automatisch (Play) oder schrittweise per Aufruf.
## Andere Systeme hängen sich an die Signale, statt selbst die Zeit zu messen.
##
## Die Uhr läuft, ist angehalten oder steht am Ende (State, AR-11). paused bleibt als Eigenschaft
## lesbar und setzbar, wie bisher; am Ende ändert Setzen nichts, erst set_date() im Spielzeitraum
## holt die Uhr dort heraus. In _process() sammelt sie die Zeit und rechnet daraus ganze Tage,
## höchstens MAX_DAYS_PER_FRAME je Bild (AR-10).

signal day_passed(date: GameDate)
signal month_passed(date: GameDate)
signal year_passed(date: GameDate)
signal reached_end()

const START_YEAR := 1985
const START_MONTH := 1
const START_DAY := 1
const END_YEAR := 1999
## Höchstens so viele Tage rechnet _process() in einem Bild, wie InvadersPage.MAX_STEPS (AR-10).
## Was darüber hinausgeht, verfällt: Nach einem Hänger springt die Uhr nicht viele Tage auf einmal.
const MAX_DAYS_PER_FRAME := 4

## Wo die Uhr steht: Sie läuft, ist angehalten oder hat das Spielende überschritten.
enum State { RUNNING, PAUSED, ENDED }

## Tage pro Echtzeit-Sekunde, wenn die Uhr läuft.
var days_per_second: float = 2.0
## Ob die Uhr steht, angehalten oder am Ende. Setzen hält an oder lässt laufen; am Ende bleibt sie
## stehen, auch mit paused = false.
var paused: bool:
	get:
		return _state != State.RUNNING
	set(value):
		if _state != State.ENDED:
			_state = State.PAUSED if value else State.RUNNING

var date: GameDate
var _day_index: int = 0
var _accumulator: float = 0.0
var _state: State = State.PAUSED


func _ready() -> void:
	date = GameDate.new(START_YEAR, START_MONTH, START_DAY)
	_day_index = date.to_day_index()


## Sammelt die Zeit und rechnet ganze Tage, höchstens MAX_DAYS_PER_FRAME; ein angefangener Tag
## bleibt für das nächste Bild.
func _process(delta: float) -> void:
	if _state != State.RUNNING:
		return
	_accumulator += delta * days_per_second
	var days := 0
	while _accumulator >= 1.0:
		if days == MAX_DAYS_PER_FRAME:
			_accumulator = 0.0
			break
		_accumulator -= 1.0
		advance_day()
		days += 1
		if _state == State.ENDED:
			break


## Einen Tag weiter und alle passenden Signale feuern.
func advance_day() -> void:
	if _state == State.ENDED:
		return
	var previous := date
	_day_index += 1
	date = GameDate.from_day_index(_day_index)

	day_passed.emit(date)
	if date.month != previous.month:
		month_passed.emit(date)
	if date.year != previous.year:
		year_passed.emit(date)

	if date.year > END_YEAR:
		_state = State.ENDED
		reached_end.emit()


## Bis zum Ersten des nächsten Monats springen.
func advance_one_month() -> void:
	var current_month := date.month
	while _state != State.ENDED and date.month == current_month:
		advance_day()


## Bis zum 1. Januar des Folgejahres springen.
func advance_one_year() -> void:
	var current_year := date.year
	while _state != State.ENDED and date.year == current_year:
		advance_day()


## Setzt die Uhr auf [param new_date], ohne Signale. paused bleibt, wie es ist; liegt das Datum im
## Spielzeitraum, ist die Uhr danach nicht am Ende, sondern angehalten, wenn sie am Ende stand. Für
## Anlegen, Fortsetzen und Verlassen (Feature 004, research.md, R6).
##
## Ohne Signale, weil die Tage dazwischen nicht im Spiel vergehen: Beim Fortsetzen am 14.03.1986
## hat die Zeitleiste sie schon still nachgespielt, und day_passed für jeden davon meldete alles
## noch einmal. Der angefangene Tag aus _process() verfällt, so kommt der erste Tageswechsel nach
## dem Setzen nicht schon im nächsten Bild.
func set_date(new_date: GameDate) -> void:
	# Eine eigene Kopie: Ändert der Aufrufer sein GameDate später, bleibt die Uhr, wo sie ist.
	date = GameDate.new(new_date.year, new_date.month, new_date.day)
	_day_index = date.to_day_index()
	_accumulator = 0.0
	# Dieselbe Grenze wie in advance_day(): Erst ein Datum nach 1999 ist das Ende.
	if date.year > END_YEAR:
		_state = State.ENDED
	elif _state == State.ENDED:
		_state = State.PAUSED


func set_paused(value: bool) -> void:
	paused = value


func toggle_paused() -> void:
	paused = not paused


func is_finished() -> bool:
	return _state == State.ENDED
