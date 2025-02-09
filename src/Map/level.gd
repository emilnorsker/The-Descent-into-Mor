@tool
extends Resource
class_name Level

const LevelElement = preload("res://src/Map/level_element.gd")

# Level contents
@export var floors: Array[LevelElement] = []      # Floor tiles
@export var surfaces: Array[LevelElement] = []    # Surface features
@export var objects: Array[LevelElement] = []     # Physical objects/fixtures
@export var items: Array[LevelElement] = []       # Collectible items
@export var entities: Array[LevelElement] = []    # NPCs, monsters, etc 