class_name SoundDirector
extends Node
## Turns world events into sounds and vibration (GDD 18.4): hits, crits, traps, objects, steps in
## dry or wet stone, the rising water, the last-30-seconds alarm, and the zone or boss music.

const STEP_INTERVAL := 0.34

var world: World
var _step_left: float = 0.0
var _was_dodging: bool = false
var _alarm_done: bool = false
var _last_tick: int = -1
var _flood_left: float = 0.0


func setup(w: World) -> void:
	world = w
	w.damage_dealt.connect(_on_damage)
	w.entity_died.connect(func(e: Entity) -> void:
		if e is Mob:
			AudioManager.play(&"mob_die"))
	w.chest_opened.connect(func(_o: FloorObject, _l: Dictionary) -> void:
		AudioManager.play(&"chest")
		AudioManager.vibrate(30))
	w.gold_changed.connect(func(_t: int) -> void: AudioManager.play(&"coins"))
	w.parried.connect(func(_a: Combatant) -> void: AudioManager.play(&"parry"))
	w.skill_cast.connect(func(_s: Skill) -> void: AudioManager.play(&"skill"))
	w.spring_used.connect(func(_o: FloorObject) -> void: AudioManager.play(&"spring"))
	w.note_found.connect(func(_k: String) -> void: AudioManager.play(&"note"))
	w.object_changed.connect(_on_object)
	w.boss_enraged.connect(func(_b: Boss) -> void: AudioManager.play(&"boss_enrage"))
	w.flood_started.connect(func(_r: Rect2i) -> void:
		AudioManager.play(&"flood")
		_flood_left = float(DataDB.table(&"floor")["flood_valve"]["duration"]))
	w.floor_failed.connect(func(_c: StringName) -> void:
		AudioManager.stop_loops()
		AudioManager.vibrate(200))
	w.floor_completed.connect(func(_r: Dictionary) -> void: AudioManager.stop_loops())
	var zone := String(w.grid.data.get("zone", "cells"))
	AudioManager.play_music(&"boss" if w.boss != null else StringName(zone))


func _on_damage(target: Combatant, _amount: float, crit: bool, source: Entity) -> void:
	if target == world.hero:
		AudioManager.play(&"hero_hurt")
		AudioManager.vibrate(25)
		return
	if source is SpikeZone:
		AudioManager.play(&"spikes")
	elif source is FloorObject:
		AudioManager.play(&"bear_trap")
	elif source is HarpoonWall:
		AudioManager.play(&"harpoon")
	elif source == world.hero or (source is Projectile and source.team == Entity.Team.HERO):
		AudioManager.play(&"crit" if crit else &"hit")


func _on_object(o: Entity) -> void:
	if not (o is FloorObject):
		return
	match (o as FloorObject).kind:
		FloorObject.Kind.GATE, FloorObject.Kind.LOCK_GATE:
			AudioManager.play(&"gate")
		FloorObject.Kind.LEVER:
			AudioManager.play(&"lever")
		FloorObject.Kind.VALVE, FloorObject.Kind.FLOOD_VALVE:
			AudioManager.play(&"valve")
		FloorObject.Kind.BEAR_TRAP:
			if not (o as FloorObject).armed:
				AudioManager.play(&"bear_trap")


func _process(delta: float) -> void:
	if world == null or not world.running:
		return
	var hero := world.hero
	var wet := world.timer.phase() >= FloorTimer.Phase.SHALLOW
	var dodging := hero.is_dodging()
	if dodging and not _was_dodging:
		AudioManager.play(&"dodge_water" if wet else &"dodge")
	_was_dodging = dodging
	if hero.velocity.length() > 0.5 and not dodging:
		_step_left -= delta
		if _step_left <= 0.0:
			_step_left = STEP_INTERVAL
			AudioManager.play(&"step_water" if wet else &"step")
	else:
		_step_left = 0.0
	var t := world.timer
	AudioManager.set_loop(&"water", clampf(t.elapsed / maxf(t.limit, 1.0) * 1.4 - 0.4, 0.0, 1.0)
		if not t.boss_mode else 0.0)
	_flood_left = maxf(0.0, _flood_left - delta)
	AudioManager.set_loop(&"flood", 1.0 if _flood_left > 0.0 else 0.0)
	var rem := t.remaining()
	if not _alarm_done and rem <= 30.0 and not t.boss_mode:
		_alarm_done = true
		AudioManager.play(&"alarm")
		AudioManager.vibrate(60)
	if rem <= 10.0 and rem > 0.0 and int(ceil(rem)) != _last_tick:
		_last_tick = int(ceil(rem))
		AudioManager.play(&"tick")


func _exit_tree() -> void:
	AudioManager.stop_loops()
