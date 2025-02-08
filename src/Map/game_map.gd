@tool
class_name Map extends Node

var _current_map: Node
var current_map: Node:
	set(value):
		_current_map = value
		if _current_map:
			floor_layer = _current_map.get_node("Floor")
			feature_layer = _current_map.get_node("Features")
			fixture_layer = _current_map.get_node("Fixtures")
			_setup_layers()
	get:
		return _current_map

var floor_layer: TileMapLayer
var feature_layer: TileMapLayer
var fixture_layer: TileMapLayer

var _blueprint_cache: Dictionary = {}
var _entities: Array[Entity] = []
var active_entities: Array[Entity] = []    # All non-terrain entities
var _blocking_positions: Dictionary = {}    # Vector2i -> Array[Entity]
var opaque_positions: Dictionary = {}      # Vector2i -> bool
var player: Entity                        # Reference to the player entity

# Signals
signal entity_added(entity: Entity, pos: Vector2i)
signal entity_removed(entity: Entity, pos: Vector2i)
signal entity_moved(entity: Entity, from_pos: Vector2i, to_pos: Vector2i)
signal position_contents_changed(pos: Vector2i)

func _ready() -> void:
	# Get layer references if we're the autoload singleton
	if get_parent() == get_tree().root:
		floor_layer = $Floor
		feature_layer = $Features
		fixture_layer = $Fixtures
		_setup_layers()

func _setup_layers() -> void:
	assert(floor_layer != null, "Map must have a Floor layer!")
	assert(feature_layer != null, "Map must have a Features layer!")
	assert(fixture_layer != null, "Map must have a Fixtures layer!")

func register_entity(entity: Entity, position: Vector2i) -> void:
	if not entity in _entities:
		_entities.append(entity)
		
	if entity.is_blocking_movement():
		if not position in _blocking_positions:
			_blocking_positions[position] = []
		_blocking_positions[position].append(entity)
	
	match entity.type:
		Entity.EntityType.CORPSE:
			floor_layer.add_child(entity)
		Entity.EntityType.ITEM:
			feature_layer.add_child(entity)
		Entity.EntityType.ACTOR:
			feature_layer.add_child(entity)
		Entity.EntityType.TERRAIN:
			floor_layer.add_child(entity)
		Entity.EntityType.FIXTURE:
			fixture_layer.add_child(entity)
	
	entity_added.emit(entity, position)
	position_contents_changed.emit(position)

func erase(entity: Entity, position: Vector2i) -> void:
	_entities.erase(entity)
	
	if entity.is_blocking_movement() and position in _blocking_positions:
		_blocking_positions[position].erase(entity)
		if _blocking_positions[position].is_empty():
			_blocking_positions.erase(position)
	
	if entity.get_parent():
		entity.get_parent().remove_child(entity)
	
	entity_removed.emit(entity, position)
	position_contents_changed.emit(position)

func move_entity(entity: Entity, from_pos: Vector2i, to_pos: Vector2i) -> void:
	if entity.is_blocking_movement():
		if from_pos in _blocking_positions:
			_blocking_positions[from_pos].erase(entity)
			if _blocking_positions[from_pos].is_empty():
				_blocking_positions.erase(from_pos)
		
		if not to_pos in _blocking_positions:
			_blocking_positions[to_pos] = []
		_blocking_positions[to_pos].append(entity)
	
	entity_moved.emit(entity, from_pos, to_pos)
	position_contents_changed.emit(from_pos)
	position_contents_changed.emit(to_pos)

func get_entities_at(pos: Vector2i) -> Array[Entity]:
	return _entities.filter(func(e): return e.grid_position == pos)

func get_entities_of_type_at(pos: Vector2i, type: Entity.EntityType) -> Array[Entity]:
	return get_entities_at(pos).filter(func(e): return e.type == type)

func get_entities_in_radius(center: Vector2i, radius: int) -> Array[Entity]:
	return _entities.filter(func(e): return e.distance(center) <= radius)

func is_position_blocked(pos: Vector2i) -> bool:
	return pos in _blocking_positions and not _blocking_positions[pos].is_empty()

func get_movement_cost_at(pos: Vector2i) -> float:
	var total_cost = 1.0
	for entity in get_entities_at(pos):
		if entity.has_method("get_movement_cost"):
			total_cost *= entity.get_movement_cost()
	return total_cost

func get_blocking_entity_at_location(pos: Vector2i) -> Entity:
	var entities = get_entities_at(pos)
	for entity in entities:
		if entity.is_blocking_movement():
			return entity
	return null

func _update_position_flags(pos: Vector2i) -> void:
	var entities = get_entities_at(pos)
	var has_blocking = false
	
	for entity in entities:
		if entity.is_blocking_movement():
			has_blocking = true
			break
	
	if has_blocking and not pos in _blocking_positions:
		_blocking_positions[pos] = entities.filter(func(e): return e.is_blocking_movement())
	elif not has_blocking and pos in _blocking_positions:
		_blocking_positions.erase(pos)

func _get_tile_entity(layer: Node2D, pos: Vector2i) -> Entity:
	var tile_data = layer.get_cell_tile_data(pos)
	if not tile_data:
		return null
		
	# Get blueprint path from tile custom data
	var blueprint_path = tile_data.get_custom_data("blueprint_path")
	if not blueprint_path:
		push_warning("Tile at %s has no blueprint path" % pos)
		return null
	
	# Load or get cached blueprint
	var blueprint: EntityBlueprint
	if blueprint_path in _blueprint_cache:
		blueprint = _blueprint_cache[blueprint_path]
	else:
		blueprint = load(blueprint_path)
		if not blueprint:
			push_error("Failed to load blueprint: %s" % blueprint_path)
			return null
		_blueprint_cache[blueprint_path] = blueprint
	
	# Create entity from blueprint
	var entity = Entity.from_blueprint(blueprint, pos)
	return entity