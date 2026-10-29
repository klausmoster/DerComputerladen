# Feature Specification: Renderer Compatibility

**Feature Branch**: `feature/009-renderer-compatibility`

**System**: 11 Infrastruktur (Darstellung, Export und Selbsttest); berührt jedes Bild des Spiels

**Created**: 2026-10-29

**Status**: Umgesetzt, im Abschluss (2026-10-29)

**Input**: User description: "Feature 009 ‚Renderer Compatibility': Wechsel des Renderers von
Forward+ auf Compatibility auf Windows, macOS und Linux. Grundlage: docs/entscheidungen/renderer.md
und Klaus' Entscheidung vom 2026-10-28 (Compatibility überall; eigenes Feature, 007 bleibt mit
Forward+ abgeschlossen; unter macOS opengl3, ANGLE über Metal nur bei Abweichungen). Ungeprüft:
Läufe mit Compatibility auf Mac und Linux, ANGLE in den Export-Vorlagen, ob das Protokoll des
Selbsttests den laufenden Renderer liest, ANGLE unter macOS über Metal laut Quelltext. Der
Selbsttest aus 007 läuft nach dem Wechsel neu, Referenzbilder dürfen sich ändern. Regeln in
CLAUDE.md und Verfassung Grundsatz I ändern sich nur auf Klaus' Beschluss, als eigene Aufgabe."

## Clarifications

### Entscheidung 2026-10-28

Klaus hat den Vorschlag in [`docs/entscheidungen/renderer.md`](../../docs/entscheidungen/renderer.md)
entschieden, Frage für Frage als Auswahl:

- Q: Welcher Renderer? → A: **Compatibility auf allen drei Systemen** (Klaus, nach Empfehlung).
  Verworfen: Forward+ behalten, weil das Spiel auf Rechnern wie dem Boot-Camp-Mac still abstürzt;
  Compatibility nur unter Windows, weil dann zwei Renderer zu prüfen wären und Windows mit 95 % der
  Spieler ohnehin alles in Compatibility können muss.
- Q: Wann umsetzen? → A: **als eigenes Feature** (Klaus, gegen die Empfehlung). Feature 007 bleibt
  mit Forward+ abgeschlossen; dieses Feature ändert CLAUDE.md, die Verfassung (Grundsatz I), FR-017
  und R13 aus 007. Verworfen: ein Nachtrag in Feature 007.
- Q: Welcher Treiber unter macOS? → A: **Godots Vorgabe, Apples OpenGL** (Klaus, nach Empfehlung).
  ANGLE über Metal nur, wenn der Lauf auf dem Mac Abweichungen zeigt.

### Clarify 2026-10-29

Fragen aus `/speckit-clarify`, von Klaus einzeln als Auswahl beantwortet:

- Q: Wie soll die neue Regel zum Renderer in CLAUDE.md und Verfassung Grundsatz I lauten? → A:
  fest (Klaus, nach Empfehlung): „Der Renderer ist Compatibility, auf allen drei Systemen. Mittel,
  die es nur in Forward+ gibt (HDR, Kantenglättung, Compute), werden nicht genutzt.“ Die Verbote für
  Mobile und Android bleiben; die alte Regel bleibt mit „bis 2026-10-29“ sichtbar. Verworfen: nur
  „Der Renderer ist Compatibility“ ohne Satz zu den Mitteln, weil dann jeder Plan neu klären müsste,
  was erlaubt ist; Compatibility mit ausdrücklich offenem Rückweg zu Forward+, aus demselben Grund.
- Q: Soll der Style-Guide einen Satz bekommen, dass HDR, Kantenglättung und Glühen über Weiß keine
  Mittel mehr sind? → A: ja, ein Satz mit Verweis auf die Verfassung, Wortlaut mit Klaus' Freigabe
  (Klaus, nach Empfehlung). Verworfen: Style-Guide unverändert, weil der Stil-Prüfer sonst nichts
  davon weiß.
- Q: Muss der Selbsttest auch unter Windows in Parallels laufen, bevor Klaus das Feature abnimmt? →
  A: willkommen, kein Muss (Klaus, nach Empfehlung). Pflicht sind Mac, Linux und der
  Boot-Camp-Rechner; ein Lauf in Parallels steht im Quickstart als Kann. Verworfen: Parallels als
  Pflicht.

### Checkliste 2026-10-29

Aus `/speckit-checklist` (`checklists/review.md`, CHK001 bis CHK018), von Klaus am 2026-10-29 mit
allen Vorschlägen freigegeben. Was sich an der Spec ändert:

