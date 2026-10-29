# Architektur von Godot-Spielen – Quellen für den Leitfaden

Stand 2026-10-28. Reine Recherche, nichts gebaut. Für Klaus und Feature 008.

Gelesen wurden: die Godot-Doku 4.7 (Abschnitt „Best practices“ und zwei Seiten daneben), Robert
Nystroms „Game Programming Patterns“, Ron Gilberts Blogs zu Thimbleweed Park und Grumpy Gamer, ein
Interview zu SCUMM, Factorio Friday Facts (FFF) und zwei Community-Quellen zu „Call down, signal
up“. Zitate stehen in Anführungszeichen und sind kürzer als 15 Wörter, je Quelle höchstens eins.
Alles andere ist in eigenen Worten zusammengefasst.

## Kurz

Die Godot-Doku stützt vier der fünf Prinzipien, ist aber an zwei Stellen weicher als wir. Bei
Autoloads empfiehlt sie diese ausdrücklich für Systeme, die nur ihre eigenen Daten verwalten (ihr
Beispiel: Quest- oder Dialogsystem), und warnt nur vor Autoloads, die fremde Daten ändern. „Kern
ohne Node“ kennt die Doku nicht als Regel. Sie behandelt Szenen und Skripte als Klassen und nennt
RefCounted für eigene Datenklassen, verlangt aber nicht, dass Logik aus Nodes herausgehalten wird.
Den Merksatz „Call down, signal up“ führt die offizielle Doku nicht, er stammt aus der Community
(KidsCanCode); die Doku sagt dasselbe in anderen Worten und betont, dass der Elternknoten seinen
Kindern die Abhängigkeiten gibt. Für Spielstände empfiehlt die Doku JSON oder Binärdaten, nicht
Resources. „Daten als Resources“ sollte deshalb auf gepflegte Spieldaten zielen, nicht auf
Spielstände. Von Nystroms 19 Mustern sind für uns sofort wichtig: Befehl, Beobachter, Zustand,
Typ-Objekt, Spielschleife und Komponente; Singleton und Service Locator nur als Warnung. Gilbert
und Factorio liefern je ein Kernprinzip: Engine und Spielinhalt strikt trennen (Gilbert) und eine
Simulation, die aus gleichem Start und gleichen Eingriffen immer dasselbe ergibt (Factorio).

---

## 1. Godot-Doku 4.7, „Best practices“

Die Seiten unter `/en/stable/` tragen den Kopf „Godot Engine 4.7 documentation“; eine eigene
Adresse `/en/4.7/` wurde nicht gebraucht. Übersicht des Abschnitts:
https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html

Kürzel der Prinzipien: **K** Kern ohne Node, **S** Signal nach oben, Aufruf nach unten, **A**
Autoloads sparsam, **R** Daten als Resources, **Z** Szenen-Komposition.

### 1.1 Introduction

https://docs.godotengine.org/en/stable/tutorials/best_practices/introduction_best_practices.html

- Allgemein: Godot erlaubt viele Wege; die Reihe geht je Artikel von einem echten Problem aus und
  empfiehlt eine Lösung. Grundlage sind objektorientierte Prinzipien.
- Zu K, S, A, R, Z: nichts Eigenes.

### 1.2 Applying object-oriented principles in Godot

https://docs.godotengine.org/en/stable/tutorials/best_practices/what_are_godot_classes.html

- **K:** Ein Skript ohne `extends` erbt von RefCounted und lässt sich darum an keinen Node hängen.
  Das ist genau die Form unserer Kern-Klassen. Die Seite sagt aber nicht, dass Logik dorthin
  gehört; sie behandelt Skript plus Szene als *eine* Klasse.
- **Z:** Eine Szene ist eine wiederverwendbare, instanzierbare Gruppe von Nodes, vergleichbar
  einer Klasse; Einzelverantwortung und Kapselung gelten auch für Szenen.
- **S, A, R:** nichts Eigenes.
- Relativiert K: Die Doku sieht Logik im Root-Skript einer Szene als Normalfall. Unser Prinzip ist
  strenger – das muss der Leitfaden als eigene Entscheidung kennzeichnen.

### 1.3 Scene organization

https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html

- **Z:** Szenen sollen ohne äußere Abhängigkeiten auskommen, „because scenes operate best when they
  operate alone“. Kinder nur dann unter einen Elternknoten, wenn sie mit ihm entfernt werden
  sollen; Baum relational denken, nicht räumlich. Vorschlag für den Aufbau: `Main` als Einstieg,
  darunter `World` und eine GUI auf Control-Basis; Teilsysteme bekommen eigene Äste.
- **S:** Signale zum *Reagieren* auf Verhalten (sicherste Variante), Methodenaufruf zum *Auslösen*.
  Der Elternknoten versorgt das Kind mit dem, was es braucht – fünf Wege: Signal verbinden,
  Methodenname setzen, Callable setzen, Objektreferenz setzen, NodePath setzen. Geschwister reden
  über den gemeinsamen Vorfahren. Der Merksatz „call down, signal up“ fällt nicht.
- **A:** Autoloads passen für Systeme, die ihre eigenen Daten verwalten, global erreichbar sein
  müssen und für sich allein bestehen. Systeme, die Daten anderer ändern, gehören in Szenen oder
  Skripte. Für kleine Spiele reicht ein einfacher „Game“-Singleton, der mit
  `change_scene_to_file()` die Hauptszene tauscht.
- **K, R:** nicht behandelt.
- Zusatz: Abhängige Nodes können als Tool-Skript Konfigurationswarnungen im Editor zeigen – die
  Szene dokumentiert dann selbst, was sie braucht.

### 1.4 When to use scenes versus scripts

https://docs.godotengine.org/en/stable/tutorials/best_practices/scenes_versus_scripts.html

