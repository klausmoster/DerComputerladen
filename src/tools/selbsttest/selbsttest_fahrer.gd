class_name SelbsttestFahrer
extends RefCounted

## Der Fahrer kennt den Titel und den Spielbildschirm, die Abläufe kennen nur ihn (Feature 007,
## contracts/selbsttest-app.md, „Fahrer“; R5; FR-005, FR-006). Er findet Ziele über ihre Bedeutung,
## etwa den Eintrag `new_game` im Hauptmenü, und liest den Zustand: sichtbare Seite, gewählte Zeile,
## Hinweis, Bildschirm, Spielstände, ob der Communicator steht. Ändert sich die Oberfläche, ändert
## sich diese eine Datei, nicht jeder Ablauf.
##
## Er liest nur, was Bildschirm, Seiten und Communicator ohnehin anbieten: öffentliche Methoden und
## Felder (current_page(), selected_entry(), entries, selected_slot(), is_in(), store()) und die
## Knoten der Szenen unter ihren Namen (Communicator/Hint, Rows, LeaveButton, Keys/CaseKey0). Am
## Spiel ändert er nichts.
##
## Alle Rechtecke stehen im Raster 640 × 360, so wie Controls im Fenster mit Stretch „viewport“
## liegen; in Fensterpixel rechnet sie erst SelbsttestEingabe um. Ein leeres Rect2 heißt: Das Ziel
## ist nicht da oder nicht zu sehen. fehlt() macht daraus den Text für „gefunden:“.
##
## Ob der Communicator steht, verfolgt der Fahrer über das Signal slide_finished: is_in() ist schon
## während der Fahrt herein wahr (Analyse, I3). Dazu hört er auf SceneTree.node_added; so ist er bei
## jedem neuen Communicator dabei, bevor dessen Fahrt beginnt.
##
## „Beenden“ im Titel beendete die App mitten im Lauf. Der Fahrer gibt deshalb jedem neuen Titel
## einen eigenen quit_callback, der nur mitzählt; ein Schritt sieht so, ob „Beenden“ ausgelöst hat.

## Seiten des Titels unter ihrem Namen in title_screen.tscn.
const SEITE_HAUPTMENUE := &"MainMenu"
const SEITE_GRADWAHL := &"DifficultySheet"
const SEITE_SPIELSTAENDE := &"SaveList"
const SEITE_RUECKFRAGE := &"ConfirmSheet"
const SEITE_INVADERS := &"Invaders"
## Kennungen der festen Zeilen der Liste, wie in MenuEntry dokumentiert.
const ZEILE_LOESCHEN := &"delete_mode"
const ZEILE_ZURUECK := &"back"
## Kennung des Knopfs „Zum Hauptmenü“ im Spielbildschirm; das Spiel selbst kennt keine.
const KNOPF_HAUPTMENUE := &"leave"

## GameSession hat als Autoload keinen class_name; den Typ gibt sein Skript.
const SESSION_SCRIPT := preload("res://core/game_session.gd")

## Über sie schicken die Abläufe ihre Eingaben.
var eingabe: SelbsttestEingabe = null
## null heißt das Autoload GameSession; Tests setzen eine eigene.
var session: Node = null
## Der Bildschirm, den der Fahrer ansieht; null heißt die laufende Szene. Tests setzen ihren Titel
## in einem eigenen Viewport.
var szene: Node = null

var _baum: SceneTree
## Kennung eines Communicators → ob er nach seiner letzten Fahrt in der Endlage steht.
var _steht: Dictionary = {}
var _beenden := 0


func _init(baum: SceneTree, p_eingabe: SelbsttestEingabe = null) -> void:
	_baum = baum
	eingabe = p_eingabe
	_baum.node_added.connect(_on_node_added)


# --- Bildschirme und Zustand ----------------------------------------------------------------------

## Der Titel, oder null, wenn kein Titel steht.
func titel() -> TitleScreen:
	return _szene() as TitleScreen


