@tool
class_name Component extends Node

var entity: Entity
var component_type: String

func _init(blueprint: Resource = null) -> void:
    if blueprint:
        component_type = blueprint.component_type if blueprint is ComponentBlueprint else "UNDEFINED"

func _ready() -> void:
    entity = get_parent() as Entity
    print("Component _ready called")
    print("Entity: ", entity)
    print("Parent: ", get_parent())
