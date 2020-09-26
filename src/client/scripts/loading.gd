extends TextureRect

onready var loadingText: Label = get_node('loading_text');

func showWithText(text: String):
	setText(text);
	self.show();

func setText(text):
	loadingText.text = text;
