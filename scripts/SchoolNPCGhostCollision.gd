extends Node

# SCHOOL NPC GHOST COLLISION CONTROLLER
# This disables collisions for Friends and Bullies while they are hidden.
# When an NPC becomes visible again, their original collision settings are restored.

const HIDDEN_NPC_NAMES: Array[String] = [
	"Kairi",
	"Kerwin",
	"Janssen",
	"Nathaly",
	"Joe",
	"Joey",
	"Joseph"
]

var original_collision_data: Dictionary = {}


func _ready() -> void:

	for npc_name in HIDDEN_NPC_NAMES:

		var npc := get_parent().get_node_or_null(npc_name) as CharacterBody2D

		if npc == null:
			continue

		store_original_collision_data(npc)

		if not npc.visibility_changed.is_connected(
			_on_npc_visibility_changed.bind(npc)
		):
			npc.visibility_changed.connect(
			_on_npc_visibility_changed.bind(npc)
			)

		update_npc_collision(npc)


func _on_npc_visibility_changed(npc: CharacterBody2D) -> void:

	if npc == null or not is_instance_valid(npc):
		return

	update_npc_collision(npc)


func store_original_collision_data(npc: CharacterBody2D) -> void:

	if npc == null or original_collision_data.has(npc):
		return

	var shape_data: Array = []

	var collision_shapes := npc.find_children(
		"CollisionShape2D",
		"CollisionShape2D",
		true,
		false
	)

	for node in collision_shapes:

		var shape := node as CollisionShape2D

		if shape != null:
			shape_data.append({
				"node": shape,
				"disabled": shape.disabled
			})

	original_collision_data[npc] = {
		"layer": npc.collision_layer,
		"mask": npc.collision_mask,
		"shapes": shape_data
	}


func update_npc_collision(npc: CharacterBody2D) -> void:

	if npc == null or not original_collision_data.has(npc):
		return

	if npc.visible:
		restore_npc_collision(npc)
	else:
		disable_npc_collision(npc)


func disable_npc_collision(npc: CharacterBody2D) -> void:

	# Hidden NPCs should never block the player.
	npc.collision_layer = 0
	npc.collision_mask = 0

	var collision_shapes := npc.find_children(
		"CollisionShape2D",
		"CollisionShape2D",
		true,
		false
	)

	for node in collision_shapes:

		var shape := node as CollisionShape2D

		if shape != null:
			shape.set_deferred("disabled", true)


func restore_npc_collision(npc: CharacterBody2D) -> void:

	if npc == null or not original_collision_data.has(npc):
		return

	var data: Dictionary = original_collision_data[npc]

	npc.collision_layer = int(data["layer"])
	npc.collision_mask = int(data["mask"])

	var shape_data: Array = data["shapes"]

	for entry in shape_data:

		var shape := entry["node"] as CollisionShape2D

		if shape != null and is_instance_valid(shape):
			shape.set_deferred(
				"disabled",
				bool(entry["disabled"])
			)
