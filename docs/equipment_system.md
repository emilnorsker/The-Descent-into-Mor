# Equipment System Documentation

## Overview
The equipment system is designed to be flexible and realistic, where each piece of equipment has meaningful properties that affect combat and survival. Equipment directly influences action economy and wound interactions.

## Weapon System

### Core Weapon Properties

1. **Range**
   - Types:
     * Melee (1 tile, orthogonal only)
     * Extended Melee (1.5 tiles, includes diagonals)
     * Reach (2 tiles)
     * Ranged (variable)
   - Affects:
     * Attack options
     * Positioning requirements
     * Tactical advantages

2. **Ammo Type**
   - Categories:
     * None (melee weapons)
     * Arrows (bows)
     * Bolts (crossbows)

3. **Weight**
   - Categories:
     * Light (0-2)
     * Medium (3-5)
     * Heavy (6+)
   - Affects:
     * Available actions per turn
     * Movement cost
     * Stamina consumption

4. **Action Economy**
   - Base actions per turn modified by:
     * Equipment weight
     * Encumbrance
     * Wounds
     * Environmental factors
   - Examples:
     ```
     Light Load: 3 actions per turn
     Medium Load: 2 actions per turn
     Heavy Load: 1 action per turn
     
     Modifiers:
     - Leg wound: -1 action
     - Heat exhaustion: -1 action
     - Heavy armor: -1 action
     ```

5. **Sharpness**
   - Levels:
     * Dull (1): Increased trauma
     * Sharp (2-3): Standard
     * Razor (4-5): Enhanced bleeding
   - Environmental effects:
     * Wet conditions reduce effectiveness
     * Blood can dull edge
     * Rust decreases sharpness

## Armor System

### Coverage and Protection

1. **Coverage Matrix**
   Each armor piece protects multiple areas:
   ```
   Example - Plate Cuirass:
   Primary Coverage:
   - Chest (full)
   - Upper Back (full)
   - Abdomen (partial)
   
   Secondary Coverage:
   - Lower Back (partial)
   - Shoulders (partial)
   ```

2. **Protection System**
   Instead of flat values, provides modifiers to wound rolls:
   ```
   Modifier Scale:
   +3: Major advantage (likely to prevent)
   +2: Significant advantage
   +1: Minor advantage
   0: No effect
   -1: Vulnerability
   
   Example - Full Plate:
   vs Slash: +3 (excellent protection)
   vs Pierce: +1 (some protection)
   vs Blunt: -1 (transfers force)
   ```

3. **Environmental Interactions**
   Wounds and armor interact with conditions:
   ```
   Bleeding + Cold:
   - Faster consciousness loss
   - Blood freezes on armor
   - Increased stiffness
   
   Broken Bone + Heat:
   - Faster fatigue
   - Swelling increases
   - More trauma gain
   
   Plate Armor + Rain:
   - Increased weight
   - Slippery surface
   - Rust risk
   - Reduced visibility
   ```

4. **Layering Effects**
   Multiple pieces interact:
   ```
   Gambeson + Mail + Plate:
   vs Slash: +4 (nearly impervious)
   vs Pierce: +2 (good protection)
   vs Blunt: +1 (force distribution)
   
   Environmental:
   - Increased heat buildup
   - Better cold protection
   - Higher action cost
   ```

### Armor Properties

1. **Coverage System**
   - Each piece covers specific body parts
   - Can mix different armor types
   - Gaps are vulnerable
   - Example Setup:
     ```
     Full Protection:
     - Head: Plate Helm
     - Neck: Mail Coif
     - Chest: Plate Cuirass
     - Arms: Mail + Plate
     - Legs: Mail + Greaves
     ```

2. **Protection Values**
   Each armor piece has ratings:
   ```
   Protection Scale (0-5):
   0: None
   1: Minimal
   2: Light
   3: Moderate
   4: Heavy
   5: Maximum

   Example (Plate Cuirass):
   - Slash: 5
   - Pierce: 3
   - Impact: 2
   ```

3. **Environmental Effects**
   - Heat:
     * Padding: +1 heat per piece
     * Mail: +0 heat
     * Plate: +2 heat per piece
   - Water:
     * Padding: +1 weight when wet
     * Mail: +2 weight when wet
     * Plate: Rust risk
   - Cold:
     * Padding: Good insulation
     * Mail: Poor insulation
     * Plate: Conducts cold

### Equipment Maintenance

