# AudioManager.gd
# Autoload singleton - Manages all audio in the game
# Place in: Autoload/AudioManager.gd
# Setup: Project > Project Settings > Autoload > Add this script as "AudioManager"

extends Node

# ===== AUDIO PLAYERS =====
# Create these as children in the scene tree
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# ===== AUDIO SETTINGS =====
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8

# ===== INITIALIZATION =====
func _ready():
	# Create audio players
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = "Ambient"
	add_child(ambient_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	print("AudioManager initialized")

# ===== MUSIC CONTROL =====
func play_music(music_path: String, fade_in: bool = true):
	var stream = load(music_path)
	if stream:
		if fade_in:
			fade_out_music()
			await get_tree().create_timer(0.5).timeout
		
		music_player.stream = stream
		music_player.volume_db = linear_to_db(music_volume)
		music_player.play()
		
		if fade_in:
			fade_in_music()
	else:
		print("Failed to load music: ", music_path)

func stop_music(fade_out: bool = true):
	if fade_out:
		fade_out_music()
		await get_tree().create_timer(0.5).timeout
	music_player.stop()

func fade_in_music(duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), duration)

func fade_out_music(duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80, duration)

# ===== AMBIENT SOUNDS =====
func play_ambient(ambient_path: String):
	var stream = load(ambient_path)
	if stream:
		ambient_player.stream = stream
		ambient_player.volume_db = linear_to_db(sfx_volume * 0.5)  # Quieter
		ambient_player.play()
	else:
		print("Failed to load ambient: ", ambient_path)

func stop_ambient():
	ambient_player.stop()

# ===== SOUND EFFECTS =====
func play_sfx(sfx_path: String, volume_scale: float = 1.0):
	var stream = load(sfx_path)
	if stream:
		# Create temporary player for this sound
		var temp_player = AudioStreamPlayer.new()
		temp_player.stream = stream
		temp_player.volume_db = linear_to_db(sfx_volume * volume_scale)
		temp_player.bus = "SFX"
		add_child(temp_player)
		temp_player.play()
		
		# Delete player when sound finishes
		temp_player.finished.connect(func(): temp_player.queue_free())
	else:
		print("Failed to load SFX: ", sfx_path)

# ===== COMMON SOUND FUNCTIONS =====

# UI Sounds
func play_button_hover():
	play_sfx("res://Assets/Audio/UI/button_hover.ogg", 0.6)

func play_button_click():
	play_sfx("res://Assets/Audio/UI/button_click.ogg")

func play_menu_open():
	play_sfx("res://Assets/Audio/UI/menu_open.ogg")

func play_menu_close():
	play_sfx("res://Assets/Audio/UI/menu_close.ogg")

# QTE Sounds
func play_qte_perfect():
	play_sfx("res://Assets/Audio/QTE/qte_perfect.ogg")

func play_qte_safe():
	play_sfx("res://Assets/Audio/QTE/qte_safe.ogg")

func play_qte_danger():
	play_sfx("res://Assets/Audio/QTE/qte_danger.ogg")

func play_qte_countdown():
	play_sfx("res://Assets/Audio/QTE/qte_countdown.ogg", 0.5)

# Cat Sounds
func play_cat_meow():
	play_sfx("res://Assets/Audio/Cat/cat_meow.ogg")

func play_cat_purr():
	play_sfx("res://Assets/Audio/Cat/cat_purr_loop.ogg")

func play_cat_hiss():
	play_sfx("res://Assets/Audio/Cat/cat_hiss.ogg")

# Affinity Sounds
func play_affinity_gain():
	play_sfx("res://Assets/Audio/UI/affinity_gain.ogg")

func play_affinity_loss():
	play_sfx("res://Assets/Audio/UI/affinity_loss.ogg")

func play_heart_break():
	play_sfx("res://Assets/Audio/UI/heart_break.ogg")

# ===== MUSIC BY DAY =====
func play_day_music(day: int):
	match day:
		1:
			play_music("res://Assets/Audio/Music/day1_theme.ogg")
		2:
			play_music("res://Assets/Audio/Music/day2_theme.ogg")
		3:
			play_music("res://Assets/Audio/Music/day3_theme.ogg")
		_:
			play_music("res://Assets/Audio/Music/day1_theme.ogg")

# ===== VOLUME CONTROL =====
func set_master_volume(value: float):
	master_volume = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

func set_music_volume(value: float):
	music_volume = clamp(value, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume)

func set_sfx_volume(value: float):
	sfx_volume = clamp(value, 0.0, 1.0)

# ===== HELPER =====
func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80
	return 20 * log(linear) / log(10)
