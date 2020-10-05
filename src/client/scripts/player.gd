extends KinematicBody2D

const DISCONNECT_TIMER: int = 5000;

var remoteUserId: int;
var localPlayer: bool = true;

const ACCELERATION: int = 8400;
const MAX_SPEED: int = 200;
const FRICTION = 14000;
const SPRINT_FACTOR = 1.7;

enum {
	RIGHT,
	UP,
	LEFT,
	DOWN
}

# specific action state
enum {
	IDLE_RIGHT,
	IDLE_UP,
	IDLE_LEFT,
	IDLE_DOWN,
	RUN_RIGHT,
	RUN_UP,
	RUN_LEFT,
	RUN_DOWN,
	ATTACK_RIGHT,
	ATTACK_UP,
	ATTACK_LEFT,
	ATTACK_DOWN,
	ROLL
}

# action states
enum {
	IDLE,
	RUN,
	ATTACK
}

var directionalStateMap = {
	IDLE: {
		RIGHT: IDLE_RIGHT,
		UP: IDLE_UP,
		LEFT: IDLE_LEFT,
		DOWN: IDLE_DOWN
	},
	RUN: {
		RIGHT: RUN_RIGHT,
		UP: RUN_UP,
		LEFT: RUN_LEFT,
		DOWN: RUN_DOWN
	},
	ATTACK: {
		RIGHT: ATTACK_RIGHT,
		UP: ATTACK_UP,
		LEFT: ATTACK_LEFT,
		DOWN: ATTACK_DOWN
	}
}

var animationMapping = {
	IDLE_RIGHT: 'IdleRight',
	IDLE_UP: 'IdleUp',
	IDLE_LEFT: 'IdleLeft',
	IDLE_DOWN: 'IdleDown',
	RUN_RIGHT: 'RunRight',
	RUN_UP: 'RunUp',
	RUN_LEFT: 'RunLeft',
	RUN_DOWN: 'RunDown',
	ATTACK_RIGHT: 'AttackRight',
	ATTACK_UP: 'AttackUp',
	ATTACK_LEFT: 'AttackLeft',
	ATTACK_DOWN: 'AttackDown'
}

onready var sprite: Sprite = $sprite;
onready var player: KinematicBody2D = self;
onready var scene: Node = get_parent().get_parent();
onready var animationPlayer: AnimationPlayer = $AnimationPlayer;

onready var namePlate:  = $name_plate;

var vel: Vector2 = Vector2();
var state: int = IDLE_RIGHT;
var actionState: int = IDLE;
var direction: int = RIGHT;

func _ready():
	if (localPlayer && global.initialPosition):
			player.position = global.initialPosition; 
			
func setRemoteUserId(id: int):
	remoteUserId = id;
	localPlayer = false;

func setInfo(info: Dictionary):
	namePlate.text = info.char_name;
	namePlate.show();

func _physics_process(delta):
	if (localPlayer):
		match actionState:
			IDLE:
				move_state(delta);
			RUN:
				move_state(delta);
			ATTACK:
				attack_state(delta);
	else:
		updateRemotePlayer()
	
func move_state(delta):
	player.position = Vector2(int(round(player.position[0])), int(round(player.position[1])));
	
	var input_vector = Vector2.ZERO;
	input_vector.x = Input.get_action_strength('move_right') - Input.get_action_strength('move_left');
	input_vector.y = Input.get_action_strength('move_down') - Input.get_action_strength('move_up');
	input_vector = input_vector.normalized();
	
	if (input_vector != Vector2.ZERO):
		if (Input.is_action_pressed('sprint')):
			vel = vel.move_toward(input_vector * MAX_SPEED * SPRINT_FACTOR, ACCELERATION * SPRINT_FACTOR * delta);
			animationPlayer.set_speed_scale(SPRINT_FACTOR);
		else:
			vel = vel.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta);
			animationPlayer.set_speed_scale(1);
		setDirection(input_vector);
		state = getDirectionalState(RUN);
	else:
		state = getDirectionalState(IDLE);
		vel = vel.move_toward(Vector2.ZERO, FRICTION * delta);

	vel = move_and_slide(vel);
	
	if (Input.is_action_just_pressed('attack')):
		actionState = ATTACK;
		state = getDirectionalState(ATTACK);
		
	updateAnimation();
	
func attack_state(_delta):
	vel = Vector2.ZERO;
	updateAnimation()
	
func on_attack_animation_finished():
	actionState = IDLE;
	updateAnimation();
	
func updateRemotePlayer():
	var playerStatus = scene.getPlayerStatusById(remoteUserId);
	var newLocation = Vector2(playerStatus.x, playerStatus.y);
	
	if (state != playerStatus.state):
		state = playerStatus.state;
		updateAnimation()
	
	player.position = newLocation;
	if (OS.get_ticks_msec() - playerStatus.lastHandshakeTime > DISCONNECT_TIMER):
		queue_free();
		
func updateAnimation():
	animationPlayer.play(animationMapping[state]);

func setDirection(vector):
	var angle = round(rad2deg(vector.angle()));
	if (angle >= -45 && angle <= 45):
		direction = RIGHT;
	elif (angle > -135 && angle < -45):
		direction = UP;
	elif (angle >= 135 || angle <= -135):
		direction = LEFT;
	elif (angle > 45 && angle < 135):
		direction = DOWN;

func getDirectionalState(stateGroup):
	return directionalStateMap[stateGroup][direction];
