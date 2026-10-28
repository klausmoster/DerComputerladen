# Offene Punkte

Hier steht, was Klaus noch entscheiden oder bestätigen muss (`docs/ki_workflow/ki_dev.md`,
„Entscheidungen nicht stillschweigend treffen“):
- **Offen:** Fragen, die Klaus entscheidet, und Lücken oder Widersprüche in den Dokumenten.
- **Eigene Entscheidungen von Claude:** Festlegungen, die nicht aus den Dokumenten folgten. Sie
  sind umgesetzt, aber noch nicht von Klaus bestätigt.

Jeder Punkt hat Datum, Herkunft und, wo es eine gibt, Claudes Empfehlung. Ist ein Punkt entschieden
oder bestätigt, wandert er nach „Erledigt“, mit Datum und Ergebnis. Die Entscheidung selbst steht
dann dort, wo sie hingehört, etwa in Spec, Verfassung oder `research.md`.

## Offen

### Feature 007, Abschluss (2026-10-28)

- **Klaus:** Regel „Selbsttest zur Gesamtabnahme“ in `ki_dev.md` (Punkt 11), Aufgaben-Vorlage und
  `ki_pruefung.md`; die Verfassung bleibt. Phase 8 aus der Lückensuche mit dem empfohlenen Paket;
  Skalierung unter Windows und X11 aus den dpi; 8 neue Referenzbilder (Version 2 des Selbsttests,
  45 Schritte).
- **Entscheidungen Claude zu Lücken der Lückensuche:**
  - Shell-Skripte unter `tools/` zählen wie Python-Werkzeuge; „Spiel“ als Name des Pakets im
    Bauskript ist erlaubt. READMEs unter `tools/` zählen als Hilfe; Spec-Dokumente und Belege sind
    frei.
  - Beschreibung nennt die Seite mit ihrem Namen („Gradwahl“), die Erwartung mit ihrer Kopfzeile
    („SCHWIERIGKEIT“). Zusatztasten heißen wie auf der Tastatur des Systems. „D3D12“ bleibt als
    Messwert. Verschachtelte Anführungszeichen „„…““.
  - Bildlaufleisten brauchen keinen Tooltip und keinen Handzeiger (Godots Standard).
  - Bei mehreren Eingaben nennt die Beschreibung die entscheidende (Vertrag, „Beschreibung“).
  - Diese Regeln kommen mit der nächsten Ergänzung des Style-Guides in „Werkzeuge“, „Texte“.
- **Folgepunkte außerhalb von 007, mit Empfehlung:**
  - Werkstatt: `raster-8` zwischen Knöpfen, Handzeiger an Knöpfen, Zeilenabstand 0 wie im
    Selbsttest; dazu ein gemeinsames Theme für Werkzeuge statt zweier Kopien.
  - Mac-Symbol: mittig setzen und für die icns Nearest statt Lanczos (`icon_interpolation`),
    zusammen mit dem Punkt aus Phase 6.
  - Linux-Symbol in kleinen Größen aus dem gerasterten Monitor, wie die ICO.
  - Rangfolge der Texte in `werkzeug-titel`: Seitenüberschrift und Summe gleich groß wie
    Bereichstitel.
  - Windows-Lauf mit Vulkan oder Direct3D 12 (Windows bisher nur mit Compatibility belegt).
  - Linux und Windows mit Version 2 des Selbsttests (45 Schritte) laufen lassen; belegt sind dort
    bisher 37 Schritte.
  - `vergleich.py` legt Belege fest unter `specs/007-build-export-selbsttest/belege/` ab; für spätere
    Features einen Ordner je Feature wählbar machen.

### Feature 007, Phase 6 (2026-10-28)

- **Klaus:** Export-Templates 4.7.2 im Editor installiert; Windows-Symbol in 16 aus jedem zweiten
  Bildpixel (Style-Guide Version 62). Direct3D-12-Dateien (Agility SDK) bringen die Templates nicht
  mit; ob Windows trotzdem Direct3D 12 nutzt, zeigt `system.grafik_api` im Protokoll.
- **Lücken aus der Phasenprüfung (Stil, ICO), von Klaus mit Empfehlung abgenommen (T049):**
  - 48 mit ×2 füllt 93 % des Quadrats statt 70 % wie die anderen Größen. Empfehlung: so lassen, ×1
    wäre mit 47 % zu klein; im Style-Guide als bewusste Ausnahme vermerken.
  - Das 1024er Symbol für macOS sitzt 1 Bildpixel links von der Mitte (leere 19. Spalte), die ICO
    mittig. Empfehlung: eigener kleiner Folgepunkt außerhalb von 007, weil er das Mac-Symbol und das
    Liquid-Glass-Symbol ändert.
  - Der Rand des abgerundeten Quadrats ist in allen Größen geglättet, wie im 1024er Symbol.
    Empfehlung: so lassen; das Symbol steht im System neben anderen, nicht im VGA-Bild.
- **Läufe auf anderen Rechnern (T047, T048):** Linux (AMD R7 200, RADV, Vulkan 1.3) 37 von 37,
  35 Fotos gleich den Mac-Referenzen. Windows auf MacBook Pro 2015 mit Boot Camp (AMD R9 M370X):
  Forward+ startet nicht, ohne Meldung; mit erzwungenem OpenGL 37 von 37 und 35 Fotos gleich.
  Ein Windows-Lauf mit Vulkan oder Direct3D 12 steht aus (Beleg mit `hinweis.md`).
- **Abweichung von FR-017, von Klaus mit Empfehlung abgenommen (T049):** Startet Direct3D 12 nur halb, zeigt Godot
  keine Meldung. Empfehlung: so lassen und in quickstart.md erklären (erledigt); eine eigene Prüfung
  beim Start wäre ein eigenes Feature.
- **Renderer:** Ob das Spiel bei Forward+ bleibt oder auf Compatibility wechselt, klärt eine eigene
  Sitzung („Renderer klären: Forward+ oder Compatibility“); bis dahin gilt CLAUDE.md.
- **Agent:** `werkstatt.gd` und `selbsttest_ergebnis.gd` schalten `GameWindow` jetzt mit
  `set_process_input(false)` ab; `invaders_page.gd` fragt das Vollbild-Kürzel mit `exact_match` ab.

### Feature 007, Phase 5 (2026-10-28)

- **Klaus:** Referenzlauf `2026-10-28_15-14-18` abgenommen; 35 vergleichbare Fotos liegen unter
  `tools/selbsttest/referenz/macos/` (1,4 MB). Die beiden Fotos von Invaders sind nicht
  vergleichbar und haben kein Referenzbild.
- **Klaus, Style-Guide Version 61:** „Texte“ gilt auch für Python-Werkzeuge; englische Meldungen von
  Python und argparse dürfen stehen; nie kürzen, auch nicht in Texten.
- **Entscheidungen Claude:** Der Bericht nennt die Ergebnisse in Wörtern („nicht vergleichbar“), das
  Rechteck als „x 280–420, y 140–152“; „Größe 320 × 180“ bleibt in der Spalte „Pixel“. Der Vergleich
  dauert in reinem Python rund 10 s je Lauf, weil `pngio` die PNG selbst entpackt; für 37 Fotos
  reicht das.

### Feature 007, Phase 4 (2026-10-28)

- **Klaus:** Die Zusammenfassung wird nicht maximiert. Das Fenster behält Größe und Lage aus dem
  Lauf, damit der Selbsttest eine reproduzierbare Fenstergröße hat; ersetzt das Maximieren aus CHK016.
- **Klaus, Lücken der Phasenprüfung (Style-Guide Version 60):** gesperrter Knopf mit Tooltip, der den
  Grund nennt; `raster-8` zwischen Knöpfen; Bestätigung `raster-16` neben der Knopfreihe; Titel eines
  Bereichs `raster-8` über dem Inhalt, „Kopf“ ist eine Fläche, „Titel“ nur Text; Schlusspunkt auf dem
  Bildschirm wie im Protokoll.
- **Folgepunkt, außerhalb von 007:** Die Werkstatt hat noch `raster-4` zwischen Knöpfen, und ihre
  Knöpfe setzen keinen Handzeiger (nur der Zeitstrahl). Beides weicht jetzt vom Abschnitt
  „Werkzeuge“ ab.
- **Hinweis:** „Ordner zeigen“ öffnet den Ordner `selbsttest/` mit dem markierten Zip, nicht den
  Ordner des Laufs aus der Pfadzeile; Knopf und Tooltip sind so freigegeben (CHK002, CHK026).
- **Style-Guide Version 58** (T027, T028): Abschnitt „Werkzeuge“ um Nicht gelaufen, Gesperrt,
  Tooltip, Bestätigung, Umbruch und den Teil „Texte“ ergänzt.

### Feature 007, Phase 3 (2026-10-28)

- **Klaus:** Der Selbsttest fand, dass `GameWindow` das Fenster mittig auf dem ganzen Bildschirm
  stellt, nicht im nutzbaren Bereich ohne Menüleiste und Dock (bei Klaus 63 Pixel zu tief). Das Spiel
  wird gerichtet: Fenster samt Titelleiste mittig im nutzbaren Bereich.
- **Entscheidungen Claude:** Der Vertrag übernimmt die Auslegungen des Agents zu allen Abläufen
  (Erwartungen in der Form des Befunds). `bedienung.01` mit vier Pfeiltasten, weil ohne Spielstand
  „Neues Spiel“ vorgewählt ist. `fenster.03` mit 1318 × 742 statt 1317 × 741, weil macOS bei
  Skalierung 2 nur ganze Punkte setzt. Zeilen mit Spielstand stehen in `erwartet:` mit Grad und
  Spieldatum; „Linksklick auf Spiel 1“ ohne „Zeile“.
- **Fehlerprobe (T024, SC-004, SC-010):** Ein eigener Agent baute verdeckt je einen Fehler in Titel,
  Gradwahl, Liste, Rückfrage, Easter Egg und Fenster in sechs Kopien. Jeder Fehler stand im passenden
  Schritt; Claude ordnete alle sechs Protokolle ohne Schlüssel richtig zu.
- **Filter nach `fenster` (Analyse, U3) nicht automatisch prüfbar:** Echte Mausereignisse lassen
  sich ohne Bedienungshilfen-Recht nicht erzeugen; die Probe mit `CGEvent` kam nicht an. Klaus prüft
  es bei der Abnahme von Hand (Maus und Tasten während des ganzen Laufs).
- **Lücken aus der Phasenprüfung, von Claude entschieden:** Ziffern bei Maß und Anzahl im Werkzeug
  („7 Spielstände“), „ein/eine“ als Wort; Lage mit Richtungen statt Vorzeichen; Einheiten „0,5 s“ und
  „Pixel“ bleiben; Fehlertexte des Spiels in „gefunden:“ in Anführungszeichen mit ihrem Punkt;
  `erwartet: keine` bei einer Entscheidung ohne Erwartung; „Seed“ als Fachwort; Ziele in „Ziel nicht
  gefunden“ nur mit dem Namen der Zeile. Kommt mit T027 in den Abschnitt „Werkzeuge“.
- **Klaus:** 19 Textbefunde, Vertrag überall angeglichen (Eingaben mit Ziel, Gehäusetasten links,
  Mitte, rechts, „Rollmarke“, „Invaders“).
- **Restrisiko Zeigerform** aus Phase 2: tritt in `laden` und `loeschen` nicht auf, auch mit dem echten
  Zeiger auf der Liste (drei Läufe). Bleibt ein Risiko, falls das Spiel später die Zeigerform an
  einem Menü-Button setzt, der schon im Baum hängt.

### Feature 007, Phase 2 (2026-10-28)

Lücken aus der Phasenprüfung (Text-Prüfer), von Claude entschieden:
- **Englische Fehlernamen von Godot** (`error_string()`) dürfen in Meldungen des Selbsttests stehen,
  etwa „titel.01_start.png ließ sich nicht schreiben: File: Can't open“. Sie sind Daten der Engine
  wie Testausgaben; übersetzt wären sie geraten. Kommt mit T027 als Satz in den Abschnitt
  „Werkzeuge“.
- **Seite ohne Kopfzeile** heißt im Protokoll nach ihrem Knoten, heute nur „Seite Invaders
  sichtbar“, wie im Vertrag. Bekommt eine neue Seite keine Kopfzeile, nennt ihr Vertrag den Namen.
- Verworfen: Großer Anfang bei satzartigen Meldungen ist keine Lücke (ein Satz ohne Schlusspunkt
  bleibt ein Satz, CHK034); „Ordner“ in der Meldung zum fremden Ordner ist richtig, sie nennt einen
  Pfad, nicht die Spielstände.
- **Klaus:** Bei titel.02 und titel.03 heißt `erwartet:` jetzt „Menü steht: …“ wie `gefunden:`,
  Hinweis ausgeschrieben, überall „nichts ausgelöst“ (contracts/ablaeufe.md).
- **Nachprüfung, von Claude entschieden:** „nicht verfügbar“ steht in `erwartet:` und `gefunden:`,
  „verfügbar“ nur, wo ein Schritt es erwartet; bedienung.03 heißt jetzt auch „Menü steht: …;
  nichts ausgelöst“. Offen, nicht dringend: „Seite Invaders“ steht im Vertrag nicht in Versalien,
  weil die Seite keine Kopfzeile hat; Empfehlung, so lassen (Name, keine Kopfzeile).
- **Für T018:** Ein Lauf dauert nur etwa 0,5 s nach rund 0,7 s Start; Maus und Tastatur während des
  Laufs und Schließen mitten im Lauf sind von Hand kaum zu treffen. Claude hat das Schließen mit
  einem Beenden-Befehl zu drei Zeitpunkten probiert (research.md, „Auslegungen aus Phase 2“).

### Feature 007, Phase 1 (2026-10-28)

- **Testläufe aus Worktrees teilen sich `user://`:** Alle Checkouts des Projekts heißen „Der
  Computerladen“ und schreiben nach `app_userdata/Der Computerladen/`. Lief die Sitzung 008 in ihrem
  Worktree gleichzeitig Tests, wurden beim Agent drei Läufe rot (bis zu 54 Tests in
  `test_title_screen`, `test_save_store`, `test_simulator`, `test_statistics_panel`,
  `test_werkstatt_scene`). Claudes Läufe nach dem Warten waren zweimal grün. Empfehlung: Sitzungen
  warten aufeinander (die Sitzung 008 tut es schon); auf Dauer eigene Testordner je Checkout.
- **`test_title_screen.gd` wackelt vielleicht schon auf `main`:** Der Agent ließ die Datei auf einer
  Kopie von HEAD sechsmal allein laufen, zweimal rot. Nicht nachgeprüft, ob dabei ein anderer
  Testlauf lief. Zu klären außerhalb von 007.
