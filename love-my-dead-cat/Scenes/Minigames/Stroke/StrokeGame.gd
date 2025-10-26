# StrokeGame.gd
# Stroke minigame - Progress bar + rhythm matching + QTE
# Place in: Scenes/Minigames/Stroke/StrokeGame.gd

extends Control

# ===== NODES =====
@onready var cat_sprite = $CatSprite
@onready var progress_bar = $ProgressBar
@onready var rhythm_indicator = $RhythmIndicator
@onready var qte_container = $QTEContainer
@onready var qte_circle = $QTEContainer/QTECircle
@onready var heart_display = $UI/HeartDisplay
@onready var round_label = $UI/RoundLabel
@onready var instruction_label = $UI/InstructionLabel

# ===== STATE =====
var current_round: int = 0
var max_rounds: int = 3
var total_score: int = 0

var stroking: bool = false
var stroke_progress: float = 0.0
var stroke_speed: float = 0.0  # Current stroking speed
var target_speed: float = 50.0  # Ideal speed (matches cat's purr rhythm)
var speed_tolerance: float = 20.0

var stroke_complete: bool = false

# Rhythm matching
var purr_beat_timer: float = 0.0
var purr_beat_interval: float = 0.5  # Beat every 0.5 seconds
var rhythm_score: int = 0

# ===== INITIALIZATION =====
func _ready():
	Global.reset_hearts()
	setup_ui()
	start_stroking_phase()
	
	qte_circle.qte_completed.connect(_on_qte_completed)
	update_hearts()
	
	# Play purr sound loop
	AudioManager.play_cat_purr()

func _process(delta):
	if stroking and not stroke_complete:
		handle_stroking(delta)
		handle_rhythm(delta)

# ===== SETUP =====
func setup_ui():
	qte_container.hide()
	progress_bar.value = 0
	progress_bar.max_value = 100
	update_round_label()
	instruction_label.text = "Hold mouse button and stroke gently!"

func update_round_label():
	round_label.text = "Round %d / %d" % [current_round + 1, max_rounds]

func update_hearts():
	if heart_display:
		heart_display.set_hearts(Global.get_hearts())

# ===== STROKING PHASE =====
func start_stroking_phase():
	stroking = true
	stroke_complete = false
	stroke_progress = 0.0
	rhythm_score = 0
	progress_bar.value = 0

func _input(event):
	if not stroking or stroke_complete:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Started stroking
				stroke_speed = target_speed
			else:
				# Stopped stroking
				stroke_speed = 0
	
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			# Calculate speed based on mouse movement
			stroke_speed = event.relative.length() * 2.0

func handle_stroking(delta):
	# Check if stroking too hard or too soft
	var speed_diff = abs(stroke_speed - target_speed)
	
	if stroke_speed > 0:
		if speed_diff <= speed_tolerance:
			# Good stroking!
			stroke_progress += delta * 30.0  # 30% per second
			cat_sprite.modulate = Color(1, 1, 1)  # Normal
			
			# Give positive feedback
			if int(stroke_progress) % 20 == 0:
				spawn_heart_particle()
		
		elif stroke_speed > target_speed + speed_tolerance:
			# Too hard!
			stroke_progress -= delta * 10.0  # Lose progress
			cat_sprite.modulate = Color(1, 0.5, 0.5)  # Red tint
			
			if stroke_speed > target_speed * 2:
				cat_hurt()
		
		else:
			# Too soft - no progress but no penalty
			cat_sprite.modulate = Color(0.8, 0.8, 1)  # Blue tint
	
	# Update progress bar
	stroke_progress = clamp(stroke_progress, 0, 100)
	progress_bar.value = stroke_progress
	
	# Check completion
	if stroke_progress >= 100:
		complete_stroking()

func cat_hurt():
	# Cat reacts to hard stroking
	AudioManager.play_cat_hiss()
	stroke_progress -= 30.0
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(cat_sprite, "position", cat_sprite.position + Vector2(20, 0), 0.1)
	tween.tween_property(cat_sprite, "position", cat_sprite.position, 0.1)

func complete_stroking():
	stroke_complete = true
	stroking = false
	instruction_label.text = "Cat is happy! Get ready for QTE..."
	
	AudioManager.play_sfx("res://Assets/Audio/Cat/cat_content_sigh.ogg")
	
	await get_tree().create_timer(1.0).timeout
	start_qte_phase()

# ===== RHYTHM MATCHING =====
func handle_rhythm(delta):
	purr_beat_timer += delta
	
	if purr_beat_timer >= purr_beat_interval:
		purr_beat_timer = 0
		show_rhythm_beat()

func show_rhythm_beat():
	# Visual indicator pulses with cat's purr rhythm
	if rhythm_indicator:
		rhythm_indicator.modulate = Color(1, 1, 0)  # Yellow flash
		
		var tween = create_tween()
		tween.tween_property(rhythm_indicator, "modulate", Color.WHITE, purr_beat_interval * 0.8)
	
	# Check if player is stroking in rhythm
	if stroke_speed > target_speed * 0.5:
		rhythm_score += 1
		
		# Bonus for good rhythm
		if rhythm_score % 5 == 0:
			stroke_progress += 10.0  # Rhythm bonus!
			spawn_note_particle()

# ===== VISUAL EFFECTS =====
func spawn_heart_particle():
	# Create simple heart particle
	var heart = Label.new()
	heart.text = "❤️"
	heart.position = cat_sprite.position + Vector2(randf_range(-50, 50), -50)
	add_child(heart)
	
	var tween = create_tween()
	tween.tween_property(heart, "position", heart.position + Vector2(0, -100), 1.0)
	tween.parallel().tween_property(heart, "modulate", Color.TRANSPARENT, 1.0)
	tween.finished.connect(func(): heart.queue_free())

func spawn_note_particle():
	# Musical note for rhythm bonus
	var note = Label.new()
	note.text = "♪"
	note.position = cat_sprite.position + Vector2(randf_range(-50, 50), -30)
	add_child(note)
	
	var tween = create_tween()
	tween.tween_property(note, "position", note.position + Vector2(50, -50), 0.8)
	tween.parallel().tween_property(note, "modulate", Color.TRANSPARENT, 0.8)
	tween.finished.connect(func(): note.queue_free())

# ===== QTE PHASE =====
func start_qte_phase():
	instruction_label.text = "QTE Time!"
	qte_container.show()
	
	await get_tree().create_timer(1.0).timeout
	qte_circle.start_qte()

func _on_qte_completed(result: String, score: int):
	total_score += score
	update_hearts()
	
	if Global.get_hearts() <= 0:
		return
	
	if current_round < max_rounds - 1:
		next_round()
	else:
		show_results()

func next_round():
	current_round += 1
	update_round_label()
	
	await get_tree().create_timer(0.5).timeout
	start_stroking_phase()

# ===== RESULTS =====
func show_results():
	Global.record_minigame_played()
	
	var performance = calculate_performance()
	award_affinity(performance)
	
	var result_screen = load("res://Scenes/UI/ResultScreen.tscn").instantiate()
	add_child(result_screen)
	result_screen.show_result(performance, total_score, 9)
	result_screen.continue_pressed.connect(return_to_living_room)

func calculate_performance() -> String:
	if total_score >= 7:
		return "good"
	elif total_score >= 4:
		return "okay"
	else:
		return "bad"

func award_affinity(performance: String):
	match performance:
		"good":
			Global.add_affinity(100)
		"okay":
			Global.add_affinity(30)
		"bad":
			Global.remove_affinity(50)

func return_to_living_room():
	get_tree().change_scene_to_file("res://Scenes/Main/LivingRoom.tscn")
