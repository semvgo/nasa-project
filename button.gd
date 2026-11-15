extends Button
@onready var panel = $"../Panel"

func _ready():
	panel.visible = false
	$".".pressed.connect(abrir_panel)
	$"../Panel/Button".pressed.connect(cerrar_panel)
func abrir_panel():
	panel.visible = true
func cerrar_panel():
	panel.visible = false
