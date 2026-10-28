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
## Knoten der Szenen unter ihren Namen (Communicator/Hint, Rows, LeaveButton, Keys/CaseKey0, die
## Spalten einer Zeile der Liste wie Difficulty und Day). Am Spiel ändert er nichts.
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
##
## Ob der Communicator vor dem Spielbildschirm hinausgefahren ist, merkt sich der Fahrer ebenfalls
## über slide_finished; der Titel ist danach weg, die Antwort bleibt bis zum nächsten Communicator.
##
## Vorbereitungen, die nicht über Eingaben gehen (CHK001), macht auch der Fahrer: Spielstände über
## SaveStore anlegen, den Titel neu laden, ein Spiel mit Grad und Seed beginnen, das Fenster auf
## eine Größe stellen. Was er anlegt, räumt er mit raeume_spielstaende_weg() wieder weg.

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

## Der Knoten des versteckten Spiels unter dem Communicator heißt SEITE_INVADERS; seine Partie
## kennt so viele Außerirdische (InvadersGame).
const AUSSERIRDISCHE := InvadersGame.COLUMNS * InvadersGame.ROWS
## Szenen, zu denen lade_titel_neu() und starte_spiel() wechseln.
const TITEL := "res://scenes/title/title_screen.tscn"
const SPIELBILDSCHIRM := "res://scenes/game/game_screen.tscn"
## Seed der Spielstände, die lege_spielstaende_an() anlegt, wie im ganzen Selbsttest (R7).
const SEED_SPIELSTAENDE := 4711
## Für stelle_fenster(): die Lage bleibt, wie sie ist.
const LAGE_BLEIBT := Vector2i(-1000000, -1000000)

## GameSession und GameWindow haben als Autoload keinen class_name; den Typ gibt ihr Skript.
const SESSION_SCRIPT := preload("res://core/game_session.gd")
const FENSTER_SCRIPT := preload("res://core/game_window.gd")

## Über sie schicken die Abläufe ihre Eingaben.
var eingabe: SelbsttestEingabe = null
## null heißt das Autoload GameSession; Tests setzen eine eigene.
var session: Node = null
## Der Bildschirm, den der Fahrer ansieht; null heißt die laufende Szene. Tests setzen ihren Titel
## in einem eigenen Viewport.
var szene: Node = null
## Wechselt die Szene und bekommt den Pfad; ungültig heißt SceneTree.change_scene_to_file(). Tests
## setzen einen eigenen Wechsel, wie scene_callback im Titel.
var szenenwechsel: Callable

var _baum: SceneTree
## Kennung eines Communicators → ob er nach seiner letzten Fahrt in der Endlage steht.
var _steht: Dictionary = {}
var _beenden := 0
## Ob der zuletzt erschienene Communicator seine letzte Fahrt draußen beendet hat.
var _hinausgefahren := false
## Die Nummern der Spielstände, die lege_spielstaende_an() angelegt hat.
var _angelegt := PackedInt32Array()


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


## Die Kopfzeile der sichtbaren Seite, wie sie dasteht, etwa „WELCHES LÖSCHEN?“ im Löschmodus der
## Liste; leer ohne sichtbare Seite.
func kopfzeile() -> String:
	var blatt := sichtbare_seite()
	return _kopf(blatt) if blatt != null else ""


## Ob der zuletzt erschienene Communicator hinausgefahren ist: Seine letzte Fahrt endete draußen.
## Das bleibt so, auch wenn er danach mit dem Titel verschwindet; erst ein neuer Communicator
## beginnt wieder bei false.
func hinausgefahren() -> bool:
	return _hinausgefahren


## Der Name des laufenden Spiels, etwa „Spiel 1“; leer, wenn keins läuft.
func laufendes_spiel() -> String:
	var spiel := _session().current
	return spiel.name if spiel != null else ""


