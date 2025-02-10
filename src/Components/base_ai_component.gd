class_name BaseAIComponent
extends Component

func _init() -> void:
    super()
    name = "BaseAIComponent"

func setup_from_blueprint(blueprint: Resource) -> Component:
    if not blueprint:
        return self
    return self

func perform() -> void:
    pass

func get_action(consumer: Entity) -> Action:
    return null

func get_point_path_to(destination: Vector2i) -> PackedVector2Array:
    return PackedVector2Array()
