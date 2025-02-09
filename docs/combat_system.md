# Combat System Documentation

### Weapon System

#### Core Weapon Properties
1. **Range**
   - Melee: 1 tile
   - Extended: 2 tiles (spears, halberds)
   - Ranged: Based on weapon type
   - Determines base attack options
   - Defense: bonus to the defense of the wielder.

2. **Ammo Type**
   - None (melee weapons)
   - Arrows
   - Bolts
   - Thrown
   - Special (magic charges, etc)

3. **Weight**
   - Light (0-2): No penalties
   - Medium (3-5): Minor speed penalty
   - Heavy (6+): Major speed penalty
   - Affects action points and stamina use

4. **Sharpness**
   - Dull (1): Reduced damage, more trauma
   - Sharp (2-3): Normal damage
   - Razor (4-5): Enhanced cutting, more bleeding
   - Can decrease with use
   - Affects wound severity

5. **Speed Penalty**
   - Affects action points
   - Modifies dodge chance
   - Impacts multiple attack options
   - Stacks with armor penalties

#### Dynamic Attack Generation
- Players choose attack type based on situation:
```
Example: Longsword
- Can perform slash (cleave or cone)
- Can perform thrust (single or line)
- Can pommel strike (blunt, single)
Each chosen at time of attack
```

### Armor System

#### Layered Protection
1. **Padding Layer**
   - Reduces blunt trauma
   - Absorbs some kinetic force
   - Minimal movement penalty
   - Examples: Gambeson, leather

2. **Mail Layer**
   - Strong vs slashing
   - Weak vs piercing
   - Moderate movement penalty
   - Distributes force across area

3. **Plate Layer**
   - Excellent vs all damage types
   - Very heavy
   - Major movement penalty
   - Can deflect hits completely

#### Armor Properties
1. **Coverage**
   - Different pieces cover different body parts
   - Gaps in armor are vulnerable
   - Can mix different types
   - Example:
     ```
     Full Plate Setup:
     - Plate helm (head)
     - Mail coif (neck)
     - Plate cuirass (chest)
     - Mail sleeves (arms)
     - Plate gauntlets (hands)
     ```

2. **Protection Values**
   - Slash Protection: How well it stops cuts
   - Pierce Protection: Resistance to stabbing
   - Impact Protection: Blunt force reduction
   - Example:
     ```
     Plate Armor:
     - Slash: 5 (Excellent)
     - Pierce: 3 (Good)
     - Impact: 2 (Moderate)
     ```

3. **Damage Reduction System**
   - Armor reduces wound severity
   - Can convert lethal hits to bruises
   - May prevent specific wound types
   - Example:
     ```
     Sword hit to plated area:
     - Deep wound -> Light wound
     - Bleeding prevented
     - Impact trauma still applies
     ```

4. **Penalties**
   - Movement speed reduction
   - Action point cost
   - Stamina drain
   - Dodge penalty
   - Stacks with weapon penalties

#### Armor Interaction with Damage Types
1. **Vs Slash**
   - Plate: Deflects most cuts
   - Mail: Prevents deep cuts
   - Leather: Reduces severity

2. **Vs Pierce**
   - Plate: Can deflect or be penetrated
   - Mail: Weak point exploitation
   - Leather: Minimal protection

3. **Vs Blunt**
   - Plate: Transfers force, may dent
   - Mail: Limited protection
   - Padding: Best defense

#### Special Armor Rules
1. **Weak Points**
   - Joints are vulnerable
   - Gaps can be targeted
   - Armor damage creates weak spots

2. **Environmental Effects**
   - Heat exhaustion in heavy armor
   - Water makes armor heavier
   - Cold metal affects wearer

3. **Maintenance**
   - Armor can be damaged
   - Requires repair
   - Degraded armor less effective

### Advanced Combat Examples

#### Example 7: Armored Combat
```
Heavy Plate Wearer vs Warhammer:
1. Direct hit to chest plate
2. Plate absorbs most force
3. Still causes impact trauma (+1)
4. Plate is dented, creating weak spot
5. Future hits to same area more effective
```

#### Example 8: Armor Gap Exploitation
```
Dagger vs Plate Mail:
1. Targeted attack to armpit gap
2. No armor protection applies
3. Critical pierce damage
4. Shows importance of targeting
```