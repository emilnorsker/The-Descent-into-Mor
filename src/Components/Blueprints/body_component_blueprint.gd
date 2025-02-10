@tool
class_name BodyComponentBlueprint
extends Resource

@export var type: String = "humanoid"
@export var parts: Dictionary = {}
@export var consciousness: float = 100.0
@export var wounds: Dictionary = {}
@export var is_dead: bool = false 