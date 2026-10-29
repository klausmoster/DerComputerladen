# Feature Specification: Ladeneröffnung

**Feature Branch**: `feature/010-ladeneroeffnung`

**System**: 05 Standortsystem (05-01 Standortwahl), 03 Wirtschaftsmodell (ein schmales Konto,
Vorstufe von 03-06 Finanzen), 10 Präsentation & UI (Stadtplan, Papiere, Spielbildschirm) und
11 Infrastruktur (Spielstand mit Laden)

**Created**: 2026-10-29

**Status**: Draft

**Input**: User description: "Feature 010 „Ladeneröffnung“. Grundlage: Eintrag 05-01 in
docs/features/Feature_Ideas.md." Festgelegt von Klaus am 2026-10-29: eine fiktive westdeutsche
Mittelstadt mit rund 150.000 Einwohnern und drei bis vier Läden; Ablauf Gradwahl, Stadtplan,
Exposé des Maklers als Papierblatt mit Kleingedrucktem, Mietvertrag, Gewerbeanmeldung mit
Ladennamen, Spiel; der Ladenname ist der angezeigte Name des Spielstands, die Datei behält ihre
Nummer; das Startkapital hängt vom Grad ab, die Kaution beträgt drei Monatsmieten, ein zu teurer
Laden bleibt grau und das Exposé sagt warum; ein schmales Konto bucht die Miete am Monatsersten
ab; der Spielbildschirm zeigt den leeren Laden als Bild mit Name, Datum und Kontostand;
Laufkundschaft und Sichtbarkeit werden nur gespeichert und wirken erst mit 03-04; die Ereignisse
der Zeitleiste bekommen keinen Ortsbezug (das ist 05-03), Hinweise im Exposé sind fester Text.

## Clarifications

### Specify 2026-10-29

Fragen zu den Markern aus `/speckit-specify`, einzeln an Klaus:

- Q: Läuft die Spieluhr auf dem Spielbildschirm? → A: Ja, mit Pause und einigen Tempostufen
  (Klaus, nach Empfehlung). So sieht der Spieler Datum und Kontostand wandern und die Miete am
  Monatsersten abgehen. Verworfen: Uhr steht wie bisher (Miete nur in Tests sichtbar), Knopf
  „Nächster Tag“ (legt früh ein Rundenspiel fest).
- Q: Wie viele Läden bietet der Makler an, mit welchem Charakter? → A: Vier (Klaus, nach
  Empfehlung): Fußgängerzone, Stadtteilzentrum im Wohngebiet, Gewerbegebiet und Nähe Bahnhof.
  Verworfen: drei, je einer pro Viertel wie im Game Design (auf „Schwer“ blieben nur zwei); vier
  mit Uni-Viertel statt Bahnhof.
- Q: Welche Beträge gelten, und wann ist ein Laden grau? → A: Beträge nach der Recherche
  (Mieten 4.800, 2.240, 1.440 und 1.350 DM; Startkapital 100.000, 60.000 und 30.000 DM), grau ist
  ein Laden, wenn das Startkapital den Kapitalnachweis des Vermieters nicht deckt: Kaution plus
  sechs Monatsmieten. Abgebucht wird weiter nur die Kaution (Klaus, nach Empfehlung). Damit
  ändert sich Klaus' Regel vom selben Tag, „grau, wenn die Kaution das Kapital übersteigt“: Die
  Kaution ist höchstens 14.400 DM, auf „Schwer“ wäre also kein Laden grau gewesen. Verworfen: nur
  die Kaution mit Schwer bei 12.000 DM (unrealistisch knapp); nur die Kaution, nie grau. Klaus'
  Folgeidee, später mit dem Laden umzuziehen, steht in `docs/Ideensammlung.md`.

### Session 2026-10-29

Fragen aus `/speckit-clarify`, einzeln an Klaus:

- Q: Dürfen zwei Spiele denselben Ladennamen tragen? → A: Ja (Klaus, nach Empfehlung); Grad,
  Spieldatum und „zuletzt gespielt“ unterscheiden sie, die Rückfrage beim Löschen nennt Grad und
  Spieldatum mit. Verworfen: ablehnen wie ein Gewerbeamt (spielweltlich schief), automatischer
  Zusatz „(2)“ (ändert sich beim Löschen).
- Q: Was passiert mit Spielständen von vor diesem Feature, ohne Laden? → A: Sie lassen sich
  nicht mehr laden, ohne eigenen Grund und ohne Sonderweg: Der Laden ist ein Pflichtteil des
  Spielstands, und ein Spielstand ohne ihn gilt wie jeder unvollständige als beschädigt (Klaus:
  „Wir sind noch in der Entwicklung. Ich möchte keinen Code drin haben, der Sonderlocken für alten
  Käse hat.“). Rücksicht auf alte Spielstände wird erst wichtig, wenn es eine Version gibt, die
  herausgegeben wird. Verworfen: eigener Grund „noch ohne Laden“, Ladenwahl nachholen, weiter
  ohne Laden.
- Q: Wann entstehen die Bilder, und gibt es bis dahin Platzhalter? → A: Gebaut wird mit
  Platzhaltern; die Bilder (bei dieser Frage neun: Stadtplan, vier Läden von außen, vier leere
  Läden von innen; mit der nächsten Antwort zehn und die Figur des Maklers) entstehen mit
  `dcl-grafik` in einer eigenen Phase am Ende des Features, vor Selbsttest und Gesamtabnahme
  (Klaus, nach Empfehlung). Die Papiere werden gezeichnet, nicht generiert.
  Verworfen: Bilder zuerst (der Bau wartet auf die Auswahl), Bilder erst in einem späteren
  Feature (die Gesamtabnahme sähe nicht aus wie das Spiel).
