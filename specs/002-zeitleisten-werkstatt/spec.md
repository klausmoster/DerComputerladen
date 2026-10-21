# Feature Specification: Zeitleisten-Werkstatt

**Feature Branch**: `feature/002-zeitleisten-werkstatt`

**System**: 01 Zeitleiste; baut 01-02 Ereignis-Engine um und nimmt die Ideen 01-04 (Ereignisse als
Daten, hier als Datei im Spielprojekt), 01-06 (Kalender-Ereignisse), 01-07 (beeinflussbare
Wahrscheinlichkeiten) und 10-01 (Demo ablösen) auf

**Created**: 2026-10-20

**Status**: Draft

**Input**: User description: Die Zeitleiste bildet das ganze Spiel ab, das Spiel „spult den Plan
ab“. Es gibt drei Arten von Ereignissen: fixe wie Weihnachten, solche, die beim Spielstart per
Zufall hinzukommen und danach fest geplant sind, und solche, die erst über Wahrscheinlichkeiten
entstehen. Aktionen des Spielers ändern Ereignisse oder die Wahrscheinlichkeit einzelner
Ereignisse. Die Zeitleiste soll sich ohne Spiel testen lassen, bevorzugt in einem kleinen
Werkzeug. Ergänzt: „Ich möchte auch einen Editor für mich haben, bei dem ich diese Events
eintakten kann und ggf. auch erstellen kann. Was ist fix, was kann per Zufall kommen, etc. Ich
will das ja alles nicht im Code oder so rumfummeln.“

## Clarifications

### Gespräch 2026-10-20

Entscheidungen von Klaus vor der Spezifikation, nach dem Vorschlag zu Architektur und Werkzeug:

- Q: Nach welchem Muster wird die Zeitleiste verwaltet? → A: Nach dem Fahrplan-Modell:
  Ereigniskatalog → Fahrplan je Spiel → Abspielen → Melden, mit einem Seed je Spiel, einem eigenen
  Würfel je Ereignis, Eingriffen statt Überschreiben und einem Kern, der ohne Spiel läuft.
  Verworfen: die heutige Engine nur zu erweitern, weil sie keinen Plan hat, in den man vorausschauen
  kann.
- Q: Wo pflegt Klaus die Ereignisse? → A: In einer eigenen Werkstatt im Projekt, die zugleich
  Editor und Simulator ist; der Katalog liegt als JSON-Datei im Spielprojekt statt in GDScript.
  Verworfen: ein Editor-Plugin (alle beteiligten Skripte liefen im Editor, mehr Aufwand, schwerer
  zu prüfen), der Inspector der Entwicklungsumgebung (kein Zeitstrahl, keine Simulation) und
  Obsidian mit Export (kein Zeitstrahl, Exportschritt vor jedem Test).
- Q: Ein Feature oder zwei? → A: Ein Feature 002, umgesetzt in Phasen, die Klaus einzeln freigibt.
- Q: Was gehört außerdem dazu? → A: Kalender-Ereignisse (Weihnachtsgeschäft, Jahreszeiten, CeBIT),
  Ereignisse mit Dauer, eine Statistik über viele Spiele und eine Ausgabe des Fahrplans als Text.

### Session 2026-10-20

- Q: Sollen die Wirkungen eines Ereignisses mit Dauer nur während dieser Dauer gelten, oder bleibt
  jede Wirkung ein einmaliger Anstoß? → A: Je Wirkung wählbar: „gilt nur während des Ereignisses“
  (Vorgabe) oder „einmaliger Anstoß“. Beginn und Ende werden nur für die erste Sorte gemeldet.
- Q: Soll die Werkstatt Änderungen mit Cmd+Z rückgängig machen können, oder reichen Speichern,
  Verwerfen und die Versionsverwaltung? → A: Mehrstufig rückgängig und wiederholen, über alle
  Änderungen am Katalog seit dem Öffnen, auch das Ziehen auf dem Zeitstrahl.
- Q: Wie soll bei einem Ereignis „beim Start gesetzt“ festgelegt werden, wie oft es kommt? → A: Als
  Anzahl von–bis mit einer Wahrscheinlichkeit je Anzahl, zusammen 100 %, Vorgabe: alle gleich.
  Beispiel: 0-mal 30 %, 1-mal 70 %.
- Q: Soll es neben fix, beim Start gesetzt und über Wahrscheinlichkeit eine vierte Art „nur als
  Folge“ geben, für Ereignisse, die nie von selbst kommen? → A: Ja. Ein solches Ereignis kommt nur
  als Folgeereignis eines anderen oder durch einen Eingriff und hat in der Werkstatt weder Datum
  noch Chance.
- Q: Soll die Werkstatt wie ein nüchternes Werkzeug aussehen oder im Look des Computerladens? →
  A: Volle Auflösung und eine normale Schrift, aber mit den Farben des Computerladens aus der
  Hauptpalette; der Style-Guide bekommt dafür einen kurzen Abschnitt „Werkzeuge“.

### Review 2026-10-20

Entscheidungen von Klaus beim Durchgehen der Checkliste [review.md](checklists/review.md):

- Q: Sollen sich Was-wäre-wenn-Proben unter einem Namen speichern und später wieder laden lassen?
  → A: Ja.
- Q: Soll die Werkstatt nach einem Absturz ungespeicherte Änderungen wiederherstellen können? →
  A: Ja, über eine Sicherungskopie, die sie beim nächsten Start anbietet.
- Q: Soll die Werkstatt denselben Seed mit und ohne Eingriffe gegenüberstellen? → A: Ja, der
  Fahrplan markiert die Unterschiede.
- Q: Sollen Seeds auch nach einem Godot-Update dasselbe Spiel ergeben? → A: Nein, gleiche
  Ergebnisse gelten für dieselbe Godot-Version.
- Der Begriff „Eingriff“ war ohne Beispiel unverständlich. User Story 6 heißt deshalb jetzt „Was
  wäre, wenn: Spieleraktionen ausprobieren“, und die Key Entities erklären den Eingriff an einem
  Beispiel.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ein Spiel spult seinen Fahrplan ab (Priority: P1)

Beim Beginn eines Spiels legt die Zeitleiste aus dem Ereigniskatalog und einem Seed, der Startzahl
für den Zufall, den Fahrplan für 1985 bis 1999 an. Fixe Ereignisse stehen an ihrem Datum,
Ereignisse „beim Start gesetzt“ an ihrem gewürfelten Datum. Läuft die Spieluhr, tritt jedes
Ereignis an seinem Tag ein und wird mit seinen Wirkungen gemeldet; Ereignisse über
Wahrscheinlichkeit werden Monat für Monat ausgewürfelt und kommen dazu. Mit demselben Seed verläuft
das Spiel genauso. Den Fahrplan eines Seeds kann Klaus ohne Spiel und ohne Werkstatt als Text
ausgeben lassen.

**Why this priority**: Das ist das Herz des Features. Werkstatt, Simulator, Eingriffe und
Statistik arbeiten alle auf diesem Fahrplan, und erst mit ihm spult das Spiel wirklich einen Plan
ab.

**Independent Test**: Den Fahrplan für einen Seed zweimal als Text ausgeben und vergleichen, dann
für einen anderen Seed; das Spiel bis zum Ende laufen lassen und die Meldungen mit dem Fahrplan
abgleichen. Die Werkstatt wird dafür nicht gebraucht.

**Acceptance Scenarios**:

1. **Given** der Katalog mit den übernommenen Ereignissen, **When** ein Spiel mit dem Seed 4711
   beginnt, **Then** enthält der Fahrplan alle 19 historischen Ereignisse an ihrem Datum, etwa
   „Intel Pentium erscheint“ am 22.03.1993.
2. **Given** der Seed 4711, **When** der Fahrplan zweimal bis zum 31.12.1999 als Text ausgegeben
   wird, **Then** sind beide Ausgaben Zeichen für Zeichen gleich.
3. **Given** ein Test-Katalog mit einem Ereignis „beim Start gesetzt“ (Zeitfenster 1987 bis 1996,
   Anzahl 1 bis 2, Mindestabstand 3 Jahre), **When** der Fahrplan angelegt wird, **Then** liegt
   jeder gesetzte Termin im Zeitfenster, zwei Termine liegen mindestens 3 Jahre auseinander, und
   die Termine stehen ab Spielbeginn fest.
4. **Given** derselbe Test-Katalog, **When** der Fahrplan einmal mit dem Seed 1 und einmal mit dem
   Seed 2 angelegt wird, **Then** unterscheiden sich die gesetzten Termine, und jeder Seed ergibt
   bei jeder Wiederholung wieder seine Termine.
