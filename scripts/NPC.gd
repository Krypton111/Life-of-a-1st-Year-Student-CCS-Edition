extends CharacterBody2D

# ---------- Movement Settings ----------
@export var move_speed : float = 60.0
@export var min_walk_time : float = 1.0
@export var max_walk_time : float = 2.5
@export var min_idle_time : float = 0.8
@export var max_idle_time : float = 2.0

# ---------- Nodes ----------
@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area : Area2D = $InteractionArea

# ---------- State ----------
enum State { IDLE, WALKING }
var current_state : State = State.IDLE
var state_timer : float = 0.0
var walk_direction : Vector2 = Vector2.DOWN
var last_direction : Vector2 = Vector2.DOWN   # for idle facing

# Interaction
var player_in_range : bool = false
signal interacted   # emitted when player interacts

func _ready():
	# Random start
	state_timer = randf_range(min_idle_time, max_idle_time)
	
	# Connect Area2D signals
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	else:
		push_error("Missing InteractionArea node on NPC")

func _physics_process(delta):
	state_timer -= delta

	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			_play_idle_animation()
			
			if state_timer <= 0.0:
				_start_walking()
		
		State.WALKING:
			velocity = walk_direction * move_speed
			_play_walk_animation()
			
			# Stop walking if timer runs out
			if state_timer <= 0.0:
				_start_idling()
			
			# If stuck on a wall (velocity much smaller than expected), pick a new direction
			if velocity.length() < move_speed * 0.1:
				_change_direction()

	move_and_slide()

# ------------------------------------------------------------
# State transitions
# ------------------------------------------------------------
func _start_walking():
	current_state = State.WALKING
	state_timer = randf_range(min_walk_time, max_walk_time)
	_pick_random_direction()

func _start_idling():
	current_state = State.IDLE
	state_timer = randf_range(min_idle_time, max_idle_time)

func _pick_random_direction():
	# Cardinal directions only (no diagonals) – you can add more if desired
	var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	walk_direction = dirs[randi() % dirs.size()]
	last_direction = walk_direction

func _change_direction():
	# Called when stuck – choose a new random direction and reset timer
	_pick_random_direction()
	state_timer = randf_range(min_walk_time, max_walk_time)

# ------------------------------------------------------------
# Animation helpers
# ------------------------------------------------------------
func _play_idle_animation():
	var anim = "idle_" + _direction_to_string(last_direction)
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim):
		animated_sprite.play(anim)

func _play_walk_animation():
	var anim = "walk_" + _direction_to_string(walk_direction)
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim):
		animated_sprite.play(anim)

func _direction_to_string(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"

# ------------------------------------------------------------
# Interaction
# ------------------------------------------------------------
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func _input(event):
	if event.is_action_pressed("interact"):
		print("F pressed, player_in_range:", player_in_range)
		if player_in_range:
			interact()

func interact():
	# Replace this with your actual interaction logic (dialogue, quest, etc.)
	print("NPC says: Hello!")
	emit_signal("interacted")