## Der Spielbildschirm, oder null.
func spielbildschirm() -> GameScreen:
	return _szene() as GameScreen


## Die Seite, die der Communicator gerade zeigt, oder null.
func sichtbare_seite() -> Control:
	var communicator := _communicator()
	return communicator.current_page() if communicator != null else null


## Die Kennung der Zeile mit dem Fokus: im Menü die des Eintrags (`new_game` …), in der Liste
## `slot_<nummer>`, ZEILE_LOESCHEN oder ZEILE_ZURUECK, im Spielbildschirm KNOPF_HAUPTMENUE. Leer,
## wenn nichts auf der sichtbaren Seite den Fokus hat.
func gewaehlter_eintrag() -> StringName:
	var spiel := spielbildschirm()
	if spiel != null:
		var knopf := spiel.get_node_or_null(^"LeaveButton") as Control
		return KNOPF_HAUPTMENUE if knopf != null and knopf.has_focus() else &""
	var seite := sichtbare_seite()
	if seite == null:
		return &""
	var fokus := seite.get_viewport().gui_get_focus_owner()
	if fokus == null or not seite.is_ancestor_of(fokus):
		return &""
	if seite is MainMenu:
		var eintrag := (seite as MainMenu).selected_entry()
		return eintrag.id if eintrag != null else &""
	if seite is SaveList:
		var slot := (seite as SaveList).selected_slot()
		if slot != null:
			return StringName("slot_%d" % slot.number)
		return ZEILE_LOESCHEN if fokus.name == &"DeleteMode" else ZEILE_ZURUECK
	return &""


## Der Text des Hinweises oder der Meldung neben der gewählten Zeile; leer, wenn keiner steht.
func hinweis_text() -> String:
	var hinweis: MenuHint = null
	var spiel := spielbildschirm()
	if spiel != null:
		hinweis = spiel.get_node_or_null(^"MenuHint") as MenuHint
	else:
		var communicator := _communicator()
		if communicator != null:
			hinweis = communicator.get_node_or_null(^"Hint") as MenuHint
	if hinweis == null or not hinweis.is_visible_in_tree():
		return ""
	var text := hinweis.get_node_or_null(^"Text") as Label
	return text.text if text != null else ""


## Ob der Communicator des Titels in der Endlage steht und nicht fährt: Seine letzte Fahrt endete
## herein, und er fährt nicht wieder hinaus.
func communicator_steht() -> bool:
	var communicator := _communicator()
	if communicator == null:
		return false
	return _steht.get(communicator.get_instance_id(), false) and communicator.is_in()


## Die Nummern der Spielstände im Ordner der Session, in der Reihenfolge der Liste.
func spielstaende() -> PackedInt32Array:
	var nummern := PackedInt32Array()
	for slot in _session().store().list_slots():
		nummern.append(slot.number)
	return nummern


## Wie oft „Beenden“ im Titel ausgelöst hat, seit der Fahrer läuft.
func beenden_ausgeloest() -> int:
	return _beenden


## Ob die gewählte Zeile eines Menüs verfügbar ist, also auslösen kann. Ohne gewählten Eintrag
## eines Menüs false.
func gewaehlt_verfuegbar() -> bool:
	var menue := sichtbare_seite() as MainMenu
	if menue == null or gewaehlter_eintrag().is_empty():
		return false
	return menue.selected_entry().available


## Ob [param seite] steht (contracts/ablaeufe.md, „Gemeinsame Prüfungen“): Sie ist die sichtbare
## Seite, der Communicator steht, die Zeile [param kennung] hat den Fokus, und der Hinweis zeigt
## den Text dieser Zeile.
func menue_steht(seite: StringName, kennung: StringName) -> bool:
	var blatt := sichtbare_seite()
	if not communicator_steht() or blatt == null or blatt.name != seite:
		return false
	if gewaehlter_eintrag() != kennung:
		return false
	return hinweis_text() == _hinweis_der_zeile(blatt)


