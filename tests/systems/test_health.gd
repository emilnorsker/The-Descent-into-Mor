extends GutTest

const TestHumanoid = preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres")
const TestWoundedHumanoid = preload("res://tests/fixtures/blueprints/actors/test_wounded_humanoid.tres")

var BodyPart = Constants.BodyPart
var WoundType = Constants.WoundType
var WoundEffect = Constants.WoundEffect
var StatusEffect = Constants.StatusEffect
var TreatmentType = Constants.TreatmentType

var entity: Entity
var body: BodyComponent

func before_each() -> void:
    var test_level = preload("res://tests/fixtures/test_level.tres")
    GameMap.load_level(test_level)
    
    # Create test entity with body using blueprint
    entity = Entity.new().setup_from_blueprint(TestHumanoid, Vector2i(1, 1))
    GameMap.register_entity(entity, Vector2i(1, 1))
    
    body = entity.components.body
    add_child_autofree(body)

func after_each() -> void:
    GameMap.clear()
    body = null

# Basic Wound Tests
func test_apply_wound() -> void:
    body.apply_wound(BodyPart.LEFT_ARM, WoundType.LIGHT)
    
    assert_true(body.get_wounds(BodyPart.LEFT_ARM), "Left arm should be wounded")
    assert_eq(body.get_wounds(BodyPart.LEFT_ARM).size(), 1, "Should have one wound")
    assert_eq(body.get_wounds(BodyPart.LEFT_ARM)[0].type, WoundType.LIGHT, "Should be light wound")

func test_vital_hit() -> void:
    watch_signals(body)
    body.apply_wound(BodyPart.HEART, WoundType.CRITICAL)
    
    assert_true(body.is_fatally_wounded(), "Critical heart wound should be fatal")
    assert_signal_emitted(body, "fatal_wound")

# Wound Effects
func test_bleeding_effects() -> void:
    body.apply_wound(BodyPart.CHEST, WoundType.BLEEDING)
    
    assert_true(body.is_bleeding(BodyPart.CHEST), "Chest should be bleeding")
    var bleed_rate = body.get_bleed_rate(BodyPart.CHEST)
    assert_eq(bleed_rate, 1.0, "Chest should have normal bleed rate")
    
    body.apply_wound(BodyPart.NECK, WoundType.BLEEDING)
    assert_eq(body.get_bleed_rate(BodyPart.NECK), 2.0, "Neck should have higher bleed rate")

func test_impairment() -> void:
    body.apply_wound(BodyPart.RIGHT_ARM, WoundType.SEVERE)
    
    assert_true(body.is_part_impaired(BodyPart.RIGHT_ARM), "Right arm should be impaired")
    assert_true(body.has_effect(BodyPart.RIGHT_ARM, WoundEffect.CRIPPLED), "Right arm should be crippled")

# Consciousness System
func test_consciousness_gain() -> void:
    body.apply_wound(BodyPart.HEAD, WoundType.MODERATE)
    var consciousness = body.get_consciousness()
    
    assert_gt(consciousness, 0, "Should gain consciousness from head wound")
    
    body.apply_wound(BodyPart.CHEST, WoundType.MODERATE)
    assert_lt(body.get_consciousness() - consciousness, 2.0, 
            "Chest wound should cause less consciousness gain than head")

func test_consciousness_check() -> void:
    watch_signals(body)
    
    # Apply multiple wounds to raise consciousness
    body.apply_wound(BodyPart.HEAD, WoundType.SEVERE)
    body.apply_wound(BodyPart.CHEST, WoundType.SEVERE)
    
    assert_true(body.get_consciousness() >= 8, "Should have high consciousness")
    body.check_consciousness()
    
    assert_signal_emitted(body, "consciousness_check_failed")
    assert_true(body.is_unconscious(), "Should be unconscious")

# Treatment System
func test_wound_treatment() -> void:
    body.apply_wound(BodyPart.LEFT_ARM, WoundType.BLEEDING)
    var initial_bleed = body.get_bleed_rate(BodyPart.LEFT_ARM)
    
    body.treat_wound(BodyPart.LEFT_ARM, 0, TreatmentType.BANDAGE)
    assert_lt(body.get_bleed_rate(BodyPart.LEFT_ARM), initial_bleed, "Bandage should reduce bleeding")
    
    body.treat_wound(BodyPart.LEFT_ARM, 0, TreatmentType.STITCHES)
    assert_eq(body.get_bleed_rate(BodyPart.LEFT_ARM), 0, "Stitches should stop bleeding")

# Recovery System
func test_natural_healing() -> void:
    body.apply_wound(BodyPart.LEFT_LEG, WoundType.LIGHT)
    body.treat_wound(BodyPart.LEFT_LEG, 0, TreatmentType.BANDAGE)
    
    # Simulate time passing
    for i in range(5):
        body.process_recovery()
    
    assert_false(body.get_wounds(BodyPart.LEFT_LEG), "Light wound should heal naturally")

func test_severe_wound_recovery() -> void:
    body.apply_wound(BodyPart.CHEST, WoundType.SEVERE)
    body.treat_wound(BodyPart.CHEST, 0, TreatmentType.STITCHES)
    
    # Simulate time passing
    for i in range(10):
        body.process_recovery()
    
    var wound = body.get_wound(BodyPart.CHEST, 0)
    assert_lt(wound.severity, WoundType.SEVERE, "Severe wound should improve with treatment")

