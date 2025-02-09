@tool
extends Resource
class_name EntityBlueprint

@export var name: String = ""
@export var texture: AtlasTexture
@export var color: Color = Color.WHITE
@export var is_blocking_movment: bool = false
@export var type: Entity.EntityType = Entity.EntityType.ACTOR
@export var ai_type: Entity.AIType = Entity.AIType.NONE

@export_category("Components")
@export var combat_blueprint: CombatComponentBlueprint
@export var terrain_blueprint: TerrainComponentBlueprint
@export var ai_blueprint: AIComponentBlueprint
@export var item_blueprint: ItemComponentBlueprint
@export var light_blueprint: LightComponentBlueprint
@export var inventory_blueprint: InventoryComponentBlueprint
@export var progression_blueprint: ProgressionComponentBlueprint
@export var equipment_blueprint: EquipmentComponentBlueprint
