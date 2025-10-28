extends Area2D

#@onready var hand_cursor = get_node("/root/HandCursor")

func _ready():
	connect("mouse_entered", Callable(self, "_on_hover"))
	connect("mouse_exited", Callable(self, "_on_exit"))


func _on_mouse_entered() -> void:
	HandCursor.set_hover()


func _on_mouse_exited() -> void:
	HandCursor.clear_hover()
