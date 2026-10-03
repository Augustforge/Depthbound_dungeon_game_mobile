class_name ConfirmWindow
extends UiWindow
## Yes / no question.


func ask(parent: Node, title_text: String, question: String, on_yes: Callable) -> ConfirmWindow:
	open(parent, title_text, Vector2(980, 0), 80)
	UiKit.label(body, question, 30)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 30)
	body.add_child(row)
	UiKit.button(row, tr("BTN_YES"), func() -> void:
		close()
		on_yes.call())
	UiKit.button(row, tr("BTN_NO"), close)
	return self
