class_name Hud
extends CanvasLayer
## In-floor HUD (GDD 17.3), placeholder look: floor and timer on top, water gauge on the right edge.

var world: World
var controls: TouchControls
var _title: Label
var _timer_label: Label
var _hint: Label
var _fps: Label
var _gauge: WaterGauge
var _hp_bar: HpBar
var overlay: WorldOverlay
var _goal: Label
var _gold: Label
var _hint_panel: PanelContainer
var _hint_label: Label
var _hint_left: float = 0.0
var _essence: EssenceBar
var _stairs_msg_left: float = 0.0
var _boss_bar: BossBar
var _line_panel: PanelContainer
var _line_label: Label
var _line_left: float = 0.0


func setup(w: World) -> void:
	world = w
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_title = _label(root, 34, Color(0.9, 0.84, 0.72))
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title.position.y = 24
	_timer_label = _label(root, 54, Color(0.95, 0.92, 0.85))
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_label.position.y = 66
	_hint = _label(root, 26, Color(0.8, 0.85, 0.85, 0.8))
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.position.y -= 60
	_fps = _label(root, 22, Color(0.6, 0.7, 0.7))
	_fps.position = Vector2(40, 16)
	_gauge = WaterGauge.new()
	_gauge.anchor_left = 1.0
	_gauge.anchor_right = 1.0
	_gauge.offset_left = -80
	_gauge.offset_right = -40
	_gauge.offset_top = 120
	_gauge.offset_bottom = 440
	root.add_child(_gauge)
	_goal = _label(root, 28, Color(0.85, 0.82, 0.7))
	_goal.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_goal.position.y = 132
	_gold = _label(root, 30, Color(1, 0.82, 0.35))
	_gold.position = Vector2(40, 112)
	_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_essence = EssenceBar.new()
	_essence.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_essence.position = Vector2(40, -64)
	_essence.size = Vector2(440, 26)
	root.add_child(_essence)
	_hint_panel = UiKit.panel(root)
	_hint_panel.anchor_left = 0.5
	_hint_panel.anchor_right = 0.5
	_hint_panel.offset_left = -450
	_hint_panel.offset_right = 450
	_hint_panel.offset_top = 190
	_hint_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label = UiKit.label(_hint_panel, "", 34)
	_hint_panel.visible = false
	_boss_bar = BossBar.new()
	_boss_bar.anchor_left = 0.5
	_boss_bar.anchor_right = 0.5
	_boss_bar.offset_left = -420
	_boss_bar.offset_right = 420
	_boss_bar.offset_top = 180
	_boss_bar.offset_bottom = 214
	root.add_child(_boss_bar)
	_line_panel = UiKit.panel(root, Color(0.75, 0.25, 0.2))
	_line_panel.anchor_left = 0.5
	_line_panel.anchor_right = 0.5
	_line_panel.anchor_top = 1.0
	_line_panel.anchor_bottom = 1.0
	_line_panel.offset_left = -520
	_line_panel.offset_right = 520
	_line_panel.offset_top = -260
	_line_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_line_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line_label = UiKit.label(_line_panel, "", 32, Color(1, 0.85, 0.75))
	_line_panel.visible = false
	_hp_bar = HpBar.new()
	_hp_bar.position = Vector2(40, 70)
	_hp_bar.size = Vector2(420, 34)
	root.add_child(_hp_bar)
	overlay = WorldOverlay.new()
	root.add_child(overlay)
	root.move_child(overlay, 0)
	controls = TouchControls.new()
	root.add_child(controls)


