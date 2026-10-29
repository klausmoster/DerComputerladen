# Anforderungs-Review Checklist: Godot- und Spielarchitektur mit Prüf-Agent

**Purpose**: Prüft, ob Spec und Plan vollständig, eindeutig, widerspruchsfrei und messbar sind,
bevor die Tasks entstehen. Bereiche: Geltungsbereich des Prüfers, Leitfaden, Ablauf, Bestand und
Behebung, Abnahmekriterien.
**Created**: 2026-10-28
**Feature**: [spec.md](../spec.md), [plan.md](../plan.md)

**Note**: Erzeugt mit `/speckit-checklist`. Geprüft wird, wie die Anforderungen geschrieben sind,
nicht, ob der spätere Code funktioniert.
**Review Ownership**: Die Checkliste gehört dem Prüfer, hier Klaus. Ein Punkt bekommt `[x]` erst,
wenn er die Anforderung dazu für gut genug hält.
**Marker Semantics**: `[x]` heißt, die Anforderung ist geprüft und in Ordnung. Es heißt nicht,
dass etwas gebaut ist.

Jeder Punkt hat einen Vorschlag von Claude („→ Vorschlag“). Was er an Spec oder Plan ändern würde,
steht dabei. Eingearbeitet wird erst nach Klaus' Freigabe; sie kam am 2026-10-28 für alle Punkte. Stil-, Text- und Architektur-Prüfer
laufen bei dieser Checkliste nicht: Die Spec legt keine Wortlaute und keine Oberfläche fest, und den
Architektur-Prüfer gibt es erst ab Phase 2 (research.md, R11).

## Widersprüche

- [x] CHK001 Passt Story 2, Szenario 1 zur Regel, dass der Prüfer auslässt, was Tests messen? Das
  Szenario lässt ihn ein neues Autoload melden; genau das misst aber ab Phase 4
  `test_genau_diese_autoloads`. [Conflict, Spec §US2, §FR-014; Plan R6; Vertrag architektur-pruefer
  Punkt 7]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Szenario 1 nimmt einen Verstoß, den kein Test misst: „Ein Baustein ruft den, der ihn
  einsetzt, direkt auf → Befund zu AR-02.“ Das Autoload ohne Grund wandert nach Story 3 (Plan), wo
  es vor jedem Test auffallen soll.
- [x] CHK002 Was ist „Code“ in FR-016? Zählen Tests dazu? Die Spec sagt in den Edge Cases, der Prüfer
  prüfe Tests nur auf Testbarkeit der Kerne; der Plan setzt ihn in Phase 4 trotzdem auf ein reines
  Testskript an. [Ambiguity, Conflict, Spec §FR-016, Edge Cases; Plan „Prüfer je Phase“]
  → Vorschlag, freigegeben von Klaus (2026-10-28): FR-016 sagt „Skripte, Szenen und Resources des Spiels und der Werkzeuge unter `src/`“.
  Tests lösen den Architektur-Prüfer nicht aus, `src/addons/` nie. Python-Werkzeuge unter `tools/`
  gehören nicht dazu. Phase 4 bekommt nur den Text-Prüfer für die Testmeldungen.
- [x] CHK003 Widerspricht die Annahme „Stil- und Text-Prüfer laufen nur über den Leitfaden und die
  Doku, soweit die Arbeitsweise das verlangt“ dem Plan? Dort laufen sie über Leitfaden und Doku gar
  nicht, nur der Text-Prüfer über die Testmeldungen. [Conflict, Spec §Assumptions; Plan „Prüfer je
  Phase“]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Die Annahme sagt: „Stil- und Text-Prüfer: nur der Text-Prüfer über die Testmeldungen
  in Phase 4. Leitfaden und Arbeitsweise sind keine Texte im Spiel oder in den Werkzeugen.“
- [x] CHK004 Gilt SC-005 auch für die Bestandsprüfung? Sie hat drei Läufe (R5), SC-005 erlaubt einen
  je Phase. [Consistency, Spec §SC-005; Plan R5]
  → Vorschlag, freigegeben von Klaus (2026-10-28): SC-005 gilt für die Phasenprüfung „in Features nach 008“; die Bestandsprüfung ist
  ausgenommen und hat ihre eigene Grenze von drei Läufen und je einer Nachprüfung.

## Vollständigkeit

