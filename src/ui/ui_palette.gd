class_name UiPalette
extends RefCounted

## Die 15 Oberflächenfarben aus dem Style-Guide, Namen wie die Tokens in `tokens.json`.
##
## Die Werte kommen unverändert aus dem Style-Guide und stehen genauso in der
## Hauptpalette `docs/art/hauptpalette.gpl` (Index 1 bis 15). Farben der Oberfläche
## kommen nur von hier oder aus dem Theme, nie frei gewählt.
##
## Die Klasse wird nie instanziiert: Konstanten hängen an der Klasse selbst, deshalb
## geht `UiPalette.TUSCHE` überall, ohne Autoload und ohne `new()`.

const TUSCHE := Color("1d1916")
const NACHT := Color("18233b")
const NACHT_HELL := Color("2c3d63")
const GEHAEUSE_DUNKEL := Color("6f6654")
const GEHAEUSE := Color("bdb39a")
const GEHAEUSE_HELL := Color("e4dcc6")
const PAPIER := Color("f5f0e2")
const ENDLOS_GRUEN := Color("cfe2c3")
const ANZEIGE_GRUND := Color("0d1716")
const ANZEIGE := Color("6ff0cf")
const KASSENROT := Color("c0392b")
const SIGNALGELB := Color("f2bf2f")
const PETROL := Color("1f6f75")
const HOLZ := Color("8b5a34")
const HOLZ_DUNKEL := Color("57351d")
