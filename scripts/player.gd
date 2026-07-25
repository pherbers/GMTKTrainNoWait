extends CharacterBody2D
class_name Player

@export var speed = 100

@onready var sprite = $Viz/Sprite2D

var push_force: Vector2

func get_input():
    var input_direction = Input.get_vector("left", "right", "up", "down")
    velocity = input_direction * speed
    
    if input_direction.length_squared() > 0.01:
        sprite.animation = "walk"
        sprite.flip_h = input_direction.x < 0
        $ArmU/Sprite2D.flip_h = input_direction.x < 0
        $ArmD/Sprite2D.flip_h = input_direction.x < 0
    else:
        sprite.animation = "idle"

    set_arm_left(false)
    set_arm_up(false)
    set_arm_right(false)
    set_arm_down(false)
    
    if Input.is_action_pressed("ArmDirectional"):
        var mouse_pos = get_global_mouse_position()
        var m_rel = (mouse_pos - global_position).normalized()
        var rad = atan2(m_rel.y, m_rel.x)
        var pi8 = PI / 8
        
        if rad < -7*pi8 or rad >= 7*pi8:
            set_arm_up(true)
            set_arm_down(true)
        elif rad < -5*pi8:
            set_arm_left(true)
            set_arm_up(true)
        elif rad < -3*pi8:
            set_arm_left(true)
            set_arm_right(true)
        elif rad < -1*pi8:
            set_arm_right(true)
            set_arm_up(true)
        elif rad < 1*pi8:
            set_arm_up(true)
            set_arm_down(true)
        elif rad < 3*pi8:
            set_arm_right(true)
            set_arm_down(true)
        elif rad < 5*pi8:
            set_arm_left(true)
            set_arm_right(true)
        elif rad < 7*pi8:
            set_arm_left(true)
            set_arm_down(true)
            
    elif Input.is_action_pressed("ArmL") and Input.is_action_pressed("ArmU"):
        set_arm_left(true)
        set_arm_up(true)
    elif Input.is_action_pressed("ArmR") and Input.is_action_pressed("ArmU"):
        set_arm_right(true)
        set_arm_up(true)
    elif Input.is_action_pressed("ArmR") and Input.is_action_pressed("ArmD"):
        set_arm_right(true)
        set_arm_down(true)
    elif Input.is_action_pressed("ArmL") and Input.is_action_pressed("ArmD"):
        set_arm_left(true)
        set_arm_down(true)
    elif Input.is_action_pressed("ArmU") or Input.is_action_pressed("ArmD"):
        set_arm_left(true)
        set_arm_right(true)
    elif Input.is_action_pressed("ArmL") or Input.is_action_pressed("ArmR"):
        set_arm_up(true)
        set_arm_down(true)
    

func _physics_process(delta):
    get_input()
    if push_force.length_squared() > 200.:
        velocity += push_force.clampf(-1000, 1000) * delta
    move_and_slide()
    push_force = Vector2.ZERO

func push(force):
    push_force += force


func set_arm_left(showme):
    $ArmL.disabled = !showme
    $ArmL.visible = showme

func set_arm_right(showme):
    $ArmR.disabled = !showme
    $ArmR.visible = showme

func set_arm_down(showme):
    $ArmD.disabled = !showme
    $ArmD.visible = showme

func set_arm_up(showme):
    $ArmU.disabled = !showme
    $ArmU.visible = showme
