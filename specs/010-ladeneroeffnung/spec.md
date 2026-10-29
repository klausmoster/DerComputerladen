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

## Überblick

Bisher führt die Gradwahl direkt in einen leeren Spielbildschirm mit dem Knopf „Zum Hauptmenü“.
Mit diesem Feature beginnt das eigentliche Spiel: Der Spieler sucht sich in einer Stadt einen
Laden, unterschreibt den Mietvertrag, meldet sein Gewerbe unter einem eigenen Namen an und steht
dann in seinem leeren Laden, mit Geld auf dem Konto und der ersten Miete vor Augen.

Beispiel: Klaus wählt „Schwer“. Auf dem Stadtplan von Wesselbach (Name vorläufig) sind vier
Läden markiert. Der Laden in der Fußgängerzone ist grau; sein Exposé sagt: „Die Kaution von
7.200 DM übersteigt Ihr Kapital.“ Er nimmt den Laden im Wohngebiet, unterschreibt den
Mietvertrag, meldet „Computer Klaus“ an und steht am 01.01.1985 im leeren Laden. Oben steht
„Computer Klaus · 01.01.1985 · Konto 13.200 DM“. Im Hauptmenü heißt sein Spielstand jetzt
„Computer Klaus“, die Datei bleibt `spiel_7.json`. (Alle Beträge im Beispiel sind Platzhalter;
die echten Zahlen klärt FR-020.)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Einen Laden aussuchen (Priority: P1)

Nach der Gradwahl sieht der Spieler den Stadtplan mit den Läden, die gerade frei sind. Wählt er
einen, liegt dessen Exposé vor ihm: ein Blatt Papier des Maklers mit Foto, Miete, Fläche, Lage und
Kleingedrucktem. Er blättert zwischen den Läden, vergleicht und entscheidet sich für einen. Ein
Laden, dessen Kaution sein Startkapital übersteigt, ist auf dem Plan grau; sein Exposé lässt sich
trotzdem lesen und sagt, warum er nicht in Frage kommt.

**Why this priority**: Die Wahl des Standorts ist die erste echte Entscheidung im Spiel. Ohne sie
gibt es keinen Laden, an dem alles Spätere hängt.

**Independent Test**: Ein neues Spiel auf „Mittel“ beginnen: Der Stadtplan erscheint mit allen
Läden. Jeden Laden wählen: Sein Exposé zeigt Foto, Miete, Fläche, Lage und Kleingedrucktes. Auf
„Schwer“ ist mindestens ein Laden grau, und sein Exposé nennt den Grund.

**Acceptance Scenarios**:

1. **Given** der Spieler hat einen Grad gewählt, **When** der Stadtplan erscheint, **Then** sind
   alle Läden der Stadt darauf markiert, je mit Lage im Viertel, und einer ist vorgewählt.
2. **Given** der Stadtplan ist zu sehen, **When** der Spieler einen Laden wählt, **Then** liegt
   dessen Exposé vor ihm, mit Foto, Monatsmiete, Kaution, Fläche, Lage, einer Beschreibung und
   dem Kleingedruckten.
3. **Given** ein Exposé liegt vor ihm, **When** er zum nächsten oder vorigen Laden blättert oder
   zum Stadtplan zurückgeht, **Then** sieht er das andere Exposé oder wieder den Plan, ohne dass
   etwas festgelegt ist.
4. **Given** die Kaution eines Ladens übersteigt das Startkapital des Grads, **When** der Spieler
   den Stadtplan sieht, **Then** ist dieser Laden grau; **When** er sein Exposé öffnet, **Then**
   sagt es, dass die Kaution sein Kapital übersteigt, und bietet keinen Mietvertrag an.
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
   Feld für den Ladennamen leer oder mit einem Vorschlag gefüllt, und er kann einen eigenen Namen
   eintippen.
