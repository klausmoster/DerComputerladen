# Anforderungs-Review Checklist: Schwierigkeitsgrade der Zeitleiste

**Purpose**: Prüft, ob Spec und Plan vollständig, eindeutig, widerspruchsfrei und messbar sind,
bevor die Tasks entstehen. Bereiche: Kern (Grad, Start-Modifikatoren, Würfel, Spielstart),
Katalogdatei und Prüfregeln, Werkstatt (Reiter, Formular, Simulator, Statistik),
Abnahmekriterien und Randfälle, Abhängigkeiten zu Feature 002.
**Created**: 2026-10-22
**Feature**: [spec.md](../spec.md), [plan.md](../plan.md)

**Note**: Erzeugt mit `/speckit-checklist`. Geprüft wird, wie die Anforderungen geschrieben sind,
nicht, ob der spätere Code funktioniert.
**Review Ownership**: Die Checkliste gehört dem Prüfer, hier Klaus. Ein Punkt bekommt `[x]` erst,
wenn er die Anforderung dazu für gut genug hält.
**Marker Semantics**: `[x]` heißt, die Anforderung ist geprüft und in Ordnung. Es heißt nicht,
dass etwas gebaut ist.

## Vollständigkeit

- [x] CHK001 Ist festgelegt, wie die Kennung eines Start-Modifikators entsteht und ob Klaus sie
  ändern kann? FR-002 verlangt eine Kennung, sagt aber nicht, woher sie kommt.
  [Gap, Spec §FR-002, §FR-015; Plan R11]
  → Vorschlag, freigegeben von Klaus (2026-10-22): „Neu“ bildet sie aus der Kennung des Ereignisses,
  im Profil eindeutig, etwa `reklamationswelle_2`. Im Reiter lässt sie sich ändern, V30 prüft sie.
  Nichts verweist auf sie, eine Änderung zieht also nichts nach. Ergänzt in FR-015; steht in R11 und
  im Datenmodell.
- [x] CHK002 Ist festgelegt, ob beim Duplizieren eines Ereignisses über Wahrscheinlichkeit seine
  Start-Modifikatoren mitkopiert werden? [Gap, Spec §FR-015, §FR-017]
  → Vorschlag, freigegeben von Klaus (2026-10-22): nein. Die Kopie bekommt eine neue Kennung und hat
  in keinem Profil einen Start-Modifikator; Klaus legt bei Bedarf welche an. So hält es Feature 002
  schon mit Folgeereignissen anderer Ereignisse, die auf das Original zeigen. Ergänzt in den Edge
  Cases.
- [x] CHK003 Ist festgelegt, was mit Start-Modifikatoren geschieht, wenn Klaus die Art ihres
  Ereignisses ändert, etwa die Reklamationswelle von „über Wahrscheinlichkeit“ auf „fix“?
  [Gap, Spec §FR-012; Plan R10]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Sie bleiben stehen, und V26 zeigt sie als Fehler.
  Ob er sie löscht oder die Art zurückstellt, hält Klaus selbst in der Hand; Cmd+Z nimmt die
  Änderung zurück. Im Spiel fallen sie weg (FR-013). Ergänzt in den Edge Cases.
- [x] CHK004 Ist festgelegt, was mit einem Start-Modifikator geschieht, dessen Ereignis selbst einen
  Fehler hat und deshalb im Spiel ausgenommen wird (FR-049 von Feature 002)? Der Edge Case
  „Kaputter Verweis“ nennt nur ein unbekanntes Ereignis. [Gap, Spec §FR-013; Plan R8]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Er fällt mit weg, und der Spielstart nennt ihn
  eigens: „… Das Ereignis „reklamationswelle“ wird übersprungen, deshalb auch dieser
  Start-Modifikator.“ So hält es Feature 002 mit Folgeereignissen. Ergänzt in FR-013.
