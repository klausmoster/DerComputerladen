# Feature Specification: Build & Export mit Selbsttest

**Feature Branch**: `feature/007-build-export-selbsttest`

**System**: 11 Infrastruktur

**Created**: 2026-10-28

**Status**: Draft

**Input**: User description: "Feature 007 ‚Build & Export mit Selbsttest' (Backlog 11-03).
Grundlage: Eintrag 11-03 in docs/features/Feature_Ideas.md." Klaus hat 11-03 als nächstes Feature
nach 006 gewählt: „wir wollen erst das Konstrukt stehen haben“ (2026-10-28).

## Clarifications

### Specify 2026-10-28

Fragen aus `/speckit-specify`, von Klaus einzeln als Auswahl beantwortet:

- Q: Wohin schreibt der Selbsttest Protokoll und Fotos? → A: in den eigenen Datenordner der
  Selbsttest-App, je Lauf ein Unterordner nach Datum und Uhrzeit und ein Zip-Archiv; auf der
  Zusammenfassung öffnet „Ordner zeigen“ den Ordner im Finder, Explorer oder Dateimanager (Klaus,
  nach Empfehlung). Verworfen: ein Ordner auf dem Schreibtisch, weil der unter Windows oft in
  OneDrive liegt und manchen Linux-Rechnern fehlt; ein Ordner neben der App, weil macOS
  heruntergeladene Apps an einem schreibgeschützten Ort startet.
- Q: Was passiert ohne Forward+? (bis 2026-10-29; seit Feature 009 läuft das Spiel mit Compatibility, siehe `specs/009-renderer-compatibility/`) → A: Godot weicht nicht auf einen einfacheren Renderer aus. Fehlt
  Vulkan oder Direct3D 12, zeigt Godot seine eigene Fehlermeldung und beendet sich; Spiel und
  Selbsttest schreiben dann nichts (Klaus, gegen die Empfehlung). Verworfen: Ausweichen nur, um eine
  deutsche Meldung zu zeigen und dann zu beenden, mit Protokoll; Ausweichen und weiterlaufen, weil
  es Grundsatz I der Verfassung widerspricht.
- Q: Gehört die neue Regel zur Arbeitsweise zu diesem Feature? → A: ja, als Vorschlag: In der
  letzten Phase schlägt Claude den Wortlaut für `ki_dev.md`, die Vorlage für Tasks und die
  Phasenprüfung vor; Klaus entscheidet je Datei, die Verfassung nur über `/speckit-constitution`.
  So gilt die Regel ab Feature 008 (Klaus, nach Empfehlung). Verworfen: ein eigener Branch zur
  Arbeitsweise nach 007.

### Clarify 2026-10-28

Fragen aus `/speckit-clarify`, von Klaus einzeln als Auswahl beantwortet:

- Q: Welche Taste schaltet unter Windows und Linux das Vollbild? → A: F11 und Alt+Enter, beide hin
  und zurück; auf dem Mac bleibt Ctrl+Cmd+F (Klaus, nach Empfehlung). Verworfen: nur F11, weil
  Spieler unter Windows Alt+Enter gewohnt sind; nur Alt+Enter, weil es unter Linux weniger bekannt
  ist.
- Q: Soll der Selbsttest auch das Fenster prüfen? → A: ja, mit einem eigenen Ablauf „Fenster“ für
  Startfaktor, Zentrierung und ganzzahlige Skalierung, aber ohne Vollbild; das Vollbild prüft Klaus
  von Hand (Klaus, gegen die Empfehlung „mit Vollbild“). Verworfen: mit Vollbild, weil es auf dem Mac
  an einer Animation des Systems hängt; nur das Protokoll.
- Q: Wie kommen die Ergebnisse von Windows und Linux zu Claude, und was bleibt im Repo? → A: Klaus
  legt das Zip in den unversionierten Ordner `build/selbsttest/`; Claude entpackt, vergleicht und
  berichtet. Ins Repo kommen Protokoll und Vergleichsbericht als Beleg in den Spec-Ordner, Fotos nur
  bei Abweichungen; die Referenzbilder vom Mac sind versioniert (Klaus, nach Empfehlung). Verworfen:
  nichts im Repo, weil sich später nicht belegen lässt, was auf Windows lief; alle Fotos jedes Laufs,
  weil das Repo je Lauf um rund 40 Bilder wächst.
- Q: Wie sieht die Zusammenfassung am Ende aus? → A: eine schlichte Seite im Look der Werkzeuge
  aus dem Style-Guide, wie die Werkstatt: oben groß die Summe, darunter die fehlerhaften Schritte,
  der Pfad und die Knöpfe „Ordner zeigen“ und „Beenden“ (Klaus, nach Empfehlung). Verworfen: auf
  dem Communicator, weil die Anzeige nur wenige Zeilen fasst und ein Fehler am Communicator die
  Ergebnisse stören würde; Text ohne Gestaltung, weil er fremd aussieht.
- Klaus, nach der Klärung: Die Zusammenfassung muss so sein, dass ein auch für Claude verwertbares
  Protokoll herauskommt. Umgesetzt in FR-014 (feste Namen und Kennungen, Fehler mit Eingabe,
  Erwartetem, Gefundenem, Foto und Meldungen des Spiels, alles im Zip) und FR-014a (Zusammenfassung
  und Protokoll aus demselben Ergebnis).
- Q: Bekommt die Zusammenfassung einen Knopf „Kopieren“? → A: ja; er legt Summe, fehlerhafte
  Schritte und Systemdaten als Text in die Zwischenablage, für den schnellen Blick im Chat, bevor das
  Zip da ist (Klaus, nach Empfehlung). Verworfen: nur das Zip.

### Abgleich mit Klaus' Ablauf 2026-10-28

