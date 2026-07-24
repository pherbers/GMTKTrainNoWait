extends Node
class_name CheatManager

@export var cheat_trigger = "käfer"
@export var cheat_mode = false
var _cheat_entry = ""

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.is_pressed():
        var letter = OS.get_keycode_string(event.key_label).to_lower()
        _cheat_entry += letter
        if not cheat_trigger.to_lower().begins_with(_cheat_entry):
            _cheat_entry = ""
        if _cheat_entry == cheat_trigger:
            print("Cheats activated")
            cheat_mode = true