5. **Given** die Spieluhr läuft, **When** der 22.03.1993 erreicht ist, **Then** meldet die
   Zeitleiste „Intel Pentium erscheint“, unter anderem mit der Wirkung „Preis cpu_486 −30 %“, und
   am 05.04.1993 die verzögerte Wirkung „Nachfrage ram +20 %“, wie bisher.
6. **Given** ein Ereignis über Wahrscheinlichkeit mit 100 % Chance pro Monat, **When** das Spiel
   beginnt, **Then** tritt es schon im Januar 1985 ein.
7. **Given** ein Ereignis über Wahrscheinlichkeit tritt ein, **When** Klaus den Fahrplan im
   Simulator ansieht, **Then** steht es dort mit der Herkunft „gewürfelt“, und die Begründung nennt
   den Würfelwert und die Schwelle, die er unterschreiten musste. Die Textausgabe nennt nur die
   Herkunft (präzisiert 2026-10-21).
8. **Given** derselbe Seed, **When** die Spieluhr einmal Tag für Tag und einmal in Monats- und
   Jahressprüngen bis zum Spielende geschaltet wird, **Then** sind beide Protokolle gleich.

---

### User Story 2 - Ereignisse in der Werkstatt anlegen und pflegen (Priority: P1)

Klaus öffnet die Werkstatt und sieht alle Ereignisse des Katalogs. Er legt ein neues an, gibt
Titel und Text ein, wählt Kategorie und Art (fix, beim Start gesetzt, über Wahrscheinlichkeit oder
nur als Folge eines anderen) und stellt Datum oder Zeitfenster, Anzahl, Chance, Dauer, Wirkungen,
Folgeereignisse und Bedingungen ein. Fehler zeigt die Werkstatt, sobald sie entstehen. Er
speichert, und das Spiel nutzt beim nächsten Start den neuen Katalog. Code fasst er dabei nie an.

**Why this priority**: Das ist Klaus' ausdrücklicher Wunsch. Erst mit der Werkstatt wird der
Katalog sein Werkzeug statt einer Datei, die jemand anderes für ihn ändert.

**Independent Test**: In der Werkstatt je ein Ereignis jeder Art anlegen, speichern, die Werkstatt
schließen und wieder öffnen: Alles ist noch da, und die Textausgabe des Fahrplans zeigt die neuen
Termine.

**Acceptance Scenarios**:

1. **Given** die Werkstatt ist offen, **When** Klaus ein neues Ereignis anlegt, den Titel
   „Neubaugebiet am Stadtrand“ eingibt und die Art „beim Start gesetzt“ wählt, **Then** zeigt die
   Werkstatt die Felder Zeitfenster, Anzahl mit Wahrscheinlichkeit je Anzahl und Mindestabstand und
   schlägt die Kennung „neubaugebiet_am_stadtrand“ vor.
2. **Given** Klaus hat ein Ereignis geändert, **When** er speichert und die Werkstatt neu öffnet,
   **Then** ist die Änderung da, und in der Versionsverwaltung erscheinen nur die geänderten Zeilen.
3. **Given** ein fixes Ereignis, **When** Klaus das Datum 12.05.2001 eingibt, **Then** meldet die
   Werkstatt am Feld Datum, dass es außerhalb von 1985 bis 1999 liegt.
4. **Given** „Konkurrent gibt auf“ ist Folgeereignis von „Konkurrent eröffnet“, **When** Klaus
   „Konkurrent gibt auf“ löschen will, **Then** nennt die Werkstatt diesen Verweis und löscht erst
   nach seiner Bestätigung.
5. **Given** es gibt ungespeicherte Änderungen, **When** Klaus die Werkstatt schließt, **Then**
   fragt sie, ob gespeichert werden soll.
6. **Given** Klaus ändert die Kennung eines Ereignisses, **When** er speichert, **Then** zeigen
   alle Folgeereignisse und Bedingungen, die darauf verwiesen haben, auf die neue Kennung.
7. **Given** Klaus hat nacheinander drei Felder geändert, **When** er dreimal Cmd+Z drückt,
   **Then** ist der Stand vor den drei Änderungen wiederhergestellt, und Shift+Cmd+Z stellt sie
   Schritt für Schritt wieder her.

---

### User Story 3 - Jährliche Ereignisse und Ereignisse mit Dauer (Priority: P2)

Das Weihnachtsgeschäft kommt jedes Jahr vom 1. November bis Ende Dezember, die Jahreszeiten
wechseln, und die CeBIT findet jeden März statt. Diese Kalender-Ereignisse stehen im Katalog wie
alle anderen. Ein Ereignis kann eine Dauer haben; dann meldet die Zeitleiste Beginn und Ende. Je
Wirkung legt Klaus fest, ob sie nur während des Ereignisses gilt oder ein einmaliger Anstoß ist.
Die Spieluhr meldet das Weihnachtsgeschäft nicht mehr selbst.

**Why this priority**: Klaus nennt Weihnachten als Beispiel für ein fixes Ereignis. Mit den
Kalender-Ereignissen steht wirklich alles in der Zeitleiste, was etwas auslösen kann, wie es die
Verfassung verlangt, und Wirtschaft und Nachfrage können sich später an Beginn und Ende hängen.

**Independent Test**: Den Fahrplan eines Seeds als Text ausgeben: Das Weihnachtsgeschäft steht in
jedem der 15 Spieljahre mit Beginn am 1. November und Ende mit dem 31. Dezember.

**Acceptance Scenarios**:

1. **Given** der Katalog mit den Kalender-Ereignissen, **When** das Spiel den 01.11.1993 erreicht,
   **Then** meldet die Zeitleiste den Beginn des Weihnachtsgeschäfts und am 01.01.1994 sein Ende.
2. **Given** das Spiel beginnt am 01.01.1985, **When** der erste Spieltag gemeldet wird, **Then**
   gilt der Winter als laufend und wird gemeldet; am 01.03.1985 wird erst sein Ende und danach der
   Beginn des Frühlings gemeldet.
3. **Given** ein Ereignis mit 42 Tagen Dauer beginnt am 10.03.1994, **When** das Spiel weiterläuft,
   **Then** ist der 20.04.1994 sein letzter Tag, und am 21.04.1994 werden sein Ende und das Ende
   seiner Wirkungen gemeldet, die nur während des Ereignisses gelten.
4. **Given** dasselbe Ereignis hat zusätzlich eine Pressemeldung als einmaligen Anstoß, **When** es
   endet, **Then** wird für diese Wirkung kein Ende gemeldet.
5. **Given** das Feature ist fertig, **When** das Weihnachtsgeschäft beginnt oder endet, **Then**
   kommt die Meldung aus der Zeitleiste und nicht mehr aus der Spieluhr.
6. **Given** ein Lieferengpass läuft noch, **When** der Würfel ihn in dieser Zeit erneut auslösen
   würde, **Then** tritt er nicht ein.

---

### User Story 4 - Ereignisse auf dem Zeitstrahl eintakten (Priority: P2)

In der Werkstatt sieht Klaus den ganzen Zeitraum 1985 bis 1999 als Zeitstrahl, eine Zeile je
Kategorie. Fixe Ereignisse sind Punkte oder, mit Dauer, Balken; gesetzte zeigen ihr Zeitfenster,
Ereignisse über Wahrscheinlichkeit ein Band mit ihrer Chance. Er zieht den Pentium mit der Maus
auf ein anderes Datum, zieht das Zeitfenster des Neubaugebiets breiter, vergrößert auf einzelne
Monate und legt per Doppelklick ein neues Ereignis an.

**Why this priority**: Das ist das Eintakten, das Klaus sich wünscht. Wann was passiert, sieht und
ändert er auf einen Blick statt in Zahlenfeldern.

**Independent Test**: Ein fixes Ereignis auf dem Zeitstrahl verschieben und speichern: Die
Textausgabe des Fahrplans zeigt das neue Datum.

**Acceptance Scenarios**:

1. **Given** der Zeitstrahl zeigt 1985 bis 1999, **When** Klaus „Intel Pentium erscheint“ vom
   22.03.1993 auf den 15.04.1993 zieht, **Then** zeigt die Werkstatt beim Ziehen das Datum
   tagesgenau an und übernimmt den 15.04.1993 ins Ereignis.
2. **Given** ein Ereignis „beim Start gesetzt“, **When** Klaus das Ende seines Zeitfensters zieht,
   **Then** ändert sich das Zeitfenster entsprechend, und die Werkstatt meldet sofort, wenn Anzahl
   und Mindestabstand nicht mehr hineinpassen.
3. **Given** die Maus steht über einem Ereignis, **When** sie kurz verweilt, **Then** zeigt ein
   Hinweis Titel, Art, Datum oder Zeitfenster und gegebenenfalls die Chance.
