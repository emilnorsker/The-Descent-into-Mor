@tool
class_name ConsumableComponent
extends Component

var targeting_radius: int = -1

func _init() -> void:
    super()

func setup_from_dict(data: Dictionary) -> Component:
    if data.has("targeting_radius"):
        targeting_radius = data.targeting_radius
    return self

func setup_from_blueprint(blueprint: Resource) -> ConsumableComponent:
    if blueprint and blueprint.has_method("targeting_radius"):
        targeting_radius = blueprint.targeting_radius

    return self

func activate(action: ConsumeAction) -> bool:
    return false

func consume(consumer: Entity) -> bool:
    var inventory: InventoryComponent = consumer.inventory
    inventory.drop(entity)
    return true
func get_targeting_radius() -> int:
    return targeting_radius
