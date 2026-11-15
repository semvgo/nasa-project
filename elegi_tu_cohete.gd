extends Panel

signal cambiar_Textura(ruta_imagen)

@onready
var boton1 = $cohete1/botoncohete1
@onready
var boton2 = $cohete2/botoncohete2
var money = 50

func _ready():
	boton1.pressed.connect(boton1_Pressed)
	boton2.pressed.connect(boton2_Pressed)

func boton1_Pressed():
	Global1.selected_ship = 1
	cambiar_Textura.emit("res://images-removebg-preview.png")
	# Salta a la escena del despegue en las nubes / tierra
	get_tree().change_scene_to_file("res://espacio inicio.tscn")

func boton2_Pressed():
	if money >= 50:
		Global1.selected_ship = 2
		cambiar_Textura.emit("res://rocket-removebg-preview.png")
		money -= 10
		# Salta a la escena del despegue en las nubes / tierra
		get_tree().change_scene_to_file("res://node_2d.tscn")
