class_name SelbsttestLauf
extends RefCounted

## Ein Lauf des Selbsttests vom Start bis zur Zusammenfassung (Feature 007, data-model.md, „Lauf“
## und „Schritt“): welche Abläufe mit welchen Schritten dran sind, und je Schritt das Ergebnis.
## Aus diesem einen Lauf entstehen Protokoll, Text für „Kopieren“ und Zusammenfassung; deshalb
## können sie sich nie widersprechen (FR-014a).
##
## Der Lauf ist kein Node, wie TimelineRun: Er misst nichts, wartet auf nichts und kennt kein
## Fenster. Der Läufer plant zu Beginn alle Abläufe mit plane() ein; so steht die Zahl der
## Schritte für den Fenstertitel fest. Danach meldet er je Schritt melde_ok() oder melde_fehler().
## Die Regeln aus FR-009 setzt der Lauf selbst um:
## - Scheitert ein Schritt, gilt der Rest seines Ablaufs als nicht gelaufen, mit dem Grund
##   „Fehler in Schritt <kennung>“.
## - Baut ein Ablauf auf einem gescheiterten auf, gilt er ganz als nicht gelaufen, mit dem Grund
##   „Fehler in Ablauf <kennung>“. Das gilt auch über mehrere Stufen: „loeschen“ baut auf „laden“,
##   „laden“ auf „neues_spiel“; scheitert „neues_spiel“, nennen beide „neues_spiel“ als Grund.
## - Wird das Fenster geschlossen, gilt jeder Schritt ab dem laufenden als nicht gelaufen, mit dem
##   Grund „Fenster geschlossen“ (FR-010).
##
## Ein Schritt ist bis zu seinem Ergebnis OFFEN. Im Protokoll gibt es OFFEN nicht; bliebe ein
## Schritt durch einen Fehler im Läufer offen, zählt er als nicht gelaufen.

## Ergebnis eines Schritts. OFFEN heißt „noch kein Ergebnis“.
enum Status { OFFEN, OK, FEHLER, NICHT_GELAUFEN }

## Wie der Status im Protokoll heißt (contracts/protokoll.md).
const STATUS_TEXT := {
	Status.OFFEN: "NICHT_GELAUFEN",
	Status.OK: "OK",
	Status.FEHLER: "FEHLER",
	Status.NICHT_GELAUFEN: "NICHT_GELAUFEN",
}


## Ein Schritt mit seiner Beschreibung aus dem Ablauf und seinem Ergebnis (data-model.md,
## „Schritt“). Die Callables des Ablaufs hält der Lauf nicht; die braucht nur der Läufer.
class Schritt:
	extends RefCounted

	## „<ablauf>.<nn>_<kurz>“, etwa „neues_spiel.04_grad_mittel“; zugleich Name des Fotos.
	var kennung: String = ""
	## Kennung des Ablaufs.
	var ablauf: String = ""
	var beschreibung: String = ""
	## Die Eingaben in Worten, etwa „Maus über „Neues Spiel“, Enter“; aus eingaben_text des Ablaufs.
	var eingaben: String = ""
	## Der erwartete Zustand in Worten, aus erwartet_text des Ablaufs.
	var erwartet: String = ""
	var hoechstzeit_ms: int = SelbsttestAblauf.HOECHSTZEIT_MS
	var foto_vergleichbar: bool = true
	## Faktor des Zeitraffers, mit dem der Schritt lief; aus dem Ablauf.
	var zeitraffer: int = SelbsttestAblauf.ZEITRAFFER
	var status: SelbsttestLauf.Status = SelbsttestLauf.Status.OFFEN
	## Bei FEHLER der gefundene Zustand, bei NICHT_GELAUFEN der Grund; sonst leer.
	var gefunden: String = ""
	## Dauer in Millisekunden echter Zeit; -1, solange es keine gibt.
	var dauer_ms: int = -1
	## Fehler und Warnungen aus Godot während des Schritts, in der Reihenfolge des Auftretens.
	var meldungen: PackedStringArray = PackedStringArray()

	## Dateiname des Fotos, „<kennung>.png“.
	func foto() -> String:
		return kennung + ".png"

	## true, wenn der Schritt ein Ergebnis mit Foto hat: OK oder FEHLER.
	func gelaufen() -> bool:
		return status == SelbsttestLauf.Status.OK or status == SelbsttestLauf.Status.FEHLER


