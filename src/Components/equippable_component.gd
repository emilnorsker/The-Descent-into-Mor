class_name EquippableComponent
extends Component

enum EquipmentType {WEAPON, ARMOR}

func equipment_type() -> EquipmentType:
	return data.equipment_type

func power_bonus() -> int:
	return data.power_bonus

func defense_bonus() -> int:
	return data.defense_bonus
