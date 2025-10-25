# LivingRoom.gd
# Main gameplay hub - player clicks objects here
# Place in: Scenes/Main/LivingRoom.gd

extends Control

# ===== NODES =====
@onready var background = $Background
@onready var cat = $Cat
@onready var affinity_bar = $UI/AffinityBar
@onready var day_label = $UI/DayLabel
@onready var care_menu = $CareMenu

# Clickable objects
@onready var sofa = $Objects/Sofa
@onready var clock = $Objects/Clock
@onready var tree = $Objects/Tree
@onready var picture = $Objects/Picture
@onready var box = $Objects/Box

# Signs
@onready var signs_container = $Signs

# Letter (Day 4 ending)
@onready var letter = $Letter

# ===== STATE =====
var care_menu_open: bool = false

# ===== INITIALIZATION =====
func _ready():
	# Setup based on current day
	setup_day()
	
	# Update UI
	update_ui()
	
	# Connect signals
	Global.affinity_changed.connect(_on_affinity_changed)
	Global.day_changed.connect(_on_day_changed)
	Global.cat_mood_changed.connect(_on_cat_mood_changed)
	
	# Play day music
	AudioManager.play_day_music(Global.get_current_day())
	
	# Setup clickable objects
	setup_clickable_objects()
	
	# Check if day 4 ended
	check_for_ending()

# ===== SETUP =====
func setup_day():
	var day = Global.get_current_day()
	
	# Change background based on day (darker each day)
	match day:
		1:
			background.texture = load("res://Assets/Art/Backgrounds/living_room_day1.png")
		2:
			background.texture = load("res://Assets/Art/Backgrounds/living_room_day2.png")
		3:
			background.texture = load("res://Assets/Art/Backgrounds/living_room_day3.png")
		4:
			background.texture = load("res://Assets/Art/Backgrounds/living_room_day4.png")
	
	# Show signs for this day
	show_signs_for_day(day)
	
	# Update cat appearance
	update_cat_appearance()

func setup_clickable_objects():
	# Connect click signals for each object
	if cat:
		cat.mouse_entered.connect(_on_cat_hover)
		cat.mouse_exited.connect(_on_cat_unhover)
		cat.gui_input.connect(_on_cat_clicked)
	
	if clock:
		clock.mouse_entered.connect(_on_clock_hover)
		clock.gui_input.connect(_on_clock_clicked)
	
	if sofa:
		sofa.mouse_entered.connect(_on_sofa_hover)
		sofa.gui_input.connect(_on_sofa_clicked)
	
	if tree:
		tree.gui_input.connect(_on_tree_clicked)
	
	if picture:
		picture.gui_input.connect(_on_picture_clicked)

# ===== UI UPDATES =====
func update_ui():
	if day_label:
		day_label.text = "Day " + str(Global.get_current_day())
	
	if affinity_bar:
		affinity_bar.value = Global.get_affinity_percentage()

func update_cat_appearance():
	# Change cat sprite based on mood and day
	var mood = Global.get_cat_mood()
	var day = Global.get_current_day()
	
	# Load appropriate cat sprite
	var cat_texture_path = "res://Assets/Art/Cat/cat_%s_day%d.png" % [mood, day]
	
	if FileAccess.file_exists(cat_texture_path):
		cat.texture = load(cat_texture_path)
	else:
		# Fallback to mood only
		cat.texture = load("res://Assets/Art/Cat/cat_%s.png" % mood)

# ===== CLICKABLE OBJECT HANDLERS =====

# Cat
func _on_cat_hover():
	# Add glow or outline
	cat.modulate = Color(1.2, 1.2, 1.2)

func _on_cat_unhover():
	cat.modulate = Color.WHITE

func _on_cat_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			open_care_menu()
			AudioManager.play_cat_meow()

# Clock
func _on_clock_hover():
	clock.modulate = Color(1.2, 1.2, 1.2)

func _on_clock_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			show_end_day_confirmation()

