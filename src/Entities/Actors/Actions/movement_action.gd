class_name MovementAction
extends ActionWithDirection


func perform() -> bool:
	var destination: Vector2i = get_destination()
	
	var map_data: MapData = get_map_data()
	var destination_tile: Tile = map_data.get_tile(destination)
	if not destination_tile or not destination_tile.is_walkable() or get_blocking_entity_at_destination():
		if entity == get_map_data().player:
			SignalBus.message_sent.emit("That way is blocked.", ColorPallete.IMPOSSIBLE)
		return false
	entity.move(offset)
	return true
	
