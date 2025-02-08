class_name Map
extends Node2D

# Node references
@onready var floor_layer: TileMapLayer = $Floor
@onready var feature_layer: TileMapLayer = $Features
@onready var fixture_layer: TileMapLayer = $Fixtures

var _blueprint_cache: Dictionary = {}
# Entity tracking
var entities_by_position: Dictionary = {}  # Vector2i -> Array[Entity]
var active_entities: Array[Entity] = []    # All non-terrain entities
var blocking_positions: Dictionary = {}     # Vector2i -> bool
var opaque_positions: Dictionary = {}      # Vector2i -> bool
var player: Entity                        # Reference to the player entity

# Signals
signal entity_added(entity: Entity, pos: Vector2i)
signal entity_removed(entity: Entity, pos: Vector2i)
signal entity_moved(entity: Entity, from_pos: Vector2i, to_pos: Vector2i)
signal position_contents_changed(pos: Vector2i)

func _ready() -> void:
    # Ensure we have our required nodes
    assert(floor_layer != null, "Map must have a Floor layer!")
    assert(feature_layer != null, "Map must have a Features layer!")
    assert(fixture_layer != null, "Map must have a Fixtures layer!")
    
    # Register as current map
    GameMap.current_map = self

# Entity Management
func register_entity(entity: Entity, pos: Vector2i) -> void:
    if not pos in entities_by_position:
        entities_by_position[pos] = []
    entities_by_position[pos].append(entity)
    
    # Update lookup dictionaries
    if entity.is_blocking_movement():
        blocking_positions[pos] = true
    if entity.blocks_sight():
        opaque_positions[pos] = true
    
    # Track if not terrain
    if entity.type != Entity.EntityType.TERRAIN:
        active_entities.append(entity)
    
    entity_added.emit(entity, pos)
    position_contents_changed.emit(pos)

func remove_entity(entity: Entity, pos: Vector2i) -> void:
    if pos in entities_by_position:
        entities_by_position[pos].erase(entity)
        if entities_by_position[pos].is_empty():
            entities_by_position.erase(pos)
    
    # Update lookup dictionaries
    _update_position_flags(pos)
    
    # Remove from tracking if not terrain
    if entity.type != Entity.EntityType.TERRAIN:
        active_entities.erase(entity)
    
    entity_removed.emit(entity, pos)
    position_contents_changed.emit(pos)

func move_entity(entity: Entity, from_pos: Vector2i, to_pos: Vector2i) -> void:
    remove_entity(entity, from_pos)
    register_entity(entity, to_pos)
    entity_moved.emit(entity, from_pos, to_pos)

# Position Queries
func get_entities_at(pos: Vector2i) -> Array[Entity]:
    var entities: Array[Entity] = []
    
    # Get floor entity
    var floor_entity = _get_tile_entity(floor_layer, pos)
    if floor_entity:
        entities.append(floor_entity)
    
    # Get feature entity
    var feature_entity = _get_tile_entity(feature_layer, pos)
    if feature_entity:
        entities.append(feature_entity)
    
    # Get fixture entity
    var fixture_entity = _get_tile_entity(fixture_layer, pos)
    if fixture_entity:
        entities.append(fixture_entity)
    
    # Get dynamic entities
    if pos in entities_by_position:
        entities.append_array(entities_by_position[pos])
    
    return entities

func get_entities_of_type_at(pos: Vector2i, type: Entity.EntityType) -> Array[Entity]:
    return get_entities_at(pos).filter(func(e): return e.type == type)

func is_position_blocked(pos: Vector2i) -> bool:
    return blocking_positions.get(pos, false)

func get_movement_cost_at(pos: Vector2i) -> float:
    var total_cost = 1.0
    for entity in get_entities_at(pos):
        if entity.has_method("get_movement_cost"):
            total_cost *= entity.get_movement_cost()
    return total_cost

# Helper Methods
func _update_position_flags(pos: Vector2i) -> void:
    blocking_positions[pos] = false
    opaque_positions[pos] = false
    
    if pos in entities_by_position:
        for entity in entities_by_position[pos]:
            if entity.is_blocking_movement():
                blocking_positions[pos] = true
            if entity.blocks_sight():
                opaque_positions[pos] = true

func _get_tile_entity(layer: TileMapLayer, pos: Vector2i) -> Entity:
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