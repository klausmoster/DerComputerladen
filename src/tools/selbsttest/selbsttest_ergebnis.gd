class_name SelbsttestErgebnis
extends Control

## Die Zusammenfassung am Ende des Selbsttests (Feature 007, contracts/selbsttest-app.md,
## „Zusammenfassung“; R11, R12; FR-015, FR-016; Review CHK016 bis CHK028). Der Läufer wechselt nach
## dem Schreiben hierher, die Startszene, wenn sich im Ordner des Laufs nicht schreiben lässt.
##
## Sie ist ein Werkzeug im Spielfenster, wie die Werkstatt: GameWindow hält an, die Skalierung des
## Spiels ist aus, die Schrift Godots eingebaute (_richte_fenster_ein()). Das Fenster behält Größe
## und Lage aus dem Lauf; maximiert wird nicht (Klaus, 2026-10-28). Das
## Theme ist eine Kopie von werkstatt_theme.tres mit den Varianten für Felder und Einträge dieser
## Seite; die Schrift kommt per Code dazu, weil sie keine Datei hat.
##
## Von oben: Überschrift, Systemzeile, Summe, „Was nicht stimmt“ mit der Liste, Pfad, Knopfreihe.
## Was die Seite zeigt, kommt nur aus dem Lauf und SelbsttestTexte; der Text für „Kopieren“ aus
## SelbsttestProtokoll, derselben Funktion wie protokoll.txt (FR-014a).
##
## Zwischenablage, Dateimanager und Beenden lassen sich über Callables ersetzen, wie quit_callback
## in GameSession; so prüfen Tests ohne Fenster, was die Knöpfe tun.

## Die Szene; erstelle() lädt sie. Kein preload: Die Szene nennt dieses Skript, ein preload hier
## wäre ein Kreis.
const SZENE := "res://tools/selbsttest/selbsttest_ergebnis.tscn"
## Zeichen, nach denen ein Pfad umbrechen darf (CHK027), unter Windows auch der Rückstrich.
const TRENNER: Array[String] = ["/", "\\"]
## Unsichtbare Stelle zum Umbrechen (Leerzeichen ohne Breite, U+200B). Hinter jedem Trenner
## eingefügt, bricht der Pfad dort um statt mitten in einem Namen; gekürzt wird er nie.
const UMBRUCHSTELLE := "\u200B"
## Leerzeichen, an dem nicht umbrochen wird (U+00A0). Es ersetzt die Leerzeichen im Pfad, etwa in
## „Application Support“; sonst bräche der Pfad auch dort um.
const FESTES_LEERZEICHEN := "\u00A0"

## Der Lauf, den die Seite zeigt.
var lauf: SelbsttestLauf = null
## Absoluter Pfad des Ordners des Laufs, für Pfad, Meldung und „ordner:“.
var ordner: String = ""
## Absoluter Pfad des Zips, für „Ordner zeigen“.
var zip_pfad: String = ""
## false, wenn sich im Ordner nicht schreiben ließ (CHK020).
var beschreibbar: bool = true
## Das Betriebssystem wie OS.get_name(); unter „Linux“ sagt die Bestätigung mehr (R11). Tests
## stellen es um.
var system_name: String = OS.get_name()
## Legt einen Text in die Zwischenablage. Tests geben eine eigene Funktion.
var zwischenablage: Callable = DisplayServer.clipboard_set
## Zeigt eine Datei im Dateimanager, gibt ein Error zurück. Tests geben eine eigene Funktion.
var dateimanager: Callable = OS.shell_show_in_file_manager
## Beendet die App; ungültig heißt get_tree().quit().
var beenden: Callable

