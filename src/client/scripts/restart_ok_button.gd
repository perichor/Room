extends Button

onready var scene = get_parent().get_parent().get_parent();

func _pressed():
	scene.quitGame();