## Ob der Spielbildschirm steht (contracts/ablaeufe.md, „Gemeinsame Prüfungen“): Er ist die
## laufende Szene, „Zum Hauptmenü“ hat den Fokus, und der Hinweis nennt [param spiel], etwa
## „Spiel 1“.
func spielbildschirm_steht(spiel: String) -> bool:
	return spielbildschirm() != null and gewaehlter_eintrag() == KNOPF_HAUPTMENUE \
		and not spiel.is_empty() and hinweis_text() == TitleTexts.leave_hint(spiel)


## Was die gewählte Zeile der Liste in den Spalten Grad und Spieldatum zeigt, wie es dasteht:
## „Mittel, 01.01.1985“, bei einem Spielstand, der sich nicht fortsetzen lässt, sein Zustand. Leer,
## wenn keine Zeile mit Spielstand gewählt ist.
func zeile_angaben() -> String:
	var liste := sichtbare_seite() as SaveList
	if liste == null or not String(gewaehlter_eintrag()).begins_with("slot_"):
		return ""
	var knopf := liste.get_viewport().gui_get_focus_owner()
	var teile := PackedStringArray()
	for zelle: StringName in [&"Difficulty", &"Day", &"State"]:
		var feld := knopf.get_node_or_null(NodePath(String(zelle))) as Label
		if feld != null and feld.visible and not feld.text.is_empty():
			teile.append(feld.text)
	return SelbsttestTexte.angaben(teile)


## Der Text der gewählten Zeile, wie er dasteht, etwa „Neues Spiel“; leer ohne gewählte Zeile.
func gewaehlter_text() -> String:
	var blatt := sichtbare_seite()
	if blatt == null or not (blatt is MainMenu or blatt is SaveList):
		return ""
	return _zeile_text(blatt)


## Der Spielstand in der obersten Zeile der Liste, wie er dasteht, etwa „Spiel 2“; leer ohne Liste.
func liste_oben() -> String:
	var liste := _seite(SEITE_SPIELSTAENDE)
	if liste == null:
		return ""
	for knopf in _knoepfe(liste):
		var name_feld := knopf.get_node_or_null(^"Name") as Label
		if name_feld != null and knopf.is_visible_in_tree():
			return name_feld.text
	return ""


## Ob über der Liste die Rollmarke oben steht.
func marke_oben() -> bool:
	var liste := _seite(SEITE_SPIELSTAENDE) as SaveList
	return liste != null and liste.shows_scroll_mark_above()


## Das versteckte Spiel, wenn es die sichtbare Seite ist; sonst null.
func invaders() -> InvadersPage:
	return sichtbare_seite() as InvadersPage


## Ob das versteckte Spiel aktiv ist: sichtbar, mit dem Fokus und einer Partie, die noch läuft.
func invaders_aktiv() -> bool:
	var seite := invaders()
	if seite == null or seite.game() == null or not seite.has_focus():
		return false
	return seite.game().state in [InvadersGame.State.PLAYING, InvadersGame.State.RESPAWN]


## Wo die Kanone steht, in Pixeln des Spielfelds; -1 ohne Partie.
func kanone_x() -> int:
	var seite := invaders()
	return seite.game().cannon_x if seite != null and seite.game() != null else -1


## Ob ein Schuss der Kanone unterwegs ist.
func schuss_unterwegs() -> bool:
	var seite := invaders()
	if seite == null or seite.game() == null:
		return false
	for teil in seite.game().drawables():
		if teil["sprite"] == &"shot":
			return true
	return false


## Wie viele Außerirdische getroffen sind.
func treffer() -> int:
	var seite := invaders()
	if seite == null or seite.game() == null:
		return 0
	return AUSSERIRDISCHE - seite.game().aliens_left()


## Das Fenster des Spiels: die Wurzel des Baums.
func fenster() -> Window:
	return _baum.root


