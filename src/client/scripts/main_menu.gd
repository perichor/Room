extends Control

onready var version: Label = get_node('build_version');
onready var connectMenu: Control = get_node('connect_menu');
onready var ipInput: LineEdit = get_node('connect_menu/ip_input');
onready var invalidIp: Label = get_node('connect_menu/ip_input/invalid_ip_text');
onready var connectButton: Button = get_node('connect_menu/connect_button');
onready var serverUnavailable: Label = get_node('connect_menu/server_down_text');
onready var loginMenu: Control = get_node('login_menu');
onready var usernameInput: LineEdit = get_node('login_menu/username_input');
onready var connectToText: Label = get_node('login_menu/connected_to_text');
onready var invalidUsername: Label = get_node('login_menu/username_input/invalid_username_text');
onready var accountSuccesful: Label = get_node('login_menu/account_succesful');
onready var loginFailed: Label = get_node('login_menu/login_failed');
onready var passwordInput: LineEdit = get_node('login_menu/password_input');
onready var invalidPassword: Label = get_node('login_menu/password_input/invalid_password_text');
onready var showCreateAccountButton: LinkButton = get_node('login_menu/create_account_button');
onready var playButton: Button = get_node('login_menu/play_button');
onready var loading: TextureRect = get_node('loading');
onready var downloadDialog: PopupDialog = get_node('loading/download_dialog');
onready var restartDialog: PopupDialog = get_node('loading/restart_dialog');
onready var createAccountDialog: PopupDialog = get_node('loading/create_account');
onready var createUsername: LineEdit = get_node('loading/create_account/create_username_input');
onready var createPassword: LineEdit = get_node('loading/create_account/create_password_input');
onready var accountUnsuccessful: Label = get_node('loading/create_account/account_unsuccesful');


var httpClient = preload('res://addons/http.gd').new();
var Unzip = preload('res://addons/unzip.gd').new();
var buildsDontMatch: bool;

func _ready():
	ipInput.text = global.SERVER_HOST;
	version.text = String(global.build_version);
	httpClient.connect('loading', self, '_on_loading');
	httpClient.connect('loaded', self, '_on_loaded');
	httpClient.connect('no_response', self, '_on_no_response');
	loading.showWithText('Connecting to server...')
	connectToServer();

func _on_loading(loaded, total, url):
	if (url == '/download'):
		var percent: float = (float(loaded) / float(total)) * 100;
		loading.setText('Downloading Update ' + String('%.1f' % percent) + '% (' + String(loaded / 1000) + 'kb out of ' + String(total / 1000) + 'kb)');

func _on_loaded(result, _headers, url):
	if (url == '/version'):
		buildsDontMatch = global.build_version != result.get_string_from_ascii();
		if (buildsDontMatch):
			downloadDialog.show()
		else:
			switchToLogin();
			loading.hide();
	elif (url == '/login'):
		loading.hide();
		result = result.get_string_from_ascii();
		if (result.begins_with('success')):
			var initialStatus = JSON.parse(result.right(8)).result;
			global.userId = initialStatus.id;
			if (!initialStatus.x || !initialStatus.y):
				initialStatus.x = global.defaultPosition.x;
				initialStatus.y = global.defaultPosition.y;
			global.initialPosition = Vector2(initialStatus.x, initialStatus.y);
			startGame();
		elif (result.begins_with('failure')):
			loginFailed.text = result.right(8);
			loginFailed.show();
	elif (url == '/create-account'):
		result = result.get_string_from_ascii();
		if (result.begins_with('success')):
			loading.hide();
			accountSuccesful.show();
			usernameInput.text = createUsername.text;
			passwordInput.text = createPassword.text;
		elif (result.begins_with('failure')):
			createAccountDialog.show();
			accountUnsuccessful.text = result.right(8);
			accountUnsuccessful.show();
	elif (url == '/download'):
		loading.setText('Download Complete');
		save(result, OS.get_executable_path().get_base_dir() + '/temp.zip');
		updateAndRestart();
		
func _on_no_response(url):
	if (url == '/version'):
		switchToConnect();
	loading.hide();
	serverUnavailable.show();
	
func checkVersion():
	loading.showWithText('Verifying Server Version');
	httpClient.getRequest(global.SERVER_HOST, global.HTTP_PORT, '/version', true, false);

func login():
	loading.showWithText('Logging in...');
	httpClient.postRequest(global.SERVER_HOST, global.HTTP_PORT, '/login', { 'username': usernameInput.text, 'password' : passwordInput.text.sha256_text() }, true, false);
	
func createAccount():
	createAccountDialog.hide();
	accountUnsuccessful.hide();
	loading.showWithText('Creating Account');
	httpClient.postRequest(global.SERVER_HOST, global.HTTP_PORT, '/create-account', { 'username': createUsername.text, 'password' : createPassword.text.sha256_text() }, true, false);

func downloadUpdate():
	loading.showWithText('Downloading Update...');
	httpClient.getRequest(global.SERVER_HOST, global.HTTP_PORT, '/download', true, true);
	
func openCreateAccountDialog():
	createAccountDialog.show();
	loading.show();

func play(_text):
	serverUnavailable.hide();
	loginFailed.hide();
	hideErrors();
	if (checkValidInputs()):
		login();
		
func connectToServer():
	invalidIp.hide();
	var ipValid = ipInput.text.is_valid_ip_address() || ipInput.text == 'local' || ipInput.text == 'localhost';
	if (!ipValid): invalidIp.show();
	if (ipValid):
		global.SERVER_HOST = ipInput.text
		if (ipInput.text == 'local' || ipInput.text == 'localhost'):
			global.SERVER_HOST = '127.0.0.1';
		checkVersion();
		
func checkValidInputs():
	var usernameValid = usernameInput.text.length();
	if (!usernameValid): invalidUsername.show();
	var passwordValid = passwordInput.text.length();
	if (!passwordValid): invalidPassword.show();
	return usernameValid && passwordValid;
	
func hideErrors():
	invalidUsername.hide();
	invalidPassword.hide();

func hideCreateAccount():
	loading.hide();
	createAccountDialog.hide();
	accountUnsuccessful.hide();
	
func switchToLogin():
	connectToText.text = 'Connected to server at: ' + global.SERVER_HOST;
	connectMenu.hide();
	loginMenu.show();

func switchToConnect():
	loginMenu.hide();
	connectMenu.show();

func startGame():
	# warning-ignore:return_value_discarded
	get_tree().change_scene('res://scenes/main_scene.tscn');

func save(content, path):
	var file = File.new();
	file.open(path, File.WRITE);
	file.store_buffer(content);
	file.close();
	
func updateAndRestart():
	Unzip.unzip(OS.get_executable_path().get_base_dir() + '/temp.zip', OS.get_executable_path().get_base_dir());
	var dir = Directory.new()
	dir.remove(OS.get_executable_path().get_base_dir() + '/temp.zip');
	restartDialog.show();
	
func quitGame():
	restartDialog.hide();
	get_tree().quit()