4. **Given** Klaus klickt mit rechts auf ein Ereignis, **When** das Menü erscheint, **Then** bietet
   es Bearbeiten, Duplizieren und Löschen.
5. **Given** Klaus doppelklickt in der Zeile „Hardware“ auf einen Tag im März 1996, **When** der
   Dialog „Neu …“ erscheint, **Then** ist er mit „fix“, diesem Tag und der Kategorie Hardware
   vorbelegt; angelegt wird das Ereignis erst mit „Anlegen“, und eine andere Art ist wählbar
   (Klaus, 2026-10-21, R16; bis dahin legte der Doppelklick das Ereignis sofort an).
6. **Given** der Zeitstrahl, **When** Klaus vergrößert und verschiebt, **Then** lässt er sich vom
   ganzen Zeitraum bis auf einen einzelnen Monat mit sichtbaren Tagen aufziehen.
7. **Given** Klaus hat den Pentium versehentlich verschoben, **When** er Cmd+Z drückt, **Then**
   steht er wieder am 22.03.1993.

---

### User Story 5 - Die Zeitleiste ohne Spiel durchspielen (Priority: P2)

Klaus gibt in der Werkstatt einen Seed ein oder lässt einen würfeln und erzeugt den Fahrplan. Er
schaltet tage-, monats- oder jahresweise weiter oder bis zum Ende und sieht im Protokoll, was
eintritt, was entfällt und was noch geplant ist. Zu jedem Termin sieht er, warum er dort steht.
Das Spiel muss er dafür nicht starten.

**Why this priority**: Klaus will die Zeitleiste ohne Spiel prüfen, am liebsten in einem kleinen
Werkzeug. So sieht er die Folgen jeder Änderung am Katalog sofort.

**Independent Test**: Einen Seed bis zum Spielende durchlaufen lassen, dann mit demselben Seed noch
einmal: Das Protokoll ist gleich und stimmt mit der Textausgabe für diesen Seed überein.

**Acceptance Scenarios**:

1. **Given** der Seed 4711, **When** Klaus den Fahrplan erzeugt, **Then** sieht er alle Termine
   1985 bis 1999, die schon feststehen, mit Herkunft und dem Zustand „geplant“.
2. **Given** ein erzeugter Fahrplan, **When** Klaus „bis zum Ende“ wählt, **Then** ist der
   Durchlauf in unter einer Sekunde fertig, und das Protokoll zeigt alle Meldungen in zeitlicher
   Reihenfolge.
3. **Given** ein gewürfelter Termin, **When** Klaus ihn auswählt, **Then** zeigt die Werkstatt
   Würfelwert, Grundchance, die beteiligten Modifikatoren und die wirksame Schwelle.
4. **Given** Klaus ändert im Katalog die Chance eines Ereignisses, ohne zu speichern, **When** er
   den Durchlauf mit demselben Seed neu startet, **Then** gilt die geänderte Chance, und alle
   Ereignisse, die nicht von diesem abhängen, behalten ihre Termine.
5. **Given** das Spiel ist nicht gestartet, **When** Klaus den Simulator benutzt, **Then** braucht
   dieser weder die laufende Spieluhr noch einen Spielstand und verändert beides nicht.

---

### User Story 6 - Was wäre, wenn: Spieleraktionen ausprobieren (Priority: P2)

Später verändern Spieleraktionen die Zeitleiste: Wer beim windigen Händler kauft, riskiert eher
eine Reklamationswelle, und wer den leeren Laden nebenan mietet, verhindert, dass dort ein
Konkurrent eröffnet. Diese Aktionen gibt es im Spiel noch nicht. Damit Klaus trotzdem sieht, wie
die Zeitleiste auf sie reagiert, stellt er im Simulator von Hand ein, was eine solche Aktion an der
Zeitleiste ändert: Er setzt Modifikatoren mit Grund und Enddatum, sagt Termine ab, verschiebt sie
oder plant neue ein. Der Fahrplan markiert, was sich gegenüber demselben Seed ohne diese Eingriffe
ändert. Eine solche Was-wäre-wenn-Probe kann er unter einem Namen speichern und später wieder
laden. Der Katalog bleibt dabei unverändert.

**Why this priority**: Das ist der zweite Kern von Klaus' Wunsch. Die Mechanik muss stehen und
geprüft sein, bevor es die Spielteile gibt, die sie auslösen.

**Independent Test**: Mit demselben Seed zweimal bis zum Spielende laufen lassen, einmal mit einem
Modifikator auf ein Ereignis: Nur dieses Ereignis und was von ihm abhängt ändert sich.

**Acceptance Scenarios**:

1. **Given** die „Reklamationswelle“ mit 3 % pro Monat, **When** Klaus den Modifikator „Ware vom
   windigen Händler: +5 Prozentpunkte vom 01.01.1990 bis 31.12.1993“ setzt, **Then** würfelt die
   Zeitleiste in den Monaten Januar 1990 bis Dezember 1993 mit 8 %, davor und danach mit 3 %.
2. **Given** derselbe Seed, **When** Klaus den Durchlauf mit diesem Modifikator neu startet,
   **Then** markiert der Fahrplan die Termine der Reklamationswelle, die gegenüber dem Lauf ohne
   Modifikator dazukommen oder wegfallen, und kein Termin eines anderen Ereignisses ist markiert,
   außer er hängt von der Reklamationswelle ab.
3. **Given** ein Ereignis mit 3 % Grundchance und den Modifikatoren „+4“ und „−6“ Prozentpunkte,
   **When** Klaus den Modifikator „+4“ entfernt, **Then** bleibt „−6“ bestehen, die wirksame
   Chance ist 0 %, und die Werkstatt zeigt die Summe −3 % und die Begrenzung auf 0 %.
4. **Given** ein Test-Katalog, in dem „Konkurrent eröffnet“ beim Start auf den 01.06.1992 gesetzt
   wurde, **When** Klaus den Termin am 01.01.1992 mit dem Grund „Laden nebenan selbst gemietet“
   absagt, **Then** steht er mit diesem Grund als abgesagt im Fahrplan und tritt nicht ein.
5. **Given** ein fixer Termin wie „Windows 95“ oder das Weihnachtsgeschäft, **When** Klaus ihn
   absagen oder verschieben will, **Then** lässt die Werkstatt das nicht zu.
6. **Given** ein Modifikator mit dem Enddatum 31.12.1993, **When** das Spiel den 01.01.1994
   erreicht, **Then** wirkt er nicht mehr, ohne dass ihn jemand entfernt hat.
7. **Given** Klaus hat für den Seed 4711 einen Modifikator gesetzt und einen Termin abgesagt,
   **When** er die Probe als „Windiger Händler ab 1990“ speichert, die Werkstatt schließt und die
   Probe später wieder lädt, **Then** sind Seed, Modifikator und Absage wieder gesetzt, und der
   Fahrplan ist derselbe wie vorher.
8. **Given** eine gespeicherte Probe mit einer Absage, **When** Klaus sie lädt, nachdem er den
   Katalog so geändert hat, dass der abgesagte Termin nicht mehr vorkommt, **Then** nennt die
   Werkstatt die Absage als nicht anwendbar und setzt die übrigen Eingriffe.

---

### User Story 7 - Statistik über viele Spiele (Priority: P3)

Klaus lässt die Werkstatt 1.000 Spiele mit verschiedenen Seeds durchrechnen. Je Ereignis sieht er,
wie oft es im Schnitt kommt, wie oft höchstens und mindestens, in wie vielen Spielen gar nicht oder
bis zur Höchstzahl, und in welchen Jahren. So sieht er etwa, dass das Neubaugebiet mit den heutigen
Werten in rund 85 % der Spiele viermal kommt, und stellt nach.

**Why this priority**: Ohne Statistik bleiben Wahrscheinlichkeiten Raterei. Wichtig wird sie aber
erst, wenn der Katalog wächst und Klaus anfängt, Werte nachzustellen.

**Independent Test**: Ein Test-Katalog mit einem Ereignis zu 50 % pro Monat ohne weitere Grenzen:
Der Mittelwert über 1.000 Spiele liegt nahe bei 90.

**Acceptance Scenarios**:

1. **Given** der übernommene Katalog, **When** Klaus die Statistik über 1.000 Spiele startet,
   **Then** zeigt sie ihren Fortschritt, lässt sich abbrechen und liegt nach höchstens 30 Sekunden
   vor.
2. **Given** das Ergebnis, **When** Klaus „Neubaugebiet“ ansieht, **Then** nennt die Statistik
   Mittelwert, kleinste und größte Anzahl, den Anteil der Spiele ohne Neubaugebiet, den Anteil mit
   erreichter Höchstzahl und die Verteilung auf die Jahre.
