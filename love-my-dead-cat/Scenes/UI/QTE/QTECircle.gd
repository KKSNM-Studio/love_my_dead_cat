# QTECircle.gd
# Reusable QTE (Quick Time Event) system
# Place in: Scenes/UI/QTE/QTECircle.gd
# Used by all minigames

extends Control

# ===== SIGNALS =====
signal qte_completed(result: String, score: int)  # "perfect", "safe", "danger"

# ===== NODES (Create these in scene) =====
@onready var circle_sprite = $CircleSprite  # The outer circle
@onready var indicator = $Indicator  # Rotating pointer
@onready var perfect_zone = $PerfectZone  # Green zone visual
@onready var safe_zone = $SafeZone  # Yellow zone visual
@onready var danger_zone = $DangerZone  # Red zone visual

# ===== QTE SETTINGS =====
var rotation_speed: float = 180.0  # Degrees per second
var is_active: bool = false
var has_clicked: bool = false

# Zone angles (in degrees)
var perfect_zone_size: float = 60.0
var safe_zone_size: float = 120.0
# Danger zone is everything else

# Zone start angle (where perfect zone begins)
var target_angle: float = 0.0

# ===== SCORE VALUES =====
const PERFECT_SCORE = 3
const SAFE_SCORE = 1
const DANGER_SCORE = 0

# ===== INITIALIZATION =====
func _ready():
	hide()  # Start hidden
	
	# Set random target angle each time
	randomize_target()
	
	# Update zone sizes from Global (based on cat mood)
	perfect_zone_size = Global.get_perfect_zone_size()

func _process(delta):
	if is_active and not has_clicked:
		# Rotate indicator
		indicator.rotation_degrees += rotation_speed * delta
		
		# Wrap around at 360
		if indicator.rotation_degrees >= 360:
			indicator.rotation_degrees -= 360

# ===== QTE CONTROL =====
func start_qte():
	is_active = true
	has_clicked = false
	show()
	
	# Reset indicator position
	indicator.rotation_degrees = 0
	
	# Randomize target zone position
	randomize_target()
	
	# Update zone visuals
	update_zone_visuals()
	
	# Play countdown sound
	AudioManager.play_qte_countdown()

func _input(event):
	if is_active and not has_clicked:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				check_hit()
				has_clicked = true

func check_hit():
	is_active = false
	
	# Get current indicator angle
	var current_angle = indicator.rotation_degrees
	
	# Calculate difference from target
	var angle_diff = abs(current_angle - target_angle)
	
	# Handle wrap-around (e.g., 350° and 10° should be close)
	if angle_diff > 180:
		angle_diff = 360 - angle_diff
	
	# Determine hit quality
	var result: String
	var score: int
	
	if angle_diff <= perfect_zone_size / 2:
		result = "perfect"
		score = PERFECT_SCORE
		flash_zone(perfect_zone, Color.GREEN)
		AudioManager.play_qte_perfect()
	elif angle_diff <= safe_zone_size / 2:
		result = "safe"
		score = SAFE_SCORE
		flash_zone(safe_zone, Color.YELLOW)
		AudioManager.play_qte_safe()
	else:
		result = "danger"
		score = DANGER_SCORE
		flash_zone(danger_zone, Color.RED)
		AudioManager.play_qte_danger()
		
		# Lose a heart on danger hit
		Global.lose_heart()
	
	# Show result briefly
	await get_tree().create_timer(0.5).timeout
	
	# Emit completion signal
	emit_signal("qte_completed", result, score)
	
	hide()

# ===== VISUAL UPDATES =====
func randomize_target():
	target_angle = randf_range(0, 360)

func update_zone_visuals():
	# Update visual representations of zones
	# This depends on how you design the zones visually
	
	# Position perfect zone at target angle
	if perfect_zone:
		perfect_zone.rotation_degrees = target_angle
		# Scale to size (implement in scene as Polygon2D or similar)
	
	# Position safe zone
	if safe_zone:
		safe_zone.rotation_degrees = target_angle
	
	# Danger zone is the rest (full circle minus safe)

func flash_zone(zone_node: Node2D, color: Color):
	if zone_node:
		var original_modulate = zone_node.modulate
		zone_node.modulate = color
		
		var tween = create_tween()
		tween.tween_property(zone_node, "modulate", original_modulate, 0.3)

# ===== DIFFICULTY ADJUSTMENT =====
func set_rotation_speed(speed: float):
	rotation_speed = speed

func increase_difficulty():
	# Make it faster or zones smaller
	rotation_speed += 30.0
	rotation_speed = min(rotation_speed, 360.0)  # Cap max speed

func reset_difficulty():
	rotation_speed = 180.0
	perfect_zone_size = Global.get_perfect_zone_size()

# ===== CLEANUP =====
func stop_qte():
	is_active = false
	has_clicked = false
	hide()
