@tool
class_name DropItemAction
extends Action


func perform() -> bool:
    if item == null:
        return false
    if entity.components.equipment and entity.components.equipment.is_item_equipped(item):
        entity.components.equipment.toggle_equip(item)
    entity.components.inventory.drop(item)
    return true