- Q: Wo spielt die Ladenwahl? → A: Im Büro des Maklers, als Adventure-Szene: Stadtplan an der
  Wand, die Papiere auf dem Schreibtisch, der Makler dahinter; der Spieler klickt auf Gegenstände
  (Klaus, gegen die Empfehlung, den Stadtplan bildfüllend mit darübergelegten Papieren zu zeigen).
  Damit kommen ein zehntes Bild (das Büro) und die Figur des Maklers dazu, und es ist die erste
  Szene im Adventure-Stil. Verworfen: Stadtplan mit Papieren (weniger Stimmung), alles auf dem
  Communicator (zu klein für Foto und Kleingedrucktes).

### Plan 2026-10-29

Fragen aus `/speckit-plan`, einzeln an Klaus:

- Q: Wo stehen die Daten der Läden? → A: In der game_bible, mit einer neuen Vorlage für Läden; ein
  Importer schreibt daraus die Daten ins Spiel (Klaus, nach Empfehlung; Architektur-Leitfaden
  AR-04: Mieten sind Spielinhalt). Verworfen: von Hand im Inspector, eine JSON-Datei wie der
  Ereigniskatalog (beides Ausnahmen von AR-04).
- Q: Ist 010 das erste Feature der Schichten Adventure und Wirtschaft? → A: Ja, beide (Klaus, nach
  Empfehlung). Ab hier gelten AR-16 bis AR-20: Geld in Pfennig, feste Reihenfolge, Bausteine ohne
  Inhalt, lineare Abläufe, Dialoge als Daten; vor der Lückensuche läuft die Bestandsprüfung.
  Verworfen: nur Adventure (das Konto müsste später auf Pfennig umgestellt werden), keine.
- Q: Wie viel vom Makler kommt schon in 010? → A: Er bekommt einen Steckbrief und ein Bild und
  sagt feste Sätze in einer Sprechblase, je Schritt und auf Klick, ohne Antworten (Klaus, nach
  Empfehlung). Klaus dazu: Der Makler „kann ja später auch wieder eine Rolle spielen“, wenn der
  Laden umzieht; deshalb wird er gleich ganz gestaltet. Verworfen: stumm; ein echter Dialog
  (zöge 09-02 vor).
- Wunsch von Klaus während des Plans (2026-10-29): „in der Doku eine Übersicht der Charaktere …
  Inkl. der ganzen Beschreibung. Name, Alter, Optik (die dann auch wieder als Referenzbild genommen
  wird) … Stuff für die KI und für die Doku.“ Umgesetzt als FR-001c.

### Review 2026-10-29

Aus der Checkliste [review.md](checklists/review.md) mit 47 Punkten, 20 von Claude und 27 aus der
Vorab-Prüfung durch Text-, Stil- und Architektur-Prüfer; Klaus hat am 2026-10-29 alle Vorschläge
freigegeben, auch die Ausnahme zu AR-13. An der Spec geändert: Überblick (Beträge, Leuchtanzeige),
US1 (Vorwahl, „nicht mietbar“), US2 (Feld leer, Text unter dem Feld), US3, US4, Edge Cases (langer
Name, Zurück, Meldung), FR-001a, FR-008, FR-010, FR-011, FR-015, FR-017, FR-019, FR-026, FR-027,
SC-001, SC-002, SC-006 und drei Annahmen. Die wichtigsten:
- Q: Wo ist der Ladenname ganz zu lesen? → A: Auf dem Spielbildschirm, in den Hinweisen und der
  Rückfrage; in der Spalte der Liste wird er nach dem Baustein Liste gekürzt (CHK006).
- Q: Darf eine nicht mietbare Markierung ihr Exposé öffnen, obwohl „gedämpft“ im Style-Guide
  „löst nichts aus“ heißt? → A: Ja; der Style-Guide bekommt dafür einen eigenen Zustand (CHK030).
- Q: Tooltip oder Hinweis im Büro und auf dem Spielbildschirm? → A: Tooltips, denn kein Knopf
  steht dort allein; auch „Zum Hauptmenü“ (CHK032).

## Überblick

Bisher führt die Gradwahl direkt in einen leeren Spielbildschirm mit dem Knopf „Zum Hauptmenü“.
Mit diesem Feature beginnt das eigentliche Spiel: Der Spieler sucht sich in einer Stadt einen
Laden, unterschreibt den Mietvertrag, meldet sein Gewerbe unter einem eigenen Namen an und steht
dann in seinem leeren Laden, mit Geld auf dem Konto und der ersten Miete vor Augen.

Beispiel: Klaus wählt „Schwer“. Auf dem Stadtplan von Wesselbach (Name vorläufig) sind vier
Läden markiert. Der Laden in der Fußgängerzone ist grau; sein Exposé sagt: „Der Vermieter
verlangt einen Kapitalnachweis über 43.200,00 DM. Sie haben 30.000,00 DM.“ Er nimmt den Laden im
Stadtteilzentrum, unterschreibt den Mietvertrag, meldet „Computer Klaus“ an und steht am
01.01.1985 im leeren Laden. Die Leuchtanzeige in der Leiste zeigt DI 01.01.1985 und 25.680,00 DM
(30.000,00 DM Startkapital minus 4.320,00 DM Kaution). Im Hauptmenü heißt sein Spielstand jetzt „Computer Klaus“,
die Datei bleibt `spiel_7.json`. (Name der Stadt und Wortlaute sind vorläufig.)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Einen Laden aussuchen (Priority: P1)

