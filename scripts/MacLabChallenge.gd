extends Control

@onready var drawing_area: Control = $paintbrowser/ScreenArea/DrawingArea
@onready var drawing_timer: Timer = $paintbrowser/ScreenArea/DrawingTimer
@onready var timer_label: Label = $paintbrowser/ScreenArea/TimerLabel
@onready var drawing_number_label: Label = $paintbrowser/ScreenArea/DrawingNumberLabel
@onready var done_button: Button = $paintbrowser/ScreenArea/DoneButton
@onready var result_panel: Panel = $paintbrowser/ScreenArea/ResultPanel
@onready var result_title: Label = $paintbrowser/ScreenArea/ResultPanel/ResultTitle
@onready var score_label: Label = $paintbrowser/ScreenArea/ResultPanel/ScoreLabel
@onready var continue_button: Button = $paintbrowser/ScreenArea/ResultPanel/ContinueButton

var is_drawing: bool = false
var current_stroke: Line2D = null
var player_points: Array[Vector2] = []

var current_drawing: int = 0
var drawing_scores: Array[float] = []
var current_score: float = 0.0

var showing_final_result: bool = false

var guide_points: Array[Vector2] = []

const TOTAL_DRAWINGS: int = 10
const TRACE_DISTANCE: float = 15.0
const DRAWING_TIME: float = 10.0