## Der größte ganzzahlige Faktor, mit dem das Raster samt Fensterrahmen in den nutzbaren Bereich
## des Bildschirms passt, auf dem das Fenster liegt; gerechnet mit GameWindow.best_factor() (R16).
func bester_faktor() -> int:
	var id := fenster().get_window_id()
	var bildschirm := DisplayServer.window_get_current_screen(id)
	var nutzbar := DisplayServer.screen_get_usable_rect(bildschirm).size
	var rahmen := DisplayServer.window_get_size_with_decorations(id) - fenster().size
	return FENSTER_SCRIPT.best_factor(nutzbar, rahmen)


## Wie weit das Fenster samt Titelleiste neben der Mitte des nutzbaren Bereichs seines Bildschirms
## liegt, ohne Menüleiste und Dock, in Pixeln; Vector2i.ZERO heißt genau mittig (Klaus, Phase 3).
## Gerechnet aus dem Rahmen, unabhängig davon, wie GameWindow das Fenster hinstellt.
func fenster_versatz() -> Vector2i:
	var id := fenster().get_window_id()
	var nutzbar := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen(id))
	var rahmen := Rect2i(DisplayServer.window_get_position_with_decorations(id),
		DisplayServer.window_get_size_with_decorations(id))
	return versatz_zur_mitte(nutzbar, rahmen)


## Wie weit [param rahmen] neben der Mitte von [param nutzbar] liegt; ohne Fenster prüfbar. Die
## Mitte der beiden Rechtecke wird verglichen, deshalb kann ein halbes Pixel Rest übrig bleiben.
static func versatz_zur_mitte(nutzbar: Rect2i, rahmen: Rect2i) -> Vector2i:
	return Vector2i((Vector2(rahmen.get_center()) - Vector2(nutzbar.get_center())).round())


## Die Lage des Fensters in der Form der Spalte „Erwartet“: „mittig im nutzbaren Bereich, auf
## 1 Pixel genau“ oder „12 Pixel rechts, 3 Pixel über der Mitte des nutzbaren Bereichs“.
func fenster_lage() -> String:
	return lage_text(fenster_versatz())


## Der Text zu fenster_lage() für den Versatz [param versatz] in Pixeln; ohne Fenster prüfbar.
static func lage_text(versatz: Vector2i) -> String:
	if absi(versatz.x) <= 1 and absi(versatz.y) <= 1:
		return SelbsttestTexte.ZUSTAND_LAGE_MITTIG
	return SelbsttestTexte.lage_daneben(versatz)


## Fenster und Bild in der Form der Spalte „Erwartet“ von „fenster“: „Fenster 640 × 360, Bild
## Faktor 1, ohne Rand“, bei einem Rand „Fenster 1318 × 742, Bild Faktor 2, mittig, Rand ringsum,
## ganze Pixel“. Das Bild liest der Fahrer aus get_final_transform() der Wurzel: Mit Stretch
## „viewport“ ist das die Vergrößerung und der Versatz, mit denen Godot das Raster 640 × 360 ins
## Fenster setzt; der Rest des Fensters ist Rand.
func fenster_zustand() -> String:
	return fenster_text(fenster().size, fenster().get_final_transform())