Nach dem Plan beschrieb Klaus den Ablauf, den er braucht: zur Validierung, etwa nach neuen Features,
die App für drei Systeme in einem eigenen Modus bauen; das Spiel darf dabei viel schneller laufen;
alle Features werden automatisch durchgespielt, gern auch länger, vielleicht mit leichteren
Szenarien; heraus kommt ein Zip mit Prüfberichten und Bildschirmfotos. Die Abweichungen hat Claude
einzeln als Auswahl gefragt:

- Q: Wie schnell läuft der Selbsttest? → A: im Zeitraffer, dazu der Ablauf `titel` einmal in
  normalem Tempo, damit Fehler, die nur bei echtem Tempo auftreten, nicht verdeckt werden; die
  Grenze von 2 Minuten entfällt (Klaus, nach Empfehlung). Verworfen: nur Zeitraffer; normales
  Tempo.
- Klaus dazu: Der Selbsttest muss nicht nach jeder Phase laufen. Der Entwicklungsprozess bleibt, wie
  er war; der Selbsttest gehört zur **Endabnahme** eines Features. Das ersetzt „Claude lässt ihn nach
  jeder Phase laufen“ aus Story 5. Innerhalb von 007 läuft er natürlich dort, wo er gebaut wird.
- Q: Gibt es einen Befehl, der für die Endabnahme alles baut? → A: ja: ein Skript baut für macOS,
  Windows und Linux je Spiel und Selbsttest, prüft, dass im Spiel kein Testcode steckt, und legt je
  System ein Zip zum Weitergeben ab (Klaus, nach Empfehlung). Verworfen: je Preset ein Befehl.
- Q: Was bringt 007 an Szenarien mit? → A: nur den Rahmen: was ein Szenario ist (eigener Ablauf,
  Spieluhr im Zeitraffer, feste Entscheidungen, Prüfpunkte mit Foto) und dass der Läufer es tragen
  kann; das erste echte Szenario bringt das erste Feature, in dem man im Spielbildschirm etwas
  bedienen kann (Klaus, nach Empfehlung). Verworfen: ein Probeszenario jetzt, weil der Selbsttest die
  Spieluhr dafür an der Oberfläche vorbei starten müsste; keine Szenarien in 007.

### Review 2026-10-28

Aus `checklists/review.md`, 39 Punkte, davon 24 aus der Prüfung des Vertrags durch Stil- und
Text-Prüfer; von Klaus am 2026-10-28 alle nach Vorschlag freigegeben. Die wichtigsten für die Spec:
- Ausnahmen von „alles über die Oberfläche“: Vorbereiten eines Ablaufs und die Fenstergröße
  (CHK001, FR-004).
- „Ordner zeigen“ zeigt das Zip des Laufs (CHK002, FR-016).
- Wann der Selbsttest auf Windows und Linux läuft, legt die Regel aus Phase 7 fest (CHK003).
- Feste Zeitzone (CHK004), nicht vergleichbare Fotos (CHK005), abhängige Abläufe (CHK006),
  Meldungen (CHK007), Export-Templates (CHK008).
- Messbar: sechs Fehler in der Fehlerprobe (CHK009), Unterschiede zweier Protokolle (CHK010),
  „ohne Störung“ (CHK011).
- Die Zusammenfassung maximiert das Fenster wie die Werkstatt (CHK016) und folgt in Aufbau,
  Schrift, Zeichen und Tasten dem Vertrag (CHK017 bis CHK028).
- Wortlaute und Formate wie im Vertrag (CHK029 bis CHK039); der Ablauf heißt „Spiel laden“.

### Analyse 2026-10-28

Aus `/speckit-analyze`, gelesen von einem unabhängigen Prüfer: 19 Befunde (2 kritisch, 2 hoch, 9
mittel, 6 niedrig); Claude hat alle nachgeprüft, Klaus hat am 2026-10-28 alle Empfehlungen
freigegeben. Für die Spec: SC-001 verlangt nur noch, dass der Zeitraffer schneller ist (I1);
Alt+Enter darf im Menü nichts auslösen (I2, FR-023); das Beispiel in Story 1 nennt 37 Schritte (M2).
Alle Befunde stehen in plan.md, „Änderungen nach der Analyse“.

## Begriffe

- **Export:** aus dem Godot-Projekt eine fertige App bauen, die ohne Godot läuft, etwa
  `Der Computerladen.app` auf dem Mac oder `Der Computerladen.exe` unter Windows. Heute gibt es
  das nur für macOS.
- **Preset:** eine gespeicherte Einstellung für einen Export: für welches System, wohin, mit
  welchem Symbol und welche Dateien weggelassen werden. Heute gibt es das Preset „macOS“; es lässt
  Tests und Werkstatt weg.
- **Selbsttest:** eine eigene App, gebaut aus dem Spiel und Testabläufen. Sie startet wie das
  Spiel per Doppelklick, bedient dann den Titel selbst, als säße jemand an Maus und Tastatur, und
  schreibt auf, was dabei herauskam.
- **Ablauf:** eine zusammenhängende Folge von Schritten, die ein Spieler so machen würde, etwa
  „Neues Spiel → Mittel → Spielbildschirm → Zum Hauptmenü“.
- **Schritt:** eine Eingabe und die Prüfung danach, etwa „Enter auf ‚Neues Spiel‘ drücken, dann
  muss die Seite SCHWIERIGKEIT mit ‚Mittel‘ gewählt zu sehen sein“. Zu jedem Schritt gehört ein
  Foto.
- **Foto:** ein Bild dessen, was das Spiel in diesem Moment zeigt, im Oberflächenraster 640 × 360,
  unabhängig davon, wie groß das Fenster ist.
- **Zeitraffer:** Im Selbsttest läuft alles, was nach Zeit rechnet, schneller: die Fahrt des
  Communicators, die Spieluhr, das versteckte Spiel. Fotos entstehen trotzdem erst, wenn alles
  steht.
