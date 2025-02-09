class_name ConsumableComponent
extends Component

func _init(blueprint: Resource = null) -> void:
	super._init(blueprint)

func get_action(consumer: Entity) -> Action:
	return ItemAction.new(consumer, entity)

func activate(action: ItemAction) -> bool:
	return false

func consume(consumer: Entity) -> void:
	var inventory: InventoryComponent = consumer.inventory_component
	inventory.drop(entity)
	entity.queue_free()

func get_targeting_radius() -> int:
	return data.targeting_radius if data.has_method("targeting_radius") else -1
