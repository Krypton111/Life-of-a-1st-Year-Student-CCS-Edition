extends Node

## ============================================================
## SAVE MANAGER - 10 SAVE SLOTS
## ============================================================
## Add this script as an Autoload named:
## SaveManager
##
## Saves are stored as:
## user://life_of_a_1st_year_student_save_01.json
## through:
## user://life_of_a_1st_year_student_save_10.json
## ============================================================

const SAVE_VERSION: int = 3
const MAX_SLOTS: int = 10
const SAVE_FILE_PREFIX: String = "user://life_of_a_1st_year_student_save_"
const SAVE_FILE_SUFFIX: String = ".json"
const SAVED_CONTROL_ACTIONS := ["move_up", "move_left", "move_down", "move_right", "interact", "toggle_quest_tracker"]

const META_KEYS := [
	"cafe_quest_route",
	"cafe_quest_phase",
	"cafe_order_ready",
	"cafe_order_phase",
	"cafe_solo_order_ready",
	"cafe_solo_order_talked_to_gelo",
	"cafe_friends_order_ready",
	"cafe_tina_order_result_recorded",
	"cafe_tina_player_correct",
	"cafe_tina_correct",
	"cafe_friends_order_result_recorded",
	"cafe_friends_wrong_count"
]

var is_loading: bool = false

const EXCLUDED_GAME_MANAGER_PROPERTIES := [
	"player_controls_locked",
	"tina_post_hallway_sequence_started",
	"tina_post_hallway_sequence_running",
	"returning_from_tina_dream"
]


func get_save_path(slot: int) -> String:
	if slot < 1 or slot > MAX_SLOTS:
		return ""

	return SAVE_FILE_PREFIX + "%02d" % slot + SAVE_FILE_SUFFIX


func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= MAX_SLOTS


func has_save(slot: int) -> bool:
	var path: String = get_save_path(slot)
	return not path.is_empty() and FileAccess.file_exists(path)


func get_slot_info(slot: int) -> Dictionary:
	var info: Dictionary = {
		"slot": slot,
		"exists": false,
		"saved_at": "",
		"scene_path": ""
	}

	if not is_valid_slot(slot):
		return info

	var slot_path: String = get_save_path(slot)

	if not FileAccess.file_exists(slot_path):
		return info

	var file := FileAccess.open(slot_path, FileAccess.READ)

	if file == null:
		return info

	var raw_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()

	if json.parse(raw_text) != OK:
		return info

	if not json.data is Dictionary:
		return info

	var data: Dictionary = json.data
	info["exists"] = true
	info["saved_at"] = str(data.get("saved_at", ""))
	info["scene_path"] = str(data.get("scene_path", ""))

	return info


func get_all_slot_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for slot in range(1, MAX_SLOTS + 1):
		result.append(get_slot_info(slot))

	return result


func is_player_locked() -> bool:
	# Dialogue is the strongest signal that the player cannot act right now.
	if is_instance_valid(DialogueManager):
		if bool(DialogueManager.get("is_active")):
			return true

	if not is_instance_valid(GameManager):
		return false

	if property_exists(GameManager, "player_controls_locked"):
		if bool(GameManager.get("player_controls_locked")):
			return true

	for property_name in [
		"tina_post_hallway_sequence_running",
		"returning_from_tina_dream"
	]:
		if property_exists(GameManager, property_name):
			if bool(GameManager.get(property_name)):
				return true

	return false


