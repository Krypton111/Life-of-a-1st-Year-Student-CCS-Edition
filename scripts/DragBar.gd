extends Control

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

@onready var browser: Control = get_parent()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = get_global_mouse_position() - browser.global_position
			else:
				dragging = false

	elif event is InputEventMouseMotion and dragging:
		browser.global_position = get_global_mouse_position() - drag_offset
