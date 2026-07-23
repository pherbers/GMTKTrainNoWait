extends Node2D
class_name Game


var passagiere: Array[Passagier]

@export var player: Player

@export var passanger_force = 1.0
@export var passanger_force_cutoff = 32.0



func _process(delta):
    pass

func _physics_process(delta):
    integrate_passanger_forces(delta)


func integrate_passanger_forces(delta: float):
    for i in range(len(passagiere)):
        var p1 = passagiere[i]
        var force_vec = calc_push_force(player.position, p1.position)
        p1.push(force_vec)
        player.push(-force_vec)

    for i in range(len(passagiere)):
        var p1 = passagiere[i]
        p1.crowd_size = 0

        for j in range(i):
            var p2 = passagiere[j]
            var force_vec = calc_push_force(p1.position, p2.position)
            if force_vec == Vector2.ZERO:
                continue
            p1.push(-force_vec)
            p2.push(force_vec)
            p1.crowd_size += 1
            p2.crowd_size += 1

func calc_push_force(pos1, pos2):
    var dist = pos1.distance_to(pos2) / 32
    if dist > passanger_force_cutoff or dist == 0:
        return Vector2.ZERO

    var force = 1. / pow(dist,4)
    var dir = pos1.direction_to(pos2)
    var force_vec = dir * force * passanger_force
    return force_vec

func get_platform_target():
    return $PlatformTarget.position

func get_train_target():
    return $TrainTarget.position
