# Recherche: Communicator als Steuerelement

Entscheidungen aus `/speckit-plan` zu [spec.md](spec.md), jede mit Grund und verworfenen
Alternativen (Verfassung, Grundsatz III). Die Verträge unter [contracts/](contracts/) setzen sie um,
das Datenmodell steht in [data-model.md](data-model.md).

Wer entschieden hat, steht an jeder Entscheidung. „Claude, 2026-10-27“ heißt: eigene Festlegung,
eingetragen in `docs/offene-punkte.md`, Abschnitt „Feature 005, Plan“; Klaus kann sie bei der
Checkliste oder jeder Abnahme ändern.

Grundlage sind der Spike `481c7e0` (Branch `claude/spike-communicator-625f4c`, nicht gemergt) und
sein Nachtrag in `docs/recherche/navigation-taschengeraet.md`, dazu der Code von Feature 004 unter
`src/scenes/title/`. Alle Maße sind Oberflächenpixel auf dem Raster 640 × 360. Wo hier Zahlen
stehen, sind es Vorschläge und Messungen für den Platz; gültig werden sie erst im Style-Guide (R12),
und Verträge und Tasks verweisen danach nur noch auf ihn (Lehre aus Feature 004, Analyse D1).

## R1 Die Farbe `lcd` gibt es nur in der Oberfläche

**Entscheidung:** `lcd` wird die 16. Farbe des Style-Guides und von `UiPalette`, aber nicht Teil der
Hauptpalette `docs/art/hauptpalette.gpl`. Die bleibt eingefroren; kein Bild wird neu gerastert. Der
Style-Guide sagt dazu: `lcd` gibt es nur in der Oberfläche, nie in einem Bild (Klaus, 2026-10-27,
nach Empfehlung, zu FR-001a).

**Grund:** Das LCD malt die Oberfläche über das Gehäusebild. Im Bild selbst steht an der Stelle der
Anzeige nur ein Platzhalter, der verdeckt wird; die Farbe kommt in keinem gerasterten Bild vor. Die
Reservierung der 15 Oberflächenfarben in der Hauptpalette dient Bildern, die Farben der Oberfläche
enthalten; `lcd` braucht das nicht.

**Folge für die Tests:** `test_bilder.gd` prüft heute, dass jede Farbe aus `UiPalette.TOKENS` in der
Hauptpalette steht. Mit `lcd` prüft er künftig nur die 15 reservierten; `lcd` steht als Ausnahme mit
Verweis auf R1 im Test. Ein zweiter Test sichert, dass `lcd` in keinem Bild unter
`res://assets/images/` vorkommt.

**Verworfen:**
- Eine Szenenfarbe (Index 16 bis 255) durch `lcd` ersetzen: Logo, App-Symbol und die
  handaufgeräumten Bilder müssten geprüft und womöglich neu gerastert werden.
- Die Palette mit `--neu` und 16 reservierten Farben neu erzeugen: alle Bilder neu rastern und von
  Hand nacharbeiten, ohne sichtbaren Gewinn.

## R2 Wert von `lcd`: #b8c4a8, ein graugrünes LCD-Grau

**Entscheidung (Vorschlag für den Style-Guide, Klaus entscheidet in Phase 1):** `lcd` = `#b8c4a8`.
Gemessen nach WCAG:

| Paar | Kontrast | Regel |
|---|---|---|
| `tusche` auf `lcd` | 9,56 : 1 | Text, mindestens 4,5 : 1 |
| `lcd` auf `tusche` (gewählte Zeile, invertiert) | 9,56 : 1 | Text |
| `gehaeuse-dunkel` auf `lcd` (nicht verfügbar) | 3,10 : 1 | große Schrift, mindestens 3 : 1, wie im Baustein Menü |
| `gehaeuse-dunkel` auf `tusche` (gewählt und nicht verfügbar) | 3,08 : 1 | große Schrift |

