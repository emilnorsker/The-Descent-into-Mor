@tool
extends Resource
class_name LevelElement

const EntityBlueprint = preload("res://src/entity_blueprint.gd")

@export var position: Vector2i
@export var blueprint: EntityBlueprint 