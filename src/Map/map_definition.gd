@tool
extends Resource
class_name MapDefinition

# Tile definitions
@export var floor_tiles: Array[TileData] = []
@export var feature_tiles: Array[TileData] = []
@export var fixture_tiles: Array[TileData] = []

# Initial entities (items, actors, etc)
@export var initial_entities: Array[EntityData] = []

# Custom resource for defining a tile
class TileData extends Resource:
    @export var position: Vector2i
    @export var blueprint_path: String

# Custom resource for defining an entity
class EntityData extends Resource:
    @export var position: Vector2i
    @export var blueprint_path: String 