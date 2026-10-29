class_name SelbsttestTexte
extends RefCounted

## Alle Texte des Selbsttests an einer Stelle (Feature 007, contracts/selbsttest-app.md, „Texte“;
## freigegeben mit der Checkliste, CHK029 bis CHK039). Protokoll, Fenstertitel und
## Zusammenfassung holen ihre Wortlaute nur von hier; so kann ein Text nicht an zwei Stellen
## verschieden stehen (FR-014a).
##
## Zwei Formen: Auf dem Bildschirm stehen ganze Sätze mit Punkt und deutsche Formen
## („28.10.2026, 14:03 Uhr“). Im Protokoll stehen Werte ohne Schlusspunkt, nur der Satz hinter
## „ergebnis:“ endet mit Punkt (CHK034); Zeiten und Maße stehen dort in Maschinenform, die
## SelbsttestProtokoll schreibt (CHK039).
##
## Zahlwörter nach dem Fall: „von 1 Schritt“, „von 2 Schritten“; „1 Fehler“, „2 Fehler“.

# --- Protokoll -----------------------------------------------------------------------------------

## Erste Zeile des Protokolls und des Texts für „Kopieren“ (CHK036).
const KOPF := "# Der Computerladen Selbsttest"
## Wert für alles, was das System nicht liefert; ein Schlüssel fehlt nie (contracts/protokoll.md).
const UNBEKANNT := "unbekannt"
## Wert von lauf.abbruch, wenn das Fenster nicht geschlossen wurde (CHK038).
const KEIN_ABBRUCH := "keiner"
## Werte von foto_vergleichbar.
const JA := "ja"
const NEIN := "nein"
## Eingaben eines Schritts ohne Eingabe, und der beiden Arten von Schritten, die nicht über
## Eingaben gehen (data-model.md, „Schritt“; CHK001).
const EINGABEN_KEINE := "keine"
const EINGABEN_VORBEREITUNG := "Vorbereitung"
const EINGABEN_FENSTER := "Fenster"

## Gründe bei NICHT_GELAUFEN (CHK034).
const FENSTER_GESCHLOSSEN := "Fenster geschlossen"
## Ein Szenario braucht die Bedienung der Uhr im Spielbildschirm, die es noch nicht gibt (R27).
const UHR_NICHT_BEDIENBAR := "Die Uhr lässt sich im Spielbildschirm noch nicht bedienen"
## Meldung, wenn sich im Ordner des Laufs nicht schreiben lässt; %s ist der Pfad. Ohne
## Schlusspunkt, so steht sie im Text für „Kopieren“; auf dem Bildschirm mit Punkt, siehe
## kein_protokoll().
const KEIN_PROTOKOLL := "Kein Protokoll: In %s lässt sich nicht schreiben"
## Namen der Grafikschnittstellen nach dem Treiber, wie Godot ihn meldet, für system.grafik_api
## (Feature 007, data-model.md; Feature 009, contracts/renderer.md, R3). ANGLE und OpenGL ES sind
## die Rückfälle von Compatibility unter Windows und Linux; Metal, Vulkan und D3D12 gibt es nur bei
## einem Start mit --rendering-method forward_plus.
const GRAFIK_API := {
	"opengl3": "OpenGL",
	"opengl3_angle": "ANGLE",
	"opengl3_es": "OpenGL ES",
	"metal": "Metal",
	"vulkan": "Vulkan",
	"d3d12": "D3D12",
}

# --- Fenster und Abläufe -------------------------------------------------------------------------

## Fenstertitel nach dem Lauf.
const FENSTERTITEL_DANACH := "Der Computerladen Selbsttest"
## Namen der Abläufe für Menschen, nach Kennung (data-model.md, „Ablauf“; CHK037).
const ABLAUF_NAMEN := {
	"titel": "Titel",
	"neues_spiel": "Neues Spiel",
	"laden": "Spiel laden",
	"loeschen": "Löschen",
	"easter_egg": "Easter Egg",
	"bedienung": "Bedienung",
	"liste": "Liste",
	"fenster": "Fenster",
	"titel_echtzeit": "Titel in Echtzeit",
}

# --- Schritte der Abläufe (contracts/ablaeufe.md) ------------------------------------------------
# Beschreibung, Eingaben und Erwartung je Schritt. Wortlaute aus dem Spiel, etwa Kopfzeilen,
# Einträge und Hinweise, kommen zur Laufzeit aus TitleTexts; ändert sich dort ein Text, bleibt der
# Ablauf gültig (R5). Werte stehen ohne Schlusspunkt (CHK034).

