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

	{"id":"secret_no_school", "title":"I DON'T WANT TO GO TO SCHOOL D:", "description":"Stay in house_game_level for 3 minutes.", "category":"super_secret", "counts_toward_completion":true},
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
var toast_layer: CanvasLayer = null
var toast_panel: PanelContainer = null
var toast_title: Label = null
var toast_description: Label = null
var toast_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_storage()
	last_scene_path = get_current_scene_path()
	build_toast_ui()


func _process(delta: float) -> void:
	check_achievements()

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

	# Unlock the 27th achievement only after all original 26 are unlocked.
	if not is_unlocked("life_of_a_1st_year") and get_unlocked_count() >= 26:
		unlock("life_of_a_1st_year")


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
	toast_layer.layer = 300
	add_child(toast_layer)

	toast_panel = PanelContainer.new()
	toast_panel.name = "AchievementToast"
	toast_panel.size = Vector2(390, 104)
	toast_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	toast_panel.position = Vector2(414, -130)
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_theme_stylebox_override("panel", make_toast_style())
	toast_layer.add_child(toast_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	toast_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	toast_title = Label.new()
	toast_title.add_theme_font_size_override("font_size", 20)
	toast_title.add_theme_color_override("font_color", Color("#F6D889"))
	box.add_child(toast_title)

	toast_description = Label.new()
	toast_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_description.add_theme_font_size_override("font_size", 13)
	toast_description.add_theme_color_override("font_color", Color("#E8DCC8"))
	box.add_child(toast_description)

	toast_panel.visible = false


func show_unlock_toast(title: String, description: String) -> void:
	if toast_panel == null:
		return

	toast_title.text = "ACHIEVEMENT UNLOCKED"
	toast_description.text = title + "\n" + description
	toast_panel.visible = true
	toast_panel.modulate.a = 1.0

	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()

	# Steam-style: slide in from the right, stay for 5 seconds,
	# then slide back out to the right.
	toast_panel.position = Vector2(414, -130)

	toast_tween = create_tween()
	toast_tween.set_trans(Tween.TRANS_QUAD)
	toast_tween.set_ease(Tween.EASE_OUT)
	toast_tween.tween_property(toast_panel, "position", Vector2(-20, -130), 0.45)
	toast_tween.tween_interval(5.0)
	toast_tween.set_ease(Tween.EASE_IN)
	toast_tween.tween_property(toast_panel, "position", Vector2(414, -130), 0.45)
	toast_tween.tween_callback(func(): toast_panel.visible = false)

func make_toast_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.085, 0.055, 0.97)
	style.border_color = Color("#CFA85B")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 12
	return style