- **Z:** Szenen deklarieren einen Baum von Nodes, Skripte geben Verhalten. Für spielspezifische
  Begriffe eine Szene, für wiederverwendbare Werkzeuge ein Skript mit `class_name` und Symbol.
  Große Hierarchien aus Code zu bauen ist langsamer als eine Szene zu instanzieren. Begründung:
  „Scenes are easier to track/edit and provide more security than scripts.“
- **K:** Ein Skript mit `class_name` kann eine Szene als Konstante halten und so als Namensraum
  dienen. Sonst nichts zu Kernen.
- **S, A, R:** nichts Eigenes.

### 1.5 Autoloads versus regular nodes

https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_regular_nodes.html

- **A:** Die Kernseite für unser Prinzip. Am Beispiel eines globalen `Sound`-Managers mit Pool
  nennt sie drei Probleme: globaler Zustand (ein Objekt hält Daten für alle, fällt es aus, leiden
  alle), globaler Zugriff (jeder Code kann falsche Daten schicken, Fehlersuche im ganzen Projekt),
  globale Ressourcenverteilung (Pool zu klein oder zu groß). Zustand gehört lokal in die Szene.
- **A, weicher als wir:** Für umfassende Systeme, die nur ihre eigenen Daten verwalten und keine
  fremden ändern, hält die Seite Autoloads ausdrücklich für richtig – Beispiele Quest- und
  Dialogsystem. Klarstellung: „An autoload is *not* necessarily a singleton.“ Es ist nur ein Node,
  der beim Start unter die Wurzel gehängt wird und Szenenwechsel überlebt.
- **R:** Für geteilte Daten empfiehlt sie eine eigene Resource statt eines Autoloads.
- **K:** Alternativen ohne Instanz: `static func` mit `class_name` (Hilfsbibliothek) und seit 4.1
  `static var` (von allen Instanzen einer Klasse geteilt). RefCounted wird nicht erwähnt.
- **Z:** Wiederverwendbares Verhalten als eigener Node-Typ mit `class_name`; Daten, die eine Szene
  besitzt, am Root der Szene ablegen und über `owner` erreichen.
- **S:** Signale werden nur am Rand als Mittel gegen globalen Zustand genannt.

### 1.6 When and how to avoid using nodes for everything

https://docs.godotengine.org/en/stable/tutorials/best_practices/node_alternatives.html

- **K:** Die wichtigste Stütze. Drei leichtere Bausteine als Node:
  - *Object*: am leichtesten, aber manuell freizugeben; Referenzen können ungültig werden.
  - *RefCounted*: gibt sich selbst frei, sobald keiner mehr darauf zeigt; laut Seite die Wahl für
    die meisten eigenen Datenklassen. Beispiel im Spiel: `TimelineRun` als Fahrplan ohne Node.
  - *Resource*: wie RefCounted, kann aber gespeichert, geladen und im Inspector bearbeitet werden;
    verhält sich fast wie ein Unter-Node und ist bei vielen Exemplaren günstiger.
- **R:** Resource für Daten, die gespeichert, geladen oder im Inspector gepflegt werden sollen.
- **S, A, Z:** nicht behandelt. Leistungszahlen nennt die Seite nicht.

### 1.7 Godot interfaces

https://docs.godotengine.org/en/stable/tutorials/best_practices/godot_interfaces.html

- **S:** Abhängigkeiten von außen zuweisen lassen und im Kind prüfen (stilles Zurückkehren,
  Fehlermeldung oder `assert`). Ein Kind kann ein Callable vom Elternknoten halten – das hält die
  Abhängigkeit minimal. Zugriffsreihenfolge: `@onready`-Variable ist am schnellsten, `get_node()`
  am langsamsten. Eindeutige Namen (`%Name`) behandelt die Seite nicht.
- **A:** Im Beispielcode steht als Kommentar zum Autoload: „Dangerous for typical nodes, but useful
  for true singleton nodes“ – gemeint sind solche, die ihre eigenen Daten verwalten.
- **R:** Resources werden beim Laden gecacht und geteilt. Wer eine unabhängige Kopie braucht,
  nimmt `duplicate()` oder `new()`. Beispiel: Zwei Regale mit derselben Produkt-Resource dürfen
  den Lagerbestand nicht in der Resource zählen, sonst zählen beide denselben Wert.
- **Z:** Gruppen und Namen als informelle Schnittstellen, die man dokumentieren muss.
- **K:** Zugriff über Eigenschaften und Methoden funktioniert für jedes Object, auch RefCounted.

### 1.8 Data preferences

https://docs.godotengine.org/en/stable/tutorials/best_practices/data_preferences.html

- **K:** Eigene Datenstrukturen (Bäume, Listen, Graphen) aus Object bauen, nicht aus Node, weil
  Node viel Ballast mitbringt. Die Seite spricht noch von „Reference“ (Godot-3-Name von
  RefCounted) und ist an dieser Stelle veraltet.
- **R:** Array (schnell beim Durchlaufen), Dictionary (schnell per Schlüssel), Object (teurer, aber
  mit Schnittstelle, Signalen, verlässlichen Eigenschaften). Enums als int sind schneller, als
  String druckbar. Resources als allgemeine Datenbehälter behandelt die Seite nicht.
- **S, A, Z:** nicht behandelt.

### 1.9 Logic preferences

https://docs.godotengine.org/en/stable/tutorials/best_practices/logic_preferences.html

- **Z:** Startwerte setzen, *bevor* ein Node in den Baum kommt (manche Setter sind teuer). Große
  Szenen in kleinere zerlegen, auch bei statischen Leveln.
- **R:** `preload` für Konstanten, die sich nicht ändern; Eigenschaften für austauschbare
  Resources. Eine Resource in einer Eigenschaft lässt sich mit `null` freigeben, eine Konstante
  nicht.
- **K, S, A:** Wo Logik leben soll, sagt die Seite trotz des Titels nicht.

### 1.10 Using signals (Einstieg „Step by step“)

