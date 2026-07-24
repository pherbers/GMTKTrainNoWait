extends Node2D
class_name Game


var passagiere: Array[Passagier]

@export var player: Player

@export var passanger_force = 1.0
@export var passanger_force_cutoff = 32.0

enum GameState { NEXT_LEVEL, PLAY, DEPART }
@export var game_state: GameState = GameState.NEXT_LEVEL

@export var train_spawns = 10
@export var platform_spawns = 10

@export var train_spawns_round = [6, 7, 10, 5, 12, 13]
@export var platform_spawns_round = [6, 7, 6, 11, 10, 11]

@export var round = 0
@export var max_rounds = 6

@export var score = 0:
    set(val):
        score = val
        update_score()


func _ready():
    $UI/Rounds/RoundsLabel.text = str(round) + "/" + str(max_rounds)
    spawn_platform()

func _process(delta):
    if $CheatManager.cheat_mode:
        if Input.is_key_pressed(KEY_0):
            for p in passagiere:
                p.find_child("NavigationAgent2D").debug_enabled = true

func _physics_process(delta):
    integrate_passanger_forces(delta)

func update_score():
    $UI/Score/ScoreLabel.text = str(score)

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
            if p1.state != p2.state:
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
    return $Spawns/Platform.get_children().pick_random().position
    
func get_platform_off_target_random():
    return $Spawns/PlatformOff.get_children().pick_random().position
    
func get_platform_off_target(from: Vector2):
    var closest = Vector2(-200,-200)
    var cdist = INF
    for c in $Spawns/PlatformOff.get_children():
        var dist = from.distance_squared_to(c.position)
        if dist < cdist:
            cdist = dist
            closest = c.position
    return closest

func get_train_target():
    return $Spawns/Train.get_children().pick_random().position

func close_doors():
    # close doors
    $Doors/DoorAnim.play("doors_close")

func train_depart():
    for p in passagiere:
        p.set_wait()
    game_state = GameState.DEPART
    $UI/Countdown/TimerNextLevel.start()
    
    spawn_platform()

func train_arrive():
    if round >= max_rounds:
        $UI/Rounds/RoundsLabel.text = "6/6"
        return
    
    round += 1
    train_spawns = train_spawns_round[round - 1]
    platform_spawns = platform_spawns_round[round - 1]
    $UI/Rounds/RoundsLabel.text = str(round) + "/" + str(max_rounds)
    
    # after closed doors
    game_state = GameState.PLAY
    for i in range(len(passagiere) - 1, -1, -1):
        var p = passagiere[i]
        if p.is_in_train():
            # despawn passagners on train
            p.queue_free()
            passagiere.remove_at(i)
        else:
            p.look_alive()
    spawn_train()
    $Doors/DoorAnim.play("doors_open")
    $UI/Countdown/TimerDepart.start()
    $UI/Countdown/TimerDoor.start()

func spawn_platform():
    var platform_count = 0
    for p in passagiere:
        if !p.is_in_train():
            platform_count+=1
            
    var dynamics = ceili(randf() * 0.5 * platform_count)
    
    var send_away = max(platform_count - platform_spawns, 0) + dynamics
    var call_up   = max(platform_spawns - platform_count, 0) + dynamics
    
    if round >= max_rounds:
        send_away = len(passagiere)
        call_up = 0
    
    for p in passagiere:
        if send_away <= 0:
            break
        if !p.is_in_train():
            p.leave_station()
            send_away -= 1
    call_up -= send_away
    
    for i in range(call_up):
        var spawn_pos = get_platform_off_target_random()
        var new_pass = preload("res://scenes/passagier.tscn").instantiate()
        new_pass.position = spawn_pos
        $Passagiere.add_child(new_pass)
    
func spawn_train():
    for i in range(train_spawns):
        var spawn_pos = get_train_target()
        var new_pass: Passagier = preload("res://scenes/passagier.tscn").instantiate()
        new_pass.position = spawn_pos
        new_pass.state = Passagier.PState.EXIT
        $Passagiere.add_child(new_pass)