## Der Text zu fenster_zustand() für ein Fenster der Größe [param groesse], in das Godot das Raster
## mit [param bild] setzt; ohne Fenster prüfbar. Mittig heißt: links und rechts, oben und unten
## höchstens 1 Pixel verschieden.
static func fenster_text(groesse: Vector2i, bild: Transform2D) -> String:
	var faktor := bild.get_scale().x
	var ecke := bild.origin
	var flaeche := Vector2(FENSTER_SCRIPT.BASE_SIZE) * faktor
	var rand := [roundi(ecke.x), roundi(groesse.x - ecke.x - flaeche.x), roundi(ecke.y),
		roundi(groesse.y - ecke.y - flaeche.y)]
	var ganz := is_equal_approx(faktor, roundf(faktor)) and is_equal_approx(bild.get_scale().y,
		faktor) and is_equal_approx(ecke.x, roundf(ecke.x)) and is_equal_approx(ecke.y, roundf(ecke.y))
	var teile := PackedStringArray()
	if rand == [0, 0, 0, 0]:
		teile.append(SelbsttestTexte.ZUSTAND_OHNE_RAND)
		if not ganz:
			teile.append(SelbsttestTexte.ZUSTAND_KEINE_GANZEN_PIXEL)
	else:
		var mittig: bool = absi(rand[0] - rand[1]) <= 1 and absi(rand[2] - rand[3]) <= 1
		teile.append(SelbsttestTexte.ZUSTAND_MITTIG if mittig else SelbsttestTexte.ZUSTAND_NICHT_MITTIG)
		var ringsum: bool = rand.all(func(breite: int) -> bool: return breite > 0)
		teile.append(SelbsttestTexte.ZUSTAND_RAND_RINGSUM if ringsum \
			else SelbsttestTexte.ZUSTAND_RAND % rand)
		teile.append(SelbsttestTexte.ZUSTAND_GANZE_PIXEL if ganz \
			else SelbsttestTexte.ZUSTAND_KEINE_GANZEN_PIXEL)
	return SelbsttestTexte.fenster(groesse, faktor, teile)


## Die Nummern der Spielstände im Ordner der Session, in der Reihenfolge der Liste.
func spielstaende() -> PackedInt32Array:
	var nummern := PackedInt32Array()
	for slot in _session().store().list_slots():
		nummern.append(slot.number)
	return nummern


## Wie oft „Beenden“ im Titel ausgelöst hat, seit der Fahrer läuft.
func beenden_ausgeloest() -> int:
	return _beenden


## Ob die gewählte Zeile verfügbar ist, also auslösen kann: im Menü nach ihrem Eintrag, in der
## Liste nach ihrem Button, der gesperrt ist, wenn die Zeile nichts auslöst (etwa „Löschen …“ im
## Löschmodus). Ohne gewählte Zeile false.
func gewaehlt_verfuegbar() -> bool:
	var seite := sichtbare_seite()
	if seite == null or gewaehlter_eintrag().is_empty():
		return false
	if seite is MainMenu:
		return (seite as MainMenu).selected_entry().available
	var knopf := seite.get_viewport().gui_get_focus_owner() as Button
	return knopf != null and not knopf.disabled


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
		# „steht“ nur mit Fokus auf „Zum Hauptmenü“, wie die gemeinsame Prüfung es verlangt (B4).
		if gewaehlter_eintrag() == KNOPF_HAUPTMENUE:
			teile.append(SelbsttestTexte.spielbildschirm(hinweis_text()))
		else:
			teile.append(SelbsttestTexte.spielbildschirm_ohne_fokus(hinweis_text()))
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
# Alle mit await. Sie geben "" zurück, wenn die Eingaben hinaus sind, sonst den Text für
# „gefunden:“; dann ging nichts mehr hinaus, und der Schritt scheitert sofort.

## Fährt die Maus auf den Eintrag [param kennung] der Seite [param seite]. Gibt "" zurück, oder
## fehlt([param beschreibung]), wenn es ihn nicht gibt; dann geht keine Eingabe hinaus.
func maus_ueber_eintrag(seite: StringName, kennung: StringName, beschreibung: String) -> String:
	var ziel := ziel_eintrag(seite, kennung)
	if not ziel.has_area():
		return fehlt(beschreibung)
	await eingabe.maus_zu(ziel.get_center())
	return ""


## Linksklick auf den Eintrag [param kennung] der Seite [param seite], wie maus_ueber_eintrag().
func klick_auf_eintrag(seite: StringName, kennung: StringName, beschreibung: String) -> String:
	return await _klick(ziel_eintrag(seite, kennung), beschreibung)


