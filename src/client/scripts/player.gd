extends KinematicBody2D

const DISCONNECT_TIMER: int = 5000;

var remotePlayerId: int;
var localPlayer: bool = true;
var score: int = 0;

var speed: int = 10;

var vel: Vector2 = Vector2();
onready var sprite: Sprite = get_node('sprite');
onready var player: KinematicBody2D = self;
onready var parent: Node = get_parent();

func _physics_process(_delta):
	if (localPlayer):
		player.position = Vector2(int(round(player.position[0])), int(round(player.position[1])));
		
		vel.x = 0;
		vel.y = 0;
		
		if (Input.is_action_pressed('move_left')):
			vel.x -= speed;
		if (Input.is_action_pressed('move_right')):
			vel.x += speed;
		if (Input.is_action_pressed('move_up')):
			vel.y -= speed;
		if (Input.is_action_pressed('move_down')):
			vel.y += speed;
			
	# warning-ignore:return_value_discarded
		move_and_collide(vel)
	else:
		var playerStatus = parent.getPlayerStatusById(remotePlayerId);
		player.position = Vector2(playerStatus.x, playerStatus.y);
		if (OS.get_ticks_msec() - playerStatus.lastHandshakeTime > DISCONNECT_TIMER):
			parent.remove_child(player);
	
func setRemotePlayerId(id: int):
	remotePlayerId = id;
	localPlayer = false;
