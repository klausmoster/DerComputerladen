# Feature Specification: Neues Spiel starten

**Feature Branch**: `feature/004-neues-spiel`

**System**: 11 Infrastruktur (11-01 Spielstände), 01 Zeitleiste (01-05 Neues Spiel) und
10 Präsentation & UI

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "Neues Spiel, Schwierigkeitsgrad wählen. Weiteres entwickeln wir
derweil, was eben alles dafür notwendig sein könnte. Neues Spiel wird gespeichert. Spiel startet
(leerer Screen ist ok). Spiel beenden. Gespeichertes Spiel fortsetzen. Spiel löschen."

## Clarifications

### Specify 2026-10-26

Fragen aus `/speckit-specify`, von Klaus jeweils nach Empfehlung entschieden:

- Q: Wie viele Spielstände gibt es, und wie heißen sie? → A: Beliebig viele; jedes Spiel ist ein
  Spielstand und heißt automatisch fortlaufend „Spiel 1“, „Spiel 2“ … Einen eigenen Namen gibt
  es, sobald der Laden einen hat (05 Standort). Verworfen: Name eintippen (braucht ein
  Eingabefeld und einen neuen Baustein), drei feste Plätze wie in den 90ern.
- Q: Wie sieht das Hauptmenü aus? → A: Oben neu „Weiterspielen“: Es setzt das zuletzt gespielte
  Spiel fort und ist vorgewählt, sobald es einen Spielstand gibt. „Spiel laden“ zeigt die Liste
  aller Spielstände, dort wird auch gelöscht. Verworfen: nur „Spiel laden“, ein Schritt mehr bis
  ins Spiel.
- Q: Was passiert mit einem gespeicherten Spiel, wenn der Katalog danach in der Werkstatt
  geändert wird? → A: Der Spielstand behält seinen Katalog: Er nimmt beim Anlegen eine Kopie mit,
  samt den Profilen der Grade, und läuft damit weiter. Änderungen gelten ab dem nächsten neuen
  Spiel. Verworfen: mit dem aktuellen Katalog neu aufbauen (die Vergangenheit könnte sich
  verschieben) und „Vergangenheit bleibt, Zukunft neu“ (deutlich aufwändiger).

### Session 2026-10-26

Fragen aus `/speckit-clarify`:

- Q: Wie verlässt der Spieler ein laufendes Spiel? → A: Über einen Knopf auf dem
  Spielbildschirm, der speichert und zurück ins Hauptmenü führt (Klaus, gegen die Empfehlung
  eines Spielmenüs mit Esc). Der Spielbildschirm wird später weiterentwickelt; Klaus' Idee dazu,
  ein Communicator aus dem jeweiligen Spieljahr, steht in `docs/Ideensammlung.md`. Zum Desktop
  geht es über „Beenden“ im Hauptmenü, Cmd+Q oder das Schließen des Fensters, die ebenfalls
  speichern.
- Q: Was kann der noch leere Spielbildschirm? → A: Nichts außer dem Knopf zurück ins Hauptmenü.
  Er ist nur das Ziel, zu dem man in diesem Feature navigiert, und hat einen Ausgang (Klaus,
  gegen die Empfehlung einer laufenden Uhr mit Pause). Die Uhr steht also; ein Spiel bleibt in
  diesem Feature am 01.01.1985. Dass Spielstände auch ein späteres Datum richtig festhalten und
  fortsetzen, belegen die automatischen Tests, die ein Spiel dafür selbst vorspulen.
- Q: Wo erscheinen die Wahl des Grads und die Liste der Spielstände? → A: Auf dem
  Titelbildschirm: Titelbild und Logo bleiben, an der Stelle des Hauptmenüs erscheint ein eigenes
  Blatt Endlospapier. Verworfen: eigene Bildschirme ohne Titelbild, ein Dialogfenster wie in der
  Werkstatt.
- Q: Wie löscht der Spieler in der Liste einen Spielstand? → A: Über einen Eintrag „Löschen …“
  unten in der Liste, der in einen Löschmodus schaltet; die dann gewählte Zeile wird nach der
  Rückfrage gelöscht (Klaus, gegen die Empfehlung Entf-Taste und Symbol in der Zeile). Claudes
  Festlegungen dazu, in FR-017a: Der Modus ist an der Kopfzeile erkennbar, er endet nach dem
  Löschen, nach Abbrechen in der Rückfrage, mit „Zurück“ und mit Esc.
- Q: Was sagen die Sätze zu den Graden? → A: Ehrlich und trocken: Je ein Satz verspricht nur, was
  der Grad heute tut, nämlich die Chancen von Ereignissen verschieben, im Ton von „Das Amt“, etwa
  Leicht: „Das Glück ist eher auf deiner Seite.“ Claude schlägt die Sätze im Plan vor, der
  Text-Prüfer prüft sie, Klaus entscheidet. Verworfen: keine Sätze; Klaus schreibt sie selbst.

