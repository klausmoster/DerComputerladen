# Feature Specification: Schwierigkeitsgrade der Zeitleiste

**Feature Branch**: `feature/003-schwierigkeitsgrade`

**System**: 01 Zeitleiste; nimmt für die Zeitleiste die Schwierigkeitsgrade aus 11-05 Spielziel und
Schwierigkeitsgrade vorweg und baut auf Feature 002 Zeitleisten-Werkstatt auf

**Created**: 2026-10-21

**Status**: Draft

**Input**: User description: Das Spiel kennt die Schwierigkeitsgrade Leicht, Mittel und Schwer. Es
bleibt ein einziger Ereigniskatalog. Je Grad gibt es ein Profil aus Start-Modifikatoren, die beim
Spielstart auf den Lauf wirken, mit demselben Mechanismus wie die Eingriffe aus Feature 002:
Modifikatoren auf Ereignisse über Wahrscheinlichkeit, Wert in Prozentpunkten, mit Zeitraum und
lesbarem Grund. Jeder Spielstart würfelt weiterhin einen eigenen Seed, sodass jedes Spiel anders
verläuft; derselbe Seed mit demselben Grad ergibt dasselbe Spiel. In der Zeitleisten-Werkstatt legt
Klaus die Profile an und bearbeitet sie, wählt im Simulator einen Grad und vergleicht in der
Statistik die Grade. Einen Bildschirm „Neues Spiel“ gibt es noch nicht; der Grad wird beim Start an
die Zeitleiste übergeben, Vorgabe Mittel. Was Grade außerhalb der Zeitleiste ändern, etwa
Startkapital, Preise oder Kundenstrom, gehört nicht zu diesem Feature.

## Clarifications

### Session 2026-10-21

- Q: Verschiebt ein Profil nur Chancen, oder auch Anzahlen gesetzter Ereignisse und die Stärke von
  Wirkungen? → A: Nur Chancen von Ereignissen über Wahrscheinlichkeit, wie die Modifikatoren aus
  Feature 002. Anzahlen und Wirkungsstärken können später ein eigenes Feature werden.
- Q: Ist „Mittel“ der Katalog oder ein Profil wie die anderen? → A: „Mittel“ ist der Katalog ohne
  Start-Modifikatoren; Profile haben nur „Leicht“ und „Schwer“.
- Q: Stehen die Profile in der Katalogdatei oder daneben? → A: In der Katalogdatei, als eigener
  Abschnitt.
- Q: Soll ein Start-Modifikator für einen eigenen Zeitraum gelten können oder immer fürs ganze
  Spiel? → A: Mit Zeitraum wie die Modifikatoren aus Feature 002; Vorgabe beim Anlegen ist das
  ganze Spiel, 01.01.1985 bis 31.12.1999.
- Q: Wo bearbeitest du die Profile in der Werkstatt? → A: In einem eigenen Reiter
  „Schwierigkeitsgrade“ neben Prüfung, Simulator und Statistik; das Formular eines Ereignisses über
  Wahrscheinlichkeit zeigt die Chance je Grad nur zum Lesen.
- Q: Wogegen markiert der Fahrplan im Simulator die Unterschiede, wenn ein Grad gewählt ist? → A:
  Umschaltbar. Vorgabe wie in Feature 002 ist derselbe Seed und Grad ohne Eingriffe; ein Schalter
  vergleicht stattdessen mit demselben Seed unter „Mittel“ ohne Eingriffe.
- Q: Rechnet der Vergleich der drei Grade in der Statistik die Eingriffe aus dem Simulator mit?
  → A: Wahlweise wie FR-045 von Feature 002; ist der Schalter an, rechnen alle drei Grade jedes
  Spiel mit denselben Modifikatoren und Einplanungen.

### Plan 2026-10-21

- Q: Was geschieht mit den Start-Modifikatoren, wenn Klaus ein Ereignis umbenennt, auf das ein
  Profil verweist? → A: Sie ziehen still mit, wie Folgeereignisse und Bedingungen seit Feature
  002; genannt werden Verweise nur beim Löschen (FR-017, Edge Case „Kaputter Verweis“).

### Review 2026-10-22

Aus der Checkliste [review.md](checklists/review.md); Klaus hat jeweils nach Empfehlung
entschieden.
- Q: Muss der echte Katalog am Ende des Features gefüllte Profile haben? → A: Ja. Zur
  Gesamtabnahme haben Leicht und Schwer je mindestens einen Start-Modifikator, und die Tests
  prüfen, dass beide nicht leer sind (FR-014, Annahmen; CHK008).
