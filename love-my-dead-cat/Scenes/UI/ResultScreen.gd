# =====================================================
# ResultScreen.gd - COMPLETE MINIGAME RESULT SCREEN
# =====================================================
# Shows results after completing a minigame with:
# - Topic (minigame name)
# - Result (Good/Okay/Bad)
# - Photo (cat reaction image)
# - Description (flavor text)
# - Score (X/9 points)
# - Continue button
#
# USAGE FROM MINIGAME:
# var result = load("res://Scenes/UI/ResultScreen.tscn").instantiate()
# add_child(result)
# result.show_result("good", 7, 9, "Feed")
# result.continue_pressed.connect(return_to_living_room)
# =====================================================

extends Panel

# =====================================================
# SIGNAL - Emitted when player clicks Continue
# =====================================================
signal continue_pressed

# =====================================================
# NODE REFERENCES
# =====================================================
# All these nodes must exist in your scene!
@onready var topic_label = $Content/TopicLabel
@onready var result_label = $Content/ResultLabel
@onready var photo_result = $Content/PhotoResult
@onready var description_label = $Content/DescriptionLabel
@onready var score_label = $Content/ScoreLabel
@onready var continue_button = $ContinueButton

# =====================================================
# PERFORMANCE DATA
# =====================================================
# Define what each performance level means
const PERFORMANCE_DATA = {
	"good": {
		"title": "😊 EXCELLENT!",
		"color": Color.GREEN,
		"description": "The cat purrs contentedly. You did great!",
		"photo_modulate": Color(0.8, 1.0, 0.8)  # Greenish tint
	},
	"okay": {
		"title": "😐 DECENT",
		"color": Color.YELLOW,
		"description": "The cat seems satisfied... mostly.",
		"photo_modulate": Color(1.0, 1.0, 0.8)  # Yellowish tint
	},
	"bad": {
		"title": "😾 POOR",
		"color": Color.RED,
		"description": "The cat is visibly upset with your performance.",
		"photo_modulate": Color(1.0, 0.8, 0.8)  # Reddish tint
	}
}

# =====================================================
# INITIALIZATION
# =====================================================
func _ready():
	"""Setup the result screen"""
	# Hide by default
	hide()
	
	# Connect continue button
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	
	# Set default text
	reset_display()

func reset_display():
	"""Set all labels to default state"""
	if topic_label:
		topic_label.text = "MINIGAME COMPLETE"
	if result_label:
		result_label.text = ""
	if description_label:
		description_label.text = ""
	if score_label:
		score_label.text = ""

# =====================================================
# MAIN FUNCTION - Show Results
# =====================================================
func show_result(performance: String, score: int, max_score: int, minigame_name: String = "Minigame"):
	"""Display the results
	
	Args:
		performance: "good", "okay", or "bad"
		score: Points earned (0-9 typically)
		max_score: Max possible points (usually 9)
		minigame_name: Name of the minigame ("Feed", "Shower", etc.)
	"""
	
	# Make visible
	show()
	
	# Set topic (minigame name)
	if topic_label:
		topic_label.text = minigame_name.to_upper() + " COMPLETE"
	
	# Get performance data
	var perf_data = PERFORMANCE_DATA.get(performance, PERFORMANCE_DATA["okay"])
	
	# Set result title and color
	if result_label:
		result_label.text = perf_data["title"]
		result_label.modulate = perf_data["color"]
	
	# Set description
	if description_label:
		description_label.text = perf_data["description"]
	
	# Set photo tint based on performance
	if photo_result:
		photo_result.modulate = perf_data["photo_modulate"]
		# Try to load appropriate cat photo
		load_cat_photo(performance)
	
	# Animate score count-up
	if score_label:
		score_label.text = "Score: 0 / %d" % max_score
		animate_score(score, max_score)
	
	# Play appropriate sound
	play_result_sound(performance)
	
	# Animate entrance
	animate_entrance()

