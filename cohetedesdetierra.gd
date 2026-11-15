extends Sprite2D
var velocity_y = -2
var despegando = false
func _process(delta):
	if Input.is_action_just_pressed("ui_accept") and despegando == false:
		despegando = true
		$"../AudioStreamPlayer2D".play()
		while true:
			await get_tree().create_timer(0.005).timeout
			position.y += velocity_y
			if position.y <= -300.0:
				$"../AudioStreamPlayer2D".stop()
				break

			
		
