extends Control
## End of the dungeon (GDD 11.4, 17.2 #11): total time, stars, the final chest by star share.

const ART := preload("res://assets/ui/main_menu.webp")


func _ready() -> void:
	UiKit.cover_art(self, ART)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var p := GameState.profile
	var box := UiKit.centered_box(self, 1100)
	UiKit.title(box, tr("FINAL_TITLE"), 56, UiKit.GOLD)
	if p.run == null or p.run.floor_index <= GameState.LAST_FLOOR:
		UiKit.button(box, tr("BTN_TO_CAMP"), GameState.to_camp)
		return
	var got := 0
	for i in range(1, GameState.LAST_FLOOR + 1):
		got += int(p.run.stars.get(str(i), 0))
	var out := Progress.finish_dungeon(p, GameState.LAST_FLOOR)
	GameState.save()
	UiKit.label(box, tr("FINAL_TIME") % UiKit.time_text(float(out["total_time"])), 34)
	UiKit.label(box, tr("FINAL_DEATHS") % int(out["deaths"]), 28, UiKit.DIM_TEXT)
	UiKit.label(box, "★ %d / %d" % [got, 3 * GameState.LAST_FLOOR], 40, Color(1, 0.8, 0.3))
	if out["new_record"]:
		UiKit.label(box, tr("FINAL_RECORD"), 30, Color(0.5, 0.95, 0.5))
	var tier := int(out["tier"])
	UiKit.title(box, tr("FINAL_CHEST") % tr("CHEST_TIER_%d" % tier), 40,
		[Color(0.8, 0.55, 0.35), Color(0.8, 0.82, 0.88), UiKit.GOLD, Color(1.0, 0.6, 0.2)][tier])
	if out["granted"]:
		UiKit.wallet(box, int(out["gold"]), int(out["crystals"]), 34).alignment = BoxContainer.ALIGNMENT_CENTER
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override(&"separation", 12)
		box.add_child(row)
		for it: Item in out["items"]:
			ItemTile.make(row, it, func() -> void: pass)
	else:
		UiKit.label(box, tr("FINAL_NO_CHEST"), 26, UiKit.DIM_TEXT)
	UiKit.button(box, tr("BTN_TO_CAMP"), GameState.to_camp)
