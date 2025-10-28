extends Control

# ===== SIGNALS =====
signal qte_completed(result: String, score: int)  # "perfect", "safe", "danger"

# ===== NODES =====
@onready var circle_sprite = $CircleSprite
@onready var indicator = $Indicator
@onready var perfect_zone: Polygon2D = $PerfectZone
@onready var safe_zone: Polygon2D = $SafeZone
@onready var danger_zone: Polygon2D = $DangerZone
@onready var safe_zone_pivot = $safeMark
@onready var perfect_zone_pivot = $perfectMark

# ===== SETTINGS =====
var rotation_speed: float = 180.0
var is_active: bool = false
var has_clicked: bool = false

# Zone settings
var perfect_zone_size: float = 10.0
var safe_zone_size: float = 70.0
var radius: float = 150.0
var target_angle: float = 0.0

# Score
const PERFECT_SCORE = 3
const SAFE_SCORE = 1
const DANGER_SCORE = 0

# ===== INITIALIZATION =====
func _ready():
	hide()
	randomize_target()
	perfect_zone_size = Global.get_perfect_zone_size()
	
	create_arc(perfect_zone, radius, perfect_zone_size, Color(0, 1, 0, 0))
	create_arc(safe_zone, radius, safe_zone_size, Color(1, 0.85, 0, 0))
	create_arc(danger_zone, radius, 360, Color(1, 0, 0, 0))

# ===== PROCESS LOOP =====
func _process(delta):
	if is_active and not has_clicked:
		indicator.rotation_degrees += rotation_speed * delta
		if indicator.rotation_degrees >= 360:
			fail();

# ===== START QTE =====
func start_qte():
	indicator.rotation_degrees = 0;
	is_active = true
	has_clicked = false
	show()

	indicator.rotation_degrees = 0
	randomize_target()
	update_zone_visuals()

	AudioManager.play_qte_countdown()

# ===== HIT CHECK =====
func _input(event):
	if is_active and not has_clicked:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			check_hit()
			has_clicked = true

func check_hit():
	is_active = false
	var current_angle = indicator.rotation_degrees
	var angle_diff = abs(current_angle - target_angle)

	if angle_diff > 180:
		angle_diff = 360 - angle_diff

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
		Global.lose_heart()

	await get_tree().create_timer(0.5).timeout
	emit_signal("qte_completed", result, score)
	hide()

func fail():
	flash_zone(danger_zone, Color.RED)
	AudioManager.play_qte_danger()
	Global.lose_heart()
	emit_signal("qte_completed", "danger", DANGER_SCORE)
	is_active = false
	has_clicked = true
	hide();
# ===== ZONE LOGIC =====

func randomize_target():
	target_angle = randf_range(80, 320)
	#target_angle = 360

func update_zone_visuals():
	perfect_zone.rotation_degrees = target_angle
	safe_zone.rotation_degrees = target_angle
	safe_zone_pivot.rotation_degrees = target_angle
	perfect_zone_pivot.rotation_degrees = target_angle
	danger_zone.rotation_degrees = 0

func create_arc(zone: Polygon2D, r: float, angle_deg: float, color: Color):
	var points = []
	points.append(Vector2.ZERO)

	var half_angle = deg_to_rad(angle_deg / 2)
	var step = deg_to_rad(3)

	var a = -half_angle
	while a <= half_angle:
		points.append(Vector2(cos(a) * r, sin(a) * r))
		a += step

	zone.polygon = points
	zone.color = color
	zone.antialiased = true

func flash_zone(zone_node: Polygon2D, color: Color):
	var original = zone_node.modulate
	zone_node.modulate = color
	var tween = create_tween()
	tween.tween_property(zone_node, "modulate", original, 0.3)

# ===== DIFFICULTY =====
func set_rotation_speed(speed: float):
	rotation_speed = clamp(speed, 30, 500)

func increase_difficulty():
	rotation_speed = min(rotation_speed + 20, 500)
	perfect_zone_size = max(perfect_zone_size - 5, 15)
	create_arc(perfect_zone, radius, perfect_zone_size, perfect_zone.color)

func reset_difficulty():
	rotation_speed = 180
	perfect_zone_size = Global.get_perfect_zone_size()
	create_arc(perfect_zone, radius, perfect_zone_size, perfect_zone.color)

# ===== STOP =====
func stop_qte():
	is_active = false
	has_clicked = false
	hide()
