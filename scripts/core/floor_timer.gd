class_name FloorTimer
extends RefCounted
## Floor time limit and water phases (GDD 10.1–10.2).

enum Phase { DRY, SHALLOW, KNEE, FLOOD }

const FLOOD_DURATION := 4.0

var limit: float = 150.0
var elapsed: float = 0.0
var paused: bool = false
## Boss arenas (GDD 15): no water until enrage; then it rises for `flood_after` seconds and the
## arena drowns. `limit` is the enrage time.
var boss_mode: bool = false
var flood_after: float = 30.0


func _init(time_limit: float = 150.0) -> void:
	limit = time_limit


func tick(dt: float) -> void:
	if not paused:
		elapsed += dt


func progress() -> float:
	if boss_mode:
		# Map boss time onto the normal water curve: dry until enrage, then 0.5 -> 1.0 over flood_after.
		if elapsed < limit:
			return 0.5 * elapsed / limit
		return 0.5 + 0.5 * minf(1.0, (elapsed - limit) / flood_after) + maxf(0.0, elapsed - limit - flood_after) / limit
	return elapsed / limit


func enraged() -> bool:
	return boss_mode and elapsed >= limit


func remaining() -> float:
	return maxf(0.0, limit - elapsed)


func phase() -> Phase:
	var p := progress()
	if p >= 1.0:
		return Phase.FLOOD
	if p >= 0.8:
		return Phase.KNEE
	if p >= 0.5:
		return Phase.SHALLOW
	return Phase.DRY


## True once the flood has filled the floor (hero dies, GDD 10.2).
func drowned() -> bool:
	if boss_mode:
		return elapsed >= limit + flood_after + FLOOD_DURATION
	return elapsed >= limit + FLOOD_DURATION


## Water surface height in metres above the floor, for views. Floor tiles sit at ~0.
func water_height() -> float:
	var p := progress()
	if p < 0.5:
		return -0.2
	if p < 0.8:
		return lerpf(-0.06, 0.1, (p - 0.5) / 0.3)
	if p < 1.0:
		return lerpf(0.3, 0.45, (p - 0.8) / 0.2)
	var flood_start := limit + (flood_after if boss_mode else 0.0)
	return lerpf(0.45, 2.6, clampf((elapsed - flood_start) / FLOOD_DURATION, 0.0, 1.0))
