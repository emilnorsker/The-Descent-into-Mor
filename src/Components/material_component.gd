class_name MaterialComponent
extends Component

@export var is_flammable: bool = false
@export var is_slippery: bool = false
@export var material_type: String = "none"

func _init() -> void:
    super()

func setup_from_blueprint(blueprint: Resource) -> Component:
    if blueprint:
        is_flammable = blueprint.is_flammable
        is_slippery = blueprint.is_slippery
        material_type = blueprint.material_type

    return self

func get_is_flammable() -> bool:
    var parent = get_parent() as Entity
    if parent and parent.combat_modifier:
        return is_flammable or parent.combat_modifier.has_state(Constants.StatusEffect.OILED)
    return is_flammable

func get_is_slippery() -> bool:
    var parent = get_parent() as Entity
    if parent and parent.combat_modifier:
        return is_slippery or parent.combat_modifier.has_state(Constants.StatusEffect.OILED) or (material_type == "metal" and parent.combat_modifier.metal_slippery())
    return is_slippery

func get_material_type() -> String:
    return material_type

func set_is_flammable(value: bool) -> void:
    is_flammable = value

func set_is_slippery(value: bool) -> void:
    is_slippery = value 