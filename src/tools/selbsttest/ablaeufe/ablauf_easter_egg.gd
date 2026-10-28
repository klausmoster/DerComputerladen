extends SelbsttestAblauf

## Ablauf „easter_egg“ (contracts/ablaeufe.md, „easter_egg“; FR-011, Punkt 5): Im Hauptmenü steht
## „Spiel laden“; die Gehäusetasten in falscher Folge starten nichts, links, Mitte, rechts starten
## das versteckte Spiel. Die Kanone fährt nach rechts und schießt, Esc beendet das Spiel, und
## Hauptmenü, Zeile und Hinweis stehen wieder wie vorher. Er beginnt beim frischen Titel, also ohne
## Spielstand: „Spiel laden“ ist dann nicht verfügbar, lässt sich aber wählen.
##
## Das Spiel rechnet nach vergangener Zeit; die Fotos von 03 und 04 hängen deshalb von der Bildrate
## ab und sind nicht vergleichbar (R7). Geprüft wird dort der Zustand.

## Die Gehäusetasten von links ab 0: die falsche Folge (02) und die richtige (03).
const FALSCHE_FOLGE: Array[int] = [1, 0, 2]
const RICHTIGE_FOLGE: Array[int] = [0, 1, 2]
## So lange hält 04 Pfeil rechts, in echter Zeit (R24).
const HALTEN_MS := 500

## Wo die Kanone vor dem Halten stand; 04 vergleicht damit.
var _kanone_beim_start := -1


func _init() -> void:
	kennung = "easter_egg"
	name = SelbsttestTexte.ablauf_name(kennung)


func schritte(fahrer: SelbsttestFahrer) -> Array[Dictionary]:
	var hauptmenue := SelbsttestFahrer.SEITE_HAUPTMENUE
	var invaders := String(SelbsttestFahrer.SEITE_INVADERS)
	var spiel_laden := "%s, %s" % [SelbsttestTexte.menue_steht(TitleTexts.HEADER_MAIN,
		TitleTexts.LABEL_LOAD_GAME), SelbsttestTexte.NICHT_VERFUEGBAR]
	return [
		neuer_schritt("01_auswahl",
			SelbsttestTexte.BESCHREIBUNG_EASTER_EGG_AUSWAHL % TitleTexts.LABEL_LOAD_GAME,
			SelbsttestTexte.bis(SelbsttestTexte.TASTE_PFEIL_RUNTER,
				SelbsttestTexte.zitat(TitleTexts.LABEL_LOAD_GAME)),
			fahrer.pfeil_runter_bis.bind(hauptmenue, &"load_game",
				SelbsttestTexte.ziel(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_LOAD_GAME)),
			_pruefe_menue.bind(fahrer, hauptmenue, &"load_game"),
			spiel_laden),
		neuer_schritt("02_falsche_folge", SelbsttestTexte.BESCHREIBUNG_EASTER_EGG_FALSCHE_FOLGE,
			SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
				SelbsttestTexte.gehaeusetasten(FALSCHE_FOLGE)),
			fahrer.klick_auf_gehaeusetasten.bind(FALSCHE_FOLGE),
			_pruefe_nicht_gestartet.bind(fahrer),
			"%s, %s" % [SelbsttestTexte.ZUSTAND_SEITE_NICHT_SICHTBAR % invaders, spiel_laden]),
		neuer_schritt("03_start", SelbsttestTexte.BESCHREIBUNG_EASTER_EGG_START,
			SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
				SelbsttestTexte.gehaeusetasten(RICHTIGE_FOLGE)),
			fahrer.klick_auf_gehaeusetasten.bind(RICHTIGE_FOLGE),
			_pruefe_gestartet.bind(fahrer),
			"%s, %s" % [SelbsttestTexte.ZUSTAND_SEITE_AKTIV % invaders,
				SelbsttestTexte.ZUSTAND_KEIN_HINWEIS],
			false),
		neuer_schritt("04_spielen", SelbsttestTexte.BESCHREIBUNG_EASTER_EGG_SPIELEN,
			SelbsttestTexte.eingaben([SelbsttestTexte.halten(SelbsttestTexte.TASTE_PFEIL_RECHTS,
				HALTEN_MS), SelbsttestTexte.TASTE_LEERTASTE]),
			_fahren_und_schiessen.bind(fahrer),
			_pruefe_gespielt.bind(fahrer),
			SelbsttestTexte.kanone_und_schuss(),
			false),
		neuer_schritt("05_ende_esc",
			SelbsttestTexte.BESCHREIBUNG_EASTER_EGG_ENDE_ESC % TitleTexts.LABEL_LOAD_GAME,
			SelbsttestTexte.TASTE_ESC,
			fahrer.taste.bind(KEY_ESCAPE),
			_pruefe_zurueck.bind(fahrer),
			SelbsttestTexte.zustaende(["%s, %s" % [spiel_laden,
				SelbsttestTexte.hinweis(TitleTexts.HINT_LOAD_GAME_NO_SAVES)],
				SelbsttestTexte.spielstaende([])])),
	]


