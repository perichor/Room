extends KinematicBody2D

const DISCONNECT_TIMER: int = 5000;

var remoteUserId: int;
var localPlayer: bool = true;
var score: int = 0;

const ACCELERATION: int = 4200;
const MAX_SPEED: int = 700;
const FRICTION = 7000;

var vel: Vector2 = Vector2();
onready var sprite: Sprite = get_node('sprite');
onready var player: KinematicBody2D = self;
onready var scene: Node = get_parent().get_parent();

func _ready():
	if (localPlayer && global.initialPosition):
			player.position = global.initialPosition; 

func _physics_process(delta):
	if (localPlayer):
		player.position = Vector2(int(round(player.position[0])), int(round(player.position[1])));
		
		var input_vector = Vector2.ZERO;
		input_vector.x = Input.get_action_strength('move_right') - Input.get_action_strength('move_left');
		input_vector.y = Input.get_action_strength('move_down') - Input.get_action_strength('move_up');
		input_vector = input_vector.normalized();
		
		if (input_vector != Vector2.ZERO):
			vel = vel.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta);
		else:
			vel = vel.move_toward(Vector2.ZERO, FRICTION * delta);

		vel = move_and_slide(vel)
	else:
		var playerStatus = scene.getPlayerStatusById(remoteUserId);
		player.position = Vector2(playerStatus.x, playerStatus.y);
		if (OS.get_ticks_msec() - playerStatus.lastHandshakeTime > DISCONNECT_TIMER):
			queue_free();
	
func setRemoteUserId(id: int):
	remoteUserId = id;
	localPlayer = false;
