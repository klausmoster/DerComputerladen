# Anforderungs-Review Checklist: Start bis zum Hauptmenü

**Purpose**: Prüft, ob Spec und Plan vollständig, eindeutig, widerspruchsfrei und messbar sind,
bevor die Tasks entstehen. Bereiche: Bedienung, Darstellung, macOS-Start und Export,
Bildvorbereitung.
**Created**: 2026-10-19
**Feature**: [spec.md](../spec.md), [plan.md](../plan.md)

**Note**: Erzeugt mit `/speckit-checklist`. Geprüft wird, wie die Anforderungen geschrieben sind,
nicht, ob der spätere Code funktioniert.
**Review Ownership**: Die Checkliste gehört dem Prüfer, hier Klaus. Ein Punkt bekommt `[x]` erst,
wenn er die Anforderung dazu für gut genug hält.
**Marker Semantics**: `[x]` heißt, die Anforderung ist geprüft und in Ordnung. Es heißt nicht,
dass etwas gebaut ist.

## Vollständigkeit

- [x] CHK001 Sind die Texte aller vier Hinweise als Anforderung festgelegt, oder gibt es sie nur
  als Vorschläge im Datenmodell, und ist der Ton (Sie oder du) dafür entschieden?
  [Completeness, Spec §FR-007, Datenmodell]
  → Vorschlag, freigegeben von Klaus: Anrede „du“ hat Klaus entschieden; die vier Hinweistexte stehen jetzt als FR-016 in der Spec.
- [x] CHK002 Ist die Kopfzeile „HAUPTMENÜ“ in der Spec festgelegt, oder steht sie nur im Vertrag?
  [Completeness, Spec §FR-006, Gap]
  → Vorschlag, freigegeben von Klaus: Kopfzeile „HAUPTMENÜ“ in FR-006 aufgenommen.
- [x] CHK003 Ist festgelegt, wie ein nicht verfügbarer Eintrag in Ruhe und ausgewählt aussieht?
  Bisher verweist die Spec nur auf eine künftige Ergänzung des Style-Guides.
  [Gap, Spec §FR-007, Plan Vorarbeiten 1]
  → Vorschlag, freigegeben von Klaus: FR-007 verlangt Kontrast ≥ 3 : 1 in Ruhe und ausgewählt; Plan, Vorarbeit 1: Text und Pfeil in `gehaeuse-dunkel` (4,98 / 4,14 / 3,31 : 1).
- [x] CHK004 Sind Aussehen, Lage und Zeitpunkt des Hinweises beschrieben (sofort oder verzögert,
  wo genau neben der Zeile)? [Gap, Spec §FR-009, Plan R10]
  → Vorschlag, freigegeben von Klaus: FR-017 (sofort, links neben der Zeile, bleibt bis zur nächsten Auswahl); Aussehen im Plan, Vorarbeit 2.
- [x] CHK005 Ist der Mauszeiger beim Überfahren der Einträge festgelegt, wie es der Style-Guide für
  anklickbare Stellen verlangt, auch für nicht verfügbare Einträge? [Gap, Style-Guide Oberfläche]
  → Entschieden (Klaus): Hand nur über verfügbaren Einträgen, sonst Pfeil; FR-018.
- [x] CHK006 Gibt es Abnahmekriterien für die Rasterfassung von Titelbild und Logo, etwa Endgröße,
  nur Farben der Hauptpalette und Freigabe durch Klaus? [Gap, Spec Assumptions, Plan R6]
  → Vorschlag, freigegeben von Klaus: FR-019 (Raster, Hauptpalette, Lesbarkeit) und SC-007 (Freigabe durch Klaus).
- [x] CHK007 Ist festgelegt, wer die Handarbeit an den gerasterten Bildern übernimmt und mit
  welchem Werkzeug? [Completeness, Plan R6]
  → Entschieden (Klaus): Klaus macht den groben Feinschliff in Pixelorama oder Aseprite; Research R6.
- [x] CHK008 Sind Bundle-ID und App-Version als Anforderung erfasst oder ausdrücklich dem Plan
  überlassen? [Completeness, Plan Offene Entscheidungen]
  → Entschieden (Klaus): Bundle-ID `de.klausmoster.dercomputerladen` im Vertrag; dazu FR-014: dieselbe Version in Versionszeile und Finder.

## Klarheit

- [x] CHK009 Ist bei FR-004 eindeutig, auf welchem Bildschirm der größte Faktor berechnet wird,
  wenn mehrere Bildschirme angeschlossen sind? [Ambiguity, Spec §FR-004]
  → Vorschlag, freigegeben von Klaus: FR-004 und Edge Cases: Bildschirm, auf dem das Fenster liegt; Start auf dem Hauptbildschirm.
