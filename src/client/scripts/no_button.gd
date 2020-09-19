extends Button

onready var loading: TextureRect = get_parent().get_parent();
onready var dialog: PopupDialog = get_parent();
func _pressed():
	loading.hide();
	dialog.hide();
