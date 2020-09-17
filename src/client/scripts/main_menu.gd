extends Control

const defaultHost: String = '104.34.146.138';

onready var ipInput: LineEdit = get_node('ip_input');

func _ready():
	ipInput.text = defaultHost;

func play():
	if (ipInput.text.length() > 0):
		global.SERVER_HOST = ipInput.text
# warning-ignore:return_value_discarded
		get_tree().change_scene('res://scenes/main_scene.tscn');