3. **Given** ein Test-Katalog mit genau einem Ereignis zu 50 % pro Monat ohne Zeitfenster,
   Höchstzahl und Mindestabstand, **When** 1.000 Spiele gerechnet werden, **Then** liegt der
   Mittelwert zwischen 85,5 und 94,5 (180 Monate, Erwartung 90).
4. **Given** Klaus hat im Simulator Modifikatoren gesetzt und Ereignisse eingeplant, **When** er
   die Statistik mit diesen Eingriffen startet, **Then** rechnet sie jedes Spiel mit ihnen.
5. **Given** dieselben Einstellungen, **When** die Statistik zweimal gerechnet wird, **Then** sind
   beide Ergebnisse gleich.
6. **Given** ein Test-Katalog mit einem Ereignis „beim Start gesetzt“, das zu 30 % keinmal und zu
   70 % einmal kommt, **When** 1.000 Spiele gerechnet werden, **Then** fehlt es in 25 % bis 35 %
   der Spiele.

---

### Edge Cases

Prüfregeln für den Katalog. Die Werkstatt benennt jeden Verstoß mit Ereignis und Feld, und die
automatische Prüfung schlägt bei Fehlern fehl:

- Eine Kennung ist leer oder doppelt: Fehler. Doppelte Kennungen lässt die Werkstatt gar nicht erst
  zu.
- Ein Datum oder Zeitfenster liegt außerhalb des 01.01.1985 bis 31.12.1999, oder ein Zeitfenster
  endet vor seinem Beginn: Fehler.
- Ein jährliches Ereignis liegt auf dem 29. Februar: Fehler. Als Ende ist „Monatsende“ erlaubt,
  damit Schaltjahre stimmen.
- Ein Ereignis „beim Start gesetzt“ kann seine höchste Anzahl mit dem Mindestabstand nicht im
  Zeitfenster unterbringen: Fehler. Beim Anlegen des Fahrplans wird der Mindestabstand nie
  verletzt.
- Die Wahrscheinlichkeiten je Anzahl ergeben zusammen nicht 100 %: Fehler.
- Ein Folgeereignis oder eine Bedingung verweist auf eine unbekannte Kennung: Fehler.
- Ein Folgeereignis zeigt auf ein fixes oder jährliches Ereignis: Fehler, denn das Ereignis käme
  sonst an seinem Datum und zusätzlich als Folge.
- Folgeereignisse bilden einen Kreis, der am selben Tag sicher endlos liefe (100 % und ohne
  Verzögerung): Fehler. Läuft trotzdem eine Kette auf, bricht die Zeitleiste sie nach einer festen
  Höchstzahl von Gliedern am selben Tag ab und meldet das.
- Folgeereignisse bilden mit Verzögerung einen Kreis, der mit 100 % sicher immer weiterläuft:
  Warnung. Erlaubt ist das, etwa für regelmäßig wiederkehrende Ereignisse; der Kreis endet mit dem
  Spiel.
- Bei einem Ereignis „beim Start gesetzt“ ist der Mindestabstand kürzer als die Dauer: Fehler, denn
  sonst überlappten sich gesetzte Termine, und einer fiele weg.
- Eine Wirkung, die nur während ihres Ereignisses gelten soll, beginnt wegen ihrer Verzögerung erst
  nach dessen Ende: Fehler. Geprüft wird mit der vollen Dauer. Ist das erste Vorkommen eines
  jährlichen Ereignisses auf den Spielbeginn gekürzt, wie der Winter 1984/85 mit 59 statt 90 Tagen,
  kann eine solche Wirkung dort trotzdem ausfallen; sie beginnt dann nicht und steht auch nicht im
  Fahrplan (präzisiert 2026-10-21; data-model, V19).
- Die Grundchance ist 0 %: Warnung, das Ereignis tritt ohne Modifikator nie ein. Das ist erlaubt,
  etwa für Ereignisse, die erst durch Spieleraktionen möglich werden.
- Eine Wirkung auf Preis, Nachfrage, Ruf oder Kundenstrom hat die Stärke 0: Warnung.
- Ein Ereignis hat keine Wirkung: erlaubt; es ist dann eine reine Meldung.

Verhalten im Lauf:

- Mehrere Termine fallen auf denselben Tag: Sie werden in einer festen Reihenfolge gemeldet, die
  der Fahrplan zeigt; Enden kommen vor Beginnen.
- Ein Ereignis mit Dauer läuft über den 31.12.1999 hinaus oder endet genau dann: Nach dem
  31.12.1999 meldet die Zeitleiste nichts mehr, auch kein Ende. Das Weihnachtsgeschäft 1999 steht
  deshalb mit seinem Ende im Fahrplan, ein Ende wird aber nicht mehr gemeldet.
- Ein Ereignis, das noch läuft, würde erneut eintreten: Es tritt nicht ein.
- Ein jährliches Ereignis läuft schon am ersten Spieltag, wie der Winter am 01.01.1985: Es gilt ab
  Spielbeginn als laufend und wird am ersten Spieltag gemeldet.
- Modifikatoren drücken die Chance unter 0 % oder heben sie über 100 %: Die wirksame Chance wird
  auf 0 % bis 100 % begrenzt; die Werkstatt zeigt Summe und Begrenzung.
- Das Enddatum eines Modifikators ist erreicht: Ab dem Folgetag wirkt er nicht mehr, ohne dass ihn
  jemand entfernt.
- Ein Eingriff träfe einen Termin, der schon eingetreten ist oder hinter dem 31.12.1999 liegt, etwa
  eine Folge am 04.01.2000, oder verschöbe einen Termin auf den aktuellen Spieltag, davor, hinter
  den 31.12.1999 oder auf seinen eigenen Tag: Das ist nicht möglich.
- Beim Spielstart enthält der Katalog fehlerhafte Einträge: Sie werden übersprungen und mit
  Kennung und Grund gemeldet, der Rest läuft.
- Der Katalog fehlt oder ist nicht lesbar: Das Spiel startet trotzdem mit leerer Zeitleiste und
  einer Fehlermeldung, die Datei und Grund nennt. Die Werkstatt nennt die Fehlerstelle und
  überschreibt die Datei nur auf ausdrücklichen Wunsch.
- Der Katalog wurde außerhalb der Werkstatt geändert, während sie offen war: Beim Speichern warnt
  die Werkstatt, statt die fremde Änderung stillschweigend zu überschreiben.
- Klaus bricht die Statistik ab: Sie zeigt das Ergebnis der bis dahin gerechneten Spiele und nennt
  deren Zahl.
- Ein fixes Ereignis, das nicht jährlich ist, liegt am 29.02. eines Schaltjahrs, ein fixes
  Ereignis mit Dauer läuft über den Jahreswechsel, oder ein Ereignis läuft über sein Zeitfenster
  hinaus: Das ist erlaubt;
  das Zeitfenster gilt für die Beginne. Beginnt oder endet ein Zeitfenster mitten im Monat, wird nur
  an Tagen im Fenster gewürfelt.
- Ein Modifikator hat sein Ende vor dem Beginn oder eine schon vergebene Kennung: Er wird
  abgelehnt. Ein Beginn in der Vergangenheit ist erlaubt und wirkt ab der nächsten Würfelrunde, der
  Wert 0 ist erlaubt.
- Es gibt noch keine Katalogdatei: Die Werkstatt bietet an, einen leeren Katalog mit den zehn
  Kategorien anzulegen; geschrieben wird er erst beim Speichern.
- Die Werkstatt stürzt mit ungespeicherten Änderungen ab: Beim nächsten Start mit demselben Katalog
  bietet sie dessen Sicherungskopie an (FR-050); die Kopien anderer Kataloge bleiben liegen, bis
  deren Katalog wieder geöffnet wird (präzisiert 2026-10-21, T078).
- Eine gespeicherte Was-wäre-wenn-Probe verweist auf ein Ereignis, das es nicht mehr gibt, oder auf
  einen Termin, der im neuen Fahrplan fehlt: Die Werkstatt nennt diese Eingriffe als nicht
  anwendbar und setzt die übrigen.

## Requirements *(mandatory)*

### Functional Requirements

**Ereigniskatalog**

- **FR-001**: Alle Ereignisse des Spiels müssen in einem Ereigniskatalog stehen: einer lesbaren
  Datei im Spielprojekt, die keinen Programmcode enthält. Spiel, Werkstatt und Textausgabe lesen
  denselben Katalog, und die automatischen Tests prüfen genau diesen.
- **FR-002**: Jedes Ereignis muss eine eindeutige, stabile Kennung, einen Titel, eine
  Beschreibung, eine Kategorie und eine Art haben; dazu Wirkungen, Folgeereignisse und Bedingungen,
  jeweils null oder mehr. Andere Ereignisse verweisen über die Kennung darauf.
