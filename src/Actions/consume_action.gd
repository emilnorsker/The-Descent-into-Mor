@tool
class_name ConsumeAction extends Action

var consumable: Entity

func _init(performer: Entity, item: Entity) -> void:
    super(performer, item)
    consumable = item

func perform() -> bool:
    if consumable == null:
        return false
        
    # ItemAction is used for consuming items
    if consumable.components.consumable:
        return consumable.components.consumable.consume(performer)
    
    # If the item is not consumable, trying to consume it causes head damage
    if performer.components.body:
        performer.components.body.apply_wound(BodyComponent.WoundType.LIGHT, BodyComponent.BodyPart.HEAD)
    
    return false
