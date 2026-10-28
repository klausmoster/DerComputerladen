extends Control

## Probeszene für den Baustein Communicator (Feature 005, T008): ein Communicator in der Endlage des
## Titels, darauf ein Menü aus drei Einträgen, auf nacht. Ohne Titelbildschirm und ohne TitleTexts,
## so zeigt sie, dass ein anderer Bildschirm den Communicator mit eigenen Seiten benutzen kann
## (SC-005). Das Menü steht auf der Anzeige (look = LCD in der Szene, seit T014).
##
## Allein startbar für Bildschirmfotos und zum Ausprobieren: Beim Start fährt der Communicator
## herein. „Hinaus und herein“ lässt ihn hinausfahren und gleich wieder herein; so sind beide
## Fahrten und die gesperrte Eingabe zu sehen. Der Hinweis bleibt dabei stehen und fährt mit dem
## Gerät, wie im Titel. Die anderen zwei Einträge zeigen eine Meldung.
##
## Gehäusetasten (Feature 006, T026): Die Probe gibt dem Gehäuse die drei grauen Tasten von G-03 mit
## den Rechtecken aus dem Style-Guide (in der Szene, case_keys). Ein gezählter Druck zeigt eine
## Meldung an der Stelle des Hinweises, welche Taste es war.
##
## Wie ein echter Bildschirm hört die Probe selbst auf das Menü und reicht den Hinweis über den
## Communicator weiter; der Communicator kennt die Signale des Menüs nicht.

## Die gewählte Zeile, wie selection_changed sie zuletzt gemeldet hat, relativ zum Communicator; die
## Meldung steht daneben. Relativ, weil die erste Auswahl kommt, während er noch draußen steht:
## Global gemerkt läge eine spätere Meldung dann unter dem Bild. _current_row() rechnet sie in die
## jetzige Lage um.
var _row_on_communicator := Rect2()

@onready var _background: ColorRect = $Background
@onready var _communicator: Communicator = $Communicator
@onready var _menu: MainMenu = $Communicator/MainMenu


func _ready() -> void:
	# Die Farbe kommt aus UiPalette und nicht als Zahl aus der Szene.
	_background.color = UiPalette.NACHT
	_menu.selection_changed.connect(_on_selection_changed)
	_menu.entry_activated.connect(_on_entry_activated)
	_communicator.slide_finished.connect(_on_slide_finished)
	_communicator.case_key_pressed.connect(_on_case_key_pressed)
	# Erst draußen hinstellen, dann Einträge und Auswahl, dann die Fahrt (Analyse, C5).
	_communicator.place_hidden()
	_menu.set_entries(_entries(), 0)
	_communicator.show_page(_menu)
	_menu.select(_menu.selected_index())
	_communicator.slide_in()


## Die drei Einträge der Probe, alle verfügbar.
func _entries() -> Array[MenuEntry]:
	return [
		_entry(&"eins", "Erster Eintrag", "Zeigt eine Meldung an der Stelle dieses Hinweises."),
		_entry(&"zwei", "Zweiter Eintrag", "Zeigt ebenfalls eine Meldung."),
		_entry(&"fahrt", "Hinaus und herein", "Der Communicator fährt hinaus und wieder herein."),
	]


func _entry(id: StringName, label: String, hint: String) -> MenuEntry:
	var entry := MenuEntry.new()
	entry.id = id
	entry.label = label
	entry.available = true
	entry.hint = hint
	return entry


func _on_selection_changed(entry: MenuEntry, row_rect: Rect2) -> void:
	_row_on_communicator = Rect2(row_rect.position - _communicator.global_position, row_rect.size)
	_communicator.show_hint(entry.hint, row_rect)


func _on_entry_activated(id: StringName) -> void:
	if id == &"fahrt":
		_communicator.slide_out()
		return
	_communicator.show_warning("Ausgelöst: %s." % _menu.selected_entry().label, _current_row())


## Eine Gehäusetaste zählt: Die Meldung nennt sie, von links gezählt ab 1.
func _on_case_key_pressed(index: int) -> void:
	_communicator.show_warning("Gehäusetaste %d gedrückt." % (index + 1), _current_row())


## Die gewählte Zeile in globalen Koordinaten, da, wo der Communicator jetzt steht.
func _current_row() -> Rect2:
	return Rect2(_communicator.global_position + _row_on_communicator.position,
		_row_on_communicator.size)


## Draußen angekommen, fährt der Communicator gleich wieder herein. Danach wählt die Probe die Zeile
## neu, denn während der Fahrt hinaus hatte keine Seite den Fokus.
func _on_slide_finished(arrived_in: bool) -> void:
	if arrived_in:
		return
	_communicator.slide_in()
	_menu.select(_menu.selected_index())
