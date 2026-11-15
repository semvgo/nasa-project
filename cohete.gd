extends Sprite2D

var velocidad_movimiento = 500 

# Estos son los límites o "muros invisibles" del mapa. 
# Si tu fondo es muy grande, quizás debas aumentar estos números (ej. a 5000 o -5000).
var limite_izq = -2500
var limite_der = 2500
var limite_arriba = -1500
var limite_abajo = 1500

func _process(delta):
	
	# Mover a la derecha y asegurar que mire a su posición original
	if Input.is_key_pressed(KEY_D):
		position.x += velocidad_movimiento * delta
		flip_h = false 
		
	# Mover a la izquierda y VOLTEAR la imagen
	if Input.is_key_pressed(KEY_A):
		position.x -= velocidad_movimiento * delta
		flip_h = true 
		
	if Input.is_key_pressed(KEY_S):
		position.y += velocidad_movimiento * delta
		
	if Input.is_key_pressed(KEY_W):
		position.y -= velocidad_movimiento * delta

	# LÍMITES DEL MAPA: clamp atrapa la posición para que el cohete no cruce las fronteras
	position.x = clamp(position.x, limite_izq, limite_der)
	position.y = clamp(position.y, limite_arriba, limite_abajo)
