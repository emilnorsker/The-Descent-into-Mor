class_name CombatComponentTemplate
extends ItemComponentTemplate

@export_category("Stats")
@export var max_hp: int = 30
@export var defense: int = 2
@export var power: int = 5

@export_category("Visuals")
@export var death_texture: AtlasTexture = preload("res://assets/resources/default_death_texture.tres")
@export var death_color: Color = Color.DARK_RED

@export var hp: int = max_hp:
	set(value):
		hp = value
		
@export var xp_given: int = 0