https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html

- **S:** Signale sind Godots Form des Beobachter-Musters und verweisen auf Nystroms Buch. Kernsatz:
  „Using signals limits coupling and keeps your code flexible.“ Eine Richtungsregel (Kind meldet
  nach oben) gibt es nicht; im Beispiel verbindet der Empfänger. Verbinden im Code wird empfohlen,
  wenn Szenen per Skript instanziert werden.

### 1.11 Resources

https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html

- **R:** Resources sind Datenbehälter, die selbst nichts tun; Nodes nutzen sie. Eigene Resource:
  Skript `extends Resource`, Felder mit `@export`, Werte im Inspector, gespeichert als `.tres`
  (Text, gut für Git). Vorteile gegenüber JSON/CSV: Konstanten, Methoden, Signale, feste
  Eigenschaften, verschachtelte Unter-Resources, kein eigener Parser. Warnung: Innere Klassen
  speichern ihre Felder nicht richtig, weil die Datei den Skriptpfad ablegt.
- `local_to_scene`, `duplicate()`, Spielstände und Sicherheit beim Laden fremder Dateien
  behandelt die Seite nicht.

### 1.12 Saving games (zur Abgrenzung von R)

https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

- **R, weicher als wir:** Für Spielstände empfiehlt die Doku JSON (einfach, lesbar) oder binäre
  Serialisierung (`store_var`/`get_var`) – Resources werden nicht erwähnt. Eine Warnung vor dem
  Laden fremder Dateien steht auf dieser Seite nicht (nicht gefunden).

### 1.13 Was die Doku für die fünf Prinzipien ergibt

| Prinzip | Stützt die Doku es? | Wo sie anders oder weicher ist |
|---|---|---|
| K Kern ohne Node | ja, als Werkzeug (1.6, 1.2) | keine Pflicht; Logik im Szenen-Skript gilt als normal |
| S Signal hoch, Aufruf runter | ja, sinngemäß (1.3, 1.7) | Merksatz fehlt; Schwerpunkt ist „Elternteil gibt Abhängigkeiten“ |
| A Autoloads sparsam | ja (1.5, 1.7) | empfiehlt Autoloads für Systeme mit eigenen Daten |
| R Daten als Resources | ja für gepflegte Daten (1.6, 1.11) | Spielstände eher JSON/Binär (1.12) |
| Z Szenen-Komposition | ja, deutlich (1.3, 1.4) | – |

Bezug zum Projekt: `Timeline` meldet nur und ändert keine fremden Daten – das ist genau die Art
Autoload, die die Doku billigt. `event_catalog.json` ist gepflegte Spieldaten als JSON, nicht als
Resource; der Leitfaden muss entscheiden, ob das eine Ausnahme bleibt.

---

## 2. Nystrom, „Game Programming Patterns“

Übersicht: https://gameprogrammingpatterns.com/contents.html – Kapitel-URL jeweils
`https://gameprogrammingpatterns.com/<name>.html`. Ausgewertet im Volltext: Command, Observer,
Singleton, Game Loop, Type Object, Event Queue, Service Locator. Die übrigen Zeilen fassen die
Kapitel nach Titel und Absicht zusammen; dort ist die Einschätzung weniger belegt.

Relevanz: **ja** = jetzt im Leitfaden, **später** = erst mit einem bestimmten System, **nein** =
für ein Spiel dieser Größe ohne Nutzen.

