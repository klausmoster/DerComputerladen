# Probe für den Architektur-Prüfer (Feature 008). Gedachter Ort im Spiel:
# res://ui/preis_format.gd
class_name PreisFormat
extends RefCounted

## Schreibt Pfennigbeträge so, wie sie im Spiel stehen, etwa „2.499,00 DM“.


static func als_dm(betrag_pf: int) -> String:
	var mark := betrag_pf / 100
	var pfennig := absi(betrag_pf) % 100
	var ziffern := str(absi(mark))
	var mit_punkten := ""
	for i in ziffern.length():
		if i > 0 and (ziffern.length() - i) % 3 == 0:
			mit_punkten += "."
		mit_punkten += ziffern[i]
	return "%s%s,%02d DM" % ["−" if betrag_pf < 0 else "", mit_punkten, pfennig]
