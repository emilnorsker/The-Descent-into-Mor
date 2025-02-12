@tool
class_name MaterialComponentBlueprint
extends ComponentBlueprint

var material_type: String = "none"
var is_flammable: bool = false
var is_slippery: bool = false

func _init() -> void:
    super()
    component_type = "material"
