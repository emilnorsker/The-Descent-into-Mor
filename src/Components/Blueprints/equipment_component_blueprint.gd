@tool
class_name EquipmentComponentBlueprint
extends ComponentBlueprint

var equipped_items: Dictionary = {}
var dropped_items: Array[Entity] = []

func _init() -> void:
    super()
    component_type = "equipment"