- **Entscheidung Claude:** Text für `eingaben:` als eigener Schlüssel im Schritt (research.md,
  „Auslegungen aus Phase 1“).

### Feature 007, Plan (2026-10-28)

Eigene Entscheidungen von Claude in `specs/007-build-export-selbsttest/research.md`:
- **Eigener Läufer statt GUT** (R1), Code unter `src/tools/selbsttest/`, damit der normale Export
  ihn wie die Werkstatt weglässt; die Werkstatt kommt mit in die Selbsttest-App (R2).
- **Ein Fahrer** zwischen Abläufen und Titel, damit Änderungen an der Oberfläche eine Stelle treffen
  (R5).
- **Höchstzeit 5 s je Schritt**, keine festen Wartezeiten, echte Fahrt des Communicators (R6).
- **Feste Zeit `2026-10-26 20:40 UTC`, Seed 4711, Zeitzone UTC+1** im Selbsttest; dafür eine
  Stellschraube in `SaveGame`, die einzige Änderung am Spielcode in Teil 1 (R7).
- **Fotos vom versteckten Spiel sind „nicht vergleichbar“**, weil es nach Zeit rechnet (R7).
- **Ein Protokoll als Text mit festen Schlüsseln**, kein JSON daneben (R9).
- **ICO mit sechs Größen aus `make_icon.py`**, statt Godot die PNG verkleinern zu lassen (R14).
- **F11, Alt+Enter und Ctrl+Cmd+F gelten auf jedem System** in einer Aktion (R15).
- **Bauzeit = Änderungszeit des Pakets** (R21).
- **Zeitraffer-Faktor 8** über `Engine.time_scale`; `fenster` läuft mit Faktor 1 (R24).
- **`tools/build/baue_alles.sh` als Shell-Skript**, Zips unter `build/abnahme/`, mit `--nur macos`
  für die Phasen vor Teil 2 (R26).
- **Szenario-Rahmen** als `SelbsttestSzenario` mit Start, Entscheidungen und Prüfpunkten nach
  Spieldatum (R27).
- **Befund:** Auf Klaus' Mac fehlen die Export-Templates für Windows und Linux; Download in Phase 6
  als `[K]`. `rcedit` wird nicht gebraucht.
- **Zum Aufräumen:** Die Recherche hat unter `~/Library/Application Support/Godot/app_userdata/`
  die Ordner `Probe` und `Probe Selbsttest` angelegt; sie können weg.

### Feature 007, Spec (2026-10-28)

Eigene Entscheidungen von Claude in `specs/007-build-export-selbsttest/spec.md`, umgesetzt in der
Spec, von Klaus noch nicht bestätigt:
- **Ein Fehler beendet nur seinen Ablauf:** Der Rest des Ablaufs gilt als „nicht gelaufen“, der
  nächste beginnt beim frischen Titel (FR-009). So zieht ein Fehler keine Folgefehler nach sich.
- **Feste Uhrzeit und fester Seed im Selbsttest** (FR-008), weil Hinweise wie „Gespielt am …“ die
  Fotos sonst bei jedem Lauf ändern.
- **Echte Maus und Tastatur sind während des Laufs abgeschaltet,** Schließen des Fensters bricht ab
  (FR-010).
- **„Beenden“ wird nicht ausgelöst,** nur geprüft, dass es da ist (FR-012).
- **Fotos im Oberflächenraster 640 × 360,** nicht in Fenstergröße; die Vergrößerung prüft der
  Ablauf „Fenster“ (Assumptions).
- ~~Höchstens 2 Minuten für einen Lauf~~: entfällt, Klaus will Zeitraffer und keine feste Grenze
  (2026-10-28); SC-001 vergleicht jetzt Zeitraffer und Echtzeit.
- **Linux nur x86_64** (FR-021).
- **Der Abschnitt „Bedienung“ der Abläufe** prüft jede Eingabeart des Titels einmal (FR-011,
  Punkt 6).
- **Fortschritt im Fenstertitel** (FR-003, aus `/speckit-clarify`), nicht im Spielbild, damit die
  Fotos nur das Spiel zeigen.
- **`rcedit` wird vermutlich nicht gebraucht:** Nach Claudes Wissen setzt Godot seit 4.1 Symbol und
  Versionsangaben einer Windows-App selbst. Der Plan prüft das in der Doku von 4.7, bevor ein
  Download angefragt wird.
- **Befund am Rande:** Ohne Einstellung weicht Godot heute still auf einen einfacheren Renderer aus,
  wenn Vulkan oder Direct3D 12 fehlt. Klaus hat entschieden, das abzuschalten (Spec, Clarifications).

### Feature 005, Phase 5 (2026-10-27)

Aus der Phasenprüfung (Stil- und Text-Prüfer, von Claude nachgeprüft):
- **Entschieden:** Der Hinweis glitt beim Fahren kurz über die Versionszeile unten links. Klaus:
  Die Versionszeile steht oben rechts im freien Himmel (T031a, Style-Guide Version 41).
- **Lücken ohne Eile**, Empfehlung jeweils in Klammern:
  - Woran `raster-16` und `raster-8` gemessen werden, am Kasten, an der sichtbaren Schrift oder
    mit Schatten (am Kasten, so prüfen es die Tests).
  - Ob die Versionszeile auf dem dunklen Himmel den Schatten braucht (behalten: gleiche Ausstattung
    wie der Untertitel, kaum sichtbar, schadet nicht).
  - Die Beschreibung des Tokens `pixelschatten` nennt Text auf einem Bild noch nicht. **Erledigt
    in Phase 6 (T035):** Style-Guide Version 47 nennt ihn.
  - Was „Bewegung reduzieren“ an den Communicator anschließt, regelt das Feature der Einstellungen
    (`animate` ist vorbereitet).
- **Beobachtung:** In Doto 10 sieht der Punkt in „V0.1“ mit Schatten fast wie ein „₊“ aus; lesbar.
- **Entschieden bei der Abnahme:** Anzeige 320 × 160 statt 384 × 192 und neues Gehäuse G-03 nach
  dem Olivetti D2000 (spec.md, Abnahme Phase 5). Damit ist die Tastatur oben doch im Bild; der
  Punkt „Tastatur nicht im Bild“ aus Phase 4 gilt nicht mehr.
- **Lücken aus der Nachprüfung von G-03, ohne Eile** (Empfehlung in Klammern):
  - Neben der Anzeige bleibt ein schmaler Streifen vom Glas des Bildes sichtbar, links und oben
    dunkler, rechts und unten heller (so lassen: wirkt wie ein vertieftes LCD, Licht von oben
    links; im Baustein festhalten, wenn es ein zweites Gehäuse gibt).
  - Ob das Gehäuse einen `pixelschatten` auf das Titelbild wirft (nein: es ist Grafik im Bild,
    kein Fenster über der Szene).
- **Eigene Entscheidungen von Claude:**
  - Die Liste wählt ihre sichtbaren Zeilen nach `look` (auf Papier 6, auf der Anzeige 5) statt
    nach der Höhe der Seite, weil die Größe erst nach dem Bau der Zeilen kommt (Agent, T031c).
  - Der Abstand zwischen Logo und Gehäuse wird am Kasten des Logoblocks gemessen, ohne Schatten,
    so wie der Style-Guide den freien Bereich bis y 83 festlegt; der gezeichnete Schatten des
    Untertitels endet bei 82 und liegt darin (Test seit T031e).
  - Menü, Liste, Papier, Hinweis und `TitleScreen.silhouette()` liegen noch unter
    `src/scenes/title/`, obwohl der Communicator sie als Bausteine nutzt. Sie ziehen nach
    `src/ui/` um, wenn das erste Feature sie außerhalb des Titels braucht, etwa der
    Spielbildschirm (T035).

### Feature 005, Phase 4 (2026-10-27)

Aus der Phasenprüfung (Stil-Prüfer, 7 Befunde, alle von Claude bestätigt) und Klaus'
Entscheidungen vom 2026-10-27, alle nach Empfehlung:
- **Tastatur nicht im Bild:** Der Baustein Communicator sagt jetzt „Deckel, Scharnier und der
  Ansatz des Unterteils; die Tastatur liegt unter dem Bildrand“.
- **Logo und Untertitel auf der Fassade:** bekommen den `pixelschatten`; neue Regel im README,
  Abschnitt Logo: Text direkt auf einem Bild trägt auf unruhigem oder hellem Grund den Schatten.
  Umgesetzt in Phase 5 (T028).
- **Gehäuse zu braun:** aufgehellt auf Cremebeige wie die Geräte in C2.
- **Schaufenster unter dem Gerät angeschnitten:** Klaus hatte T-02 nach einer Montage gewählt; so
  bleibt es.
- Offene Lücken aus derselben Prüfung, ohne Eile: ab wann ein Grund „unruhig“ ist; ob „Licht von
  oben links“ in Nachtszenen mit eigener Lichtquelle für das Umgebungslicht gilt; die Grenze
  zwischen Textur mit Dithering und Rauschen. Empfehlung: bei der nächsten Szene klären, nicht
  jetzt.

### Feature 005, Phase 3 (2026-10-27)

Lücken im Style-Guide aus der Phasenprüfung (Stil-Prüfer, von Claude nachgeprüft). Von Klaus am
2026-10-27 mit der Abnahme von Phase 3 nach Empfehlung entschieden und eingetragen (Style-Guide,
Version 38, Bausteine Liste und Menü):
- **Rollmarke in einer gewählten, gedämpften Zeile:** Im Löschmodus ist „Löschen …“ gedämpft. Ist
  es gewählt und steht unten mehr, ist die Rollmarke `lcd`, Schrift und Pfeil aber
  `gehaeuse-dunkel`. Der Baustein Liste sagt „`lcd` wie die Schrift“. Empfehlung: so lassen, denn die
  Rollmarke gehört zur Liste, nicht zum Eintrag; im Baustein „wie die Schrift“ ersetzen durch „auch
  wenn die Zeile gedämpft ist“.
- **Gedrückte Zeile:** Das README verlangt für alles Bedienbare `relief-gedrueckt` beim Drücken;
  Menü und Liste regeln weder auf Papier noch auf der Anzeige, ob eine Zeile gedrückt anders
  aussieht. Gebaut ist seit Feature 001: kein eigener Zustand. Empfehlung: im Baustein Menü
  festhalten „Eine Zeile hat keinen eigenen Zustand ‚gedrückt‘; die Auswahl ist die Rückmeldung.“

### Feature 005, Phase 2 (2026-10-27)

Auslegungen des Agents beim Baustein Communicator, von Claude übernommen. Klaus bestätigt sie oder
ändert sie mit der Abnahme von Phase 2 (T012):
- **Ungerade Endlage meldet eine Warnung:** Steht der Communicator in seiner Szene nicht auf ganzen
  Bildpixeln, meldet `_ready()` das per `push_warning`; jeder Bildschirm fällt so beim Start auf.
- **Fahrt ohne Weg meldet sofort:** Steht der Communicator schon am Ziel, kommt `slide_finished`
  gleich, damit ein Bildschirm, der darauf wartet, nie hängen bleibt. Ein zweites `slide_in()`
  während der Fahrt ändert nichts; `place_hidden()` meldet nichts, es ist keine Fahrt.
- **Ende der Fahrt aus dem Tween:** Das Ende meldet das Signal `finished` des Tweens, nicht der
  Rückgabewert von `custom_step()`, der erst ein Bild später `false` wird (Fehler im Spike, bei 30
  Bildern je Sekunde 267 statt 233 ms).
- **Sperre über Godots rekursive Sperre:** `focus_behavior_recursive` und
  `mouse_behavior_recursive` sperren beim Hinausfahren den ganzen Teilbaum, auch Zeilen, die ein
  Menü erst zur Laufzeit baut; keine Sperrfläche (sie hielte die Tastatur nicht ab).
- **Ruhender Zeiger:** Godot 4.7 meldet `mouse_entered` nur bei echter Mausbewegung; eine eigene
  Sperre für die Fahrt herein ist nicht nötig. Im echten Fenster prüft Klaus es mit der Probeszene.
- **Hinweis ohne neue Funktion:** Der Communicator reicht `MenuHint` ein Rechteck mit der linken
  Kante des Gehäuses; `MenuHint` bleibt unverändert.
- **Lücken aus der Phasenprüfung:** rechter Rand und Hinweis beim Hinausfahren; von Klaus am
  2026-10-27 nach Empfehlung entschieden und im Baustein Communicator eingetragen (Style-Guide,
  Version 37): Der Rand bis 616 gilt für Anzeige und Seiten, das Gehäuse darf bis an den Bildrand;
  der Hinweis fährt mit hinaus. Die Auslegungen oben hat Klaus mit der Abnahme bestätigt.
- **Für Phase 5 merken:** Ruft der Titel während der Sperre `select()` an Menü oder Liste, druckt
  Godot „can't grab focus“, und die Startprobe würde laut. Das Flag `_leaving` muss deshalb auch vor
  jedem `select()` greifen (T029).

### Feature 005, Plan (2026-10-27)

Eigene Festlegungen von Claude in `specs/005-communicator/research.md`. Klaus bestätigt sie oder
ändert sie, spätestens mit der Checkliste:
- **Gewählt und nicht verfügbar** (R3): Balken `tusche`, Schrift und Pfeil `gehaeuse-dunkel`
  (3,08 : 1), wie auf dem Papier gedämpft auch gewählt.
- **Papier bleibt in Menü und Liste** (R5): Schalter `look` mit `PAPER` als Vorgabe; der Titel nutzt
  nur `LCD`. Die Seiten nehmen auf der Anzeige die volle Breite ein.
- **Zeitschritt gedeckelt** (R6): im ersten Bild jeder Fahrt auf 1/60 s, danach auf 1/30 s. So
  springt das Gerät im langen ersten Bild höchstens ein Viertel des Wegs (23 %), und die Fahrt
  dauert auch bei 30 Bildern je Sekunde gut 233 ms. Bis zur Analyse (C2) stand hier 1/30 s für
  jeden Schritt, was im ersten Bild 42 % ergab.
- **Erst anlegen, dann hinausfahren** (R8): Scheitert das Anlegen, fährt nichts, und die Meldung
  kommt sofort. Dazu sperren Communicator und ein Flag `_leaving` im Titel jede Eingabe während der
  Fahrt hinaus (Analyse, B2, C20).
- **Helle Schrift der gewählten Zeile aus dem Code** (R15), weil ein Button unter der Maus die
  Hover-Farbe nimmt und das Theme allein eine Zeile unsichtbar machte (Analyse, B1).
- **Der Hinweis gehört zum Communicator** (R7) und fährt als Kind mit, statt wie im Spike per
  Differenz nachgeführt zu werden.
