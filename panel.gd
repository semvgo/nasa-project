extends Panel

func _ready():
	$Button.pressed.connect(play_the_game)

func play_the_game():
	get_tree().change_scene_to_file("res://interfazelegir cohete.tscn")