## Datum und Uhrzeit des Starts, lokal, wie aus Time.get_datetime_dict_from_system().
var start: Dictionary
## „2026-10-28_14-03-12“: Name des Ordners und Anfang des Zips (data-model.md).
var id: String
## Die Systemdaten aus SelbsttestSystem.werte; ein fehlender Wert ist null.
var system: Dictionary = {}
## selbsttest.version, die Nummer der Abläufe aus dem Läufer (R21); -1 heißt unbekannt.
var version: int = -1
## Der Faktor der Abläufe im Zeitraffer, für lauf.zeitraffer (R24).
var zeitraffer: int = SelbsttestAblauf.ZEITRAFFER
## Die feste Uhrzeit, mit der das Spiel rechnet, als Unix-Zeit in UTC (R7); -1 heißt unbekannt.
var feste_zeit: int = -1
## Der feste Versatz zu UTC in Minuten, mit dem das Spiel Uhrzeiten zeigt (R7).
var feste_zeitzone: int = 60
## Dauer des ganzen Laufs in Millisekunden; -1 heißt unbekannt.
var dauer_ms: int = -1
## „keiner“, oder die Kennung des Schritts, in dem das Fenster geschlossen wurde (CHK038).
var abbruch: String = SelbsttestTexte.KEIN_ABBRUCH
## Je Verlust des Fokus: {"kennung": String, "ms": int}, ms seit dem Start des Laufs.
var fokusverluste: Array[Dictionary] = []
## Die eingeplanten Abläufe in ihrer Reihenfolge.
var ablaeufe: Array[SelbsttestAblauf] = []
## Alle Schritte aller Abläufe in ihrer Reihenfolge.
var schritte: Array[Schritt] = []


## Ein Lauf, der zu [param p_start] beginnt; die Vorgabe ist jetzt, in Ortszeit.
func _init(p_start: Dictionary = Time.get_datetime_dict_from_system()) -> void:
	start = p_start
	id = "%04d-%02d-%02d_%02d-%02d-%02d" % [start["year"], start["month"], start["day"],
		start["hour"], start["minute"], start["second"]]


## Plant [param neuer_ablauf] mit seinen [param ablauf_schritte] ein, alle zunächst OFFEN. Baut
## der Ablauf auf einem schon gescheiterten auf, gilt er sofort ganz als nicht gelaufen.
func plane(neuer_ablauf: SelbsttestAblauf, ablauf_schritte: Array[Dictionary]) -> void:
	ablaeufe.append(neuer_ablauf)
	for daten in ablauf_schritte:
		var neu := Schritt.new()
		neu.kennung = daten.get("kennung", "")
		neu.ablauf = neuer_ablauf.kennung
		neu.beschreibung = daten.get("beschreibung", "")
		neu.eingaben = daten.get("eingaben_text", SelbsttestTexte.EINGABEN_KEINE)
		neu.erwartet = daten.get("erwartet_text", "")
		neu.hoechstzeit_ms = daten.get("hoechstzeit_ms", SelbsttestAblauf.HOECHSTZEIT_MS)
		neu.foto_vergleichbar = daten.get("foto_vergleichbar", true)
		neu.zeitraffer = neuer_ablauf.zeitraffer
		schritte.append(neu)
	_sperre_abhaengige()


## Alle Schritte zusammen, für „Schritt n von gesamt“.
func gesamt() -> int:
	return schritte.size()


## Die laufende Nummer eines Schritts im ganzen Lauf, ab 1; 0, wenn es ihn nicht gibt.
func nummer(kennung: String) -> int:
	for i in schritte.size():
		if schritte[i].kennung == kennung:
			return i + 1
	return 0


## Der Schritt mit [param kennung], oder null.
func schritt(kennung: String) -> Schritt:
	for eintrag in schritte:
		if eintrag.kennung == kennung:
			return eintrag
	return null


## Die Schritte des Ablaufs [param ablauf_kennung] in ihrer Reihenfolge.
func schritte_von(ablauf_kennung: String) -> Array[Schritt]:
	var liste: Array[Schritt] = []
	for eintrag in schritte:
		if eintrag.ablauf == ablauf_kennung:
			liste.append(eintrag)
	return liste


## Der Ablauf mit [param ablauf_kennung], oder null.
func finde_ablauf(ablauf_kennung: String) -> SelbsttestAblauf:
	for eintrag in ablaeufe:
		if eintrag.kennung == ablauf_kennung:
			return eintrag
	return null


## true, wenn der Schritt noch kein Ergebnis hat und also laufen soll.
func ist_offen(kennung: String) -> bool:
	var eintrag := schritt(kennung)
	return eintrag != null and eintrag.status == Status.OFFEN


## true, wenn von [param ablauf_kennung] noch ein Schritt offen ist. Ein Ablauf, der auf einem
## gescheiterten aufbaut, hat keinen offenen Schritt mehr; der Läufer überspringt ihn.
func ablauf_offen(ablauf_kennung: String) -> bool:
	for eintrag in schritte_von(ablauf_kennung):
		if eintrag.status == Status.OFFEN:
			return true
	return false


## true, wenn ein Schritt von [param ablauf_kennung] FEHLER hat.
func ablauf_gescheitert(ablauf_kennung: String) -> bool:
	for eintrag in schritte_von(ablauf_kennung):
		if eintrag.status == Status.FEHLER:
			return true
	return false


