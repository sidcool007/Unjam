extends Node
## Autoload "Levels": loads the data-driven campaign from res://levels/campaign.json.
## Level logic never lives here; this only parses and serves level dictionaries.

const CAMPAIGN_PATH := "res://levels/campaign.json"

var levels: Array = []
var load_error := ""


func _ready() -> void:
	load_campaign(CAMPAIGN_PATH)


func load_campaign(path: String) -> bool:
	levels.clear()
	load_error = ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		load_error = "cannot open %s" % path
		return false
	var data = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary) or not (data.get("levels") is Array):
		load_error = "campaign file is malformed"
		return false
	for lv in data["levels"]:
		if lv is Dictionary:
			levels.append(lv)
	return not levels.is_empty()


func count() -> int:
	return levels.size()


func has_level(id: int) -> bool:
	return id >= 1 and id <= levels.size()


## Level dictionary for 1-based id.
func get_level(id: int) -> Dictionary:
	return levels[id - 1]


## Par = length of the recorded (validated) solution.
func par(id: int) -> int:
	return (levels[id - 1]["solution"] as Array).size()
