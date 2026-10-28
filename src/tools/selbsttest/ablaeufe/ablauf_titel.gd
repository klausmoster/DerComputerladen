extends SelbsttestAblauf

## Ablauf „titel“ (contracts/ablaeufe.md, „titel“; FR-011, Punkt 1): Der Titel erscheint, der
## Communicator fährt herein, das Hauptmenü steht mit „Neues Spiel“; „Weiterspielen“ ist ohne
## Spielstand nicht verfügbar und nennt den Grund; „Beenden“ ist verfügbar und löst beim Überfahren
## nichts aus; „Einstellungen“ ist noch nicht verfügbar und sagt, dass es später kommt. Er beginnt
## beim frischen Titel, den der Läufer vorbereitet.
##
## Die Wortlaute aus dem Spiel kommen aus TitleTexts, die des Selbsttests aus SelbsttestTexte. Die
## Prüfungen sind eigene Methoden; bind() gibt ihnen den Fahrer mit, so wird jede zum Callable, das
## der Läufer jedes Bild aufruft.
##
## titel_echtzeit erbt von hier und spielt dieselben Schritte ohne Zeitraffer.


func _init() -> void:
	kennung = "titel"
	name = SelbsttestTexte.ablauf_name(kennung)


func schritte(fahrer: SelbsttestFahrer) -> Array[Dictionary]:
	var hauptmenue := SelbsttestFahrer.SEITE_HAUPTMENUE
	var weiterspielen := SelbsttestTexte.ziel(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_CONTINUE)
	var beenden := SelbsttestTexte.ziel(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_QUIT)
	var einstellungen := SelbsttestTexte.ziel(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_SETTINGS)
	return [
		neuer_schritt("01_start", SelbsttestTexte.BESCHREIBUNG_TITEL_START,
			SelbsttestTexte.EINGABEN_KEINE, _keine_eingabe,
			_pruefe_start.bind(fahrer),
			"%s; %s" % [SelbsttestTexte.menue_steht(TitleTexts.HEADER_MAIN,
				TitleTexts.LABEL_NEW_GAME), SelbsttestTexte.spielstaende(PackedStringArray())]),
		neuer_schritt("02_nicht_verfuegbar",
			SelbsttestTexte.BESCHREIBUNG_TITEL_NICHT_VERFUEGBAR % TitleTexts.LABEL_CONTINUE,
			SelbsttestTexte.maus_ueber(TitleTexts.LABEL_CONTINUE),
			_maus_ueber.bind(fahrer, hauptmenue, &"continue", weiterspielen),
			_pruefe_nicht_verfuegbar.bind(fahrer),
			SelbsttestTexte.zeile_ohne_ausloesen(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_CONTINUE,
				TitleTexts.HINT_CONTINUE_NO_SAVES, SelbsttestTexte.NICHT_VERFUEGBAR)),
		neuer_schritt("03_beenden_da",
			SelbsttestTexte.BESCHREIBUNG_TITEL_BEENDEN_DA % TitleTexts.LABEL_QUIT,
			SelbsttestTexte.maus_ueber(TitleTexts.LABEL_QUIT),
			_maus_ueber.bind(fahrer, hauptmenue, &"quit", beenden),
			_pruefe_beenden_da.bind(fahrer),
			SelbsttestTexte.zeile_ohne_ausloesen(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_QUIT,
				TitleTexts.HINT_QUIT, SelbsttestTexte.VERFUEGBAR)),
		neuer_schritt("04_einstellungen",
			SelbsttestTexte.BESCHREIBUNG_TITEL_EINSTELLUNGEN % TitleTexts.LABEL_SETTINGS,
			SelbsttestTexte.maus_ueber(TitleTexts.LABEL_SETTINGS),
			_maus_ueber.bind(fahrer, hauptmenue, &"settings", einstellungen),
			_pruefe_einstellungen.bind(fahrer),
			SelbsttestTexte.zeile_ohne_ausloesen(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_SETTINGS,
				TitleTexts.HINT_SETTINGS, SelbsttestTexte.NICHT_VERFUEGBAR)),
	]


## 01: Menü steht: HAUPTMENÜ, „Neues Spiel“; Spielstände: keine.
func _pruefe_start(fahrer: SelbsttestFahrer) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"new_game") \
			and fahrer.spielstaende().is_empty():
		return ""
	return fahrer.zustand()


## 02: „Weiterspielen“ gewählt mit dem Hinweis, dass es kein Spiel gibt; nichts ausgelöst, also
## weiter das Hauptmenü, kein Spielstand und kein Beenden.
func _pruefe_nicht_verfuegbar(fahrer: SelbsttestFahrer) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"continue") \
			and not fahrer.gewaehlt_verfuegbar() and fahrer.hinweis_text() == TitleTexts.HINT_CONTINUE_NO_SAVES \
			and fahrer.spielstaende().is_empty() and fahrer.beenden_ausgeloest() == 0:
		return ""
	return fahrer.zustand()


## 03: „Beenden“ gewählt, verfügbar, mit seinem Hinweis; nichts ausgelöst.
func _pruefe_beenden_da(fahrer: SelbsttestFahrer) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"quit") \
			and fahrer.gewaehlt_verfuegbar() \
			and fahrer.hinweis_text() == TitleTexts.HINT_QUIT and fahrer.beenden_ausgeloest() == 0:
		return ""
	return fahrer.zustand()


## 04: „Einstellungen“ gewählt, nicht verfügbar, mit dem Hinweis, dass es später kommt; nichts
## ausgelöst, also weiter das Hauptmenü, kein Spielstand und kein Beenden.
func _pruefe_einstellungen(fahrer: SelbsttestFahrer) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"settings") \
			and not fahrer.gewaehlt_verfuegbar() and fahrer.hinweis_text() == TitleTexts.HINT_SETTINGS \
			and fahrer.spielstaende().is_empty() and fahrer.beenden_ausgeloest() == 0:
		return ""
	return fahrer.zustand()


func _keine_eingabe() -> String:
	return ""


func _maus_ueber(fahrer: SelbsttestFahrer, seite: StringName, eintrag: StringName,
		beschreibung: String) -> String:
	return await fahrer.maus_ueber_eintrag(seite, eintrag, beschreibung)
