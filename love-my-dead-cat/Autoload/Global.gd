# ==================================================================
# Global.gd - CORRECTED VERSION V4
# ==================================================================
# Core game state manager with proper affinity, injury, and demon systems
#
# KEY CHANGES FROM OLD VERSION:
# - Affinity: 0-100 range (was -500 to 1000)
# - Starting affinity: 50 (was 500)
# - Days: 3 maximum (was 4)
# - Added injury system
# - Added demon mode
# - Removed sign system
# - Changed from mood to state system
# ==================================================================

extends Node

# ===== SIGNALS =====
signal affinity_changed(new_affinity: int)
signal injury_changed(new_injury: int)
signal day_changed(new_day: int)
signal cat_state_changed(new_state: String)

# ===== CONSTANTS =====
const MAX_DAYS = 3
const MAX_AFFINITY = 100
const MIN_AFFINITY = 0
const STARTING_AFFINITY = 50

# Ending thresholds
const GOOD_ENDING_THRESHOLD = 70

# Cat state thresholds
const DEMON_AFFINITY_THRESHOLD = 30
const DEMON_INJURY_THRESHOLD = 3

# Injury penalty
const INJURY_AFFINITY_PENALTY = 5

# Hearts (for minigames)
const MAX_HEARTS = 3

# ===== GAME STATE =====
var current_day: int = 1
var affinity: int = STARTING_AFFINITY
var injury: int = 0
var demon_mode: bool = false
var cat_state: String = "normal"  # "normal", "injury", "demon"
var hearts: int = MAX_HEARTS

# Tracking
var minigames_played_today: int = 0

# ===== INITIALIZATION =====
func _ready():
	print("=== Global Manager Initialized (V4) ===")
	print("Starting Affinity: ", affinity)
	print("Starting Injury: ", injury)
	print("Starting Day: ", current_day)
	_update_cat_state()

# ===== AFFINITY MANAGEMENT =====

func add_affinity(amount: int):
	"""Add affinity points (can be negative to subtract)"""
	var old_affinity = affinity
	affinity = clamp(affinity + amount, MIN_AFFINITY, MAX_AFFINITY)
	
	print("[Global] Affinity: ", old_affinity, " → ", affinity, " (", 
		  "+%d" % amount if amount >= 0 else "%d" % amount, ")")
	
	emit_signal("affinity_changed", affinity)
	_update_cat_state()
	
	# Auto-save on affinity change
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").auto_save()

func remove_affinity(amount: int):
	"""Remove affinity (convenience function)"""
	add_affinity(-amount)

func get_affinity() -> int:
	"""Get current affinity value"""
	return affinity

func get_affinity_percentage() -> float:
	"""Returns 0.0 to 1.0 for UI display (e.g., progress bars)"""
	return float(affinity) / float(MAX_AFFINITY)

# ===== INJURY SYSTEM =====

func add_injury(amount: int = 1):
	"""
	Add injury points (from failed minigames)
	Triggers state update and auto-save
	"""
	injury += amount
	print("[Global] Injury added: +", amount, " | Total: ", injury)
	
	emit_signal("injury_changed", injury)
	_update_cat_state()
	
	# Auto-save on injury change
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").auto_save()

func heal_injury(amount: int = 1):
	"""
	Heal injury (from successful StuffOffal minigame)
	Cannot go below 0
	"""
	var old_injury = injury
	injury = max(0, injury - amount)
	
	print("[Global] Injury healed: -", amount, " | Remaining: ", injury)
	
	emit_signal("injury_changed", injury)
	_update_cat_state()
	
	# Auto-save on injury change
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").auto_save()

func get_injury() -> int:
	"""Get current injury value"""
	return injury

func must_fix_injury_before_play() -> bool:
	"""
	Check if StuffOffal MUST be played first
	Returns true if injury > 0
	"""
	return injury > 0

# ===== CAT STATE SYSTEM =====

func _update_cat_state():
	"""
	Update cat's visual/behavioral state based on injury and affinity
	
	State Priority:
	1. Demon: injury >= 3 OR affinity < 30 (highest priority)
	2. Injury: injury >= 1 (guts visible)
	3. Normal: injury == 0 (default)
	"""
	var old_state = cat_state
	
	# Check conditions in priority order
	if injury >= DEMON_INJURY_THRESHOLD or affinity < DEMON_AFFINITY_THRESHOLD:
		cat_state = "demon"
		demon_mode = true
	elif injury > 0:
		cat_state = "injury"
		demon_mode = false
	else:
		cat_state = "normal"
		demon_mode = false
	
	# Only emit signal if state actually changed
	if old_state != cat_state:
		print("[Global] Cat state changed: ", old_state, " → ", cat_state)
		emit_signal("cat_state_changed", cat_state)
		
		# Auto-save on state change
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").auto_save()

func get_cat_state() -> String:
	"""Get current cat state ("normal", "injury", or "demon")"""
	return cat_state

func is_demon_mode() -> bool:
	"""Check if cat is in demon mode"""
	return demon_mode

# ===== HEARTS SYSTEM (for minigames) =====

func reset_hearts():
	"""Reset hearts to maximum (called at start of each minigame)"""
	hearts = MAX_HEARTS

func lose_heart():
	"""Lose one heart (called when QTE fails)"""
	hearts = max(0, hearts - 1)
	print("[Global] Heart lost! Remaining: ", hearts)
	return hearts

func get_hearts() -> int:
	"""Get current hearts"""
	return hearts

func is_out_of_hearts() -> bool:
	"""Check if player has run out of hearts"""
	return hearts <= 0

# ===== DAY PROGRESSION =====