func save_game(slot: int) -> bool:
	if not is_valid_slot(slot):
		push_warning("SaveManager: Invalid save slot: " + str(slot))
		return false

	# Refuse to save while a dialogue or cutscene is active. This is a defense
	# in depth check — the PauseMenu also blocks this, but we never want a
	# save to sneak through from any other call site either.
	if is_player_locked():
		push_warning("SaveManager: Cannot save while the player is locked (dialogue/cutscene).")
		return false

	var current_scene := get_tree().current_scene

	if current_scene == null:
		push_warning("SaveManager: No current scene to save.")
		return false

	var save_data: Dictionary = {
		"save_version": SAVE_VERSION,
		"slot": slot,
		"saved_at": Time.get_datetime_string_from_system(),
		"scene_path": current_scene.scene_file_path,
		"game_manager": collect_game_manager_state(),
		"metadata": collect_metadata(),
		"player_profile": collect_player_profile(),
		"controls": collect_controls()
	}

	var player := find_player(current_scene)

	if player != null:
		save_data["player_position"] = {
			"x": player.global_position.x,
			"y": player.global_position.y
		}
	else:
		save_data["player_position"] = null

	var save_path: String = get_save_path(slot)
	var file := FileAccess.open(save_path, FileAccess.WRITE)

	if file == null:
		push_error(
			"SaveManager: Could not open save slot for writing. Error: "
			+ str(FileAccess.get_open_error())
		)
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	print("SAVE COMPLETE - SLOT ", slot, ": ", save_path)
	return true


func load_game(slot: int) -> bool:
	if not is_valid_slot(slot):
		push_warning("SaveManager: Invalid save slot: " + str(slot))
		return false

	var load_path: String = get_save_path(slot)

	if not FileAccess.file_exists(load_path):
		push_warning("SaveManager: Slot " + str(slot) + " is empty.")
		return false

	var file := FileAccess.open(load_path, FileAccess.READ)

	if file == null:
		push_error("SaveManager: Could not open save slot.")
		return false

	var raw_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result: int = json.parse(raw_text)

	if parse_result != OK:
		push_error("SaveManager: Save slot is corrupted or invalid JSON.")
		return false

	var save_data: Variant = json.data

	if not save_data is Dictionary:
		push_error("SaveManager: Save slot does not contain a valid dictionary.")
		return false

	var scene_path: String = str(save_data.get("scene_path", ""))

	if scene_path.is_empty():
		push_error("SaveManager: Save slot has no scene path.")
		return false

	# Make sure the tree is not paused before swapping scenes, otherwise the
	# new scene will spawn already frozen.
	is_loading = true
	get_tree().paused = false

	# Restore persistent state BEFORE changing scenes so _ready() can see it.
	restore_player_profile(save_data.get("player_profile", {}))
	restore_controls(save_data.get("controls", {}))
	restore_game_manager_state(save_data.get("game_manager", {}))
	restore_metadata(save_data.get("metadata", {}))
	reset_runtime_flags()

	var change_error: Error = get_tree().change_scene_to_file(scene_path)

	if change_error != OK:
		is_loading = false
		push_error(
			"SaveManager: Could not load scene: "
			+ scene_path
			+ " Error: "
			+ str(change_error)
		)
		return false

	# Wait for the scene swap and the new scene's _ready() to finish.
	await get_tree().scene_changed
	await get_tree().process_frame

	var new_scene := get_tree().current_scene

	if new_scene == null:
		push_error("SaveManager: Loaded scene is null.")
		return false

	# Re-apply metadata AFTER _ready() in case the scene touched it.
	restore_metadata(save_data.get("metadata", {}))
	reset_runtime_flags()

	# Clear any lock the freshly-loaded scene might have set based on stale
	# state. This guarantees the player can move after loading.
	force_clear_player_locks()

	var player := find_player(new_scene)

	if player != null:
		var saved_position: Variant = save_data.get("player_position", null)

		if saved_position is Dictionary:
			var x: float = float(saved_position.get("x", player.global_position.x))
			var y: float = float(saved_position.get("y", player.global_position.y))

			player.global_position = Vector2(x, y)

			if player is CharacterBody2D:
				player.velocity = Vector2.ZERO

			# A loaded scene creates a fresh Player node. Explicitly restore
			# its processing state because an earlier pause/cutscene may have
			# disabled physics processing on the previous Player instance.
			player.process_mode = Node.PROCESS_MODE_PAUSABLE
			player.set_process(true)
			player.set_physics_process(true)

	# Ensure the tree isn't paused and the mouse is hidden for gameplay.
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	is_loading = false

	print("LOAD COMPLETE - SLOT ", slot, ": ", scene_path)
	return true