@onready var _ueberschrift: Label = %Ueberschrift
@onready var _systemzeile: Label = %Systemzeile
@onready var _summe: Label = %Summe
@onready var _meldung: Label = %Meldung
@onready var _bereich: VBoxContainer = %Bereich
@onready var _bereichstitel: Label = %Bereichstitel
@onready var _eintraege: VBoxContainer = %Eintraege
@onready var _luecke: Control = %Luecke
@onready var _pfad: Label = %Pfad
@onready var _kopieren: Button = %Kopieren
@onready var _ordner_zeigen: Button = %OrdnerZeigen
@onready var _beenden: Button = %Beenden
@onready var _bestaetigung: Label = %Bestaetigung


## Die Zusammenfassung für [param p_lauf], noch nicht im Baum. Der Läufer gibt sie an
## SceneTree.change_scene_to_node(); so stehen alle Felder, bevor _ready() läuft.
static func erstelle(p_lauf: SelbsttestLauf, p_ordner: String, p_zip_pfad: String,
		p_beschreibbar: bool = true) -> SelbsttestErgebnis:
	var ergebnis := (load(SZENE) as PackedScene).instantiate() as SelbsttestErgebnis
	ergebnis.lauf = p_lauf
	ergebnis.ordner = p_ordner
	ergebnis.zip_pfad = p_zip_pfad
	ergebnis.beschreibbar = p_beschreibbar
	return ergebnis


func _ready() -> void:
	# Die Kopie des Themes gehört nur dieser Seite; die Schrift darf deshalb direkt hinein.
	# Open Sans SemiBold ist Godots eingebaute Schrift und hat keine Datei, die das Theme nennen
	# könnte (CHK017).
	theme.default_font = ThemeDB.fallback_font
	_richte_fenster_ein()
	get_window().title = SelbsttestTexte.FENSTERTITEL_DANACH
	_richte_knoepfe_ein()
	_zeige_lauf()
	# Fokus auf „Kopieren“: Ein versehentliches Enter beendet so nichts (CHK023).
	_kopieren.grab_focus()


## Die Bestätigung steht bis zum nächsten Klick (CHK025). _input() sieht jeden Klick, bevor ein
## Knopf ihn bekommt; ein Klick auf „Kopieren“ zeigt sie danach gleich wieder.
func _input(event: InputEvent) -> void:
	var taste := event as InputEventMouseButton
	if taste == null or not taste.pressed:
		return
	if taste.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN,
			MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
		return
	_bestaetigung.visible = false


## Der Text für „Kopieren“ (contracts/protokoll.md): ohne die Schritte in Ordnung, am Ende der
## Ordner; ist der Ordner nicht beschreibbar, Meldung und Systemdaten.
func kopiertext() -> String:
	if beschreibbar:
		return SelbsttestProtokoll.kopieren(lauf, ordner)
	return SelbsttestProtokoll.kopieren_nicht_beschreibbar(lauf, ordner)


## „Kopieren“: Text in die Zwischenablage, dann die Bestätigung.
func kopiere() -> void:
	zwischenablage.call(kopiertext())
	_bestaetigung.text = SelbsttestTexte.BESTAETIGUNG_LINUX if system_name == "Linux" \
		else SelbsttestTexte.BESTAETIGUNG
	_bestaetigung.visible = true


## „Ordner zeigen“: das Zip im Dateimanager, markiert unter Windows und macOS; Linux öffnet den
## Ordner (R11, CHK002). Gibt es das Zip nicht, weil das Packen scheiterte, zeigt es den Ordner
## des Laufs.
func zeige_ordner() -> void:
	_bestaetigung.visible = false
	var ziel := zip_pfad if FileAccess.file_exists(zip_pfad) else ordner
	var fehler: Variant = dateimanager.call(ziel)
	if fehler is int and fehler != OK:
		push_warning("%s: %s" % [ziel, error_string(fehler)])


## „Beenden“.
func beende() -> void:
	_bestaetigung.visible = false
	if beenden.is_valid():
		beenden.call()
	else:
		get_tree().quit()


# --- Aufbau ---------------------------------------------------------------------------------------

