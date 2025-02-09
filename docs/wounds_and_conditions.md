# Wounds and Conditions Catalog

## Wound Generation System

### Base Wound Table
Roll 1d6 + Consciousness Impact Modifier:

```
Consciousness Impact:
1-2: +0 to roll
3-4: +1 to roll
5-6: +2 to roll
7-8: +3 to roll
9+:  +4 to roll

Final Roll Result:
1-2: Light Wound
3-4: Moderate Wound
5-6: Severe Wound
7-8: Critical Wound
9+:  Fatal Wound
```

### Wound Type by Damage Type

#### Slash Damage
```
Light (1-2):
- Surface cut
- Light bleeding
- Minor pain

Moderate (3-4):
- Deep cut
- Steady bleeding
- Muscle damage

Severe (5-6):
- Severed muscles
- Arterial damage
- Tendon damage

Critical (7-8):
- Major artery cut
- Limb severance risk
- Multiple systems

Fatal (9+):
- Decapitation
- Bisection
- Major organ destruction
```

#### Pierce Damage
```
Light (1-2):
- Flesh wound
- Minor bleeding
- Surface puncture

Moderate (3-4):
- Deep puncture
- Internal bleeding
- Organ bruising

Severe (5-6):
- Organ puncture
- Major bleeding
- Cavity penetration

Critical (7-8):
- Vital organ hit
- Massive bleeding
- System failure

Fatal (9+):
- Heart pierce
- Brain damage
- Spine severance
```

#### Blunt Damage
```
Light (1-2):
- Bruising
- Minor swelling
- Temporary pain

Moderate (3-4):
- Heavy bruising
- Hairline fracture
- Joint damage

Severe (5-6):
- Bone break
- Organ bruising
- Concussion

Critical (7-8):
- Multiple breaks
- Internal rupture
- Skull fracture

Fatal (9+):
- Crushed organs
- Massive trauma
- Brain damage
```

### Location Modifiers
Add these to the wound roll:
```
Head: +2
Neck: +2
Heart: +3
Spine: +2
Joints: +1
Limbs: +0
Torso: +0
```

### Armor Interaction
Subtract armor rating from wound roll:
```
Example:
Base Roll: 6
Location (Head): +2
Armor (Plate): -3
Final Roll: 5 (Severe Wound)
```

### Environmental Modifiers
```
Wet: +1 to bleeding effects
Cold: -1 to bleeding, +1 to trauma
Heat: +1 to bleeding, +1 to infection
Dark: -1 to accuracy, +1 to wound severity
Elevation: +1 to fall damage
```

### Multiple Wound Interaction
```
Same Location:
- Take highest severity
- Add 1 to consciousness per additional wound
- Stack bleeding effects

Adjacent Locations:
- Both wounds apply
- +1 to consciousness checks
- May combine effects

System-Wide:
- All wounds apply
- Consciousness checks more frequent
- Higher risk of shock
```

### Treatment Difficulty
Based on wound severity:
```
Light: Basic treatment (bandage)
Moderate: Skilled treatment (stitches)
Severe: Expert treatment (surgery)
Critical: Immediate expert care
Fatal: Divine intervention needed
```

## Wound Types

### Head Wounds
1. **Concussion**
   - Consciousness: +3
   - Effects:
     * Blurred vision
     * Disorientation (-1 action)
     * Nausea (may vomit on exertion)
   - Environmental Interactions:
     * Heat worsens symptoms
     * Cold reduces swelling

2. **Skull Fracture**
   - Consciousness: +5
   - Effects:
     * Severe disorientation
     * Risk of brain damage
     * May lose consciousness
   - Critical: Requires immediate treatment

3. **Eye Damage**
   - Consciousness: +2
   - Effects:
     * Reduced vision
     * Blood in vision
     * Light sensitivity
   - May be permanent if untreated

4. **Jaw Wound**
   - Consciousness: +2
   - Effects:
     * Difficulty speaking
     * Cannot eat solid food
     * Risk of infection
   - Healing requires immobilization

### Torso Wounds

1. **Chest Wound**
   - Consciousness: +3
   - Effects:
     * Difficulty breathing
     * Reduced stamina
     * Pain on movement
   - Critical if lung punctured

2. **Heart Area**
   - Consciousness: +8
   - Effects:
     * Immediate critical condition
     * Rapid blood loss
     * Death risk very high
   - Requires immediate treatment

