# =====================================================
# FeedGame.gd - FEED MINIGAME
# =====================================================
# Player chooses what to feed the cat, then does 3 QTE rounds (if Cat Food chosen)
#
# GAME FLOW:
# 1. Show food choices (Cat Food vs Raw Meat)
# 2. Cat Food → Start QTE (3 rounds)
# 3. Raw Meat → Immediately bad result
# =====================================================

extends Control

# =====================================================
# NODE REFERENCES
# =====================================================
@onready var cat_food_button = $FoodChoice/VBoxContainer/CatFoodButton
@onready var raw_meat_button = $FoodChoice/VBoxContainer/RawMeatButton

@onready var food_choice_container = $FoodChoice
@onready var qte_container = $QTEContainer
@onready var qte_circle = $QTEContainer/QteCircle

@onready var heart_display = $UI/HeartDisplay
@onready var round_label = $UI/RoundLabel
@onready var instruction_label = $UI/InstructionLabel

# =====================================================
# GAME STATE
# =====================================================
var current_round: int = 0
var max_rounds: int = 3
var total_score: int = 0
var food_chosen: String = ""

# =====================================================
# INITIALIZATION
# =====================================================
func _ready():
	Global.reset_hearts()
	setup_ui()
	show_food_choice()

	# Connect buttons
	cat_food_button.pressed.connect(_on_cat_food_chosen)
	raw_meat_button.pressed.connect(_on_raw_meat_chosen)

	# Connect QTE signal
	qte_circle.qte_completed.connect(_on_qte_completed)

	update_hearts()

# =====================================================
# UI
# =====================================================
func setup_ui():
	qte_container.hide()
	food_choice_container.show()
	update_round_label()

func update_round_label():
	round_label.text = "Round %d / %d" % [max(current_round, 1), max_rounds]

func update_hearts():
	if heart_display and heart_display.has_method("set_hearts"):
		heart_display.set_hearts(Global.get_hearts())

# =====================================================
# PHASE 1: FOOD CHOICE
# =====================================================
func show_food_choice():
	food_choice_container.show()
	qte_container.hide()
	instruction_label.text = "Choose food for your cat!"

func _on_cat_food_chosen():
	food_chosen = "cat_food"
	AudioManager.play_button_click()

	print("Player chose cat food (safe choice)")
	start_qte_rounds()

func _on_raw_meat_chosen():
	food_chosen = "raw_meat"
	AudioManager.play_button_click()

	print("Player chose raw meat (bad choice)")

	# Big penalty, then immediate bad result
	Global.remove_affinity(100)
	AudioManager.play_affinity_loss()
	instruction_label.text = "The cat refuses to eat raw meat..."

	await get_tree().create_timer(1.5).timeout
	show_results_direct_bad()

# =====================================================
# PHASE 2: QTE ROUNDS
# =====================================================
func start_qte_rounds():
	food_choice_container.hide()
	qte_container.show()

	current_round = 0
	total_score = 0

	start_next_round()

func start_next_round():
	current_round += 1
	update_round_label()
	instruction_label.text = "Round %d - Click when in green zone!" % current_round

	await get_tree().create_timer(0.5).timeout
	qte_circle.start_qte()

func _on_qte_completed(result: String, score: int):
	total_score += score
	update_hearts()

	if Global.get_hearts() <= 0:
		return  # Game Over handled globally

	if current_round < max_rounds:
		await get_tree().create_timer(0.5).timeout
		start_next_round()
	else:
		show_results()

# =====================================================
# PHASE 3: RESULTS
# =====================================================
func show_results():
	Global.record_minigame_played()
	var performance = calculate_performance()
	award_affinity(performance)
	show_result_screen(performance)

# Shortcut for raw meat (immediate bad result)
func show_results_direct_bad():
	Global.record_minigame_played()
	award_affinity("bad")
	show_result_screen("bad")

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
			AudioManager.play_affinity_gain()
		"okay":
			Global.add_affinity(30)
			AudioManager.play_affinity_gain()
		"bad":
			Global.remove_affinity(50)
			AudioManager.play_affinity_loss()

func show_result_screen(performance: String):
	var result_scene = load("res://Scenes/UI/ResultScreen.tscn")
	if result_scene:
		var result_screen = result_scene.instantiate()
		add_child(result_screen)
		result_screen.show_result(performance, total_score, 9)
		result_screen.continue_pressed.connect(return_to_living_room)
	else:
		await get_tree().create_timer(1.5).timeout
		return_to_living_room()

func return_to_living_room():
	get_tree().change_scene_to_file("res://Scenes/Main/LivingRoom.tscn")
