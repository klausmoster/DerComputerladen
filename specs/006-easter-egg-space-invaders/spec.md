# Feature Specification: Easter Egg 01: Space Invaders

**Feature Branch**: `feature/006-easter-egg-space-invaders`

**System**: 10 Präsentation & UI; mit dem Ton auch 11 Infrastruktur

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "Feature 006 ‚Easter Egg 01: Space Invaders'. Auf dem
Titelbildschirm steht der Communicator (Gehäuse G-03 nach dem Olivetti D2000). Direkt unter
seinem Bildschirm, rechts, sitzen drei graue Knöpfe. Drückt der Spieler nacheinander den ersten,
zweiten und dritten, startet Space Invaders – nur ein einfaches Level."

## Clarifications

### Specify 2026-10-27

Fragen aus `/speckit-specify`, von Klaus einzeln als Auswahl beantwortet:

- Q: Wo läuft Space Invaders? → A: auf der Anzeige des Communicators, als eigene Seite, 320 × 160
  (Klaus, nach Empfehlung). Titelbild, Logo und Gerät bleiben stehen, wie ein Taschenspiel der
  80er. Verworfen: bildschirmfüllend, weil es eine eigene Szene mit Szenenwechsel braucht und das
  Gerät dafür hinausfahren müsste; die Anzeige mit Heranzoomen, weil die Bewegung neu im
  Style-Guide wäre und die Pixel nicht mehr aufs Raster passen.
- Q: Was passiert nach Sieg oder Niederlage? → A: Eine Meldung auf der Anzeige nennt das Ergebnis
  und die Punkte; eine Taste oder ein Klick führt zurück zur Seite, auf der der Spieler war (Klaus,
  nach Empfehlung). Verworfen: von selbst nach 3 Sekunden, weil man das Ergebnis verpassen kann;
  ein Menü mit „Nochmal“, weil es mehr Bedienung und Texte bringt.
- Q: Woraus entsteht die Grafik? → A: aus kleinen Pixelmustern, einfarbig in `tusche` auf `lcd`,
  wie das Menü auf der Anzeige; keine neue Farbe, keine Bilder aus Leonardo (Klaus, nach
  Empfehlung). Verworfen: Sprite-Bilder als PNG, weil sie Rasterfassung und Prompt-Log brauchen;
  Bilder aus Leonardo, weil es so winzige Figuren schlecht trifft und auf einer einfarbigen Anzeige
  wenig davon bleibt.

### Clarify 2026-10-27

Fragen aus `/speckit-clarify`, von Klaus einzeln als Auswahl beantwortet:

- Q: Mit welchen Tasten steuert der Spieler die Kanone? → A: Pfeil links und rechts fahren, die
  Leertaste schießt (Klaus, nach Empfehlung). Verworfen: zusätzlich A und D, weil es mehr zu
  testen gibt und dem Menü fremd ist; Strg als Schuss, weil es auf dem Mac ungewohnt ist.
- Q: Was bricht eine angefangene Folge ab? → A: nur ein falscher grauer Knopf; ist er Knopf 1, zählt
  er als neuer Anfang. Klicks ins Menü, Tasten, Seitenwechsel und Pausen stören nicht (Klaus, nach
  Empfehlung). Verworfen: zusätzlich eine Pause über 2 Sekunden; jede andere Eingabe, weil die
  Knöpfe dann alle Eingaben mithören müssten.
- Q: Reagieren die Knöpfe sichtbar, und welcher Mauszeiger steht über ihnen? → A: Solange die
  Maustaste auf einem Knopf unten ist, sitzt er eingedrückt, 1 Bildpixel tiefer und ohne
  Lichtkante; das gilt für jeden der drei, auch einen falschen. Der Zeiger bleibt der Pfeil, damit
  nichts das Geheimnis verrät (Klaus, nach Empfehlung). Verworfen: keine Reaktion, weil man nicht
  merkt, ob ein Klick getroffen hat; die Hand als Zeiger, weil sie jedem das Geheimnis zeigt.