- **Szenario:** ein Ablauf, der ein Spiel über längere Spielzeit im Zeitraffer spielt, mit festen
  Entscheidungen und Prüfpunkten, etwa „Neues Spiel auf Leicht, bis 1987 jeden Monat Ware
  nachbestellen; am 01.01.1987 prüfen: Kontostand im erwarteten Bereich, Foto“. Das erste kommt mit
  einem späteren Feature.
- **Endabnahme:** die Gesamtabnahme eines Features durch Klaus. Zu ihr gehört ab Feature 008 ein Lauf
  des Selbsttests.
- **Referenzbild:** das Foto eines Schritts, wie es auf macOS aussieht und als richtig abgenommen
  ist. Fotos von Windows und Linux werden damit Pixel für Pixel verglichen.
- **Protokoll:** eine Textdatei je Lauf mit den Systemdaten des Rechners und dem Ergebnis jedes
  Schritts.
- **Renderer:** der Teil von Godot, der das Bild malt. Das Spiel nutzt Forward+ (bis 2026-10-29; seit Feature 009 läuft das Spiel mit Compatibility, siehe `specs/009-renderer-compatibility/`); das braucht auf
  dem Rechner Vulkan, Direct3D 12 oder Metal. In virtuellen Linux-Maschinen fehlt Vulkan oft.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Der Selbsttest läuft auf dem Mac (Priority: P1)

Klaus oder Claude baut die Selbsttest-App und startet sie per Doppelklick. Ein Fenster geht auf,
der Titel erscheint, und die App spielt ihre Abläufe im Zeitraffer durch, ohne dass jemand etwas tut: Der
Communicator fährt herein, „Neues Spiel“ wird gewählt, ein Grad, der Spielbildschirm erscheint,
zurück zum Hauptmenü, das Spiel wird geladen und gelöscht, die drei grauen Knöpfe starten das
versteckte Spiel und Esc beendet es wieder. Nach jedem Schritt prüft die App, ob zu sehen ist, was
zu sehen sein soll, und macht ein Foto. Am Ende zeigt sie eine Zusammenfassung, etwa „Alles in Ordnung: 37 von 37
Schritten in Ordnung“, und sagt, wo Protokoll und Fotos liegen.

**Why this priority**: Das ist der Kern des Features. Tests ohne Fenster sehen nicht alles; in
Feature 006 kam das Signal, dass das Fenster den Fokus hat, nur im echten Fenster, und kein Test
hat den Fehler gefunden. Der Selbsttest bedient das echte Spiel im echten Fenster.

**Independent Test**: Selbsttest-App für macOS bauen, per Doppelklick starten, nichts anfassen. Am
Ende steht die Zusammenfassung da, Protokoll und Fotos liegen am genannten Ort, jeder Schritt ist
in Ordnung.

**Acceptance Scenarios**:

1. **Given** die gebaute Selbsttest-App, **When** Klaus sie per Doppelklick startet, **Then**
   laufen alle Abläufe ohne weiteres Zutun durch, und am Ende steht eine Zusammenfassung auf dem
   Bildschirm.
2. **Given** ein Lauf ist fertig, **When** Klaus nachsieht, **Then** gibt es ein Protokoll mit den
   Systemdaten und je Schritt einer Zeile mit Ablauf, Schritt, Ergebnis und Foto, und zu jedem
   Schritt ein Foto.
3. **Given** ein Schritt findet nicht, was er erwartet, etwa die Seite SCHWIERIGKEIT fehlt nach
   „Neues Spiel“, **When** der Lauf weitergeht, **Then** steht der Schritt im Protokoll als
   Fehler, mit Erwartetem und Gefundenem, und die übrigen Abläufe laufen trotzdem.
4. **Given** auf dem Rechner liegen echte Spielstände, **When** der Selbsttest läuft, **Then**
   bleiben sie unverändert, und der Selbsttest sieht sie nicht.
5. **Given** derselbe Mac, **When** der Selbsttest zweimal hintereinander läuft, **Then** sind die
   Fotos beider Läufe Pixel für Pixel gleich.

---

### User Story 2 - Das Spiel bleibt ohne Testcode (Priority: P1)

Klaus baut wie bisher das Spiel für macOS. Darin steckt kein Testcode und kein Selbsttest; das Spiel
startet und verhält sich wie vor diesem Feature.

**Why this priority**: Der Selbsttest darf nie beim Spieler landen. Das ist dieselbe Regel, nach
der heute schon Tests und Werkstatt aus dem Export fallen.

**Independent Test**: Das Spiel exportieren und den Inhalt der App durchsehen: keine Datei der
Testabläufe darin. Die App startet zum Titel wie bisher.

**Acceptance Scenarios**:

1. **Given** der normale Export für macOS, **When** die App gebaut ist, **Then** enthält sie weder
   Testabläufe noch Tests noch die Werkstatt.
2. **Given** die normale App, **When** Klaus sie startet, **Then** erscheint der Titel wie vor
   diesem Feature, und nichts läuft von selbst.

---

### User Story 3 - Fotos mit dem Mac vergleichen (Priority: P2)

Claude legt nach einem abgenommenen Lauf auf dem Mac die Fotos als Referenzbilder ab. Kommen Fotos
von einem anderen Rechner zurück, vergleicht Claude sie Pixel für Pixel mit den Referenzbildern und
sagt je Schritt: gleich, oder wie viele Pixel abweichen und wo, mit einem Bild, das die
Abweichungen markiert.

**Why this priority**: Ein Foto allein sagt wenig; erst der Vergleich zeigt, dass Windows und Linux
dasselbe Bild malen wie der Mac. Er braucht aber den Selbsttest aus Story 1.

**Independent Test**: Zwei Läufe auf dem Mac vergleichen: alles gleich. Ein Foto absichtlich um
einen Pixel ändern: Der Vergleich findet genau diesen Pixel.

**Acceptance Scenarios**:

1. **Given** Referenzbilder vom Mac und die Fotos eines neuen Laufs, **When** Claude vergleicht,
   **Then** steht je Schritt da, ob das Foto gleich ist, und bei Abweichungen deren Zahl und ein
   Bild mit den markierten Stellen.
2. **Given** ein Foto ohne Referenzbild, etwa für einen neuen Schritt, **When** verglichen wird,
   **Then** meldet der Vergleich das als fehlende Referenz, nicht als Fehler des Spiels.
3. **Given** eine Änderung an der Oberfläche ist abgenommen, **When** sich dadurch Fotos ändern,
   **Then** erneuert Claude die betroffenen Referenzbilder, und die alten bleiben in der
   Versionsgeschichte sichtbar.

---

### User Story 4 - Das Spiel für Windows und Linux (Priority: P3)

Klaus baut das Spiel und den Selbsttest auch für Windows (x86_64) und Linux. Das Spiel trägt unter
Windows das App-Symbol. Klaus startet den Selbsttest auf einem Windows- und einem Linux-Rechner und
gibt Protokoll und Fotos an Claude zurück. Claude vergleicht sie mit dem Mac und berichtet.

**Why this priority**: Das Spiel soll auf allen drei Desktop-Systemen laufen. Der Teil baut auf dem
Selbsttest auf, der dort erst zeigt, ob es wirklich läuft.

**Independent Test**: Auf einem Windows-Rechner den Selbsttest starten; alle Schritte laufen, das
Protokoll nennt Windows, Grafikkarte und Renderer. Das Spiel selbst zeigt im Explorer und in der
Taskleiste das App-Symbol.

**Acceptance Scenarios**:

1. **Given** die Presets für Windows und Linux, **When** Klaus exportiert, **Then** entstehen für
   jedes System das Spiel und der Selbsttest, beim Spiel ohne Testcode.
2. **Given** das Spiel unter Windows, **When** Klaus es im Explorer ansieht und startet, **Then**
   tragen Datei, Fenster und Taskleiste das App-Symbol des Spiels.
3. **Given** das Spiel startet unter Windows oder Linux, **When** das Fenster aufgeht, **Then**
   bekommt es wie auf dem Mac den größten ganzzahligen Faktor, der auf den Bildschirm passt, und
   ist zentriert.
4. **Given** ein Rechner ohne Vulkan oder Direct3D 12, **When** der Selbsttest oder das Spiel
   startet, **Then** weicht Godot nicht auf einen einfacheren Renderer aus, sondern zeigt seine
   eigene Fehlermeldung und beendet sich. Die Quickstart-Anleitung nennt diese Meldung, damit Klaus
   sie erkennt.

---

### User Story 5 - Der Selbsttest wächst mit jedem Feature (Priority: P3)

Ab jetzt prüft der Selbsttest, was ein Feature an Sichtbarem dazubringt. Er gehört zur Endabnahme:
Vor der Gesamtabnahme bekommt das Feature seine Abläufe, Claude baut mit einem Befehl für alle drei
Systeme, lässt den Selbsttest auf dem Mac laufen und legt das Ergebnis mit der Bitte um
Gesamtabnahme vor; wann Klaus ihn auf Windows und Linux startet, legt die Regel aus Phase 7 fest.
Die Phasen davor laufen wie bisher, ohne
Selbsttest (Klaus, 2026-10-28).

**Why this priority**: Ein Selbsttest, der nicht mitwächst, prüft bald das falsche Spiel. Die
Regel ändert aber die Arbeitsweise und damit Dokumente, über die nur Klaus entscheidet.

**Independent Test**: Claude legt in der letzten Phase den Wortlaut für `ki_dev.md`, die Vorlage
für Tasks und die Prüfung vor. Klaus entscheidet je Datei; was er annimmt, steht danach
dort, die Verfassung nur über `/speckit-constitution`. Die Regel gilt ab Feature 008.

**Acceptance Scenarios**:

1. **Given** Klaus hat die Regel beschlossen, **When** `/speckit-tasks` ein neues Feature mit
   Sichtbarem plant, **Then** enthält `tasks.md` vor der Gesamtabnahme die Aufgabe „[A]
   Selbsttest-Abläufe anpassen“.
2. **Given** ein Feature ist fertig, **When** Claude es Klaus zur Gesamtabnahme vorlegt, **Then**
   nennt die Bitte das Ergebnis des Selbsttests auf dem Mac mit Zahlen und den Weg für Windows und
   Linux.
3. **Given** eine Phase mitten im Feature, **When** Claude sie zur Abnahme vorlegt, **Then** gehört
   kein Lauf des Selbsttests dazu.

---

### Edge Cases

- **Ein Schritt scheitert:** Der Ablauf bricht an dieser Stelle ab, seine übrigen Schritte stehen
  als „nicht gelaufen“ im Protokoll, und der nächste Ablauf beginnt wieder beim frischen Titel.
  Ein Fehler zieht so keine Folgefehler in anderen Abläufen nach sich.
- **Ein Schritt hängt:** Jeder Schritt hat eine Höchstzeit. Wird das Erwartete bis dahin nicht
  sichtbar, ist der Schritt ein Fehler mit dem Vermerk „Zeit abgelaufen“.
- **Jemand bewegt die Maus oder tippt während des Laufs:** Echte Eingaben von Maus und Tastatur
  dürfen den Lauf nicht stören; sie werden während des Laufs nicht ans Spiel weitergereicht.
  Schließen des Fensters bricht den Lauf ab; das Protokoll vermerkt den Abbruch.
- **Das Fenster verliert den Fokus,** etwa weil Klaus in ein anderes Programm klickt: Das
  versteckte Spiel hält dann an, wie es soll. Das Protokoll vermerkt jeden Fokusverlust mit dem
  Schritt, in dem er geschah, damit ein Fehler daraus nicht wie ein Fehler im Spiel aussieht.
