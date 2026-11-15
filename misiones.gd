extends Control
@onready var panel = $Panel
func _ready():
	$Button.pressed.connect(abrir_misiones)

func abrir_misiones():
	panel.visible = true
	
