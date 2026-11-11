extends Control

# =========================================================
# SETTINGS
# =========================================================

@export_file("*.tscn")
var main_menu_path: String = "res://scenes/ui/MainMenu.tscn"

@export var fade_in_duration: float = 1.0
@export var logo_hold_duration: float = 2.0
@export var fade_out_duration: float = 1.5
@export var main_menu_fade_duration: float = 1.5


# =========================================================
# VARIABLES
# =========================================================

@onready var logo: CanvasItem = get_node_or_null("../Logo")

var quest_tracker: Node
var fade_layer: CanvasLayer
var fade_overlay: ColorRect


# =========================================================
# INITIALIZATION
# =========================================================

func _ready() -> void:
	hide_quest_tracker()

	if logo == null:
		push_error(
            "Splash screen: Could not find Logo node at ../Logo."
		)
		return

	logo.visible = true
	logo.modulate = Color.WHITE

	create_fade_overlay()

	await get_tree().process_frame

	await play_splash_sequence()


# =========================================================
# QUEST TRACKER
# =========================================================

func hide_quest_tracker() -> void:
	quest_tracker = get_node_or_null("/root/QuestUIManager")

	if quest_tracker:
		quest_tracker.hide()
	else:
		push_warning(
            "Splash screen: QuestUIManager Autoload was not found."
		)


# =========================================================
# FADE OVERLAY
# =========================================================

func create_fade_overlay() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.name = "SplashFadeLayer"
	fade_layer.layer = 10000

	add_child(fade_layer)

	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.color = Color.BLACK
	fade_overlay.color.a = 1.0

	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fade_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fade_layer.add_child(fade_overlay)


# =========================================================
# SPLASH SEQUENCE
# =========================================================

func play_splash_sequence() -> void:

	# FADE IN LOGO
	var fade_in_tween := create_tween()

	fade_in_tween.tween_property(
		fade_overlay,
		"color:a",
		0.0,
		fade_in_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await fade_in_tween.finished


	# HOLD LOGO
	await get_tree().create_timer(
		logo_hold_duration
	).timeout


	# FADE OUT LOGO
	var fade_out_tween := create_tween()

	fade_out_tween.tween_property(
		fade_overlay,
		"color:a",
		1.0,
		fade_out_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await fade_out_tween.finished


	# LOAD MAIN MENU WHILE BLACK
	var scene_tree := get_tree()

	var error := scene_tree.change_scene_to_file(
		main_menu_path
	)

	if error != OK:
		push_error(
            "Splash screen: Failed to load main menu: "
			+ main_menu_path
		)
		return

	await scene_tree.scene_changed

	# FADE IN MAIN MENU
	await scene_tree.process_frame

	await FadeManager.fade_in(
		main_menu_fade_duration
	)