func delete_save(slot: int) -> bool:
	if not is_valid_slot(slot):
		return false

	if not has_save(slot):
		return true

	var delete_path: String = get_save_path(slot)
	var delete_error: Error = DirAccess.remove_absolute(delete_path)

	if delete_error != OK:
		push_error(
			"SaveManager: Could not delete save slot. Error: "
			+ str(delete_error)
		)
		return false

	return true


func reset_runtime_flags() -> void:
	for property_name in EXCLUDED_GAME_MANAGER_PROPERTIES:
		if not property_exists(GameManager, property_name):
			continue

		GameManager.set(property_name, false)
		print("SaveManager: cleared runtime flag -> ", property_name)


func force_clear_player_locks() -> void:
	if not is_instance_valid(GameManager):
		return

	for property_name in EXCLUDED_GAME_MANAGER_PROPERTIES:
		if property_exists(GameManager, property_name):
			GameManager.set(property_name, false)


func collect_player_profile() -> Dictionary:
	return {
		"player_name": str(PlayerSetup.player_name),
		"player_gender": str(PlayerSetup.player_gender)
	}


func restore_player_profile(profile: Variant) -> void:
	if not is_instance_valid(PlayerSetup):
		return
	if profile is Dictionary:
		PlayerSetup.player_name = str(profile.get("player_name", ""))
		PlayerSetup.player_gender = str(profile.get("player_gender", ""))
	else:
		PlayerSetup.clear_profile()


func collect_controls() -> Dictionary:
	var result: Dictionary = {}
	for action in SAVED_CONTROL_ACTIONS:
		var saved_key := 0
		if InputMap.has_action(action):
			for event in InputMap.action_get_events(action):
				if event is InputEventKey:
					var key_event := event as InputEventKey
					saved_key = int(key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode)
					break
		result[action] = saved_key
	return result


func restore_controls(controls: Variant) -> void:
	if not controls is Dictionary:
		return
	for action in SAVED_CONTROL_ACTIONS:
		if not controls.has(action):
			continue
		var key_code := int(controls.get(action, 0))
		if key_code == 0:
			continue
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key_code
		key_event.keycode = key_code
		InputMap.action_add_event(action, key_event)


func collect_game_manager_state() -> Dictionary:
	var result: Dictionary = {}

	if not is_instance_valid(GameManager):
		return result

	for property_info in GameManager.get_property_list():
		var property_name: String = str(property_info.get("name", ""))

		if property_name.is_empty():
			continue

		if property_name in EXCLUDED_GAME_MANAGER_PROPERTIES:
			continue

		var usage: int = int(property_info.get("usage", 0))

		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue

		var value: Variant = GameManager.get(property_name)

		# Never write the temporary "all achievements" testing state into a save.
		# Save the real pre-toggle snapshot so loading this slot later cannot
		# permanently grant achievements that were only enabled for testing.
		if (
			property_name == "achievements_unlocked"
			and is_instance_valid(AchievementManager)
			and AchievementManager.are_all_achievements_enabled()
		):
			value = AchievementManager.achievements_before_override.duplicate(true)

		var encoded: Variant = encode_value(value)

		if encoded != null:
			result[property_name] = encoded

	return result