- Q: Was tut die Werkstatt, wenn ein Start-Modifikator mitten im Monat beginnt, obwohl die
  Zeitleiste am Monatsersten würfelt? → A: Sie warnt und nennt die erste Würfelrunde, in der er
  wirkt; ebenso bei einem Ende, das kein Monatsletzter ist (FR-012; CHK013).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ein Spiel startet mit einem Schwierigkeitsgrad (Priority: P1)

Ein Spiel beginnt mit einem der Grade Leicht, Mittel oder Schwer. Die Zeitleiste würfelt wie
bisher einen eigenen Seed und spielt ihren Fahrplan ab, nur gelten von Anfang an die
Start-Modifikatoren des gewählten Grads. Bei „Schwer“ kommt etwa die Reklamationswelle öfter, bei
„Leicht“ seltener. Jedes Spiel verläuft trotzdem anders, weil jeder Start einen neuen Seed
bekommt. Wer denselben Seed mit demselben Grad noch einmal startet, bekommt genau dasselbe Spiel.

**Why this priority**: Das ist der Kern des Wunsches. Ohne Grade, die beim Start wirken, haben
Profile und Werkstatt nichts zu tun.

**Independent Test**: Mit einem Test-Katalog und einem Test-Profil zweimal denselben Seed starten,
einmal mit „Mittel“ und einmal mit „Schwer“: Nur die Ereignisse, die das Profil verändert, und was
von ihnen abhängt, laufen anders.

**Acceptance Scenarios**:

1. **Given** die Reklamationswelle mit 3 % pro Monat und das Profil „Schwer“ mit dem
   Start-Modifikator „Schwer: +5 Prozentpunkte vom 01.01.1985 bis 31.12.1999“, **When** ein Spiel
   mit „Schwer“ startet, **Then** würfelt die Zeitleiste die Reklamationswelle jeden Monat mit 8 %.
2. **Given** kein vorgegebener Seed, **When** zwei Spiele nacheinander mit „Schwer“ starten,
   **Then** bekommt jedes seinen eigenen, gewürfelten Seed, und die Zeitleiste nennt Seed und Grad
   des laufenden Spiels.
3. **Given** der Seed 4711 und der Grad „Schwer“, **When** das Spiel zweimal mit diesen Werten
   startet, **Then** sind beide Fahrpläne bis zum 31.12.1999 gleich.
4. **Given** der Seed 4711, **When** das Spiel einmal mit „Mittel“ und einmal mit „Schwer“ startet,
   **Then** unterscheiden sich nur die Termine der Ereignisse, die das Profil verändert, und die
   Termine, die von ihnen abhängen, etwa Folgen und Ereignisse mit Bedingungen.
5. **Given** beim Start ist kein Grad angegeben, **When** das Spiel startet, **Then** gilt „Mittel“.
6. **Given** im Profil „Schwer“ verweist ein Start-Modifikator auf ein Ereignis, das es im Katalog
   nicht mehr gibt, **When** das Spiel startet, **Then** überspringt die Zeitleiste diesen
   Start-Modifikator, meldet ihn mit Grad, Kennung und Grund, und alle übrigen gelten.
7. **Given** ein Spiel mit „Schwer“ und dem Start-Modifikator +5 auf die Reklamationswelle,
   **When** später ein Eingriff −6 Prozentpunkte auf dasselbe Ereignis setzt, **Then** addieren
   sich beide zu −1 Punkt, und die wirksame Chance ist 2 %.

---

### User Story 2 - Profile in der Werkstatt anlegen und pflegen (Priority: P1)

Klaus öffnet in der Zeitleisten-Werkstatt den Reiter „Schwierigkeitsgrade“ neben Prüfung,
Simulator und Statistik und wählt dort „Leicht“ oder „Schwer“; „Mittel“ ist der Katalog selbst und
hat kein Profil. Je Profil sieht er die Start-Modifikatoren als Liste: Ereignis, Wert in
Prozentpunkten, Zeitraum, Grund. Er legt welche an, ändert, dupliziert und löscht sie. Die
Werkstatt prüft laufend wie beim Katalog und zeigt Fehler, etwa einen Start-Modifikator auf ein
fixes Ereignis. Im Formular eines Ereignisses über Wahrscheinlichkeit liest er die Chance je Grad
ab, bearbeitet wird sie nur im Reiter. Gespeichert wird zusammen mit dem Katalog.

**Why this priority**: Ohne Pflege in der Werkstatt müsste Klaus Profile von Hand in einer Datei
schreiben. Die Werkstatt ist laut Verfassung der Ort, an dem die Daten der Zeitleiste gepflegt
werden.