| Muster | Kern in einem Satz | Godot-Entsprechung | Relevanz |
|---|---|---|---|
| Command (`command`) | Ein Aufruf wird zum Datenobjekt, das man speichern, wiederholen oder rückgängig machen kann. | Eigene RefCounted-Klasse je Eingriff; kein eingebautes Gegenstück | **ja**: Jeder Spielereingriff („Preis für 486DX-33 auf 2.499 DM“) als Befehl ergibt Spielstand = Seed + Eingriffe und Wiederholungen |
| Flyweight (`flyweight`) | Viele Objekte teilen sich unveränderliche Daten statt eigener Kopien. | Resources werden beim Laden geteilt (1.7) | **ja**, nebenbei: Produktdaten einmal laden; Bestand nicht in die geteilte Resource |
| Observer (`observer`) | Ein Subjekt meldet ein Ereignis, ohne zu wissen, wer zuhört. | Signale | **ja**: Grundlage von S; Timeline meldet `event_fired` |
| Prototype (`prototype`) | Neue Objekte entstehen als Kopie eines Musterobjekts. | `Resource.duplicate()`, `PackedScene.instantiate()` | **später**: z.B. Kundentypen aus Vorlage; Gilberts Pseudo-Räume (Abschnitt 3) sind dieses Muster |
| Singleton (`singleton`) | Genau eine Instanz mit globalem Zugriff. | Autoload (ist laut Doku aber kein echtes Singleton) | **nur als Warnung**, siehe unten |
| State (`state`) | Ein Objekt wechselt sein Verhalten je nach Zustand, jeder Zustand ist eine eigene Einheit. | Zustandsklassen als RefCounted oder Nodes; `match` auf Enum für Einfaches | **ja**: Kunde (betritt Laden, wartet, verhandelt, geht), Seiten des Communicators |
| Double Buffer (`double-buffer`) | Lesen aus dem alten, Schreiben in den neuen Zustand, dann tauschen. | Kein Gegenstück; Grafik puffert Godot selbst | **später**: nur wenn ein Tagesabschluss alle Händler gleichzeitig auf Vortagswerte reagieren lässt |
| Game Loop (`game-loop`) | Die Schleife entkoppelt Spielzeit von Echtzeit und Rechnergeschwindigkeit. | `_process` (je Bild) und `_physics_process` (fester Takt) | **ja**: Die Simulation braucht einen festen Schritt (Tag), unabhängig von der Bildrate |
| Update Method (`update-method`) | Jedes Objekt bekommt je Schritt einen Aufruf, um sich fortzuschreiben. | `_process` je Node | **ja, eingeschränkt**: Kernobjekte bekommen `advance_day()` vom Takt, nicht je Bild ein `_process` |
| Bytecode (`bytecode`) | Verhalten als Daten in einer kleinen virtuellen Maschine. | GDScript selbst; `Expression` | **nein**: keine eigene Skriptsprache; GDScript reicht |
| Subclass Sandbox (`subclass-sandbox`) | Eine Basisklasse bietet geschützte Bausteine, Unterklassen bauen daraus Verhalten. | Basisskript mit Hilfsfunktionen, `extends` | **später**: Raum- oder Hotspot-Skripte im Adventure-Teil |
| Type Object (`type-object`) | Ein „Typ“ ist ein Datenobjekt, nicht eine eigene Klasse. | Eigene Resource je Typ (`.tres`) | **ja**: Ein Produkt wie „486DX-33“ ist eine Datenzeile, keine Klasse; ebenso Ereignisse im Katalog |
| Component (`component`) | Ein Objekt setzt sich aus unabhängigen Teilen je Bereich zusammen. | Kind-Nodes, Szenen-Komposition | **ja**: Grundlage von Z |
| Event Queue (`event-queue`) | Senden und Verarbeiten werden zeitlich getrennt. | `call_deferred`, `CONNECT_DEFERRED`, eigene Warteschlange | **später/vorsichtig**: Ereignisse des Tages sammeln und am Tagesende abarbeiten; zentrale Queue wirkt wie ein globales Objekt |
| Service Locator (`service-locator`) | Ein globaler Zugang zu einem Dienst, ohne seine Klasse zu kennen. | Autoload als Zugang, austauschbare Implementierung | **nur als Warnung**; höchstens für Ton oder Protokoll |
| Data Locality (`data-locality`) | Daten so im Speicher anordnen, dass der Cache sie gut trifft. | `PackedArray`-Typen | **nein**: Ein Laden mit hunderten Produkten ist kein Engpass |
| Dirty Flag (`dirty-flag`) | Abgeleitete Werte erst neu berechnen, wenn sich die Grundlage geändert hat. | eigene Bool-Variable, Setter | **später**: z.B. Bilanzansicht; Vorsicht wegen Factorio FFF #340 (Abschnitt 4) |
| Object Pool (`object-pool`) | Objekte wiederverwenden statt neu anlegen. | kein Gegenstück; die Doku rät beim Sound-Pool ab (1.5) | **nein** |
| Spatial Partition (`spatial-partition`) | Objekte nach Ort ordnen, um Nachbarn schnell zu finden. | Physik-Server, `NavigationServer` | **nein**: Räume sind klein, Godot übernimmt Kollision |

### 2.1 Was Nystrom gegen Singletons sagt

https://gameprogrammingpatterns.com/singleton.html

Sein Urteil: Das Muster aus dem Gang-of-Four-Buch „usually does more harm than good“. Gründe:

- Es ist eine globale Variable in Klassenform; globaler Zustand macht Code schwer zu verstehen.
- Es koppelt alles an alles: Weil jeder es erreicht, verflechten sich fremde Systeme.
- Es ist schlecht für Nebenläufigkeit (gemeinsamer Speicher).
- Faule Initialisierung nimmt die Kontrolle über den Zeitpunkt; teurer Aufbau mitten im Spiel.
- Es bündelt zwei Dinge – „genau eins“ und „überall erreichbar“ –, und meist will man nur das
  zweite, bekommt aber das erste an jeder Aufrufstelle fest eingebaut.

Seine Alternativen, in dieser Reihenfolge: Braucht es die Klasse überhaupt (viele „Manager“
gehören in die Objekte, die sie verwalten)? Die Abhängigkeit hineinreichen. Über eine Basisklasse
holen. Über etwas ohnehin Globales holen (ein `Game`-Objekt, das die Systeme besitzt). Erst
danach Service Locator. Für „nur eine Instanz“ reicht ihm eine statische Klasse.

Übertragen: Ein `LagerManager`-Autoload wäre genau das, wovor Nystrom warnt. Besser: Das Lager ist
ein Kern-Objekt, das `GameSession` besitzt und Szenen hineingereicht bekommen.

### 2.2 Weitere Kernaussagen

- **Observer**, https://gameprogrammingpatterns.com/observer.html: Signale sind synchron – der
  Sender wartet, bis alle Empfänger fertig sind. Gefahr „vergessener Zuhörer“: eine verdeckte
  Seite empfängt weiter. Nicht nehmen, wenn man beide Seiten zugleich verstehen muss; innerhalb
  eines Features ist ein direkter Aufruf klarer.
- **Event Queue**, https://gameprogrammingpatterns.com/event-queue.html: „Decouple when a message or
  event is sent from when it is processed.“ Risiken: Rückkopplungen, veralteter Zustand (Daten in
  das Ereignis kopieren), zentraler Bus als globale Variable. Das trifft auch GDQuests Event-Bus
  (Abschnitt 6).
- **Service Locator**, https://gameprogrammingpatterns.com/service-locator.html: sparsam; nur für
  Dinge, die von Natur aus einmalig sind und viele Systeme berühren (Ton, Protokoll). Ein
  „Null-Dienst“ statt `null` verhindert Abstürze durch Startreihenfolge.
- **Command**, https://gameprogrammingpatterns.com/command.html: Undo ist mit Befehlen leicht,
  ohne schwer. Für Wiederholungen speichert man nicht jeden Zustand, sondern die Befehle je
  Schritt und rechnet die Simulation neu.
- **Game Loop**, https://gameprogrammingpatterns.com/game-loop.html: Ein variabler Zeitschritt
  macht das Spiel nicht deterministisch; ein fester Schritt hält es stabil und Fehler
  nachstellbar. Variante „fester Update, variables Rendern“ mit Akkumulator.
