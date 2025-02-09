extends Action
class_name ThrowAction

var item: Entity

func _init(p_performer: Entity, p_target: Entity, p_item: Entity) -> void:
	super(p_performer, p_target)
	item = p_item

func perform() -> bool:
	if not is_valid():
		return false
		
	var damage = get_damage()
	var damage_type = Constants.DamageType.BLUNT
	
	if item.has_component("DamageTypeComponent"):
		damage_type = item.get_component("DamageTypeComponent").type
	
	target.body_component.apply_wound(Constants.BodyPart.CHEST, damage_type, damage)
	performer.inventory_component.remove_item(item)
	return true

func get_damage() -> int:
	if item.has_component("WeaponComponent"):
		return item.get_component("WeaponComponent").damage
	else:
		# Generic items do weight-based damage
		return ceil(item.get_component("WeightComponent").weight * 0.01)

func get_max_range() -> int:
	var weight = item.get_component("WeightComponent").weight
	return 10 - ceil(weight * 2)

func is_valid() -> bool:
	if not target or not item:
		return false
		
	var distance = (target.grid_position - performer.grid_position).length()
	return distance <= get_max_range() 