### Plan 2026-10-26

- Q: Gelten Claudes fünf Festlegungen aus der Spec (Esc auf dem Spielbildschirm, „Spiel N“,
  Löschmodus, „Spiel laden“ bei nur beschädigten Spielständen, kein Speichern während des
  Spiels)? → A: Ja, alle bestätigt (Klaus, nach Empfehlung).
- Q: Welche Sätze stehen bei den Graden (FR-004)? → A: Vorschlag A aus `research.md`, R18:
  Leicht „Das Glück ist eher auf deiner Seite.“, Mittel „Das Glück hält sich raus.“, Schwer „Das
  Glück ist eher auf der Seite der anderen.“ (Klaus, nach Empfehlung). Verworfen: B mit guten und
  schlechten Ereignissen, das nur bei passenden Profilen stimmt; C mit „Zufall“, das mehr
  behauptet, als der Grad tut.

### Review 2026-10-26

Aus der Checkliste [review.md](checklists/review.md) mit 36 Punkten; Klaus hat am 2026-10-26 alle
Vorschläge freigegeben. Präzisiert sind FR-004, FR-010, FR-011, FR-015, FR-017, FR-017a, FR-018,
FR-023, SC-002 und SC-006; neu sind Edge Cases zu Fehlerwegen und vier Annahmen. Die wichtigsten:
- Q: Was, wenn zwei Fenster des Spiels gleichzeitig ein neues Spiel anlegen? → A: Ein neues Spiel
  schreibt nur unter einer Nummer, zu der es noch keine Datei gibt, sonst nimmt es die nächste
  (CHK002).
- Q: Was, wenn das Speichern beim Schließen des Fensters scheitert? → A: Das Fenster bleibt offen
  mit einer Meldung; ein zweites Schließen beendet ohne Speichern (CHK020). Seit der Phasenprüfung
  von Phase 3 sagt die Meldung nur den Fehler, wie überall (Klaus, 2026-10-26).
- Q: Wie wird SC-002 gemessen? → A: mit 20 Spielständen und je 500 Ereignissen im Katalog, dazu
  das Fortsetzen eines Spielstands vom 31.12.1999 (CHK024).

### Analyse 2026-10-26

Aus `/speckit-analyze` mit 44 Befunden; Klaus hat am 2026-10-26 alle nach Empfehlung freigegeben.
An der Spec geändert: der Edge Case „Zwei Fenster des Spiels gleichzeitig“ verspricht nicht mehr,
dass nie etwas überschrieben wird (F10), und FR-016 sagt „zum laufenden Spiel machen“ statt „auf
dem Spielbildschirm zeigen“ (B5). Alles Übrige betraf Plan, research.md, Datenmodell, Verträge,
Quickstart und Tasks (plan.md, „Änderungen nach der Analyse“).

## Überblick

Bisher endet das Spiel am Hauptmenü: „Neues Spiel“ und „Spiel laden“ sind nicht verfügbar, und im
Hintergrund startet die Zeitleiste von selbst ein Spiel mit „Mittel“, das niemand sieht. Mit
diesem Feature beginnt der Spieler ein eigenes Spiel: Er wählt Leicht, Mittel oder Schwer, das
Spiel wird als Spielstand gespeichert, und er landet auf einem noch leeren Spielbildschirm. Er kann
das Spiel verlassen, später fortsetzen und einen Spielstand löschen.

Ein **Spielstand** ist die Datei, die ein Spiel festhält, so dass es nach dem Beenden genau dort
weitergeht. Beispiel, sobald die Uhr im Spiel läuft (ein späteres Feature): Klaus beginnt am
Abend ein Spiel auf „Schwer“, spielt bis zum 14.03.1986 und beendet die App. Am nächsten Tag wählt
er sein Spiel, und es geht am 14.03.1986 auf „Schwer“ weiter, mit demselben Fahrplan der
Zeitleiste, als hätte er nie unterbrochen. In diesem Feature steht die Uhr noch; das Festhalten
des Datums prüfen die automatischen Tests.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Neues Spiel mit Schwierigkeitsgrad beginnen (Priority: P1)

Der Spieler wählt im Hauptmenü „Neues Spiel“. Es erscheint die Wahl des Schwierigkeitsgrads mit
Leicht, Mittel und Schwer, jeweils mit einem Satz, was der Grad bedeutet; vorgewählt ist Mittel.
Er bestätigt, ein Spiel am 01.01.1985 wird als Spielstand gespeichert, und der noch leere
Spielbildschirm erscheint.