## Linksklick auf die Zeile der Liste mit dem Spielstand [param nummer].
func klick_auf_zeile(nummer: int, beschreibung: String) -> String:
	return await _klick(ziel_zeile(nummer), beschreibung)


## Linksklick auf „Zum Hauptmenü“ im Spielbildschirm.
func klick_auf_knopf_hauptmenue(beschreibung: String) -> String:
	return await _klick(ziel_knopf_hauptmenue(), beschreibung)


## Drückt [param keycode], mit [param shift] zusammen mit Umschalt, und lässt im nächsten Bild
## los; die Taste geht an das Control mit dem Fokus.
func taste(keycode: Key, shift: bool = false) -> String:
	await eingabe.taste(keycode, shift)
	return ""


## Hält [param keycode] [param ms] Millisekunden echter Zeit.
func taste_halten(keycode: Key, ms: int) -> String:
	await eingabe.taste_halten(keycode, ms)
	return ""


## Rechtsklick auf den Eintrag [param kennung] der Seite [param seite].
func rechtsklick_auf_eintrag(seite: StringName, kennung: StringName, beschreibung: String) -> String:
	return await _klick(ziel_eintrag(seite, kennung), beschreibung, MOUSE_BUTTON_RIGHT)


## Linksklick nacheinander auf die Gehäusetasten in [param folge], Index von links ab 0. Fehlt
## eine, endet die Folge dort mit „Ziel nicht gefunden: Gehäusetaste rechts“.
func klick_auf_gehaeusetasten(folge: Array[int]) -> String:
	for index in folge:
		var antwort := await _klick(ziel_gehaeusetaste(index),
			SelbsttestTexte.gehaeusetaste(index))
		if not antwort.is_empty():
			return antwort
	return ""


## Dreht das Mausrad über der Zeile der Liste mit dem Spielstand [param nummer] um eine Raste.
func mausrad_auf_zeile(nummer: int, richtung: MouseButton, beschreibung: String) -> String:
	var ziel := ziel_zeile(nummer)
	if not ziel.has_area():
		return fehlt(beschreibung)
	await eingabe.rad(ziel.get_center(), richtung)
	return ""


# --- Vorbereitung ---------------------------------------------------------------------------------
# Was nicht über Eingaben geht (CHK001). Ebenfalls mit await und "" oder dem Text für „gefunden:“.

## Legt im Ordner der Session die Spielstände 1 bis [param anzahl] an, über SaveStore wie ein neues
## Spiel: Mittel, am ersten Tag, Seed SEED_SPIELSTAENDE, mit einer Kopie des Katalogs der Zeitleiste.
## „Zuletzt gespielt“ ist die feste Zeit der Session für Spiel 1 und je eine Stunde früher für jedes
## weitere; so steht Spiel 1 in der Liste oben. Gibt "" zurück oder den Grund von SaveStore in
## Anführungszeichen.
func lege_spielstaende_an(anzahl: int) -> String:
	var sitzung := _session()
	var zeit: int = sitzung.now.call()
	var zeitleiste: Node = sitzung.timeline if sitzung.timeline != null else Timeline
	var katalog: EventCatalog = zeitleiste.get(&"catalog")
	var speicher := sitzung.store()
	for nummer in range(1, anzahl + 1):
		var spiel := SaveGame.new()
		spiel.number = nummer
		spiel.name = SaveGame.default_name(nummer)
		spiel.difficulty = Difficulty.Level.MITTEL
		spiel.seed = SEED_SPIELSTAENDE
		spiel.day = TimelineRun.FIRST_DAY
		spiel.created_at = zeit - (nummer - 1) * 3600
		spiel.last_played_at = spiel.created_at
		spiel.game_version = str(ProjectSettings.get_setting("application/config/version", ""))
		spiel.catalog = katalog.duplicate_catalog() if katalog != null else EventCatalog.new()
		if speicher.write(spiel, true) != OK:
			return SelbsttestTexte.meldung_des_spiels(speicher.last_error)
		_angelegt.append(nummer)
	return ""


