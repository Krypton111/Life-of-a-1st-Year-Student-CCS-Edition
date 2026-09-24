extends CharacterBody2D

@export var interaction_distance: float = 60.0


func can_interact(player: CharacterBody2D) -> bool:

	if player == null:
		return false

	var distance: float = global_position.distance_to(
		player.global_position
	)

	return distance <= interaction_distance
