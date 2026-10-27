# Recherche: Easter Egg 01: Space Invaders

Entscheidungen aus `/speckit-plan` zu [spec.md](spec.md), jede mit Grund und verworfenen
Alternativen (Verfassung, Grundsatz III). Die Verträge unter [contracts/](contracts/) setzen sie um,
das Datenmodell steht in [data-model.md](data-model.md).

Wer entschieden hat, steht an jeder Entscheidung. „Claude, 2026-10-27“ heißt: eigene Festlegung,
eingetragen in `docs/offene-punkte.md`, Abschnitt „Feature 006, Plan“; Klaus kann sie bei der
Checkliste oder jeder Abnahme ändern.

Grundlage ist der Stand von `main` nach Feature 005: Baustein `Communicator` in
`src/ui/communicator/`, Titel in `src/scenes/title/`, Gehäuse G-03 `organizer_1991.png`. Maße
heißen hier **Bildpixel** auf dem Raster des Gehäusebilds (196 × 134) oder **Oberflächenpixel** auf
dem Raster 640 × 360; ein Bildpixel sind 2 × 2 Oberflächenpixel. Wo Zahlen stehen, sind es
Vorschläge und Messungen; gültig werden sie erst im Style-Guide (R12), wie in Feature 005.

## R1 Die Knöpfe gehören zum Gehäuse, die Folge zum Titel

**Entscheidung:** Der Communicator bekommt **Gehäusetasten**: Rechtecke im Gehäusebild, die er
drückbar macht, eindrückt, mit einem Klick hörbar macht und mit dem Signal
`case_key_pressed(index)` meldet. Welche Tasten ein Gehäuse hat, ist wie `display_rect` eine
Eigenschaft des Gehäuses (`case_keys`). Was eine Folge von Tasten bedeutet, weiß nur der Titel; dafür
gibt es eine kleine Klasse `KeySequence` ohne Node (Claude, 2026-10-27). Die Vorgabe von `case_keys`
ist leer; der Titel setzt die drei Tasten von G-03 in seiner Szene, mit den Rechtecken aus dem
Style-Guide. So bleiben spätere Bildschirme mit G-03 ohne drückbare Tasten, wie die Spec annimmt
(Analyse, I2).

**Grund:** Der Communicator kennt den Titel nicht (Feature 005, FR-007); so bleibt es. Die Knöpfe
selbst sind aber Teil des Geräts: Jeder spätere Bildschirm mit G-03 hat sie, und ein anderes Gehäuse
hat andere. Die Folge ohne Node lässt sich wie `TimelineRun` ohne Szene testen.

**Verworfen:**
- Knöpfe und Folge im Titel: Der Titel müsste die Lage des Gehäuses im Gerät kennen und das Gehäuse
  selbst übermalen.
- Die Folge im Communicator: Er wüsste dann, was ein Bildschirm mit seinen Tasten vorhat.

## R2 Lage der drei Knöpfe in G-03

**Messung (Claude, 2026-10-27, an `organizer_1991.png`; nachgemessen in T001 an Leuchtwerten je
Bildpixel und einer Montage ×8):** Die drei grauen Tasten liegen ganz rechts in der Reihe der
Funktionstasten. Gezählt wird einschließlich:

| Knopf | x | y | Größe | Oberflächenpixel im Gehäuse | im Titel |
|---|---|---|---|---|---|
| 1 (links) | 140 bis 150 | 114 bis 121 | 11 × 8 | ab 280/228, 22 × 16 | ab 524/320 |
| 2 (Mitte) | 154 bis 165 | 114 bis 121 | 12 × 8 | ab 308/228, 24 × 16 | ab 552/320 |
| 3 (rechts) | 169 bis 180 | 114 bis 121 | 12 × 8 | ab 338/228, 24 × 16 | ab 582/320 |

Zur Taste gehören die helle Oberseite (Zeilen 114 bis 117), die Vorderkante (118, 119) und ihr
Schatten (120, 121); unter ihr beginnt in Zeile 122 die dunkle Fläche (Leuchtwert 64 gegen 82 bis 99
im Schatten). Die Zeile 113 läuft hell über die ganze Reihe, auch über die Spalte zwischen den
Tasten; sie ist der Rand der Fläche, nicht die Taste. Eine eigene helle Lichtkante haben die Tasten
nicht: Die linke Spalte ist dunkler als die Oberseite (136 gegen 176), nicht heller. Rechts ist die
Spalte 150, 165 bzw. 180 die Schattenkante. Bis T001 standen hier y 114 bis 120 und Taste 3 bis x
179; der Schatten in Zeile 121 und die Kante bei x 180 gehören aber zur Taste. Seit Style-Guide
Version 49 gelten die Werte aus dem Baustein Communicator, „Gehäusetasten“.