**Independent Test**: In einem leeren Profil drei Start-Modifikatoren anlegen, speichern, die
Werkstatt schließen und wieder öffnen: Alle drei stehen da, und ein Spielstart mit diesem Grad
nutzt sie.

**Acceptance Scenarios**:

1. **Given** das Profil „Leicht“ ist leer, **When** Klaus den Start-Modifikator „Leicht: −2
   Prozentpunkte auf die Reklamationswelle vom 01.01.1985 bis 31.12.1999“ anlegt und speichert,
   **Then** steht er nach dem Neustart der Werkstatt im Profil „Leicht“.
2. **Given** ein Start-Modifikator auf das jährliche Ereignis „Weihnachtsgeschäft“, **When** die
   Werkstatt prüft, **Then** zeigt sie einen Fehler: Start-Modifikatoren gehören nur zu Ereignissen
   über Wahrscheinlichkeit.
3. **Given** ein Start-Modifikator mit Ende vor Beginn oder ohne Grund, **When** die Werkstatt
   prüft, **Then** zeigt sie den Fehler mit Grad und Start-Modifikator.
4. **Given** ein Start-Modifikator im Profil „Schwer“ verweist auf „Konkurrent eröffnet“, **When**
   Klaus „Konkurrent eröffnet“ im Katalog löscht, **Then** zeigt die Werkstatt vorher, dass das
   Profil „Schwer“ darauf verweist, wie bei den übrigen Verweisen (FR-036 von Feature 002).
5. **Given** Klaus ändert in einem Start-Modifikator nur den Wert, **When** er speichert, **Then**
   ändert sich in der gespeicherten Datei nur diese Angabe.
6. **Given** die Reklamationswelle mit 3 % pro Monat, „Leicht: −2 Prozentpunkte“ und „Schwer: +5
   Prozentpunkte“, beide vom 01.01.1985 bis 31.12.1999, **When** Klaus das Formular der
   Reklamationswelle öffnet, **Then** zeigt es nur zum Lesen: Leicht 1 %, Mittel 3 %, Schwer 8 %.
7. **Given** „Schwer: +3 Prozentpunkte auf Konkurrent eröffnet vom 01.01.1995 bis 31.12.1999“
   und eine Grundchance von 3 %, **When** Klaus das Formular von „Konkurrent eröffnet“ öffnet,
   **Then** nennt es für „Schwer“ 3 % bis 31.12.1994 und 6 % ab 01.01.1995.

---

### User Story 3 - Grade im Simulator durchspielen (Priority: P2)

Im Simulator der Werkstatt wählt Klaus neben dem Seed einen Grad. Der Durchlauf beginnt mit den
Start-Modifikatoren dieses Grads, und Fahrplan und Protokoll zeigen sie mit ihrem Grund. Seine
eigenen Eingriffe kommen wie bisher dazu. Wechselt er den Grad, startet der Durchlauf mit demselben
Seed neu. Der Fahrplan markiert wie bisher, was sich gegenüber demselben Seed und Grad ohne
Eingriffe ändert; auf Wunsch vergleicht er stattdessen mit „Mittel“ ohne Eingriffe und zeigt so,
was der Grad bewirkt. Eine Was-wäre-wenn-Probe merkt sich den Grad mit.

**Why this priority**: So sieht Klaus am einzelnen Spiel, was ein Grad bewirkt, bevor er ihn über
viele Spiele vergleicht.

**Independent Test**: Seed 4711 im Simulator mit „Schwer“ bis zum Spielende laufen lassen und den
Vergleich auf „Mittel“ umstellen: Das Protokoll nennt die Start-Modifikatoren, und markiert sind
nur die Termine der veränderten Ereignisse und der von ihnen abhängigen.

**Acceptance Scenarios**:

1. **Given** der Simulator mit Seed 4711 und Grad „Mittel“, **When** Klaus auf „Schwer“ wechselt,
   **Then** startet der Durchlauf mit Seed 4711 und den Start-Modifikatoren von „Schwer“ neu.
2. **Given** ein Durchlauf mit „Schwer“, **When** Klaus das Protokoll ansieht, **Then** stehen die
   Start-Modifikatoren darin mit Grad und Grund, unterscheidbar von seinen eigenen Eingriffen.
3. **Given** Klaus speichert eine Probe mit Grad „Schwer“, **When** er sie später lädt, **Then**
   sind Seed, Grad und Eingriffe wieder gesetzt.
