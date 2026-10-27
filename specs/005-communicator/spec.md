# Feature Specification: Communicator als Steuerelement

**Feature Branch**: `feature/005-communicator`

**System**: 10 Präsentation & UI

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "Neues Feature 005: Nutze Communicator als Steuerelement. Wir
beginnen mit dem Titelscreen, soll aber als generelles Steuerelement beibehalten werden. Das
Detail muss dann im Zweifel noch in den jeweiligen Features ausdefiniert werden. Mit diesem
Feature 005 wollen wir aber die Umsetzung vom Spike ‚Communicator im Hauptmenü' aufgreifen und
das Titelmenü direkt umbauen."

## Clarifications

### Specify 2026-10-27

Fragen aus `/speckit-specify`, von Klaus einzeln als Auswahl beantwortet:

- Q: Welche Blätter des Titels kommen auf den Communicator? → A: Alle vier: Hauptmenü, Gradwahl,
  Spielstände und Rückfrage stehen als Seiten auf der Anzeige; im Titel gibt es kein Endlospapier
  mehr (Klaus, nach Empfehlung). Die Anzeige muss dafür die Liste der Spielstände fassen.
  Verworfen: die Liste als Papier wie im Spike, weil der Wechsel zwischen Gerät und Papier
  ungewollt wirkt; nur das Hauptmenü, weil das Gerät dann bei fast jedem Schritt hinausführe.
- Q: Welches Gehäuse hat der Communicator im Titel? → A: fest der Organizer von 1991 (Klaus, nach
  Empfehlung). Verworfen: das Gehäuse zum Jahr des zuletzt gespielten Spielstands, weil es jetzt
  schon drei Gehäuse bräuchte; der Communicator von 1996, weil er nicht zum Titelbild passt und
  das Gerät vom Spielende vorwegnimmt.
- Q: Das Gerät mit der Liste auf der Anzeige verdeckt einen großen Teil von Titelbild T-01, auch
  das Schaufenster. Wie damit umgehen? → A: Das Titelbild wird angepasst: Ein neues Titelbild
  T-02 mit einer ruhigen Fläche für das Gerät entsteht in diesem Feature (Klaus, gegen die
  Empfehlung „Verdecken erlaubt“). Verworfen: T-01 verdecken lassen; eine kleinere Anzeige mit
  Ark Pixel 10, weil die Menüschrift im Titel kleiner würde.

### Clarify 2026-10-27

Fragen aus `/speckit-clarify`, von Klaus einzeln als Auswahl beantwortet:

- Q: Wie sieht die gewählte Zeile auf der Anzeige aus? → A: invertiert wie auf einem echten LCD:
  ein dunkler Balken, Schrift und Pfeil darin in der Farbe der Anzeige (Klaus, nach Empfehlung).
  Vorbild ist die Regel der Leuchtanzeige, dass eine echte Anzeige nur eine Farbe kann. Verworfen:
  `signalgelb` wie auf dem Papier, das im Spike auf dem LCD fremd wirkte; nur der Pfeil, weil die
  Auswahl dann schwach zu sehen ist.
- Q: Welche Farbe hat der Grund der Anzeige? → A: eine neue Farbrolle `lcd`, ein graugrünes
  LCD-Grau als 16. Farbe der Oberfläche (Klaus, gegen die Empfehlung `endlos-gruen`). Verworfen:
  `endlos-gruen` als LCD-Grund; `anzeige` auf `anzeige-grund`, das wie eine Kasse wirkt
  und dort nur Ziffern und wenige Wörter erlaubt. Folge: Der Style-Guide bekommt eine 16. Farbe,
  und der Plan klärt, ob und wie die eingefrorene Hauptpalette sie aufnimmt.
- Q: Wo stehen im Titel der Communicator und der Hinweis zur gewählten Zeile? → A: Der
  Communicator steht rechts unten, seine Tastatur ragt unten aus dem Bild, als halte man ihn hoch;
  das Logo bleibt links oben frei. Der Hinweis bleibt ein Zettel links neben dem Gerät auf Höhe
  der gewählten Zeile (Klaus, nach Empfehlung). Verworfen: das Gerät mittig, weil dann der Hinweis
  wenig Platz hat und das Logo rücken müsste; der Hinweis als Statuszeile auf der Anzeige, weil er
  Zeilen der Liste kostet.
