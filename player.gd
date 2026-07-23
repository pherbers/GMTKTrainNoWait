extends CharacterBody2D
class_name Player

@export var speed = 100

var push_force: Vector2

func get_input():
    var input_direction = Input.get_vector("left", "right", "up", "down")
    velocity = input_direction * speed

    if Input.is_action_just_pressed("ArmL"):
        set_arm_left(true)
    if Input.is_action_just_released("ArmL"):
        set_arm_left(false)
    if Input.is_action_just_pressed("ArmR"):
        set_arm_right(true)
    if Input.is_action_just_released("ArmR"):
        set_arm_right(false)

func _physics_process(delta):
    get_input()
    velocity += push_force * delta
    move_and_slide()
    push_force = Vector2.ZERO

func push(force):
    push_force += force


func set_arm_left(show):
    $ArmL.disabled = !show
    $ArmL.visible = show

func set_arm_right(show):
    $ArmR.disabled = !show
    $ArmR.visible = show
