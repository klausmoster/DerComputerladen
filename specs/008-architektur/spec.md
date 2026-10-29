# Feature Specification: Godot- und Spielarchitektur mit Prüf-Agent

**Feature Branch**: `feature/008-architektur`

**System**: 11 Infrastruktur (Codebasis und Arbeitsweise); berührt alle Systeme, die Code haben

**Created**: 2026-10-28

**Status**: Draft

**Input**: User description: "Feature 008 ‚Godot- und Spielarchitektur mit Prüf-Agent' (Backlog
11-06). Klaus legt fest, nach welchen Godot-Prinzipien und nach den Mustern welcher Spiele ‚Der
Computerladen' gebaut wird. Ein neuer Prüf-Agent prüft Code dagegen, so wie heute `stil-pruefer`
und `text-pruefer` gegen den Style-Guide prüfen. Welche Spiele und Prinzipien gelten sollen, wird
mit Klaus geklärt."

## Clarifications

### Specify 2026-10-28

Fragen aus `/speckit-specify`, von Klaus einzeln als Auswahl beantwortet:

- Q: Woher kommen die Muster, gegen die der Prüfer den Code hält? → A: ein Musterkatalog und dazu
  Vorbilder je Schicht (Klaus, nach Empfehlung). Der Katalog ist Robert Nystroms Buch „Game
  Programming Patterns“, mit Mustern wie Beobachter, Zustand, Befehl und Typ-Objekt. Vorbilder für
  den Adventure-Teil sind SCUMM mit Monkey Island und Thimbleweed Park (Räume, anklickbare Stellen,
  Dialoge), für die Wirtschaft deterministische Simulationen wie Factorio. Verworfen: nur die
  deutschen Wirtschaftssimulationen der 90er („Das Amt“, „Der Patrizier“, „Pizza Connection“, „Mad
  TV“), weil ihr Innenleben kaum dokumentiert ist und der Prüfer so wenig Schriftliches hätte; keine
  Spiele, nur Godot, weil der Adventure- und der Wirtschaftsteil sonst ohne Vorbild beginnen. Die
  „Das Amt“-Linie bleibt Vorbild für Aufbau und Humor (Style-Guide), nicht für den Code.
- Q: Welche Godot-Prinzipien gelten? → A: alle fünf (Klaus, nach Empfehlung): Kern ohne Node;
  Signal nach oben, Aufruf nach unten; Autoloads sparsam; Daten als Resources; Szenen-Komposition.
  **Auslegung von Claude:** In der Auswahl stand „die vier unten und dazu Daten als Resources“,
  darunter standen aber nur drei. Als fünftes Prinzip hat Claude die Szenen-Komposition aus dem
  Auftrag eingesetzt: Eine Szene wird aus kleinen, eigenständigen Szenen zusammengesetzt, so wie
  der Titel den Communicator als fertigen Baustein einsetzt. Klaus hat das bei der Klärung
  bestätigt (unten, „Clarify 2026-10-28“).
- Q: Wo stehen die Regeln? → A: in einem eigenen Architektur-Leitfaden im Repo (Klaus, nach
  Empfehlung). Er ist für den neuen Prüfer, was der Style-Guide für den Stil-Prüfer ist; weil er im
  Repo liegt, liest der Prüfer ihn selbst. In die Verfassung kommt höchstens ein Verweis, und den
  beschließt Klaus. Verworfen: ein Abschnitt in der Verfassung, weil jede neue Regel dann einen
  Versionssprung bräuchte; ein Ausbau von `docs/spielbeschreibung/architektur.md`, weil die den
  Stand im Code beschreibt, nicht was gelten soll.
- Q: Wann prüft der Prüfer? → A: zweimal je Feature (Klaus, nach Empfehlung): beim Plan liest er
  den Entwurf, bevor gebaut wird, und danach jede Phase, die Code oder Szenen ändert, in der
  Phasenprüfung neben Stil und Text. Verworfen: nur Code-Phasen, weil ein Fehler im Plan dann erst
  gebaut auffällt; nur vor dem Merge, weil ein Umbau dann schon teuer ist.
- Q: Prüft er den bestehenden Code nach? → A: ja, mit Reparatur (Klaus, gegen die Empfehlung „nur
  Bericht“). Ein Lauf über das ganze Spiel ergibt einen Bericht; die bestätigten Abweichungen, die
  Klaus freigibt, behebt der Godot-Agent in einer eigenen Phase. Verworfen: nur Bericht; gar keine
  Nachprüfung.

### Clarify 2026-10-28

Fragen aus `/speckit-clarify`, von Klaus einzeln als Auswahl beantwortet:

- Q: Wird Grundsatz VI der Verfassung erweitert, so dass er Code-Phasen und den Leitfaden nennt? →
  A: ja, in 008 (Klaus, nach Empfehlung). Den Wortlaut beschließt Klaus über
  `/speckit-constitution`, sobald der Leitfaden steht, als MINOR-Sprung auf 2.3.0. Verworfen: die
  Regel nur in der Arbeitsweise und die Verfassung erst nach dem Nachmessen, weil
  `/speckit-analyze` sonst bei jedem Feature einen Widerspruch zu Grundsatz VI meldet und der
  Prüfer keine Pflicht wäre.
- Q: Gilt als fünftes Prinzip die Szenen-Komposition? → A: ja (Klaus, nach Empfehlung). Verworfen:
  nur die vier übrigen Prinzipien.
- Q: An welcher Stelle liest der Prüfer den Plan? → A: bei `/speckit-checklist`, zusammen mit Stil-
  und Text-Prüfer, die dort schon Wortlaute und Zustände aus dem Vertrag lesen (Klaus, nach
  Empfehlung). Verworfen: am Ende von `/speckit-plan` im Constitution Check, weil es ein eigener
  Zeitpunkt nur für diesen Prüfer wäre.
- Q: Wie weit geht die Behebung im Bestand? → A: In 008 wird behoben, was ein System betrifft und
  das Verhalten nicht ändert; was mehrere Systeme umbaut, wird ein eigenes Feature in
  `Feature_Ideas.md` (Klaus, nach Empfehlung). Verworfen: alles Freigegebene in 008, weil der
  Umfang erst nach dem Bericht feststeht und 008 unbegrenzt wachsen könnte; eine feste Grenze von
  einer Phase, weil sie auch kleine Behebungen hinauswerfen kann.
- Q: Werden die messbaren Regeln schon in 008 Tests? → A: ja, mit Fehlerprobe (Klaus, nach
  Empfehlung). Beispiele: Kein Kern erbt von einem Node; es gibt genau die Autoloads, die der
  Leitfaden nennt. Verworfen: nur vermerken und später bauen, weil der Prüfer dann Messbares
  prüfen müsste (`ki_pruefung.md`, Grundsatz 4).

### Review 2026-10-28

Aus `checklists/review.md`, 19 Punkte, von Klaus am 2026-10-28 alle nach Vorschlag freigegeben. Die
wichtigsten für die Spec:
- Story 2 prüft einen Verstoß, den kein Test misst; das Autoload ohne Grund gehört zur Planprüfung
  in Story 3 (CHK001).
- „Code“ heißt Skripte, Szenen und Resources des Spiels und der Werkzeuge unter `src/`; Tests lösen
  den Architektur-Prüfer nicht aus (CHK002).
- Die Prüfung eines Plans wird in Phase 2 am Plan von 006 erprobt (CHK005).
- Die Bestandsprüfung umfasst auch Resources und `project.godot` (CHK007) und den Code von 007, wenn
  er bis dahin gemergt ist (CHK008); die Behebung beginnt erst, wenn 007 im Branch ist (CHK019).
- „Ein System“ heißt ein Ordner ohne geänderte Schnittstelle nach außen (CHK012).
- SC-002, SC-005, SC-006 und SC-007 sind genauer gefasst (CHK004, CHK006, CHK016).
Alle Punkte stehen in plan.md, „Änderungen nach der Checkliste“.

### Analyse 2026-10-28

Aus `/speckit-analyze`, gelesen von einem unabhängigen Prüfer: 18 Befunde, keiner kritisch; Claude
hat jeden nachgeprüft, Klaus hat am 2026-10-28 alle Empfehlungen freigegeben. Für die Spec:
- Der Selbsttest aus Feature 007 unter `src/tools/selbsttest/` zählt als Werkzeug: Der Prüfer
  prüft ihn, die Bestandsprüfung umfasst ihn, und er ist ein eigener Ordner im Sinne von FR-027
  (I1).
- 007 ändert dieselben Dateien der Arbeitsweise wie 008; vor Phase 2 wird nach seinem Stand gesehen
  (I2).
- Eine begründete Ausnahme ohne Skript braucht nur die Zeile in der Tabelle (I3, wie CHK010).
- FR-021 nennt die Stellen, die den Prüfer einplanen; eine eigene Plan-Vorlage gibt es nicht (C6).
- SC-005 erlaubt die Teil-Wiederholungen der Bestandsprüfung (I8).
Alle Befunde stehen in plan.md, „Änderungen nach der Analyse“.

## Begriffe

- **Architektur:** wie der Code aufgeteilt ist und wer wen kennt, nicht was er tut. Beispiel: Dass
  die Zeitleiste ein Ereignis meldet und die Wirtschaft es später hört, statt dass die Zeitleiste
  Preise selbst ändert, ist eine Architektur-Entscheidung.
- **Architektur-Leitfaden (kurz: Leitfaden):** das Dokument mit allen Regeln, gegen die geprüft
  wird. Der Maßstab des Architektur-Prüfers.
