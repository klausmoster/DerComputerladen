# Feature Specification: Start bis zum Hauptmenü

**Feature Branch**: `feature/001-hauptmenue`

**System**: 10 Präsentation & UI; zieht den macOS-Teil von 11-03 Build & Export vor

**Created**: 2026-10-19

**Status**: Draft

**Input**: User description: "als erstes feature ggf. mainscreen oder so" – das Hauptmenü nach dem
Titelscreen-Entwurf und dem Style-Guide. Ergänzt: "dass wir die ganze App unter macOS auch starten
können […] startet und lädt die App bis zum Startscreen".

## Clarifications

### Session 2026-10-19

- Q: Gehört die Rasterfassung von Titelbild und Logo zu diesem Feature, oder kommt vorher 10-03
  Pixel-Art-Pipeline? → A: Nicht als Auswahl beantwortet; stattdessen ist der Umfang erweitert: Zum
  ersten Feature gehört auch, dass die App unter macOS als eigenständige App startet und bis zum
  Titelbildschirm lädt. Für die Rasterfrage gilt vorerst die Annahme, dass sie in dieses Feature
  gehört.
- Q: Soll die Mac-App vorerst nur auf dem eigenen Mac laufen oder auch auf anderen Macs? → A: Nur
  auf dem eigenen Mac; Signieren und Beglaubigen kommen mit 11-03.
- Q: Startet die App im Vollbild oder im Fenster, und wie schaltet man um, solange es keine
  Einstellungen gibt? → A: Im Vollbild; Ctrl+Cmd+F und der grüne Fensterknopf schalten ins
  Fenster und zurück.
- Q: Wohin führt „Neues Spiel“, solange es noch keinen Spielbildschirm gibt? → A: Nirgendwohin:
  „Neues Spiel“ ist wie „Spiel laden“ vorerst nicht verfügbar; der Titelbildschirm ist die
  Endstation dieses Features.
- Q: Woher kommt das App-Symbol für Dock und Finder? → A: Aus dem Logo: der beige Monitor vom
  linken Ende des Ladenschilds, aufs Pixelraster gebracht, auf einem abgerundeten Quadrat.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - App unter macOS bis zum Titelbildschirm starten (Priority: P1)

Klaus baut das Spiel als Mac-App und startet sie wie jede andere App per Doppelklick, ohne die
Entwicklungsumgebung. Die App lädt und zeigt dann im Vollbild den Titelbildschirm: den Computerladen an der
Straßenecke am Abend, oben links das Ladenschild-Logo mit Untertitel, rechts das Hauptmenü auf
Endlospapier und unten links die Versionszeile.

**Why this priority**: Das ist der Kern des ersten Features. Ab hier gibt es ein Spiel, das man
starten kann, und jedes weitere Feature hängt sich an diesen Einstieg. Der Titelbildschirm setzt
außerdem den Ton: Retro im Bild, modern in der Hand.

**Independent Test**: Die App bauen und im Finder doppelklicken: Der Titelbildschirm erscheint. Das
funktioniert auch dann, wenn die Menüpunkte noch nichts tun.

**Acceptance Scenarios**:

1. **Given** die App ist gebaut und die Entwicklungsumgebung geschlossen, **When** Klaus sie im Finder
   doppelklickt, **Then** startet sie und zeigt nach dem Laden den Titelbildschirm mit Titelbild,
   Logo, Untertitel, Hauptmenü und Versionszeile.
2. **Given** die App lädt noch, **When** der Titelbildschirm noch nicht bereit ist, **Then** ist
   nur ein ruhiger dunkler Grund aus dem Style-Guide zu sehen, kein fremdes Logo.
3. **Given** die App läuft, **When** Klaus auf Dock und App-Umschalter schaut, **Then** steht dort
   „Der Computerladen“ mit dem Monitor aus dem Logo als Symbol.
4. **Given** die App ist gestartet, **When** der Titelbildschirm erscheint, **Then** läuft sie im
   Vollbild, und Ctrl+Cmd+F wechselt ins Fenster und wieder zurück.