## Löscht über SaveStore die Spielstände, die lege_spielstaende_an() angelegt hat, und nur die.
func raeume_spielstaende_weg() -> void:
	var speicher := _session().store()
	for nummer in _angelegt:
		speicher.delete(nummer)
	_angelegt.clear()


## Lädt den Titel neu, wie nach „Zum Hauptmenü“, und wartet, bis sein Hauptmenü steht, höchstens
## SelbsttestAblauf.HOECHSTZEIT_MS echter Zeit. Gibt "" zurück oder den Zustand, in dem es stehen
## blieb.
func lade_titel_neu() -> String:
	var alt := _szene()
	var alt_id := alt.get_instance_id() if alt != null else 0
	_wechsle(TITEL)
	var frist := Time.get_ticks_msec() + SelbsttestAblauf.HOECHSTZEIT_MS
	while true:
		var neu := titel()
		if neu != null and neu.get_instance_id() != alt_id and communicator_steht() \
				and not gewaehlter_eintrag().is_empty():
			return ""
		if Time.get_ticks_msec() >= frist:
			return zustand()
		await _baum.process_frame
	return ""


## Beginnt über die Session ein Spiel mit [param grad] und [param p_seed] und wechselt zum
## Spielbildschirm, wie der Titel es nach der Fahrt hinaus tut; für den Start eines Szenarios
## (R27). Die Oberfläche kann keinen Seed wählen, deshalb ist das eine Vorbereitung.
func starte_spiel(grad: Difficulty.Level, p_seed: int) -> String:
	var sitzung := _session()
	if sitzung.start_new(grad, p_seed) != OK:
		return SelbsttestTexte.meldung_des_spiels(sitzung.last_error)
	_wechsle(SPIELBILDSCHIRM)
	var frist := Time.get_ticks_msec() + SelbsttestAblauf.HOECHSTZEIT_MS
	while spielbildschirm() == null:
		if Time.get_ticks_msec() >= frist:
			return zustand()
		await _baum.process_frame
	return ""


## Lässt die Spieluhr über die Bedienung des Spielbildschirms im Zeitraffer bis [param _datum]
## laufen. Die Bedienung gibt es noch nicht; bis dahin meldet der Fahrer das, und der Schritt
## scheitert (R27). Das erste Feature mit Bedienung der Uhr baut es hier ein.
func uhr_bis(_datum: GameDate) -> String:
	return SelbsttestTexte.UHR_NICHT_BEDIENBAR


## Stellt das Fenster auf [param groesse] und, wenn angegeben, an [param lage], beide in
## Bildschirmpixeln. Nicht über Eingaben: Größe ziehen ist Sache des Systems (R16). Wartet ein
## Bild, damit Godot die neue Größe übernimmt.
func stelle_fenster(groesse: Vector2i, lage: Vector2i = LAGE_BLEIBT) -> String:
	fenster().size = groesse
	if lage != LAGE_BLEIBT:
		fenster().position = lage
	await _baum.process_frame
	return ""


## Drückt Pfeil runter, bis auf [param seite] der Eintrag [param kennung] gewählt ist, höchstens
## einmal je Zeile. Fehlt der Eintrag, fehlt([param beschreibung]); kommt die Auswahl nicht dort
## an, der Zustand, in dem sie stehen blieb.
func pfeil_runter_bis(seite: StringName, kennung: StringName, beschreibung: String) -> String:
	var blatt := _seite(seite)
	if blatt == null or not ziel_eintrag(seite, kennung).has_area():
		return fehlt(beschreibung)
	for versuch in _knoepfe(blatt).size():
		if gewaehlter_eintrag() == kennung:
			return ""
		await eingabe.taste(KEY_DOWN)
	return "" if gewaehlter_eintrag() == kennung else zustand()


# --- Intern ---------------------------------------------------------------------------------------

