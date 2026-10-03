extends Node
## Developer helpers driven by command line user args (after "--"):
##   --screenshot=<abs path.png> --frames=<n>   save a frame after n frames and quit
##   --smoke-test                                check that data loads, print SMOKE_OK and quit
##   --quit-after=<frames>                       quit after n frames

var _args: Dictionary = {}
var _frame: int = 0
var _perf_frames: int = 0
var _perf_process: float = 0.0
var _perf_physics: float = 0.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var parts := a.trim_prefix("--").split("=", true, 1)
		_args[parts[0]] = parts[1] if parts.size() > 1 else "true"
	if _args.has("smoke-test"):
		_run_smoke_test.call_deferred()
	set_process(_args.has("screenshot") or _args.has("quit-after") or _args.has("perf"))


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
	if _args.has("perf") and _frame > 30:
		_perf_frames += 1
		_perf_process += Performance.get_monitor(Performance.TIME_PROCESS)
		_perf_physics += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		if _perf_frames % 60 == 0:
			print("PERF process %.2f ms, physics %.2f ms, objects %d, draw calls %d" % [
				_perf_process / _perf_frames * 1000.0, _perf_physics / _perf_frames * 1000.0,
				Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])


func _run_smoke_test() -> void:
	var ok := DataDB.load_errors.is_empty() and Settings.load_translations() > 0
	ok = ok and FileAccess.file_exists("res://levels/d01/floor_01.txt")
	print("SMOKE_OK" if ok else "SMOKE_FAIL %s" % [DataDB.load_errors])
	get_tree().quit(0 if ok else 1)
