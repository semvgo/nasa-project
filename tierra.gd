extends Sprite2D

var velocidad_rotacion = 1.5

func _process(delta):
	# Gira el planeta constantemente
	rotation += velocidad_rotacion * delta
