extends SelbsttestAblauf

## Ablauf „liste“, Name „Liste“ (contracts/ablaeufe.md, „liste“; Feature 007, T058): die Wege aus
## Liste und Rückfrage zurück. Esc und „Zurück“ führen aus der Liste ins Hauptmenü auf „Spiel
## laden“; im Löschmodus beendet Esc nur den Modus, und die Liste bleibt mit der Auswahl auf
## „Löschen …“; Esc in der Rückfrage führt zurück zur Liste auf den Spielstand, nach dem sie fragte.
## Zuletzt löscht ein Linksklick in der Rückfrage Spiel 1, und weil Spiel 2 bleibt, steht die Liste
## mit der Auswahl auf ihm, statt ins Hauptmenü zu gehen wie bei „loeschen“.
##
## Er beginnt beim frischen Titel ohne Spielstand. Schritt 01 legt deshalb als Vorbereitung zwei
## Spielstände über SaveStore an und lädt den Titel neu, wie bedienung.06 (CHK001); aufraeumen()
## löscht, was davon übrig ist, auch wenn ein Schritt scheiterte. Spiel 1 ist der zuletzt gespielte
## und steht oben.
##
## Was jeder Schritt erwartet, folgt dem Spiel (TitleScreen, SaveList): Die Liste merkt sich, wer
## sie geöffnet hat, und Zurück wählt im Hauptmenü wieder ihn; set_delete_mode(false) lässt die
## Auswahl, wo sie war; _cancel_delete() wählt den Spielstand der Rückfrage; _delete_confirmed()
## wählt die Zeile, die an seine Stelle rückt. Wortlaute wie in ablauf_loeschen.gd.

## So viele Spielstände legt 01 an: einer bleibt nach dem Löschen in 06, damit die Liste stehen
## bleibt.
const SPIELSTAENDE := 2


func _init() -> void:
	kennung = "liste"
	name = SelbsttestTexte.ablauf_name(kennung)


