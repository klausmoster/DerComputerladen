class_name TimelineEvent
extends Resource

## Definition eines Ereignisses auf der Zeitleiste.
##
## Fixe Ereignisse (is_fixed = true) feuern an einem festen Datum (year/month/day)
## und bilden die reale Hardware-/Software-/Wirtschaftsgeschichte ab.
## Variable Ereignisse (is_fixed = false) werden monatlich gewürfelt und hängen
## von Wahrscheinlichkeit, Zeitfenster, Häufigkeit und Cooldown ab.

enum Category {
	HARDWARE,    ## CPU/RAM/Grafik/… Release
	SOFTWARE,    ## Betriebssystem/Programm Release
	TECH,        ## Technologie-Meilenstein (CD-ROM, USB, Internet)
	WIRTSCHAFT,  ## Konjunktur, gesellschaftliche Rahmenbedingungen
	LOKAL,       ## Standortbezogen (Neubaugebiet …)
	KONKURRENZ,  ## Mitbewerber eröffnet/schließt
	KUNDE,       ## Großkunde, Auftrag
	REKLAMATION, ## Reklamationswelle
	LIEFERUNG,   ## Lieferengpass
}

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var category: Category = Category.HARDWARE
@export var is_fixed: bool = true

@export_group("Fixes Datum")
@export var year: int = 1985
@export var month: int = 1
@export var day: int = 1

@export_group("Variabel")
## Wahrscheinlichkeit pro Monat (0..1).
@export_range(0.0, 1.0, 0.01) var monthly_chance: float = 0.0
@export var earliest_year: int = 1985
@export var latest_year: int = 1999
## 0 = unbegrenzt.
@export var max_occurrences: int = 0
## Mindestabstand in Tagen zwischen zwei Auslösungen.
@export var cooldown_days: int = 0

@export_group("Wirkung")
@export var effects: Array[EventEffect] = []


func trigger_day_index() -> int:
	return GameDate.new(year, month, day).to_day_index()


## Darf das variable Ereignis im aktuellen Monat überhaupt gewürfelt werden?
func can_occur(date: GameDate, occurrences: int, last_fired_day: int, current_day: int) -> bool:
	if date.year < earliest_year or date.year > latest_year:
		return false
	if max_occurrences > 0 and occurrences >= max_occurrences:
		return false
	if cooldown_days > 0 and last_fired_day >= 0 and current_day - last_fired_day < cooldown_days:
		return false
	return true


func category_label() -> String:
	return Category.keys()[category].capitalize()
