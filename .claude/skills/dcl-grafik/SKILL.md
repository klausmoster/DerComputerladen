---
name: dcl-grafik
description: Erzeugt und rastert Grafiken für „Der Computerladen“. Claude bedient Leonardo.ai selbst über Claude in Chrome, Klaus wählt nur aus; danach Rasterfassung mit tools/raster/, Montage zum Prüfen, Prompt-Log. Nutze dies bei jedem neuen oder geänderten Bild (Titelbild, Szene, Gehäuse des Communicators, Figur, Cover, Logo), bei jedem Prompt für Leonardo und bei jeder Nachbearbeitung eines gerasterten Bilds.
argument-hint: "[Bild-ID und Zweck, etwa G-03 Gehäuse des Communicators]"
---

# Grafik erzeugen und rastern

Wer was tut: **Claude erzeugt die Bilder selbst in Leonardo**, über Claude in Chrome im Konto des
Projekts. Klaus wählt das Bild aus und gibt es frei. Claude fragt nicht, ob Klaus erzeugen will,
und schreibt keine Anleitung zum Selbermachen (Klaus, 2026-10-27; `docs/ki_workflow/ki_dev.md`,
Grafik).

Vorher lesen: im Style-Guide (https://claude.ai/artifact/Hc5aS78T3fAzufkKnjrKRX) den
Leonardo-Workflow (Modelle, Stilblock, Formate, Nachbearbeitung, Prompt-Bibliothek) und den
Baustein, zu dem das Bild gehört; `tools/raster/README.md`; den letzten passenden Eintrag in
`docs/art/leonardo/prompt-log.md` als Beispiel für die Rasterfassung.

## 1. Prompt

1. Bild-ID vergeben (T- Titel, S- Szene, F- Figur, G- Gerät, C- Cover), Zweck und Endgröße aus dem
   Leonardo-Workflow, Abschnitt „Formate“, oder aus der Spec.
2. Prompt auf Englisch, am Ende unverändert der Stilblock. Kein echter Markenname, kein Logo, keine
   Schrift; ein echtes Vorbild nur in Worten beschreiben, nie ein Foto davon als Bildvorlage.
   Was die Oberfläche später darüber malt (etwa ein LCD), als leere Fläche mit genauem
   Seitenverhältnis verlangen.
3. Den Prompt **vor** dem Erzeugen in die Prompt-Bibliothek des Style-Guides schreiben (Abschnitt
   „Prompts“, mit Modell, Format, Zweck und Vorbild) und den Style-Guide veröffentlichen
   (Grundsatz IV der Verfassung).

## 2. Erzeugen in Leonardo

1. Claude in Chrome: `tabs_context_mcp` mit `createIfEmpty`. Chrome läuft auf Klaus' Rechner nur
   mit eigenem Profil, sonst schließt es sich sofort. Ist die Erweiterung nicht erreichbar (auch
   `list_connected_browsers` leer), Chrome selbst starten:
   `open -na "Google Chrome" --args --user-data-dir="$HOME/Library/Application Support/Google/Chrome-Profil"`
   und erneut verbinden. Hilft das nicht, das sofort sagen, mit Grund; nicht auf einen anderen
   Browser ausweichen, im eingebauten Browser ist Leonardo nicht angemeldet.
2. Stil und Format setzt am sichersten die Adresse:
   `https://app.leonardo.ai/generate?model=lucid-origin&aspectRatio=1:1&size=LARGE&style=556c1ee5-ec38-42e8-955a-1e82dad0ffa1&mode=FAST&quantity=4&promptEnhance=OFF`
   plus `styleReference` für C2 (Upload-ID `82babb4d-8986-4fb1-9c6f-4a5aca320999`, Stärke HIGH).
   Die Oberfläche übernimmt den Stil daraus nicht immer: im Menü „Style“ von Hand „None“ wählen.
3. Einstellungen nach dem Leonardo-Workflow: Modell
   Lucid Origin, Seitenverhältnis und größte Bildgröße, 4 Bilder, Style None, Prompt Enhance aus,
   Generation Mode Fast, Style Reference Stilanker C2 (Stärke High; liegt im Konto als Upload
   `stilanker-c2.jpg`). Vor dem Erzeugen per Screenshot prüfen, dass alles stimmt, auch der Stil:
   Leonardo stellt ihn gern auf „Dynamic“ zurück.
4. Prompt einfügen (Feld anklicken, Cmd+A, Entf, tippen), erzeugen, rund 30 s warten. Die Bild-URLs mit `javascript_tool` aus den `<img>`-Quellen
   lesen (`https://cdn.leonardo.ai/users/…/generations/<Durchgang>/…-<n>.jpg`). Den Seed des
   Durchgangs liefert der Cache der Seite: `window.__APOLLO_CLIENT__.cache.extract()`, Schlüssel
   `generations:<Durchgang>`, Feld `seed`.
5. Mit `curl -s` in einen eigenen, neuen Ordner im Scratchpad laden (`<id>-0.jpg` bis `-3.jpg`),
   mit `sips -Z 720` verkleinerte Fassungen für Klaus machen und ihm alle vier mit `SendUserFile`
   zeigen: Was gelungen ist, was stört, eine Empfehlung. Gewählt wird das Bild, das dem Stilanker
   am nächsten kommt, nicht das spektakulärste. Klaus entscheidet als Auswahl, Empfehlung zuerst.
6. Das gewählte Original nach `docs/art/leonardo/<id>-<name>.jpg` kopieren.

## 3. Rasterfassung

Alle Werkzeuge vom Repo-Root mit `python3 -I`; eigene Hilfsskripte liegen im Scratchpad, nie in
dem Ordner mit den geladenen Bildern.

1. **Maßstab finden:** Was genau passen muss (ein LCD, die Bildgröße), im Original messen. Das
   Original mit `sips -z` so skalieren, dass dieses Maß ein ganzes Vielfaches des Faktors wird
   (G-02: LCD 480 × 240 bei Faktor 3 = 160 × 80 Bildpixel).
2. **Ausschnitt und Freistellen:** mit `sips -c` zuschneiden; freistehende Geräte per Füllung vom
   Rand freistellen (OKLab-Abstand zur Randfarbe unter 0,06), als RGBA-PNG schreiben (`pngio`).
3. `tools/raster/rasterize.py … --faktor N` oder `--groesse BxH`, danach mit einer vergrößerten
   Ansicht mit Rastermarken messen, wo die wichtigen Kanten liegen.
4. **Zuschneiden und Herausnehmen:** Ist ein Rand zu breit, ganze Spalten und Zeilen aus
   gleichförmigen Flächen herausnehmen, nie aus Tasten, Kanten oder Figuren; Ränder ringsum
   gleich breit halten. Was herausgenommen wird, notieren (für das Prompt-Log).
5. `tools/raster/cleanup.py <bild>` (arbeitet in der Datei selbst).
6. **Von Hand:** Schriftreste, Zeichen und Logos mit der Farbe daneben übermalen, Konturen
   schließen, Einzelpunkte entfernen, Blenden spiegeln, wenn sie ungleich sind. Nur Farben der
   Hauptpalette `docs/art/hauptpalette.gpl`; sie ist eingefroren.
7. **Helligkeit:** Wirkt ein Gerät zu braun oder dunkel, den warmen Kunststoff in OKLab um 0,12
   aufhellen und a/b mit 0,75 entsättigen, auf die nächste Szenenfarbe der Palette (Index ab 16);
   Konturen und Blau bleiben.
8. Als indiziertes PNG nach `src/assets/images/`, dann
   `Godot --headless --path src --import`; `.import` mit committen.

## 4. Prüfen und zeigen

1. **Montage** in Spielgröße 640 × 360: Titelbild, Logo, das neue Bild an seiner Lage, Flächen der
   Oberfläche (etwa die LCD-Farbe) darüber; ×2 vergrößert ansehen. Erst prüfen, was Klaus stören
   könnte (Ränder, Schnitte, Schrift, Farben), dann zeigen.
2. Nach dem Einbau Fotos aus dem echten Spiel; die Phasenprüfung (`/dcl-phasenpruefung`) prüft das
   Bild gegen den Style-Guide.
3. **Prompt-Log** `docs/art/leonardo/prompt-log.md`: Datei, Datum, Durchgang, Bild und Seed,
   Format und Einstellungen, Auswahl mit Grund, die ganze Rasterfassung mit allen Zahlen, Status,
   und der Prompt im Wortlaut.
4. Ändern sich dabei Maße (Lage der Anzeige, Größe des Gehäuses), gehen sie zuerst in den
   Style-Guide und die Specs, dann als Auftrag an den Godot-Agent.