- [x] CHK005 Ist festgelegt, wie Simulator, Statistik und Textausgabe mit fehlerhaften
  Start-Modifikatoren umgehen? FR-013 spricht nur vom Spielstart, FR-042 von Feature 002 nur von
  Ereignissen. [Gap, Spec §FR-013, §FR-018, §FR-020, §FR-021]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Alle drei nehmen sie aus wie das Spiel und nennen
  sie. Simulator und Statistik tun das im Hinweis „Ausgenommen, weil fehlerhaft“, die Textausgabe
  auf stderr mit Exit-Code 1. Ergänzt in FR-013 und den Verträgen.
- [x] CHK006 Ist festgelegt, dass Cmd+Z Änderungen an Profilen zurücknimmt und dass die
  Sicherungskopie sie enthält? FR-016 nennt nur Speichern und „ungespeichert“.
  [Gap, Spec §FR-016]
  → Vorschlag, freigegeben von Klaus (2026-10-22): ja. Profile nutzen denselben Verlauf und dieselbe
  Sicherungskopie wie der Katalog (FR-034 und FR-050 von Feature 002). Jede Änderung im Profil ist
  ein Schritt im Verlauf, mit Namen wie „Wert von Schwer: reklamationswelle“. Ergänzt in FR-016;
  steht in R10.
- [x] CHK007 Gilt „Katalog geändert, neu starten“ aus FR-042 von Feature 002 auch, wenn Klaus nur
  ein Profil ändert? [Gap, Spec §FR-018, §FR-020]
  → Vorschlag, freigegeben von Klaus (2026-10-22): ja, für Simulator und Statistik, denn ein Profil
  gehört zum Katalog. Ergänzt in FR-018 und FR-020; die Verträge decken es über `content_key()` ab.
- [x] CHK008 Ist festgelegt, ob der ausgelieferte Katalog am Ende des Features gefüllte Profile
  haben muss? Ohne Start-Modifikatoren wären Leicht und Schwer im Spiel wie Mittel (Edge Case
  „Leeres Profil“). US1 nennt aber als Beispiel eine Reklamationswelle, die bei Leicht seltener
  kommt. [Gap, Spec US1, Annahmen; Plan R18]
  → Entschieden (Klaus, 2026-10-22, nach Empfehlung): ja, mit Test. Zur Gesamtabnahme hat der echte
  Katalog in Leicht und Schwer je mindestens einen Start-Modifikator. Die Werte legt Klaus fest,
  Ausgangspunkt ist R18. `test_shipped_catalog.gd` prüft, dass beide Profile nicht leer sind, prüft
  aber keine Werte. Einarbeiten in Annahmen, Plan (Phase 3) und Vertrag.
- [x] CHK009 Ist festgelegt, wie die Prüfung eine Meldung zu einem Start-Modifikator zeigt? In der
  Spalte „Ereignis“ steht bei Meldungen ohne Ereignis heute nur „–“. [Gap, Spec §FR-016]
  → Vorschlag, freigegeben von Klaus (2026-10-22): In der Spalte steht „Profil Schwer“, im Feld
  `profiles.schwer[2].reason`. Der Text nennt Grad und Start-Modifikator. Dafür ändert sich
  `issues_panel.gd` ein wenig; FR-016, R11 und der Vertrag nennen es.

## Klarheit

- [x] CHK010 Ist definiert, welche Termine von einem veränderten Ereignis „abhängen“ (FR-009; US1,
  Szenario 4)? Die Spec nennt nur Beispiele: Folgen und Ereignisse mit Bedingungen.
  [Clarity, Spec §FR-009, SC-002; Plan R7]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Abhängig ist alles, was von einem veränderten
  Ereignis aus erreichbar ist, auch über mehrere Stufen. Der Weg führt über Folgeereignisse (von der
  Quelle zur Folge) oder über Bedingungen (vom Ereignis in der Bedingung zum bedingten Ereignis).
  Alles andere bleibt Termin für Termin gleich. Ergänzt in FR-009 und im Datenmodell („Abhängige
  Ereignisse“); daran misst SC-002 (CHK024).
