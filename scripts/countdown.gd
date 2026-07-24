extends Node2D

@onready var label = $TimeLabel
@onready var timer = $TimerDepart
@onready var timer2 = $TimerNextLevel

func _process(delta: float) -> void:
    label.text = str(floori(timer.time_left + timer2.time_left)) + "s"
    
