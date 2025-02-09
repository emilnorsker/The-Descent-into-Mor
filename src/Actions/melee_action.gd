extends Action
class_name MeleeAction

var body_part: int
var weapon: Entity

func _init(p_performer: Entity, p_target: Entity, p_body_part: int, p_weapon: Entity = null) -> void:
	super(p_performer, p_target)
	body_part = p_body_part
	weapon = p_weapon

func perform() -> bool:
	if not is_valid():
		return false
		
	if weapon:
		return _perform_weapon_attack()
	else:
		return _perform_natural_attack()

func _perform_weapon_attack() -> bool:
	var damage = weapon.get_component("WeaponComponent").damage
	var damage_type = weapon.get_component("DamageTypeComponent").type
	var wound_type = _calculate_wound_type(damage, damage_type)
	
	target.body_component.apply_wound(Constants.BodyPart.CHEST, wound_type, damage)
	return true

func _perform_natural_attack() -> bool:
	var body_data = performer.body_component.get_part_data(body_part)
	var damage = body_data.damage
	var damage_type = body_data.damage_type
	var wound_type = _calculate_wound_type(damage, damage_type)
	
	if body_part == Constants.BodyPart.HEAD:
		# Headbutt also damages attacker
		performer.body_component.apply_wound(Constants.BodyPart.HEAD, Constants.WoundType.LIGHT)
	elif body_part in [Constants.BodyPart.LEFT_LEG, Constants.BodyPart.RIGHT_LEG]:
		# Kicks target the abdomen and do moderate damage
		target.body_component.apply_wound(Constants.BodyPart.ABDOMEN, Constants.WoundType.MODERATE)
		return true
	
	target.body_component.apply_wound(Constants.BodyPart.CHEST, wound_type, damage)
	return true

func _calculate_wound_type(damage: int, damage_type: int) -> int:
	# Base wound type on damage
	var wound_type = Constants.WoundType.LIGHT
	if damage >= 4:
		wound_type = Constants.WoundType.CRITICAL
	elif damage >= 3:
		wound_type = Constants.WoundType.SEVERE
	elif damage >= 2:
		wound_type = Constants.WoundType.MODERATE
		
	# Adjust based on damage type
	match damage_type:
		Constants.DamageType.SLASH:
			wound_type = min(wound_type + 1, Constants.WoundType.CRITICAL)
		Constants.DamageType.PIERCE:
			if wound_type >= Constants.WoundType.MODERATE:
				wound_type = min(wound_type + 1, Constants.WoundType.CRITICAL)
	
	return wound_type

func is_valid() -> bool:
	if not target:
		return false
		
	var distance = (target.grid_position - performer.grid_position).length()
	return distance <= get_range()

func get_range() -> int:
	if weapon:
		return weapon.get_component("WeaponComponent").range
	else:
		return performer.body_component.get_part_data(body_part).range 