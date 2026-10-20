# Feature Specification: Start bis zum Hauptmenü

**Feature Branch**: `feature/001-hauptmenue`

**System**: 10 Präsentation & UI; zieht den macOS-Teil von 11-03 Build & Export vor

**Created**: 2026-10-19

**Status**: Approved (Review 2026-10-19, [review.md](checklists/review.md))

**Input**: User description: "als erstes feature ggf. mainscreen oder so" – das Hauptmenü nach dem
Titelscreen-Entwurf und dem Style-Guide. Ergänzt: "dass wir die ganze App unter macOS auch starten
können […] startet und lädt die App bis zum Startscreen".

## Clarifications

### Session 2026-10-19

- Q: Gehört die Rasterfassung von Titelbild und Logo zu diesem Feature, oder kommt vorher 10-03
  Pixel-Art-Pipeline? → A: Nicht als Auswahl beantwortet; stattdessen ist der Umfang erweitert: Zum
  ersten Feature gehört auch, dass die App unter macOS als eigenständige App startet und bis zum
  Titelbildschirm lädt. Die Rasterfrage ist im Review bestätigt (siehe unten).
- Q: Soll die Mac-App vorerst nur auf dem eigenen Mac laufen oder auch auf anderen Macs? → A: Nur
  auf dem eigenen Mac; Signieren und Beglaubigen kommen mit 11-03.
- Q: Startet die App im Vollbild oder im Fenster, und wie schaltet man um, solange es keine
  Einstellungen gibt? → A: Im Vollbild; Ctrl+Cmd+F und der grüne Fensterknopf schalten ins
  Fenster und zurück. **Geändert am 2026-10-20** (Klaus, bei der Abnahme T040 von Feature 002):
  Die App startet im Fenster; Ctrl+Cmd+F und der grüne Knopf schalten ins Vollbild und zurück.
- Q: Wohin führt „Neues Spiel“, solange es noch keinen Spielbildschirm gibt? → A: Nirgendwohin:
  „Neues Spiel“ ist wie „Spiel laden“ vorerst nicht verfügbar; der Titelbildschirm ist die
  Endstation dieses Features.
- Q: Woher kommt das App-Symbol für Dock und Finder? → A: Aus dem Logo: der beige Monitor vom
  linken Ende des Ladenschilds, aufs Pixelraster gebracht, auf einem abgerundeten Quadrat.

### Review 2026-10-19

Entscheidungen von Klaus beim Durchgehen der Checkliste [review.md](checklists/review.md):

- Q: Siezen oder duzen die Texte den Spieler? → A: Sie duzen ihn, im ganzen Spiel.
- Q: Was macht ein Rechtsklick auf einen Eintrag? → A: Er wählt die Zeile und zeigt ihren Hinweis,
  löst aber nichts aus, wie im Style-Guide.
- Q: Welche Grundfläche bekommt das App-Symbol? → A: `nacht`.
- Q: Gehört die Rasterfassung von Titelbild und Logo in dieses Feature? → A: Ja.
- Q: Wer räumt die gerasterten Bilder von Hand auf? → A: Klaus, nur Grobes wie Einzelpixel und
  Farbreste.
- Q: Welche Tasten bedienen das Menü außer Pfeiltasten und Enter? → A: Die Leertaste löst aus wie
  Enter, Tab und Shift+Tab wählen wie Pfeil runter und hoch.
- Q: Welcher Mauszeiger erscheint über den Einträgen? → A: Die Hand nur über verfügbaren, sonst
  der Pfeil.
- Q: Welche Bundle-ID bekommt die App? → A: `de.klausmoster.dercomputerladen` (steht im Plan).

### Abschluss 2026-10-20

Entscheidungen von Klaus bei der Umsetzung und der Lückensuche (T044):

- Q: Wann wählt die Maus eine Zeile? → A: Sobald sie sie betritt; eine Bewegung innerhalb
  derselben Zeile wählt nicht neu (abgenommen in T039). FR-011 ist entsprechend gefasst.
- Q: Braucht der Start eine Ladeanzeige? → A: Nein. Der Start dauert rund 1 Sekunde (SC-001);
  langsamer ist nur der erste Start nach einem Export, wenn macOS die neue App prüft.