- **Regel:** eine Aussage im Leitfaden, die sich an einer Stelle im Code als eingehalten oder
  verletzt erkennen lässt, mit Grund, Beispiel und Quelle. Beispiel: „Ein Baustein kennt den, der
  ihn einsetzt, nicht; er meldet per Signal.“
- **Godot-Prinzip:** eine Regel, die aus der Arbeitsweise von Godot folgt, etwa „Signal nach oben,
  Aufruf nach unten“.
- **Muster:** eine bewährte Lösung für ein wiederkehrendes Problem aus dem Musterkatalog, etwa
  „Zustand“: Ein Kunde im Laden ist mal „schaut sich um“, mal „wartet an der Theke“, mal „geht“,
  und jeder Zustand hat sein eigenes Verhalten.
- **Vorbild:** ein Spiel, dessen bekannter Aufbau für eine Schicht unseres Spiels übernommen wird,
  mit dem, was wir übernehmen und was nicht.
- **Schicht:** ein Teil des Spiels mit eigenem Vorbild: Kern (Logik ohne Darstellung), Oberfläche,
  Adventure (Orte, anklickbare Stellen, Dialoge), Wirtschaft (Simulation mit Takt).
- **Architektur-Prüfer (kurz: Prüfer):** ein Prüf-Agent, der nur liest und Code, Szenen und Pläne
  gegen den Leitfaden prüft.
- **Befund:** eine Stelle, an der der Code oder der Plan eine Regel verletzt, mit Ort, Regel, Beleg
  und Schwere.
- **Lücke im Leitfaden:** eine Frage zur Architektur, die der Leitfaden nicht beantwortet.
  Entscheidet Klaus.
- **Begründete Ausnahme:** eine Stelle, die eine Regel bewusst verletzt, mit Grund an der Stelle und
  einer Zeile in der Tabelle „Ausnahmen“ des Leitfadens; hat die Stelle kein Skript, reicht die Zeile.
  Im Plan steht eine geplante Ausnahme unter „Ausnahmen vom Leitfaden“. Kein Befund.
- **Bestandsprüfung:** der einmalige Lauf des Prüfers über den Code, der vor dem Leitfaden
  entstanden ist.
- **Abweichung:** ein Befund aus der Bestandsprüfung, also im alten Code.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Klaus legt die Architektur fest (Priority: P1)

Klaus liest einen Leitfaden, der für jedes der fünf Godot-Prinzipien, für die Muster aus dem
Katalog, die das Spiel braucht, und für jede Schicht mit ihrem Vorbild sagt, was gilt, warum und
wo man es im eigenen Code sieht. Er entscheidet jede Regel einzeln: übernehmen, ändern oder
streichen. Am Ende steht ein Maßstab, nach dem gebaut und geprüft wird.

**Why this priority**: Ohne schriftlichen Maßstab urteilt ein Prüfer nach Geschmack
(`ki_pruefung.md`, Grundsatz 2). Der Leitfaden ist die Voraussetzung für alles andere und hat auch
ohne Prüfer Wert: Spec, Plan und der Godot-Agent können sich daran halten.

**Independent Test**: Den Leitfaden lesen. Jede Regel hat Aussage, Grund, Beispiel aus dem
eigenen Code oder ein ausgedachtes Beispiel aus dem Spiel, Quelle und Klaus' Entscheidung mit
Datum. Wer nur den Leitfaden kennt, kann bei einer vorgelegten Stelle sagen, ob sie eine Regel
verletzt.

**Acceptance Scenarios**:

1. **Given** der Leitfaden, **When** Klaus das Prinzip „Signal nach oben, Aufruf nach unten“ sucht,
   **Then** findet er die Regel mit Grund, einem Beispiel aus dem Code (der Communicator meldet
   Gehäusetasten und kennt den Titel nicht) und einer Quelle.
2. **Given** der Leitfaden, **When** Klaus die Schicht Adventure liest, **Then** steht dort das
   Vorbild SCUMM mit Thimbleweed Park, was davon übernommen wird und was nicht, und dass die Regeln
   erst mit dem ersten Feature dieser Schicht am Code geprüft werden können.
3. **Given** eine Regel, die Klaus streicht, **When** der Leitfaden fertig ist, **Then** steht sie
   nicht als gültige Regel darin, und die Streichung ist mit Grund und Datum festgehalten.
4. **Given** eine Regel, die sich messen lässt, etwa „ein Kern erbt nicht von einem Node“, **When**
   der Leitfaden fertig ist, **Then** ist sie als Test vermerkt und nicht als Aufgabe des Prüfers.

---

### User Story 2 - Der Prüfer prüft eine Code-Phase (Priority: P1)