- [x] CHK011 Ist eindeutig, was FR-018 beim Wechsel des Grads mit „Klaus' Eingriffe bleiben dabei
  erhalten wie bei einem Neustart in Feature 002“ meint? Feature 002 hat zwei Neustarts, mit und
  ohne Eingriffe. [Ambiguity, Spec §FR-018; Plan R13]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Der Lauf wird so neu gebaut, wie er war: derselbe
  Seed, derselbe Tag, dieselben angewandten Eingriffe; nur der Grad ist anders. War er „ohne
  Eingriffe“ gestartet, ist es der neue auch. Die gesammelten Eingriffe bleiben immer erhalten.
  FR-018 ist so präzisiert.
- [x] CHK012 Ist ein Start-Modifikator mit dem Wert 0 erlaubt? FR-002 sagt „positiv oder
  negativ“, „Neu“ legt ihn laut Plan mit 0 an. [Ambiguity, Spec §FR-002; data-model.md]
  → Vorschlag, freigegeben von Klaus (2026-10-22): erlaubt und ohne Meldung, wie bei Modifikatoren
  aus Feature 002. Sonst stünde nach „Neu“ sofort eine zweite Meldung da. FR-002 sagt jetzt
  „positiv, negativ oder 0“.
- [x] CHK013 Ist festgelegt, ab wann ein Start-Modifikator wirkt, der mitten im Monat beginnt?
  Gewürfelt wird am Monatsersten. „Schwer +3 ab 15.03.1990“ wirkt deshalb erst ab der Würfelrunde
  am 01.04.1990, das Formular zeigt aber „ab 15.03.1990“. Ebenso gilt ein Ende am 15.06.1994 noch
  für die ganze Würfelrunde im Juni. [Clarity, Spec §FR-007, §FR-015; data-model.md, „Wann er
  wirkt“]
  → Entschieden (Klaus, 2026-10-22, nach Empfehlung): eine Warnung V31, wenn der Beginn nicht der
  Erste oder das Ende nicht der Letzte eines Monats ist. Ihr Text lautet etwa „wirkt ab der
  Würfelrunde am 01.04.1990“. Verworfen: nur beschreiben; nur ganze Monate erlauben. Einarbeiten in
  FR-012, Datenmodell (Prüfregeln), research.md, Verträge und Quickstart.
- [x] CHK014 Ist festgelegt, was als „unbekannter Grad“ gilt (FR-011)? Als Text kommt ein Grad aus
  Textausgabe und Probe, als Zahl beim Spielstart. [Clarity, Spec §FR-011, §FR-019, §FR-021;
  Plan R1]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Als Text gelten nur „leicht“, „mittel“ und
  „schwer“, klein geschrieben; als Zahl nur die drei Werte der Aufzählung. Alles andere lehnt der
  Spielstart ab (FR-011). Die Textausgabe antwortet mit der Aufrufhilfe, und eine Probe ist dann
  unlesbar. Ergänzt in FR-011; steht in R1, R14 und R16.
- [x] CHK015 Ist festgelegt, welche Werte der Vergleich der Grade zeigt und welche nicht? FR-020
  nennt vier Werte. Offen sind die Obergrenze und die Verteilung auf die Jahre aus FR-044 von
  Feature 002. [Clarity, Spec §FR-020; Plan R15]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Der Vergleich zeigt je Grad drei Werte: Ø,
  „Spanne“ (kleinste bis größte Anzahl, etwa „0–14“) und „ohne“. Das sind neun Werte je Ereignis.
  Obergrenze und Verteilung gibt es nur bei einem Grad. Ergänzt in FR-020.
