extends Node

## ============================================================
## ACHIEVEMENT MANAGER
## ============================================================
## Add this script as an Autoload named:
## AchievementManager
##
## Achievement progress itself is stored inside GameManager so the
## existing 10-slot SaveManager automatically saves it.
## ============================================================

const ACHIEVEMENTS: Array[Dictionary] = [
	{"id":"baon_for_today", "title":"Baon for today.", "description":"Take the baon from the table at home."},

	{"id":"comlab_low", "title":"Programming is hard.", "description":"Complete COMLAB 202 with a 0%-30% score."},
	{"id":"comlab_medium", "title":"Kinda got it.", "description":"Complete COMLAB 202 with a 31%-80% score."},
	{"id":"comlab_high", "title":"ggez lol", "description":"Complete COMLAB 202 with an 81%-100% score."},

	{"id":"maclab_low", "title":"Me no likey drawing.", "description":"Complete MAC LAB with a 0%-30% score."},
	{"id":"maclab_medium", "title":"Still need practice.", "description":"Complete MAC LAB with a 31%-80% score."},
	{"id":"maclab_high", "title":"Picasso Prodigy.", "description":"Complete MAC LAB with an 81%-100% score."},

	{"id":"lecture_low", "title":"Sir Charles will get angry.", "description":"Complete the Lecture Room challenge with a 0%-30% score."},
	{"id":"lecture_medium", "title":"Math is hard.", "description":"Complete the Lecture Room challenge with a 31%-80% score."},
	{"id":"lecture_high", "title":"You used ChatGPT.", "description":"Complete the Lecture Room challenge with an 81%-100% score."},

	{"id":"bookstore_friends", "title":"You got a friend in me.", "description":"Go with the group of friends to the bookstore."},
	{"id":"bookstore_friendly", "title":"You really are friendly.", "description":"Talk to everyone in the bookstore."},

	{"id":"bullies_join", "title":"If you can't beat them, join them.", "description":"Choose to come with the bullies."},
	{"id":"bullies_nerd", "title":"Nerd priorities.", "description":"Choose not to go with the bullies because you have class."},

	{"id":"cafe_tina", "title":"Make amends to the ones we wronged.", "description":"Go to the cafe with Tina."},
	{"id":"cafe_friends", "title":"You got a friend in me part 2.", "description":"Go to the cafe with the group of friends."},
	{"id":"cafe_solo", "title":"Changed your mind or just wanted to go alone?", "description":"Go to the cafe by yourself."},
	{"id":"cafe_gelo", "title":"Past is past, but why not coconut :D", "description":"Talk to Gelo at the cafe."},
	{"id":"cafe_tina_both_correct", "title":"It wasn't that hard to remember.", "description":"Get both your and Tina's drinks correct."},
	{"id":"cafe_tina_one_wrong", "title":"Her order was complicated anyway.", "description":"Get exactly one of your and Tina's drinks wrong."},
	{"id":"cafe_tina_both_wrong", "title":"Memory of a Goldfish.", "description":"Get both your and Tina's drinks wrong."},
	{"id":"cafe_friends_all_correct", "title":"Memo Plus Gold.", "description":"Get your order and all of the friends' orders correct."},
	{"id":"cafe_friends_some_wrong", "title":"Lotsa orders.", "description":"Get at least one, but not all, of the group orders wrong."},
	{"id":"cafe_friends_all_wrong", "title":"Lotsa orders part 2.", "description":"Get every group order wrong."},
	{"id":"cafe_no_gelo", "title":"Past is past.", "description":"Choose not to talk to Gelo."},

	{"id":"life_of_a_1st_year", "title":"Life of a 1st Year.", "description":"Unlock all 25 other non-secret achievements."},

	{"id":"secret_no_school", "title":"I DON'T WANT TO GO TO SCHOOL D:", "description":"Stay in house_game_level for 3 minutes.", "category":"super_secret", "counts_toward_completion":false},

	{"id":"secret_school_hallway", "title":"Please do not loiter!", "description":"Stay in the school hallway for 3 minutes straight without entering another room.", "category":"super_secret", "counts_toward_completion":false},
	{"id":"secret_comlab_chill", "title":"Wat'cha doin'? Just Chillin' part 1", "description":"Stay in COMLAB 202 for 3 minutes straight without entering another room.", "category":"super_secret", "counts_toward_completion":false},
	{"id":"secret_maclab_chill", "title":"Wat'cha doin'? Just Chillin' part 2", "description":"Stay in the school MAC LAB for 3 minutes straight without entering another room.", "category":"super_secret", "counts_toward_completion":false},
	{"id":"secret_lecture_chill", "title":"Wat'cha doin'? Just Chillin' part 3", "description":"Stay in the Lecture Room for 3 minutes straight without entering another room.", "category":"super_secret", "counts_toward_completion":false},
	{"id":"secret_bookstore_loiter", "title":"Paper cuts", "description":"Stay in the bookstore for 3 minutes straight without entering another room.", "category":"super_secret", "counts_toward_completion":false},
	{"id":"secret_cafe_chill", "title":"Sus! Marya & Hosep!", "description":"Stay in the cafe for 3 minutes straight without entering another room.", "category":"super_secret", "counts_toward_completion":false},

]

