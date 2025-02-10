class_name InventoryComponent
extends Component

signal item_added(item: Entity)
signal item_removed(item: Entity)
signal item_dropped(item: Entity)

var _items: Array[Entity] = []
var _capacity: int = 10

func _init() -> void:
    super()

func setup_from_blueprint(blueprint: Resource) -> InventoryComponent:
    if blueprint:
        if blueprint.has_method("capacity"):
            _capacity = blueprint.capacity
        if blueprint.has_method("items"):
            _items = blueprint.items

    return self

func add_item(item: Entity) -> void:
    if not item in _items and _items.size() < _capacity:
        _items.append(item)
        item_added.emit(item)

func remove_item(item: Entity) -> void:
    if item in _items:
        _items.erase(item)
        item_removed.emit(item)

func drop(item: Entity) -> void:
    if item in _items:
        _items.erase(item)
        item.grid_position = get_parent().grid_position
        GameMap.register_entity(item, item.grid_position)
        item_dropped.emit(item)

func items() -> Array[Entity]:
    return _items

func has_item(item: Entity) -> bool:
    return item in _items

func get_capacity() -> int:
    return _capacity