- [x] CHK005 Wird die Prüfung eines Plans (Story 3) vor dem ersten echten Feature je erprobt? Die
  Fehlerprobe misst nur den Auftrag „Phase“, und R11 lässt die Planprüfung für 008 aus. Der
  Unabhängige Test von Story 3 („Plan von 006 vorlegen“) steht in keiner Phase. [Gap, Spec §US3;
  Plan R8, R11; Quickstart Phase 2]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Phase 2 bekommt eine Planprobe: der Plan von 006 mit research.md und den Verträgen
  als Auftrag „Plan“. Erwartet ist ein Bericht in der Form des Vertrags. Aufwand: ein Prüfer-Lauf,
  eine [C]-Aufgabe.
- [x] CHK006 Was geschieht, wenn der Prüfer die Fehlerprobe nicht besteht? SC-002 verlangt alle fünf,
  sagt aber nicht, was dann folgt. [Gap, Spec §SC-002; Plan R8]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Claude schärft die Anweisung des Prüfers nach und wiederholt die Probe, höchstens
  zweimal. Besteht er dann nicht, entscheidet Klaus: weiter mit Einschränkung oder Feature anhalten.
  Jede Wiederholung steht im „Nachmessen“.
- [x] CHK007 Gehören Resources (`.tres`) und `project.godot` zur Bestandsprüfung? FR-025 nennt
  „Skript- und Szenendateien“, AR-04 (Daten als Resources) und AR-03 (Autoloads) lassen sich aber
  nur an diesen Dateien beurteilen. [Gap, Spec §FR-025, §SC-003; Plan R5]
  → Vorschlag, freigegeben von Klaus (2026-10-28): FR-025 und SC-003 nennen Skripte, Szenen, Resources und `project.godot`, ohne
  `addons/` und `test/`. Heute sind es drei `.tres`.
- [x] CHK008 Kommt der Code von 007 in die Bestandsprüfung? Die Annahme sagt „Stand von `main` zu
  ihrem Beginn“, der Branch von 008 enthält 007 aber erst, wenn `main` hereingeholt wird. [Gap,
  Dependency, Spec §Assumptions]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Vor Phase 3 fragt Claude, ob 007 gemergt ist. Wenn ja, holt Claude `main` mit
  Klaus' OK in den Branch, dann erst startet die Bestandsprüfung. Wenn nein, prüft sie ohne 007,
  und der Bericht sagt das.
- [x] CHK009 Wie entscheidet Klaus die Regeln in Phase 1 praktisch? R2 sagt „in einer Durchsicht“,
  aber nicht, in welcher Form die Antworten kommen und wo sie stehen. [Clarity, Plan R2]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Claude legt eine Tabelle vor: Regel, Kurzfassung, Empfehlung. Klaus antwortet wie bei
  dieser Checkliste („alle wie Vorschlag außer …“). Claude setzt danach den Stand jeder Regel;
  die echten Alternativen kommen davor einzeln als Auswahl.
- [x] CHK010 Wie wird eine Ausnahme in einer Szene ohne Skript oder in einer Resource festgehalten?
  Der Vertrag verlangt den Kommentar „im Skript des Knotens“. [Edge Case, Gap, Vertrag leitfaden
  „Ausnahmen“; Plan R3]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Hat die Stelle kein Skript, reicht die Zeile in der Tabelle, mit Datei und Knoten.
  Der Prüfer erkennt die Ausnahme dann an der Tabelle allein.
- [x] CHK011 Was tut Claude, wenn ein Lauf der Bestandsprüfung nicht alle Dateien schafft? R5
  begründet drei Läufe mit der Größe, regelt aber nicht den Fall, dass ein Lauf unter „Unsicher“
  Dateien meldet, die er nicht gelesen hat. [Edge Case, Plan R5; Spec §SC-003]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Dann teilt Claude diesen Teil, etwa die Werkstatt in Ansichten und Rest, und lässt nur
  die fehlenden Dateien noch einmal prüfen. SC-003 gilt erst als erfüllt, wenn jede Datei genannt ist.

## Klarheit

- [x] CHK012 Was heißt „ein System“ bei der Grenze der Behebung? FR-027 trennt „ein System“ von
  „mehrere Systeme“; die Systemliste in `Features.md` hat aber 01 bis 11, und der Titel gehört zu
  10, Spielstände zu 11. [Ambiguity, Spec §FR-027, Clarify]
  → Vorschlag, freigegeben von Klaus (2026-10-28): „Ein System“ heißt: Die Behebung ändert Dateien in nur einem der Ordner `core/`,
  `scenes/title/`, `scenes/game/`, `ui/` oder `tools/werkstatt/` und keine Schnittstelle, die ein
  anderer Ordner nutzt (Signal, öffentliche Methode, Autoload). Alles andere wird ein eigenes Feature.