- **Uhrzeit und Datum des Rechners:** Hinweise im Titel zeigen, wann ein Spiel zuletzt gespielt
  wurde. Damit Fotos auf jedem Rechner gleich sind, rechnet der Selbsttest mit einer festen
  Uhrzeit in einer festen Zeitzone und einem festen Seed; die echte Uhrzeit des Laufs steht nur im Protokoll.
- **Ordner für Ergebnisse nicht beschreibbar:** Der Selbsttest zeigt das auf dem Bildschirm mit dem
  Pfad, statt still ohne Protokoll zu enden.
- **Zweiter Lauf:** Ein neuer Lauf überschreibt keinen alten; jeder Lauf bekommt eigene Dateien,
  benannt nach Datum und Uhrzeit.
- **Spielstände aus einem früheren Selbsttest:** Jeder Lauf beginnt mit einem leeren eigenen
  Ordner für Spielstände, damit „Neues Spiel“ immer gleich vorgewählt ist.
- **Bildschirm kleiner als 1280 × 720:** Das Fenster bekommt Faktor 1. Die Fotos sind davon nicht
  betroffen, weil sie im Oberflächenraster entstehen; das Protokoll nennt Faktor und Fenstergröße.
- **Zwischenablage unter Linux:** Ohne Clipboard-Manager ist der kopierte Text nach dem Beenden
  weg. Die Bestätigung sagt es dort: „Kopiert. Erst einfügen, dann beenden.“
- **macOS warnt beim ersten Start vor der unbekannten App,** Windows ebenso über SmartScreen: Das
  liegt vor Godot und ist nicht Teil des Selbsttests; die Quickstart-Anleitung sagt, wie Klaus es
  bestätigt.

## Requirements *(mandatory)*

### Functional Requirements

**Selbsttest-App**

- **FR-001**: Es MUSS ein eigenes Preset „Selbsttest“ für macOS geben, das eine App aus dem Spiel
  und den Testabläufen baut. Sie trägt einen eigenen Namen, an dem sie vom Spiel zu unterscheiden
  ist, und kann neben dem Spiel auf demselben Rechner liegen.
- **FR-002**: Der normale Export des Spiels MUSS Testabläufe, Tests und Werkstatt weglassen. Das
  Spiel MUSS sich ohne Selbsttest genau wie vor diesem Feature verhalten, mit drei gewollten
  Ausnahmen: Das Fenster steht samt Titelleiste mittig im nutzbaren Bereich (Klaus, Phase 3), F11 und
  Alt+Enter schalten das Vollbild (Clarify, Phase 6), und ohne Vulkan oder Direct3D 12 weicht es nicht
  auf OpenGL aus (R13).
- **FR-003**: Die Selbsttest-App MUSS nach dem Start ohne weiteres Zutun alle Abläufe nacheinander
  durchspielen und danach die Zusammenfassung zeigen. Während des Laufs MUSS der Fenstertitel den
  Fortschritt nennen, etwa „Selbsttest · Schritt 6 von 45: Neues Spiel“; im Spielbild selbst erscheint
  nichts davon, damit die Fotos nur das Spiel zeigen.
- **FR-003a**: Die App MUSS ihre Abläufe im Zeitraffer spielen: Alles, was im Spiel nach Zeit
  rechnet, läuft um einen festen Faktor schneller, im Protokoll als `lauf.zeitraffer` genannt.
  Höchstzeiten gelten in echter Zeit. Der Ablauf `titel` MUSS zusätzlich einmal in normalem Tempo
  laufen (Ablauf `titel_echtzeit`), damit Fehler, die nur bei echtem Tempo auftreten, sichtbar
  bleiben. Auch `fenster` läuft in normalem Tempo, weil es Fenstergrößen misst (R24). Eine feste
  Obergrenze für die Dauer eines Laufs gibt es nicht.
- **FR-004**: Alle Eingaben der Abläufe MÜSSEN als Maus- und Tastatureingaben durch dieselbe
  Eingabe des Spiels gehen, die auch echte Maus und Tastatur nutzen, im echten Fenster. Kein
  Schritt darf eine Seite, einen Knopf oder eine Funktion des Spiels direkt aufrufen, um eine
  Eingabe zu ersetzen. Ausgenommen sind das Vorbereiten eines Ablaufs (Ordner leeren, Spielstände
  anlegen, frischer Titel) und was das Betriebssystem tut, etwa die Fenstergröße; das Protokoll
  nennt solche Schritte mit `eingaben: Vorbereitung` bzw. `eingaben: Fenster`.
- **FR-005**: Die Abläufe MÜSSEN Ziele über ihre Bedeutung finden, etwa „der Eintrag ‚Neues
  Spiel‘“ oder „die mittlere graue Gehäusetaste“, nicht über feste Bildschirmkoordinaten. Rückt
  ein Knopf um ein paar Pixel, läuft der Ablauf weiter; wird ein Eintrag umbenannt oder entfernt,
  scheitert der Schritt mit einer Meldung, die den gesuchten Eintrag nennt.
- **FR-006**: Nach jedem Schritt MUSS die App prüfen, ob der erwartete Zustand erreicht ist: welche
  Seite sichtbar ist, welche Zeile gewählt ist, welcher Hinweis steht, welcher Bildschirm aktiv ist
  und welche Spielstände es gibt. Bewegungen wie die Fahrt des Communicators MÜSSEN vor Prüfung und
  Foto abgeschlossen sein.
- **FR-007**: Nach jedem Schritt MUSS die App ein Foto im Oberflächenraster 640 × 360 als
  verlustfreies Bild speichern, benannt nach Ablauf und Schritt, sodass derselbe Schritt in jedem
  Lauf denselben Namen hat. Ein Schritt, dessen Bild vom Tempo des Rechners abhängt, ist als nicht
  vergleichbar markiert; geprüft wird dort nur der Zustand.