func schritte(fahrer: SelbsttestFahrer) -> Array[Dictionary]:
	var hauptmenue := SelbsttestFahrer.SEITE_HAUPTMENUE
	var liste := SelbsttestFahrer.SEITE_SPIELSTAENDE
	var rueckfrage := SelbsttestFahrer.SEITE_RUECKFRAGE
	var spiel_1 := SaveGame.default_name(1)
	var spiel_2 := SaveGame.default_name(2)
	var spiel_1_loeschen := TitleTexts.delete_label(spiel_1)
	var angaben := SelbsttestTexte.angaben([Difficulty.label(Difficulty.Level.MITTEL),
		str(GameDate.from_day_index(TimelineRun.FIRST_DAY))])

	# Ziele, wie sie in „Ziel nicht gefunden: …“ stehen.
	var ziel_spiel_laden := SelbsttestTexte.ziel(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_LOAD_GAME)
	var ziel_zurueck := SelbsttestTexte.ziel(TitleTexts.HEADER_SAVES, TitleTexts.LABEL_BACK)
	var ziel_loeschen := SelbsttestTexte.ziel(TitleTexts.HEADER_SAVES, TitleTexts.LABEL_DELETE_MODE)
	var ziel_zeile := SelbsttestTexte.ziel_ohne_zeichen(TitleTexts.HEADER_DELETE_MODE, spiel_1)
	var ziel_spiel_1_loeschen := SelbsttestTexte.ziel(TitleTexts.HEADER_CONFIRM, spiel_1_loeschen)

	# Eingaben in Worten.
	var klick_spiel_laden := SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
		SelbsttestTexte.zitat(TitleTexts.LABEL_LOAD_GAME))
	var klick_zurueck := SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
		SelbsttestTexte.zitat(TitleTexts.LABEL_BACK))
	var klick_loeschen := SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
		SelbsttestTexte.zitat(TitleTexts.LABEL_DELETE_MODE))
	var klick_spiel_1 := SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK, spiel_1)
	var klick_spiel_1_loeschen := SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
		SelbsttestTexte.zitat(spiel_1_loeschen))

	# Eingaben als Callables; jede wartet, bis sie hinaus ist.
	var oeffnen := fahrer.klick_auf_eintrag.bind(hauptmenue, &"load_game", ziel_spiel_laden)
	var loeschmodus := fahrer.klick_auf_eintrag.bind(liste, SelbsttestFahrer.ZEILE_LOESCHEN,
		ziel_loeschen)
	var zeile_1 := fahrer.klick_auf_zeile.bind(1, ziel_zeile)
	var esc := fahrer.taste.bind(KEY_ESCAPE)

	# Erwartungen.
	var spiel_1_steht := SelbsttestTexte.menue_steht_ohne_zeichen(TitleTexts.HEADER_SAVES,
		SelbsttestTexte.zeile_mit_angaben(spiel_1, angaben))
	var spiel_laden_steht := SelbsttestTexte.menue_steht(TitleTexts.HEADER_MAIN,
		TitleTexts.LABEL_LOAD_GAME)
	var beide := SelbsttestTexte.spielstaende([spiel_1, spiel_2])
	return [
		neuer_schritt("01_oeffnen",
			SelbsttestTexte.BESCHREIBUNG_KLICK_ZEIGT_LISTE % TitleTexts.LABEL_LOAD_GAME,
			SelbsttestTexte.vorbereitung(SelbsttestTexte.spielstaende_anzahl(SPIELSTAENDE),
				klick_spiel_laden),
			_nacheinander.bind([fahrer.lege_spielstaende_an.bind(SPIELSTAENDE),
				fahrer.lade_titel_neu, oeffnen]),
			_pruefe_spielstand.bind(fahrer, 1, angaben, PackedInt32Array([1, 2])),
			SelbsttestTexte.zustaende([spiel_1_steht, beide])),
		neuer_schritt("02_esc", SelbsttestTexte.BESCHREIBUNG_LISTE_ESC,
			SelbsttestTexte.TASTE_ESC,
			esc,
			_pruefe_menue.bind(fahrer, hauptmenue, &"load_game"),
			spiel_laden_steht),
		neuer_schritt("03_zurueck",
			SelbsttestTexte.BESCHREIBUNG_KLICK_INS_HAUPTMENUE % TitleTexts.LABEL_BACK,
			SelbsttestTexte.eingaben([klick_spiel_laden, klick_zurueck]),
			_nacheinander.bind([oeffnen,
				fahrer.klick_auf_eintrag.bind(liste, SelbsttestFahrer.ZEILE_ZURUECK, ziel_zurueck)]),
			_pruefe_menue.bind(fahrer, hauptmenue, &"load_game"),
			spiel_laden_steht),
		neuer_schritt("04_loeschmodus_esc",
			SelbsttestTexte.BESCHREIBUNG_LISTE_LOESCHMODUS_ESC,
			SelbsttestTexte.eingaben([klick_spiel_laden, klick_loeschen, SelbsttestTexte.TASTE_ESC]),
			_nacheinander.bind([oeffnen, loeschmodus, esc]),
			_pruefe_loeschmodus_aus.bind(fahrer),
			"%s, %s" % [SelbsttestTexte.menue_steht(TitleTexts.HEADER_SAVES,
				TitleTexts.LABEL_DELETE_MODE), SelbsttestTexte.VERFUEGBAR]),
		neuer_schritt("05_rueckfrage_esc",
			SelbsttestTexte.BESCHREIBUNG_LISTE_RUECKFRAGE_ESC % spiel_1,
			SelbsttestTexte.eingaben([klick_loeschen, klick_spiel_1, SelbsttestTexte.TASTE_ESC]),
			_nacheinander.bind([loeschmodus, zeile_1, esc]),
			_pruefe_spielstand.bind(fahrer, 1, angaben, PackedInt32Array([1, 2])),
			SelbsttestTexte.zustaende([spiel_1_steht, beide])),
		neuer_schritt("06_loeschen",
			SelbsttestTexte.BESCHREIBUNG_LISTE_LOESCHEN % [spiel_1_loeschen, spiel_1, spiel_2],
			SelbsttestTexte.eingaben([klick_loeschen, klick_spiel_1, klick_spiel_1_loeschen]),
			_nacheinander.bind([loeschmodus, zeile_1,
				fahrer.klick_auf_eintrag.bind(rueckfrage, &"delete", ziel_spiel_1_loeschen)]),
			_pruefe_spielstand.bind(fahrer, 2, angaben, PackedInt32Array([2])),
			SelbsttestTexte.zustaende([SelbsttestTexte.menue_steht_ohne_zeichen(
				TitleTexts.HEADER_SAVES, SelbsttestTexte.zeile_mit_angaben(spiel_2, angaben)),
				SelbsttestTexte.spielstaende([spiel_2])])),
	]


## Was von den Spielständen aus 01 noch da ist, kommt weg, ob die Schritte gelangen oder nicht.
func aufraeumen(fahrer: SelbsttestFahrer) -> void:
	fahrer.raeume_spielstaende_weg()


## 01, 05 und 06: Menü steht: SPIELSTÄNDE, Spiel [param nummer] mit [param angaben], ohne
## Löschmodus (die Kopfzeile heißt SPIELSTÄNDE); im Ordner genau die Spielstände [param im_ordner].
func _pruefe_spielstand(fahrer: SelbsttestFahrer, nummer: int, angaben: String,
		im_ordner: PackedInt32Array) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_SPIELSTAENDE, StringName("slot_%d" % nummer)) \
			and fahrer.kopfzeile() == TitleTexts.HEADER_SAVES and fahrer.zeile_angaben() == angaben \
			and fahrer.spielstaende() == im_ordner:
		return ""
	return fahrer.zustand()


## 04: Der Löschmodus ist aus, die Kopfzeile heißt wieder SPIELSTÄNDE; „Löschen …“ bleibt gewählt
## und ist wieder verfügbar.
func _pruefe_loeschmodus_aus(fahrer: SelbsttestFahrer) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_SPIELSTAENDE, SelbsttestFahrer.ZEILE_LOESCHEN) \
			and fahrer.kopfzeile() == TitleTexts.HEADER_SAVES and fahrer.gewaehlt_verfuegbar():
		return ""
	return fahrer.zustand()
