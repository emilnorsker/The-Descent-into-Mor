@tool
class_name BodyComponentBlueprint
extends ComponentBlueprint

var type: String = "humanoid"
var parts: Dictionary = {}
var consciousness: float = 100.0
var wounds: Dictionary = {}
var is_dead: bool = false

func _init() -> void:
    super()
    component_type = "body" 