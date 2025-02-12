class_name WeightComponent
extends Component

const DEFAULT_BLUEPRINT = preload("res://new_assets/blueprints/weights/basic.tres")

var weight: float = 1.0
var affects_balance: bool = false
var balance_penalty: float = 0.0

func _init(blueprint: Resource = null) -> void:
    super()
    name = "WeightComponent"
    
    if not blueprint:
        blueprint = DEFAULT_BLUEPRINT
    
    if blueprint:
        if not blueprint is WeightComponentBlueprint:
            push_error("Invalid blueprint type provided to WeightComponent")
            return
            
        weight = blueprint.weight
        affects_balance = blueprint.affects_balance
        balance_penalty = blueprint.balance_penalty

# ... rest of the file unchanged ... 