- **Platzhalter-Gehäuse** (R11): Kern und Seiten entstehen vor G-02 mit einem Rechteck in
  `gehaeuse`; nur der Titel wartet auf die Bilder.
- **Vorschlag `lcd` = #b8c4a8** (R2) und **Lage im Titel** (R9): von Klaus mit Phase 1 freigegeben
  (2026-10-27); stehen im Style-Guide, Version 36.

### Feature 005, Spec (2026-10-27)

Eigene Festlegungen von Claude in `specs/005-communicator/spec.md`, die nicht aus Klaus' Antworten
folgen. Klaus bestätigt sie oder ändert sie, spätestens mit dem Plan:
- **„Beenden“ ohne Fahrt** (FR-013a, Annahmen): Nur Spielstart und Fortsetzen lassen den
  Communicator erst hinausfahren; „Beenden“ schließt sofort, weil danach nichts mehr zu sehen ist.
- **Seitenwechsel ohne Übergang** (FR-005): Die neue Seite ersetzt die vorige sofort, das Gerät
  bleibt stehen, wie bei den Blättern aus dem Drucker.
- **Bedienbar schon während der Fahrt herein** (FR-003): Enter auf „Weiterspielen“ wirkt, bevor
  das Gerät steht; während der Fahrt hinaus wirkt dagegen keine Eingabe (FR-013a).
- **Jedes Mal hereinfahren** (FR-010): auch nach der Rückkehr aus dem Spiel, nicht nur beim Start
  der App.
- **Der Hinweis fährt mit** (FR-006), statt erst zu erscheinen, wenn das Gerät steht.

### Feature 004, Phasenprüfung Phase 2 (2026-10-26)

Lücken im Abschnitt „Sprache“, die der Text-Prüfer gemeldet und Claude bestätigt hat. Zwei hat
Klaus gleich entschieden (unter „Erledigt“); diese bleiben offen, keine blockiert etwas:
- **Grund im Hinweis: Fehlermeldung oder Hinweis?** „Sprache“ erlaubt Witz in Hinweisen, aber
  nicht in Fehlermeldungen. Ein Grund wie „Der Schwierigkeitsgrad ist unbekannt.“ steht im Hinweis,
  ist aber eine Fehlermeldung. Empfehlung: ergänzen „Was ein Hinweis über einen Fehler sagt, ist
  eine Fehlermeldung: ohne Witz.“
- **Wörter aus dem Inneren des Spiels:** Klaus hat für die Gründe entschieden, dass Seed,
  Formatversion, Eingriff und Ereigniskatalog nicht beim Spieler erscheinen. Empfehlung: als
  allgemeine Regel unter „Nicht“ aufnehmen: „Keine Wörter aus dem Inneren des Spiels in Texten für
  den Spieler, etwa Seed oder Formatversion; die gehören in die Werkzeuge und ins Protokoll.“
- **Tausenderpunkt außerhalb von Geld:** „Sprache“ zeigt ihn nur an DM-Beträgen. Empfehlung:
  Punkt bei Beträgen und Mengen ab vier Stellen, nicht bei Nummern und Namen („Spiel 10000“).
- **Gilt „Sprache“ auch fürs Protokoll?** (Nachprüfung) Der Abschnitt sagt nicht, ob er auch
  für Texte gilt, die nur ins Protokoll gehen (`push_warning()`, `last_error`). Das Datenmodell
  erlaubt dort Godots englische Fehlertexte. Empfehlung: im Einleitungssatz klarstellen „für alle
  Texte, die der Spieler sieht; das Protokoll ist für Entwickler und muss nur richtig sein“.
- Verworfen: „Grad“ und „Schwierigkeitsgrad“ seien zwei Wörter für dasselbe. „Gradwahl“ ist nur
  der Name im Vertrag; der Spieler liest SCHWIERIGKEIT und die Grade selbst.

### Feature 004, Lückensuche (T033, 2026-10-26)

- **`/speckit-converge`:** 64 Anforderungen, Szenarien und Edge Cases, 24 Plan-Entscheidungen und
  7 Grundsätze der Verfassung geprüft. Zwei kleine Funde, beide in Phase 7: Speichern verliert bei
  zwei Fehlern hintereinander eine `.neu` (T036, Klaus: reparieren), der Knopf des
  Spielbildschirms ohne laufendes Spiel (T041, Auslegung angenommen: Läuft kein Spiel, etwa weil
  die Szene im Editor allein startet, führt der Knopf ohne Speichern gleich ins Hauptmenü;
  `game_screen.gd`, `_on_leave_button_pressed()`). FR-015 in der Spec war
  veraltet und ist nachgezogen.
- **Stil-Prüfer:** kein Verstoß am Gebauten. Der Vertrag sagte beim Knopf „Mauszeiger: die Hand“
  ohne Ausnahme; nachgezogen. Lücken entschieden (Style-Guide Version 30): Zebra an der Stelle,
  Rollmarken nur Anzeige, Fokuslinie nur bei Tastatur. **Offen, ohne Eile:** Was geschieht, wenn ein
  Hinweis unten aus dem Bild ragen würde? Heute bleiben 10 Pixel; Empfehlung: dann rechts neben der
  Zeile oder nach oben versetzt, festlegen, wenn ein höheres Blatt kommt.
- **Text-Prüfer:** zwei Befunde bestätigt, beide in Phase 7 (T037 Grund ohne „das Spiel“, T038
  Hinweis von „Spiel laden“). Verworfen: „Spiel laden“ neben „Laden aufmachen“ sei ein Wort für
  zwei Dinge; Verb und Name des Ladens sind verschiedene Wörter, „Spiel laden“ ist der übliche
  Menüeintrag. Lücken entschieden (Version 30): Namen im Satz groß, das Programm heißt nicht „das
  Spiel“. Die Regel „ein Hinweis verspricht nur, was geht“ hat Klaus am 2026-10-27 wieder
  verworfen: Ein Hinweis wechselt nicht mit der Lage, „Spiel laden“ sagt immer „Zurück in einen
  deiner Läden.“ (Style-Guide Version 33).

### Feature 004, Prüfung der Spielbeschreibung (2026-10-27)

Beim Nachziehen von `docs/spielbeschreibung/` fand die Prüfung zwei Stellen, an denen Spec und Code
auseinandergehen; die Spielbeschreibung folgt dem Code.
- **Reihenfolge beim Fortsetzen:** `data-model.md` (Abschnitt „GameSession“) und `tasks.md` sagen
  „Uhr auf `day`, dann `Timeline.resume_game()`“. `GameSession.resume()` ruft erst
  `resume_game()` und stellt dann die Uhr, damit bei einer Ablehnung der Zeitleiste die Uhr bleibt,
  wie sie war; begründet nur im Code-Kommentar. Bei einem fortsetzbaren Spielstand ändert das
  nichts. Empfehlung: die Reihenfolge des Codes in `data-model.md` nachziehen.
- **Nächste Nummer:** FR-009 in `spec.md` sagt „um eins größer als die größte Nummer unter den
  vorhandenen Spielständen“. `SaveStore.next_number()` zählt alle Dateien nach dem Muster mit,
  auch eine übrig gebliebene `.neu` ohne Spielstand und Ordner mit solchem Namen, wie es
  `data-model.md` und R4 festlegen. Empfehlung: den Satz in FR-009 an R4 angleichen.

### Feature 004, Phasenprüfung Phase 5 (2026-10-26)

- **Erledigt durch Klaus' Entscheidungen** (Style-Guide Version 29, Vertrag nachgezogen):
  - Im Löschmodus sind beschädigte und zu neue Spielstände verfügbar, nicht gedämpft; gedämpft heißt
    immer „löst nichts aus“ (Stil-Prüfer, Widerspruch zum Vertrag).
  - Rückfrage bei nicht fortsetzbaren Spielständen in derselben Satzform wie bei fortsetzbaren:
    „Spiel 9 bleibt: neuere Version. Esc geht auch.“ (Text-Prüfer, Widerspruch zum Vertrag).
  - „Vorher fragt das Spiel nach.“ wird „Vorher kommt eine Rückfrage.“; in „Sprache“ steht die
    Regel „Kein Wort für zwei Dinge auf demselben Blatt“ (Text-Prüfer, Lücke).
  - Der Hinweis einer Zeile der Liste nennt beide Daten: „Steht am 13.07.1985. Gespielt am
    26.10.2026, 21:40 Uhr.“ Damit ist der Punkt aus Phase 4 „erklärt das Spieldatum nicht“ erledigt.
- **Repariert** (Stil-Prüfer, bestätigt): Die Meldung „Löschen ging nicht“ blieb beim Rollen an der
  Stelle statt beim Spielstand. Sie gehört jetzt zum Spielstand.
- **Lücke im Style-Guide, erledigt in Version 30** (Stil-Prüfer): README, Bewegung, nennt Übergänge von 150 bis
  250 ms, „Fenster gleiten oder klappen auf“. Ob ein Blatt im Titel, das ein anderes ersetzt, und
  das Rollen der Liste einen Übergang haben, regelt er nicht; gebaut ist ein Sprung, seit Phase 4.
  Empfehlung: Blätter und Rollen springen, wie ein neuer Ausdruck aus dem Drucker; in „Bewegung“
  so festhalten. Für die Lückensuche in Phase 6.
- **`SaveGame.time_sentence()` wird nicht mehr gebraucht** (Godot-Agent): Der neue Hinweis der
  Liste setzt Datum und Uhrzeit aus `time_text()` zusammen. `time_sentence()` steht noch im Vertrag
  `contracts/spielstand.md` und in `test_save_game.gd`. Empfehlung: in Phase 6 mit Vertrag und Test
  entfernen.
- **GUT meldet 4 Orphans in `test_main_menu.gd`** (Buttons), schon vor der Reparatur. Die Tests
  sind grün. Empfehlung: in Phase 6 ansehen.
- **Lücke im Style-Guide, erledigt in Version 30** (Stil-Prüfer, Nachprüfung): Baustein Meldung sagt „bleibt, bis
  der Spieler eine andere Zeile wählt“, aber nicht, ob die Zeile der Eintrag oder die Stelle ist.
  Gebaut ist: Die Meldung gehört zum Eintrag und wandert beim Rollen mit; rollt er aus dem Fenster
  und die Auswahl rückt nach, ersetzt der Hinweis sie. Empfehlung: diesen Satz in den Baustein
  Meldung aufnehmen, in Phase 6.
- **Verworfen** (Text-Prüfer, Nachprüfung): „Spiel 4 ist danach weg: beschädigt. Für immer.“ lasse
  sich als „für immer beschädigt“ lesen. Der Punkt trennt die Sätze, und die Satzform ist die der
  fortsetzbaren Spielstände, die Klaus abgenommen hat.
- **Verworfen:** „WELCHES LÖSCHEN?“ statt „WELCHEN“ (Text-Prüfer): richtig, bezogen auf „Spiel 7“,
  und so im Style-Guide. Rollmarke in `tusche` neben dem gedämpften „Löschen …“ (Stil-Prüfer): Sie
  gehört zur Liste, nicht zum Eintrag. Rollen ohne Auswahlwechsel als „andere Zeile“ (Stil-Prüfer):
  Die Regel der Meldung beantwortet das, gewählt bleibt derselbe Spielstand.

### Feature 004, Phasenprüfung Phase 4 (2026-10-26)

- **„Spiel laden“ tut in Phase 4 noch nichts** (Text-Prüfer, bestätigt): Mit Spielständen ist der
  Eintrag verfügbar, sein Hinweis verspricht die Liste, die erst mit T026 kommt. Erledigt sich mit
  Phase 5; bis dahin nur für die Abnahme von Phase 4 wichtig.
- **Lücken in „Sprache“** (Text-Prüfer), je mit Empfehlung, keine blockiert:
  - Hinweis einer Zeile der Spielstände: Er nennt „zuletzt gespielt“, sagt aber nicht, was Enter
    tut, und erklärt das Spieldatum nicht. Empfehlung: in Phase 5 messen, ob „Spielt am 14.03.1986
    weiter. Zuletzt gespielt am …“ in zwei Zeilen passt; sonst so lassen.
  - Gleiche Wörter: „Weiterspielen“, „fortsetzen“ und „laden“ für dieselbe Handlung; „Noch kein
    Spiel angefangen.“ und „Noch keine Spielstände.“ für denselben Zustand. Gehört zur offenen
    Regel „Dasselbe heißt überall gleich“ (Phase 3).
  - Satzform der Hinweise (Infinitiv, Imperativ, dritte Person) ist nicht geregelt. Empfehlung:
    „Ein Hinweis sagt im Infinitiv, was der Eintrag tut; Gründe und Zustände als Aussagesatz.“
  - Ob der Wortschatz der Zeit auch für Texte über den echten Rechner gilt („Desktop“, „Esc“).
- **Erledigt durch Klaus' Entscheidungen** (Stil-Prüfer): Lochrand an der Unterkante und Abstand
  des Hinweises zum allein stehenden Knopf, siehe „Erledigt“.
- **Für Phase 5 merken:** Die Meldung „Löschen ging nicht. Der Spielstand ist noch da.“ stimmt
  nicht, wenn `delete()` mit `ERR_FILE_NOT_FOUND` endet, weil die Datei schon weg ist.

### Feature 004, Phasenprüfung Phase 3 (2026-10-26)

Lücken im Style-Guide, die der Text-Prüfer gemeldet und Claude bestätigt hat; keine blockiert:
- **„Ein Satz pro Meldung“ gegen die Beispiele:** Der Leitsatz „Kurz und gesprochen“ verlangt
  einen Satz, das Beispiel einer Meldung in „Sprache“ hat drei, der Baustein Meldung zwei.
  Empfehlung: „Eine Meldung sagt eine Sache in höchstens zwei kurzen Sätzen.“
- **„Meldung“ heißt zweierlei:** In „Sprache“ ist eine Meldung eine Nachricht aus dem Spiel mit
  Witz, im Baustein Meldung ein Fehler ohne Witz. Empfehlung: In „Sprache“ für Nachrichten aus
  dem Spiel „Nachricht“ sagen und ergänzen: „Die Meldung (Baustein) ist eine Fehlermeldung: ohne
  Witz.“
- **Dasselbe heißt überall gleich:** „Sprache“ hat keine solche Regel; Anlass war „schließen“
  gegen „Beenden“. Mit Klaus' Entscheidung unten ist der Anlass weg. Empfehlung: die Regel
  trotzdem aufnehmen.

### Feature 004, Plan (2026-10-26)

