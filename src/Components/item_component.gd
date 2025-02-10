@tool
class_name ItemComponent
extends Component

enum EquipmentType {
    WEAPON,
    ARMOR,
    ACCESSORY,
    RANGED
}

var equipment_type: EquipmentType = EquipmentType.WEAPON
# TODO: Add getter and setters to check for potewntial modifiers
var power_bonus: int = 0
var defense_bonus: int = 0
var slot: Constants.BodyPart = Constants.BodyPart.RIGHT_HAND
var range: int = 0

func _init() -> void:
    super()

func get_range() -> int:
    if get_parent() and get_parent().components.combat:
        return range + get_parent().components.combat.get_power_bonus()
    return range

func setup_from_blueprint(blueprint: Resource) -> ItemComponent:
    if blueprint:
        if blueprint.power_bonus:
            power_bonus = blueprint.power_bonus
        if blueprint.defense_bonus:
            defense_bonus = blueprint.defense_bonus
        if blueprint.slot:
            slot = blueprint.slot
        if blueprint.equipment_type:
            equipment_type = blueprint.equipment_type
        if blueprint.range:
            range = blueprint.range

    return self
