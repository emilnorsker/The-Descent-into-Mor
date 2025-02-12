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
    if consumable.consumable:
        return consumable.consumable.consume(performer)
    
    # If the item is not consumable, trying to consume it causes head damage
    if performer.body:
        performer.body.apply_wound(BodyComponent.WoundType.LIGHT, BodyComponent.BodyPart.HEAD)
    
    return false
