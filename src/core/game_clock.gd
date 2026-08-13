extends Node

## Autoload-Singleton: die Spieluhr.
##
## Hält das aktuelle In-Game-Datum (1985-01-01 bis 1999-12-31) und treibt die
## Zeit voran – entweder automatisch (Play) oder schrittweise per Aufruf.
## Andere Systeme hängen sich an die Signale, statt selbst die Zeit zu messen.

signal day_passed(date: GameDate)
signal month_passed(date: GameDate)
signal year_passed(date: GameDate)
signal season_changed(is_holiday_season: bool)
signal reached_end()

const START_YEAR := 1985
const START_MONTH := 1
const START_DAY := 1
const END_YEAR := 1999

## Tage pro Echtzeit-Sekunde, wenn die Uhr läuft.
var days_per_second: float = 2.0
var paused: bool = true

var date: GameDate
var _day_index: int = 0
var _accumulator: float = 0.0
var _ended: bool = false


func _ready() -> void:
	date = GameDate.new(START_YEAR, START_MONTH, START_DAY)
	_day_index = date.to_day_index()


func _process(delta: float) -> void:
	if paused or _ended:
		return
	_accumulator += delta * days_per_second
	while _accumulator >= 1.0:
		_accumulator -= 1.0
		advance_day()
		if _ended:
			break


## Einen Tag weiter und alle passenden Signale feuern.
func advance_day() -> void:
	if _ended:
		return
	var previous := date
	_day_index += 1
	date = GameDate.from_day_index(_day_index)

	day_passed.emit(date)
	if date.month != previous.month:
		month_passed.emit(date)
	if date.year != previous.year:
		year_passed.emit(date)
	if date.is_holiday_season() != previous.is_holiday_season():
		season_changed.emit(date.is_holiday_season())

	if date.year > END_YEAR:
		_ended = true
		paused = true
		reached_end.emit()


## Bis zum Ersten des nächsten Monats springen.
func advance_one_month() -> void:
	var current_month := date.month
	while not _ended and date.month == current_month:
		advance_day()


## Bis zum 1. Januar des Folgejahres springen.
func advance_one_year() -> void:
	var current_year := date.year
	while not _ended and date.year == current_year:
		advance_day()


func set_paused(value: bool) -> void:
	paused = value


func toggle_paused() -> void:
	paused = not paused


func is_finished() -> bool:
	return _ended
