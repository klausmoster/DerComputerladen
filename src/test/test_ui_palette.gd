extends GutTest

## Prüft die Farbnamen der Palette (Feature 002, T008): Jedes der 16 Tokens aus dem
## Style-Guide führt zu seiner Farbe, die Kategorienfarben sind Tokens der Palette mit
## genug Kontrast zum Grund des Zeitstrahls, und ein unbekannter Name ergibt Magenta.
##
## Seit Feature 005 (T004) dazu: die 16. Farbe `lcd` und ihre vier Textpaare aus dem
## Style-Guide, Baustein Communicator, mit genug Kontrast.
##
## Im Ereigniskatalog stehen Kategorienfarben als Namen wie "petrol". Ein Tippfehler
## dort soll im Zeitstrahl sofort auffallen, statt still eine falsche Farbe zu zeigen.
##
## `by_token()` ist statisch; die Tests rufen sie an der Klasse auf.

const MAGENTA := Color(1, 0, 1)
## Mindestkontrast farbiger Flächen ohne Text zu ihrem Grund (research.md, R14).
const MINDESTKONTRAST := 3.0
## Mindestkontrast für Text nach WCAG.
const MINDESTKONTRAST_TEXT := 4.5
## Mindestkontrast für große Schrift nach WCAG, so gilt er für gedämpfte Einträge im Baustein Menü.
const MINDESTKONTRAST_GROSS := 3.0


func test_alle_16_tokens_fuehren_zu_ihrer_konstante() -> void:
	# Arrange: Die Konstanten heißen wie die Tokens, nur groß und mit Unterstrich,
	# etwa "gehaeuse-hell" und GEHAEUSE_HELL.
	var konstanten := (UiPalette as Script).get_script_constant_map()

	# Assert
	assert_eq(UiPalette.TOKENS.size(), 16, "Der Style-Guide hat 16 Oberflächenfarben.")
	for token: StringName in UiPalette.TOKENS:
		var konstante := String(token).to_upper().replace("-", "_")
		assert_eq(UiPalette.TOKENS[token], konstanten.get(konstante),
			"Token „%s“ muss die Farbe der Konstante %s haben." % [token, konstante])


func test_by_token_liefert_die_farbe_und_magenta_fuer_unbekanntes() -> void:
	assert_eq(UiPalette.by_token(&"petrol"), UiPalette.PETROL)
	assert_eq(UiPalette.by_token(&"gehaeuse-hell"), UiPalette.GEHAEUSE_HELL)
	assert_eq(UiPalette.by_token(&"petrool"), MAGENTA, "Ein Tippfehler muss als Magenta auffallen.")
	assert_eq(UiPalette.by_token(&""), MAGENTA, "Ein leerer Name ist keine Farbe.")


func test_kategorienfarben_sind_tokens_mit_genug_kontrast() -> void:
	for token: StringName in UiPalette.CATEGORY_TOKENS:
		assert_true(UiPalette.TOKENS.has(token), "„%s“ ist kein Token der Palette." % token)
		var farbe := UiPalette.by_token(token)
		for grund: Color in [UiPalette.PAPIER, UiPalette.ENDLOS_GRUEN]:
			assert_gte(_kontrast(farbe, grund), MINDESTKONTRAST,
				"„%s“ hebt sich nicht genug vom Grund %s ab." % [token, grund.to_html(false)])


# --- lcd (Feature 005, T004) ----------------------------------------------

func test_lcd_hat_den_wert_aus_dem_style_guide() -> void:
	assert_eq(UiPalette.by_token(&"lcd"), UiPalette.LCD, "Das Token „lcd“ führt zu LCD.")
	assert_eq(UiPalette.LCD.to_html(false), "b8c4a8",
		"lcd ist #b8c4a8 (Style-Guide, Baustein Communicator).")


func test_lcd_ist_keine_kategorienfarbe() -> void:
	assert_does_not_have(UiPalette.CATEGORY_TOKENS, &"lcd",
		"lcd gehört der Anzeige des Communicators, nicht den Kategorien des Zeitstrahls.")
	assert_eq(UiPalette.CATEGORY_TOKENS.size(), 7, "Die Kategorienfarben bleiben, wie sie sind.")


func test_textpaare_auf_der_anzeige_haben_genug_kontrast() -> void:
	# Arrange: die vier Textpaare aus dem Style-Guide, je mit der Regel, die für sie gilt.
	# Gemessen hat der Style-Guide 9,56, 9,56, 3,10 und 3,08 : 1.
	var paare := [
		["tusche auf lcd", UiPalette.TUSCHE, UiPalette.LCD, MINDESTKONTRAST_TEXT, 9.56],
		["lcd auf tusche, gewählte Zeile", UiPalette.LCD, UiPalette.TUSCHE,
			MINDESTKONTRAST_TEXT, 9.56],
		["gehaeuse-dunkel auf lcd, nicht verfügbar", UiPalette.GEHAEUSE_DUNKEL, UiPalette.LCD,
			MINDESTKONTRAST_GROSS, 3.10],
		["gehaeuse-dunkel auf tusche, gewählt und nicht verfügbar", UiPalette.GEHAEUSE_DUNKEL,
			UiPalette.TUSCHE, MINDESTKONTRAST_GROSS, 3.08],
	]

	for paar: Array in paare:
		# Act
		var kontrast := _kontrast(paar[1], paar[2])

		# Assert: über der Regel, und auf zwei Stellen der Wert aus dem Style-Guide.
		assert_gte(kontrast, paar[3] as float, "%s: zu wenig Kontrast." % paar[0])
		assert_almost_eq(kontrast, paar[4] as float, 0.005,
			"%s: anderer Kontrast als im Style-Guide." % paar[0])


# --- Helfer ---------------------------------------------------------------

## Kontrastverhältnis nach WCAG: (hellere + 0,05) / (dunklere + 0,05), mit der relativen
## Helligkeit der linearisierten Farbe.
func _kontrast(a: Color, b: Color) -> float:
	var hell_a := a.srgb_to_linear().get_luminance()
	var hell_b := b.srgb_to_linear().get_luminance()
	return (maxf(hell_a, hell_b) + 0.05) / (minf(hell_a, hell_b) + 0.05)
