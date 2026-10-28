class_name SelbsttestProtokoll
extends RefCounted

## Text von protokoll.txt und Text für „Kopieren“ aus einem SelbsttestLauf (Feature 007,
## contracts/protokoll.md; R9). Beide entstehen in derselben Funktion, _text(); sie unterscheiden
## sich nur darin, dass „Kopieren“ die Schritte mit OK weglässt und am Ende den Ordner nennt
## (FR-014a). So können Datei und kopierter Text nie auseinanderlaufen.
##
## Regeln aus dem Vertrag:
## - Zeilenende "\n" auf allen Systemen; den Text als UTF-8 ohne BOM zu schreiben, ist Sache von
##   SelbsttestAblage (FileAccess.store_string() schreibt kein BOM).
## - Jede Zeile ist leer, eine Überschrift „# …“ oder eine Angabe „schlüssel: wert“.
## - Schlüssel sind fest, in fester Reihenfolge, und fehlen nie; ein fehlender Wert heißt
##   „unbekannt“. Ein Zeilenumbruch in einem Wert wird zu „⏎“.
## - Zeiten, Maße und Zahlen in Maschinenform: „2026-10-28 14:03:12“, „3024x1964“, „2.0“ (CHK039).
## - Werte ohne Schlusspunkt, nur „ergebnis:“ ist ein Satz (CHK034). Die Wortlaute kommen aus
##   SelbsttestTexte und aus den Abläufen, die so geschrieben sind; Meldungen aus Godot stehen
##   unverändert da.

## Zeichen für einen Zeilenumbruch in einem Wert (contracts/protokoll.md).
const UMBRUCH := "⏎"
## Schlüssel unter „# Lauf“, die aus den Systemdaten kommen, in ihrer Reihenfolge; davor stehen
## die des Laufs selbst (siehe _text()).
const PROGRAMM_SCHLUESSEL: Array[String] = ["selbsttest.gebaut", "computerladen.version",
	"godot.version"]

## Welcher Text entsteht.
enum _Art { DATEI, KOPIEREN, NICHT_BESCHREIBBAR }


## Der Text von protokoll.txt.
static func protokoll(lauf: SelbsttestLauf) -> String:
	return _text(lauf, _Art.DATEI, "")


## Der Text für „Kopieren“: wie das Protokoll, unter „# Schritte“ nur die mit FEHLER oder
## NICHT_GELAUFEN, am Ende „ordner:“ mit [param ordner], dem absoluten Pfad des Laufs.
static func kopieren(lauf: SelbsttestLauf, ordner: String) -> String:
	return _text(lauf, _Art.KOPIEREN, ordner)


## Der Text für „Kopieren“, wenn sich in [param ordner] nicht schreiben lässt: Kopf, „# Lauf“,
## „# System“ und die Meldung, ohne Schritte und Summe (Analyse, U5).
static func kopieren_nicht_beschreibbar(lauf: SelbsttestLauf, ordner: String) -> String:
	return _text(lauf, _Art.NICHT_BESCHREIBBAR, ordner)


## Ein Wert in Maschinenform, in einer Zeile: null und leerer Text werden „unbekannt“, Vector2i
## „3024x1964“, eine Kommazahl „2.0“, ein Zeilenumbruch „⏎“.
static func wert(inhalt: Variant) -> String:
	var text: String
	match typeof(inhalt):
		TYPE_NIL:
			text = ""
		TYPE_VECTOR2I:
			var mass: Vector2i = inhalt
			text = "%dx%d" % [mass.x, mass.y]
		TYPE_FLOAT:
			# str() gibt 2.0 als „2.0“ und 1.25 als „1.25“; auf zwei Stellen gerundet, damit aus
			# 59.94000244 nicht „59.94000244140625“ wird.
			text = str(snappedf(inhalt, 0.01))
		_:
			text = str(inhalt)
	if text.is_empty():
		return SelbsttestTexte.UNBEKANNT
	# Erst das Paar \r\n, dann jedes einzelne; so wird aus einem Windows-Umbruch ein Zeichen.
	return text.replace("\r\n", UMBRUCH).replace("\r", UMBRUCH).replace("\n", UMBRUCH)


## „2026-10-28 14:03:12“ aus einem Datum wie aus Time.get_datetime_dict_from_system(); ohne
## Sekunden „2026-10-28 14:03“.
static func zeit_text(datum: Dictionary, mit_sekunden: bool = true) -> String:
	var text := "%04d-%02d-%02d %02d:%02d" % [datum["year"], datum["month"], datum["day"],
		datum["hour"], datum["minute"]]
	if mit_sekunden:
		text += ":%02d" % datum["second"]
	return text


## „2026-10-26 21:40 UTC+01:00“: die Unix-Zeit [param unix] im Versatz [param minuten] zu UTC.
static func feste_zeit_text(unix: int, minuten: int) -> String:
	var ortszeit := Time.get_datetime_dict_from_unix_time(unix + minuten * 60)
	var vorzeichen := "+" if minuten >= 0 else "-"
	var betrag := absi(minuten)
	return "%s UTC%s%02d:%02d" % [zeit_text(ortszeit, false), vorzeichen, floori(betrag / 60.0),
		betrag % 60]