# Sofa
func _on_sofa_hover():
	sofa.modulate = Color(1.1, 1.1, 1.1)

func _on_sofa_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			show_note("A comfortable old sofa. You've had many good times here with your cat.")

# Tree
func _on_tree_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		show_note("A small potted tree. It looks less healthy than before...")

# Picture
func _on_picture_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		show_note("A photo of you and your cat from happier times.")

# ===== CARE MENU =====
func open_care_menu():
	if care_menu:
		care_menu.show()
		care_menu_open = true
		AudioManager.play_menu_open()

func close_care_menu():
	if care_menu:
		care_menu.hide()
		care_menu_open = false
		AudioManager.play_menu_close()
		
		# Update cat appearance after care
		update_cat_appearance()

# ===== DAY MANAGEMENT =====
func show_end_day_confirmation():
	# Create confirmation popup
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "End this day?\n\nMake sure you've cared for your cat!"
	confirm.ok_button_text = "End Day"
	confirm.cancel_button_text = "Keep Playing"
	
	add_child(confirm)
	confirm.popup_centered()
	
	confirm.confirmed.connect(end_day)
	confirm.canceled.connect(func(): confirm.queue_free())

func end_day():
	# Transition to next day
	Global.advance_day()
	
	# Play transition
	show_day_transition()

func show_day_transition():
	# Load transition scene
	get_tree().change_scene_to_file("res://Scenes/Transitions/DayTransition.tscn")

# ===== SIGNS SYSTEM =====
func show_signs_for_day(day: int):
	# Show 2 signs per day
	var signs_for_day = get_signs_for_day(day)
	
	for sign_id in signs_for_day:
		var sign_node = signs_container.get_node_or_null(sign_id)
		if sign_node:
			sign_node.show()
			sign_node.gui_input.connect(_on_sign_clicked.bind(sign_id))

func get_signs_for_day(day: int) -> Array:
	match day:
		1:
			return ["Sign1", "Sign2"]
		2:
			return ["Sign3", "Sign4"]
		3:
			return ["Sign5", "Sign6"]
		4:
			return ["Sign7", "Sign8"]
		_:
			return []

func _on_sign_clicked(event: InputEvent, sign_id: String):
	if event is InputEventMouseButton and event.pressed:
		discover_sign(sign_id)

func discover_sign(sign_id: String):
	Global.discover_sign(sign_id)
	
	# Show sign message
	var sign_message = get_sign_message(sign_id)
	show_note(sign_message)
	
	# Hide the sign (already found)
	var sign_node = signs_container.get_node_or_null(sign_id)
	if sign_node:
		sign_node.hide()

func get_sign_message(sign_id: String) -> String:
	# Could load from JSON file
	match sign_id:
		"Sign1":
			return "Scratches on the wall spell: 'HELP ME'"
		"Sign2":
			return "Wet pawprints lead to the door..."
		"Sign3":
			return "A knocked over vase points toward the window."
		"Sign4":
			return "Blood drops form a trail..."
		_:
			return "You found a strange sign."

# ===== NOTE SYSTEM =====
func show_note(message: String):
	# Create or show note popup
	var note_popup = load("res://Scenes/UI/NotePopup.tscn").instantiate()
	add_child(note_popup)
	note_popup.show_message(message)
	
	AudioManager.play_sfx("res://Assets/Audio/UI/note_rustle.ogg")

# ===== ENDING =====
func check_for_ending():
	if Global.get_current_day() > 4:
		# Show letter at door
		if letter:
			letter.show()
			letter.gui_input.connect(_on_letter_clicked)

func _on_letter_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		# Go to ending
		Global.go_to_ending()

# ===== SIGNAL HANDLERS =====
func _on_affinity_changed(new_affinity: int):
	update_ui()

func _on_day_changed(new_day: int):
	setup_day()
	update_ui()

func _on_cat_mood_changed(new_mood: String):
	update_cat_appearance()
