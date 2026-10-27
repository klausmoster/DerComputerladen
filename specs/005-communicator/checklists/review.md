# Anforderungs-Review Checklist: Communicator als Steuerelement

**Purpose**: Prüft, ob Spec und Plan vollständig, eindeutig, widerspruchsfrei und messbar sind,
bevor die Tasks entstehen. Bereiche: der Communicator als Baustein, Fahrt und Eingabe, Seiten auf
der Anzeige, Titel, Grafik und Style-Guide, Abnahmekriterien.
**Created**: 2026-10-27
**Feature**: [spec.md](../spec.md), [plan.md](../plan.md)

**Note**: Erzeugt mit `/speckit-checklist`. Geprüft wird, wie die Anforderungen geschrieben sind,
nicht, ob der spätere Code funktioniert.
**Review Ownership**: Die Checkliste gehört dem Prüfer, hier Klaus. Ein Punkt bekommt `[x]` erst,
wenn er die Anforderung dazu für gut genug hält.
**Marker Semantics**: `[x]` heißt, die Anforderung ist geprüft und in Ordnung. Es heißt nicht,
dass etwas gebaut ist.

Jeder Punkt hat einen Vorschlag von Claude („→ Vorschlag“). Was er an Spec oder Plan ändern würde,
steht dabei. Eingearbeitet wird erst nach Klaus' Freigabe; sie kam am 2026-10-27 für alle Punkte.

## Vollständigkeit

- [x] CHK001 Ist festgelegt, was eine Rollmarke tut, die in der gewählten Zeile steht? Auf Papier
  ist die Rollmarke `tusche` auf `signalgelb`; auf der Anzeige läge sie `tusche` auf dem Balken in
  `tusche` und wäre unsichtbar, sobald „Löschen …“ gewählt ist. [Gap, Spec §FR-004a; Plan R3;
  data-model „Seiten auf der Anzeige“]
  → Vorschlag, freigegeben von Klaus (2026-10-27): In der gewählten Zeile ist die Rollmarke `lcd` wie Schrift und Pfeil. Ergänzen in
  R3, im Datenmodell und im Abschnitt „Auf der Anzeige“ des Bausteins Liste (R12).
- [x] CHK002 Ist festgelegt, ob das Gehäuse etwas tut, wenn man darauf klickt, etwa auf eine Taste
  der Tastatur im Bild? [Gap, Spec §FR-001]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Das Gehäuse ist reine Grafik: kein Klick, keine Hand, kein Gelb; nur die Seiten auf
  der Anzeige sind bedienbar. Satz in FR-001 und im Baustein Communicator.
- [x] CHK003 Nennt FR-008 alle Bausteine, die sich mit dem Communicator ändern? Die Meldung steht
  „an der Stelle des Hinweises“, und die rückt neben das Gehäuse. [Completeness, Spec §FR-008;
  Plan R12]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Baustein Meldung in FR-008 und R12 ergänzen: Lage wie der Hinweis.
- [x] CHK004 Ist festgelegt, in welcher Schrift die Kopfzeile auf der Anzeige steht? Der
  Style-Guide gibt Doto für alles, was der Nadeldrucker ausgibt, und für die Leuchtanzeige; die
  Anzeige des Communicators ist keins von beiden. [Gap, Style-Guide Schrift; data-model „Seiten auf
  der Anzeige“]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Doto bleibt, denn ein LCD ist ebenfalls eine Punktmatrix. Der Style-Guide nennt die
  Anzeige des Communicators bei Doto mit (R12, Punkt 5).
- [x] CHK005 Ist festgelegt, wann das Gehäuse G-02 vor T-02 fertig sein muss? T-02 soll eine ruhige
  Fläche genau dort lassen, wo das Gerät steht; ohne Maße des Gehäuses lässt sich der Prompt nicht
  genau schreiben. [Dependency, Plan R10, Phase 2]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Reihenfolge in R10 und Phase 2: erst G-02 erzeugen, rastern und die Anzeige
  nachmessen, dann den Prompt für T-02 mit der Fläche schreiben.
