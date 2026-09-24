extends Area2D

@export var interaction_distance: float = 20.0

var collected: bool = false


func _ready() -> void:
	add_to_group("bookstore_item")


func get_item_type() -> String:

	match name:

		"YellowPad":
			return "YellowPad"

		"Ballpen1":
			return "Ballpen"

		"Ballpen2":
			return "Ballpen"

		"Ballpen3":
			return "Ballpen"

		"CorrectionTape":
			return "CorrectionTape"

		"DiscreteMathBook":
			return "DiscreteMathBook"

		_:
			return ""


func get_interaction_position() -> Vector2:

	var sprite := get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite:
		return sprite.global_position

	return global_position


func can_interact(player: CharacterBody2D) -> bool:

	if collected:
		return false

	if not visible:
		return false

	if player == null:
		return false

	var distance: float = get_interaction_position().distance_to(
		player.global_position
	)

	return distance <= interaction_distance


func collect_item() -> void:

	if collected:
		return

	var bookstore_controller := get_tree().current_scene.get_node_or_null(
		"BookstoreController"
	)

	if bookstore_controller == null:
		print("ERROR: BookstoreController not found.")
		return

	var item_type: String = get_item_type()

	print(
		"COLLECT ITEM REQUEST: ",
		name,
		" | TYPE: ",
		item_type
	)

	match item_type:

		"YellowPad":

			bookstore_controller.collect_yellow_pad()

		"Ballpen":

			bookstore_controller.collect_ballpen()

		"CorrectionTape":

			bookstore_controller.collect_correction_tape()

		"DiscreteMathBook":

			bookstore_controller.collect_discrete_math_book()

		_:

			print(
				"ERROR: UNKNOWN ITEM NAME: ",
				name
			)

			return

	collected = true

	visible = false

	var collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if collision:
		collision.set_deferred(
			"disabled",
			true
		)

	print(
		"BOOKSTORE ITEM COLLECTED: ",
		name,
		" | TYPE: ",
		item_type
	)
