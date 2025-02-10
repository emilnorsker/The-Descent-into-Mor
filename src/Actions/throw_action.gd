@tool
extends Action
class_name ThrowAction

var item: Entity

func _init(p_performer: Entity, p_target: Entity, p_item: Entity) -> void:
    super(p_performer, p_target)
    item = p_item

func perform() -> bool:
    if not is_valid():
        return false
        
    var damage = get_damage()
    
    # Thrown weapons always cause light wounds
    target.components.body.apply_wound(Constants.WoundType.LIGHT, Constants.BodyPart.CHEST, 1)
    performer.components.inventory.remove_item(item)
    return true

func get_damage() -> int:
    var damage = 0
    
    # Add power bonus only for actual weapons
    if item.components.item and item.components.item.power_bonus > 0:
        damage += performer.components.combat.power + item.components.item.power_bonus
    
    # Add weight-based damage
    if item.components.weight:
        var weight = item.components.weight.get_weight()
        damage = int(ceil(weight * 0.1))  # 50 weight = 5 damage
    
    return max(1, damage)  # Minimum 1 damage

func get_range() -> int:
    var base_range = 10
    if item.components.weight:
        var weight = item.components.weight.get_weight()
        base_range = int(10 - ceil(weight * 0.5))  # 0.5 weight = 9 range
    return max(1, base_range)

func is_valid() -> bool:
    if not target or not item:
        return false
        
    var distance = (target.grid_position - performer.grid_position).length()
    return distance <= get_range()

func get_wound_type(damage: int) -> int:
    if damage <= 0:
        return Constants.WoundType.LIGHT
    elif damage <= 3:
        return Constants.WoundType.MODERATE
    elif damage <= 6:
        return Constants.WoundType.SEVERE
    elif damage <= 9:
        return Constants.WoundType.CRITICAL
    else:
        return Constants.WoundType.FATAL

func get_wound_severity(damage: int) -> int:
    # Calculate severity based on damage
    # Severity ranges from 1 to 5
    if damage <= 0:
        return 1
    elif damage <= 3:
        return 2
    elif damage <= 6:
        return 3
    elif damage <= 9:
        return 4
    else:
        return 5 