## R3 Eingedrückt: Ausschnitt aus dem Gehäusebild, eine Zeile tiefer

**Entscheidung:** Solange die linke Maustaste auf einer Taste unten ist, malt der Communicator über
die Taste ihren eigenen Ausschnitt aus dem Gehäusebild, **ohne seine oberste Zeile**, um 1 Bildpixel
tiefer; die frei werdende oberste Zeile füllt er mit der Farbe des Spalts links neben der Taste. Die
Vorderkante wird dadurch eine Zeile schmaler; die unterste Zeile der Taste fällt weg, der Ausschnitt
reicht nie über das Rechteck hinaus (Analyse, I5). Kein neues Bild, keine neue Farbe (Spec, FR-001a;
Claude, 2026-10-27). Eine helle linke Spalte haben die Tasten nicht (T001, R2); es fällt also nur die
oberste Zeile weg (Review, CHK029). Gehäusetasten sind Teil des
Bildes und bekommen deshalb kein `relief-gedrueckt` (Review, CHK003).

**Grund:** Ein Ausschnitt mit `AtlasTexture` aus der vorhandenen Textur hält Farben und Raster des
Gehäuses genau; fährt das Gerät, fährt die Taste mit. Die Farbe des Spalts steht schon im Bild.

**Verworfen:**
- Eine zweite Fassung des Gehäusebilds mit gedrückten Tasten: drei Tasten bräuchten drei Bilder oder
  eine eigene Rasterfassung.
- Die Taste abdunkeln: Das wäre eine neue Farbe, nicht in der Hauptpalette.

## R4 Druck, Klick und Sperre

**Entscheidung:** Je Taste ein unsichtbares `Control` als Klickfläche mit `mouse_filter` STOP und dem
Pfeil als Zeiger. Gedrückt wird bei linker Maustaste unten; **gezählt wird beim Loslassen über
derselben Taste** (Spec, FR-001). Der Klick ertönt beim Drücken, wie bei einer echten Taste, auch wenn
der Druck nachher nicht zählt. Rechte und mittlere Maustaste tun nichts. Die Klickflächen sind Kinder
des Communicators; die Sperre aus Feature 005 (`mouse_behavior_recursive`) gilt damit auch für sie
(FR-004), ohne eigenen Code (Claude, 2026-10-27).

**Grund:** „Loslassen über derselben Taste“ ist das Verhalten jedes Buttons und verhindert, dass ein
weggezogener Druck zählt (Spec, Randfälle). Ein Klick beim Drücken fühlt sich mechanisch an.

**Verworfen:** `Button` mit leerem Stil: zieht Fokus und Tastatur an sich (Enter und Leertaste würden
die Taste auslösen) und brächte eine Hover-Farbe mit.

## R5 Die Folge

**Entscheidung:** `KeySequence` hält die erwartete Folge (`[0, 1, 2]`) und den Fortschritt.
`press(index) -> bool` liefert true, wenn die Folge damit vollständig ist, und beginnt dann von vorn.
Ein falscher Index setzt zurück; ist er der erste der Folge, zählt er als neuer Anfang (Spec, FR-003).
Der Titel ruft `reset()`, wenn das Spiel startet und wenn er erscheint. Während Space Invaders auf
der Anzeige steht, leitet der Titel Tastendrücke nicht an die Folge weiter; die Tasten klicken und
drücken sich weiter ein (Claude, 2026-10-27).

**Grund:** Allgemein genug für ein späteres Easter Egg 02, ohne vorzugreifen. Dass die Tasten während
des Spiels weiter klicken, hält das Gerät stimmig; dass sie nichts starten, verhindert ein zweites
Spiel im ersten (Spec, Randfälle: genau ein Spiel).

## R6 Das Spiel: ein Kern ohne Node, eine Seite zum Zeigen