Nach der Gradwahl sieht der Spieler den Stadtplan mit den Läden, die gerade frei sind. Wählt er
einen, liegt dessen Exposé vor ihm: ein Blatt Papier des Maklers mit Foto, Miete, Fläche, Lage und
Kleingedrucktem. Er blättert zwischen den Läden, vergleicht und entscheidet sich für einen. Ein
Laden, für den der Vermieter mehr Kapital sehen will, als der Spieler hat, ist auf dem Plan grau; sein Exposé lässt sich
trotzdem lesen und sagt, warum er nicht in Frage kommt.

**Why this priority**: Die Wahl des Standorts ist die erste echte Entscheidung im Spiel. Ohne sie
gibt es keinen Laden, an dem alles Spätere hängt.

**Independent Test**: Ein neues Spiel auf „Mittel“ beginnen: Der Stadtplan erscheint mit allen
Läden. Jeden Laden wählen: Sein Exposé zeigt Foto, Miete, Fläche, Lage und Kleingedrucktes. Auf
„Schwer“ ist die Fußgängerzone als nicht mietbar gekennzeichnet, und ihr Exposé nennt den Grund.

**Acceptance Scenarios**:

1. **Given** der Spieler hat einen Grad gewählt, **When** der Stadtplan erscheint, **Then** sind
   alle Läden der Stadt darauf markiert, je mit Lage im Viertel, und vorgewählt ist der erste
   bezahlbare in der Reihenfolge der Läden.
2. **Given** der Stadtplan ist zu sehen, **When** der Spieler einen Laden wählt, **Then** liegt
   dessen Exposé vor ihm, mit Foto, Monatsmiete, Kaution, Fläche, Lage, einer Beschreibung und
   dem Kleingedruckten.
3. **Given** ein Exposé liegt vor ihm, **When** er zum nächsten oder vorigen Laden blättert oder
   zum Stadtplan zurückgeht, **Then** sieht er das andere Exposé oder wieder den Plan, ohne dass
   etwas festgelegt ist.
4. **Given** der Kapitalnachweis eines Ladens (Kaution plus sechs Monatsmieten) übersteigt das
   Startkapital des Grads, **When** der Spieler den Stadtplan sieht, **Then** ist dieser Laden
   als nicht mietbar gekennzeichnet („grau“); **When** er sein Exposé öffnet, **Then** nennt es den verlangten Nachweis und das
   Kapital des Spielers in DM und bietet keinen Mietvertrag an.
5. **Given** der Stadtplan ist zu sehen, **When** der Spieler zurückgeht, **Then** ist er wieder
   in der Gradwahl, und es ist kein Spielstand angelegt.

---

### User Story 2 - Mieten, anmelden, eröffnen (Priority: P1)

Hat der Spieler sich entschieden, liegt der Mietvertrag vor ihm, mit Miete, Kaution und
Mietbeginn. Er unterschreibt. Dann füllt er die Gewerbeanmeldung aus und trägt den Namen seines
Ladens ein. Mit der Anmeldung ist das Spiel angelegt: Die Kaution ist vom Startkapital abgebucht,
der Spielstand heißt wie der Laden, und der Spielbildschirm erscheint.

**Why this priority**: Erst hier entsteht das Spiel. Der Ladenname macht es zu „seinem“ Laden und
ersetzt im Hauptmenü das nüchterne „Spiel 7“.

**Independent Test**: Auf „Leicht“ einen Laden wählen, den Mietvertrag unterschreiben und
„Elektro Test“ anmelden: Der Spielbildschirm zeigt „Elektro Test“, und „Spiel laden“ führt einen
Spielstand „Elektro Test“ mit Grad Leicht und dem 01.01.1985.

**Acceptance Scenarios**:

1. **Given** ein Exposé eines bezahlbaren Ladens liegt vor ihm, **When** der Spieler sich für den
   Laden entscheidet, **Then** liegt der Mietvertrag vor ihm, mit Anschrift, Fläche,
   Monatsmiete, Kaution und Mietbeginn.
2. **Given** der Mietvertrag liegt vor ihm, **When** er nicht unterschreibt und zurückgeht,
   **Then** liegt wieder das Exposé vor ihm, und nichts ist festgelegt.
3. **Given** er hat unterschrieben, **When** die Gewerbeanmeldung erscheint, **Then** ist das
   Feld für den Ladennamen leer, und er tippt einen eigenen Namen ein. Einen Vorschlag gibt es
   nicht, weil das Spiel den Namen des Spielers nicht kennt.
4. **Given** die Gewerbeanmeldung mit einem gültigen Namen, **When** er sie abgibt, **Then** ist
   ein Spielstand mit diesem Namen, dem Grad, dem Laden und dem Kontostand nach Abzug der Kaution
   angelegt, und der Spielbildschirm erscheint.
5. **Given** der Name ist leer oder besteht nur aus Leerzeichen, **When** er die Anmeldung abgeben
   will, **Then** geht das nicht, und ein Text unter dem Feld sagt, dass ein Name fehlt.
6. **Given** irgendein Schritt vor der Abgabe der Anmeldung, **When** der Spieler die App beendet
   oder ins Hauptmenü zurückgeht, **Then** entsteht kein Spielstand.

---

### User Story 3 - Im eigenen Laden stehen (Priority: P2)

Der Spielbildschirm zeigt den gewählten Laden leer von innen, dazu den Ladennamen, das Datum und
den Kontostand. Setzt der Spieler das Spiel später fort, steht er wieder in demselben Laden mit
demselben Namen und Kontostand.

**Why this priority**: Das ist der sichtbare Lohn der Wahl und der Ort, an dem alle späteren
Systeme ansetzen. Er kommt nach P1, weil der Weg bis zur Anmeldung schon allein prüfbar ist.

