extends FloorScene
## Test room for systems checks (stage 0–2): the floor scene on the spike map.


func _ready() -> void:
	map_path = DevTools.arg("map", "res://levels/test/spike_room")
	super._ready()
