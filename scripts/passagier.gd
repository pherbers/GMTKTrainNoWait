extends RigidBody2D

class_name Passagier

enum PState {WAIT_PLATFORM, WAIT_TRAIN, ENTER, EXIT, LEAVE}
@export var state: PState

@onready var game: Game = $/root/Game

@onready var nav: NavigationAgent2D = $NavigationAgent2D
var walk_force = 2000.

@onready var train_area: Area2D = $/root/Game/TrainArea
    
var push_force: Vector2
var crowd_size: int

@export var points_happy = 100
@export var points_pissed = -300

func _ready():
    game.passagiere.append(self)
    $NavigationAgent2D/Timer.start(randf())
    $NavigationAgent2D/Timer.wait_time = 1
    
    update_visuals()
    update_nav_target()

func _physics_process(_delta):
    apply_central_force(push_force)
    push_force = Vector2.ZERO

    # navigation
    var navpos = nav.get_next_path_position()
    var navdir = position.direction_to(navpos)
    var walk_force_mod = 1.
    if crowd_size > 3:
        walk_force_mod = 0.9
    if crowd_size > 6:
        walk_force_mod = 0.7
    if crowd_size > 10:
        walk_force_mod = 0.4
    apply_force(navdir * walk_force * walk_force_mod)

func _exit_tree():
    if game:
        var i = game.passagiere.find(self)
        if i >= 0:
            game.passagiere.remove_at(i)


func push(force):
    push_force += force


func repath():
    nav.target_position = nav.target_position

func set_wait():
    if state == PState.LEAVE:
        return
    if is_in_train():
        if state == PState.EXIT:
            # could not exit, pissed
            react_pissed()
        else:
            react_happy()
        state = PState.WAIT_TRAIN
    else:
        if state == PState.ENTER:
            # could not enter, pissed
            react_pissed()
        else:
            react_happy()
        state = PState.WAIT_PLATFORM
    update_visuals()
    update_nav_target()

func is_in_train() -> bool:
    return train_area.overlaps_body(self)

func react_pissed():
    game.score += points_pissed
    var piss = preload("res://scenes/react_pissed.tscn").instantiate()
    piss.position = position + Vector2(0, 16)
    piss.find_child("Label").text = "" + str(points_pissed)
    
    game.add_child(piss)
    
func react_happy():
    game.score += points_happy
    var happy = preload("res://scenes/react_happy.tscn").instantiate()
    happy.position = position + Vector2(0, 16)
    happy.find_child("Label").text = "+" + str(points_happy)
    game.add_child(happy)

func look_alive():
    if state == PState.LEAVE:
        return
    if is_in_train():
        state = PState.EXIT
    else:
        state = PState.ENTER
    
    update_visuals()
    update_nav_target()

func leave_station():
    if state == PState.LEAVE:
        update_nav_target()
        return
    state = PState.LEAVE
    nav.navigation_finished.connect(queue_free)
    update_nav_target()
    update_visuals()

func update_visuals():
    if state == PState.ENTER:
        $Sprite2D.modulate = Color.SEA_GREEN
    elif state == PState.EXIT:
        $Sprite2D.modulate = Color.DARK_RED
    elif state == PState.LEAVE:
        $Sprite2D.modulate = Color.BLACK
    elif state == PState.WAIT_PLATFORM:
        $Sprite2D.modulate = Color.WEB_GREEN
    elif state == PState.WAIT_TRAIN:
        $Sprite2D.modulate = Color.RED
        
func update_nav_target():
    if state == PState.ENTER:
        nav.target_position = game.get_train_target()
    elif state == PState.EXIT:
        nav.target_position = game.get_platform_target()
    elif state == PState.LEAVE:
        nav.target_position = game.get_platform_off_target(position)
    elif state == PState.WAIT_PLATFORM:
        nav.target_position = game.get_platform_target()
    elif state == PState.WAIT_TRAIN:
        nav.target_position = game.get_train_target()
    
