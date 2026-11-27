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


func test_autotest_is_inert_without_its_trigger_file_and_in_release_builds() -> void:
	var trig := ProjectSettings.globalize_path(Autotest.TRIGGER)
	if FileAccess.file_exists(Autotest.TRIGGER):
		DirAccess.remove_absolute(trig)
	check(not Autotest.should_run(), "no trigger file -> autotest does not run")
	var src := FileAccess.get_file_as_string("res://src/services/autotest.gd")
	check(src.contains("OS.is_debug_build()"), "autotest is gated on debug builds (never runs in release exports)")


func test_ci_workflows_exist_and_contain_no_literal_secrets() -> void:
	for f in ["ci.yml", "release.yml"]:
		var path: String = "res://.github/workflows/" + f
		check(FileAccess.file_exists(path), f + " exists")
		var txt: String = FileAccess.get_file_as_string(path)
		check(not txt.contains("BEGIN PRIVATE KEY"), f + " has no private key")
		for line in txt.split("\n"):
			var l := line.strip_edges()
			if l.to_lower().contains("password") and l.contains(":") and not l.begins_with("#"):
				check(l.contains("secrets.") or l.contains("$PW") or l.contains("\"$"), "%s: password line must reference a secret, got: %s" % [f, l])
	var rel: String = FileAccess.get_file_as_string("res://.github/workflows/release.yml")
	check(rel.contains("workflow_dispatch") and not rel.contains("on:\n  push"), "release workflow is manual only")
	check(not rel.contains("upload-google-play") and not rel.contains("r0adkll/upload"), "release workflow never publishes to Google Play")
