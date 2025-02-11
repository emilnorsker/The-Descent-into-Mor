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
        
    # ItemAction is used for consuming items
    if item.components.consumable:
        return item.components.consumable.activate(self)
    
    # If the item is not consumable, trying to consume it causes head damage
    if performer.components.body:
        performer.components.body.apply_wound(BodyComponent.WoundType.LIGHT, BodyComponent.BodyPart.HEAD)
    return false