## titel.01_start: so festgelegt in CHK030.
const BESCHREIBUNG_TITEL_START := "Start, der Communicator fährt herein"
## titel.02_nicht_verfuegbar.
const BESCHREIBUNG_TITEL_NICHT_VERFUEGBAR := "Maus über „%s“ wählt, ohne Spielstand nicht verfügbar"
## titel.03_beenden_da.
const BESCHREIBUNG_TITEL_BEENDEN_DA := "Maus über „%s“ wählt, ohne auszulösen"
## titel.04_einstellungen.
const BESCHREIBUNG_TITEL_EINSTELLUNGEN := "Maus über „%s“ wählt, noch nicht verfügbar"
## Zusatz zu einer Erwartung: Ein Schritt hat nichts ausgelöst. Immer so, nie „nicht ausgelöst“.
const NICHTS_AUSGELOEST := "nichts ausgelöst"
## Die gewählte Zeile ist verfügbar, etwa „Beenden“ in titel.03.
const VERFUEGBAR := "verfügbar"
## Die gewählte Zeile ist nicht verfügbar; steht hinter ihr, auch in „gefunden:“
## (contracts/ablaeufe.md, „Gemeinsame Prüfungen“, „Verfügbarkeit“).
const NICHT_VERFUEGBAR := "nicht verfügbar"

## Beschreibungen, die in mehreren Abläufen gleich lauten; so steht jeder Wortlaut nur einmal.
## %s ist ein Wortlaut aus TitleTexts. loeschen.01 und liste.01:
const BESCHREIBUNG_KLICK_ZEIGT_LISTE := "Linksklick auf „%s“ zeigt die Liste der Spielstände"
## laden.05, bedienung.05 und liste.03:
const BESCHREIBUNG_KLICK_INS_HAUPTMENUE := "Linksklick auf „%s“ führt zurück ins Hauptmenü"

## neues_spiel.01_gradwahl bis neues_spiel.05_zum_hauptmenue. %s sind Wortlaute aus TitleTexts,
## der Grad aus Difficulty.label().
const BESCHREIBUNG_NEUES_SPIEL_GRADWAHL := "Enter auf „%s“ öffnet die Gradwahl"
const BESCHREIBUNG_NEUES_SPIEL_ZURUECK_ESC := "Esc führt zurück ins Hauptmenü"
const BESCHREIBUNG_NEUES_SPIEL_GRADWAHL_KLICK := "Linksklick auf „%s“ öffnet die Gradwahl"
const BESCHREIBUNG_NEUES_SPIEL_GRAD := "Enter auf %s beginnt ein neues Spiel"
const BESCHREIBUNG_NEUES_SPIEL_ZUM_HAUPTMENUE := "Linksklick auf „%s“ speichert, der Titel kommt neu"
## laden.01_weiterspielen bis laden.04_zeile, laden.05 siehe oben; der Spielstand heißt wie
## SaveGame.default_name().
const BESCHREIBUNG_LADEN_WEITERSPIELEN := "Enter auf „%s“ setzt %s fort"
const BESCHREIBUNG_LADEN_ZURUECK := "Enter auf „%s“ führt zurück ins Hauptmenü"
const BESCHREIBUNG_LADEN_LISTE := "Enter auf „%s“ zeigt die Liste der Spielstände"
const BESCHREIBUNG_LADEN_ZEILE := "Linksklick auf %s setzt es fort"
## loeschen.02_loeschmodus bis loeschen.06_loeschen, loeschen.01 siehe oben.
const BESCHREIBUNG_LOESCHEN_LOESCHMODUS := "Linksklick auf „%s“ schaltet den Löschmodus ein"
const BESCHREIBUNG_LOESCHEN_RUECKFRAGE := "Linksklick auf %s im Löschmodus führt zur Rückfrage"
const BESCHREIBUNG_LOESCHEN_ABBRECHEN := "Enter auf „%s“ führt zurück zur Liste, %s bleibt"
const BESCHREIBUNG_LOESCHEN_RUECKFRAGE_2 := "Linksklick auf %s im Löschmodus führt noch einmal zur Rückfrage"
const BESCHREIBUNG_LOESCHEN_LOESCHEN := "Enter auf „%s“ löscht den letzten Spielstand"
## easter_egg.01_auswahl bis easter_egg.05_ende_esc.
const BESCHREIBUNG_EASTER_EGG_AUSWAHL := "Pfeil runter bis „%s“ wählt, hierher kehrt die Auswahl nach Invaders zurück"
const BESCHREIBUNG_EASTER_EGG_FALSCHE_FOLGE := "Gehäusetasten in falscher Folge starten Invaders nicht"
const BESCHREIBUNG_EASTER_EGG_START := "Gehäusetasten links, Mitte, rechts starten Invaders"
const BESCHREIBUNG_EASTER_EGG_SPIELEN := "Pfeil rechts fährt die Kanone, Leertaste schießt"
const BESCHREIBUNG_EASTER_EGG_ENDE_ESC := "Esc beendet Invaders, „%s“ steht wieder da"
## bedienung.01_pfeile bis bedienung.06_mausrad, bedienung.05 siehe oben.
const BESCHREIBUNG_BEDIENUNG_PFEILE := "Pfeiltasten wählen, am Anfang geht es am Ende weiter"
const BESCHREIBUNG_BEDIENUNG_TAB := "Tab wählt die nächste Zeile, Umschalt+Tab die vorige"
const BESCHREIBUNG_BEDIENUNG_RECHTSKLICK := "Rechtsklick auf „%s“ wählt, ohne auszulösen"
const BESCHREIBUNG_BEDIENUNG_LEERTASTE := "Leertaste auf „%s“ öffnet die Gradwahl"
const BESCHREIBUNG_BEDIENUNG_MAUSRAD := "Mausrad runter rollt die Liste um 1 Zeile"
## liste.02_esc bis liste.06_loeschen, liste.01 und liste.03 siehe oben. %s sind Wortlaute aus TitleTexts, der
## Spielstand heißt wie SaveGame.default_name(). Bei mehreren Eingaben nennt die Beschreibung die,
## die den Zustand bewirkt (contracts/ablaeufe.md, „Beschreibung“).
const BESCHREIBUNG_LISTE_ESC := "Esc in der Liste führt zurück ins Hauptmenü"
const BESCHREIBUNG_LISTE_LOESCHMODUS_ESC := "Esc schaltet den Löschmodus aus, die Liste bleibt"
const BESCHREIBUNG_LISTE_RUECKFRAGE_ESC := "Esc in der Rückfrage führt zurück zur Liste, %s bleibt"
const BESCHREIBUNG_LISTE_LOESCHEN := "Linksklick auf „%s“ löscht %s, die Auswahl springt auf %s"
## fenster.01_start bis fenster.04_zurueck.
const BESCHREIBUNG_FENSTER_START := "Start mit dem größten Faktor, der passt, Fenster mittig im nutzbaren Bereich"
const BESCHREIBUNG_FENSTER_FAKTOR_1 := "Bild mit Faktor 1 ohne Rand"
const BESCHREIBUNG_FENSTER_KRUMM := "Bild mit ganzem Faktor mittig im krummen Fenster, Rand ringsum"
const BESCHREIBUNG_FENSTER_ZURUECK := "Bild mit dem Startfaktor ohne Rand, Fenster wieder in Startgröße und -lage"
## Schritte eines Szenarios (R27): Start mit Grad und Seed, Entscheidung und Prüfpunkt an einem
## Spieldatum, etwa „Prüfpunkt am 01.03.1987“.
const BESCHREIBUNG_SZENARIO_START := "%s beginnt mit %s, Seed %d"
const BESCHREIBUNG_SZENARIO_ENTSCHEIDUNG := "Entscheidung am %s"
const BESCHREIBUNG_SZENARIO_PRUEFPUNKT := "Prüfpunkt am %s"

