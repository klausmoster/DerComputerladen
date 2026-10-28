extends SelbsttestAblauf

## Ablauf „bedienung“ (contracts/ablaeufe.md, „bedienung“; FR-011, Punkt 6): Pfeiltasten und Tab
## wählen und laufen an den Enden um, Rechtsklick wählt ohne auszulösen, die Leertaste löst aus,
## Linksklick auf „Zurück“ führt zurück, das Mausrad rollt die Liste um eine ganze Zeile. Er beginnt
## beim frischen Titel ohne Spielstand.
##
## Für das Mausrad braucht die Liste mehr Spielstände, als sie zeigt. Schritt 06 legt deshalb als
## Vorbereitung sieben über SaveStore an und lädt den Titel neu, damit „Spiel laden“ verfügbar ist
## (CHK001; Analyse, U1). aufraeumen() löscht sie nach dem Ablauf wieder, auch wenn ein Schritt
## scheiterte.
##
## Schritte 01 und 02 merken sich nach jeder Taste die gewählte Zeile; die Prüfung vergleicht den
## ganzen Weg, nicht nur das Ende.

## So viele Spielstände legt 06 an: einer mehr als die Liste auf der Anzeige zeigt (5), und noch
## einer, damit nach dem Rollen auch unten mehr steht.
const SPIELSTAENDE := 7

## Die gewählten Zeilen nach jeder Taste von 01 und 02.
var _weg := PackedStringArray()


func _init() -> void:
	kennung = "bedienung"
	name = SelbsttestTexte.ablauf_name(kennung)


func schritte(fahrer: SelbsttestFahrer) -> Array[Dictionary]:
	var hauptmenue := SelbsttestFahrer.SEITE_HAUPTMENUE
	var gradwahl := SelbsttestFahrer.SEITE_GRADWAHL
	var mittel := Difficulty.label(Difficulty.Level.MITTEL)
	var spiel_2 := SaveGame.default_name(2)
	var angaben := SelbsttestTexte.angaben([mittel,
		str(GameDate.from_day_index(TimelineRun.FIRST_DAY))])
	var pfeile := [[KEY_DOWN, false], [KEY_UP, false], [KEY_UP, false], [KEY_UP, false]]
	var pfeile_weg := PackedStringArray([TitleTexts.LABEL_LOAD_GAME, TitleTexts.LABEL_NEW_GAME,
		TitleTexts.LABEL_CONTINUE, TitleTexts.LABEL_QUIT])
	var tab := [[KEY_TAB, false], [KEY_TAB, true]]
	var tab_weg := PackedStringArray([TitleTexts.LABEL_CONTINUE, TitleTexts.LABEL_QUIT])
	var beenden_steht := SelbsttestTexte.menue_steht(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_QUIT)
	return [
		neuer_schritt("01_pfeile", SelbsttestTexte.BESCHREIBUNG_BEDIENUNG_PFEILE,
			SelbsttestTexte.eingaben([SelbsttestTexte.TASTE_PFEIL_RUNTER,
				SelbsttestTexte.TASTE_PFEIL_HOCH, SelbsttestTexte.TASTE_PFEIL_HOCH,
				SelbsttestTexte.TASTE_PFEIL_HOCH]),
			_tasten_mit_weg.bind(fahrer, pfeile),
			_pruefe_weg.bind(fahrer, pfeile_weg, &"quit"),
			SelbsttestTexte.zustaende([SelbsttestTexte.auswahl_wandert(pfeile_weg), beenden_steht])),
		neuer_schritt("02_tab", SelbsttestTexte.BESCHREIBUNG_BEDIENUNG_TAB,
			SelbsttestTexte.eingaben([SelbsttestTexte.TASTE_TAB,
				SelbsttestTexte.TASTE_UMSCHALT_TAB]),
			_tasten_mit_weg.bind(fahrer, tab),
			_pruefe_weg.bind(fahrer, tab_weg, &"quit"),
			SelbsttestTexte.zustaende([SelbsttestTexte.auswahl_wandert(tab_weg), beenden_steht])),
		neuer_schritt("03_rechtsklick",
			SelbsttestTexte.BESCHREIBUNG_BEDIENUNG_RECHTSKLICK % TitleTexts.LABEL_NEW_GAME,
			SelbsttestTexte.auf(SelbsttestTexte.RECHTSKLICK,
				SelbsttestTexte.zitat(TitleTexts.LABEL_NEW_GAME)),
			fahrer.rechtsklick_auf_eintrag.bind(hauptmenue, &"new_game",
				SelbsttestTexte.ziel(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_NEW_GAME)),
			_pruefe_nichts_ausgeloest.bind(fahrer),
			SelbsttestTexte.zustaende([SelbsttestTexte.menue_steht(TitleTexts.HEADER_MAIN,
				TitleTexts.LABEL_NEW_GAME), SelbsttestTexte.NICHTS_AUSGELOEST])),
		neuer_schritt("04_leertaste",
			SelbsttestTexte.BESCHREIBUNG_BEDIENUNG_LEERTASTE % TitleTexts.LABEL_NEW_GAME,
			SelbsttestTexte.auf(SelbsttestTexte.TASTE_LEERTASTE,
				SelbsttestTexte.zitat(TitleTexts.LABEL_NEW_GAME)),
			fahrer.taste.bind(KEY_SPACE),
			_pruefe_menue.bind(fahrer, gradwahl, &"medium"),
			SelbsttestTexte.menue_steht_ohne_zeichen(TitleTexts.HEADER_DIFFICULTY, mittel)),
		neuer_schritt("05_zurueck_klick",
			SelbsttestTexte.BESCHREIBUNG_KLICK_INS_HAUPTMENUE % TitleTexts.LABEL_BACK,
			SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
				SelbsttestTexte.zitat(TitleTexts.LABEL_BACK)),
			fahrer.klick_auf_eintrag.bind(gradwahl, &"back",
				SelbsttestTexte.ziel(TitleTexts.HEADER_DIFFICULTY, TitleTexts.LABEL_BACK)),
			_pruefe_menue.bind(fahrer, hauptmenue, &"new_game"),
			SelbsttestTexte.menue_steht(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_NEW_GAME)),
		neuer_schritt("06_mausrad", SelbsttestTexte.BESCHREIBUNG_BEDIENUNG_MAUSRAD,
			SelbsttestTexte.vorbereitung(SelbsttestTexte.spielstaende_anzahl(SPIELSTAENDE),
				SelbsttestTexte.eingaben([SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
					SelbsttestTexte.zitat(TitleTexts.LABEL_LOAD_GAME)),
					SelbsttestTexte.ueber(SelbsttestTexte.MAUSRAD_RUNTER,
						SaveGame.default_name(1))])),
			_nacheinander.bind([fahrer.lege_spielstaende_an.bind(SPIELSTAENDE),
				fahrer.lade_titel_neu,
				fahrer.klick_auf_eintrag.bind(hauptmenue, &"load_game",
					SelbsttestTexte.ziel(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_LOAD_GAME)),
				fahrer.mausrad_auf_zeile.bind(1, MOUSE_BUTTON_WHEEL_DOWN,
					SelbsttestTexte.ziel_ohne_zeichen(TitleTexts.HEADER_SAVES,
						SaveGame.default_name(1)))]),
			_pruefe_gerollt.bind(fahrer, spiel_2, angaben),
			SelbsttestTexte.zustaende([SelbsttestTexte.liste_oben(spiel_2, true),
				SelbsttestTexte.menue_steht_ohne_zeichen(TitleTexts.HEADER_SAVES,
					SelbsttestTexte.zeile_mit_angaben(spiel_2, angaben))])),
	]


