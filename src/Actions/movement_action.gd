@tool
class_name MovementAction
extends Action


func perform() -> bool:
    
    if not GameMap.get_blocking_entity_at_location(target.grid_position):
        var offset = target.grid_position - performer.grid_position
        performer.move(offset)
        return true
    return false
    