- [x] CHK016 Sind die Abläufe im Reiter „Schwierigkeitsgrade“ so beschrieben, dass Klaus sie vor dem
  Bau beurteilen kann? Gemeint ist: welcher Grad vorn steht, was „Neu“ vorbelegt, ob „Löschen“
  nachfragt und was bei Mittel zu sehen ist. [Clarity, Spec §FR-015; Plan R11]
  → Vorschlag, freigegeben von Klaus (2026-10-22): wie R11:
  - Vorgabe ist Leicht.
  - „Neu“ legt ohne Dialog an, mit dem gewählten Ereignis, dem Wert 0 und dem ganzen Spiel.
  - „Löschen“ fragt nicht nach; Cmd+Z holt den Start-Modifikator zurück.
  - Bei Mittel steht nur der Hinweis „Mittel ist der Katalog ohne Start-Modifikatoren …“.
  - Tabelle und Felder stehen nebeneinander.
- [x] CHK017 Ist festgelegt, welche Texte aus Feature 002 sich sichtbar ändern?
  [Clarity, Spec §FR-021; Plan R13, R15, R16]
  → Vorschlag, freigegeben von Klaus (2026-10-22): zwei. Die Kopfzeile der Textausgabe heißt „# Seed
  4711, Grad Mittel, bis 31.12.1999“. Der Ergebnistext der Statistik heißt „…, Seeds 1 bis 1.000,
  Mittel, ohne Eingriffe; …“. Beide nennen den Grad immer. Gleich bleiben der Stand im Simulator und
  die Markierungen beim Vergleich mit demselben Grad. Ergänzt in FR-020 und FR-021; steht im Plan in
  der Tabelle „Was sich an Feature 002 ändert“.
- [x] CHK018 Ist festgelegt, ob die Anzeige „Je Grad“ im Formular fehlerhafte Start-Modifikatoren
  mitzählt? [Clarity, Spec §FR-015; Plan R12]
  → Vorschlag, freigegeben von Klaus (2026-10-22): nein, wie im Spiel. Die Anzeige zeigt, was ein
  Spiel mit diesem Grad würfeln würde; den Fehler zeigen der Reiter und die Prüfung. Ergänzt in
  FR-015.

## Widerspruchsfreiheit

- [x] CHK019 Passen US1, Szenario 6 und FR-013 zusammen? Das Szenario verlangt eine Meldung „mit
  Kennung und Grund“, FR-013 eine „mit Grad, Kennung und Grund“. [Consistency, Spec US1, §FR-013]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Das Szenario nennt jetzt auch den Grad.
- [x] CHK020 Passen FR-005 und SC-006 („ändert sich nur diese in der Datei“) zum ersten Speichern
  einer Datei aus Feature 002? Dabei bekommt die Zeile `"format": 1` ein Komma, und vier Zeilen
  kommen dazu. [Consistency, Spec §FR-005, SC-006, Edge Case „Ältere Katalogdatei“; Plan R3]
  → Vorschlag, freigegeben von Klaus (2026-10-22): FR-005 und SC-006 gelten für Dateien, die den
  Abschnitt schon haben. Der Edge Case sagt jetzt, dass das erste Speichern genau diese fünf Zeilen
  ändert, und SC-006 wird an einer solchen Datei gemessen.
- [x] CHK021 Ist der Name von 01-05 einheitlich? Spec (Annahmen) und der Vertrag von Feature 002
  sprechen von „01-05 „Neues Spiel““. `docs/features/Feature_Ideas.md` beschreibt 01-05 dagegen
  als „Spielstart zu einem späteren Datum“. [Conflict, Spec Annahmen; Feature_Ideas 01-05]
  → Entschieden (Klaus, 2026-10-22, nach Empfehlung): Die Auswahl des Grads gehört zu 01-05, das
  dann „Neues Spiel: Startdatum, Seed und Grad“ heißt. Der Eintrag in `Feature_Ideas.md` bekommt in
  Phase 6 den Hinweis auf `start_game(seed, difficulty)`; die Spec bleibt. Verworfen: zu 11-05; eine
  eigene Idee.
