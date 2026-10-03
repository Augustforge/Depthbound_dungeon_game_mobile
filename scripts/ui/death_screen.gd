class_name DeathScreen
extends CanvasLayer
## Death (GDD 11.2): "You have fallen" / "The water took you"; retry the floor from its snapshot.

signal retry
signal new_run


func setup(cause: StringName) -> void:
	layer = 40
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := UiKit.dimmer(root, 0.0)
	var tw := create_tween()
	tw.tween_property(dim, "color", Color(0.05, 0.0, 0.0, 0.75) if cause == &"fell" else Color(0.0, 0.08, 0.1, 0.8), 1.2)
	var box := UiKit.centered_box(root, 760)
	UiKit.label(box, tr("DEATH_DROWNED" if cause == &"drowned" else "DEATH_FELL"), 64,
			Color(0.6, 0.9, 1.0) if cause == &"drowned" else Color(0.9, 0.3, 0.25))
	UiKit.button(box, tr("BTN_RETRY"), func() -> void: retry.emit())
	UiKit.button(box, tr("BTN_NEW_RUN"), func() -> void: new_run.emit())