**Why this priority**: Das ist der Kern: Ab hier gibt es ein Spiel, das der Spieler selbst beginnt.
Ohne diesen Weg hat kein anderer Teil des Features etwas, woran er hängt.

**Independent Test**: Im Hauptmenü „Neues Spiel“ wählen, „Schwer“ wählen und bestätigen: Der
Spielbildschirm erscheint, und „Spiel laden“ zeigt einen neuen Spielstand mit „Schwer“ und dem
01.01.1985.

**Acceptance Scenarios**:

1. **Given** das Hauptmenü ist zu sehen, **When** der Spieler „Neues Spiel“ wählt, **Then**
   erscheint die Wahl des Grads mit Leicht, Mittel und Schwer, und Mittel ist vorgewählt.
2. **Given** die Wahl des Grads ist zu sehen, **When** der Spieler „Leicht“ wählt und bestätigt,
   **Then** ist ein Spielstand mit Grad Leicht am 01.01.1985 angelegt, und der Spielbildschirm
   erscheint.
3. **Given** die Wahl des Grads ist zu sehen, **When** der Spieler abbricht, **Then** ist er zurück
   im Hauptmenü, und es ist kein Spielstand angelegt.
4. **Given** der Spieler beginnt zweimal hintereinander ein neues Spiel mit demselben Grad,
   **When** er beide Spielstände vergleicht, **Then** haben sie verschiedene Seeds, also
   verschiedene Fahrpläne.
5. **Given** das Hauptmenü ist zu sehen und noch kein Spiel begonnen, **When** niemand etwas tut,
   **Then** läuft im Hintergrund kein Spiel, und es entsteht kein Spielstand.

---

### User Story 2 - Spiel verlassen, ohne etwas zu verlieren (Priority: P1)

Der Spieler verlässt ein laufendes Spiel, zurück ins Hauptmenü oder ganz aus der App. Dabei wird
der Spielstand gespeichert, ohne dass er daran denken muss.

**Why this priority**: Ohne einen Ausgang aus dem Spiel und ohne Sicherung ist „Fortsetzen“ nichts
wert. Beides gehört zum ersten spielbaren Stand.

**Independent Test**: Ein neues Spiel beginnen und über den Knopf verlassen: Das Hauptmenü
erscheint mit „Weiterspielen“ vorgewählt. Ein automatischer Test spult ein Spiel bis Februar 1985
vor und verlässt es: Der Spielstand trägt dasselbe Datum im Februar 1985.

**Acceptance Scenarios**:

1. **Given** ein Spiel läuft, **When** der Spieler den Knopf „Zum Hauptmenü“ auf dem
   Spielbildschirm wählt, **Then** wird der Spielstand gespeichert, und das Hauptmenü erscheint,
   mit „Weiterspielen“ vorgewählt.
2. **Given** ein Spiel läuft, **When** der Spieler unter macOS Cmd+Q drückt oder das Fenster
   schließt, **Then** wird der Spielstand gespeichert, und die App endet.
3. **Given** ein Spiel steht am 31.12.1999 (im automatischen Test vorgespult), **When** es
   verlassen wird, **Then** ist der Spielstand gespeichert und lässt sich wieder öffnen.

---

### User Story 3 - Gespeichertes Spiel fortsetzen (Priority: P2)

Der Spieler setzt ein gespeichertes Spiel fort und ist wieder auf dem Spielbildschirm; das Spiel
steht am gespeicherten Datum, mit dem gespeicherten Grad und Seed.

**Why this priority**: Das ist der Sinn des Speicherns. Es kommt nach P1, weil ein Spiel auch ohne
Fortsetzen schon spielbar und prüfbar ist.

**Independent Test**: Von Hand: zwei Spiele mit verschiedenen Graden beginnen, die App neu
starten, mit „Weiterspielen“ das zuletzt begonnene fortsetzen; „Spiel laden“ zeigt es danach oben.
Automatisch: ein Spiel bis zum 14.03.1986 vorspulen, speichern, neu laden: Es steht am 14.03.1986
mit demselben Grad und Seed, und die Zeitleiste meldet ab dort dieselben Ereignisse wie ein Spiel,
das nie unterbrochen wurde.

**Acceptance Scenarios**:

1. **Given** es gibt mindestens einen Spielstand, **When** der Titelbildschirm erscheint und der
   Spieler Enter drückt, **Then** ist „Weiterspielen“ vorgewählt, und der Spielbildschirm
   erscheint mit dem zuletzt gespielten Spielstand als laufendem Spiel.
2. **Given** es gibt keinen Spielstand, **When** der Titelbildschirm erscheint, **Then** sind
   „Weiterspielen“ und „Spiel laden“ nicht verfügbar, ihr Hinweis sagt, warum, und „Neues Spiel“
   ist vorgewählt.
