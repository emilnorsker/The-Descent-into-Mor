@tool
class_name ComponentBlueprint
extends Resource

# The type of component this blueprint is for
var component_type: String = "invalid"

func _init() -> void:
    component_type = "base component"