- **Eigener Benutzerordner, später:** Spielstände liegen unter macOS in
  `~/Library/Application Support/Godot/app_userdata/Der Computerladen/`. Mit
  `application/config/use_custom_user_dir` lägen sie unter „Der Computerladen“ ohne „Godot“.
  Empfehlung: vor der ersten Veröffentlichung umstellen, nicht in Feature 004; heute zögen
  Einstellungen und Sicherungskopien der Werkstatt mit um.

### Phase 12 von Feature 002 (2026-10-21)

- **Vier Zeilen in den Tabellen (T101):** Mit der neuen Vorgabe zeigen Statistik mit Warnung und
  Fahrplan je 2 Zeilen statt 1, die Statistik ohne Warnung 5 statt 3. Für 4 Zeilen müsste der
  Zeitstrahl in der Vorgabe 48 px abgeben (378 statt 426 px). Empfehlung: die Vorgabe lassen. Den
  Teiler ziehst du einmal dorthin, wo er dir passt, und die Werkstatt merkt ihn sich (T091).

### Feature 003, Plan (2026-10-21)

- **Startwerte der Profile (R18):** Claudes Vorschlag für die sechs Ereignisse über
  Wahrscheinlichkeit steht in `specs/003-schwierigkeitsgrade/research.md`, R18. Klaus legt die
  Profile zur Abnahme von Phase 3 in der Werkstatt an und stellt sie mit der Statistik nach. Seit
  2026-10-22 steht fest, dass beide Profile zur Gesamtabnahme gefüllt sein müssen
  (Checkliste, CHK008). Offen sind nur noch die Werte. Stand 2026-10-23 (T020): Klaus hat je drei
  Start-Modifikatoren angelegt, alle auf „Großkunde meldet sich“, als vorläufige Werte (Leicht
  zusammen −2, Schwer +3). Er stellt sie später mit der Statistik ein, die mit Phase 5 die Grade
  vergleicht.

### Feature 003, Lückensuche (2026-10-26)

- **Mögliche Schieflage der Würfel (Feature 002, `EventDice`):** Über die Seeds 1 bis 4.000 liegt
  die Reklamationswelle mit 3 % pro Monat im Mittel bei 5,508 statt 5,4 und mit Schwer bei 14,579
  statt 14,4, beides etwa drei Standardabweichungen darüber. SC-003 ist trotzdem klar erfüllt.
  Empfehlung: später einmal die Würfel je Kennung prüfen; für Feature 003 nichts zu tun.

### KI-Workflow und Prüf-Agents (2026-10-22)

Aus der Einführung der Prüfer, beschrieben in `docs/ki_workflow/ki_pruefung.md`.
- **Gemeinsames `user://`:** Alle Arbeitsordner teilen sich `user://` von „Der
  Computerladen“, und die Tests schreiben in feste Unterordner wie `user://test_simulator/`. Zwei
  Testläufe zur selben Zeit, etwa im Worktree der Arbeitsweise und in der Sitzung „[003]
  Schwierigkeitsgrade ab dem Plan“, können sich stören. Ein Hook, der von selbst testet, macht das
  wahrscheinlicher.

### Probelauf des Stil-Prüfers an Feature 001 (2026-10-22)

Der Stil-Prüfer hat Titelbildschirm, Hauptmenü und Hinweis gegen den Style-Guide geprüft, Claude
hat jeden Befund nachgeprüft. Was davon repariert oder in den Style-Guide kommt, entscheidet Klaus,
in einem eigenen Schritt. Zahlen in `docs/ki_workflow/ki_pruefung.md`, „Nachmessen“.
- **Bestätigt:**
  - **Logo ohne `pixelschatten` (mittel):** Das Logo steht halb auf Himmel, halb auf der
    Fassade, also auf unruhigem Grund. Der Style-Guide verlangt dort `pixelschatten` (Logo). Das
    PNG hat keinen, die Szene auch nicht. Empfehlung: Schatten ergänzen, wie beim Hinweis. **Erledigt mit Feature 005, Phase 5:** Das
    Logo hat auf T-02 eine Silhouette in `tusche` als `pixelschatten`.
  - **Ränder nicht aus dem Raster (mittel):** Logo bei x 14 und y 12, Menü 24 vom rechten Rand,
    Versionszeile 6 vom unteren. `raster-16` ist laut Style-Guide der „Rand zum Bildschirmrand im
    Titel“. Die Werte kommen aus dem Titelscreen-Entwurf und stehen so im Vertrag von Feature 001.
    Empfehlung: auf 16 ziehen; der Entwurf ist älter als die Raster-Regel. **Teils erledigt mit
    Feature 005:** Das Menü ist ersetzt, die Versionszeile steht oben rechts mit 16 Rand (Klaus,
    2026-10-27); offen bleibt das Logo bei 14/12.
  - **Textschatten von 1 px (niedrig):** Untertitel und Versionszeile haben einen harten Schatten
    in `tusche` um (1, 1). Er steht im Vertrag von Feature 001, im Style-Guide gibt es ihn nicht.
    Empfehlung: als Token in den Style-Guide, denn er hält die Schrift auf dem Bild lesbar.
    **Erledigt mit Feature 005:** Der Style-Guide regelt Text auf einem Bild mit `pixelschatten`
    (2 px), Untertitel und Versionszeile haben ihn.
- **Verworfen:** `papier`-Text auf dem Titelbild sei kein erlaubtes Farbpaar. Der Abschnitt Logo
  verlangt den Untertitel aber ausdrücklich in `papier`. Das ist eine Lücke, kein Fehler (unten).
- **Lücken im Style-Guide:**
  - **Text auf einem Vollbild:** Die Farbpaare kennen keinen Bildgrund. Ist `papier` auf dem
    Titelbild erlaubt, und mit welchem Schatten?
  - **Kontur am Menü:** „Alles Bedienbare“ hat eine `tusche`-Kontur und Relief, der Baustein Menü
    beschreibt Endlospapier ohne beides. Welche Regel gilt?
  - **Logo im Spiel:** Der Style-Guide nennt das Original mit 850 × 164, im Spiel steht die
    gerasterte Fassung mit 141 × 27 Bildpixeln. Wie groß darf das Logo erscheinen?
  - **Gelbe Zeile:** Nur der Innenbereich wird `signalgelb`, die Lochränder nicht. Der Baustein
    sagt nur „Die gewählte Zeile ist `signalgelb`“.
  - **Vollbild ohne SubViewport:** Für Szenen beschreibt der Style-Guide einen SubViewport mit
    320 × 180. Das Titelbild ist ein TextureRect mit 640 × 360, ganzzahlig doppelt. Reicht das für
    Vollbilder?
  - Verworfen: die Maße der Lochränder. Sie stehen im Baustein Bildrahmen, den Claude dem Prüfer
    nicht mitgegeben hatte, und der Code hält sie ein.

### Probelauf des Text-Prüfers an Feature 001 und der Werkstatt (2026-10-22)

Der Text-Prüfer hat rund 740 Texte und alle 27 Ereignisse des Katalogs gegen den Abschnitt
„Sprache“ und für die Werkstatt gegen „Werkzeuge“ geprüft, Claude hat jeden Befund im Code
nachgesehen. Feature 001: keine Befunde. Alles Weitere betrifft die Werkstatt, an der gerade die
Sitzung „[003] Schwierigkeitsgrade ab dem Plan“ arbeitet; repariert wird also erst nach Feature 003,
wenn Klaus es will.
- **Bestätigt:**
  - **Prozent ohne Leerzeichen (mittel):** Wirkungen stehen als „-30%“
    (`core/timeline/event_effect.gd:85`), verlangt ist „−30 %“ wie „3,5 %“ unter „Werkzeuge“.
  - **Datum als „02-30“ (mittel):** `core/timeline/catalog_validator.gd:165`; zwei Zeilen davor steht
    „29.02.“. Empfehlung: „30.02.“.
  - **Englische Fehlertexte der Engine (mittel):** `error_string()` und `json.get_error_message()`
    enden in deutschen Sätzen auf Englisch, etwa „… lässt sich nicht schreiben: Can't open.“ Sechs
    Stellen. Tritt nur bei Dateifehlern auf.
  - **Ein Feld, drei Namen (mittel):** „Chance“ im Formular, „Grundchance“ im Verlauf und in den
    Prüfregeln; beim Folgeereignis „Chance“ und „Wahrscheinlichkeit“.
  - **Einzahl fehlt (niedrig):** „dauert 1 Tage“, „nach 1 Tagen“, „Rechnet 1 Spiele“ sind möglich
    (Prüfregeln V19 und Nachbarn, Statistik).
  - **Würfel und Chance in verschiedenen Einheiten (niedrig):** „Würfel 0,4120 < 50 %“
    (`core/timeline/schedule_entry.gd:164`).
  - **Tastennamen englisch (niedrig):** „Ctrl+Shift+Z“ und „Enter“; deutsch wären „Strg“ und
    „Eingabetaste“. Die Schreibweise steht so im Vertrag von Feature 002 (R15); Klaus entscheidet.
  - **Beispiel ohne Vorzeichen (niedrig):** „+5, -6 oder 2,5“ in
    `tools/werkstatt/intervention_dialog.tscn:51`, obwohl der Satz Vorzeichen verlangt.
  - **Zwei Namen für Dauer 0 (niedrig):** „0 heißt Augenblick“ neben „ohne Dauer“
    (`tools/werkstatt/event_form.gd`).
  - **Grammatik im Katalog (niedrig):** „Preise müssen umgedacht werden“ (`euro_buchgeld`);
    Vorschlag „umgerechnet“. Den Katalog pflegt Klaus in der Werkstatt.
- **Verworfen:**
  - Seed ohne Tausenderpunkt: Der Seed ist eine Kennnummer, keine Menge (siehe Lücken).
  - Beispieldatum „1.3.1993“: Es zeigt bewusst, dass die kurze Eingabe geht.
  - „High-End“ im Katalog: ein Computerwort der Zeit, das der Abschnitt „Sprache“ erlaubt.
- **Lücken im Style-Guide:**
  - Gilt „ein Satz pro Meldung“ auch für Dialoge und Tooltips der Werkzeuge? Dort stehen bis zu vier
    Sätze, auch im Beispiel des Abschnitts „Werkzeuge“.
  - Witz in Beispielwerten der Werkzeuge, etwa „etwa Ware vom windigen Händler“?
  - Fachwörter im Werkzeug: Ist „Seed“ erlaubt, und schreibt man Kennnummern mit Tausenderpunkt?
  - Daten in Dateien und auf der Kommandozeile stehen als JJJJ-MM-TT; der Abschnitt regelt nur
    angezeigte Daten.
  - Minuszeichen: „-“ oder „−“? Im Code steht beides.
  - Kategorie „Tech“: ein Anglizismus, sobald sie im Spiel erscheint; deutsch wäre „Technik“.
  - Versionsnummer „V0.1“ mit Punkt statt Komma.
- **Unsicher:** die Mehrzahl „Beginne“ in der Statistik; „Vorkommen“ stünde schon im Kern.

### Ältere Punkte aus Claudes bisherigem lokalem Gedächtnis

- **Spielfenster ragt 6 Pixel in den Bereich des Docks** (Feature 002, Abnahme von Phase 4,
  2026-10-20): beobachtet, von Klaus noch nicht entschieden.
- **Systemmenüs von macOS sind englisch** (Feature 001): Es gibt kein `.lproj`. Ob sie deutsch
  werden, entscheidet Klaus später.
- **Nächstes Feature nach 002:** Empfehlung 02-01 und 02-02, Bible-Importer und Warengruppen.
- **Mac-App unter `build/macos`:** Sie stammt vom Probe-Export vor dem Fensterstart. Neu
  exportieren hat Claude angeboten.

### Feature 008, Recherche (2026-10-28)

- **Fließkomma auf drei Systemen:** Ob GDScript auf Windows, macOS und Linux mit Fließkomma
  bitgleich rechnet, ist ungeprüft. Wichtig, sobald die Wirtschaft mit Seed rechnet und Spielstände
  aus Eingriffen nachspielt (`docs/recherche/architektur-quellen.md`, 6.3).

### Feature 008, Lücken im Style-Guide aus der Phasenprüfung Phase 4 (2026-10-28)

Vom Text-Prüfer an den Testmeldungen von `test_architektur.gd` gemeldet, je mit Empfehlung von
Claude; Klaus entscheidet:
- **Geltung für Testmeldungen:** „Ausgenommen sind Testausgaben“ steht nur unter „Anrede“.
  Empfehlung: ein Satz im Abschnitt „Sprache“: Für Testausgaben gelten klares Deutsch und die
  Begriffe des Maßstabs, den der Test misst; Ton und Wortschatz der Zeit nicht.
- **„das Spiel“ in Texten für Entwickler:** Empfehlung: Die Regel „Das Programm heißt nicht ‚das
  Spiel‘“ gilt nur für Texte, die der Spieler sieht.
- **Ort und Regel in Testmeldungen:** Empfehlung: einheitlich „pfad:zeile:“ und die Regelnummer
  einmal am Ende in Klammern.
- **Namen aus Code und Engine** (Autoload, Node, RefCounted) in Texten für Entwickler: Empfehlung:
  bleiben stehen.
- **Einzahl bei Zahlen** („1 Stelle“): schon als künftiger Test in `ki_pruefung.md` vorgemerkt.

### Feature 008, Lücken im Leitfaden aus Fehler- und Planprobe (2026-10-28)

Gemeldet vom Architektur-Prüfer, von Claude nachgeprüft. Klaus hat am 2026-10-28 alle acht wie
empfohlen entschieden; sie stehen im Leitfaden (AR-02, AR-04, AR-07, AR-08, AR-15, „Schwere“):
- **L1 Stellschrauben und Werte aus dem Style-Guide (AR-04):** Fallen Tempi, Chancen, Pixelmuster
  unter „gepflegte Spieldaten“? Empfehlung: AR-04 gilt für Spielinhalt, also was in die game_bible
  gehört (Produkte, Preise, Kunden, Mieten). Stellschrauben einer Mechanik dürfen als benannte
  Konstanten an einer Stelle im Kern stehen; Werte aus dem Style-Guide spiegelt der Code als
  Konstanten wie `UiPalette`. Folge: Befund 1 der Planprobe wird verworfen, die Miete in der
  Fehlerprobe bleibt ein Befund.
- **L2 game_bible und `.tres` (AR-04, Verfassung V):** Werden Resources aus der game_bible erzeugt
  oder von Hand gepflegt? Empfehlung: Die game_bible bleibt die Quelle; Resources entstehen daraus
  über einen Importer (Backlog 02-01), nie von Hand, damit es keine zweite Quelle gibt.
- **L3 Schwere bei Verstoß gegen die Verfassung:** Empfehlung: Verletzt eine Stelle zugleich die
  Verfassung, gilt „kritisch“, auch wenn die Regel allein „mittel“ wäre.
