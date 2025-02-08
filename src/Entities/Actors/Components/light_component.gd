class_name LightComponent extends Component

var range: float
var color: Color
var angle: float
var fan_angle: float

func _init(blueprint: LightComponentBlueprint) -> void:
    range = blueprint.range
    color = blueprint.color
    angle = blueprint.angle
    fan_angle = blueprint.fan_angle

func _ready() -> void:
    # Just add to group, don't move to manager
    add_to_group("lights") 