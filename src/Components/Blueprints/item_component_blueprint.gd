@tool
class_name ItemComponentBlueprint extends ComponentBlueprint

enum EquipmentType {
    NONE,
    WEAPON,
    ARMOR,
    ACCESSORY,
    RANGED
}

var equipment_type: EquipmentType = EquipmentType.NONE
var power_bonus: int = 0
var defense_bonus: int = 0
var value: int = 0
var slot: int = 0  # Use raw int instead of enum reference
var range: int = -1

func _init() -> void:
    super()
    component_type = "item"
