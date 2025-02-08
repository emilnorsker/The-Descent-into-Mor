class_name PickupAction
extends Action


func perform() -> bool:
	var inventory: InventoryComponent = entity.inventory_component
	var map_data: MapData = get_map_data()
	
	for item in map_data.get_items():
		if entity.grid_position == item.grid_position:
			if inventory.items.size() >= inventory.capacity:
				SignalBus.message_sent.emit("Your inventory is full.", ColorPallete.IMPOSSIBLE)
				return false
			
			map_data.entities.erase(item)
			item.get_parent().remove_child(item)
			inventory.items.append(item)
			SignalBus.message_sent.emit(
				"You picked up the %s!" % item.get_entity_name(),
				Color.WHITE
			)
			return true
	
	SignalBus.message_sent.emit("There is nothing here to pick up.", ColorPallete.IMPOSSIBLE)
	return false
