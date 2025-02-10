extends GutTest

var DamageType = Constants.DamageType
var TargetType = Constants.TargetType
var WoundType = Constants.WoundType
var BodyPart = Constants.BodyPart
var StatusEffect = Constants.StatusEffect

var attacker: Entity  # We'll use this instead of 'player' to be more generic
var target: Entity
var bystander: Entity  # For testing AOE effects

func before_each() -> void:
    var test_level = preload("res://tests/fixtures/test_map.tscn")
    GameMap.load_level(test_level)
    
    # We'll create entities in a specific formation for testing different attack patterns
    attacker = Entity.new().setup_from_blueprint(preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres"), Vector2i(2, 2))
    target = Entity.new().setup_from_blueprint(preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres"), Vector2i(3, 2))
    bystander = Entity.new().setup_from_blueprint(preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres"), Vector2i(4, 2))
    
    GameMap.register_entity(attacker, attacker.grid_position)
    GameMap.register_entity(target, target.grid_position)
    GameMap.register_entity(bystander, bystander.grid_position)

func after_each() -> void:
    GameMap.clear()

# Test Different Attack Types
func test_melee_attack() -> void:
    var melee_action = MeleeAction.new(attacker, target, BodyPart.CHEST)
    
    var initial_hp = target.components.combat.hp
    var result = melee_action.perform()
        
    assert_true(result, "Melee action should succeed")
    assert_lt(target.components.combat.hp, initial_hp, "Target should take damage")

func test_throw_attack() -> void:
    var weapon = Entity.new().setup_from_blueprint(preload("res://tests/fixtures/blueprints/items/test_weapon.tres"), Vector2i(0, 0))
    attacker.components.inventory.add(weapon)
    
    var throw_action = ThrowAction.new(attacker, target, weapon)
    
    var initial_hp = target.components.combat.hp
    var result = throw_action.perform()
    
    assert_true(result, "Throw action should succeed")
    assert_lt(target.components.combat.hp, initial_hp, "Target should take throw damage")

# Test Combat Stats
func test_defense_calculation() -> void:
    var armor = Entity.new().setup_from_blueprint(preload("res://tests/fixtures/blueprints/items/test_armor.tres"), Vector2i(0, 0))
    target.components.inventory.add(armor)
    target.components.equipment.equip(armor)
    
    var melee_action = MeleeAction.new(attacker, target, BodyPart.CHEST)
    var initial_hp = target.components.combat.hp
    melee_action.perform()
    
    var damage_taken = initial_hp - target.components.combat.hp
    assert_lt(damage_taken, attacker.components.combat.power, "Armor should reduce damage taken")

func test_power_calculation() -> void:
    var weapon = Entity.new().setup_from_blueprint(preload("res://tests/fixtures/blueprints/items/test_weapon.tres"), Vector2i(0, 0))
    attacker.components.inventory.add(weapon)
    attacker.components.equipment.equip(weapon)
    
    var melee_action = MeleeAction.new(attacker, target, BodyPart.CHEST)
    var initial_hp = target.components.combat.hp
    melee_action.perform()
    
    var damage_taken = initial_hp - target.components.combat.hp
    assert_gt(damage_taken, attacker.components.combat.power, "Weapon should increase damage dealt")

# Test Death
func test_death() -> void:
    target.components.combat.hp = 1  # Set target to almost dead
    
    var melee_action = MeleeAction.new(attacker, target, BodyPart.CHEST)
    melee_action.perform()
    
    assert_true(target.components.combat.is_dead(), "Target should be dead")
    assert_false(GameMap.get_actor_at_location(target.grid_position), "Dead target should be removed from map") 