- **FR-003**: Art „fix“: ein Datum im Spielzeitraum, wahlweise jährlich wiederkehrend in einem
  Bereich von Jahren.
- **FR-004**: Art „beim Start gesetzt“: ein tagesgenaues Zeitfenster, eine Anzahl von–bis mit einer
  Wahrscheinlichkeit je Anzahl (zusammen 100 %, Vorgabe: alle gleich) und ein Mindestabstand
  zwischen zwei Beginnen in Tagen. Beim Anlegen des Fahrplans wird die Anzahl nach diesen
  Wahrscheinlichkeiten gewürfelt und die Termine gleichverteilt im Zeitfenster, unter Einhaltung
  des Mindestabstands.
- **FR-005**: Art „über Wahrscheinlichkeit“: eine Grundchance pro Monat von 0 % bis 100 %, ein
  Zeitfenster, eine Höchstzahl (0 heißt unbegrenzt), ein Mindestabstand in Tagen und Bedingungen.
  Gewürfelt wird zu Beginn jedes Monats im Spielzeitraum, auch im Januar 1985. Bei Erfolg tritt das
  Ereignis an einem gewürfelten Tag dieses Monats ein. Ein Monat, den das Zeitfenster nur teilweise
  überdeckt, wird gewürfelt, der Tag aber nur unter den Tagen im Fenster. Der Mindestabstand gilt
  zu jedem Termin dieses Ereignisses, der weder entfallen noch abgesagt ist, auch zu einem schon
  geplanten; 0 heißt kein Abstand. Bei der Höchstzahl zählen ebenfalls alle Termine außer
  entfallenen und abgesagten. Eine Chance von 100 % trifft immer.
- **FR-006**: Ereignisse, die nicht fix oder jährlich sind, müssen Bedingungen haben können: Ein
  anderes Ereignis ist schon eingetreten oder noch nicht eingetreten. Bei Ereignissen über
  Wahrscheinlichkeit werden sie vor dem Würfeln geprüft, bei geplanten Terminen am Tag ihrer
  Fälligkeit; ist eine nicht erfüllt, entfällt der Termin mit Begründung. Ein Ereignis gilt als
  eingetreten, sobald ein Termin von ihm begonnen hat, auch wenn er noch läuft; was am selben Tag
  beginnt, zählt erst ab dem Folgetag.
- **FR-007**: Wirkungen müssen wie bisher Art (Preis, Nachfrage, Ruf, Kundenstrom, Presse), Ziel
  (eine Warengruppe wie „cpu_486“ oder „alles“), Stärke (relativ, etwa −30 %), Verzögerung in
  Tagen und eine Notiz haben. Bei Ereignissen mit Dauer legt jede Wirkung zusätzlich fest, ob sie
  nur während des Ereignisses gilt (Vorgabe) oder ein einmaliger Anstoß ist.
- **FR-008**: Folgeereignisse müssen ein Zielereignis, eine Verzögerung (fest oder als Spanne in
  Tagen) und eine Wahrscheinlichkeit (Vorgabe 100 %) haben. Ob und wann ein Folgeereignis kommt,
  wird beim Eintreten des auslösenden Ereignisses gewürfelt; danach steht es im Fahrplan. Dazu
  gibt es die Art „nur als Folge“: Ein solches Ereignis kommt nie von selbst, sondern nur als
  Folgeereignis oder durch einen Eingriff, und hat weder Datum noch Chance. Zielereignisse von
  Folgeereignissen dürfen nicht fix oder jährlich sein.
- **FR-009**: Kategorien müssen Teil des Katalogs sein, mit Name und Farbe für die Werkstatt. Zu
  den neun bisherigen kommt „Kalender“ hinzu.

**Fahrplan und Zufall**

- **FR-010**: Zu Beginn eines Spiels muss die Zeitleiste aus Katalog und Seed den Fahrplan für den
  ganzen Spielzeitraum anlegen: alle fixen und jährlichen Termine und alle gesetzten Termine mit
  ihren gewürfelten Daten.
- **FR-011**: Während das Spiel läuft, müssen gewürfelte Ereignisse, Folgeereignisse und Eingriffe
  in den Fahrplan kommen. Alles, was die Zeitleiste auslöst, steht vorher im Fahrplan, spätestens
  in dem Moment, in dem es entschieden wird.
- **FR-012**: Jeder Termin muss Datum, Ereignis, Herkunft (fix, jährlich, gesetzt, gewürfelt,
  Folge von …, Eingriff), Zustand, bei Dauer das Ende und eine Begründung tragen. Zustände sind
  geplant, läuft, eingetreten (ohne Dauer), beendet (mit Dauer, nach dem Ende), entfallen und
  abgesagt. Die Begründung nennt bei gewürfelten Terminen und bei Folgeereignissen Würfelwert und
  Schwelle, dazu die beteiligten Modifikatoren mit Grund und Wert, wie sie beim Wurf galten; bei
  gesetzten Terminen, dass sie beim Spielstart gesetzt wurden. Bei Entfall, Absage und Verschiebung
  nennt sie den Grund; trifft einen Termin mehreres, steht dort der letzte Grund, die früheren
  stehen im Protokoll (präzisiert 2026-10-21, wie im Datenmodell).
- **FR-013**: Verzögerte Wirkungen müssen mit ihrem Fälligkeitstag beim auslösenden Termin im
  Fahrplan stehen.
- **FR-014**: Jedes Spiel muss einen Seed haben, eine ganze Zahl von 0 bis 2.147.483.647; ist
  keiner vorgegeben, wird einer aus diesem Bereich gewürfelt. Ablesen lässt er sich in der
  Werkstatt, in der Textausgabe und für andere Teile des Spiels über die Zeitleiste; eine Anzeige
  für den Spieler gehört nicht zu diesem Feature. Gleicher Katalog, gleicher Seed und gleiche
  Eingriffe müssen denselben Fahrplan und dasselbe Protokoll ergeben, unabhängig vom Tempo der
  Spieluhr, davon, ob Tag für Tag oder in Sprüngen weitergeschaltet wird, und vom Betriebssystem.
- **FR-015**: Jede Zufallsentscheidung darf nur vom Seed, vom betroffenen Ereignis und vom
  Zeitpunkt abhängen. Ändert sich ein Ereignis, kommt eines hinzu oder fällt eines weg, bleiben die
  Entscheidungen aller übrigen Ereignisse gleich, außer bei denen, die über Bedingungen oder
  Folgeereignisse davon abhängen.

**Abspielen und Melden**

- **FR-016**: Das Spiel muss den Fahrplan mit der Spieluhr abspulen: Jeder Termin wird an seinem Tag
  ausgelöst, mehrere Termine eines Tages in einer festen Reihenfolge, die der Fahrplan zeigt; Enden
  kommen vor Beginnen.
- **FR-017**: Die Zeitleiste muss den Beginn eines Ereignisses mit seinen Wirkungen, fällige
  verzögerte Wirkungen, das Ende von Ereignissen mit Dauer und das Ende ihrer Wirkungen melden,
  die nur während des Ereignisses gelten. Sie wendet keine Wirkung selbst an. Die bisherigen
  Meldungen behalten Namen und Bedeutung, damit spätere Abnehmer sich ohne Umbau anschließen
  können; die Felder der gemeldeten Ereignisse und Wirkungen folgen dem neuen Katalog.
- **FR-018**: Ketten von Folgeereignissen am selben Tag müssen nach einer festen Höchstzahl von
  Gliedern abbrechen und das melden. Gezählt wird je Kette, vom Termin an, der sie anstößt; der
  Abbruch steht im Protokoll und erscheint im Spiel als Warnung.
- **FR-019**: Nach dem 31.12.1999 darf die Zeitleiste nichts mehr melden.

**Kalender und Dauer**

- **FR-020**: Ein Ereignis muss eine Dauer haben können. Bei Ereignissen, die nicht jährlich sind,
  ist sie eine Zahl von Tagen: Das Ereignis beginnt an seinem Datum, sein letzter Tag ist Beginn
  plus Dauer minus 1, und das Ende wird am Tag danach gemeldet. Bei jährlichen Ereignissen sind
  Beginn und Ende Tage im Jahr, das Ende darf über den Jahreswechsel reichen und „Monatsende“ sein.
- **FR-021**: Gilt eine Wirkung nur während ihres Ereignisses, müssen ihr Beginn und ihr Ende
  gemeldet werden; ist sie verzögert, beginnt sie entsprechend später und endet mit dem Ereignis.
  Einmalige Anstöße und alle Wirkungen von Ereignissen ohne Dauer werden einmal gemeldet, wie
  bisher.
