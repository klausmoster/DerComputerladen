extends SelbsttestAblauf

## Ablauf „fenster“ (contracts/ablaeufe.md, „fenster“; R16; FR-011, Punkt 7): Das Fenster startet
## mit dem größten ganzzahligen Faktor, der auf den Bildschirm passt, samt Titelleiste mittig im
## nutzbaren Bereich ohne Menüleiste und Dock;
## bei 640 × 360 steht das Bild 1:1, bei einer krummen Größe mit ganzem Faktor in der Mitte und Rand
## ringsum; zurück in der Startgröße wieder ohne Rand. Ohne Vollbild und ohne Zeitraffer, denn er
## wartet auf Fenster des Systems (R24). Er beginnt beim frischen Titel.
##
## Die Größe stellt der Fahrer über das Fenster ein, nicht über Eingaben (Spec FR-004); im
## Protokoll steht „eingaben: Fenster …“. Geprüft werden Zahlen: Größe und Lage des Fensters, und
## wie Godot das Raster hineinsetzt, gelesen aus get_final_transform() der Wurzel. Die Fotos zeigen
## dennoch das Raster, immer 640 × 360. Schritt 04 stellt Größe und Lage vom Start wieder her.

## Fenstergrößen von 02 und 03, in Bildschirmpixeln.
const FAKTOR_1 := Vector2i(640, 360)
## Krumm, aber gerade: Auf einem Bildschirm mit Skalierung 2 setzt macOS nur gerade Maße.
const KRUMM := Vector2i(1318, 742)

## Größe und Lage des Fensters, bevor 02 sie ändert; 04 stellt sie wieder her.
var _vorher_groesse := Vector2i.ZERO
var _vorher_lage := Vector2i.ZERO


func _init() -> void:
	kennung = "fenster"
	name = SelbsttestTexte.ablauf_name(kennung)
	zeitraffer = 1


## Die Startgröße steht erst fest, wenn das Fenster da ist: Sie hängt vom Bildschirm ab. Der Läufer
## ruft schritte() nach dem Start, wenn GameWindow das Fenster schon eingepasst hat; deshalb nennt
## die Erwartung von 01 und 04 die Zahlen dieses Rechners.
func schritte(fahrer: SelbsttestFahrer) -> Array[Dictionary]:
	var faktor := fahrer.bester_faktor()
	var start := SelbsttestTexte.fenster(FAKTOR_1 * faktor, faktor,
		[SelbsttestTexte.ZUSTAND_OHNE_RAND])
	@warning_ignore("integer_division")
	var krumm_faktor := mini(KRUMM.x / FAKTOR_1.x, KRUMM.y / FAKTOR_1.y)
	var krumm := SelbsttestTexte.fenster(KRUMM, krumm_faktor, [SelbsttestTexte.ZUSTAND_MITTIG,
		SelbsttestTexte.ZUSTAND_RAND_RINGSUM, SelbsttestTexte.ZUSTAND_GANZE_PIXEL])
	var faktor_1 := SelbsttestTexte.fenster(FAKTOR_1, 1, [SelbsttestTexte.ZUSTAND_OHNE_RAND])
	return [
		neuer_schritt("01_start", SelbsttestTexte.BESCHREIBUNG_FENSTER_START,
			SelbsttestTexte.EINGABEN_KEINE, _keine_eingabe,
			_pruefe_start.bind(fahrer, start),
			SelbsttestTexte.zustaende([start, SelbsttestTexte.ZUSTAND_LAGE_MITTIG])),
		neuer_schritt("02_faktor_1", SelbsttestTexte.BESCHREIBUNG_FENSTER_FAKTOR_1,
			SelbsttestTexte.fenster_auf(FAKTOR_1),
			_merke_und_stelle.bind(fahrer, FAKTOR_1),
			_pruefe_fenster.bind(fahrer, faktor_1),
			faktor_1),
		neuer_schritt("03_krumm", SelbsttestTexte.BESCHREIBUNG_FENSTER_KRUMM,
			SelbsttestTexte.fenster_auf(KRUMM),
			fahrer.stelle_fenster.bind(KRUMM),
			_pruefe_fenster.bind(fahrer, krumm),
			krumm),
		neuer_schritt("04_zurueck", SelbsttestTexte.BESCHREIBUNG_FENSTER_ZURUECK,
			SelbsttestTexte.FENSTER_AUF_STARTGROESSE,
			_stelle_zurueck.bind(fahrer),
			_pruefe_fenster.bind(fahrer, start),
			start),
	]


## Ist ein Schritt des Ablaufs gescheitert, steht das Fenster vielleicht noch krumm; dann stellt
## dieser Haken Größe und Lage vom Start wieder her, damit die folgenden Abläufe gleich aussehen.
func aufraeumen(fahrer: SelbsttestFahrer) -> void:
	if _vorher_groesse != Vector2i.ZERO and fahrer.fenster().size != _vorher_groesse:
		fahrer.fenster().size = _vorher_groesse
		fahrer.fenster().position = _vorher_lage


## 01: Fenster und Bild wie [param start], mittig im nutzbaren Bereich. Dazu wartet der Schritt,
## bis der Communicator des frischen Titels steht: Ohne Eingabe wartet der Läufer nicht darauf, und
## die Fotos dieses Ablaufs zeigten sonst die Fahrt herein, in jedem Lauf an anderer Stelle.
func _pruefe_start(fahrer: SelbsttestFahrer, start: String) -> String:
	var zustand := fahrer.fenster_zustand()
	var lage := fahrer.fenster_lage()
	var steht := fahrer.communicator_steht()
	if zustand == start and lage == SelbsttestTexte.ZUSTAND_LAGE_MITTIG and steht:
		return ""
	var teile := PackedStringArray([zustand, lage])
	if not steht:
		teile.append(SelbsttestTexte.ZUSTAND_COMMUNICATOR_FAEHRT)
	return SelbsttestTexte.zustaende(teile)


## 02 bis 04: Fenster und Bild wie [param erwartet].
func _pruefe_fenster(fahrer: SelbsttestFahrer, erwartet: String) -> String:
	var zustand := fahrer.fenster_zustand()
	return "" if zustand == erwartet else zustand


## 02, Eingaben: merkt sich Größe und Lage vom Start, dann das Fenster auf [param groesse].
func _merke_und_stelle(fahrer: SelbsttestFahrer, groesse: Vector2i) -> String:
	_vorher_groesse = fahrer.fenster().size
	_vorher_lage = fahrer.fenster().position
	return await fahrer.stelle_fenster(groesse)


## 04, Eingaben: Größe und Lage vom Start zurück.
func _stelle_zurueck(fahrer: SelbsttestFahrer) -> String:
	var antwort: String = await fahrer.stelle_fenster(_vorher_groesse, _vorher_lage)
	_vorher_groesse = Vector2i.ZERO
	return antwort


func _keine_eingabe() -> String:
	return ""