const STATE_KEY := "achievements_unlocked"
const HOUSE_SECRET_SECONDS := 180.0

var house_timer: float = 0.0
var room_timer: float = 0.0
var last_scene_path: String = ""

# Temporary settings override. The snapshot is restored when the toggle is
# turned off, so test-unlocking achievements never erases earlier progress.
var all_achievements_override_active: bool = false
var achievements_before_override: Dictionary = {}
var toast_layer: CanvasLayer = null
var toast_panel: Panel = null
var toast_title: Label = null
var toast_description: Label = null
var toast_tween: Tween = null
var toast_state: int = 0
var toast_timer: float = 0.0
const TOAST_WIDTH := 380.0
const TOAST_HEIGHT := 112.0
const TOAST_MARGIN := 20.0
const TOAST_ANIMATION_TIME := 0.35
const TOAST_DISPLAY_TIME := 5.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_storage()
	last_scene_path = get_current_scene_path()
	build_toast_ui()


func _process(delta: float) -> void:
	# AchievementManager always processes, even while the SceneTree is paused.
	# This keeps both achievement detection and the popup countdown running.
	check_achievements()
	update_toast(delta)

	var scene_path := get_current_scene_path()
	if scene_path != last_scene_path:
		if not scene_path.ends_with("house_game_level.tscn"):
			house_timer = 0.0
		room_timer = 0.0
		last_scene_path = scene_path

	if get_tree().paused:
		return

	if scene_path.ends_with("house_game_level.tscn"):
		house_timer += delta
		if house_timer >= HOUSE_SECRET_SECONDS:
			unlock("secret_no_school")

	var room_achievement_id := get_room_dwell_achievement(scene_path)
	if room_achievement_id.is_empty():
		room_timer = 0.0
		return

	room_timer += delta
	if room_timer >= HOUSE_SECRET_SECONDS:
		unlock(room_achievement_id)


func get_room_dwell_achievement(scene_path: String) -> String:
	if scene_path.ends_with("/School.tscn"):
		return "secret_school_hallway"
	if scene_path.ends_with("/comlab202.tscn"):
		return "secret_comlab_chill"
	if scene_path.ends_with("/mac_lab.tscn"):
		return "secret_maclab_chill"
	if scene_path.ends_with("/Lecture Room.tscn"):
		return "secret_lecture_chill"
	if scene_path.ends_with("/Bookstore.tscn"):
		return "secret_bookstore_loiter"
	if scene_path.ends_with("/game.tscn"):
		return "secret_cafe_chill"
	return ""


func ensure_storage() -> void:
	if not GameManager.has_meta(STATE_KEY):
		GameManager.set_meta(STATE_KEY, {})

	if not (GameManager.get("achievements_unlocked") is Dictionary):
		GameManager.set("achievements_unlocked", {})


func get_unlocked() -> Dictionary:
	ensure_storage()
	var stored: Variant = GameManager.get("achievements_unlocked")
	if stored is Dictionary:
		return stored
	return {}