**Independent Test**: Ein Spiel mit dem Laden im Gewerbegebiet anlegen, ins Hauptmenü gehen und
mit „Weiterspielen“ fortsetzen: Der Bildschirm zeigt denselben Laden, Namen und Kontostand.

**Acceptance Scenarios**:

1. **Given** ein Spiel wurde eben angelegt, **When** der Spielbildschirm erscheint, **Then** zeigt
   er das Innere des gewählten Ladens, leer, dazu den Ladennamen und in der Leuchtanzeige DI
   01.01.1985 und den Kontostand.
2. **Given** zwei Spiele mit verschiedenen Läden, **When** der Spieler jedes fortsetzt, **Then**
   zeigt jedes sein eigenes Ladenbild, seinen Namen und seinen Kontostand.
3. **Given** ein laufendes Spiel, **When** der Spieler „Zum Hauptmenü“ wählt, **Then** wird wie
   bisher gespeichert, und das Hauptmenü erscheint; der Spielstand heißt wie der Laden.

---

### User Story 4 - Die Miete geht ab (Priority: P2)

Am Ersten jedes Monats bucht das Konto die Monatsmiete ab. Der Kontostand auf dem Spielbildschirm
sinkt entsprechend, und der Spielstand hält ihn fest.

**Why this priority**: Die laufende Miete ist der Grund, warum die Wahl des Ladens zählt: Ein
teurer Laden frisst das Kapital schneller. Erst die Wirtschaft (03-04) bringt Einnahmen dagegen.

**Independent Test**: Ein Spiel mit bekannter Miete bis zum 01.03.1985 laufen lassen (von Hand
oder im automatischen Test vorgespult): Der Kontostand ist um genau so viele Monatsmieten
gesunken, wie Monatserste vergangen sind, und bleibt nach Speichern und Fortsetzen gleich.

**Acceptance Scenarios**:

1. **Given** ein Spiel im Stadtteilzentrum (1.440 DM Monatsmiete) am 31.01.1985, **When** der
   01.02.1985 beginnt, **Then** sinkt der Kontostand um 1.440,00 DM, und der Spielbildschirm
   zeigt den neuen Stand.
2. **Given** ein Spiel wird am 15.03.1985 gespeichert und fortgesetzt, **When** der 01.04.1985
   beginnt, **Then** wird die Miete genau einmal abgebucht, nicht doppelt und nicht gar nicht.
3. **Given** ein Spiel läuft über mehrere Monatserste, **When** man die Abbuchungen zählt,
   **Then** ist es genau eine je Monatserstem seit Mietbeginn.

---

### User Story 5 - Spielstände von vorher (Priority: P3)

Spielstände, die vor diesem Feature angelegt wurden, haben keinen Laden. Sie lassen sich nicht
mehr fortsetzen und stehen in der Liste wie jeder andere unvollständige Spielstand.

**Why this priority**: Es gibt sie nur auf Klaus' Rechner und im Selbsttest, das Spiel ist noch in
der Entwicklung. Wichtig ist nur, dass nichts abstürzt.

**Independent Test**: Einen Spielstand im bisherigen Format ohne Laden in den Ordner legen und das
Hauptmenü öffnen: Er steht als beschädigt in der Liste und lässt sich löschen.

**Acceptance Scenarios**:

1. **Given** ein Spielstand ohne Laden liegt im Ordner, **When** das Hauptmenü erscheint, **Then**
   stürzt nichts ab, und der Spielstand steht als nicht fortsetzbar in der Liste, mit demselben
   Grund wie jeder Spielstand, dem ein Teil fehlt.
2. **Given** ein solcher Spielstand, **When** der Spieler ihn im Löschmodus wählt, **Then** lässt
   er sich löschen wie jeder andere.

---

### Edge Cases

- **Alle Läden zu teuer:** Darf nicht vorkommen. In jedem Grad muss mindestens ein Laden
  bezahlbar sein (FR-021); die Tests prüfen das für alle Grade.
- **Kapitalnachweis genau gleich dem Startkapital:** Der Laden ist bezahlbar. Nach der Kaution
  bleiben genau sechs Monatsmieten auf dem Konto; ohne Einnahmen ist es nach der sechsten Miete
  am 01.07.1985 leer.
- **Konto im Minus:** Ohne Einnahmen sinkt das Konto Monat für Monat und fällt irgendwann unter
  null. Was dann geschieht, regelt FR-025.
- **Langer Name:** Der Ladenname ist auf eine Länge begrenzt, die auf dem Spielbildschirm, in den
  Hinweisen des Hauptmenüs und der Liste und in der Rückfrage ganz zu sehen ist (FR-016, SC-006).
  In der Spalte der Liste wird er nach dem Baustein Liste mit „…“ gekürzt.
- **Zeichen im Namen:** Umlaute und ß sind erlaubt; Zeichen, die die Schrift des Spiels nicht
  zeigen kann, lassen sich nicht eintippen.
- **Gleicher Name zweimal:** Erlaubt; Grad, Spieldatum und „zuletzt gespielt“ unterscheiden
  die Spielstände (FR-018).
- **Zurück aus jedem Schritt:** Esc und „Zurück“ führen je einen Schritt zurück: Anmeldung →
  Mietvertrag → Exposé → Stadtplan → Gradwahl. Zurück von der Anmeldung nimmt die Unterschrift
  weg; der eingetippte Name bleibt, solange die Eröffnung offen ist, auch bei einem anderen Laden.
  Erst die abgegebene Anmeldung legt etwas fest.
