@tool
class_name MaterialComponentBlueprint extends Resource

@export var is_flammable: bool = false
@export var is_slippery: bool = false
@export var material_type: String = "none"

func get_component_name() -> String:
    return "MaterialComponent"

func get_properties() -> Dictionary:
    return {
        "is_flammable": is_flammable,
        "is_slippery": is_slippery,
        "type": material_type
    } 