3. **Gut Wound**
   - Consciousness: +4
   - Effects:
     * Internal bleeding
     * Risk of infection
     * Severe pain
   - Worsens over time if untreated

4. **Spine Injury**
   - Consciousness: +6
   - Effects:
     * Paralysis risk
     * Loss of control
     * Permanent damage likely
   - Location determines severity

### Limb Wounds

1. **Arm Wounds**
   - **Muscle Cut**
     * Consciousness: +2
     * Reduced strength
     * Bleeding
     * May heal fully
   
   - **Tendon Damage**
     * Consciousness: +3
     * Loss of function
     * Requires surgery
     * Long recovery
   
   - **Bone Break**
     * Consciousness: +4
     * Useless arm
     * Risk of shock
     * Must be set

2. **Leg Wounds**
   - **Muscle Cut**
     * Consciousness: +2
     * Limping
     * Movement cost +1
     * Bleeding
   
   - **Tendon Damage**
     * Consciousness: +3
     * Cannot support weight
     * -2 actions for movement
     * Long-term impact
   
   - **Bone Break**
     * Consciousness: +4
     * Cannot stand
     * Shock risk
     * Requires splint

### Bleeding Wounds

1. **Light Bleeding**
   - Consciousness: +1 per 3 turns
   - Effects:
     * Slow blood loss
     * Can clot naturally
     * Minor weakness
   - Environmental:
     * Cold slows bleeding
     * Heat speeds it

2. **Arterial Bleeding**
   - Consciousness: +1 per turn
   - Effects:
     * Rapid blood loss
     * Cannot clot naturally
     * Requires immediate action
   - Critical if untreated

3. **Internal Bleeding**
   - Consciousness: +1 per 2 turns
   - Effects:
     * Hidden damage
     * Worsens with movement
     * Hard to treat
   - May cause organ damage

## Conditions

### Physical States

1. **Exhaustion**
   - Caused by:
     * Extended activity
     * Blood loss
     * Heat
   - Effects:
     * -1 action
     * Increased trauma gain
     * Slower recovery

2. **Shock**
   - Triggered by:
     * Severe wounds
     * Massive trauma
     * Critical hits
   - Effects:
     * Immediate consciousness check
     * Reduced action points
     * May cause collapse

3. **Infection**
   - Develops in:
     * Untreated wounds
     * Dirty conditions
     * Deep punctures
   - Effects:
     * Fever
     * Wound won't heal
     * Increasing trauma

### Environmental Effects

1. **Heat Exhaustion**
   - Causes:
     * Heavy armor in sun
     * Extended exertion
     * Lack of water
   - Effects:
     * -1 action
     * Increased trauma from wounds
     * Risk of collapse

2. **Hypothermia**
   - Causes:
     * Wet conditions
     * Metal armor in cold
     * Blood loss in cold
   - Effects:
     * Slowed movement
     * Reduced healing
     * Consciousness gain

3. **Drowning**
   - Stages:
     * Struggle (2 turns)
     * Panic (1 turn)
     * Unconsciousness
   - Effects:
     * Progressive action loss
     * Rapid consciousness gain
     * Death risk

## Wound Combinations

### Dangerous Combinations
1. **Bleeding + Exhaustion**
   - Faster consciousness gain
   - Higher risk of shock
   - Harder recovery

2. **Head Wound + Internal Bleeding**
   - May mask symptoms
   - Increased critical risk
   - Harder to treat

3. **Broken Bone + Infection**
   - Won't heal properly
   - Fever complications
   - May require amputation

### Environmental Factors

1. **Cold Environment**
   - Slows bleeding
   - Increases stiffness
   - Risk of hypothermia

2. **Hot Environment**
   - Speeds bleeding
   - Infection risk
   - Exhaustion risk

3. **Wet Conditions**
   - Infection risk
   - Slippery footing
   - Equipment issues

## Treatment Requirements

### Immediate Care Needed
- Heart wounds
- Arterial bleeding
- Skull fractures
- Spine injuries
- Drowning

### Urgent Care Needed
- Internal bleeding
- Deep infections
- Compound fractures
- Severe concussions
- Eye injuries

### Stable but Serious
- Simple fractures
- Muscle cuts
- Light bleeding
- Bruising
- Minor infections 