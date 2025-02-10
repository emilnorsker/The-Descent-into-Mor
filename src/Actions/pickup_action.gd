@tool
class_name PickupAction
extends Action


func perform() -> bool:
    var item = GameMap.get_entities_of_type_at(entity.grid_position, Entity.EntityType.ITEM)[0]
    if not item:
        return false
    
    if entity.components.inventory.add(item):
        SignalBus.message_sent.emit(
            "%s picked up %s" % [entity.entity_name, item.entity_name],
            Color.WHITE
        )
        GameMap.erase(item)
        return true
    
    return false