- Q: Fährt der Communicator hinaus, bevor das Spiel beginnt? → A: Ja: Beginnt oder setzt der
  Spieler ein Spiel fort, gleitet der Communicator erst nach unten hinaus, dann erscheint der
  Spielbildschirm, wie wenn man das Gerät wegsteckt (Klaus, gegen die Empfehlung „sofort ins
  Spiel“). Verworfen: der Wechsel ohne Fahrt, der keine Wartezeit hätte.
- Q: Der Spike empfahl, im Titel beim Papier zu bleiben und das Gerät erst im Spielbildschirm zu
  bauen; Klaus will den Titel umbauen. Wie halten wir es? → A: Der Titel wird umgebaut, die
  Empfehlung des Spikes bewusst verworfen (Klaus, nach Empfehlung). Ihre drei Gründe sind durch
  die Antworten oben gelöst: Statt T-01 zu verdecken, kommt T-02 (FR-015); statt zwischen Gerät
  und Papier zu wechseln, stehen alle vier Blätter auf dem Gerät (FR-011); und weil das Gerät ins
  Spiel gehört und dort mit den Jahren wechselt, hat der Titel fest den Organizer von 1991
  (FR-012), der Wechsel kommt mit dem Spielbildschirm. Verworfen: dem Spike folgen und 005 auf dem
  Spielbildschirm beginnen; Titel und Spielbildschirm zugleich, weil das Feature dann deutlich
  größer würde.

## Überblick

Bisher bedient der Spieler den Titel über Blätter aus Endlospapier: Hauptmenü, Gradwahl, Liste
der Spielstände und Rückfrage (Feature 004). Mit diesem Feature kommt der **Communicator**: ein
Taschengerät aus der Zeit, das von unten ins Bild fährt und auf seiner Anzeige die Menüs zeigt.
Er wird im Titel eingeführt und ersetzt dort das Papier. Gebaut wird er aber als allgemeines
Steuerelement, das spätere Bildschirme mit eigenen Seiten benutzen, zuerst wohl der
Spielbildschirm.

Beispiel: Klaus startet das Spiel. Das Titelbild erscheint, der Organizer gleitet von unten
herein, auf seiner Anzeige steht das Hauptmenü mit „Weiterspielen“ vorgewählt. Klaus drückt Enter,
der Organizer gleitet wieder hinaus, und Klaus ist im Spiel. Später zeigt derselbe Communicator im Laden die Seite Termine, nur mit anderem
Inhalt; wie er dort geöffnet wird, regelt das Feature des Spielbildschirms.

Vorgeschichte: Die Recherche
[navigation-taschengeraet.md](../../docs/recherche/navigation-taschengeraet.md) schlägt vor, das
Spiel über ein Gerät zu bedienen, dessen Gehäuse mit den Jahren wechselt. Der Spike „Communicator
im Hauptmenü“ (Branch `claude/spike-communicator-625f4c`, Commit `481c7e0`) hat einen Organizer
von 1991 probehalber ins Hauptmenü gebaut. Seine Erkenntnisse stehen im Nachtrag zur Recherche;
er empfahl, den Titel beim Papier zu lassen und das Gerät erst im Spielbildschirm zu bauen. Klaus
hat am 2026-10-27 anders entschieden: Der Titel wird mit diesem Feature umgebaut, und die Gründe
des Spikes sind durch die Entscheidungen unter „Clarifications“ gelöst.

**Begriffe** (mit Beispiel):
- **Communicator**: das Taschengerät, über das der Spieler das Spiel bedient. Der Name gilt für
  das Steuerelement, egal welches Gehäuse es gerade hat. Beispiel: Im Titel ist es der Organizer
  von 1991, 1997 im Spiel vielleicht ein Gerät nach Art des Nokia 9000.
- **Gehäuse**: wie der Communicator aussieht, ein gemaltes Bild auf dem Bildraster. Beispiel:
  das aufgeklappte graue Gehäuse mit Tastatur aus dem Spike.
