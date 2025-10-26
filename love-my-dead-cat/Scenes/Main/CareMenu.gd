# CareMenu.gd
# Pop-up menu showing cat mood and minigame options
# Place in: Scenes/Main/CareMenu.gd

extends Panel

# ===== SIGNALS =====
signal menu_closed

# ===== NODES =====
@onready var cat_display = $Layout/LeftSide/CatDisplay
@onready var cat_mood_label = $Layout/LeftSide/MoodLabel
@onready var cat_sprite = $Layout/LeftSide/CatDisplay/CatSprite

@onready var shower_button = $Layout/RightSide/MinigameButtons/ShowerButton
@onready var feed_button = $Layout/RightSide/MinigameButtons/FeedButton
@onready var stroke_button = $Layout/RightSide/MinigameButtons/StrokeButton
@onready var stuff_button = $Layout/RightSide/MinigameButtons/StuffButton

@onready var note_button = $Layout/RightSide/NoteButton
@onready var close_button = $Layout/RightSide/CloseButton

# ===== INITIALIZATION =====
func _ready():
	# Hide by default
	hide()
	
	# Connect button signals
	shower_button.pressed.connect(_on_shower_pressed)
	feed_button.pressed.connect(_on_feed_pressed)
	stroke_button.pressed.connect(_on_stroke_pressed)
	stuff_button.pressed.connect(_on_stuff_pressed)
	note_button.pressed.connect(_on_note_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Connect hover effects
	setup_button_hover_effects()
	
	# Update display when opened
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		update_display()

# ===== DISPLAY UPDATES =====
func update_display():
	update_cat_display()
	update_mood_label()
	update_button_states()

func update_cat_display():
	# Update cat sprite based on current mood
	var mood = Global.get_cat_mood()
	var day = Global.get_current_day()
	
	# Load appropriate sprite
	var sprite_path = "res://Assets/Art/Cat/cat_%s_day%d.png" % [mood, day]
	if FileAccess.file_exists(sprite_path):
		cat_sprite.texture = load(sprite_path)
	else:
		# Fallback to just mood
		sprite_path = "res://Assets/Art/Cat/cat_%s.png" % mood
		if FileAccess.file_exists(sprite_path):
			cat_sprite.texture = load(sprite_path)
	
	# Animate cat based on mood
	animate_cat_by_mood(mood)

func animate_cat_by_mood(mood: String):
	match mood:
		"happy":
			# Gentle breathing animation
			var tween = create_tween().set_loops()
			tween.tween_property(cat_sprite, "scale", Vector2(1.05, 1.05), 1.0)
			tween.tween_property(cat_sprite, "scale", Vector2(1.0, 1.0), 1.0)
		
		"angry":
			# Stiff, no animation or slight shake
			cat_sprite.scale = Vector2(1.0, 1.0)
		
		"neutral":
			# Slow breathing
			var tween = create_tween().set_loops()
			tween.tween_property(cat_sprite, "scale", Vector2(1.02, 1.02), 1.5)
			tween.tween_property(cat_sprite, "scale", Vector2(1.0, 1.0), 1.5)

func update_mood_label():
	var mood = Global.get_cat_mood()
	
	match mood:
		"happy":
			cat_mood_label.text = "😊 Happy\nPerfect zones are LARGE!"
			cat_mood_label.modulate = Color.GREEN
		"neutral":
			cat_mood_label.text = "😐 Neutral\nPerfect zones are medium."
			cat_mood_label.modulate = Color.YELLOW
		"angry":
			cat_mood_label.text = "😾 Angry\nPerfect zones are SMALL!"
			cat_mood_label.modulate = Color.RED

func update_button_states():
	# Could disable buttons based on game state
	# For now, all buttons always available
	pass

# ===== BUTTON HANDLERS =====
func _on_shower_pressed():
	AudioManager.play_button_click()
	hide()
	get_tree().change_scene_to_file("res://Scenes/Minigames/Shower/ShowerGame.tscn")

func _on_feed_pressed():
	AudioManager.play_button_click()
	hide()
	get_tree().change_scene_to_file("res://Scenes/Minigames/Feed/FeedGame.tscn")

func _on_stroke_pressed():
	AudioManager.play_button_click()
	hide()
	get_tree().change_scene_to_file("res://Scenes/Minigames/Stroke/StrokeGame.tscn")

func _on_stuff_pressed():
	AudioManager.play_button_click()
	hide()
	get_tree().change_scene_to_file("res://Scenes/Minigames/StuffOffal/StuffOffalGame.tscn")

func _on_note_pressed():
	AudioManager.play_button_click()
	show_cat_note()

func _on_close_pressed():
	AudioManager.play_menu_close()
	hide()
	emit_signal("menu_closed")

# ===== NOTE SYSTEM =====
func show_cat_note():
	var note_message = get_cat_note_message()
	
	# Create note popup
	var note_popup = load("res://Scenes/UI/NotePopup.tscn").instantiate()
	add_child(note_popup)
	note_popup.show_message(note_message)

func get_cat_note_message() -> String:
	var day = Global.get_current_day()
	var mood = Global.get_cat_mood()
	var affinity = Global.get_affinity()
	
	# Different messages based on day, mood, and affinity
	if affinity >= 700:
		# High affinity messages
		match day:
			1:
				return "Thank you for taking care of me... I know this is strange."
			2:
				return "I can sense something wrong. Please, keep me close."
			3:
				return "The scratches on the walls... they're warnings. Be careful."
			4:
				return "Tonight is the night. Thank you for everything."
	
	elif affinity >= 400:
		# Medium affinity
		match day:
			1:
				return "I'm... grateful you let me in."
			2:
				return "Something feels off. Can you feel it too?"
			3:
				return "I'm trying to protect you. Please understand."
			4:
				return "It's almost time. Stay alert."
	
	else:
		# Low affinity - cat is upset
		match day:
			1:
				return "Why did you bring me back if you won't care for me?"
			2:
				return "You're not paying attention to the signs..."
			3:
				return "You don't understand. This is your last chance."
			4:
				return "You've made your choice. So have I."
	
	return "..."

# ===== HOVER EFFECTS =====
func setup_button_hover_effects():
	var buttons = [shower_button, feed_button, stroke_button, stuff_button, note_button, close_button]
	
	for button in buttons:
		if button:
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: Button):
	AudioManager.play_button_hover()
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.1)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