**Entscheidung:** Zwei Klassen nach dem Muster Fahrplan/Zeitleiste:
- `InvadersGame` (RefCounted): der ganze Zustand und `step(input)`, ein fester Schritt von 1/60 s.
  Kein Node, keine Zeit aus der Engine, Zufall nur über einen eigenen `RandomNumberGenerator` mit
  Seed. Meldet, was in einem Schritt passiert ist (Schuss, Treffer, Takt, Kanone getroffen, Ende),
  als Liste von Ereignissen, die die Seite in Töne und Bilder übersetzt.
- `InvadersPage` (Control): eine Seite des Communicators. Sammelt die Eingabe, taktet den Kern mit
  festem Schritt aus `_process()` (Zeitspeicher, höchstens 4 Schritte je Bild), malt in `_draw()`,
  spielt Töne und zeigt am Ende die Ergebnisanzeige.

Beide liegen unter `src/scenes/title/invaders/` (Claude, 2026-10-27).

**Grund:** Der Kern lässt sich Schritt für Schritt mit festem Seed testen, ohne Szene und ohne zu
warten (Tests deterministisch, `ki_dev.md`). Fester Schritt heißt: Das Spiel läuft auf jedem Rechner
gleich schnell. Der Deckel von 4 Schritten verhindert nach einem Hänger einen Sprung.

**Verworfen:**
- Nodes je Außerirdischem (`Sprite2D`, `Area2D`): Physik und Kollision für 32 Rechtecke sind zu viel,
  und auf dem Bildraster reicht ein Vergleich von Rechtecken.
- `_physics_process()`: hängt am Physiktakt des Projekts, nicht an der Seite. Auch `_process()` läuft weiter,
  wenn die Seite verborgen ist; deshalb hält sie nach `finished` und
  verborgen ihren Takt selbst an (Analyse, U1).
- Ein eigener Ordner `src/minigames/`: Es gibt ein einziges Spiel, und es gehört zum Titel. Braucht
  ein zweites Easter Egg denselben Rahmen, zieht beides um.

## R7 Spielfeld und Maße

**Übernommen in den Style-Guide am 2026-10-27 (Version 49, Baustein Spiel auf der Anzeige).** Bis dahin
ein Vorschlag von Claude; seitdem gilt nur noch der Style-Guide, auch nach dem Feinschliff in T024
(Analyse, V1). Gezählt wird einschließlich: x 75 bis 83 sind 9 Pixel (Analyse, I1). Das Feld ist die Anzeige, 160 × 80
Bildpixel, gezeigt ×2 als 320 × 160 Oberflächenpixel. Alles liegt auf ganzen Bildpixeln.

| Teil | Maß in Bildpixeln |
|---|---|
| Innenrand | 2 an jeder Seite (4 Oberflächenpixel wie bei Menü und Liste); nichts liegt außerhalb |
| Kopfzeile | oben 8 hoch: Punkte ab x 2 in `drucker`, Leben rechts als Muster `life` (7 × 4, Abstand 2), das letzte endet bei x 157 |
| Außerirdische | 8 × 6, Block 8 Spalten × 4 Reihen, Abstand 4 waagrecht, 3 senkrecht; Block 92 × 33 |
| Start des Blocks | oben bei y 12, waagrecht mittig |
| Kanone | 9 × 5, Zeilen 73 bis 77, Mitte heißt x 75 bis 83; 1 Bildpixel je Schritt (Analyse, U2) |
| Schuss | 1 × 4, 2 Bildpixel je Schritt |
| Bombe | 2 × 3 im Zickzack, damit sie sich vom Schuss unterscheidet (T002; bis dahin 1 × 3), 1 Bildpixel je zwei Schritte; Schuss und Bombe fliegen aneinander vorbei |
| Explosion | Muster `explosion` 8 × 6 an der Stelle des Getroffenen, 0,25 s; hält nichts auf |
| Gelandet | sobald die unterste Zeile eines lebenden Außerirdischen y 73 erreicht, die oberste Zeile der Kanone (Analyse, I1) |
| Takt des Blocks | ein Schritt von 2 Bildpixeln; am Rand 3 tiefer und Richtungswechsel; Rand heißt die Außenkante der lebenden Außerirdischen (Analyse, M2) |
| Abstand der Takte | in Schritten `3 + round(27 · (n − 1) / 31)` bei n übrigen: 30 Schritte (0,5 s) bei 32, 3 Schritte (0,05 s) bei einem (Analyse, U3) |
| Bomben | höchstens 3 zugleich; je Takt mit Chance 1/4 von einer zufälligen untersten in einer Spalte |
| Punkte | oberste Reihe 30, die beiden mittleren 20, unterste 10; höchstens 640 |
| Leben | 3; die Kopfzeile zeigt alle verbleibenden, die Kanone im Feld eingeschlossen; nach einem Treffer 1 s Pause: Explosion an der Stelle der Kanone, Bomben weg, der Block steht, dann die Kanone wieder in der Mitte (Analyse, M3, U5) |