func is_unlocked(id: String) -> bool:
	return bool(get_unlocked().get(id, false))


func unlock(id: String) -> void:
	if is_unlocked(id):
		return

	var stored := get_unlocked()
	stored[id] = true
	GameManager.set("achievements_unlocked", stored)

	var definition := get_achievement(id)
	if not definition.is_empty():
		show_unlock_toast(
			str(definition.get("title", "Achievement")),
			str(definition.get("description", ""))
		)

	print("ACHIEVEMENT UNLOCKED: ", id)


func set_all_achievements_enabled(enabled: bool, snapshot_override: Dictionary = {}, use_snapshot_override: bool = false) -> Dictionary:
	if enabled:
		if all_achievements_override_active:
			# Save-slot loading can replace GameManager's dictionary. Re-apply
			# the temporary all-unlocked view without changing the real snapshot.
			var refreshed_unlocked: Dictionary = {}
			for achievement in ACHIEVEMENTS:
				refreshed_unlocked[str(achievement.get("id", ""))] = true
			GameManager.set(STATE_KEY, refreshed_unlocked)
			return achievements_before_override.duplicate(true)

		if use_snapshot_override or not snapshot_override.is_empty():
			achievements_before_override = snapshot_override.duplicate(true)
		else:
			achievements_before_override = get_unlocked().duplicate(true)

		all_achievements_override_active = true
		var all_unlocked: Dictionary = {}
		for achievement in ACHIEVEMENTS:
			all_unlocked[str(achievement.get("id", ""))] = true
		GameManager.set(STATE_KEY, all_unlocked)
		return achievements_before_override.duplicate(true)

	if all_achievements_override_active:
		GameManager.set(STATE_KEY, achievements_before_override.duplicate(true))
	elif not snapshot_override.is_empty():
		# Handles settings reloads that explicitly turn the feature off.
		GameManager.set(STATE_KEY, snapshot_override.duplicate(true))

	all_achievements_override_active = false
	achievements_before_override.clear()
	return {}


func are_all_achievements_enabled() -> bool:
	return all_achievements_override_active


func get_achievement(id: String) -> Dictionary:
	for achievement in ACHIEVEMENTS:
		if str(achievement.get("id", "")) == id:
			return achievement
	return {}


func get_all_achievements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for achievement in ACHIEVEMENTS:
		var item := achievement.duplicate(true)
		if not item.has("category"):
			item["category"] = "standard"
		item["unlocked"] = is_unlocked(str(item.get("id", "")))
		result.append(item)
	return result


func get_unlocked_count() -> int:
	var count := 0
	for achievement in ACHIEVEMENTS:
		if is_unlocked(str(achievement.get("id", ""))):
			count += 1
	return count


func get_total_count() -> int:
	return ACHIEVEMENTS.size()


