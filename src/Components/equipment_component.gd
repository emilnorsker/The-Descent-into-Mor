@tool
class_name EquipmentComponent
extends Component

# The equipment component is used to equip items to an entity.
# It also tracks the total defense and power bonuses of the equipped items.
# it is not a single item, but rather the interface to the items equipped on the body.

const DEFAULT_BLUEPRINT = preload("res://new_assets/blueprints/equipment/basic.tres")

signal equipment_changed
signal item_equipped(item: Entity, slot: String)
signal item_unequipped(item: Entity, slot: String)

var _equipped_items: Dictionary = {}
var dropped_items: Array[Entity] = []

var _defense_bonus: int = 0
var total_defense_bonus: int:
    set(value):
        _defense_bonus = value
        equipment_changed.emit()
    get:
        return _get_defense_bonus()

var _power_bonus: int = 0
var total_power_bonus: int:
    set(value):
        _power_bonus = value
        equipment_changed.emit()
    get:
        return _get_power_bonus()

func _init(blueprint: Resource = null) -> void:
    super()
    name = "EquipmentComponent"
    
    if not blueprint:
        blueprint = DEFAULT_BLUEPRINT
    
    if blueprint:
        if not blueprint is EquipmentComponentBlueprint:
            push_error("Invalid blueprint type provided to EquipmentComponent")
            return
            
        _equipped_items = blueprint.equipped_items.duplicate()
        dropped_items = blueprint.dropped_items.duplicate()

func _get_defense_bonus() -> int:
    var bonus = 0
    
    for item in _equipped_items.values():
        if item and item.has("item"):
            bonus += item.item.defense_bonus
    
    return bonus


func _get_power_bonus() -> int:
    var bonus = 0
    
    for item in _equipped_items.values():
        if item and item.has("item"):
            bonus += item.item.power_bonus
    
    return bonus


func is_item_equipped(item: Entity) -> bool:
    return item in _equipped_items.values()


func equip(item: Entity, slot = null) -> void:
    var parent = get_parent()
    if not parent or not item:
        return
        
    if not slot:
        slot = BodyComponent.BodyPart.RIGHT_EQUIPMENT
    
    # Convert int slot to string if needed
    var slot_key = str(slot) if typeof(slot) == TYPE_INT else slot
        
    # Unequip any existing item in the slot
    if _equipped_items.has(slot_key) and _equipped_items[slot_key]:
        _unequip_from_slot(slot_key)
    
    # Add the item to the slot
    _equipped_items[slot_key] = item
    
        
    parent.body.protection[slot] = item.defense_bonus
    
    item_equipped.emit(item, slot_key)

func unequip(item: Entity) -> void:
    for slot in _equipped_items.keys():
        if _equipped_items[slot] == item:
            _unequip_from_slot(slot)
            break

func _unequip_from_slot(slot: String) -> void:
    var item = _equipped_items[slot]
    if item:
        var parent = get_parent()
        if parent and parent.has("inventory"):
            parent.inventory.add_item(item)
        _equipped_items[slot] = null
        
        # Remove protection if it was armor
        if item.has("item"):
            var body = parent.body
            if body:
                body.protection[slot] = 0
        
        item_unequipped.emit(item, slot)

func get_equipped_item(slot) -> Entity:
    var slot_key = str(slot) if typeof(slot) == TYPE_INT else slot
    return _equipped_items.get(slot_key)

func has_equipped_item(slot) -> bool:
    var slot_key = str(slot) if typeof(slot) == TYPE_INT else slot
    return _equipped_items.has(slot_key) and _equipped_items[slot_key] != null

func get_equipped_items() -> Array[Entity]:
    var items: Array[Entity] = []
    for item in _equipped_items.values():
        if item:
            items.append(item)
    return items
