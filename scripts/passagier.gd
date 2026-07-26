extends RigidBody2D

class_name Passagier

enum PState {WAIT_PLATFORM, WAIT_TRAIN_DEPART, WAIT_TRAIN_ARRIVE, ENTER, EXIT, LEAVE}
@export var state: PState

@onready var game: Game = $/root/Game

@onready var nav: NavigationAgent2D = $NavigationAgent2D
var walk_force = 2000.

@onready var train_area: Area2D = $/root/Game/TrainArea
@onready var sprite: AnimatedSprite2D = $Sprite2D

var push_force: Vector2
var crowd_size: int

@export var points_happy = 100
@export var points_pissed = -300

enum PType { NORMAL, OLD, AGRESSIVE}
@export var type = PType.NORMAL

func _ready():
    game.passagiere.append(self)
    $NavigationAgent2D/Timer.start(randf())
    $NavigationAgent2D/Timer.wait_time = 1

    update_visuals()
    update_nav_target()

    sprite.animation = "idle"
    if type == PType.OLD:
        walk_force /= 2
        sprite.speed_scale = 0.5
        sprite.sprite_frames = preload("res://sprites/passenger_omi.tres")
        sprite.animation = "idle"
        sprite.play()
    if type == PType.AGRESSIVE:
        walk_force *= 2
        sprite.speed_scale = 1.5
        sprite.sprite_frames = preload("res://sprites/passenger_bfman.tres")
        sprite.animation = "idle"
        sprite.play()

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
    var dists = navpos.distance_squared_to(position)
    if dists < 1:
        walk_force_mod *= dists
        sprite.animation = "idle"
    else:
        if state != PState.WAIT_TRAIN_DEPART and state != PState.WAIT_TRAIN_ARRIVE:
            sprite.animation = "walk"
        if navdir.x < -0.2:
            sprite.flip_h = true
        if navdir.x > 0.2:
            sprite.flip_h = false
    apply_force(navdir * walk_force * walk_force_mod)

func _exit_tree():
    pass

func push(force):
    push_force += force


func repath():
    nav.target_position = nav.target_position

func set_wait():
    if state == PState.LEAVE:
        return
    if is_in_train() and state != PState.WAIT_TRAIN_ARRIVE:
        if state == PState.EXIT:
            # could not exit, pissed
            react_pissed()
        else:
            react_happy()
        set_wait_train()
    else:
        if state == PState.ENTER:
            # could not enter, pissed
            react_pissed()
        else:
            react_happy()
        state = PState.WAIT_PLATFORM
    update_visuals()
    update_nav_target()


func set_wait_train():
    state = PState.WAIT_TRAIN_DEPART
    var train = $/root/Game/Train/Viz/Passengers
    get_parent().remove_child(self)
    train.add_child(self)


func is_in_train() -> bool:
    return train_area.overlaps_body(self)

func react_pissed():
    game.score += points_pissed
    game.pissed_people += 1
    var piss = preload("res://scenes/react_pissed.tscn").instantiate()
    piss.find_child("Label").text = "" + str(points_pissed)

    if is_in_train():
        piss.position = Vector2(randi_range(-100, 100), -96)
        game.add_child(piss)
        create_tween().tween_property(piss, "position", piss.position + Vector2(0, -48), 5)
    else:
        piss.position = Vector2(0, -48)
        add_child(piss)

func react_happy():
    game.score += points_happy
    var happy = preload("res://scenes/react_happy.tscn").instantiate()
    happy.position = position + Vector2(0, 16)
    happy.find_child("Label").text = "+" + str(points_happy)
    add_child(happy)

func look_alive():
    if state == PState.LEAVE:
        return
    if state == PState.WAIT_TRAIN_ARRIVE:
        state = PState.EXIT
        var passnode = $/root/Game/Passagiere
        get_parent().remove_child(self)
        passnode.add_child(self)
    else:
        state = PState.ENTER

    update_visuals()
    update_nav_target()

func leave_station():
    if state == PState.LEAVE:
        update_nav_target()
        return
    state = PState.LEAVE
    nav.navigation_finished.connect(despawn)
    update_nav_target()
    update_visuals()

func despawn():
    if game:
        var i = game.passagiere.find(self)
        if i >= 0:
            game.passagiere.remove_at(i)
    queue_free()
func update_visuals():
    if state == PState.ENTER:
        $Halo.visible = true
        $Halo.modulate = Color.NAVY_BLUE
    elif state == PState.EXIT:
        $Halo.visible = true
        $Halo.modulate = Color.DARK_RED
    elif state == PState.LEAVE:
        $Halo.visible = false
    elif state == PState.WAIT_PLATFORM:
        $Halo.visible = false
    elif state == PState.WAIT_TRAIN_DEPART:
        sprite.animation = "idle"
        $Halo.visible = false
    elif state == PState.WAIT_TRAIN_ARRIVE:
        $Halo.visible = false
        sprite.animation = "idle"

func update_nav_target():
    if state == PState.ENTER:
        nav.target_position = game.get_train_target()
    elif state == PState.EXIT:
        nav.target_position = game.get_platform_target()
    elif state == PState.LEAVE:
        nav.target_position = game.get_platform_off_target(position)
    elif state == PState.WAIT_PLATFORM:
        if nav.target_position.distance_to(position) > 10:
            nav.target_position = game.get_platform_target()
    elif state == PState.WAIT_TRAIN_DEPART:
        pass
    elif state == PState.WAIT_TRAIN_ARRIVE:
        pass
        #nav.target_position = game.get_train_target()