- **Anzeige**: der Bildschirm des Communicators, auf dem Oberflächenraster und für jedes Gehäuse
  gleich groß, damit jede Seite in jedes Gehäuse passt. Beispiel: das LCD des Organizers.
- **Seite**: was auf der Anzeige steht, ein Menü oder eine Liste mit Kopfzeile. Beispiel: die
  Seite SCHWIERIGKEIT mit Leicht, Mittel, Schwer und Zurück.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Hauptmenü auf dem Communicator (Priority: P1)

Der Spieler startet das Spiel. Auf dem Titelbild gleitet der Communicator von unten herein, und
auf seiner Anzeige steht das Hauptmenü. Er bedient es wie bisher mit Maus und Tastatur, und neben
der gewählten Zeile steht ihr Hinweis.

**Why this priority**: Das ist der Kern des Umbaus und der erste Eindruck des Spiels. Ohne ihn
gibt es nichts, woran die anderen Seiten hängen.

**Independent Test**: Spiel starten: Der Communicator gleitet herein, das Hauptmenü steht auf der
Anzeige, „Neues Spiel“ oder „Weiterspielen“ ist vorgewählt. Mit Pfeiltasten und Maus wählen, den
Hinweis prüfen, „Beenden“ auslösen.

**Acceptance Scenarios**:

1. **Given** die App startet, **When** der Titelbildschirm erscheint, **Then** gleitet der
   Communicator von unten herein, ohne zu federn, und auf seiner Anzeige steht das Hauptmenü mit
   denselben Einträgen, Hinweisen und derselben Vorwahl wie in Feature 004.
2. **Given** der Communicator gleitet gerade herein, **When** der Spieler Enter drückt, **Then**
   löst der vorgewählte Eintrag aus, genau wie ohne Fahrt.
3. **Given** das Hauptmenü steht auf der Anzeige, **When** der Spieler mit der Maus über eine
   Zeile fährt oder Pfeil runter drückt, **Then** ist diese Zeile gewählt, und ihr Hinweis steht
   daneben, ohne die Anzeige oder das Logo zu verdecken.
4. **Given** der Titelbildschirm ist zu sehen, **When** der Spieler hinsieht, **Then** sind Logo,
   Untertitel und Versionszeile vollständig zu sehen, und auf dem Titel liegt kein Endlospapier.

---

### User Story 2 - Alle Wege des Titels über den Communicator (Priority: P1)

Der Spieler geht die Wege aus Feature 004: ein neues Spiel mit Grad beginnen, einen Spielstand
fortsetzen, einen löschen. Jeder Schritt erscheint als Seite auf der Anzeige des Communicators.
Wechselt die Seite, bleibt der Communicator stehen; nur der Inhalt der Anzeige wechselt.

**Why this priority**: Der Titel muss als Ganzes funktionieren. Ein Hauptmenü auf dem Gerät, das
für jeden weiteren Schritt zum Papier wechselt, hat der Spike als ungewollt erkannt.

**Independent Test**: „Neues Spiel“ wählen: Die Seite SCHWIERIGKEIT erscheint auf derselben
Anzeige, der Communicator bewegt sich nicht. Esc führt zurück ins Hauptmenü. Danach „Spiel
laden“, „Löschen …“, einen Spielstand und „Abbrechen“ wählen; jede Seite steht auf der Anzeige.

**Acceptance Scenarios**:

1. **Given** das Hauptmenü steht auf der Anzeige, **When** der Spieler „Neues Spiel“ auslöst,
   **Then** ersetzt die Seite SCHWIERIGKEIT das Hauptmenü ohne Übergang, und der Communicator
   bleibt stehen.
2. **Given** eine Seite steht auf der Anzeige, **When** der Spieler Esc drückt oder „Zurück“
   auslöst, **Then** führt das eine Ebene zurück wie in Feature 004, und die Auswahl steht auf dem
   Eintrag, der die Seite geöffnet hat.
3. **Given** die Seite SPIELSTÄNDE mit mehr Spielständen, als sichtbar sind, **When** der Spieler
   mit Pfeiltasten oder Mausrad scrollt, **Then** scrollt die Liste wie in Feature 004 in ganzen
   Zeilen, und „Löschen …“ und „Zurück“ bleiben zu sehen.