## Eingaben in Worten, für „eingaben:“ und die Beschreibungen (contracts/selbsttest-app.md,
## „Texte“: Tasten heißen Enter, Esc, Tab, Umschalt+Tab, Leertaste, Pfeil runter).
const TASTE_ENTER := "Enter"
const TASTE_ESC := "Esc"
const TASTE_PFEIL_RUNTER := "Pfeil runter"
const TASTE_PFEIL_HOCH := "Pfeil hoch"
const TASTE_PFEIL_RECHTS := "Pfeil rechts"
const TASTE_TAB := "Tab"
const TASTE_UMSCHALT_TAB := "Umschalt+Tab"
const TASTE_LEERTASTE := "Leertaste"
const LINKSKLICK := "Linksklick"
const RECHTSKLICK := "Rechtsklick"
const MAUSRAD_RUNTER := "Mausrad runter"
## Ein Szenario beginnt sein Spiel als Vorbereitung: „Spiel 1 mit Leicht, Seed 4711“.
const SZENARIO_SPIEL := "%s mit %s, Seed %d"
## erwartet: eines Schritts, der nichts prüft, etwa einer Entscheidung im Szenario ohne Erwartung.
const ERWARTET_KEINE := "keine"
## „Fenster auf die Startgröße“ in fenster.04.
const FENSTER_AUF_STARTGROESSE := "Fenster auf die Startgröße"
## Ein Ziel, das keine Seite mit Kopfzeile hat, etwa der Knopf „Zum Hauptmenü“: „Spielbildschirm,
## „Zum Hauptmenü““ in „Ziel nicht gefunden: …“.
const ZIEL_SPIELBILDSCHIRM := "Spielbildschirm"

# --- Zustände, wie der Fahrer sie liest -----------------------------------------------------------
# In der Form der Spalte „Erwartet“ (CHK031, CHK032); sie landen in „gefunden:“.