---

### User Story 2 - Spiel beenden (Priority: P2)

Über „Beenden“ verlässt der Spieler das Spiel und ist zurück auf dem Desktop. Unter macOS beenden
auch Cmd+Q und das Schließen des Fensters das Spiel.

**Why this priority**: „Beenden“ ist in diesem Feature der einzige verfügbare Menüpunkt. Ein
Desktop-Spiel muss sich über das eigene Menü und auf die übliche Art des Betriebssystems schließen
lassen.

**Independent Test**: „Beenden“ wählen, ein zweites Mal Cmd+Q drücken, ein drittes Mal das Fenster
schließen: Jedes Mal endet die App vollständig.

**Acceptance Scenarios**:

1. **Given** der Titelbildschirm ist zu sehen, **When** der Spieler „Beenden“ wählt, **Then**
   schließt sich das Spiel ohne Rückfrage.
2. **Given** das Spiel läuft unter macOS, **When** der Spieler Cmd+Q drückt oder das Fenster
   schließt, **Then** endet die App genauso wie über „Beenden“.

---

### User Story 3 - Menü mit Maus und Tastatur bedienen (Priority: P2)

Das Menü verhält sich, wie es der Style-Guide für Menüs festlegt: Überfahren mit der Maus und
Auswahl mit den Pfeiltasten heben die Zeile hervor, Klick oder Enter führt sie aus, und ein Hinweis
(Tooltip) sagt, was der Eintrag tut oder warum er noch nicht verfügbar ist.

**Why this priority**: Das ist die erste Bedienung im Spiel. Hier zeigt sich das Versprechen, dass
sich der Retro-Look wie ein heutiges Spiel bedienen lässt.

**Independent Test**: Das Menü einmal nur mit der Tastatur und einmal nur mit der Maus bedienen.

**Acceptance Scenarios**:

1. **Given** der Titelbildschirm ist zu sehen, **When** die Maus über einen Eintrag fährt,
   **Then** wird die Zeile hervorgehoben, und der Hinweis zum Eintrag erscheint.
2. **Given** ein Eintrag ist ausgewählt, **When** der Spieler Pfeil runter drückt, **Then** ist der
   nächste Eintrag ausgewählt; nach dem letzten folgt wieder der erste.
3. **Given** die Maus steht auf einem Eintrag, **When** der Spieler eine Pfeiltaste drückt,
   **Then** gibt es weiterhin genau eine hervorgehobene Zeile, nämlich die per Tastatur gewählte.

---

### User Story 4 - Noch nicht verfügbare Einträge (Priority: P3)

„Neues Spiel“, „Spiel laden“ und „Einstellungen“ stehen schon im Menü, damit es vollständig ist.
Ihre Funktionen gibt es aber noch nicht. Sie sind deshalb als nicht verfügbar erkennbar und sagen
im Hinweis, warum.

**Why this priority**: Die Einträge gehören zum vollständigen Hauptmenü, ihre Funktionen kommen
mit eigenen Features: das Spiel mit dem ersten spielbaren Feature, Spielstände mit dem
Speichersystem 11-01, Einstellungen mit einem Feature, das noch keine Nummer hat.

**Independent Test**: Alle drei Einträge überfahren und auslösen: Es erscheint der Hinweis, sonst
passiert nichts.

**Acceptance Scenarios**:

1. **Given** der Titelbildschirm ist gerade erschienen, **When** der Spieler Enter drückt,
   **Then** passiert nichts, weil das vorausgewählte „Neues Spiel“ nicht verfügbar ist.
2. **Given** der Titelbildschirm ist zu sehen, **When** die Maus über „Spiel laden“ fährt,
   **Then** sagt der Hinweis, dass Spielstände erst mit dem Speichersystem kommen.
3. **Given** der Titelbildschirm ist zu sehen, **When** der Spieler „Einstellungen“ anklickt,
   **Then** passiert nichts, und es erscheint kein Fehler.

---