- [x] CHK006 Kommen in der Abschlussphase alle Dateien der Spielbeschreibung vor, die der
  Communicator berührt? Der Begriff „Communicator“ ist neu, und `glossar.md` hat ihn nicht.
  [Completeness, Plan Phase 6]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Phase 6 nennt `glossar.md` (Communicator, Gehäuse, Anzeige, Seite) und
  `architektur.md` (neuer Ordner `src/ui/communicator/`) dazu.

## Klarheit

- [x] CHK007 Ist „Die Maus wählt die Zeile, die gerade unter ihr liegt“ eindeutig, wenn die Maus
  stillsteht und eine Zeile unter ihr durchfährt? [Ambiguity, Spec Edge Cases „Eingaben während der
  Fahrt“]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Die Maus wählt nur, wenn sie bewegt oder geklickt wird; eine Zeile, die unter dem
  ruhenden Zeiger durchfährt, wird nicht gewählt. So springt die Auswahl beim Hereinfahren nicht
  über das Menü.
- [x] CHK008 Ist geklärt, ob ein Linksklick während der Fahrt herein auslöst? FR-003 nennt nur die
  Tastatur. [Clarity, Spec §FR-003]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Ja, auf die Zeile unter dem Zeiger, wie im Stand. FR-003 sagt „Eingaben mit Maus und
  Tastatur“.
- [x] CHK009 Meint „keine Eingabe“ in FR-013a auch Fensterbefehle wie Cmd+Q, Schließen und
  Vollbild? Der Edge Case erlaubt das Schließen ausdrücklich. [Ambiguity, Spec §FR-013a, Edge
  Cases]
  → Vorschlag, freigegeben von Klaus (2026-10-27): FR-013a präzisieren: „keine Eingabe an Communicator und Titel“; Schließen, Cmd+Q
  und Vollbild wirken wie immer.
- [x] CHK010 Ist SC-002 messbar, wenn das erste Bild lange dauert? Ab dem Anfang dieses Bilds
  gemessen wären 250 ms bei 0,5 s Ladezeit nicht zu halten. [Measurability, Spec §SC-002; Plan R6]
  → Vorschlag, freigegeben von Klaus (2026-10-27): SC-002 misst ab dem ersten Bild, in dem der Communicator unterwegs ist, und zählt die
  Zeitschritte danach; ein langes erstes Bild zählt als ein gedeckelter Schritt.
- [x] CHK011 Ist der Edge Case „Kleinstes Fenster (640 × 360)“ sinnvoll? Das Bild wird nur
  ganzzahlig skaliert; die Anordnung ist in jeder Fenstergröße dieselbe. [Clarity, Spec Edge
  Cases]
  → Vorschlag, freigegeben von Klaus (2026-10-27): umformulieren: „Bei Faktor 1, dem kleinsten Fenster, ist jede Zeile lesbar; die
  Anordnung ist dieselbe wie bei jedem anderen Faktor.“ Prüfung bleibt im Quickstart.
- [x] CHK012 Sagt SC-007 vollständig, welche alten Tests sich ändern dürfen? Nicht nur Papier,
  auch die Lage der Blätter und des Hinweises ändert sich. [Clarity, Spec §SC-007]
  → Vorschlag, freigegeben von Klaus (2026-10-27): „angepasst nur, wo sie Papier, Lage der Blätter oder Lage des Hinweises prüfen“.

## Widerspruchsfreiheit

- [x] CHK013 Widerspricht SC-005 dem Plan? SC-005 verlangt eine Probeseite „ohne eine Datei des
  Titels“, aber `MainMenu` liegt in `scenes/title/` und soll dort bleiben (Plan, Structure
  Decision). [Conflict, Spec §SC-005; Plan; contracts/communicator.md]
  → Vorschlag, freigegeben von Klaus (2026-10-27): SC-005 präzisieren: „ohne den Titelbildschirm und seine Texte“. Menü und Liste
  dürfen genutzt werden; ihr Umzug nach `src/ui/` gehört zu dem Feature, das sie als Erstes
  außerhalb des Titels braucht (offener Punkt).