const ZUSTAND_KEIN_BILDSCHIRM := "kein Titel und kein Spielbildschirm"
const ZUSTAND_COMMUNICATOR_FAEHRT := "Communicator nicht in Endlage"
const ZUSTAND_KEINE_SEITE := "keine Seite sichtbar"
const ZUSTAND_KEINE_ZEILE := "keine Zeile gewählt"
const ZUSTAND_SPIELBILDSCHIRM := "Spielbildschirm steht"
## Der Spielbildschirm ohne Fokus auf „Zum Hauptmenü“; dann steht er nicht (B4).
const ZUSTAND_SPIELBILDSCHIRM_OHNE_FOKUS := "Spielbildschirm, „%s“ ohne Fokus"
## Wie der Vertrag es bei easter_egg.03 schreibt.
const ZUSTAND_KEIN_HINWEIS := "Hinweis aus"
## Seite ohne Kopfzeile, etwa das versteckte Spiel; %s ist der Name des Knotens.
const ZUSTAND_SEITE := "Seite %s sichtbar"
## Ein Eintrag hat ausgelöst, etwa „Beenden“, das der Selbsttest abfängt, statt sich zu beenden;
## %s ist der Wortlaut aus TitleTexts.
const ZUSTAND_AUSGELOEST := "„%s“ ausgelöst"
## Wie der Vertrag es bei neues_spiel.04 und neues_spiel.05 schreibt; der Fahrer weiß es über
## slide_finished.
const ZUSTAND_HINAUSGEFAHREN := "Communicator hinausgefahren"
const ZUSTAND_NICHT_HINAUSGEFAHREN := "Communicator nicht hinausgefahren"
const ZUSTAND_TITEL_NEU := "Titel neu"
## Eine Seite ohne Kopfzeile, die nicht zu sehen ist oder spielt, etwa das versteckte Spiel; %s ist
## der Name des Knotens (easter_egg.02, easter_egg.03).
const ZUSTAND_SEITE_NICHT_SICHTBAR := "Seite %s nicht sichtbar"
const ZUSTAND_SEITE_AKTIV := "Seite %s sichtbar und aktiv"
const ZUSTAND_SEITE_NICHT_AKTIV := "Seite %s sichtbar und nicht aktiv"
## Das versteckte Spiel nach easter_egg.04.
const ZUSTAND_KANONE_RECHTS := "Kanone weiter rechts als beim Start"
const ZUSTAND_KANONE_NICHT_RECHTS := "Kanone nicht weiter rechts als beim Start"
const ZUSTAND_SCHUSS := "ein Schuss unterwegs"
const ZUSTAND_TREFFER := "ein Treffer gezählt"
const ZUSTAND_KEIN_SCHUSS := "kein Schuss unterwegs und kein Treffer gezählt"
## Rollen der Liste (bedienung.06): oberste Zeile und Rollmarke oben.
const ZUSTAND_LISTE_OBEN := "Liste oben bei %s"
const ZUSTAND_MARKE_OBEN := "Rollmarke oben sichtbar"
const ZUSTAND_KEINE_MARKE_OBEN := "Rollmarke oben nicht sichtbar"
## Fenster und Bild (fenster.01 bis fenster.04). Maße deutsch mit „ד (Phasenprüfung Phase 1, L1).
const ZUSTAND_OHNE_RAND := "ohne Rand"
const ZUSTAND_MITTIG := "mittig"
const ZUSTAND_NICHT_MITTIG := "nicht mittig"
const ZUSTAND_RAND_RINGSUM := "Rand ringsum"
const ZUSTAND_RAND := "Rand links %d, rechts %d, oben %d, unten %d"
const ZUSTAND_GANZE_PIXEL := "ganze Pixel"
const ZUSTAND_KEINE_GANZEN_PIXEL := "keine ganzen Pixel"
const ZUSTAND_LAGE_MITTIG := "mittig im nutzbaren Bereich, auf 1 Pixel genau"
## „0 Pixel rechts, 2 Pixel unter der Mitte des nutzbaren Bereichs“; links und über bei negativem
## Versatz, siehe lage_daneben().
const ZUSTAND_LAGE_DANEBEN := "%d Pixel %s, %d Pixel %s der Mitte des nutzbaren Bereichs"

# --- Eigene Fehler des Läufers (meldung: [selbsttest] …, CHK007) ---------------------------------

