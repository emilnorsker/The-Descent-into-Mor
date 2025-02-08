class_name MapData
extends Resource

signal entity_placed(entity: Entity)

var entities: Array[Entity] = []
var pathfinder: AStar2D
var player: Entity

func get_items() -> Array[Entity]:
	return entities.filter(func(e): return e.type == Entity.EntityType.ITEM)

func get_tile(pos: Vector2i) -> Entity:
	for entity in entities:
		if entity.grid_position == pos and entity.type == Entity.EntityType.TERRAIN:
			return entity
	return null 