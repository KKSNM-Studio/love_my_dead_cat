# =====================================================
# FeedGame.gd - FEED MINIGAME
# =====================================================
# Player chooses what to feed the cat, then does 3 QTE rounds
#
# GAME FLOW:
# 1. Show food choices (Cat Food vs Raw Meat)
# 2. Player clicks one
# 3. If Raw Meat → lose affinity (bad choice!)
# 4. Play 3 rounds of QTE
# 5. Calculate performance (how many perfects/safes/dangers)
# 6. Give affinity based on performance
# 7. Return to Living Room
#
# REQUIRED SCENE STRUCTURE:
# FeedGame (Control) ← This script
# ├── FoodChoice (Panel) - shown first
# │   └── VBoxContainer
# │       ├── CatFoodButton (Button)
# │       └── RawMeatButton (Button)
# ├── QTEContainer (Control) - shown after food choice
# │   └── QTECircle (INSTANCED SCENE from QTECircle.tscn)
# └── UI (CanvasLayer)
#     ├── HeartDisplay (HBoxContainer)
#     ├── RoundLabel (Label)
#     └── InstructionLabel (Label)
# =====================================================

extends Control

# =====================================================
# NODE REFERENCES
# =====================================================
# Get buttons for food choice
@onready var cat_food_button = $FoodChoice/VBoxContainer/CatFoodButton
@onready var raw_meat_button = $FoodChoice/VBoxContainer/RawMeatButton

# Container sections
@onready var food_choice_container = $FoodChoice
@onready var qte_container = $QTEContainer

# The QTE minigame (instanced scene)
@onready var qte_circle = $QTEContainer/QTECircle

# UI elements
@onready var heart_display = $UI/HeartDisplay
@onready var round_label = $UI/RoundLabel
@onready var instruction_label = $UI/InstructionLabel

# =====================================================
# GAME STATE
# =====================================================
var current_round: int = 0     # Which QTE round (1, 2, or 3)
var max_rounds: int = 3        # Total rounds to play
var total_score: int = 0       # Sum of all QTE scores
var food_chosen: String = ""   # "cat_food" or "raw_meat"

# =====================================================
# INITIALIZATION
# =====================================================
func _ready():
	"""Setup the minigame when scene loads"""
	
	# Give player fresh hearts for this minigame
	Global.reset_hearts()
	
	# Setup UI
	setup_ui()
	
	# Show food choice first
	show_food_choice()
	
	# Connect button signals (manual connection in code)
	cat_food_button.pressed.connect(_on_cat_food_chosen)
	raw_meat_button.pressed.connect(_on_raw_meat_chosen)
	
	# Connect QTE completion signal
	qte_circle.qte_completed.connect(_on_qte_completed)
	
	# Update heart display
	update_hearts()

# =====================================================
# UI SETUP
# =====================================================
func setup_ui():
	"""Initialize UI elements"""
	# Hide QTE at start
	qte_container.hide()
	# Show food choice
	food_choice_container.show()
	# Set round label
	update_round_label()

func update_round_label():
	"""Update the "Round X / 3" label"""
	# Shows current round (we add 1 because array starts at 0)
	round_label.text = "Round %d / %d" % [current_round + 1, max_rounds]

func update_hearts():
	"""Refresh heart display from Global"""
	if heart_display:
		# HeartDisplay has a function to update visuals
		if heart_display.has_method("set_hearts"):
			heart_display.set_hearts(Global.get_hearts())

# =====================================================
# PHASE 1: FOOD CHOICE
# =====================================================
func show_food_choice():
	"""Show the food selection buttons"""
	food_choice_container.show()
	qte_container.hide()
	instruction_label.text = "Choose food for your cat!"

func _on_cat_food_chosen():
	"""Player clicked Cat Food button (SAFE choice)"""
	food_chosen = "cat_food"
	AudioManager.play_button_click()
	
	print("Player chose cat food (safe choice)")
	
	# This is the correct choice - no penalty
	# Just proceed to QTE
	start_qte_rounds()

