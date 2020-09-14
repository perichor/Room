extends KinematicBody2D

var score: int = 0;

var speed: int = 10;

var vel: Vector2 = Vector2();
onready var sprite: Sprite = get_node('sprite');
onready var player: KinematicBody2D = get_node('.');

func _physics_process(_delta):
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
