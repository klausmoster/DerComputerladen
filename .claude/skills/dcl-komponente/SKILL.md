---
name: dcl-komponente
description: Befüllt eine PC-Komponenten-Doc der game_bible (Der Computerladen) mit recherchierten Daten. Funktioniert generisch für jeden Komponententyp (CPU, Tastatur, …) anhand der Templates unter docs/game_bible/Templates/. Der Skill listet alle vorhandenen Templates, fragt welches genutzt werden soll, und füllt dann alle Frontmatter-Felder (Technik, Markt, Preise als von/bis-Range, Handel, Lager, Kompatibilität, Wettbewerb) sowie die Spiel-Inhalte (Datenblatt, Beschreibung, Zeitungsartikel, Werbung, Hintergrund). Nutze dies, wenn der Nutzer eine Komponente anlegen, befüllen, recherchieren oder vervollständigen möchte.
---

# Komponenten-Doc füllen

Recherchiert und befüllt eine Komponenten-Seite der game_bible mit Daten. Die
game_bible liegt unter `docs/game_bible/` (Ordner für Komponenten, Ordner
`Templates/`). Der Skill ist **generisch**: Welche Felder es gibt und wo die
Datei am Ende liegt, steht im jeweiligen Template — nicht hier fest verdrahtet.

Ziel ist allein das **Anlegen/Befüllen der Daten-Datei**.

## Verbindliche Regeln (zuerst lesen)
- **Schema:** Das **gewählte Template** (`Templates/TEMPLATE_*.md`) ist die
  **alleinige** Autorität für Aufbau, Feldnamen, Reihenfolge und `## +`-Struktur.
  Übernimm GENAU dessen Frontmatter-Struktur und dessen `## +`-Abschnitte
  (inkl. `###`-Rubriken) — nichts weglassen, nichts erfinden.
- **Keine Orientierung an vorhandenen Dateien:** Baue jede neue oder
  aktualisierte Datei **immer so, wie das Template es vorgibt** — niemals so, wie
  eine schon vorhandene Datei aufgebaut ist. Weicht eine Bestandsdatei vom
  Template ab, ist das KEIN Vorbild (sonst lassen sich Strukturänderungen nie
  durchsetzen). Vorhandene Dateien dienen nur dazu, eine Komponente
  auszuwählen/wiederzufinden — nicht als Stil- oder Strukturvorlage.
- **Datenregeln:** `KI-Prompt.md` (in `docs/game_bible/`) enthält die
  Konventionen — beachte sie:
  - Strukturierte Daten NUR ins Frontmatter; Skalare als `kategorie_feld`.
  - Preise als Range: je Eintrag `von`/`bis` als **Zahl in DM** (kein "DM",
    kein Tausenderpunkt). Range = typische Spanne günstig…teuer.
  - Freitext NUR unter `##`-Überschriften, deren Titel mit `+` beginnt.
- **Genauigkeit:** Nur belegbare Werte; Unsicheres plausibel schätzen und im
  Freitext als „geschätzt" kennzeichnen. Bezug: deutscher Markt, 1990er, DM,
  Datumsformat `JJJJ-MM`.

## Schritt 1 — Template wählen
1. Liste alle Templates: `.md`-Dateien unter `docs/game_bible/Templates/`, deren
   Name mit `TEMPLATE_` beginnt.
2. Lies aus jedem Template den `SKILL-ROUTING`-Kommentarblock (siehe unten) aus,
   um den Komponententyp (`typ`) zu kennen.
3. Frage per AskUserQuestion, welcher Komponententyp/welches Template genutzt
   werden soll — eine Option je gefundenem Template (Label = `typ`).

### Der SKILL-ROUTING-Block im Template
Jedes Template enthält im Body einen Kommentar dieser Form:
```
<!-- SKILL-ROUTING (vom /dcl-komponente-Skill gelesen; NICHT in die fertige Datei kopieren)
typ: CPU
zielordner: CPUs/<hersteller>
dateiname: <name>
index_seite: CPUs/<hersteller>/<hersteller>.md
hinweis: "..."
-->
```
- `typ` — Anzeigename des Komponententyps (für die Auswahlfrage).
- `zielordner` — wohin die fertige Datei gehört. Platzhalter `<hersteller>` =
  Ordner-Kurzform des Herstellers (z.B. „Intel", „AMD").
- `dateiname` — Muster für den Dateinamen ohne `.md`. `<name>` = voller
  Anzeigename, den der Nutzer nennt.
- `index_seite` — optionale Index-/Übersichtsseite für einen Wikilink (leer/fehlt = kein Link).

Fehlt der Block in einem Template, frage den Nutzer nach Zielordner und
Dateiname.

## Schritt 2 — Komponente wählen (neu oder vorhanden)
1. Suche im `zielordner` des Templates nach vorhandenen Daten-Dateien (`.md` mit
   echten Daten im Frontmatter, nicht reine Index-/Link-Seiten).