Der Godot-Agent hat eine Phase gebaut, die Code oder Szenen ändert. In der Phasenprüfung startet
Claude neben Stil- und Text-Prüfer den Architektur-Prüfer. Er liest den Leitfaden und die
geänderten Dateien und meldet jeden Befund mit Ort, Regel, Beleg und Schwere, dazu die Lücken im
Leitfaden. Claude prüft jeden Befund nach, bevor Klaus ihn sieht.

**Why this priority**: Das ist der eigentliche Zweck des Features: Abweichungen fallen auf, bevor
sie sich über mehrere Features ausbreiten. Gleiche Priorität wie Story 1, denn ein Leitfaden, den
niemand prüft, veraltet still.

**Independent Test**: Eine Fehlerprobe: kleine Probedateien außerhalb des Spiels mit je einem
absichtlichen Verstoß gegen jedes Godot-Prinzip, etwa einem Baustein, der den, der ihn einsetzt,
direkt aufruft. Der Prüfer
findet sie, ohne die erlaubten Stellen daneben als Befund zu melden.

**Acceptance Scenarios**:

1. **Given** eine Phase, in der ein Baustein den, der ihn einsetzt, direkt aufruft, **When** der
   Prüfer sie prüft, **Then** meldet er einen Befund zur Regel „Signal nach oben, Aufruf nach
   unten“ mit Ort und Beleg.
2. **Given** eine Phase, deren Code alle Regeln einhält, **When** der Prüfer sie prüft, **Then**
   schreibt er „keine Befunde“ und welche Regeln er geprüft hat.
3. **Given** eine Stelle, die eine Regel bewusst verletzt und den Grund nennt, **When** der Prüfer
   sie sieht, **Then** führt er sie als begründete Ausnahme auf, nicht als Befund.
4. **Given** eine Frage, die der Leitfaden nicht regelt, etwa wie ein Dialog seine Texte bekommt,
   **When** der Prüfer darauf stößt, **Then** meldet er eine Lücke im Leitfaden, keinen Fehler.
5. **Given** eine Phase, die nur Dokumente, Bilder oder Tests ändert, **When** Claude die
   Phasenprüfung plant, **Then** läuft der Architektur-Prüfer nicht.
6. **Given** der Prüfer, **When** er arbeitet, **Then** ändert er keine Datei.

---

### User Story 3 - Der Prüfer liest den Plan (Priority: P2)

Ein neues Feature hat seinen Plan: welche Systeme, welche Bausteine, wer wen kennt, welche Signale.
Bevor gebaut wird, liest der Prüfer den Plan gegen den Leitfaden. So fällt etwa ein überflüssiges
Autoload oder ein Kern, der eine Szene braucht, auf, bevor der Agent es baut.

**Why this priority**: Ein Fehler im Plan kostet vor dem Bau eine Zeile, danach eine Phase. Er
setzt Story 1 und 2 voraus und lohnt sich erst beim nächsten Feature mit Code.

**Independent Test**: Den Plan eines fertigen Features, etwa 006, dem Prüfer vorlegen, als wäre er
neu. Er liefert einen Bericht in derselben Form wie bei einer Phase.

**Acceptance Scenarios**:

1. **Given** ein Plan, der eine Wirtschaftslogik in eine Szene legt, **When** der Prüfer ihn liest,
   **Then** meldet er einen Befund zur Regel „Kern ohne Node“, mit dem Abschnitt im Plan als Ort.
2. **Given** ein Plan, der ein neues Autoload vorsieht, ohne es zu begründen, **When** der Prüfer
   ihn liest, **Then** meldet er einen Befund zur Regel „Autoloads sparsam“, bevor es gebaut ist.
3. **Given** der Ablauf eines Features, **When** der Plan steht, **Then** ist die Prüfung des Plans
   ein fester Schritt, bevor die Aufgaben entstehen.

---

### User Story 4 - Bestandsprüfung des vorhandenen Codes (Priority: P2)

Der Code aus den Features 001 bis 006 entstand vor dem Leitfaden. Der Prüfer läuft einmal über das
ganze Spiel und die Werkstatt und schreibt einen Bericht: welche Stellen von welcher Regel
abweichen, welche Ausnahmen begründet sind und welche Lücken der Leitfaden hat. Claude prüft jede
Abweichung nach. Klaus entscheidet je Abweichung: beheben, als Ausnahme festhalten oder die Regel
ändern.

**Why this priority**: Der Lauf ist zugleich der Probelauf des Prüfers, wie es der Stil-Prüfer an
Feature 001 hatte. Er zeigt, ob der Prüfer etwas taugt, und schärft den Leitfaden an echtem Code.

**Independent Test**: Der Bericht nennt jede geprüfte Datei und je Abweichung Ort, Regel, Beleg,
Schwere und Claudes Urteil (bestätigt oder verworfen, mit Grund).

**Acceptance Scenarios**:

1. **Given** der fertige Leitfaden, **When** der Prüfer den Bestand prüft, **Then** deckt der
   Bericht jedes Skript, jede Szene und jede Resource des Spiels und der Werkstatt ab, dazu
   `project.godot`, ohne fremde Bibliotheken und ohne Tests.
2. **Given** eine bestätigte Abweichung, **When** Klaus sie liest, **Then** kann er sie zum Beheben
   freigeben, als begründete Ausnahme festhalten oder die Regel ändern lassen.
3. **Given** eine Abweichung, deren Behebung groß ist, etwa ein Umbau über mehrere Systeme, **When**
   Klaus entscheidet, **Then** kann er sie als eigenes Feature vormerken statt in 008 zu beheben.

---

### User Story 5 - Bestätigte Abweichungen beheben (Priority: P3)

Die Abweichungen, die Klaus zum Beheben freigibt, behebt der Godot-Agent in einer eigenen Phase.
Das Spiel verhält sich danach genau wie vorher; nur der Aufbau des Codes ändert sich. Der Prüfer
prüft das Geänderte noch einmal.

**Why this priority**: Klaus will den Bestand an den Leitfaden angleichen, damit neue Features auf
einem einheitlichen Aufbau beginnen. Der Umfang steht aber erst nach dem Bericht fest.

**Independent Test**: Vor und nach der Phase dieselben Prüfungen: alle Tests grün, die Startprobe
still, Fahrpläne bytegleich, Titel, Spielstände und Easter Egg wie vorher bedienbar.

**Acceptance Scenarios**:

1. **Given** eine freigegebene Abweichung, **When** der Agent sie behoben hat, **Then** meldet der
   Prüfer an dieser Stelle keinen Befund mehr.
2. **Given** die Phase ist fertig, **When** Claude prüft, **Then** laufen alle Tests zweimal grün,
   die Startprobe ist still, und der Fahrplan ist für die Seeds 1, 4711 und 99999 bytegleich mit
   vorher.
3. **Given** ein vorhandener Spielstand von vor der Phase, **When** Klaus ihn fortsetzt, **Then**
   lädt er wie vorher.

---

### Edge Cases

- **Leitfaden und Verfassung widersprechen sich:** Die Verfassung gilt. Der Prüfer meldet den
  Widerspruch als Lücke im Leitfaden, Klaus entscheidet.
- **Leitfaden und Godot-Doku widersprechen sich**, etwa wenn die Doku ein Autoload empfiehlt, wo der
  Leitfaden es verbietet: Der Leitfaden gilt, sein Grund steht bei der Regel.
- **Alter Code außerhalb des Diffs:** In einer Phasenprüfung prüft der Prüfer nur, was die Phase
  ändert. Fällt ihm eine Abweichung daneben auf, nennt er sie unter „Unsicher“, nicht als Befund
  der Phase.
- **Regeln für Schichten, die es noch nicht gibt** (Adventure, Wirtschaft): Sie stehen im
  Leitfaden, werden aber erst mit dem ersten Feature der Schicht geprüft. Bis dahin meldet der
  Prüfer zu ihnen nichts.
- **Werkzeuge:** Für die Werkstatt gelten dieselben Regeln, auch wenn sie nicht im Export ist.
  Ausnahmen, die nur für Werkzeuge gelten, stehen im Leitfaden.
- **Tests und fremde Bibliotheken:** Tests prüft der Prüfer nur darauf, ob sie Kerne ohne Szene
  testen können; fremde Bibliotheken wie das Test-Werkzeug prüft er nicht.
- **Eine Phase ändert Code und Sichtbares:** Alle drei Prüfer laufen gleichzeitig, ein gemeinsamer
  Bericht.
- **Der Prüfer steht in einer Sitzung nicht bereit:** Claude nimmt einen allgemeinen Agent, der
  zuerst die Datei des Prüfers liest und ausdrücklich nur liest (`ki_pruefung.md`, „Die Prüfer“).
- **Zwei Prüfer urteilen über dieselbe Stelle**, etwa der Stil-Prüfer über einen Baustein und der
  Architektur-Prüfer über dessen Aufbau: Der Stil-Prüfer urteilt, wie es aussieht, der
  Architektur-Prüfer, wie es gebaut ist; keine Regel steht in beiden Maßstäben.
- **Eine Behebung ändert Verhalten:** Dann ist sie keine Behebung im Sinne von Story 5, sondern
  geht als Frage an Klaus zurück.

## Requirements *(mandatory)*

### Functional Requirements

**Leitfaden**

- **FR-001**: Es MUSS einen Architektur-Leitfaden geben, der im Repo liegt und den der Prüfer selbst
  lesen kann.
- **FR-002**: Der Leitfaden MUSS die fünf Godot-Prinzipien als Regeln enthalten: Kern ohne Node;
  Signal nach oben, Aufruf nach unten; Autoloads sparsam; Daten als Resources;
  Szenen-Komposition.
