extends TestCase
## Guards release hygiene: consistent identity/version across presets and
## project.godot, no permissions, and no credentials in tracked config.


func _presets() -> Array:
	var cfg := ConfigFile.new()
	check(cfg.load("res://export_presets.cfg") == OK, "export_presets.cfg parses")
	var out := []
	for sec in cfg.get_sections():
		if sec.begins_with("preset.") and not sec.ends_with(".options"):
			out.append({"name": cfg.get_value(sec, "name"), "opts": sec + ".options", "cfg": cfg})
	return out


func test_two_presets_exist_with_same_identity_and_version() -> void:
	var ps := _presets()
	eq(ps.size(), 2, "debug + release presets")
	var ids := {}
	var codes := {}
	var names := {}
	for p in ps:
		var cfg: ConfigFile = p["cfg"]
		ids[cfg.get_value(p["opts"], "package/unique_name")] = true
		codes[cfg.get_value(p["opts"], "version/code")] = true
		names[cfg.get_value(p["opts"], "version/name")] = true
	eq(ids.size(), 1, "one application id across presets")
	eq(codes.size(), 1, "one version code across presets")
	eq(names.size(), 1, "one version name across presets")
	var proj_version := str(ProjectSettings.get_setting("application/config/version"))
	check(names.has(proj_version), "preset version name matches project.godot config/version (%s)" % proj_version)
	var id := str(ids.keys()[0])
	var rx := RegEx.new()
	rx.compile("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$")
	check(rx.search(id) != null, "application id '%s' is a valid Android package name" % id)
	check(int(codes.keys()[0]) >= 1, "version code is a positive integer")


func test_no_permissions_and_portrait_and_no_backup() -> void:
	for p in _presets():
		var cfg: ConfigFile = p["cfg"]
		for key in cfg.get_section_keys(p["opts"]):
			if key.begins_with("permissions/"):
				check(cfg.get_value(p["opts"], key) == false, "%s: %s must stay off" % [p["name"], key])
		eq(cfg.get_value(p["opts"], "user_data_backup/allow"), false, "%s: auto-backup off" % p["name"])
	eq(int(ProjectSettings.get_setting("display/window/handheld/orientation")), 1, "portrait orientation")


func test_no_credentials_in_tracked_config() -> void:
	for p in _presets():
		var cfg: ConfigFile = p["cfg"]
		for key in ["keystore/debug", "keystore/debug_user", "keystore/debug_password",
				"keystore/release", "keystore/release_user", "keystore/release_password"]:
			eq(str(cfg.get_value(p["opts"], key, "")), "", "%s: %s must be empty in git (use env vars)" % [p["name"], key])
	var gi := FileAccess.get_file_as_string("res://.gitignore")
	for pat in ["*.keystore", "*.jks", "*.apk", "*.aab"]:
		check(gi.contains(pat), ".gitignore covers %s" % pat)


func test_release_preset_targets_aab_with_gradle_and_debug_does_not() -> void:
	for p in _presets():
		var cfg: ConfigFile = p["cfg"]
		if str(p["name"]).contains("AAB"):
			eq(cfg.get_value(p["opts"], "gradle_build/use_gradle_build"), true)
			eq(int(cfg.get_value(p["opts"], "gradle_build/export_format")), 1, "AAB format")
			eq(cfg.get_value(p["opts"], "architectures/arm64-v8a"), true, "64-bit ABI included (Play requirement)")
		else:
			eq(cfg.get_value(p["opts"], "gradle_build/use_gradle_build"), false)