4. **Given** die Gradwahl, **When** der Spieler „Mittel“ auslöst, **Then** beginnt ein Spiel wie
   in Feature 004, der Communicator gleitet nach unten hinaus, und danach erscheint der
   Spielbildschirm.
5. **Given** das Löschen eines Spielstands scheitert, **When** die Meldung erscheint, **Then**
   steht sie an der Stelle des Hinweises neben der Zeile, wie in Feature 004.
6. **Given** irgendeine Seite des Titels, **When** der Spieler hinsieht, **Then** steht sie auf
   der Anzeige des Communicators; Endlospapier kommt im Titel nicht mehr vor.

---

### User Story 3 - Ein Steuerelement für spätere Bildschirme (Priority: P2)

Ein späteres Feature, etwa der Spielbildschirm, zeigt den Communicator mit eigenen Seiten. Dafür
muss es den Titel nicht anfassen: Es gibt die Seiten vor, der Communicator zeigt sie, fährt
herein und hinaus und bedient sie wie im Titel.

**Why this priority**: Klaus will den Communicator als allgemeines Steuerelement behalten. Das
bringt dem Spieler heute noch nichts Sichtbares, entscheidet aber, ob spätere Features ihn
wiederverwenden können oder neu bauen müssen.

**Independent Test**: Ein automatischer Test zeigt den Communicator außerhalb des Titels mit
einer Probeseite aus drei Einträgen, lässt ihn herein- und hinausfahren, wählt per Tastatur
einen Eintrag und prüft, dass der Eintrag gemeldet wird. Am Titel ändert sich dafür nichts.

**Acceptance Scenarios**:

1. **Given** ein Bildschirm außer dem Titel, **When** er den Communicator mit einer eigenen Seite
   zeigt, **Then** sieht der Communicator aus und verhält sich wie im Titel.
2. **Given** der Communicator steht im Bild, **When** der Bildschirm ihn verschwinden lässt,
   **Then** gleitet er nach unten hinaus, so wie er hereingekommen ist.
3. **Given** der Communicator gleitet gerade herein, **When** der Bildschirm ihn verschwinden
   lässt, **Then** kehrt er aus seiner aktuellen Lage um, ohne zu springen.

---

### Edge Cases

- **Langes erstes Bild**: Das erste Bild nach dem Start dauert wegen Laden länger. Der
  Communicator springt dadurch nicht gleich halb herein, sondern gleitet sichtbar (Falle aus dem
  Spike).
- **Eingaben während der Fahrt**: Tastatur wirkt sofort. Die Maus wählt die Zeile, die gerade
  unter ihr liegt; der Hinweis fährt mit seiner Zeile mit.
- **Eingaben während der Fahrt hinaus**: Drückt der Spieler nach „Weiterspielen“ noch einmal
  Enter oder Esc, während der Communicator hinausfährt, passiert nichts; es beginnt kein zweites
  Spiel (FR-013a). Schließt er in dieser Zeit das Fenster, läuft das Spiel schon und wird beim
  Schließen gespeichert wie in Feature 004.
- **Mehrmals Esc schnell hintereinander**: Jede Ebene wird einzeln zurückgegangen; im Hauptmenü
  tut Esc nichts, wie in Feature 004.
- **Rückkehr aus dem Spiel**: Nach „Zum Hauptmenü“ erscheint der Titel neu, und der Communicator
  gleitet wieder herein, mit „Weiterspielen“ vorgewählt.
- **Vollbild umschalten während der Fahrt**: Die Fahrt endet in derselben Lage wie ohne Umschalten,
  ohne halbe Pixel.
- **Letzter Spielstand gelöscht**: Die Anzeige zeigt das Hauptmenü auf „Neues Spiel“, wie in
  Feature 004; der Communicator bleibt dabei stehen.
- **Lange Texte**: „Spiel 9999“, die längste Kopfzeile WELCHES LÖSCHEN? und der längste Eintrag
  passen auf die Anzeige; Namen werden nur nach den Regeln des Bausteins Liste gekürzt.
