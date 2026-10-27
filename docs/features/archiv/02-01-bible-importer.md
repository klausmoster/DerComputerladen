---
feature_id: "02-01"
feature_name: "game_bible-Importer"
feature_system: "02 Produktdatenbank"
feature_status: "spezifiziert"
feature_phase: "plan"
godot_knoten:
- "ProductDatabase (Autoload, Node)"
godot_dateien:
- "src/data/product.gd (neu)"
- "src/data/product_database.gd (neu)"
- "src/data/products.json (generiert)"
- "docs/game_bible/export_products.py (neu)"
godot_signale_raus:
- "database_loaded(count: int)"
godot_signale_rein: []
lernen_ziele:
- "Custom Resource als typisierter Datencontainer"
- "JSON in Godot lesen und in Objekte überführen"
- "Autoload mit Ladezustand"
lernen_neue_konzepte:
- "JSON.parse_string() und Fehlerbehandlung"
- "res:// vs. user:// — wo Daten liegen dürfen"
- "static func als Factory (Product.from_dict)"
bezug_haengt_ab_von: []
bezug_blockiert:
- "03-01"
- "07-01"
- "08-01"
tags:
- feature
---
# 02-01 game_bible-Importer

## + Problem

Die Spieldaten liegen in der game_bible — recherchierte Komponenten mit
Preiskurven, Handelsmargen, Lager-Wertverlust und Kompatibilität. Die Engine
kennt davon **nichts**. `EventDatabase` verweist auf `"cpu_486"` und `"ram"`, aber
diese Strings zeigen ins Leere: Es gibt kein Produkt, keinen Preis, keinen
Bestand.

Solange diese Brücke fehlt, ist die Zeitleiste eine Ereignisanzeige ohne Wirkung,
und jedes Wirtschaftssystem müsste seine Daten neu erfinden.

## + Lösung

Die game_bible bleibt die einzige Quelle der Wahrheit — dort wird recherchiert,
dort steht das Frontmatter. Ein Exportschritt zieht daraus eine maschinenlesbare
Datei, die Godot beim Start einliest und in typisierte Produkt-Objekte überführt.

Danach kann jedes System fragen: „Was kostet ein Am386DX-40 im März 1993?" — und
bekommt eine Antwort aus recherchierten Daten statt aus einer erfundenen Formel.

Bewusst **zwei getrennte Schritte**, kein Live-Parsen: Obsidian-Dateien bleiben
für Menschen optimiert, die Engine bekommt etwas, das sie schnell und ohne
YAML-Parser lesen kann.

## + Technischer Vertrag

**`docs/game_bible/export_products.py`** (neu)

Liest rekursiv alle `.md` unter einem Pfad, überspringt Dateien mit `TEMPLATE`-
Präfix und solche ohne Frontmatter, und schreibt **eine** JSON-Datei:

```bash
python3 export_products.py CPUs --out ../../src/data/products.json
```

Ausgabeform — bewusst flach, das Frontmatter wird nicht umgedeutet:

```json
{
  "version": 1,
  "products": [
    {
      "id": "amd-am386dx-40",
      "name": "AMD Am386DX-40, 40MHz",
      "kategorie": "cpu",
      "quelle": "CPUs/AMD/AMD Am386DX-40, 40MHz.md",
      "frontmatter": { "...": "unveränderte Übernahme" }
    }
  ]
}
```

`id` wird aus dem Dateinamen abgeleitet (kleingeschrieben, kebab-case).
`kategorie` kommt aus dem ersten Eintrag in `tags`.

**`src/data/product.gd`** (neu) — `class_name Product extends Resource`

```gdscript
@export var id: String
@export var name: String
@export var kategorie: String
@export var grunddaten: Dictionary   # grunddaten_* ohne Präfix
@export var technik: Dictionary      # technik_* ohne Präfix
@export var markt: Array             # Liste wie im Frontmatter
@export var preise: Array            # [{ datum: String, von: int, bis: int }]
@export var handel: Array
@export var lager: Array

static func from_dict(data: Dictionary) -> Product
func preis_am(datum: String) -> Vector2i   # (von, bis); (0,0) wenn unbekannt
```

`preis_am()` liefert **nur exakte Treffer** auf einen `JJJJ-MM`-Stützpunkt.
Interpolation zwischen Stützpunkten ist ausdrücklich 03-01, nicht dieses Feature.

Die `kategorie_feld`-Präfixe aus dem Frontmatter werden beim Einlesen in
Dictionaries gruppiert — `technik_takt_mhz: 40` wird zu `technik["takt_mhz"] = 40`.
Das ist dieselbe Regel, nach der `regenerate_tables.py` seine Tabellen baut.

**`src/data/product_database.gd`** (neu) — Autoload `ProductDatabase`

```gdscript
signal database_loaded(count: int)

func load_from(path: String = "res://data/products.json") -> Error
func get_product(id: String) -> Product        # null wenn unbekannt
func by_kategorie(kategorie: String) -> Array[Product]
func all() -> Array[Product]
```

