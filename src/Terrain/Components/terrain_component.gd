class_name TerrainComponent
extends Component

var blueprint: TerrainComponentBlueprint

func blocks_sight() -> bool:
    return blueprint.blocks_sight

func movement_cost() -> float:
    return blueprint.movement_cost

func terrain_type() -> String:
    return blueprint.terrain_type 