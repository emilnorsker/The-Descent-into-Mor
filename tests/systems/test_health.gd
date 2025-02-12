extends GutTest

const TestHumanoid = preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres")
const TestWoundedHumanoid = preload("res://tests/fixtures/blueprints/actors/test_wounded_humanoid.tres")

var entity: Entity
var body: BodyComponent

func before_each() -> void:
    var test_level = load("res://tests/fixtures/test_level.tres")
    GameMap.load_level(test_level)
    
    # Create test entity with body using blueprint
    entity = Entity.new(TestHumanoid, Vector2i(1, 1))
    GameMap.register_entity(entity, Vector2i(1, 1))
    
    body = entity.body

func after_each() -> void:
    GameMap.clear()
    body = null
    entity = null
# Basic Wound Tests
func test_apply_wound() -> void:
    body.apply_wound(BodyComponent.WoundType.LIGHT,  BodyComponent.BodyPart.LEFT_ARM)
    
    var wounds = body.get_wounds(BodyComponent.BodyPart.LEFT_ARM)
    assert_true(wounds.size() > 0, "Left arm should be wounded")
    assert_eq(wounds.size(), 1, "Should have one wound")
    assert_eq(wounds[0].type, BodyComponent.WoundType.LIGHT, "Should be light wound")

# func test_vital_hit() -> void:
#     watch_signals(body)
#     body.apply_wound(BodyComponent.WoundType.FATAL,  BodyComponent.BodyPart.HEAD)
    
#     assert_true(body.is_dead, "Fatal head wound should be fatal")
#     assert_signal_emitted(body, "died")


# # Consciousness System
# func test_consciousness_loss() -> void:
#     var consciousness = body.consciousness
#     body.apply_wound(BodyComponent.WoundType.MODERATE,  BodyComponent.BodyPart.HEAD)
#     assert_lt(body.consciousness, consciousness, "Should lose consciousness from head wound")
    
#     body.apply_wound(BodyComponent.WoundType.MODERATE,  BodyComponent.BodyPart.CHEST)
#     assert_lt(body.consciousness - consciousness, 2.0, 
#             "Chest wound should cause less consciousness gain than head")

# func test_consciousness_check() -> void:
#     watch_signals(body)
    
#     # Apply multiple wounds to raise consciousness
#     body.apply_wound(BodyComponent.WoundType.LIGHT,  BodyComponent.BodyPart.CHEST)
#     body.apply_wound(BodyComponent.WoundType.FATAL,  BodyComponent.BodyPart.HEAD)

    
#     assert_true(body.consciousness <= 15, "Should have low consciousness")
#     body.check_consciousness()
    
#     assert_signal_emitted(body, "consciousness_check_failed")
#     assert_true(body.is_dead, "Should be dead from consciousness check")



# TODO:Treatment System
# func test_wound_treatment() -> void:
    # body.apply_wound(BodyComponent.WoundType.MODERATE,  BodyComponent.BodyPart.LEFT_ARM)
    # var initial_bleeding = body.get_total_bleeding()
    
    # body.treat_wound(BodyComponent.BodyPart.LEFT_ARM, 0, TreatmentType.BANDAGE)
    # assert_lt(body.get_total_bleeding(), initial_bleeding, "Bandage should reduce bleeding")
    
    # body.treat_wound(BodyComponent.BodyPart.LEFT_ARM, 0, TreatmentType.STITCHES)
    # assert_eq(body.get_total_bleeding(), 0, "Stitches should stop bleeding")

# # Recovery System
# func test_natural_healing() -> void:
#     body.apply_wound(BodyComponent.WoundType.LIGHT,  BodyComponent.BodyPart.LEFT_LEG)
#     body.treat_wound(BodyComponent.BodyPart.LEFT_LEG, 0, TreatmentType.BANDAGE)
    
#     # Simulate time passing
#     for i in range(5):
#         body.process_recovery()
    
#     var leg_wounds = body.get_wounds(BodyComponent.BodyPart.LEFT_LEG)
#     assert_true(leg_wounds.is_empty(), "Light wound should heal naturally")