- **Speichern scheitert beim Anlegen:** Wie bisher entsteht kein Spiel; die Meldung „Speichern
  ging nicht. Es ist kein Spiel angelegt.“ erscheint als Meldung neben „Anmelden“, Name und
  Unterschrift bleiben stehen, und der Spieler kann es erneut versuchen.
- **Fenster schließen mitten in der Ladenwahl:** Die App endet ohne Rückfrage, und es bleibt kein
  Spielstand zurück, weil noch keiner angelegt ist.
- **Spielende 31.12.1999:** Die Miete am 01.12.1999 ist die letzte; danach gibt es keinen
  Monatsersten mehr.
- **Gleiches Spiel, gleicher Fahrplan:** Die Wahl des Ladens ändert den Fahrplan der Zeitleiste
  nicht. Seed und Grad ergeben denselben Fahrplan wie bisher, egal welcher Laden.

## Requirements *(mandatory)*

### Functional Requirements

**Ablauf**

- **FR-001**: Nach der Wahl des Grads MUST der Spieler durch diese Schritte geführt werden, in
  dieser Reihenfolge: Stadtplan, Exposé, Mietvertrag, Gewerbeanmeldung, Spielbildschirm. Die
  ersten vier spielen im Büro des Maklers, einer Szene im Adventure-Stil: Der Stadtplan hängt an
  der Wand, Exposés, Mietvertrag und Formular liegen auf dem Schreibtisch, der Makler sitzt
  dahinter. Ein Klick auf einen Gegenstand holt ihn heran, etwa den Stadtplan oder ein Exposé.
- **FR-001a**: Anklickbare Dinge im Büro MUST den Regeln des Style-Guides für anklickbare Stellen
  folgen: Beim Überfahren wechselt der Mauszeiger, die Stelle wird `signalgelb` hervorgehoben, ein
  Tooltip nennt Funktion und Taste („Stadtplan ansehen.“); Rechtsklick zeigt den Tooltip, löst aber
  nichts aus. Mit der Tastatur lassen sie sich in fester Reihenfolge anwählen (Vertrag).
- **FR-001b**: Der Makler MUST eine eigene Figur mit Steckbrief sein (Name, Alter, Aussehen, Art zu
  reden), den Klaus freigibt; er soll in späteren Features wiederkommen, etwa beim Umzug. Er
  sagt in einer Sprechblase feste Sätze: einen beim Betreten des Büros, je einen zu jedem Exposé,
  beim Mietvertrag, bei der Gewerbeanmeldung und beim Abschied, dazu einen weiteren, wenn der
  Spieler ihn anklickt. Antworten gibt es nicht; ein Dialog gehört zu 09-02. Die Sätze stehen als
  Daten, nicht im Code.
- **FR-001c**: Jede Figur des Spiels MUST eine Beschreibung in der game_bible haben: Name, Rolle,
  Alter, Optik, Art zu reden, wo sie vorkommt und ihr Referenzbild, das für jedes neue Bild der
  Figur als Vorlage dient. Eine Übersicht listet alle Figuren. In diesem Feature: der
  Ladenbesitzer und der Makler.
- **FR-002**: Jeder Schritt vor der Abgabe der Gewerbeanmeldung MUST sich zurücknehmen lassen,
  mit Esc und mit einem sichtbaren „Zurück“, je einen Schritt; vom Stadtplan zurück in die
  Gradwahl.
- **FR-003**: Ein Spielstand MUST erst entstehen, wenn die Gewerbeanmeldung abgegeben ist. Davor
  wird nichts geschrieben.
- **FR-004**: Alle Schritte MUST sich mit Maus und mit Tastatur bedienen lassen; Hover zeigt, was
  ein Klick tut (Verfassung I).

**Stadt und Läden**

- **FR-005**: Die Stadt MUST eine fiktive westdeutsche Mittelstadt mit rund 150.000 Einwohnern
  sein, mit den Vierteln Innenstadt, Wohngebiet und Gewerbegebiet. Ihr Name und die
  Straßennamen sind erfunden.
- **FR-006**: Die Stadt MUST vier Läden zur Wahl stellen, jeder mit eigenem Charakter:

  | Laden | Viertel | Miete | Fläche | Laufkundschaft | Sichtbarkeit | Eigenart |
  |---|---|---|---|---|---|---|
  | Fußgängerzone | Innenstadt | am höchsten | klein | hoch | hoch | Parken schwierig |
  | Stadtteilzentrum | Wohngebiet | mittel | mittel | mittel | mittel | Stammkunden aus der Nachbarschaft |
  | Gewerbegebiet | Gewerbegebiet | am niedrigsten | groß | niedrig | niedrig | Parkplätze vor der Tür, viel Platz für Lager |
  | Nähe Bahnhof | Innenstadt, Rand | niedrig | klein bis mittel | hoch | mittel | viel Durchgang, Ruf der Gegend zweifelhaft |

  Jeder Laden hat: Anschrift, Viertel, Fläche in m², Monatsmiete in
  DM, Kaution, Laufkundschaft und Sichtbarkeit als Stufe, eine kurze Beschreibung,
  Kleingedrucktes, ein Foto von außen und ein Bild von innen, leer.
- **FR-007**: Laufkundschaft und Sichtbarkeit MUST gespeichert und im Exposé in Worten
  angedeutet werden; sie haben in diesem Feature keine Wirkung auf das Spiel.
- **FR-008**: Die Daten der Stadt und der Läden MUST in der game_bible gepflegt werden, je Laden
  eine Notiz nach einer eigenen Vorlage, Preise als Range wie dort üblich. Ein Importer bringt sie
  ins Spiel; Klaus ändert Mieten und Texte in der game_bible, ohne Code anzufassen. Ein Bau des
  Spiels bricht ab, wenn die erzeugten Daten nicht zur game_bible passen.