- „Kantenglättung“ heißt in Regel und Style-Guide „Kantenglättung des Bildes“, denn im Style-Guide
  meint das Wort sonst die Schrift (CHK013). Laut Godot-Handbuch fehlen in Compatibility 2D-HDR,
  MSAA in 2D, FXAA und SMAA; MSAA in 3D und Glühen gibt es dort, Glühen nur ohne HDR (CHK014).
  Deshalb lautet die Klammer der Regel jetzt „(HDR, Kantenglättung des Bildes in 2D, Compute)“.
- Aus dem Satz in CLAUDE.md „Keine Rücksicht auf Compatibility/Mobile oder GLES-Beschränkungen“ wird
  „Keine Rücksicht auf den Renderer Mobile“ (CHK015).
- FR-004 nennt Startgrund und schwarze Ränder und misst an den Fotos des Selbsttests und am echten
  Fenster; die Fotos allein zeigen nur das Bild in 640 × 360 (CHK001, CHK016, CHK017). Die Werkstatt
  kommt dazu (CHK003).

### Begriffe

- **Renderer:** der Teil von Godot, der das Bild malt. Bisher Forward+, das auf dem Rechner Vulkan,
  Direct3D 12 oder Metal braucht. Künftig Compatibility, das mit OpenGL 3.3 auskommt, wie es auch
  ein Büro-PC von 2012 hat.
- **Grafikschnittstelle:** die Sprache, in der der Renderer mit der Grafikkarte spricht, etwa
  OpenGL, Direct3D 12 oder Metal. Das Protokoll des Selbsttests nennt sie unter `system.grafik_api`.
- **ANGLE:** ein Übersetzer, der OpenGL-Befehle in eine andere Schnittstelle übersetzt: unter
  Windows in Direct3D 11, unter macOS in Metal. Godot nimmt ihn unter Windows von selbst, wenn der
  Treiber kein brauchbares OpenGL hat.
- **Boot-Camp-Rechner:** Klaus' MacBook Pro von 2015 mit Windows und einer AMD R9 M370X. Dort
  startet Forward+ ohne Meldung nicht; mit erzwungenem OpenGL liefen in Feature 007 alle 37
  Schritte (damals; heute hat der Selbsttest 45), und die 35 Fotos glichen den Mac-Referenzen.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Das Spiel startet auf dem Boot-Camp-Rechner (Priority: P1)

Ein Spieler mit einem älteren Windows-Rechner, etwa Klaus' Boot-Camp-Mac, lädt das Spiel, packt es
aus und startet es per Doppelklick. Der Titel erscheint, er kommt ins Hauptmenü und kann ein neues
Spiel beginnen, ohne eine Startoption zu kennen oder eine Datei anzulegen.

**Why this priority**: Das ist der Anlass des Features. Heute stürzt das Spiel genau bei der
Zielgruppe still ab, die den Computerladen der 90er erlebt hat und eher auf älteren Notebooks und
Macs mit Windows spielt.

**Independent Test**: Den Windows-Export auf den Boot-Camp-Rechner kopieren und per Doppelklick
starten; Titel und Hauptmenü erscheinen.

**Acceptance Scenarios**:

1. **Given** der Windows-Export dieses Features auf dem Boot-Camp-Rechner, **When** Klaus ihn per
   Doppelklick startet, **Then** erscheint der Titel ohne Startoption und ohne zusätzliche Datei.
2. **Given** dieselbe Selbsttest-App auf dem Boot-Camp-Rechner, **When** Klaus sie per Doppelklick
   startet, **Then** laufen alle Schritte durch, und das Protokoll nennt Compatibility als Renderer
   und die tatsächlich laufende Grafikschnittstelle.

---

### User Story 2 - Das Bild bleibt auf allen drei Systemen gleich (Priority: P1)

Nach dem Wechsel sieht das Spiel auf Mac, Windows und Linux so aus wie vorher: dieselben Farben der
Palette, dasselbe Pixelraster, kein Weichzeichnen. Der Selbsttest aus Feature 007 belegt das mit
seinen Fotos.

**Why this priority**: Der Wechsel lohnt nur, wenn er das Bild nicht verändert. Der Style-Guide
(feste Palette, ganzzahlige Skalierung, harte Pixel) gilt unverändert.

**Independent Test**: Selbsttest auf dem Mac laufen lassen und mit den Referenzbildern vergleichen.

**Acceptance Scenarios**:

1. **Given** der Selbsttest dieses Features auf dem Mac, **When** er durchläuft und mit den
   Referenzbildern verglichen wird, **Then** sind alle Fotos Pixel für Pixel gleich, oder jede
   Abweichung ist benannt und von Klaus beurteilt.