- Q: Was gehört zum einfachen Level? → A: eine Welle Außerirdischer, drei Leben und Punkte, ohne
  Deckungen und ohne Ufo (Klaus, nach Empfehlung). Verworfen: Deckungen, mit oder ohne Ufo, weil sie
  pixelgenaue Treffer brauchen und eine oder zwei Phasen mehr kosten; ein Leben, weil es zu hart
  ist.

### Ton 2026-10-27

Ton ist für das Spiel geplant (`docs/game_design.md`, „Sound und Musik“); dieses Feature führt
ihn ein (Klaus, 2026-10-27). Die Fragen dazu hat Klaus einzeln als Auswahl beantwortet:

- Q: Woher kommen die Töne? → A: Ein Python-Skript im Repo erzeugt kurze Töne in Rechteckwelle, wie
  ein Taschengerät von 1991, und legt sie als Tondateien ins Projekt (Klaus, nach Empfehlung).
  Verworfen: Töne zur Laufzeit errechnen, weil sie schwerer zu testen und vorab anzuhören sind;
  eine freie Soundbibliothek, weil sie Downloads, Auswahl und eine Lizenzliste braucht.
- Q: Welche Töne gibt es? → A: im Spiel Schuss, Treffer, Kanone getroffen, der Marschtakt der
  Außerirdischen sowie je ein kurzes Motiv für Sieg und Niederlage; dazu ein Klick für jeden der
  drei grauen Knöpfe. Das Menü des Titels bleibt stumm (Klaus, nach Empfehlung). Verworfen: nur im
  Spiel, weil ein Druck ohne Klick tot wirkt; auch das Menü, weil es den abgenommenen Titel aus
  Feature 005 berührt.
- Q: Wie wird die Lautstärke geregelt, solange es keine Einstellungen gibt? → A: Das Spiel bekommt
  getrennte Tonkanäle für alles zusammen und für Effekte, Musik kommt später dazu; die Lautstärke
  ist fest und eher leise, einstellbar wird sie mit dem Menüeintrag „Einstellungen“ (Klaus, nach
  Empfehlung). Verworfen: eine Taste zum Stummschalten, weil sie nirgends erklärt ist; ohne
  getrennte Kanäle, weil „Einstellungen“ sonst jede Tonquelle anfassen müsste.

## Begriffe

- **Easter Egg:** ein verstecktes Extra, das nirgends angekündigt ist und das man nur durch
  Ausprobieren oder Hörensagen findet. Hier: Wer auf dem Titel die drei grauen Knöpfe des
  Communicators der Reihe nach drückt, spielt eine Runde Space Invaders.
- **Die drei grauen Knöpfe:** die drei Tasten ganz rechts in der Reihe der Funktionstasten, direkt
  unter der Anzeige des Gehäuses G-03. Heute sind sie nur ein Teil des Bilds. „Der erste“ ist der
  linke, „der dritte“ der rechte.
- **Die Folge:** erster, zweiter, dritter Knopf, in dieser Reihenfolge gedrückt.
- **Space Invaders:** das Arcade-Spiel von 1978: Unten fährt die Kanone des Spielers nach links und
  rechts und schießt nach oben; oben rückt ein Block von Außerirdischen seitwärts hin und her und
  bei jedem Randwechsel eine Stufe tiefer, und sie werfen Bomben nach unten.
- **Level:** eine Welle, also ein Block Außerirdischer, vom ersten Schuss bis alle getroffen sind
  oder der Spieler verloren hat.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Das Geheimnis finden (Priority: P1)

Der Spieler steht im Hauptmenü des Titels. Er klickt auf dem Gehäuse des Communicators den ersten,
dann den zweiten, dann den dritten grauen Knopf. Space Invaders beginnt. Nichts auf dem Titel
verrät vorher, dass die Knöpfe etwas tun.

**Why this priority**: Ohne den Auslöser gibt es kein Easter Egg. Er ist zugleich der Teil, der
den heutigen Titel berührt, und muss deshalb zuerst stehen und zeigen, dass das Menü unverändert
bleibt.

**Independent Test**: Auf dem Titel die drei Knöpfe der Reihe nach klicken: Das Spiel startet. Eine
andere Reihenfolge startet nichts, und Menü, Gradwahl, Liste und Rückfrage bedienen sich wie vorher.

**Acceptance Scenarios**:

