extends CharacterBody2D

var velocidad_movimiento = 500.0
var aterrizado = false
var muerto = false
var ultimo_normal = Vector2.UP

var cartel_ui: Label = null # Cartel central para aterrizajes y muerte
var hud_ui: Label = null    # Marcador de Gasolina, Oxígeno y Materiales

# Tasas de consumo por segundo (puedes subirlas o bajarlas para ajustar la dificultad)
var gasto_gasolina = 15.0 
var gasto_oxigeno = 5.0   

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	# 1. LEER NAVE ELEGIDA DEL GLOBAL
	if get_node_or_null("/root/Global1") != null:
		var ruta_1 = "res://cohete1.png"
		var ruta_2 = "res://cohete2.png"
		if Global1.nave_elegida == 1 and ResourceLoader.exists(ruta_1):
			$Cohete.texture = load(ruta_1)
		elif Global1.nave_elegida == 2 and ResourceLoader.exists(ruta_2):
			$Cohete.texture = load(ruta_2)
			
	# 2. CREAR INTERFAZ EN PANTALLA (HUD + Cartel de avisos)
	var capa = CanvasLayer.new()
	capa.layer = 100
	add_child(capa)
	
	# Marcador de recursos (Arriba a la izquierda)
	hud_ui = Label.new()
	hud_ui.position = Vector2(20, 20)
	hud_ui.add_theme_font_size_override("font_size", 24)
	hud_ui.add_theme_color_override("font_color", Color.WHITE)
	hud_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	hud_ui.add_theme_constant_override("outline_size", 6)
	capa.add_child(hud_ui)
	
	# Cartel de Aterrizaje / Game Over (Más abajo en grande)
	cartel_ui = Label.new()
	cartel_ui.position = Vector2(40, 150)
	cartel_ui.add_theme_font_size_override("font_size", 32)
	cartel_ui.add_theme_color_override("font_color", Color.YELLOW)
	cartel_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	cartel_ui.add_theme_constant_override("outline_size", 8)
	cartel_ui.hide()
	capa.add_child(cartel_ui)

func _physics_process(delta):
	# Si no existe Global1 por error, evitamos que crashee
	if get_node_or_null("/root/Global1") == null:
		return

	# 1. SI EL JUGADOR MURIÓ: Congelar todo y permitir reiniciar con 'R'
	if muerto:
		velocity = Vector2.ZERO
		if Input.is_key_pressed(KEY_R):
			# Recarga recursos básicos y reinicia la escena
			Global1.gasolina = 100.0
			Global1.oxigeno = 100.0
			Global1.materiales = 5
			get_tree().reload_current_scene()
		return

	# Actualizar los números en pantalla todo el tiempo
	actualizar_hud()

	# 2. SI ESTÁ ATERRIZADO EN UN PLANETA (A salvo: no gasta oxígeno ni gasolina)
	if aterrizado:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_R):
			aterrizado = false
			global_position += ultimo_normal * 20.0
			cartel_ui.hide()
		return

	# 3. CONSUMO DE OXÍGENO (Baja constantemente en el espacio)
	Global1.oxigeno -= gasto_oxigeno * delta
	if Global1.oxigeno <= 0:
		Global1.oxigeno = 0
		actualizar_hud()
		morir("¡TE QUEDASTE SIN OXÍGENO EN EL ESPACIO!")
		return

	# 4. MOVIMIENTO CON WASD Y CONSUMO DE GASOLINA
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
		
	# Si el jugador está presionando teclas para moverse, gasta gasolina
	if direccion != Vector2.ZERO:
		if Global1.gasolina > 0:
			Global1.gasolina -= gasto_gasolina * delta
			velocity = direccion.normalized() * velocidad_movimiento
			if Global1.gasolina <= 0:
				Global1.gasolina = 0
				actualizar_hud()
				morir("¡SIN GASOLINA! Quedaste a la deriva en el espacio.")
				return
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	# 5. COLISIÓN Y ATERRIZAJE AUTOMÁTICO
	var colision = move_and_collide(velocity * delta)
	
	if colision:
		var objeto_chocado = colision.get_collider()
		ultimo_normal = colision.get_normal()
		
		aterrizado = true
		velocity = Vector2.ZERO
		
		var nombre_planeta = "el planeta"
		if objeto_chocado != null and objeto_chocado.get_parent() != null:
			nombre_planeta = str(objeto_chocado.get_parent().name)
			
		# Revisar si logró llevar materiales al planeta
		var mensaje_mision = ""
		if Global1.materiales > 0:
			mensaje_mision = "\nMateriales disponibles: " + str(Global1.materiales) + " (Usa ESPACIO al despegar)"
		else:
			mensaje_mision = "\n¡Cuidado! Llegaste sin materiales."
			
		cartel_ui.add_theme_color_override("font_color", Color.YELLOW)
		cartel_ui.text = "¡Aterrizaje exitoso en " + nombre_planeta + "!" + mensaje_mision + "\nPresiona ENTER para despegar"
		cartel_ui.show()

	# 6. DEJAR MATERIALES CON ESPACIO (Solo si tiene materiales en el inventario)
	if Input.is_action_just_pressed("ui_select"):
		if Global1.materiales > 0:
			Global1.materiales -= 1 # Resta 1 material al usarlo
			var nuevo_objeto = ColorRect.new()
			nuevo_objeto.color = Color.GREEN
			nuevo_objeto.size = Vector2(30, 30)
			nuevo_objeto.global_position = global_position
			get_parent().add_child(nuevo_objeto)
			actualizar_hud()
		else:
			# Aviso rápido si intenta poner un objeto pero ya se le acabaron
			cartel_ui.add_theme_color_override("font_color", Color.ORANGE)
			cartel_ui.text = "¡No te quedan materiales para colocar!"
			cartel_ui.show()

func actualizar_hud():
	hud_ui.text = "⛽ Gasolina: " + str(int(Global1.gasolina)) + "%\n" + \
				  "🫧 Oxígeno: " + str(int(Global1.oxigeno)) + "%\n" + \
				  "📦 Materiales: " + str(Global1.materiales)

func morir(causa: String):
	muerto = true
	velocity = Vector2.ZERO
	cartel_ui.add_theme_color_override("font_color", Color.RED)
	cartel_ui.text = "💀 GAME OVER 💀\n" + causa + "\nPresiona 'R' para reintentar"
	cartel_ui.show()
