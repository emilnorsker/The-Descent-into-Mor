@tool
extends Action
class_name ThrowAction

var item: Entity
var target_part: BodyComponent.BodyPart

func _init(performer: Entity, target: Entity, item: Entity, target_part: BodyComponent.BodyPart = BodyComponent.BodyPart.NONE) -> void:
    super(performer, target)
    self.item = item
    var parts = BodyComponent.BodyPart
    if target_part == parts.NONE:
        target_part = parts[
            parts.keys()[
                randi_range(1, parts.size() - 1)
            ]
        ]
    self.target_part = target_part

func perform() -> bool:
    if not is_valid():
        return false
        
    var damage = get_damage()
    var severity = target.body.get_wound_severity(damage, target_part)
    
    print("throwing ", item.entity_name, " with damage ", damage, " to ", BodyComponent.BodyPart.keys()[target_part])
    
    target.body.apply_wound(severity, target_part)
    performer.inventory.remove_item(item)
    return true

func get_damage() -> int:
    var damage = 0
    
    # Add power bonus only for actual weapons
    if item.item and item.item.power_bonus > 0:
        damage += item.item.power_bonus
    
    # Add weight-based damage
    if item.weight:
        var weight = item.weight.get_weight()
        damage += int(ceil(weight * 0.1))  # 50 weight = 5 damage
    
        print("thrown with weightdamage: ", damage)

    return max(1, damage)  # Minimum 1 damage

func get_range() -> int:
    var base_range = 10
    if item.weight:
        var weight = item.weight.get_weight()
        base_range = int(10 - ceil(weight * 0.5))  # 0.5 weight = 9 range
    return max(1, base_range)

func is_valid() -> bool:
    if not target or not item:
        return false
        
    var distance = (target.grid_position - performer.grid_position).length()
    return distance <= get_range()