4. **Given** eine Probe aus Feature 002 ohne Grad, **When** Klaus sie lädt, **Then** gilt „Mittel“.
5. **Given** der Simulator mit Seed 4711, Grad „Schwer“ und ohne Eingriffe, **When** Klaus den
   Vergleich auf „Mittel ohne Eingriffe“ umstellt, **Then** markiert der Fahrplan nur Termine der
   Ereignisse, die das Profil „Schwer“ verändert, und der von ihnen abhängigen.
6. **Given** derselbe Durchlauf mit dem Eingriff „Lieferengpass −4 Prozentpunkte ab 01.01.1990“,
   **When** der Vergleich auf der Vorgabe steht, **Then** markiert der Fahrplan nur, was dieser
   Eingriff gegenüber „Schwer ohne Eingriffe“ ändert, und nennt den Vergleichslauf.

---

### User Story 4 - Grade in der Statistik vergleichen (Priority: P2)

Klaus lässt die Statistik für alle drei Grade mit je 1.000 Spielen rechnen, mit denselben Seeds für
jeden Grad. Je Ereignis sieht er die Werte der drei Grade nebeneinander, etwa wie oft die
Reklamationswelle im Schnitt kommt und in wie vielen Spielen gar nicht. So stellt er die Profile
nach, bis sich die Grade so anfühlen, wie er es will.

**Why this priority**: Ohne Vergleich bleibt offen, ob „Schwer“ wirklich schwerer ist. Er wird
wichtig, sobald Klaus anfängt, Profile nachzustellen.

**Independent Test**: Ein Test-Katalog mit einem Ereignis zu 3 % pro Monat ohne weitere Grenzen und
ein Profil „Schwer“ mit +5 Prozentpunkten: Über 1.000 Spiele liegt der Mittelwert bei „Mittel“
nahe 5,4 und bei „Schwer“ nahe 14,4.

**Acceptance Scenarios**:

1. **Given** der Katalog und die Profile von „Leicht“ und „Schwer“, **When** Klaus den Vergleich
   über je 1.000 Spiele startet, **Then** zeigt die Statistik ihren Fortschritt, lässt sich
   abbrechen und zeigt je Ereignis Mittelwert, kleinste und größte Anzahl und den Anteil der
   Spiele ohne Eintreten für jeden Grad nebeneinander.
2. **Given** derselbe Katalog und dieselben Profile, **When** der Vergleich zweimal gerechnet wird,
   **Then** sind beide Ergebnisse gleich.
3. **Given** ein Ereignis, das kein Profil verändert und das von keinem veränderten abhängt,
   **When** der Vergleich fertig ist, **Then** hat es in allen drei Graden dieselben Werte.
4. **Given** Klaus hat im Simulator „Lieferengpass −4 Prozentpunkte ab 01.01.1990“ gesetzt, und
   kein Profil verändert den Lieferengpass, **When** er den Vergleich mit den Eingriffen aus dem
   Simulator startet, **Then** rechnen alle drei Grade jedes Spiel mit diesem Eingriff, und der
   Lieferengpass hat in allen drei Graden dieselben Werte.

---

### Edge Cases

- **Leeres Profil**: „Leicht“ oder „Schwer“ ohne Start-Modifikatoren verhält sich wie „Mittel“,
  also wie der Katalog allein.
- **Ältere Katalogdatei**: Eine Katalogdatei aus Feature 002 ohne Abschnitt für Profile lässt sich
  laden; beide Profile sind dann leer, und beim nächsten Speichern kommt der Abschnitt dazu. Dieses
  erste Speichern ändert die Zeile mit der Formatnummer und legt den leeren Abschnitt an; sonst
  ändert sich nichts. FR-005 und SC-006 gelten für Dateien, die den Abschnitt schon haben.
- **Ereignis dupliziert**: Die Kopie eines Ereignisses über Wahrscheinlichkeit hat in keinem
  Profil einen Start-Modifikator; die Start-Modifikatoren bleiben beim Original.
- **Art geändert**: Ändert Klaus die Art eines Ereignisses, auf das Start-Modifikatoren zeigen,
  etwa die Reklamationswelle von „über Wahrscheinlichkeit“ auf „fix“, bleiben sie stehen und sind
  ein Prüffehler, bis er sie löscht oder die Art zurückstellt. Ein Spielstart überspringt sie.
- **Beginn mitten im Monat**: Die Zeitleiste würfelt am Monatsersten. „Schwer: +3 Prozentpunkte
  ab 15.03.1990“ wirkt deshalb erst ab der Würfelrunde am 01.04.1990, und ein Ende am 15.06.1994
  gilt noch für die Würfelrunde am 01.06.1994. Die Werkstatt warnt in beiden Fällen (FR-012).
