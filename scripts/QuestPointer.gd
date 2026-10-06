extends Node2D


# ============================================================
# QUEST POINTER SETTINGS
# ============================================================

const POINTER_HEIGHT: float = 50.0
const POINTER_SIZE: float = 9.0
const POINTER_BOB_HEIGHT: float = 4.0
const POINTER_BOB_SPEED: float = 3.0

const POINTER_RETRACT_DISTANCE: float = 150.0
const PLAYER_FADE_DISTANCE: float = 120.0

const POINTER_MIN_DISTANCE: float = 0.0
const POINTER_FOLLOW_FACTOR: float = 0.55

const POINTER_COLOR: Color = Color("#F6D889")
const POINTER_OUTLINE_COLOR: Color = Color("#4A3020")


# ============================================================
# REFERENCES
# ============================================================

var player: Node2D = null
var quest_target: Node2D = null

var quest_pointer_time: float = 0.0

var markers: Dictionary = {}

# Scene whose markers are currently loaded.
var marker_scene: Node = null


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	player = get_parent() as Node2D

	z_index = 1000

	await get_tree().process_frame

	_find_all_markers()

	marker_scene = get_tree().current_scene

	queue_redraw()


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	# --------------------------------------------------------
	# Make sure we always have the current Player.
	# --------------------------------------------------------

	if player == null or not is_instance_valid(player):

		player = _find_player()

		if player == null:
			queue_redraw()
			return


	quest_pointer_time += delta


	# --------------------------------------------------------
	# Refresh markers if the scene changed.
	# --------------------------------------------------------

	_refresh_markers_if_scene_changed()


	# --------------------------------------------------------
	# Determine the current quest target.
	# --------------------------------------------------------

	_update_target()


	queue_redraw()


# ============================================================
# FIND PLAYER
# ============================================================

func _find_player() -> Node2D:

	var current_scene: Node = get_tree().current_scene

	if current_scene == null:
		return null


	var player_node: Node = current_scene.find_child(
		"Player",
		true,
		false
	)


	if player_node != null and player_node is Node2D:
		return player_node as Node2D


	return null


# ============================================================
# REFRESH MARKERS WHEN SCENE CHANGES
# ============================================================

func _refresh_markers_if_scene_changed() -> void:

	var current_scene: Node = get_tree().current_scene

	if current_scene == null:
		return


	if current_scene != marker_scene:

		marker_scene = current_scene

		_find_all_markers()

		quest_target = null


# ============================================================
# FIND ALL QUEST MARKERS
# ============================================================

func _find_all_markers() -> void:

	var current_scene: Node = get_tree().current_scene

	if current_scene == null:
		return


	markers.clear()


	# ========================================================
	# HOUSE
	# ========================================================

	markers["baon"] = _find_marker(
		current_scene,
		"QuestMarker_Baon"
	)

	markers["out"] = _find_marker(
		current_scene,
		"QuestMarker_Out"
	)


	# ========================================================
	# SCHOOL HALLWAY
	# ========================================================

	markers["comlab202"] = _find_marker(
		current_scene,
		"QuestMarker_Comlab202"
	)

	markers["maclab"] = _find_marker(
		current_scene,
		"QuestMarker_Maclab"
	)

	markers["lecture_room"] = _find_marker(
		current_scene,
		"QuestMarker_LectureRoom"
	)


	# ========================================================
	# COMLAB
	# ========================================================

	markers["talk1"] = _find_marker(
		current_scene,
		"QuestMarker_Talk1"
	)

	markers["challenge1"] = _find_marker(
		current_scene,
		"QuestMarker_Challenge1"
	)

	markers["door1"] = _find_marker(
		current_scene,
		"QuestMarker_Door1"
	)


	# ========================================================
	# MAC LAB
	# ========================================================

	markers["talk2"] = _find_marker(
		current_scene,
		"QuestMarker_Talk2"
	)

	markers["challenge2"] = _find_marker(
		current_scene,
		"QuestMarker_Challenge2"
	)

	markers["door2"] = _find_marker(
		current_scene,
		"QuestMarker_Door2"
	)


	# ========================================================
	# LECTURE ROOM
	# ========================================================

	markers["talk3"] = _find_marker(
		current_scene,
		"QuestMarker_Talk3"
	)

	markers["challenge3"] = _find_marker(
		current_scene,
		"QuestMarker_Challenge3"
	)

	markers["door3"] = _find_marker(
		current_scene,
		"QuestMarker_Door3"
	)


# ============================================================
# FIND MARKER
# ============================================================

func _find_marker(
	root: Node,
	marker_name: String
) -> Node2D:

	if root == null:
		return null


	var marker_node: Node = root.find_child(
		marker_name,
		true,
		false
	)


	if marker_node != null and marker_node is Node2D:
		return marker_node as Node2D


	return null