2. **Given** der Selbsttest unter Linux und unter Windows, **When** Klaus ihn startet und das Zip
   zurückgibt, **Then** laufen alle Schritte durch, und der Vergleich mit den Referenzbildern des
   Macs zeigt keine Abweichung, oder jede ist benannt und beurteilt.
3. **Given** der Mac-Lauf zeigt Abweichungen gegenüber den bisherigen Referenzbildern, **When**
   Claude sie vorlegt, **Then** entscheidet Klaus, ob unter macOS ANGLE über Metal versucht wird
   oder ob neue Referenzbilder abgenommen werden.

---

### User Story 3 - Regeln und Doku sagen dasselbe wie das Spiel (Priority: P2)

Wer später am Spiel arbeitet, Klaus, Claude, der Godot-Agent oder ein Prüfer, findet überall
dieselbe Regel: Der Renderer ist Compatibility. Die alte Regel „Renderer bleibt Forward+“ bleibt
mit Datum sichtbar, damit klar ist, warum gewechselt wurde.

**Why this priority**: Ohne geänderte Regel würde der nächste Plan gegen die Verfassung geprüft und
den Wechsel als Verstoß melden. Sie ändert sich aber nur auf Klaus' Beschluss. Die Regel ändert sich
trotzdem zuerst, vor der Einstellung (plan.md, R7).

**Independent Test**: Nach dem Feature nach „Forward+“ suchen: Jede Fundstelle ist entweder
Geschichte (ältere Specs, alte Regel mit Datum) oder geändert.

**Acceptance Scenarios**:

1. **Given** Klaus' Beschluss zur neuen Regel, **When** die Aufgabe dazu erledigt ist, **Then**
   nennen CLAUDE.md und Verfassung Grundsatz I Compatibility als Renderer und schließen die Mittel
   aus, die es nur in Forward+ gibt; die Verfassung mit neuer Version.
2. **Given** die Spec von Feature 007, **When** dieses Feature fertig ist, **Then** tragen FR-017
   und die Recherche zum Renderer (R13) einen sichtbaren Vermerk „bis 2026-10-29: Forward+“ mit
   Verweis auf dieses Feature.
3. **Given** der Style-Guide, **When** dieses Feature fertig ist, **Then** hält er in einem Satz
   fest, dass HDR, Glühen über Weiß als Folge von HDR und Kantenglättung des Bildes keine Mittel
   sind.

---

### Edge Cases

- **Ein Rechner hat weder OpenGL 3.3 noch Direct3D 11:** Godot zeigt seine eigene Meldung „Unable
  to initialize video driver“ und beendet sich, unter Linux nach dem Versuch mit OpenGL ES (laut
  Quelltext von 4.7.2, research.md, R8). Eine eigene Meldung des Spiels gehört
  nicht zu diesem Feature.
- **Windows mit schlechtem OpenGL-Treiber:** Godot soll von selbst auf ANGLE über Direct3D 11
  ausweichen. Das klappt nur, wenn ANGLE im Windows-Export enthalten ist; das ist ungeprüft (FR-006).
- **Apples OpenGL zeigt auf dem Mac Abweichungen:** Dann kommt ANGLE über Metal in Frage. Die
  Godot-Doku schreibt dazu „über natives OpenGL“, der Quelltext zeigt Metal (`renderer.md`, 3).
  Welche Lesart stimmt, ist erst zu prüfen, wenn ANGLE gebraucht wird.
- **Linux unter X11 ohne volles OpenGL 3.3:** Godot weicht auf OpenGL ES aus. Das Protokoll muss
  zeigen, was tatsächlich läuft.
- **Ein Selbsttest-Lauf auf einem Rechner mit Vulkan oder Direct3D 12:** Auch dort läuft jetzt
  Compatibility; das Protokoll darf nicht mehr Forward+ zeigen.
- **Ältere Specs 001 bis 006 und Feature 008 nennen Forward+:** Sie bleiben als Geschichte stehen
  und werden nicht geändert.

## Requirements *(mandatory)*

### Functional Requirements

**Renderer**

- **FR-001**: Spiel und Selbsttest-App MÜSSEN auf Windows, macOS und Linux mit Compatibility
  laufen, ohne Startoption und ohne zusätzliche Datei beim Spieler.
- **FR-002**: Unter macOS MUSS Godots Vorgabe gelten (Apples OpenGL). ANGLE über Metal DARF NUR
  eingestellt werden, wenn der Mac-Lauf Abweichungen zeigt und Klaus es entscheidet.