- **Grenzen der Chance**: Start-Modifikatoren und Eingriffe zusammen heben eine Chance nie über
  100 % und senken sie nie unter 0 %, wie bei Feature 002 (FR-025).
- **Mehrere Start-Modifikatoren auf dasselbe Ereignis** in einem Profil addieren sich.
- **Falsches Ziel**: Ein Start-Modifikator auf ein fixes, jährliches, beim Start gesetztes oder nur
  als Folge vorkommendes Ereignis ist ein Prüffehler.
- **Kaputter Verweis**: Löscht Klaus ein Ereignis, nennt die Werkstatt vorher die
  Start-Modifikatoren, die darauf verweisen, und entfernt sie mit; benennt er es um, ziehen sie
  mit (FR-017). Verweist ein Start-Modifikator trotzdem auf ein unbekanntes Ereignis, etwa nach
  einer Änderung an der Datei von Hand, zeigt die Werkstatt ihn als Fehler, und ein Spielstart
  überspringt ihn und meldet ihn (präzisiert im Plan, Klaus, 2026-10-21).
- **Unbekannter Grad**: Verlangt ein Spielstart einen Grad, den es nicht gibt, beginnt kein neues
  Spiel; die Zeitleiste meldet den Fehler, und ein laufendes Spiel bleibt, wie es ist.
- **Zeitraum außerhalb des Spiels**: Ein Start-Modifikator vor dem 01.01.1985 oder nach dem
  31.12.1999 ist ein Prüffehler; ein Zeitraum, der nur einen Teil des Spiels abdeckt, ist erlaubt,
  etwa „Schwer: +3 Prozentpunkte auf Konkurrent eröffnet ab 01.01.1995“.
- **Vergleich bei „Mittel“**: Ist im Simulator „Mittel“ gewählt, sind beide Vergleichsläufe gleich;
  der Schalter ändert dann keine Markierung.
- **Kein Wechsel im Spiel**: Der Grad gilt für das ganze Spiel; ein laufendes Spiel wechselt ihn
  nicht. Start-Modifikatoren lassen sich im Spiel nicht entfernen, nur im Profil ändern.

## Requirements *(mandatory)*

### Functional Requirements

**Grade und Profile**

- **FR-001**: Das Spiel muss genau drei Schwierigkeitsgrade kennen: Leicht, Mittel und Schwer.
- **FR-002**: Die Grade „Leicht“ und „Schwer“ müssen je ein Profil haben: eine Liste von
  Start-Modifikatoren. Ein Start-Modifikator hat dieselben Angaben wie ein Modifikator aus
  Feature 002 (FR-025): eine Kennung, ein Ereignis über Wahrscheinlichkeit, einen Wert in
  Prozentpunkten (positiv, negativ oder 0), einen lesbaren Grund, einen Beginn und verpflichtend
  ein Ende; „unbegrenzt“ heißt 31.12.1999. Beim Anlegen gibt die Werkstatt das ganze Spiel vor,
  01.01.1985 bis 31.12.1999.
- **FR-003**: Profile dürfen nur die Chance von Ereignissen über Wahrscheinlichkeit verschieben.
  Die Anzahl beim Start gesetzter Ereignisse, fixe und jährliche Termine und die Stärke von
  Wirkungen bleiben in allen Graden, wie der Katalog sie beschreibt.
- **FR-004**: „Mittel“ muss der Katalog ohne Start-Modifikatoren sein. Es hat kein Profil, und die
  Grundchancen im Katalog sind die Werte von „Mittel“.
- **FR-005**: Die Profile müssen in der Katalogdatei stehen, als eigener Abschnitt. Eine
  Katalogdatei ohne diesen Abschnitt ist gültig; dann sind beide Profile leer. Die gespeicherte
  Form ist menschenlesbar, und ändert Klaus eine einzelne Angabe, ändert sich nur diese in der
  Datei. Das erste Speichern einer älteren Datei legt den Abschnitt an (Edge Case „Ältere
  Katalogdatei“).

**Spielstart**

- **FR-006**: Beim Spielstart muss der Grad an die Zeitleiste übergeben werden können; ohne Angabe
  gilt „Mittel“. Die Zeitleiste nennt den Grad des laufenden Spiels wie seinen Seed.