func _on_raw_meat_chosen():
	"""Player clicked Raw Meat button (DANGEROUS choice)"""
	food_chosen = "raw_meat"
	AudioManager.play_button_click()
	
	print("Player chose raw meat (dangerous choice)")
	
	# This is a BAD choice! Cat doesn't like raw meat
	Global.remove_affinity(100)  # Big penalty!
	AudioManager.play_affinity_loss()
	
	# Show warning message to player
	instruction_label.text = "The cat looks unsettled by the raw meat..."
	await get_tree().create_timer(2.0).timeout
	
	# Still proceed to QTE (but cat will be more angry = harder)
	start_qte_rounds()

# =====================================================
# PHASE 2: QTE ROUNDS
# =====================================================
func start_qte_rounds():
	"""Begin the 3 QTE rounds"""
	# Hide food choice
	food_choice_container.hide()
	# Show QTE
	qte_container.show()
	
	# Reset counters
	current_round = 0
	total_score = 0
	
	# Start first round
	start_next_round()

func start_next_round():
	"""Start the next QTE round"""
	current_round += 1
	update_round_label()
	
	print("Starting round ", current_round)
	instruction_label.text = "Round %d - Click when in green zone!" % current_round
	
	# Brief countdown before QTE starts
	await get_tree().create_timer(1.0).timeout
	
	# Start the QTE
	qte_circle.start_qte()

func _on_qte_completed(result: String, score: int):
	"""Called when QTE finishes (from signal)"""
	# result: "perfect", "safe", or "danger"
	# score: 3, 1, or 0
	
	print("QTE completed: ", result, " | Score: ", score)
	
	# Add to total score
	total_score += score
	
	# Update heart display (may have lost a heart)
	update_hearts()
	
	# Check if player ran out of hearts
	if Global.get_hearts() <= 0:
		# Game Over is handled by Global
		# (it automatically loads GameOver scene)
		return
	
	# Check if more rounds to play
	if current_round < max_rounds:
		# Play next round
		await get_tree().create_timer(0.5).timeout
		start_next_round()
	else:
		# All rounds complete! Show results
		show_results()

# =====================================================
# PHASE 3: RESULTS & SCORING
# =====================================================
func show_results():
	"""Calculate final score and give affinity"""
	print("Minigame complete! Total score: ", total_score)
	
	# Tell Global that player did play a minigame today
	Global.record_minigame_played()
	
	# Determine performance level
	var performance = calculate_performance()
	
	# Give affinity based on performance
	award_affinity(performance)
	
	# Show result screen UI
	show_result_screen(performance)

func calculate_performance() -> String:
	"""Convert score to performance rating"""
	# Max score = 3 rounds × 3 points = 9
	# 7-9 = good (mostly perfects)
	# 4-6 = okay (mix of hits)
	# 0-3 = bad (mostly dangers/misses)
	
	if total_score >= 7:
		return "good"
	elif total_score >= 4:
		return "okay"
	else:
		return "bad"

func award_affinity(performance: String):
	"""Give/take affinity based on performance"""
	match performance:
		"good":
			Global.add_affinity(100)    # Big reward
			AudioManager.play_affinity_gain()
		"okay":
			Global.add_affinity(30)     # Small reward
			AudioManager.play_affinity_gain()
		"bad":
			Global.remove_affinity(50)  # Penalty
			AudioManager.play_affinity_loss()

func show_result_screen(performance: String):
	"""Load and show the result screen"""
	# Load the result screen scene
	var result_scene = load("res://Scenes/UI/ResultScreen.tscn")
	
	if result_scene:
		var result_screen = result_scene.instantiate()
		add_child(result_screen)
		
		# Show the results (performance, score, max_score)
		result_screen.show_result(performance, total_score, 9)
		
		# Wait for player to click Continue
		result_screen.continue_pressed.connect(return_to_living_room)
	else:
		print("Result screen not found, returning to living room")
		await get_tree().create_timer(2.0).timeout
		return_to_living_room()

func return_to_living_room():
	"""Go back to main hub"""
	get_tree().change_scene_to_file("res://Scenes/Main/LivingRoom.tscn")

# =====================================================
# DEBUGGING
# =====================================================
# To test this minigame alone:
# 1. Open FeedGame.tscn
# 2. Press F6 (run current scene)
# 3. Should be able to play without Living Room
#
# Common issues:
# - Buttons don't work? Check signals are connected
# - QTE doesn't appear? Check qte_container visibility
# - Hearts don't update? Check HeartDisplay has set_hearts() method
# - Can't return to Living Room? Check scene path is correct
# =====================================================