func restore_game_manager_state(state: Variant) -> void:
	if not is_instance_valid(GameManager):
		return

	# Never carry achievements from the previously loaded session into a save
	# that predates achievement support or lacks this field. A saved dictionary
	# below replaces this empty one when the slot contains achievement history.
	if property_exists(GameManager, "achievements_unlocked"):
		GameManager.set("achievements_unlocked", {})

	if not state is Dictionary:
		return

	for property_name in state.keys():
		var property_name_string: String = str(property_name)

		if property_name_string in EXCLUDED_GAME_MANAGER_PROPERTIES:
			continue

		if not property_exists(GameManager, property_name_string):
			continue

		var value: Variant = decode_value(state[property_name])

		if value != null:
			GameManager.set(property_name_string, value)


func collect_metadata() -> Dictionary:
	var result: Dictionary = {}

	for key in META_KEYS:
		if GameManager.has_meta(key):
			var encoded: Variant = encode_value(GameManager.get_meta(key))

			if encoded != null:
				result[key] = encoded

	return result


func restore_metadata(metadata: Variant) -> void:
	# Metadata absent from an older/other save must not leak across save slots.
	for key in META_KEYS:
		if GameManager.has_meta(key):
			GameManager.remove_meta(key)

	if not metadata is Dictionary:
		return

	for key in metadata.keys():
		var value: Variant = decode_value(metadata[key])

		if value != null:
			GameManager.set_meta(str(key), value)


func encode_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_NIL:
			return {"__type": "nil"}

		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value

		TYPE_STRING_NAME:
			return {
				"__type": "string_name",
				"value": str(value)
			}

		TYPE_VECTOR2:
			return {
				"__type": "vector2",
				"x": value.x,
				"y": value.y
			}

		TYPE_VECTOR2I:
			return {
				"__type": "vector2i",
				"x": value.x,
				"y": value.y
			}

		TYPE_COLOR:
			return {
				"__type": "color",
				"r": value.r,
				"g": value.g,
				"b": value.b,
				"a": value.a
			}

		TYPE_ARRAY:
			var encoded_array: Array = []

			for item in value:
				var encoded_item: Variant = encode_value(item)

				if encoded_item == null:
					return null

				encoded_array.append(encoded_item)

			return encoded_array

		TYPE_DICTIONARY:
			var encoded_dictionary: Dictionary = {}

			for key in value.keys():
				var encoded_key: Variant = encode_value(key)
				var encoded_item: Variant = encode_value(value[key])

				if encoded_key == null or encoded_item == null:
					return null

				encoded_dictionary[str(encoded_key)] = encoded_item

			return encoded_dictionary

		_:
			return null


func decode_value(value: Variant) -> Variant:
	if value is Dictionary and value.has("__type"):
		var type_name: String = str(value["__type"])

		match type_name:
			"nil":
				return null

			"string_name":
				return StringName(str(value.get("value", "")))

			"vector2":
				return Vector2(
					float(value.get("x", 0.0)),
					float(value.get("y", 0.0))
				)

			"vector2i":
				return Vector2i(
					int(value.get("x", 0)),
					int(value.get("y", 0))
				)

			"color":
				return Color(
					float(value.get("r", 0.0)),
					float(value.get("g", 0.0)),
					float(value.get("b", 0.0)),
					float(value.get("a", 1.0))
				)

	if value is Array:
		var decoded_array: Array = []

		for item in value:
			decoded_array.append(decode_value(item))

		return decoded_array

	if value is Dictionary:
		var decoded_dictionary: Dictionary = {}

		for key in value.keys():
			decoded_dictionary[key] = decode_value(value[key])

		return decoded_dictionary

	return value


func property_exists(object: Object, property_name: String) -> bool:
	for property_info in object.get_property_list():
		if str(property_info.get("name", "")) == property_name:
			return true

	return false


func find_player(root: Node) -> Node:
	if root == null:
		return null

	var player := root.find_child("Player", true, false)

	if player != null:
		return player

	return find_character_body(root)


func find_character_body(node: Node) -> Node:
	if node is CharacterBody2D and str(node.name).to_lower() == "player":
		return node

	for child in node.get_children():
		var result := find_character_body(child)

		if result != null:
			return result

	return null
