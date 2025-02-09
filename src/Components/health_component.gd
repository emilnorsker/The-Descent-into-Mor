extends Node
class_name HealthComponent

signal consciousness_check_failed
signal wound_applied(wound_type: int, body_part: int)
signal condition_applied(condition: int)
signal died

enum BodyPart {
	HEAD,
	NECK,
	CHEST,
	ABDOMEN,
	LEFT_ARM,
	RIGHT_ARM,
	LEFT_LEG,
	RIGHT_LEG
}

enum WoundType {
	LIGHT,
	MODERATE,
	SEVERE,
	CRITICAL,
	FATAL
}

enum WoundEffect {
	BLEEDING,
	PAIN,
	CRIPPLED,
	INTERNAL
}

var wounds = {}  # Dictionary of BodyPart -> Array of Wound
var consciousness = 0
var conditions = []
var is_dead = false

class Wound:
	var type: int  # WoundType
	var effects: Array  # Array of WoundEffect
	var severity: int  # 1-5
	var bleeding_rate: int
	var treatment_level: int  # 0 = untreated, 1 = bandaged, 2 = stitched
	
	func _init(p_type: int, p_severity: int):
		type = p_type
		severity = p_severity
		effects = []
		bleeding_rate = 0
		treatment_level = 0
		
		# Apply effects based on type and severity
		match type:
			WoundType.LIGHT:
				if severity > 2:
					effects.append(WoundEffect.BLEEDING)
			WoundType.MODERATE:
				effects.append(WoundEffect.BLEEDING)
				effects.append(WoundEffect.PAIN)
			WoundType.SEVERE:
				effects.append(WoundEffect.BLEEDING)
				effects.append(WoundEffect.PAIN)
				effects.append(WoundEffect.CRIPPLED)
			WoundType.CRITICAL:
				effects.append(WoundEffect.BLEEDING)
				effects.append(WoundEffect.PAIN)
				effects.append(WoundEffect.CRIPPLED)
				effects.append(WoundEffect.INTERNAL)
			WoundType.FATAL:
				effects.append_array([WoundEffect.BLEEDING, WoundEffect.PAIN, 
								   WoundEffect.CRIPPLED, WoundEffect.INTERNAL])
		
		# Set bleeding rate based on severity and effects
		if WoundEffect.BLEEDING in effects:
			bleeding_rate = severity

func _ready():
	# Initialize wounds dictionary for each body part
	for part in BodyPart.values():
		wounds[part] = []

func apply_wound(type: int, body_part: int, severity: int = 1) -> void:
	if is_dead:
		return
		
	var wound = Wound.new(type, severity)
	wounds[body_part].append(wound)
	
	# Add consciousness based on wound severity and location
	var consciousness_gain = severity
	match body_part:
		BodyPart.HEAD:
			consciousness_gain *= 2
		BodyPart.NECK:
			consciousness_gain *= 1.5
		BodyPart.CHEST:
			consciousness_gain *= 1.25
	
	add_consciousness(consciousness_gain)
	
	emit_signal("wound_applied", type, body_part)
	
	# Check for instant death conditions
	if type == WoundType.FATAL and (body_part == BodyPart.HEAD or body_part == BodyPart.NECK):
		die()

func add_consciousness(amount: int) -> void:
	consciousness += amount
	check_consciousness()

func check_consciousness() -> void:
	if consciousness >= 10:
		# Roll to stay conscious (1d6)
		var roll = randi() % 6 + 1
		if roll < 4:  # Need 4+ to stay conscious
			emit_signal("consciousness_check_failed")
			apply_condition("unconscious")

func process_bleeding() -> void:
	var total_bleeding = 0
	
	# Calculate total bleeding from all wounds
	for part in wounds.keys():
		for wound in wounds[part]:
			if wound.treatment_level == 0 and WoundEffect.BLEEDING in wound.effects:
				total_bleeding += wound.bleeding_rate
	
	if total_bleeding > 0:
		add_consciousness(total_bleeding / 2)  # Consciousness from blood loss

func treat_wound(body_part: int, wound_index: int, treatment_level: int) -> void:
	if wound_index < wounds[body_part].size():
		var wound = wounds[body_part][wound_index]
		wound.treatment_level = treatment_level
		
		# Reduce bleeding based on treatment
		if treatment_level > 0 and WoundEffect.BLEEDING in wound.effects:
			wound.bleeding_rate = max(0, wound.bleeding_rate - treatment_level)

func apply_condition(condition: String) -> void:
	if not condition in conditions:
		conditions.append(condition)
		emit_signal("condition_applied", condition)

func remove_condition(condition: String) -> void:
	conditions.erase(condition)

func has_condition(condition: String) -> bool:
	return condition in conditions

func is_limb_impaired(body_part: int) -> bool:
	for wound in wounds[body_part]:
		if WoundEffect.CRIPPLED in wound.effects:
			return true
	return false

func get_total_bleeding() -> int:
	var total = 0
	for part in wounds.keys():
		for wound in wounds[part]:
			if wound.treatment_level == 0 and WoundEffect.BLEEDING in wound.effects:
				total += wound.bleeding_rate
	return total

func die() -> void:
	is_dead = true
	emit_signal("died")

func get_wounds_of_type(type: int) -> Array:
	var result = []
	for part in wounds.keys():
		for wound in wounds[part]:
			if wound.type == type:
				result.append({"part": part, "wound": wound})
	return result

func process_recovery() -> void:
	# Natural consciousness recovery
	if consciousness > 0:
		consciousness = max(0, consciousness - 1)
		
	# Process wound recovery
	for part in wounds.keys():
		for wound in wounds[part]:
			if wound.treatment_level > 0:
				# Treated wounds can improve
				if wound.severity > 1 and randf() < 0.1:  # 10% chance per turn
					wound.severity -= 1
					if wound.severity == 0:
						wounds[part].erase(wound) 