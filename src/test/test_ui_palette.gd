extends GutTest

## Prüft die Farbnamen der Palette (Feature 002, T008): Jedes der 15 Tokens aus dem
## Style-Guide führt zu seiner Farbe, die Kategorienfarben sind Tokens der Palette mit
## genug Kontrast zum Grund des Zeitstrahls, und ein unbekannter Name ergibt Magenta.
##
## Im Ereigniskatalog stehen Kategorienfarben als Namen wie "petrol". Ein Tippfehler
## dort soll im Zeitstrahl sofort auffallen, statt still eine falsche Farbe zu zeigen.
##
## `by_token()` ist statisch; die Tests rufen sie an der Klasse auf.

const MAGENTA := Color(1, 0, 1)
## Mindestkontrast farbiger Flächen ohne Text zu ihrem Grund (research.md, R14).
const MINDESTKONTRAST := 3.0


func test_alle_15_tokens_fuehren_zu_ihrer_konstante() -> void:
	# Arrange: Die Konstanten heißen wie die Tokens, nur groß und mit Unterstrich,
	# etwa "gehaeuse-hell" und GEHAEUSE_HELL.
	var konstanten := (UiPalette as Script).get_script_constant_map()

	# Assert
	assert_eq(UiPalette.TOKENS.size(), 15, "Der Style-Guide hat 15 Oberflächenfarben.")
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


# --- Helfer ---------------------------------------------------------------

## Kontrastverhältnis nach WCAG: (hellere + 0,05) / (dunklere + 0,05), mit der relativen
## Helligkeit der linearisierten Farbe.
func _kontrast(a: Color, b: Color) -> float:
	var hell_a := a.srgb_to_linear().get_luminance()
	var hell_b := b.srgb_to_linear().get_luminance()
	return (maxf(hell_a, hell_b) + 0.05) / (minf(hell_a, hell_b) + 0.05)