Die senkrechte Lage von Punkten und Leben in der Kopfzeile legt T002 im Style-Guide fest (Analyse,
U5).

Das Feld liegt auf dem Bildraster wie eine Szene; die Abstände `raster-2` bis `raster-16` gelten
dort nicht (Review, CHK028). Alle Lagen sind ganze Bildpixel (Review, CHK023).

Mit diesen Zahlen braucht ein Durchgang über die Breite am Anfang rund 17 s; bis der Block die
Kanone erreicht, vergehen ohne Treffer gut 2 Minuten, mit Treffern wird er schneller. Das zielt auf
SC-002 (1 bis 3 Minuten). Die Zahlen stehen als Konstanten an einer Stelle; Klaus stellt sie bei der
Abnahme von Phase 4 nach Gefühl ein.

### Auslegungen aus Phase 3

Vom Agent in T011 festgelegt, von Claude geprüft und angenommen (2026-10-27); Begründungen in
`lernnotizen.md`, Phase 3:
- Reihenfolge eines Schritts: Explosionen altern, Kanone fährt, Schuss fliegt, neuer Druck schießt,
  Treffer, Bomben fallen, Treffer an der Kanone, Takt. Endet die Partie oder trifft eine Bombe, endet
  der Schritt dort.
- Der Schuss startet direkt über der Spitze (x `cannon_x + 4`, y 69 bis 72) und zählt im Schritt des
  Drucks schon als Treffer; er verschwindet, bevor er in die Kopfzeile flöge.
- Die Bombe startet direkt unter dem Werfer, fällt ab dem zweiten Schritt und trifft, sobald sich
  ihr Rechteck mit dem der Kanone (9 × 5) überschneidet, auch an den leeren Ecken des Musters.
- Stirbt ein Außerirdischer, wird der laufende Takt auf den neuen, kürzeren Abstand gekürzt.
- Die Explosion an der Kanone steht die ganze Pause von 60 Schritten, auch nach dem letzten Treffer,
  bei `(cannon_x, 72)`.
- Gemessen (SC-002): Der Testspieler, der zielt und ausweicht, gewinnt nach 2 854 bis 3 309
  Schritten (47 bis 55 s); ohne Schuss landet der Block nach 9 420 Schritten (157 s), jeder Treffer an
  der Kanone verschiebt das um 61 Schritte. Ein Mensch braucht länger; das Spielgefühl prüft Klaus
  in Phase 4.
- Die Unterkante des Blocks springt von 71 auf 74 und trifft die Zeile 73 nie genau; „erreicht“ heißt
  deshalb „73 oder tiefer“.

## R8 Pixelmuster

**Entscheidung:** Die Muster sind Daten: je Figur ein Array aus Strings, `#` ist `tusche`, `.` ist
leer, in `invaders_sprites.gd` (Klasse `InvadersSprites`). Drei Arten Außerirdischer mit je zwei
Bewegungsbildern, die Kanone, die Explosion; alle **eigene Entwürfe**, nicht aus dem Original
abgezeichnet. Claude entwirft sie in Phase 1 im Style-Guide, Klaus gibt sie frei; der Agent übernimmt
sie von dort. Gemalt wird mit `draw_rect()` je gesetztem Pixel auf dem Bildraster (Spec, FR-030;
Claude, 2026-10-27).

**Grund:** Muster als Text lassen sich im Style-Guide zeigen, im Review lesen und in Tests prüfen
(etwa „jedes Muster ist 8 × 6“). Eigene Entwürfe halten die Hommage frei von fremder Grafik (Spec,
Assumptions). Dass Klaus die Muster selbst zeichnet, ist ein guter Kandidat für eine `[K]`-Aufgabe.

**Verworfen:** Ein Spritesheet als PNG: von Klaus in Specify verworfen.

## R9 Eingabe im Spiel

