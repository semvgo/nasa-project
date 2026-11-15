extends CharacterBody2D

var velocidad_movimiento = 500 
var planeta_cercano = ""

func _ready():
	print("--- INICIANDO SISTEMA DE NAVEGACIÓN ---")
	var lista_planetas = ["Tierra", "Mercurio", "Venus", "Marte"] 
	
	for nombre in lista_planetas:
		if get_parent().get_node_or_null(nombre) != null:
			print("✅ Planeta conectado: " + nombre)
		else:
			print("❌ ERROR: Godot no encuentra el nodo llamado: " + nombre)

func _physics_process(delta):
	var direccion_x = 0
	var direccion_y = 0
	
	# RECUERDA: Cambiar $Cohete a $Sprite2D si tu nodo de imagen se llama así
	if Input.is_key_pressed(KEY_D):
		direccion_x = 1
		$Cohete.flip_h = false 
	if Input.is_key_pressed(KEY_A):
		direccion_x = -1
		$Cohete.flip_h = true
	if Input.is_key_pressed(KEY_W):
		direccion_y = -1
	if Input.is_key_pressed(KEY_S):
		direccion_y = 1
		
	velocity = Vector2(direccion_x, direccion_y).normalized() * velocidad_movimiento
	move_and_slide() 

	var tocando_planeta = false
	var lista_planetas = ["Tierra", "Mercurio", "Venus", "Marte"] 
	
	for nombre in lista_planetas:
		var nodo_planeta = get_parent().get_node_or_null(nombre)
		if nodo_planeta != null:
			# Aumenté la distancia a 1000 píxeles
			if global_position.distance_to(nodo_planeta.global_position) < 1000:
				tocando_planeta = true
				planeta_cercano = nombre
				
	if tocando_planeta:
		print("¡Estoy cerca de: " + planeta_cercano + "! Presiona ENTER")
		
		if Input.is_key_pressed(KEY_ENTER):
			print("¡Tecla ENTER presionada!")
			aterrizar()
			
	if Input.is_action_just_pressed("ui_select"): 
		dejar_objeto()

func aterrizar():
	velocidad_movimiento = 0 
	print("Función de aterrizar activada.")
	
	if has_node("CanvasLayer/Label"):
		$CanvasLayer/Label.text = "¡Aterrizaje exitoso en " + planeta_cercano + "!"
		$CanvasLayer/Label.show()
	else:
		print("Falta crear el CanvasLayer y Label para mostrar el texto en pantalla.")

func dejar_objeto():
	var nuevo_objeto = ColorRect.new()
	nuevo_objeto.color = Color.GREEN
	nuevo_objeto.size = Vector2(30, 30)
	nuevo_objeto.global_position = global_position
	get_parent().add_child(nuevo_objeto)