- **L4 Regelmäßige Buchungen und AR-07:** Ist die Miete am Monatsersten ein „Ereignis“? Empfehlung:
  Ereignis heißt Eintrag im Katalog. Regelmäßiges wie Miete oder Zinsen ist Mechanik eines Kerns;
  den Monatswechsel reicht die Hülle hinein (`GameClock.month_passed`). Ereignisse innerhalb eines
  Kerns, etwa `SHOT` im Easter Egg, sind keine Ereignisse im Sinne von AR-07.
- **L5 Signale übersetzen (AR-02):** Empfehlung: Ein Baustein darf das Signal eines inneren Teils in
  ein eigenes Signal mit eigener Bedeutung übersetzen, wie `CaseKey.pressed` zu `case_key_pressed`;
  verboten ist nur das bloße Durchreichen.
- **L6 Spiel ohne Spielstand (AR-08, AR-09):** Empfehlung: AR-08 und AR-09 gelten für den
  Spielverlauf, der in den Spielstand geht. Ein Minispiel ohne Spielstand darf seinen Startwert in
  der Hülle zufällig wählen; der Kern bekommt ihn trotzdem von außen.
- **L7 Lesbarer Zustand eines Kerns (AR-15):** Empfehlung: Felder, die die Oberfläche nur lesen
  darf, tragen den Doku-Kommentar „Nur lesen.“; der Prüfer meldet Schreibzugriffe von außen.
- **L8 Texte der Oberfläche (AR-04):** Empfehlung: Texte stehen je Bildschirm an einer Stelle als
  Konstanten, wie `TitleTexts`; das ist kein Verstoß gegen AR-04. Dialoge regelt AR-20.

## Eigene Entscheidungen von Claude

### Arbeitsweise (2026-10-21)

- **Lokales Gedächtnis aufgelöst:** Was dort stand, ist nach `docs/ki_dev.md` und hierher
  umgezogen. Danach hat Claude die Dateien im lokalen Memory-Verzeichnis gelöscht.


### Feature 002, Phase 11 (2026-10-21)

Auslegungen des Agents, die Claude angenommen hat. Sie stehen auch in Vertrag, Datenmodell und
Lernnotizen.
- **Statistik und Einträge ohne Tag (R1):** Die Statistik ordnet das ganze Eingriffsprotokoll,
  bevor sie aussucht. Ein Eintrag ohne lesbaren Tag gilt so wie im Simulator hinter seinem
  Vorgänger, auch wenn das eine Absage ist.
- **Tooltips (R2):** „Neu starten mit Eingriffen“ und „Probe speichern …“ sind zweizeilig statt
  rund 120 Zeichen in einer Zeile.
- **Meldungen (R3):** Ganze Zahlen stehen ohne „.0“ da, etwa „die Zahl 5“.
- **Klick in den Zeitstrahl (T077):** „Erst treffen, dann übernehmen“ gilt auch beim Linksklick.
  Gezogen wird nur, wenn an der Stelle nach dem Übernehmen noch dasselbe Ereignis steht.
- **Sicherungskopie (T078):**
  - Gleich behandelt werden `res://`, absolute und relative Pfade derselben Datei, nicht aber
    Verknüpfungen und Groß- und Kleinschreibung.
  - Eine fremde oder unlesbare Datei unter dem eigenen Namen wird nicht angeboten, und die nächste
    Sicherung ersetzt sie.
  - Der Hinweis bei einem Schreibfehler kommt einmal je Fehlerserie.
  - Eine alte Datei `user://werkstatt_sicherung.json` wird nicht übernommen; bei Klaus gibt es
    keine.
- **Fehlerkontur (T081):** auch an der Beschreibung (`ErrorTextEdit`), nicht am Knopf „+“ der
  Bedingungen, denn er ist kein Feld.
- **Abgelehnte Eingriffe (T082):** Die Warnung erscheint, sobald ein Spiel fertig ist. Absagen und
  Verschiebungen gelten weder als gezählt noch als abgelehnt, weil die Statistik sie nie anwendet.
- **Mehr als 20 Anzahlen (T086):** Das Formular zeigt die ersten 20 Gewichte, die Summe über alle
  und bei „bis“ den echten Wert.
- **Einstufung in T092:** Die fehlende Fehlerkontur an Feldern in Dialogen und die abgeschnittene
  Fokuslinie stehen als CRITICAL in Phase 12. Grundsatz IV der Verfassung verlangt, dass alles
  Sichtbare dem Style-Guide folgt, und `/speckit-converge` stuft jeden Verstoß dagegen als
  CRITICAL ein. Zu sehen ist beides nur als Kleinigkeit am Rand.

### Feature 002, Phase 12 (2026-10-21)

- **Tag 00 als V22 (T098):** Der Agent fragte, ob „05-00“ wie „00-00“ eine Meldung bekommt. Claude
  hat entschieden: ja, das Format kennt nur „MM-TT“, „MM-ende“ und „“, und 00 ist kein Tag.
- Auslegungen des Agents, die Claude angenommen hat:
  - **Kontur bei Ablehnung (T093):** Lehnt der Lauf einen Eingriff ab, bekommt das Feld die
    Kontur, das der Grund meint, etwa der Tag einer Einplanung. Gilt der Grund dem Termin selbst,
    etwa bei Windows 95, bekommt kein Feld eine Kontur.
  - **Reihenfolge im Verlauf (T095):** Beim Menü „…“ steht das Ziel im Verlauf vor dem Titel; Cmd+Z
    nimmt also zuerst den Titel zurück. Eine ungültige Eingabe in einem Ereignis, das Klaus gerade
    verlässt, fällt wie bisher ohne Hinweis weg.
  - **Begründung (T097):** Bei entfallenen und abgesagten Terminen sagt sie weiter „Verzögerte
    Wirkungen: entfallen mit dem Termin“.
  - **Monat 13 bis 99 (T098):** jetzt V22 statt V09; „13-ende“ fällt auf „ohne Dauer“ zurück,
    statt erhalten zu bleiben.
  - **Prüfung der Probe (T099):** Wert und Beginn eines Modifikators werden vor Ereignis, Kennung
    und Grund geprüft. Auch ein negativer Seed ist ein Lesefehler.
  - **Mindesthöhe (T101):** Die 80 px, die T091 jedem Bereich zusichert, bleiben.

### Feature 003, Klärung der Spec (2026-10-21)

- **Chance je Zeitabschnitt (FR-015):** Gilt ein Start-Modifikator nur für einen Teil des Spiels,
  nennt die Anzeige im Ereignisformular die Chance je Abschnitt, etwa „Schwer 3 % bis 31.12.1994,
  6 % ab 01.01.1995“. Das folgt aus zwei Antworten von Klaus, Zeitraum und Anzeige nur zum Lesen;
  die Form hat Claude gewählt.

### Feature 003, Plan (2026-10-21)

Festlegungen, die nicht aus den Dokumenten folgten. Einzelheiten und verworfene Alternativen
stehen in `specs/003-schwierigkeitsgrade/research.md`.
- **Aufbau des Abschnitts (R2):** Die Katalogdatei hat den Abschnitt `"profiles"` mit `"leicht"`
  und `"schwer"`. Ein Start-Modifikator hat dieselben Schlüssel wie ein Modifikator in einer
  Probe. Die Listen behalten ihre Reihenfolge und werden nicht sortiert.
- **Formatnummer (R3):** Sie bleibt 1, Dateien aus Feature 002 laden weiter.
- **Profil für Mittel oder einen unbekannten Grad (R4):** ein Strukturfehler V22, wie jeder
  unbekannte Schlüssel.
- **Kennungen (R5):** Start-Modifikatoren und Eingriffe stehen im Lauf in zwei Listen, die
  Kennungen sind je Liste eindeutig. Eine Vorsilbe in der Kennung braucht es nicht.
- **V30 (R8):** Die Regel prüft auch eine leere Kennung und falsche Zeichen, über FR-012 hinaus.
- **Ganze Profile im Verlauf (R10):** Jede Änderung an einem Start-Modifikator ersetzt in der
  Werkstatt das ganze Profil durch eine Kopie. So stimmt Rückgängig auch, wenn ein Löschen zwei
  Start-Modifikatoren eines Profils mitnimmt.

### Feature 003, Analyse (2026-10-22)

Klaus hat alle 41 Befunde nach Empfehlung freigegeben. Zwei hat Claude beim Einarbeiten anders
gelöst als im Bericht vorgeschlagen, mit demselben Ziel; bei sechs weiteren ließ der Bericht
Einzelheiten offen, die Claude festgelegt hat. Alles steht in
`specs/003-schwierigkeitsgrade/plan.md`, „Änderungen nach der Analyse“, und an den genannten
Stellen.
- **Anders gelöst:**
  - **Text eines Profils (U1, R10):** `DifficultyProfile.to_dict()` statt
    `JSON.stringify(to_list())` als Sonderfall. `_text_of()` ruft es wie bei Ereignissen und
    Kategorien.
  - **FilterBar im Simulator (G10, R13):** Sie bricht nicht um und wird nicht breiter als bisher;
    `%CompareLabel` kürzt mit „…“ und zeigt den Text beim Überfahren ganz. Gilt bis Phase 4;
    seither bricht sie in der kleinen Größe um (siehe „Feature 003, Phase 4, Oberfläche“).
- **Festgelegt, wo der Bericht offen ließ:**
  - **Kein Vergleichslauf (A3, R13):** „Kein Vergleich: Der Lauf hat keine Eingriffe.“ Bei
    Mittel mit Häkchen gelten die Texte von Feature 002.
  - **„Neu“ ohne gewähltes Ereignis (A4, FR-015):** das erste Ereignis über Wahrscheinlichkeit
    nach Kennung.
  - **V31 (U7, R8):** Beginn und Ende werden einzeln geprüft. Liegt im Zeitraum kein
    Monatserster, gibt es nur eine Warnung an `from_day`, „wirkt nie“; gilt V27 oder V28, prüft
    V31 nicht.
  - **Felder (U4, R8):** Ein unbekannter Grad hat das Feld `profiles.<schlüssel>`. Die Prüfung
    zeigt „Profil Leicht“ und „Profil Schwer“ nur bei genau diesen Pfadteilen, sonst „Profile“.
  - **Start-Modifikatoren im Simulator (U10, R13):** ohne eigene Farbe, denn gedämpfter Text hält
    auf Zebra und Auswahl den Kontrast nicht.
  - **Weggelassene Start-Modifikatoren nennen (G1, R8):** `by_event` kennzeichnet die, die ohne
    eigene Meldung nur wegen ihres Ereignisses wegfallen. Zeitleiste und Textausgabe nennen aus
    der Hilfe nur diese, so steht keiner doppelt da. Die Textausgabe hängt an Meldungen zu
    Start-Modifikatoren „Der Start-Modifikator fehlt in der Ausgabe.“

### Feature 003, Phase 1 (2026-10-22)

Auslegungen des Agents, die Claude angenommen hat. Sie stehen auch im Datenmodell, „Prüfregeln“.
- **Texte von V25 bis V30:** vom Agent formuliert, etwa „Das Ereignis „x“ gibt es im Katalog
  nicht.“ (V25); vorgegeben waren nur V29 und V31.
- **Ort der Meldungen zum Abschnitt:** „Katalog“, wie bei den übrigen Schlüsseln der obersten
  Ebene; ist ein Profil keine Liste, das Profil selbst.
- **V26 bei doppelter Kennung:** Es meldet, sobald eines der Ereignisse mit dieser Kennung nicht
  über Wahrscheinlichkeit kommt, wie V16.
- **`catalog_alle_arten.json`:** Leicht −2 gilt das ganze Spiel, Schwer +5 nur 1990 bis 1994, damit
  die Rundreise auch andere Daten abdeckt.
- **Datum lesen:** `ChanceModifier._read_day()` wiederholt die zehn Zeilen von
  `TimelineEvent._read_day()`, damit Phase 1 `TimelineEvent` nicht anfasst.
- **Fund für Phase 2:** `catalog_issue.gd` nennt in Kommentaren noch „V01 bis V24“; der Agent zieht
  das in Phase 2 mit nach. Erledigt in Phase 2.

### Feature 003, Phase 2 (2026-10-23)

Auslegungen des Agents, die Claude angenommen hat:
- **Doppelte Kennung im Profil beim Spielstart:** Alle Start-Modifikatoren mit dieser Kennung
  fallen durch, nicht nur der zweite, wie V30 jeden meldet. Sonst hinge es an der Reihenfolge,
  welcher gilt.
- **Texte, die der Vertrag offenließ,** etwa in der Textausgabe „Den Schwierigkeitsgrad „extrem“
  gibt es nicht; erlaubt sind leicht, mittel und schwer.“ und im Lauf „Der Start-Modifikator
  braucht einen Grund.“
- **Zusatz „Das Ereignis fehlt in der Ausgabe.“** nur an Meldungen mit einer Ereigniskennung, auch
  in der Textausgabe, wie U5 es für die Zeitleiste verlangt. Eine Meldung V01 zu einer leeren
  Kennung steht damit ohne Zusatz da.
- **Neuer Test `test_fahrplan_ausgabe.gd`:** Die Fehlerprobe zeigte, dass kein Test die
  Textausgabe selbst prüfte. Er startet Godot als eigenen Prozess und kostet rund 6 Sekunden.
- **Textausgabe und `start_refusals`:** Sie gibt die Liste nicht aus; nach `without_faulty()` und
  der Prüfung des Grads ist sie dort immer leer.

### Feature 003, Phase 3, Teil 1 (2026-10-23)

Auslegungen des Agents, die Claude angenommen hat:
- **Ungültige Aufrufe:** Duplizieren, Löschen und Felder setzen mit Mittel oder einer Stelle, die es
  nicht gibt, melden es mit `push_error()` und tun nichts, wie bei einer unbekannten
  Ereigniskennung. `add_start_modifier()` gibt dann still null, wie der Vertrag sagt.
- **Namen im Verlauf:** etwa „Wert von Schwer: reklamationswelle“, „Start-Modifikator Schwer:
  reklamationswelle duplizieren“; ohne Kennung „Schwer: Nr. 3“.
- **Kennung beim Duplizieren:** wie bei Ereignissen mit Anhang, also `reklamationswelle_2` und
  davon `reklamationswelle_2_2`.
- **Löschdialog ohne Grund:** Fehlt der Grund, nennt er die Kennung, sonst „Schwer: Nr. 3“.
- **Werte mit mehr als vier Nachkommastellen** werden bei der nächsten Änderung im selben Profil
  gerundet; geschrieben wird ohnehin gerundet.