**Entscheidung:** Die Seite nimmt beim Start den Fokus (`focus_mode` ALL) und wertet Tasten in
`_gui_input()` aus: Pfeil links und rechts als gehaltener Zustand (gedrückt bis losgelassen, Echo
zählt nicht), Leertaste als Schuss bei jedem neuen Druck, Esc beendet. Jede Taste ohne Cmd, Strg
oder Alt, auch eine unbekannte, wird mit `accept_event()` verbraucht, damit nichts zum Titel
durchdringt (Spec, FR-012, FR-017). Tasten mit Cmd, Strg oder Alt und die Aktion `toggle_fullscreen`
lässt sie durch: „Fenster schließen und Vollbild wirken wie immer“ (Baustein Communicator; Review,
CHK006). Die Seite zeigt keinen Fokusrahmen (Review, CHK025). Die Maus: Ein Linksklick auf die Anzeige zählt nur in der Ergebnisanzeige (FR-020). Verliert
die Seite den Fokus, etwa durch einen Klick auf eine Gehäusetaste, holt sie ihn zurück (Claude,
2026-10-27).

**Grund:** Über den Fokus bekommt nur die Seite die Tasten; die verborgenen Seiten des Menüs haben
keinen Fokus mehr, weil `show_page()` sie verbirgt. Ein eigener Tastenzustand statt
`Input.is_action_pressed()` macht die Seite mit erfundenen Ereignissen testbar.

**Verworfen:** Eigene Aktionen in der InputMap (`invaders_left` …): Für drei Tasten in einem
versteckten Spiel ist das mehr Projekteinstellung als Nutzen; die Pfeile sind fest gewählt (Clarify).

## R10 Ende, Ergebnisanzeige und Rückweg

**Entscheidung:** Am Ende hält der Kern an, und die Seite zeigt auf der Anzeige die Ergebnisanzeige.
Sie heißt nicht Meldung, weil der Baustein Meldung ein Fehlerhinweis neben dem Gehäuse ist (Review,
CHK004). Aufbau (Review, CHK024): Zeilen 1 und 2 in `drucker` (Doto) und Versalien wie Kopfzeilen,
Zeile 3 in `menue` (Ark Pixel 12) wie ein Eintrag; Zeilenhöhe 20, als Block mittig in der Anzeige;
vom Feld bleibt nur die Kopfzeile. Über der Anzeige bleibt der Zeiger der Pfeil (Review, CHK022).
Sie nimmt eine Taste oder einen Linksklick erst **0,5 s** nach dem Ende und nur als neuen Druck an
(kein Echo, kein noch gehaltener Schuss; FR-020). Shift, Strg, Alt und Cmd allein zählen nicht
(Review, CHK009), ebenso keine Taste mit Cmd, Strg oder Alt: Ein Kürzel wie Vollbild wirkt und führt
nicht weiter (Analyse, M4). Dann meldet sie
`finished`; Esc meldet zu jeder Zeit `finished`. Der Titel merkt sich beim Start Seite, Fokus und
Zeile des Hinweises und stellt alle drei beim Ende wieder her; eine Meldung von vorher kommt als
Hinweis der Zeile zurück (FR-022; Claude, 2026-10-27; Review, CHK008). Zeile und Hinweis führt der
Titel schon in `_selected_row` und `_selected_hint`; neu gemerkt werden nur Seite und Fokus
(Analyse, D1). Ausgeblendet wird mit `_hide_hint()` des Titels, das auch die Meldung vergisst
(Analyse, C2).

**Wortlaut** (nach der Checkliste mit Text-Prüfer, Review CHK030 bis CHK034):

| Fall | Zeile 1 | Zeile 2 | Zeile 3 |
|---|---|---|---|
| gewonnen | `ALLE ERWISCHT.` | `640 PUNKTE` | `Weiter mit Taste oder Klick.` |
| verloren, Kanone ohne Leben getroffen | `GAME OVER` | `380 PUNKTE` | `Weiter mit Taste oder Klick.` |
| verloren, gelandet | `GAME OVER` | `380 PUNKTE` | `Weiter mit Taste oder Klick.` |

