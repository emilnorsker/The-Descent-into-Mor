@tool
class_name DropItemAction
extends Action

var item: Entity
var entity: Entity

func _init(entity: Entity, item: Entity) -> void:
    self.entity = entity
    self.item = item

func perform() -> bool:
    if entity.equipment and entity.equipment.is_item_equipped(item):
        entity.equipment.toggle_equip(item)
    entity.inventory.drop(item)
    return true