- [x] CHK022 Deckt die Ausnahme Ereigniskatalog in Grundsatz V der Verfassung die Profile? Sie
  spricht von „den Ereignissen der Zeitleiste“. [Consistency, Verfassung V; Plan, Constitution
  Check]
  → Entschieden (Klaus, 2026-10-22, nach Empfehlung): so lassen. Die Ausnahme gilt der Datei und
  ihrer Pflege in der Werkstatt, die Verfassung bleibt bei 2.1.1. Verworfen: PATCH 2.1.2.
- [x] CHK023 Ist festgelegt, dass Reiter, Anzeige je Grad und Vergleichstabelle ohne neue
  Bausteine aus dem Style-Guide auskommen? Und was geschieht, wenn doch einer nötig wird?
  [Consistency, Verfassung IV; Plan R11, R15]
  → Vorschlag, freigegeben von Klaus (2026-10-22): ja, alle nutzen vorhandene Bausteine aus dem
  Abschnitt „Werkzeuge“. Braucht der Agent einen neuen, etwa Farben für die Grade, hält er an und
  fragt; der Baustein kommt dann zuerst in den Style-Guide. Steht in R11, im Plan und in
  werkstatt.md; kommt in den Auftrag an den Agent.

## Abnahmekriterien

- [x] CHK024 Ist SC-002 messbar? Die Spec sagt, nur „die Termine der veränderten Ereignisse und der
  von ihnen abhängigen“ dürfen sich unterscheiden, aber nicht, wie man den Unterschied feststellt.
  [Measurability, Spec SC-002; Plan R7]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Der Test vergleicht je Seed Mittel und Schwer mit
  `ScheduleDiff`. Jede Markierung und jeder weggefallene Termin muss zu einem Ereignis aus der Hülle
  von CHK010 gehören. Ergänzt in SC-002.
- [x] CHK025 Ist „ohne weitere Grenzen“ in SC-003 genau genug? Die Erwartung 5,4 gilt nur, wenn
  das Ereignis in jedem der 180 Monate kommen kann. [Clarity, Spec SC-003, US4]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Zeitfenster das ganze Spiel, kein Mindestabstand,
  keine Höchstzahl, keine Dauer und keine Bedingungen. Ergänzt in SC-003.
- [x] CHK026 Ist festgelegt, unter welchen Bedingungen SC-004 gemessen wird: headless oder in der
  Werkstatt, auf welchem Rechner, mit oder ohne Eingriffe? [Measurability, Spec SC-004]
  → Vorschlag, freigegeben von Klaus (2026-10-22): in der Werkstatt auf Klaus' Rechner, vom Klick
  auf „Starten“ bis 100 %, ohne Eingriffe, mit dem echten Katalog samt Profilen. Die Statistik zeigt
  die Zeit selbst an. Ergänzt in SC-004.
- [x] CHK027 Lässt sich US1, Szenario 2 sicher prüfen? Dort heißt es: „jedes Spiel bekommt seinen
  eigenen, gewürfelten Seed“. Zwei Würfe können aber zufällig gleich sein.
  [Measurability, Spec US1; `docs/ki_dev.md`, Abschnitt „Tests“]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Der Test setzt den globalen Zufall fest
  (`seed()`), startet zweimal ohne Seed und erwartet zwei verschiedene Seeds im Bereich 0 bis
  2.147.483.647. Das Szenario bleibt, wie es ist; steht in R17 und im Vertrag.
- [x] CHK028 Ist festgelegt, wie viel von Reiter und Vergleichstabelle bei Klaus' Fenstergröße
  1920 × 925 zu sehen sein muss? [Measurability, Plan R11, R15; `docs/ki_dev.md`]
  → Vorschlag, freigegeben von Klaus (2026-10-22): im Reiter mindestens vier Zeilen der Tabelle und
  alle Felder ohne Rollen; in der Statistik alle zehn Spalten ohne waagerechtes Rollen; beides in
  der Vorgabe-Teilung. Der Agent belegt es mit Bildschirmfotos. Steht in R11 und im Vertrag.

