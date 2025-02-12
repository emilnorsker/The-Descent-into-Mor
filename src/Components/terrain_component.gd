@tool
class_name TerrainComponent
extends Component

const DEFAULT_BLUEPRINT = preload("res://new_assets/blueprints/terrain/basic.tres")

var blocks_sight: bool = false
var movement_cost: int = 1
var terrain_type: String = "ground"
var elevation: int = 0
var surface_type: String = "normal"

func _init(blueprint: Resource = null) -> void:
    super()
    name = "TerrainComponent"
    
    if not blueprint:
        blueprint = DEFAULT_BLUEPRINT
    
    if blueprint:
        if not blueprint is TerrainComponentBlueprint:
            push_error("Invalid blueprint type provided to TerrainComponent")
            return
            
        blocks_sight = blueprint.blocks_sight
        movement_cost = blueprint.movement_cost
        terrain_type = blueprint.terrain_type
        elevation = blueprint.elevation
        surface_type = blueprint.surface_type

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