- [x] CHK010 Ist die Mindestgröße in FR-013 in Bildschirmpixeln oder in macOS-Punkten gemeint? Auf
  Retina-Bildschirmen unterscheidet sich das um den Faktor 2. [Ambiguity, Spec §FR-013]
  → Vorschlag, freigegeben von Klaus: FR-013 nennt 640 × 360 Bildschirmpixel (auf Retina 320 × 180 Punkte).
- [x] CHK011 Ist „Launchpad“ in FR-001 für macOS 27 noch der richtige Begriff? Seit macOS 26 gibt
  es Launchpad in der bisherigen Form nicht mehr. [Clarity, Spec §FR-001]
  → Vorschlag, freigegeben von Klaus: FR-001 nennt Finder, Dock und Spotlight statt Launchpad.
- [x] CHK012 Ist bei FR-001 klar, was „bauen lassen“ heißt: über den Export-Dialog, die
  Kommandozeile oder beides, und mit welchem Ziel? [Clarity, Spec §FR-001, Plan R4]
  → Vorschlag, freigegeben von Klaus: FR-001: reproduzierbar mit einem Befehl, Ergebnis außerhalb der Versionsverwaltung; Befehl im Quickstart.
- [x] CHK013 Ist festgelegt, ob neben Enter auch die Leertaste einen Eintrag auslöst?
  [Ambiguity, Spec §FR-010]
  → Entschieden (Klaus): Leertaste löst aus wie Enter; FR-010.
- [x] CHK014 Ist die Grundfläche des App-Symbols festgelegt, `nacht` oder Ladenschild-Rot?
  [Ambiguity, Spec §FR-002, Plan R5]
  → Entschieden (Klaus): Grundfläche `nacht`; FR-002.
- [x] CHK015 Ist beim Logo eindeutig, auf welches Raster es kommt (Bildraster ×2 oder
  Oberflächenraster) und woran sich seine Lesbarkeit messen lässt? [Clarity, Plan R6]
  → Vorschlag, freigegeben von Klaus: Logo auf dem Bildraster, jeder gemalte Pixel ein Bildpixel, Schriftzug vollständig lesbar (FR-019); Ausweichlösung in R6.

## Widerspruchsfreiheit

- [x] CHK016 FR-009 sagt „Ein Rechtsklick führt nichts aus“, der Style-Guide sagt „Rechtsklick
  zeigt Infos, statt zu handeln“: Welche Regel gilt im Menü? [Conflict, Spec §FR-009,
  Style-Guide Oberfläche]
  → Entschieden (Klaus): Rechtsklick wählt die Zeile und zeigt den Hinweis, löst nichts aus, wie im Style-Guide; FR-009.
- [x] CHK017 Gilt für Menüzeilen nur die Hervorhebung in `signalgelb` mit Pfeil, oder zusätzlich
  die `tusche`-Linie, die der Style-Guide allgemein für den Tastaturfokus vorsieht?
  [Consistency, Spec §FR-011, Style-Guide Oberfläche]
  → Vorschlag, freigegeben von Klaus: FR-011: nur `signalgelb` mit Pfeil, keine zusätzliche Fokuslinie (Menü-Baustein geht vor).
- [x] CHK018 Laut Style-Guide nennt ein Tooltip Funktion und Tastenkürzel, das Feature hat aber
  keine Kürzel je Eintrag. Ist das als Ausnahme festgehalten? [Consistency, Spec Assumptions]
  → Vorschlag, freigegeben von Klaus: als Ausnahme in den Assumptions der Spec festgehalten.
- [x] CHK019 Passen Startgrund (`anzeige-grund`) und die schwarzen Ränder der Skalierung
  zusammen, oder braucht es eine Regel, die beide gleichsetzt? [Consistency, Spec §FR-003,
  Spec §FR-012, Plan R3]
  → Vorschlag, freigegeben von Klaus: Startgrund `anzeige-grund`, die Ränder bleiben schwarz; Unterschied kaum sichtbar (R3).
- [x] CHK020 Stimmt die Regel des Style-Guides „Hauptpalette aus dem Stilanker und den ersten
  Szenen“ mit R7 überein, das auch das Cover C-01 einbezieht? [Consistency, Plan R7]
  → Vorschlag, freigegeben von Klaus: C-01 bleibt dabei; der Style-Guide sagt künftig „die ersten freigegebenen Bilder“ (R7, Vorarbeit 6).
- [x] CHK021 Deckt FR-014 auch die Regel des Datenmodells für eine leere Version ab?
  [Consistency, Spec §FR-014, Datenmodell]
  → Vorschlag, freigegeben von Klaus: FR-014: ohne Version steht nur „PROTOTYP“.
- [x] CHK022 Sollen die App-Version im Bundle und die Versionszeile aus derselben Quelle kommen,
  und steht das irgendwo? [Consistency, Spec §FR-014, Plan Export-Preset]
  → Vorschlag, freigegeben von Klaus: FR-014: dieselbe Versionsnummer zeigt der Finder in den Informationen zur App.

## Messbarkeit der Erfolgskriterien