- **Type Object**, https://gameprogrammingpatterns.com/type-object.html: Typen kommen aus Daten,
  Designer ändern sie ohne Code; Typen können von einem Eltern-Typ erben. Schwäche:
  typspezifisches *Verhalten* ist schwer – dann aus festen Verhaltensbausteinen wählen.

---

## 3. SCUMM und Thimbleweed Park (Ron Gilbert)

### 3.1 Quellen

| Datum | Titel | URL | Inhalt kurz |
|---|---|---|---|
| 2013-07-12 | The SCUMM Diary (Interview mit Aric Wilmunder) | https://www.gamedeveloper.com/design/the-scumm-diary-stories-behind-one-of-the-greatest-game-engines-ever-made | SCUMM-Aufbau, Werkzeuge |
| 2014-08-05 | SCUMM Notes From The C64 | https://grumpygamer.com/scumm_notes/ | nur Bilder alter Notizen; Text nicht auswertbar |
| 2014-08-10 | Puzzle Dependency Charts | https://grumpygamer.com/puzzle_dependency_charts/ | Rätselplanung |
| 2015-01-05 | Engine | https://blog.thimbleweedpark.com/engine.html | Trennung Engine/Spiel |
| 2015-01-20 | Scripting Test | https://blog.thimbleweedpark.com/scripting_test.html | Squirrel, Skripte als Threads |
| 2015-03-16 | Wimpy | https://blog.thimbleweedpark.com/wimpy.html | Raumeditor, JSON |
| 2015-03-20 | Your Kickstarter Dollars At Work! | https://blog.thimbleweedpark.com/debugger.html | Debug-Konsole |
| 2015-06-30 | Dialog Puzzles | https://blog.thimbleweedpark.com/dialog_puzzles.html | Dialoge als Text |
| 2015-10-19 | Save Game | https://blog.thimbleweedpark.com/savegame.html | Spielstände |
| 2016-01-05 | Pseudo Rooms | https://blog.thimbleweedpark.com/pseudorooms.html | Räume aus Vorlage |
| 2020-03-22 | Lock-down in Seattle | https://grumpygamer.com/lock_down/ | Dinky, Oberfläche ins Skript |
| 2020-05-25 | Delores Dev | https://grumpygamer.com/delores_dev/ | Spielquellen veröffentlicht |

