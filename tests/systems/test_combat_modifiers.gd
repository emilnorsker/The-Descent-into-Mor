extends GutTest

const Level = preload("res://src/Map/level.gd")

var entity: Entity

func before_each() -> void:
    var test_level = preload("res://tests/fixtures/test_level.tres")
    GameMap.load_level(test_level)
    
    # Create test entity with combat modifier component
    var blueprint = preload("res://assets/blueprints/actors/player.tres")
    entity = Entity.new(blueprint, Vector2i(1, 1))
    
    # Add combat modifier component if not present
    if not entity.modifiers:
        var modifiers = ModifierComponent.new()
        entity.components["modifiers"] = modifiers
        entity.add_child(modifiers)
    
    GameMap.register_entity(entity, entity.grid_position)

func after_each() -> void:
    GameMap.clear()

# Utility Functions
func create_enemy_nearby() -> Entity:
    var enemy = Entity.new(
        preload("res://assets/blueprints/actors/monsters/orc.tres")
    )
    enemy.grid_position = entity.grid_position + Vector2i(1, 0)
    GameMap.register_entity(enemy, enemy.grid_position)
    return enemy 