## 02: Seite Invaders nicht sichtbar, Menü steht: HAUPTMENÜ, „Spiel laden“, nicht verfügbar. Der
## Befund beginnt wie die Erwartung, solange das Spiel nicht zu sehen ist.
func _pruefe_nicht_gestartet(fahrer: SelbsttestFahrer) -> String:
	if fahrer.invaders() != null:
		return fahrer.zustand()
	var nicht_sichtbar := SelbsttestTexte.ZUSTAND_SEITE_NICHT_SICHTBAR \
		% SelbsttestFahrer.SEITE_INVADERS
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"load_game") \
			and not fahrer.gewaehlt_verfuegbar():
		return ""
	return "%s, %s" % [nicht_sichtbar, fahrer.zustand()]


## 03: Seite Invaders sichtbar und aktiv, Hinweis aus.
func _pruefe_gestartet(fahrer: SelbsttestFahrer) -> String:
	if fahrer.invaders_aktiv() and fahrer.hinweis_text().is_empty():
		return ""
	return fahrer.zustand()


## 04, Eingaben: merkt sich, wo die Kanone steht, hält Pfeil rechts und drückt die Leertaste.
func _fahren_und_schiessen(fahrer: SelbsttestFahrer) -> String:
	_kanone_beim_start = fahrer.kanone_x()
	await fahrer.taste_halten(KEY_RIGHT, HALTEN_MS)
	return await fahrer.taste(KEY_SPACE)


## 04: Kanone weiter rechts als beim Start; ein Schuss unterwegs oder ein Treffer gezählt. Der
## Befund nennt beides in derselben Form, dahinter den Zustand der Seite.
func _pruefe_gespielt(fahrer: SelbsttestFahrer) -> String:
	var rechts := fahrer.kanone_x() > _kanone_beim_start
	var schuss := fahrer.schuss_unterwegs()
	var treffer := fahrer.treffer() > 0
	if rechts and (schuss or treffer) and fahrer.invaders_aktiv():
		return ""
	var kanone := SelbsttestTexte.ZUSTAND_KANONE_RECHTS if rechts \
		else SelbsttestTexte.ZUSTAND_KANONE_NICHT_RECHTS
	var feuer := SelbsttestTexte.ZUSTAND_SCHUSS if schuss \
		else SelbsttestTexte.ZUSTAND_TREFFER if treffer else SelbsttestTexte.ZUSTAND_KEIN_SCHUSS
	return SelbsttestTexte.zustaende([kanone, feuer, fahrer.zustand()])


## 05: Menü steht: HAUPTMENÜ, „Spiel laden“, nicht verfügbar, mit seinem Hinweis; Spielstände:
## keine.
func _pruefe_zurueck(fahrer: SelbsttestFahrer) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"load_game") \
			and not fahrer.gewaehlt_verfuegbar() \
			and fahrer.hinweis_text() == TitleTexts.HINT_LOAD_GAME_NO_SAVES \
			and fahrer.spielstaende().is_empty():
		return ""
	return fahrer.zustand()
