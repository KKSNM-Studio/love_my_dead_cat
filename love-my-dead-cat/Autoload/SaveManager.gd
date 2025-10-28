# ==================================================================
# SaveManager.gd - AUTO-SAVE SYSTEM
# ==================================================================
# Handles saving and loading game state automatically
#
# AUTO-SAVES on:
# - Day change
# - Affinity change
# - Injury change
# - Demon state update
#
# USAGE:
# - SaveManager.auto_save()  # Called automatically by Global
# - SaveManager.load_game()  # Called from MainMenu
# - SaveManager.has_save()   # Check if save exists
# ==================================================================

extends Node

# ===== CONSTANTS =====
var save_file_path := "user://lovemydeadcat_save.json"

# ===== AUTO-SAVE =====

func auto_save():
	"""
	Called automatically by Global when state changes
	Gets current state and saves to file
	"""
	if not has_node("/root/Global"):
		print("[SaveManager] ERROR: Global not found!")
		return
	
	var state = Global.get_save_data()
	save(state)
	print("[SaveManager] Auto-saved at Day ", state.get("day", 0))

# ===== MANUAL SAVE =====

func save(state: Dictionary):
	"""
	Save game state dictionary to JSON file
	
	Args:
		state: Dictionary containing game state (from Global.get_save_data())
	"""
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	
	if file:
		# Pretty print with tabs for readability
		var json_string = JSON.stringify(state, "\t")
		file.store_string(json_string)
		file.close()
		print("[SaveManager] Game saved successfully")
	else:
		var error = FileAccess.get_open_error()
		print("[SaveManager] ERROR: Could not open save file for writing! Error code: ", error)

# ===== LOAD =====

func load_game() -> Dictionary:
	"""
	Load game state from file
	
	Returns:
		Dictionary with game state, or empty {} if no save exists
	"""
	if not FileAccess.file_exists(save_file_path):
		print("[SaveManager] No save file found at: ", save_file_path)
		return {}
	
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		# Parse JSON
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.get_data()
			print("[SaveManager] Game loaded successfully")
			print("[SaveManager] Loaded Day: ", data.get("day", "?"))
			print("[SaveManager] Loaded Affinity: ", data.get("affinity", "?"))
			return data
		else:
			print("[SaveManager] ERROR: Failed to parse save file!")
			print("[SaveManager] Parse error: ", json.get_error_message())
			print("[SaveManager] Error at line: ", json.get_error_line())
			return {}
	else:
		var error = FileAccess.get_open_error()
		print("[SaveManager] ERROR: Could not open save file for reading! Error code: ", error)
		return {}

# ===== CHECK IF SAVE EXISTS =====

func has_save() -> bool:
	"""
	Check if a save file exists
	
	Returns:
		true if save file exists, false otherwise
	"""
	return FileAccess.file_exists(save_file_path)

# ===== CLEAR SAVE =====

func clear_save():
	"""
	Delete the save file
	Used when starting new game or resetting
	"""
	if FileAccess.file_exists(save_file_path):
		var result = DirAccess.remove_absolute(save_file_path)
		if result == OK:
			print("[SaveManager] Save file deleted successfully")
		else:
			print("[SaveManager] ERROR: Could not delete save file! Error code: ", result)
	else:
		print("[SaveManager] No save file to delete")

# ===== GET SAVE INFO =====

func get_save_info() -> Dictionary:
	"""
	Get information about the save file without loading it completely
	Useful for showing "Continue" button info
	
	Returns:
		Dictionary with save info, or empty {} if no save
	"""
	if not has_save():
		return {}
	
	var data = load_game()
	if data.is_empty():
		return {}
	
	return {
		"day": data.get("day", 1),
		"affinity": data.get("affinity", 50),
		"exists": true
	}

# ===== DEBUG FUNCTIONS =====

func print_save_file_path():
	"""Debug: Print where save file is located"""
	print("[SaveManager] Save file path: ", ProjectSettings.globalize_path(save_file_path))

func print_save_data():
	"""Debug: Print contents of save file"""
	if not has_save():
		print("[SaveManager] No save file exists")
		return
	
	var data = load_game()
	if data.is_empty():
		print("[SaveManager] Save file is empty or corrupted")
		return
	
	print("[SaveManager] === SAVE FILE CONTENTS ===")
	for key in data.keys():
		print("[SaveManager] ", key, ": ", data[key])
	print("[SaveManager] ========================")

# ===== READY =====

func _ready():
	"""Initialize SaveManager"""
	print("[SaveManager] Initialized")
	print("[SaveManager] Save location: ", save_file_path)
	
	if has_save():
		var info = get_save_info()
		print("[SaveManager] Found existing save: Day ", info.get("day", "?"))
	else:
		print("[SaveManager] No existing save found")