## Der frische Titel stand nicht innerhalb der Höchstzeit.
const TITEL_KAM_NICHT := "Der Titel ließ sich nicht neu laden"
## Den Ordner der Spielstände leert der Läufer nur unter user://selbsttest/; %s ist der Ordner.
const ORDNER_NICHT_GELEERT := "Ordner %s ist nicht der des Selbsttests und bleibt, wie er ist"
## Das laufende Spiel ließ sich vor dem frischen Titel nicht beenden; %s ist der Grund.
const SPIEL_NICHT_BEENDET := "Das laufende Spiel ließ sich nicht beenden: %s"
## Eine Datei des Laufs ließ sich nicht schreiben: Datei und Grund.
const NICHT_GESCHRIEBEN := "%s ließ sich nicht schreiben: %s"

# --- Zusammenfassung -----------------------------------------------------------------------------

const BEREICHSTITEL := "Was nicht stimmt"
## Zeichen im Feld vor einem Eintrag der Liste: Fehler und nicht gelaufen (CHK019).
const ZEICHEN_FEHLER := "!"
const ZEICHEN_NICHT_GELAUFEN := "–"
const KNOPF_KOPIEREN := "Kopieren"
const KNOPF_ORDNER_ZEIGEN := "Ordner zeigen"
const KNOPF_BEENDEN := "Beenden"
const TOOLTIP_KOPIEREN := "Legt das Ergebnis als Text in die Zwischenablage."
const TOOLTIP_ORDNER_ZEIGEN := "Zeigt das Zip dieses Laufs im Dateimanager."
const TOOLTIP_BEENDEN := "Beendet den Selbsttest."
## Tooltip von „Ordner zeigen“, wenn er gesperrt ist, weil sich im Ordner nicht schreiben ließ.
const TOOLTIP_ORDNER_GESPERRT := "Kein Zip: Im Ordner lässt sich nicht schreiben."
const BESTAETIGUNG := "Kopiert."
## Unter Linux mit X11 ist die Zwischenablage nach dem Beenden leer (R11).
const BESTAETIGUNG_LINUX := "Kopiert. Erst einfügen, dann beenden."


## „Selbsttest · Schritt 6 von 45: Neues Spiel“ (CHK035, R22).
static func fenstertitel(nummer: int, gesamt: int, name_des_ablaufs: String) -> String:
	return "Selbsttest · Schritt %d von %d: %s" % [nummer, gesamt, name_des_ablaufs]


## Der Name eines Ablaufs nach seiner Kennung; die Kennung selbst, wenn sie unbekannt ist.
static func ablauf_name(kennung: String) -> String:
	return ABLAUF_NAMEN.get(kennung, kennung)


## Der Name der Grafikschnittstelle nach dem Treiber aus
## RenderingServer.get_current_rendering_driver_name(); der Treiber selbst, wenn er unbekannt ist.
static func grafik_api_name(treiber: String) -> String:
	return GRAFIK_API.get(treiber, treiber)


## Die Summe, auf dem Bildschirm und hinter „ergebnis:“ im Protokoll (CHK033): „Alles in Ordnung:
## 45 von 45 Schritten.“ oder „43 von 45 Schritten in Ordnung, 1 Fehler, 1 nicht gelaufen.“ Der
## erste Teil steht immer, Fehler und nicht gelaufen entfallen bei 0.
static func summe(anzahl_ok: int, anzahl_fehler: int, anzahl_nicht_gelaufen: int) -> String:
	var gesamt := anzahl_ok + anzahl_fehler + anzahl_nicht_gelaufen
	if anzahl_ok == gesamt:
		return "Alles in Ordnung: %d %s." % [anzahl_ok, _von_schritten(gesamt)]
	var teile := PackedStringArray(["%d %s in Ordnung" % [anzahl_ok, _von_schritten(gesamt)]])
	if anzahl_fehler > 0:
		teile.append("%d Fehler" % anzahl_fehler)
	if anzahl_nicht_gelaufen > 0:
		teile.append("%d nicht gelaufen" % anzahl_nicht_gelaufen)
	return ", ".join(teile) + "."


## „Selbsttest vom 28.10.2026, 14:03 Uhr“; [param start] ist ein Datum wie aus
## Time.get_datetime_dict_from_system().
static func ueberschrift(start: Dictionary) -> String:
	return "Selbsttest vom %02d.%02d.%04d, %02d:%02d Uhr" % [start["day"], start["month"],
		start["year"], start["hour"], start["minute"]]


## „macOS 26.0.0 · Apple M3 Pro · OpenGL“ aus den Systemdaten; was fehlt, heißt „unbekannt“.
static func systemzeile(system: Dictionary) -> String:
	var teile: Array[String] = []
	for schluessel: String in ["system.os", "system.os_version", "system.gpu", "system.grafik_api"]:
		var wert: Variant = system.get(schluessel)
		teile.append(UNBEKANNT if wert == null or str(wert).is_empty() else str(wert))
	return "%s %s · %s · %s" % teile