3. **Given** mehrere Spielstände, **When** der Spieler in „Spiel laden“ einen älteren wählt,
   **Then** erscheint dieses Spiel, und beim nächsten Start setzt „Weiterspielen“ es fort.
4. **Given** ein Spiel wurde im automatischen Test am 14.03.1986 gespeichert und fortgesetzt,
   **When** es bis zum 31.12.1986 läuft, **Then** meldet die Zeitleiste dieselben Ereignisse an
   denselben Tagen wie ein Spiel mit demselben Seed und Grad, das ohne Pause bis dorthin lief.
5. **Given** mehrere Spielstände, **When** der Spieler sie in „Spiel laden“ sieht, **Then** stehen
   sie nach „zuletzt gespielt“ geordnet, das jüngste oben, je mit Name, Grad, Spieldatum und wann
   zuletzt gespielt.

---

### User Story 4 - Spielstand löschen (Priority: P3)

Der Spieler löscht einen Spielstand, den er nicht mehr braucht. Vorher fragt das Spiel nach.

**Why this priority**: Aufräumen ist nötig, sobald es mehrere Spielstände gibt, aber nicht für das
erste Spiel.

**Independent Test**: Zwei Spielstände anlegen, in der Liste „Löschen …“ wählen, einen davon
wählen und die Rückfrage bestätigen: Er ist aus der Liste und aus dem Ordner verschwunden, der
andere ist unverändert.

**Acceptance Scenarios**:

1. **Given** die Liste der Spielstände ist zu sehen, **When** der Spieler „Löschen …“ und dann
   „Spiel 1“ wählt, **Then** fragt das Spiel nach und nennt den Spielstand mit Name, Grad und
   Spieldatum.
2. **Given** die Liste ist im Löschmodus, **When** der Spieler Esc drückt, **Then** ist der
   Löschmodus beendet, und Enter auf einer Zeile setzt wieder fort.
3. **Given** die Rückfrage ist zu sehen, **When** der Spieler bestätigt, **Then** ist der
   Spielstand gelöscht und verschwindet aus der Liste.
4. **Given** die Rückfrage ist zu sehen, **When** der Spieler abbricht oder Esc drückt, **Then**
   bleibt der Spielstand unverändert.
5. **Given** der letzte Spielstand wurde gelöscht, **When** der Spieler zurück im Hauptmenü ist,
   **Then** sind „Weiterspielen“ und „Spiel laden“ nicht verfügbar, und „Neues Spiel“ ist
   vorgewählt. Ist die Liste nach dem Löschen leer, kehrt das Spiel von selbst ins Hauptmenü
   zurück.

---

### Edge Cases

- **Beschädigter Spielstand**: Eine Datei, die sich nicht lesen lässt, etwa nach einem Absturz
  von außen oder von Hand verändert, erscheint in der Liste als „beschädigt“ mit dem Grund. Sie
  lässt sich nicht fortsetzen, aber löschen. Das Spiel überschreibt sie nie und stürzt nicht ab.
- **Zu neuer Spielstand**: Ein Spielstand aus einer neueren Version des Spiels, erkennbar an seiner
  Formatversion, erscheint in der Liste mit dem Hinweis, dass er eine neuere Version braucht. Er
  lässt sich nicht fortsetzen, aber löschen, und wird nie überschrieben.
- **Werte außerhalb ihres Bereichs**: Ein unbekannter Grad, ein Seed außerhalb, ein Spieldatum
  außerhalb von 1985 bis 1999 oder ein Eingriff mit einem Datum, das es nicht gibt: Der
  Spielstand gilt als beschädigt.
- **Speichern scheitert**, etwa weil der Datenträger voll ist: Der Spieler erfährt es mit einer
  Meldung, der vorige Stand des Spielstands bleibt lesbar, und das Spiel läuft weiter. Scheitert
  schon das erste Speichern eines neuen Spiels, entsteht weder Spielstand noch laufendes Spiel, und
  die Gradwahl bleibt mit der Meldung stehen. Scheitert es beim Fortsetzen, läuft das Spiel, und
  der Spielbildschirm zeigt die Meldung.
- **Speichern beim Beenden scheitert** (Fensterknopf, Cmd+Q): Das Fenster bleibt offen, damit der
  Spieler die Meldung sieht, dieselbe wie sonst: „Speichern ging nicht. Dein Spiel läuft weiter.“
  Beendet er noch einmal, endet das Spiel ohne Speichern; der vorige Stand bleibt. Die Meldung
  erklärt das nicht (Klaus, 2026-10-26, nach der Phasenprüfung von Phase 3).
