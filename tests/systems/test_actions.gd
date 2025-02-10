extends GutTest

var attacker: Entity
var target: Entity

func before_each() -> void:    
    var test_level = preload("res://tests/fixtures/test_level.tres")
    GameMap.load_level(test_level)
    
    # Create entities with body components
    attacker = Entity.new()
    attacker.add_component("BodyComponent", {
        "type": "humanoid",
        "parts": {
            Constants.BodyPart.HEAD: {"damage": 2, "range": 1, "damage_type": Constants.DamageType.BLUNT},
            Constants.BodyPart.LEFT_ARM: {"damage": 1, "range": 1, "damage_type": Constants.DamageType.BLUNT},
            Constants.BodyPart.RIGHT_ARM: {"damage": 1, "range": 1, "damage_type": Constants.DamageType.BLUNT},
            Constants.BodyPart.LEFT_LEG: {"damage": 2, "range": 1, "damage_type": Constants.DamageType.BLUNT},
            Constants.BodyPart.RIGHT_LEG: {"damage": 2, "range": 1, "damage_type": Constants.DamageType.BLUNT}
        }
    })
    attacker.add_component("InventoryComponent")
    attacker.add_component("EquipmentComponent")
    
    target = Entity.new()
    target.add_component("BodyComponent", {
        "type": "humanoid",
        "parts": {
            Constants.BodyPart.HEAD: {"vital": true},
            Constants.BodyPart.CHEST: {"vital": true},
            # ... other body parts ...
        }
    })
    
    GameMap.register_entity(attacker, Vector2i(1, 1))
    GameMap.register_entity(target, Vector2i(2, 1))

func after_each() -> void:
    GameMap.clear()

# Natural Weapon Tests
func test_unarmed_attacks() -> void:
    # Test punch
    var punch = MeleeAction.new(attacker, target, Constants.BodyPart.RIGHT_ARM)
    var result = punch.perform()
    
    assert_true(result, "Punch should succeed")
    assert_true(target.components.body.get_wounds(Constants.BodyPart.CHEST), "Punch should cause wound")
    assert_eq(target.components.body.get_wound_type(Constants.BodyPart.CHEST), Constants.WoundType.LIGHT, 
            "Punch should cause light wound")
    
    # Test kick
    var kick = MeleeAction.new(attacker, target, Constants.BodyPart.LEFT_LEG)
    result = kick.perform()
    
    assert_true(result, "Kick should succeed")
    assert_eq(target.components.body.get_wound_type(Constants.BodyPart.ABDOMEN), Constants.WoundType.MODERATE,
            "Kick should cause moderate wound")
    
    # Test headbutt
    var headbutt = MeleeAction.new(attacker, target, Constants.BodyPart.HEAD)
    result = headbutt.perform()
    
    assert_true(result, "Headbutt should succeed")
    assert_true(attacker.components.body.get_wounds(Constants.BodyPart.HEAD),
            "Headbutt should also damage attacker")

# Weapon Tests
func test_weapon_attacks() -> void:
    var sword = create_weapon_entity([
        ["WeaponComponent", {"damage": 3, "range": 1}],
        ["DamageTypeComponent", {"type": Constants.DamageType.SLASH}],
        ["WeightComponent", {"weight": 1.5}]
    ])
    
    attacker.components.body.equip_to_slot(sword)
    var slash = MeleeAction.new(attacker, target, Constants.BodyPart.CHEST, sword)
    var result = slash.perform()
    
    assert_true(result, "Sword attack should succeed")
    assert_true(target.components.body.is_bleeding(Constants.BodyPart.CHEST),
            "Slash should cause bleeding")

# Throw Tests
func test_throw_weapon() -> void:
    var dagger = create_weapon_entity([
        ["WeaponComponent", {"damage": 2, "range": 1}],
        ["DamageTypeComponent", {"type": Constants.DamageType.PIERCE}],
        ["WeightComponent", {"weight": 0.5}]
    ])
    
    attacker.inventory_component.add_item(dagger)
    var throw = ThrowAction.new(attacker, target, dagger)
    
    # Calculate expected range based on weight
    var expected_range = 10 - ceil(dagger.get_component(WeightComponent).weight * 2)
    assert_eq(throw.get_max_range(), expected_range, "Throw range should be weight-based")
    
    var result = throw.perform()
    assert_true(result, "Throw should succeed")
    assert_true(target.components.body.get_wounds(Constants.BodyPart.CHEST),
            "Thrown weapon should cause wound")

func test_throw_generic_item() -> void:
    var rock = create_item_entity([
        ["WeightComponent", {"weight": 2.0}]
    ])
    
    attacker.inventory_component.add_item(rock)
    var throw = ThrowAction.new(attacker, target, rock)
    
    # Test weight-based damage
    var expected_damage = ceil(rock.get_component(WeightComponent).weight * 0.01)
    assert_eq(throw.get_damage(), expected_damage, "Generic throw damage should be weight-based")
    
    var result = throw.perform()
    assert_true(result, "Throw should succeed")
    assert_true(target.components.body.get_wounds(Constants.BodyPart.CHEST),
            "Thrown item should cause wound")

# Range Tests
func test_attack_ranges() -> void:
    # Test out of punch range
    GameMap.move_entity(target, Vector2i(4, 1))
    var punch = MeleeAction.new(attacker, target, Constants.BodyPart.RIGHT_ARM)
    assert_false(punch.perform(), "Punch should fail at range 3")
    
    # Test weapon range
    var spear = create_weapon_entity([
        ["WeaponComponent", {"damage": 2, "range": 2}],
        ["DamageTypeComponent", {"type": Constants.DamageType.PIERCE}],
        ["WeightComponent", {"weight": 2.0}]
    ])
    
    attacker.components.body.equip_to_slot(spear)
    var thrust = MeleeAction.new(attacker, target, null, spear)
    assert_true(thrust.perform(), "Spear should hit at range 2")

# Utility Functions
func create_weapon_entity(components: Array) -> Entity:
    var weapon = Entity.new()
    for component in components:
        weapon.add_component(component[0], component[1])
    return weapon

func create_item_entity(components: Array) -> Entity:
    var item = Entity.new()
    for component in components:
        item.add_component(component[0], component[1])
    return item 