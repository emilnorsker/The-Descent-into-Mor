class_name TerrainComponent
extends Component

var blocks_sight: bool
var movement_cost: float
var terrain_type: String

func _init(blueprint: TerrainComponentBlueprint) -> void:
	super._init()
	blocks_sight = blueprint.blocks_sight
	movement_cost = blueprint.movement_cost
	terrain_type = blueprint.terrain_type

func get_movement_cost() -> float:
	return movement_cost

func blocks_sight() -> bool:
	return blocks_sight

func get_terrain_type() -> String:
	return terrain_type 