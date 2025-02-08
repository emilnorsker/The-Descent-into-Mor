class_name LightComponent extends Component

var range: float
var color: Color
var angle: float
var fan_angle: float

func _init(definition: LightComponentDefinition) -> void:
    range = definition.range
    color = definition.color
    angle = definition.angle
    fan_angle = definition.fan_angle

func _ready() -> void:
    # Just add to group, don't move to manager
    add_to_group("lights") 