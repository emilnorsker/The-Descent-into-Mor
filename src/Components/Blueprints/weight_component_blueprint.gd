@tool
class_name WeightComponentBlueprint
extends ComponentBlueprint

var weight: float = 1.0
var affects_balance: bool = false
var balance_penalty: float = 0.0

func _init() -> void:
    super()
    component_type = "weight"
