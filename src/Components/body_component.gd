extends Node
class_name BodyComponent

var type: String
var parts: Dictionary
var wounds: Dictionary = {}
var consciousness: float = 0.0

func _init(properties: Dictionary = {}) -> void:
	type = properties.get("type", "humanoid")
	parts = properties.get("parts", {})
	
	# Initialize wounds dictionary
	for part in parts.keys():
		wounds[part] = []

func apply_wound(body_part: int, wound_type: int, severity: int = 1) -> void:
	if not parts.has(body_part):
		return
		
	var wound = {
		"type": wound_type,
		"severity": severity,
		"effects": []
	}
	
	# Add wound effects based on type and severity
	match wound_type:
		Constants.WoundType.LIGHT:
			if severity > 2:
				wound.effects.append(Constants.WoundEffect.BLEEDING)
		Constants.WoundType.MODERATE:
			wound.effects.append(Constants.WoundEffect.BLEEDING)
			wound.effects.append(Constants.WoundEffect.PAIN)
		Constants.WoundType.SEVERE:
			wound.effects.append(Constants.WoundEffect.BLEEDING)
			wound.effects.append(Constants.WoundEffect.PAIN)
			wound.effects.append(Constants.WoundEffect.CRIPPLED)
		Constants.WoundType.CRITICAL, Constants.WoundType.FATAL:
			wound.effects.append_array([
				Constants.WoundEffect.BLEEDING,
				Constants.WoundEffect.PAIN,
				Constants.WoundEffect.CRIPPLED,
				Constants.WoundEffect.INTERNAL
			])
	
	wounds[body_part].append(wound)
	
	# Update consciousness based on wound
	var consciousness_gain = severity
	match body_part:
		Constants.BodyPart.HEAD:
			consciousness_gain *= 2
		Constants.BodyPart.NECK:
			consciousness_gain *= 1.5
		Constants.BodyPart.CHEST:
			consciousness_gain *= 1.25
	
	consciousness += consciousness_gain

func has_wound(body_part: int) -> bool:
	return wounds.has(body_part) and not wounds[body_part].is_empty()

func get_wound_type(body_part: int, index: int) -> int:
	if not has_wound(body_part) or index >= wounds[body_part].size():
		return -1
	return wounds[body_part][index].type

func is_bleeding(body_part: int) -> bool:
	if not has_wound(body_part):
		return false
		
	for wound in wounds[body_part]:
		if Constants.WoundEffect.BLEEDING in wound.effects:
			return true
	return false

func get_part_data(body_part: int) -> Dictionary:
	return parts.get(body_part, {}) 