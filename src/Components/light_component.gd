class_name LightComponent
extends Component

func _ready() -> void:
	add_to_group("light_sources")

func range() -> int:
	return data.range

func color() -> Color:
	return data.color

func angle() -> float:
	return data.angle

func fan_angle() -> float:
	return data.fan_angle 