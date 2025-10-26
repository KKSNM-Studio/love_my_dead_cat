# ShowerGame.gd
# Shower minigame - Area2D collision + dodge mechanic + QTE
# Place in: Scenes/Minigames/Shower/ShowerGame.gd

extends Control

# ===== NODES =====
@onready var cat_sprite = $CatSprite
@onready var soap = $Soap
@onready var soap_pickup_area = $Soap/Area2D
@onready var cat_body_area = $CatSprite/BodyArea2D
@onready var player_cursor = $PlayerCursor  # Follows mouse
@onready var scratch_warning = $ScratchWarning  # Shows when cat about to scratch
@onready var qte_container = $QTEContainer
@onready var qte_circle = $QTEContainer/QTECircle
@onready var heart_display = $UI/HeartDisplay
@onready var round_label = $UI/RoundLabel
@onready var instruction_label = $UI/InstructionLabel

# ===== STATE =====
var current_round: int = 0
var max_rounds: int = 3
var total_score: int = 0

var has_soap: bool = false
var wiping_progress: float = 0.0
var wiping_complete: bool = false

var cat_scratch_timer: float = 0.0
var cat_scratch_cooldown: float = 3.0  # Scratches every 3 seconds
var is_dodging: bool = false

enum Phase { PICKUP_SOAP, WIPE_CAT, QTE }
var current_phase: Phase = Phase.PICKUP_SOAP

# ===== INITIALIZATION =====
func _ready():
	Global.reset_hearts()
	setup_ui()
	start_phase_pickup_soap()
	
	# Connect signals
	qte_circle.qte_completed.connect(_on_qte_completed)
	update_hearts()

func _process(delta):
	# Move cursor to follow mouse
	if player_cursor:
		player_cursor.position = get_local_mouse_position()
	
	# Handle current phase
	match current_phase:
		Phase.PICKUP_SOAP:
			check_soap_pickup()
		Phase.WIPE_CAT:
			handle_wiping(delta)
			handle_cat_scratch(delta)

# ===== SETUP =====
func setup_ui():
	qte_container.hide()
	update_round_label()
	instruction_label.text = "Get the soap!"

func update_round_label():
	round_label.text = "Round %d / %d" % [current_round + 1, max_rounds]

func update_hearts():
	if heart_display:
		heart_display.set_hearts(Global.get_hearts())

# ===== PHASE 1: PICKUP SOAP =====
func start_phase_pickup_soap():
	current_phase = Phase.PICKUP_SOAP
	soap.show()
	instruction_label.text = "Move cursor to get the soap!"
	
	# Position soap randomly
	soap.position = Vector2(randf_range(200, 1000), randf_range(200, 600))

func check_soap_pickup():
	if not has_soap:
		# Check if cursor overlaps soap
		var cursor_pos = player_cursor.position
		var soap_pos = soap.position
		var distance = cursor_pos.distance_to(soap_pos)
		
		if distance < 50:  # Close enough to pick up
			pickup_soap()

func pickup_soap():
	has_soap = true
	soap.hide()
	AudioManager.play_sfx("res://Assets/Audio/Minigames/soap_squish.ogg")
	
	# Move to wipe phase
	start_phase_wipe_cat()

# ===== PHASE 2: WIPE CAT =====
func start_phase_wipe_cat():
	current_phase = Phase.WIPE_CAT
	instruction_label.text = "Wipe the cat! Avoid scratches!"
	wiping_progress = 0.0
	wiping_complete = false
	cat_scratch_timer = cat_scratch_cooldown

func handle_wiping(delta):
	if wiping_complete:
		return
	
	# Check if cursor is on cat body
	if is_cursor_on_cat():
		wiping_progress += delta * 30.0  # 30% per second
		
		# Visual feedback - cat gets cleaner
		cat_sprite.modulate = Color(1, 1, 1, 0.5 + wiping_progress / 200.0)
		
		if wiping_progress >= 100.0:
			wiping_progress = 100.0
			complete_wiping()
	
	# Update progress (could show progress bar)

func is_cursor_on_cat() -> bool:
	# Simple distance check
	var cursor_pos = player_cursor.position
	var cat_pos = cat_sprite.position
	return cursor_pos.distance_to(cat_pos) < 150

func complete_wiping():
	wiping_complete = true
	AudioManager.play_sfx("res://Assets/Audio/Minigames/water_splash.ogg")
	instruction_label.text = "Cat is clean! Get ready for QTE..."
	
	await get_tree().create_timer(1.0).timeout
	start_qte_phase()

# ===== CAT SCRATCH MECHANIC =====
func handle_cat_scratch(delta):
	cat_scratch_timer -= delta
	
	if cat_scratch_timer <= 1.0 and cat_scratch_timer > 0.8:
		# Show warning
		if scratch_warning:
			scratch_warning.show()
			scratch_warning.modulate = Color(1, 0, 0, 0.5)
	
	if cat_scratch_timer <= 0:
		trigger_cat_scratch()
		cat_scratch_timer = cat_scratch_cooldown

func trigger_cat_scratch():
	scratch_warning.hide()
	
	# Check if player was still wiping (cursor on cat)
	if is_cursor_on_cat() and not is_dodging:
		# Player got scratched!
		player_got_scratched()
	
	AudioManager.play_cat_hiss()

func player_got_scratched():
	print("Player got scratched!")
	
	# Lose some progress
	wiping_progress -= 20.0
	wiping_progress = max(0, wiping_progress)
	
	# Visual feedback
	screen_shake()

func screen_shake():
	# Simple screen shake effect
	var tween = create_tween()
	var original_pos = position
	tween.tween_property(self, "position", original_pos + Vector2(10, 0), 0.05)
	tween.tween_property(self, "position", original_pos - Vector2(10, 0), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)

# ===== PHASE 3: QTE =====
func start_qte_phase():
	current_phase = Phase.QTE
	instruction_label.text = "QTE Time!"
	
	qte_container.show()
	await get_tree().create_timer(1.0).timeout
	qte_circle.start_qte()

func _on_qte_completed(result: String, score: int):
	total_score += score
	update_hearts()
	
	if Global.get_hearts() <= 0:
		return
	
	# Next round or finish
	if current_round < max_rounds - 1:
		next_round()
	else:
		show_results()

func next_round():
	current_round += 1
	update_round_label()
	
	await get_tree().create_timer(0.5).timeout
	
	# Reset for next round
	start_phase_pickup_soap()

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
