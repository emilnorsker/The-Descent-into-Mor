@tool
class_name DropItemAction
extends Action


func perform() -> bool:
    if item == null:
        return false
    if entity.equipment and entity.equipment.is_item_equipped(item):
        entity.equipment.toggle_equip(item)
    entity.inventory.drop(item)
    return true