- [x] CHK014 Passt FR-001a („Grund der Anzeige ist `lcd`“) zu FR-001 („für jedes Gehäuse gleich
  groß“) und zur Recherche, nach der der Zeitplaner von 1985 Papier als Anzeige hat?
  [Consistency, Spec §FR-001, §FR-001a; Recherche Abschnitt 4]
  → Vorschlag, freigegeben von Klaus (2026-10-27): FR-001a gilt für den Organizer. Die Farbe der Anzeige gehört zum Gehäuse; spätere
  Gehäuse dürfen eine andere aus dem Style-Guide haben. Größe und Bedienung bleiben gleich.
- [x] CHK015 Gilt das Raster des Style-Guides für das Gehäuse? Es ist ein Bild auf dem Bildraster,
  fährt aber in ganzen Oberflächenpixeln, also zeitweise um einen halben Bildpixel versetzt zum
  Titelbild. Der Style-Guide sagt: Szenenobjekte bewegen sich in ganzen Bildpixeln. [Conflict,
  Spec §FR-002; Style-Guide Raster; Plan R9]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Der Communicator ist Oberfläche: Er fährt in ganzen Oberflächenpixeln, seine
  Endlage liegt auf ganzen Bildpixeln (gerade Lagen, R9). So steht er im Stand sauber auf dem
  Raster des Titelbilds. Satz im Baustein Communicator.
- [x] CHK016 Stimmt das Datenmodell mit Feature 004 überein, wenn das Fortsetzen scheitert? Es
  sagt „Die Meldung steht an der Zeile“; der Code von 004 zeigt dann keine Meldung, sondern liest
  Hauptmenü oder Liste neu. [Conflict, data-model „Titelbildschirm“; `title_screen.gd`]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Datenmodell korrigieren: Scheitert das Fortsetzen, liest der Titel wie in 004 neu;
  eine Meldung gibt es nur beim Anlegen. Der Communicator fährt in beiden Fällen nicht.
- [x] CHK017 Ist „Bewegung reduzieren“ einheitlich behandelt? Die Spec sagt, der Communicator
  erscheint dann ohne Gleiten; der Style-Guide sagt, die Einstellung schaltet „alle
  Deko-Animationen“ ab. Ist die Fahrt Deko? [Consistency, Spec Annahmen; Style-Guide Bewegung]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Ja, die Fahrt ist Deko und entfällt dann; der Baustein Communicator sagt es
  ausdrücklich. Gebaut wird die Einstellung nicht in diesem Feature (`animate` ist vorbereitet).

## Abdeckung von Abläufen und Randfällen

- [x] CHK018 Ist festgelegt, was eine Eingabe tut, bevor der Communicator zu fahren beginnt, etwa
  Enter im allerersten Bild, wenn das Hauptmenü noch keine Einträge hat? [Gap, Spec §FR-003,
  §FR-010]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Bis das Hauptmenü seine Einträge hat, tut eine Eingabe nichts. Edge Case ergänzen;
  der Vertrag sagt, dass die Fahrt mit dem Bau der Einträge beginnt.
- [x] CHK019 Ist festgelegt, wo der Hinweis steht, während der Communicator noch fast ganz unter dem
  Bild ist? Er stünde dann selbst unter dem Bildrand. [Coverage, Spec §FR-006, §FR-010a]
  → Vorschlag, freigegeben von Klaus (2026-10-27): so lassen: Der Hinweis fährt mit seiner Zeile herein und ist zu sehen, sobald die
  Zeile es ist. Satz im Baustein Communicator.
- [x] CHK020 Ist festgelegt, was nach „Zum Hauptmenü“ geschieht, wenn der Spieler sofort Esc
  drückt, während der Communicator hereinfährt? [Coverage, Spec Edge Cases „Rückkehr aus dem
  Spiel“]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Im Hauptmenü tut Esc nichts, auch während der Fahrt (FR-013). Keine Änderung, der
  Edge Case „Mehrmals Esc“ deckt es; im Quickstart als Probe.
