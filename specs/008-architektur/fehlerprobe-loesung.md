# Lösung der Fehlerprobe (Feature 008, T009)

Nicht für den Prüfer. Die Probe liegt in [fehlerprobe/](fehlerprobe/); sie misst SC-002: Der Prüfer
findet je Godot-Prinzip den eingebauten Verstoß und meldet an der erlaubten Stelle daneben nichts
(research.md, R8). Der Auftrag nennt keine Regel als von Tests gemessen, damit dieselbe Probe auch
nach Phase 4 dieselben fünf Befunde erwartet (Analyse, A4).

| Regel | Datei | Verstoß (muss gefunden werden) | Erlaubt daneben (darf kein Befund sein) |
|---|---|---|---|
| AR-01 Kern ohne Node | `kasse_kern.gd` | `tagesabschluss()` liest `GameClock.date`: ein Kern greift auf ein Autoload zu, statt den Tag hineingereicht zu bekommen | `verkaufe()` würfelt mit dem eigenen, hineingereichten `_rng` |
| AR-02 Signal nach oben, Aufruf nach unten | `regal.gd` | `_gui_input()` ruft `get_parent().kasse_aktualisieren(…)` | dieselbe Funktion sendet `ware_gewaehlt`; `zeige_ware()` ruft das Kind `$Preisschild` nach unten |
| AR-03 Autoloads sparsam | `autoloads_project.godot`, `events.gd` | fünftes Autoload `Events`, ein allgemeiner Signalbus | `preis_format.gd`: Hilfsfunktion als `static func` einer Klasse, kein Autoload |
| AR-04 Daten als Resources | `preisliste.gd` | feste Preise im Code: `if ware_id == "486dx-33": return 249900` | Preise aus der Resource `Ware` (`ware.gd`) lesen; eigene Preise im Kern speichern, nicht in die Resource schreiben |
| AR-05 Szenen-Komposition | `lagerliste.gd` | der Baustein unter `ui/` fragt `get_tree().current_scene.name == "Laden"`, kennt also einen Bildschirm | `setze_zeilen()`: die Zeilen kommen von außen; `zeile_gewaehlt` meldet nach oben |

**Bestanden** heißt: alle fünf Verstöße als Befund, je mit der richtigen Regel; keiner der Einträge
in der rechten Spalte als Befund. Weitere Befunde beurteilt Claude einzeln: Sie sind kein Fehlschlag,
wenn sie eine Regel zutreffend zitieren. Ein Befund zum Verstoß aus AR-05 unter AR-02 (der Baustein
greift über `get_tree()` nach dem Bildschirm) zählt als gefunden.
