extends TestCase
## Localisation: every translatable key present with Hindi text, formatting intact, switching works.

const ProgressScript = preload("res://src/services/progress.gd")
const PATH := "user://test_save_i18n.json"


func _new_progress() -> Node:
	var p = ProgressScript.new()
	p.save_path = PATH
	return p


func test_every_campaign_and_ui_string_has_hindi() -> void:
	var keys: Array = []
	for r in CampaignText.REASONS.values():
		if r != "":
			keys.append(r)
	for v in CampaignText.INTROS.values():
		keys.append(v[0])
		keys.append(v[1])
	keys.append(CampaignText.RULES_TEXT)
	for v in CampaignText.STAGES.values():
		keys.append(v)
	for k in keys:
		check(I18n.HI.has(k), "missing Hindi for: " + str(k).substr(0, 60))


func test_source_files_only_use_known_keys() -> void:
	# every literal passed to tr("...") must have a Hindi entry
	var files := ["res://src/ui/game_screen.gd", "res://src/ui/menu_screen.gd", "res://src/ui/level_select_screen.gd", "res://src/ui/toggle_row.gd"]
	var re := RegEx.new()
	re.compile("tr\\(\"((?:[^\"\\\\]|\\\\.)*)\"\\)")
	for f in files:
		var src := FileAccess.get_file_as_string(f)
		for m in re.search_all(src):
			var key: String = m.get_string(1).replace("\\n", "\n")
			check(I18n.HI.has(key), "%s: no Hindi for tr(\"%s\")" % [f.get_file(), key.substr(0, 50)])


func test_hindi_entries_non_empty_and_keep_format_specifiers() -> void:
	for k in I18n.HI:
		var v: String = I18n.HI[k]
		check(v.strip_edges() != "", "empty Hindi for " + str(k).substr(0, 40))
		check(str(k).count("%d") + str(k).count("%s") == v.count("%d") + v.count("%s"), "format specifier count differs: " + str(k).substr(0, 50))


func test_hindi_is_not_absurdly_longer_than_english() -> void:
	for k in I18n.HI:
		if str(k).length() <= 24:
			check(String(I18n.HI[k]).length() <= str(k).length() * 2 + 6, "Hindi much longer than English (layout risk): " + str(k))


func test_locale_switching_translates_and_reverts() -> void:
	I18n.apply("hi")
	eq(TranslationServer.get_locale().substr(0, 2), "hi")
	eq(tr("Undo"), "पूर्ववत")
	eq(tr("Level %d") % 3, "स्तर 3")
	I18n.apply("en")
	eq(tr("Undo"), "Undo")
	I18n.apply("auto")


func test_resolve_auto_falls_back_to_english_for_unsupported_device_language() -> void:
	eq(I18n.resolve("en"), "en")
	eq(I18n.resolve("hi"), "hi")
	check(I18n.resolve("auto") in I18n.SUPPORTED)


func test_language_setting_persists_and_bad_value_is_ignored() -> void:
	var p = _new_progress()
	p._set_defaults()
	p.set_language("hi")
	var d: Dictionary = p.to_dict()
	eq(d["language"], "hi")
	var q = _new_progress()
	check(q.apply_dict(JSON.parse_string(JSON.stringify(d))))
	eq(q.language, "hi")
	var bad := d.duplicate()
	bad["language"] = "klingon"
	var r = _new_progress()
	check(r.apply_dict(bad))
	eq(r.language, "auto")
	I18n.apply("auto")
