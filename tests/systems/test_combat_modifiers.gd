extends GutTest

const MapScene = preload("res://src/Map/Map.tscn")
const Level = preload("res://src/Map/level.gd")

var entity: Entity
var map_scene: Node

func before_each() -> void:
    map_scene = MapScene.instantiate()
    add_child_autofree(map_scene)
    
    # Create test entity with combat modifier component
    var blueprint = preload("res://assets/blueprints/actors/player.tres")
    entity = Entity.new().setup_from_blueprint(blueprint, Vector2i(1, 1))
    
    # Add combat modifier component if not present
    if not entity.components.combat_modifier:
        var combat_modifier = CombatModifierComponent.new()
        entity.components["combat_modifier"] = combat_modifier
        entity.add_child(combat_modifier)
    
    GameMap.register_entity(entity, entity.grid_position)

func after_each() -> void:
    GameMap.clear()
    if map_scene:
        map_scene.queue_free()
        map_scene = null

# Environmental State Tests
func test_oiled_state() -> void:
    # Test floor tile effects
    var floor_tile = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/terrain/floor.tres"), Vector2i(1, 1))
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.OILED, floor_tile)
    
    # Test creature movement on oiled floor
    var creature = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
    if not creature.components.combat_modifier:
        var combat_modifier = CombatModifierComponent.new()
        creature.components["combat_modifier"] = combat_modifier
        creature.add_child(combat_modifier)
    
    
    if creature.roll(3):  # Failed check (1-3 fails, 4-6 succeeds)
        assert_true(creature.compoents.combat_modifier.has_status(Constants.StatusEffect.PRONE), "Should fall prone on oiled floor")
    
    # Test entity being oiled
    var weapon = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/items/sword.tres"), Vector2i(1, 1))
    if not weapon.components.combat_modifier:
        var combat_modifier = CombatModifierComponent.new()
        weapon.components["combat_modifier"] = combat_modifier
        weapon.add_child(combat_modifier)
    
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.OILED, weapon)
    assert_true(weapon.components.material and weapon.components.material.is_slippery(), "Oiled weapon should be slippery")
    assert_true(weapon.components.material and weapon.components.material.is_flammable(), "Oiled weapon should be flammable")
    
    # Test combat effects
    var attacker = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
    if not attacker.components.combat_modifier:
        var combat_modifier = CombatModifierComponent.new()
        attacker.components["combat_modifier"] = combat_modifier
        attacker.add_child(combat_modifier)
    
    if attacker.components.body:
        attacker.components.body.equip_to_slot(weapon)
        var grip_check = attacker.roll_grip_check()
        if grip_check <= 3:  # Failed check (1-3 fails, 4-6 succeeds)
            assert_true(weapon.has_status(Constants.StatusEffect.DISARMED), "Should drop oiled weapon on failed check")

func test_ablaze_state() -> void:
    # Test entity on fire
    var creature = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.ABLAZE, creature)
    
    # Should cause wounds to entities with health
    if creature.components.body.consciousness > 0:
        assert_true(creature.components.body.has_wound(Constants.BodyPart.CHEST), "Ablaze should cause wounds")
        assert_eq(creature.components.body.get_wound_type(Constants.BodyPart.CHEST, 0), Constants.WoundType.MODERATE, 
                "Fire should cause moderate wounds")
    
    # Test smoke effects
    var nearby_tile = Vector2i(2, 1)
    assert_true(GameMap.is_line_of_sight_blocked(Vector2i(1, 1), Vector2i(3, 1)), 
            "Smoke should block line of sight")
    
    # Test fire spreading
    var flammable_object = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/items/wooden_chair.tres"), Vector2i(2, 1))
    GameMap.register_entity(flammable_object, flammable_object.grid_position)
    
    GameMap.process_turn()  # Let fire spread
    assert_true(flammable_object.has_state(Constants.StatusEffect.ABLAZE), "Fire should spread to nearby flammable objects")
    
    # Test equipment damage fr
    var sword = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/items/sword.tres"), Vector2i(1, 1))
    creature.components.body.equip_to_slot(sword)
    
    watch_signals(creature.components.equipment)
    GameMap.process_turn()  # Process fire damage


    assert_signal_emitted(creature.components.equipment, "equipment_damaged", "Fire should damage equipment")
        
func test_mud_covered() -> void:
    # Test mud on floor
    var floor_tile = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/terrain/floor.tres"), Vector2i(1, 1))
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.MUD_COVERED, floor_tile)
    
    # Test movement impairment
    var creature = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
    creature.action_queue.append( MovementAction.new(creature, floor_tile) )
    creature.process_action_queue()
    assert_true(creature.has_state(Constants.StatusEffect.MUD_COVERED), "Mud should be applied to prone")

    entity.components.combat_modifier.apply_state(Constants.StatusEffect.ABLAZE, creature)
    assert_false(creature.has_state(Constants.StatusEffect.ABLAZE), "Mud should prevent catching fire")
    
    # Test equipment effects
    var armor = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/items/plate_armor.tres"), Vector2i(1, 1))
    creature.components.equipment.equip_armor(armor)
    var initial_protection = armor.get_protection_value()
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.MUD_COVERED, armor)
    assert_lt(armor.get_protection_value(), initial_protection, "Mud should reduce armor effectiveness")
    
