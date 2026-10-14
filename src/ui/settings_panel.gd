class_name SettingsPanel
extends VBoxContainer
## Sound / music / reduced-motion toggles bound to Progress.settings.


static func make() -> SettingsPanel:
	var p := SettingsPanel.new()
	p.add_theme_constant_override("separation", 12)
	for row in [["Sound effects", "sound"], ["Music", "music"], ["Reduce motion", "reduce_motion"]]:
		var key: String = row[1]
		var t := ToggleRow.make(row[0], bool(Progress.settings[key]))
		t.toggled.connect(func(on): Progress.set_setting(key, on))
		p.add_child(t)
	return p
