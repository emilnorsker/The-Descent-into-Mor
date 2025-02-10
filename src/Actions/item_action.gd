@tool
class_name ItemAction
extends Action

const EquipAction = preload("res://src/Actions/equip_action.gd")

var item: Entity
var target_position: Vector2i

func _init(performer: Entity, item: Entity, target_position = null) -> void:
    var target = GameMap.get_actor_at_location(target_position) if target_position else performer
    super(performer, target)
    self.item = item
    if not target_position is Vector2i:
        target_position = performer.grid_position
    self.target_position = target_position

func get_target_actor() -> Entity:
    return GameMap.get_actor_at_location(target_position)

func perform() -> bool:
    if item == null:
        return false
        
    # Try to use item based on its components
    if item.item_component:
        return EquipAction.new(performer, item).perform()
    elif item.consumable_component:
        return item.consumable_component.activate(self)
    else:
        # Trying to use an invalid item causes self-damage
        var body = performer.body
        if body and item.material:
            var material = item.material
            if material.get_is_slippery():
                # Roll grip check
                var grip_check = randi() % 6 + 1
                if grip_check < 4:  # Failed check
                    item.drop()
                    return false
        return true
