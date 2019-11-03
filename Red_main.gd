extends KinematicBody2D


var Blue_Sprite = preload("res://Waving_Blue.png")
var Red_Sprite = preload("res://Waving_Red.png")

func _ready():
	$AnimationPlayer.play("Waving_Red_Animation")

func _physics_process(delta):
	
	if (int(Input.is_action_just_pressed("Right")) - int(Input.is_action_just_pressed("Left"))) :
	 	get_parent().movement_question(Vector2((int(Input.is_action_just_pressed("Right")) - int(Input.is_action_just_pressed("Left"))),0),"Red")
	elif (int(Input.is_action_just_pressed("Down")) - int(Input.is_action_just_pressed("Up"))):
		get_parent().movement_question(Vector2(0, (int(Input.is_action_just_pressed("Down")) - int(Input.is_action_just_pressed("Up")))),"Red")
		
	#Color part
	if Input.is_action_just_pressed("Tour"):
		get_parent().new_unit(1,"Red")


