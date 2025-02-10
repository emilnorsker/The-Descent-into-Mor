@tool   
class_name EquipmentComponentBlueprint extends Resource

@export var weapon: EntityBlueprint
@export var armor: EntityBlueprint 
@export var slots: Dictionary = {}
@export var defense_bonus: int = 0
@export var power_bonus: int = 0