# ============================================================
# UPDATE QUEST TARGET
# ============================================================

func _update_target() -> void:

	# --------------------------------------------------------
	# Do not show pointer during locked events/dialogue.
	# --------------------------------------------------------

	if not _should_draw():

		quest_target = null

		return


	var scene: Node = get_tree().current_scene

	if scene == null:

		quest_target = null

		return


	# --------------------------------------------------------
	# Get filename.
	# --------------------------------------------------------

	var scene_name: String = (
		scene.scene_file_path
		.get_file()
		.to_lower()
	)


	# --------------------------------------------------------
	# IMPORTANT:
	# Remove underscores so:
	#
	# mac_lab
	# maclab
	#
	# are treated the same.
	# --------------------------------------------------------

	var normalized_scene_name: String = (
		scene_name.replace("_", "")
	)


	# ========================================================
	# COMLAB
	# ========================================================

	if normalized_scene_name.contains("comlab"):

		# ----------------------------------------------------
		# FIRST:
		# Talk to Miss Joyz.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"miss_joyz_first_dialogue_done"
			)
		):

			_set_target("talk1")

			return


		# ----------------------------------------------------
		# SECOND:
		# Complete programming quiz.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"quiz_completed"
			)
		):

			_set_target("challenge1")

			return


		# ----------------------------------------------------
		# THIRD:
		# Talk to Miss Joyz again.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"miss_joyz_second_dialogue_done"
			)
		):

			_set_target("talk1")

			return


		# ----------------------------------------------------
		# FOURTH:
		# Exit COMLAB.
		# ----------------------------------------------------

		_set_target("door1")

		return


	# ========================================================
	# MAC LAB
	# ========================================================

	if normalized_scene_name.contains("maclab"):

		# ----------------------------------------------------
		# FIRST:
		# Talk to Sir Mico.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"sir_mico_dialogue_done"
			)
		):

			_set_target("talk2")

			return


		# ----------------------------------------------------
		# SECOND:
		# Complete MacLab challenge.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"maclab_challenge_completed"
			)
		):

			_set_target("challenge2")

			return


		# ----------------------------------------------------
		# THIRD:
		# Talk to Sir Mico again.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"sir_mico_second_dialogue_done"
			)
		):

			_set_target("talk2")

			return


		# ----------------------------------------------------
		# FOURTH:
		# Exit MacLab.
		# ----------------------------------------------------

		_set_target("door2")

		return


	# ========================================================
	# LECTURE ROOM
	# ========================================================

	if normalized_scene_name.contains("lecture"):

		# ----------------------------------------------------
		# FIRST:
		# Talk to Sir Charles.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"sir_charles_dialogue_done"
			)
		):

			_set_target("talk3")

			return


		# ----------------------------------------------------
		# SECOND:
		# Complete Lecture challenge.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"lecture_challenge_completed"
			)
		):

			_set_target("challenge3")

			return


		# ----------------------------------------------------
		# THIRD:
		# Talk to Sir Charles again.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"sir_charles_second_dialogue_done"
			)
		):

			_set_target("talk3")

			return


		# ----------------------------------------------------
		# FOURTH:
		# Exit Lecture Room.
		# ----------------------------------------------------

		_set_target("door3")

		return


	# ========================================================
	# SCHOOL HALLWAY
	# ========================================================

	if normalized_scene_name.contains("school"):

		# ----------------------------------------------------
		# COMLAB not finished.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"quiz_completed"
			)
		):

			_set_target("comlab202")

			return


		# ----------------------------------------------------
		# MACLAB not finished.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"maclab_challenge_completed"
			)
		):

			_set_target("maclab")

			return


		# ----------------------------------------------------
		# LECTURE ROOM not finished.
		# ----------------------------------------------------

		if not bool(
			GameManager.get(
				"lecture_challenge_completed"
			)
		):

			_set_target("lecture_room")

			return


		# ----------------------------------------------------
		# EVERYTHING COMPLETE.
		# ----------------------------------------------------

		quest_target = null

		return


	# ========================================================
	# HOUSE
	# ========================================================

	if normalized_scene_name.contains("house"):

		if not bool(
			GameManager.get(
				"has_baon"
			)
		):

			_set_target("baon")

			return


		_set_target("out")

		return


	# ========================================================
	# NO TARGET
	# ========================================================

	quest_target = null


# ============================================================
# SET TARGET
# ============================================================