1. **Given** der Titel, der Communicator in seiner Endlage, **When** der Spieler Knopf 1, Knopf 2
   und Knopf 3 klickt, **Then** startet Space Invaders.
2. **Given** der Titel, **When** der Spieler Knopf 2, Knopf 1, Knopf 3 klickt, **Then** startet
   nichts, und das Menü bleibt, wie es war.
5. **Given** der Titel, **When** der Spieler Knopf 1, Knopf 1, Knopf 2, Knopf 3 klickt, **Then**
   startet Space Invaders, weil der zweite Druck auf Knopf 1 als neuer Anfang zählt.
6. **Given** der Spieler hat Knopf 1 geklickt, **When** er eine Zeile des Menüs wählt oder eine
   andere Seite öffnet und dann Knopf 2 und Knopf 3 klickt, **Then** startet Space Invaders.
7. **Given** der Titel, **When** der Spieler die Maustaste auf einem der drei Knöpfe drückt,
   **Then** sitzt dieser eingedrückt, bis die Taste wieder oben ist; der Zeiger bleibt der Pfeil.
3. **Given** der Titel mit einer beliebigen Seite auf der Anzeige (Hauptmenü, Gradwahl, Liste,
   Rückfrage), **When** der Spieler die Folge klickt, **Then** startet Space Invaders auch dort.
4. **Given** der Titel, **When** der Spieler irgendwo anders auf das Gehäuse klickt, **Then**
   passiert wie heute nichts.

---

### User Story 2 - Eine Runde spielen (Priority: P1)

Space Invaders läuft. Der Spieler steuert mit der Tastatur die Kanone nach links und rechts und
schießt. Der Block der Außerirdischen rückt hin und her und tiefer und wirft Bomben. Trifft der
Spieler alle, hat er gewonnen. Wird seine Kanone getroffen oder erreichen die Außerirdischen den
Boden, hat er verloren.

**Why this priority**: Das ist das Easter Egg selbst. Ohne ein spielbares Level ist der Auslöser
wertlos; gleiche Priorität wie Story 1.

**Independent Test**: Das Spiel lässt sich auch ohne Auslöser direkt starten (Probeszene) und von
Anfang bis Sieg oder Niederlage durchspielen.

**Acceptance Scenarios**:

1. **Given** das Spiel hat begonnen, **When** der Spieler Pfeil links oder Pfeil rechts hält,
   **Then** fährt die Kanone in diese Richtung und hält am Rand des Spielfelds.
2. **Given** das Spiel läuft, **When** der Spieler die Leertaste drückt, **Then** fliegt ein Schuss senkrecht
   nach oben; ein zweiter geht erst, wenn der erste getroffen hat oder aus dem Feld ist.
3. **Given** ein Schuss trifft einen Außerirdischen, **Then** verschwindet dieser, und der Spieler
   bekommt Punkte.
4. **Given** der Block erreicht den seitlichen Rand, **Then** rückt er eine Stufe tiefer und zieht
   in die Gegenrichtung.
5. **Given** der letzte Außerirdische ist getroffen, **Then** ist das Level gewonnen.
6. **Given** eine Bombe trifft die Kanone und kein Leben ist mehr übrig, oder ein Außerirdischer
   erreicht die Höhe der Kanone, **Then** ist das Level verloren.

---

### User Story 3 - Zurück zum Titel (Priority: P2)

Nach Sieg oder Niederlage, oder wenn der Spieler mittendrin aufhören will, kehrt er zum Titel
zurück und kann dort normal weitermachen, auch ein Spiel beginnen oder die Folge erneut drücken.

**Why this priority**: Ohne einen sauberen Rückweg wäre der Titel nach dem Easter Egg kaputt. Er
ist aber erst wichtig, wenn Story 1 und 2 stehen.

**Independent Test**: Space Invaders gewinnen, verlieren und mit Esc abbrechen; jedes Mal steht
danach der Titel bedienbar da wie vorher.

**Acceptance Scenarios**:

1. **Given** das Level ist gewonnen oder verloren, **When** die Meldung mit Ergebnis und Punkten steht und
   der Spieler eine Taste drückt oder klickt, **Then** zeigt die Anzeige wieder die Seite, auf der
   er war.
