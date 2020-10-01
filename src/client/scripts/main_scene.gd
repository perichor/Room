extends Node

var playerResource = preload('res://scenes/player.tscn');
var udpClient = preload('res://scripts/udp.gd').new();

onready var localPlayer = get_node('YSort/player');
var remotePlayers = {};

func _ready():
	udpClient.connect('playerUpdate', self, 'handlePlayerUpdate')

func _process(_delta):
	sendPlayerUpdate();
	udpClient.processPackets();

func getPlayerStatusById(userId):
	return remotePlayers[userId];	

func handlePlayerUpdate(userId, x, y):
	if (!remotePlayers.has(userId)):
		var newPlayer = playerResource.instance();
		remotePlayers[userId] = {
			'playerId': userId,
			'x': x,
			'y': y,
			'lastHandshakeTime': OS.get_ticks_msec()
		}
		newPlayer.setRemoteUserId(userId);
		add_child(newPlayer);
	else:
		remotePlayers[userId].x = x;
		remotePlayers[userId].y = y;
		remotePlayers[userId].lastHandshakeTime = OS.get_ticks_msec();

func sendPlayerUpdate():
	var x: int = int(round(localPlayer.position[0]));
	var y: int = int(round(localPlayer.position[1]));
	udpClient.buildPlayerUpdatePacket(x, y);