- **FR-007**: Die Zeitleiste muss die Start-Modifikatoren des Grads setzen, bevor sie zum ersten Mal
  würfelt. Sie wirken in ihrem Zeitraum wie Modifikatoren aus FR-025 von Feature 002: Gleichzeitig
  gültige addieren sich mit allen übrigen Modifikatoren, die wirksame Chance ist Grundchance plus
  Summe, begrenzt auf 0 % bis 100 %. Gewürfelt wird am Monatsersten; ein Start-Modifikator wirkt
  also in den Würfelrunden, deren Tag in seinem Zeitraum liegt.
- **FR-008**: Der Seed muss unabhängig vom Grad bleiben: Ein Start ohne Seed würfelt einen neuen;
  derselbe Katalog mit demselben Seed und demselben Grad ergibt denselben Fahrplan.
- **FR-009**: Mit demselben Seed dürfen sich zwei Grade nur in den Terminen der Ereignisse
  unterscheiden, deren Chance ein Profil verändert, und in den Terminen, die von ihnen abhängen.
  Die Würfel der übrigen Ereignisse bleiben unberührt (FR-015 von Feature 002). Abhängig ist jedes
  Ereignis, das von einem veränderten aus erreichbar ist, auch über mehrere Stufen: über
  Folgeereignisse, von der Quelle zur Folge, und über Bedingungen, vom Ereignis in der Bedingung
  zum bedingten Ereignis.
- **FR-010**: Start-Modifikatoren müssen im Protokoll mit Grad und Grund stehen, unterscheidbar von
  späteren Eingriffen. Im laufenden Spiel lassen sie sich nicht entfernen.
- **FR-011**: Ein Spielstart mit einem unbekannten Grad muss abgelehnt werden: Es beginnt kein
  neues Spiel, die Zeitleiste meldet den Fehler, und ein laufendes Spiel bleibt, wie es ist.
  Bekannt sind nur Leicht, Mittel und Schwer; in Dateien und Argumenten heißen sie „leicht“,
  „mittel“ und „schwer“, klein geschrieben.

**Prüfregeln**

- **FR-012**: Die Werkstatt und der Spielstart müssen Profile nach festen Regeln prüfen. Ein Fehler
  ist: ein unbekanntes Ereignis; ein Ereignis, das nicht über Wahrscheinlichkeit kommt; ein Ende vor
  dem Beginn; ein Zeitraum außerhalb 01.01.1985 bis 31.12.1999; ein leerer Grund; eine doppelte
  Kennung im Profil; ein Wert, der keine Zahl ist. Eine Warnung ist ein Beginn, der kein
  Monatserster ist, und ein Ende, das kein Monatsletzter ist; sie nennt die erste bzw. letzte
  Würfelrunde, in der der Start-Modifikator wirkt (Klaus, 2026-10-22).
- **FR-013**: Beim Spielstart müssen fehlerhafte Start-Modifikatoren übersprungen und mit Grad,
  Kennung und Grund gemeldet werden; die übrigen gelten (wie FR-049 von Feature 002). Ebenso fällt
  ein Start-Modifikator weg, dessen Ereignis wegen eines Fehlers ausgenommen ist, und wird genannt.
  Simulator, Statistik und Textausgabe nehmen dieselben Start-Modifikatoren aus und nennen sie.
- **FR-014**: Die automatischen Tests müssen die gespeicherten Profile mit denselben Prüfregeln
  prüfen wie die Werkstatt (wie FR-048 von Feature 002). Sobald Klaus die Profile angelegt hat,
  prüfen sie auch, dass Leicht und Schwer im echten Katalog nicht leer sind (Klaus, 2026-10-22).

**Werkstatt**

- **FR-015**: Die Werkstatt muss die Profile von „Leicht“ und „Schwer“ in einem eigenen Reiter
  „Schwierigkeitsgrade“ neben Prüfung, Simulator und Statistik zeigen und Klaus dort
  Start-Modifikatoren anlegen, ändern, duplizieren und löschen lassen; „Mittel“ zeigt sie als
  Katalog ohne Start-Modifikatoren. „Neu“ legt einen Start-Modifikator auf das gewählte Ereignis
  an, wenn es über Wahrscheinlichkeit kommt, sonst auf das erste solche, mit dem ganzen Spiel und
  dem Wert 0. Seine Kennung bildet die
  Werkstatt aus der Kennung des Ereignisses, im Profil eindeutig; Klaus kann sie ändern. Löschen
  fragt nicht nach und lässt sich zurücknehmen. Das Formular eines Ereignisses über
  Wahrscheinlichkeit zeigt die Chance je Grad aus Grundchance und Start-Modifikatoren nur zum Lesen;
  gilt ein Start-Modifikator nur für einen Teil des Spiels, nennt es die Chance je Zeitabschnitt.
  Start-Modifikatoren mit einem Fehler zählen dabei nicht mit, wie im Spiel. Werte zeigt die
  Werkstatt in Prozentpunkten, Chancen in Prozent, wie in Feature 002.
