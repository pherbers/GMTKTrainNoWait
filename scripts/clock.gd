extends Node2D

@onready var game: Game = $/root/Game
@onready var timer_depart: Timer = $/root/Game/UI/Countdown/TimerDepart
@onready var timer_arrive: Timer = $/root/Game/UI/Countdown/TimerNextLevel

@onready var clockarm_l = $ClockarmL
@onready var clockarm_s = $ClockarmS

var tick = 0.
var time_left = 0.
var _rot = 0
var _rot_short = 0
var hour = 7

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    tick -= delta
    time_left -= delta
    if tick <= 0:
        var t = 60 - time_left
        if game.game_state == Game.GameState.MAIN_MENU:
            t = int(Time.get_unix_time_from_system()) % 60
        var turn = deg_to_rad(360. / 60. * t)
        _rot = turn
        tick += 1.
    if abs(angle_difference(clockarm_l.rotation, _rot)) > delta * 2:
        clockarm_l.rotation += delta * 2
    else:
        clockarm_l.rotation = _rot
    _rot_short = deg_to_rad(360. / 12. * hour)
    clockarm_s.rotation = rotate_toward(clockarm_s.rotation, _rot_short, delta * 2)

func reset_clock():
    time_left = 25.
    tick = 0.