Die Kopfzeile im Spiel zeigt `PUNKTE 0380`: führende Nullen nur dort, wo die Stellenzahl fest ist;
in der Ergebnisanzeige ohne. Zeilen 1 und 2 zählen als Meldung im Sinne des Abschnitts Sprache
(trocken, Witz im Nachsatz erlaubt), Zeile 3 als Bedienung (ohne Witz); je Zeile ein Satz. Bis zum
Phase 2 heißen beide Niederlagen wie beim Automaten von 1978 „GAME OVER“ (Klaus, 2026-10-27, gegen
die Empfehlung „SIE SIND GELANDET.“): Eine deutsche Fassung des Originals gab es nicht, auch in
Deutschland zeigte der Automat englische Texte, und „Game Over“ ist ein Computerwort der Zeit. Bis
dahin „KANONE KAPUTT.“ und „DIE SIND GELANDET.“; „DIE“ klang schräg. Bis zum
Review hießen sie „ALLE ERWISCHT!“, „SIE SIND GELANDET.“ und „Weiter mit einer Taste.“; das
Ausrufezeichen war zu laut, „SIE“ las sich wie die Anrede, und der Klick fehlte. Alle Wortlaute stehen in `TitleTexts` (Feature 004, alle
Texte des Titels an einer Stelle).

**Verworfen:** Esc mit Rückfrage: Das Spiel dauert Minuten und speichert nichts.

## R11 Anhalten ohne Fokus

**Entscheidung:** Die Seite hört auf `NOTIFICATION_APPLICATION_FOCUS_OUT` und `…_FOCUS_IN`. Ohne
Fokus taktet sie den Kern nicht und hält ihre Töne an (`stream_paused`); mit Fokus geht es weiter, ohne
dass die verlorene Zeit nachgeholt wird (Spec, FR-016, FR-044; Claude, 2026-10-27). Das gilt für
alle Zeiten des Spiels: die Pause nach einem Treffer, die Explosionen und die Sperre der
Ergebnisanzeige (Review, CHK014).

**Verworfen:** `get_tree().paused`: hielte auch Titel und Communicator an und braucht `process_mode`
an jedem Node, der weiterlaufen soll.

## R12 Style-Guide zuerst

**Entscheidung:** Vor dem ersten Code kommen in den Style-Guide (Phase 1, Claude schreibt, Klaus gibt
frei):
1. Baustein Communicator, **Gehäusetasten**: Lage der drei Tasten in G-03 (R2), eingedrückt (R3).
   Ausnahme von allen Regeln für anklickbare Stellen, mit Grund (versteckt, Teil des Bildes): kein
   Zeigerwechsel, kein `signalgelb`, kein Tooltip, kein Hinweis, kein Relief (Spec, FR-001b; Review,
   CHK002, CHK003). Der Satz „Das Gehäuse ist reine Grafik: Ein Klick darauf tut nichts“ wird zu
   „Das Gehäuse ist Grafik bis auf seine Gehäusetasten“ (CHK001). Die Beschreibung von G-03 nennt
   die drei grauen Tasten (CHK027).
2. Neuer Abschnitt **Spiel auf der Anzeige**: Feld, Innenrand, Kopfzeile in `drucker`, Maße und
   Lagen (R7), Pixelmuster mit `explosion` und `life` (R8), Ergebnisanzeige (R10), nur `tusche` auf
   `lcd`; kein Fokusrahmen, Zeiger Pfeil, „Bewegung reduzieren“ gilt nicht, `raster-*` gilt nicht im
   Feld; Regeln für Texte im Spiel und führende Nullen (Review, CHK021 bis CHK028, CHK033, CHK034).
   Im Baustein Communicator: Eine Seite ist ein Menü, eine Liste oder das Spiel; während des Spiels
   ist der Hinweis verborgen (CHK021, CHK027). Im Abschnitt Sprache ein Verweis auf die Regeln für
   Texte im Spiel (CHK034).
3. Neuer Abschnitt **Ton**: Klang (Rechteckwelle), Tonhöhen, Längen, Pegel, die Tonkanäle (R13,
   R14), und dass das Menü stumm bleibt.

## R13 Töne: Rechteckwelle aus einem Skript

**Übernommen in den Style-Guide am 2026-10-27 (Version 49, Abschnitt Ton); seitdem gilt die Tabelle
dort.**

**Entscheidung:** `tools/ton/make_sounds.py` (Python 3, Standardbibliothek, `wave` und `struct`)
erzeugt alle Töne als WAV, 22 050 Hz, 16 Bit, mono, nach `src/assets/sounds/`. Es braucht keine
Eingabe und schreibt bei jedem Lauf dieselben Bytes. Vorschlag für die Töne (Claude, 2026-10-27,
gültig mit dem Style-Guide):

