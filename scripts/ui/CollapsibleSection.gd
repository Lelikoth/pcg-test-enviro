class_name CollapsibleSection
extends VBoxContainer

## Provides a reusable UI section whose content can be expanded or collapsed.
##
## The header button displays the section title together with an indicator
## showing the current expansion state.


const EXPANDED_INDICATOR: String = "▼"
const COLLAPSED_INDICATOR: String = "▶"


## Controls whether the section content is initially visible.
@export var expanded: bool = true

## Text displayed in the section header.
@export var header_text: String = "Section"


@onready var header_button: Button = $HeaderButton
@onready var content_container: VBoxContainer = $ContentContainer


func _ready() -> void:
	header_button.pressed.connect(_toggle)
	_apply_state()


## Toggles the section between expanded and collapsed states.
func _toggle() -> void:
	expanded = not expanded
	_apply_state()


## Updates content visibility and the header label.
func _apply_state() -> void:
	content_container.visible = expanded
	header_button.text = _get_header_label()


## Builds the header label for the current expansion state.
func _get_header_label() -> String:
	var indicator := (
		EXPANDED_INDICATOR
		if expanded
		else COLLAPSED_INDICATOR
	)

	return "%s %s" % [
		indicator,
		header_text
	]