4. **Given** die Gewerbeanmeldung mit einem gültigen Namen, **When** er sie abgibt, **Then** ist
   ein Spielstand mit diesem Namen, dem Grad, dem Laden und dem Kontostand nach Abzug der Kaution
   angelegt, und der Spielbildschirm erscheint.
5. **Given** der Name ist leer oder besteht nur aus Leerzeichen, **When** er die Anmeldung abgeben
   will, **Then** geht das nicht, und ein Hinweis sagt, dass ein Name fehlt.
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
   er das Innere des gewählten Ladens, leer, dazu Ladenname, Datum 01.01.1985 und Kontostand.
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

1. **Given** ein Spiel mit 1.200 DM Monatsmiete am 31.01.1985, **When** der 01.02.1985 beginnt,
   **Then** sinkt der Kontostand um 1.200 DM, und der Spielbildschirm zeigt den neuen Stand.
2. **Given** ein Spiel wird am 15.03.1985 gespeichert und fortgesetzt, **When** der 01.04.1985
   beginnt, **Then** wird die Miete genau einmal abgebucht, nicht doppelt und nicht gar nicht.
3. **Given** ein Spiel läuft über mehrere Monatserste, **When** man die Abbuchungen zählt,
   **Then** ist es genau eine je Monatserstem seit Mietbeginn.

---

### User Story 5 - Spielstände von vorher (Priority: P3)

Spielstände, die vor diesem Feature angelegt wurden, haben keinen Laden. Sie bleiben in der Liste
und werden sinnvoll behandelt, statt das Spiel abstürzen zu lassen oder zu verschwinden.

**Why this priority**: Es gibt sie bisher nur auf Klaus' Rechner und im Selbsttest. Wichtig ist,
dass nichts kaputtgeht; wie genau sie weiterlaufen, ist zweitrangig.

**Independent Test**: Einen Spielstand im bisherigen Format ohne Laden in den Ordner legen und das
Hauptmenü öffnen: Er steht in der Liste und verhält sich wie in FR-031 festgelegt.

**Acceptance Scenarios**:

1. **Given** ein Spielstand ohne Laden liegt im Ordner, **When** das Hauptmenü erscheint, **Then**
   stürzt nichts ab, und der Spielstand steht in der Liste unter seinem bisherigen Namen.
2. **Given** ein solcher Spielstand, **When** der Spieler ihn wählt, **Then** geschieht, was
   FR-031 festlegt.

---

### Edge Cases

- **Alle Läden zu teuer:** Darf nicht vorkommen. In jedem Grad muss mindestens ein Laden
  bezahlbar sein (FR-021); die Tests prüfen das für alle Grade.
- **Kaution genau gleich dem Startkapital:** Der Laden ist bezahlbar, das Konto steht danach
  auf 0 DM; die erste Miete bringt es ins Minus (siehe FR-025).
- **Konto im Minus:** Ohne Einnahmen sinkt das Konto Monat für Monat und fällt irgendwann unter
  null. Was dann geschieht, regelt FR-025.
- **Langer Name:** Der Ladenname ist auf eine Länge begrenzt, die im Spielbildschirm, in der
  Liste der Spielstände und im Hauptmenü ganz zu sehen ist (FR-016).
- **Zeichen im Namen:** Umlaute und ß sind erlaubt; Zeichen, die die Schrift des Spiels nicht
  zeigen kann, lassen sich nicht eintippen.
- **Gleicher Name zweimal:** Zwei Spiele dürfen gleich heißen oder nicht, siehe FR-018.
- **Zurück aus jedem Schritt:** Esc und „Zurück“ führen je einen Schritt zurück: Anmeldung →
  Mietvertrag → Exposé → Stadtplan → Gradwahl. Nach der Unterschrift bleibt die Unterschrift
  beim Zurückgehen nicht stehen; erst die abgegebene Anmeldung legt etwas fest.
