extends Node
class_name CombatModifierComponent

var states = {}
var positions = {}
var environments = {}

func apply_state(state: String, entity = null, body_part = null) -> void:
	states[state] = {
		"entity": entity,
		"body_part": body_part,
		"intensity": 1.0
	}

func apply_position(position: String) -> void:
	positions[position] = true

func apply_environment(environment: String) -> void:
	environments[environment] = true

func has_state(state: String) -> bool:
	return states.has(state)

func has_position(position: String) -> bool:
	return positions.has(position)

func has_environment(environment: String) -> bool:
	return environments.has(environment)

func get_ablaze_intensity() -> float:
	if not has_state("ablaze"):
		return 0.0
	return states["ablaze"].intensity

func leaves_trail() -> bool:
	return has_state("bleeding")

func causes_weakness() -> bool:
	return has_state("bleeding")

func attracts_predators() -> bool:
	return has_state("bleeding")

func needs_recovery() -> bool:
	return has_state("winded")

func affects_reactions() -> bool:
	return has_state("winded")

func vision_affected() -> bool:
	return has_state("winded")

func hard_to_defend() -> bool:
	return has_position("flanking")

func better_angles() -> bool:
	return has_position("flanking")

func exposed_position() -> bool:
	return has_position("flanking")

func is_treacherous() -> bool:
	return has_state("mud_covered") and has_position("high_ground")

func can_cause_slides() -> bool:
	return has_state("mud_covered") and has_position("high_ground")

func provides_defense() -> bool:
	return has_position("high_ground")

func causes_panic() -> bool:
	return has_state("ablaze") and has_position("pinned")

func ground_slick() -> bool:
	return has_environment("rain")

func vision_reduced() -> bool:
	return has_environment("rain")

func metal_slippery() -> bool:
	return has_environment("rain")

func movement_hidden() -> bool:
	return has_environment("darkness")

func vision_severely_reduced() -> bool:
	return has_environment("rain") and has_environment("darkness") 