- [x] CHK013 Welcher Spielstand belegt „lädt wie vorher“? R9 nennt „einen Spielstand“, FR-028
  „vorhandene Spielstände“. [Clarity, Measurability, Spec §FR-028, US5; Plan R9]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Vor Phase 5 legt Claude zwei Spielstände an (Mittel, Seed 4711, gespeichert 1987;
  Schwer mit einem Eingriff, gespeichert 1993) und sichert sie. Nach der Phase lädt Claude beide mit
  einem kurzen Skript, Klaus einen davon von Hand. Dazu laufen die vorhandenen Tests der Spielstände.
- [x] CHK014 Sind „Muster, die das Spiel für ein vorgemerktes System braucht“ abgegrenzt? FR-003 sagt
  nicht, was „vorgemerkt“ heißt. [Ambiguity, Spec §FR-003; Plan R12]
  → Vorschlag, freigegeben von Klaus (2026-10-28): „vorgemerkt“ heißt: das System steht in `Features.md` und hat Einträge in
  `Feature_Ideas.md`. Die Liste der Muster in R12 gilt als Umsetzung von FR-003.
- [x] CHK015 Ist die Schwere eines Befunds in der Spec erklärt? FR-011 nennt nur die vier Stufen, die
  Bedeutung steht allein im Vertrag des Prüfers. [Clarity, Spec §FR-011; Vertrag architektur-pruefer
  „Schwere“]
  → Vorschlag, freigegeben von Klaus (2026-10-28): FR-011 verweist auf die Tabelle „Schwere“ im Vertrag; der Leitfaden übernimmt sie im
  Abschnitt „So liest man eine Regel“, damit Prüfer und Klaus dieselbe Tabelle sehen.

## Messbarkeit

- [x] CHK016 Lässt sich SC-006 in 008 überhaupt messen? Es spielt im ersten Feature danach. [Measurability,
  Spec §SC-006]
  → Vorschlag, freigegeben von Klaus (2026-10-28): SC-006 bleibt, mit dem Zusatz: In 008 belegt es Phase 2 an der Aufgaben-Vorlage und am
  Skill; im nächsten Feature trägt Claude das Ergebnis in `ki_pruefung.md` nach. Ebenso SC-007.
- [x] CHK017 Ist SC-001 („alle Teile aus FR-005“) prüfbar, ohne jede Regel von Hand zu lesen?
  [Measurability, Spec §SC-001; Quickstart Phase 1]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Claude zählt mit einem kurzen Skript je `### AR-` die acht fett gesetzten Teile und
  den Stand; die Zahl steht in der Bitte um Abnahme von Phase 1. Ein Test wird es nicht, weil der
  Leitfaden kein Teil des Spiels ist.

## Abhängigkeiten und Annahmen

- [x] CHK018 Ist festgehalten, dass ein neuer Agent erst in einer neuen Sitzung bereitsteht? Für
  Phase 2 heißt das: Fehlerprobe und Planprobe laufen über einen allgemeinen Agent, der die Datei
  liest. [Dependency, Plan R4; ki_pruefung „Erfahrungen“]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Plan, Phase 2, sagt das ausdrücklich. Den Agent-Typ nutzt Claude ab der ersten neuen
  Sitzung; Ergebnis beider Wege steht im „Nachmessen“.
- [x] CHK019 Hält die Spec fest, dass auch die Behebung mit 007 kollidieren kann, nicht nur
  `Features.md` und `Feature_Ideas.md`? 007 ändert womöglich dieselben Skripte. [Dependency, Spec
  §Assumptions]
  → Vorschlag, freigegeben von Klaus (2026-10-28): Annahme „Merge“ ergänzt: Phase 5 beginnt erst, wenn 007 gemergt und `main` im Branch
  ist (CHK008), sonst arbeitet die Behebung an veraltetem Code.

## Notes

- Eingearbeitet wird nach Klaus' Freigabe in Spec, Plan, research.md, Verträge und Quickstart.
- Nicht als eigener Punkt übernommen: die Fließkomma-Frage (betrifft die Wirtschaft, steht in
  `docs/offene-punkte.md`); die Entscheidungen zu Ereigniskatalog und Probe „speichern, laden,
  vergleichen“ (gehören in Phase 1, R12).
