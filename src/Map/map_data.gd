class_name MapData
extends RefCounted

var map: Map
var player: Entity

func _init(map: Map) -> void:
	self.map = map

func register_blocking_entity(entity: Entity) -> void:
	map.register_entity(entity, entity.grid_position)

func unregister_blocking_entity(entity: Entity) -> void:
	map.remove_entity(entity, entity.grid_position)

func get_blocking_entities_at(pos: Vector2i) -> Array[Entity]:
	return map.get_entities_at(pos).filter(func(e): return e.is_blocking_movement())

func is_position_blocked(pos: Vector2i) -> bool:
	return map.is_position_blocked(pos)

func get_movement_cost_at(pos: Vector2i) -> float:
	return map.get_movement_cost_at(pos)

func get_entities_at(pos: Vector2i) -> Array[Entity]:
	return map.get_entities_at(pos)

func get_entities_of_type_at(pos: Vector2i, type: Entity.EntityType) -> Array[Entity]:
	return map.get_entities_of_type_at(pos, type) 