- **FR-003**: Der Leitfaden MUSS die Muster aus „Game Programming Patterns“ enthalten, die das
  Spiel heute nutzt oder für ein vorgemerktes System braucht, je mit der Stelle oder dem System,
  wo es gilt. Vorgemerkt ist ein System, das in `docs/features/Features.md` steht und Einträge in
  `docs/features/Feature_Ideas.md` hat. Muster ohne Bezug zum Spiel bleiben draußen.
- **FR-004**: Der Leitfaden MUSS je Schicht das Vorbild nennen und sagen, was übernommen wird und
  was nicht: Adventure nach SCUMM mit Monkey Island und Thimbleweed Park, Wirtschaft nach
  deterministischen Simulationen wie Factorio, Kern und Oberfläche nach den Godot-Prinzipien.
- **FR-005**: Jede Regel MUSS haben: Aussage, Grund, ein Beispiel (aus dem eigenen Code, sonst ein
  ausgedachtes aus dem Spiel), ein Gegenbeispiel, die Quelle, die Schicht, ob ein Test oder der
  Prüfer sie prüft, und Klaus' Entscheidung mit Datum.
- **FR-006**: Die Grundsätze, die heute in `docs/spielbeschreibung/architektur.md` und in der
  Verfassung stehen (etwa „Melden statt anwenden“, „Wiederholbar“), MÜSSEN im Leitfaden als Regeln
  aufgehen oder ausdrücklich auf ihre Quelle verweisen, ohne Widerspruch.
- **FR-007**: Jede Regel wird nur gültig, wenn Klaus sie entschieden hat. Gestrichene und geänderte
  Regeln bleiben mit altem Wortlaut, Grund und Datum sichtbar.
- **FR-008**: Regeln, die sich messen lassen, MÜSSEN als Test geprüft werden, nicht vom Prüfer
  (`ki_pruefung.md`, Grundsatz 4). Der Leitfaden nennt für jede solche Regel den Test. Die Tests
  entstehen in 008, jeder mit Fehlerprobe: Ein absichtlich eingebauter Verstoß lässt ihn rot werden.
- **FR-009**: Der Leitfaden MUSS sagen, wie eine begründete Ausnahme aussieht: wo der Grund steht
  und wer sie freigibt.

**Prüfer**

- **FR-010**: Es MUSS einen Architektur-Prüfer geben, der nur liest und keine Datei ändern kann.
- **FR-011**: Der Prüfer MUSS jeden Befund mit Ort, Regel (mit Wortlaut), Beleg und Schwere
  (kritisch, hoch, mittel, niedrig) melden, in derselben Form wie Stil- und Text-Prüfer. Was die
  Stufen heißen, steht in einer Tabelle im Vertrag des Prüfers und im Leitfaden.
- **FR-012**: Der Prüfer MUSS Lücken im Leitfaden als Lücke melden, nicht als Fehler, und
  begründete Ausnahmen als solche aufführen.
- **FR-013**: Der Prüfer MUSS, wenn er nichts findet, „keine Befunde“ schreiben und welche Regeln er
  geprüft hat.
- **FR-014**: Der Prüfer DARF NICHT nach Geschmack urteilen: Jeder Befund stützt sich auf eine Regel,
  die er zitieren kann.
- **FR-015**: Der Prüfer MUSS Code, Szenen und Pläne prüfen können. Ein Plan wird mit dem Abschnitt
  als Ort geprüft, Code mit Datei und Zeile oder Node.

**Wann geprüft wird**

- **FR-016**: Jede Phase, die Code ändert, MUSS vor Klaus' Abnahme vom Architektur-Prüfer geprüft
  werden, in derselben Phasenprüfung wie Stil und Text. Code heißt hier: Skripte, Szenen und
  Resources des Spiels und der Werkzeuge unter `src/`. Tests lösen den Prüfer nicht aus,
  `src/addons/` nie; Python-Werkzeuge unter `tools/` gehören nicht dazu.
- **FR-017**: Jeder Plan eines Features mit Code MUSS vom Prüfer gelesen werden, bevor die Aufgaben
  entstehen: bei `/speckit-checklist`, zusammen mit Stil- und Text-Prüfer. Er liest Plan und
  Vertrag, also wer wen kennt, Signale, Autoloads und Daten.
- **FR-018**: Claude MUSS jeden Befund nachprüfen (bestätigt oder verworfen, mit Grund), bevor Klaus
  ihn sieht. Bestätigte Befunde behebt der Godot-Agent; danach prüft der Prüfer das Geänderte noch
  einmal.
- **FR-019**: Phasen, die keinen Code im Sinne von FR-016 ändern, prüft der Architektur-Prüfer
  nicht.

**Arbeitsweise**