**Stadtplan**

- **FR-009**: Der Stadtplan MUST die ganze Stadt als ein Bild zeigen, mit den Vierteln und je
  einer Markierung pro Laden. Er hängt an der Wand des Büros und wird zum Lesen herangeholt;
  ein Klick auf eine Markierung öffnet das Exposé dieses Ladens.
- **FR-010**: Eine Markierung MUST zeigen, ob der Laden bezahlbar ist; ein zu teurer ist als nicht
  mietbar gekennzeichnet („grau“, Darstellung nach Style-Guide), öffnet aber trotzdem sein Exposé.
  Der Tooltip einer Markierung nennt Funktion, Viertel und Monatsmiete.

**Exposé**

- **FR-011**: Das Exposé MUST als Blatt Papier eines Maklers erscheinen, mit Foto von außen,
  Anschrift, Viertel, Fläche, Monatsmiete, Kaution, Beschreibung und Kleingedrucktem am Fuß des
  Blatts, in einer kleineren Schrift als der Text des Blatts (Schriften nach Style-Guide).
- **FR-012**: Das Kleingedruckte MUST fester Text je Laden sein, der Hinweise auf Vor- und
  Nachteile des Standorts gibt, etwa „Parkplätze nur in der Tiefgarage am Markt“. Es verweist auf
  keine Ereignisse der Zeitleiste (Ortsbezug ist 05-03).
- **FR-013**: Übersteigt der Kapitalnachweis (FR-021) das Startkapital, MUST das Exposé das
  sichtbar sagen, etwa als Stempel oder Vermerk des Maklers, mit verlangtem Nachweis und Kapital
  des Spielers in DM, und keinen Weg zum Mietvertrag anbieten.
- **FR-014**: Von einem Exposé aus MUST der Spieler zum nächsten und vorigen Laden blättern
  können, ohne über den Stadtplan zu gehen.

**Mietvertrag**

- **FR-015**: Der Mietvertrag MUST als Blatt Papier erscheinen, mit Vermieter, Mieter (eine leere
  Zeile, auf der die Unterschrift des Spielers steht, ein gezeichneter Schriftzug, kein Name),
  Anschrift, Fläche, Monatsmiete, Kaution von drei Monatsmieten, Mietbeginn
  01.01.1985 und einer Unterschriftszeile. Unterschreiben ist eine eigene, bewusste Handlung.

**Gewerbeanmeldung und Ladenname**

- **FR-016**: Die Gewerbeanmeldung MUST als amtliches Formular erscheinen, mit einem Feld für den
  Ladennamen, das der Spieler eintippt. Der Name hat 1 bis 24 Zeichen (vorläufig; im Plan gegen
  den Platz in Liste und Spielbildschirm geprüft), Leerzeichen am Anfang und Ende zählen nicht.
- **FR-017**: Der Ladenname MUST der angezeigte Name des Spielstands werden: in „Spiel laden“, im
  Hinweis zu „Weiterspielen“, in der Rückfrage beim Löschen und im Tooltip zu „Zum Hauptmenü“.
  Die Datei behält ihre Nummer (`spiel_N.json`).
- **FR-018**: Zwei Spiele MUST denselben Ladennamen tragen dürfen; jedes Spiel ist eine eigene
  Welt. Auseinander hält man sie wie bisher an Grad, Spieldatum und „zuletzt gespielt“ in der
  Liste; die Rückfrage beim Löschen nennt neben dem Namen auch Grad und Spieldatum.
- **FR-019**: Die Anmeldung MUST sich erst abgeben lassen, wenn der Name gültig ist; bis dahin ist
  „Anmelden“ aus, und ein Text des Formulars unter dem Feld sagt, was fehlt.

**Geld**

- **FR-020**: Das Startkapital MUST vom Grad abhängen, und die Mieten der Läden MUST zu
  Westdeutschland 1985 passen. Es gelten diese Beträge (Klaus, 2026-10-29, nach der Recherche in
  [recherche-geld.md](recherche-geld.md)):

  | Laden | Fläche | Miete/Monat | Kaution | Kapitalnachweis |
  |---|---|---|---|---|
  | Fußgängerzone | 60 m² | 4.800 DM | 14.400 DM | 43.200 DM |
  | Nähe Bahnhof | 80 m² | 2.240 DM | 6.720 DM | 20.160 DM |
  | Stadtteilzentrum | 90 m² | 1.440 DM | 4.320 DM | 12.960 DM |
  | Gewerbegebiet | 150 m² | 1.350 DM | 4.050 DM | 12.150 DM |

  Startkapital: Leicht 100.000 DM, Mittel 60.000 DM, Schwer 30.000 DM. Die Mieten sind aus Werten
  des RDM-Preisspiegels 2001 auf 1985 zurückgeschätzt, das Startkapital lehnt sich an belegte
  Gründungen an (1979 im Schnitt rund 26.500 DM Eigenmittel und 32.500 DM Eigenkapitalhilfe).
  Alle Beträge stehen bei den Daten der Läden (FR-008) und lassen sich dort ändern.
- **FR-021**: Ein Laden MUST bezahlbar sein, wenn das Startkapital mindestens den
  Kapitalnachweis deckt, den der Vermieter verlangt: Kaution plus sechs Monatsmieten. Mit den
  Beträgen aus FR-020 ist auf „Schwer“ die Fußgängerzone grau, alle anderen Läden und alle Läden
  auf „Mittel“ und „Leicht“ sind bezahlbar. In jedem Grad MUST mindestens ein Laden bezahlbar
  sein.