- **FR-008**: Die App MUSS mit einer festen Uhrzeit in einer festen Zeitzone, einem festen Seed und einem leeren eigenen
  Ordner für Spielstände rechnen, sodass zwei Läufe auf demselben Rechner Pixel für Pixel gleiche
  Fotos liefern. Echte Spielstände MÜSSEN unberührt und für den Selbsttest unsichtbar bleiben.
- **FR-009**: Jeder Schritt MUSS eine Höchstzeit haben. Scheitert ein Schritt, MUSS der Rest seines
  Ablaufs als „nicht gelaufen“ gelten und der nächste Ablauf beim frischen Titel beginnen. Baut ein
  Ablauf auf einem gescheiterten auf, gilt er ganz als nicht gelaufen, mit Grund.
- **FR-010**: Echte Maus- und Tastatureingaben MÜSSEN während des Laufs vom Spiel ferngehalten
  werden. Schließen des Fensters MUSS den Lauf abbrechen und den Abbruch im Protokoll vermerken.

**Abläufe**

- **FR-011**: Die Abläufe MÜSSEN mindestens abdecken:
  1. **Titel:** App-Start, der Communicator fährt herein, das Hauptmenü steht mit „Neues Spiel“
     vorgewählt und seinem Hinweis; nicht verfügbare Einträge zeigen ihren Grund.
  2. **Neues Spiel:** „Neues Spiel“ öffnet die Gradwahl mit „Mittel“ vorgewählt; Esc führt zurück
     auf „Neues Spiel“; erneut öffnen, einen Grad wählen, der Communicator fährt hinaus, der
     Spielbildschirm erscheint; „Zum Hauptmenü“ führt zum Titel, das Spiel ist gespeichert, und
     „Weiterspielen“ ist vorgewählt.
  3. **Weiterspielen und Laden:** „Weiterspielen“ setzt das Spiel fort; „Spiel laden“ zeigt die
     Liste mit dem Spielstand, seine Zeile setzt fort.
  4. **Löschen:** in der Liste „Löschen …“, die Zeile wählen, die Rückfrage „LÖSCHEN?“ mit
     „Abbrechen“ vorgewählt, „Spiel 1 löschen“; danach steht das Hauptmenü auf „Neues Spiel“.
  5. **Easter Egg:** die drei grauen Gehäusetasten mit der Maus der Reihe nach drücken, das
     versteckte Spiel erscheint auf der Anzeige, die Kanone fährt und schießt auf Tasten, Esc führt
     zurück auf die Seite und Zeile, von der es gestartet wurde.
  6. **Bedienung:** mindestens ein Schritt je Eingabeart aus dem Titel: Maus über eine Zeile,
     Linksklick, Rechtsklick, Pfeiltasten, Tab, Enter, Esc und Mausrad in der Liste.
  7. **Fenster:** Das Fenster startet mit dem größten ganzzahligen Faktor, der auf den Bildschirm
     passt, und steht zentriert; auf Faktor 1 verkleinert und wieder vergrößert, bleibt das Bild
     ganzzahlig vergrößert, mittig und mit schwarzem Rand. Das Vollbild schaltet der Selbsttest
     nicht; Klaus prüft es von Hand nach der Quickstart-Anleitung.
  8. **Titel in Echtzeit:** der Ablauf `titel` noch einmal, ohne Zeitraffer, mit denselben
     Schritten und denselben Fotos wie `titel` (FR-003a).
- **FR-011a**: Der Läufer MUSS **Szenarien** tragen können: Abläufe, die ein Spiel über längere
  Spielzeit im Zeitraffer spielen, mit festen Entscheidungen über die Oberfläche und Prüfpunkten, an
  denen er Zustand prüft und fotografiert. 007 baut den Rahmen und beschreibt ihn so, dass ein
  späteres Feature ein Szenario anlegen kann, ohne den Läufer zu ändern, außer einem Eintrag in
  seiner Liste der Abläufe (`SelbsttestLaeufer.ABLAEUFE`); ein Szenario selbst bringt
  erst das erste Feature mit Bedienung im Spielbildschirm.
- **FR-012**: „Beenden“ im Hauptmenü wird nicht ausgelöst, weil es den Selbsttest beenden würde;
  geprüft wird nur, dass der Eintrag da und verfügbar ist.

**Ergebnisse**

- **FR-013**: Jeder Lauf MUSS ein Protokoll schreiben mit:
  - Systemdaten: Betriebssystem mit Version, Prozessor, Grafikkarte mit Treiber, Renderer und
    Grafikschnittstelle (etwa Metal, Vulkan, Direct3D 12), Bildschirmgröße, Skalierung des
    Bildschirms, Bildwiederholrate, Fenstergröße und Faktor, Sprache und Tastaturbelegung des
    Systems, Version des Spiels und von Godot, Datum und Uhrzeit des Laufs;
  - je Schritt: Kennung (mit laufender Nummer im Ablauf), Ablauf, Schritt, Ergebnis (in Ordnung, Fehler, nicht gelaufen), bei Fehler
    Erwartetes und Gefundenes, Dauer und Name des Fotos;
  - Fokusverluste und einen Abbruch, wenn es sie gab;
  - am Ende die Summe: wie viele Schritte in Ordnung, fehlerhaft, nicht gelaufen.
- **FR-014**: Das Protokoll MUSS für Klaus ohne Werkzeug lesbar und für Claude ohne Nachfrage
  auswertbar sein (Klaus, 2026-10-28):
  - Jede Systemangabe hat einen festen Namen, jeder Schritt eine feste Kennung aus Ablauf und
    Schritt, gleich auf allen Systemen und in jedem Lauf. So lassen sich zwei Protokolle Schritt für
    Schritt nebeneinanderlegen, etwa Mac gegen Windows.
  - Ein Fehler steht so da, dass Claude ihn ohne Rückfrage einordnen kann: was der Schritt
    eingegeben hat, was erwartet war, was gefunden wurde, das Foto dazu und Warnungen oder Fehler,
    die Godot in diesem Schritt gemeldet hat, gleich von wem; eigene Fehler des Selbsttests sind
    als solche markiert.
  - Das Protokoll nennt die Version des Selbsttests und das Datum seines Baus, damit klar ist,
    welcher Stand der Abläufe lief.
  - Das Zip eines Laufs enthält alles, was Claude zum Auswerten braucht: Protokoll, alle Fotos und
    die Ausgabe des Spiels während des Laufs. Klaus muss nichts abtippen oder beschreiben.
