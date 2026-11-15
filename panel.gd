extends Panel

func _ready():
	$Button.pressed.connect(play_the_game)

func play_the_game():
	print ("works")
