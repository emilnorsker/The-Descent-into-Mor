@tool
class_name InventoryComponentBlueprint extends ComponentBlueprint

var capacity: int = 10
var items: Array = []

func _init() -> void:
    super()
    component_type = "inventory" 