Weitere Titel im Archiv, nicht gelesen: „Switching And Inventory“, „Thoughts On Props“, „Walk
Boxes!“, „Scrolling Rooms“ (Liste: https://blog.thimbleweedpark.com/archives.html).

### 3.2 Was Gilbert über den Aufbau sagt

- **Engine und Spielinhalt strikt getrennt.** Die Engine ist C/C++, das Spiel steht in Skripten;
  Skriptschreiber sollen keinen Zugriff auf Engine-Code haben. Kernsatz: „keep the engine world
  and the game world very separate“ (Engine, 2015). Belege dafür: Bei Delores veröffentlichte er
  den ganzen Spielcode, die Engine aber nicht (Delores Dev, 2020). Assets und Engine liegen in
  getrennten Repositories (debugger.html). Schon bei SCUMM war der Interpreter so gebaut, dass er
  keine spielspezifische Logik enthält; Reste wie Textfarben der Figuren wanderten später in
  Skriptbefehle (SCUMM Diary).
- **Oberfläche ins Skript.** Bei Maniac Mansion war die Oberfläche noch Maschinencode und zog über
  die Jahre in SCUMM-Skripte; 2020 zog Gilbert die Oberfläche von Thimbleweed Park vollständig aus
  der Engine in seine neue Sprache Dinky (Lock-down in Seattle).
- **Skripte laufen nebeneinander, ohne Zustandsautomat.** Jedes Skript läuft je Bild bis
  `breakhere()`, dann kommt das nächste – kooperativ, keine echten Threads. `breaktime(t)` wartet
  Sekunden, `startthread`/`stopthread` starten und beenden Skripte (Scripting Test). SCUMM hatte
  dasselbe mit Befehlen zum Schlafen und zum Warten auf eine Figur, damit Designer linear schreiben
  konnten (SCUMM Diary).
- **Squirrel statt eigener Sprache.** Gewählt wegen C-artiger Syntax und weil es leicht zu ändern
  war; eine eigene Sprache hätte rund einen Monat gekostet (Engine; Scripting Test). Später
  ersetzte Gilbert Squirrel durch Dinky, zu etwa 90 % kompatibel (Lock-down in Seattle).
- **Räume und Objekte als Daten.** Ein Raum ist eine JSON-Datei mit Hintergrund, Spritesheet und
  Objekten; ein Objekt hat Hotspot-Rechteck, Position, Benutzungsposition mit Blickrichtung,
  Z-Reihenfolge, Animationszustände und kann bloße Kulisse („Prop“) sein. Die Engine lädt sie und
  verknüpft jedes Objekt per Name mit seinem Code-Objekt (Wimpy). Bei SCUMM verwaltete der
  Raumeditor FLEM Objekte, Zustände, Laufflächen und Verdeckungsebenen (SCUMM Diary).
- **Pseudo-Räume.** Ein Raum dient als Vorlage, die Engine kopiert ihn zur Laufzeit; jede Kopie
  hat eigenen Zustand. So entstehen die Hotelzimmer, ohne 110 Räume zu bauen (Pseudo Rooms).
- **Verben und Figuren.** SCUMM hatte zuerst eine Verbleiste (Gehe zu, Nimm, Schau an), später
  Symbole; Figuren wurden mit eigenen Werkzeugen animiert (SCUMM Diary). Gilberts eigene Texte
  zum Verbsystem von Thimbleweed Park: nicht gefunden.
- **Dialoge als reiner Text.** Eigenes Textformat: benannte Knoten, Sprecherzeilen, nummerierte
  Antworten mit Sprung zum Zielknoten, Zusätze wie `[once]`/`[showonce]`, Variablen setzen und
  Bedingungen in Klammern. Gilbert will keine Klick-Werkzeuge für Dialogbäume (Dialog Puzzles).
  Der Name „Yack“ für das Format steht nur in Foren und Fremdprojekten, nicht in einem
  Gilbert-Text (nicht gefunden).
- **Spielstände ohne laufende Skripte.** Gespeichert werden globale Spielvariablen (gesammelt in
  einer Tabelle `g`), Variablen je Raum und Figur sowie Position, Blickrichtung und Anklickbarkeit.
  Laufende Skripte lassen sich nicht speichern: Lokale werden beim Betreten des Raums neu
  gestartet, Ton ebenfalls. Vor Zwischensequenzen und Dialogen wird still gespeichert, mittendrin
  nicht. Bezüge werden per Name gespeichert, nicht per Laufzeit-ID. Neue Versionen müssen alte
  Spielstände laden können, aber nicht umgekehrt (Save Game).
- **Werkzeuge sind Teil der Architektur.** Wimpy ist ein eigenes Programm, nutzt aber den Lade-
  und Zeichencode der Engine, damit die Vorschau stimmt; Bearbeiten im laufenden Spiel lehnte
  Gilbert ab (Wimpy). Die Debug-Konsole liest und setzt jede Variable und führt Skriptzeilen aus,
  auch aus Dateien für Testlagen (debugger.html). SCUMM hatte eine ganze Werkzeugkette:
  Compiler, Entwicklungs-Interpreter, Raum-, Schrift- und Animationseditor (SCUMM Diary).
- **Rätsel planen.** Rätselabhängigkeitsdiagramme zeigen, was wovon abhängt, nicht die Reihenfolge;
  Akte enden in einem Engpass (Puzzle Dependency Charts).

### 3.3 Was auf Godot übertragbar ist

- *Trennung Engine/Inhalt* → In Godot ist die Engine schon getrennt. Die eigene Schicht darüber
  (Adventure-Kern: Raum, Hotspot, Verb, Dialog) sollte keinen Text, kein Rätsel und keinen
  Ladeninhalt kennen. Beispiel: Der Kern weiß, wie „Benutze Diskette mit Laufwerk“ geprüft wird,
  aber nicht, dass es im Lager eine Diskette gibt.
- *Räume als Daten* → Raum als Szene (Hintergrund, Hotspots als `Area2D` oder Control) plus eine
  Resource je Objekt (Name, Beschreibung, Benutzungspunkt, Zustände). Wimpy entspricht dem
  Godot-Editor selbst – kein eigenes Werkzeug nötig.
- *Skripte als Coroutinen* → GDScript hat `await` (auf Signal oder Timer); damit lassen sich
  Abläufe linear schreiben wie mit `breakhere`. Vorsicht wie bei Gilbert: Laufende `await`-Ketten
  lassen sich nicht speichern – also speichern nur an Ruhepunkten (vor Dialog, vor
  Zwischensequenz).
- *Dialoge als Text* → eigenes einfaches Textformat oder Resource je Knoten; Bedingungen lesen
  Spielvariablen, setzen sie aber über einen klaren Zugang.
- *Pseudo-Räume* → Szene einmal bauen, mehrfach instanzieren, Zustand je Instanz in einer
  duplizierten Resource (Prototyp-Muster).
- *Spielstand per Name, rückwärtskompatibel* → passt zu `SaveGame` mit Formatversion.
- *Debug-Konsole* → später als `[A]`-Werkzeug denkbar; nicht Teil von 008.

---

## 4. Factorio, Friday Facts

### 4.1 Quellen

| FFF | URL | Inhalt kurz |
|---|---|---|
| #36 | https://www.factorio.com/blog/post/fff-36 | Wiederholungen weichen auf anderem Betriebssystem ab; Ursache Winkelfunktionen |
| #47 | https://www.factorio.com/blog/post/fff-47 | Prüfsumme (CRC) der Karte je Tick, Wiederholung vergleicht |
| #70 | https://www.factorio.com/blog/post/fff-70 | Logik und Zeichnen getrennt; 60 Updates/s auch bei 40 Bildern/s |
| #76 | https://www.factorio.com/blog/post/fff-76 | Mehrspieler im Gleichschritt: nur Eingaben werden gesendet |
| #108 | https://www.factorio.com/blog/post/fff-108 | Zahlenformatierung unterscheidet sich je Compiler und bricht Gleichlauf |
| #188 | https://factorio.com/blog/post/fff-188 | Was ein Desync ist, Desync-Berichte |
| #315 | https://www.factorio.com/blog/post/fff-315 | Testlauf „heavy mode“: speichern, laden, CRC vergleichen – jeden Tick |
| #340 | https://www.factorio.com/blog/post/fff-340 | Tiefe Desyncs: nicht gespeicherter Cache, Reihenfolge beim Serialisieren |
| Wiki | https://wiki.factorio.com/Game-tick | Tick = 1/60 s, UPS |

### 4.2 Was dort steht

- **Gleichschritt (lockstep):** Jeder Rechner simuliert die ganze Welt; übers Netz gehen nur die
  Aktionen der Spieler. Weicht ein Rechner minimal ab, laufen die Welten auseinander – der Desync
  (#76, #188). Kernsatz aus #188: „a desynchronization (desync) occurs“, sobald ein Rechner nur
  ein wenig anders rechnet.
- **Fester Tick:** Ein Tick ist die Grundeinheit der Spielzeit, normal 60 je Sekunde (Wiki). Ist
  ein Update zu teuer, wird das Spiel langsamer, aber kein Tick übersprungen (#70).
- **Simulation und Darstellung getrennt:** Logik und Zeichnen laufen getrennt; fällt das Zeichnen
  auf 40 Bilder je Sekunde, rechnet die Simulation weiter 60 Ticks (#70).
- **Was den Gleichlauf bricht:** Winkelfunktionen der C++-Bibliothek liefern je Plattform andere
  Ergebnisse – eigene Implementierung nötig (#36). Zahlen werden je Compiler anders formatiert
  (#108). Ein Cache, der nicht gespeichert, sondern beim Laden neu berechnet wird, ergibt unter
  anderen Bedingungen einen anderen Wert; eine Reihenfolge beim Serialisieren, die vom Zufall der
  Hash-Tabelle abhängt, ebenso (#340).
- **Werkzeuge:** Prüfsumme der ganzen Karte je Tick; beim Wiederholen weicht sie im ersten falschen
  Tick ab, der Unterschied ist meist ein einziger Wert (#47). Desync-Berichte enthalten beide
  Zustände zum Vergleich (#188). Die Testsuite speichert und lädt in jedem Tick und vergleicht die
  Prüfsumme; das läuft nach jedem Commit (#315).
- **Wiederholungen:** Dass sie nur mit Determinismus gehen, sagt ein Forenbeitrag zu #340, nicht
  der Text selbst. Wie Factorio Wiederholungen aufzeichnet (Eingaben oder Spielstand), steht in
  #36 und #47 nicht (nicht gefunden).

### 4.3 Was auf eine Einzelspieler-Wirtschaftssim übertragbar ist

Unser Fall ist einfacher: ein Spieler, kein Netz, kein Gleichschritt. Übertragbar ist der Kern:
**Gleicher Seed + gleiche Eingriffe = gleicher Spielverlauf.** Dann besteht ein Spielstand
grundsätzlich aus Seed, Grad und der Liste der Eingriffe – so wie `GameSession` heute schon den
Fahrplan bis zum gespeicherten Tag nachspielt.

- *Fester Tick* → Der Tag (oder eine feste Stunde) ist der Tick der Wirtschaft, nicht `delta` aus
  `_process`. Die Uhr gibt Ticks vor, die Kerne rechnen je Tick. Beispiel: Ob Herr Krause den
  486DX-33 kauft, hängt vom Spieltag ab, nicht davon, wie schnell der Rechner zeichnet.
- *Simulation von Darstellung getrennt* → Kern ohne Node (K) ist genau diese Trennung. Die Anzeige
  liest nur und meldet Eingriffe als Befehl zurück.
- *Zufall nur aus dem Seed* → ein eigener Zufallsgenerator je Spiel (`RandomNumberGenerator` mit
  Seed), nie das globale `randf()`. Je System ein eigener Strom, damit ein neues System die Zahlen
  der anderen nicht verschiebt (eigener Vorschlag, nicht aus Factorio).
- *Keine Fließkomma-Fallen* → Geld als ganze Zahl (Pfennig), nicht als `float`. Das folgt aus
  #36/#108 sinngemäß. Ob Godot auf allen drei Desktops bitgleich mit Fließkomma rechnet, wurde
  nicht geprüft.
- *Reihenfolge festlegen* → Über Dictionarys nur in fester Reihenfolge laufen (Godot hält die
  Einfügereihenfolge, siehe 1.8); keine Logik, die von Node-Reihenfolge im Baum abhängt.
- *Caches beim Laden* → wie #340: Abgeleitete Werte entweder speichern oder beim Laden aus den
  Eingriffen gleich neu berechnen; nie unter anderen Bedingungen.
- *Probe wie „heavy mode“* → Test: Spiel N Tage laufen lassen, speichern, laden, weiter laufen
  lassen; Prüfsumme muss gleich sein wie ohne Speichern. Das ist als Fehlerprobe für 008 messbar.

---

## 5. „Call down, signal up“ – Herkunft

- **KidsCanCode, Godot 4 Recipes, „Node communication“:**
  https://kidscancode.org/godot_recipes/4.x/basics/node_communication/index.html – nennt den
  Merksatz wörtlich: „Call down, signal up.“ Regeln: Eltern rufen Kinder direkt (über
  `get_node()` oder `@export`), Kinder melden per Signal nach oben, Geschwister nur über den
  gemeinsamen Elternknoten. Zu meiden: `get_parent()`, `get_node("..")`, lange absolute Pfade.
  Ohne Datum.
- **Wikibooks, „Guide to the Godot game engine/Signals and methods“:**
  https://en.wikibooks.org/wiki/Guide_to_the_Godot_game_engine/Signals_and_methods – nennt den
  Satz als verbreiteten Rat in der Community, ohne Herkunft.
- **GDQuest, „Best practices with Godot signals“:**
  https://www.gdquest.com/library/signals_good_practices/ – nennt den Merksatz nicht. Rät davon ab,
  Signale über mehrere Ebenen weiterzureichen („bubbling“), und empfiehlt bei mehr als zwei, drei
  Schritten einen Event-Bus. Ursprünglich für Godot 3 geschrieben.
- **GDQuest, „The Events bus singleton“:**
  https://www.gdquest.com/library/pattern_event_bus_singleton/ – ein Autoload, der nur Signale
  hat. GDQuest nennt selbst den Nachteil: unzusammenhängende Signale in einem Objekt, Suche im
  ganzen Code. Das widerspricht A und Nystroms Warnung zur zentralen Queue (2.2).
- Wer den Satz geprägt hat: **nicht gefunden.** Die offizielle Doku verwendet ihn nicht (1.3,
  1.10).

---

## 6. Was für den Leitfaden folgt

Vorschläge, keine Entscheidungen. In Klammern die Quelle.

### 6.1 Je Prinzip

**K – Kern ohne Node**
- Spiellogik und Spielzustand liegen in Klassen, die von RefCounted erben (Form: Skript ohne
  `extends` oder `extends RefCounted`); Szene oder Autoload hält den Kern und reicht Signale
  weiter (1.6, 1.2; Vorbild `TimelineRun`).
- Ausdrücklich als *strenger als die Godot-Doku* kennzeichnen und begründen: Determinismus und
  Testbarkeit ohne Szenenbaum (4.3; Nystrom Game Loop).
- Kern greift nie auf `get_tree()`, `Engine`, Zeit oder globalen Zufall zu; Zeit und Seed kommen
  von außen (4.2).
- Messbar: Keine Datei unter `src/core/` außer den Hüllen erbt von Node.

**S – Signal nach oben, Aufruf nach unten**
- Merksatz nach KidsCanCode, Begründung nach der Doku: Der Elternknoten gibt dem Kind seine
  Abhängigkeiten, das Kind meldet per Signal (5; 1.3).
- Kein `get_parent()`, kein `get_node("..")`, keine absoluten Pfade zu fremden Szenen (5).
- Kein Weiterreichen von Signalen über mehr als eine Ebene und kein allgemeiner Event-Bus (GDQuest
  in 5; Nystrom Event Queue 2.2).
- Innerhalb eines Features darf direkt aufgerufen werden; Signale für Systemgrenzen (Nystrom
  Observer 2.2).

**A – Autoloads sparsam**
- Eine feste Liste der erlaubten Autoloads im Leitfaden (heute `GameClock`, `Timeline`,
  `GameWindow`, `GameSession`); jeder neue braucht Klaus' Freigabe.
- Kriterium aus der Doku übernehmen: nur Systeme, die eigene Daten verwalten und keine fremden
  ändern (1.3, 1.5, 1.7). Damit ist klar, warum die Doku Autoloads für Systeme erlaubt und wir
  trotzdem wenige wollen.
- Keine „Manager“-Autoloads; erst prüfen, ob die Aufgabe in ein Kern-Objekt von `GameSession`
  gehört (Nystrom Singleton 2.1).
- Für Hilfsfunktionen `static func` mit `class_name` statt Autoload (1.5).

**R – Daten als Resources**
- Gepflegte Spieldaten (Produkte, Kundentypen, Raumobjekte) als eigene Resource-Klassen in `.tres`
  (1.6, 1.11) – das ist das Typ-Objekt-Muster (Nystrom).
- Geteilte Resources sind nur lesbar; veränderlicher Zustand gehört in den Kern oder in ein
  Duplikat (1.7).
- Spielstände ausdrücklich ausnehmen: eigenes Format mit Versionsnummer, wie die Doku (JSON/Binär)
  und Gilbert (Bezüge per Name, rückwärtskompatibel) (1.12; 3.2).
- Offene Entscheidung für Klaus: Bleibt `event_catalog.json` als JSON (Werkstatt pflegt es) oder
  wird es Resource?

**Z – Szenen-Komposition**
- Jede Szene läuft für sich (F6) und meldet fehlende Abhängigkeiten selbst, z.B. über
  Konfigurationswarnungen (1.3).
- Kind nur, wenn es mit dem Elternteil verschwinden soll (1.3).
- Spielspezifische Bausteine als Szene, wiederverwendbare Werkzeuge als `class_name`-Skript (1.4).
- Startwerte setzen, bevor die Szene in den Baum kommt (1.9).

### 6.2 Je Schicht

**Adventure-Teil (Vorbild SCUMM / Thimbleweed Park)**
- Adventure-Kern (Raum, Hotspot, Verb, Inventar, Dialog) kennt keinen Spielinhalt; Inhalt steht
  in Daten und Raum-Skripten (Gilbert, Engine; SCUMM Diary).
- Raumobjekte als Resource mit Hotspot, Benutzungspunkt, Blickrichtung, Zuständen (Wimpy).
- Abläufe linear mit `await` schreiben, gespeichert wird nur an Ruhepunkten (Scripting Test; Save
  Game).
- Dialoge als Textdaten mit Knoten, Bedingungen und Variablen, nicht als Code (Dialog Puzzles).

**Wirtschaft (Vorbild Factorio)**
- Fester Tick aus der Spieluhr; keine Wirtschaftsrechnung in `_process` mit `delta` (FFF #70;
  Nystrom Game Loop).
- Jeder Spielereingriff ist ein Befehl; Spielstand = Seed + Grad + Eingriffe, Laden heißt
  nachspielen (Nystrom Command; FFF #76).
- Zufall nur aus dem Seed, Geld als ganze Zahl, feste Reihenfolgen (FFF #36, #108, #340).
- Probe „speichern–laden–vergleichen“ als Test mit Fehlerprobe (FFF #47, #315).

**Oberfläche (Communicator, Titel)**
- Die Oberfläche liest den Zustand und meldet Eingriffe; sie ändert Kern-Daten nie direkt
  (Factorio-Trennung #70; Gilbert: Oberfläche ist Inhalt, nicht Engine, Lock-down in Seattle).
- Verdeckte Seiten trennen ihre Signale oder lesen beim Zeigen neu (Nystrom Observer, vergessener
  Zuhörer).
- Zustände einer Seite als Zustandsmuster, sobald es mehr als zwei, drei Zustände sind (Nystrom
  State).

### 6.3 Nicht gefunden oder offen

- Herkunft von „Call down, signal up“.
- Gilberts eigene Beschreibung des Verbsystems von Thimbleweed Park; der Name „Yack“ aus erster
  Hand.
- Wie Factorio Wiederholungen aufzeichnet.
- Ob GDScript-Fließkomma auf Windows, macOS und Linux bitgleich rechnet (nicht geprüft; darum der
  Vorschlag Geld als ganze Zahl).
- Nystroms Kapitel Flyweight, Prototype, State, Double Buffer, Update Method, Bytecode, Subclass
  Sandbox, Component, Data Locality, Dirty Flag, Object Pool, Spatial Partition wurden für diese
  Datei nicht im Volltext gelesen; die Zeilen in Abschnitt 2 geben ihre bekannte Absicht wieder.