- [x] CHK023 Ist für SC-001 festgelegt, wie gemessen wird: Kaltstart oder erneuter Start, Stoppuhr
  oder Protokoll? [Measurability, Spec §SC-001]
  → Vorschlag, freigegeben von Klaus: SC-001: Stoppuhr bis zur ersten Reaktion, schlechtester von drei Starts, ohne den ersten nach dem Export.
- [x] CHK024 Lässt sich „Kein Pixel ist unscharf“ objektiv feststellen, etwa über ein vergrößertes
  Bildschirmfoto? [Measurability, Spec §SC-004, Spec §FR-012]
  → Vorschlag, freigegeben von Klaus: SC-004: Bildschirmfoto in Originalgröße, Rasterpixel als gleichfarbige Blöcke, Schrift ohne Zwischentöne.
- [x] CHK025 Hat der Seitenvergleich mit dem Entwurf eine Toleranz, pixelgenau oder nach
  Augenmaß? [Measurability, Spec §SC-006]
  → Vorschlag, freigegeben von Klaus: SC-006: Farben und Schriften genau, Lage und Größen auf 2 Oberflächenpixel, nur das Logo darf kleiner sein.
- [x] CHK026 Ist für „unter 100 ms“ eine Messmethode genannt, oder ist das als Augenmaß gemeint?
  [Measurability, Spec §SC-003]
  → Vorschlag, freigegeben von Klaus: SC-003: ohne wahrnehmbare Verzögerung, spätestens im nächsten Bild.
- [x] CHK027 Ist messbar beschrieben, wann das App-Symbol „wie macOS es erwartet“ aussieht, etwa
  ohne grauen Rahmen unter macOS 26 und neuer? [Measurability, Spec §FR-002]
  → Vorschlag, freigegeben von Klaus: FR-002: im Dock von macOS 27 ohne grauen Rahmen, in der Listenansicht des Finders erkennbar.

## Abläufe und Grenzfälle

- [x] CHK028 Ist festgelegt, was beim Überfahren der Kopfzeile oder der Lochränder passiert und ob
  der Hinweis stehen bleibt, wenn die Maus das Menü verlässt? [Edge Case, Spec Edge Cases, Gap]
  → Vorschlag, freigegeben von Klaus: Edge Cases: Kopfzeile und Lochränder ändern die Auswahl nicht; der Hinweis bleibt stehen.
- [x] CHK029 Ist die Tab-Taste (und Shift+Tab) als Navigation festgelegt oder ausgeschlossen?
  [Coverage, Gap]
  → Entschieden (Klaus): Tab und Shift+Tab wählen wie Pfeil runter und hoch; FR-010.
- [x] CHK030 Ist beschrieben, wie das Bild auf Mac-Bildschirmen mit Kameraaussparung liegt?
  [Edge Case, Gap]
  → Vorschlag, freigegeben von Klaus: Edge Cases: das ganze Bild liegt unterhalb der Aussparung; Prüfung im Quickstart.
- [x] CHK031 Gibt es eine Anforderung für ein fehlendes oder nicht ladbares Bild bzw. eine fehlende
  Schrift, oder ist das bewusst ausgeschlossen? [Exception Flow, Gap]
  → Vorschlag, freigegeben von Klaus: bewusst ausgeschlossen: fehlende Dateien sind ein Fehler beim Bauen (Assumptions).

## Abhängigkeiten und Annahmen

- [x] CHK032 Ist die Annahme bestätigt, dass die Rasterfassung von Titelbild und Logo in dieses
  Feature gehört? [Assumption, Spec Clarifications]
  → Entschieden (Klaus): Ja, die Rasterfassung gehört in dieses Feature.
- [x] CHK033 Ist festgehalten, was gilt, wenn das App-Menü des Exports kein Cmd+Q mitbringt?
  [Dependency, Spec §FR-008, Plan R11]
  → Vorschlag, freigegeben von Klaus: R11: fehlt Cmd+Q, kommt in diesem Feature ein Beenden-Eintrag über NativeMenu dazu.

## Notes

- `[x]` nur setzen, wenn die Anforderung geprüft und in Ordnung ist; offene Punkte bleiben leer.
- Erst wenn alle Punkte abgehakt oder bewusst zurückgestellt sind, folgt `/speckit-tasks`.
- `/speckit-implement` nutzen wir nicht (Verfassung, Grundsatz II); die Checkliste ist das Tor
  vor den Tasks.
- `checklists/requirements.md` ist die eingebaute Qualitätsprüfung der Spec und wird von
  `/speckit-specify` und `/speckit-clarify` gepflegt.
- Befunde und Entscheidungen stehen direkt beim Punkt: „Entschieden (Klaus)“ hat Klaus selbst
  entschieden, „Vorschlag, freigegeben von Klaus“ hat Claude vorgeschlagen und Klaus am
  2026-10-19 freigegeben. Alle 33 Punkte sind erledigt.
