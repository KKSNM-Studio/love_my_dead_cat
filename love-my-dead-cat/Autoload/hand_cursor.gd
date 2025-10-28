extends Sprite2D

# โหลด texture ล่วงหน้า
var default_tex = preload("res://Assets/Art/Cursors/default.PNG")
var held_item_tex = preload("res://Assets/Art/Cursors/hover.PNG")

# ตัวแปรสถานะ
var held_item = null
var SCALE_FACTOR = 0.05

func _ready():
	# ตั้งค่า cursor เริ่มต้น
	Input.set_custom_mouse_cursor(_get_scaled_texture(default_tex))


# -----------------------------
# เปลี่ยน cursor เมื่อ hover
func set_hover():
	#var cursor = tex if tex != null else (held_item if held_item != null else default_tex)
	Input.set_custom_mouse_cursor(_get_scaled_texture(held_item_tex), Input.CURSOR_ARROW)
	#print("wtf")


# -----------------------------
# เคลียร์ hover กลับไป default หรือ held item
func clear_hover():
	var cursor = held_item if held_item != null else default_tex
	Input.set_custom_mouse_cursor(_get_scaled_texture(cursor))


# -----------------------------
# หยิบ item
func pick_item(tex = null):
	held_item = tex if tex != null else held_item_tex
	Input.set_custom_mouse_cursor(_get_scaled_texture(held_item))


# -----------------------------
# วาง item
func drop_item():
	held_item = null
	clear_hover()


# -----------------------------
# ย่อ texture
func _get_scaled_texture(tex):
	if tex == null:
		return default_tex
	
	var img = tex.get_image()
	if img.is_empty():
		return default_tex
	
	var new_size = img.get_size() * SCALE_FACTOR
	img.resize(new_size.x, new_size.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)
