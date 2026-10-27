extends Control

## Probeszene für das Spiel auf der Anzeige (Feature 006, T019): ein Communicator in der Endlage des
## Titels auf nacht, darauf die Seite InvadersPage, die gleich eine Partie beginnt. Nach finished,
## ob durch Esc oder aus der Ergebnisanzeige, beginnt die nächste. Ohne Titelbildschirm, ohne
## TitleTexts-Menü und ohne GameSession: Die Probe zeigt, dass die Seite allein spielbar ist
## (Spec, Story 2).
##
## Allein startbar zum Spielen und für Bildschirmfotos. Wie ein echter Bildschirm zeigt die Probe
## die Seite erst mit show_page() und ruft danach start() (Analyse, C1).

@onready var _background: ColorRect = $Background
@onready var _communicator: Communicator = $Communicator
@onready var _page: InvadersPage = $Communicator/InvadersPage


func _ready() -> void:
	# Die Farbe kommt aus UiPalette und nicht als Zahl aus der Szene.
	_background.color = UiPalette.NACHT
	_page.finished.connect(_on_finished)
	_communicator.show_page(_page)
	_page.start()


## Die Probe kennt keinen Titel, zu dem sie zurückkehrt: Es geht mit einer neuen Partie weiter.
func _on_finished() -> void:
	_page.start()
