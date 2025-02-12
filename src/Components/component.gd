@tool
class_name Component
extends Node

@onready var entity: Entity = get_parent() as Entity

func _init() -> void:
    pass

func setup_from_dict(data: Dictionary) -> Component:
    push_error("setup_from_dict not implemented for %s" % get_class() + " " + get_name())
    return self

func setup_from_blueprint(blueprint: Resource) -> Component:
    return self
