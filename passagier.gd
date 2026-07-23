extends RigidBody2D

class_name Passagier

enum PState {WAIT, ENTER, EXIT}
@export var state: PState

@onready var game: Game = $/root/Game

@onready var nav: NavigationAgent2D = $NavigationAgent2D
@export var walk_force = 2000.

var push_force: Vector2
var crowd_size: int

func _ready():
    game.passagiere.append(self)
    if state == PState.ENTER:
        nav.target_position = game.get_train_target()
        $Sprite2D.modulate = Color.SEA_GREEN
    if state == PState.EXIT:
        nav.target_position = game.get_platform_target()
        $Sprite2D.modulate = Color.DARK_RED
    $NavigationAgent2D/Timer.start(randf())
    $NavigationAgent2D/Timer.wait_time = 1

func _physics_process(_delta):
    apply_central_force(push_force)
    push_force = Vector2.ZERO

    # navigation
    if state != PState.WAIT:
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
        game.passagiere.remove_at(game.passagiere.find(self))


func push(force):
    push_force += force


func repath():
    if state != PState.WAIT:
        nav.target_position = nav.target_position