2. **Given** das Spiel läuft, **When** der Spieler Esc drückt, **Then** endet das Spiel sofort ohne
   Rückfrage, und der Titel steht wieder da.
3. **Given** der Spieler ist zurück auf dem Titel, **When** er das Menü bedient, **Then** verhält
   es sich wie vor dem Easter Egg, mit derselben Seite und Auswahl wie beim Start der Folge.

---

### Edge Cases

- Der Spieler klickt die Folge, während der Communicator noch hereinfährt oder schon hinausfährt
  (ein Spiel beginnt): Die Knöpfe nehmen nur an, wenn auch die Seiten Eingaben annehmen. Fährt das
  Gerät hinaus, startet nichts.
- Der Spieler klickt Knopf 1, Knopf 2, Knopf 2, Knopf 3: Der zweite Druck auf Knopf 2 ist falsch und
  setzt zurück; Knopf 3 startet nichts.
- Der Spieler drückt die Maustaste auf einem Knopf, zieht die Maus weg und lässt woanders los: Der
  Knopf springt zurück, und der Druck zählt nicht.
- Ein Klick der rechten oder mittleren Maustaste auf einen Knopf zählt nicht und drückt ihn nicht
  ein.
- Der Spieler klickt die Folge mehrmals schnell hintereinander: Es startet genau ein Spiel.
- Während Space Invaders läuft, drückt der Spieler Enter, Leertaste oder Pfeile: Nur das Spiel
  reagiert; das Menü dahinter löst nichts aus und wechselt keine Auswahl.
- Das Fenster verliert den Fokus, während das Spiel läuft: Das Spiel und sein Ton halten an, bis
  das Fenster wieder den Fokus hat.
- Der Spieler drückt Esc, während ein Ton klingt: Der Ton des Spiels verstummt sofort.
- Auf dem Rechner ist kein Tonausgang da oder er ist stumm: Das Spiel läuft ohne Ton weiter, ohne
  Meldung.
- Der Spieler schließt das Fenster während des Spiels: Die App beendet sich wie vom Titel aus; es
  gibt nichts zu speichern.
- Es gibt keinen Spielstand oder einen beschädigten: Das Easter Egg geht trotzdem, es braucht
  keinen.

## Requirements *(mandatory)*

### Functional Requirements

**Auslöser**

- **FR-001**: Die drei grauen Knöpfe des Gehäuses G-03 MÜSSEN auf dem Titel mit der linken Maustaste
  drückbar sein. Ihre Klickfläche MUSS mit dem sichtbaren Knopf im Bild übereinstimmen. Ein Druck
  zählt, wenn die Maustaste über demselben Knopf losgelassen wird, auf dem sie gedrückt wurde.
- **FR-001a**: Solange die linke Maustaste auf einem Knopf unten ist, MUSS er eingedrückt
  erscheinen: 1 Bildpixel tiefer, ohne Lichtkante. Das gilt für jeden der drei Knöpfe, auch wenn
  der Druck die Folge nicht weiterbringt.
- **FR-001b**: Über den Knöpfen MUSS der Mauszeiger der Pfeil bleiben. Die Ausnahme von der Regel
  „Hand nur, wo ein Klick etwas tut“ kommt vor dem Bau in den Style-Guide.
- **FR-002**: Die Folge erster, zweiter, dritter Knopf MUSS Space Invaders starten.
- **FR-003**: Jede andere Reihenfolge DARF NICHT starten. Nur ein Druck auf den falschen grauen
  Knopf bricht eine angefangene Folge ab; ist der falsche Knopf 1, beginnt damit eine neue Folge.
  Klicks und Tasten im Menü, Seitenwechsel und Pausen lassen die Folge, wie sie ist. Startet das
  Spiel oder verlässt der Spieler den Titel, beginnt die Folge von vorn.
- **FR-004**: Die Knöpfe MÜSSEN nur Eingaben annehmen, wenn der Communicator Eingaben annimmt; sonst
  zählen Klicks auf sie nicht.
- **FR-005**: Nichts auf dem Titel DARF das Easter Egg ankündigen: kein Hinweis, kein Menüeintrag,
  keine Beschriftung.
