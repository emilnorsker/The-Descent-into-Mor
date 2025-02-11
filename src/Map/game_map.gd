class_name Map extends Node

var floor_layer: TileMapLayer
var feature_layer: TileMapLayer
var fixture_layer: TileMapLayer

var _entities: = []
var active_entities: = [] 
var _blocking_positions: Dictionary = {} 
var opaque_positions: Dictionary = {} 
var player: Entity

# Signals
signal entity_added(entity: Entity, pos: Vector2i)
signal entity_removed(entity: Entity, pos: Vector2i)
signal entity_moved(entity: Entity, from_pos: Vector2i, to_pos: Vector2i)
signal position_contents_changed(pos: Vector2i)


func _ready() -> void:
    floor_layer = $Floor
    feature_layer = $Features
    fixture_layer = $Fixtures

func load_level(level: Level) -> void:
    clear()
    
    # Load floors
    for element in level.floors:
        var entity = Entity.new().setup_from_blueprint(element.blueprint, element.position)
        register_entity(entity, element.position)
    
    # Load surfaces
    for element in level.surfaces:
        var entity = Entity.new().setup_from_blueprint(element.blueprint, element.position)
        register_entity(entity, element.position)
    
    # Load objects
    for element in level.objects:
        var entity = Entity.new().setup_from_blueprint(element.blueprint, element.position)
        register_entity(entity, element.position)
    
    # Load items
    for element in level.items:
        var entity = Entity.new().setup_from_blueprint(element.blueprint, element.position)
        register_entity(entity, element.position)
    
    # Load entities
    for element in level.entities:
        var entity = Entity.new().setup_from_blueprint(element.blueprint, element.position)
        register_entity(entity, element.position)

func clear() -> void:
    # Remove all entities
    for entity in _entities.duplicate():
        erase(entity)
    
    _entities.clear()
    active_entities.clear()
    _blocking_positions.clear()
    opaque_positions.clear()
    player = null

func register_entity(entity: Entity, position: Vector2i) -> void:    
    # Add to correct layer first
    match entity.type:
        Entity.EntityType.CORPSE:
            floor_layer.add_child(entity)
        Entity.EntityType.ITEM:
            feature_layer.add_child(entity)
        Entity.EntityType.ACTOR:
            feature_layer.add_child(entity)
        Entity.EntityType.TERRAIN:
            if entity.get_parent() != floor_layer:
                feature_layer.add_child(entity)
            else:
                floor_layer.add_child(entity)
        Entity.EntityType.FIXTURE:
            fixture_layer.add_child(entity)
    
    if not entity in _entities:
        _entities.append(entity)
        # Sort entities by type to maintain correct stacking order
        # Order: TERRAIN (floor) -> TERRAIN (surface) -> FIXTURE -> ITEM -> ACTOR
        _entities.sort_custom(func(a: Entity, b: Entity) -> bool:
            # Helper function to get sort weight for entity types
            var get_type_weight = func(e: Entity) -> int:
                match e.type:
                    Entity.EntityType.TERRAIN:
                        return 0 if e.get_parent() == floor_layer else 1
                    Entity.EntityType.FIXTURE:
                        return 2
                    Entity.EntityType.ITEM:
                        return 3
                    Entity.EntityType.ACTOR:
                        return 4
                    _: # CORPSE or any other type
                        return 5
            
            var a_weight = get_type_weight.call(a)
            var b_weight = get_type_weight.call(b)
            return a_weight < b_weight
        )
        
    if entity.blocks_movement:
        if not position in _blocking_positions:
            _blocking_positions[position] = []
        _blocking_positions[position].append(entity)
    
    entity_added.emit(entity, position)        

func erase(entity: Entity) -> void:
    assert(entity != null, "Cannot erase null entity")
    var position = entity.grid_position
    
    _entities.erase(entity)
    
    if entity.blocks_movement and position in _blocking_positions:
        _blocking_positions[position].erase(entity)
        if _blocking_positions[position].is_empty():
            _blocking_positions.erase(position)
    
    if entity.get_parent():
        entity.get_parent().remove_child(entity)
    
    entity_removed.emit(entity, position)
    position_contents_changed.emit(position)

func move_entity(entity: Entity, from_pos: Vector2i, to_pos: Vector2i) -> void:
    if entity.blocks_movement:
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
    var entities: Array[Entity] = []
    for e in _entities:
        if e.grid_position == pos:
            entities.append(e)
    return entities

func get_entities_of_type_at(pos: Vector2i, type: Entity.EntityType) -> Array[Entity]:
    var entities: Array[Entity] = []
    for e in get_entities_at(pos):
        if e.type == type:
            entities.append(e)
    return entities

func get_entities_in_radius(center: Vector2i, radius: int) -> Array[Entity]:
    var entities: Array[Entity] = []
    for e in _entities:
        if e.distance(center) <= radius:
            entities.append(e)
    return entities

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
        if entity.blocks_movement:
            return entity
    return null

func is_line_of_sight_blocked(from_pos: Vector2i, to_pos: Vector2i) -> bool:
    var line = get_line(from_pos, to_pos)
    for pos in line:
        for entity in get_entities_at(pos):
            if entity.components.terrain and entity.components.terrain.blocks_sight:
                return true
    return false

func get_line(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
    var line: Array[Vector2i] = []
    var x = start.x
    var y = start.y
    var dx = end.x - start.x
    var dy = end.y - start.y
    var step_x = 1 if dx > 0 else -1 if dx < 0 else 0
    var step_y = 1 if dy > 0 else -1 if dy < 0 else 0
    var longest = abs(dx) if abs(dx) > abs(dy) else abs(dy)
    var shortest = abs(dy) if abs(dx) > abs(dy) else abs(dx)
    var error = longest / 2
    
    while x != end.x or y != end.y:
        line.append(Vector2i(x, y))
        var e2 = error
        if e2 > -longest:
            error -= shortest
            x += step_x
        if e2 < shortest:
            error += longest
            y += step_y
    
    line.append(end)
    return line

func get_entities_in_rect(start: Vector2i, end: Vector2i) -> Array[Entity]:
    var min_x = mini(start.x, end.x)
    var max_x = maxi(start.x, end.x)
    var min_y = mini(start.y, end.y)
    var max_y = maxi(start.y, end.y)
    
    var entities: Array[Entity] = []
    for x in range(min_x, max_x + 1):
        for y in range(min_y, max_y + 1):
            var pos = Vector2i(x, y)
            entities.append_array(get_entities_at(pos))
    return entities

# TODO: This is a temporary function to process the turn. It should be replaced with a more generic system that can handle all the different types of actions.
func process_turn() -> void:
    for entity in _entities:
        print("Processing turn for entity: ", entity.entity_name)
        if entity.components.modifiers:
            entity.process_action_queue()