## Erste Zeile eines Eintrags der Liste: „neues_spiel.01_gradwahl · Enter auf „Neues Spiel“ öffnet
## die Gradwahl“.
static func eintrag(kennung: String, beschreibung: String) -> String:
	return "%s · %s" % [kennung, beschreibung]


## Zweite Zeile eines Fehlers.
static func erwartet(zustand: String) -> String:
	return "Erwartet: %s" % zustand


## Dritte Zeile eines Fehlers.
static func gefunden(zustand: String) -> String:
	return "Gefunden: %s" % zustand


## Zweite Zeile eines nicht gelaufenen Schritts, mit seinem Grund.
static func nicht_gelaufen(grund: String) -> String:
	return "Nicht gelaufen: %s" % grund


## „Protokoll und Fotos liegen hier: …“ mit dem Pfad des Laufs.
static func pfad(ordner: String) -> String:
	return "Protokoll und Fotos liegen hier: %s" % ordner


## Die Meldung auf dem Bildschirm, wenn sich im Ordner nicht schreiben lässt, als Satz mit Punkt.
static func kein_protokoll(ordner: String) -> String:
	return KEIN_PROTOKOLL % ordner + "."


## gefunden bei FEHLER, wenn der Zustand bis zur Höchstzeit nicht kam (CHK034).
static func zeit_abgelaufen(zustand: String) -> String:
	return "Zeit abgelaufen, zuletzt: %s" % zustand


## gefunden bei FEHLER, wenn der Fahrer ein Ziel nicht findet, etwa „HAUPTMENÜ, „Neues Spiel““.
static func ziel_nicht_gefunden(ziel: String) -> String:
	return "Ziel nicht gefunden: %s" % ziel


## Grund bei NICHT_GELAUFEN für den Rest eines Ablaufs nach einem Fehler.
static func fehler_in_schritt(kennung: String) -> String:
	return "Fehler in Schritt %s" % kennung


## Grund bei NICHT_GELAUFEN für einen Ablauf, der auf einem gescheiterten aufbaut (FR-009).
static func fehler_in_ablauf(kennung: String) -> String:
	return "Fehler in Ablauf %s" % kennung


## Ein Menüeintrag als Ziel in der Form der Spalte „Erwartet“: „HAUPTMENÜ, „Neues Spiel““
## (Phasenprüfung Phase 1, L2), auch „SPIELSTÄNDE, „Zurück““. So steht es auch in „Ziel nicht
## gefunden: …“. Grade und Spielstände stehen ohne Anführungszeichen, siehe ziel_ohne_zeichen().
static func ziel(kopf: String, eintrag: String) -> String:
	return "%s, „%s“" % [kopf, eintrag]


## Ein Grad oder Spielstand als Ziel, ohne Anführungszeichen (CHK031): „SCHWIERIGKEIT, Leicht“,
## „SPIELSTÄNDE, Spiel 1“.
static func ziel_ohne_zeichen(kopf: String, wert: String) -> String:
	return "%s, %s" % [kopf, wert]


## „Menü steht: HAUPTMENÜ, „Neues Spiel““ (contracts/ablaeufe.md, „Gemeinsame Prüfungen“).
static func menue_steht(kopf: String, eintrag: String) -> String:
	return "Menü steht: " + ziel(kopf, eintrag)


## „Menü steht: SCHWIERIGKEIT, Mittel“ für einen Grad oder Spielstand.
static func menue_steht_ohne_zeichen(kopf: String, wert: String) -> String:
	return "Menü steht: " + ziel_ohne_zeichen(kopf, wert)


## „Seite HAUPTMENÜ, keine Zeile gewählt“, wenn keine Zeile den Fokus hat. „Menü steht“ heißt
## dagegen, dass eine Zeile ihn hat.
static func seite_ohne_zeile(kopf: String) -> String:
	return "Seite %s, %s" % [kopf, ZUSTAND_KEINE_ZEILE]


## „„Beenden“ ausgelöst“.
static func ausgeloest(eintrag: String) -> String:
	return ZUSTAND_AUSGELOEST % eintrag


## Erwartung einer gewählten Zeile mit ihrem Hinweis, die nichts auslöst (titel.02, titel.03):
## „Menü steht: HAUPTMENÜ, „Beenden“, verfügbar, Hinweis „…“; nichts ausgelöst“.
## [param verfuegbarkeit] ist VERFUEGBAR, NICHT_VERFUEGBAR oder "", wenn der Schritt sie nicht nennt.
static func zeile_ohne_ausloesen(kopf: String, eintrag: String, hinweis_text: String,
		verfuegbarkeit: String) -> String:
	var teile := PackedStringArray([menue_steht(kopf, eintrag)])
	if not verfuegbarkeit.is_empty():
		teile.append(verfuegbarkeit)
	teile.append(hinweis(hinweis_text))
	return "%s; %s" % [", ".join(teile), NICHTS_AUSGELOEST]


