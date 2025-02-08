# Roguelike ECS Architecture

A component-based entity system designed for roguelike games, focusing on clear separation of concerns and extensibility. The system uses Godot 4's built-in node system combined with a data-driven approach using resources.

## Core Concepts

### Entity Types

The system defines five fundamental types of entities:

```gdscript
enum EntityType {
    ACTOR,   # Living entities that can take actions (players, monsters)
    ITEM,    # Moveable objects that can be collected (weapons, potions)
    FIXTURE, # Interactive world objects (doors, chests, torches)
    TERRAIN, # Base world elements (floors, walls, water)
    CORPSE   # Dead actors that persist in the world
}
```

### Components & Templates

The architecture uses a split between behavior (Components) and data (Templates):

- **Components**: Godot nodes that contain behavior and runtime state
- **Templates**: Resource files that define initial configuration

This separation allows for easy modification of entity properties without changing code.

#### Core Components

```gdscript
Component (base)
├── CombatComponent      # Combat stats and behavior
├── ProgressionComponent # Leveling and experience
├── InventoryComponent   # Item storage and management
├── EquipmentComponent   # Gear management
├── ConsumableComponent  # One-time use items
├── TerrainComponent    # Movement and terrain properties
├── FixtureComponent    # Interactive world objects
└── LightComponent      # Light source behavior
```

#### Template System

Templates are data-only resources that define component initialization:

```gdscript
ItemComponentTemplate
├── ConsumableComponentTemplate
└── EquippableComponentTemplate

CombatComponentTemplate
ProgressionComponentTemplate
TerrainComponentTemplate
FixtureComponentTemplate
```

## Blueprint System

Blueprints are complete entity definitions stored as `.tres` resource files.

### Structure

```
assets/blueprints/
├── actors/
│   ├── player.tres
│   └── monsters/
│       ├── orc.tres
│       └── troll.tres
├── items/
│   ├── weapons/
│   │   ├── sword.tres
│   │   └── dagger.tres
│   └── consumables/
│       └── health_potion.tres
├── terrain/
│   ├── natural/
│   │   ├── floor.tres
│   │   ├── wall.tres
│   │   └── water.tres
│   └── artificial/
│       └── bridge.tres
└── fixtures/
    ├── interactive/
    │   ├── door.tres
    │   └── chest.tres
    └── static/
        ├── torch.tres
        └── statue.tres
```

### Example Blueprint

```gdscript
# torch.tres
@tool
extends EntityBlueprint

# Visual properties
@export var name = "Torch"
@export var texture = preload("res://assets/torch.tres")
@export var color = Color.WHITE

# Component templates
@export var light_template = LightComponentTemplate.new()
@export var fixture_template = FixtureComponentTemplate.new()
```

## Component Details

### Terrain System

The terrain system handles the base layer of the game world:

- **Floor**: Basic navigable terrain
- **Wall**: Blocking terrain
- **Water**: Modified movement cost

```gdscript
class_name TerrainComponent
extends Component

var movement_cost: float
var is_blocking: bool
var terrain_type: TerrainType
```

### Fixture System

Fixtures are interactive world objects:

- **Doors**: Can be opened/closed
- **Chests**: Can store items
- **Torches**: Provide light

```gdscript
class_name FixtureComponent
extends Component

var interaction_type: InteractionType
var state: Dictionary  # Flexible state storage
```

## Action System

Actions represent any change in the game state:

```gdscript
class_name Action
extends RefCounted

func perform() -> bool:
    return false  # Base action does nothing
```

Common actions:
- `MoveAction`: Grid-based movement
- `MeleeAction`: Basic combat
- `InteractAction`: Using fixtures
- `UseItemAction`: Consuming or equipping items

## Best Practices

### Component Design

1. **Single Responsibility**
   - Each component should handle one aspect of functionality
   - Use signals for communication between components

2. **Data-Driven**
   - Keep configuration in templates
   - Use blueprints for entity definitions
   - Avoid hardcoding values

3. **Extension Points**
   - Components should be easy to add/remove
   - Use composition over inheritance
   - Design for future expansion

### Blueprint Organization

1. **Clear Hierarchy**
   - Group similar entities
   - Use descriptive names
   - Maintain consistent structure

2. **Resource Management**
   - Use preloaded resources when possible
   - Share templates between similar entities
   - Keep resource paths relative

## Example Usage

### Creating an Entity

```gdscript
# Load a blueprint
var chest_blueprint = preload("res://assets/blueprints/fixtures/interactive/chest.tres")

# Create entity from blueprint
var chest = Entity.new()
chest.apply_blueprint(chest_blueprint)

# Add to scene
add_child(chest)
```

### Component Interaction

```gdscript
# Player attacking a monster
func attack(target: Entity) -> void:
    var damage = combat_component.power - target.combat_component.defense
    target.combat_component.take_damage(damage)
```

## Future Extensions

1. **Enhanced Terrain**
   - Environmental effects
   - Destructible terrain
   - Dynamic pathfinding costs

2. **Advanced Fixtures**
   - Multi-state interactions
   - Mechanical systems (levers, pressure plates)
   - Traps and hazards

3. **Component System**
   - Status effect system
   - Buff/debuff management
   - Environmental interactions

4. **AI Improvements**
   - Behavior trees
   - Group tactics
   - Environmental awareness 