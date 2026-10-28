extends SelbsttestAblauf

## Ablauf „loeschen“, Name „Löschen“ (contracts/ablaeufe.md, „loeschen“; FR-011, Punkt 4): In der
## Liste schaltet „Löschen …“ den Löschmodus ein, Spiel 1 führt zur Rückfrage, „Abbrechen“ lässt
## es stehen; beim zweiten Mal löscht „Spiel 1 löschen“ es, und weil es der letzte Spielstand war,
## steht das Hauptmenü auf „Neues Spiel“.
##
## Er baut auf „laden“ auf und beginnt im Hauptmenü auf „Weiterspielen“ mit Spiel 1 im Ordner. Das
## Löschen trifft nur den Ordner des Selbsttests; echte Spielstände liegen nie dort (FR-008).
## Wortlaute wie in ablauf_neues_spiel.gd.


func _init() -> void:
	kennung = "loeschen"
	name = SelbsttestTexte.ablauf_name(kennung)
	baut_auf = "laden"


func schritte(fahrer: SelbsttestFahrer) -> Array[Dictionary]:
	var hauptmenue := SelbsttestFahrer.SEITE_HAUPTMENUE
	var liste := SelbsttestFahrer.SEITE_SPIELSTAENDE
	var rueckfrage := SelbsttestFahrer.SEITE_RUECKFRAGE
	var spiel_1 := SaveGame.default_name(1)
	var angaben := SelbsttestTexte.angaben([Difficulty.label(Difficulty.Level.MITTEL),
		str(GameDate.from_day_index(TimelineRun.FIRST_DAY))])
	var liste_steht := SelbsttestTexte.menue_steht_ohne_zeichen(TitleTexts.HEADER_SAVES,
		SelbsttestTexte.zeile_mit_angaben(spiel_1, angaben))
	var loeschen := SelbsttestTexte.ziel(TitleTexts.HEADER_SAVES, TitleTexts.LABEL_DELETE_MODE)
	var zeile_im_loeschmodus := SelbsttestTexte.ziel_ohne_zeichen(TitleTexts.HEADER_DELETE_MODE,
		spiel_1)
	var klick_loeschen := SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
		SelbsttestTexte.zitat(TitleTexts.LABEL_DELETE_MODE))
	var klick_spiel_1 := SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK, spiel_1)
	var rueckfrage_steht := SelbsttestTexte.menue_steht(TitleTexts.HEADER_CONFIRM,
		TitleTexts.LABEL_CANCEL)
	return [
		neuer_schritt("01_liste",
			SelbsttestTexte.BESCHREIBUNG_LOESCHEN_LISTE % TitleTexts.LABEL_LOAD_GAME,
			SelbsttestTexte.auf(SelbsttestTexte.LINKSKLICK,
				SelbsttestTexte.zitat(TitleTexts.LABEL_LOAD_GAME)),
			fahrer.klick_auf_eintrag.bind(hauptmenue, &"load_game",
				SelbsttestTexte.ziel(TitleTexts.HEADER_MAIN, TitleTexts.LABEL_LOAD_GAME)),
			_pruefe_liste.bind(fahrer, angaben, false),
			liste_steht),
		neuer_schritt("02_loeschmodus",
			SelbsttestTexte.BESCHREIBUNG_LOESCHEN_LOESCHMODUS % TitleTexts.LABEL_DELETE_MODE,
			klick_loeschen,
			fahrer.klick_auf_eintrag.bind(liste, SelbsttestFahrer.ZEILE_LOESCHEN, loeschen),
			_pruefe_loeschmodus.bind(fahrer),
			"%s, %s" % [SelbsttestTexte.menue_steht(TitleTexts.HEADER_DELETE_MODE,
				TitleTexts.LABEL_DELETE_MODE), SelbsttestTexte.NICHT_VERFUEGBAR]),
		neuer_schritt("03_rueckfrage", SelbsttestTexte.BESCHREIBUNG_LOESCHEN_RUECKFRAGE % spiel_1,
			klick_spiel_1,
			fahrer.klick_auf_zeile.bind(1, zeile_im_loeschmodus),
			_pruefe_menue.bind(fahrer, rueckfrage, &"cancel"),
			rueckfrage_steht),
		neuer_schritt("04_abbrechen",
			SelbsttestTexte.BESCHREIBUNG_LOESCHEN_ABBRECHEN % [TitleTexts.LABEL_CANCEL, spiel_1],
			SelbsttestTexte.auf(SelbsttestTexte.TASTE_ENTER,
				SelbsttestTexte.zitat(TitleTexts.LABEL_CANCEL)),
			fahrer.taste.bind(KEY_ENTER),
			_pruefe_liste.bind(fahrer, angaben, true),
			SelbsttestTexte.zustaende([liste_steht, SelbsttestTexte.spielstaende([spiel_1])])),
		neuer_schritt("05_rueckfrage_2",
			SelbsttestTexte.BESCHREIBUNG_LOESCHEN_RUECKFRAGE_2 % [TitleTexts.LABEL_DELETE_MODE,
				spiel_1],
			SelbsttestTexte.eingaben([klick_loeschen, klick_spiel_1]),
			_nacheinander.bind([
				fahrer.klick_auf_eintrag.bind(liste, SelbsttestFahrer.ZEILE_LOESCHEN, loeschen),
				fahrer.klick_auf_zeile.bind(1, zeile_im_loeschmodus)]),
			_pruefe_menue.bind(fahrer, rueckfrage, &"cancel"),
			rueckfrage_steht),
		neuer_schritt("06_loeschen",
			SelbsttestTexte.BESCHREIBUNG_LOESCHEN_LOESCHEN % TitleTexts.delete_label(spiel_1),
			SelbsttestTexte.eingaben([SelbsttestTexte.bis(SelbsttestTexte.TASTE_PFEIL_RUNTER,
				SelbsttestTexte.zitat(TitleTexts.delete_label(spiel_1))),
				SelbsttestTexte.TASTE_ENTER]),
			_nacheinander.bind([fahrer.pfeil_runter_bis.bind(rueckfrage, &"delete",
				SelbsttestTexte.ziel(TitleTexts.HEADER_CONFIRM, TitleTexts.delete_label(spiel_1))),
				fahrer.taste.bind(KEY_ENTER)]),
			_pruefe_geloescht.bind(fahrer),
			SelbsttestTexte.zustaende([SelbsttestTexte.menue_steht(TitleTexts.HEADER_MAIN,
				TitleTexts.LABEL_NEW_GAME), SelbsttestTexte.spielstaende([])])),
	]


