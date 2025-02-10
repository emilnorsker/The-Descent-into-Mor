@tool
class_name Component
extends Node

@onready var entity: Entity = get_parent() as Entity

func _init() -> void:
    pass


func setup_from_blueprint(blueprint: Resource) -> Component:
    return self