- **FR-014a**: Die Zusammenfassung auf dem Bildschirm MUSS aus demselben Ergebnis entstehen wie das
  Protokoll und darf ihm nie widersprechen: dieselbe Summe, dieselben fehlerhaften Schritte mit
  denselben Kennungen.
- **FR-015**: Am Ende MUSS die App eine Zusammenfassung auf dem Bildschirm zeigen: die Summe, die
  fehlerhaften Schritte mit Ablauf und Schritt und wo Protokoll und Fotos liegen, dazu die Knöpfe
  „Kopieren“, „Ordner zeigen“ und „Beenden“. „Kopieren“ legt Summe, fehlerhafte Schritte mit allen
  Angaben aus FR-014 und die Systemdaten als Text in die Zwischenablage, sodass Klaus ihn in den
  Chat einfügen kann. Sie ist eine eigene Seite im Look der Werkzeuge aus dem
  Style-Guide, wie die Werkstatt, nicht auf dem Communicator, und duzt. Anders als die Werkstatt
  bleibt sie im Fenster des Laufs, ohne Größe und Lage zu ändern (Klaus, Phase 4). Fehler und nicht gelaufene Schritte unterscheiden sich in Form und
  Zeichen. Passen nicht alle fehlerhaften Schritte auf die Seite, lässt sich die Liste scrollen.
  Aufbau, Schrift, Tasten und Wortlaute legt der Vertrag fest.
- **FR-016**: Protokoll und Fotos MÜSSEN im eigenen Datenordner der Selbsttest-App liegen, je Lauf
  in einem Unterordner, benannt nach Datum und Uhrzeit, und zusätzlich als ein Zip-Archiv je Lauf,
  das Klaus an Claude zurückgibt. Die Zusammenfassung MUSS den Pfad nennen und einen Knopf „Ordner
  zeigen“ haben, der das Zip des Laufs im Finder, Explorer oder Dateimanager zeigt, markiert, wo
  das System es kann; daneben liegt der Ordner des Laufs.
- **FR-017** (bis 2026-10-29; seit Feature 009 läuft das Spiel mit Compatibility, siehe `specs/009-renderer-compatibility/`): Spiel und Selbsttest MÜSSEN mit Forward+ laufen; Godot DARF NICHT auf einen
  einfacheren Renderer ausweichen. Fehlt Vulkan oder Direct3D 12, zeigt Godot seine eigene
  Fehlermeldung und beendet sich, ohne Protokoll. Das Protokoll MUSS Renderer und
  Grafikschnittstelle nennen, die tatsächlich laufen, etwa wenn Windows statt Direct3D 12 auf
  Vulkan ausweicht.

**Vergleich mit Referenzbildern**

- **FR-018**: Die Referenzbilder vom Mac MÜSSEN im Repo liegen, je Schritt eins, mit demselben
  Namen wie das Foto.
- **FR-019**: Ein Vergleichswerkzeug außerhalb von Godot MUSS die Fotos eines Laufs mit den
  Referenzbildern vergleichen und je Schritt melden: gleich, abweichend mit Zahl der Pixel und
  einem Bild mit markierten Abweichungen, nicht vergleichbar, Referenz fehlt oder Foto fehlt.
- **FR-020**: Referenzbilder MÜSSEN nur nach einem Lauf erneuert werden, dessen Ergebnis Klaus
  abgenommen hat.
- **FR-020a**: Ergebnisse von anderen Rechnern MÜSSEN als Zip in einen unversionierten
  Eingangsordner im Repo gelegt werden, aus dem Claude sie entpackt und vergleicht. Als Beleg
  versioniert werden je Lauf das Protokoll und der Vergleichsbericht im Spec-Ordner, die Fotos nur,
  wo sie vom Referenzbild abweichen, mit dem Bild der markierten Abweichungen.

**Windows und Linux**

- **FR-021**: Es MUSS Presets für das Spiel und für den Selbsttest unter Windows (x86_64) und Linux
  (x86_64) geben, mit denselben Ausschlüssen wie unter macOS.
- **FR-022**: Das Spiel MUSS unter Windows das App-Symbol tragen, als Datei im Explorer, im Fenster
  und in der Taskleiste. Das Symbol im Windows-Format MUSS aus derselben Quelle entstehen wie das
  Symbol für macOS.
- **FR-023**: Fenster und Skalierung MÜSSEN unter Windows und Linux wie auf dem Mac gelten:
  ganzzahliger Faktor beim Start, zentriert, Mindestgröße 640 × 360. Das Vollbild MUSS sich auf
  allen drei Systemen per Tastatur hin und zurück schalten lassen: auf dem Mac mit Ctrl+Cmd+F, unter
  Windows und Linux mit F11 und mit Alt+Enter. Das Kürzel schaltet nur das Vollbild und löst im
  Menü nichts aus, auch nicht Alt+Enter auf einem gewählten Eintrag (Analyse, I2).
- **FR-024**: Was der Export für Windows und Linux braucht, heute die vollständigen
  Export-Templates 4.7.2, MUSS dokumentiert sein; ein Download geschieht nur mit Klaus' Erlaubnis, mit Dateiname, Quelle
  und Größe.
- **FR-025**: Die Exporte MÜSSEN ohne Signatur auskommen; Signieren und Beglaubigen kommen später.
  In den gespeicherten Export-Einstellungen stehen keine Zugangsdaten.

**Arbeitsweise**

