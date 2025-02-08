# Roguelike Map System

A layered tile-based map system using Godot 4's TileMaplayers for efficient world representation and entity placement.

## Core Concepts

The map system uses a single Map node with multiple layers to represent different aspects of the world:

**World Structure**
- Layer 0: Floor - Base terrain you can walk on
- Layer 1: Features - Special terrain (water, pits, etc)
- Layer 2: Fixtures - Interactive/blocking objects (walls, doors, chests)

## Layer Details

### Floor Layer (0)
Base walkable terrain that forms the ground of your world.

**Properties:**
- Entity blueprint reference
- Movement cost for traversal
- Floor type identifier
- Sound properties
- Movement modifiers (e.g., flamable)

**Examples:**
- Stone floor
- Wooden floor
- Grass
- Carpet

### Features Layer (1)
Special terrain elements that affect gameplay.

**Properties:**
- Entity blueprint reference
- Movement modifiers
- Damage properties
- Feature type identifier
- Status effect properties

**Examples:**
- Water (slows movement)
- Lava (causes damage)
- Chasms (blocks movement)
- Ice (slippery movement)

### Fixtures Layer (2)
Static objects that can be converted to entities. This includes both structural elements (walls) and interactive objects.

**Properties:**
- Entity blueprint reference
- Fixture type identifier
- Movement blocking properties
- Destructibility
- Vision blocking properties
- Interaction methods

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

### Physics Layer System
The system defines distinct physics layers for collision handling:
- None: No physics interaction
- Floor: Base terrain collision
- Feature: Special terrain collision
- Fixture: Object collision

### Custom Properties
Each tile can have various properties that define its behavior:
- Movement costs
- Entity references
- Type identifiers
- Interaction methods
- Blocking flags
- Vision properties

## Runtime Behavior

### Processing Order
The system processes layers in a specific order to ensure proper game state:
1. Floor layer processing for base navigation
2. Feature layer effects application
3. Fixture conversion to entities

### World Building
The map system provides tools for:
- Layer management
- Tile property access
- Entity conversion
- Runtime modifications

## Best Practices

1. **Layer Organization**
   - Floor is always the base layer
   - Features modify floor behavior
   - Fixtures can be structural or interactive

2. **Performance**
   - Use appropriate layer for each element
   - Minimize runtime conversion
   - Cache navigation data


4. **Extension**
   - Easy to add new tile types
   - Flexible custom data
   - Clear conversion rules

## Map Queries and Entity Management

The map system maintains a comprehensive view of the game world through efficient tracking and querying mechanisms.

### Entity Tracking System
The world map maintains several key data structures:
- Position-based entity lookup
- Active entity list
- Cached position states

### Query Types

#### Position Queries
The system provides several ways to query entities at specific positions:

1. **Full Position Query**
   - Returns all entities at a position
   - Useful for complete state analysis
   - Example: Checking what's on a tile before movement

2. **Filtered Position Query**
   - Returns entities of a specific type
   - Useful for targeted checks
   - Example: Finding items for pickup

3. **State Queries**
   - Quick checks for common conditions:
     * Is position blocked?
     * What's the movement cost?
     * Is position visible?
   - Optimized for frequent access

#### Area Queries
For larger-scale information gathering:

1. **Rectangular Area**
   - Query all entities within a rectangle
   - Useful for room-based operations
   - Example: Room-wide effects

2. **Radius Search**
   - Find entities within a circular area
   - Useful for AOE effects and visibility
   - Example: Explosion damage

### Entity Management

The system handles entity lifecycle through three main operations:

1. **Registration**
   - Adds entities to the tracking system
   - Updates cached position states
   - Triggers appropriate events

2. **Removal**
   - Cleans up entity references
   - Updates position caches
   - Handles cleanup events

3. **Movement**
   - Updates position tracking
   - Maintains cache consistency
   - Notifies interested systems

### Event System

The map broadcasts key events to interested systems:

1. **Entity Events**
   - Entity added to position
   - Entity removed from position
   - Entity moved between positions

2. **Position Events**
   - Position contents changed
   - Position state changed (blocked/unblocked)

### Common Operations

1. **Movement Planning**
   Before moving an entity, the system:
   - Checks destination for blocking entities
   - Calculates total movement cost
   - Verifies path clearance
   - Updates entity positions

2. **Combat Targeting**
   For area effect abilities:
   - Identifies entities in range
   - Filters for valid targets
   - Applies effects to targets

3. **Environment Interaction**
   When interacting with the environment:
   - Identifies interactive elements
   - Determines valid interactions
   - Triggers appropriate responses

### Best Practices

1. **Query Optimization**
   - Cache frequently accessed data
   - Use filtered queries when possible
   - Batch area queries for performance

2. **Event Usage**
   - Subscribe only to relevant events
   - Handle events efficiently
   - Clean up event listeners

3. **Entity Management**
   - Register entities immediately after creation
   - Clean up entities properly on removal
   - Keep position data consistent

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