@tool
class_name EquipAction
extends Action

var _item: Entity
var _target_slot: BodyComponent.BodyPart = BodyComponent.BodyPart.NONE  # Default to no specific slot

func _init(entity: Entity, item: Entity, target_slot: BodyComponent.BodyPart = BodyComponent.BodyPart.NONE) -> void:
    super(entity, entity)  # Both performer and target are the same entity
    _item = item
    _target_slot = target_slot

func perform() -> bool:
    if not _item.item or _item.item.equipment_type == ItemComponent.EquipmentType.NONE:
        # Trying to equip non-equipment items damages the arm
        if performer.body:
            performer.body.apply_wound(BodyComponent.WoundType.LIGHT, BodyComponent.BodyPart.RIGHT_ARM)
        return false
    
    if not performer.body:
        return false
    
    var body = performer.body
    body.equip_to_slot(_item, _target_slot)
    return true

func is_valid() -> bool:
    if not _item.item or _item.item.equipment_type == ItemComponent.EquipmentType.NONE:
        return false
    
    # If a specific slot was requested, validate it
    if _target_slot != -1:
        if not performer.body:
            return false
        var body = performer.body
        if not body.get_part_data(_target_slot).has("slots"):
            return false
    
    return true