- **Speichern scheitert beim Anlegen:** Wie bisher entsteht kein Spiel; die Meldung „Speichern
  ging nicht. Es ist kein Spiel angelegt.“ erscheint auf der Gewerbeanmeldung, die Eingaben
  bleiben stehen, und der Spieler kann es erneut versuchen.
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
  dieser Reihenfolge: Stadtplan, Exposé, Mietvertrag, Gewerbeanmeldung, Spielbildschirm.
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
- **FR-006**: Die Stadt MUST [NEEDS CLARIFICATION: drei oder vier Läden, und mit welchem Charakter
  je Laden?] zur Wahl stellen. Jeder Laden hat: Anschrift, Viertel, Fläche in m², Monatsmiete in
  DM, Kaution, Laufkundschaft und Sichtbarkeit als Stufe, eine kurze Beschreibung,
  Kleingedrucktes, ein Foto von außen und ein Bild von innen, leer.
- **FR-007**: Laufkundschaft und Sichtbarkeit MUST gespeichert und im Exposé in Worten
  angedeutet werden; sie haben in diesem Feature keine Wirkung auf das Spiel.
- **FR-008**: Die Daten der Läden MUST an einer Stelle gepflegt werden, nicht verstreut im Code,
  so dass Klaus Mieten und Texte ändern kann, ohne Logik anzufassen.

**Stadtplan**

- **FR-009**: Der Stadtplan MUST die ganze Stadt als ein Bild zeigen, mit den Vierteln und je
  einer Markierung pro Laden.
- **FR-010**: Eine Markierung MUST zeigen, ob der Laden bezahlbar ist; ein zu teurer ist grau.
  Hover über einer Markierung zeigt Viertel und Monatsmiete.

**Exposé**

- **FR-011**: Das Exposé MUST als Blatt Papier eines Maklers erscheinen, mit Foto von außen,
  Anschrift, Viertel, Fläche, Monatsmiete, Kaution, Beschreibung und Kleingedrucktem in kleinerer
  Schrift am Fuß des Blatts.
- **FR-012**: Das Kleingedruckte MUST fester Text je Laden sein, der Hinweise auf Vor- und
  Nachteile des Standorts gibt, etwa „Parkplätze nur in der Tiefgarage am Markt“. Es verweist auf
  keine Ereignisse der Zeitleiste (Ortsbezug ist 05-03).
- **FR-013**: Ist die Kaution höher als das Startkapital, MUST das Exposé das sichtbar sagen,
  etwa als Stempel oder Vermerk des Maklers, mit Kaution und Kapital in DM, und keinen Weg zum
  Mietvertrag anbieten.
- **FR-014**: Von einem Exposé aus MUST der Spieler zum nächsten und vorigen Laden blättern
  können, ohne über den Stadtplan zu gehen.

**Mietvertrag**

- **FR-015**: Der Mietvertrag MUST als Blatt Papier erscheinen, mit Vermieter, Mieter (noch ohne
  Ladennamen), Anschrift, Fläche, Monatsmiete, Kaution von drei Monatsmieten, Mietbeginn
  01.01.1985 und einer Unterschriftszeile. Unterschreiben ist eine eigene, bewusste Handlung.

**Gewerbeanmeldung und Ladenname**

- **FR-016**: Die Gewerbeanmeldung MUST als amtliches Formular erscheinen, mit einem Feld für den
  Ladennamen, das der Spieler eintippt. Der Name hat 1 bis 24 Zeichen (vorläufig; im Plan gegen
  den Platz in Liste und Spielbildschirm geprüft), Leerzeichen am Anfang und Ende zählen nicht.
- **FR-017**: Der Ladenname MUST der angezeigte Name des Spielstands werden: in „Spiel laden“, im
  Hinweis zu „Weiterspielen“, in der Rückfrage beim Löschen und auf dem Knopf „Zum Hauptmenü“.
  Die Datei behält ihre Nummer (`spiel_N.json`).
