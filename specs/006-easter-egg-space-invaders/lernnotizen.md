# Lernnotizen: Easter Egg 01: Space Invaders

Zu jeder umgesetzten Task die Godot-Konzepte und warum es so gebaut ist, an den Stellen im
Projekt. Bei `[A]`-Tasks schreibt der Agent die Notizen, Claude trägt sie je Phase hier ein; baut
Klaus eine Task selbst, schreibt Claude die Notiz beim Review. Abnahmen und Phasenprüfungen bauen
nichts und haben deshalb keine Notiz.

## Phase 2

### T004 Tonskript: eine Rechteckwelle als Zahlen

Kein Godot, aber die Grundlage für alles, was in Phase 2 bis 5 klingt (`tools/ton/make_sounds.py`).

- Ein **digitaler Ton** ist eine Liste von Zahlen, 22 050 je Sekunde (die Abtastrate). Jede Zahl
  sagt, wie weit die Lautsprechermembran in diesem Augenblick ausgelenkt ist, als 16-Bit-Wert von
  −32 768 bis 32 767. `wave` aus der Standardbibliothek schreibt die Liste mit dem Kopf, den ein
  WAV braucht.
- Eine **Rechteckwelle** springt nur zwischen zwei Werten, +Pegel und −Pegel. Wie oft sie springt,
  ist die Tonhöhe: Bei 98 Hz (`marsch_1.wav`) wechselt sie 98-mal je Sekunde hin und her, also alle
  rund 112 Proben. Das Skript führt eine **Phase** von 0 bis 1 mit; je Probe wächst sie um
  Frequenz ÷ Abtastrate, und in der ersten Hälfte ist der Wert oben, in der zweiten unten. So kann
  sich die Frequenz Probe für Probe ändern, ohne zu springen, etwa beim Schuss von 1200 auf 600 Hz.
  So klangen PC-Lautsprecher und Taschengeräte, die nur „an“ und „aus“ kannten.
- **Rauschen** sind Zufallszahlen. Damit es bei jedem Lauf dasselbe Rauschen ist, hat jede Datei
  einen festen Seed (`random.Random(1)` für den Klick). Ein Seed ist der Startwert des
  Zufallsgenerators: gleicher Seed, gleiche Folge, wie beim Fahrplan der Zeitleiste. Daraus folgt
  „bytegleich“, und deshalb kann `test_ton.gd` die Dateien über Prüfsummen mit dem Skript
  vergleichen.
- **Hüllkurve:** Treffer und Kanone werden leiser, indem jede Probe mit einem Faktor malgenommen
  wird, der exponentiell von 1 gegen 0 fällt. Am Ende jedes Tons fallen die letzten 5 ms linear auf
  genau 0. Ein Ton, der mitten in einer Auslenkung abbricht, knackt im Lautsprecher.
- **Kein stiller Anfang:** Die Phase beginnt bei 0, die erste Probe ist also schon +Pegel. Damit
  klingt der Ton im selben Augenblick, in dem Godot ihn startet (SC-007).
- **−6 dBFS:** Der Spitzenpegel ist die Hälfte des Vollausschlags (10^(−6/20) ≈ 0,5). Das lässt
  Luft, wenn mehrere Töne gleichzeitig im Bus `Effekte` zusammenkommen, damit die Summe nicht
  übersteuert.

### T005 Tonkanäle und Import: `default_bus_layout.tres` und die `.import` der WAV

- Ein **Bus** (im Style-Guide „Tonkanal“) ist eine Mischstufe im `AudioServer`: Jeder
  `AudioStreamPlayer` spielt in genau einen Bus (`bus = &"Effekte"`), der Bus mischt alles, was in
  ihn spielt, regelt den Pegel (`volume_db`), kann Effekte tragen und gibt das Ergebnis an sein
  Ziel weiter (`send`). Am Ende steht immer `Master`, Bus 0, der an den Ausgang geht.
- Die Töne bekommen einen eigenen Bus `Effekte` (−10 dB, Ziel `Master`), statt direkt in `Master`
  zu spielen. So gibt es genau eine Stelle für „Effekte lauter oder leiser“
  (`AudioServer.set_bus_volume_db()`), und kein Player trägt einen eigenen Pegel. Kommt später
  Musik, bekommt sie einen Bus neben `Effekte`; ein „Einstellungen“ regelt dann beide getrennt und
  `Master` als Gesamtlautstärke (R14). Effekte auf den Bussen gibt es keine: Hall wäre gegen den
  Style-Guide.
- `src/default_bus_layout.tres` ist eine Resource vom Typ `AudioBusLayout`, als Text geschrieben.
  Jeder Bus ist ein Satz Zeilen `bus/<nummer>/…`; `bus/1/send = &"Master"` ist das Ziel. `Master`
  steht ausdrücklich mit 0 dB darin, obwohl das der Vorgabewert ist: Wer die Datei liest, sieht
  beide Kanäle.
