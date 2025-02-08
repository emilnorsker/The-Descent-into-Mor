# Roguelike Map System

A layered tile-based map system using Godot 4's TileMap layers for efficient world representation and entity placement.

## Core Concepts

The map system uses a single TileMap node with multiple layers to represent different aspects of the world:

```
WorldTileMap (TileMap)
├── Layer 0: "floor"        # Base terrain you can walk on
├── Layer 1: "features"     # Special terrain (water, pits, etc)
└── Layer 2: "fixtures"     # Interactive/blocking objects (walls, doors, chests)
```

## Layer Details

### Floor Layer (0)
Base walkable terrain that forms the ground of your world.

```gdscript
# Custom Data
class FloorData:
    var movement_cost: float = 1.0    # Base movement cost
    var floor_type: String            # "stone", "dirt", "grass"
    var footstep_sound: String        # Sound effect reference
    var is_slippery: bool = false     # Affects movement
```

**Examples:**
- Stone floor
- Wooden floor
- Grass
- Carpet

### Features Layer (1)
Special terrain elements that affect gameplay.

```gdscript
# Custom Data
class FeatureData:
    var movement_cost: float = 1.0     # Movement modifier
    var damage_per_turn: float = 0     # Damage dealt per turn
    var feature_type: String           # "water", "lava", "pit"
    var effect_type: String            # Status effect applied
```

**Examples:**
- Water (slows movement)
- Lava (causes damage)
- Chasms (blocks movement)
- Ice (slippery movement)

### Fixtures Layer (2)
Static objects that can be converted to entities. This includes both structural elements (walls) and interactive objects.

```gdscript
# Custom Data
class FixtureData:
    var blueprint_path: String         # Path to entity blueprint
    var fixture_type: String          # "wall", "door", "chest"
    var is_blocking: bool = true      # Blocks movement
    var is_destructible: bool = false # Can be broken
    var blocks_sight: bool = true     # Affects FOV
    var interaction_type: String      # How to interact (NONE for walls)
```

**Examples:**
Structural:
- Stone walls
- Wooden walls
- Pillars
- Barriers

Interactive:
- Doors
- Chests
- Levers
- Torches

## TileSet Configuration

### Physics Layers
```gdscript
enum PhysicsLayer {
    NONE,
    FLOOR,
    FEATURE,
    FIXTURE
}
```

### Custom Data Layers
```gdscript
var custom_data = {
    "movement_cost": {"type": TYPE_FLOAT, "default": 1.0},
    "blueprint_path": {"type": TYPE_STRING, "default": ""},
    "fixture_type": {"type": TYPE_STRING, "default": ""},
    "interaction_type": {"type": TYPE_STRING, "default": ""},
    "is_blocking": {"type": TYPE_BOOL, "default": false},
    "blocks_sight": {"type": TYPE_BOOL, "default": false}
}
```

## Runtime Behavior

### Layer Processing Order
1. Process floor for base navigation
2. Apply feature effects
3. Convert fixtures to entities

### Example Usage

```gdscript
# Setting up the TileMap
var world_map = TileMap.new()
world_map.add_layer(-1)  # Floor
world_map.add_layer(-1)  # Features
world_map.add_layer(-1)  # Fixtures

# Getting tile data
var tile_data = world_map.get_cell_tile_data(0, Vector2i(0, 0))
var movement_cost = tile_data.get_custom_data("movement_cost")

# Converting fixtures to entities
func convert_fixtures_to_entities():
    var fixtures_layer = 2
    for cell in world_map.get_used_cells(fixtures_layer):
        var tile_data = world_map.get_cell_tile_data(fixtures_layer, cell)
        var blueprint = tile_data.get_custom_data("blueprint_path")
        if blueprint:
            spawn_entity_at_position(blueprint, cell)
```

## Best Practices

1. **Layer Organization**
   - Floor is always the base layer
   - Features modify floor behavior
   - Fixtures can be structural or interactive

2. **Performance**
   - Use appropriate layer for each element
   - Minimize runtime conversion
   - Cache navigation data

3. **Design**
   - Plan tile variations
   - Consider gameplay impact
   - Think about visual stacking

4. **Extension**
   - Easy to add new tile types
   - Flexible custom data
   - Clear conversion rules

## Future Extensions

1. **Advanced Features**
   - Animated tiles
   - Destructible environment
   - Dynamic lighting

2. **Procedural Generation**
   - Room templates
   - Cellular automata
   - BSP dungeons

3. **Gameplay Systems**
   - Environmental hazards
   - Interactive terrain
   - Dynamic obstacles 