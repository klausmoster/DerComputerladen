class_name MenuEntry
extends Resource

## Ein Eintrag in einem Menü des Titels: was dort steht, ob er sich auslösen lässt und was
## sein Hinweis sagt.
##
## Als Resource lässt sich ein Eintrag im Inspector pflegen und als Unter-Resource in
## einer Szene speichern; Tests und der Titelbildschirm legen ihn mit `MenuEntry.new()` an.
## Das Menü liest nur die Felder, die Daten gehören also nicht in den Code des Menüs.
##
## Regeln (siehe specs/001-hauptmenue/data-model.md und specs/004-neues-spiel,
## contracts/titelbildschirm.md):
## - `id` ist im Menü eindeutig und eine dieser Kennungen:
##   - Hauptmenü: `&"continue"`, `&"new_game"`, `&"load_game"`, `&"settings"`, `&"quit"`;
##   - Gradwahl: `&"easy"`, `&"medium"`, `&"hard"`, `&"back"`;
##   - Liste der Spielstände: `&"delete_mode"`, `&"back"`;
##   - Rückfrage: `&"cancel"`, `&"delete"`.
## - `hint` ist nie leer: Jeder Eintrag sagt, was er tut oder warum er noch nicht geht.

## Feste Kennung, an der das Spiel den Eintrag erkennt, unabhängig vom angezeigten Text.
@export var id: StringName
## Text im Menü, deutsch.
@export var label: String
## Ob sich der Eintrag auslösen lässt. Nicht verfügbare Einträge stehen im Menü und
## lassen sich wählen, lösen aber nichts aus.
@export var available: bool = false
## Text des Hinweises zur gewählten Zeile. Duzt den Spieler.
@export_multiline var hint: String
