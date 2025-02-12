class_name LightComponent
extends Component

const DEFAULT_BLUEPRINT = preload("res://new_assets/blueprints/light/basic.tres")

var _range: int = 5
var _color: Color = Color.WHITE
var _angle: float = 0.0
var _fan_angle: float = 360.0

func _init(blueprint: Resource = null) -> void:
    super()
    name = "LightComponent"
    
    if not blueprint:
        blueprint = DEFAULT_BLUEPRINT
    
    if blueprint:
        if not blueprint is LightComponentBlueprint:
            push_error("Invalid blueprint type provided to LightComponent")
            return
            
        _range = blueprint.range
        _color = blueprint.color
        _angle = blueprint.angle
        _fan_angle = blueprint.fan_angle

func _ready() -> void:
    add_to_group("light_sources")

func setup_from_dict(data: Dictionary) -> Component:
    if data.has("range"):
        _range = data.range
    if data.has("color"):
        _color = data.color
    if data.has("angle"):
        _angle = data.angle
    if data.has("fan_angle"):
        _fan_angle = data.fan_angle
    return self

func setup_from_blueprint(blueprint: Resource) -> LightComponent:
    if blueprint:
        _range = blueprint.range
        _color = blueprint.color
        _angle = blueprint.angle
        _fan_angle = blueprint.fan_angle

    return self

func get_range() -> int:
    return _range

func get_color() -> Color:
    return _color

func get_angle() -> float:
    return _angle

func get_fan_angle() -> float:
    return _fan_angle 