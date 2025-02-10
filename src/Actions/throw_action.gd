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
    
    target.components.body.apply_wound(Constants.WoundType.LIGHT, Constants.BodyPart.CHEST, damage)
    performer.components.inventory.remove_item(item)
    return true

func get_damage() -> int:
    if item.components.item and item.components.item.power_bonus > 0:
        return performer.components.combat.get_power() + item.components.item.power_bonus
    if item.components.weight:
        var weight = item.components.weight.get_weight()
        return int(ceil(weight * 0.1))  # 50 weight = 5 damage
    return 1

func get_range() -> int:
    if item.components.item and item.components.item.range > 0:
        return item.components.item.range
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