func advance_day():
	"""
	Move to next day
	- Apply injury penalty to affinity BEFORE advancing
	- Reset daily counters
	- Check if game should end
	"""
	# Apply injury penalty BEFORE advancing day
	if injury > 0:
		var penalty = injury * INJURY_AFFINITY_PENALTY
		print("[Global] Injury penalty applied: -", penalty, " affinity (", injury, " injuries)")
		remove_affinity(penalty)
	
	# Advance day
	current_day += 1
	minigames_played_today = 0
	
	print("=== DAY ", current_day, " ===")
	print("Current Affinity: ", affinity)
	print("Current Injury: ", injury)
	print("Current State: ", cat_state)
	
	emit_signal("day_changed", current_day)
	
	# Auto-save on day change
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").auto_save()
	
	# Check if game should end
	if current_day > MAX_DAYS:
		print("[Global] Game complete! Going to ending...")
		# Don't immediately go to ending - let player see mail first
		# Ending will be triggered when player clicks the mail

func get_current_day() -> int:
	"""Get current day number (1-3)"""
	return current_day

func is_final_day() -> bool:
	"""Check if this is the last day (Day 3)"""
	return current_day == MAX_DAYS

func is_game_over() -> bool:
	"""Check if game has ended (past day 3)"""
	return current_day > MAX_DAYS

func record_minigame_played():
	"""Track that player completed a minigame today"""
	minigames_played_today += 1
	print("[Global] Minigames played today: ", minigames_played_today)

# ===== ENDING SYSTEM =====

func determine_ending() -> String:
	"""
	Determine which ending to show based on final affinity
	
	SPEC:
	- Affinity >= 70 → Good Ending
	- Affinity < 70 → Bad Ending
	"""
	if affinity >= GOOD_ENDING_THRESHOLD:
		return "good"
	else:
		return "bad"

func go_to_ending():
	"""Load the appropriate ending scene based on affinity"""
	var ending_type = determine_ending()
	
	print("=== GOING TO ENDING ===")
	print("Final Affinity: ", affinity)
	print("Final Injury: ", injury)
	print("Final State: ", cat_state)
	print("Ending Type: ", ending_type.to_upper())
	
	match ending_type:
		"good":
			get_tree().change_scene_to_file("res://Scenes/Endings/GoodEnding.tscn")
		"bad":
			get_tree().change_scene_to_file("res://Scenes/Endings/BadEnding.tscn")
		_:
			print("ERROR: Unknown ending type: ", ending_type)

# ===== GAME MANAGEMENT =====

func restart_game():
	"""Reset all state and return to main menu"""
	current_day = 1
	affinity = STARTING_AFFINITY
	injury = 0
	demon_mode = false
	cat_state = "normal"
	hearts = MAX_HEARTS
	minigames_played_today = 0
	
	print("=== GAME STATE RESET ===")
	
	# Clear save file
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").clear_save()
	
	get_tree().change_scene_to_file("res://Scenes/Main/MainMenu.tscn")

func quit_game():
	"""Exit the game"""
	print("=== QUITTING GAME ===")
	get_tree().quit()

# ===== SAVE/LOAD SYSTEM =====

func get_save_data() -> Dictionary:
	"""Return current game state as dictionary for saving"""
	return {
		"day": current_day,
		"affinity": affinity,
		"injury": injury,
		"demon_mode": demon_mode,
		"cat_state": cat_state,
		"hearts": hearts,
		"minigames_played": minigames_played_today,
		"version": "v4"  # For future compatibility
	}

func load_save_data(data: Dictionary):
	"""Restore game state from save data"""
	if data.has("day"):
		current_day = data.day
	if data.has("affinity"):
		affinity = data.affinity
	if data.has("injury"):
		injury = data.injury
	if data.has("demon_mode"):
		demon_mode = data.demon_mode
	if data.has("cat_state"):
		cat_state = data.cat_state
	if data.has("hearts"):
		hearts = data.hearts
	if data.has("minigames_played"):
		minigames_played_today = data.minigames_played
	
	# Update state after loading
	_update_cat_state()
	
	print("=== GAME LOADED ===")
	print("Day: ", current_day)
	print("Affinity: ", affinity)
	print("Injury: ", injury)
	print("State: ", cat_state)

# ===== DEBUG HELPERS (Optional - Remove in production) =====

func debug_set_affinity(value: int):
	"""Debug: Set affinity to specific value"""
	affinity = clamp(value, MIN_AFFINITY, MAX_AFFINITY)
	emit_signal("affinity_changed", affinity)
	_update_cat_state()
	print("[DEBUG] Affinity set to: ", affinity)

func debug_set_injury(value: int):
	"""Debug: Set injury to specific value"""
	injury = max(0, value)
	emit_signal("injury_changed", injury)
	_update_cat_state()
	print("[DEBUG] Injury set to: ", injury)

func debug_set_day(day: int):
	"""Debug: Jump to specific day"""
	current_day = clamp(day, 1, MAX_DAYS + 1)
	emit_signal("day_changed", current_day)
	print("[DEBUG] Day set to: ", current_day)

func debug_trigger_demon():
	"""Debug: Force demon mode"""
	injury = DEMON_INJURY_THRESHOLD
	_update_cat_state()
	print("[DEBUG] Demon mode triggered")

func debug_print_state():
	"""Debug: Print all current values"""
	print("=== CURRENT STATE ===")
	print("Day: ", current_day, "/", MAX_DAYS)
	print("Affinity: ", affinity, "/", MAX_AFFINITY, " (", get_affinity_percentage() * 100, "%)")
	print("Injury: ", injury)
	print("Cat State: ", cat_state)
	print("Demon Mode: ", demon_mode)
	print("Hearts: ", hearts, "/", MAX_HEARTS)
	print("Minigames Today: ", minigames_played_today)
	print("Will Get Ending: ", determine_ending().to_upper())
	print("==================")
