class_name SelbsttestAblage
extends RefCounted

## Wo ein Lauf seine Ergebnisse ablegt (Feature 007, data-model.md, „Ergebnis eines Laufs“; R11;
## FR-016): im Datenordner der Selbsttest-App unter selbsttest/<lauf-id>/ mit protokoll.txt,
## ausgabe.txt und fotos/<kennung>.png, daneben dasselbe als <lauf-id>_<system>.zip.
##
## Der Basisordner ist umstellbar, damit Tests in eigene Ordner schreiben; nie nach
## user://spielstaende/. Jede Methode gibt ein Error zurück, wie FileAccess und DirAccess; was
## daraus folgt, entscheidet der Läufer. Lässt sich schon beim Anlegen nicht schreiben, zeigt die
## Zusammenfassung „Kein Protokoll: In <pfad> lässt sich nicht schreiben.“ mit ordner().
##
## Texte schreibt sie als UTF-8 ohne BOM, so wie sie kommen; FileAccess.store_string() ändert
## keine Zeilenenden. Das Zip packt ZIPPacker aus Godot, eine Datei nach der anderen; die Pfade im
## Zip beginnen ohne den Ordner des Laufs, also protokoll.txt und fotos/<kennung>.png.

## Basisordner im Datenordner der App (R11).
const BASIS := "user://selbsttest/"
const PROTOKOLL := "protokoll.txt"
const AUSGABE := "ausgabe.txt"
const FOTOS := "fotos"
## Name der Probedatei, mit der lege_an() prüft, ob sich schreiben lässt; sie bleibt nicht liegen.
const PROBE := ".probe"

## Der Basisordner, mit „/“ am Ende; Tests stellen ihn um.
var basis: String = BASIS
## Die Kennung des Laufs, „2026-10-28_14-03-12“.
var lauf_id: String
## Das System im Namen des Zips, klein: „macos“, „windows“, „linux“.
var system: String = OS.get_name().to_lower()


func _init(p_lauf_id: String, p_basis: String = BASIS) -> void:
	lauf_id = p_lauf_id
	basis = p_basis


## Legt den Ordner des Laufs samt fotos/ an und prüft, ob sich darin schreiben lässt. Bei einem
## Fehler bleibt nichts liegen, was sich nicht schreiben ließ; ordner() nennt den Pfad.
func lege_an() -> Error:
	var fehler := DirAccess.make_dir_recursive_absolute(_pfad(FOTOS))
	if fehler != OK:
		return fehler
	var probe := FileAccess.open(_pfad(PROBE), FileAccess.WRITE)
	if probe == null:
		return FileAccess.get_open_error()
	probe.close()
	return DirAccess.remove_absolute(_pfad(PROBE))


## Der Ordner des Laufs als absoluter Pfad des Systems, für die Zusammenfassung und „ordner:“.
func ordner() -> String:
	return ProjectSettings.globalize_path(_pfad(""))


## Das Zip des Laufs als absoluter Pfad des Systems, für „Ordner zeigen“.
func zip_pfad() -> String:
	return ProjectSettings.globalize_path(_zip())


## Speichert [param bild] als fotos/<kennung>.png.
func speichere_foto(kennung: String, bild: Image) -> Error:
	if bild == null:
		return ERR_INVALID_PARAMETER
	return bild.save_png(_pfad(FOTOS.path_join(kennung + ".png")))


## Schreibt [param text] nach protokoll.txt.
func schreibe_protokoll(text: String) -> Error:
	return _schreibe(PROTOKOLL, text)


## Schreibt [param text] nach ausgabe.txt.
func schreibe_ausgabe(text: String) -> Error:
	return _schreibe(AUSGABE, text)


## Packt den Ordner des Laufs in das Zip daneben; ein altes Zip gleichen Namens ersetzt es. Die
## Dateien kommen in fester Reihenfolge: erst die im Ordner, dann die Unterordner, je nach Namen.
func packe() -> Error:
	var packer := ZIPPacker.new()
	var fehler := packer.open(_zip())
	if fehler != OK:
		return fehler
	var dateien := PackedStringArray()
	_sammle("", dateien)
	for datei in dateien:
		var inhalt := FileAccess.get_file_as_bytes(_pfad(datei))
		if inhalt.is_empty() and FileAccess.get_open_error() != OK:
			packer.close()
			return FileAccess.get_open_error()
		fehler = packer.start_file(datei)
		if fehler == OK:
			fehler = packer.write_file(inhalt)
		if fehler == OK:
			fehler = packer.close_file()
		if fehler != OK:
			packer.close()
			return fehler
	return packer.close()


## Sammelt die Dateien unter [param unterordner] als Pfade relativ zum Ordner des Laufs.
func _sammle(unterordner: String, dateien: PackedStringArray) -> void:
	var pfad := _pfad(unterordner)
	var namen := DirAccess.get_files_at(pfad)
	namen.sort()
	for name in namen:
		dateien.append(unterordner.path_join(name) if not unterordner.is_empty() else name)
	var ordner_namen := DirAccess.get_directories_at(pfad)
	ordner_namen.sort()
	for name in ordner_namen:
		_sammle(unterordner.path_join(name) if not unterordner.is_empty() else name, dateien)


func _schreibe(datei: String, text: String) -> Error:
	var zugriff := FileAccess.open(_pfad(datei), FileAccess.WRITE)
	if zugriff == null:
		return FileAccess.get_open_error()
	zugriff.store_string(text)
	var fehler := zugriff.get_error()
	zugriff.close()
	return fehler


## user://selbsttest/<lauf-id>/[param relativ]; ohne [param relativ] der Ordner selbst, ohne „/“
## am Ende.
func _pfad(relativ: String) -> String:
	var lauf_ordner := basis.path_join(lauf_id)
	return lauf_ordner.path_join(relativ) if not relativ.is_empty() else lauf_ordner


## user://selbsttest/<lauf-id>_<system>.zip.
func _zip() -> String:
	return basis.path_join("%s_%s.zip" % [lauf_id, system])
