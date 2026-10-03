extends Control
## Camp «Последний приют» (GDD 3.5, 17.1): the art with living effects and five places —
## Descent (the run), Equipment, Ulm the merchant, the Record board and the Reflection.

const ART := preload("res://assets/ui/camp.webp")
const SPOTS := {
	"descend": Vector2(0.2, 0.52), "equipment": Vector2(0.37, 0.67), "merchant": Vector2(0.78, 0.5),
	"records": Vector2(0.3, 0.33), "reflection": Vector2(0.52, 0.86),
}

var _spots: Dictionary = {}
var _top: HBoxContainer


func _ready() -> void:
	AudioManager.play_music(&"camp")
	UiKit.cover_art(self, ART)
	var fx := ArtEffects.new()
	add_child(fx)
	fx.setup(ART)
	fx.add_beam_dust(Vector2(0.5, 0.0), Vector2(0.5, 0.5), 0.1, 30)
	fx.add_drops(0.35, 0.75, 10)
	fx.add_glints(Rect2(0.12, 0.6, 0.2, 0.15), 20)
	fx.add_glints(Rect2(0.4, 0.82, 0.3, 0.08), 12, Color(1.0, 0.75, 0.45))
	fx.add_glow(Vector2(0.522, 0.66), 0.09, Color(1.0, 0.5, 0.15), 0.6)
	fx.add_embers(Vector2(0.522, 0.66), 22)
	for t: Vector2 in [Vector2(0.707, 0.353), Vector2(0.678, 0.45), Vector2(0.882, 0.268), Vector2(0.861, 0.524),
			Vector2(0.945, 0.61), Vector2(0.112, 0.414), Vector2(0.264, 0.48), Vector2(0.224, 0.51)]:
		fx.add_glow(t, 0.035, Color(1.0, 0.6, 0.25), 0.4)
	for id: String in SPOTS:
		_spots[id] = Hotspot.make(self, "", _on_spot.bind(id))
	_top = HBoxContainer.new()
	_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top.offset_left = 40
	_top.offset_right = -40
	_top.offset_top = 24
	_top.offset_bottom = 94
	_top.add_theme_constant_override(&"separation", 30)
	add_child(_top)
	resized.connect(_layout)
	EventBus.language_changed.connect(func(_l: String) -> void: _refresh())
	_refresh()
	_layout.call_deferred()
	GameState.save()
	if DevTools.arg("demo") == "1":
		_fill_demo_profile()
	if not DevTools.arg("open").is_empty():
		_on_spot.call_deferred(DevTools.arg("open"))


func _refresh() -> void:
	var p := GameState.profile
	var run := GameState.run
	_spots["descend"].set_caption(tr("CAMP_DESCEND") % run.floor_index if run != null else tr("CAMP_NEW_RUN"))
	_spots["equipment"].set_caption(tr("EQUIP_TITLE"))
	_spots["merchant"].set_caption(tr("MERCHANT_TITLE"))
	_spots["records"].set_caption(tr("RECORDS_TITLE"))
	_spots["reflection"].set_caption(tr("REFLECTION_TITLE"))
	for c in _top.get_children():
		c.queue_free()
	var title := UiKit.title(_top, tr("CAMP_TITLE"), 40, Color(0.95, 0.85, 0.65))
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override(&"shadow_offset_y", 3)
	var w := UiKit.wallet(_top, p.gold, p.crystals, 34)
	w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.small_button(_top, tr("MENU_SETTINGS"), func() -> void: SettingsWindow.new().setup(self), 24)
	UiKit.small_button(_top, tr("CAMP_MENU"), func() -> void: GameState.to_menu(), 24)


func _layout() -> void:
	for id: String in SPOTS:
		(_spots[id] as Hotspot).place(UiKit.art_point(size, ART.get_size(), SPOTS[id]))


func _on_spot(id: String) -> void:
	var p := GameState.profile
	match id:
		"descend":
			GameState.descend()
		"equipment":
			var w := EquipmentWindow.new().setup(self, p)
			w.closed.connect(_closed)
		"merchant":
			var w := MerchantWindow.new().setup(self, p)
			w.closed.connect(_closed)
		"records":
			RecordsWindow.new().setup(self, p)
		"reflection":
			var w := ReflectionWindow.new().setup(self, p)
			w.closed.connect(_closed)


func _closed() -> void:
	GameState.save()
	_refresh()


## Dev (--demo=1): some gold, crystals and gear to look at the windows.
func _fill_demo_profile() -> void:
	var p := GameState.profile
	var rng := RngStreams.new(7).stream("demo", 1)
	p.gold = 2400
	p.crystals = 15
	p.best_floor = 6
	for i in 12:
		p.add_item(Loot.roll_item(["wood", "iron", "relic", "boss_executioner_morten"][i % 4], 2 + i % 6, rng))
	for it in p.inventory.duplicate():
		if not p.equipped.has(it.slot) and p.equipped.size() < 4:
			p.equip(it)
	p.refresh_merchant()
	p.record_floor(1, 61.0, 3)
	p.record_floor(2, 75.0, 2)
	_refresh()
