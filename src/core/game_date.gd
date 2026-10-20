class_name GameDate
extends RefCounted

## Leichtgewichtiger Kalender-Wert für die Simulation (1985 als Epoche).
## Rechnet intern über einen absoluten Tagesindex, damit Vergleiche und
## Zeitsprünge trivial sind. Schaltjahre werden korrekt behandelt.
##
## Der Index zählt auch vor 1985, dann negativ: Der 31.12.1984 ist −1, der
## 01.12.1984 −31. Das brauchen jährliche Ereignisse, die schon vor Spielbeginn
## laufen, etwa der Winter 1984/85 (Feature 002, research.md R9).

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


## Ob Jahr, Monat und Tag ein Kalendertag sind. Der 29.02.1988 ist einer, der
## 29.02.1989 und der 30.02. nie.
static func is_valid(y: int, m: int, d: int) -> bool:
	return m >= 1 and m <= 12 and d >= 1 and d <= days_in_month(y, m)


## "1993-03-22" → GameDate; null, wenn der Text kein gültiges Datum ist.
##
## Verlangt genau die Form JJJJ-MM-TT mit führenden Nullen, wie sie im
## Ereigniskatalog steht. "1993-3-22" ist deshalb kein Datum: Sonst stünde nach
## dem nächsten Speichern still "1993-03-22" in der Datei.
static func from_iso(text: String) -> GameDate:
	if text.length() != 10:
		return null
	for i in text.length():
		if i == 4 or i == 7:
			if text[i] != "-":
				return null
		# Ein einzelnes Zeichen ist nur dann eine gültige Zahl, wenn es eine Ziffer
		# ist; „+“ und „-“ allein sind es nicht.
		elif not text[i].is_valid_int():
			return null
	var y := text.substr(0, 4).to_int()
	var m := text.substr(5, 2).to_int()
	var d := text.substr(8, 2).to_int()
	if not is_valid(y, m, d):
		return null
	return GameDate.new(y, m, d)


## GameDate → "1993-03-22".
func to_iso() -> String:
	return "%04d-%02d-%02d" % [year, month, day]


## Tage seit 1985-01-01 (= Index 0), vor 1985 negativ.
func to_day_index() -> int:
	var idx := 0
	# Höchstens eine der beiden Schleifen läuft: Ab 1985 kommen die vollen Jahre
	# seit 1985 dazu, vor 1985 gehen die Jahre bis 1985 ab.
	for y in range(EPOCH_YEAR, year):
		idx += _days_in_year(y)
	for y in range(year, EPOCH_YEAR):
		idx -= _days_in_year(y)
	for m in range(1, month):
		idx += days_in_month(year, m)
	return idx + day - 1


static func from_day_index(index: int) -> GameDate:
	var y := EPOCH_YEAR
	var remaining := index
	# Vor 1985 so viele Jahre zurückgehen, bis der Rest nicht mehr negativ ist.
	while remaining < 0:
		y -= 1
		remaining += _days_in_year(y)
	while remaining >= _days_in_year(y):
		remaining -= _days_in_year(y)
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


static func _days_in_year(y: int) -> int:
	return 366 if is_leap_year(y) else 365