- **Löschen scheitert**, etwa weil die Datei gesperrt ist: Der Spieler erfährt es mit einer
  Meldung, der Spielstand bleibt, und die Liste zeigt den Stand neu, ohne Löschmodus.
- **Absturz oder Stromausfall während des Speicherns**: Der vorige Stand des Spielstands bleibt
  lesbar; es entsteht nie eine halb geschriebene Datei an seiner Stelle. Der Spieler sieht danach
  nichts Besonderes, nur das Protokoll nennt, was übrig blieb.
- **Datei ändert sich von außen**, etwa im Finder gelöscht, während die Liste zu sehen ist:
  Fortsetzen nimmt den Stand, den die Liste gelesen hat, und das Speichern dabei schreibt ihn
  wieder. Die Liste liest den Ordner jedes Mal neu, wenn sie erscheint.
- **Zwei Fenster des Spiels gleichzeitig**: Ein neues Spiel schreibt nur unter einer Nummer, zu der
  es noch keine Datei gibt, sonst nimmt es die nächste. Das verringert einen Zusammenstoß, schließt
  ihn aber nicht aus, wenn beide im selben Augenblick anlegen; zwei Fenster gleichzeitig sind kein
  Fall für dieses Feature. Spielen beide Fenster dasselbe Spiel, gilt das letzte Speichern.
- **Geänderter Ereigniskatalog**: Klaus ändert nach dem Speichern den Katalog in der Werkstatt,
  etwa die Chance von „Konkurrent eröffnet“. Ein gespeichertes Spiel läuft mit seinem eigenen
  Katalog weiter, als wäre nichts geändert; erst ein neues Spiel nutzt den geänderten (FR-022).
- **Spielstand mit fehlerhaftem eigenem Katalog**: Enthält die Kopie Ereignisse mit Fehlern,
  gelten dieselben Regeln wie beim Katalog des Spiels: Die fehlerhaften fallen weg, der Rest
  läuft (Feature 002, FR-049). Ist die Kopie gar nicht lesbar, gilt der Spielstand als
  beschädigt.
- **Ende der Spielzeit**: Ein Spiel, das am 31.12.1999 steht, lässt sich fortsetzen; es läuft
  dann nicht weiter. Was danach kommt, regelt 11-05 Spielziel.
- **Ordner der Spielstände fehlt**: Er wird beim ersten Speichern angelegt; bis dahin gibt es
  einfach keine Spielstände.
- **Fremde Dateien im Ordner**: Dateien, die keine Spielstände sind, erscheinen nicht in der Liste
  und werden nie gelöscht.
- **Neues Spiel bei vorhandenen Spielständen**: Ein neues Spiel legt einen weiteren Spielstand an
  und überschreibt keinen vorhandenen.

## Requirements *(mandatory)*

### Functional Requirements

**Hauptmenü**

- **FR-001**: Das Hauptmenü muss genau diese Einträge in dieser Reihenfolge haben:
  „Weiterspielen“, „Neues Spiel“, „Spiel laden“, „Einstellungen“, „Beenden“. Das ändert FR-006
  von Feature 001. „Weiterspielen“ setzt das zuletzt gespielte, fortsetzbare Spiel fort. „Spiel
  laden“ zeigt die Liste aller Spielstände; dort wird fortgesetzt und gelöscht.
- **FR-001a**: Beim Erscheinen des Titelbildschirms muss „Weiterspielen“ vorgewählt sein, wenn es
  einen fortsetzbaren Spielstand gibt, sonst „Neues Spiel“. Das ändert FR-010 von Feature 001.
- **FR-002**: Einträge, die nichts zu tun haben, müssen wie in Feature 001 sichtbar, als nicht
  verfügbar erkennbar und mit einem Hinweis versehen sein, der den Grund nennt: „Weiterspielen“,
  solange es keinen fortsetzbaren Spielstand gibt, „Spiel laden“, solange es gar keinen gibt.
  Auch nur beschädigte Spielstände machen „Spiel laden“ verfügbar, damit man sie löschen kann.
  „Einstellungen“ bleibt nicht verfügbar.
- **FR-003**: Solange der Spieler kein Spiel begonnen oder fortgesetzt hat, darf kein Spiel laufen:
  Die Zeitleiste startet nicht mehr von selbst, und es entsteht kein Spielstand.

**Neues Spiel**

- **FR-004**: „Neues Spiel“ muss eine Wahl des Schwierigkeitsgrads zeigen: Leicht, Mittel und
  Schwer, in dieser Reihenfolge, vorgewählt Mittel. Zu jedem Grad gibt es einen Satz, der nur
  verspricht, was der Grad tut (heute: Ereignisse kommen öfter oder seltener), trocken im Ton des
  Abschnitts „Sprache“ im Style-Guide. Der Hinweis der gewählten Zeile nennt den Satz zu ihrem
  Grad; weil Mittel vorgewählt ist, steht sein Satz sofort da. Die Sätze schlägt der Plan vor,
  Klaus entscheidet sie.
