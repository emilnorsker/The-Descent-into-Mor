@tool
class_name ItemComponent
extends Component

enum EquipmentType {
    WEAPON,
    ARMOR,
    ACCESSORY
}

var equipment_type: EquipmentType = EquipmentType.WEAPON
var power_bonus: int = 0
var defense_bonus: int = 0
var slot: Constants.BodyPart = Constants.BodyPart.RIGHT_HAND

func _init() -> void:
    super()

func setup_from_blueprint(blueprint: Resource) -> ItemComponent:
    if blueprint:
        if blueprint.power_bonus:
            power_bonus = blueprint.power_bonus
        if blueprint.defense_bonus:
            defense_bonus = blueprint.defense_bonus
        if blueprint.slot:
            slot = blueprint.slot

    return self