- **Fehler auf dem Titel** (Anlegen oder Löschen scheitert): Die Meldung steht wie in Feature 004
  an der Stelle des Hinweises; der Communicator bewegt sich nicht.
- **Kleinstes Fenster** (640 × 360): Communicator, Hinweis, Logo und Versionszeile passen ohne
  Überschneidung, die die Lesbarkeit stört.

## Requirements *(mandatory)*

### Functional Requirements

**Der Communicator als Steuerelement**

- **FR-001**: Der Communicator muss aus einem Gehäuse und einer Anzeige bestehen. Das Gehäuse ist
  ein gemaltes Bild auf dem Bildraster; die Anzeige liegt auf dem Oberflächenraster und ist für
  jedes Gehäuse gleich groß, damit jede Seite in jedes spätere Gehäuse passt.
- **FR-001a**: Der Grund der Anzeige muss eine eigene, neue Farbrolle `lcd` haben, ein
  graugrünes LCD-Grau, als 16. Farbe der Oberfläche im Style-Guide. Text steht darauf in `tusche`;
  Wert, Textpaare und Kontrast legt der Style-Guide fest (FR-008). `lcd` gibt es nur in der
  Oberfläche, nie in einem Bild; die eingefrorene Hauptpalette bleibt, wie sie ist (Klaus,
  2026-10-27, im Plan, research.md R1).
- **FR-002**: Der Communicator muss erscheinen, indem er von unten ins Bild gleitet, und
  verschwinden, indem er nach unten hinausgleitet; überall gleich, in ganzen Oberflächenpixeln,
  ohne zu federn. Dauer und Verlauf regelt der Style-Guide (heute: Übergänge 150–250 ms, nichts
  federt).
- **FR-003**: Der Communicator muss bedienbar sein, sobald er zu gleiten beginnt. Eine Eingabe mit
  der Tastatur während der Fahrt wirkt wie im Stand.
- **FR-004**: Auf der Anzeige muss immer genau eine Seite stehen, ein Menü oder eine Liste mit
  Kopfzeile. Bedient wird sie wie die Blätter aus Feature 001 und 004: eine gemeinsame Auswahl
  für Maus und Tastatur, Pfeiltasten und Tab, Enter, Leertaste und Linksklick lösen aus,
  Rechtsklick wählt nur, nicht verfügbare Einträge sind gedämpft und wählbar, Esc führt eine Ebene
  zurück.
- **FR-004a**: Die gewählte Zeile muss auf der Anzeige invertiert erscheinen: ein dunkler Balken,
  Schrift und Pfeil darin in der Farbe der Anzeige (`lcd`). Auf der Anzeige ersetzt das den
  Balken in `signalgelb`; auf Papier und überall sonst bleibt `signalgelb` die Auswahl. Eine
  gewählte, nicht verfügbare Zeile bleibt als gedämpft erkennbar; wie, regelt der Style-Guide mit
  ausreichendem Kontrast (FR-008).
- **FR-005**: Wechselt die Seite, muss die neue die vorige ohne Übergang ersetzen; der
  Communicator bleibt dabei stehen.
- **FR-006**: Neben der gewählten Zeile muss ihr Hinweis stehen, an derselben Stelle eine
  Meldung, wie in Feature 004. Er darf weder die Anzeige noch das Logo verdecken und fährt mit,
  wenn der Communicator sich bewegt.
- **FR-007**: Der Communicator muss ein eigenständiger Baustein sein: Der Bildschirm, der ihn
  zeigt, gibt die Seiten vor und erfährt, welcher Eintrag ausgelöst wurde. Ein späterer
  Bildschirm muss ihn mit eigenen Seiten zeigen können, ohne dass sich der Titel ändert.
- **FR-008**: Vor dem Bauen muss der Style-Guide den Baustein **Communicator** enthalten: Gehäuse,
  Größe und Lage der Anzeige, die Farbe `lcd` mit ihren Textpaaren (FR-001a), Auswahl auf der
  Anzeige, Lage von Hinweis und Meldung, Bewegung. Die Bausteine Menü, Liste und Hinweis und der Abschnitt
  Bewegung werden dazu passend angeglichen (Verfassung, Grundsatz IV).

**Titelbildschirm**