- **FR-022**: Ein Ereignis darf nie zweimal gleichzeitig laufen.
- **FR-023**: Der Katalog muss mindestens diese Kalender-Ereignisse enthalten: das
  Weihnachtsgeschäft (jährlich vom 1. November bis Ende Dezember), die vier Jahreszeiten (Frühling
  ab 1. März, Sommer ab 1. Juni, Herbst ab 1. September, Winter ab 1. Dezember, jeweils bis zum
  Monatsende vor der nächsten) und die CeBIT in Hannover (jährlich ab 1986 im März).
- **FR-024**: Die Spieluhr darf das Weihnachtsgeschäft nicht mehr selbst melden. Wer es braucht,
  hört auf das Kalender-Ereignis.

**Eingriffe**

- **FR-025**: Ein Modifikator muss zu einem Ereignis über Wahrscheinlichkeit gehören und eine
  Kennung, einen Wert in Prozentpunkten (positiv oder negativ), einen lesbaren Grund, einen Beginn
  (Vorgabe: der aktuelle Spieltag) und verpflichtend ein Enddatum haben; „unbegrenzt“ heißt
  31.12.1999. Gleichzeitig gültige Modifikatoren addieren sich, die wirksame Chance ist Grundchance
  plus Summe, begrenzt auf 0 % bis 100 %. Abgelaufene Modifikatoren wirken nicht. Jeder lässt sich
  einzeln entfernen, und die Grundchance im Katalog bleibt unberührt. Die Werkstatt zeigt Chancen in
  Prozent und Modifikatoren in Prozentpunkten.
- **FR-026**: Geplante Termine, die nicht fix oder jährlich sind, müssen sich mit Grund absagen oder
  auf ein Datum nach dem aktuellen Spieltag bis zum 31.12.1999 verschieben lassen. Ein Ereignis
  aus dem Katalog, das nicht fix oder jährlich ist, muss sich mit Grund als neuer Termin auf einen
  solchen Tag einplanen lassen. Der aktuelle Spieltag ist schon abgespielt und scheidet deshalb
  aus. Fixe und jährliche Termine lassen sich weder absagen noch verschieben, ebenso Termine nach
  dem 31.12.1999, etwa eine Folge am 04.01.2000; ein Verschieben auf denselben Tag wird abgelehnt
  (präzisiert 2026-10-21, wie im Vertrag seit T056).
- **FR-027**: Eingriffe dürfen nur ab dem aktuellen Spieltag wirken; Vergangenes bleibt, wie es war.
  Vor dem Abspielen des 01.01.1985 wirken sie ab diesem Tag. Jeder Eingriff steht mit Zeitpunkt und
  Grund im Protokoll. Die Eingriffe stehen später allen Spielteilen offen; in diesem Feature nutzen
  sie die Werkstatt und die automatischen Tests.

**Werkstatt: Katalog bearbeiten**

- **FR-028**: Die Werkstatt muss ein eigenständiges Werkzeug im Projekt sein, das Klaus aus der
  Entwicklungsumgebung startet. Sie gehört nicht zum ausgelieferten Spiel und ersetzt die bisherige
  Zeitleisten-Demo.
- **FR-029**: Die Werkstatt muss in der vollen Auflösung ihres Fensters arbeiten, nicht im
  hochskalierten Bildraster des Spiels, und eine Schrift ohne Pixelraster nutzen, damit viel Text
  lesbar auf den Bildschirm passt. Ihre Farben stammen aus der Hauptpalette des Computerladens,
  eingesetzt nach dem Abschnitt „Werkzeuge“ des Style-Guides; Text hat zu seinem Grund einen
  Kontrast von mindestens 4,5 : 1.
- **FR-030**: Die Werkstatt muss alle Ereignisse als Liste zeigen, filterbar nach Art und Kategorie
  und durchsuchbar nach Titel.
- **FR-031**: Klaus muss Ereignisse anlegen, duplizieren, ändern und löschen und Kategorien anlegen
  und umbenennen können. Je nach Art zeigt die Werkstatt nur die passenden Felder. Zielereignisse
  von Folgeereignissen und Bedingungen wählt er aus der Liste vorhandener Ereignisse, Wirkungsziele
  aus den schon benutzten Zielen oder als neue Eingabe. Dabei gilt:
  - Wechselt Klaus die Art, behält die Werkstatt alle Werte, die auch die neue Art hat (etwa
    Zeitfenster, Mindestabstand, Dauer). Die übrigen Felder der neuen Art bekommen Vorgaben, Werte
    der alten Art fallen weg; Cmd+Z stellt den alten Stand wieder her.
  - Eine Kategorie lässt sich nur löschen, wenn kein Ereignis mehr zu ihr gehört. Eine neue
    Kategorie bekommt die erste noch freie der Farben, die der Style-Guide für Kategorien erlaubt;
    sind alle vergeben, die am seltensten benutzte, bei Gleichstand die frühere in seiner Liste.
    Ihre Kennung entsteht beim Anlegen aus dem Namen und bleibt danach fest; Umbenennen ändert nur
    den Namen.
  - Zahlen nimmt die Werkstatt mit Komma oder Punkt an und zeigt sie mit Komma. Wahrscheinlichkeiten
    und Stärken stehen in Prozent, Daten als `TT.MM.JJJJ`, auch ohne führende Nullen. Eine
    ungültige Eingabe wird nicht übernommen; das Feld zeigt den alten Wert und einen Hinweis.
- **FR-032**: Beim Anlegen muss die Werkstatt die Kennung aus dem Titel vorschlagen. Doppelte
  Kennungen lässt sie nicht zu; ändert Klaus eine Kennung, zieht sie alle Verweise im Katalog nach.
- **FR-033**: Die Werkstatt muss den Katalog laufend nach den Prüfregeln aus den Edge Cases prüfen
  und Fehler und Warnungen mit Ereignis und Feld auflisten; ein Klick auf eine Meldung führt zum
  betroffenen Feld.
- **FR-034**: Die Werkstatt muss auf Befehl speichern, auch mit Cmd+S (unter Windows und Linux
  Ctrl+S). Ungespeicherte Änderungen sind zu erkennen; vor dem Schließen und vor dem Verwerfen fragt
  sie nach. Einen Katalog mit Fehlern speichert sie nur nach Rückfrage. Jede Änderung am Katalog,
  auch das Ziehen auf dem Zeitstrahl, lässt sich mit Cmd+Z schrittweise rückgängig machen und mit
  Shift+Cmd+Z wiederholen (unter Windows und Linux Ctrl+Z und Ctrl+Shift+Z). Der Verlauf reicht
  über das Speichern hinweg; Verwerfen und Schließen leeren ihn. Eingriffe im Simulator gehören
  nicht dazu.
- **FR-035**: Die gespeicherte Datei muss menschenlesbar sein. Ändert Klaus ein einzelnes Feld,
  ändert sich in der Datei nur dessen Zeile; die Reihenfolge von Ereignissen und Feldern bleibt beim
  Speichern stabil, damit Änderungen in der Versionsverwaltung nachvollziehbar bleiben. Ausgenommen
  sind die Kennung, nach der die Ereignisse sortiert sind (der Block des Ereignisses wandert an
  seine neue Stelle), und die Art, die eigene Felder hat.
- **FR-036**: Löscht Klaus ein Ereignis, auf das andere verweisen, muss die Werkstatt diese Verweise
  nennen und erst nach Bestätigung löschen. Die Verweise werden dabei mit entfernt; alles zusammen
  ist ein Schritt, den Cmd+Z zurücknimmt.

**Werkstatt: Zeitstrahl**

- **FR-037**: Die Werkstatt muss den Katalog auf einem Zeitstrahl 1985 bis 1999 zeigen, eine Zeile
  je Kategorie: fixe Ereignisse als Punkt oder mit Dauer als Balken, jährliche in jedem ihrer Jahre,
  gesetzte als ihr Zeitfenster, Ereignisse über Wahrscheinlichkeit als Band über ihr Zeitfenster mit
  ihrer Chance. Überlappen sich Ereignisse einer Zeile, stapelt der Zeitstrahl sie in Unterzeilen;
  Titel stehen daneben, wenn Platz ist, sonst nur im Hinweis. Ereignisse der Art „nur als Folge“
  haben keine Marke auf der Achse; sie stehen in der Liste und erscheinen im Simulator, sobald sie
  geplant sind. Sucht oder filtert Klaus die Liste, zeigt der Zeitstrahl nur die passenden
  Ereignisse, blendet Zeilen ohne Treffer aus und nennt, wie viele er zeigt, etwa „Filter: 11 von
  500“ (Klaus, 2026-10-21, T074).
