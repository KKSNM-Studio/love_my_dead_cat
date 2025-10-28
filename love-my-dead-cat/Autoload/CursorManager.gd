# ==================================================================
# CursorManager.gd - DYNAMIC CURSOR SYSTEM
# ==================================================================
# Manages cursor states for different interactions
#
# STATES:
# - Default: Normal cursor
# - Hover: When mouse over clickable objects
# - Holding: When dragging items (Shower minigame)
#
# USAGE:
# In objects:
#   func _on_mouse_entered():
#       CursorManager.on_object_hover()
#   
#   func _on_mouse_exited():
#       CursorManager.on_object_unhover()
#
# In drag minigames:
#   func pick_up_item():
#       CursorManager.hold_item(item_texture)
#   
#   func drop_item():
#       CursorManager.release_item()
# ==================================================================

extends Node

# ===== CURSOR TEXTURES =====
var default_cursor: Texture2D
var hover_cursor: Texture2D
var held_item_cursor: Texture2D

# ===== STATE =====
var is_holding_item: bool = false

# ===== INITIALIZATION =====

func _ready():
	print("[CursorManager] Initialized")
	# Set default system cursor (can customize later)
	reset_to_default()

# ===== DEFAULT CURSOR =====

func set_default(texture: Texture2D = null):
	"""
	Set the default cursor texture
	
	Args:
		texture: Custom cursor image (null for system default)
	"""
	default_cursor = texture
	if texture and not is_holding_item:
		Input.set_custom_mouse_cursor(texture)
		print("[CursorManager] Default cursor set")

func reset_to_default():
	"""Return to default cursor"""
	is_holding_item = false
	held_item_cursor = null
	
	if default_cursor:
		Input.set_custom_mouse_cursor(default_cursor)
	else:
		Input.set_custom_mouse_cursor(null)  # System default
	
	print("[CursorManager] Reset to default")

# ===== HOVER CURSOR =====

func set_hover(texture: Texture2D = null):
	"""
	Show hover cursor (called by interactive objects)
	Only works if not holding an item
	
	Args:
		texture: Hover cursor image (null for default hover)
	"""
	if is_holding_item:
		return  # Don't change cursor while holding item
	
	hover_cursor = texture
	if texture:
		Input.set_custom_mouse_cursor(texture)

func clear_hover():
	"""
	Clear hover cursor (called when mouse exits object)
	Only works if not holding an item
	"""
	if is_holding_item:
		return  # Don't change cursor while holding item
	
	reset_to_default()

# ===== HELD ITEM CURSOR =====

func hold_item(texture: Texture2D):
	"""
	Hold an item (e.g., soap, towel, shower head)
	Used in drag-and-drop minigames
	
	Args:
		texture: Image of the item being held
	"""
	if not texture:
		print("[CursorManager] WARNING: Tried to hold null texture")
		return
	
	is_holding_item = true
	held_item_cursor = texture
	Input.set_custom_mouse_cursor(texture)
	print("[CursorManager] Holding item: ", texture.resource_path if texture.resource_path else "unnamed")

func is_holding() -> bool:
	"""
	Check if currently holding an item
	
	Returns:
		true if holding an item, false otherwise
	"""
	return is_holding_item

func get_held_item() -> Texture2D:
	"""
	Get the currently held item texture
	
	Returns:
		Texture2D of held item, or null if not holding anything
	"""
	return held_item_cursor

func release_item():
	"""Release the held item and return to default cursor"""
	if not is_holding_item:
		print("[CursorManager] WARNING: Tried to release but not holding anything")
		return
	
	print("[CursorManager] Released item: ", held_item_cursor.resource_path if held_item_cursor and held_item_cursor.resource_path else "unnamed")
	
	is_holding_item = false
	held_item_cursor = null
	reset_to_default()

# ===== CONVENIENCE FUNCTIONS =====

func on_object_hover(object_texture: Texture2D = null):
	"""
	Convenience function for objects to call on mouse_entered
	
	Usage in object script:
		func _on_mouse_entered():
			CursorManager.on_object_hover(my_hover_texture)
	
	Args:
		object_texture: Optional custom hover cursor for this object
	"""
	set_hover(object_texture)

func on_object_unhover():
	"""
	Convenience function for objects to call on mouse_exited
	
	Usage in object script:
		func _on_mouse_exited():
			CursorManager.on_object_unhover()
	"""
	clear_hover()

# ===== DEBUG FUNCTIONS =====

func print_state():
	"""Debug: Print current cursor state"""
	print("[CursorManager] === CURSOR STATE ===")
	print("[CursorManager] Is Holding: ", is_holding_item)
	print("[CursorManager] Default Cursor: ", "Set" if default_cursor else "None")
	print("[CursorManager] Hover Cursor: ", "Set" if hover_cursor else "None")
	print("[CursorManager] Held Item: ", "Set" if held_item_cursor else "None")
	print("[CursorManager] ====================")

# ===== CUSTOM CURSOR PRESETS (Optional) =====

func load_custom_cursors():
	"""
	Optional: Load custom cursor images
	Call this from a scene if you have custom cursor assets
	"""
	# Try to load custom default cursor
	if FileAccess.file_exists("res://Assets/UI/Cursors/cursor_default.png"):
		var texture = load("res://Assets/UI/Cursors/cursor_default.png")
		set_default(texture)
	
	# Try to load custom hover cursor
	if FileAccess.file_exists("res://Assets/UI/Cursors/cursor_hover.png"):
		hover_cursor = load("res://Assets/UI/Cursors/cursor_hover.png")
	
	print("[CursorManager] Custom cursors loaded (if available)")

func apply_cursor_style(style: String):
	"""
	Optional: Apply preset cursor styles
	
	Args:
		style: "normal", "pointer", "grab", "grabbing"
	"""
	match style:
		"normal":
			reset_to_default()
		"pointer":
			# Show hand/pointer cursor
			pass
		"grab":
			# Show open hand
			pass
		"grabbing":
			# Show closed hand
			pass