- **FR-003**: Einstellungen, die nur für Forward+ gelten (die Wahl von Direct3D 12 unter Windows,
  das Verbot des Ausweichens auf OpenGL), MÜSSEN entfallen, damit keine bedeutungslose Einstellung
  im Projekt stehen bleibt.
- **FR-004**: Was der Renderer heute malt, MUSS gleich bleiben: Fenstergröße, ganzzahlige
  Skalierung, harte Pixel, Farben der Palette, der Startgrund in `anzeige-grund` ohne Logo der Engine
  und schwarze Ränder bei krummen Fenstergrößen. Maßstab sind die Fotos des Selbsttests gegen die
  Referenzbilder (SC-002, SC-003) für das Bild in 640 × 360 und ein Blick ins echte Fenster je System
  für Vergrößerung, Ränder und Startgrund (SC-007). Auch die Zeitleisten-Werkstatt startet und zeigt
  ihre Schrift wie bisher; das prüft Claude im echten Fenster bei 1920 × 925.

**Selbsttest und Belege**

- **FR-005**: Das Protokoll des Selbsttests MUSS Renderer und Grafikschnittstelle nennen, die
  tatsächlich laufen, nicht die eingestellten. Laut Code liest es beide schon beim Lauf; die
  Beispieldaten der Tests nennen noch Forward+ und Metal und MÜSSEN zum neuen Stand passen.
- **FR-006**: Es MUSS geprüft und festgehalten werden, ob der Windows-Export ANGLE enthält, sodass
  Godot bei schlechtem OpenGL-Treiber ausweichen kann. Fehlt ANGLE, legt Claude Klaus vor, ob es
  dazukommt.
- **FR-007**: Der Selbsttest MUSS nach dem Wechsel auf dem Mac laufen und mit den Referenzbildern
  verglichen werden. Auf Linux und auf dem Boot-Camp-Rechner startet Klaus ihn; die Ergebnisse
  kommen als Zip zurück und werden ebenso verglichen.
- **FR-008**: Neue Referenzbilder DÜRFEN NUR nach Klaus' Abnahme entstehen. Weichen Fotos ab, legt
  Claude jede Abweichung mit Bild vor, bevor etwas ersetzt wird.

**Regeln und Doku**

- **FR-009**: CLAUDE.md („Harte Rahmenbedingungen“) und Verfassung Grundsatz I MÜSSEN nach Klaus'
  Beschluss lauten: „Der Renderer ist Compatibility, auf allen drei Systemen. Mittel, die es nur in
  Forward+ gibt (HDR, Kantenglättung des Bildes in 2D, Compute), werden nicht genutzt.“ Die Verbote
  für Mobile und Android bleiben; aus „Keine Rücksicht auf Compatibility/Mobile oder
  GLES-Beschränkungen“ in CLAUDE.md wird „Keine Rücksicht auf den Renderer Mobile“, denn
  Compatibility und der Rückfall auf OpenGL ES unter Linux sind gewollt. Die alte Regel bleibt mit
  „bis 2026-10-29“ sichtbar. Die Verfassung ändert sich
  über `/speckit-constitution` mit neuer Version. Das ist eine eigene Aufgabe, die erst mit Klaus'
  Beschluss erledigt ist.
- **FR-009a**: Der Style-Guide MUSS einen Satz bekommen, dass HDR, Glühen über Weiß als Folge von
  HDR (Farbwerte über 1,0) und Kantenglättung des Bildes keine Mittel sind, mit Verweis auf die
  Verfassung; die Kantenglättung der Schrift regelt weiter der Abschnitt Schrift. Der Satz steht am
  Ende der Zeile mit den Godot-Einstellungen unter „Raster und Auflösung“, die dazu den Renderer und
  das fehlende `snap_2d_vertices_to_pixel` nennt. Den Wortlaut gibt Klaus frei.
- **FR-010**: In Feature 007 MÜSSEN FR-017, die Klärung „Was passiert ohne Forward+?“, R13,
  `quickstart.md` und die Lernnotiz zum Renderer einen Vermerk „bis 2026-10-29“ mit Verweis auf
  dieses Feature bekommen; der alte Text bleibt lesbar.
- **FR-011**: `docs/spielbeschreibung/` MUSS den neuen Renderer nennen, mindestens die Abschnitte
  zur Darstellung und zu Build und Tests.
- **FR-012**: Der offene Punkt „Renderer“ in `docs/offene-punkte.md` MUSS mit Verweis auf dieses
  Feature geschlossen werden, ebenso die Frage nach fehlenden Direct3D-12-Dateien, die mit dem
  Wechsel entfällt.