- **FR-016**: Die Werkstatt muss Profile laufend prüfen und Fehler mit Grad und Start-Modifikator
  zeigen; in der Liste der Prüfung steht der Grad dort, wo sonst das Ereignis steht. Gespeichert
  wird zusammen mit dem Katalog, auch mit Cmd+S, und ungespeicherte Änderungen an Profilen zählen
  wie ungespeicherte Änderungen am Katalog. Cmd+Z nimmt sie zurück, und die Sicherungskopie
  enthält sie, wie beim Katalog (FR-034 und FR-050 von Feature 002).
- **FR-017**: Löscht Klaus ein Ereignis, auf das ein Profil verweist, muss die Werkstatt diese
  Verweise vorher nennen und mit entfernen, wie die übrigen Verweise (FR-036 von Feature 002).
  Benennt er es um, ziehen die Start-Modifikatoren still mit, wie Folgeereignisse und Bedingungen
  (präzisiert im Plan, Klaus, 2026-10-21; bis dahin sollte die Werkstatt die Verweise auch vor dem
  Umbenennen nennen).
- **FR-018**: Im Simulator muss Klaus neben dem Seed einen Grad wählen können. Der Durchlauf beginnt
  mit dessen Start-Modifikatoren; ein Wechsel des Grads startet den Durchlauf mit demselben Seed
  neu, und Klaus' Eingriffe bleiben dabei erhalten wie bei einem Neustart in Feature 002. Der
  Durchlauf entsteht dabei so, wie er war, mit dem aktuellen Katalog: derselbe Tag und dieselben
  angewandten Eingriffe, nur der Grad ist anders; ein Durchlauf ohne Eingriffe bleibt ohne.
  Eingriffe, die im neuen Grad nicht anwendbar sind, nennt der Simulator wie beim Laden einer
  Probe (FR-051 von Feature 002); die gesammelten bleiben für „Neu starten mit Eingriffen“ (alles
  präzisiert im Review, 2026-10-22). Der Fahrplan markiert Unterschiede wie in Feature 002
  gegenüber demselben Seed und Grad ohne Eingriffe; ein Schalter stellt den Vergleich auf denselben
  Seed mit „Mittel“ ohne Eingriffe um, und der Simulator nennt, wogegen gerade verglichen wird.
  Ändert Klaus ein Profil, während ein Durchlauf läuft, gilt wie bei jeder Änderung am Katalog
  „Katalog geändert, neu starten“ (FR-042 von Feature 002).
- **FR-019**: Eine Was-wäre-wenn-Probe muss den Grad mit speichern und beim Laden wieder setzen.
  Eine Probe ohne Grad gilt als „Mittel“. Eine Probe mit einem unbekannten Grad ist unlesbar, und
  die Werkstatt sagt es, wie bei einem Seed außerhalb des Bereichs.
- **FR-020**: Die Statistik muss für einen gewählten Grad rechnen und alle drei Grade vergleichen
  können: je Grad dieselbe Anzahl Spiele mit denselben Seeds, je Ereignis Mittelwert, kleinste und
  größte Anzahl und Anteil der Spiele ohne Eintreten nebeneinander. Obergrenze und Verteilung auf
  die Jahre (FR-044 von Feature 002) zeigt sie nur für einen Grad. Sie zeigt ihren Fortschritt und
  lässt sich abbrechen; nach einem Abbruch zählen im Vergleich nur Seeds, die in allen drei Graden
  fertig sind. Das Ergebnis nennt den Grad, auch Mittel. Wahlweise rechnet sie wie in Feature 002
  (FR-045) mit den Modifikatoren und Einplanungen aus dem Simulator, im Vergleich dann für alle
  drei Grade gleich. Ändert Klaus ein Profil während einer Rechnung, gilt „Katalog geändert, neu
  starten“ wie im Simulator.
- **FR-021**: Die Textausgabe des Fahrplans ohne Werkstatt (FR-046 von Feature 002) muss einen Grad
  annehmen und ihn mit dem Seed in der Kopfzeile nennen, auch Mittel.

### Key Entities *(include if feature involves data)*

- **Schwierigkeitsgrad**: einer von Leicht, Mittel, Schwer; gilt für ein ganzes Spiel.
- **Profil**: gehört zu „Leicht“ oder „Schwer“; die Liste seiner Start-Modifikatoren, gespeichert
  als Abschnitt der Katalogdatei. „Mittel“ hat keins.