- **FR-026**: Das Feature MUSS in der Quickstart-Anleitung beschreiben, wie man den Selbsttest
  baut, startet und die Ergebnisse zurückgibt, für jedes der drei Systeme.
- **FR-026a**: Ein Befehl MUSS für die Endabnahme alles bauen: für macOS, Windows und Linux je Spiel
  und Selbsttest, mit der Prüfung, dass im Spiel kein Testcode steckt (SC-005), und je System einem
  Zip zum Weitergeben. Scheitert ein Teil, MUSS der Befehl das mit System und Grund melden und mit
  einem Fehlercode enden.
- **FR-027**: In der letzten Phase MUSS Claude den Wortlaut der Regel aus Story 5 für `ki_dev.md`,
  die Vorlage für Tasks und die Prüfung vorschlagen: Selbsttest zur Endabnahme, nicht nach jeder
  Phase. Geändert wird nur, was Klaus annimmt,
  die Verfassung nur über `/speckit-constitution`.

### Key Entities

- **Ablauf:** Name, Reihenfolge, Schritte; beginnt immer beim frischen Titel mit leerem Ordner für
  Spielstände, außer er baut erklärt auf dem vorigen auf.
- **Schritt:** Name, Eingaben, erwarteter Zustand, Höchstzeit; ergibt ein Ergebnis und ein Foto.
- **Lauf:** Datum und Uhrzeit, Systemdaten, die Ergebnisse aller Schritte, Fokusverluste, Abbruch.
- **Protokoll:** der Lauf als Textdatei.
- **Foto / Referenzbild:** Bild 640 × 360 je Schritt; das Referenzbild ist das abgenommene Foto vom
  Mac.
- **Vergleichsbericht:** je Schritt das Ergebnis des Vergleichs, dazu die Bilder mit markierten
  Abweichungen.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Der Ablauf `titel` braucht im Zeitraffer weniger Zeit als `titel_echtzeit` (Analyse,
  I1: Der Communicator begrenzt seinen Schritt je Bild, der Zeitraffer wirkt bei ihm nur etwa
  doppelt); Dauer je Schritt und gesamt stehen im Protokoll. Eine feste
  Obergrenze gibt es nicht (Klaus, 2026-10-28).
- **SC-002**: Zwei Läufe hintereinander auf demselben Mac liefern Fotos, die Pixel für Pixel
  gleich sind, und Protokolle, die sich nur in Zeiten, Dauern, Pfaden und Fokusverlusten
  unterscheiden.
- **SC-003**: Auf dem Mac sind in einem Lauf ohne Fokusverlust und ohne Abbruch alle Schritte in
  Ordnung.
- **SC-004**: Fehlerprobe: In einer Kopie wird mindestens je ein Fehler in Titel, Gradwahl, Liste,
  Rückfrage, Easter Egg und Fenster eingebaut, also sechs, etwa eine falsch vorgewählte Zeile. Der
  Selbsttest meldet jeden als Fehler im passenden Schritt.
- **SC-005**: Der normale Export enthält keine einzige Datei der Testabläufe; geprüft am Inhalt
  der gebauten App.
- **SC-006**: Echte Spielstände sind nach einem Lauf bytegleich mit vorher.
- **SC-007**: Klaus findet nach einem Lauf Protokoll und Fotos mit höchstens einem Klick von der
  Zusammenfassung aus.
- **SC-008**: Der Vergleich findet einen absichtlich geänderten einzelnen Pixel und meldet zwei
  gleiche Läufe als gleich.
- **SC-009**: Auf je einem Windows- und Linux-Rechner mit Vulkan oder Direct3D 12 läuft der
  Selbsttest bis zur Zusammenfassung, und Claude hat zu jedem Foto ein Vergleichsergebnis.
- **SC-010**: Claude kann aus Zip oder kopiertem Text eines Laufs jeden fehlerhaften Schritt ohne
  Rückfrage an Klaus einordnen; geprüft an der Fehlerprobe aus SC-004, deren Protokolle Claude ohne
  weitere Angaben dem richtigen eingebauten Fehler zuordnet.

## Assumptions

- Teil 1 (macOS) wird vor Teil 2 (Windows, Linux) gebaut und abgenommen. Teil 2 braucht Klaus mit
  einem Windows- und einem Linux-Rechner; Claude kann dort nichts ausführen.
- Die Abläufe decken nur, was es heute im Spiel gibt: Titel, Seiten auf dem Communicator, den
  leeren Spielbildschirm und das Easter Egg. Was später dazukommt, bringt sein Feature mit.
- Was vor Godot liegt, prüft der Selbsttest nicht: Fensterverwaltung des Systems, Warnungen beim
  ersten Start, Tastaturbelegung des Systems über die Anzeige im Protokoll hinaus. Dafür wirft
  Klaus einen kurzen Blick darauf, nach der Quickstart-Anleitung.
- Die Fotos zeigen das Oberflächenraster 640 × 360, nicht das vergrößerte Fenster. Ob die
  Vergrößerung stimmt, prüft der Ablauf „Fenster“ an Faktor, Fenstergröße und Lage des Bilds.
- Töne prüft der Selbsttest nur so weit, wie Tests das heute tun: welcher Ton auf welchem Kanal
  anläuft, nicht, wie er klingt.
- Linux heißt x86_64; ARM-Rechner sind nicht Ziel dieses Features.
- Ob der Selbsttest auf GUT aufbaut oder einen eigenen kleinen Läufer bekommt und wie die Abläufe
  ihre Ziele finden, entscheidet der Plan.
- Die Selbsttest-App ist ein Werkzeug für Klaus und Claude und wird nicht an Spieler gegeben.
- Der Selbsttest gehört zur Endabnahme, nicht zu jeder Phase (Klaus, 2026-10-28). Innerhalb von 007
  läuft er in den Phasen, die ihn bauen, weil er dort selbst das Prüfstück ist.