- **FR-020**: Die Arbeitsweise in `docs/ki_workflow/` MUSS den Architektur-Prüfer beschreiben:
  Maßstab, Zeitpunkte, Abgrenzung zu Claudes Prüfung und zu `/code-review`. Die bisherige Festlegung
  „kein eigener Code-Prüfer“ bleibt mit Datum sichtbar, mit dem Grund für die Änderung: Der neue
  Prüfer hat einen eigenen schriftlichen Maßstab.
- **FR-021**: Der Skill der Phasenprüfung, die Aufgaben-Vorlage, die Verfassung und
  `ki_pruefung.md` MÜSSEN den Architektur-Prüfer kennen, so dass er in jedem neuen Feature von selbst
  eingeplant wird. Eine eigene Plan-Vorlage gibt es nicht: Den Abschnitt „Prüfer je Phase“ schreibt
  Claude nach `ki_pruefung.md`, „Ausnahmen vom Leitfaden“ verlangt die Verfassung.
- **FR-022**: Der Godot-Agent MUSS den Leitfaden vor jeder Aufgabe lesen.
- **FR-023**: Grundsatz VI der Verfassung MUSS in 008 so erweitert werden, dass er Code-Phasen, den
  Architektur-Prüfer und den Leitfaden als Maßstab nennt. Den Wortlaut beschließt Klaus über
  `/speckit-constitution` (MINOR, 2.3.0). Ein Verweis in `CLAUDE.md` kommt nur auf seinen Beschluss.
- **FR-024**: Claude MUSS je Lauf des Prüfers zählen wie bei Stil und Text: gemeldet, bestätigt,
  verworfen, Lücken, nur er fand. Die Zahlen stehen in `ki_pruefung.md`.

**Bestand**

- **FR-025**: Der Prüfer MUSS einmal den ganzen vorhandenen Code des Spiels und der Werkstatt prüfen,
  also Skripte, Szenen, Resources und `project.godot`, ohne `addons/` und `test/`, und einen
  Bericht liefern, der jede geprüfte Datei nennt.
- **FR-026**: Claude MUSS jede Abweichung aus dem Bericht nachprüfen und Klaus je bestätigte
  Abweichung eine Empfehlung vorlegen: beheben, als begründete Ausnahme festhalten, Regel ändern
  oder als eigenes Feature vormerken, je mit Aufwand.
- **FR-027**: Abweichungen, die Klaus zum Beheben freigibt, MÜSSEN in einer eigenen Phase behoben
  werden, ohne das Verhalten des Spiels zu ändern. In 008 gehört dazu nur, was ein System betrifft;
  was mehrere Systeme umbaut, kommt als eigenes Feature nach `docs/features/Feature_Ideas.md`. Ein
  System betrifft eine Behebung, wenn sie nur Dateien in einem der Ordner `core/`, `scenes/title/`,
  `scenes/game/`, `ui/`, `tools/werkstatt/` oder `tools/selbsttest/` (aus Feature 007) ändert und keine Schnittstelle, die ein anderer
  Ordner nutzt: Signal, öffentliche Methode oder Autoload.
- **FR-028**: Nach der Behebung MÜSSEN alle Tests zweimal grün laufen, die Startprobe still sein, die
  Fahrpläne bytegleich bleiben und vorhandene Spielstände wie vorher laden. Belegt wird das an zwei
  Spielständen, die Claude vor der Phase anlegt und sichert.
- **FR-029**: Nach der Behebung MUSS `docs/spielbeschreibung/architektur.md` den neuen Stand
  beschreiben.

### Key Entities

- **Architektur-Leitfaden:** der Maßstab. Enthält Regeln, gegliedert nach Godot-Prinzipien, Mustern
  und Schichten, dazu die Liste der begründeten Ausnahmen und die Geschichte gestrichener Regeln.
- **Regel:** Aussage, Grund, Beispiel, Gegenbeispiel, Quelle, Schicht, Prüfweise (Test oder
  Prüfer), Entscheidung mit Datum.
- **Vorbild:** Spiel, Schicht, was übernommen wird, was nicht, Quelle.
- **Befund:** Ort, Regel, Beleg, Schwere, Claudes Urteil mit Grund.
- **Lücke im Leitfaden:** Frage, Ort, Empfehlung, Klaus' Entscheidung.
- **Begründete Ausnahme:** Ort, verletzte Regel, Grund, wer sie freigab.
- **Bestandsbericht:** geprüfte Dateien, Abweichungen, Ausnahmen, Lücken, Zählung.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Jede gültige Regel im Leitfaden hat alle Teile aus FR-005; keine fehlt.
- **SC-002**: In der Fehlerprobe mit einem eingebauten Verstoß je Godot-Prinzip findet der Prüfer
  alle fünf und meldet an den erlaubten Stellen daneben keinen Befund. Besteht er nicht, schärft
  Claude seine Anweisung nach und wiederholt die Probe höchstens zweimal; besteht er dann immer noch
  nicht, entscheidet Klaus, ob es mit Einschränkung weitergeht oder das Feature anhält.