- **FR-018**: Haben zwei Spiele denselben Ladennamen, MUST der Spieler sie trotzdem
  auseinanderhalten können; ob gleiche Namen erlaubt sind, klärt `/speckit-clarify`.
- **FR-019**: Die Anmeldung MUST sich erst abgeben lassen, wenn der Name gültig ist; ein Hinweis
  sagt, was fehlt.

**Geld**

- **FR-020**: Das Startkapital MUST vom Grad abhängen, und die Mieten der Läden MUST zu
  Westdeutschland 1985 passen: [NEEDS CLARIFICATION: Beträge in DM für Startkapital je Grad und
  Monatsmiete je Laden, mit Quellen].
- **FR-021**: In jedem Grad MUST mindestens ein Laden bezahlbar sein, und auf „Schwer“ MUST
  mindestens einer zu teuer sein.
- **FR-022**: Die Kaution MUST drei Monatsmieten betragen und bei der Anmeldung vom Startkapital
  abgehen. Sie bleibt beim Vermieter und erscheint nicht als Guthaben.
- **FR-023**: Die Monatsmiete MUST am Ersten jedes Monats vom Konto abgehen, das erste Mal am
  01.02.1985, weil der Januar laut Kleingedrucktem für den Ausbau mietfrei ist (Festlegung von
  Claude, siehe Annahmen). Jede Abbuchung geschieht genau einmal, auch über Speichern und
  Fortsetzen hinweg.
- **FR-024**: Der Kontostand MUST in ganzen DM geführt und mit Tausenderpunkt und „DM“ angezeigt
  werden, etwa „13.200 DM“.
- **FR-025**: Fällt der Kontostand unter null, MUST er weiter geführt und auffällig angezeigt
  werden; weitere Folgen hat das in diesem Feature nicht. Pleite, Kredit und Spielende gehören
  zu 03-06 Finanzen (Festlegung von Claude, siehe Annahmen).

**Spielbildschirm**

- **FR-026**: Der Spielbildschirm MUST das Innere des gewählten Ladens als Bild zeigen, leer,
  dazu Ladenname, Spieldatum und Kontostand, und weiterhin den Knopf „Zum Hauptmenü“.
- **FR-027**: Die Spieluhr MUST auf dem Spielbildschirm [NEEDS CLARIFICATION: laufen, mit Pause
  und Tempo, oder wie bisher stehen?]. Ändert sich das Datum, aktualisieren sich Datum und
  Kontostand sofort.

**Spielstand**

- **FR-028**: Der Spielstand MUST zusätzlich festhalten: welcher Laden, den Ladennamen, den
  Kontostand, Laufkundschaft und Sichtbarkeit des Ladens und bis zu welchem Monat die Miete
  abgebucht ist.
- **FR-029**: Speichern und Fortsetzen MUST denselben Laden, Namen und Kontostand ergeben; ein
  fortgesetztes Spiel bucht dieselben Mieten an denselben Tagen ab wie eines ohne Pause.
- **FR-030**: Ein Laden im Spielstand MUST seine Werte bei der Anmeldung festhalten: Ändert Klaus
  später Mieten oder Texte, gilt das erst ab dem nächsten neuen Spiel, wie beim Katalog.
- **FR-031**: Spielstände ohne Laden, angelegt vor diesem Feature, MUST in der Liste bleiben;
  nie stürzt dabei etwas ab, und nie wird ein solcher Spielstand ungefragt gelöscht oder
  überschrieben. Was beim Fortsetzen geschieht, klärt `/speckit-clarify`.

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

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Vom Bestätigen des Grads bis zum eigenen Laden braucht ein Spieler, der die Schritte
  kennt, höchstens 60 Sekunden; jedes Papier erscheint ohne spürbare Wartezeit (unter 0,2 s).
- **SC-002**: In jedem Grad ist mindestens ein Laden bezahlbar, auf „Schwer“ mindestens einer zu
  teuer; geprüft für alle drei Grade.