- **Regelverstoß, behoben:** Für eine kurze Probe lag einige Sekunden eine Datei
  `src/zz_probe_kanon.gd` im Repo; sie ist gelöscht, `git status` zeigt nur die drei Dateien von
  T014.

### Feature 003, Phase 3, Teil 2 (2026-10-23)

- **Höhe bei 1280 × 720 (Claudes Entscheidung):** Mit einem langen Hinweis V31 bricht er in der
  schmalen Feldspalte auf sechs Zeilen um, und die Werkstatt wird 23 px höher als ihr Fenster. Ohne
  Hinweis passt alles, bei 1920 × 925 sowieso, und der Simulator ist in dieser Größe schon vorher
  98 px zu hoch. Claude lässt es so; ein ScrollContainer um `%Fields` wiche vom Vertrag ab.
- Auslegungen des Agents, die Claude angenommen hat:
  - Bei 1280 × 720 rollt die Tabelle waagerecht, statt Spalten zu quetschen, wie im Simulator.
  - Nach „Löschen“ ist keine Zeile gewählt.
  - Ein Start-Modifikator ohne Ereignis heißt in Tabelle und Auswahl „– kein Ereignis –“.
  - Die Auswahl „Ereignis“ zeigt nur Titel; die Kennung steht im Hinweis des Eintrags.
  - Nach „Neu“ ist der Wert „+0“ markiert, damit Klaus gleich die Zahl tippt.
  - Zusätzliche Hinweise beim Überfahren an „Duplizieren“, „Löschen“, Wert und Kennung.
  - Die linke Seite des Teilers heißt `TableBox`; der Pfad `…/Tabs/DifficultyPanel/Split` stimmt.

### Feature 003, Phase 4, Kern (2026-10-23)

Auslegungen des Agents, die Claude angenommen hat:
- **`write_file()` lehnt einen unbekannten Grad ab,** etwa 7, mit `ERR_INVALID_PARAMETER`, wie eine
  ungültige Kennung. Sonst entstünde `"difficulty": ""`, eine Datei, die `read_file()` nicht liest.
- **Meldung bei einem Wert, der kein Text ist:** `"difficulty": 1` ergibt „… nennt den
  Schwierigkeitsgrad 1, den es nicht gibt.“; ein Text steht in „…“.
- **Erst das Format, dann der Grad:** Eine Datei mit `"format": 2` meldet das Format.
- **Übergang bis T025:** Bis der Simulator den Grad kennt, speichert er Proben immer als Mittel.

### Feature 003, Phase 4, Oberfläche (2026-10-23)

- **FilterBar als `HFlowContainer` (Claudes Entscheidung, angenommen vom Agent):** Kürzen des
  Texts allein reichte nicht, das Häkchen braucht 176 px. In 1280 × 720 bricht die Leiste jetzt in
  zwei Zeilen um, statt aus dem Fenster zu ragen; bei 1920 × 925 bleibt sie einzeilig. Steht im
  Vertrag.
- **Entschieden von Klaus (T027, 2026-10-23): stört nicht.** Mit Schwer wird die Zeile zur Chance
  bei 1920 × 925 vier statt zwei Zeilen hoch; der Simulator wächst um 46 px, die dem Zeitstrahl
  fehlen. Mit Mittel bleibt alles.
- Auslegungen des Agents, die Claude angenommen hat:
  - `%ExcludedNotice` nennt weggelassene Start-Modifikatoren aller Profile, mit dem Grad im Ort.
  - „Katalog geändert“ merkt auch, wenn nur eine Lesemeldung zu einem Profil verschwindet.
  - Spalten der Proben: Name, Seed, Grad, Stand, Eingriffe.
  - Derselbe Grad noch einmal gewählt baut nicht neu.

### Feature 003, Phase 5, Kern (2026-10-23)

Auslegungen des Agents, die Claude angenommen hat:
- **Grade nacheinander:** Ein Seed läuft erst ganz in Leicht, dann in Mittel, dann in Schwer. Weil
  die Würfel nur an Seed, Zweck und Kennung hängen, ändert das kein Ergebnis.
- **Doppelte oder unbekannte Grade in der Liste** filtert die Statistik nicht; das Panel gibt nur
  gültige weiter (FR-011).
- **Grund einer Ablehnung:** Er kommt aus dem ersten Grad. R15 ist dazu präzisiert.
- **Laufzeit der Tests:** Die Suite braucht jetzt rund 46 statt 31 Sekunden, weil SC-003 drei Grade
  mit je 1.000 Spielen rechnet.

### Feature 003, Phase 5, Oberfläche (2026-10-25)

- **„Katalog geändert“ in der Statistik (Claudes Entscheidung):** Sie nimmt wie der Simulator die
  Stellen weggelassener Start-Modifikatoren in den Schlüssel auf, damit beide Werkzeuge im selben
  Moment „Katalog geändert“ zeigen. Der Vertrag sagte „wie bisher“.
- Auslegungen des Agents, die Claude angenommen hat:
  - Der Text während der Rechnung nennt den Grad, etwa „Rechnet 1.000 Spiele je Grad …“.
  - Während einer Rechnung ist die Auswahl des Grads gesperrt, wie Anzahl und Häkchen.
  - Beim Vergleich hat jede Zelle einen eigenen Hinweis, nicht nur jede Spalte.
  - Ob die Tabelle vergleicht, entscheidet die Rechnung, die dasteht, nicht die Auswahl.
  - In 1280 × 720 rollt die Vergleichstabelle waagerecht.
- **Bilder:** Am Rechner hing beim Fotografieren nur der eingebaute Bildschirm; die Bilder
  entstanden bei Faktor 1 in 1920 × 924. Die Breiten sind dieselben wie bei Faktor 2; die Schrift
  prüft Klaus in T031 am großen Monitor.

### Feature 003, Lückensuche (2026-10-26)

15 Befunde aus T033, alle von Claude am Code bestätigt. Vier gehen als T036 bis T039 an den Agent
(tasks.md, Phase 7). Den Rest hat Claude in der Doku nachgezogen oder hier eingetragen:
- **Weggelassene Start-Modifikatoren nennen (K1):** Jede Meldung steht einmal da; ein
  Start-Modifikator mit zwei Fehlern also zweimal, wie ein Ereignis. Datenmodell und R8 sind
  präzisiert.
- **`start_modifiers` im Lauf (K2, Claudes Entscheidung):** unveränderlich per Vereinbarung, wie
  `modifiers` aus Feature 002; kein Schreibschutz im Code.
- **Doppelte V31-Hinweise im Reiter (W2):** Klaus, 2026-10-26: so lassen, wie beim Simulator. Mit
  Beginn und Ende mitten im Monat wird der Reiter bei 1920 × 925 um 47 px höher, der Zeitstrahl
  entsprechend kleiner.
- Zusätze der Agents, die Claude angenommen hat:
  - `select_difficulty()` im Simulator übergeht einen unbekannten Grad still (S4).
  - Zeilen mit Start-Modifikatoren im Simulator haben einen Hinweis „Start-Modifikator von
    Schwer: … · Kennung …“ (S4).
  - „Je Grad“ setzt vor „%“ ein geschütztes Leerzeichen, damit Zahl und Zeichen nicht getrennt
    umbrechen (W4).
  - Im Reiter: Hinweise an der Gradauswahl, an „Neu“ und an den Zellen Ereignis, Grund und
    Kennung; Platzhalter „TT.MM.JJJJ“ auch an „Beginn“ (W5).
  - Ein Start-Modifikator ohne Kennung bekommt beim Duplizieren eine Kennung aus seinem Ereignis,
    ersatzweise `start_modifikator` (W5).
  - Ein Feld, das mit `profiles[` beginnt, gilt als Profilfeld (W5).
  - Der Test `test_im_kleinen_fenster_passt_jeder_reiter_in_die_breite` (W5).
- Auslegungen des Agents in Phase 7, die Claude angenommen hat:
  - **T036:** Nach dem Übernehmen einer Sicherungskopie gelten die Lesemeldungen beider Profile
    nicht mehr, ohne Vergleich des Inhalts; das Profil kommt dann aus der Kopie.
  - **T037:** Der Löschdialog zählt die Kennung selbst (`_has_twin()`), dieselbe Regel wie
    `delete_event()`; ein Test hält beide zusammen. „zweiten Ereignis“ gilt auch bei dreien.

### Feature 003, Quickstart automatisiert (2026-10-26)

- **Automatischer Durchlauf statt Prüfung von Hand (Klaus, 2026-10-26):** Klaus bat, T034
  automatisiert durchzutesten, weil die Tabellen für ihn schwer nachzuvollziehen sind. Zwei Agents
  haben beide Quickstarts Zeile für Zeile Tests zugeordnet oder im echten Fenster nachgespielt.
  Feature 003: 61 von 64 Zeilen bestanden, Rest von Hand oder entfällt. Feature 002: 92 von 98
  bestanden, drei nicht.
- **Drei Funde, Klaus, 2026-10-26: alle vor der Abnahme beheben** (tasks.md, Phase 8): Tab bleibt
  in der Beschreibung hängen (T094); Cmd+Q wirkt nicht bei offenem Dialog zur Sicherungskopie
  (T096); unter 1440 × 900 ist der Simulator höher als das Fenster. Im kleinen Fenster darf der
  Reiter rollen, bei 1920 × 925 bleibt alles, wie es ist.
- **Umsetzung in Phase 8, Auslegungen des Agents, die Claude angenommen hat:**
  - Für Cmd+Q bei offenem Dialog sind die Dialoge nicht mehr `exclusive`, und die Werkstatt sperrt
    selbst. Das gilt für alle 15 Dialoge: Der offene Dialog geht zu wie mit „Abbrechen“, dann läuft
    das Schließen weiter. Bei „Trotzdem speichern“ und der fremden Änderung entfällt das Speichern.
  - Neu ist: Nach einem Klick neben einen Dialog hat der Dialog sofort wieder den Fokus.
  - Im rollenden Reiter folgt die Ansicht der Tab-Taste nicht; `follow_focus` ließe beim Klick in
    eine hohe Tabelle die Ansicht springen.
  - Bei 1024 × 600 ist die Werkstatt zu breit; gemessen nur zur Information, nicht Teil von T043.

### Feature 004, Plan (2026-10-26)

Festlegungen in `specs/004-neues-spiel/research.md`, die nicht aus Spec und Klärung folgen. Noch
nicht umgesetzt; Klaus kann sie bei jeder Abnahme ändern. Die übrigen hat Klaus mit der Checkliste
und mit dem Style-Guide (T002) bestätigt (unter „Erledigt“).
- **Zurück aus einem Blatt** wählt im Hauptmenü den Eintrag, der es geöffnet hat
  (`data-model.md`).

### Feature 004, Phase 2 (2026-10-26)

- **Katalog mit falschem Format im Spielstand ist beschädigt:** `EventCatalog.from_data()` fällt
  bei `"format": "zwei"` wie `from_json()` auf 1 zurück und meldet nur V22. Ein Spielstand wird
  aber nur vom Spiel geschrieben; steht dort etwas anderes als die ganze Zahl 1, ist die Datei
  verändert. `SaveGame.from_data()` prüft das deshalb vorher und meldet den Spielstand als
  beschädigt. Anlass: Bericht des Agents zu T005.
- **`replay()` gibt den Eintrag selbst zurück, keine Kopie** (Auslegung des Agents zu T004,
  angenommen): So sieht die Probe genau ihren eigenen Eintrag; ein Test prüft es.
- **Auslegungen des Agents zu T006 bis T009, von Claude angenommen:**
  - `SaveGame.from_data()` hat einen vierten, freiwilligen Parameter `details` für das Protokoll,
    damit der Satz für den Spieler nie einen Wert aus der Datei enthält.
  - Scheitert Schritt 5 (die `.alt` löschen), gibt `write()` OK zurück und meldet nur
    `push_warning()`: Der neue Stand ist zu diesem Zeitpunkt schon gespeichert.
  - Ein Ordner mit dem Namen einer Spielstandsdatei zählt für die nächste Nummer mit, erscheint
    aber nie in der Liste.
  - Zeitpunkte werden streng als `JJJJ-MM-TTTHH:MM:SSZ` gelesen; ein Name nur aus Leerzeichen zählt
    wie ein leerer.
  - Der Test zu SC-003 im Kern nimmt den Katalog, wie er gelesen ist; Prüfen und Weglassen beim
    Fortsetzen kommt mit T013. Das Fortsetzen vom 31.12.1999 in höchstens 1 s misst T014.
  - SC-002 gemessen: 20 Spielstände mit je 500 Ereignissen in rund 0,6 s gelesen.

### Feature 004, Phase 3 (2026-10-26)

- **Eingriff nach dem Spieldatum macht den Spielstand beschädigt:** Ein Eingriff mit `at_day`
  nach dem gespeicherten Tag schöbe den Lauf beim Fortsetzen über diesen Tag hinaus, und die Tage
  dazwischen kämen nie als Signal. Das Spiel schreibt so etwas nie; steht es in der Datei, ist sie
  verändert. `SaveGame.from_data()` meldet deshalb „Ein Teil der Datei stimmt nicht“. Anlass:
  Frage des Agents zu T013; umgesetzt mit T014.
- **Auslegungen des Agents zu T014, angenommen:**
  - Das zweite Schließen nach gescheitertem Speichern beendet immer ohne Speichern, auch wenn
    dazwischen ein Speichern gelang.
  - Ein neues Spiel weicht höchstens fünfmal auf die nächste Nummer aus.
  - Ein Eingriff, den das Fortsetzen ablehnt, fehlt nach dem nächsten Speichern in der Datei; am
    Fahrplan ändert das nichts, weil er ohnehin nicht galt.
  - Ein Test hakt Godots englische Fehlermeldung „Method/function failed“ ab; sie kann sich mit
    einer anderen Godot-Version ändern.
- **Auslegungen des Agents zu T012 und T013, angenommen:** `resume_game()` lehnt einen negativen
  Seed ab, statt zu würfeln; ohne Katalog läuft das Spiel wie mit einem leeren; `set_date()` setzt
  auch den Rest des angefangenen Tags zurück.

### Feature 004, Phase 4 (2026-10-26)

- **Auslegungen des Agents zu T017 bis T019, angenommen:** Die Fokuslinie am Knopf liegt wie in
  `bundle.css` einen Pixel neben dem Knopf (ein Pixel Luft, dann die Linie). Relief ein Pixel
  innerhalb der Kontur, Innenabstand 9 links und rechts, 2 oben und unten, gedrückt 3 und 1.
  `TitleTexts` hält auch Kopfzeilen und Einträge; die Namen der Grade kommen aus
  `Difficulty.label()`.