## Der Schritt [param kennung] ist in Ordnung. Ändert nur einen offenen Schritt.
func melde_ok(kennung: String, p_dauer_ms: int,
		p_meldungen: PackedStringArray = PackedStringArray()) -> void:
	var eintrag := schritt(kennung)
	if eintrag == null or eintrag.status != Status.OFFEN:
		return
	eintrag.status = Status.OK
	eintrag.dauer_ms = p_dauer_ms
	eintrag.meldungen = p_meldungen


## Der Schritt [param kennung] ist gescheitert, [param p_gefunden] ist der gefundene Zustand. Der
## Rest seines Ablaufs und jeder Ablauf, der darauf aufbaut, gilt als nicht gelaufen (FR-009).
## Ändert nur einen offenen Schritt.
func melde_fehler(kennung: String, p_gefunden: String, p_dauer_ms: int,
		p_meldungen: PackedStringArray = PackedStringArray()) -> void:
	var eintrag := schritt(kennung)
	if eintrag == null or eintrag.status != Status.OFFEN:
		return
	eintrag.status = Status.FEHLER
	eintrag.gefunden = p_gefunden
	eintrag.dauer_ms = p_dauer_ms
	eintrag.meldungen = p_meldungen
	for rest in schritte_von(eintrag.ablauf):
		if rest.status == Status.OFFEN:
			_nicht_gelaufen(rest, SelbsttestTexte.fehler_in_schritt(kennung))
	_sperre_abhaengige()


## Das Fenster wurde während des Schritts [param kennung] geschlossen (FR-010): lauf.abbruch nennt
## ihn, und jeder noch offene Schritt gilt als nicht gelaufen, auch dieser.
func brich_ab(kennung: String) -> void:
	abbruch = kennung
	for eintrag in schritte:
		if eintrag.status == Status.OFFEN:
			_nicht_gelaufen(eintrag, SelbsttestTexte.FENSTER_GESCHLOSSEN)


## Vermerkt einen Verlust des Fokus während [param kennung], [param ms] nach dem Start.
func vermerke_fokusverlust(kennung: String, ms: int) -> void:
	fokusverluste.append({"kennung": kennung, "ms": ms})


## Zahl der Schritte je Ergebnis: {"ok", "fehler", "nicht_gelaufen", "gesamt"}. Ein offener
## Schritt zählt als nicht gelaufen.
func summe() -> Dictionary:
	var zahlen := {"ok": 0, "fehler": 0, "nicht_gelaufen": 0, "gesamt": schritte.size()}
	for eintrag in schritte:
		match eintrag.status:
			Status.OK:
				zahlen["ok"] += 1
			Status.FEHLER:
				zahlen["fehler"] += 1
			_:
				zahlen["nicht_gelaufen"] += 1
	return zahlen


## Der Satz der Summe, auf dem Bildschirm und hinter „ergebnis:“ (CHK033).
func summe_text() -> String:
	var zahlen := summe()
	return SelbsttestTexte.summe(zahlen["ok"], zahlen["fehler"], zahlen["nicht_gelaufen"])


## true, wenn jeder Schritt in Ordnung ist.
func alles_in_ordnung() -> bool:
	return summe()["ok"] == schritte.size()


## Die Schritte, die nicht in Ordnung sind, in ihrer Reihenfolge: für die Liste der
## Zusammenfassung und den Text für „Kopieren“.
func nicht_in_ordnung() -> Array[Schritt]:
	var liste: Array[Schritt] = []
	for eintrag in schritte:
		if eintrag.status != Status.OK:
			liste.append(eintrag)
	return liste


## Setzt jeden Ablauf, der auf einem gescheiterten aufbaut, ganz auf nicht gelaufen. Der Grund
## nennt den Ablauf, in dem der Fehler steckt, auch über mehrere Stufen.
func _sperre_abhaengige() -> void:
	for eintrag in ablaeufe:
		if eintrag.baut_auf.is_empty():
			continue
		var ursache := _ursache(eintrag.baut_auf, [])
		if ursache.is_empty():
			continue
		for offen in schritte_von(eintrag.kennung):
			if offen.status == Status.OFFEN:
				_nicht_gelaufen(offen, SelbsttestTexte.fehler_in_ablauf(ursache))


## Die Kennung des Ablaufs, an dessen Fehler [param ablauf_kennung] scheitert: er selbst, wenn er
## einen FEHLER hat, sonst der, auf dem er aufbaut, und so weiter; leer, wenn keiner scheiterte.
## [param gesehen] schützt vor einem Kreis aus baut_auf.
func _ursache(ablauf_kennung: String, gesehen: Array[String]) -> String:
	if ablauf_kennung in gesehen:
		return ""
	gesehen.append(ablauf_kennung)
	if ablauf_gescheitert(ablauf_kennung):
		return ablauf_kennung
	var eintrag := finde_ablauf(ablauf_kennung)
	if eintrag == null or eintrag.baut_auf.is_empty():
		return ""
	return _ursache(eintrag.baut_auf, gesehen)


static func _nicht_gelaufen(eintrag: Schritt, grund: String) -> void:
	eintrag.status = Status.NICHT_GELAUFEN
	eintrag.gefunden = grund
