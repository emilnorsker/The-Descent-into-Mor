@tool
extends Resource
class_name EntityBlueprint

@export var entity_name: String = ""
@export var blocks_movement: bool = false
@export var type: Entity.EntityType = Entity.EntityType.ACTOR
@export var key: String = ""

@export_category("Components")
@export var components: Dictionary = {}
@export var combat_blueprint: Resource
@export var inventory_blueprint: Resource
@export var equipment_blueprint: Resource
@export var progression_blueprint: Resource
@export var consumable_blueprint: Resource
@export var light_blueprint: Resource
@export var material_blueprint: Resource
@export var weight_blueprint: Resource
@export var combat_modifier_blueprint: Resource
@export var terrain_blueprint: Resource
@export var ai_blueprint: Resource
@export var body_blueprint: Resource