- **SC-003**: Für ein Spiel, das ohne Pause bis zum 31.12.1999 läuft, sind genau 179 Mieten
  abgebucht (Februar 1985 bis Dezember 1999), und der Kontostand ist Startkapital minus Kaution
  minus 179 Monatsmieten, auf die Mark genau.
- **SC-004**: Ein Spiel, das an einem beliebigen Tag gespeichert und fortgesetzt wird, hat am
  31.12.1999 denselben Kontostand wie eines ohne Pause; geprüft für mindestens drei Tage,
  darunter ein Monatserster und der Tag davor.
- **SC-005**: Der Fahrplan der Zeitleiste ist für die Seeds 1, 4711 und 99999 in allen drei Graden
  bytegleich zu vorher, unabhängig vom gewählten Laden.
- **SC-006**: Jeder Ladenname mit 1 bis zur Höchstlänge Zeichen, auch mit Umlauten, ist im
  Spielbildschirm, in der Liste der Spielstände und im Hinweis des Hauptmenüs vollständig zu
  lesen.
- **SC-007**: Wer vor der Abgabe der Anmeldung abbricht, an welcher Stelle auch immer, hinterlässt
  keine Datei im Ordner der Spielstände.

## Assumptions

- **Erster Monat mietfrei** (Festlegung von Claude): Das Spiel beginnt am 01.01.1985, einem
  Monatsersten. Damit nicht schon am ersten Tag Kaution und Miete fällig sind, ist der Januar laut
  Kleingedrucktem für den Ausbau mietfrei, wie es bei Gewerbemieten üblich ist. So stimmt Klaus'
  Regel „grau, wenn die Kaution das Kapital übersteigt“ auch für den ersten Tag.
- **Konto im Minus ohne Folgen** (Festlegung von Claude): Pleite, Dispo, Kredit und Zinsen kommen
  mit 03-06 Finanzen. Bis dahin darf das Konto ins Minus und wird nur auffällig angezeigt.
- **Kein Ortsbezug:** Die Ereignisse der Zeitleiste gelten weiter für alle Läden gleich (05-03).
- **Keine Einnahmen:** In diesem Feature gibt es nur Abgänge. Verkäufe, Nebenkosten, Strom und
  Steuern kommen mit der Wirtschaft.
- **Keine Gebühr für die Gewerbeanmeldung** im Konto, solange die Recherche keinen Betrag liefert,
  der spürbar ist; ein Betrag von wenigen Mark lohnt keine eigene Buchung.
- **Schauplatz:** Stadtplan, Exposé, Mietvertrag und Gewerbeanmeldung sind eigene Bilder bzw.
  Papiere außerhalb des Communicators; der Titelbildschirm mit Communicator bleibt bis zur
  Gradwahl unverändert. Wie die Papiere aussehen, regelt der Style-Guide, der dafür ergänzt
  wird, falls nötig (Verfassung IV).
- **Texteingabe ist neu:** Bisher gibt es im Spiel kein Feld zum Eintippen. Die Gewerbeanmeldung
  braucht eines; im Plan wird geklärt, wie es im Stil des Spiels aussieht.
- **Grafiken:** Stadtplan, Fotos der Läden von außen und Bilder von innen entstehen mit dem Skill
  `dcl-grafik`; wann und ob mit Platzhaltern begonnen wird, klärt `/speckit-clarify`.
- **Selbsttest:** Der Ablauf `neues_spiel` des Selbsttests führt heute von der Gradwahl direkt ins
  Spiel und muss um die neuen Schritte ergänzt werden (`ki_dev.md`, Punkt 11).
- **Tests spulen vor:** Wie in Feature 004 belegen automatische Tests die Mieten über viele
  Monate, indem sie das Spiel selbst vorspulen, unabhängig davon, ob die Uhr im Spiel läuft.
