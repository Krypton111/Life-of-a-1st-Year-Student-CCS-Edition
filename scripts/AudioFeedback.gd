extends Node

const CLICK_VOLUME_DB := -10.0
const CLICK_COOLDOWN_USEC := 35000

var click_player: AudioStreamPlayer
var click_stream: AudioStreamWAV
var last_click_usec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	click_stream = _make_click_sound()

	click_player = AudioStreamPlayer.new()
	click_player.name = "UIConfirmationSound"
	click_player.process_mode = Node.PROCESS_MODE_ALWAYS
	click_player.volume_db = CLICK_VOLUME_DB
	click_player.stream = click_stream
	add_child(click_player)

	get_tree().node_added.connect(_on_node_added)
	call_deferred("_connect_existing_controls")


func _connect_existing_controls() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		_connect_controls_recursively(scene)


func _on_node_added(node: Node) -> void:
	if node is Control:
		_connect_control(node)
	# Some scenes add their controls in batches; connecting descendants later
	# also catches children that already existed when a parent was added.
	if node is Node and node.is_inside_tree():
		call_deferred("_connect_controls_recursively", node)


func _connect_controls_recursively(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is Control:
		_connect_control(node)
	for child in node.get_children():
		_connect_controls_recursively(child)


func _connect_control(control: Control) -> void:
	if control.is_in_group("global_ui_sound_exempt"):
		return

	if control is BaseButton:
		var button := control as BaseButton
		if not button.pressed.is_connected(_play_confirmation_sound):
			button.pressed.connect(_play_confirmation_sound)
		return

	if control is Range:
		var value_control := control as Range
		if not value_control.value_changed.is_connected(_on_range_changed):
			value_control.value_changed.connect(_on_range_changed)
		return

	if control is LineEdit:
		var line_edit := control as LineEdit
		if not line_edit.text_submitted.is_connected(_on_line_edit_submitted):
			line_edit.text_submitted.connect(_on_line_edit_submitted)
		return

	# Clickable custom controls (cards, tabs, and other focusable UI elements)
	# receive a click sound without double-playing it for standard buttons.
	if control.focus_mode != Control.FOCUS_NONE:
		if not control.gui_input.is_connected(_on_custom_control_input):
			control.gui_input.connect(_on_custom_control_input.bind(control))


func _on_custom_control_input(event: InputEvent, control: Control) -> void:
	if not is_instance_valid(control) or not control.is_visible_in_tree():
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_play_confirmation_sound()


func _on_range_changed(_value: float) -> void:
	_play_confirmation_sound()


func _on_line_edit_submitted(_text: String) -> void:
	_play_confirmation_sound()


func _play_confirmation_sound(_unused = null) -> void:
	var now := Time.get_ticks_usec()
	if now - last_click_usec < CLICK_COOLDOWN_USEC:
		return
	last_click_usec = now

	if is_instance_valid(click_player):
		click_player.stop()
		click_player.play()


func _make_click_sound() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.055
	var sample_count := int(sample_rate * duration)
	var pcm_data := PackedByteArray()
	pcm_data.resize(sample_count * 2)

	for i in range(sample_count):
		var t := float(i) / sample_rate
		var progress := t / duration
		var frequency := lerpf(1450.0, 720.0, progress)
		var envelope := exp(-t * 72.0)
		var sample := sin(TAU * frequency * t) * envelope * 0.22
		var pcm := int(clampf(sample, -1.0, 1.0) * 32767.0)
		pcm_data[i * 2] = pcm & 0xff
		pcm_data[i * 2 + 1] = (pcm >> 8) & 0xff

	var click := AudioStreamWAV.new()
	click.format = AudioStreamWAV.FORMAT_16_BITS
	click.mix_rate = sample_rate
	click.stereo = false
	click.data = pcm_data
	return click
