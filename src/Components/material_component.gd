class_name MaterialComponent
extends Component

const DEFAULT_BLUEPRINT = preload("res://new_assets/blueprints/materials/metal.tres")

# TODO: add getters and setters
var _is_flammable: bool = false
var _is_slippery: bool = false
var material_type: String = "none"

func _init(blueprint: Resource = null) -> void:
    super()
    name = "MaterialComponent"
    
    # Use default blueprint if none provided
    if not blueprint:
        blueprint = DEFAULT_BLUEPRINT
    
    if blueprint:
        if not blueprint is MaterialComponentBlueprint:
            push_error("Invalid blueprint type provided to MaterialComponent")
            return
            
        _is_flammable = blueprint.is_flammable
        _is_slippery = blueprint.is_slippery
        material_type = blueprint.material_type

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