- **FR-038**: Der Zeitstrahl muss sich vom ganzen Zeitraum bis auf einen einzelnen Monat mit
  sichtbaren Tagen vergrößern und seitlich verschieben lassen: mit dem Mausrad, auf dem Trackpad
  durch Kneifen und Wischen mit zwei Fingern (Klaus, Phase 6, R16), mit den Knöpfen „+“, „−“ und
  „Alles“ und mit einer waagerechten Leiste unter der Zeitfläche (Wünsche von Klaus bei T055).
- **FR-039**: Klaus muss mit der Maus eintakten können: fixe Ereignisse auf ein anderes Datum
  ziehen und Beginn und Ende von Zeitfenstern und Dauern ziehen; beim Ziehen zeigt die Werkstatt das
  Datum tagesgenau. Überfahren zeigt einen Hinweis mit den wichtigsten Angaben, ein Rechtsklick ein
  Menü mit Bearbeiten, Duplizieren und Löschen, ein Doppelklick auf eine leere Stelle öffnet
  „Neu …“, vorbelegt mit „fix“, dem Tag und der Kategorie der Zeile (Klaus, 2026-10-21, R16; bis
  dahin legte er dort sofort ein fixes Ereignis an). Jährliche Ereignisse lassen sich nicht
  ziehen, nur im Formular ändern; ihr Hinweis sagt das.

**Werkstatt: Simulator**

- **FR-040**: Klaus muss in der Werkstatt einen Seed eingeben oder würfeln lassen und daraus den
  Fahrplan erzeugen können, ohne das Spiel zu starten. Das Seed-Feld nimmt nur Ziffern an.
- **FR-041**: Er muss die Zeit tage-, monats- und jahresweise oder bis zu einem Datum oder bis zum
  Spielende weiterschalten können; Fahrplan und Protokoll zeigen dabei, was eingetreten, entfallen
  und noch geplant ist, und zu jedem Termin seine Begründung.
- **FR-042**: Der Simulator muss den gerade bearbeiteten Katalog nutzen, auch ungespeichert, und
  darf weder die Spieluhr noch einen Spielstand verändern. Ändert Klaus den Katalog, während ein
  Durchlauf läuft, behält der Durchlauf seinen Stand; die Werkstatt zeigt, dass der Katalog neuer
  ist, und die Änderung gilt ab dem nächsten Neustart. Hat der Katalog Fehler, nehmen Simulator und
  Statistik die betroffenen Ereignisse aus wie das Spiel (FR-049) und nennen sie.
- **FR-043**: Im Simulator muss Klaus Modifikatoren setzen und entfernen und Termine absagen,
  verschieben und einplanen können, wie in FR-025 bis FR-027, und die Folgen sofort im Fahrplan
  sehen. Einen Durchlauf kann er mit demselben Seed neu starten, mit oder ohne seine Eingriffe.
  Seine Eingriffe bleiben erhalten, solange die Werkstatt offen ist, auch über Neustarts und
  Änderungen am Katalog hinweg; nur das Laden einer Probe ersetzt sie durch deren Eingriffe
  (FR-051). Beim Neustart mit Eingriffen gilt jeder an seinem Tag, nach Tagen geordnet; der Lauf
  steht danach auf dem alten Tag, mindestens aber auf dem Tag des letzten Eingriffs (präzisiert
  2026-10-21, T075). Läuft ein Durchlauf mit Eingriffen, markiert der Fahrplan jeden
  Termin, der gegenüber demselben Seed ohne Eingriffe neu ist, wegfällt, auf einem anderen Tag
  liegt oder einen anderen Zustand hat.

**Statistik**

- **FR-044**: Die Werkstatt muss auf Wunsch viele Spiele mit aufeinanderfolgenden Seeds
  durchrechnen (Anzahl wählbar, Vorgabe 1.000) und je Ereignis Mittelwert, kleinste und größte
  Anzahl, den Anteil der Spiele ohne Eintreten und mit erreichter Obergrenze und die Verteilung auf
  die Jahre zeigen. Obergrenze ist die Höchstzahl bei Ereignissen über Wahrscheinlichkeit und die
  höchste Anzahl bei gesetzten; Ereignisse ohne Obergrenze zeigen dort keinen Wert.
- **FR-045**: Die Statistik muss ihren Fortschritt zeigen und sich abbrechen lassen. Wahlweise
  rechnet sie jedes Spiel mit den Modifikatoren und Einplanungen aus dem Simulator. Absagen und
  Verschiebungen betreffen Termine eines bestimmten Seeds und gelten deshalb nicht für die
  Statistik.

**Textausgabe**

- **FR-046**: Der Fahrplan eines Seeds muss sich ohne Werkstatt und ohne Fenster als Text ausgeben
  lassen, wahlweise bis zu einem Datum. Gleicher Katalog und gleicher Seed ergeben Zeichen für
  Zeichen dieselbe Ausgabe.

**Übernahme und Prüfung**

- **FR-047**: Die 25 vorhandenen Ereignisse (19 fixe, 6 über Wahrscheinlichkeit) müssen mit allen
  Angaben in den Katalog übernommen werden; die fixen treten am selben Tag mit denselben Wirkungen
  ein wie bisher.
- **FR-048**: Die automatischen Tests müssen den gespeicherten Katalog mit denselben Prüfregeln wie
  die Werkstatt prüfen; ein Katalog mit Fehlern lässt sie scheitern.
- **FR-049**: Beim Spielstart müssen fehlerhafte Einträge übersprungen und mit Kennung und Grund
  gemeldet werden. Fehlt der Katalog oder ist er nicht lesbar, startet das Spiel mit leerer
  Zeitleiste und einer Fehlermeldung, die Datei und Grund nennt.

**Sicherungskopie und Was-wäre-wenn-Proben**

- **FR-050**: Hat Klaus ungespeicherte Änderungen, muss die Werkstatt spätestens alle 2 Minuten eine
  Sicherungskopie des Katalogs anlegen, außerhalb des Projekts und je Katalog eine eigene (Klaus,
  2026-10-21, T078; bis dahin eine für alle, und die Kopie eines anderen Katalogs verhinderte die
  Sicherung). Findet sie beim Start eine Sicherungskopie des geöffneten Katalogs, bietet sie an,
  diese zu übernehmen, zu verwerfen oder auf später zu verschieben, und nennt dabei, wann Kopie und
  Katalogdatei zuletzt geändert wurden. Kopien anderer Kataloge bleiben unberührt. Lässt sich die
  Kopie nicht schreiben, sagt die Werkstatt es. Nach dem Speichern, nach dem Verwerfen und nach dem
  regulären Schließen löscht sie die Kopie, beim Schließen nicht, solange „später“ gilt (R23).
- **FR-051**: Klaus muss die Eingriffe eines Durchlaufs samt Seed als Was-wäre-wenn-Probe unter
  einem Namen speichern, später laden und löschen können. Als Stand speichert die Werkstatt den Tag
  des Laufs, mindestens aber den des letzten Eingriffs (präzisiert 2026-10-21, T075). Die Proben
  liegen als lesbare Dateien im Projekt neben der Werkstatt und gehören nicht zum ausgelieferten
  Spiel. Beim Laden setzt die Werkstatt Seed und Eingriffe wieder, die Eingriffe der Probe ersetzen
  die gesammelten. Eingriffe, die im neuen Fahrplan nicht anwendbar sind, nennt sie, statt sie
  stillschweigend wegzulassen.

### Key Entities *(include if feature involves data)*

- **Ereigniskatalog**: alle Ereignisdefinitionen und Kategorien des Spiels; ändert sich während
  eines Spiels nie.
- **Ereignis**: Kennung, Titel, Beschreibung, Kategorie, Art (fix, beim Start gesetzt, über
  Wahrscheinlichkeit, nur als Folge) mit den Angaben der Art, Dauer, Wirkungen, Folgeereignisse und
  Bedingungen.
- **Kategorie**: Name und Farbe; ordnet Ereignisse den Zeilen des Zeitstrahls zu.
- **Wirkung**: Art, Ziel, Stärke, Verzögerung, Notiz; bei Ereignissen mit Dauer außerdem, ob sie nur
  während des Ereignisses gilt oder ein einmaliger Anstoß ist.
- **Folgeereignis**: Zielereignis, Verzögerung fest oder als Spanne, Wahrscheinlichkeit.
- **Bedingung**: Verweis auf ein anderes Ereignis mit „schon eingetreten“ oder „noch nicht
  eingetreten“.
- **Seed**: die Startzahl, aus der alle Zufallsentscheidungen eines Spiels folgen.
- **Fahrplan**: die nach Datum geordneten Termine eines Spiels.
- **Termin**: Datum, Ereignis, Herkunft, Zustand, gegebenenfalls Ende, Begründung und die
  verzögerten Wirkungen mit ihren Fälligkeitstagen.
