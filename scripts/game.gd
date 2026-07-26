extends Node2D
class_name Game


var passagiere: Array[Passagier]

@export var player: Player

@export var passanger_force = 1.0
@export var passanger_force_cutoff = 32.0

enum GameState { MAIN_MENU, NEXT_LEVEL, PLAY, DEPART, GAME_OVER }
@export var game_state: GameState = GameState.NEXT_LEVEL

@export var train_spawns = 10
@export var platform_spawns = 10

@export var train_spawns_round = [6, 7, 10, 5, 8, 5, 15, 15, 20, 15]
@export var platform_spawns_round = [6, 7, 6, 11, 7, 8, 10, 16, 16, 23]

@export var round_ = 0
@export var max_rounds = 10
var pissed_people = 0

@export var score = 0:
    set(val):
        score = val
        update_score()

@export var pissometer = 0:
    set(val):
        pissometer = val
        update_score()
@export var max_piss = 10
@export var unpiss_per_round = 10

var clean_rounds = 0

func _ready():
    $Train/AnimationPlayer.play("train_gone")
    $UI/MainMenu.visible = true
    $UI/Pissometer.visible = false
    spawn_platform()

func _input(event):
    if event.is_action("StartGame") and game_state == GameState.MAIN_MENU:
        start_game()
    if event.is_action("StartGame") and game_state == GameState.GAME_OVER:
        get_tree().reload_current_scene()

func start_game():
    $UI/Rounds/RoundsLabel.text = str(round_) + "/" + str(max_rounds)
    game_state = GameState.NEXT_LEVEL
    $UI/Countdown/TimerNextLevel.start()
    $UI/MainMenu.visible = false
    $UI/Pissometer.visible = true
    between_rounds()

func _process(delta):
    if $CheatManager.cheat_mode:
        if Input.is_key_pressed(KEY_0):
            for p in passagiere:
                p.find_child("NavigationAgent2D").debug_enabled = true

func _physics_process(delta):
    integrate_passanger_forces(delta)

func update_score():
    $UI/Score/ScoreLabel.text = str(score)
    $UI/Pissometer/ProgressBar.max_value = max_piss
    var tween = get_tree().create_tween()
    tween.tween_property($UI/Pissometer/ProgressBar, "value", pissometer, 1.0)

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

var _platform_target_index = randi_range(0,29)
func get_platform_target():
    _platform_target_index = (_platform_target_index + 5) % 29
    return $Spawns/Platform.get_child(_platform_target_index).position

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

func get_train_target_at_door():
    return $Spawns/Train.find_children("Door*").pick_random().position

func close_doors():
    # close doors
    $Train/Doors/DoorAnim.play("doors_close")

func train_depart():
    print("Train Depart")
    for p in passagiere:
        p.set_wait()
    game_state = GameState.DEPART
    $UI/Countdown/TimerNextLevel.start(10)
    $UI/Countdown/TimerBetweenRounds.start()
    print(str(pissed_people) + " people are pissed")
    if pissed_people > 0:
        pissometer = clamp(pissometer + min(pissed_people, 6), 0, max_piss)
        shake_tween($UI/Pissometer/Pissed)
    else:
        pissometer = clamp(pissometer - 3, 0, max_piss)
        shake_tween($UI/Pissometer/Happy)
        clean_rounds += 1

    pissed_people = 0
    if pissometer == max_piss:
        game_over(false)

    if player.position.y < -92:
        player.death()

    spawn_platform()

func between_rounds():
    print("Between rounds")
    for p in $Train/Viz/Passengers.get_children():
        # despawn passagners on train
        p.despawn()
    if game_state == GameState.GAME_OVER:
        return
    spawn_train()
    $Train/AnimationPlayer.play("train_arrive")

func train_arrive():
    print("Train arrive")
    if round_ >= max_rounds:
        $UI/Rounds/RoundsLabel.text = "10/10"
        return

    round_ += 1
    train_spawns = train_spawns_round[round_ - 1]
    platform_spawns = platform_spawns_round[round_ - 1]
    $UI/Rounds/RoundsLabel.text = str(round_) + "/" + str(max_rounds)

    game_state = GameState.PLAY

    for p in passagiere:
        p.look_alive()

    $Train/Doors/DoorAnim.play("doors_open")
    $UI/Countdown/TimerDepart.start()
    $UI/Countdown/TimerDoor.start()

func spawn_platform():
    var platform_count = 0
    for p in passagiere:
        if !p.is_in_train():
            platform_count+=1

    var dynamics = ceili(randf() * 0.5 * platform_count)
    if round_ == 7:
        dynamics = 0

    var send_away = max(platform_count - platform_spawns, 0) + dynamics
    var call_up   = max(platform_spawns - platform_count, 0) + dynamics

    if round_ >= max_rounds:
        game_over(true)

    if game_state == GameState.GAME_OVER:
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
        new_pass.type = [0,0,0,0,0,0,1,2].pick_random()
        $Passagiere.add_child(new_pass)

func spawn_train():
    for i in range(train_spawns):
        var spawn_pos = get_train_target()
        var new_pass: Passagier = preload("res://scenes/passagier.tscn").instantiate()
        new_pass.state = Passagier.PState.WAIT_TRAIN_ARRIVE
        new_pass.type = [0,0,0,0,0,0,1,2].pick_random()
        if round_ == 6:
            new_pass.type = 1
        if new_pass.type == 1:
            spawn_pos = get_train_target_at_door()
        $Train/Viz/Passengers.add_child(new_pass)
        new_pass.position = spawn_pos

func game_over(victory: bool):
    if game_state == GameState.GAME_OVER:
        return
    game_state = GameState.GAME_OVER
    print("Game Over")
    $UI/Countdown/TimerNextLevel.stop()
    $UI/GameOverMenu.visible = true
    $UI/GameOverMenu/Score.text = str(score)
    if victory:
        $UI/GameOverMenu/Victory.visible = true
        $UI/GameOverMenu/Victory/Round2.text = str(clean_rounds) + "/" + str(max_rounds)
    else:
        $UI/GameOverMenu/Fail.visible = true
        $UI/GameOverMenu/Victory/Round2.text = str(round_) + "/" + str(max_rounds)

func shake_tween(object):
    var tween = create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(object, "scale", Vector2(2,2), 0.5)
    tween.tween_property(object, "scale", Vector2(1,1), 0.5)
    tween.tween_property(object, "scale", Vector2(2,2), 0.5)
    tween.tween_property(object, "scale", Vector2(1,1), 0.5)
    tween.tween_property(object, "scale", Vector2(2,2), 0.5)
    tween.tween_property(object, "scale", Vector2(1,1), 0.5)