- **FR-006**: Bedienung, Seiten, Hinweise und Fahrt des Titels MÜSSEN unverändert bleiben, wenn der
  Spieler die Knöpfe nicht benutzt.
- **FR-007**: Das Easter Egg DARF weder einen Spielstand anlegen noch einen ändern, und es DARF kein
  Spiel des Computerladens beginnen oder fortsetzen.

**Das Spiel**

- **FR-010**: Space Invaders MUSS als eigene Seite auf der Anzeige des Communicators laufen, so groß
  wie die Anzeige. Titelbild, Logo, Versionszeile und Gerät bleiben stehen; das Gerät bewegt sich
  beim Start und beim Ende nicht. Der Hinweis neben dem Gerät ist verborgen, solange das Spiel auf
  der Anzeige steht.
- **FR-011**: Das Spiel MUSS genau ein Level haben, ohne Deckungen und ohne Ufo: ein Block Außerirdischer, der seitwärts hin und
  her zieht, am Rand eine Stufe tiefer rückt und schneller wird, je weniger übrig sind.
- **FR-012**: Pfeil links und Pfeil rechts MÜSSEN die Kanone fahren lassen, solange sie gehalten
  werden; die Leertaste MUSS schießen. Höchstens ein eigener Schuss ist zugleich im Feld. Andere
  Tasten außer Esc tun im Spiel nichts.
- **FR-012a**: Der Spieler MUSS mit drei Leben beginnen. Trifft eine Bombe die Kanone, verliert er
  eines, und die Kanone erscheint nach einer kurzen Pause wieder in der Mitte.
- **FR-013**: Die Außerirdischen MÜSSEN Bomben nach unten werfen; immer nur einer aus der untersten
  Reihe einer Spalte kann werfen.
- **FR-014**: Das Spiel MUSS Punkte und verbleibende Leben anzeigen. Punkte werden nicht dauerhaft
  gespeichert.
- **FR-015**: Das Level MUSS als gewonnen enden, wenn kein Außerirdischer übrig ist, und als
  verloren, wenn die Kanone ohne Leben getroffen wird oder ein Außerirdischer ihre Höhe erreicht.
- **FR-016**: Das Spiel MUSS anhalten, solange das Fenster nicht den Fokus hat.
- **FR-017**: Während das Spiel läuft, DÜRFEN Tastatur und Maus nichts im Menü des Titels auslösen
  oder wählen.

**Ende und Rückweg**

- **FR-020**: Nach Sieg oder Niederlage MUSS die Anzeige eine Meldung mit dem Ergebnis und den
  Punkten zeigen. Eine Taste oder ein Linksklick auf die Anzeige MUSS danach zur vorigen Seite
  zurückführen; ein Druck, der noch aus dem Spiel stammt (etwa ein gehaltener Schuss), DARF die
  Meldung nicht gleich überspringen.
- **FR-021**: Esc MUSS das laufende Spiel jederzeit sofort beenden und zum Titel zurückführen.
- **FR-022**: Zurück auf dem Titel MÜSSEN Seite und Auswahl dieselben sein wie beim Start der Folge.

**Aussehen**

- **FR-030**: Außerirdische, Kanone, Schüsse und Bomben MÜSSEN kleine Pixelmuster sein, einfarbig
  in `tusche` auf dem Grund `lcd` der Anzeige, auf dem Bildraster; jeder Außerirdische hat zwei
  Bewegungsbilder, die beim Weiterrücken wechseln. Das Spiel bringt keine neue Farbe und kein Bild
  aus Leonardo. Die Darstellung „Spiel auf der Anzeige“ kommt vor dem Bau in den Style-Guide.
**Ton**

- **FR-040**: Das Spiel MUSS diese Töne spielen: einen Schuss der Kanone, einen Treffer an einem
  Außerirdischen, einen Treffer an der Kanone, den Marschtakt der Außerirdischen (vier tiefe Töne im
  Wechsel, einer je Schritt des Blocks, also schneller, je weniger übrig sind) und je ein kurzes
  Motiv für Sieg und Niederlage.
- **FR-041**: Jeder Druck auf einen der drei grauen Knöpfe MUSS einen kurzen, trockenen Klick
  spielen, auch ein falscher. Sonst bleibt der Titel stumm.
