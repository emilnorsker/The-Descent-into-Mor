@tool
class_name ItemComponent
extends Component

enum EquipmentType {
    NONE,
    WEAPON,
    ARMOR,
    ACCESSORY,
    RANGED
}

var equipment_type: EquipmentType = EquipmentType.WEAPON
# TODO: Add getter and setters to check for potewntial modifiers
var power_bonus: int = 0
var defense_bonus: int = 0
var slot: BodyComponent.BodyPart = BodyComponent.BodyPart.RIGHT_EQUIPMENT
var range: int = -1 # -1 means default range

func _init() -> void:
    super()

func get_range() -> int:
    if range == -1:
        return 1
    if get_parent() and get_parent().combat:
        return range + get_parent().combat.get_power_bonus()
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

func setup_from_dict(data: Dictionary) -> Component:
    if data.has("equipment_type"):
        equipment_type = data.equipment_type
    if data.has("power_bonus"):
        power_bonus = data.power_bonus
    if data.has("defense_bonus"):
        defense_bonus = data.defense_bonus
    if data.has("slot"):
        slot = data.slot
    if data.has("range"):
        range = data.range
    return self
