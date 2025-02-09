class_name MovementAction
extends ActionWithDirection


func perform() -> bool:
	var destination: Vector2i = get_destination()
	
	if not GameMap.get_blocking_entity_at_location(destination):
		entity.move(offset)
		return true
	return false
	