# Combat State Tests
func test_bleeding_state() -> void:
    var creature = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
    creature.components.combat_modifier.apply_state(Constants.StatusEffect.BLEEDING, creature)
    
    assert_true(creature.has_state(Constants.StatusEffect.BLEEDING), "Should be bleeding")

func test_dazed_state() -> void:
    var creature = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
    
    # Test dazed right arm
    var sword = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/items/sword.tres"), Vector2i(1, 1))
    creature.components.body.equip_to_slot(sword, Constants.BodyPart.RIGHT_ARM)
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.DAZED, creature, Constants.BodyPart.RIGHT_ARM)
    
    # Should only affect right arm
    var grip_check = creature.roll_grip_check(Constants.BodyPart.RIGHT_ARM)
    if grip_check < 4:  # Failed check
        pass #assert_true(sword.is_dropped(), "Should drop weapon from dazed arm")
    
    # Test dazed left arm with shield
    var shield = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/items/shield.tres"), Vector2i(1, 1))
    creature.components.body.equip_to_slot(shield, Constants.BodyPart.LEFT_ARM)
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.DAZED, creature, Constants.BodyPart.LEFT_ARM)
    
    # Right arm weapon should be unaffected
    ##assert_false(sword.is_dropped(), "Weapon in undazed arm should not be dropped")
    
    # Test vision effects when head is dazed
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.DAZED, creature, Constants.BodyPart.HEAD)
    assert_true(creature.vision_is_blurred(), "Dazed head should blur vision")
    assert_lt(creature.get_vision_range(), creature.get_base_vision_range(), "Dazed head should reduce vision range")
    
    # Test balance effects when legs are dazed
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.DAZED, creature, Constants.BodyPart.LEFT_LEG)
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.DAZED, creature, Constants.BodyPart.RIGHT_LEG)
    assert_true(creature.has_status(Constants.StatusEffect.PRONE_TO_FALLING), "Dazed legs should risk falling")

func test_ablaze_and_pinned() -> void:
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.ABLAZE)
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.PINNED)
    
    assert_true(entity.components.combat_modifier.causes_panic(), "Should cause panic")

# Behavioral Interaction Tests
func test_panic_behavior() -> void:
    # Test panic state effects
    var creature = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/player.tres"))
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.ABLAZE, creature)

    # Test panic state effects
    assert_true(creature.has_status(Constants.StatusEffect.PANICKED), "Should be panicked when ablaze")
    
    # Test weapon handling while panicked
    var sword = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/items/sword.tres"))
    creature.components.body.equip_to_slot(sword)
    
    GameMap.process_turn()  # Process panic effects
    #assert_true(sword.is_dropped(), "Should drop weapon when panicked")

func test_equipment_interaction() -> void:
    var creature = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/player.tres"))
    
    # Test weapon with oiled state
    var sword = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/items/sword.tres"))
    creature.components.body.equip_to_slot(sword)
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.OILED, sword)
    
    # Test grip checks with oiled weapon
    GameMap.process_turn()  # Process weapon state
    assert_true(sword.components.material and sword.components.material.is_slippery(), "Oiled weapon should be slippery")
    
    # Test armor with mud state
    var armor = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/items/plate_armor.tres"))
    creature.components.equipment.equip_armor(armor)
    var base_protection = armor.get_protection_value()
    
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.MUD_COVERED, armor)
    assert_lt(armor.get_protection_value(), base_protection, "Mud should reduce armor effectiveness")

func test_progressive_state_effects() -> void:
    var creature = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
    if not creature.components.combat_modifier:
        var combat_modifier = CombatModifierComponent.new()
        creature.components["combat_modifier"] = combat_modifier
        creature.add_child(combat_modifier)
    
    entity.components.combat_modifier.apply_state(Constants.StatusEffect.BLEEDING, creature)
    
    var initial_consciousness = creature.components.body.consciousness
    
    for i in range(3):
        creature.components.combat_modifier.process_turn()
        
    assert_lt(creature.components.body.consciousness, initial_consciousness, "Bleeding should cause progressive damage")
    
    assert_true(creature.has_status(Constants.StatusEffect.BLEEDING), "Bleeding should cause loss of con over time")
    assert_true(creature.has_status(Constants.StatusEffect.WEAKENED), "Bleeding should cause weakness over time")

# Utility Functions
func create_enemy_nearby() -> Entity:
    var enemy = Entity.new().setup_from_blueprint(
        preload("res://assets/blueprints/actors/monsters/orc.tres")
    )
    enemy.grid_position = entity.grid_position + Vector2i(1, 0)
    GameMap.register_entity(enemy, enemy.grid_position)
    return enemy 