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
@export var terrain_template: TerrainComponentDefinition
@export var combat_template: CombatComponentTemplate
@export var ai_type: Entity.AIType
@export var item_template: ItemComponentTemplate
@export var inventory_capacity: int = 0
@export var progression_template: ProgressionComponentTemplate
@export var has_equipment: bool = false
@export var light_template: LightComponentTemplate