- Q: Wer macht den groben Feinschliff an Titelbild und Logo? → A: Auf Klaus' Wunsch eine Regel
  (`tools/raster/cleanup.py`); von Hand nachbessern geht jederzeit.
- Q: Kommt „Beenden“ erst in Phase 4? → A: Nein, es wurde beim ersten Test der App vorgezogen.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - App unter macOS bis zum Titelbildschirm starten (Priority: P1)

Klaus baut das Spiel als Mac-App und startet sie wie jede andere App per Doppelklick, ohne die
Entwicklungsumgebung. Die App lädt und zeigt dann im Fenster den Titelbildschirm: den
Computerladen an der Straßenecke am Abend, oben links das Ladenschild-Logo mit Untertitel, rechts
das Hauptmenü auf Endlospapier und unten links die Versionszeile.

**Why this priority**: Das ist der Kern des ersten Features. Ab hier gibt es ein Spiel, das man
starten kann, und jedes weitere Feature hängt sich an diesen Einstieg. Der Titelbildschirm setzt
außerdem den Ton: Retro im Bild, modern in der Hand.

**Independent Test**: Die App bauen und im Finder doppelklicken: Der Titelbildschirm erscheint. Das
funktioniert auch dann, wenn die Menüpunkte noch nichts tun.

**Acceptance Scenarios**:

1. **Given** die App ist gebaut und die Entwicklungsumgebung geschlossen, **When** Klaus sie im
   Finder doppelklickt, **Then** startet sie und zeigt nach dem Laden den Titelbildschirm mit
   Titelbild, Logo, Untertitel, Hauptmenü und Versionszeile.
2. **Given** die App lädt noch, **When** der Titelbildschirm noch nicht bereit ist, **Then** ist
   nur der dunkle Startgrund zu sehen, kein fremdes Logo.
3. **Given** die App läuft, **When** Klaus auf Dock und App-Umschalter schaut, **Then** steht dort
   „Der Computerladen“ mit dem Monitor aus dem Logo auf `nacht` als Symbol.
4. **Given** die App ist gestartet, **When** der Titelbildschirm erscheint, **Then** läuft sie im
   Fenster, und Ctrl+Cmd+F wechselt ins Vollbild und wieder zurück.

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
Auswahl mit Pfeiltasten oder Tab heben die Zeile hervor, Linksklick, Enter oder Leertaste führt
sie aus, und ein Hinweis (Tooltip) sagt, was der Eintrag tut oder warum er noch nicht verfügbar
ist. Ein Rechtsklick zeigt nur den Hinweis.

**Why this priority**: Das ist die erste Bedienung im Spiel. Hier zeigt sich das Versprechen, dass
sich der Retro-Look wie ein heutiges Spiel bedienen lässt.

**Independent Test**: Das Menü einmal nur mit der Tastatur und einmal nur mit der Maus bedienen.

**Acceptance Scenarios**:

1. **Given** der Titelbildschirm ist zu sehen, **When** die Maus über einen Eintrag fährt,
   **Then** wird die Zeile hervorgehoben, und der Hinweis zum Eintrag erscheint.
2. **Given** ein Eintrag ist ausgewählt, **When** der Spieler Pfeil runter oder Tab drückt,
   **Then** ist der nächste Eintrag ausgewählt; nach dem letzten folgt wieder der erste.
3. **Given** die Maus steht auf einem Eintrag, **When** der Spieler eine Pfeiltaste drückt,
   **Then** gibt es weiterhin genau eine hervorgehobene Zeile, nämlich die per Tastatur gewählte.
4. **Given** der Titelbildschirm ist zu sehen, **When** der Spieler mit rechts auf einen Eintrag
   klickt, **Then** ist die Zeile gewählt und ihr Hinweis zu sehen, ausgelöst wird nichts.
5. **Given** der Titelbildschirm ist zu sehen, **When** die Maus über „Beenden“ steht, **Then**
   zeigt der Mauszeiger die Hand; über einem nicht verfügbaren Eintrag bleibt er ein Pfeil.

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

1. **Given** der Titelbildschirm ist gerade erschienen, **When** der Spieler Enter oder die
   Leertaste drückt, **Then** passiert nichts, weil das vorausgewählte „Neues Spiel“ nicht
   verfügbar ist.
