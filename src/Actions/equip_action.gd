@tool
class_name EquipAction
extends Action

var _item: Entity
var _target_slot: int = -1  # Default to no specific slot

func _init(entity: Entity, item: Entity, target_slot: int = -1) -> void:
    super(entity, entity)  # Both performer and target are the same entity
    _item = item
    _target_slot = target_slot

func perform() -> bool:
    if not _item.components.item or _item.components.item.equipment_type == ItemComponent.EquipmentType.NONE:
        return false
    
    if not performer.components.body:
        return false
    
    var body = performer.components.body
    body.equip_to_slot(_item, _target_slot)
    return true

func is_valid() -> bool:
    if not _item.components.equipment:
        return false
    
    # If a specific slot was requested, validate it
    if _target_slot != -1:
        if not performer.components.body:
            return false
        var body = performer.components.body
        if not body.get_part_data(_target_slot).has("slots"):
            return false
    
    return true