# Multiple Wound System
func test_wound_stacking() -> void:
    body.apply_wound(BodyPart.RIGHT_ARM, WoundType.LIGHT)
    body.apply_wound(BodyPart.RIGHT_ARM, WoundType.MODERATE)
    
    assert_eq(body.get_wound_count(BodyPart.RIGHT_ARM), 2, "Should have two wounds")
    assert_true(body.is_part_impaired(BodyPart.RIGHT_ARM), "Multiple wounds should impair")

func test_max_wounds() -> void:
    # Head can only take 2 wounds
    body.apply_wound(BodyPart.HEAD, WoundType.LIGHT)
    body.apply_wound(BodyPart.HEAD, WoundType.LIGHT)
    body.apply_wound(BodyPart.HEAD, WoundType.LIGHT)
    
    assert_eq(body.get_wound_count(BodyPart.HEAD), 2, "Head should not exceed max wounds")

# Death System
func test_death_conditions() -> void:
    watch_signals(body)
    
    # Test death from vital hit
    body.apply_wound(BodyPart.NECK, WoundType.FATAL)
    assert_true(body.is_dead(), "Fatal neck wound should cause death")
    assert_signal_emitted(body, "died")
    
    # Test death from blood loss
    body = BodyComponent.new()  # Reset
    body.apply_wound(BodyPart.LEFT_ARM, WoundType.BLEEDING)
    body.apply_wound(BodyPart.RIGHT_ARM, WoundType.BLEEDING)
    body.apply_wound(BodyPart.LEFT_LEG, WoundType.BLEEDING)
    
    for i in range(10):  # Simulate severe blood loss
        body.process_bleeding()
    
    assert_true(body.is_dead(), "Excessive blood loss should cause death")

# Edge Cases
func test_wound_on_dead_body() -> void:
    body.apply_wound(BodyPart.HEART, WoundType.FATAL)
    var wound_count = body.get_total_wound_count()
    
    body.apply_wound(BodyPart.LEFT_ARM, WoundType.LIGHT)
    assert_eq(body.get_total_wound_count(), wound_count, "Dead body should not receive new wounds")

func test_invalid_treatment() -> void:
    body.treat_wound(BodyPart.CHEST, 0, TreatmentType.BANDAGE)  # No wound exists
    assert_eq(body.get_wound_count(BodyPart.CHEST), 0, "Should handle invalid treatment gracefully")

# Adjacent Wound Tests
func test_adjacent_wound_effects() -> void:
    # Test chest + abdomen wounds
    body.apply_wound(BodyPart.CHEST, WoundType.MODERATE)
    body.apply_wound(BodyPart.ABDOMEN, WoundType.MODERATE)
    
    # Should have greater effect than individual wounds
    var combined_effect = body.get_torso_impairment()
    var single_wound = body.get_part_impairment(BodyPart.CHEST)
    assert_gt(combined_effect, single_wound, "Adjacent wounds should have greater effect")
    
    # Test for internal bleeding risk
    assert_true(body.has_effect(BodyPart.CHEST, WoundEffect.INTERNAL) or 
               body.has_effect(BodyPart.ABDOMEN, WoundEffect.INTERNAL),
               "Adjacent torso wounds should risk internal bleeding")

func test_movement_impairment() -> void:
    # Test single leg wound
    body.apply_wound(BodyPart.LEFT_LEG, WoundType.MODERATE)
    var single_leg_movement = body.get_movement_multiplier()
    
    # Test both legs wounded
    body.apply_wound(BodyPart.RIGHT_LEG, WoundType.MODERATE)
    var both_legs_movement = body.get_movement_multiplier()
    
    assert_lt(both_legs_movement, single_leg_movement, "Two wounded legs should impair more than one")
    assert_true(body.has_status(StatusEffect.PRONE_TO_FALLING), "Wounded legs should risk falling")

func test_arm_coordination() -> void:
    # Test single arm wound
    body.apply_wound(BodyPart.LEFT_ARM, WoundType.MODERATE)
    var single_arm_penalty = body.get_action_penalty()
    
    # Test both arms wounded
    body.apply_wound(BodyPart.RIGHT_ARM, WoundType.MODERATE)
    var both_arms_penalty = body.get_action_penalty()
    
    assert_gt(both_arms_penalty, single_arm_penalty, "Two wounded arms should cause greater penalty")
    assert_true(body.has_status(StatusEffect.DISARMED), "Two wounded arms should cause disarming")

func test_wound_chain_reaction() -> void:
    # Test how wounds can trigger cascading effects
    body.apply_wound(BodyPart.NECK, WoundType.BLEEDING)
    body.apply_wound(BodyPart.CHEST, WoundType.INTERNAL)
    
    # Process several turns to see effects spread
    for i in range(3):
        body.process_bleeding()
        body.process_effects()
    
    # Check for cascading effects
    assert_true(body.has_status(StatusEffect.WEAKENED), "Blood loss should cause weakness")
    assert_true(body.has_status(StatusEffect.SHOCK_RISK), "Multiple serious wounds should risk shock")
    
    # Test consciousness impact
    var consciousness = body.get_consciousness()
    body.process_bleeding()
    assert_gt(body.get_consciousness(), consciousness, "Effects should compound over time") 