## Abläufe und Randfälle

- [x] CHK029 Ist festgelegt, was beim Wechsel des Grads mit Absagen und Verschiebungen geschieht,
  deren Termin es im neuen Grad nicht gibt? Und versucht ein Wechsel Eingriffe neu, die vorher
  nicht anwendbar waren? [Coverage, Spec §FR-018; Plan R13]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Nicht anwendbare Eingriffe nennt der Simulator
  wie beim Laden einer Probe (FR-051 von Feature 002). Neu versucht werden nur die angewandten, „so,
  wie er war“; alle gesammelten versucht „Neu starten mit Eingriffen“. Ergänzt in FR-018 und R13.
- [x] CHK030 Ist festgelegt, was der Vergleich der Grade nach „Abbrechen“ zeigt?
  [Gap, Spec §FR-020]
  → Vorschlag, freigegeben von Klaus (2026-10-22): nur Seeds, die in allen drei Graden fertig sind;
  jeder Grad hat also gleich viele Spiele mit denselben Seeds. Ergänzt in FR-020; steht in R15.
- [x] CHK031 Ist festgelegt, was beim Laden einer Probe mit einem unbekannten Grad geschieht, etwa
  „extrem“ nach einer Änderung von Hand? FR-019 regelt nur die Probe ohne Grad.
  [Gap, Spec §FR-019]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Die Probe ist unlesbar, und die Werkstatt sagt
  es, wie bei einem Seed außerhalb des Bereichs (T099 von Feature 002). Unter einem geratenen Grad
  zeigte sie ein anderes Spiel. Ergänzt in FR-019; steht in R14.
- [x] CHK032 Ist festgelegt, wie die Anzeige „Je Grad“ aussieht, wenn mehrere Start-Modifikatoren
  auf dasselbe Ereignis viele Zeitabschnitte ergeben? [Edge Case, Spec §FR-015]
  → Vorschlag, freigegeben von Klaus (2026-10-22): keine Grenze; die Zeile eines Grads bricht um.
  Gleiche Nachbarn werden zusammengelegt, es erscheinen also nur echte Wechsel. Steht in R12, im
  Datenmodell und im Vertrag.
- [x] CHK033 Ist festgelegt, welchen Katalog ein Wechsel des Grads im Simulator nimmt, wenn Klaus
  den Katalog seit dem Start des Laufs geändert hat? [Coverage, Spec §FR-018; FR-042 von
  Feature 002]
  → Vorschlag, freigegeben von Klaus (2026-10-22): den aktuellen, wie jeder Neustart; der Hinweis
  „Katalog geändert“ verschwindet danach. Ergänzt in FR-018, R13 und im Vertrag.

## Nicht-funktionale Anforderungen

- [x] CHK034 Ist festgelegt, dass Mittel genau wie vor dem Feature rechnet? FR-004 sagt, Mittel
  sei der Katalog ohne Start-Modifikatoren. Dass Fahrplan und Protokoll Zeichen für Zeichen gleich
  bleiben, sagt die Spec nicht; der Plan macht es zur festen Größe. [Gap, Spec §FR-004; Plan R6,
  R17]
  → Vorschlag, freigegeben von Klaus (2026-10-22): als Erfolgskriterium SC-007 aufgenommen: „Mit
  Mittel sind Fahrplan und Protokoll für die Seeds 1, 4711 und 99999 Zeichen für Zeichen wie vor
  diesem Feature“, gemessen an der eingefrorenen Grundlinie.
- [x] CHK035 Gibt es eine Leistungsanforderung für die Prüfung der Profile? SC-011 von Feature 002
  verlangt Prüfung und Änderung unter 100 ms mit 500 Ereignissen und sagt nichts zu Profilen.
  [Gap, Non-Functional; SC-011 von Feature 002]
  → Vorschlag, freigegeben von Klaus (2026-10-22): keine neue Zahl. Profile haben höchstens einige
  Dutzend Einträge. SC-011 gilt weiter, samt der Prüfung der Profile, und `test_large_catalog.gd`
  misst es. Steht im Plan.