### Edge Cases

- Das Fenster ist kein ganzzahliges Vielfaches des Oberflächenrasters: Der Titelbildschirm
  erscheint im größten passenden ganzzahligen Faktor mittig mit schwarzem Rand, nie unscharf oder
  verzerrt. Das gilt auch für Mac-Bildschirme, die nicht im Format 16:9 sind.
- Der Spieler ändert die Fenstergröße oder wechselt zwischen Vollbild und Fenster, während der
  Titelbildschirm zu sehen ist: Die Darstellung folgt sofort derselben Regel.
- Das Fenster soll kleiner werden als das Oberflächenraster: Das geht nicht, die Mindestgröße ist
  das Raster bei Faktor 1.
- Die App wird ein zweites Mal gestartet, während sie schon läuft: Die laufende App kommt nach
  vorn, eine zweite öffnet sich nicht.
- Der Spieler drückt direkt nach dem Start Enter: Das Spiel bleibt offen, denn vorausgewählt ist
  „Neues Spiel“, und das ist nicht verfügbar.
- Der Spieler drückt Esc oder klickt mit rechts auf einen Eintrag: Es wird nichts ausgelöst.
- Die Maus verlässt das Menü: Die zuletzt gewählte Zeile bleibt ausgewählt, damit die Tastatur
  dort weitermacht.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Das Spiel muss sich als eigenständige macOS-App bauen lassen, die ohne
  Entwicklungsumgebung per Doppelklick in Finder, Dock oder Launchpad startet.
- **FR-002**: Die App muss in Finder, Dock und App-Umschalter „Der Computerladen“ heißen und ein
  eigenes Symbol tragen: den beigen Monitor aus dem Ladenschild-Logo auf einem abgerundeten
  Quadrat, wie macOS es für App-Symbole erwartet.
- **FR-003**: Beim Start muss die App bis zum Titelbildschirm laden. Bis er bereit ist, zeigt sie
  nur einen ruhigen dunklen Grund aus dem Style-Guide, kein fremdes Logo.
- **FR-004**: Die App muss im Vollbild starten. Ctrl+Cmd+F und der grüne Fensterknopf von macOS
  schalten zwischen Vollbild und Fenster um; im Fenster erscheint die Darstellung im größten
  ganzzahligen Faktor, der auf den Bildschirm passt.
