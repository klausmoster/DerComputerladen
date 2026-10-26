extends SceneTree

## Fotografiert eine Szene im Raster 640 × 360 für die Phasenprüfung, einmal in Originalgröße und
## einmal dreifach vergrößert (Nearest), damit Prüfer die Pixel erkennen.
##
## Aufruf vom Repo-Ordner aus:
##   Godot --path src -s <pfad>/fotos.gd -- --szene=res://scenes/title/title_screen.tscn --ziel=/tmp/fotos/ --name=titel
##
## Für Zustände wie eine gewählte Menüzeile kopiert Claude das Skript in den Scratchpad und ergänzt
## in `_zustaende()` die Schritte, etwa `menue.select(3)`. Ins Repo schreibt das Skript nichts.

var _ziel := ""
var _name := "foto"


func _initialize() -> void:
	var szene := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--szene="):
			szene = arg.trim_prefix("--szene=")
		elif arg.begins_with("--ziel="):
			_ziel = arg.trim_prefix("--ziel=")
		elif arg.begins_with("--name="):
			_name = arg.trim_prefix("--name=")
	if szene.is_empty() or _ziel.is_empty():
		push_error("Aufruf: -- --szene=res://… --ziel=/ordner/ [--name=foto]")
		quit(1)
		return
	_fotografieren.call_deferred(szene)


func _fotografieren(szene: String) -> void:
	var knoten: Node = load(szene).instantiate()
	root.add_child(knoten)
	await _warten()
	await _foto(_name)
	await _zustaende(knoten)
	quit()


## Hier kommen weitere Zustände hin, je mit eigenem Foto. Ohne Ergänzung gibt es nur das erste.
func _zustaende(_knoten: Node) -> void:
	pass


func _warten() -> void:
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw


func _foto(name: String) -> void:
	await _warten()
	var bild := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_ziel)
	bild.save_png(_ziel.path_join(name + ".png"))
	var gross := bild.duplicate() as Image
	gross.resize(bild.get_width() * 3, bild.get_height() * 3, Image.INTERPOLATE_NEAREST)
	gross.save_png(_ziel.path_join(name + "_x3.png"))
	print("Foto ", name, ": ", bild.get_size())