## Der Zustand in der Form der Spalte „Erwartet“, für „gefunden:“: etwa „Menü steht: HAUPTMENÜ,
## „Neues Spiel“, Hinweis „…“; Spielstände: keine“.
func zustand() -> String:
	var teile := PackedStringArray()
	var spiel := spielbildschirm()
	if spiel != null:
		teile.append("%s, %s" % [SelbsttestTexte.ZUSTAND_SPIELBILDSCHIRM,
			SelbsttestTexte.hinweis(hinweis_text())])
	elif titel() == null:
		teile.append(SelbsttestTexte.ZUSTAND_KEIN_BILDSCHIRM)
	elif not communicator_steht():
		teile.append(SelbsttestTexte.ZUSTAND_COMMUNICATOR_FAEHRT)
	else:
		teile.append(_seite_text())
	if _beenden > 0:
		teile.append(SelbsttestTexte.ausgeloest(TitleTexts.LABEL_QUIT))
	teile.append(SelbsttestTexte.spielstaende(_namen()))
	return "; ".join(teile)


# --- Ziele ----------------------------------------------------------------------------------------

## Der Eintrag [param kennung] auf der Seite [param seite] (SEITE_…), etwa new_game im Hauptmenü;
## in der Liste ZEILE_LOESCHEN und ZEILE_ZURUECK. Leer, wenn es ihn nicht gibt oder die Seite nicht
## zu sehen ist.
func ziel_eintrag(seite: StringName, kennung: StringName) -> Rect2:
	var blatt := _seite(seite)
	if blatt == null:
		return Rect2()
	if blatt is MainMenu:
		var menue := blatt as MainMenu
		var knoepfe := _knoepfe(menue)
		for index in mini(menue.entries.size(), knoepfe.size()):
			if menue.entries[index].id == kennung:
				return _rechteck(knoepfe[index])
		return Rect2()
	if blatt is SaveList:
		match kennung:
			ZEILE_LOESCHEN:
				return _rechteck(blatt.get_node_or_null(^"Rows/DeleteMode") as Control)
			ZEILE_ZURUECK:
				return _rechteck(blatt.get_node_or_null(^"Rows/Back") as Control)
	return Rect2()


## Die Zeile der Liste, die gerade den Spielstand [param nummer] zeigt; leer, wenn er nicht im
## Fenster der Liste steht.
func ziel_zeile(nummer: int) -> Rect2:
	var blatt := _seite(SEITE_SPIELSTAENDE)
	if blatt == null:
		return Rect2()
	var gesucht := ""
	for slot in _session().store().list_slots():
		if slot.number == nummer:
			gesucht = slot.display_name()
	if gesucht.is_empty():
		return Rect2()
	for knopf in _knoepfe(blatt):
		var name_feld := knopf.get_node_or_null(^"Name") as Label
		if name_feld != null and knopf.is_visible_in_tree() and name_feld.text == gesucht:
			return _rechteck(knopf)
	return Rect2()


## Die Gehäusetaste [param index], von links ab 0; leer, wenn es sie nicht gibt.
func ziel_gehaeusetaste(index: int) -> Rect2:
	var communicator := _communicator()
	if communicator == null:
		return Rect2()
	return _rechteck(communicator.get_node_or_null(NodePath("Keys/CaseKey%d" % index)) as Control)


## Der Knopf „Zum Hauptmenü“ im Spielbildschirm; leer ohne Spielbildschirm.
func ziel_knopf_hauptmenue() -> Rect2:
	var spiel := spielbildschirm()
	if spiel == null:
		return Rect2()
	return _rechteck(spiel.get_node_or_null(^"LeaveButton") as Control)


