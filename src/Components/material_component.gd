class_name MaterialComponent
extends Component

# TODO: add getters and setters
var _is_flammable: bool = false
var _is_slippery: bool = false
var material_type: String = "none"

func _init() -> void:
    super()

func setup_from_dict(data: Dictionary) -> Component:
    if data.has("flammable"):
        _is_flammable = data.flammable
    if data.has("slippery"):
        _is_slippery = data.slippery
    if data.has("type"):
        material_type = data.type
    return self

func setup_from_blueprint(blueprint: Resource) -> Component:
    if not blueprint:
        return self

    _is_flammable = blueprint.is_flammable
    _is_slippery = blueprint.is_slippery
    material_type = blueprint.material_type

    return self

func is_flammable() -> bool:
    var parent = get_parent() as Entity
    if parent and parent.modifiers:
        return _is_flammable or parent.modifiers.has_state(ModifierComponent.StatusEffect.OILED)
    return _is_flammable

func is_slippery() -> bool:
    var parent = get_parent() as Entity
    if parent and parent.modifiers:
        return _is_slippery or parent.modifiers.has_state(ModifierComponent.StatusEffect.OILED)
    return _is_slippery

func set_is_flammable(value: bool) -> void:
    _is_flammable = value

func set_is_slippery(value: bool) -> void:
    _is_slippery = value
