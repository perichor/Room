extends Control

onready var version: Label = get_node('build_version');
onready var ipInput: LineEdit = get_node('ip_input');
onready var invalidIp: Label = get_node('ip_input/invalid_ip_text');
onready var loading: TextureRect = get_node('loading');
onready var loadingText: Label = get_node('loading/loading_text');
onready var downloadDialog: PopupDialog = get_node('loading/download_dialog');
onready var serverUnavailable: Label = get_node('server_down_text');

var http = preload('res://addons/http.gd').new();

var buildsDontMatch: bool;

func _ready():
	ipInput.text = global.SERVER_HOST;
	version.text = String(global.build_version);
	http.connect('loading', self, '_on_loading');
	http.connect('loaded', self, '_on_loaded');
	http.connect('no_response', self, '_on_no_response');

func _on_loading(loaded, total, url):
	if (url == '/download'):
		var percent: float = (float(loaded) / float(total)) * 100;
		loadingText.text = 'Downloading Update ' + String('%.1f' % percent) + '% (' + String(loaded / 1000) + 'kb out of ' + String(total / 1000) + 'kb)';

func _on_loaded(result, headers, url):
	if (url == '/version'):
		buildsDontMatch = global.build_version != result.get_string_from_ascii();
		if (buildsDontMatch):
			downloadDialog.show()
		else:
			startGame();
	elif (url == '/download'):
		loadingText.text = 'Download Complete';
		save(result, OS.get_executable_path().get_base_dir() + '/temp.zip');
		updateAndRestart();
		
func _on_no_response():
	loading.hide();
	serverUnavailable.show();
	
func downloadUpdate():
	loadingText.text = 'Downloading Update...';
	http.getHttp(global.SERVER_HOST, '/download', global.FILE_PORT, false, true);

func play():
	serverUnavailable.hide();
	if (ipInput.text.is_valid_ip_address()):
		global.SERVER_HOST = ipInput.text
		invalidIp.hide();
		loading.show();
		loadingText.text = 'Verifying Server Version';
		http.getHttp(global.SERVER_HOST, '/version', global.FILE_PORT, false, false);
	else:
		invalidIp.show();
		
func startGame():
	# warning-ignore:return_value_discarded
	get_tree().change_scene('res://scenes/main_scene.tscn');

func save(content, path):
	var file = File.new();
	file.open(path, File.WRITE);
	file.store_buffer(content);
	file.close();
	
func updateAndRestart():
#	print(OS.execute(OS.get_executable_path().get_base_dir() + '/updater.sh', []))
#	print(OS.execute('sleep', [5, 'unzip', OS.get_executable_path().get_base_dir() + '/temp.zip', 'rm', OS.get_executable_path().get_base_dir() + '/temp.zip']));
	print(OS.execute('unzip', [OS.get_executable_path().get_base_dir() + '/temp.zip']));