## „Ziel nicht gefunden: …“ mit [param beschreibung], dem Ziel in der Form der Spalte „Erwartet“,
## etwa „HAUPTMENÜ, „Neues Spiel““ (SelbsttestTexte.ziel()).
func fehlt(beschreibung: String) -> String:
	return SelbsttestTexte.ziel_nicht_gefunden(beschreibung)


# --- Eingaben -------------------------------------------------------------------------------------

## Fährt die Maus auf den Eintrag [param kennung] der Seite [param seite]. Gibt "" zurück, oder
## fehlt([param beschreibung]), wenn es ihn nicht gibt; dann geht keine Eingabe hinaus. Mit await.
func maus_ueber_eintrag(seite: StringName, kennung: StringName, beschreibung: String) -> String:
	var ziel := ziel_eintrag(seite, kennung)
	if not ziel.has_area():
		return fehlt(beschreibung)
	await eingabe.maus_zu(ziel.get_center())
	return ""


# --- Intern ---------------------------------------------------------------------------------------

func _szene() -> Node:
	if is_instance_valid(szene):
		return szene
	return _baum.current_scene


func _communicator() -> Communicator:
	var bildschirm := titel()
	if bildschirm == null:
		return null
	return bildschirm.get_node_or_null(^"Communicator") as Communicator


## Die Seite [param seite] des Titels, wenn sie zu sehen ist; sonst null.
func _seite(seite: StringName) -> Control:
	var communicator := _communicator()
	if communicator == null:
		return null
	var blatt := communicator.get_node_or_null(NodePath(String(seite))) as Control
	if blatt == null or not blatt.is_visible_in_tree():
		return null
	return blatt


## Die Buttons einer Seite in Rows, von oben nach unten. Die Kopfzeile ist ein Label.
static func _knoepfe(blatt: Control) -> Array[Button]:
	var knoepfe: Array[Button] = []
	var zeilen := blatt.get_node_or_null(^"Rows")
	if zeilen == null:
		return knoepfe
	for kind in zeilen.get_children():
		if kind is Button and not kind.is_queued_for_deletion():
			knoepfe.append(kind)
	return knoepfe


## Das Rechteck von [param control] im Raster; leer, wenn es fehlt oder nicht zu sehen ist.
static func _rechteck(control: Control) -> Rect2:
	if control == null or not control.is_visible_in_tree():
		return Rect2()
	return control.get_global_rect()


## Die Kopfzeile, wie sie auf der Seite steht.
static func _kopf(blatt: Control) -> String:
	var kopf := blatt.get_node_or_null(^"Rows/Header") as Label
	return kopf.text if kopf != null else String(blatt.name)


## „Menü steht: HAUPTMENÜ, „Neues Spiel“, Hinweis „…““ für die sichtbare Seite; Grade und
## Spielstände ohne Anführungszeichen, wie in der Spalte „Erwartet“ (CHK031). Ist der gewählte
## Eintrag eines Menüs nicht verfügbar, steht „nicht verfügbar“ zwischen Zeile und Hinweis
## („Verfügbarkeit“ im Vertrag). Hat keine Zeile den Fokus, „Seite HAUPTMENÜ, keine Zeile gewählt,
## …“.
func _seite_text() -> String:
	var blatt := sichtbare_seite()
	if blatt == null:
		return SelbsttestTexte.ZUSTAND_KEINE_SEITE
	if not (blatt is MainMenu or blatt is SaveList):
		return SelbsttestTexte.ZUSTAND_SEITE % blatt.name
	var kopf := _kopf(blatt)
	var zeile := _zeile_text(blatt)
	var text: String
	if zeile.is_empty():
		text = SelbsttestTexte.seite_ohne_zeile(kopf)
	elif _ohne_zeichen(blatt, gewaehlter_eintrag()):
		text = SelbsttestTexte.menue_steht_ohne_zeichen(kopf, zeile)
	else:
		text = SelbsttestTexte.menue_steht(kopf, zeile)
	if not zeile.is_empty() and blatt is MainMenu and not gewaehlt_verfuegbar():
		text += ", " + SelbsttestTexte.NICHT_VERFUEGBAR
	return "%s, %s" % [text, SelbsttestTexte.hinweis(hinweis_text())]


