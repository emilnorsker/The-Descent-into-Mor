@tool
extends Resource
class_name ProgressionComponentBlueprint

@export var level_up_base: int = 200
@export var level_up_factor: int = 150
@export var xp_given: int = 0
@export var current_level: int = 1
@export var current_xp: int = 0 