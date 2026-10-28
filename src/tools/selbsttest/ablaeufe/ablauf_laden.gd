extends SelbsttestAblauf

## Ablauf „laden“, Name „Spiel laden“ (contracts/ablaeufe.md, „laden“; FR-011, Punkt 3): Spiel 1
## lässt sich fortsetzen, erst mit „Weiterspielen“, dann aus der Liste der Spielstände; dazwischen
## und danach führt „Zum Hauptmenü“ zurück zum Titel, einmal mit Enter, einmal mit Linksklick. Die
## Liste zeigt die Zeile mit Grad und Spieldatum.
##
## Er baut auf „neues_spiel“ auf: Er beginnt nicht beim frischen Titel, sondern dort, wo jener
## endete, im Hauptmenü auf „Weiterspielen“ mit Spiel 1 im Ordner. Scheitert „neues_spiel“, läuft
## dieser Ablauf nicht (FR-009). Wortlaute wie in ablauf_neues_spiel.gd.


func _init() -> void:
	kennung = "laden"
	name = SelbsttestTexte.ablauf_name(kennung)
	baut_auf = "neues_spiel"


func schritte(fahrer: SelbsttestFahrer) -> Array[Dictionary]:
	var hauptmenue := SelbsttestFahrer.SEITE_HAUPTMENUE
	var spiel_1 := SaveGame.default_name(1)
	var angaben := SelbsttestTexte.angaben([Difficulty.label(Difficulty.Level.MITTEL),
		str(GameDate.from_day_index(TimelineRun.FIRST_DAY))])
	var spielbildschirm := SelbsttestTexte.spielbildschirm(TitleTexts.leave_hint(spiel_1))
	var weiterspielen := SelbsttestTexte.menue_steht(TitleTexts.HEADER_MAIN,
		TitleTexts.LABEL_CONTINUE)
	var knopf := SelbsttestTexte.ziel(SelbsttestTexte.ZIEL_SPIELBILDSCHIRM, TitleTexts.LABEL_LEAVE)
	return [
		neuer_schritt("01_weiterspielen",
			SelbsttestTexte.BESCHREIBUNG_LADEN_WEITERSPIELEN % [TitleTexts.LABEL_CONTINUE, spiel_1],
			SelbsttestTexte.auf(SelbsttestTexte.TASTE_ENTER,
				SelbsttestTexte.zitat(TitleTexts.LABEL_CONTINUE)),
			fahrer.taste.bind(KEY_ENTER),
			_pruefe_spielbildschirm.bind(fahrer, spiel_1),
			spielbildschirm),
		neuer_schritt("02_zurueck",
			SelbsttestTexte.BESCHREIBUNG_LADEN_ZURUECK % TitleTexts.LABEL_LEAVE,
			SelbsttestTexte.auf(SelbsttestTexte.TASTE_ENTER,
				SelbsttestTexte.zitat(TitleTexts.LABEL_LEAVE)),
			fahrer.taste.bind(KEY_ENTER),
			_pruefe_menue.bind(fahrer, hauptmenue, &"continue"),
			weiterspielen),
		neuer_schritt("03_liste",
			SelbsttestTexte.BESCHREIBUNG_LADEN_LISTE % TitleTexts.LABEL_LOAD_GAME,
			SelbsttestTexte.eingaben([SelbsttestTexte.bis(SelbsttestTexte.TASTE_PFEIL_RUNTER,
				SelbsttestTexte.zitat(TitleTexts.LABEL_LOAD_GAME)), SelbsttestTexte.TASTE_ENTER]),
			_nacheinander.bind([fahrer.pfeil_runter_bis.bind(hauptmenue, &"load_game",
				SelbsttestTexte.ziel(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_LOAD_GAME)),
				fahrer.taste.bind(KEY_ENTER)]),
			_pruefe_liste.bind(fahrer, angaben),
			SelbsttestTexte.menue_steht_ohne_zeichen(TitleTexts.HEADER_SAVES,
				SelbsttestTexte.zeile_mit_angaben(spiel_1, angaben))),
		neuer_schritt("04_zeile", SelbsttestTexte.BESCHREIBUNG_LADEN_ZEILE % spiel_1,
			SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK, spiel_1),
			fahrer.klick_auf_zeile.bind(1,
				SelbsttestTexte.ziel_ohne_zeichen(TitleTexts.HEADER_SAVES, spiel_1)),
			_pruefe_spielbildschirm.bind(fahrer, spiel_1),
			spielbildschirm),
		neuer_schritt("05_zurueck_2",
			SelbsttestTexte.BESCHREIBUNG_LADEN_ZURUECK_2 % TitleTexts.LABEL_LEAVE,
			SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
				SelbsttestTexte.zitat(TitleTexts.LABEL_LEAVE)),
			fahrer.klick_auf_knopf_hauptmenue.bind(knopf),
			_pruefe_menue.bind(fahrer, hauptmenue, &"continue"),
			weiterspielen),
	]


## 01 und 04: Spielbildschirm steht mit [param spiel]; sein Hinweis nennt es.
func _pruefe_spielbildschirm(fahrer: SelbsttestFahrer, spiel: String) -> String:
	return "" if fahrer.spielbildschirm_steht(spiel) else fahrer.zustand()


## 03: Menü steht: SPIELSTÄNDE, Spiel 1, und seine Zeile zeigt [param angaben], Grad und
## Spieldatum. Die Kopfzeile zählt mit: Im Löschmodus hieße sie anders.
func _pruefe_liste(fahrer: SelbsttestFahrer, angaben: String) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_SPIELSTAENDE, &"slot_1") \
			and fahrer.kopfzeile() == TitleTexts.HEADER_SAVES and fahrer.zeile_angaben() == angaben:
		return ""
	return fahrer.zustand()
