@tool
class_name ItemComponentBlueprint extends Resource

@export var equipment_type: ItemComponent.EquipmentType
@export var power_bonus: int = 0
@export var defense_bonus: int = 0
@export var slot: BodyComponent.BodyPart = BodyComponent.BodyPart.RIGHT_EQUIPMENT
@export var range: int = 0
