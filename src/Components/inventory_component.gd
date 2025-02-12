@tool
class_name InventoryComponent extends Component

const DEFAULT_BLUEPRINT = preload("res://new_assets/blueprints/inventory/basic.tres")

signal item_added(item: Entity)
signal item_removed(item: Entity)
signal item_dropped(item: Entity)

var capacity: int = 10
var items: Array[Entity] = []
var weight_limit: float = 100.0

func _init(blueprint: Resource = null) -> void:
    super()
    name = "InventoryComponent"
    
    if not blueprint:
        blueprint = DEFAULT_BLUEPRINT
    
    if blueprint:
        if not blueprint is InventoryComponentBlueprint:
            push_error("Invalid blueprint type provided to InventoryComponent")
            return
            
        capacity = blueprint.capacity
        # Create actual entities from the blueprint items
        for item_blueprint in blueprint.items:
            var item = Entity.new(item_blueprint, Vector2i.ZERO)
            items.append(item)

func add_item(item: Entity) -> void:
    if not item in items and items.size() < capacity:
        var total_weight = get_total_weight() + item.weight.get_weight()
        if total_weight <= weight_limit:
            items.append(item)
            item_added.emit(item)

func remove_item(item: Entity) -> void:
    if item in items:
        items.erase(item)
        item_removed.emit(item)

func drop(item: Entity) -> void:
    if item in items:
        items.erase(item)
        item.grid_position = get_parent().grid_position
        GameMap.register_entity(item, item.grid_position)
        item_dropped.emit(item)

func get_items() -> Array[Entity]:
    return items

func has_item(item: Entity) -> bool:
    return item in items

func get_capacity() -> int:
    return capacity

func get_weight_limit() -> float:
    return weight_limit

func get_total_weight() -> float:
    var total: float = 0.0
    for item in items:
        total += item.weight.get_weight()
    return total
