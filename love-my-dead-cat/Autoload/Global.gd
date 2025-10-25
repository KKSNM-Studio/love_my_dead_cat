# Global.gd
# Autoload singleton - Manages all game state
# Place in: Autoload/Global.gd
# Setup: Project > Project Settings > Autoload > Add this script as "Global"

extends Node

# ===== SIGNALS =====
signal affinity_changed(new_affinity: int)
signal heart_lost(hearts_remaining: int)
signal day_changed(new_day: int)
signal cat_mood_changed(new_mood: String)
signal sign_discovered(sign_id: String)

# ===== CONSTANTS =====
const MAX_HEARTS = 3
const MAX_AFFINITY = 1000  # Perfect care = 1000 points
const MIN_AFFINITY = -500  # Terrible care = negative points

# Cat mood thresholds
const MOOD_HAPPY_THRESHOLD = 600
const MOOD_ANGRY_THRESHOLD = 300

# QTE perfect zone sizes based on mood
const PERFECT_ZONE_HAPPY = 90.0  # degrees (large)
const PERFECT_ZONE_NEUTRAL = 60.0  # degrees (medium)
const PERFECT_ZONE_ANGRY = 30.0  # degrees (small)

# ===== GAME STATE =====
var current_day: int = 1
var total_affinity: int = 500  # Start neutral
var hearts: int = MAX_HEARTS
var cat_mood: String = "neutral"  # "happy", "neutral", "angry"

# Tracking systems
var minigames_played_today: int = 0
var signs_discovered: Array[String] = []
var decoded_all_signs: bool = false

# Day progression tracking
var skipped_days: int = 0  # How many days player didn't care for cat

# ===== INITIALIZATION =====
func _ready():
	print("Global manager initialized")
	update_cat_mood()

# ===== AFFINITY MANAGEMENT =====
func add_affinity(amount: int):
	total_affinity += amount
	total_affinity = clamp(total_affinity, MIN_AFFINITY, MAX_AFFINITY)
	print("Affinity changed: +", amount, " | Total: ", total_affinity)
	emit_signal("affinity_changed", total_affinity)
	update_cat_mood()

func remove_affinity(amount: int):
	add_affinity(-amount)

func get_affinity() -> int:
	return total_affinity

func get_affinity_percentage() -> float:
	# Returns 0.0 to 1.0 for UI display
	return float(total_affinity - MIN_AFFINITY) / float(MAX_AFFINITY - MIN_AFFINITY)

# ===== CAT MOOD SYSTEM =====
func update_cat_mood():
	var old_mood = cat_mood
	
	if total_affinity >= MOOD_HAPPY_THRESHOLD:
		cat_mood = "happy"
	elif total_affinity <= MOOD_ANGRY_THRESHOLD:
		cat_mood = "angry"
	else:
		cat_mood = "neutral"
	
	if old_mood != cat_mood:
		print("Cat mood changed: ", old_mood, " -> ", cat_mood)
		emit_signal("cat_mood_changed", cat_mood)

func get_cat_mood() -> String:
	return cat_mood

func get_perfect_zone_size() -> float:
	# Returns QTE perfect zone size based on mood
	match cat_mood:
		"happy":
			return PERFECT_ZONE_HAPPY
		"angry":
			return PERFECT_ZONE_ANGRY
		_:
			return PERFECT_ZONE_NEUTRAL

# ===== HEART SYSTEM =====
func lose_heart():
	hearts -= 1
	hearts = max(0, hearts)
	print("Heart lost! Remaining: ", hearts)
	emit_signal("heart_lost", hearts)
	
	if hearts <= 0:
		game_over_no_hearts()

func reset_hearts():
	hearts = MAX_HEARTS
	print("Hearts reset to ", MAX_HEARTS)

func get_hearts() -> int:
	return hearts

func game_over_no_hearts():
	print("GAME OVER: No hearts remaining!")
	# Wait a moment then switch to game over scene
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://Scenes/Endings/GameOver.tscn")

# ===== DAY PROGRESSION =====
func advance_day():
	# Check if player played any minigames today
	if minigames_played_today == 0:
		print("Player skipped caring for cat today!")
		skip_day_penalty()
	
	current_day += 1
	minigames_played_today = 0
	
	print("Advanced to day ", current_day)
	emit_signal("day_changed", current_day)
	
	# Check if game should end
	if current_day > 4:
		trigger_ending()

func skip_day_penalty():
	# Penalty for not caring for cat
	skipped_days += 1
	var penalty = 100 * skipped_days  # Escalating penalty
	remove_affinity(penalty)
	print("Skip day penalty: -", penalty, " affinity")

func get_current_day() -> int:
	return current_day

func record_minigame_played():
	minigames_played_today += 1

# ===== SIGN SYSTEM =====
func discover_sign(sign_id: String):
	if sign_id not in signs_discovered:
		signs_discovered.append(sign_id)
		print("Sign discovered: ", sign_id)
		emit_signal("sign_discovered", sign_id)
		
		# Bonus affinity for finding signs
		add_affinity(50)
		
		# Check if all signs found
		check_all_signs_discovered()

func check_all_signs_discovered():
	# Assuming 8 total signs (2 per day)
	var total_signs = 8
	if signs_discovered.size() >= total_signs:
		decoded_all_signs = true
		print("All signs discovered! Secret ending unlocked.")

func has_discovered_all_signs() -> bool:
	return decoded_all_signs

# ===== ENDING SYSTEM =====
func trigger_ending():
	print("Triggering ending sequence...")
	# Show letter at door in living room
	# This will be handled by LivingRoom scene
	pass

func determine_ending() -> String:
	# Returns which ending to show based on game state
	if has_discovered_all_signs() and total_affinity >= 800:
		return "secret"
	elif total_affinity >= 600:
		return "good"
	else:
		return "bad"

func go_to_ending():
	var ending_type = determine_ending()
	print("Going to ending: ", ending_type)
	
	match ending_type:
		"secret":
			get_tree().change_scene_to_file("res://Scenes/Endings/SecretEnding.tscn")
		"good":
			get_tree().change_scene_to_file("res://Scenes/Endings/GoodEnding.tscn")
		"bad":
			get_tree().change_scene_to_file("res://Scenes/Endings/BadEnding.tscn")

# ===== GAME MANAGEMENT =====
func restart_game():
	# Reset all state
	current_day = 1
	total_affinity = 500
	hearts = MAX_HEARTS
	cat_mood = "neutral"
	minigames_played_today = 0
	signs_discovered.clear()
	decoded_all_signs = false
	skipped_days = 0
	
	print("Game state reset")
	
	# Return to main menu or living room
	get_tree().change_scene_to_file("res://Scenes/Main/MainMenu.tscn")

func quit_game():
	get_tree().quit()

# ===== SAVE/LOAD (Optional) =====
# Uncomment if you want save functionality
# func save_game():
# 	var save_data = {
# 		"day": current_day,
# 		"affinity": total_affinity,
# 		"mood": cat_mood,
# 		"signs": signs_discovered
# 	}
# 	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
# 	file.store_var(save_data)
# 	file.close()
# 
# func load_game():
# 	if not FileAccess.file_exists("user://savegame.save"):
# 		return false
# 	
# 	var file = FileAccess.open("user://savegame.save", FileAccess.READ)
# 	var save_data = file.get_var()
# 	file.close()
# 	
# 	current_day = save_data.day
# 	total_affinity = save_data.affinity
# 	cat_mood = save_data.mood
# 	signs_discovered = save_data.signs
# 	update_cat_mood()
# 	
# 	return true
