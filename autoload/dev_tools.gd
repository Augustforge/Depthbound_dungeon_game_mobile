extends Node
## Developer helpers driven by command line user args (after "--"):
##   --screenshot=<abs path.png> --frames=<n>   save a frame after n frames and quit
##   --smoke-test                                check that data loads, print SMOKE_OK and quit
##   --quit-after=<frames>                       quit after n frames

var _args: Dictionary = {}
var _frame: int = 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var parts := a.trim_prefix("--").split("=", true, 1)
		_args[parts[0]] = parts[1] if parts.size() > 1 else "true"
	if _args.has("smoke-test"):
		_run_smoke_test.call_deferred()
	set_process(_args.has("screenshot") or _args.has("quit-after"))


func arg(name: String, default: String = "") -> String:
	return _args.get(name, default)


func _process(_delta: float) -> void:
	_frame += 1
	if _args.has("screenshot") and _frame == int(_args.get("frames", "45")):
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path: String = _args["screenshot"]
		var err := img.save_png(path)
		print("DevTools: screenshot %s -> %s" % [path, error_string(err)])
		get_tree().quit(0 if err == OK else 1)
	elif _args.has("quit-after") and _frame >= int(_args["quit-after"]):
		get_tree().quit(0)


func _run_smoke_test() -> void:
	var ok := DataDB.load_errors.is_empty() and Settings.load_translations() > 0
	ok = ok and FileAccess.file_exists("res://levels/d01/floor_01.txt")
	print("SMOKE_OK" if ok else "SMOKE_FAIL %s" % [DataDB.load_errors])
	get_tree().quit(0 if ok else 1)
