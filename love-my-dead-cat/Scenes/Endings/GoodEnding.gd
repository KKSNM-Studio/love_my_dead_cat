# ===== GoodEnding.gd =====
# Place in: Scenes/Endings/GoodEnding.gd

extends Control

@onready var ending_text = $EndingText
@onready var restart_button = $RestartButton
@onready var quit_button = $QuitButton

func _ready():
	# Play good ending music
	AudioManager.stop_music()
	AudioManager.play_music("res://Assets/Audio/Music/good_ending_theme.ogg")
	
	# Show ending text with typewriter effect
	var text = """
	✨ GOOD ENDING ✨
	
	You cared for your cat with love and patience.
	Despite being gone, it stayed by your side,
	grateful for every moment you shared.
	
	The bond between you transcends death itself.
	Your cat will always watch over you,
	a guardian from beyond.
	
	Thank you for playing.
	"""
	
	show_text_gradually(text)
	
	# Connect buttons
	restart_button.pressed.connect(_on_restart)
	quit_button.pressed.connect(_on_quit)

func show_text_gradually(text: String):
	ending_text.text = ""
	
	for i in range(text.length()):
		ending_text.text += text[i]
		await get_tree().create_timer(0.03).timeout

func _on_restart():
	Global.restart_game()

func _on_quit():
	Global.quit_game()
