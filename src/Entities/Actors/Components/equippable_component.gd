class_name EquippableComponent
extends Component

enum EquipmentType {WEAPON, ARMOR}

var equipment_type: EquipmentType
var power_bonus: int
var defense_bonus: int

func _init(blueprint: EquippableComponentBlueprint) -> void:
	equipment_type = blueprint.equipment_type
	power_bonus = blueprint.power_bonus
	defense_bonus = blueprint.defense_bonus

func get_save_data() -> Dictionary:
	return {
		"equipment_type": equipment_type,
		"power_bonus": power_bonus,
		"defense_bonus": defense_bonus
	}

func restore(save_data: Dictionary) -> void:
	equipment_type = save_data["equipment_type"]
	power_bonus = save_data["power_bonus"]
	defense_bonus = save_data["defense_bonus"]