- **Ausgeschalteter Knopf zeigt den Pfeil:** Der Vertrag sagte „immer die Hand“, der Style-Guide
  „keine Reaktion beim Überfahren“. Der Style-Guide gilt; umgesetzt mit T021.
- **Lücke im Style-Guide:** Der `pixelschatten` des Hinweises ist `tusche` und auf `nacht` (dem
  Spielbildschirm) kaum zu sehen. Für den Stil-Prüfer in T023.

### Feature 004, Phase 5 (2026-10-26)

- **Auslegungen des Agents zu T025, angenommen:** Hinter dem Namen bleiben wie hinter der letzten
  Spalte 6 Pixel Luft, die Namensspalte ist also 58 breit; „Spiel 10000“ wird zu „Spiel 10…“. Das
  Mausrad rollt nur das Fenster; rollt der gewählte Spielstand hinaus, rückt die Auswahl auf die
  nächste sichtbare Zeile. Bei nicht fortsetzbaren Zeilen bleibt „zuletzt gespielt“ leer. Die
  Liste schaltet den Löschmodus bei „Löschen …“ selbst ein, aus nie selbst.
- **Löschen einer Datei, die schon weg ist:** Endet `SaveStore.delete()` mit
  `ERR_FILE_NOT_FOUND`, etwa weil ein zweites Fenster sie gelöscht hat, ist der Wunsch des Spielers
  erfüllt. Keine Meldung, die Liste wird neu gelesen. „Löschen ging nicht. Der Spielstand ist
  noch da.“ kommt nur, wenn der Spielstand danach wirklich noch da ist. Anlass: Text-Prüfer in
  Phase 4.
- **Auslegungen des Agents zu T026 bis T028, angenommen:** Ist der Ordner beim Öffnen von
  „Spiel laden“ inzwischen leer, bleibt das Hauptmenü, neu gelesen und auf „Spiel laden“; dessen
  Hinweis sagt dann, dass es keine gibt. „Abbrechen“ in der Rückfrage liest den Ordner nicht neu.
  Scheitert das Fortsetzen eines fortsetzbaren Spielstands doch, liest die Liste neu, ohne Meldung
  (kommt nicht vor, nur abgesichert).
- **„Spiel 10000 löschen“ passt nicht in die Rückfrage:** 109 Pixel bei 108 Platz. Liegt außerhalb
  dessen, was die Spec abdeckt (bis „Spiel 9999“); kein Handlungsbedarf, solange niemand 10 000
  Spiele anlegt.

### KI-Workflow, Schritte 1 und 2 (2026-10-22)

- **Phasenprüfung als Punkt 8:** In `docs/ki_workflow/ki_dev.md`, „Ablauf je Feature“, steht sie
  am Ende statt zwischen Punkt 4 und 5. So bleiben die Nummern, auf die Specs und Aufträge
  verweisen, etwa „Punkt 6“ für die Lückensuche.
- **Musterbericht nachgeschärft:** Drei ausgedachte Befunde widersprachen dem Style-Guide. 2 px
  Abstand ist erlaubt (`raster-2`), jetzt sind es 3 px; Preise stehen als „499,00 DM“; „googeln“
  gab es bis 1999 nicht, auch nicht ab 1998.

### Feature 008, Plan (2026-10-28)

Alle in `specs/008-architektur/research.md`; Klaus kann sie bei Checkliste oder Abnahme ändern:
- **R1** Leitfaden als eine Datei `docs/architektur-leitfaden.md`, Regeln mit festen Nummern `AR-NN`.
- **R2** Klaus entscheidet die Regeln in einer Durchsicht des Entwurfs; einzeln gefragt wird nur bei
  echten Alternativen.
- **R3** Begründete Ausnahme = Kommentar `# Ausnahme AR-NN: …` an der Stelle und Zeile im Leitfaden.
- **R4** Prüfer als Subagent mit `Read, Grep, Glob`, `model: inherit`, Aufträge Phase, Plan, Bestand.
- **R5** Bestandsprüfung in drei Läufen: Kern, Spiel und Oberfläche, Werkstatt.
- **R6/R7** `test_architektur.gd` mit drei Prüfungen, gebaut nach der Bestandsprüfung.
- **R8** Fehlerprobe des Prüfers unter `specs/008-architektur/fehlerprobe/`.
- **R9** Behebung gemessen an Testzahl, Startprobe, Fahrplänen der Seeds 1, 4711, 99999 und einem
  Spielstand.
- **R11** Keine Planprüfung durch den Architektur-Prüfer für 008 selbst.
- **Bestandsprüfung (Phase 3):** Klaus hat am 2026-10-28 alle 17 Abweichungen und 19 Lücken wie
  empfohlen entschieden (`specs/008-architektur/bestandsbericht.md`): 13 Behebungen in Phase 5
  (T036a, T036b), eine Ausnahme (`werkstatt.gd`, AR-02), zwei Features (11-09, 11-10), zwei verworfen.
- **R12** Muster im Leitfaden: Beobachter, Komponente, Typ-Objekt, Befehl, Zustand, Spielschleife;
  Singleton nur als Warnung. Entschieden in Phase 1 (Klaus, 2026-10-28): Der Ereigniskatalog bleibt
  JSON als begründete Ausnahme zu AR-04; dazu kommen die Tests „kein globaler Zufall in Kernen“ und
  „Spiel kennt Werkzeuge nicht“, die Probe „speichern, laden, vergleichen“ entfällt. Alle 20 Regeln
  des Leitfadens hat Klaus wie vorgeschlagen übernommen.

## Erledigt

- **Nachzug der Arbeitsweise auf `main`** (Klaus, 2026-10-27): Prüfung ergab elf veraltete Stellen.
  Behoben: Phasenprüfung fest statt „in Einführung“, Tagebuch im Einstieg, Spec Kit 1.2.3 mit
  eigener Vorlage, Regel „Aufwand“ nach `ki_dev.md`, Godot-Agent liest die Spielbeschreibung.
  Beschlossen nach Empfehlung: die Aufgabe „Phasenprüfung“ in
  `.specify/templates/overrides/tasks-template.md`, nach jedem Spec-Kit-Update ein Diff über
  `overrides/` und die Verfassung; die Prüfer lesen bei `/speckit-checklist` schon den Vertrag;
  `CLAUDE.md` ohne die alten Feature-Docs; Verfassung 2.2.0 mit Grundsatz VI. Den Abschnitt
  „Grafik“ in `ki_dev.md` zieht der Merge von Feature 005 nach.
- **Abnahme des Skills `/dcl-phasenpruefung`** (Schritt 6 des KI-Workflows): erledigt mit dem
  Pilot in Feature 004, wo der Skill die Phasenprüfungen trug, etwa T010 und T015 (2026-10-26).
  Ausgetragen beim Nachzug der Arbeitsweise am 2026-10-27.
- **Spec Kit auf 1.2.3 gehoben:** Klaus, 2026-10-27, nach einer Probe in einem leeren Ordner.
  Geändert haben sich nur `setup-plan.sh` und `check-prerequisites.sh` (Schutz vor leerem
  `plan.md`) sowie Versionsnummern und Prüfsummen; gezielt eingespielt statt `specify init --force`,
  damit Verfassung und eigene Vorlagen unberührt bleiben. `specify` auf Klaus' Rechner ist 1.2.3.
- **Spec Kit ersetzt `/dcl-feature` dauerhaft:** Klaus, 2026-10-27, nach drei Features im Pilot.
  Aufgeräumt am 2026-10-27: alte Feature-Docs in `docs/features/archiv/`, `TEMPLATE_FEATURE.md`
  und der Skill `dcl-feature` entfernt, `CLAUDE.md` mit Klaus' OK angepasst.
- **Lochrand und Abstand am Knopf (Phasenprüfung Phase 4):** Klaus, 2026-10-26, nach Empfehlung:
  Ein Loch, das die Unterkante eines Blatts berühren würde, entfällt; beim allein stehenden Knopf
  zählen die 4 Pixel bis zum Hinweis ab der Fokuslinie. Steht im Style-Guide (Bildrahmen,
  Hinweis; Version 27).
- **Rückfrage mit dem Namen vorn (Phase 4):** Klaus, 2026-10-26, nach Empfehlung: „Spiel 2 bleibt:
  Schwer, 14.03.1986. Esc geht auch.“ und „Spiel 2 ist danach weg: Schwer, 14.03.1986. Für
  immer.“ Die alte Fassung brauchte mit „Spiel 9999“ drei Zeilen. Steht im Style-Guide (Menü,
  Version 26), research.md (R14) und im Vertrag.
- **Meldung beim Beenden (Phasenprüfung Phase 3):** Klaus, 2026-10-26: Scheitert beim Beenden
  das Speichern, zeigt das Spiel nur den Fehler, dieselbe Meldung wie sonst („Speichern ging nicht.
  Dein Spiel läuft weiter.“). Ein zweites Beenden endet ohne Speichern, ohne dass die Meldung das
  erklärt. Vorher stand dort „Schließt du noch einmal, dann ohne.“; Klaus: Ein Spiel zeigt da
  einfach den Fehler. Steht in Spec (Edge Cases), research.md (R8) und den Verträgen.
- **Gründe für beschädigte Spielstände (Phasenprüfung Phase 2):** Klaus, 2026-10-26, nach
  Empfehlung: nur Wörter, die der Spieler kennt. Vier Gründe statt acht; Seed, Formatversion,
  Eingriff und Ereigniskatalog stehen nur im Protokoll. Steht im Datenmodell, „Zustand“.
- **Uhrzeit in Spalten einer Liste ohne „Uhr“:** Klaus, 2026-10-26, nach Empfehlung; steht in
  „Sprache“, „Zahlen, Geld und Daten“ (Style-Guide, Version 24).
- **Style-Guide für Feature 004 (T001, T002):** Klaus, 2026-10-26, freigegeben: Version 22 mit
  „Blätter im Titel“ und „Rückfrage“ beim Menü, den Bausteinen Liste und Meldung, dem allein
  stehenden Knopf mit Hinweis und der Fokuslinie in `papier` auf dunklem Grund, dem Spielbildschirm
  als Platzhalter. Damit gelten auch die Lage der Blätter, die Spalten der Liste und der
  Spielbildschirm aus „Feature 004, Plan“ als bestätigt.
- **Analyse von Feature 004:** Klaus, 2026-10-26: alle 44 Befunde nach Empfehlung einarbeiten.
  Eingearbeitet in Spec (Clarifications „Analyse 2026-10-26“, Edge Case „Zwei Fenster“, FR-016),
  Plan („Änderungen nach der Analyse“), research.md, Datenmodell, Verträge, Quickstart und Tasks.
  Wo Claude anders gelöst hat als der Prüfer vorschlug: Spalten 0, 64, 108, 172 und Papier 304
  statt nur die 6 px Rest zu benennen (F9, B4), Rollmarken in Kopfzeile und „Löschen …“ statt in
  Zeilen der Spielstände, Werte im Vertrag als Verweis auf den Style-Guide statt als Zahl (D1).
- **Review-Checkliste von Feature 004:** Klaus, 2026-10-26: alle 36 Vorschläge freigegeben
  (`specs/004-neues-spiel/checklists/review.md`), eingearbeitet in Spec, Plan, research.md,
  Datenmodell, Verträge und Quickstart. Damit bestätigt sind auch diese Festlegungen des Plans, die
  jetzt in der Spec stehen: Ordnung und Rollen der Liste, „Löschen …“ im Löschmodus nicht
  verfügbar, die Sätze zu den Graden im Hinweis, „Abbrechen“ als Zurück der Rückfrage, Speichern
  beim Fortsetzen, Schließen bei gescheitertem Speichern, ein Eingriff mit falschem Datum macht den
  Spielstand beschädigt, Katalog beim Start der App gelesen.
- **Sätze zu den Graden (Feature 004, R18):** Klaus, 2026-10-26, nach Empfehlung Vorschlag A:
  Leicht „Das Glück ist eher auf deiner Seite.“, Mittel „Das Glück hält sich raus.“, Schwer „Das
  Glück ist eher auf der Seite der anderen.“ Steht in `specs/004-neues-spiel/research.md`, R18, und
  im Vertrag `titelbildschirm.md`; der Text-Prüfer prüft sie in Phase 4.
- **Fünf Festlegungen aus der Spec von Feature 004:** Klaus, 2026-10-26, alle bestätigt: Esc auf
  dem Spielbildschirm löst nichts aus (FR-020); „Spiel N“ mit N = größte Nummer + 1 (FR-009); der
  Löschmodus mit seinen Enden und „Abbrechen“ vorgewählt (FR-017, FR-017a); nur beschädigte
  Spielstände machen „Spiel laden“ verfügbar (FR-002); kein Speichern während des Spiels, solange
  die Uhr steht (Annahmen).
- **Eine Sitzung je Feature von specify an:** Klaus, 2026-10-26: Ein Feature läuft von
  `/speckit-specify` bis zur Gesamtabnahme in einer Sitzung; Claude bietet keine eigene Sitzung ab
  dem Plan mehr an. Steht in `docs/ki_workflow/ki_dev.md`, „Ablauf je Feature“, Punkt 7.
- **Merge von Feature 003 und KI-Workflow nach `main`:** Klaus, 2026-10-26, nach Empfehlung, vor
  dem Start von Feature 004: erst Feature 003 (`6e5ea67`), dann der Branch des KI-Workflows
  (`342e0d1`). So sind Prüfer und Skill im Pilot von Feature 004 dabei.
- **Feature 003 abgenommen:** Klaus, 2026-10-26 (T035). Alle Phasen 1 bis 8 sind abgenommen
  oder geprüft und committet; T034 lief automatisiert mit wenigen Handgriffen von Klaus. Über den
  Merge nach `main` entscheidet Klaus; diese Sitzung wechselt den Branch nicht.
- **Pilot und Merge des KI-Workflows** (Schritt 9): Klaus, 2026-10-22, nach Empfehlung: Der Pilot
  läuft im nächsten Feature nach 003, in der ersten Phase mit Sichtbarem oder Texten. Ab dem Pilot
  gelten die Prüfer, auch für Werkzeuge. Der Branch geht nach `main`, sobald Feature 003 dort ist.
- **Hook nach dem Godot-Agent** (Schritt 8 des KI-Workflows): Klaus, 2026-10-22, nach Empfehlung:
  vorerst keiner, Schritt 8 entfällt. Die Tests laufen beim Agent und danach zweimal bei Claude.
  Liefert der Agent zweimal rote Tests ab, ohne es zu melden, kommt ein Hook bei `SubagentStop`
  mit dem Matcher `godot-entwickler`. Steht in `docs/ki_workflow/ki_pruefung.md`.
