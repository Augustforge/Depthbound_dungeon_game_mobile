class_name RecordsWindow
extends UiWindow
## Record board (GDD 11.5, 17.1): best time and stars per floor, the dungeon's best total time
## and chest tier.


func setup(parent: Node, p: Profile) -> RecordsWindow:
	open(parent, tr("RECORDS_TITLE"), Vector2(1200, 900))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(&"h_separation", 40)
	grid.add_theme_constant_override(&"v_separation", 8)
	body.add_child(grid)
	for h in ["RECORDS_FLOOR", "RECORDS_NAME", "RECORDS_TIME", "RECORDS_STARS"]:
		UiKit.title(grid, tr(h), 26, UiKit.DIM_TEXT)
	for i in range(1, GameState.LAST_FLOOR + 1):
		var rec := p.floor_record(i)
		UiKit.label(grid, str(i), 28)
		var name_key := "FLOOR_%s_%02d" % [Profile.DUNGEON.to_upper(), i]
		var n := UiKit.label(grid, tr(name_key), 28)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiKit.label(grid, UiKit.time_text(float(rec["time"])) if not rec.is_empty() else "—", 28)
		UiKit.label(grid, UiKit.stars_text(int(rec.get("stars", 0))), 28, Color(1, 0.8, 0.3))
	var d := p.dungeon_record()
	var total := UiKit.time_text(float(d["best_total"])) if d["completed"] else "—"
	UiKit.label(body, tr("RECORDS_DUNGEON") % total, 30, UiKit.BRONZE)
	if int(d["best_tier"]) >= 0:
		UiKit.label(body, tr("RECORDS_TIER") % tr("CHEST_TIER_%d" % int(d["best_tier"])), 28, UiKit.GOLD)
	return self
