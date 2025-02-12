extends GutTest

# The anatomy system handles mapping of damage between different creature anatomies.
# For example, when a humanoid attacks a snake's "hand" (which doesn't exist),
# the system needs to intelligently map that to an appropriate part of the snake's body.

var anatomy_mapper: AnatomyMapper
var human_anatomy: AnatomyBlueprint
var snake_anatomy: AnatomyBlueprint
var multi_armed_anatomy: AnatomyBlueprint

func before_each() -> void:
	anatomy_mapper = AnatomyMapper.new()
	add_child(anatomy_mapper)
	
	# Load anatomy blueprints for different creature types
	human_anatomy = load("res://assets/blueprints/anatomies/human_anatomy.tres")
	snake_anatomy = load("res://assets/blueprints/anatomies/snake_anatomy.tres")
	multi_armed_anatomy = load("res://assets/blueprints/anatomies/multi_armed_anatomy.tres")
	
	# Register anatomies with mapper for cross-anatomy translations
	anatomy_mapper.register_anatomy(human_anatomy)
	anatomy_mapper.register_anatomy(snake_anatomy)
	anatomy_mapper.register_anatomy(multi_armed_anatomy)

func after_each() -> void:
	anatomy_mapper.queue_free()

# Test Case: Mapping a humanoid hand to a snake's anatomy
# Logic Flow:
# 1. A humanoid attacks a snake's "left_hand"
# 2. Since snakes don't have hands, the system should:
#    a. Recognize that "hand" maps to "body_front" based on mapping rules
#    b. Apply appropriate damage modifiers for the translated location
#    c. Use single distribution since we're mapping to one specific part
# 3. The mapping should maintain reasonable damage scaling
func test_hand_to_snake_mapping() -> void:
	var result = anatomy_mapper.map_damage_location("left_hand", "humanoid", "serpentine")
	
	# Should map to exactly one target (the front section)
	assert_eq(result.target_nodes.size(), 1, "Should map to a single target")
	assert_eq(result.target_nodes[0], "body_front", "Hand should map to body_front on snake")
	
	# Should use single distribution since we're mapping to one specific part
	assert_eq(result.distribution_type, "single", "Should use single distribution")
	
	# Damage modifier should be reduced since hitting a larger body section
	assert_eq(result.damage_modifiers[0], 0.75, "Should apply correct damage modifier")

# Test Case: Mapping a humanoid wing attack to a multi-armed creature
# Logic Flow:
# 1. A humanoid attacks with a "wing_left" attack
# 2. For a multi-armed creature, this should:
#    a. Map to the entire left arm cluster (3 arms)
#    b. Distribute damage across all arms in the cluster
#    c. Scale damage appropriately for multi-target hit
# 3. This tests how the system handles one-to-many mappings
func test_wing_to_multi_armed_mapping() -> void:
	var result = anatomy_mapper.map_damage_location("wing_left", "humanoid", "multi_armed")
	
	# Should pick one arm from the cluster
	assert_eq(result.target_nodes.size(), 1, "Should map to a single target")
	assert_true(result.target_nodes[0].begins_with("arm_upper_left_"), "Should pick one of the left arms")
	
	# Should use single distribution since we're picking one target
	assert_eq(result.distribution_type, "single", "Should use single distribution")
	
	# Damage should not be split since we're hitting one arm
	assert_eq(result.damage_modifiers[0], 0.5, "Should use arm's damage modifier")

# Test Case: Mapping vital areas between different anatomies
# Logic Flow:
# 1. Attack targets a vital area (head)
# 2. The system should:
#    a. Recognize this is a vital area
#    b. Map to the corresponding vital area in the target anatomy
#    c. Maintain the high damage multiplier for vital hits
# 3. This tests preservation of critical hit zones across anatomies
func test_vital_area_mapping() -> void:
	var result = anatomy_mapper.map_damage_location("head", "humanoid", "serpentine")
	
	# Vital areas should map one-to-one
	assert_eq(result.target_nodes.size(), 1, "Should map to a single target")
	assert_eq(result.target_nodes[0], "head", "Head should map to head")
	
	# Vital area damage multiplier should be preserved
	assert_eq(result.damage_modifiers[0], 2.0, "Should maintain vital area damage multiplier")

# Test Case: Handling non-existent body parts
# Logic Flow:
# 1. Attack targets a body part that doesn't exist
# 2. The system should:
#    a. Recognize the part doesn't exist
#    b. Return an empty mapping rather than guessing
#    c. Allow the combat system to handle the miss
# 3. This tests graceful handling of invalid inputs
func test_nonexistent_part_mapping() -> void:
	var result = anatomy_mapper.map_damage_location("nonexistent_part", "humanoid", "serpentine")
	
	# Should return empty results for invalid parts
	assert_eq(result.target_nodes.size(), 0, "Should not map non-existent part")
	assert_eq(result.damage_modifiers.size(), 0, "Should not have damage modifiers")

# Test Case: Mapping symmetrical parts to a different anatomy
# Logic Flow:
# 1. Attack targets a symmetrical part (right arm)
# 2. When mapping to multi-armed creature:
#    a. Recognize this is a symmetrical part
#    b. Map to the corresponding arm cluster
#    c. Distribute damage across the cluster
# 3. This tests handling of symmetrical part mappings
func test_symmetrical_part_mapping() -> void:
	var result = anatomy_mapper.map_damage_location("right_arm", "humanoid", "multi_armed")
	
	# Should map to all arms in the right cluster
	assert_eq(result.target_nodes.size(), 3, "Should map to cluster of arms")
	assert_true(result.target_nodes.has("arm_upper_right_1"), "Should include first right arm")
	
	# Should use multiple distribution for symmetrical parts
	assert_eq(result.distribution_type, "multiple", "Should use multiple distribution for symmetrical parts") 