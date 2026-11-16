extends Sprite2D

var velocity_y = -2
var despegando = false

func _ready():
	if Global1.selected_ship == 2:
		texture = load("res://rocket-removebg-preview (2).png")

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and despegando == false:
		despegando = true
		
		while true:
			await get_tree().create_timer(0.005).timeout
			position.y += velocity_y
			if position.y <= -300.0:
				get_tree().change_scene_to_file("res://espacio inicio.tscn")

				
				break