2. Frage per AskUserQuestion: Option **„Neue Komponente"** plus je eine Option
   pro gefundener vorhandener Datei. Bei mehr als 3 vorhandenen: als Text
   auflisten und den Nutzer eine nennen lassen.
3. Bei **neuer Komponente**: erfrage den vollständigen Namen (z.B. „Intel 80486
   DX-33, 33MHz"). Leite den Zielpfad aus dem Routing ab
   (`zielordner`/`dateiname`.md), ersetze die Platzhalter und **bestätige den
   finalen Pfad** mit dem Nutzer (Ordner anlegen, falls nötig).
4. Bei **vorhandener Komponente**: recherchierte Werte ergänzen/korrigieren, dabei
   die Datei zugleich auf die **aktuelle Template-Form** bringen (Felder,
   Reihenfolge, `## +`-Struktur). Recherchierte Inhalte nicht grundlos verwerfen,
   aber Abweichungen vom Template begradigen statt erhalten.

## Schritt 3 — Recherche & Quellen-Abgleich (VOR dem Füllen)
Reihenfolge ist **zwingend** — keine Werte aus dem Gedächtnis ohne
Quellenabgleich (Gefahr falscher Specs).

1. **Zuerst** diese deutschen Hardware-Fachquellen durchlesen (Basis-Set, gilt
   für alle PC-Komponenten — soweit für den Typ relevant, mindestens diese):
   - `de.wikipedia.org` — Modellübersicht, Architektur, Einführungsdatum
   - `heise.de` / **c't-Archiv** — zeitgenössische Tests & Marktpreise (DE)
   - `computerbase.de` — Spezifikationen & Einordnung
   - `pcwelt.de` — Tests, Preise, Marktlage
   - `hardwareluxx.de` — Specs & News
   - `planet3dnow.de` — vertieft (besonders AMD)
2. **Danach** eine allgemeine Websuche für Lücken (Preise, Marktdaten,
   Detailspecs). Bei CPUs zum Abgleich technischer Werte zusätzlich:
   `cpu-world.com`, `en.wikichip.org`, Hersteller-Datenblätter.
3. **Abgleich (Kreuzprüfung):** Jeden einzelnen Wert — Spezifikation, Datum,
   Preis — über **mindestens zwei unabhängige Quellen** gegenprüfen:
   - Stimmen die Quellen überein → Wert übernehmen.
   - Widersprechen sie sich → den plausibelsten Wert wählen, die Abweichung in
     `## + Hintergrund & Quellen` festhalten und als „geschätzt / Quellen
     uneinig" kennzeichnen.
   - Nur eine Quelle → als unsicher markieren.
4. Alle benutzten Quell-Links sammeln → sie gehören in `## + Hintergrund & Quellen`.

## Schritt 4 — Alle Template-Felder füllen
Fülle aus den in Schritt 3 abgeglichenen Daten **alle** Frontmatter-Felder, die
das gewählte Template vorgibt — übernimm Feldnamen und Reihenfolge exakt.
Typische Blöcke: `grunddaten_*`, `technik_*`, `markt`, `preise_*`, `handel`,
`lager`, `kompatibilität`, `wettbewerb`, `tags`.
Preise/Handel als `von`/`bis`-Zahlen über mehrere Stützmonate (Einführung →
Auslauf), so dass eine realistische Preiskurve entsteht. Übernimm nur Werte, die
den Abgleich aus Schritt 3 bestanden haben.

## Schritt 5 — Spiel-Inhalte (geschützte Abschnitte)
Fülle die `## +`-Abschnitte, die das Template vorgibt — verankert an den
recherchierten Daten. Beim CPU-Template z.B.:
- `## + Datenblatt` — kompaktes Datenblatt im Stil der Zeit (In-Game-Datenblatt).
- `## + Beschreibung` — neutrale Sachbeschreibung.
- `## + Zeitungsartikel` — kurzer Artikel im Ton eines deutschen
  Computermagazins der 1990er (z.B. c't/PC-Welt).
- `## + Werbung` — Werbetext/Anzeige im Stil der Zeit.
- `## + Hintergrund & Quellen` — Einordnung, Besonderheiten + Quell-Links.

Übernimm die `## +`-Überschriften so, wie sie im Template stehen. Die
erklärenden HTML-Kommentare und den `SKILL-ROUTING`-Block aus dem Template
**nicht** in die fertige Datei kopieren.

## Schritt 6 — Verlinken (nur bei neuer Komponente)
Wenn das Template eine `index_seite` nennt, ergänze dort einen `[[Wikilink]]`
auf die neue Datei, falls noch nicht vorhanden.

## Abschluss
Fasse zusammen: welches Template genutzt wurde, welche Quellen herangezogen
wurden, welche Felder gefüllt/geschätzt wurden und welche `## +`-Abschnitte
entstanden sind. Weise ausdrücklich auf Werte hin, bei denen sich die Quellen
widersprachen oder die nur einfach belegt sind.