- **Text-Leitfaden als Abschnitt „Sprache“ im Style-Guide** (Schritt 4 des KI-Workflows): Klaus,
  2026-10-22, nach Empfehlung. Den Ton hat er in vier Fragen entschieden, jeweils nach Empfehlung:
  trocken-ironisch wie „Das Amt“; kein Witz in der Bedienung; maßvoll aus der Zeit; das Spiel duzt
  den Spieler, Kunden, Bank und Ämter siezen den Ladenbesitzer wie damals üblich. Der Abschnitt
  steht im Style-Guide (Version 19), die drei Textregeln unter „Schrift“ verweisen jetzt dorthin.
- **KI-Workflow in eigenem Ordner:** Klaus, 2026-10-22: Konzept freigegeben, mit der Änderung an
  `CLAUDE.md` (Pfad `docs/ki_workflow/`). Umgesetzt in den Schritten 1 und 2: `ki_dev.md` ist
  umgezogen, dazu kommen der Einstieg `README.md` und `ki_pruefung.md` mit Schaubildern; die beiden
  Konzepte sind darin aufgegangen.
- **Analyse von Feature 003:** Klaus, 2026-10-22: alle 41 Befunde nach Empfehlung einarbeiten.
  Eingearbeitet in Spec, Plan, research.md, Datenmodell, Verträge, Quickstart, Checkliste und
  tasks.md, jetzt mit T001 bis T035. Zusammengefasst im Plan unter „Änderungen nach der Analyse“;
  Claudes eigene Festlegungen dabei stehen oben unter „Feature 003, Analyse“.
- **Eigene Festlegungen des Plans von Feature 003, bestätigt im Review:** Klaus hat am
  2026-10-22 die Vorschläge der Checkliste freigegeben und damit diese Festlegungen bestätigt:
  - der Reiter mit „Neu“ ohne Dialog und „Löschen“ ohne Rückfrage (R11, CHK016);
  - der Wechsel des Grads im Simulator, „so, wie er war“ (R13, CHK011, CHK029, CHK033);
  - der Stand im Simulator ohne Grad und die Texte der Markierungen (R13, CHK017);
  - die unlesbare Probe bei einem unbekannten Grad (R14, CHK031);
  - „Spanne“ und keine Verteilung beim Vergleich, der Grad im Ergebnistext (R15, CHK015,
    CHK017);
  - die Kopfzeile der Textausgabe mit Grad (R16, CHK017);
  - das einmalige Speichern des echten Katalogs in Phase 1 (R3, CHK037).

  Steht in `specs/003-schwierigkeitsgrade/checklists/review.md`.
- **Verfassung, Grundsatz V und die Profile (Feature 003):** Klaus, 2026-10-22, nach Empfehlung:
  so lassen. Die Ausnahme Ereigniskatalog gilt der Datei und ihrer Pflege in der Werkstatt, also
  auch den Profilen darin; die Verfassung bleibt bei 2.1.1. Steht in
  `specs/003-schwierigkeitsgrade/checklists/review.md`, CHK022.
- **Verweise beim Umbenennen (Feature 003, FR-017):** Klaus, 2026-10-21, im Plan:
  Start-Modifikatoren ziehen still mit wie Folgen und Bedingungen; genannt wird nur beim Löschen.
  Steht in der Spec und in `specs/003-schwierigkeitsgrade/research.md`, R9.
- **`CLAUDE.md` verweist auf `docs/ki_dev.md`** (Claudes Ergänzung nach Klaus' Satz „ki_dev ist in
  claude.md“): Klaus hat den Absatz „Arbeitsweise“ mit dem Merge von Feature 002 nach `main`
  freigegeben (2026-10-21).
- **Noch eine Lückensuche nach Phase 12?** Klaus, 2026-10-21: nein, weiter mit T072. Punkt 6 in
  `docs/ki_dev.md` bleibt, wie er ist; für Phase 12 gilt diese Ausnahme.
- **Phase 11 und 12 zusammen abnehmen** (Claudes Vorschlag): Klaus hat am 2026-10-21 beide mit
  T103 abgenommen; sie stehen in einem Commit.
- **Wirkungen abgesagter und entfallener Termine (T097):** Klaus, 2026-10-21: nicht zeigen, sie
  kommen nie. Umgesetzt in Phase 12.
- **Zwei Termine eines Ereignisses am selben Tag (T100):** Klaus, 2026-10-21: nichts bauen, die
  Grenze festhalten. Steht im Datenmodell unter „Neu abspielen“ und in R22.
- **Vorgabe-Teilung der Tabellen (T101):** Klaus, 2026-10-21: Die Tabelle bekommt Vorrang.
  Umgesetzt in Phase 12.

### Feature 006, Spec (2026-10-27)

- **Der Name „Space Invaders“ erscheint nicht im Spiel:** Er ist eine Marke. Das Easter Egg
  übernimmt nur die Spielidee, keine Grafik, keinen Ton und keinen Namen aus dem Original. Klaus
  kann das im Review kippen (`specs/006-easter-egg-space-invaders/spec.md`, Assumptions).
- **Regeln für Ton in den Style-Guide:** Klang, Tonhöhen und Lautstärke kommen als Abschnitt
  „Ton“ in den Style-Guide, damit es eine Quelle für alles gibt, was Look und Klang bestimmt.
- **Das Spiel hält an, solange das Fenster keinen Fokus hat** (FR-016), damit niemand eine Partie
  verliert, während er in einem anderen Fenster ist.

### Feature 006, Plan (2026-10-27)

Alle in `specs/006-easter-egg-space-invaders/research.md`; Klaus kann sie bei Checkliste oder Abnahme
ändern:
- **R1** Die Knöpfe sind Gehäusetasten des Communicators (`case_keys`, Signal), die Folge kennt nur
  der Titel (`KeySequence`).
- **R2/R3** Lage der Knöpfe aus G-03 gemessen; eingedrückt aus dem eigenen Bildausschnitt eine Zeile
  tiefer, ohne neues Bild.
- **R4** Gezählt wird beim Loslassen über derselben Taste, der Klick ertönt beim Drücken.
- **R5** Während das Spiel läuft, klicken die Knöpfe weiter, starten aber nichts.
- **R6** Spiel als Kern ohne Node mit festem Schritt 1/60 s und Seed, dazu eine Seite; unter
  `src/scenes/title/invaders/`.
- **R7** Maße und Tempi des Levels als Vorschlag; Klaus stellt sie in Phase 4 ein.
- **R8** Pixelmuster als Text-Daten, eigene Entwürfe statt Kopien des Originals.
- **R10** Wortlaute der Meldung (Vorschlag), Sperre von 0,5 s vor dem Weiter.
- **R11** Anhalten über die Fokus-Benachrichtigungen der App statt `get_tree().paused`.
- **R13/R14** WAV 22 050 Hz aus `tools/ton/make_sounds.py`; Kanäle `Master` und `Effekte` (−10 dB),
  kein Autoload für Ton.

### Feature 006, Phasenprüfung Phase 4 (2026-10-27)

Lücken im Style-Guide, von den Prüfern gemeldet und von Claude nachgeprüft. Klaus hat am 2026-10-27
alle nach Empfehlung entschieden; geschlossen im Style-Guide, Version 53 (Baustein Spiel auf der
Anzeige, Sprache):
- **Kopfzeile „oben bündig bei y 1“** (Stil): Gebaut ist der Zeilenkasten ab Oberflächenpixel 2 wie
  bei einem Label; die Versalien stehen dann in den Zeilen 5 bis 11, die Leben in 4 bis 11.
  Empfehlung: so lassen und im Baustein „Zeilenkasten ab y 1, wie ein Label“ schreiben.
- **„Waagrecht mittig“ bei Doto mit Laufweite** (Stil): Nachgemessen liegen die drei Zeilen der
  Ergebnisanzeige 1 bis 1,5 Oberflächenpixel links der Mitte, weil die Laufweite nach dem letzten
  Zeichen mitzählt und nach links gerundet wird. Empfehlung: „mittig auf 1 Oberflächenpixel genau,
  ein Rest fällt nach links“ in den Baustein.
- **Explosion an der Kanone, halber Pixel** (Stil): 8 breit über 9; gebaut bündig links
  (research.md, Auslegungen Phase 3). Empfehlung: so in den Baustein.
- **Satzzeichen in Versalzeilen** (Text): Empfehlung für „Sprache“: Ein Satz endet mit Punkt
  („ALLE ERWISCHT.“), eine Angabe nicht („640 PUNKTE“, „GAME OVER“, „HAUPTMENÜ“), eine Frage mit
  Fragezeichen („LÖSCHEN?“).
- **„Weiter mit …“ in zwei Bedeutungen** (Text): „Weiter mit Spiel 2 …“ im Hauptmenü und „Weiter mit
  Taste oder Klick.“ in der Ergebnisanzeige stehen auf verschiedenen Seiten nacheinander.
  Empfehlung: lassen; „Blatt“ in der Regel meint eine Seite.

### Feature 006, Phasenprüfung Phase 5 (2026-10-27)

Lücken vom Stil-Prüfer, von Claude nachgeprüft. Klaus hat am 2026-10-27 nach Empfehlung entschieden;
die Sätze stehen im Style-Guide, Version 54 (Baustein Communicator), der Code folgt in einer Aufgabe
für den Agent vor der Abnahme:
- **Fenster verliert den Fokus, während eine Gehäusetaste unten ist:** Heute schickt Godot dann ein
  Loslassen, und steht die Maus über der Taste, zählt der Druck. Empfehlung: wie beim Hinausfahren
  zurückspringen und nicht zählen; Satz im Baustein Communicator, `cancel()` bei
  `NOTIFICATION_APPLICATION_FOCUS_OUT` in `CaseKey`, ein Test. Aufwand: klein, eine Aufgabe für den
  Agent.
- **Kein Fokus und keine Tastatur an den Gehäusetasten:** gebaut so (`FOCUS_NONE`), im Style-Guide
  fehlt der Satz. Empfehlung: in die Ausnahmeliste im Baustein Communicator.
- **Meldung in der Probeszene für einen Tastendruck:** Die Probe zeigt „Gehäusetaste 3 gedrückt.“ als
  Meldung, obwohl die Meldung für Fehler ist; so macht es die Probe seit Feature 005. Empfehlung:
  lassen, Probeszenen sind kein Teil des Spiels.
- Verworfen: „Baustein Hinweis fehlt im Maßstab“; der Pfad im Auftrag war falsch, der Baustein
  steht im Style-Guide.

### Feature 006, Lückensuche (2026-10-28)

Lücken vom Stil- und Text-Prüfer über das ganze Feature (T036), von Claude nachgeprüft. Klaus hat am
2026-10-28 nach Empfehlung entschieden. Übernommen in den Style-Guide, Version 56 (T044): das Spiel
als Seite im Titel (Baustein Communicator, „Einsatz“; Baustein Menü, „Seiten im Titel“), die
Gehäusetasten auch in der Probeszene, „Name des Vorbilds“ nur für Sichtbares und Hörbares, Werkzeuge
und Probeszenen unter denselben Sprachregeln (Abschnitt Sprache, „Anrede“). Nicht übernommen:
- **„Taste“ in „Weiter mit Taste oder Klick.“, während Gehäusetasten zu sehen sind (Text L1):** Kein
  Verstoß; die Regel „kein Wort für zwei Dinge“ gilt für Wörter auf derselben Seite, und die
  Gehäusetasten stehen nirgends als Wort. „Knopf“ oder „Tastendruck“ passt nicht in die Zeile.
- **Ob die Ergebnisanzeige als Meldung oder Warnung zählt (Text L3):** Der Abschnitt „Texte im Spiel
  auf der Anzeige“ sagt schon „zählt als Meldung“; eine Warnung kommt im Spiel nicht vor. Ohne Folge
  für Text oder Code.
- **Satzform der Meldungen in der Probeszene (Text L4):** Probeszenen folgen jetzt denselben
  Sprachregeln; eine eigene Regel für ihre Satzform braucht es nicht. „Gehäusetaste 3 gedrückt.“
  bleibt, wie in Phase 5 entschieden.

### Feature 006, Nachprüfung Phase 7 (2026-10-28)

Lücken von Stil- und Text-Prüfer über das Geänderte, von Claude nachgeprüft. Klaus hat am 2026-10-28
nach Empfehlung entschieden; die Sätze stehen im Style-Guide, Version 57, der Code tut es schon so:
- **Meldung beim Start des Spiels:** Hinweis und Meldung sind verborgen; danach kommt der Hinweis der
  gewählten Zeile zurück, die Meldung nicht (Baustein Communicator, „Hinweis und Meldung“; Baustein
  Spiel, „Einsatz“).
- **Versionszeile während des Spiels:** bleibt stehen (Baustein Spiel, „Einsatz“).
- **Gehäusetasten beim Hereinfahren:** zählen schon, wie die Seiten (Baustein Communicator,
  „Gehäusetasten“).
- **Sprachregeln und Testausgaben:** Testausgaben im Code sind ausgenommen (Abschnitt Sprache,
  „Anrede“).
- Der Befund des Stil-Prüfers (Kommentar zum Fokusverlust in `invaders_page.gd` nannte eine
  Gehäusetaste als Ursache) ist behoben, ebenso in `research.md` R9 und `test_invaders_page.gd`.

### Feature 006, Spielbeschreibung (2026-10-28)

Beim Abgleich für `docs/spielbeschreibung/` (T039) fielen sieben kleine Abweichungen zwischen
Spec-Dokumenten und Code auf. Keine ändert das Verhalten; die Spielbeschreibung beschreibt den Code.
Empfehlung: so lassen, die Specs von 006 sind abgeschlossen.
- Eindrücken: gemalt über das Signal `draw` von `Keys` in `communicator.gd`, nicht in einem
  `Keys._draw()` (contracts/gehaeusetasten.md).
- Die Folge beginnt mit jedem Titel neu, statt dass der Titel beim Erscheinen `reset()` ruft (R5).
- Die 15 ms Tonlatenz sind Godots Vorgabe, keine Projekteinstellung (R13).
- Zwei Rückfallwege beim Rückweg (Hauptmenü, wenn keine Seite gemerkt ist; Zeile neu wählen, wenn
  das Control fehlt) stehen nicht in contracts/titelbildschirm.md.
- Die Explosion an der Kanone steht auch nach dem letzten Treffer, wie in R7 ausgelegt, nicht nur in
  `RESPAWN` (contracts/invaders.md).
- Ohne Fensterfokus prüft `_gui_input()` den Fokus nicht; es kommen dann keine Tasten an
  (data-model.md).
- `CaseKey` meldet beim Loslassen einer Taste, die nicht unten ist, kein `down_changed(false)`;
  im Ergebnis gleich (contracts/gehaeusetasten.md).
