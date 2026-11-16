extends Panel

signal cambiar_Textura(ruta_imagen)

@onready var boton1 = $cohete1/botoncohete1
@onready var boton2 = $cohete2/botoncohete2

func _ready():
	boton1.pressed.connect(boton1_Pressed)
	boton2.pressed.connect(boton2_Pressed)
	
	# Si ya compró el cohete 2 antes, el botón dice "use" en vez de cobrar de nuevo
	if Global1.ship2_unlocked:
		boton2.text = "use"
		
	actualizar_texto_monedas()

func boton1_Pressed():
	Global1.selected_ship = 1
	# El cohete 1 básico solo tiene propulsor básico (para Marte), pero no escudo térmico
	Global1.has_gravity_thrusters = true
	Global1.has_heat_shield = false
	cambiar_Textura.emit("res://images-removebg-preview.png")
	get_tree().change_scene_to_file("res://vista tierra.tscn")

func boton2_Pressed():
	# Si ya lo había comprado antes, lo usa gratis:
	if Global1.ship2_unlocked:
		usar_cohete_2()
	# Si no lo ha comprado, verifica si ya ganó al menos 10 monedas en las misiones:
	elif Global1.coins >= 10:
		Global1.coins -= 10
		Global1.monedas = Global1.coins
		Global1.ship2_unlocked = true
		boton2.text = "use"
		actualizar_texto_monedas()
		usar_cohete_2()

func usar_cohete_2():
	Global1.selected_ship = 2
	# El cohete 2 mejorado incluye Escudo de Calor y Propulsores de Gravedad (aterriza en Venus y Mercurio)
	Global1.has_heat_shield = true
	Global1.has_gravity_thrusters = true
	cambiar_Textura.emit("res://rocket-removebg-preview.png")
	get_tree().change_scene_to_file("res://vista tierra.tscn")

func actualizar_texto_monedas():
	# Si hay un nodo "monedas" en esta pantalla, también le pone las monedas actuales de Global1
	var raiz = get_tree().current_scene
	if raiz != null:
		for hijo in raiz.find_children("*", "Label", true, false):
			if hijo.get_parent().name == "monedas" or hijo.name == "monedas":
				hijo.text = str(Global1.coins)
