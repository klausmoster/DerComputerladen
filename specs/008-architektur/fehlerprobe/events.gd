# Probe für den Architektur-Prüfer (Feature 008). Gedachter Ort im Spiel: res://core/events.gd,
# als Autoload „Events“ eingetragen (siehe autoloads_project.godot).
extends Node

## Alle Signale des Ladens an einer Stelle, damit jede Szene sie senden und hören kann.

signal ware_verkauft(ware_id: String, erloes_pf: int)
signal kunde_betritt_laden(kunde_id: int)
signal kunde_verlaesst_laden(kunde_id: int)
signal lager_leer(ware_id: String)