## „Spielstände: keine“ oder „Spielstände: Spiel 1, Spiel 2“ (CHK032).
static func spielstaende(namen: PackedStringArray) -> String:
	return "Spielstände: %s" % ("keine" if namen.is_empty() else ", ".join(namen))


## „Hinweis „Noch kein Spiel angefangen.““; leer heißt „Hinweis aus“.
static func hinweis(text: String) -> String:
	return ZUSTAND_KEIN_HINWEIS if text.is_empty() else "Hinweis „%s“" % text


## Eingabe „Maus über „Weiterspielen““.
static func maus_ueber(eintrag: String) -> String:
	return "Maus über %s" % zitat(eintrag)


## Ein Menüeintrag in Anführungszeichen: „„Neues Spiel““. Grade und Spielstände stehen ohne.
static func zitat(eintrag: String) -> String:
	return "„%s“" % eintrag


## Eine Eingabe auf ein Ziel: „Enter auf „Weiterspielen““, „Linksklick auf Spiel 1“.
## [param ziel] steht schon in seiner Form, mit zitat() oder ohne.
static func auf(eingabe: String, ziel: String) -> String:
	return "%s auf %s" % [eingabe, ziel]


## Eine Taste, bis ein Ziel gewählt ist: „Pfeil runter bis „Spiel laden““.
static func bis(eingabe: String, ziel: String) -> String:
	return "%s bis %s" % [eingabe, ziel]


## Eine gehaltene Taste: „Pfeil rechts halten 0,5 s“; [param ms] in Millisekunden, deutsch mit
## Komma.
static func halten(taste: String, ms: int) -> String:
	return "%s halten %s s" % [taste, str(ms / 1000.0).replace(".", ",")]


## Gehäusetasten nach Index von links ab 0, mit ihrer Lage: „Gehäusetasten Mitte, links, rechts“.
static func gehaeusetasten(folge: Array[int]) -> String:
	var lagen := PackedStringArray()
	for index in folge:
		lagen.append(_lage_der_taste(index))
	return "Gehäusetasten %s" % ", ".join(lagen)


## Eine Gehäusetaste, etwa in „Ziel nicht gefunden: Gehäusetaste rechts“.
static func gehaeusetaste(index: int) -> String:
	return "Gehäusetaste %s" % _lage_der_taste(index)


## Eine Vorbereitung vor den Eingaben: „Vorbereitung: 7 Spielstände; Linksklick auf …“ (CHK001);
## ohne [param danach] nur „Vorbereitung: …“.
static func vorbereitung(was: String, danach: String = "") -> String:
	if danach.is_empty():
		return "%s: %s" % [EINGABEN_VORBEREITUNG, was]
	return "%s: %s; %s" % [EINGABEN_VORBEREITUNG, was, danach]


## Eine Eingabe über einem Ziel: „Mausrad runter über Spiel 1“.
static func ueber(eingabe: String, ziel: String) -> String:
	return "%s über %s" % [eingabe, ziel]


## Erwartung von easter_egg.04: „Kanone weiter rechts als beim Start; ein Schuss unterwegs oder
## ein Treffer gezählt“.
static func kanone_und_schuss() -> String:
	return zustaende([ZUSTAND_KANONE_RECHTS, "%s oder %s" % [ZUSTAND_SCHUSS, ZUSTAND_TREFFER]])


## „0 Pixel rechts, 2 Pixel unter der Mitte des nutzbaren Bereichs“ für [param versatz] in Pixeln;
## ein negativer Versatz heißt links und über.
static func lage_daneben(versatz: Vector2i) -> String:
	return ZUSTAND_LAGE_DANEBEN % [absi(versatz.x), "links" if versatz.x < 0 else "rechts",
		absi(versatz.y), "über" if versatz.y < 0 else "unter"]


## „Spielbildschirm, „Zum Hauptmenü“ ohne Fokus, Hinweis „…““: Der Spielbildschirm ist da, aber
## sein Knopf hat nicht den Fokus, also steht er nicht (B4, N3). Den Wortlaut des Knopfs gibt
## TitleTexts.
static func spielbildschirm_ohne_fokus(hinweis_text: String) -> String:
	return "%s, %s" % [ZUSTAND_SPIELBILDSCHIRM_OHNE_FOKUS % TitleTexts.LABEL_LEAVE,
		hinweis(hinweis_text)]


## Was bedienung.06 vorbereitet: „1 Spielstand“, „7 Spielstände“, Zahlwort nach der Zahl wie bei
## den Schritten (N5).
static func spielstaende_anzahl(anzahl: int) -> String:
	return "%d %s" % [anzahl, "Spielstand" if anzahl == 1 else "Spielstände"]


