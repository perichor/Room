extends Button

onready var parent: Node = get_parent();

func _pressed():
	parent.play();
