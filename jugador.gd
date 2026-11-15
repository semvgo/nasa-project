extends CharacterBody2D

var velocidad_movimiento = 500.0
var aterrizado = false
var ultimo_normal = Vector2.UP
var cartel_ui: Label = null

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	# 1. CAMBIO DE NAVE SEGURO
	if get_node_or_null("/root/Global1") != null:
		var ruta_1 = "res://cohete1.png"
		var ruta_2 = "res://cohete2.png"
		if Global1.nave_elegida == 1 and ResourceLoader.exists(ruta_1):
			$Cohete.texture = load(ruta_1)
		elif Global1.nave_elegida == 2 and ResourceLoader.exists(ruta_2):
			$Cohete.texture = load(ruta_2)
			
	# 2. CREAR EL CARTEL EN PANTALLA AUTOMÁTICAMENTE
	var capa = CanvasLayer.new()
	capa.layer = 100
	add_child(capa)
	
	cartel_ui = Label.new()
	cartel_ui.position = Vector2(40, 40)
	cartel_ui.add_theme_font_size_override("font_size", 35)
	cartel_ui.add_theme_color_override("font_color", Color.YELLOW)
	cartel_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	cartel_ui.add_theme_constant_override("outline_size", 8)
	cartel_ui.hide()
	capa.add_child(cartel_ui)

func _physics_process(delta):
	# 1. SI ESTÁ ATERRIZADO: Queda fijo hasta presionar ENTER (o R) para despegar
	if aterrizado:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_R):
			aterrizado = false
			# Empuja 20 píxeles hacia afuera del planeta para no volver a chocar al instante
			global_position += ultimo_normal * 20.0
			cartel_ui.hide()
		return

	# 2. MOVIMIENTO CON WASD
	var direccion = Vector2.ZERO
	if Input.is_key_pressed(KEY_D):
		direccion.x += 1
		$Cohete.flip_h = false
	if Input.is_key_pressed(KEY_A):
		direccion.x -= 1
		$Cohete.flip_h = true
	if Input.is_key_pressed(KEY_W):
		direccion.y -= 1
	if Input.is_key_pressed(KEY_S):
		direccion.y += 1
		
	velocity = direccion.normalized() * velocidad_movimiento

	# 3. AL TOCAR LA HITBOX: Aterrizaje instantáneo sin resbalar
	var colision = move_and_collide(velocity * delta)
	
	if colision:
		var objeto_chocado = colision.get_collider()
		ultimo_normal = colision.get_normal()
		
		# Congela la nave inmediatamente al contacto
		aterrizado = true
		velocity = Vector2.ZERO
		
		var nombre_planeta = "el planeta"
		if objeto_chocado != null and objeto_chocado.get_parent() != null:
			nombre_planeta = str(objeto_chocado.get_parent().name)
			
		cartel_ui.text = "¡Aterrizaje exitoso en " + nombre_planeta + "!\nPresiona ENTER para despegar"
		cartel_ui.show()

	# 4. DEJAR OBJETO CON ESPACIO
	if Input.is_action_just_pressed("ui_select"):
		var nuevo_objeto = ColorRect.new()
		nuevo_objeto.color = Color.GREEN
		nuevo_objeto.size = Vector2(30, 30)
		nuevo_objeto.global_position = global_position
		get_parent().add_child(nuevo_objeto)