- **FR-022**: Die Kaution MUST drei Monatsmieten betragen und bei der Anmeldung vom Startkapital
  abgehen. Sie bleibt beim Vermieter und erscheint nicht als Guthaben.
- **FR-023**: Die Monatsmiete MUST am Ersten jedes Monats vom Konto abgehen, das erste Mal am
  01.02.1985, weil der Januar laut Kleingedrucktem für den Ausbau mietfrei ist (Festlegung von
  Claude, siehe Annahmen). Jede Abbuchung geschieht genau einmal, auch über Speichern und
  Fortsetzen hinweg.
- **FR-024**: Der Kontostand MUST auf den Pfennig genau geführt und wie im Style-Guide angezeigt
  werden, etwa „25.680,00 DM“.
- **FR-025**: Fällt der Kontostand unter null, MUST er weiter geführt und wie im Style-Guide für
  negative Beträge in der Leuchtanzeige angezeigt werden (Minus und „SOLL“); weitere Folgen hat das in diesem
  Feature nicht. Pleite, Kredit und Spielende gehören
  zu 03-06 Finanzen (Festlegung von Claude, siehe Annahmen).

**Spielbildschirm**

- **FR-026**: Der Spielbildschirm MUST das Innere des gewählten Ladens als Bild zeigen, leer, dazu
  den Ladennamen (wo er steht, regelt der Style-Guide) und Datum und Kontostand in der
  Leuchtanzeige nach dem Baustein Anzeige, etwa DI 01.01.1985 und 25.680,00 DM, und weiterhin den
  Knopf „Zum Hauptmenü“, jetzt mit Tooltip statt Hinweis daneben, weil er nicht mehr allein steht.
- **FR-027**: Die Spieluhr MUST auf dem Spielbildschirm laufen, mit Pause und drei Tempostufen
  (1, 2 und 7 Tage je Sekunde), bedienbar mit Maus und
  Tastatur, Pause auch mit der Leertaste. Der Spielbildschirm erscheint pausiert, auch nach dem
  Fortsetzen, damit niemand Tage verliert, während er sich umsieht (Festlegung von Claude). Ändert
  sich das Datum, aktualisieren sich Datum und Kontostand sofort. Am 31.12.1999 hält die Uhr an,
  und ihr Knopf ist aus; mehr geschieht dann in diesem Feature nicht.
- **FR-027a**: Pause und Tempo MUST sichtbar sein. Verlassen, Fenster schließen und Cmd+Q
  speichern wie bisher das aktuelle Spieldatum; ein Speichern während des Laufs ist darüber
  hinaus nicht nötig.

**Spielstand**

- **FR-028**: Der Spielstand MUST zusätzlich festhalten: welcher Laden, den Ladennamen, den
  Kontostand, Laufkundschaft und Sichtbarkeit des Ladens und bis zu welchem Monat die Miete
  abgebucht ist.
- **FR-029**: Speichern und Fortsetzen MUST denselben Laden, Namen und Kontostand ergeben; ein
  fortgesetztes Spiel bucht dieselben Mieten an denselben Tagen ab wie eines ohne Pause.
- **FR-030**: Ein Laden im Spielstand MUST seine Werte bei der Anmeldung festhalten: Ändert Klaus
  später Mieten oder Texte, gilt das erst ab dem nächsten neuen Spiel, wie beim Katalog.
- **FR-031**: Der Laden MUST ein Pflichtteil des Spielstands sein. Ein Spielstand ohne ihn,
  etwa einer von vor diesem Feature, gilt wie jeder unvollständige als beschädigt: nicht
  fortsetzbar, löschbar, mit dem bisherigen Grund für einen fehlenden Teil. Es gibt keinen eigenen
  Grund, keine Umwandlung und keinen Sonderweg für alte Spielstände (Klaus, 2026-10-29). Nie
  stürzt dabei etwas ab, und nie wird ein solcher Spielstand ungefragt gelöscht oder
  überschrieben.

**Unverändert**

- **FR-032**: Die Zeitleiste MUST unverändert bleiben: Die Wahl des Ladens wirkt nicht auf
  Fahrplan, Chancen oder Ereignisse. Für die Seeds 1, 4711 und 99999 in allen drei Graden ist der
  Fahrplan bytegleich zu vorher.

### Key Entities

- **Stadt**: der Ort des Spiels; Name, Einwohnerzahl, Viertel, Stadtplan.
- **Laden (Angebot)**: ein freier Laden der Stadt, wie der Makler ihn anbietet; Anschrift,
  Viertel, Fläche, Monatsmiete, Kaution, Laufkundschaft, Sichtbarkeit, Beschreibung,
  Kleingedrucktes, Bilder.
- **Mietvertrag**: die Verbindung von Spiel und Laden; Mietbeginn, Monatsmiete, Kaution; im
  Spielstand als Kopie der Werte des Ladens.
- **Ladenname**: der Name aus der Gewerbeanmeldung; zugleich der angezeigte Name des Spielstands.
- **Konto**: der Kontostand in DM und die Buchungen, die ihn ändern (Startkapital, Kaution, Miete);
  in diesem Feature nur Abgänge.
- **Startkapital**: der Betrag, mit dem ein Spiel beginnt; hängt vom Grad ab.
- **Kapitalnachweis**: was der Vermieter an Kapital sehen will, bevor er vermietet: Kaution plus
  sechs Monatsmieten. Er wird nur geprüft, nicht abgebucht.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Vom Bestätigen des Grads bis zum eigenen Laden braucht ein Spieler, der die Schritte
  kennt, höchstens 60 Sekunden, gemessen im Selbsttest-Ablauf `ladenwahl` mit festen Eingaben;
  jedes Papier erscheint ohne spürbare Wartezeit, unter 0,2 s, gemessen in einem Test.
