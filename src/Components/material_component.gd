class_name MaterialComponent
extends Component

var _is_flammable: bool = false
var _is_slippery: bool = false
var material_type: String = "none"

func _init() -> void:
    super()

func setup_from_blueprint(blueprint: Resource) -> Component:
    if not blueprint:
        return self

    _is_flammable = blueprint.is_flammable
    _is_slippery = blueprint.is_slippery
    material_type = blueprint.material_type

    return self

func get_is_flammable() -> bool:
    var parent = get_parent() as Entity
    if parent and parent.components.combat_modifier:
        return _is_flammable or parent.components.combat_modifier.has_state(Constants.StatusEffect.OILED)
    return _is_flammable

func get_is_slippery() -> bool:
    var parent = get_parent() as Entity
    if parent and parent.components.combat_modifier:
        return _is_slippery or parent.components.combat_modifier.has_state(Constants.StatusEffect.OILED)
    return _is_slippery

func set_is_flammable(value: bool) -> void:
    _is_flammable = value

func set_is_slippery(value: bool) -> void:
    _is_slippery = value