## Klick mit [param taste] auf die Mitte von [param ziel]; leer heißt fehlt([param beschreibung]).
func _klick(ziel: Rect2, beschreibung: String, taste: MouseButton = MOUSE_BUTTON_LEFT) -> String:
	if not ziel.has_area():
		return fehlt(beschreibung)
	await eingabe.klick(ziel.get_center(), taste)
	return ""


## Wechselt zur Szene [param pfad], über szenenwechsel, ohne ihn mit change_scene_to_file().
func _wechsle(pfad: String) -> void:
	if szenenwechsel.is_valid():
		szenenwechsel.call(pfad)
	else:
		_baum.change_scene_to_file(pfad)


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
## Spielstände ohne Anführungszeichen, wie in der Spalte „Erwartet“ (CHK031), ein Spielstand mit
## dem, was seine Zeile in Grad und Spieldatum zeigt: „SPIELSTÄNDE, Spiel 1 mit Mittel,
## 01.01.1985“. Ist die gewählte Zeile nicht verfügbar, im Menü wie in der Liste, steht „nicht
## verfügbar“ zwischen Zeile und Hinweis („Verfügbarkeit“ im Vertrag). Hat keine Zeile den Fokus,
## „Seite HAUPTMENÜ, keine Zeile gewählt, …“. Das versteckte Spiel hat keine Kopfzeile und heißt
## nach seinem Knoten: „Seite Invaders sichtbar und aktiv, Hinweis aus“.
func _seite_text() -> String:
	var blatt := sichtbare_seite()
	if blatt == null:
		return SelbsttestTexte.ZUSTAND_KEINE_SEITE
	if blatt is InvadersPage:
		var seite := SelbsttestTexte.ZUSTAND_SEITE_AKTIV if invaders_aktiv() \
			else SelbsttestTexte.ZUSTAND_SEITE_NICHT_AKTIV
		return "%s, %s" % [seite % blatt.name, SelbsttestTexte.hinweis(hinweis_text())]
	if not (blatt is MainMenu or blatt is SaveList):
		return "%s, %s" % [SelbsttestTexte.ZUSTAND_SEITE % blatt.name,
			SelbsttestTexte.hinweis(hinweis_text())]
	var kopf := _kopf(blatt)
	var zeile := _zeile_text(blatt)
	var text: String
	if zeile.is_empty():
		text = SelbsttestTexte.seite_ohne_zeile(kopf)
	elif _ohne_zeichen(blatt, gewaehlter_eintrag()):
		text = SelbsttestTexte.menue_steht_ohne_zeichen(kopf, zeile)
	else:
		text = SelbsttestTexte.menue_steht(kopf, zeile)
	if not zeile.is_empty() and not gewaehlt_verfuegbar():
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


## Der Text der Zeile mit dem Fokus, wie er dasteht; ein Spielstand mit seinen Angaben. Leer ohne
## Fokus.
func _zeile_text(blatt: Control) -> String:
	var kennung := gewaehlter_eintrag()
	if kennung.is_empty():
		return ""
	if blatt is MainMenu:
		return (blatt as MainMenu).selected_entry().label
	var slot := (blatt as SaveList).selected_slot()
	if slot != null:
		return SelbsttestTexte.zeile_mit_angaben(slot.display_name(), zeile_angaben())
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
		_hinausgefahren = false
		knoten.slide_finished.connect(_on_slide_finished.bind(kennung))
		knoten.tree_exited.connect(_vergiss.bind(kennung))
	elif knoten is TitleScreen:
		var bildschirm := knoten as TitleScreen
		if not bildschirm.quit_callback.is_valid():
			bildschirm.quit_callback = _on_beenden


func _on_slide_finished(arrived_in: bool, kennung: int) -> void:
	_steht[kennung] = arrived_in
	_hinausgefahren = not arrived_in


func _vergiss(kennung: int) -> void:
	_steht.erase(kennung)


func _on_beenden() -> void:
	_beenden += 1