func _label(parent: Control, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", color)
	l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override(&"outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _process(_delta: float) -> void:
	if world == null:
		return
	var t := world.timer
	_title.text = tr("HUD_FLOOR") % [world.floor_index, 25]
	var rem := ceili(t.remaining())
	_timer_label.text = "%d:%02d" % [rem / 60, rem % 60]
	var alarm := t.remaining() <= 30.0
	_timer_label.add_theme_color_override(&"font_color", Color(1, 0.35, 0.3) if alarm else Color(0.95, 0.92, 0.85))
	_hint.text = tr("SPIKE_HINT") if not world.grid.data.get("tutorial", false) else ""
	_hint.visible = OS.has_feature("pc") or OS.has_feature("editor")
	_gold.text = "◆ %d" % (world.gold_collected + (world.run.gold if world.run else 0))
	_goal.text = _goal_text()
	_essence.value = world.essence
	_essence.threshold = world.essence_threshold()
	_essence.total = world.essence_total
	_hint_left -= get_process_delta_time()
	_hint_panel.visible = _hint_left > 0.0
	var near := world.interactable_near(world.hero.pos)
	controls.action_visible = near != null or world.hero.interact_target != null
	controls.action_progress = 0.0 if world.hero.interact_target == null else \
			1.0 - world.hero.interact_left / maxf(world.hero.interact_total, 0.01)
	_stairs_message()
	_boss_bar.boss = world.boss
	_boss_bar.visible = world.boss != null and world.boss.alive
	_line_left -= get_process_delta_time()
	_line_panel.visible = _line_left > 0.0
	_fps.text = "%d FPS" % Engine.get_frames_per_second()
	_gauge.ratio = clampf(t.progress(), 0.0, 1.0)
	controls.dodge_ready = world.hero.dodge_ready_ratio()
	controls.auto_on = world.hero.auto_mode
	for i in Hero.MAX_ACTIVES:
		var sk := world.hero.actives[i]
		controls.skills[i] = {} if sk == null else {
			"ready": sk.ready_ratio(), "level": sk.level, "label": tr(String(sk.data.get("name_key", sk.id))),
			"seconds": sk.cooldown_left}
	_hp_bar.hp = world.hero.hp
	_hp_bar.max_hp = world.hero.max_hp


func show_hint(text: String, seconds: float) -> void:
	_hint_label.text = text
	_hint_left = seconds


## Boss line plate (GDD 15): shown 3 s at the bottom, the fight does not stop.
func show_boss_line(key: String) -> void:
	var boss_name := tr(String(world.boss.boss_data["name_key"])) if world.boss else ""
	_line_label.text = "%s: «%s»" % [boss_name, tr(key)]
	_line_left = 3.0


func _goal_text() -> String:
	match world.goal_type:
		&"boss":
			if world.boss and world.boss.enraged:
				return tr("BOSS_ENRAGED")
			return tr(String(world.boss.boss_data["name_key"])) if world.boss else ""
		&"key_holder":
			return tr("GOAL_KEY_DONE") if world.has_key else tr("GOAL_KEY_MISSING")
		&"seals":
			return tr("GOAL_SEALS") % [world.seals_done, world.seals_needed]
	return tr("GOAL_BREAKTHROUGH")


## "Locked: you need the key" / "seals 1/3" when standing at closed stairs (GDD 13.2).
func _stairs_message() -> void:
	var at_stairs := world.hero.pos.distance_to(FloorGrid.cell_center(world.grid.exit)) < 1.6
	if at_stairs and not world.goal_done() and _hint_left <= 0.0:
		var msg := tr("STAIRS_LOCKED_KEY") if world.goal_type == &"key_holder" \
				else tr("STAIRS_LOCKED_SEALS") % [world.seals_done, world.seals_needed]
		show_hint(msg, 1.5)


## Big boss health bar with phase marks (GDD 17.3).
class BossBar:
	extends Control
	var boss: Boss

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if boss == null:
			return
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r.grow(4), Color(0, 0, 0, 0.85))
		var k := clampf(boss.hp / boss.max_hp, 0.0, 1.0)
		var col := Color(0.85, 0.15, 0.1) if not boss.enraged else Color(1.0, 0.35, 0.05)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * k, size.y)), col)
		for th: Dictionary in boss.boss_data.get("thresholds", []):
			var x := size.x * float(th["hp"])
			draw_line(Vector2(x, -6), Vector2(x, size.y + 6), Color(1, 0.9, 0.6), 3.0)
		draw_rect(r, Color(0.8, 0.65, 0.45), false, 2.0)
		var font := get_theme_default_font()
		var t := tr(String(boss.boss_data["name_key"]))
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		draw_string_outline(font, Vector2((size.x - tw) * 0.5, size.y - 7), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6,
				Color(0, 0, 0))
		draw_string(font, Vector2((size.x - tw) * 0.5, size.y - 7), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)


class EssenceBar:
	extends Control
	var value: float = 0.0
	var threshold: float = 1.0
	var total: float = 1.0

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r.grow(3), Color(0, 0, 0, 0.8))
		var full := value >= threshold and total > 0.0
		var col := Color(0.75, 0.45, 1.0) if full else Color(0.5, 0.3, 0.75)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(value / maxf(total, 1.0), 0, 1), size.y)), col)
		var tx := size.x * clampf(threshold / maxf(total, 1.0), 0, 1)
		draw_line(Vector2(tx, -8), Vector2(tx, size.y + 8), Color(1, 0.9, 0.6), 3.0)
		draw_rect(r, Color(0.7, 0.62, 0.48), false, 2.0)
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, -12), "%s %d / %d" % [tr("HUD_ESSENCE"), roundi(value), roundi(threshold)],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.85, 0.75, 1.0))


class HpBar:
	extends Control
	var hp: float = 1.0
	var max_hp: float = 1.0

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r.grow(3), Color(0, 0, 0, 0.8))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(hp / max_hp, 0, 1), size.y)), Color(0.75, 0.12, 0.1))
		draw_rect(r, Color(0.7, 0.62, 0.48), false, 2.0)
		var font := get_theme_default_font()
		var text := "%d / %d" % [ceili(hp), roundi(max_hp)]
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(font, Vector2((size.x - tw) * 0.5, size.y - 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)


class WaterGauge:
	extends Control
	var ratio: float = 0.0

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.03, 0.05, 0.06, 0.8))
		var h := size.y * ratio
		draw_rect(Rect2(0, size.y - h, size.x, h), Color(0.15, 0.75, 0.72, 0.9))
		for mark: float in [0.5, 0.8]:
			var y := size.y * (1.0 - mark)
			draw_line(Vector2(-6, y), Vector2(size.x + 6, y), Color(0.9, 0.85, 0.7, 0.8), 2.0)
		draw_rect(r, Color(0.7, 0.62, 0.48), false, 3.0)
