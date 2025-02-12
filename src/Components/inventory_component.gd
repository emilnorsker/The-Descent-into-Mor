class_name InventoryComponent
extends Component

signal item_added(item: Entity)
signal item_removed(item: Entity)
signal item_dropped(item: Entity)

var _items: Array[Entity] = []
var _capacity: int = 10
var _weight_limit: float = 100.0

func _init() -> void:
    super()

func setup_from_dict(data: Dictionary) -> InventoryComponent:
    if data.has("capacity"):
        _capacity = data.capacity
    if data.has("weight_limit"):
        _weight_limit = data.weight_limit
    if data.has("items"):
        _items = data.items
    return self

func setup_from_blueprint(blueprint: Resource) -> InventoryComponent:
    if blueprint:
        # Convert blueprint to dictionary and use setup_from_dict
        var data = {}
        if blueprint.has_method("get_capacity"):
            data["capacity"] = blueprint.get_capacity()
        if blueprint.has_method("get_weight_limit"):
            data["weight_limit"] = blueprint.get_weight_limit()
        if blueprint.has_method("get_items"):
            data["items"] = blueprint.get_items()
        return setup_from_dict(data)
    return self

func add_item(item: Entity) -> void:
    if not item in _items and _items.size() < _capacity:
        var total_weight = get_total_weight() + item.weight.get_weight() if item.has_component("weight") else 0.0
        if total_weight <= _weight_limit:
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

func get_weight_limit() -> float:
    return _weight_limit

func get_total_weight() -> float:
    var total: float = 0.0
    for item in _items:
        if item.has_component("weight"):
            total += item.weight.get_weight()
    return total
