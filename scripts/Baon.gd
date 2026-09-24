extends Area2D

@export var interaction_distance: float = 50.0
@export var visible_z_index: int = 10

var collected: bool = false


func _ready() -> void:

	add_to_group("house_interactable")

	# Make sure the baon is visible when the house scene starts.
	visible = true
	modulate = Color.WHITE
	z_index = visible_z_index

	var sprite := get_node_or_null("Sprite2D") as Sprite2D

	if sprite:
		sprite.visible = true
		sprite.modulate = Color.WHITE
		sprite.z_index = visible_z_index

		if sprite.texture == null:
			print("WARNING: Baon/Sprite2D has no texture assigned.")

	# If the player already collected the baon, keep it hidden.
	if GameManager.has_baon:
		collected = true
		visible = false
		disable_collision()


func can_interact(player: CharacterBody2D) -> bool:

	if player == null:
		return false

	if collected:
		return false

	if not visible:
		return false

	return global_position.distance_to(
		player.global_position
	) <= interaction_distance


func interact() -> void:

	if collected:
		return

	collected = true
	GameManager.has_baon = true

	# Picking up the baon immediately completes the house objective.
	var quest_manager := get_node_or_null("/root/QuestUIManager")
	if quest_manager != null and quest_manager.has_method("complete_baon"):
		quest_manager.complete_baon()

	visible = false
	disable_collision()


func disable_collision() -> void:

	var collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if collision:
		collision.set_deferred(
			"disabled",
			true
		)
