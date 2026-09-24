extends Node

signal dialogue_finished

var dialogue_ui = null
var dialogue_layer = null
var is_active := false
var skip_dialogue_confirmation_disabled := false

func start_dialogue(dialogue_data: Array, left_texture: Texture2D, right_texture: Texture2D) -> void:
	if is_active:

		return
	is_active = true
	GameManager.player_controls_locked = true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.velocity = Vector2.ZERO
		var animated_sprite = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if animated_sprite:
			animated_sprite.pause()
	dialogue_layer = get_tree().current_scene.get_node_or_null("UI") as CanvasLayer
	if dialogue_layer == null:
		print("ERROR: UI CanvasLayer not found.")
		is_active = false
		GameManager.player_controls_locked = false
		return
	dialogue_ui = dialogue_layer.get_node_or_null("DialogueUI") as Control
	if dialogue_ui == null:
		print("ERROR: DialogueUI not found under UI.")
		is_active = false
		GameManager.player_controls_locked = false
		return
	if dialogue_ui.has_method("start_dialogue"):
		dialogue_ui.start_dialogue(dialogue_data, left_texture, right_texture)
	else:
		print("ERROR: DialogueUI does not have start_dialogue().")
		is_active = false
		GameManager.player_controls_locked = false

func start_multi_dialogue(dialogue_data: Array, speaker_portraits: Dictionary, player_texture: Texture2D) -> void:
	if is_active:
		return
	# Dialogue is an interactive UI state, so the cursor must be visible.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	is_active = true
	GameManager.player_controls_locked = true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.velocity = Vector2.ZERO
		var animated_sprite = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if animated_sprite:
			animated_sprite.pause()
	dialogue_layer = get_tree().current_scene.get_node_or_null("UI") as CanvasLayer
	if dialogue_layer == null:
		print("ERROR: UI CanvasLayer not found.")
		is_active = false
		GameManager.player_controls_locked = false
		return
	dialogue_ui = dialogue_layer.get_node_or_null("DialogueUI") as Control
	if dialogue_ui == null:
		print("ERROR: DialogueUI not found under UI.")
		is_active = false
		GameManager.player_controls_locked = false
		return
	if dialogue_ui.has_method("start_multi_dialogue"):
		dialogue_ui.start_multi_dialogue(dialogue_data, speaker_portraits, player_texture)
	else:
		print("ERROR: DialogueUI does not have start_multi_dialogue().")
		is_active = false
		GameManager.player_controls_locked = false

func face_dialogue_participants(speaker_name: String) -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return

	var speaker: CharacterBody2D = null

	if speaker_name == "Player":
		speaker = player

		# If the player is speaking, face the nearest visible NPC toward the player too.
		var nearest_npc: CharacterBody2D = null
		var nearest_distance: float = INF

		for node in get_tree().get_nodes_in_group("npc"):
			var npc := node as CharacterBody2D
			if npc == null or not npc.is_inside_tree() or not npc.visible:
				continue

			var distance: float = npc.global_position.distance_to(player.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_npc = npc

		if nearest_npc != null:
			face_character_toward_character(player, nearest_npc)
			face_character_toward_character(nearest_npc, player)

		return

	var scene := get_tree().current_scene
	if scene != null:
		speaker = scene.get_node_or_null(NodePath(speaker_name)) as CharacterBody2D

		if speaker == null:
			speaker = scene.find_child(speaker_name, true, false) as CharacterBody2D

	if speaker == null:
		for node in get_tree().get_nodes_in_group("npc"):
			if node is CharacterBody2D and node.name == speaker_name:
				speaker = node as CharacterBody2D
				break

	if speaker == null or speaker == player:
		return

	face_character_toward_character(speaker, player)
	face_character_toward_character(player, speaker)

func face_character_toward_character(character: CharacterBody2D, target_character: CharacterBody2D) -> void:
	if character == null or target_character == null:
		return

	var difference := target_character.global_position - character.global_position
	if difference.length() <= 0.1:
		return

	var sprite := character.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	var animation_name := "idle_down"
	if abs(difference.x) > abs(difference.y):
		animation_name = "idle_right" if difference.x > 0.0 else "idle_left"
	else:
		animation_name = "idle_down" if difference.y > 0.0 else "idle_up"

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)
		sprite.pause()

func end_dialogue() -> void:
	if not is_active:
		return
	GameManager.player_controls_locked = false
	# Returning from dialogue restores normal gameplay cursor behavior.
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	dialogue_ui = null
	dialogue_layer = null
	is_active = false
	dialogue_finished.emit()