- **FR-005**: Die Wahl muss sich bestätigen und abbrechen lassen, mit Maus und Tastatur wie das
  Hauptmenü. Abbrechen über „Zurück“ oder Esc führt ohne Spielstand zurück ins Hauptmenü
  (FR-023).
- **FR-006**: Bestätigen muss ein Spiel mit dem gewählten Grad und einem gewürfelten Seed am
  01.01.1985 beginnen, es sofort als neuen Spielstand speichern und dann den Spielbildschirm
  zeigen.

**Spielstand**

- **FR-007**: Ein Spielstand muss mindestens festhalten: Formatversion, Name, Schwierigkeitsgrad,
  Seed, Spieldatum, wann er angelegt und wann zuletzt gespielt wurde, die Version des Spiels, die
  ihn zuletzt schrieb, den Ereigniskatalog des Spiels (FR-022) und die Eingriffe in die
  Zeitleiste, damit der Fahrplan beim Fortsetzen derselbe ist. Spätere Features wie Wirtschaft
  und Laden fügen ihre Daten hinzu.
- **FR-008**: Aus einem Spielstand muss beim Fortsetzen derselbe Spielverlauf entstehen wie ohne
  Unterbrechung: gleiches Datum, gleicher Grad, gleicher Seed und ab dem Spieldatum dieselben
  Meldungen der Zeitleiste an denselben Tagen.
- **FR-009**: Es muss beliebig viele Spielstände nebeneinander geben können; ein neues Spiel
  überschreibt nie einen vorhandenen. Jeder Spielstand heißt automatisch „Spiel N“, wobei N um
  eins größer ist als die größte Nummer unter den vorhandenen Spielständen; ohne Spielstände ist
  es „Spiel 1“. Beispiel: Es gibt „Spiel 1“ und „Spiel 3“, das nächste heißt „Spiel 4“.
- **FR-010**: Das Spiel muss automatisch speichern: beim Anlegen, beim Fortsetzen, beim Verlassen
  über den Knopf „Zum Hauptmenü“ und beim Beenden der App, auch mit Cmd+Q und dem Schließen des
  Fensters. Ein eigenes „Speichern“ zum Anklicken gibt es nicht.
- **FR-011**: Speichern muss so geschehen, dass ein Abbruch mittendrin den vorigen Stand lesbar
  lässt. Scheitert das Speichern, erfährt der Spieler es mit einer Meldung, und das Spiel läuft
  weiter. Die Meldung steht an der Stelle des Hinweises, bis der Spieler etwas anderes wählt oder
  auslöst; wie sie aussieht, regelt der Style-Guide.
- **FR-012**: Spielstände müssen im Benutzerordner des Spiels liegen, nicht im Spielprojekt, und
  Updates des Spiels überstehen.
- **FR-013**: Ein Spielstand, der sich nicht lesen lässt, dessen Formatversion neuer ist als die
  des Spiels oder dessen Werte außerhalb ihres Bereichs liegen, muss in der Liste mit Grund als
  nicht fortsetzbar erscheinen, sich löschen lassen und darf nie überschrieben werden.
- **FR-014**: Ein Spielstand mit einer älteren, bekannten Formatversion muss sich fortsetzen
  lassen. Beim nächsten Speichern wird er in die aktuelle Formatversion gebracht. (Mit diesem
  Feature gibt es nur Formatversion 1; die Regel gilt für spätere Features.)
- **FR-022**: Ein Spielstand muss den Ereigniskatalog, mit dem das Spiel begann, samt den Profilen
  der Grade mitführen und beim Fortsetzen damit weiterlaufen. Änderungen am Katalog in der
  Werkstatt wirken nur auf neue Spiele.

**Fortsetzen und Liste**

- **FR-015**: Die Liste der Spielstände muss je Spielstand Name, Grad, Spieldatum und „zuletzt
  gespielt“ zeigen, geordnet nach „zuletzt gespielt“, das jüngste oben. Nicht fortsetzbare
  Spielstände stehen darunter, nach Nummer absteigend. „Zuletzt gespielt“ ist die Ortszeit des
  Rechners, in der Liste etwa „26.10.2026 21:40“. Der Hinweis der Zeile nennt Spieldatum und
  „zuletzt gespielt“ ausgeschrieben: „Steht am 13.07.1985. Gespielt am 26.10.2026, 21:40 Uhr.“
  (Klaus, 2026-10-26, Phasenprüfung Phase 5). Passen nicht alle Spielstände aufs Blatt, rollt die Liste mit der
  Auswahl und dem Mausrad; „Löschen …“ und „Zurück“ bleiben immer zu sehen.
