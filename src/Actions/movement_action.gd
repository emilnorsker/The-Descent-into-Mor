@tool
class_name MovementAction
extends Action


func perform() -> bool:
    var destination: Vector2i = get_destination()
    
    if not GameMap.get_blocking_entity_at_location(destination):
        var offset = target.grid_position - performer.grid_position
        performer.move(offset)
        return true
    return false
    