## Fenster für ein Werkzeug wie in der Werkstatt (CHK016; Werkstatt._set_up_window()): volle
## Auflösung statt des Spielrasters, Text in normaler Größe auch auf dem Retina-Bildschirm. Anders
## als die Werkstatt maximiert die Seite nicht (Klaus, 2026-10-28): Das Fenster behält Größe und
## Lage aus dem Lauf, damit der Selbsttest eine Fenstergröße hat, die sich wiederholen lässt; die
## Seite nimmt die Fläche, die da ist. Headless gibt es kein Fenster; dann bleibt alles, wie es ist.
func _richte_fenster_ein() -> void:
	if DisplayServer.get_name() == "headless":
		return
	# GameWindow anhalten, damit es Größe und Lage nicht mehr anfasst: Es gäbe dem Fenster sonst
	# beim Wechsel aus dem Vollbild wieder die ganzzahlige Spielgröße. Über den Pfad, wie in der
	# Werkstatt.
	var game_window := get_node_or_null(^"/root/GameWindow")
	if game_window != null:
		game_window.set_process(false)
		game_window.set_process_input(false)
	var fenster := get_window()
	fenster.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	# Unter Windows und X11 kennt screen_get_scale() die Skalierung nicht; SelbsttestSystem rechnet
	# sie dort aus den dpi (Klaus, Phase 8).
	fenster.content_scale_factor = SelbsttestSystem.bildschirm_skalierung()


func _richte_knoepfe_ein() -> void:
	_kopieren.text = SelbsttestTexte.KNOPF_KOPIEREN
	_kopieren.tooltip_text = SelbsttestTexte.TOOLTIP_KOPIEREN
	_ordner_zeigen.text = SelbsttestTexte.KNOPF_ORDNER_ZEIGEN
	_ordner_zeigen.tooltip_text = SelbsttestTexte.TOOLTIP_ORDNER_ZEIGEN
	_beenden.text = SelbsttestTexte.KNOPF_BEENDEN
	_beenden.tooltip_text = SelbsttestTexte.TOOLTIP_BEENDEN
	_kopieren.pressed.connect(kopiere)
	_ordner_zeigen.pressed.connect(zeige_ordner)
	_beenden.pressed.connect(beende)
	# Ohne Ordner gibt es nichts zu zeigen (CHK020). Ein gesperrter Knopf behält in Godot seinen
	# Fokus-Modus; ohne ihn überspringt Tab den Knopf, und der Zeiger bleibt ein Pfeil wie bei
	# Knopf (ui/knopf.gd).
	if not beschreibbar:
		_ordner_zeigen.disabled = true
		_ordner_zeigen.tooltip_text = SelbsttestTexte.TOOLTIP_ORDNER_GESPERRT
		_ordner_zeigen.focus_mode = Control.FOCUS_NONE
		_ordner_zeigen.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _zeige_lauf() -> void:
	_ueberschrift.text = SelbsttestTexte.ueberschrift(lauf.start)
	_systemzeile.text = SelbsttestTexte.systemzeile(lauf.system)
	if not beschreibbar:
		# An Stelle von Summe, Liste und Pfad steht die Meldung als Feld (CHK020).
		_meldung.text = SelbsttestTexte.kein_protokoll(umbrechbar(ordner))
		_meldung.visible = true
		_summe.visible = false
		_bereich.visible = false
		_pfad.visible = false
		_luecke.visible = true
		return
	_summe.text = lauf.summe_text()
	_pfad.text = SelbsttestTexte.pfad(umbrechbar(ordner))
	var schritte := lauf.nicht_in_ordnung()
	# Bei alles in Ordnung entfallen Bereichstitel und Liste (CHK021); die Lücke hält die
	# Knopfreihe unten. Beide stehen in einem eigenen Bereich: 8 vom Titel zur Liste, 16 zur Summe.
	_bereich.visible = not schritte.is_empty()
	_luecke.visible = schritte.is_empty()
	_bereichstitel.text = SelbsttestTexte.BEREICHSTITEL
	var feld := _feldgroesse()
	for i in schritte.size():
		_eintraege.add_child(_eintrag(schritte[i], i % 2 == 1, feld))