func check_achievements() -> void:
	if not is_instance_valid(GameManager):
		return

	# While the testing toggle is active, don't convert temporary state into
	# real achievement progress. The original snapshot is restored on disable.
	if all_achievements_override_active:
		return

	# 1. House / baon.
	if bool(GameManager.get("has_baon")):
		unlock("baon_for_today")

	# 2-4. COMLAB 202 score branch.
	if bool(GameManager.get("quiz_completed")):
		unlock_score_achievement("comlab", float(GameManager.get("comlab_performance_score")))

	# 5-7. MAC LAB score branch.
	if bool(GameManager.get("maclab_challenge_completed")):
		unlock_score_achievement("maclab", float(GameManager.get("maclab_performance_score")))

	# 8-10. Lecture Room score branch.
	if bool(GameManager.get("lecture_challenge_completed")):
		unlock_score_achievement("lecture", float(GameManager.get("lecture_performance_score")))

	# Bookstore decisions.
	if int(GameManager.get("friends_bookstore_choice")) == 1:
		unlock("bookstore_friends")

	var talked_to_everyone := (
		bool(GameManager.get("bookstore_talked_to_kairi"))
		and bool(GameManager.get("bookstore_talked_to_kerwin"))
		and bool(GameManager.get("bookstore_talked_to_janssen"))
		and bool(GameManager.get("bookstore_talked_to_nathaly"))
		and bool(GameManager.get("bookstore_talked_to_ate_libro"))
		and bool(GameManager.get("bookstore_talked_to_kuya_libro"))
	)
	if talked_to_everyone:
		unlock("bookstore_friendly")

	# Bullies decision lives in QuestUIManager's local state.
	var current_scene := get_tree().current_scene
	if current_scene != null:
		var quest_ui := current_scene.find_child("QuestUIManager", true, false)
		if quest_ui != null:
			var bully_choice: int = int(quest_ui.get("bully_choice"))
			if bully_choice == 1:
				unlock("bullies_join")
			elif bully_choice == 2:
				unlock("bullies_nerd")

	# Cafe route decisions are stored in metadata because the cafe controller
	# consumes GameManager.cafe_route after entering the scene.
	var cafe_route := str(GameManager.get_meta("cafe_quest_route", ""))
	if cafe_route == "tina":
		unlock("cafe_tina")
	elif cafe_route == "friends":
		unlock("cafe_friends")
	elif cafe_route == "solo":
		unlock("cafe_solo")

	# Solo Gelo decision.
	if cafe_route == "solo" and bool(GameManager.get_meta("cafe_solo_order_ready", false)):
		if bool(GameManager.get_meta("cafe_solo_order_talked_to_gelo", false)):
			unlock("cafe_gelo")
		else:
			unlock("cafe_no_gelo")

	# Tina's two-drink result.
	if bool(GameManager.get_meta("cafe_tina_order_result_recorded", false)):
		var player_correct: bool = bool(GameManager.get_meta("cafe_tina_player_correct", false))
		var tina_correct: bool = bool(GameManager.get_meta("cafe_tina_correct", false))
		if player_correct and tina_correct:
			unlock("cafe_tina_both_correct")
		elif player_correct or tina_correct:
			unlock("cafe_tina_one_wrong")
		else:
			unlock("cafe_tina_both_wrong")

	# Friends' five-drink result.
	if bool(GameManager.get_meta("cafe_friends_order_result_recorded", false)):
		var wrong_count: int = int(GameManager.get_meta("cafe_friends_wrong_count", 0))
		if wrong_count <= 0:
			unlock("cafe_friends_all_correct")
		elif wrong_count >= 5:
			unlock("cafe_friends_all_wrong")
		else:
			unlock("cafe_friends_some_wrong")


	# The completion achievement requires every non-secret achievement
	# except itself. Super-secret achievements never gate the main ending.
	if (
		not is_unlocked("life_of_a_1st_year")
		and get_original_achievement_count_unlocked() == get_non_secret_original_achievement_total()
	):
		unlock("life_of_a_1st_year")


func get_original_achievement_count_unlocked() -> int:
	var count := 0
	for achievement in ACHIEVEMENTS:
		var achievement_id := str(achievement.get("id", ""))
		if achievement_id == "life_of_a_1st_year":
			continue
		if str(achievement.get("category", "standard")) == "super_secret":
			continue
		if is_unlocked(achievement_id):
			count += 1
	return count


func get_non_secret_original_achievement_total() -> int:
	var count := 0
	for achievement in ACHIEVEMENTS:
		if str(achievement.get("id", "")) == "life_of_a_1st_year":
			continue
		if str(achievement.get("category", "standard")) == "super_secret":
			continue
		count += 1
	return count


func has_completed_all_non_secret_achievements() -> bool:
	for achievement in ACHIEVEMENTS:
		if str(achievement.get("category", "standard")) == "super_secret":
			continue
		if not is_unlocked(str(achievement.get("id", ""))):
			return false
	return true


func unlock_score_achievement(prefix: String, score: float) -> void:
	if score < 0.0:
		return

	var suffix := ""
	if score <= 30.0:
		suffix = "_low"
	elif score <= 80.0:
		suffix = "_medium"
	else:
		suffix = "_high"

	unlock(prefix + suffix)


func get_current_scene_path() -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return ""
	return scene.scene_file_path


