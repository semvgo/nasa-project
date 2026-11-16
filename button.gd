extends Button

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	pressed.connect(_al_presionar)

func _al_presionar():
	# Si este es el botón principal (hijo de "misiones"), abre o cierra el Panel
	if has_node("../Panel"):
		var panel = get_node("../Panel")
		panel.visible = not panel.visible
	# Si este botón está adentro del Panel (el de cerrar), oculta el Panel
	elif get_parent() is Panel:
		get_parent().visible = false
