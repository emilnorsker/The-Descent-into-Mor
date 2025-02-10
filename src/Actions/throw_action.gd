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
    var damage_type = get_damage_type()
    
    target.body_component.apply_wound(Constants.BodyPart.CHEST, damage_type, damage)
    performer.inventory_component.remove_item(item)
    return true

func get_damage_type() -> String:
    var damage_type = "blunt"
    if item.damage_type:
        damage_type = item.damage_type.type
    return damage_type

func get_damage() -> int:
    if item.weapon:
        return item.weapon.damage
    if item.weight:
        return ceil(item.weight.weight * 0.01)
    return 1

func get_range() -> int:
    var weight = item.weight.weight if item.weight else 1.0
    return max(1, 10 - ceil(weight * 2))

func is_valid() -> bool:
    if not target or not item:
        return false
        
    var distance = (target.grid_position - performer.grid_position).length()
    return distance <= get_range() 