2. **Given** der Titelbildschirm ist zu sehen, **When** die Maus über „Spiel laden“ fährt,
   **Then** erscheint der Hinweis „Noch keine Spielstände. Speichern kommt bald.“
3. **Given** der Titelbildschirm ist zu sehen, **When** der Spieler „Einstellungen“ anklickt,
   **Then** passiert nichts, und es erscheint kein Fehler.

---

### Edge Cases

- Das Fenster ist kein ganzzahliges Vielfaches des Oberflächenrasters: Der Titelbildschirm
  erscheint im größten passenden ganzzahligen Faktor mittig mit schwarzem Rand, nie unscharf oder
  verzerrt. Das gilt auch für Mac-Bildschirme, die nicht im Format 16:9 sind.
- Der Mac-Bildschirm hat eine Kameraaussparung: Das ganze Bild liegt unterhalb der Aussparung,
  nichts davon wird verdeckt.
- Der Spieler ändert die Fenstergröße oder wechselt zwischen Vollbild und Fenster, während der
  Titelbildschirm zu sehen ist: Die Darstellung folgt sofort derselben Regel.
- Mehrere Bildschirme sind angeschlossen: Die App startet auf dem Hauptbildschirm. Die
  Fenstergröße richtet sich nach dem Bildschirm, auf dem das Fenster gerade liegt.
- Das Fenster soll kleiner werden als das Oberflächenraster: Das geht nicht, die Mindestgröße ist
  das Raster bei Faktor 1.
- Die App wird ein zweites Mal gestartet, während sie schon läuft: Die laufende App kommt nach
  vorn, eine zweite öffnet sich nicht.
- Der Spieler drückt direkt nach dem Start Enter oder die Leertaste: Das Spiel bleibt offen, denn
  vorausgewählt ist „Neues Spiel“, und das ist nicht verfügbar.
- Der Spieler drückt Esc: Es wird nichts ausgelöst.
- Die Maus fährt über die Kopfzeile oder die Lochränder: Die Auswahl ändert sich nicht.
- Die Maus verlässt das Menü: Die zuletzt gewählte Zeile bleibt ausgewählt und ihr Hinweis stehen,
  damit die Tastatur dort weitermacht.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Das Spiel muss sich als eigenständige macOS-App bauen lassen, reproduzierbar mit
  einem einzigen Befehl; das Ergebnis liegt außerhalb der Versionsverwaltung. Die App startet ohne
  Entwicklungsumgebung per Doppelklick im Finder, aus dem Dock oder über Spotlight.
- **FR-002**: Die App muss in Finder, Dock und App-Umschalter „Der Computerladen“ heißen und ein
  eigenes Symbol tragen: den beigen Monitor aus dem Ladenschild-Logo auf einem abgerundeten
  Quadrat in `nacht`. Unter macOS 27 erscheint es im Dock ohne grauen Rahmen, und der Monitor ist
  auch in der Listenansicht des Finders zu erkennen.
- **FR-003**: Beim Start muss die App bis zum Titelbildschirm laden. Bis er bereit ist, zeigt sie
  nur den Startgrund in `anzeige-grund` aus dem Style-Guide, kein fremdes Logo.
- **FR-004**: Die App muss im Fenster starten (bis 2026-10-20: im Vollbild). Ctrl+Cmd+F und der
  grüne Fensterknopf von macOS schalten zwischen Fenster und Vollbild um. Im Fenster, auch beim
  Start, erscheint die Darstellung im größten ganzzahligen Faktor, der samt Titelleiste auf den
  Bildschirm passt, auf dem das Fenster gerade liegt.