**Nicht dazu gehört:** Preisinterpolation über die Zeit (→ 03-01), Lagerbestände
(→ 07-01), das Verbinden mit `Timeline.effect_applied` (→ 03-01), Anzeige im
Spiel (→ 10-xx). Dieses Feature endet, wenn die Daten typisiert im Speicher
liegen.

## + Schritte

1. `[C]` Godot-Doku zu `JSON.parse_string()`, `Resource` und Autoload-Ladezeit
   zusammenfassen — was passiert wann beim Projektstart.
2. `[C]` `export_products.py` schreiben. Python, gleiche Machart wie
   `regenerate_tables.py`, und dort liegt schon der Frontmatter-Parser.
3. `[K]` `product.gd` anlegen: Felder definieren, `from_dict()` schreiben.
   Kern-Lernstück — Resource, typisierte Felder, static factory.
4. `[C]` Zehn Zeilen Beispielcode zum Ansehen, wie ein Dictionary mit
   Präfix-Keys in gruppierte Dictionaries zerlegt wird. Zum Lesen, nicht zum
   Übernehmen.
5. `[K]` `product_database.gd` als Autoload anlegen und in `project.godot`
   registrieren.
6. `[K]` `preis_am()` implementieren.
7. `[C]` Review gegen die Akzeptanzkriterien.

Aufteilung ist ein Vorschlag — Schritte wandern im Gespräch.

## + Akzeptanzkriterien

- `export_products.py CPUs` erzeugt eine JSON mit genau zwei Produkten (Stand
  heute: Am386DX-40 und Pentium 60); leere Index-Seiten wie `AMD.md` und
  `TEMPLATE_CPU.md` sind **nicht** enthalten.
- `ProductDatabase.get_product("amd-am386dx-40").technik["takt_mhz"]` liefert
  `40` als `int`, nicht als String.
- `by_kategorie("cpu")` liefert beide CPUs.
- `get_product("gibtsnicht")` liefert `null` und wirft keinen Fehler.
- `preis_am("1993-03")` auf dem Pentium 60 liefert die Werte aus dem
  Frontmatter; `preis_am("1993-04")` liefert `(0, 0)`, weil es dafür keinen
  Stützpunkt gibt — das ist kein Fehler, sondern die Abgrenzung zu 03-01.
- Projektstart bleibt fehlerfrei (headless, Exit 0).

## + Entscheidungen

**Export-Schritt statt YAML-Parsing in Godot.** Godot bringt keinen YAML-Parser
mit; einen in GDScript zu schreiben wäre viel Aufwand für ein gelöstes Problem.
Ein Python-Skript neben `regenerate_tables.py` passt zur bestehenden Machart und
kann dessen Frontmatter-Parser mitbenutzen.

**JSON statt generierter `.tres`-Dateien.** `.tres` wäre nativer, müsste aber aus
Python heraus in Godots eigenem Format geschrieben werden — fehleranfällig und
an die Engine-Version gebunden. JSON liest Godot mit einer Zeile, und die
Umwandlung in typisierte `Product`-Objekte passiert kontrolliert in GDScript.

**Frontmatter unverändert durchreichen.** Der Export deutet nichts um. Wenn ein
neues Template neue Felder bringt, landen sie automatisch in der JSON, ohne dass
das Exportskript angefasst werden muss — dieselbe Generik wie bei
`regenerate_tables.py`.

**Keine Interpolation hier.** Verlockend, weil die Daten danach schreien. Aber
Preiskurven sind ein eigenes Modell mit eigenen Fragen (linear? beschleunigt
durch Nachfolgeprodukte?) und gehören zu 03-01.

## + Offene Fragen

- **Wann läuft der Export?** Von Hand wie `regenerate_tables.py`, oder als
  Git-Hook? Von Hand ist ehrlicher, birgt aber die Gefahr, dass `products.json`
  und game_bible auseinanderlaufen. Ein `version`-Feld und ein Zeitstempel in der
  JSON würden das wenigstens sichtbar machen.
- **Gehört `products.json` ins Repo?** Sie ist generiert, also nach der
  Drei-Kategorien-Regel „Ableitung" — aber ohne sie startet das Spiel nicht, und
  ein Godot-Export braucht sie unter `res://`. Vermutlich committen und als
  bewusste Ausnahme dokumentieren.
- **`id`-Ableitung aus dem Dateinamen** bricht, wenn eine Datei umbenannt wird.
  Ein explizites `grunddaten_id` im Frontmatter wäre stabiler — würde aber das
  CPU-Template ändern, und das ist laut Konvention die Autorität. Vor dem Bauen
  entscheiden.
- **Die Brücke zu den `target`-Strings der Timeline fehlt weiterhin.**
  `"cpu_386"` ist keine Produkt-`id`, sondern eine Warengruppe. Es braucht eine
  Zuordnung Gruppe → Produkte. Möglicherweise über `tags` im Frontmatter, aber
  das ist noch nicht durchdacht — gehört zu 03-01.

## + Lernnotizen

<!-- Wird beim Bauen gefüllt. -->
