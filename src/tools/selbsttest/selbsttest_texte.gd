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
const BESCHREIBUNG_TITEL_NICHT_VERFUEGBAR := "„%s“ wählen, ohne Spielstand nicht verfügbar"
## titel.03_beenden_da.
const BESCHREIBUNG_TITEL_BEENDEN_DA := "„%s“ wählen, ohne auszulösen"
## Zusatz zu einer Erwartung: Ein Schritt hat nichts ausgelöst. Immer so, nie „nicht ausgelöst“.
const NICHTS_AUSGELOEST := "nichts ausgelöst"
## Die gewählte Zeile ist verfügbar, etwa „Beenden“ in titel.03.
const VERFUEGBAR := "verfügbar"
## Die gewählte Zeile ist nicht verfügbar; steht hinter ihr, auch in „gefunden:“
## (contracts/ablaeufe.md, „Gemeinsame Prüfungen“, „Verfügbarkeit“).
const NICHT_VERFUEGBAR := "nicht verfügbar"

# --- Zustände, wie der Fahrer sie liest -----------------------------------------------------------
# In der Form der Spalte „Erwartet“ (CHK031, CHK032); sie landen in „gefunden:“.

const ZUSTAND_KEIN_BILDSCHIRM := "kein Titel und kein Spielbildschirm"
const ZUSTAND_COMMUNICATOR_FAEHRT := "Communicator nicht in Endlage"
const ZUSTAND_KEINE_SEITE := "keine Seite sichtbar"
const ZUSTAND_KEINE_ZEILE := "keine Zeile gewählt"
const ZUSTAND_SPIELBILDSCHIRM := "Spielbildschirm steht"
## Wie der Vertrag es bei easter_egg.03 schreibt.
const ZUSTAND_KEIN_HINWEIS := "Hinweis aus"
## Seite ohne Kopfzeile, etwa das versteckte Spiel; %s ist der Name des Knotens.
const ZUSTAND_SEITE := "Seite %s sichtbar"
## Ein Eintrag hat ausgelöst, etwa „Beenden“, das der Selbsttest abfängt, statt sich zu beenden;
## %s ist der Wortlaut aus TitleTexts.
const ZUSTAND_AUSGELOEST := "„%s“ ausgelöst"

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
const KNOPF_KOPIEREN := "Kopieren"
const KNOPF_ORDNER_ZEIGEN := "Ordner zeigen"
const KNOPF_BEENDEN := "Beenden"
const TOOLTIP_KOPIEREN := "Legt das Ergebnis als Text in die Zwischenablage."
const TOOLTIP_ORDNER_ZEIGEN := "Zeigt das Zip dieses Laufs im Dateimanager."
const TOOLTIP_BEENDEN := "Beendet den Selbsttest."
const BESTAETIGUNG := "Kopiert."
## Unter Linux mit X11 ist die Zwischenablage nach dem Beenden leer (R11).
const BESTAETIGUNG_LINUX := "Kopiert. Erst einfügen, dann beenden."


## „Selbsttest · Schritt 12 von 40: Neues Spiel“ (CHK035, R22).
static func fenstertitel(nummer: int, gesamt: int, name_des_ablaufs: String) -> String:
	return "Selbsttest · Schritt %d von %d: %s" % [nummer, gesamt, name_des_ablaufs]


## Der Name eines Ablaufs nach seiner Kennung; die Kennung selbst, wenn sie unbekannt ist.
static func ablauf_name(kennung: String) -> String:
	return ABLAUF_NAMEN.get(kennung, kennung)


## Die Summe, auf dem Bildschirm und hinter „ergebnis:“ im Protokoll (CHK033): „Alles in Ordnung:
## 37 von 37 Schritten.“ oder „35 von 37 Schritten in Ordnung, 1 Fehler, 1 nicht gelaufen.“ Der
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


## „macOS 26.0.0 · Apple M3 Pro · Metal“ aus den Systemdaten; was fehlt, heißt „unbekannt“.
static func systemzeile(system: Dictionary) -> String:
	var teile: Array[String] = []
	for schluessel: String in ["system.os", "system.os_version", "system.gpu", "system.grafik_api"]:
		var wert: Variant = system.get(schluessel)
		teile.append(UNBEKANNT if wert == null or str(wert).is_empty() else str(wert))
	return "%s %s · %s · %s" % teile


## Erste Zeile eines Eintrags der Liste: „neues_spiel.01_gradwahl · Enter auf „Neues Spiel““.
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


## gefunden bei FEHLER, wenn der Fahrer ein Ziel nicht findet, etwa „Hauptmenü, new_game“.
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
	return "Maus über „%s“" % eintrag


## Eine Datei des Laufs, etwa ein Foto, ließ sich nicht schreiben: Dateiname und Grund.
static func nicht_geschrieben(datei: String, grund: String) -> String:
	return NICHT_GESCHRIEBEN % [datei, grund]


## „von 1 Schritt“, „von 2 Schritten“: Dativ, nach der Zahl.
static func _von_schritten(anzahl: int) -> String:
	return "von %d %s" % [anzahl, "Schritt" if anzahl == 1 else "Schritten"]