- **Start-Modifikator**: ein Modifikator, der schon beim Spielstart gilt; Kennung, Ereignis über
  Wahrscheinlichkeit, Wert in Prozentpunkten, Grund, Beginn, Ende.
- **Lauf**: ein Spiel aus Katalog, Seed und Grad; wie in Feature 002, jetzt mit Grad.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Derselbe Seed mit demselben Grad und Katalog ergibt in 100 von 100 Wiederholungen
  denselben Fahrplan bis zum 31.12.1999.
- **SC-002**: Mit festem Seed und gewechseltem Grad unterscheiden sich in 100 von 100 geprüften
  Seeds nur die Termine der veränderten Ereignisse und der von ihnen abhängigen (FR-009).
  Gemessen wird mit dem Vergleich zweier Läufe wie in Feature 002 (FR-043): Jeder Unterschied
  gehört zu einem veränderten oder abhängigen Ereignis.
- **SC-003**: Mit einem Test-Ereignis zu 3 % pro Monat ohne weitere Grenzen und +5 Prozentpunkten im
  Profil „Schwer“ liegt der Mittelwert über 1.000 Spiele bei „Mittel“ zwischen 4,9 und 5,9 und bei
  „Schwer“ zwischen 13,4 und 15,4 (180 Monate, Erwartung 5,4 und 14,4). „Ohne weitere Grenzen“
  heißt: Zeitfenster das ganze Spiel, kein Mindestabstand, keine Höchstzahl, keine Dauer, keine
  Bedingungen.
- **SC-004**: Der Vergleich aller drei Grade über je 1.000 Spiele mit dem vorhandenen Katalog liegt
  nach höchstens 90 Sekunden vor. Gemessen in der Werkstatt auf Klaus' Rechner, vom Starten bis
  100 %, ohne Eingriffe, mit dem echten Katalog samt Profilen.
- **SC-005**: Klaus legt ein Profil mit drei Start-Modifikatoren in der Werkstatt in unter 5 Minuten
  an, ohne eine Datei von Hand zu öffnen.
- **SC-006**: Ändert Klaus einen einzelnen Wert in einem Start-Modifikator, ändert sich in der
  gespeicherten Datei genau eine Zeile. Gemessen an einer Datei, die den Abschnitt für Profile
  schon hat.
- **SC-007**: Mit „Mittel“ sind Fahrplan und Protokoll für die Seeds 1, 4711 und 99999 Zeichen für
  Zeichen wie vor diesem Feature, gemessen an einer Grundlinie, die vor dem Umbau festgehalten wird
  (Review, 2026-10-22).

## Assumptions

- Es gibt genau drei Grade mit festen Namen. Weitere Grade oder eigene Namen kommen, wenn überhaupt,
  später.
- Weil Profile nur Chancen verschieben, verändert ein Grad im heutigen Katalog die 6 Ereignisse über
  Wahrscheinlichkeit. Mit dem Katalog wächst die Wirkung. Anzahlen gesetzter Ereignisse und die
  Stärke von Wirkungen je Grad sind ein mögliches späteres Feature.
- Grade wirken in diesem Feature nur auf die Zeitleiste. Was sie an Wirtschaft, Startkapital,
  Preisen oder Kundenstrom ändern, gehört zu 03 Wirtschaftsmodell und 11-05 Spielziel und
  Schwierigkeitsgrade.
- Einen Bildschirm, auf dem der Spieler den Grad wählt, gibt es noch nicht; er kommt mit 01-05
  „Neues Spiel“. Bis dahin startet das Spiel mit „Mittel“, und andere Grade lassen sich in der
  Werkstatt, in Tests und in der Textausgabe nutzen. 01-05 umfasst Startdatum, Seed und Grad
  (Klaus, 2026-10-22).
- Zur Gesamtabnahme hat der echte Katalog in Leicht und Schwer je mindestens einen
  Start-Modifikator. Die Werte legt Klaus in der Werkstatt fest; die Tests prüfen nur, dass beide
  Profile nicht leer sind (Klaus, 2026-10-22).
- Start-Modifikatoren nutzen den Mechanismus aus Feature 002 unverändert: Ein Modifikator ändert
  nur die Schwelle, nie den Wurf. Deshalb bleibt FR-009 erfüllbar, ohne die Würfel zu ändern.
- Die Werkstatt gestaltet die Profile nach dem Abschnitt „Werkzeuge“ des Style-Guides wie den Rest
  der Werkstatt.
- Spielstände gibt es noch nicht (11-01). Wenn sie kommen, speichern sie den Grad mit.
