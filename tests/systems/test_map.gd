extends GutTest

var test_level: Resource
var player: Entity
var orc: Entity
var sword: Entity

func before_each() -> void:
    test_level = load("res://tests/fixtures/test_level.tres")
    
    # Create test entities
    var player_blueprint = preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres")
    var orc_blueprint = preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres")
    var sword_blueprint = preload("res://tests/fixtures/blueprints/items/test_weapon.tres")
    
    player = Entity.new().setup_from_blueprint(player_blueprint, Vector2i(1, 1))
    orc = Entity.new().setup_from_blueprint(orc_blueprint, Vector2i(2, 2))
    sword = Entity.new().setup_from_blueprint(sword_blueprint, Vector2i(1, 1))

func after_each() -> void:
    # Clear GameMap state
    GameMap.clear()

# Test Core Map Functionality
func test_level_loading() -> void:
    assert_not_null(test_level, "Level resource should be loaded")
    assert_not_null(test_level.floors, "Level should have floor data")
    assert_not_null(test_level.surfaces, "Level should have surface data")
    assert_not_null(test_level.objects, "Level should have object data")
    
    # Verify test level data
    assert_eq(test_level.floors.size(), 1, "Should have one floor tile")
    assert_eq(test_level.surfaces.size(), 1, "Should have one surface feature")
    assert_eq(test_level.objects.size(), 1, "Should have one object")

# Test Entity Placement and Stacking
func test_basic_tile_layer_stacking() -> void:
    # Clear any existing entities
    GameMap.clear()
    
    var pos = Vector2i(1, 1)
    
    # Load only the basic layers
    for element in test_level.floors:
        var entity = Entity.new(element.blueprint, element.position)
        GameMap.register_entity(entity, element.position)
    for element in test_level.surfaces:
        var entity = Entity.new(element.blueprint, element.position)
        GameMap.register_entity(entity, element.position)
    for element in test_level.objects:
        var entity = Entity.new(element.blueprint, element.position)
        GameMap.register_entity(entity, element.position)
    
    # Get all entities at position
    var entities = GameMap.get_entities_at(pos)
    
    # Verify we get floor, surface, and object in correct order
    assert_eq(entities.size(), 3, "Should have floor, surface, and object")

func test_complete_entity_stacking() -> void:
    # Clear any existing entities
    GameMap.clear()
    
    var pos = Vector2i(1, 1)
    
    # Load basic layers first
    for element in test_level.floors:
        var entity = Entity.new(element.blueprint, element.position)
        GameMap.register_entity(entity, element.position)
    for element in test_level.surfaces:
        var entity = Entity.new(element.blueprint, element.position)
        GameMap.register_entity(entity, element.position)
    for element in test_level.objects:
        var entity = Entity.new(element.blueprint, element.position)
        GameMap.register_entity(entity, element.position)
    
    # Place dynamic entities
    GameMap.register_entity(sword, pos)  # Item
    GameMap.register_entity(player, pos) # Actor
    
    var all_entities = GameMap.get_entities_at(pos)
    
    # Verify complete stacking order: floor -> surface -> object -> items -> actors
    assert_eq(all_entities.size(), 5, "Should have all 5 entity types stacked")
    assert_true(all_entities.has(sword), "Item should be the sword")
    assert_true(all_entities.has(player), "Actor should be the player")

# Test Combat Positioning
func test_combat_positioning() -> void:
    var player_pos = Vector2i(1, 1)
    var orc_pos = Vector2i(2, 2)
    
    GameMap.register_entity(player, player_pos)
    GameMap.register_entity(orc, orc_pos)
    
    # Verify combat range
    var distance = player.distance(orc_pos)
    assert_eq(distance, 1, "Entities should be at melee range")
    
    # Test blocking
    assert_true(GameMap.is_position_blocked(player_pos), "Player position should be blocked")
    assert_true(GameMap.is_position_blocked(orc_pos), "Orc position should be blocked")

# Test Movement and Position Updates
func test_entity_movement() -> void:
    # Clear any existing entities
    GameMap.clear()
    
    var start_pos = Vector2i(1, 1)
    var end_pos = Vector2i(2, 1)
    
    GameMap.register_entity(player, start_pos)
    watch_signals(GameMap) # Watch for movement signals
    
    player.move(end_pos - start_pos)
    
    # Verify movement
    assert_signal_emitted_with_parameters(GameMap, "entity_moved", [player, start_pos, end_pos])
    assert_false(GameMap.is_position_blocked(start_pos), "Start position should no longer be blocked")
    assert_true(GameMap.is_position_blocked(end_pos), "End position should now be blocked")

# Test Area Effects
func test_area_effects() -> void:
    # Clear any existing entities and skip level loading
    GameMap.clear()
    
    var center = Vector2i(2, 2)
    var radius = 2
    
    # Create fresh entities for this test
    var player_blueprint = preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres")
    var orc_blueprint = preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres")
    var sword_blueprint = preload("res://tests/fixtures/blueprints/items/test_weapon.tres")
    
    var test_player = Entity.new().setup_from_blueprint(player_blueprint, Vector2i(2, 2))
    var test_orc = Entity.new().setup_from_blueprint(orc_blueprint, Vector2i(3, 2))
    var test_sword = Entity.new().setup_from_blueprint(sword_blueprint, Vector2i(5, 5))
    
    # Place entities in a pattern
    GameMap.register_entity(test_player, Vector2i(2, 2))  # Center
    GameMap.register_entity(test_orc, Vector2i(3, 2))     # Edge of radius
    GameMap.register_entity(test_sword, Vector2i(5, 5))   # Outside radius
    
    var affected = GameMap.get_entities_in_radius(center, radius)
    assert_eq(affected.size(), 2, "Should affect 2 entities within radius")
    assert_has(affected, test_player, "Should affect player at center")
    assert_has(affected, test_orc, "Should affect orc at edge")
    assert_does_not_have(affected, test_sword, "Should not affect sword outside radius")

# Test Item Interaction Scenarios
func test_item_interaction() -> void:
    # Clear any existing entities and skip level loading
    GameMap.clear()
    
    var pos = Vector2i(1, 1)
    
    # Create fresh entities for this test
    var player_blueprint = preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres")
    var sword_blueprint = preload("res://tests/fixtures/blueprints/items/test_weapon.tres")
    
    var test_player = Entity.new().setup_from_blueprint(player_blueprint, pos)
    var test_sword = Entity.new().setup_from_blueprint(sword_blueprint, pos)
    
    # Place sword and player
    GameMap.register_entity(test_sword, pos)
    GameMap.register_entity(test_player, pos)
    
    # Verify item is accessible
    var items = GameMap.get_entities_of_type_at(pos, Entity.EntityType.ITEM)
    assert_eq(items.size(), 1, "Should find the sword")
    
    # Remove item (simulating pickup)
    GameMap.erase(test_sword)
    items = GameMap.get_entities_of_type_at(pos, Entity.EntityType.ITEM)
    assert_eq(items.size(), 0, "Item should be removed after pickup")