## Die Spielstände aus 06 kommen wieder weg, ob der Schritt gelang oder nicht.
func aufraeumen(fahrer: SelbsttestFahrer) -> void:
	fahrer.raeume_spielstaende_weg()


## 01 und 02, Eingaben: [param tasten] als Paare [Taste, mit Umschalt]; nach jeder merkt sich der
## Ablauf die gewählte Zeile.
func _tasten_mit_weg(fahrer: SelbsttestFahrer, tasten: Array) -> String:
	_weg.clear()
	for paar: Array in tasten:
		await fahrer.taste(paar[0], paar[1])
		_weg.append(fahrer.gewaehlter_text())
	return ""


## 01 und 02: Die Auswahl ging den Weg [param weg] und steht am Ende auf [param ende] im Hauptmenü.
func _pruefe_weg(fahrer: SelbsttestFahrer, weg: PackedStringArray, ende: StringName) -> String:
	if _weg == weg and fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, ende):
		return ""
	return SelbsttestTexte.zustaende([SelbsttestTexte.auswahl_wandert(_weg), fahrer.zustand()])


## 03: Menü steht: HAUPTMENÜ, „Neues Spiel“; nichts ausgelöst, also weiter das Hauptmenü, kein
## Spielstand und kein Beenden.
func _pruefe_nichts_ausgeloest(fahrer: SelbsttestFahrer) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"new_game") \
			and fahrer.beenden_ausgeloest() == 0 and fahrer.spielstaende().is_empty():
		return ""
	return fahrer.zustand()


## 06: Liste oben bei [param oben], Rollmarke oben sichtbar; die Auswahl rückt mit auf [param oben]
## mit seinen [param angaben].
func _pruefe_gerollt(fahrer: SelbsttestFahrer, oben: String, angaben: String) -> String:
	if fahrer.liste_oben() == oben and fahrer.marke_oben() \
			and fahrer.menue_steht(SelbsttestFahrer.SEITE_SPIELSTAENDE, &"slot_2") \
			and fahrer.kopfzeile() == TitleTexts.HEADER_SAVES and fahrer.zeile_angaben() == angaben:
		return ""
	if fahrer.liste_oben().is_empty():
		return fahrer.zustand()
	return SelbsttestTexte.zustaende([SelbsttestTexte.liste_oben(fahrer.liste_oben(),
		fahrer.marke_oben()), fahrer.zustand()])