| Datei | Wofür | Klang |
|---|---|---|
| `knopf.wav` | Gehäusetaste | 4 ms Rauschen, kurz abfallend; ein trockener Klick |
| `schuss.wav` | Schuss | Rechteck, 1200 → 600 Hz in 80 ms |
| `treffer.wav` | Außerirdischer getroffen | Rauschen mit Rechteck 200 Hz, 120 ms, abfallend |
| `kanone.wav` | Kanone getroffen | Rauschen, 600 ms, langsam abfallend |
| `marsch_1.wav` … `marsch_4.wav` | Takt des Blocks | Rechteck 98, 87, 78, 73 Hz, je 60 ms |
| `sieg.wav` | gewonnen | Rechteck, aufsteigend C5 E5 G5 C6, je 90 ms |
| `niederlage.wav` | verloren | Rechteck, absteigend G4 E4 C4, je 160 ms |

Jeder Ton beginnt ohne Stille und endet mit 5 ms Ausblenden gegen Knacken. Spitzenpegel −6 dBFS.
Die vier Marschtöne teilen sich einen Player: Ein neuer Takt schneidet den vorigen Ton ab, auch wenn
die Takte kürzer werden als der Ton (Review, CHK015).

**Grund:** Spec, Ton 2026-10-27. 22 050 Hz reicht für Rechteck und Rauschen und hält die Dateien
klein (zusammen unter 100 KB). Ohne Stille am Anfang trifft SC-007 (höchstens 50 ms); Godots
Ausgabe-Latenz liegt bei 15 ms (Projekteinstellung `audio/driver/output_latency`). Das Rauschen kommt
aus einem festen Seed, damit der Lauf bytegleich ist. Die `.import` jeder WAV setzt Kompression aus
(PCM), kein Trimmen, kein Normalisieren, keine Schleife, damit Godot die Proben unverändert spielt;
Tests lesen die Proben aus der Rohdatei (Analyse, U6). Die Werte der Tabelle gelten nach T002 nur
noch im Style-Guide (Analyse, V1).

**Verworfen:** OGG statt WAV: lohnt bei so kurzen Tönen nicht und bringt beim Start eine kleine
Verzögerung durch das Dekodieren.

## R14 Tonkanäle

**Entscheidung:** `src/default_bus_layout.tres` mit `Master` und `Effekte` (Ziel `Master`); Godot
lädt sie ohne Projekteinstellung. `Effekte` steht fest auf −10 dB, `Master` auf 0 dB. Jeder
`AudioStreamPlayer` dieses Features hat `bus = &"Effekte"`. Musik bekommt später einen eigenen Kanal
neben `Effekte` (Spec, FR-043; Claude, 2026-10-27).

**Grund:** `Master` heißt in Godot immer so; ein späteres „Einstellungen“ regelt `Master` als
Gesamtlautstärke und `Effekte` getrennt, an genau einer Stelle (`AudioServer.set_bus_volume_db`).

**Verworfen:** Ein Autoload `Ton` schon jetzt: Es gibt nur eine Stelle, die Töne spielt, je Seite ein
paar Player reichen. Ein Autoload lohnt, wenn das Spiel selbst Töne bekommt.

## R15 Tests ohne Tonausgang

**Entscheidung:** Headless läuft Godot mit dem Dummy-Treiber; Töne „spielen“ dort ohne Ausgabe, und
`playing` wird true. Tests prüfen deshalb, *welcher* Player auf welchem Kanal anläuft, nicht, ob etwas
zu hören ist. Ob die Töne gut klingen und rechtzeitig kommen, prüft Klaus bei der Abnahme (Phase 2:
die WAV-Dateien, Phase 4: im Spiel). Ein Test prüft an den Dateien, dass die erste Probe nicht still
ist (SC-007) und das Skript bytegleich erzeugt.

## R16 Nichts am bestehenden Titel ändert sich

**Entscheidung:** Ohne Druck auf eine Gehäusetaste bleibt der Titel bytegleich in seinem Verhalten:
alle Tests aus Feature 001, 004 und 005 laufen unverändert (SC-004). Neu im Titel sind nur die
Verbindung zu `case_key_pressed`, `KeySequence`, die Seite `InvadersPage` unter dem Communicator
und der Rückweg. Die Wache `_accepts_input()` gilt auch für den Start des Spiels: Fährt das Gerät
hinaus oder ist der Titel noch nicht bereit, startet nichts (FR-004).
