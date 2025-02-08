class_name InventoryComponent
extends Component

func items() -> Array[Entity]:
	return data.items

func capacity() -> int:
	return data.capacity

func drop(item: Entity) -> void:
	data.items.erase(item)

	push_error("TODO implement drop")
	SignalBus.message_sent.emit("You dropped the %s." % item.get_entity_name(), Color.WHITE)
