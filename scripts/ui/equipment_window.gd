class_name EquipmentWindow
extends UiWindow
## Equipment (GDD 14.3, 17.1): hero stats, 6 slots, the 30-cell bag, item details with the
## difference against the equipped item. Opened in the camp, the pause menu and the floor summary.
## Emits `gear_changed` so a running floor can re-apply the gear to the hero.

signal gear_changed

const TILE := Vector2(128, 100)

var profile: Profile
var _selected: Item
var _stats_box: VBoxContainer
var _slots_box: GridContainer
var _bag_title: Label
var _bag: GridContainer
var _details: VBoxContainer


func setup(parent: Node, p: Profile) -> EquipmentWindow:
	profile = p
	open(parent, tr("EQUIP_TITLE"), Vector2(1820, 900))
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 26)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	_stats_box = _column(row, 300)
	var slots_col := _column(row, 270)
	UiKit.title(slots_col, tr("EQUIP_SLOTS"), 28, UiKit.DIM_TEXT)
	_slots_box = GridContainer.new()
	_slots_box.columns = 2
	_add_grid_gaps(_slots_box)
	slots_col.add_child(_slots_box)
	var bag_col := _column(row, 690)
	_bag_title = UiKit.title(bag_col, "", 28, UiKit.DIM_TEXT)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(690, 650)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bag_col.add_child(scroll)
	_bag = GridContainer.new()
	_bag.columns = 5
	_add_grid_gaps(_bag)
	scroll.add_child(_bag)
	_details = _column(row, 470)
	if DevTools.arg("select") == "1" and not p.inventory.is_empty():
		_selected = p.inventory[0]
	refresh()
	return self


func refresh() -> void:
	for c in _stats_box.get_children():
		c.queue_free()
	UiKit.title(_stats_box, tr("EQUIP_STATS"), 28, UiKit.DIM_TEXT)
	for line in HeroStats.lines(profile):
		var r := HBoxContainer.new()
		_stats_box.add_child(r)
		var n := UiKit.label(r, tr(String(line["key"])), 24, UiKit.DIM_TEXT)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.autowrap_mode = TextServer.AUTOWRAP_OFF
		UiKit.label(r, String(line["value"]), 26, UiKit.TEXT).autowrap_mode = TextServer.AUTOWRAP_OFF
	for c in _slots_box.get_children():
		c.queue_free()
	for slot: Variant in Item.cfg()["slots"]:
		var it: Item = profile.equipped.get(StringName(slot))
		ItemTile.make(_slots_box, it, _select.bind(it) if it != null else func() -> void: pass,
			tr("SLOT_" + String(slot).to_upper()), it != null and it == _selected, TILE)
	for c in _bag.get_children():
		c.queue_free()
	_bag_title.text = tr("EQUIP_BAG") % [profile.inventory.size(), profile.inventory_size()]
	for it in profile.inventory:
		ItemTile.make(_bag, it, _select.bind(it), "", it == _selected, TILE)
	for i in profile.inventory_size() - profile.inventory.size():
		ItemTile.make(_bag, null, func() -> void: pass, "", false, TILE)
	_show_details()


func _select(it: Item) -> void:
	_selected = it
	refresh()


func _show_details() -> void:
	for c in _details.get_children():
		c.queue_free()
	if _selected == null or (not profile.inventory.has(_selected) and profile.equipped.get(_selected.slot) != _selected):
		_selected = null
		UiKit.label(_details, tr("EQUIP_PICK"), 26, UiKit.DIM_TEXT)
		return
	var worn: bool = profile.equipped.get(_selected.slot) == _selected
	var card := ItemCard.make(_details, _selected, profile.equipped.get(_selected.slot), not worn)
	if worn:
		card.add_actions([{"text": tr("BTN_UNEQUIP"), "cb": _unequip, "disabled": profile.inventory_full()}])
	else:
		card.add_actions([{"text": tr("BTN_EQUIP"), "cb": _equip}])


func _equip() -> void:
	profile.equip(_selected)
	gear_changed.emit()
	refresh()


func _unequip() -> void:
	if profile.unequip(_selected.slot):
		gear_changed.emit()
	refresh()


func _column(parent: Node, width: float) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.custom_minimum_size = Vector2(width, 0)
	c.add_theme_constant_override(&"separation", 10)
	parent.add_child(c)
	return c


static func _add_grid_gaps(g: GridContainer) -> void:
	g.add_theme_constant_override(&"h_separation", 10)
	g.add_theme_constant_override(&"v_separation", 10)
