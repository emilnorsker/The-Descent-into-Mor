@tool
class_name EquipmentComponent
extends Component

signal equipment_changed

var slots := {}

var _defense_bonus: int = 0
var defense_bonus: int:
    set(value):
        _defense_bonus = value
        equipment_changed.emit()
    get:
        return get_defense_bonus()

var _power_bonus: int = 0
var power_bonus: int:
    set(value):
        _power_bonus = value
        equipment_changed.emit()
    get:
        return get_power_bonus()

func _init() -> void:
    super()

func setup_from_blueprint(blueprint: Resource) -> EquipmentComponent:
    if not blueprint:
        push_error("Invalid blueprint provided to EquipmentComponent.setup_from_blueprint")
        return self

    defense_bonus = blueprint.defense_bonus
    power_bonus = blueprint.power_bonus
    slots = blueprint.slots

    return self

func get_defense_bonus() -> int:
    var bonus = 0
    
    for item in entity.components.equipment.slots.values():
        if item.components.item:
            bonus += item.components.item.defense_bonus()
    
    return bonus


func get_power_bonus() -> int:
    var bonus = 0
    
    for item in slots.values():
        if item.components.item:
            bonus += item.components.item.power_bonus()
    
    return bonus



func is_item_equipped(item: Entity) -> bool:
    return item in slots.values()


func equip(item: Entity, body_part: int = Constants.BodyPart.RIGHT_HAND) -> void:
    var current_item = slots.get(body_part)
    if current_item:
        _unequip_from_slot(body_part)
    slots[body_part] = item
    
    # Add item as child of entity to follow its transforms
    if item.get_parent():
        item.get_parent().remove_child(item)
    entity.add_child(item)
    item.position = Vector2.ZERO  # Relative to parent
    
    SignalBus.message_sent.emit(entity.entity_name + " equips the %s." % item.get_entity_name(), Color.WHITE)
    
    equipment_changed.emit()


func _unequip_from_slot(slot: int) -> void:
    var current_item = slots.get(slot)
    
    # Remove from entity and reset position
    if current_item and current_item.get_parent():
        current_item.get_parent().remove_child(current_item)

    SignalBus.message_sent.emit(entity.entity_name + " removes the %s." % current_item.get_entity_name(), Color.WHITE)
    
    slots.erase(slot)
    
    equipment_changed.emit()
