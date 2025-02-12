@tool
class_name LightComponentBlueprint
extends ComponentBlueprint

var range: int = 5
var color: Color = Color.WHITE
var angle: float = 0.0
var fan_angle: float = 360.0

func _init() -> void:
    super()
    component_type = "light" 