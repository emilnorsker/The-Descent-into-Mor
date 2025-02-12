@tool
class_name EntityBlueprint extends Resource

func _get_class() -> String:
    return "EntityBlueprint"

# Default blueprints for each component type
const DEFAULT_BODY_BLUEPRINT = preload("res://new_assets/blueprints/body/humanoid.tres")
const DEFAULT_COMBAT_BLUEPRINT = preload("res://new_assets/blueprints/combat/basic.tres")
const DEFAULT_INVENTORY_BLUEPRINT = preload("res://new_assets/blueprints/inventory/basic.tres")
const DEFAULT_EQUIPMENT_BLUEPRINT = preload("res://new_assets/blueprints/equipment/basic.tres")
const DEFAULT_MATERIAL_BLUEPRINT = preload("res://new_assets/blueprints/materials/metal.tres")
const DEFAULT_MODIFIER_BLUEPRINT = preload("res://new_assets/blueprints/modifiers/basic.tres")
const DEFAULT_WEIGHT_BLUEPRINT = preload("res://new_assets/blueprints/weights/basic.tres")
const DEFAULT_LIGHT_BLUEPRINT = preload("res://new_assets/blueprints/light/basic.tres")
const DEFAULT_TERRAIN_BLUEPRINT = preload("res://new_assets/blueprints/terrain/basic.tres")

var entity_name: String = "Default Entity"
var entity_type: Entity.EntityType = Entity.EntityType.ACTOR

# TODO: make light a optional component
# TODO: make this more performant???? now it's instantiating all base components
#       components every time the blueprint is instantiated, regardless of what components are defined in 
#       the blueprint
var components: Dictionary = {
    "body": DEFAULT_BODY_BLUEPRINT,
    "combat": DEFAULT_COMBAT_BLUEPRINT,
    "inventory": DEFAULT_INVENTORY_BLUEPRINT,
    "equipment": DEFAULT_EQUIPMENT_BLUEPRINT,
    "material": DEFAULT_MATERIAL_BLUEPRINT,
    "modifiers": DEFAULT_MODIFIER_BLUEPRINT,
    "weight": DEFAULT_WEIGHT_BLUEPRINT,
    "light": DEFAULT_LIGHT_BLUEPRINT,
    "terrain": DEFAULT_TERRAIN_BLUEPRINT
}

func _to_string() -> String:
    return "EntityBlueprint(%s, type=%s, components=%s)" % [
        entity_name,
        Entity.EntityType.keys()[entity_type],
        components.keys()
    ]

func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    properties.append({
        "name": "entity_name",
        "type": TYPE_STRING,
        "usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
    })
    properties.append({
        "name": "entity_type",
        "type": TYPE_INT,
        "usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
    })
    properties.append({
        "name": "components",
        "type": TYPE_DICTIONARY,
        "usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
    })
    return properties
