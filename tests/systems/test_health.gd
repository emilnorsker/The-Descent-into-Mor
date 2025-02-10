extends GutTest

const TestHumanoid = preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres")
const TestWoundedHumanoid = preload("res://tests/fixtures/blueprints/actors/test_wounded_humanoid.tres")

var BodyPart = BodyComponent.BodyPart
var WoundType = BodyComponent.WoundType
var WoundEffect = BodyComponent.WoundEffect
var StatusEffect = Constants.StatusEffect
var TreatmentType = Constants.TreatmentType

var entity: Entity
var body: BodyComponent

func before_each() -> void:
    var test_level = load("res://tests/fixtures/test_level.tres")
    GameMap.load_level(test_level)
    
    # Create test entity with body using blueprint
    entity = Entity.new().setup_from_blueprint(TestHumanoid, Vector2i(1, 1))
    GameMap.register_entity(entity, Vector2i(1, 1))
    
    body = entity.components.body

func after_each() -> void:
    GameMap.clear()
    body = null

# Basic Wound Tests
func test_apply_wound() -> void:
    body.apply_wound(WoundType.LIGHT, BodyPart.LEFT_ARM)
    
    var wounds = body.get_wounds(BodyPart.LEFT_ARM)
    assert_true(wounds.size() > 0, "Left arm should be wounded")
    assert_eq(wounds.size(), 1, "Should have one wound")
    assert_eq(wounds[0].type, WoundType.LIGHT, "Should be light wound")

func test_vital_hit() -> void:
    watch_signals(body)
    body.apply_wound(WoundType.FATAL, BodyPart.HEAD)
    
    assert_true(body.is_dead, "Fatal head wound should be fatal")
    assert_signal_emitted(body, "died")

# Wound Effects
func test_bleeding_effects() -> void:
    body.apply_wound(WoundType.MODERATE, BodyPart.CHEST)
    
    var chest_wounds = body.get_wounds(BodyPart.CHEST)
    assert_true(WoundEffect.BLEEDING in chest_wounds[0].effects, "Chest should be bleeding")
    assert_eq(chest_wounds[0].bleeding_rate, 1, "Chest should have normal bleed rate")
    
    body.apply_wound(WoundType.SEVERE, BodyPart.NECK)
    var neck_wounds = body.get_wounds(BodyPart.NECK)
    assert_eq(neck_wounds[0].bleeding_rate, 2, "Neck should have higher bleed rate")

func test_impairment() -> void:
    body.apply_wound(WoundType.SEVERE, BodyPart.RIGHT_ARM)
    
    assert_true(body.is_limb_impaired(BodyPart.RIGHT_ARM), "Right arm should be impaired")
    var arm_wounds = body.get_wounds(BodyPart.RIGHT_ARM)
    assert_true(WoundEffect.CRIPPLED in arm_wounds[0].effects, "Right arm should be crippled")

# Consciousness System
func test_consciousness_gain() -> void:
    body.apply_wound(WoundType.MODERATE, BodyPart.HEAD)
    var consciousness = body.consciousness
    
    assert_gt(consciousness, 0, "Should gain consciousness from head wound")
    
    body.apply_wound(WoundType.MODERATE, BodyPart.CHEST)
    assert_lt(body.consciousness - consciousness, 2.0, 
            "Chest wound should cause less consciousness gain than head")

func test_consciousness_check() -> void:
    watch_signals(body)
    
    # Apply multiple wounds to raise consciousness
    body.apply_wound(WoundType.SEVERE, BodyPart.HEAD)
    body.apply_wound(WoundType.SEVERE, BodyPart.CHEST)
    
    assert_true(body.consciousness >= 8, "Should have high consciousness")
    body.check_consciousness()
    
    assert_signal_emitted(body, "consciousness_check_failed")
    assert_true(body.is_dead, "Should be dead from consciousness check")

# Treatment System
func test_wound_treatment() -> void:
    body.apply_wound(WoundType.MODERATE, BodyPart.LEFT_ARM)
    var initial_bleeding = body.get_total_bleeding()
    
    body.treat_wound(BodyPart.LEFT_ARM, 0, TreatmentType.BANDAGE)
    assert_lt(body.get_total_bleeding(), initial_bleeding, "Bandage should reduce bleeding")
    
    body.treat_wound(BodyPart.LEFT_ARM, 0, TreatmentType.STITCHES)
    assert_eq(body.get_total_bleeding(), 0, "Stitches should stop bleeding")

# Recovery System
func test_natural_healing() -> void:
    body.apply_wound(WoundType.LIGHT, BodyPart.LEFT_LEG)
    body.treat_wound(BodyPart.LEFT_LEG, 0, TreatmentType.BANDAGE)
    
    # Simulate time passing
    for i in range(5):
        body.process_recovery()
    
    var leg_wounds = body.get_wounds(BodyPart.LEFT_LEG)
    assert_true(leg_wounds.is_empty(), "Light wound should heal naturally")

func test_severe_wound_recovery() -> void:
    body.apply_wound(WoundType.SEVERE, BodyPart.CHEST)
    body.treat_wound(BodyPart.CHEST, 0, TreatmentType.STITCHES)
    
    # Simulate time passing
    for i in range(10):
        body.process_recovery()
    
    var chest_wounds = body.get_wounds(BodyPart.CHEST)
    assert_lt(chest_wounds[0].severity, WoundType.SEVERE, "Severe wound should improve with treatment")

