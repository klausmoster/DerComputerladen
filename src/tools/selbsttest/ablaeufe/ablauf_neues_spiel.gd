extends SelbsttestAblauf

## Ablauf „neues_spiel“ (contracts/ablaeufe.md, „neues_spiel“; FR-011, Punkt 2): Die Gradwahl
## öffnet sich mit Enter und mit Linksklick, Esc führt zurück, Enter auf Mittel beginnt ein Spiel.
## Der Communicator fährt hinaus, der Spielbildschirm kommt, und Spiel 1 liegt im Ordner. „Zum
## Hauptmenü“ speichert und bringt den Titel neu, mit „Weiterspielen“ vorgewählt. Er beginnt beim
## frischen Titel; „laden“ baut auf seinem Ende auf.
##
## Wortlaute wie in ablauf_titel.gd: aus TitleTexts, Grade aus Difficulty.label(), Namen der
## Spielstände aus SaveGame.default_name(), die des Selbsttests aus SelbsttestTexte. Die Eingaben
## sind Methoden des Fahrers, mit bind() schon mit ihrem Ziel versehen.


func _init() -> void:
	kennung = "neues_spiel"
	name = SelbsttestTexte.ablauf_name(kennung)


func schritte(fahrer: SelbsttestFahrer) -> Array[Dictionary]:
	var hauptmenue := SelbsttestFahrer.SEITE_HAUPTMENUE
	var gradwahl := SelbsttestFahrer.SEITE_GRADWAHL
	var neues_spiel := SelbsttestTexte.ziel(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_NEW_GAME)
	var mittel := Difficulty.label(Difficulty.Level.MITTEL)
	var spiel_1 := SaveGame.default_name(1)
	var erster_tag := str(GameDate.from_day_index(TimelineRun.FIRST_DAY))
	var weiter := TitleTexts.continue_hint(spiel_1, mittel, erster_tag)
	var gradwahl_steht := SelbsttestTexte.menue_steht_ohne_zeichen(TitleTexts.HEADER_DIFFICULTY,
		mittel)
	return [
		neuer_schritt("01_gradwahl",
			SelbsttestTexte.BESCHREIBUNG_NEUES_SPIEL_GRADWAHL % TitleTexts.LABEL_NEW_GAME,
			SelbsttestTexte.eingaben([SelbsttestTexte.maus_ueber(TitleTexts.LABEL_NEW_GAME),
				SelbsttestTexte.TASTE_ENTER]),
			_nacheinander.bind([fahrer.maus_ueber_eintrag.bind(hauptmenue, &"new_game", neues_spiel),
				fahrer.taste.bind(KEY_ENTER)]),
			_pruefe_menue.bind(fahrer, gradwahl, &"medium"),
			gradwahl_steht),
		neuer_schritt("02_zurueck_esc", SelbsttestTexte.BESCHREIBUNG_NEUES_SPIEL_ZURUECK_ESC,
			SelbsttestTexte.TASTE_ESC,
			fahrer.taste.bind(KEY_ESCAPE),
			_pruefe_menue.bind(fahrer, hauptmenue, &"new_game"),
			SelbsttestTexte.menue_steht(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_NEW_GAME)),
		neuer_schritt("03_gradwahl_klick",
			SelbsttestTexte.BESCHREIBUNG_NEUES_SPIEL_GRADWAHL_KLICK % TitleTexts.LABEL_NEW_GAME,
			SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
				SelbsttestTexte.zitat(TitleTexts.LABEL_NEW_GAME)),
			fahrer.klick_auf_eintrag.bind(hauptmenue, &"new_game", neues_spiel),
			_pruefe_menue.bind(fahrer, gradwahl, &"medium"),
			gradwahl_steht),
		neuer_schritt("04_grad_mittel", SelbsttestTexte.BESCHREIBUNG_NEUES_SPIEL_GRAD % mittel,
			SelbsttestTexte.auf(SelbsttestTexte.TASTE_ENTER, mittel),
			fahrer.taste.bind(KEY_ENTER),
			_pruefe_spiel_begonnen.bind(fahrer, spiel_1),
			SelbsttestTexte.zustaende([SelbsttestTexte.ZUSTAND_HINAUSGEFAHREN,
				SelbsttestTexte.spielbildschirm(TitleTexts.leave_hint(spiel_1)),
				SelbsttestTexte.spielstaende([spiel_1])])),
		neuer_schritt("05_zum_hauptmenue",
			SelbsttestTexte.BESCHREIBUNG_NEUES_SPIEL_ZUM_HAUPTMENUE % TitleTexts.LABEL_LEAVE,
			SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
				SelbsttestTexte.zitat(TitleTexts.LABEL_LEAVE)),
			fahrer.klick_auf_knopf_hauptmenue.bind(
				SelbsttestTexte.ziel(SelbsttestTexte.ZIEL_SPIELBILDSCHIRM, TitleTexts.LABEL_LEAVE)),
			_pruefe_titel_neu.bind(fahrer, weiter),
			SelbsttestTexte.titel_neu(SelbsttestTexte.zustaende([
				"%s, %s, %s" % [SelbsttestTexte.menue_steht(TitleTexts.HEADER_MAIN,
					TitleTexts.LABEL_CONTINUE), SelbsttestTexte.VERFUEGBAR,
					SelbsttestTexte.hinweis(weiter)],
				SelbsttestTexte.spielstaende([spiel_1])]))),
	]


## 04: Communicator hinausgefahren; Spielbildschirm steht mit [param spiel], dem laufenden Spiel;
## Spielstände: Spiel 1. Der Befund beginnt wie die Erwartung mit der Fahrt, damit beide Zeile an
## Zeile zu vergleichen sind.
func _pruefe_spiel_begonnen(fahrer: SelbsttestFahrer, spiel: String) -> String:
	if fahrer.hinausgefahren() and fahrer.spielbildschirm_steht(spiel) \
			and fahrer.laufendes_spiel() == spiel \
			and fahrer.spielstaende() == PackedInt32Array([1]):
		return ""
	var fahrt := SelbsttestTexte.ZUSTAND_HINAUSGEFAHREN if fahrer.hinausgefahren() \
		else SelbsttestTexte.ZUSTAND_NICHT_HINAUSGEFAHREN
	return SelbsttestTexte.zustaende([fahrt, fahrer.zustand()])


## 05: Titel neu, „Weiterspielen“ gewählt und verfügbar, mit dem Hinweis [param weiter] zu Spiel 1,
## Mittel; Spielstände: Spiel 1. Ein Titel nach dem Spielbildschirm ist immer ein neuer.
func _pruefe_titel_neu(fahrer: SelbsttestFahrer, weiter: String) -> String:
	if fahrer.titel() == null:
		return fahrer.zustand()
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"continue") \
			and fahrer.gewaehlt_verfuegbar() and fahrer.hinweis_text() == weiter \
			and fahrer.spielstaende() == PackedInt32Array([1]):
		return ""
	return SelbsttestTexte.titel_neu(fahrer.zustand())
