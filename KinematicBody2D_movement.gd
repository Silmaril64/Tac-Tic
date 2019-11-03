extends KinematicBody2D


var case = 100

func _ready():
	$AnimationPlayer.play("Waving_Blue_Animation")
	$AnimationPlayer.play("Waving_Red_Animation")

func _physics_process(delta):
	move_local_x(case*(int(Input.is_action_just_pressed("Right")) - int(Input.is_action_just_pressed("Left"))))
	move_local_y(case*(int(Input.is_action_just_pressed("Down")) - int(Input.is_action_just_pressed("Up"))))
	