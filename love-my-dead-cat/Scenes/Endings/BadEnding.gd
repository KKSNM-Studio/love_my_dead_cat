# ===== BadEnding.gd =====
# Place in: Scenes/Endings/BadEnding.gd

extends Control

@onready var ending_text = $EndingText
@onready var restart_button = $RestartButton
@onready var quit_button = $QuitButton

func _ready():
	# Play bad ending music
	AudioManager.stop_music()
	AudioManager.play_music("res://Assets/Audio/Music/bad_ending_theme.ogg")
	
	# Show ending text
	var text = """
	💀 BAD ENDING 💀
	
	You neglected the cat that returned to you.
	You ignored its warnings, its desperate signs.
	
	The thing it tried to protect you from...
	found you.
	
	And the cat, hurt and angry,
	chose not to save you this time.
	
	Perhaps in another life,
	you'll pay more attention to those who care.
	
	THE END
	"""
	
	show_text_gradually(text)
	
	restart_button.pressed.connect(_on_restart)
	quit_button.pressed.connect(_on_quit)

func show_text_gradually(text: String):
	ending_text.text = ""
	
	for i in range(text.length()):
		ending_text.text += text[i]
		await get_tree().create_timer(0.04).timeout
	
	# Add horror effect at end
	screen_distortion()

func screen_distortion():
	for i in range(5):
		modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.1).timeout
		modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout

func _on_restart():
	Global.restart_game()

func _on_quit():
	Global.quit_game()
