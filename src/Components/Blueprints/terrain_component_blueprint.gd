@tool
class_name TerrainComponentBlueprint
extends Resource

@export var blocks_sight: bool = false
@export var movement_cost: int = 1
@export var terrain_type: String = "ground"
@export var elevation: int = 0
@export var surface_type: String = "normal"  # normal, slippery, rough, etc. 