## 01 und 04: Menü steht: SPIELSTÄNDE, Spiel 1 mit [param angaben], ohne Löschmodus (die Kopfzeile
## heißt SPIELSTÄNDE). [param mit_spielstaenden]: Spielstände: Spiel 1 gehört zur Erwartung (04).
func _pruefe_liste(fahrer: SelbsttestFahrer, angaben: String, mit_spielstaenden: bool) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_SPIELSTAENDE, &"slot_1") \
			and fahrer.kopfzeile() == TitleTexts.HEADER_SAVES and fahrer.zeile_angaben() == angaben \
			and (not mit_spielstaenden or fahrer.spielstaende() == PackedInt32Array([1])):
		return ""
	return fahrer.zustand()


## 02: Kopfzeile WELCHES LÖSCHEN?; „Löschen …“ bleibt gewählt und ist im Löschmodus nicht
## verfügbar.
func _pruefe_loeschmodus(fahrer: SelbsttestFahrer) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_SPIELSTAENDE, SelbsttestFahrer.ZEILE_LOESCHEN) \
			and fahrer.kopfzeile() == TitleTexts.HEADER_DELETE_MODE \
			and not fahrer.gewaehlt_verfuegbar():
		return ""
	return fahrer.zustand()


## 06: Menü steht: HAUPTMENÜ, „Neues Spiel“; Spielstände: keine.
func _pruefe_geloescht(fahrer: SelbsttestFahrer) -> String:
	if fahrer.menue_steht(SelbsttestFahrer.SEITE_HAUPTMENUE, &"new_game") \
			and fahrer.spielstaende().is_empty():
		return ""
	return fahrer.zustand()
