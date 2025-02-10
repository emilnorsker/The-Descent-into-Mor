class_name ConsumableComponent
extends Component

var targeting_radius: int = -1

func _init() -> void:
    super()

func setup_from_blueprint(blueprint: Resource) -> ConsumableComponent:
    if blueprint and blueprint.has_method("targeting_radius"):
        targeting_radius = blueprint.targeting_radius

    return self

func get_action(consumer: Entity) -> Action:
    return ItemAction.new(consumer, entity)

func activate(action: ItemAction) -> bool:
    return false

func consume(consumer: Entity) -> void:
    var inventory: InventoryComponent = consumer.components.inventory
    inventory.drop(entity)
    entity.queue_free()

func get_targeting_radius() -> int:
    return targeting_radius
