class_name UiWindow
extends CanvasLayer
## A modal window: dimmed background, bronze panel, title and a close button. Content goes into
## `body`. Emits `closed` and frees itself when closed.

signal closed

var body: VBoxContainer
var panel: PanelContainer
var _title: Label


func open(parent: Node, title_text: String, size: Vector2 = Vector2(1500, 860), layer_index: int = 50) -> UiWindow:
	layer = layer_index
	parent.add_child(self)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	UiKit.dimmer(root, 0.75)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	panel = UiKit.panel(center)
	panel.custom_minimum_size = size
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override(&"separation", 16)
	panel.add_child(outer)
	var head := HBoxContainer.new()
	outer.add_child(head)
	_title = UiKit.title(head, title_text, 44)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var close_btn := UiKit.small_button(head, "✗", close, 34)
	close_btn.custom_minimum_size = Vector2(80, 64)
	body = VBoxContainer.new()
	body.add_theme_constant_override(&"separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)
	AudioManager.play(&"ui_open")
	return self


func set_title(text: String) -> void:
	_title.text = text


func clear_body() -> void:
	for c in body.get_children():
		c.queue_free()


func close() -> void:
	AudioManager.play(&"ui_close")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