# func test_severe_wound_recovery() -> void:
#     body.apply_wound(BodyComponent.WoundType.SEVERE,  BodyComponent.BodyPart.CHEST)
#     body.treat_wound(BodyComponent.BodyPart.CHEST, 0, TreatmentType.STITCHES)
    
#     # Simulate time passing
#     for i in range(10):
#         body.process_recovery()
    
#     var chest_wounds = body.get_wounds(BodyComponent.BodyPart.CHEST)
#     assert_lt(chest_wounds[0].severity, BodyComponent.WoundType.SEVERE, "Severe wound should improve with treatment")

# # Multiple Wound System
# func test_wound_stacking() -> void:
#     body.apply_wound(BodyComponent.WoundType.SEVERE,  BodyComponent.BodyPart.RIGHT_ARM)
#     body.apply_wound(BodyComponent.WoundType.SEVERE,  BodyComponent.BodyPart.RIGHT_ARM)
    
#     var arm_wounds = body.get_wounds(BodyComponent.BodyPart.RIGHT_ARM)
#     print(arm_wounds)
#     assert_eq(arm_wounds.size(), 2, "Should have two wounds")
#     # assert_true(body.is_limb_impaired(BodyComponent.BodyPart.RIGHT_ARM), "Multiple wounds should impair")

# # func test_max_wounds() -> void:
# #     # Head can only take 2 wounds
# #     body.apply_wound(BodyComponent.WoundType.LIGHT,  BodyComponent.BodyPart.HEAD)
# #     body.apply_wound(BodyComponent.WoundType.LIGHT,  BodyComponent.BodyPart.HEAD)
# #     body.apply_wound(BodyComponent.WoundType.LIGHT,  BodyComponent.BodyPart.HEAD)
    
# #     var head_wounds = body.get_wounds(BodyComponent.BodyPart.HEAD)
# #     assert_eq(head_wounds.size(), 2, "Head should not exceed max wounds")

# # Death System
# func test_death_conditions() -> void:
#     watch_signals(body)
    
#     # Test death from vital hit
#     body.apply_wound(BodyComponent.WoundType.FATAL,  BodyComponent.BodyPart.NECK)
#     assert_true(body.is_dead, "Fatal neck wound should cause death")
#     assert_signal_emitted(body, "died")
    
#     # Test death from blood loss
#     body = BodyComponent.new()  # Reset
#     body._ready()  # Initialize wounds dictionary
    
#     # Apply multiple bleeding wounds
#     body.apply_wound(BodyComponent.WoundType.SEVERE,  BodyComponent.BodyPart.LEFT_ARM)
#     body.apply_wound(BodyComponent.WoundType.SEVERE,  BodyComponent.BodyPart.RIGHT_ARM)
#     body.apply_wound(BodyComponent.WoundType.SEVERE,  BodyComponent.BodyPart.LEFT_LEG)


##############
    
    # # Process bleeding until death
    # var max_turns = 20
    # var turns = 0
    # while not body.is_dead and turns < max_turns:
    #     body.process_bleeding()
    #     turns += 1
    
    # assert_true(body.is_dead, "Excessive blood loss should cause death")
################

# # Edge Cases
# func test_wound_on_dead_body() -> void:
#     body.apply_wound(BodyComponent.WoundType.FATAL,  BodyComponent.BodyPart.HEAD)
#     var wound_count = body.get_wounds().size()
    
#     body.apply_wound(BodyComponent.WoundType.LIGHT,  BodyComponent.BodyPart.LEFT_ARM)
#     assert_eq(body.get_wounds().size(), 1, "Dead body should receive new wounds")


# func test_invalid_treatment() -> void:
#     body.treat_wound(BodyComponent.BodyPart.CHEST, 0, TreatmentType.BANDAGE)  # No wound exists
#     var chest_wounds = body.get_wounds(BodyComponent.BodyPart.CHEST)
#     assert_eq(chest_wounds.size(), 0, "Should handle invalid treatment gracefully")