- Warum Godot die Datei **von selbst** lädt: Die Projekteinstellung `audio/buses/default_bus_layout`
  hat den Vorgabewert `"res://default_bus_layout.tres"` (Klassenreferenz `ProjectSettings`). Beim
  Start lädt der `AudioServer` die Datei unter diesem Pfad, falls es sie gibt. Deshalb bleibt
  `project.godot` unverändert; eine Einstellung stünde dort nur, wenn wir einen anderen Pfad
  wollten. Der Editor legt dieselbe Datei an, sobald man im Fenster „Audio“ unten einen Bus
  hinzufügt. Die Fehlerprobe zeigt es: Ohne die Datei kennt der `AudioServer` nur `Master`, und
  `test_kanaele_master_und_effekte` schlägt fehl.
- Die Datei hat keine `uid://` im Kopf, weil sie als Text entstand; der Editor trägt eine ein,
  sobald er sie einmal speichert. Für Godot reicht der Pfad, und der ist durch die Einstellung
  ohnehin fest.
- Eine **`.import`** neben jeder WAV hält fest, wie Godot die Rohdatei in eine eigene Ressource
  umwandelt (`AudioStreamWAV`, abgelegt unter `.godot/imported/`, nicht im Repo). Unter `[params]`
  stehen die Import-Einstellungen, unter `[remap]` die `uid` der Datei. Deshalb wird `.import`
  committet: Ohne sie importiert ein frischer Clone mit den Vorgaben, und Verweise per `uid`
  brechen.
- Godots Vorgaben für WAV passen hier zweimal nicht, beide habe ich in den zehn `.import` geändert:
  `compress/mode=2` („Quite OK Audio“, verlustbehaftet) wird `0` („PCM (Uncompressed)“), und
  `edit/loop_mode=0` („Detect from WAV“, folgt den Schleifenmarken in der Datei) wird `1`
  („Disabled“). `edit/trim` und `edit/normalize` sind schon `false`.
- Warum **PCM**: Die Proben sollen so klingen, wie das Skript sie schreibt. QOA und IMA ADPCM
  verändern sie leicht und müssen beim Abspielen dekodiert werden; Trimmen schnitte leise Stellen unter −50 dB
  an Anfang und Ende ab, also einen Teil des Ausblendens, und die Länge stimmte nicht mehr;
  Normalisieren den Spitzenpegel von −6 dBFS auf 0 dB
  heben. Bei zusammen unter 100 KB kostet PCM nichts. „Schleife aus“ statt „aus der Datei“ macht
  die Absicht ausdrücklich, statt sich darauf zu verlassen, dass die WAV keine Marken hat.
- Geändert wurde die `.import` als Text, danach lief `--import` noch einmal. Godot merkt an den
  geänderten `[params]`, dass die Ressource neu entstehen muss. Im Editor ginge dasselbe im Dock
  „Import“ mit „Reimport“.

### T006 Tests: Rohdatei, Import und Kanäle getrennt prüfen

- `test_ton.gd` liest Proben, Länge und Prüfsumme aus der **Rohdatei**
  (`FileAccess.get_file_as_bytes()`, `FileAccess.get_md5()`), nicht aus der importierten Ressource
  (wie `test_bilder.gd` bei den PNG). Was der Import daraus macht, prüft ein eigener Test an der
  geladenen `AudioStreamWAV` (`format == FORMAT_16_BITS`, `loop_mode == LOOP_DISABLED`, `stereo`,
  `mix_rate`) und an der `.import` selbst, gelesen mit `ConfigFile`, denn sie ist eine INI-Datei.
  Beides zusammen sagt: Die Datei ist richtig, und Godot spielt sie unverändert.
- `_lies_wav()` geht die RIFF-Blöcke der Reihe nach durch, statt feste 44 Byte Kopf anzunehmen. Eine
  WAV darf weitere Blöcke haben; so findet der Test `fmt ` und `data` auch dann.
  `PackedByteArray.decode_s16()` liest eine vorzeichenbehaftete 16-Bit-Probe, Little Endian wie in
  WAV üblich.
- Die Kanäle prüft der Test am laufenden `AudioServer` (`bus_count`, `get_bus_send()`,
  `get_bus_volume_db()`), nicht an der `.tres`. Er prüft damit, was Godot beim Start tatsächlich
  geladen hat, also auch, dass die Datei ohne Projekteinstellung greift.
- Ein Test prüft, dass im Ordner genau die zehn WAV liegen. Ein elfter Ton ohne Eintrag im
  Style-Guide fällt so auf, statt ungeprüft mitzulaufen.
- Headless läuft der Dummy-Tontreiber; zu hören ist nichts (R15). Ob die Töne gut klingen und sofort
  einsetzen, prüft Klaus mit `afplay`.
