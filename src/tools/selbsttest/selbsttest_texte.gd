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


## „von 1 Schritt“, „von 2 Schritten“: Dativ, nach der Zahl.
static func _von_schritten(anzahl: int) -> String:
	return "von %d %s" % [anzahl, "Schritt" if anzahl == 1 else "Schritten"]