## Special Equipment

### Tools
1. **Medical**
   - Bandages
   - Suture kits
   - Splints
   - Healing poultices

2. **Utility**
   - Rope
   - Grappling hooks
   - Torches
   - Lock picks

3. **Combat Support**
   - Caltrops
   - Smoke bombs
   - Trip wires
   - Shields

### Consumables
1. **Combat**
   - Throwing weapons
   - Ammunition
   - Weapon oils
   - Poisons

2. **Medical**
   - Healing potions
   - Antidotes
   - Stimulants
   - Pain reducers

3. **Utility**
   - Repair kits
   - Whetstones
   - Oil (maintenance)
   - Torch fuel

## Equipment Strategy Examples

### Example 1: Light Scout
```
Setup:
- Leather armor (minimal penalty)
- Short bow (range advantage)
- Dagger (backup)
- Light tools and medical supplies
Strategy: Mobile, range-focused, survival-oriented
```

### Example 2: Heavy Fighter
```
Setup:
- Full plate (maximum protection)
- Longsword (versatility)
- Warhammer (vs armor)
- Minimal extra equipment
Strategy: Close combat, durability, tactical positioning
```

### Example 3: Balanced Warrior
```
Setup:
- Mail + partial plate (moderate protection)
- Spear (reach advantage)
- Arming sword (backup)
- Mixed utility items
Strategy: Adaptable, good protection, utility options
```

### Action Economy System

1. **Base Actions**
   - Every turn starts with base actions:
     ```
     Unencumbered: 3 actions
     Light Load: 2 actions
     Medium Load: 2 actions
     Heavy Load: 1 action
     ```

2. **Action Costs**
   ```
   Basic Actions:
   - Move: 1 action
   - Attack: 1 action
   - Item use: 1 action
   - Weapon swap: 1 action
   
   Special Actions:
   - Complex attack (cone/cleave): 2 actions
   - Careful aim: 2 actions
   - Apply bandage: 2 actions
   - Sprint: 2 actions (double movement)
   ```

3. **Equipment Impact**
   ```
   Weapon Examples:
   - Dagger (Light): No action penalty
   - Longsword (Medium): -1 action if used one-handed
   - Greataxe (Heavy): Always -1 action
   
   Armor Examples:
   - Leather: No penalty
   - Chain: -1 action
   - Full Plate: -1 action, -2 in heat
   
   Combined Examples:
   Plate + Greataxe: 1 base action
   Chain + Longsword: 2 base actions
   Leather + Dagger: 3 base actions
   ```

4. **Condition Modifiers**
   ```
   Wounds:
   - Light wound: No penalty
   - Deep wound: -1 action to related activities
   - Critical wound: -1 action to all activities
   
   Environmental:
   - Heat exhaustion: -1 action
   - Freezing: -1 action
   - Wet ground: Movement costs +1 action
   - Darkness: Careful actions only (2 actions)
   ```

5. **Complex Scenarios**
   ```
   Example 1 - Wounded Knight:
   - Full plate armor (-1)
   - Longsword (medium)
   - Leg wound (-1)
   Base: 3 actions
   Final: 1 action per turn
   
   Example 2 - Archer in Rain:
   - Leather armor (no penalty)
   - Bow (medium)
   - Wet conditions (careful aim needed)
   Base: 3 actions
   Most attacks cost 2 actions due to conditions
   
   Example 3 - Exhausted Fighter:
   - Chain mail (-1)
   - Heat exhaustion (-1)
   - Spear (medium)
   Base: 3 actions
   Final: 1 action per turn
   ```

6. **Recovery and Adaptation**
   ```
   Recovery Options:
   - Rest: Gain +1 action next turn
   - Drop equipment: Immediate action economy improvement
   - Switch weapons: Might improve action economy
   
   Tactical Choices:
   - Remove armor: +1 action but less protection
   - Use weapon two-handed: Better effect but fewer actions
   - Lighter backup weapon: More actions but less effect
   ```

7. **Special Situations**
   ```
   Combat in Water:
   - Heavy armor: 0 actions (drowning risk)
   - Medium armor: 1 action
   - Light/No armor: 2 actions
   
   Climbing:
   - Heavy load: Impossible
   - Medium load: 2 actions per movement
   - Light load: 1 action per movement
   
   Stealth:
   - Heavy armor: Impossible
   - Medium armor: 2 actions per movement
   - Light armor: 1 action per movement
   ``` 