extends GutTest

# Test Map System
# This test suite verifies the core functionality of our map system
# focusing on real gameplay scenarios and interactions

var TestMap = preload("res://tests/fixtures/test_map.tscn")
var test_map: Map
var player: Entity
var orc: Entity
var sword: Entity

func before_each() -> void:
	test_map = TestMap.instantiate()
	add_child_autofree(test_map)
	
	# Create test entities with real blueprints
	var player_blueprint = preload("res://assets/blueprints/actors/player.tres")
	var orc_blueprint = preload("res://assets/blueprints/actors/monsters/orc.tres")
	var sword_blueprint = preload("res://assets/blueprints/items/weapons/sword.tres")
	
	player = Entity.from_blueprint(player_blueprint, Vector2i(1, 1))
	orc = Entity.from_blueprint(orc_blueprint, Vector2i(2, 2))
	sword = Entity.from_blueprint(sword_blueprint, Vector2i(1, 1))

# Test Core Map Functionality
func test_map_has_required_layers() -> void:
	assert_not_null(test_map.floor_layer, "Map should have a floor layer")
	assert_not_null(test_map.feature_layer, "Map should have a feature layer")
	assert_not_null(test_map.fixture_layer, "Map should have a fixture layer")
	assert_eq(test_map.floor_layer.get_class(), "TileMapLayer", "Floor layer should be a TileMapLayer")
	assert_eq(test_map.feature_layer.get_class(), "TileMapLayer", "Feature layer should be a TileMapLayer")
	assert_eq(test_map.fixture_layer.get_class(), "TileMapLayer", "Fixture layer should be a TileMapLayer")

# Test Entity Placement and Stacking
func test_basic_tile_layer_stacking() -> void:
	var pos = Vector2i(1, 1)
	
	# Get all entities at position before adding dynamic entities
	var base_entities = GameMap.get_entities_at(pos)
	
	# Verify we get floor, feature, and fixture in correct order
	assert_eq(base_entities.size(), 3, "Should have floor, feature, and fixture")
	assert_eq(base_entities[0].type, Entity.EntityType.TERRAIN, "First entity should be floor")
	assert_eq(base_entities[1].type, Entity.EntityType.TERRAIN, "Second entity should be feature")
	assert_eq(base_entities[2].type, Entity.EntityType.FIXTURE, "Third entity should be fixture")

func test_complete_entity_stacking() -> void:
	var pos = Vector2i(1, 1)
	
	# Place dynamic entities
	GameMap.register_entity(sword, pos)  # Item
	GameMap.register_entity(player, pos) # Actor
	
	var all_entities = GameMap.get_entities_at(pos)
	
	# Verify complete stacking order: floor -> feature -> fixture -> items -> actors
	assert_eq(all_entities.size(), 5, "Should have all 5 entity types stacked")
	assert_eq(all_entities[0].type, Entity.EntityType.TERRAIN, "First entity should be floor")
	assert_eq(all_entities[1].type, Entity.EntityType.TERRAIN, "Second entity should be feature")
	assert_eq(all_entities[2].type, Entity.EntityType.FIXTURE, "Third entity should be fixture")
	assert_eq(all_entities[3].type, Entity.EntityType.ITEM, "Fourth entity should be item")
	assert_eq(all_entities[4].type, Entity.EntityType.ACTOR, "Fifth entity should be actor")
	
	# Verify the specific entities
	assert_eq(all_entities[3], sword, "Item should be the sword")
	assert_eq(all_entities[4], player, "Actor should be the player")

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
	var start_pos = Vector2i(1, 1)
	var end_pos = Vector2i(2, 1)
	
	GameMap.register_entity(player, start_pos)
	watch_signals(test_map) # Watch for movement signals
	
	player.move(end_pos - start_pos)
	
	# Verify movement
	assert_signal_emitted_with_parameters(test_map, "entity_moved", [player, start_pos, end_pos])
	assert_false(GameMap.is_position_blocked(start_pos), "Start position should no longer be blocked")
	assert_true(GameMap.is_position_blocked(end_pos), "End position should now be blocked")

# Test Area Effects
func test_area_effects() -> void:
	var center = Vector2i(2, 2)
	var radius = 2
	
	# Place entities in a pattern
	GameMap.register_entity(player, Vector2i(2, 2))  # Center
	GameMap.register_entity(orc, Vector2i(3, 2))     # Edge of radius
	GameMap.register_entity(sword, Vector2i(5, 5))   # Outside radius
	
	var affected = GameMap.get_entities_in_radius(center, radius)
	assert_eq(affected.size(), 2, "Should affect 2 entities within radius")
	assert_has(affected, player, "Should affect player at center")
	assert_has(affected, orc, "Should affect orc at edge")
	assert_does_not_have(affected, sword, "Should not affect sword outside radius")

# Test Item Interaction Scenarios
func test_item_interaction() -> void:
	var pos = Vector2i(1, 1)
	
	# Place sword and player
	GameMap.register_entity(sword, pos)
	GameMap.register_entity(player, pos)
	
	# Verify item is accessible
	var items = GameMap.get_entities_of_type_at(pos, Entity.EntityType.ITEM)
	assert_eq(items.size(), 1, "Should find the sword")
	
	# Remove item (simulating pickup)
	GameMap.remove_entity(sword, pos)
	items = GameMap.get_entities_of_type_at(pos, Entity.EntityType.ITEM)
	assert_eq(items.size(), 0, "Item should be removed after pickup")
