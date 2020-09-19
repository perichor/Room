extends Button

onready var scene = get_parent().get_parent().get_parent();
onready var dialog: PopupDialog = get_parent();
func _pressed():
	scene.downloadUpdate()
	dialog.hide();