## Die eine Funktion für alle drei Texte.
static func _text(lauf: SelbsttestLauf, art: _Art, ordner: String) -> String:
	var zeilen := PackedStringArray([SelbsttestTexte.KOPF])
	if art != _Art.NICHT_BESCHREIBBAR:
		_angabe(zeilen, "ergebnis", lauf.summe_text())

	zeilen.append("")
	zeilen.append("# Lauf")
	_angabe(zeilen, "lauf.start", zeit_text(lauf.start))
	_angabe(zeilen, "lauf.dauer_ms", _zahl(lauf.dauer_ms))
	_angabe(zeilen, "lauf.feste_zeit", feste_zeit_text(lauf.feste_zeit, lauf.feste_zeitzone)
		if lauf.feste_zeit >= 0 else "")
	_angabe(zeilen, "lauf.zeitraffer", lauf.zeitraffer)
	_angabe(zeilen, "lauf.abbruch", lauf.abbruch)
	_angabe(zeilen, "selbsttest.version", _zahl(lauf.version))
	for schluessel in PROGRAMM_SCHLUESSEL:
		_angabe(zeilen, schluessel, lauf.system.get(schluessel))

	zeilen.append("")
	zeilen.append("# System")
	for schluessel in SelbsttestSystem.SYSTEM_SCHLUESSEL:
		_angabe(zeilen, schluessel, lauf.system.get(schluessel))

	if art == _Art.NICHT_BESCHREIBBAR:
		zeilen.append("")
		_angabe(zeilen, "meldung", SelbsttestTexte.KEIN_PROTOKOLL % ordner)
		return "\n".join(zeilen) + "\n"

	zeilen.append("")
	zeilen.append("# Fokus")
	_angabe(zeilen, "fokus.verluste", lauf.fokusverluste.size())
	for verlust in lauf.fokusverluste:
		_angabe(zeilen, "fokus.verlust", "%s %d" % [verlust["kennung"], verlust["ms"]])

	zeilen.append("")
	zeilen.append("# Schritte")
	for schritt in lauf.schritte:
		if art == _Art.KOPIEREN and schritt.status == SelbsttestLauf.Status.OK:
			continue
		_schritt(zeilen, schritt)
		zeilen.append("")

	# Nach dem letzten Block steht schon eine Leerzeile; ohne Block steht sie hier.
	if zeilen[-1] != "":
		zeilen.append("")
	zeilen.append("# Summe")
	var zahlen := lauf.summe()
	_angabe(zeilen, "summe.ok", zahlen["ok"])
	_angabe(zeilen, "summe.fehler", zahlen["fehler"])
	_angabe(zeilen, "summe.nicht_gelaufen", zahlen["nicht_gelaufen"])
	_angabe(zeilen, "summe.gesamt", zahlen["gesamt"])

	if art == _Art.KOPIEREN:
		zeilen.append("")
		_angabe(zeilen, "ordner", ordner)
	return "\n".join(zeilen) + "\n"


## Ein Block je Schritt. Bei NICHT_GELAUFEN nur schritt, ablauf, status und gefunden mit dem Grund;
## gefunden steht nur bei FEHLER und NICHT_GELAUFEN.
static func _schritt(zeilen: PackedStringArray, schritt: SelbsttestLauf.Schritt) -> void:
	_angabe(zeilen, "schritt", schritt.kennung)
	_angabe(zeilen, "ablauf", schritt.ablauf)
	if not schritt.gelaufen():
		_angabe(zeilen, "status", SelbsttestLauf.STATUS_TEXT[schritt.status])
		_angabe(zeilen, "gefunden", schritt.gefunden)
		return
	_angabe(zeilen, "beschreibung", schritt.beschreibung)
	_angabe(zeilen, "eingaben", schritt.eingaben)
	_angabe(zeilen, "erwartet", schritt.erwartet)
	_angabe(zeilen, "status", SelbsttestLauf.STATUS_TEXT[schritt.status])
	if schritt.status == SelbsttestLauf.Status.FEHLER:
		_angabe(zeilen, "gefunden", schritt.gefunden)
	_angabe(zeilen, "dauer_ms", _zahl(schritt.dauer_ms))
	_angabe(zeilen, "zeitraffer", schritt.zeitraffer)
	_angabe(zeilen, "foto", schritt.foto())
	_angabe(zeilen, "foto_vergleichbar",
		SelbsttestTexte.JA if schritt.foto_vergleichbar else SelbsttestTexte.NEIN)
	for meldung in schritt.meldungen:
		_angabe(zeilen, "meldung", meldung)


## Hängt „schlüssel: wert“ an.
static func _angabe(zeilen: PackedStringArray, schluessel: String, inhalt: Variant) -> void:
	zeilen.append("%s: %s" % [schluessel, wert(inhalt)])


## Eine Zahl, die -1 sein kann, wenn es sie nicht gibt; dann „unbekannt“.
static func _zahl(zahl: int) -> Variant:
	if zahl < 0:
		return null
	return zahl