func _set_target(marker_key: String) -> void:

	# --------------------------------------------------------
	# If marker isn't currently registered, refresh everything.
	# --------------------------------------------------------

	if not markers.has(marker_key):

		_find_all_markers()


	# --------------------------------------------------------
	# Still doesn't exist.
	# --------------------------------------------------------

	if not markers.has(marker_key):

		quest_target = null

		return


	# --------------------------------------------------------
	# Get marker.
	# --------------------------------------------------------

	var marker: Node2D = markers[marker_key] as Node2D


	if marker == null:

		_find_all_markers()

		if not markers.has(marker_key):

			quest_target = null

			return

		marker = markers[marker_key] as Node2D


	# --------------------------------------------------------
	# Validate.
	# --------------------------------------------------------

	if marker == null:

		quest_target = null

		return


	if not is_instance_valid(marker):

		markers.erase(marker_key)

		quest_target = null

		return


	if not marker.is_inside_tree():

		quest_target = null

		return


	# --------------------------------------------------------
	# Target successfully assigned.
	# --------------------------------------------------------

	quest_target = marker


# ============================================================
# SHOULD DRAW
# ============================================================

func _should_draw() -> bool:

	if player == null:
		return false


	if not is_instance_valid(player):
		return false


	if not player.is_inside_tree():
		return false


	# --------------------------------------------------------
	# Hide during scripted events/cutscenes.
	# --------------------------------------------------------

	if bool(
		GameManager.get(
			"player_controls_locked"
		)
	):
		return false


	# --------------------------------------------------------
	# Hide while dialogue is active.
	# --------------------------------------------------------

	if DialogueManager.is_active:
		return false


	return true


# ============================================================
# DRAW
# ============================================================

func _draw() -> void:

	if player == null:
		return


	if quest_target == null:
		return


	if not is_instance_valid(quest_target):
		return


	if not quest_target.is_inside_tree():
		return


	# --------------------------------------------------------
	# Direction from player to target.
	# --------------------------------------------------------

	var direction: Vector2 = (
		quest_target.global_position
		-
		player.global_position
	)


	var distance: float = direction.length()


	if distance <= POINTER_MIN_DISTANCE:
		return


	if direction == Vector2.ZERO:
		return


	direction = direction.normalized()


	# --------------------------------------------------------
	# Retract pointer when close to target.
	# --------------------------------------------------------

	var retract_factor: float = clampf(
		distance /
		POINTER_RETRACT_DISTANCE,
		0.0,
		1.0
	)


	var pointer_distance: float = (
		POINTER_HEIGHT *
		retract_factor
	)


	# --------------------------------------------------------
	# Bobbing animation.
	# --------------------------------------------------------

	var bob: float = (
		sin(
			quest_pointer_time *
			POINTER_BOB_SPEED
		)
		*
		POINTER_BOB_HEIGHT
		*
		retract_factor
	)


	var pointer_position: Vector2 = (
		direction *
		(pointer_distance + bob)
	)


	# --------------------------------------------------------
	# Fade when very close to player.
	# --------------------------------------------------------

	var alpha: float = clampf(
		distance /
		PLAYER_FADE_DISTANCE,
		0.0,
		1.0
	)


	if alpha <= 0.0:
		return


	# --------------------------------------------------------
	# Arrow rotation.
	# --------------------------------------------------------

	var angle: float = direction.angle()


	# ========================================================
	# OUTER ARROW
	# ========================================================

	var tip: Vector2 = Vector2(
		POINTER_SIZE,
		0.0
	)


	var back_top: Vector2 = Vector2(
		-POINTER_SIZE * 0.65,
		-POINTER_SIZE * 0.65
	)


	var back_bottom: Vector2 = Vector2(
		-POINTER_SIZE * 0.65,
		POINTER_SIZE * 0.65
	)


	var outer_polygon: PackedVector2Array = PackedVector2Array([
		pointer_position +
		tip.rotated(angle),

		pointer_position +
		back_top.rotated(angle),

		pointer_position +
		back_bottom.rotated(angle)
	])


	# ========================================================
	# INNER ARROW
	# ========================================================

	var inner_tip: Vector2 = Vector2(
		POINTER_SIZE * 0.55,
		0.0
	)


	var inner_back_top: Vector2 = Vector2(
		-POINTER_SIZE * 0.35,
		-POINTER_SIZE * 0.35
	)


	var inner_back_bottom: Vector2 = Vector2(
		-POINTER_SIZE * 0.35,
		POINTER_SIZE * 0.35
	)


	var inner_polygon: PackedVector2Array = PackedVector2Array([
		pointer_position +
		inner_tip.rotated(angle),

		pointer_position +
		inner_back_top.rotated(angle),

		pointer_position +
		inner_back_bottom.rotated(angle)
	])


	# ========================================================
	# COLORS
	# ========================================================

	var outline_color: Color = POINTER_OUTLINE_COLOR
	outline_color.a *= alpha


	var fill_color: Color = POINTER_COLOR
	fill_color.a *= alpha


	# ========================================================
	# DRAW OUTLINE
	# ========================================================

	draw_colored_polygon(
		outer_polygon,
		outline_color
	)


	# ========================================================
	# DRAW INNER ARROW
	# ========================================================

	draw_colored_polygon(
		inner_polygon,
		fill_color
	)