## Abhängigkeiten und Annahmen

- [x] CHK036 Ist die Änderung an `catalog_500.json` begründet und freigegeben? Feature 002
  beschreibt die Datei als einmal erzeugt und nie geändert. [Dependency, Plan R17]
  → Entschieden (Klaus, 2026-10-22, nach Empfehlung): freigegeben. `catalog_500.json` und
  `catalog_minimal.json` bekommen in Phase 1 nur den leeren Abschnitt, fünf Zeilen; ihre Ereignisse
  bleiben, wie sie sind. Die eingefrorene Übernahme bleibt unangetastet. Verworfen: die Tests so
  ändern, dass sie den Abschnitt nicht mit vergleichen. Steht so schon in R17.
- [x] CHK037 Ist der Schritt „Klaus speichert den echten Katalog einmal“ in Phase 1 mit anderen
  offenen Werkstätten abgestimmt? Speichert danach noch eine Werkstatt mit dem alten Code, etwa aus
  der Sitzung zu Feature 002, verschwindet der Abschnitt wieder. [Dependency, Plan R3]
  → Vorschlag, freigegeben von Klaus (2026-10-22): Vor dem Speichern schließt Klaus jede ältere
  Werkstatt, mit oder ohne Speichern. Danach öffnet er sie nur noch mit dem neuen Code. Zusätzlich
  warnt die Rückfrage zur fremden Änderung (FR-034 von Feature 002). Steht im Plan und im Quickstart
  bei der Abnahme von Phase 1.
- [x] CHK038 Ist festgelegt, welche Dokumente außerhalb des Features nachgezogen werden? Das
  betrifft die offene Frage „Schwierigkeitsgrade?“ im GDD sowie 11-05 und 11-01 in
  `Feature_Ideas.md`. [Dependency, Spec System, Annahmen]
  → Vorschlag, freigegeben von Klaus (2026-10-22): in Phase 6.
  - 11-05 bekommt den Hinweis, dass die Grade der Zeitleiste mit Feature 003 gebaut sind;
    Wirtschaft und Spielziel bleiben offen.
  - 11-01 bekommt den Hinweis, dass Spielstände den Grad speichern.
  - Die Zeile im GDD ändert Claude nur mit Klaus' OK.

  Steht im Plan, Phase 6.

## Notes

- `[x]` erst, wenn Klaus den Punkt für erledigt hält; offene Punkte bleiben leer, bis sie geklärt
  oder korrigiert sind.
- Jeder Punkt hat einen Vorschlag von Claude. Fünf brauchten Klaus' Entscheidung: CHK008, CHK013,
  CHK021, CHK022 und CHK036. Klaus hat sie am 2026-10-22 entschieden, alle nach Empfehlung.
- Stand 2026-10-22: Alle 38 Punkte sind erledigt. Fünf hat Klaus entschieden, die übrigen 33
  Vorschläge von Claude hat er freigegeben. Eingearbeitet sind alle in Spec, Datenmodell, Verträge,
  research.md, Plan und Quickstart; was sich an der Spec geändert hat, fasst der Plan unter
  „Änderungen an der Spec nach dem Plan“ zusammen.
- Nach der Freigabe steht unter dem Punkt „→ Vorschlag, freigegeben von Klaus: …“ oder
  „→ Entschieden (Klaus): …“, wie bei Feature 002. Eingearbeitet wird in Spec, Datenmodell,
  Verträge, research.md, Plan und Quickstart.
- `/speckit-implement` wird in diesem Projekt nicht verwendet (Verfassung, Grundsatz II).
- `checklists/requirements.md` hat einen eigenen Ablauf über `/speckit-specify` und
  `/speckit-clarify`.