- **FR-042**: Alle Töne MÜSSEN im Klang eines Taschengeräts von 1991 sein, Rechteckwelle, und von
  einem Werkzeug im Repo erzeugt werden, sodass sie sich jederzeit gleich neu erzeugen lassen. Es
  gibt keine Töne aus fremden Quellen.
- **FR-043**: Jeder Ton MUSS über einen Kanal für Effekte laufen, der in einen Kanal für alles
  zusammen mündet. Die Lautstärke ist fest und eher leise; ein späteres Feature „Einstellungen“
  regelt sie an den Kanälen, ohne die Tonquellen zu ändern.
- **FR-044**: Hält das Spiel an oder endet es, MÜSSEN seine Töne mit anhalten oder verstummen.

**Texte**

- **FR-031**: Alle Texte des Spiels (etwa Punkte, Sieg, Niederlage) MÜSSEN deutsch sein und den
  Spieler duzen.

### Key Entities

- **Folge der Knöpfe:** wie weit der Spieler in der Folge ist (0 bis 3); setzt sich nach einem
  falschen Druck zurück. Lebt nur, solange der Titel steht.
- **Partie:** eine Runde Space Invaders: Lage der Kanone, verbleibende Leben, Punkte, die
  übrigen Außerirdischen mit Lage und Tempo des Blocks, die Schüsse und Bomben im Feld, und ob
  sie läuft, angehalten, gewonnen oder verloren ist. Sie wird nicht gespeichert.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Nach dem dritten Knopf der Folge ist das Spiel in höchstens 0,5 s spielbereit.
- **SC-002**: Ein durchschnittlicher Spieler kann das Level in 1 bis 3 Minuten gewinnen; verlieren
  ist möglich, wenn er nicht ausweicht.
- **SC-003**: Das Spiel läuft flüssig, ohne sichtbares Ruckeln, bei Klaus' Fenstergröße.
- **SC-004**: Alle bestehenden Tests des Titels laufen nach dem Feature unverändert grün.
- **SC-005**: Von 20 zufälligen Folgen aus drei Klicks, die nicht 1-2-3 sind, startet keine das
  Spiel.
- **SC-006**: Nach Sieg, Niederlage und Esc ist der Titel jedes Mal in höchstens 1 s wieder
  bedienbar.
- **SC-007**: Jeder Ton setzt hörbar ohne Verzögerung zum Ereignis ein, höchstens 50 ms nach
  Schuss, Treffer oder Klick.

## Assumptions

- Nur der Titel bekommt das Easter Egg. Andere Gehäuse und spätere Bildschirme mit Communicator
  bleiben, wie sie sind.
- Keine Bestenliste. Die genaue Größe des Blocks und die Tempi folgen im Plan aus dem Spielfeld
  320 × 160.
- Ob Musik im MIDI-Stil oder nach AdLib und Sound Blaster klingt, lässt das GDD offen; dieses
  Feature bringt nur Effekte und legt dafür nichts fest.
- Wie die Töne klingen (Tonhöhe, Länge, Lautstärke), legt der Plan fest; die Regeln dafür kommen
  vor dem Bau als Abschnitt „Ton“ in den Style-Guide, wie alles, was zum Look gehört.
- Wie bei den Seiten nach dem Ende kehrt auch Esc zu der Seite zurück, auf der der Spieler war,
  mit ihrer Auswahl; der Hinweis der gewählten Zeile erscheint wieder.
- Die Lage der drei Knöpfe ergibt sich aus dem Gehäusebild G-03 (`docs/art/leonardo/prompt-log.md`,
  `specs/005-communicator/`). Die eingedrückte Fassung entsteht aus dem Gehäusebild selbst, ohne
  Leonardo; das Gehäusebild bleibt unverändert.
- Die Mechanik folgt dem Original von 1978 nur so weit, wie es ein einfaches Level braucht; es ist
  eine Hommage, keine Nachbildung, und nutzt keine Grafik, keinen Ton und keinen Namen aus dem
  Original außer der Spielidee. Der Name „Space Invaders“ erscheint nicht im Spiel (Entscheidung von Claude, 2026-10-27: Der
  Name ist eine Marke; Klaus kann sie im Review kippen).