- **FR-010**: Erscheint der Titelbildschirm, muss der Communicator mit dem Hauptmenü auf der
  Anzeige hereingleiten, jedes Mal, auch nach der Rückkehr aus dem Spiel. Titelbild, Logo,
  Untertitel und Versionszeile bleiben; Logo, Untertitel und Versionszeile werden nicht verdeckt.
- **FR-010a**: Im Titel muss der Communicator rechts unten stehen, das Logo bleibt links oben. Die
  Anzeige ist ganz zu sehen; vom Gehäuse darf unten ein Teil, etwa die Tastatur, aus dem Bild
  ragen, als halte man das Gerät hoch. Der Hinweis steht als Zettel links neben dem Gerät auf Höhe
  der gewählten Zeile. Die genauen Maße legt der Style-Guide fest (FR-008).
- **FR-011**: Alle vier Blätter des Titels müssen als Seiten auf der Anzeige des Communicators
  stehen: Hauptmenü, Gradwahl (SCHWIERIGKEIT), Liste der Spielstände (SPIELSTÄNDE, im Löschmodus
  WELCHES LÖSCHEN?) und Rückfrage (LÖSCHEN?). Endlospapier kommt im Titel nicht mehr vor. Das
  ändert FR-023 von Feature 004, das für diese Blätter Endlospapier verlangt.
- **FR-012**: Im Titel muss der Communicator fest das Gehäuse des Organizers von 1991 haben,
  unabhängig von Spielständen und Datum. Der Titel steht außerhalb der Spielzeit.
- **FR-013**: Wege, Einträge, Texte, Hinweise, Vorwahl und Esc im Titel müssen bleiben, wie
  Feature 004 sie festlegt (`docs/spielbeschreibung/titel-und-hauptmenue.md`, „Wege“). Es ändert
  sich nur, worauf die Seiten stehen.
- **FR-013a**: Beginnt der Spieler ein neues Spiel oder setzt er eines fort, muss der
  Communicator erst nach unten hinausgleiten; danach erscheint der Spielbildschirm. Das Spiel wird
  vorher angelegt oder fortgesetzt wie in Feature 004: Scheitert das, fährt nichts hinaus, und die
  Meldung steht an ihrer Zeile. Während der Fahrt hinaus löst keine Eingabe etwas aus, auch Esc
  nicht. „Beenden“ schließt dagegen sofort, ohne Fahrt.
- **FR-014**: Jede Seite des Titels muss ganz auf die Anzeige passen, auch mit der längsten
  Kopfzeile, dem längsten Eintrag und „Spiel 9999“. Die Liste der Spielstände scrollt, wenn nicht
  alle Spielstände zu sehen sind, wie in Feature 004.
- **FR-015**: Der Titel muss ein neues Titelbild **T-02** bekommen, das T-01 ersetzt. Es zeigt
  dieselbe Welt wie T-01, lässt aber rechts unten, wo der Communicator steht, eine ruhige Fläche,
  so dass er nichts Wichtiges des Bilds verdeckt. Logo und Untertitel stehen weiter frei darauf.

**Grafik**

- **FR-020**: Gehäuse und Titelbild T-02 müssen nach dem Leonardo-Workflow des Style-Guides
  entstehen, auf die Hauptpalette gebracht und von Hand aufgeräumt sein, mit Prompt, Modell und
  Seed im Prompt-Log und als freigegeben vermerkt. Die Anzeige im Gehäuse hat das
  Seitenverhältnis der festen Anzeige aus FR-001. Kein echter Markenname und kein Logo auf dem
  Gehäuse. Die Prompts liefert Claude, die Bilder erzeugt Klaus.

### Key Entities *(include if feature involves data)*

- **Communicator**: das Steuerelement; ein Gehäuse, eine Anzeige, eine Lage (im Bild, draußen,
  unterwegs) und die Seite, die gerade darauf steht.
