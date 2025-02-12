@tool
class_name CombatComponentBlueprint
extends ComponentBlueprint

var max_hp: int = 30
var power: int = 5
var defense: int = 2

func _init() -> void:
    super()
    component_type = "combat" 