# Multiple Wound System
func test_wound_stacking() -> void:
    body.apply_wound(WoundType.LIGHT, BodyPart.RIGHT_ARM)
    body.apply_wound(WoundType.MODERATE, BodyPart.RIGHT_ARM)
    
    var arm_wounds = body.get_wounds(BodyPart.RIGHT_ARM)
    assert_eq(arm_wounds.size(), 2, "Should have two wounds")
    assert_true(body.is_limb_impaired(BodyPart.RIGHT_ARM), "Multiple wounds should impair")

func test_max_wounds() -> void:
    # Head can only take 2 wounds
    body.apply_wound(WoundType.LIGHT, BodyPart.HEAD)
    body.apply_wound(WoundType.LIGHT, BodyPart.HEAD)
    body.apply_wound(WoundType.LIGHT, BodyPart.HEAD)
    
    var head_wounds = body.get_wounds(BodyPart.HEAD)
    assert_eq(head_wounds.size(), 2, "Head should not exceed max wounds")

# Death System
func test_death_conditions() -> void:
    watch_signals(body)
    
    # Test death from vital hit
    body.apply_wound(WoundType.FATAL, BodyPart.NECK)
    assert_true(body.is_dead, "Fatal neck wound should cause death")
    assert_signal_emitted(body, "died")
    
    # Test death from blood loss
    body = BodyComponent.new()  # Reset
    body._ready()  # Initialize wounds dictionary
    
    # Apply multiple bleeding wounds
    body.apply_wound(WoundType.SEVERE, BodyPart.LEFT_ARM)
    body.apply_wound(WoundType.SEVERE, BodyPart.RIGHT_ARM)
    body.apply_wound(WoundType.SEVERE, BodyPart.LEFT_LEG)
    
    # Process bleeding until death
    var max_turns = 20
    var turns = 0
    while not body.is_dead and turns < max_turns:
        body.process_bleeding()
        turns += 1
    
    assert_true(body.is_dead, "Excessive blood loss should cause death")

# Edge Cases
func test_wound_on_dead_body() -> void:
    body.apply_wound(WoundType.FATAL, BodyPart.HEAD)
    var wound_count = body.get_wounds().size()
    
    body.apply_wound(WoundType.LIGHT, BodyPart.LEFT_ARM)
    assert_eq(body.get_wounds().size(), wound_count, "Dead body should not receive new wounds")

func test_invalid_treatment() -> void:
    body.treat_wound(BodyPart.CHEST, 0, TreatmentType.BANDAGE)  # No wound exists
    var chest_wounds = body.get_wounds(BodyPart.CHEST)
    assert_eq(chest_wounds.size(), 0, "Should handle invalid treatment gracefully")

# Adjacent Wound Tests
func test_adjacent_wound_effects() -> void:
    # Test chest + abdomen wounds
    body.apply_wound(WoundType.MODERATE, BodyPart.CHEST)
    body.apply_wound(WoundType.MODERATE, BodyPart.ABDOMEN)
    
    # Should have greater effect than individual wounds
    var chest_wounds = body.get_wounds(BodyPart.CHEST)
    var abdomen_wounds = body.get_wounds(BodyPart.ABDOMEN)
    assert_true(WoundEffect.INTERNAL in chest_wounds[0].effects or 
               WoundEffect.INTERNAL in abdomen_wounds[0].effects,
               "Adjacent torso wounds should risk internal bleeding")

func test_movement_impairment() -> void:
    # Test single leg wound
    body.apply_wound(WoundType.MODERATE, BodyPart.LEFT_LEG)
    var left_leg_wounds = body.get_wounds(BodyPart.LEFT_LEG)
    
    # Test both legs wounded
    body.apply_wound(WoundType.MODERATE, BodyPart.RIGHT_LEG)
    var right_leg_wounds = body.get_wounds(BodyPart.RIGHT_LEG)
    
    assert_true(body.is_limb_impaired(BodyPart.LEFT_LEG) and body.is_limb_impaired(BodyPart.RIGHT_LEG), 
                "Both legs should be impaired")

func test_arm_coordination() -> void:
    # Test single arm wound
    body.apply_wound(WoundType.MODERATE, BodyPart.LEFT_ARM)
    var left_arm_wounds = body.get_wounds(BodyPart.LEFT_ARM)
    
    # Test both arms wounded
    body.apply_wound(WoundType.MODERATE, BodyPart.RIGHT_ARM)
    var right_arm_wounds = body.get_wounds(BodyPart.RIGHT_ARM)
    
    assert_true(body.is_limb_impaired(BodyPart.LEFT_ARM) and body.is_limb_impaired(BodyPart.RIGHT_ARM), 
                "Both arms should be impaired")

func test_wound_chain_reaction() -> void:
    # Test how wounds can trigger cascading effects
    body.apply_wound(WoundType.MODERATE, BodyPart.NECK)
    body.apply_wound(WoundType.SEVERE, BodyPart.CHEST)
    
    # Process several turns to see effects spread
    for i in range(3):
        body.process_bleeding()
    
    # Check for cascading effects
    assert_gt(body.consciousness, 0, "Blood loss should increase consciousness")
    assert_true(body.get_total_bleeding() > 0, "Should have active bleeding") 