- **FR-016**: Einen Spielstand fortsetzen muss ihn mit gespeichertem Datum, Grad und Seed zum
  laufenden Spiel machen, den Spielbildschirm zeigen und „zuletzt gespielt“ auf jetzt setzen.

**Löschen**

- **FR-017**: Löschen muss vorher nachfragen. Die Rückfrage nennt Name, Grad und Spieldatum, bei
  einem nicht fortsetzbaren Spielstand statt Grad und Spieldatum seinen Zustand, etwa „beschädigt“.
  Vorgewählt ist „Abbrechen“; Esc bricht ab. Erst die Bestätigung löscht den Spielstand
  endgültig.
- **FR-017a**: Gelöscht wird über den Eintrag „Löschen …“ unter den Spielständen der Liste, vor
  „Zurück“. Er schaltet die Liste in einen Löschmodus, erkennbar an der geänderten Kopfzeile;
  im Hinweis jeder Zeile steht dann, dass sie gelöscht wird. Die gewählte Zeile führt zur
  Rückfrage (FR-017). Der Modus endet nach dem Löschen, nach Abbrechen in der Rückfrage, mit
  „Zurück“ und mit Esc; danach setzt eine Zeile wieder fort. Im Löschmodus lassen sich auch
  nicht fortsetzbare Spielstände wählen. „Löschen …“ selbst ist im Löschmodus nicht verfügbar; sein
  Hinweis sagt, wie es weitergeht. Ist nach dem Löschen kein Spielstand mehr übrig, führt das Spiel
  von selbst ins Hauptmenü.
- **FR-018**: Löschen darf nur den gewählten Spielstand entfernen, samt den Zwischendateien, die
  beim Speichern zu ihm entstehen, und keine anderen Dateien.

**Spielbildschirm**

- **FR-019**: Der Spielbildschirm darf leer sein bis auf den Knopf „Zum Hauptmenü“. Die Uhr steht;
  das Spiel bleibt an seinem Datum. Eine sichtbare Uhr, Tempo und Pause kommen mit einem späteren
  Feature.
- **FR-020**: Der Spielbildschirm muss einen Knopf „Zum Hauptmenü“ haben. Er speichert ohne
  Rückfrage und führt ins Hauptmenü. Mit Maus und Tastatur bedienbar, mit Hinweis wie die
  Einträge des Hauptmenüs. Esc löst nichts aus, damit niemand versehentlich das Spiel verlässt.

**Gestaltung und Text**

- **FR-021**: Alle neuen Bildschirme und Texte müssen dem Style-Guide folgen, den Spieler duzen und
  mit Maus und Tastatur bedienbar sein wie das Hauptmenü aus Feature 001. Was der Style-Guide für
  einen neuen Baustein, etwa die Liste der Spielstände oder die Rückfrage, noch nicht regelt, kommt
  vor dem Bauen in den Style-Guide (Verfassung, Grundsatz IV).
- **FR-023**: Die Wahl des Grads, die Liste der Spielstände und die Rückfrage beim Löschen müssen
  auf dem Titelbildschirm erscheinen: Titelbild, Logo und Versionszeile bleiben, an der Stelle des
  Hauptmenüs steht ein eigenes Blatt Endlospapier mit Kopfzeile, etwa „SCHWIERIGKEIT“ und
  „SPIELSTÄNDE“. Jedes Blatt hat einen Eintrag, der eine Ebene zurückführt: „Zurück“, in der
  Rückfrage „Abbrechen“ (FR-017). Er und Esc führen aus der Liste und der Gradwahl ins Hauptmenü,
  aus der Rückfrage in die Liste; im Löschmodus beenden beide nur den Modus (FR-017a). Im Hauptmenü
  selbst tut Esc nichts, wie in Feature 001. Ob ein Blatt dafür breiter sein darf als das Hauptmenü,
  regelt der Style-Guide.

### Key Entities *(include if feature involves data)*

- **Spielstand**: ein Spiel, das sich fortsetzen lässt. Formatversion, Name, Grad, Seed, Spieldatum,
  angelegt am, zuletzt gespielt am, Spielversion, Eingriffe in die Zeitleiste und der eigene
  Ereigniskatalog; später mehr. Beispiel: „Spiel 2, Schwer, 14.03.1986, zuletzt gespielt 26.10.2026
  21:40“.
- **Liste der Spielstände**: alle Spielstände im Ordner, lesbare und nicht lesbare, je mit dem, was
  sich anzeigen lässt, und dem Grund, wenn einer nicht fortsetzbar ist.
