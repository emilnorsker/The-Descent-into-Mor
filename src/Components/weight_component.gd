class_name WeightComponent
extends Component

var weight: float = 1.0
var affects_balance: bool = false
var balance_penalty: float = 0.0

func _init() -> void:
    super()

func setup_from_blueprint(blueprint: Resource) -> WeightComponent:
    if blueprint:
        weight = blueprint.weight
        affects_balance = blueprint.affects_balance
        balance_penalty = blueprint.balance_penalty

    return self

func get_weight() -> float:
    var base_weight = weight
    var parent = get_parent() as Entity
    if parent and parent.components.combat_modifier:
        if parent.components.combat_modifier.has_state(Constants.StatusEffect.MUD_COVERED):
            base_weight *= 1.5  # Mud increases weight by 50%
    return base_weight

func get_affects_balance() -> bool:
    return affects_balance or get_weight() > 5.0

func get_balance_penalty() -> float:
    var penalty = balance_penalty
    if get_weight() > 5.0:
        penalty += (get_weight() - 5.0) * 0.1
    return penalty

func get_movement_penalty() -> float:
    var base_penalty = 0.0
    var current_weight = get_weight()
    
    if current_weight > 10.0:
        base_penalty = (current_weight - 10.0) * 0.1
    
    var parent = get_parent() as Entity
    if parent and parent.combat_modifier:
        if parent.combat_modifier.has_state(Constants.StatusEffect.MUD_COVERED):
            base_penalty *= 1.5  # Mud increases movement penalty
    
    return base_penalty 