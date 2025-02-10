extends Resource
class_name WeightComponentBlueprint

@export var weight: float = 1.0
@export var affects_balance: bool = false
@export var balance_penalty: float = 0.0

func get_component_name() -> String:
    return "WeightComponent"

func get_properties() -> Dictionary:
    return {
        "weight": weight,
        "affects_balance": affects_balance,
        "balance_penalty": balance_penalty
    } 