- **SC-002**: Auf „Schwer“ ist genau die Fußgängerzone nicht mietbar, auf „Mittel“ und „Leicht“
  keiner; geprüft mit den Daten aus der game_bible.
- **SC-003**: Für ein Spiel, das ohne Pause bis zum 31.12.1999 läuft, sind genau 179 Mieten
  abgebucht (Februar 1985 bis Dezember 1999), und der Kontostand ist Startkapital minus Kaution
  minus 179 Monatsmieten, auf die Mark genau.
- **SC-004**: Ein Spiel, das an einem beliebigen Tag gespeichert und fortgesetzt wird, hat am
  31.12.1999 denselben Kontostand wie eines ohne Pause; geprüft für mindestens drei Tage,
  darunter ein Monatserster und der Tag davor.
- **SC-005**: Der Fahrplan der Zeitleiste ist für die Seeds 1, 4711 und 99999 in allen drei Graden
  bytegleich zu vorher, unabhängig vom gewählten Laden.
- **SC-006**: Jeder Ladenname mit 1 bis zur Höchstlänge Zeichen, auch mit Umlauten und aus den
  breitesten erlaubten Zeichen, ist auf dem Spielbildschirm, im Hinweis zu „Weiterspielen“, in den
  Hinweisen der Liste und in der Rückfrage vollständig zu lesen. In der Spalte der Liste wird er
  nach dem Baustein Liste gekürzt.
- **SC-007**: Wer vor der Abgabe der Anmeldung abbricht, an welcher Stelle auch immer, hinterlässt
  keine Datei im Ordner der Spielstände.

## Assumptions

- **Erster Monat mietfrei** (Festlegung von Claude): Das Spiel beginnt am 01.01.1985, einem
  Monatsersten. Damit nicht schon am ersten Tag Kaution und Miete fällig sind, ist der Januar laut
  Kleingedrucktem für den Ausbau mietfrei, wie es bei Gewerbemieten üblich ist. Am ersten Tag geht
  also nur die Kaution ab.
- **Konto im Minus ohne Folgen** (Festlegung von Claude): Pleite, Dispo, Kredit und Zinsen kommen
  mit 03-06 Finanzen. Bis dahin darf das Konto ins Minus und zeigt Minus und „SOLL“.
- **Kein Ortsbezug:** Die Ereignisse der Zeitleiste gelten weiter für alle Läden gleich (05-03).
- **Keine Einnahmen:** In diesem Feature gibt es nur Abgänge. Verkäufe, Nebenkosten, Strom und
  Steuern kommen mit der Wirtschaft.
- **Keine Gebühr für die Gewerbeanmeldung** im Konto: Die Recherche fand für 1985 keinen Betrag,
  die Gemeinden setzten ihn selbst fest, wohl im niedrigen zweistelligen DM-Bereich; das lohnt
  keine eigene Buchung.
- **Schauplatz:** Die Ladenwahl ist eine eigene Szene, das Büro des Maklers, außerhalb des
  Communicators; der Titelbildschirm mit Communicator bleibt bis zur Gradwahl unverändert. Wie
  Szene, Figur und Papiere aussehen und wie sich anklickbare Dinge zeigen, regelt der
  Style-Guide, der dafür vor dem Bau ergänzt wird, falls nötig (Verfassung IV). Dass die
  Gewerbeanmeldung im Büro des Maklers ausgefüllt wird statt auf dem Amt, ist eine Vereinfachung
  (Festlegung von Claude): Der Makler hat das Formular vom Gewerbeamt schon bereitliegen.
- **Texteingabe ist neu:** Bisher gibt es im Spiel kein Feld zum Eintippen. Die Gewerbeanmeldung
  braucht eines; im Plan wird geklärt, wie es im Stil des Spiels aussieht.
- **Grafiken:** Zehn Bilder (Büro des Maklers, Stadtplan, vier Läden von außen, vier leere
  Läden von innen) und die Figur des Maklers entstehen mit dem Skill `dcl-grafik` in einer eigenen
  Phase am Ende des Features. Bis dahin stehen Platzhalter in Bildgröße mit Beschriftung, etwa
  „FOTO FUSSGÄNGERZONE“. Die Lage der Läden auf dem Stadtplan gehört zum Stadtplan und wird mit
  dem echten Plan angepasst. Exposé, Mietvertrag und Gewerbeanmeldung werden gezeichnet, nicht generiert.
- **Selbsttest:** Der Ablauf `neues_spiel` des Selbsttests führt heute von der Gradwahl direkt ins
  Spiel und muss um die neuen Schritte ergänzt werden (`ki_dev.md`, Punkt 11).
- **Zeitleiste läuft still mit** (CHK010): Mit der Uhr läuft die Zeitleiste und meldet ihre
  Ereignisse; angezeigt werden sie erst mit 10-04. In 010 sieht der Spieler davon nichts.
- **Kein Speichern während des Spiels** (CHK011): Gespeichert wird beim Verlassen, Schließen und
  Fortsetzen; Speichern während des Spiels kommt mit 11-01. Bis dahin geht nach einem Absturz
  verloren, was seit dem Fortsetzen geschah.
- **Ende 1999** (CHK016): Am 31.12.1999 hält die Uhr an; Spielende und Bilanz kommen mit 11-05.
- **Tests spulen vor:** Wie in Feature 004 belegen automatische Tests die Mieten über viele
  Monate, indem sie das Spiel selbst vorspulen, unabhängig davon, ob die Uhr im Spiel läuft.
