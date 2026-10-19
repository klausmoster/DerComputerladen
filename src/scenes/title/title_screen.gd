class_name TitleScreen
extends Control

## Der Titelbildschirm: Titelbild T-01, Logo mit Untertitel, Hauptmenü und Versionszeile,
## angeordnet nach dem Titelscreen-Entwurf (FR-005).
##
## Er setzt die Teile nur zusammen und verbindet sie. Das Menü meldet die gewählte Zeile
## per Signal, der Titelbildschirm reicht sie an den Hinweis weiter. Menü und Hinweis
## kennen einander nicht.

## Kennzeichen in der Versionszeile, solange das Spiel ein Prototyp ist.
const STAGE := "PROTOTYP"

@onready var _menu_hint: MenuHint = $MenuHint
@onready var _version_line: Label = $VersionLine


func _ready() -> void:
	# Die Nummer steht in project.godot und nicht in der Szene. So zeigt die Zeile immer die
	# Version des laufenden Spiels (FR-014).
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	_version_line.text = version_text(version)


## Der Text der Versionszeile: Aus „0.1“ wird „V0.1 · PROTOTYP“. Ohne Version steht nur
## das Kennzeichen da, kein „V“ ohne Zahl.
static func version_text(version: String) -> String:
	if version.is_empty():
		return STAGE
	return "V%s · %s" % [version, STAGE]


## Zeigt den Hinweis zur gewählten Zeile neben ihr. Verbunden in title_screen.tscn.
func _on_main_menu_selection_changed(entry: MenuEntry, row_rect: Rect2) -> void:
	_menu_hint.show_for(entry, row_rect)
