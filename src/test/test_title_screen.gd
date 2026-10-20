extends GutTest

## Prüft den Text der Versionszeile auf dem Titelbildschirm (FR-014): Aus der Versionsnummer
## des Projekts wird „V0.1 · PROTOTYP“, ohne Nummer steht nur „PROTOTYP“ da.
##
## `version_text()` ist statisch. Die Tests rufen sie an der Klasse auf und brauchen
## deshalb keinen Titelbildschirm im Baum.


func test_version_wird_mit_v_und_kennzeichen_gezeigt() -> void:
	# Act
	var text := TitleScreen.version_text("0.1")

	# Assert
	assert_eq(text, "V0.1 · PROTOTYP",
		"Vor der Nummer steht ein V, dahinter mit Mittelpunkt das Kennzeichen.")


func test_ohne_version_steht_nur_das_kennzeichen_da() -> void:
	# Act
	var text := TitleScreen.version_text("")

	# Assert
	assert_eq(text, "PROTOTYP", "Ohne Nummer darf kein „V“ ohne Zahl erscheinen.")
