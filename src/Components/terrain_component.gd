@tool
class_name TerrainComponent
extends Component

@export var blocks_sight: bool = false
@export var movement_cost: int = 1
@export var terrain_type: String = "ground"
@export var elevation: int = 0
@export var surface_type: String = "normal"

func _init() -> void:
    super()

func setup_from_dict(data: Dictionary) -> Component:
    if data.has("blocks_sight"):
        blocks_sight = data.blocks_sight
    if data.has("movement_cost"):
        movement_cost = data.movement_cost
    if data.has("terrain_type"):
        terrain_type = data.terrain_type
    if data.has("elevation"):
        elevation = data.elevation
    if data.has("surface_type"):
        surface_type = data.surface_type
    return self

func setup_from_blueprint(blueprint: Resource) -> Component:
    if blueprint:
        blocks_sight = blueprint.blocks_sight
        movement_cost = blueprint.movement_cost
        terrain_type = blueprint.terrain_type
        elevation = blueprint.elevation
        surface_type = blueprint.surface_type
    return self
