class_name NoteWindow
extends CanvasLayer
## A prisoner's note (GDD 3.6): text window; the floor timer is paused while it is open.

signal closed


func setup(key: String) -> void:
	layer = 45
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	UiKit.dimmer(root, 0.55)
	var box := UiKit.centered_box(root, 900)
	UiKit.label(box, tr("NOTE_TITLE"), 34, UiKit.BRONZE)
	UiKit.label(box, tr(key), 38, Color(0.92, 0.88, 0.76))
	UiKit.button(box, tr("BTN_CLOSE"), func() -> void:
		closed.emit()
		queue_free())
