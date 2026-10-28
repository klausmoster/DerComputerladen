class_name SelbsttestSzenario
extends SelbsttestAblauf

## Rahmen für Szenarien (Feature 007, contracts/selbsttest-app.md, „Szenario“; R27; FR-011a;
## data-model.md, „Szenario“): ein Ablauf, der ein Spiel mit festem Grad und Seed beginnt und dann
## Tag für Tag spielt. An festen Spieldaten trifft er Entscheidungen über die Oberfläche oder prüft
## einen Zustand und fotografiert ihn. Ein Szenario erbt von hier, setzt Kennung, Grad und Seed und
## überschreibt entscheidungen() und pruefpunkte(); schritte() baut daraus die Schritte, der Läufer
## spielt sie wie jeden anderen Ablauf.
##
## Szenarien liegen unter src/tools/selbsttest/szenarien/ und stehen in SelbsttestLaeufer.ABLAEUFE.
## Heute gibt es keins: Die Uhr lässt sich im Spielbildschirm noch nicht bedienen. Der Fahrer
## meldet das bei jedem Spieldatum (SelbsttestTexte.UHR_NICHT_BEDIENBAR), und der Schritt scheitert,
## statt die Uhr an der Oberfläche vorbei laufen zu lassen.
##
## Die Schritte:
## - „00_start“: Vorbereitung, Spiel 1 beginnt mit [member grad] und [member seed]; die Oberfläche
##   kann keinen Seed wählen. Erwartet: der Spielbildschirm mit Spiel 1.
## - Je Spieldatum in der Reihenfolge der Daten: Uhr bis dahin, dann die Entscheidung eingeben oder
##   den Prüfpunkt prüfen. An einem Tag kommen erst die Entscheidungen, dann die Prüfpunkte.

## Grad des neuen Spiels.
var grad: Difficulty.Level = Difficulty.Level.MITTEL
## Seed des neuen Spiels, wie bei GameSession.start_new().
@warning_ignore("shadowed_global_identifier")
var seed: int = 0


## Die Entscheidungen, je { "datum": GameDate, "eingaben": Callable } und wahlweise
## "kennung" (nn_kurz wie bei neuer_schritt()), "beschreibung", "eingaben_text",
## "erwartet": Callable und "erwartet_text". Ohne Kennung heißt der Schritt „nn_entscheidung“
## nach seiner Stelle. Ohne Erwartung gilt die Entscheidung als getroffen, wenn ihre Eingaben
## hinaus sind. Die Basisklasse hat keine.
func entscheidungen(_fahrer: SelbsttestFahrer) -> Array[Dictionary]:
	return []


## Die Prüfpunkte, je { "kennung": nn_kurz, "datum": GameDate, "erwartet": Callable,
## "erwartet_text": String } und wahlweise "beschreibung". Die Kennung heißt wie bei Schritten,
## etwa „03_kontostand“, im Protokoll „<szenario>.03_kontostand“. Die Basisklasse hat keine.
func pruefpunkte(_fahrer: SelbsttestFahrer) -> Array[Dictionary]:
	return []


## Start, dann Entscheidungen und Prüfpunkte nach Spieldatum.
func schritte(fahrer: SelbsttestFahrer) -> Array[Dictionary]:
	var spiel := SaveGame.default_name(1)
	var liste: Array[Dictionary] = [neuer_schritt("00_start",
		SelbsttestTexte.BESCHREIBUNG_SZENARIO_START % [spiel, Difficulty.label(grad), seed],
		SelbsttestTexte.vorbereitung(SelbsttestTexte.SZENARIO_SPIEL % [spiel,
			Difficulty.label(grad), seed]),
		fahrer.starte_spiel.bind(grad, seed) if fahrer != null else _nichts,
		_pruefe_spielbildschirm.bind(fahrer, spiel),
		SelbsttestTexte.spielbildschirm(TitleTexts.leave_hint(spiel)))]
	var termine: Array[Dictionary] = []
	for eintrag in entscheidungen(fahrer):
		termine.append({"art": 0, "eintrag": eintrag})
	for eintrag in pruefpunkte(fahrer):
		termine.append({"art": 1, "eintrag": eintrag})
	# sort_custom ist nicht stabil; die Stelle in der Liste entscheidet deshalb bei gleichem Tag.
	for stelle in termine.size():
		termine[stelle]["stelle"] = stelle
	termine.sort_custom(_frueher)
	for termin in termine:
		liste.append(_schritt(fahrer, termin, liste.size()))
	return liste


## Ein Schritt aus einer Entscheidung oder einem Prüfpunkt; [param nummer] ist seine Stelle unter
## allen Schritten, für die Kennung einer Entscheidung ohne eigene.
func _schritt(fahrer: SelbsttestFahrer, termin: Dictionary, nummer: int) -> Dictionary:
	var eintrag: Dictionary = termin["eintrag"]
	var datum: GameDate = eintrag["datum"]
	var entscheidung: bool = termin["art"] == 0
	var nn_kurz: String = eintrag.get("kennung", "%02d_entscheidung" % nummer)
	var vorlage := SelbsttestTexte.BESCHREIBUNG_SZENARIO_ENTSCHEIDUNG if entscheidung \
		else SelbsttestTexte.BESCHREIBUNG_SZENARIO_PRUEFPUNKT
	var beschreibung: String = eintrag.get("beschreibung", vorlage % str(datum))
	var uhr := SelbsttestTexte.uhr_bis(str(datum))
	var eingaben_text := uhr
	var folge: Array = [fahrer.uhr_bis.bind(datum) if fahrer != null else _nichts]
	if entscheidung:
		folge.append(eintrag["eingaben"])
		# Ohne eigenen Text steht nur die Uhr da, nicht „…, keine“ (B17).
		if eintrag.has("eingaben_text"):
			eingaben_text = SelbsttestTexte.eingaben([uhr, eintrag["eingaben_text"]])
	var erwartet: Callable = eintrag.get("erwartet", _nichts)
	# Eine Entscheidung ohne Erwartung prüft nichts; im Protokoll „erwartet: keine“ (Lücke 5).
	var erwartet_text: String = eintrag.get("erwartet_text", SelbsttestTexte.ERWARTET_KEINE)
	return neuer_schritt(nn_kurz, beschreibung, eingaben_text, _nacheinander.bind(folge),
		erwartet, erwartet_text)


## Nach Spieldatum; am selben Tag erst Entscheidungen, dann Prüfpunkte, sonst nach ihrer Stelle.
static func _frueher(a: Dictionary, b: Dictionary) -> bool:
	var tag_a: int = (a["eintrag"]["datum"] as GameDate).to_day_index()
	var tag_b: int = (b["eintrag"]["datum"] as GameDate).to_day_index()
	if tag_a != tag_b:
		return tag_a < tag_b
	if a["art"] != b["art"]:
		return a["art"] < b["art"]
	return a["stelle"] < b["stelle"]


## 00: Spielbildschirm steht mit [param spiel].
func _pruefe_spielbildschirm(fahrer: SelbsttestFahrer, spiel: String) -> String:
	return "" if fahrer.spielbildschirm_steht(spiel) else fahrer.zustand()


## Keine Eingabe, keine Prüfung: gibt "".
func _nichts() -> String:
	return ""