func build_toast_ui() -> void:
	toast_layer = CanvasLayer.new()
	toast_layer.name = "AchievementToastLayer"
	toast_layer.layer = 10000
	add_child(toast_layer)

	# Use a plain Control as the full-screen coordinate space.
	# The popup itself is a Panel with a fixed pixel size, NOT a Container.
	# This prevents Godot from expanding it into a large block.
	var toast_root := Control.new()
	toast_root.name = "ToastRoot"
	toast_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_layer.add_child(toast_root)

	toast_panel = Panel.new()
	toast_panel.name = "AchievementToast"
	toast_panel.size = Vector2(TOAST_WIDTH, TOAST_HEIGHT)
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_theme_stylebox_override("panel", make_toast_style())
	toast_root.add_child(toast_panel)

	# Title is positioned manually so it cannot resize the panel.
	toast_title = Label.new()
	toast_title.name = "ToastTitle"
	toast_title.position = Vector2(16, 12)
	toast_title.size = Vector2(TOAST_WIDTH - 32, 28)
	toast_title.text = "ACHIEVEMENT UNLOCKED"
	toast_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_title.add_theme_font_size_override("font_size", 17)
	toast_title.add_theme_color_override("font_color", Color("#FFE1A8"))
	toast_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_child(toast_title)

	# Achievement name + description.
	toast_description = Label.new()
	toast_description.name = "ToastDescription"
	toast_description.position = Vector2(16, 43)
	toast_description.size = Vector2(TOAST_WIDTH - 32, TOAST_HEIGHT - 51)
	toast_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_description.add_theme_font_size_override("font_size", 12)
	toast_description.add_theme_color_override("font_color", Color("#FFF0D8"))
	toast_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_child(toast_description)

	toast_panel.visible = false
	toast_state = 0
	toast_timer = 0.0


func show_unlock_toast(title: String, description: String) -> void:
	if toast_panel == null or toast_title == null or toast_description == null:
		return

	toast_title.text = "ACHIEVEMENT UNLOCKED"
	toast_description.text = title + "\n" + description

	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()

	toast_panel.visible = true
	toast_panel.modulate.a = 1.0
	toast_state = 1
	toast_timer = 0.0

	# Start outside the right edge.
	var viewport_size := get_viewport().get_visible_rect().size
	var hidden_x := viewport_size.x + 10.0
	var popup_y := viewport_size.y - toast_panel.size.y - TOAST_MARGIN
	toast_panel.position = Vector2(hidden_x, popup_y)


func update_toast(delta: float) -> void:
	if toast_panel == null or not toast_panel.visible:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var hidden_x := viewport_size.x + 10.0
	var visible_x := viewport_size.x - toast_panel.size.x - TOAST_MARGIN
	var popup_y := viewport_size.y - toast_panel.size.y - TOAST_MARGIN

	# Always keep the notification anchored to the bottom-right,
	# including if the game window is resized.
	popup_y = max(10.0, popup_y)

	if toast_state == 1:
		# Slide in.
		toast_timer += delta
		var t := clampf(toast_timer / TOAST_ANIMATION_TIME, 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		toast_panel.position = Vector2(lerp(hidden_x, visible_x, t), popup_y)

		if toast_timer >= TOAST_ANIMATION_TIME:
			toast_state = 2
			toast_timer = 0.0
			toast_panel.position = Vector2(visible_x, popup_y)

	elif toast_state == 2:
		# This countdown deliberately uses AchievementManager's ALWAYS
		# process mode, so it continues while the pause menu is open.
		toast_timer += delta
		toast_panel.position = Vector2(visible_x, popup_y)

		if toast_timer >= TOAST_DISPLAY_TIME:
			toast_state = 3
			toast_timer = 0.0

	elif toast_state == 3:
		# Slide out.
		toast_timer += delta
		var t := clampf(toast_timer / TOAST_ANIMATION_TIME, 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		toast_panel.position = Vector2(lerp(visible_x, hidden_x, t), popup_y)

		if toast_timer >= TOAST_ANIMATION_TIME:
			toast_state = 0
			toast_timer = 0.0
			toast_panel.visible = false
			toast_panel.position = Vector2(hidden_x, popup_y)


func make_toast_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.09, 0.055, 0.98)
	style.border_color = Color("#C99555")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 12
	return style
