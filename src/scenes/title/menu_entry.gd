class_name MenuEntry
extends Resource

## Ein Eintrag im Hauptmenü: was dort steht, ob er sich auslösen lässt und was sein
## Hinweis sagt.
##
## Als Resource lässt sich ein Eintrag im Inspector pflegen und als Unter-Resource in
## einer Szene speichern; Tests legen ihn mit `MenuEntry.new()` an. Das Menü liest nur
## die Felder, die Daten gehören also nicht in den Code des Menüs.
##
## Regeln (siehe specs/001-hauptmenue/data-model.md):
## - `id` ist im Menü eindeutig und eine von `&"new_game"`, `&"load_game"`,
##   `&"settings"` und `&"quit"`.
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
