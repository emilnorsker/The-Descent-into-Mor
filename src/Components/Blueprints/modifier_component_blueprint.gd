@tool
class_name ModifierComponentBlueprint
extends ComponentBlueprint

@export var states: Array[ModifierComponent.StatusEffect] = []

func _init() -> void:
    super()
    component_type = "modifiers"
