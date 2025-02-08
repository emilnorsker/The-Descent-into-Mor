class_name PickupAction
extends Action


func perform() -> bool:
	var inventory: InventoryComponent = entity.inventory_component
	
	for item in GameMap.get_entities_of_type_at(entity.grid_position, Entity.EntityType.ITEM):
		if entity.grid_position == item.grid_position:
			if inventory.is_full():
				SignalBus.message_sent.emit("Your inventory is full.", ColorPallete.IMPOSSIBLE)
				return false
			
			GameMap.erase(item, item.grid_position)
			item.get_parent().remove_child(item)
			inventory.add(item)
			SignalBus.message_sent.emit(
				"You picked up the %s!" % item.get_entity_name(),
				Color.WHITE
			)
			return true
	
	SignalBus.message_sent.emit("There is nothing here to pick up.", ColorPallete.IMPOSSIBLE)
	return false