const DASH_ON: int = 4
const DASH_OFF: int = 3


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	result_panel.visible = false

	done_button.pressed.connect(_on_done_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	drawing_timer.timeout.connect(_on_timer_timeout)

	await get_tree().process_frame

	start_drawing()


func _process(_delta: float) -> void:
	update_timer_label()


func update_timer_label() -> void:
	var time_left: int = int(ceil(drawing_timer.time_left))
	timer_label.text = "Time: %d" % time_left


func _input(event: InputEvent) -> void:
	if result_panel.visible:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_stroke()
			else:
				end_stroke()

	elif event is InputEventMouseMotion and is_drawing:
		add_to_stroke()


func start_stroke() -> void:
	if drawing_timer.is_stopped():
		return

	var mouse_position: Vector2 = drawing_area.get_local_mouse_position()

	if not drawing_area.get_rect().has_point(mouse_position):
		return

	is_drawing = true

	current_stroke = Line2D.new()
	current_stroke.width = 8.0
	current_stroke.default_color = Color.BLACK
	current_stroke.antialiased = false

	drawing_area.add_child(current_stroke)

	current_stroke.add_point(mouse_position)
	player_points.append(mouse_position)


func add_to_stroke() -> void:
	if current_stroke == null:
		return

	var local_pos: Vector2 = drawing_area.get_local_mouse_position()

	if current_stroke.get_point_count() == 0:
		current_stroke.add_point(local_pos)
		player_points.append(local_pos)
		return

	var last_point: Vector2 = current_stroke.get_point_position(
		current_stroke.get_point_count() - 1
	)

	if last_point.distance_to(local_pos) > 2.0:
		current_stroke.add_point(local_pos)
		player_points.append(local_pos)


func end_stroke() -> void:
	is_drawing = false
	current_stroke = null


func start_drawing() -> void:
	await clear_drawing_area()

	result_panel.visible = false
	showing_final_result = false
	done_button.disabled = false

	drawing_number_label.text = "Drawing %d / %d" % [
		current_drawing + 1,
		TOTAL_DRAWINGS
	]

	drawing_timer.wait_time = DRAWING_TIME

	match current_drawing:
		0:
			create_circle_guide()

		1:
			create_square_guide()

		2:
			create_triangle_guide()

		3:
			create_star_guide()

		4:
			create_heart_guide()

		5:
			create_house_guide()

		6:
			create_tree_guide()

		7:
			create_human_guide()

		8:
			create_car_guide()

		9:
			create_cat_guide()

	drawing_timer.start()
	update_timer_label()


func clear_drawing_area() -> void:
	is_drawing = false
	current_stroke = null

	player_points.clear()
	guide_points.clear()

	for child in drawing_area.get_children():
		if child is Line2D:
			child.queue_free()

	await get_tree().process_frame


func create_guide_line() -> Line2D:
	var line: Line2D = Line2D.new()

	line.width = 6.0
	line.antialiased = false
	line.default_color = Color.BLACK

	drawing_area.add_child(line)

	return line


func add_broken_segment(
	start_point: Vector2,
	end_point: Vector2,
	segments: int
) -> void:
	for i in range(segments):
		var t1: float = float(i) / float(segments)
		var t2: float = float(i + 1) / float(segments)

		var segment_start: Vector2 = start_point.lerp(
			end_point,
			t1
		)

		var segment_end: Vector2 = start_point.lerp(
			end_point,
			t2
		)

		guide_points.append(segment_start)

		var dash_cycle: int = DASH_ON + DASH_OFF

		if i % dash_cycle < DASH_ON:
			var line: Line2D = create_guide_line()

			line.add_point(segment_start)
			line.add_point(segment_end)

	guide_points.append(end_point)


func add_broken_circle(
	center: Vector2,
	radius: float,
	points: int
) -> void:
	var circle_points: Array[Vector2] = []

	for i in range(points + 1):
		var angle: float = TAU * float(i) / float(points)

		var circle_point: Vector2 = center + Vector2(
			cos(angle),
			sin(angle)
		) * radius

		circle_points.append(circle_point)
		guide_points.append(circle_point)

	for i in range(points):
		var dash_cycle: int = DASH_ON + DASH_OFF

		if i % dash_cycle < DASH_ON:
			var line: Line2D = create_guide_line()

			line.add_point(circle_points[i])
			line.add_point(circle_points[i + 1])


func create_circle_guide() -> void:
	var center: Vector2 = Vector2(
		drawing_area.size.x / 2.0,
		drawing_area.size.y / 2.0
	)

	add_broken_circle(
		center,
		150.0,
		120
	)


func create_square_guide() -> void:
	var center: Vector2 = Vector2(
		drawing_area.size.x / 2.0,
		drawing_area.size.y / 2.0
	)

	var box_size: float = 260.0
	var half_size: float = box_size / 2.0

	var top_left: Vector2 = center + Vector2(
		-half_size,
		-half_size
	)

	var top_right: Vector2 = center + Vector2(
		half_size,
		-half_size
	)

	var bottom_right: Vector2 = center + Vector2(
		half_size,
		half_size
	)

	var bottom_left: Vector2 = center + Vector2(
		-half_size,
		half_size
	)

	add_broken_segment(top_left, top_right, 60)
	add_broken_segment(top_right, bottom_right, 60)
	add_broken_segment(bottom_right, bottom_left, 60)
	add_broken_segment(bottom_left, top_left, 60)


func create_triangle_guide() -> void:
	var center: Vector2 = Vector2(
		drawing_area.size.x / 2.0,
		drawing_area.size.y / 2.0
	)

	var top: Vector2 = center + Vector2(0, -150)
	var bottom_right: Vector2 = center + Vector2(150, 120)
	var bottom_left: Vector2 = center + Vector2(-150, 120)

	add_broken_segment(top, bottom_right, 60)
	add_broken_segment(bottom_right, bottom_left, 60)
	add_broken_segment(bottom_left, top, 60)


func create_star_guide() -> void:
	var center: Vector2 = Vector2(
		drawing_area.size.x / 2.0,
		drawing_area.size.y / 2.0
	)

	var outer_radius: float = 150.0
	var inner_radius: float = 65.0

	var star_points: Array[Vector2] = []

	for i in range(10):
		var angle: float = -PI / 2.0 + (
			TAU * float(i) / 10.0
		)

		var radius: float

		if i % 2 == 0:
			radius = outer_radius
		else:
			radius = inner_radius

		var point: Vector2 = center + Vector2(
			cos(angle),
			sin(angle)
		) * radius

		star_points.append(point)

	for i in range(10):
		var next_index: int = (i + 1) % 10

		add_broken_segment(
			star_points[i],
			star_points[next_index],
			30
		)


func create_heart_guide() -> void:
	var center: Vector2 = Vector2(
		drawing_area.size.x / 2.0,
		drawing_area.size.y / 2.0
	)

	var scale_factor: float = 12.0
	var points: int = 120

	var heart_points: Array[Vector2] = []

	for i in range(points + 1):
		var t: float = TAU * float(i) / float(points)

		var x: float = 16.0 * pow(sin(t), 3)

		var y: float = -(
			13.0 * cos(t)
			- 5.0 * cos(2.0 * t)
			- 2.0 * cos(3.0 * t)
			- cos(4.0 * t)
		)

		var point: Vector2 = center + Vector2(
			x,
			y
		) * scale_factor

		heart_points.append(point)
		guide_points.append(point)

	for i in range(points):
		var dash_cycle: int = DASH_ON + DASH_OFF

		if i % dash_cycle < DASH_ON:
			var line: Line2D = create_guide_line()

			line.add_point(heart_points[i])
			line.add_point(heart_points[i + 1])


func create_house_guide() -> void:
	var center: Vector2 = Vector2(
		drawing_area.size.x / 2.0,
		drawing_area.size.y / 2.0
	)

	var left: Vector2 = center + Vector2(-150, 60)
	var right: Vector2 = center + Vector2(150, 60)

	var bottom_left: Vector2 = center + Vector2(-150, 210)
	var bottom_right: Vector2 = center + Vector2(150, 210)

	var roof_top: Vector2 = center + Vector2(0, -90)

	add_broken_segment(left, bottom_left, 40)
	add_broken_segment(bottom_left, bottom_right, 60)
	add_broken_segment(bottom_right, right, 40)

	add_broken_segment(left, roof_top, 45)
	add_broken_segment(roof_top, right, 45)

	var door_top_left: Vector2 = center + Vector2(-35, 115)
	var door_top_right: Vector2 = center + Vector2(35, 115)

	var door_bottom_left: Vector2 = center + Vector2(-35, 210)
	var door_bottom_right: Vector2 = center + Vector2(35, 210)

	add_broken_segment(
		door_top_left,
		door_top_right,
		15
	)

	add_broken_segment(
		door_top_left,
		door_bottom_left,
		25
	)

	add_broken_segment(
		door_top_right,
		door_bottom_right,
		25
	)

	var window_left_top: Vector2 = center + Vector2(-115, 105)
	var window_left_bottom: Vector2 = center + Vector2(-115, 155)

	var window_right_top: Vector2 = center + Vector2(-65, 105)
	var window_right_bottom: Vector2 = center + Vector2(-65, 155)

	add_broken_segment(
		window_left_top,
		window_right_top,
		15
	)

	add_broken_segment(
		window_right_top,
		window_right_bottom,
		15
	)

	add_broken_segment(
		window_right_bottom,
		window_left_bottom,
		15
	)

	add_broken_segment(
		window_left_bottom,
		window_left_top,
		15
	)


func create_tree_guide() -> void:
	var center: Vector2 = Vector2(
		drawing_area.size.x / 2.0,
		drawing_area.size.y / 2.0
	)

	var trunk_left: Vector2 = center + Vector2(-30, 40)
	var trunk_right: Vector2 = center + Vector2(30, 40)

	var trunk_bottom_left: Vector2 = center + Vector2(-30, 200)
	var trunk_bottom_right: Vector2 = center + Vector2(30, 200)

	add_broken_segment(
		trunk_left,
		trunk_bottom_left,
		35
	)

	add_broken_segment(
		trunk_right,
		trunk_bottom_right,
		35
	)

	add_broken_segment(
		trunk_bottom_left,
		trunk_bottom_right,
		15
	)

	var crown_top: Vector2 = center + Vector2(0, -140)
	var crown_left: Vector2 = center + Vector2(-150, 40)
	var crown_right: Vector2 = center + Vector2(150, 40)

	add_broken_segment(
		crown_top,
		crown_right,
		40
	)

	add_broken_segment(
		crown_right,
		crown_left,
		60
	)

	add_broken_segment(
		crown_left,
		crown_top,
		40
	)


func create_human_guide() -> void:
	var center: Vector2 = Vector2(
		drawing_area.size.x / 2.0,
		drawing_area.size.y / 2.0
	)

	var head_center: Vector2 = center + Vector2(0, -140)

	add_broken_circle(
		head_center,
		50.0,
		50
	)

	var body_top_left: Vector2 = center + Vector2(-60, -80)
	var body_top_right: Vector2 = center + Vector2(60, -80)

	var body_bottom_right: Vector2 = center + Vector2(60, 60)
	var body_bottom_left: Vector2 = center + Vector2(-60, 60)

	add_broken_segment(
		body_top_left,
		body_top_right,
		25
	)

	add_broken_segment(
		body_top_right,
		body_bottom_right,
		30
	)

	add_broken_segment(
		body_bottom_right,
		body_bottom_left,
		30
	)

	add_broken_segment(
		body_bottom_left,
		body_top_left,
		30
	)

	var left_shoulder: Vector2 = center + Vector2(-60, -40)
	var right_shoulder: Vector2 = center + Vector2(60, -40)

	var left_hand: Vector2 = center + Vector2(-150, 40)
	var right_hand: Vector2 = center + Vector2(150, 40)

	add_broken_segment(
		left_shoulder,
		left_hand,
		35
	)

	add_broken_segment(
		right_shoulder,
		right_hand,
		35
	)

	var left_hip: Vector2 = center + Vector2(-35, 60)
	var right_hip: Vector2 = center + Vector2(35, 60)

	var left_foot: Vector2 = center + Vector2(-80, 190)
	var right_foot: Vector2 = center + Vector2(80, 190)

	add_broken_segment(
		left_hip,
		left_foot,
		40
	)

	add_broken_segment(
		right_hip,
		right_foot,
		40
	)


func create_car_guide() -> void:
	var center: Vector2 = Vector2(
		drawing_area.size.x / 2.0,
		drawing_area.size.y / 2.0
	)

	var body_top_left: Vector2 = center + Vector2(-170, -20)
	var body_top_right: Vector2 = center + Vector2(170, -20)

	var body_bottom_right: Vector2 = center + Vector2(170, 90)
	var body_bottom_left: Vector2 = center + Vector2(-170, 90)

	add_broken_segment(
		body_top_left,
		body_top_right,
		60
	)

	add_broken_segment(
		body_top_right,
		body_bottom_right,
		30
	)

	add_broken_segment(
		body_bottom_right,
		body_bottom_left,
		60
	)

	add_broken_segment(
		body_bottom_left,
		body_top_left,
		30
	)

	var roof_left: Vector2 = center + Vector2(-90, -20)
	var roof_top_left: Vector2 = center + Vector2(-45, -100)

	var roof_top_right: Vector2 = center + Vector2(45, -100)
	var roof_right: Vector2 = center + Vector2(90, -20)

	add_broken_segment(
		roof_left,
		roof_top_left,
		25
	)

	add_broken_segment(
		roof_top_left,
		roof_top_right,
		30
	)

	add_broken_segment(
		roof_top_right,
		roof_right,
		25
	)

	var left_wheel_center: Vector2 = center + Vector2(-100, 95)
	var right_wheel_center: Vector2 = center + Vector2(100, 95)

	add_broken_circle(
		left_wheel_center,
		35.0,
		40
	)

	add_broken_circle(
		right_wheel_center,
		35.0,
		40
	)


func create_cat_guide() -> void:
	var center: Vector2 = Vector2(
		drawing_area.size.x / 2.0,
		drawing_area.size.y / 2.0
	)

	var head_center: Vector2 = center + Vector2(0, -100)

	add_broken_circle(
		head_center,
		90.0,
		60
	)

	var left_ear_base: Vector2 = center + Vector2(-60, -150)
	var left_ear_top: Vector2 = center + Vector2(-90, -220)

	var right_ear_base: Vector2 = center + Vector2(60, -150)
	var right_ear_top: Vector2 = center + Vector2(90, -220)

	add_broken_segment(
		left_ear_base,
		left_ear_top,
		20
	)

	add_broken_segment(
		left_ear_top,
		center + Vector2(-20, -150),
		20
	)

	add_broken_segment(
		right_ear_base,
		right_ear_top,
		20
	)

	add_broken_segment(
		right_ear_top,
		center + Vector2(20, -150),
		20
	)

	var body_left: Vector2 = center + Vector2(-70, 0)
	var body_right: Vector2 = center + Vector2(70, 0)

	var body_bottom_left: Vector2 = center + Vector2(-70, 140)
	var body_bottom_right: Vector2 = center + Vector2(70, 140)

	add_broken_segment(
		body_left,
		body_bottom_left,
		35
	)

	add_broken_segment(
		body_right,
		body_bottom_right,
		35
	)

	add_broken_segment(
		body_bottom_left,
		body_bottom_right,
		35
	)

	var tail_start: Vector2 = body_right
	var tail_mid: Vector2 = center + Vector2(160, 100)
	var tail_end: Vector2 = center + Vector2(180, 20)

	add_broken_segment(
		tail_start,
		tail_mid,
		30
	)

	add_broken_segment(
		tail_mid,
		tail_end,
		25
	)


func calculate_score() -> float:
	if guide_points.is_empty():
		return 0.0

	if player_points.is_empty():
		return 0.0

	var correct_guide_points: int = 0
	var outside_penalty: float = 0.0

	for guide_point in guide_points:
		var closest_distance: float = INF

		for player_point in player_points:
			var distance: float = guide_point.distance_to(
				player_point
			)

			if distance < closest_distance:
				closest_distance = distance

		if closest_distance <= TRACE_DISTANCE:
			correct_guide_points += 1

	var guide_accuracy: float = (
		float(correct_guide_points)
		/ float(guide_points.size())
	) * 100.0

	for player_point in player_points:
		var closest_distance: float = INF

		for guide_point in guide_points:
			var distance: float = player_point.distance_to(
				guide_point
			)

			if distance < closest_distance:
				closest_distance = distance

		if closest_distance > TRACE_DISTANCE:
			var excess_distance: float = (
				closest_distance
				- TRACE_DISTANCE
			)

			outside_penalty += excess_distance / 10.0

	var penalty: float = (
		outside_penalty
		/ float(player_points.size())
	) * 100.0

	var final_score: float = guide_accuracy - penalty

	return clamp(
		final_score,
		0.0,
		100.0
	)


func _on_timer_timeout() -> void:
	finish_current_drawing()


func _on_done_pressed() -> void:
	if result_panel.visible:
		return

	if drawing_timer.is_stopped():
		return

	drawing_timer.stop()
	finish_current_drawing()


func finish_current_drawing() -> void:
	if result_panel.visible:
		return

	is_drawing = false
	current_stroke = null

	drawing_timer.stop()
	done_button.disabled = true

	current_score = calculate_score()
	drawing_scores.append(current_score)

	score_label.text = "Score: %d%%" % roundi(current_score)

	if current_drawing >= TOTAL_DRAWINGS - 1:
		result_title.text = "Drawing Challenge Complete!"
		continue_button.text = "View Final Score"
	else:
		result_title.text = "Drawing Complete!"
		continue_button.text = "Next Drawing"

	result_panel.visible = true


func _on_continue_pressed() -> void:
	if showing_final_result:
		return

	if current_drawing >= TOTAL_DRAWINGS - 1:
		show_final_result()
		return

	current_drawing += 1
	await start_drawing()


func show_final_result() -> void:
	showing_final_result = true

	var total_score: float = 0.0

	for score in drawing_scores:
		total_score += score

	var final_score: float = (
		total_score
		/ float(TOTAL_DRAWINGS)
	)

	GameManager.maclab_performance_score = final_score
	GameManager.maclab_challenge_completed = true

	result_title.text = "Drawing Challenge Complete!"
	score_label.text = "Final Score: %d%%" % roundi(final_score)
	continue_button.text = "Finish"

	result_panel.visible = true

	continue_button.pressed.disconnect(_on_continue_pressed)
	continue_button.pressed.connect(_on_finish_pressed)


func _on_finish_pressed() -> void:
	await FadeManager.change_scene_with_fade(
		"res://scenes/main_level_scenes/mac_lab.tscn"
	)
