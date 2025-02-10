@tool
class_name ActionWithDirection
extends Action

var offset: Vector2i

func _init(entity: Entity, dx: int, dy: int) -> void:
    super(entity)
    offset = Vector2i(dx, dy)

func get_destination() -> Vector2i:
    return entity.grid_position + offset 