extends GutTest

const MapScene = preload("res://src/Map/Map.tscn")
const Level = preload("res://src/Map/level.gd")

var test_level: Level
var player: Entity
var orc: Entity
var sword: Entity

func before_each() -> void:
	# Initialize GameMap scene
	var map_scene = MapScene.instantiate()
	add_child_autofree(map_scene)
	
	# Load test level resource
	test_level = preload("res://tests/fixtures/test_level.tres")
	
	# Initialize GameMap with test level
	GameMap.load_level(test_level)
	
	# Create test entities with real blueprints
	var player_blueprint = preload("res://assets/blueprints/actors/player.tres")
	var orc_blueprint = preload("res://assets/blueprints/actors/monsters/orc.tres")
	var sword_blueprint = preload("res://assets/blueprints/items/weapons/sword.tres")
	
	player = Entity.from_blueprint(player_blueprint, Vector2i(1, 1))
	orc = Entity.from_blueprint(orc_blueprint, Vector2i(2, 2))
	sword = Entity.from_blueprint(sword_blueprint, Vector2i(1, 1))

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
	print("\nTesting basic tile layer stacking...")
	
	# Load only the basic layers
	for element in test_level.floors:
		var entity = Entity.from_blueprint(element.blueprint, element.position)
		GameMap.register_entity(entity, element.position)
	for element in test_level.surfaces:
		var entity = Entity.from_blueprint(element.blueprint, element.position)
		GameMap.register_entity(entity, element.position)
	for element in test_level.objects:
		var entity = Entity.from_blueprint(element.blueprint, element.position)
		GameMap.register_entity(entity, element.position)
	
	# Get all entities at position
	var entities = GameMap.get_entities_at(pos)
	print("Entities found: ", entities.size())
	for i in range(entities.size()):
		print("Entity ", i, ": ", entities[i].type if entities[i] else "null")
	
	# Verify we get floor, surface, and object in correct order
	assert_eq(entities.size(), 3, "Should have floor, surface, and object")
	if entities.size() > 0:
		assert_eq(entities[0].type, Entity.EntityType.TERRAIN, "First entity should be floor")
	if entities.size() > 1:
		assert_eq(entities[1].type, Entity.EntityType.TERRAIN, "Second entity should be surface")
	if entities.size() > 2:
		assert_eq(entities[2].type, Entity.EntityType.FIXTURE, "Third entity should be object")

func test_complete_entity_stacking() -> void:
	# Clear any existing entities
	GameMap.clear()
	
	var pos = Vector2i(1, 1)
	
	# Load basic layers first
	for element in test_level.floors:
		var entity = Entity.from_blueprint(element.blueprint, element.position)
		GameMap.register_entity(entity, element.position)
	for element in test_level.surfaces:
		var entity = Entity.from_blueprint(element.blueprint, element.position)
		GameMap.register_entity(entity, element.position)
	for element in test_level.objects:
		var entity = Entity.from_blueprint(element.blueprint, element.position)
		GameMap.register_entity(entity, element.position)
	
	# Place dynamic entities
	GameMap.register_entity(sword, pos)  # Item
	GameMap.register_entity(player, pos) # Actor
	
	var all_entities = GameMap.get_entities_at(pos)
	
	# Verify complete stacking order: floor -> surface -> object -> items -> actors
	assert_eq(all_entities.size(), 5, "Should have all 5 entity types stacked")
	assert_eq(all_entities[0].type, Entity.EntityType.TERRAIN, "First entity should be floor")
	assert_eq(all_entities[1].type, Entity.EntityType.TERRAIN, "Second entity should be surface")
	assert_eq(all_entities[2].type, Entity.EntityType.FIXTURE, "Third entity should be object")
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
	watch_signals(GameMap) # Watch for movement signals
	
	player.move(end_pos - start_pos)
	
	# Verify movement
	assert_signal_emitted_with_parameters(GameMap, "entity_moved", [player, start_pos, end_pos])
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
	GameMap.erase(sword)
	items = GameMap.get_entities_of_type_at(pos, Entity.EntityType.ITEM)
	assert_eq(items.size(), 0, "Item should be removed after pickup")
