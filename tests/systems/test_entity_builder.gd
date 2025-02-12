extends GutTest

# This test suite verifies that the Entity property system works correctly.
# The Entity class provides access to component properties through a _get/_set 
# virtual property system. This allows code to access component properties directly
# through the entity (entity.health) instead of through the component 
# (entity.combat.health).


const TestHumanoid = preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres")
const TestArmor = preload("res://tests/fixtures/blueprints/items/test_armor.tres")

var IGNORED_PROPERTIES: Array[StringName] = [
    &"script",
    &"Script Variables",
    &"Node",
    &"_import_path",
    &"name",
    &"unique_name_in_owner",
    &"scene_file_path",
    &"owner",
    &"multiplayer",
    
    # Process related
    &"Process",
    &"process_mode",
    &"process_priority",
    &"process_physics_priority",
    
    # Thread related
    &"Thread Group",
    &"process_thread_group",
    &"process_thread_group_order",
    &"process_thread_messages",
    
    # Physics
    &"Physics Interpolation",
    &"physics_interpolation_mode",
    
    # Translation
    &"Auto Translate",
    &"auto_translate_mode",
    
    # Editor
    &"Editor Description",
    &"editor_description",
    
    # Script
    &"script",
    &"Script Variables",
    &"component.gd",
    
    # Base Component properties
    &"component_type",
    &"node",
    &"entity",
    &"process",
    &"process_mode",
    &"process_priority",
    &"process_physics_priority",
    &"process_thread_group",
    &"process_thread_group_order",
    &"process_thread_messages",
    &"thread_group",
    &"thread_group_order",
    &"thread_messages",
]

# Verifies that no component properties have naming conflicts
# Since Entity._get() searches all components for properties, having duplicate
# names would make it ambiguous which component's property should be returned.
# Built-in properties and base Component properties are allowed to be duplicated.
func test_no_duplicate_properties() -> void:

    # Create entity and verify blueprint
    var entity = Entity.new()
    var components = entity._components.values()
    
    # Assert we have components
    assert_true(components.size() > 0, "Entity should have components to test")
    
    # Debug each component's properties
    for i in range(components.size()):
        var component_a = components[i]
        var properties_a = component_a.get_property_list()
        
        for j in range(i + 1, components.size()):
            var component_b = components[j]
            var properties_b = component_b.get_property_list()
            
            for prop_a in properties_a:
                for prop_b in properties_b:
                    # Skip built-in and base Component properties
                    if prop_a.name in IGNORED_PROPERTIES:
                        continue
                    # Only check script variables
                    if not (prop_a.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
                        continue
                        
                    if prop_a.name == prop_b.name:
                        assert_ne(prop_a.name, prop_b.name, 
                            "Property '%s' is defined in multiple components: %s and %s" % 
                            [prop_a.name, component_a.name, component_b.name])
    
    print("=== Completed test_no_duplicate_properties ===\n")

# Verifies that component properties can be accessed and modified through the entity.
# Properties should be accessible both directly (entity.health) and through nested
# access (entity.combat.health). Changes to properties should persist.
func test_component_property_access() -> void:
    var entity = Entity.new(TestHumanoid, Vector2i(1, 1))
    
    assert_eq(entity.grid_position, Vector2i(1, 1), "Should have correct grid position")
    assert_eq(entity.entity_type, Entity.EntityType.ACTOR, "Should have correct entity type")
    
    entity.grid_position = Vector2i(2, 2)
    assert_eq(entity.grid_position, Vector2i(2, 2), "Should be able to update grid position")
    
    assert_eq(entity.body.consciousness, 100.0, "Should be able to access nested property")
    
    entity.body.consciousness = 1.0
    assert_eq(entity.body.consciousness, 1.0, "Should be able to update nested property")

# Verifies that component properties don't conflict with entity properties.
# Entity properties (like entity_type) should take precedence over component
# properties with the same name to prevent confusion between entity state
# and component state. Base Component properties (entity, component_type) 
# are allowed to exist in all components.
func test_component_property_conflicts() -> void:
    var entity = Entity.new(TestHumanoid)
    
    var all_properties: Array[StringName] = []
    for component_name in entity._components:
        var component = entity._components[component_name]
        var properties = component.get_property_list()
        
        for property in properties:
            # Skip built-in and base Component properties
            if property.name in IGNORED_PROPERTIES:
                continue
                
            # Only check script variables
            if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
                continue
                
            assert_false(property.name in all_properties, 
                "Property %s from %s conflicts with existing property" % [property.name, component_name])
            all_properties.append(property.name)

# Verifies that entity_type property works correctly.
# Entity type is a core property that should be set during initialization
# and maintain the correct enum value.
func test_entity_properties():
    var entity = Entity.new()
    assert_eq(entity.entity_type, Entity.EntityType.ACTOR, "Should have correct entity_type enum value")

# Verifies that all entity blueprints in new_assets/entities can be used to create entities.
# This test dynamically loads all .tres files in the directory and attempts to create
# an entity with each one. This helps catch issues with blueprint configurations.
func test_all_entity_blueprints() -> void:
    var dir = DirAccess.open("res://new_assets/entities")
    assert_not_null(dir, "Should be able to open entities directory")
    
    dir.list_dir_begin()
    var file_name = dir.get_next()
    var tested_blueprints = 0
    
    while file_name != "":
        if file_name.ends_with(".tres"):
            var blueprint_path = "res://new_assets/entities/" + file_name
            var blueprint = load(blueprint_path).duplicate()
            assert_not_null(blueprint, "Should be able to load blueprint: %s" % blueprint_path)
            
            var entity = Entity.new(blueprint)
            assert_not_null(entity, "Should be able to create entity from blueprint: %s" % blueprint_path)
            assert_true(entity._components.size() > 0, "Entity should have components: %s" % blueprint_path)
            
            tested_blueprints += 1
            
        file_name = dir.get_next()
    
    dir.list_dir_end()
    assert_true(tested_blueprints > 0, "Should have tested at least one blueprint")
    print("=== Completed test_all_entity_blueprints, tested %d blueprints ===\n" % tested_blueprints)
