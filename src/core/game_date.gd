class_name GameDate
extends RefCounted

## Leichtgewichtiger Kalender-Wert für die Simulation (1985 als Epoche).
## Rechnet intern über einen absoluten Tagesindex, damit Vergleiche und
## Zeitsprünge trivial sind. Schaltjahre werden korrekt behandelt.

const EPOCH_YEAR := 1985

const MONTH_NAMES_DE := [
	"", "Januar", "Februar", "März", "April", "Mai", "Juni",
	"Juli", "August", "September", "Oktober", "November", "Dezember",
]

var year: int
var month: int
var day: int


func _init(p_year: int = EPOCH_YEAR, p_month: int = 1, p_day: int = 1) -> void:
	year = p_year
	month = p_month
	day = p_day


static func is_leap_year(y: int) -> bool:
	return (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)


static func days_in_month(y: int, m: int) -> int:
	match m:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			return 29 if is_leap_year(y) else 28
	return 30


## Tage seit 1985-01-01 (= Index 0).
func to_day_index() -> int:
	var idx := 0
	for y in range(EPOCH_YEAR, year):
		idx += 366 if is_leap_year(y) else 365
	for m in range(1, month):
		idx += days_in_month(year, m)
	return idx + day - 1


static func from_day_index(index: int) -> GameDate:
	var y := EPOCH_YEAR
	var remaining := index
	while true:
		var year_len := 366 if is_leap_year(y) else 365
		if remaining < year_len:
			break
		remaining -= year_len
		y += 1
	var m := 1
	while remaining >= days_in_month(y, m):
		remaining -= days_in_month(y, m)
		m += 1
	return GameDate.new(y, m, remaining + 1)


## Weihnachtsgeschäft (November/Dezember) – Hauptumsatzzeit.
func is_holiday_season() -> bool:
	return month == 11 or month == 12


func season() -> String:
	match month:
		12, 1, 2:
			return "Winter"
		3, 4, 5:
			return "Frühling"
		6, 7, 8:
			return "Sommer"
		_:
			return "Herbst"


func _to_string() -> String:
	return "%02d.%02d.%d" % [day, month, year]


## Lesbares Label, z.B. "März 1993".
func to_label() -> String:
	return "%s %d" % [MONTH_NAMES_DE[month], year]