- **FR-005**: Der Titelbildschirm muss das Titelbild T-01 über den ganzen Bildschirm zeigen,
  darüber das Logo mit dem Untertitel „WIRTSCHAFTSSIMULATION · 1985–1999“, das Hauptmenü und die
  Versionszeile. Anordnung und Gestaltung folgen dem
  [Titelscreen-Entwurf](https://claude.ai/artifact/RHKxpTb6JfWFQdNnPYEWHH) und dem
  [Style-Guide](https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX).
- **FR-006**: Das Hauptmenü muss genau diese Einträge in dieser Reihenfolge haben: „Neues Spiel“,
  „Spiel laden“, „Einstellungen“, „Beenden“. Darüber steht die Kopfzeile „HAUPTMENÜ“.
- **FR-007**: „Neues Spiel“, „Spiel laden“ und „Einstellungen“ müssen sichtbar und als nicht
  verfügbar erkennbar sein, in Ruhe wie ausgewählt. Ihr Text bleibt dabei lesbar, mit einem
  Kontrast von mindestens 3 : 1 zum Zeilengrund. Ihr Hinweis nennt den Grund, Auslösen hat keine
  Wirkung.
- **FR-008**: „Beenden“ muss das Spiel ohne Rückfrage schließen. Unter macOS wirken Cmd+Q und das
  Schließen des Fensters genauso.
- **FR-009**: Das Menü muss mit der Maus bedienbar sein: Überfahren hebt die Zeile hervor und
  zeigt ihren Hinweis, ein Linksklick führt sie aus. Ein Rechtsklick wählt die Zeile und zeigt
  ihren Hinweis, führt aber nichts aus.
- **FR-010**: Das Menü muss mit der Tastatur bedienbar sein: Pfeil runter und Tab wählen den
  nächsten Eintrag, Pfeil hoch und Shift+Tab den vorigen, reihum und auch die nicht verfügbaren;
  dabei erscheint jeweils ihr Hinweis. Enter oder Leertaste führen den gewählten Eintrag aus,
  sofern er verfügbar ist. Beim Erscheinen des Titelbildschirms ist „Neues Spiel“ gewählt.
- **FR-011**: Es muss immer genau eine Zeile hervorgehoben sein, so wie der Menü-Baustein des
  Style-Guides es vorsieht: Zeile in `signalgelb` mit Pfeil davor, ohne zusätzliche Fokuslinie.
  Die Maus wählt eine Zeile, sobald sie sie betritt, Pfeiltasten und Tab bei jedem Druck; es
  gilt, was zuletzt gewählt hat.
- **FR-012**: Die Darstellung muss den Regeln des Style-Guides zu Raster und Skalierung folgen:
  nur ganzzahlig skaliert, sonst mit schwarzem Rand, nie unscharf.
- **FR-013**: Das Fenster darf sich nicht kleiner ziehen lassen als das Oberflächenraster bei
  Faktor 1, also 640 × 360 Bildschirmpixel (auf Retina-Bildschirmen 320 × 180 Punkte).
- **FR-014**: Die Versionszeile muss die Version des laufenden Spiels zeigen und es als Prototyp
  kennzeichnen, im Entwurf „V0.1 · PROTOTYP“. Ist keine Version gesetzt, steht dort nur
  „PROTOTYP“. Dieselbe Versionsnummer zeigt der Finder in den Informationen zur App.
- **FR-015**: Alle Texte des Titelbildschirms müssen deutsch sein und den Spieler duzen.
- **FR-016**: Jeder Eintrag muss einen Hinweis haben:

  | Eintrag | Hinweis |
  |---|---|
  | Neues Spiel | Der Laden hat noch zu. Bald kannst du ihn eröffnen. |
  | Spiel laden | Noch keine Spielstände. Speichern kommt bald. |
  | Einstellungen | Noch nichts einzustellen. Kommt später. |
  | Beenden | Laden abschließen und zurück zum Desktop. |

- **FR-017**: Der Hinweis muss ohne Verzögerung mit der Auswahl erscheinen, links neben der
  gewählten Zeile, und stehen bleiben, bis eine andere Zeile gewählt wird. Sein Aussehen legt der
  Style-Guide fest.
- **FR-018**: Über verfügbaren Einträgen muss der Mauszeiger die Hand zeigen, über nicht
  verfügbaren bleibt er ein Pfeil.
- **FR-019**: Titelbild und Logo müssen auf dem Bildraster liegen: das Titelbild mit genau
  320 × 180 Bildpixeln, das Logo so, dass jeder seiner gemalten Pixel ein Bildpixel ist. Beide
  verwenden nur Farben der Hauptpalette, und der Schriftzug „DER COMPUTERLADEN“ bleibt mit jedem
  Buchstaben vollständig lesbar.

### Key Entities *(include if feature involves data)*

- **Menüeintrag**: Bezeichnung, verfügbar oder nicht, Hinweistext, ausgelöste Aktion.
- **Version**: Versionsnummer des Spiels und Kennzeichen „Prototyp“.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Vom Doppelklick auf die App bis zum bedienbaren Titelbildschirm vergehen auf dem
  Entwicklungsrechner höchstens 3 Sekunden. Gemessen wird mit der Stoppuhr bis zur ersten
  Reaktion des Menüs; es zählt der schlechteste von drei Starts, der erste Start nach einem neuen
  Export zählt nicht mit.
- **SC-002**: Die gebaute App startet auf dem Entwicklungsrechner ohne Entwicklungsumgebung und
  ohne Warnung von macOS.
- **SC-003**: Jede Zeile reagiert auf Überfahren, Pfeiltaste, Tab und Klick ohne wahrnehmbare
  Verzögerung, spätestens im nächsten Bild und damit unter den 100 ms, die der Style-Guide für
  Rückmeldungen verlangt.
- **SC-004**: Im Vollbild auf 1080p, 1440p und 4K füllt der Titelbildschirm das ganze Bild; auf dem
  eingebauten Bildschirm des Entwicklungsrechners und bei jeder anderen getesteten Fenstergröße
  erscheint er ganzzahlig skaliert mit schwarzem Rand. Kein Pixel ist unscharf: Ein
  Bildschirmfoto in Originalgröße zeigt jeden Rasterpixel als Block gleichfarbiger
  Bildschirmpixel und die Schrift ohne Zwischentöne.
- **SC-005**: „Beenden“ lässt sich allein mit der Tastatur und allein mit der Maus auslösen,
  jeweils mit höchstens drei Eingaben.
- **SC-006**: Im Seitenvergleich mit dem Titelscreen-Entwurf stimmen Farben und Schriften genau,
  Lage und Größen auf 2 Oberflächenpixel. Nur das Logo darf durch die Rasterfassung etwas kleiner
  sein. Jede weitere Abweichung ist im Style-Guide begründet.
- **SC-007**: Klaus gibt das Aussehen von gerastertem Titelbild, Logo und App-Symbol frei;
  offensichtliche Fehler wie Einzelpixel und Farbreste sind entfernt.

## Assumptions

- Gebaut wird in diesem Feature nur für macOS, und die App läuft vorerst nur auf dem
  Entwicklungsrechner. Signieren mit Developer-ID, Beglaubigung durch Apple sowie die Builds für
  Windows und Linux folgen mit 11-03 Build & Export.
- Es gibt noch keinen Spielbildschirm. „Neues Spiel“ wird mit dem ersten spielbaren Feature
  freigeschaltet. Die Zeitleisten-Demo bleibt in der Entwicklungsumgebung startbar, aus der App ist
  sie nicht erreichbar.
- Titelbild und Logo werden aus den freigegebenen Leonardo-Bildern aufs Raster gebracht; den
  groben Feinschliff macht eine Regel, Klaus bessert bei Bedarf von Hand nach (Abschluss
  2026-10-20). Das überschneidet sich mit 10-03 Pixel-Art-Pipeline, die danach
  die wiederholbare Fassung für alle weiteren Bilder liefert.
- Vor dem Bauen wird der Style-Guide ergänzt (Verfassung, Grundsatz IV): Aussehen nicht verfügbarer
  Einträge, Hinweis, Startgrund, App-Symbol, Anrede „du“ und die Nachbearbeitung bei ungleich
  großen gemalten Pixeln.
- Spielstände kommen mit dem Speichersystem (11-01), Einstellungen mit einem eigenen Feature.
- Es gibt keinen Ton und keine Musik (kommt mit 11-02), kein Intro vor dem Titel und keine
  Animation im Titelbild.
- Eigene Tastenkürzel je Eintrag gibt es nicht, die Hinweise nennen deshalb keine. Die Regel des
  Style-Guides, dass ein Tooltip das Kürzel nennt, greift, sobald es Kürzel gibt.
- Bilder und Schriften sind fest in die App eingebaut. Fehlt eines, ist das ein Fehler beim Bauen,
  den die Startprobe aufdeckt; ein eigenes Verhalten zur Laufzeit ist dafür bewusst nicht
  vorgesehen.
- Dass ein zweiter Doppelklick die laufende App nach vorn holt, leistet macOS; das Spiel tut dafür
  nichts.
- Gespielt wird am Desktop mit Maus und Tastatur unter Windows, macOS und Linux (Verfassung,
  Grundsatz I).