- **SC-003**: Der Bestandsbericht nennt 100 % der Skripte, Szenen und Resources des Spiels und der
  Werkstatt und `project.godot` als geprüft.
- **SC-004**: Nach der Behebung meldet ein zweiter Lauf des Prüfers an keiner behobenen Stelle mehr
  einen Befund, alle Tests laufen zweimal grün mit derselben Zahl an Prüfungen, und die Fahrpläne
  für die Seeds 1, 4711 und 99999 sind bytegleich mit vorher.
- **SC-005**: In Features nach 008 kostet eine Phasenprüfung für die Architektur höchstens einen
  Prüfer-Lauf und eine Nachprüfung je Phase. Die Bestandsprüfung ist ausgenommen; sie hat drei Läufe,
  je eine Nachprüfung und, wo ein Lauf nicht alles schafft, Teil-Wiederholungen nur über das Fehlende.
- **SC-006**: Im ersten Feature nach 008, das Code baut, wird der Prüfer beim Plan und in jeder
  Code-Phase eingeplant, ohne dass jemand daran erinnern muss. In 008 belegen das die
  Aufgaben-Vorlage und der Skill der Phasenprüfung; das Ergebnis im nächsten Feature trägt Claude in
  `ki_pruefung.md` nach.
- **SC-007**: Nach der Bestandsprüfung und den Code-Phasen des nächsten Features liegt eine Zählung
  vor, nach der Klaus entscheidet, ob der Prüfer bleibt, nachgeschärft oder gestrichen wird
  (`ki_pruefung.md`, Grundsatz 6). Auch diese Entscheidung fällt erst nach 008; Claude trägt sie
  in `ki_pruefung.md` nach.

## Assumptions

- **Reihenfolge:** Erst entsteht der Leitfaden mit Klaus' Entscheidungen, dann der Prüfer, dann die
  Fehlerprobe, dann die Bestandsprüfung, dann die Tests, dann die Behebung. Jeder Schritt endet mit Klaus' Abnahme.
- **Bestand:** Die Bestandsprüfung läuft über den Stand von `main` zu ihrem Beginn. Vor Phase 3
  fragt Claude, ob Feature 007 gemergt ist; wenn ja, holt Claude `main` mit Klaus' OK in den Branch,
  und der Code von 007 gehört dazu. Wenn nein, sagt der Bericht, dass 007 fehlt.
- **Merge:** 008 wird erst nach 007 gemergt, sonst kollidieren `Features.md` und
  `Feature_Ideas.md`. Die Behebung (Phase 5) beginnt erst, wenn 007 gemergt und `main` im Branch ist,
  weil 007 dieselben Skripte ändern kann. 007 ändert in seinem Abschluss auch `ki_dev.md`,
  `ki_pruefung.md` und die Aufgaben-Vorlage, also dieselben Dateien wie 008 in Phase 2; vor Phase 2
  sieht Claude deshalb nach dem Stand von 007. Kommt 007 erst nach der Bestandsprüfung herein, prüft
  der Prüfer seinen Code in Phase 5 nach.
- **Quellen:** „Game Programming Patterns“ ist frei online lesbar; die Best Practices der
  Godot-Doku 4.7, Ron Gilberts Texte zu SCUMM und Thimbleweed Park und die „Friday Facts“ zu
  Factorio sind öffentlich. Die Recherche dazu kommt nach `docs/recherche/` und in `research.md`
  des Plans. Es wird nichts heruntergeladen, was Klaus nicht erlaubt.
- **Abgrenzung:** Claude prüft weiter gegen Spec und Vertrag, ob der Code das Richtige tut;
  `/code-review` sucht Fehler; der Architektur-Prüfer prüft nur den Aufbau gegen den Leitfaden.
- **Name:** Der Prüfer heißt nach dem Muster der anderen `architektur-pruefer`.
- **Kein Sichtbares:** 008 ändert nichts, was der Spieler sieht oder liest. Von Stil- und
  Text-Prüfer läuft nur der Text-Prüfer, über die Testmeldungen in Phase 4. Leitfaden und
  Arbeitsweise sind keine Texte im Spiel oder in den Werkzeugen.
- **Umfang der Behebung:** Eine Phase, notfalls zwei. Was das Verhalten ändern müsste, geht als
  Frage an Klaus zurück; was mehrere Systeme umbaut, wird ein eigenes Feature (FR-027).
- **Kein neues Spielsystem:** 008 baut keine Wirtschaft, kein Adventure und keine Produktdaten.
  Regeln für diese Schichten beschreiben, wie sie später gebaut werden.