- [x] CHK021 Ist ein Fallback festgelegt, falls ein Bild fehlt oder sich nicht laden lässt, etwa
  G-02 oder T-02 nach einem kaputten Import? [Gap, Edge Cases]
  → Vorschlag, freigegeben von Klaus (2026-10-27): keine Laufzeit-Regel; `test_bilder.gd` prüft jedes Bild im Ordner, und ein fehlendes
  Bild fällt beim Start als Fehler auf (Startprobe still). Annahme ergänzen.

## Messbarkeit der Abnahmekriterien

- [x] CHK022 Ist SC-006 messbar für den Hinweis in jeder Lage? Der Hinweis ist bis zu zwei Zeilen
  hoch und hängt an der gewählten Zeile; die tiefste Zeile ist „Zurück“ der Liste. [Measurability,
  Spec §SC-006; Plan R9]
  → Vorschlag, freigegeben von Klaus (2026-10-27): SC-006 nennt die Probe: für jede Zeile jeder Seite der längste Hinweis, auch als
  Meldung, in der Endlage. Steht schon im Vertrag des Titels; Spec angleichen.
- [x] CHK023 Sind die Kontraste aus R2 als Abnahmekriterium festgehalten oder nur als Vorschlag?
  [Measurability, Spec §FR-001a; Plan R2]
  → Vorschlag, freigegeben von Klaus (2026-10-27): In den Style-Guide mit Wert und Kontrast; `test_ui_palette.gd` prüft die vier Paare
  gegen 4,5 : 1 und 3 : 1, wie andere Kontraste im Projekt.
- [x] CHK024 Lässt sich FR-015 („nichts Wichtiges des Bilds verdeckt“) objektiv abnehmen?
  [Measurability, Spec §FR-015]
  → Vorschlag, freigegeben von Klaus (2026-10-27): Klaus entscheidet am Bildschirmfoto bei der Freigabe von T-02 (Phase 2) und noch
  einmal in Phase 5. In FR-015 als Abnahme durch Klaus benennen, nicht als Test.

## Abhängigkeiten und Annahmen

- [x] CHK025 Ist festgehalten, welche Teile von Feature 001 und 004 sich ändern? [Dependency, Spec
  §FR-011, §FR-013]
  → Vorschlag, freigegeben von Klaus (2026-10-27): FR-011 nennt FR-023 von 004. Ergänzen: FR-005 von Feature 001 (Anordnung nach dem
  Titelscreen-Entwurf mit Papier rechts) und der Abschnitt „Blätter im Titel“ des Bausteins Menü.
- [x] CHK026 Ist die Annahme geprüft, dass Leonardo eine Bildvorlage für T-02 anbietet?
  [Assumption, Plan R10]
  → Vorschlag, freigegeben von Klaus (2026-10-27): steht schon als „wenn Leonardo das anbietet“; ergänzen: sonst ein Prompt mit der
  Beschreibung von T-01 und C2 als Style Reference, und Klaus entscheidet am Ergebnis.

## Notes

- Durchgang 1 (2026-10-27): 26 Punkte. Echte Lücken und Widersprüche: CHK001 (unsichtbare
  Rollmarke), CHK013 (SC-005 gegen den Plan), CHK015 (Raster beim Fahren), CHK016 (Datenmodell
  gegen den Code von 004), CHK010 (SC-002 nicht messbar). Der Rest sind Präzisierungen.
- Durchgang 2 (2026-10-27): Klaus hat alle 26 Vorschläge freigegeben. Eingearbeitet in Spec
  (Clarifications „Review 2026-10-27“, FR-001, FR-001a, FR-002, FR-003, FR-008, FR-011, FR-013a,
  FR-015, SC-002, SC-005, SC-006, SC-007, Edge Cases, Annahmen), research.md (R3, R10, R12, R13),
  Datenmodell, Verträge, Quickstart und Plan („Änderungen nach der Checkliste“).
- `/speckit-implement` wird nicht verwendet (Verfassung, Grundsatz II); die Markierungen setzt
  Klaus.