## Ein Text aus dem Spiel in „gefunden:“, etwa eine Meldung von SaveStore, in Anführungszeichen;
## so behält er seinen Schlusspunkt (CHK034).
static func meldung_des_spiels(text: String) -> String:
	return "„%s“" % text


## Die Uhr im Zeitraffer bis zu einem Spieldatum laufen lassen, als Eingabe eines Szenarios: „Uhr
## bis 01.03.1987“.
static func uhr_bis(datum: String) -> String:
	return "Uhr bis %s" % datum


## Eine Fenstergröße als Eingabe: „Fenster auf 1318 × 742“.
static func fenster_auf(groesse: Vector2i) -> String:
	return "%s auf %d × %d" % [EINGABEN_FENSTER, groesse.x, groesse.y]


## „Auswahl wandert: „Spiel laden“, „Neues Spiel“, …“: die gewählten Zeilen nach jeder Taste.
static func auswahl_wandert(zeilen: PackedStringArray) -> String:
	var zitiert := PackedStringArray()
	for zeile in zeilen:
		zitiert.append(zitat(zeile))
	return "Auswahl wandert: %s" % ", ".join(zitiert)


## „Liste oben bei Spiel 2, Rollmarke oben sichtbar“.
static func liste_oben(spielstand: String, marke_oben: bool) -> String:
	return "%s, %s" % [ZUSTAND_LISTE_OBEN % spielstand,
		ZUSTAND_MARKE_OBEN if marke_oben else ZUSTAND_KEINE_MARKE_OBEN]


## „Fenster 3200 × 1800, Bild Faktor 5“ und was folgt, etwa „ohne Rand“. Ein Faktor, der keine
## ganze Zahl ist, steht deutsch mit Komma, etwa „2,5“: Er ist Teil eines Zustands, kein Messwert
## der Systemdaten (Phasenprüfung Phase 3, B7).
static func fenster(groesse: Vector2i, faktor: float, teile: PackedStringArray) -> String:
	var zahl := str(int(faktor)) if is_equal_approx(faktor, roundf(faktor)) \
		else str(faktor).replace(".", ",")
	var text := "Fenster %d × %d, Bild Faktor %s" % [groesse.x, groesse.y, zahl]
	return text if teile.is_empty() else "%s, %s" % [text, ", ".join(teile)]


## Mehrere Eingaben eines Schritts nacheinander: „Maus über „Neues Spiel“, Enter“.
static func eingaben(teile: PackedStringArray) -> String:
	return ", ".join(teile)


## Mehrere Zustände eines Schritts: „Communicator hinausgefahren; Spielbildschirm steht;
## Spielstände: Spiel 1“.
static func zustaende(teile: PackedStringArray) -> String:
	return "; ".join(teile)


## „Spielbildschirm steht, Hinweis „Speichert Spiel 1 und führt ins Hauptmenü.““ (contracts/
## ablaeufe.md, „Spielbildschirm steht“: Der Hinweis nennt das laufende Spiel.)
static func spielbildschirm(hinweis_text: String) -> String:
	return "%s, %s" % [ZUSTAND_SPIELBILDSCHIRM, hinweis(hinweis_text)]


## „Titel neu, Menü steht: …“: Der Titel ist nach dem Spielbildschirm neu erschienen.
static func titel_neu(zustand: String) -> String:
	return "%s, %s" % [ZUSTAND_TITEL_NEU, zustand]


## Was eine Zeile der Liste in den Spalten Grad und Spieldatum zeigt: „Mittel, 01.01.1985“, bei
## einem Spielstand, der sich nicht fortsetzen lässt, sein Zustand.
static func angaben(teile: PackedStringArray) -> String:
	return ", ".join(teile)


## Eine Zeile der Liste mit ihren Angaben: „Spiel 1 mit Mittel, 01.01.1985“; ohne Angaben nur der
## Name.
static func zeile_mit_angaben(spielstand: String, p_angaben: String) -> String:
	if p_angaben.is_empty():
		return spielstand
	return "%s mit %s" % [spielstand, p_angaben]


## Eine Datei des Laufs, etwa ein Foto, ließ sich nicht schreiben: Dateiname und Grund.
static func nicht_geschrieben(datei: String, grund: String) -> String:
	return NICHT_GESCHRIEBEN % [datei, grund]


## „von 1 Schritt“, „von 2 Schritten“: Dativ, nach der Zahl.
static func _von_schritten(anzahl: int) -> String:
	return "von %d %s" % [anzahl, "Schritt" if anzahl == 1 else "Schritten"]


## links, Mitte, rechts für die Gehäusetasten 0, 1, 2; eine weitere heißt nach ihrem Index.
static func _lage_der_taste(index: int) -> String:
	return ["links", "Mitte", "rechts"][index] if index >= 0 and index < 3 else str(index)