- **Gehäuse**: ein Bild mit der Stelle, an der die Anzeige sitzt. Heute eins; später je Gerät eins.
- **Seite**: Kopfzeile, Einträge mit Hinweis und Verfügbarkeit, ein Eintrag für „eine Ebene
  zurück“. Beispiel: SCHWIERIGKEIT mit Leicht, Mittel, Schwer, Zurück.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Der Spieler braucht für jeden Weg des Titels so viele Eingaben wie in Feature 004:
  mit „Weiterspielen“ 1 Eingabe bis zum Spielbildschirm, auch während der Communicator noch
  hereingleitet; ein neues Spiel mit Vorgabe Mittel höchstens 3.
- **SC-002**: Der Communicator steht spätestens 250 ms nach dem ersten Bild des Titels in seiner
  Endlage; der Titel ist wie in Feature 001 nach höchstens 3 s bedienbar. Beim Spielstart ist er
  spätestens 250 ms nach der auslösenden Eingabe hinausgefahren, und der Spielbildschirm folgt
  ohne weitere Wartezeit.
- **SC-003**: In jedem Bild der Fahrt steht der Communicator auf ganzen Oberflächenpixeln, und er
  kommt nie über die Endlage hinaus; ein automatischer Test belegt das Bild für Bild.
- **SC-004**: Jede Seite des Titels passt auf die Anzeige, geprüft mit der längsten Kopfzeile,
  dem längsten Eintrag, „Spiel 9999“ und sechs sichtbaren Spielständen; alle Hinweise und
  Meldungen passen weiter in zwei Zeilen.
- **SC-005**: Ein automatischer Test zeigt den Communicator außerhalb des Titels mit einer
  Probeseite und bedient sie, ohne eine Datei des Titels zu benutzen.
- **SC-006**: Logo, Untertitel und Versionszeile überschneiden sich in keiner Lage des
  Communicators und in keinem Zustand des Titels mit Communicator, Hinweis oder Meldung.
- **SC-007**: Alle Tests aus Feature 001 und 004 zum Verhalten des Titels bleiben grün, angepasst
  nur, wo sie das Papier selbst prüfen; die Startprobe bleibt still, und die Phasenprüfung endet
  ohne offene Befunde.

## Assumptions

- Gespielt wird am Desktop mit Maus und Tastatur (Verfassung, Grundsatz I).
- Der Spike wird nicht gemergt. Was taugt, etwa das Gleiten in ganzen Pixeln mit gedeckeltem
  Zeitschritt oder der Schalter für den Untergrund des Menüs, übernimmt die Umsetzung gezielt.
- Der Name „Communicator“ meint das Steuerelement. Das Gerät von 1996 nach Art des Nokia 9000,
  das die Recherche ebenfalls „Communicator“ nennt, ist eines seiner möglichen Gehäuse.
- **Nicht Teil dieses Features**, sondern der Features, die den Communicator später nutzen:
  - der Communicator auf dem Spielbildschirm, mit Öffnen und Schließen per Taste oder Klick;
  - Reiter oder Funktionstasten für mehrere Seiten nebeneinander, die Seiten Termine, Adressen,
    Lager, Kasse, Nachrichten, Notizen und Ablage;
  - das Zusammenspiel mit der Bedienleiste;
  - ob die Spieluhr anhält, solange er offen ist;
  - der Wechsel des Gehäuses mit den Jahren, der Kauf als Ware, Pager und Handy;
  - Speichern und „Zum Hauptmenü“ als Seite Ablage.
- Die Einstellung „Bewegung reduzieren“ gibt es noch nicht. Kommt sie, erscheint der Communicator
  ohne Gleiten (Style-Guide, Bewegung).
- Der Spielbildschirm bleibt wie in Feature 004: der Knopf „Zum Hauptmenü“ auf `nacht`.
- „Beenden“ schließt sofort, ohne dass der Communicator hinausfährt, denn danach ist nichts mehr
  zu sehen (Claudes Festlegung zu FR-013a).
- Die Texte des Titels bleiben, wie sie sind; neue Texte entstehen in diesem Feature nicht.
- Gehäuse und T-02 werden auf die unveränderte Hauptpalette gerastert (FR-001a). T-01 bleibt
  im Repo als Original, das Cover C-01 bleibt unberührt.
- Jede Phase mit Sichtbarem oder Texten endet mit der Phasenprüfung durch Stil- und Text-Prüfer
  vor Klaus' Abnahme (`docs/ki_workflow/ki_pruefung.md`).