# =====================================================
# CAT PHOTO LOADING
# =====================================================
func load_cat_photo(performance: String):
	"""Load cat reaction image based on performance"""
	if not photo_result:
		return
	
	# Try to load performance-specific photo
	var photo_paths = [
		"res://Assets/Art/Results/cat_result_%s.png" % performance,
		"res://Assets/Art/Cat/cat_%s.png" % performance,
		"res://Assets/Art/Cat/cat_%s.png" % Global.get_cat_mood()
	]
	
	for path in photo_paths:
		if FileAccess.file_exists(path):
			photo_result.texture = load(path)
			return
	
	# Fallback: Use colored rectangle
	print("Cat photo not found, using placeholder")
	# Photo already has color tint from modulate

# =====================================================
# SCORE ANIMATION
# =====================================================
func animate_score(final_score: int, max_score: int):
	"""Animate score counting up from 0 to final score"""
	var current = 0
	var duration = 1.0  # 1 second total
	var steps = 20      # 20 animation steps
	var delay = duration / steps
	var increment = float(final_score) / steps
	
	# Count up gradually
	for i in range(steps):
		await get_tree().create_timer(delay).timeout
		current += increment
		score_label.text = "Score: %d / %d" % [int(current), max_score]
		
		# Play tick sound every few steps
		if i % 5 == 0:
			AudioManager.play_sfx_safe("res://Assets/Audio/UI/score_tick.ogg", 0.3)
	
	# Ensure final value is exact
	score_label.text = "Score: %d / %d" % [final_score, max_score]
	
	# Play completion sound
	AudioManager.play_sfx_safe("res://Assets/Audio/UI/score_complete.ogg")

# =====================================================
# ENTRANCE ANIMATION
# =====================================================
func animate_entrance():
	"""Animate the panel appearing"""
	# Start slightly smaller and transparent
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0
	
	# Animate to full size and opacity
	var tween = create_tween()
	tween.set_parallel(true)  # Run both animations at once
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Play whoosh sound
	AudioManager.play_sfx_safe("res://Assets/Audio/UI/result_appear.ogg")

# =====================================================
# AUDIO FEEDBACK
# =====================================================
func play_result_sound(performance: String):
	"""Play sound based on performance"""
	match performance:
		"good":
			AudioManager.play_sfx_safe("res://Assets/Audio/UI/result_good.ogg")
		"okay":
			AudioManager.play_sfx_safe("res://Assets/Audio/UI/result_okay.ogg")
		"bad":
			AudioManager.play_sfx_safe("res://Assets/Audio/UI/result_bad.ogg")

# =====================================================
# CONTINUE BUTTON
# =====================================================
func _on_continue_pressed():
	"""Called when Continue button is clicked"""
	AudioManager.play_button_click()
	
	# Animate exit
	animate_exit()
	
	# Wait for animation
	await get_tree().create_timer(0.3).timeout
	
	# Emit signal to parent
	emit_signal("continue_pressed")
	
	# Remove self
	queue_free()

func animate_exit():
	"""Animate the panel disappearing"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)

# =====================================================
# ALTERNATIVE: Simple Version (If Images Don't Work)
# =====================================================
func show_result_simple(performance: String, score: int, max_score: int):
	"""Simplified version without images"""
	show()
	
	var perf_data = PERFORMANCE_DATA.get(performance, PERFORMANCE_DATA["okay"])
	
	if result_label:
		result_label.text = perf_data["title"]
		result_label.modulate = perf_data["color"]
	
	if description_label:
		description_label.text = perf_data["description"]
	
	if score_label:
		score_label.text = "Score: %d / %d" % [score, max_score]
	
	# Skip animations if performance is an issue
	# animate_entrance()

# =====================================================
# DEBUGGING
# =====================================================
# Test this scene directly:
# 1. Open ResultScreen.tscn
# 2. Attach this script to root Panel
# 3. Press F6 to run
# 4. In _ready(), add:
#    show_result("good", 7, 9, "Test")
# =====================================================