- **FR-005**: Der Titelbildschirm muss das Titelbild T-01 über den ganzen Bildschirm zeigen,
  darüber das Logo mit dem Untertitel „WIRTSCHAFTSSIMULATION · 1985–1999“, das Hauptmenü und die
  Versionszeile. Anordnung und Gestaltung folgen dem
  [Titelscreen-Entwurf](https://claude.ai/artifact/RHKxpTb6JfWFQdNnPYEWHH) und dem
  [Style-Guide](https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX).
- **FR-006**: Das Hauptmenü muss genau diese Einträge in dieser Reihenfolge haben: „Neues Spiel“,
  „Spiel laden“, „Einstellungen“, „Beenden“.
- **FR-007**: „Neues Spiel“, „Spiel laden“ und „Einstellungen“ müssen sichtbar und als nicht
  verfügbar erkennbar sein. Ihr Hinweis nennt den Grund, Auslösen hat keine Wirkung.
- **FR-008**: „Beenden“ muss das Spiel ohne Rückfrage schließen. Unter macOS wirken Cmd+Q und das
  Schließen des Fensters genauso.
- **FR-009**: Das Menü muss mit der Maus bedienbar sein: Überfahren hebt die Zeile hervor und
  zeigt ihren Hinweis, ein Linksklick führt sie aus. Ein Rechtsklick führt nichts aus.
- **FR-010**: Das Menü muss mit der Tastatur bedienbar sein: Pfeil hoch und Pfeil runter wählen
  alle Einträge reihum, auch die nicht verfügbaren, und zeigen ihren Hinweis; Enter führt den
  gewählten aus, sofern er verfügbar ist. Beim Erscheinen des Titelbildschirms ist „Neues Spiel“
  gewählt.
- **FR-011**: Es muss immer genau eine Zeile hervorgehoben sein. Die zuletzt benutzte Eingabe,
  Maus oder Tastatur, bestimmt, welche.
- **FR-012**: Die Darstellung muss den Regeln des Style-Guides zu Raster und Skalierung folgen:
  nur ganzzahlig skaliert, sonst mit schwarzem Rand, nie unscharf.
- **FR-013**: Das Fenster darf sich nicht kleiner ziehen lassen als das Oberflächenraster.
- **FR-014**: Die Versionszeile muss die Version des laufenden Spiels zeigen und es als Prototyp
  kennzeichnen, im Entwurf „V0.1 · PROTOTYP“.
- **FR-015**: Alle Texte des Titelbildschirms müssen deutsch sein.

### Key Entities *(include if feature involves data)*

- **Menüeintrag**: Bezeichnung, verfügbar oder nicht, Hinweistext, ausgelöste Aktion.
- **Version**: Versionsnummer des Spiels und Kennzeichen „Prototyp“.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Vom Doppelklick auf die App bis zum bedienbaren Titelbildschirm vergehen auf dem
  Entwicklungsrechner höchstens 3 Sekunden.
- **SC-002**: Die gebaute App startet auf dem Entwicklungsrechner ohne Entwicklungsumgebung und
  ohne Warnung von macOS.
- **SC-003**: Jede Zeile reagiert auf Überfahren, Pfeiltaste und Klick sichtbar in unter 100 ms,
  wie es der Style-Guide für Rückmeldungen verlangt.
- **SC-004**: Im Vollbild auf 1080p, 1440p und 4K füllt der Titelbildschirm das ganze Bild; auf dem
  eingebauten Bildschirm des Entwicklungsrechners und bei jeder anderen getesteten Fenstergröße
  erscheint er ganzzahlig skaliert mit schwarzem Rand. Kein Pixel ist unscharf.
- **SC-005**: „Beenden“ lässt sich allein mit der Tastatur und allein mit der Maus auslösen,
  jeweils mit höchstens drei Eingaben.
- **SC-006**: Im Seitenvergleich mit dem Titelscreen-Entwurf stimmen Anordnung, Farben und
  Schriften überein. Jede Abweichung ist im Style-Guide begründet.

## Assumptions

- Gebaut wird in diesem Feature nur für macOS, und die App läuft vorerst nur auf dem
  Entwicklungsrechner. Signieren mit Developer-ID, Beglaubigung durch Apple sowie die Builds für
  Windows und Linux folgen mit 11-03 Build & Export.
- Es gibt noch keinen Spielbildschirm. „Neues Spiel“ wird mit dem ersten spielbaren Feature
  freigeschaltet. Die Zeitleisten-Demo bleibt in der Entwicklungsumgebung startbar, aus der
  App ist sie nicht erreichbar.
- Titelbild und Logo erscheinen in ihrer Rasterfassung nach dem Style-Guide. Dafür werden die
  freigegebenen Leonardo-Bilder nachbearbeitet, denn heute liegen sie noch nicht auf dem Raster.
  Das überschneidet sich mit 10-03 Pixel-Art-Pipeline.
- Der Style-Guide legt heute noch nicht fest, wie ein nicht verfügbarer Menüeintrag aussieht. Das
  wird vor dem Bauen dort ergänzt (Verfassung, Grundsatz IV), ebenso ein Abschnitt zum
  App-Symbol.
- Spielstände kommen mit dem Speichersystem (11-01), Einstellungen mit einem eigenen Feature.
- Es gibt keinen Ton und keine Musik (kommt mit 11-02), kein Intro vor dem Titel und keine
  Animation im Titelbild.
- Eigene Tastenkürzel für einzelne Einträge gibt es nicht; Pfeiltasten und Enter genügen.
- Gespielt wird am Desktop mit Maus und Tastatur unter Windows, macOS und Linux (Verfassung,
  Grundsatz I).
