extends Node

## Applies a restrained warm color grade to gameplay scenes so the pixel art
## shares the cozy, late-afternoon palette of the main menu.
const MAIN_MENU_PATH := "res://scenes/ui/MainMenu.tscn"
const COLOR_GRADE_NAME := "GoldenHourColorGrade"
const GOLDEN_HOUR_TINT := Color(1.0, 0.96, 0.89)

func _ready() -> void:
	if not get_tree().scene_changed.is_connected(_on_scene_changed):
		get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_apply_to_current_scene")


func _on_scene_changed() -> void:
	call_deferred("_apply_to_current_scene")


func _apply_to_current_scene() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	# The menu already draws its own sunset palette, so do not tint it twice.
	if scene.scene_file_path.to_lower() == MAIN_MENU_PATH.to_lower():
		return

	var color_grade := scene.get_node_or_null(COLOR_GRADE_NAME) as CanvasModulate
	if color_grade == null:
		color_grade = CanvasModulate.new()
		color_grade.name = COLOR_GRADE_NAME
		color_grade.color = GOLDEN_HOUR_TINT
		scene.add_child(color_grade)
	else:
		color_grade.color = GOLDEN_HOUR_TINT