- **Eingriff**: was eine Spieleraktion an der Zeitleiste ändert, etwa „Reklamationswelle ab 1990
  um 5 Prozentpunkte wahrscheinlicher“, weil der Spieler beim windigen Händler kauft. Ein Eingriff
  ist ein Modifikator, eine Absage, eine Verschiebung oder eine Einplanung, jeweils mit Zeitpunkt
  und Grund. Später kommen Eingriffe von den Spielteilen, in diesem Feature von Hand aus dem
  Simulator.
- **Was-wäre-wenn-Probe**: ein benannter Satz von Eingriffen mit seinem Seed, gespeichert neben der
  Werkstatt.
- **Modifikator**: Kennung, Ereignis, Wert in Prozentpunkten, Grund, Beginn und Ende.
- **Protokoll**: alle Meldungen und Eingriffe eines Durchlaufs in zeitlicher Reihenfolge.
- **Statistik**: die Auswertung vieler Durchläufe je Ereignis.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Klaus legt in der Werkstatt fünf Ereignisse an: je eines fix, jährlich mit Dauer,
  beim Start gesetzt und über Wahrscheinlichkeit, dazu ein Folgeereignis der Art „nur als Folge“.
  Er speichert und erzeugt im Simulator den Fahrplan für den Seed 4711, ohne eine Datei von Hand zu
  öffnen, in zusammen höchstens 10 Minuten; das Schreiben der Texte zählt nicht mit. Im Fahrplan
  stehen dann das fixe, das jährliche und das gesetzte Ereignis. Klaus misst selbst, nachdem er den
  Quickstart einmal durchgegangen ist; die Uhr läuft vom ersten „Neu“, bis der Fahrplan erzeugt ist.
- **SC-002**: Mit gleichem Katalog, Seed und gleichen Eingriffen ergeben 10 Durchläufe bis zum
  Spielende 10 Zeichen für Zeichen gleiche Textausgaben, ob Tag für Tag oder in Sprüngen
  geschaltet.
- **SC-003**: Über die Seeds 1 bis 100 ändert der Modifikator aus US6, Szenario 1 keinen einzigen
  Termin eines Ereignisses, das nicht über Bedingungen oder Folgeereignisse von der
  Reklamationswelle abhängt.
- **SC-004**: Auf dem Entwicklungsrechner ist ein ganzes Spiel 1985 bis 1999 in unter 1 Sekunde
  durchgerechnet und die Statistik über 1.000 Spiele in unter 30 Sekunden. Gemessen wird in der
  Werkstatt mit dem übernommenen Katalog samt Kalender-Ereignissen: „Bis zum Ende“, bis das
  Protokoll steht, und die Statistik vom Start bis 100 %.
- **SC-005**: Im übernommenen Katalog treten bei jedem von 100 Seeds die 19 historischen Ereignisse
  am selben Tag und mit denselben Wirkungen ein wie vor dem Umbau. Geprüft wird an einer
  eingefrorenen Kopie der Übernahme, damit spätere Änderungen in der Werkstatt den Nachweis nicht
  berühren.
- **SC-006**: Jede Prüfregel aus den Edge Cases ist mit einem absichtlich fehlerhaften Beispiel
  belegt: Die Werkstatt benennt das Ereignis und das Feld, bei Kategorien die Kategorie. Bei einer
  Fehlerregel schlägt die automatische Prüfung fehl, eine Warnregel erscheint als Warnung.
- **SC-007**: Zu jedem Termin im Fahrplan sieht Klaus mit einem Klick, warum er dort steht.
- **SC-008**: Für ein Ereignis zu 50 % pro Monat ohne weitere Grenzen ergibt die Statistik über
  1.000 Spiele einen Mittelwert zwischen 85,5 und 94,5.
- **SC-009**: Das Weihnachtsgeschäft beginnt in allen 15 Spieljahren am 1. November und endet mit
  dem 31. Dezember; die Spieluhr meldet es nicht mehr selbst.
- **SC-010**: Klaus nimmt die Werkstatt ab: Er pflegt die Ereignisse ohne Code und bestätigt, dass
  sich mit Zeitstrahl und Formularen so eintakten lässt, wie er es sich vorgestellt hat.
- **SC-011**: Mit einem Test-Katalog von 500 Ereignissen, je zur Hälfte fix und über
  Wahrscheinlichkeit, ist ein ganzes Spiel in unter 2 Sekunden durchgerechnet und die Statistik
  über 1.000 Spiele in unter 5 Minuten. Eine Änderung am Katalog samt neuer Prüfung dauert unter
  100 ms; das Ziehen auf dem Zeitstrahl ruckelt nicht.

## Assumptions

- Der Katalog ist eine JSON-Datei im Spielprojekt (Entscheidung von Klaus am 2026-10-20);
  Aufbau und Ort legt der Plan fest. Weil Spielinhalt nach Grundsatz V der Verfassung in der
  game_bible liegt, bekommt Grundsatz V vor dem Plan einen Zusatz für den Ereigniskatalog. Den
  Wortlaut beschließt Klaus.
- Die Werkstatt ist ein Entwicklungswerkzeug und gehört nicht zum Spiel. Nach Grundsatz IV wird vor
  ihrem Bau der Style-Guide um einen kurzen Abschnitt „Werkzeuge“ ergänzt: Farbrollen aus der
  Hauptpalette, Schrift und Auflösung für Werkzeuge. Klaus gibt ihn frei; einen Zusatz zu Grundsatz
  IV braucht es damit nicht.
- Es gibt noch keine Spieleraktionen und keinen Spielbildschirm. Eingriffe kommen in diesem
  Feature aus der Werkstatt und aus den Tests. Bedingungen auf den echten Spielzustand, etwa Ruf,
  Warenqualität oder Standort, kommen mit den Systemen, die diesen Zustand führen.
- Bis es „Neues Spiel“ gibt, beginnt ein Spiel wie bisher mit dem Programmstart, und der Seed wird
  gewürfelt.
- Geprüft wird auf dem Entwicklungsrechner unter macOS. Dass der Fahrplan unter Windows und Linux
  gleich ausfällt (FR-014), wird mit 11-03 Build & Export nachgewiesen.
- Gleiche Ergebnisse gelten für dieselbe Godot-Version (Entscheidung von Klaus im Review). Nach
  einem Godot-Update können neue Fahrpläne anders ausfallen; Spielstände behalten später ihren
  gespeicherten Fahrplan (11-01).
- Die Werkstatt schaltet die Fensterlogik des Spiels nur für sich ab, solange sie läuft. Das Spiel
  lädt die Werkstatt nie und bleibt davon unberührt.
- Die 25 Ereignisse werden unverändert übernommen. Welche davon künftig „beim Start gesetzt“ sind,
  etwa Neubaugebiet oder Konkurrent eröffnet, und welche Werte sich ändern, entscheidet Klaus in der
  Werkstatt. Die Abnahme nutzt eigene Test-Kataloge, damit sie nicht vom Spielinhalt abhängt.
- Die genauen Termine und die Dauer der CeBIT trägt Klaus in der Werkstatt ein; als Startwert gilt
  Mitte März, eine Woche.
- Die Wirkungsarten bleiben Preis, Nachfrage, Ruf, Kundenstrom und Presse. Eine neue Wirkungsart
  braucht einen Abnehmer im Spiel und kommt mit dessen Feature. Folgeereignisse sind künftig ein
  eigener Teil eines Ereignisses statt einer Wirkungsart. Wirkungsziele bleiben freie Bezeichnungen;
  der Abgleich mit echten Warengruppen kommt mit 02-02.
- Die Werkstatt bearbeitet den Katalog des Spiels. Nur für Prüfungen, etwa SC-011, lässt sie sich
  mit einem anderen Katalog starten.
- Die Werkstatt merkt sich zwischen zwei Starts, wo Klaus ihre Teiler hingezogen hat, in einer
  Einstellungsdatei außerhalb des Projekts (Wunsch von Klaus, Phase 10).
- Die Statistik rechnet die Seeds ab 1 fortlaufend, damit sie wiederholbar ist.
- Nicht dazu gehören: Speichern und Laden von Seed, Fahrplan und Eingriffen (11-01; das Modell
  ist so angelegt, dass diese drei genügen), ein späterer Spielstart (01-05), das Anwenden der
  Wirkungen (03-xx), die Anzeige von Ereignissen im Spiel (10-04) und ein Umzug des Katalogs in die
  game_bible.
- Gearbeitet wird am Desktop mit Maus und Tastatur (Verfassung, Grundsatz I); Hover, Tooltips,
  Rechtsklick und Drag & Drop sind ausdrücklich erwünscht.