- **FR-013**: Der Entscheidungsvorschlag `docs/entscheidungen/renderer.md` MUSS mit der Spec
  committet werden und unverändert bleiben bis auf einen Vermerk, wo die Entscheidung umgesetzt ist.

### Key Entities

- **Protokoll eines Laufs:** Systemdaten des Rechners, darunter Renderer und Grafikschnittstelle,
  dazu das Ergebnis jedes Schritts. Beleg dafür, was auf einem Rechner tatsächlich lief.
- **Referenzbild:** Foto eines Schritts auf dem Mac, von Klaus als richtig abgenommen. Maßstab für
  die Fotos aller Systeme.
- **Entscheidung zum Renderer:** `docs/entscheidungen/renderer.md` mit Befund, Abwägung und Klaus'
  drei Antworten; Grundlage dieser Spec.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Auf dem Boot-Camp-Rechner startet das Spiel per Doppelklick und zeigt den Titel; der
  Selbsttest läuft dort ohne Startoption mit allen Schritten durch.
- **SC-002**: Auf dem Mac sind alle Fotos des Selbsttests gleich den Referenzbildern, oder jede
  Abweichung ist von Klaus beurteilt und die Referenz danach abgenommen. Die Fotos belegen das Bild
  in 640 × 360, nicht die Vergrößerung ins Fenster (dafür SC-007).
- **SC-003**: Auf Linux und dem Boot-Camp-Rechner zeigt der Vergleich mit den Referenzbildern des
  Macs 0 Abweichungen, oder jede ist benannt und beurteilt. Ein Lauf in Parallels zählt dazu, wenn
  es ihn gibt, ist aber keine Bedingung.
- **SC-004**: Alle drei Protokolle nennen Compatibility als Renderer.
- **SC-005**: Eine Suche nach „Forward+“ in CLAUDE.md, Verfassung, Spielbeschreibung und den Regeln
  der Arbeitsweise findet nur noch Stellen mit Datum, die die alte Regel als Geschichte zeigen.
- **SC-006**: Alle Tests sind grün, zweimal hintereinander mit derselben Zahl der Prüfungen.
- **SC-007**: Je System zeigt das echte Fenster beim Start den Startgrund in `anzeige-grund` und bei
  einer krummen Fenstergröße ganzzahlig vergrößerte, harte Pixel mit schwarzen Rändern: auf dem Mac
  mit Bildschirmfoto durch Claude, unter Windows und Linux mit einem Blick durch Klaus nach der
  Prüfliste im Quickstart. Die Werkstatt zeigt auf dem Mac ihre Schrift wie vor dem Wechsel.

## Assumptions

- Das Spiel nutzt heute keinen Shader, kein Licht und keine Partikel; Compatibility nimmt ihm also
  nichts (`renderer.md`, 1). Was es nicht mehr gibt (HDR in 2D, Kantenglättung des Bildes in 2D,
  Compute), widerspricht ohnehin dem Pixelraster.
- Der Lauf in Boot Camp mit erzwungenem OpenGL aus Feature 007 (37 von 37 Schritten, 35 Fotos
  gleich) gilt als starker Hinweis, aber nicht als Beleg für dieses Feature; der Beleg ist ein Lauf
  mit dem neuen Export ohne Startoption.
- Die Läufe auf Linux und Windows macht Klaus auf denselben Rechnern wie in Feature 007: Linux mit
  AMD R7 200, Windows auf dem Boot-Camp-Rechner. Ein Lauf unter Parallels ist willkommen, aber kein
  Muss (Klaus, 2026-10-29).
- Der selbsttätige Rückfall auf ANGLE unter Windows ist Godots Verhalten und wird nicht eigens
  belegt; belegt wird, dass ANGLE im Export steckt und läuft (Start mit `opengl3_angle`, FR-006).
- Die Dauer eines Laufs steht im Beleg und wird mit dem Lauf aus Feature 007 verglichen; dauert er
  mehr als doppelt so lange, geht das an Klaus. Eine eigene Anforderung an die Dauer gibt es nicht.
- Fehlt einem Rechner auch für Compatibility die Grafik, bleibt es bei Godots eigener Meldung; eine
  eigene Prüfung beim Start wäre ein eigenes Feature (`renderer.md`, 4).
- Farben, Raster, Schriften und Einrasten im Style-Guide hängen nicht am Renderer und bleiben; neu
  ist nur der Satz aus FR-009a.
- Feature 008 ist vor diesem Feature nach `main` gegangen; die Verfassung, die dieses Feature ändert,
  ist die Fassung 2.3.0.
- Ältere Specs (001 bis 006, 008) bleiben als Geschichte unverändert.
