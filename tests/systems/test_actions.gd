extends GutTest

const TestHumanoid = preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres")
const TestWeapon = preload("res://tests/fixtures/blueprints/items/test_weapon.tres")

var attacker: Entity
var target: Entity

func before_each() -> void:    
    var test_level = preload("res://tests/fixtures/test_level.tres")
    GameMap.load_level(test_level)
    
    # Create entities with body components using blueprint
    attacker = Entity.new().setup_from_blueprint(TestHumanoid, Vector2i(1, 1))
    target = Entity.new().setup_from_blueprint(TestHumanoid, Vector2i(2, 1))
    
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
    var wounds = target.components.body.get_wounds(Constants.BodyPart.CHEST)
    assert_true(wounds.size() > 0, "Punch should cause wound")
    if wounds.size() > 0:
        assert_eq(wounds[0].type, Constants.WoundType.LIGHT, 
                "Punch should cause light wound")
    
    # Test kick
    var kick = MeleeAction.new(attacker, target, Constants.BodyPart.LEFT_LEG)
    result = kick.perform()
    
    assert_true(result, "Kick should succeed")
    wounds = target.components.body.get_wounds(Constants.BodyPart.ABDOMEN)
    assert_true(wounds.size() > 0, "Kick should cause wound")
    if wounds.size() > 0:
        assert_eq(wounds[0].type, Constants.WoundType.MODERATE,
                "Kick should cause moderate wound")
    
    # Test headbutt
    var headbutt = MeleeAction.new(attacker, target, Constants.BodyPart.HEAD)
    result = headbutt.perform()
    
    assert_true(result, "Headbutt should succeed")
    wounds = attacker.components.body.get_wounds(Constants.BodyPart.HEAD)
    assert_true(wounds.size() > 0, "Headbutt should also damage attacker")
    if wounds.size() > 0:
        assert_eq(wounds[0].type, Constants.WoundType.LIGHT,
                "Headbutt should also cause light wound")

# Weapon Tests
func test_weapon_attacks() -> void:
    var sword = Entity.new().setup_from_blueprint(TestWeapon, Vector2i.ZERO)
    
    attacker.components.body.equip_to_slot(sword)
    var slash = MeleeAction.new(attacker, target, Constants.BodyPart.CHEST)
    var result = slash.perform()
    
    assert_true(result, "Sword attack should succeed")
    assert_true(
        target.components.combat_modifier and 
        target.components.combat_modifier.has_state(Constants.StatusEffect.BLEEDING),
            "Slash should cause bleeding")

# Throw Tests
func test_throw_weapon() -> void:
    var dagger = create_item_entity([
        ["WeightComponent", {"weight": 0.5}],
        ["ItemComponent", {"power_bonus": 1, "defense_bonus": 1}]
    ])
    
    attacker.components.body.equip_to_slot(dagger)
    var throw = ThrowAction.new(attacker, target, dagger)
    
    # Calculate expected range based on weight
    print("dagger weight: ", dagger.components.weight.get_weight())
    var expected_range = int(10 - ceil(dagger.components.weight.get_weight() * 0.5))
    assert_eq(throw.get_range(), expected_range, "Throw range should be weight-based")
    
    var result = throw.perform()
    assert_true(result, "Throw should succeed")
    var wounds = target.components.body.get_wounds(Constants.BodyPart.CHEST)
    assert_true(wounds.size() > 0, "Thrown weapon should cause wound")
    if wounds.size() > 0:
        assert_eq(wounds[0].type, Constants.WoundType.LIGHT,
                "Thrown weapon should cause light wound")

func test_throw_generic_item() -> void:
    var rock = create_item_entity([
        ["WeightComponent", {"weight": 50.0}],
        ["ItemComponent", {"power_bonus": 1, "defense_bonus": 1}]
    ])
    
    attacker.components.body.equip_to_slot(rock)
    var throw = ThrowAction.new(attacker, target, rock)
    
    # Test weight-based damage
    var expected_damage = int(ceil(rock.components.weight.get_weight() * 0.1))
    assert_eq(throw.get_damage(), expected_damage, "Generic throw damage should be weight-based")
    
    var result = throw.perform()
    assert_true(result, "Throw should succeed")
    
    var wounds = target.components.body.get_wounds(Constants.BodyPart.CHEST)
    assert_true(wounds.size() > 0, "Thrown item should cause wound")
    if wounds.size() > 0:
        assert_eq(wounds[0].type, Constants.WoundType.LIGHT,
                "Thrown item should cause light wound")

# Range Tests
func test_attack_ranges() -> void:
    # Test out of punch range
    target.move(Vector2i(4, 1) - target.grid_position)
    var punch = MeleeAction.new(attacker, target, Constants.BodyPart.RIGHT_ARM)
    assert_false(punch.perform(), "Punch should fail at range 3")
    
    # Test weapon range
    var spear = create_item_entity([
        ["WeightComponent", {"weight": 2.0}],
        ["ItemComponent", {"power_bonus": 1, "defense_bonus": 1}]
    ])
    
    attacker.components.body.equip_to_slot(spear)
    var thrust = MeleeAction.new(attacker, target, Constants.BodyPart.RIGHT_ARM)
    assert_true(thrust.perform(), "Spear should hit at range 2")

# Utility Functions
func create_item_entity(data: Array) -> Entity:
    # Create a temporary blueprint based on test weapon
    var blueprint = TestWeapon.duplicate()
    
    # Modify components based on data
    for component_data in data:
        var type = component_data[0]
        var values = component_data[1]
        
        match type:
            "ItemComponent":
                blueprint.components.item.power_bonus = values.get("power_bonus", 0)
                blueprint.components.item.defense_bonus = values.get("defense_bonus", 0)
            "WeightComponent":
                var weight_blueprint = blueprint.components.weight
                weight_blueprint.weight = values.get("weight", 1.5)
                weight_blueprint.affects_balance = values.get("affects_balance", false)
                weight_blueprint.balance_penalty = values.get("balance_penalty", 0.0)
    
    return Entity.new().setup_from_blueprint(blueprint, Vector2i.ZERO)