## Ein Eintrag der Liste (CHK019, CHK024, CHK027): links das Feld, rechts die Zeilen, lange Werte
## umbrochen. Jeder zweite Eintrag hat den Grund endlos-gruen. Nicht anklickbar und ohne
## Überfahren: Kein Teil nimmt die Maus an, das Mausrad kommt so beim ScrollContainer an.
func _eintrag(schritt: SelbsttestLauf.Schritt, zweiter: bool, feld: Vector2) -> PanelContainer:
	var kasten := PanelContainer.new()
	kasten.theme_type_variation = &"AlternateEntryPanel" if zweiter else &"EntryPanel"
	kasten.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var reihe := HBoxContainer.new()
	reihe.add_theme_constant_override(&"separation", 8)
	reihe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kasten.add_child(reihe)

	var fehler := schritt.status == SelbsttestLauf.Status.FEHLER
	var zeichen := Label.new()
	zeichen.theme_type_variation = &"ErrorMarkLabel" if fehler else &"NotRunMarkLabel"
	zeichen.text = SelbsttestTexte.ZEICHEN_FEHLER if fehler \
		else SelbsttestTexte.ZEICHEN_NICHT_GELAUFEN
	zeichen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zeichen.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	zeichen.custom_minimum_size = feld
	zeichen.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	reihe.add_child(zeichen)

	var zeilen := VBoxContainer.new()
	zeilen.add_theme_constant_override(&"separation", 0)
	zeilen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zeilen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reihe.add_child(zeilen)
	for text in eintrag_zeilen(schritt):
		var zeile := Label.new()
		zeile.text = text
		zeile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		zeilen.add_child(zeile)
	return kasten


## Die Zeilen eines Eintrags: bei FEHLER Kennung mit Beschreibung, „Erwartet: …“ und „Gefunden:
## …“; sonst Kennung mit Beschreibung und „Nicht gelaufen: …“ mit dem Grund.
static func eintrag_zeilen(schritt: SelbsttestLauf.Schritt) -> PackedStringArray:
	var zeilen := PackedStringArray([
		SelbsttestTexte.eintrag(schritt.kennung, schritt.beschreibung)])
	if schritt.status == SelbsttestLauf.Status.FEHLER:
		zeilen.append(SelbsttestTexte.erwartet(schritt.erwartet))
		zeilen.append(SelbsttestTexte.gefunden(schritt.gefunden))
	else:
		var grund := schritt.gefunden if not schritt.gefunden.is_empty() \
			else SelbsttestTexte.UNBEKANNT
		zeilen.append(SelbsttestTexte.nicht_gelaufen(grund))
	return zeilen


## [param pfad] so, dass er nur nach einem Trenner umbricht (CHK027): hinter jedem Trenner eine
## unsichtbare Umbruchstelle, jedes Leerzeichen fest. Ohne das bräche ein langer Pfad an einem
## Leerzeichen in einem Ordnernamen um oder mitten in einem Namen. Zu sehen ist der Pfad genau so,
## wie er heißt.
static func umbrechbar(pfad: String) -> String:
	pfad = pfad.replace(" ", FESTES_LEERZEICHEN)
	for trenner in TRENNER:
		pfad = pfad.replace(trenner, trenner + UMBRUCHSTELLE)
	return pfad


## Das Feld vor einem Eintrag ist quadratisch und so hoch wie eine Zeile Text; so steht das
## Zeichen genau neben der ersten Zeile.
func _feldgroesse() -> Vector2:
	var schrift := get_theme_font(&"font", &"Label")
	var hoehe := ceilf(schrift.get_height(get_theme_font_size(&"font_size", &"Label")))
	return Vector2(hoehe, hoehe)