## Ob die Zeile [param kennung] von [param blatt] ein Grad oder Spielstand ist; die stehen ohne
## Anführungszeichen. Menüeinträge, „Löschen …“, „Zurück“ und „Abbrechen“ stehen in „…“.
static func _ohne_zeichen(blatt: Control, kennung: StringName) -> bool:
	if blatt.name == SEITE_GRADWAHL:
		return kennung in TitleScreen.LEVEL_IDS
	if blatt is SaveList:
		return String(kennung).begins_with("slot_")
	return false


## Der Text der Zeile mit dem Fokus, wie er dasteht; leer ohne Fokus.
func _zeile_text(blatt: Control) -> String:
	var kennung := gewaehlter_eintrag()
	if kennung.is_empty():
		return ""
	if blatt is MainMenu:
		return (blatt as MainMenu).selected_entry().label
	var slot := (blatt as SaveList).selected_slot()
	if slot != null:
		return slot.display_name()
	return TitleTexts.LABEL_DELETE_MODE if kennung == ZEILE_LOESCHEN else TitleTexts.LABEL_BACK


## Der Hinweis, den die gewählte Zeile von [param blatt] haben muss. Im Menü steht er im Eintrag;
## in der Liste setzt er sich aus TitleTexts zusammen, wie SaveList ihn bildet.
func _hinweis_der_zeile(blatt: Control) -> String:
	if blatt is MainMenu:
		var eintrag := (blatt as MainMenu).selected_entry()
		return eintrag.hint if eintrag != null else ""
	if not blatt is SaveList:
		return ""
	var liste := blatt as SaveList
	var loeschmodus := liste.is_delete_mode()
	var slot := liste.selected_slot()
	if slot == null:
		if gewaehlter_eintrag() == ZEILE_LOESCHEN:
			return TitleTexts.HINT_DELETE_MODE_ACTIVE if loeschmodus else TitleTexts.HINT_DELETE_MODE
		return TitleTexts.HINT_BACK_DELETE_MODE if loeschmodus else TitleTexts.HINT_BACK
	if loeschmodus:
		return TitleTexts.slot_delete_hint(slot.display_name())
	if not slot.can_resume():
		return slot.reason
	var gespielt := SaveGame.time_text(slot.game.last_played_at).split(" ")
	return TitleTexts.slot_hint(slot.game.day_text(), gespielt[0], gespielt[1])


## Die Namen der Spielstände im Ordner, für „Spielstände: …“.
func _namen() -> PackedStringArray:
	var namen := PackedStringArray()
	for slot in _session().store().list_slots():
		namen.append(slot.display_name())
	return namen


func _session() -> SESSION_SCRIPT:
	return (session if session != null else GameSession) as SESSION_SCRIPT


## Neue Knoten: Ein Communicator beginnt außerhalb der Endlage, ein Titel bekommt den
## quit_callback, der mitzählt. node_added kommt beim Eintritt in den Baum, vor _ready().
func _on_node_added(knoten: Node) -> void:
	if knoten is Communicator:
		var kennung := knoten.get_instance_id()
		_steht[kennung] = false
		knoten.slide_finished.connect(_on_slide_finished.bind(kennung))
		knoten.tree_exited.connect(_vergiss.bind(kennung))
	elif knoten is TitleScreen:
		var bildschirm := knoten as TitleScreen
		if not bildschirm.quit_callback.is_valid():
			bildschirm.quit_callback = _on_beenden


func _on_slide_finished(arrived_in: bool, kennung: int) -> void:
	_steht[kennung] = arrived_in


func _vergiss(kennung: int) -> void:
	_steht.erase(kennung)


func _on_beenden() -> void:
	_beenden += 1