**Grund:** Das Grün eines Organizers um 1991 ist grau und matt, nicht das frische `endlos-gruen`
(#cfe2c3). Mit `#b8c4a8` reicht der Kontrast auch für gedämpfte Einträge, ohne eine weitere Farbe.

**Verworfen:**
- `#a8b59a`, näher am echten Psion: gedämpft nur 2,63 : 1, unter der Regel.
- `#c3cdb0`: mehr Luft beim Kontrast (3,42 : 1), wirkt aber fast wie `endlos-gruen`.

## R3 Die gewählte Zeile auf der Anzeige: Balken in `tusche`, Schrift in `lcd`

**Entscheidung:** Auf der Anzeige liegt unter der gewählten Zeile ein Balken in `tusche`; Schrift
und Pfeil darin sind `lcd` (FR-004a). Ist die gewählte Zeile nicht verfügbar, bleibt der Balken
`tusche`, und Schrift und Pfeil sind `gehaeuse-dunkel` (3,08 : 1, R2). So bleibt gedämpft gedämpft,
auch gewählt, wie auf dem Papier (Claude, 2026-10-27). Eine Rollmarke in der gewählten Zeile, etwa
auf „Löschen …“, ist ebenfalls `lcd`; in `tusche` verschwände sie im Balken (Checkliste CHK001).

**Grund:** Ein echtes LCD hat eine Farbe und invertiert (Klaus' Antwort in clarify). In Godot nimmt
ein gesperrter Button immer `font_disabled_color`, auch mit Fokus (Kommentar in `main_menu.gd`); der
gedämpfte Fall ergibt sich also ohne eigenen Code.

**Verworfen:**
- Gewählt und nicht verfügbar als Balken in `gehaeuse-dunkel` mit Schrift `lcd` (2,92 : 1 bei
  diesem Wert): unter der Regel, und die Schriftfarbe müsste je Zustand im Code wechseln.

## R4 Der Communicator ist ein eigener Baustein in `src/ui/communicator/`

**Entscheidung:** Neue Szene `communicator.tscn` mit Skript `class_name Communicator` unter
`src/ui/communicator/`, nicht unter `src/scenes/title/`. Sie besteht aus Gehäuse (Bild), Anzeige
(gemalt in `lcd`), den Seiten und dem Hinweis. Der Bildschirm, der sie zeigt, legt seine Seiten als
Kinder hinein und sagt, welche zu sehen ist; was ein Eintrag bewirkt, entscheidet weiter er
(FR-007). Vorbild ist `Organizer` aus dem Spike, verallgemeinert.

**Grund:** Wiederverwendbare Bausteine liegen in `src/ui/` wie `knopf.gd` aus Feature 004. Der
Spielbildschirm soll den Communicator später ohne Umweg über den Titel benutzen. Die Seiten bleiben
`MainMenu` und `SaveList`, die schon Signale für Auswahl und Auslösen haben; der Communicator muss
ihre Signale nicht kennen.

**Verworfen:**
- Den Spike-`Organizer` unter `scenes/title/` lassen: Er wäre an den Titel gebunden (FR-007).
- Eine eigene Seiten-Klasse, von der `MainMenu` und `SaveList` erben: ein großer Umbau zweier
  geprüfter Klassen, ohne dass der Spieler etwas davon hat. Eine „Seite“ ist jedes Control, das
  der Bildschirm in den Communicator legt.

## R5 Seiten auf der Anzeige: Schalter `look` an Menü und Liste

**Entscheidung:** `MainMenu` und `SaveList` bekommen den Schalter `look` mit `PAPER` (Vorgabe, wie
bisher) und `LCD`, wie im Spike an `MainMenu`. Auf `LCD` malen sie kein Papier, keine Lochränder,
keinen Schatten und kein Zebra; die Auswahl ist invertiert (R3); Zeilen und Pfeil rücken nach links,
weil der Lochrand fehlt. Malen und Maße für beide Untergründe stehen an einer Stelle: `MenuPaper`
bekommt die LCD-Fassung dazu (`draw_lcd_selection()`), Menü und Liste rufen je nach `look` die
eine oder die andere. Die Schriftfarben kommen aus neuen Theme-Varianten `LcdRow` und `LcdHeader`.
Die Seiten nehmen die volle Breite der Anzeige ein (Claude, 2026-10-27).

**Grund:** Der Spike hat gezeigt, dass ein Schalter reicht: Bedienung, Auswahl, Signale und Rollen
bleiben gleich, nur das Malen ändert sich. Das Papier bleibt erhalten, weil der Style-Guide
Endlospapier für alles behält, was aus dem Drucker kommt, und die Tests von Feature 004 es prüfen.

**Verworfen:**
- Das Papier aus Menü und Liste entfernen, weil der Titel es nicht mehr braucht: Die Bausteine Menü
  und Liste im Style-Guide bleiben gültig; später nutzt etwa ein Ausdruck aus dem Nadeldrucker sie.
- Eigene Klassen `LcdMenu` und `LcdList`: doppelte Bedienung, doppelte Tests.

## R6 Die Fahrt: Tween mit gedeckeltem Zeitschritt, auf ganzen Pixeln

**Entscheidung:** Wie im Spike: Ein Tween schreibt in eine Eigenschaft `slide_y`, die beim Setzen auf
ganze Oberflächenpixel rundet. Der Tween ist angehalten und wird in `_process()` mit
`custom_step()` getaktet, der Zeitschritt je Bild ist gedeckelt. Herein mit `EASE_OUT`, hinaus mit
`EASE_IN`, beide `TRANS_CUBIC`, also ohne Überschwingen. Dauer 200 ms (Style-Guide, Bewegung:
150 bis 250 ms). Der Deckel liegt bei 1/30 s statt der 1/60 s im Spike (Claude, 2026-10-27).

**Grund:** Ohne Deckel springt das Gerät im langsamen ersten Bild gleich halb herein (Falle aus dem
Spike, Edge Case „Langes erstes Bild“). Mit 1/60 s als Deckel dauerte die Fahrt bei 30 Bildern je
Sekunde 400 ms und bräche SC-002 (250 ms); mit 1/30 s bleibt sie bis 30 Bilder je Sekunde genau 200 ms
und fängt trotzdem das lange erste Bild ab. `custom_step()` macht die Fahrt im Test Bild für Bild
prüfbar (SC-003), ohne zu warten.

**Verworfen:**
- `position.y` direkt tweenen: Zwischenlagen auf halben Pixeln.
- Eine `AnimationPlayer`-Spur: Dauer und Ziel ändern sich zur Laufzeit (Umkehr mitten in der
  Fahrt, User Story 3, Szenario 3), das kann der Tween einfacher.
- Ungedeckelter Zeitschritt: der Sprung aus dem Spike.

## R7 Der Hinweis gehört zum Communicator und fährt mit

**Entscheidung:** Der Communicator enthält den Hinweis (`menu_hint.tscn`) als eigenes Kind über den
Seiten. Er steht links neben dem Gehäuse, 4 vor dessen linker Kante, oben bündig mit der gewählten
Zeile (FR-010a). Der Bildschirm reicht ihm Text und Zeile über `show_hint()`, `show_warning()` und
`hide_hint()`; der Communicator setzt die Lage in x selbst. Weil der Hinweis ein Kind ist, fährt er
mit, ohne Code (FR-006).

**Grund:** Im Spike verschob der Titelbildschirm den Hinweis bei jeder Bewegung um die Differenz, ein
Behelf, den der Nachtrag selbst so nennt. Als Kind bewegt er sich mit dem Gerät. Die Lage neben dem
Gehäuse statt neben der Zeile gehört zum Baustein, also auch dorthin.

**Verworfen:**
- Hinweis im Titelbildschirm lassen und per Signal `moved` nachführen: der Behelf aus dem Spike.
- `show_for()` mit der Zeile wie bisher: Der Hinweis stünde dann auf dem Gehäuse, 4 vor der Zeile.

## R8 Hinausfahren vor dem Spielstart und gesperrte Eingabe

**Entscheidung:** Gelingt `GameSession.start_new()` oder `resume()`, ruft der Titelbildschirm
`Communicator.slide_out()` und wechselt die Szene erst mit dem Signal `slide_finished`. Während der
Fahrt hinaus nimmt der Communicator keine Eingabe an: Er nimmt seinen Seiten den Fokus und lässt
keine Maus durch; der Titelbildschirm ignoriert Esc (FR-013a). Scheitert das Anlegen, fährt nichts,
und die Meldung steht wie bisher. „Beenden“ schließt sofort (Spec, Annahmen).

**Grund:** Das Spiel läuft schon, wenn die Fahrt beginnt; schließt der Spieler in diesen 200 ms das
Fenster, speichert `GameSession` wie in Feature 004. Ein zweites Enter darf kein zweites Spiel
anlegen.

**Verworfen:**
- Erst hinausfahren, dann anlegen: Scheitert das Anlegen, müsste das Gerät wieder hereinfahren, und
  die Meldung käme verspätet.
- Mit `await` im Titelbildschirm statt Signal: gleichwertig; das Signal lässt sich im Test ohne
  Warten auslösen, wenn `animate` aus ist.

## R9 Lage im Titel: Anzeige rechts unten, Gehäuse ragt unten hinaus

**Vorschlag für den Style-Guide (Phase 1):**

| Teil | Lage |
|---|---|
| Anzeige | 384 × 192, x 224 bis 608, y 120 bis 312 (Endlage) |
| Gehäuse | rund 432 breit, Oberkante y 96, Unterkante unter dem Bild (Tastatur halb zu sehen) |
| Hinweis | rechte Kante x 196, also höchstens von x 36 an; oben bündig mit der Zeile |
| Logo und Untertitel | unverändert x 14 bis 296, y 12 bis 83; 13 frei bis zum Gehäuse |
| Versionszeile | unverändert unten links |

Die Anzeige von 384 × 192 schlägt die Recherche vor (Abschnitt 4, „Maße auf 640 × 360“). Sie fasst
die längste Seite: SPIELSTÄNDE mit Kopfzeile, sechs Spielständen, „Löschen …“ und „Zurück“ sind
9 Zeilen zu 20, also 180 von 192; die Liste ist 304 breit, die Anzeige 384. Das Hauptmenü mit fünf
Einträgen belegt 120 der 192; der Rest bleibt leeres LCD (FR-014, SC-004).

Auf dem Bildraster ist die Anzeige 192 × 96 Bildpixel, das Gehäuse beginnt auf geraden Lagen. Der
Logo-Abstand von mindestens `raster-8` (Style-Guide, Logo) ist eingehalten.

**Verworfen:**
- Anzeige oben bündig mit den Blättern von Feature 004 (y 150): Die Liste mit 180 Höhe reichte bis
  y 330, das Gehäuse fast ganz aus dem Bild.
- Das Seitenverhältnis 3 : 2 des Spike-Gehäuses: zu wenig Breite für die Liste.

## R10 Grafiken: Gehäuse G-02 und Titelbild T-02 aus Leonardo

**Entscheidung:** Zwei neue Bilder, beide nach dem Leonardo-Workflow (FR-020). Claude schreibt die
Prompts mit dem Stilblock des Style-Guides, Klaus erzeugt die Bilder; Claude rastert und räumt mit
`tools/raster/` auf, Klaus gibt frei.

1. **G-02 Organizer 1991**, frontal, aufgeklappt, mit einem leeren LCD im Seitenverhältnis 2 : 1
   („wide LCD, exactly twice as wide as high“, Lehre aus dem Spike). Gerastert mit einem Faktor, der
   das LCD auf 192 × 96 Bildpixel bringt; danach wird die LCD-Fläche von Hand auf genau diese Größe
   gebracht und die Sprenkel über dem LCD aus G-01 vermieden oder entfernt. Datei
   `src/assets/images/organizer_1991.png`. G-02 kommt zuerst: Erst wenn das Gehäuse gerastert und
   die Anzeige darin nachgemessen ist, schreibt Claude den Prompt für T-02 mit der Fläche, die es
   frei lassen muss (CHK005).
2. **T-02 Titelbild**: dieselbe Welt wie T-01, mit einer ruhigen, dunklen Fläche rechts unten, wo das
   Gerät steht (FR-015). In Leonardo mit T-01 als Bildvorlage und C2 als Style Reference, wenn
   Leonardo das zu dem Zeitpunkt anbietet; die Modellliste ändert sich, also vorher prüfen
   (`ki_dev.md`, Grafik). Bietet Leonardo keine Bildvorlage, beschreibt der Prompt T-01 in Worten,
   mit C2 als Style Reference, und Klaus entscheidet am Ergebnis (CHK026). Datei `src/assets/images/title_t02.png`, 320 × 180. T-01 bleibt im Repo.

Beide Prompts kommen ins Prompt-Log und in die Prompt-Bibliothek des Style-Guides. Die Hauptpalette
bleibt (R1); die Farben von T-02 liegen nah an T-01, aus dem die Palette mit entstand.

**Verworfen:**
- G-01 aus dem Spike weiterverwenden: LCD 3 : 2 und zu klein (188 × 122), nicht freigegeben.
- T-02 ganz neu erfinden: Klaus will dieselbe Welt (Spec, FR-015).

## R11 Bis die Grafiken da sind: Platzhalter-Gehäuse

**Entscheidung:** Der Kern des Communicators (Phase 3) und die Seiten auf der Anzeige (Phase 4)
entstehen mit einem Platzhalter: einem Rechteck in `gehaeuse` mit Kontur `tusche` in der Größe des
Gehäuses. Erst die Phase des Titels (Phase 5) braucht G-02 und T-02 (Claude, 2026-10-27).

**Grund:** So hängt der Code nicht an Klaus' Zeit in Leonardo, und die Phasen bleiben einzeln
prüfbar. Die Lage der Anzeige im Gehäuse ist eine Konstante, die mit G-02 nur nachgemessen wird.

**Verworfen:** Erst alle Bilder, dann der Code: Klaus' Grafikarbeit stünde auf dem kritischen Weg.

## R12 Style-Guide zuerst (Phase 1)

**Entscheidung:** Vor jedem Code ergänzt Claude den Style-Guide, Klaus gibt frei (FR-008, Grundsatz
IV):
1. **Baustein Communicator** (neu, mit Vorschau): Gehäuse als reine Grafik ohne Klick (CHK002),
   Anzeige 384 × 192 für jedes Gehäuse, ihre Farbe je Gehäuse, beim Organizer `lcd` (CHK014), Lage
   im Titel (R9), Fahrt herein und hinaus in ganzen Oberflächenpixeln mit der Endlage auf ganzen
   Bildpixeln (CHK015), die Fahrt als Deko-Animation, die „Bewegung reduzieren“ abschaltet
   (CHK017), Seitenwechsel ohne Übergang, keine Eingabe während der Fahrt hinaus, Hinweis und
   Meldung neben dem Gehäuse, die mit ihrer Zeile hereinfahren (CHK019).
2. **Token `lcd`** in `tokens.json` und im README unter Farben: Wert mit den Kontrasten aus R2, „nur Oberfläche, nie im
   Bild“ (R1), neue Textpaare `tusche` auf `lcd`, `lcd` auf `tusche`, gedämpft `gehaeuse-dunkel` auf
   `lcd` und auf `tusche`.
3. **Baustein Menü und Liste**: Abschnitt „Auf der Anzeige“ mit invertierter Auswahl und
   Rollmarke `lcd` in der gewählten Zeile (R3), ohne
   Papier, Lochränder und Zebra, mit den Abständen; „Blätter im Titel“ wird zu „Seiten im Titel“ und
   verweist auf den Communicator.
4. **Baustein Hinweis und Baustein Meldung**: Lage neben dem Gehäuse (R7; CHK003).
5. **README**: Schrift: Doto auch für Kopfzeilen auf der Anzeige des Communicators, denn ein LCD
   ist ebenfalls eine Punktmatrix (CHK004); `signalgelb` heißt „hier bist du gerade“, auf der Anzeige zeigt das der invertierte
   Balken; Bildaufbau Titel mit T-02 und Gerät; Bewegung mit der Fahrt des Communicators; der Satz
   zu den Blättern im Titel, die ohne Übergang wechseln, gilt nun für Seiten.
6. **Prompt-Bibliothek**: G-02 und T-02 (R10).

## R13 Tests

**Entscheidung:**
- Neu `test_communicator.gd`: Fahrt Bild für Bild auf ganzen Pixeln, nie über die Endlage (SC-003);
  Dauer bis zur Endlage höchstens 250 ms bei 30 und 60 Bildern je Sekunde und mit einem langen ersten
  Bild (SC-002); Umkehr mitten in der Fahrt; Probeseite außerhalb des Titels mit drei Einträgen,
  per Tastatur gewählt und gemeldet, ohne eine Datei aus `scenes/title/` (SC-005); keine Eingabe
  während der Fahrt hinaus; Hinweis neben dem Gehäuse und mitgefahren.
- `test_main_menu.gd` und `test_save_list.gd`: `look = LCD` malt kein Papier, invertiert die Auswahl,
  Bedienung gleich; die Tests mit `PAPER` bleiben.
- `test_title_screen.gd`: Pfade zu den Seiten im Communicator; jede Seite passt auf die Anzeige mit
  den längsten Texten und „Spiel 9999“ (SC-004); Logo, Untertitel und Versionszeile überschneiden
  sich in keiner Lage mit Gehäuse, Anzeige oder Hinweis (SC-006); Hinausfahren vor dem Szenenwechsel,
  kein zweites Spiel bei Enter während der Fahrt; jedes Erscheinen fährt herein. Mit
  `animate = false`, wo nur das Ergebnis zählt.
- `test_ui_palette.gd`: 16 Farben, `lcd` als Token; `CATEGORY_TOKENS` unverändert; die vier
  Kontraste aus R2 gegen 4,5 : 1 und 3 : 1 (CHK023).
- In `test_communicator.gd` außerdem: Eine Zeile, die unter dem ruhenden Mauszeiger durchfährt,
  wird nicht gewählt (CHK007); ein Klick auf das Gehäuse tut nichts (CHK002).
- In `test_title_screen.gd` außerdem: Eine Eingabe, bevor das Hauptmenü seine Einträge hat, tut
  nichts (CHK018); scheitert das Fortsetzen, fährt nichts (CHK016).
- Bildschirmfotos aus dem echten Fenster in Klaus' Größe (1920 × 925 logisch, Faktor 2) bei jeder
  Phase mit Sichtbarem.

## R14 Code des Spikes gezielt übernehmen

**Entscheidung:** Der Agent liest den Spike mit `git show 481c7e0:<pfad>` und übernimmt daraus, was
passt: das Gleiten aus `organizer.gd` (R6), den Schalter `look` aus `main_menu.gd` (R5) und die
Testideen aus `test_title_screen.gd`. Nichts wird gemergt oder per `cherry-pick` geholt; das Bild
G-01 kommt nicht ins Spiel.

**Grund:** Der Spike baut auf Feature 004 kurz vor dem Merge auf, liegt auf einem eigenen Branch und
enthält Behelfe (Hinweis per Differenz, Liste als Papier), die hier anders entschieden sind.
