extends GutTest

var TestMap = preload("res://tests/fixtures/test_map.tscn")
var test_map: Map

func before_each() -> void:
    test_map = TestMap.instantiate()
    add_child_autofree(test_map)
    
func test_map_has_all_layers() -> void:
    assert_not_null(test_map.floor_layer, "Should have floor layer")
    assert_not_null(test_map.feature_layer, "Should have feature layer")
    assert_not_null(test_map.fixture_layer, "Should have fixture layer")

class TestMapInteraction:
    extends GutTest
    
    var test_map: Map
    var test_entity: Entity
    
    func before_each() -> void:
        test_map = preload("res://tests/fixtures/test_map.tscn").instantiate()
        add_child_autofree(test_map)
        
        # Create a test entity
        test_entity = Entity.new()
        test_entity.type = Entity.EntityType.ACTOR
    
    func test_can_place_entity_on_empty_floor() -> void:
        var pos = Vector2i(1, 1)
        test_map.register_entity(test_entity, pos)
        
        var entities = test_map.get_entities_at(pos)
        assert_has(entities, test_entity, "Entity should be at position")
    
    func test_can_move_entity_between_positions() -> void:
        var start_pos = Vector2i(0, 0)
        var end_pos = Vector2i(1, 1)
        
        # Place entity
        test_map.register_entity(test_entity, start_pos)
        
        # Watch for movement signal
        watch_signals(test_map)
        
        # Move entity
        test_map.move_entity(test_entity, start_pos, end_pos)
        
        # Check signal was emitted
        assert_signal_emitted_with_parameters(test_map, "entity_moved", 
            [test_entity, start_pos, end_pos])
        
        # Check entity is at new position
        var entities = test_map.get_entities_at(end_pos)
        assert_has(entities, test_entity, "Entity should be at new position")
    
    func test_blocking_entity_blocks_position() -> void:
        var pos = Vector2i(1, 1)
        test_entity.blocks_movement = true
        
        test_map.register_entity(test_entity, pos)
        assert_true(test_map.is_position_blocked(pos), "Position should be blocked")
    
    func test_movement_cost_accumulates() -> void:
        var pos = Vector2i(1, 1)
        
        # Create two entities with movement costs
        var entity1 = Entity.new()
        entity1.movement_cost = 2.0
        
        var entity2 = Entity.new()
        entity2.movement_cost = 1.5
        
        # Place both entities
        test_map.register_entity(entity1, pos)
        test_map.register_entity(entity2, pos)
        
        # Total cost should be multiplicative
        assert_eq(test_map.get_movement_cost_at(pos), 3.0, 
            "Movement cost should be multiplicative")

class TestAreaEffects:
    extends GutTest
    
    var test_map: Map
    
    func before_each() -> void:
        test_map = preload("res://tests/fixtures/test_map.tscn").instantiate()
        add_child_autofree(test_map)
    
    func test_area_effect_hits_all_entities_in_range() -> void:
        var center = Vector2i(2, 2)
        var radius = 2
        
        # Place several entities at different distances
        var entities = []
        for x in range(5):
            for y in range(5):
                var entity = Entity.new()
                var pos = Vector2i(x, y)
                test_map.register_entity(entity, pos)
                entities.append(entity)
        
        # Get affected entities
        var affected = test_map.get_entities_in_radius(center, radius)
        
        # Check that all entities within radius are affected
        for entity in entities:
            var distance = entity.grid_position.distance_to(center)
            if distance <= radius:
                assert_has(affected, entity, "Entity within radius should be affected")
            else:
                assert_does_not_have(affected, entity, "Entity outside radius should not be affected")
    
    func test_rectangular_area_query() -> void:
        var start = Vector2i(1, 1)
        var end = Vector2i(3, 3)
        
        # Place entities in a grid
        for x in range(5):
            for y in range(5):
                var entity = Entity.new()
                test_map.register_entity(entity, Vector2i(x, y))
        
        var entities = test_map.get_entities_in_rect(start, end)
        assert_eq(entities.size(), 9, "Should find 9 entities in 3x3 rectangle") 