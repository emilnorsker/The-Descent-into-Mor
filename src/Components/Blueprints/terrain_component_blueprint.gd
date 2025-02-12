@tool
class_name TerrainComponentBlueprint
extends ComponentBlueprint

var blocks_sight: bool = false
var movement_cost: int = 1
var terrain_type: String = "ground"
var elevation: int = 0
var surface_type: String = "normal"  # normal, slippery, rough, etc.

func _init() -> void:
    super()
    component_type = "terrain" 