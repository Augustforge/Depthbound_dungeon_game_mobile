class_name MerchantWindow
extends UiWindow
## Ulm the merchant (GDD 14.5): 6 items for gold, buys anything for 25 %, restock for crystals.

const TILE := Vector2(128, 100)

var profile: Profile
var _selected: Item
var _wallet: HBoxContainer
var _wallet_parent: HBoxContainer
var _stock: GridContainer
var _bag: GridContainer
var _bag_title: Label
var _details: VBoxContainer
var _refresh_btn: Button


func setup(parent: Node, p: Profile) -> MerchantWindow:
	profile = p
	open(parent, tr("MERCHANT_TITLE"), Vector2(1820, 900))
	_wallet_parent = HBoxContainer.new()
	_wallet_parent.add_theme_constant_override(&"separation", 40)
	body.add_child(_wallet_parent)
	var greet := UiKit.label(_wallet_parent, tr("MERCHANT_GREETING"), 26, UiKit.DIM_TEXT)
	greet.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	greet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 26)
	body.add_child(row)
	var stock_col := VBoxContainer.new()
	stock_col.custom_minimum_size = Vector2(440, 0)
	row.add_child(stock_col)
	UiKit.title(stock_col, tr("MERCHANT_STOCK"), 28, UiKit.DIM_TEXT)
	_stock = GridContainer.new()
	_stock.columns = 3
	EquipmentWindow._add_grid_gaps(_stock)
	stock_col.add_child(_stock)
	_refresh_btn = UiKit.small_button(stock_col, "", _paid_refresh, 24)
	var bag_col := VBoxContainer.new()
	row.add_child(bag_col)
	_bag_title = UiKit.title(bag_col, "", 28, UiKit.DIM_TEXT)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(690, 640)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bag_col.add_child(scroll)
	_bag = GridContainer.new()
	_bag.columns = 5
	EquipmentWindow._add_grid_gaps(_bag)
	scroll.add_child(_bag)
	_details = VBoxContainer.new()
	_details.custom_minimum_size = Vector2(470, 0)
	row.add_child(_details)
	if DevTools.arg("select") == "1" and not p.merchant_stock.is_empty():
		_selected = p.merchant_stock[0]
	refresh()
	return self


func refresh() -> void:
	if _wallet:
		_wallet.queue_free()
	_wallet = UiKit.wallet(_wallet_parent, profile.gold, profile.crystals)
	for c in _stock.get_children():
		c.queue_free()
	for it in profile.merchant_stock:
		var cell := VBoxContainer.new()
		_stock.add_child(cell)
		ItemTile.make(cell, it, _select.bind(it), "", it == _selected, TILE)
		UiKit.label(cell, "◆ %d" % it.price(), 22, UiKit.GOLD if profile.gold >= it.price() else Color(0.6, 0.45, 0.35))
	var cost := int(Item.cfg()["merchant"]["refresh_crystals"])
	_refresh_btn.text = tr("MERCHANT_REFRESH") % cost
	_refresh_btn.disabled = profile.crystals < cost
	for c in _bag.get_children():
		c.queue_free()
	_bag_title.text = tr("EQUIP_BAG") % [profile.inventory.size(), profile.inventory_size()]
	for it in profile.inventory:
		ItemTile.make(_bag, it, _select.bind(it), "", it == _selected, TILE)
	_show_details()


func _select(it: Item) -> void:
	_selected = it
	refresh()


func _show_details() -> void:
	for c in _details.get_children():
		c.queue_free()
	if _selected == null or not (profile.inventory.has(_selected) or profile.merchant_stock.has(_selected)):
		_selected = null
		UiKit.label(_details, tr("EQUIP_PICK"), 26, UiKit.DIM_TEXT)
		return
	var card := ItemCard.make(_details, _selected, profile.equipped.get(_selected.slot))
	if profile.merchant_stock.has(_selected):
		card.add_actions([{"text": tr("BTN_BUY") % _selected.price(), "cb": _buy,
			"disabled": not profile.can_buy(_selected)}])
		if profile.inventory_full():
			UiKit.label(_details, tr("MERCHANT_BAG_FULL"), 22, Color(0.95, 0.5, 0.4))
	else:
		card.add_actions([{"text": tr("BTN_SELL") % _selected.sell_price(), "cb": _sell}])


func _buy() -> void:
	if profile.buy(_selected):
		AudioManager.play(&"buy")
	GameState.save()
	refresh()


func _sell() -> void:
	profile.sell(_selected)
	_selected = null
	GameState.save()
	refresh()


func _paid_refresh() -> void:
	if profile.paid_refresh():
		_selected = null
		GameState.save()
	refresh()
