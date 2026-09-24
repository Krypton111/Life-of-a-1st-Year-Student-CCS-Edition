extends Control

@export var drag_height: float = 90.0

var dragging: bool = false
var drag_start_mouse: Vector2 = Vector2.ZERO
var drag_start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var local_mouse: Vector2 = get_local_mouse_position()

				var drag_area := Rect2(
					0.0,
					0.0,
					size.x,
					drag_height
				)

				if drag_area.has_point(local_mouse):
					dragging = true
					drag_start_mouse = get_viewport().get_mouse_position()
					drag_start_position = global_position

			else:
				dragging = false

	elif event is InputEventMouseMotion and dragging:
		var current_mouse: Vector2 = get_viewport().get_mouse_position()
		var mouse_difference: Vector2 = current_mouse - drag_start_mouse

		var new_position: Vector2 = drag_start_position + mouse_difference

		var viewport_size: Vector2 = get_viewport_rect().size
		var browser_size: Vector2 = size

		var max_x: float = maxf(
			0.0,
			viewport_size.x - browser_size.x
		)

		var max_y: float = maxf(
			0.0,
			viewport_size.y - browser_size.y
		)

		new_position.x = clampf(
			new_position.x,
			0.0,
			max_x
		)

		new_position.y = clampf(
			new_position.y,
			0.0,
			max_y
		)

		global_position = new_position
