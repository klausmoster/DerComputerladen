extends Control

## Probeszene für den Baustein Communicator (Feature 005, T008): ein Communicator in der Endlage des
## Titels, darauf ein Menü aus drei Einträgen, auf nacht. Ohne Titelbildschirm und ohne TitleTexts,
## so zeigt sie, dass ein anderer Bildschirm den Communicator mit eigenen Seiten benutzen kann
## (SC-005). Bis Phase 3 steht das Menü auf Papier; T014 stellt es auf die Anzeige um.
##
## Allein startbar für Bildschirmfotos und zum Ausprobieren: Beim Start fährt der Communicator
## herein. „Hinaus und herein“ lässt ihn hinausfahren und gleich wieder herein; so sind beide
## Fahrten und die gesperrte Eingabe zu sehen. Der Hinweis bleibt dabei stehen und fährt mit dem
## Gerät, wie im Titel. Die anderen zwei Einträge zeigen eine Meldung.
##
## Wie ein echter Bildschirm hört die Probe selbst auf das Menü und reicht den Hinweis über den
## Communicator weiter; der Communicator kennt die Signale des Menüs nicht.

## Die gewählte Zeile, wie selection_changed sie zuletzt gemeldet hat; die Meldung steht daneben.
var _selected_row := Rect2()

@onready var _background: ColorRect = $Background
@onready var _communicator: Communicator = $Communicator
@onready var _menu: MainMenu = $Communicator/MainMenu


func _ready() -> void:
	# Die Farbe kommt aus UiPalette und nicht als Zahl aus der Szene.
	_background.color = UiPalette.NACHT
	_menu.selection_changed.connect(_on_selection_changed)
	_menu.entry_activated.connect(_on_entry_activated)
	_communicator.slide_finished.connect(_on_slide_finished)
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
	_selected_row = row_rect
	_communicator.show_hint(entry.hint, row_rect)


func _on_entry_activated(id: StringName) -> void:
	if id == &"fahrt":
		_communicator.slide_out()
		return
	_communicator.show_warning("Ausgelöst: %s." % _menu.selected_entry().label, _selected_row)


## Draußen angekommen, fährt der Communicator gleich wieder herein. Danach wählt die Probe die Zeile
## neu, denn während der Fahrt hinaus hatte keine Seite den Fokus.
func _on_slide_finished(arrived_in: bool) -> void:
	if arrived_in:
		return
	_communicator.slide_in()
	_menu.select(_menu.selected_index())