- **Laufendes Spiel**: das Spiel auf dem Spielbildschirm; gehört genau zu einem Spielstand, in den
  es beim Verlassen gespeichert wird.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Vom Hauptmenü bis zum Spielbildschirm eines neuen Spiels braucht der Spieler mit der
  Tastatur höchstens 3 Eingaben, mit Vorgabe Mittel.
- **SC-002**: „Weiterspielen“ bringt den Spieler vom Titelbildschirm mit 1 Eingabe auf den
  Spielbildschirm; über „Spiel laden“ braucht er mit der Maus 2 Klicks, mit der Tastatur
  höchstens 4 Eingaben. Auf dem Entwicklungsrechner erscheint die Liste mit 20 Spielständen, je mit
  einem Katalog von 500 Ereignissen, in höchstens 1 Sekunde, und ein Spielstand vom 31.12.1999 ist
  in höchstens 1 Sekunde fortgesetzt.
- **SC-003**: Für die Seeds 1, 4711 und 99999 in allen drei Graden gilt: Ein Spiel, das am
  14.03.1986 gespeichert, neu geöffnet und bis zum 31.12.1999 gespielt wird, meldet dieselben
  Ereignisse an denselben Tagen wie ein Spiel, das ohne Pause durchläuft.
- **SC-004**: Keiner der Fehlerfälle aus den Edge Cases, also beschädigt, zu neu, unbekannter
  Grad, Seed außerhalb, Speichern scheitert, lässt das Spiel abstürzen oder einen Spielstand
  verloren gehen; jeder ist durch einen automatischen Test belegt.
- **SC-005**: Nach dem Verlassen eines Spiels steht im Spielstand das Datum, an dem das Spiel
  stand, auf den Tag genau; ein automatischer Test belegt das für den 01.01.1985, einen Tag im
  Februar 1985, den 14.03.1986 und den 31.12.1999.
- **SC-006**: Die Startprobe bleibt still, und ohne Spielstände sieht der Titelbildschirm aus wie
  in Feature 001, bis auf Einträge, Hinweise und Höhe des Menüs.

## Assumptions

- Gespielt wird am Desktop mit Maus und Tastatur unter Windows, macOS und Linux (Verfassung,
  Grundsatz I).
- Ein Spiel beginnt immer am 01.01.1985. Ein späteres Startdatum, das 01-05 vormerkt, ist nicht
  Teil dieses Features.
- Der Seed wird gewürfelt; der Spieler sieht und wählt ihn nicht. Einen Seed vorgeben geht weiter
  in der Werkstatt und in Tests.
- Der Grad wirkt in diesem Feature nur auf die Zeitleiste (Feature 003). Was er an Wirtschaft,
  Startkapital oder Kunden ändert, gehört zu 11-05; dann werden auch die Sätze zu den Graden
  angepasst (FR-004).
- Der Grad lässt sich nach dem Beginn nicht mehr ändern.
- Der Spielbildschirm bekommt erst mit späteren Features Inhalt, etwa Laden, Zeitung oder den
  Communicator aus der Ideensammlung. Mit ihnen kommen auch die sichtbare Uhr, Tempo und Pause.
- Speichern während des Spiels, etwa monatlich, ist nicht nötig, solange die Uhr steht; spätere
  Features können es dazunehmen.
- Ein Spielstand gehört zu einem Benutzer auf einem Rechner. Spielstände zwischen Rechnern
  übertragen, in der Cloud sichern oder exportieren ist nicht Teil des Features.
- Die Werkstatt und ihre Proben bleiben, wie sie sind. Die Proben halten wie ein Spielstand Seed,
  Grad und Eingriffe; der Plan prüft, was sich teilen lässt.
- Den Ereigniskatalog liest das Spiel beim Start; eine Änderung aus der Werkstatt gilt für neue
  Spiele nach dem nächsten Start.
- Ein Spielstand enthält nur Daten; eine von Hand veränderte Datei kann höchstens beschädigt sein,
  aber nichts ausführen.
- Die Uhr des Rechners geht richtig; „zuletzt gespielt“ steht so in der Liste, wie es gespeichert
  wurde.
- Geprüft ist die Liste mit bis zu 20 Spielständen (SC-002). Mehr sind erlaubt und dauern länger;
  eine Grenze gibt es nicht.
- Die automatischen Tests schreiben ihre Spielstände in einen eigenen Ordner, nie in den echten
  (`docs/ki_workflow/ki_dev.md`, „Tests“).
- Das Feature ist der Pilot der Prüf-Agents: Jede Phase mit Sichtbarem oder Texten endet mit der
  Phasenprüfung durch Stil- und Text-Prüfer vor Klaus' Abnahme (`docs/ki_workflow/ki_pruefung.md`).
