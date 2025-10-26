# StuffOffalGame.gd
# Stuff Offal minigame - Drag & drop organs + staple + QTE
# Place in: Scenes/Minigames/StuffOffal/StuffOffalGame.gd

extends Control

# ===== NODES =====
@onready var cat_outline = $CatOutline
@onready var organs_container = $OrgansContainer
@onready var drop_zone = $CatOutline/DropZone
@onready var stapler = $Stapler
@onready var qte_container = $QTEContainer
@onready var qte_circle = $QTEContainer/QTECircle
@onready var heart_display = $UI/HeartDisplay
@onready var round_label = $UI/RoundLabel
@onready var instruction_label = $UI/InstructionLabel

# ===== STATE =====
var current_round: int = 0
var max_rounds: int = 3
var total_score: int = 0

enum Phase { DRAG_ORGANS, STAPLE, QTE }
var current_phase: Phase = Phase.DRAG_ORGANS

# Organ management
var organs_to_place: Array = []
var organs_placed: int = 0
var total_organs: int = 4

var stapling_progress: float = 0.0
var stapling_complete: bool = false

# ===== ORGAN CLASS =====
class Organ:
	var id: String
	var texture_path: String
	var node: TextureRect
	var is_placed: bool = false

# ===== INITIALIZATION =====
func _ready():
	Global.reset_hearts()
	setup_ui()
	setup_organs()
	start_drag_phase()
	
	qte_circle.qte_completed.connect(_on_qte_completed)
	update_hearts()

func _process(_delta):
	if current_phase == Phase.STAPLE:
		handle_stapling()

# ===== SETUP =====
func setup_ui():
	qte_container.hide()
	stapler.hide()
	update_round_label()
	instruction_label.text = "Drag organs into the cat!"

func update_round_label():
	round_label.text = "Round %d / %d" % [current_round + 1, max_rounds]

func update_hearts():
	if heart_display:
		heart_display.set_hearts(Global.get_hearts())

func setup_organs():
	# Create organ objects
	organs_to_place.clear()
	organs_placed = 0
	
	var organ_names = ["Heart", "Liver", "Intestine", "Stomach"]
	
	for i in range(total_organs):
		var organ = Organ.new()
		organ.id = organ_names[i]
		organ.texture_path = "res://Assets/Art/Minigames/StuffOffal/organ_%s.png" % organ.id.to_lower()
		organs_to_place.append(organ)
		
		# Create visual node
		create_organ_node(organ, i)

func create_organ_node(organ: Organ, index: int):
	var organ_rect = TextureRect.new()
	organ_rect.name = "Organ_" + organ.id
	organ_rect.texture = load(organ.texture_path) if FileAccess.file_exists(organ.texture_path) else null
	organ_rect.custom_minimum_size = Vector2(80, 80)
	organ_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	organ_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Position organs in a row at bottom
	organ_rect.position = Vector2(200 + index * 120, 800)
	
	organs_container.add_child(organ_rect)
	organ.node = organ_rect
	
	# Enable dragging
	setup_drag_and_drop(organ_rect, organ)

# ===== DRAG AND DROP =====
func setup_drag_and_drop(node: TextureRect, organ: Organ):
	# Make it interactive
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Store reference to organ
	node.set_meta("organ", organ)
	
	# Connect signals
	node.gui_input.connect(_on_organ_input.bind(node, organ))

var dragging_organ: Organ = null
var drag_offset: Vector2 = Vector2.ZERO

func _on_organ_input(event: InputEvent, node: TextureRect, organ: Organ):
	if organ.is_placed:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging
				dragging_organ = organ
				drag_offset = node.get_local_mouse_position()
				node.z_index = 100  # Bring to front
				
				AudioManager.play_sfx("res://Assets/Audio/Minigames/organ_squish.ogg", 0.5)
			else:
				# Stop dragging - check if over drop zone
				if dragging_organ == organ:
					check_organ_placement(node, organ)
					dragging_organ = null
					node.z_index = 0

func _input(event):
	if dragging_organ and event is InputEventMouseMotion:
		# Move organ with mouse
		var organ_node = dragging_organ.node
		organ_node.global_position = get_global_mouse_position() - drag_offset

func check_organ_placement(node: TextureRect, organ: Organ):
	# Check if organ is over drop zone
	var organ_center = node.global_position + node.size / 2
	var drop_zone_rect = drop_zone.get_global_rect()
	
	if drop_zone_rect.has_point(organ_center):
		# Successfully placed!
		place_organ(node, organ)
	else:
		# Return to original position
		var tween = create_tween()
		tween.tween_property(node, "position", Vector2(200 + organs_to_place.find(organ) * 120, 800), 0.3)
		
		AudioManager.play_sfx("res://Assets/Audio/UI/button_click.ogg")

func place_organ(node: TextureRect, organ: Organ):
	organ.is_placed = true
	organs_placed += 1
	
	# Move organ to center of cat
	var target_pos = drop_zone.position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	var tween = create_tween()
	tween.tween_property(node, "position", target_pos, 0.3)
	
	AudioManager.play_sfx("res://Assets/Audio/Minigames/organ_squish.ogg")
	
	# Check if all organs placed
	if organs_placed >= total_organs:
		complete_organ_placement()

func complete_organ_placement():
	instruction_label.text = "All organs placed! Now staple the belly!"
	await get_tree().create_timer(1.0).timeout
	start_staple_phase()

# ===== STAPLE PHASE =====
func start_staple_phase():
	current_phase = Phase.STAPLE
	stapler.show()
	stapling_progress = 0.0
	stapling_complete = false
	instruction_label.text = "Click and hold to staple!"

func handle_stapling():
	if stapling_complete:
		return
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Check if mouse over stapler area
		if is_mouse_over_stapler():
			stapling_progress += 1.0  # Increase progress
			
			# Play staple sound occasionally
			if int(stapling_progress) % 30 == 0:
				AudioManager.play_sfx("res://Assets/Audio/Minigames/stapler_chunk.ogg")
			
			# Visual feedback
			cat_outline.modulate = Color(1, 1 - stapling_progress / 100.0, 1 - stapling_progress / 100.0)
	
	if stapling_progress >= 100:
		complete_stapling()

func is_mouse_over_stapler() -> bool:
	var mouse_pos = get_local_mouse_position()
	var stapler_rect = Rect2(stapler.position, stapler.size)
	return stapler_rect.has_point(mouse_pos)

func complete_stapling():
	stapling_complete = true
	instruction_label.text = "Stitched up! Get ready for QTE..."
	AudioManager.play_sfx("res://Assets/Audio/Cat/cat_pained_mew.ogg")
	
	await get_tree().create_timer(1.0).timeout
	start_qte_phase()

# ===== QTE PHASE =====
func start_qte_phase():
	current_phase = Phase.QTE
	instruction_label.text = "QTE Time!"
	stapler.hide()
	qte_container.show()
	
	await get_tree().create_timer(1.0).timeout
	qte_circle.start_qte()

func _on_qte_completed(result: String, score: int):
	total_score += score
	update_hearts()
	
	if Global.get_hearts() <= 0:
		return
	
	if current_round < max_rounds - 1:
		next_round()
	else:
		show_results()

func next_round():
	current_round += 1
	update_round_label()
	
	# Clear organs for next round
	for child in organs_container.get_children():
		child.queue_free()
	
	await get_tree().create_timer(0.5).timeout
	
	# Reset
	setup_organs()
	start_drag_phase()

func start_drag_phase():
	current_phase = Phase.DRAG_ORGANS
	cat_outline.modulate = Color.WHITE
	instruction_label.text = "Drag organs into the cat!"

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
