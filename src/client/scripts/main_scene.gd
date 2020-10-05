extends Node

var playerResource = preload('res://scenes/player.tscn');
var udpClient = preload('res://scripts/udp.gd').new();
var httpClient = preload('res://addons/http.gd').new();

onready var perspective = get_node('perspective');
onready var localPlayer = get_node('perspective/player');

var remotePlayers = {};

func _ready():
	udpClient.connect('playerUpdate', self, 'handlePlayerUpdate');
	httpClient.connect('loaded', self, '_on_loaded');

func _process(_delta):
	sendPlayerUpdate();
	udpClient.processPackets();
	
func _on_loaded(result, _headers, url):
	if (url.begins_with('/get-user-info')):
		result = result.get_string_from_utf8();
		if (result.begins_with('success')):
			var info = JSON.parse(result.right(8)).result;
			if (remotePlayers.has(int(info.userId))):
				remotePlayers[int(info.userId)].node.setInfo(info);
		
func getUserInfo(userId):
	httpClient.getRequest(global.SERVER_HOST, global.HTTP_PORT, '/get-user-info/' + str(userId), true, false);

func getPlayerStatusById(userId):
	return remotePlayers[userId];

func handlePlayerUpdate(userId, x, y, state):
	if (!remotePlayers.has(userId)):
		var newPlayer = playerResource.instance();
		remotePlayers[userId] = {
			'playerId': userId,
			'x': x,
			'y': y,
			'state': state,
			'lastHandshakeTime': OS.get_ticks_msec(),
			'node': newPlayer
		}
		getUserInfo(userId);
		newPlayer.setRemoteUserId(userId);
		perspective.add_child(newPlayer);
	else:
		remotePlayers[userId].x = x;
		remotePlayers[userId].y = y;
		remotePlayers[userId].state = state;
		remotePlayers[userId].lastHandshakeTime = OS.get_ticks_msec();

func sendPlayerUpdate():
	var x: int = int(round(localPlayer.position[0]));
	var y: int = int(round(localPlayer.position[1]));
	var state: int = localPlayer.state;
	udpClient.buildPlayerUpdatePacket(x, y, state);
	

