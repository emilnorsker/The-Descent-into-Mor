class_name EntityBlueprint
extends Resource

@export_category("Visuals")
@export var name: String = "Unnamed Entity"
@export var texture: AtlasTexture
@export_color_no_alpha var color: Color = Color.WHITE

@export_category("Mechanics")
@export var is_blocking_movment: bool = true
@export var type: Entity.EntityType

@export_category("Components")
@export var terrain_blueprint: TerrainComponentBlueprint
@export var combat_blueprint: CombatComponentBlueprint
@export var ai_type: Entity.AIType
@export var item_blueprint: ItemComponentBlueprint
@export var inventory_capacity: int = 0
@export var progression_blueprint: ProgressionComponentBlueprint
@export var has_equipment: bool = false
@export var light_blueprint: LightComponentBlueprint
