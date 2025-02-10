extends Node
class_name Action

var performer: Entity
var target: Entity

func _init(p_performer: Entity, p_target: Entity) -> void:
    performer = p_performer
    target = p_target

func perform() -> bool:
    return false  # Base class does nothing

func get_range() -> int:
    return 1  # Default range is 1 tile

func is_valid() -> bool:
    return true  # Base class assumes valid

func get_cost() -> int:
    return 1  # Default cost is 1 action point


