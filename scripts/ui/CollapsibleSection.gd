extends VBoxContainer
class_name CollapsibleSection

@export var expanded: bool = true
@export var header_text: String = "Section"

@onready var header_button: Button = $HeaderButton
@onready var content_container: VBoxContainer = $ContentContainer

func _ready() -> void:
	header_button.text = _get_header_label()
	header_button.pressed.connect(_toggle)
	_apply_state()

func _toggle() -> void:
	expanded = not expanded
	_apply_state()

func _apply_state() -> void:
	content_container.visible = expanded
	header_button.text = _get_header_label()

func _get_header_label() -> String:
	return ("▼ " if expanded else "▶ ") + header_text
