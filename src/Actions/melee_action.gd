@tool
class_name MeleeAction extends Action

var attacking_limb: int
var target_body_part: int

func _init(p_performer: Entity, p_target: Entity, p_attacking_limb: int, p_target_body_part: int = Constants.BodyPart.CHEST) -> void:
    super(p_performer, p_target)
    attacking_limb = p_attacking_limb
    target_body_part = p_target_body_part

func perform() -> bool:
    if not is_valid():
        return false
        
    var hit_chance = get_hit_chance()
    var hit_dc = 4  # Base DC for hitting
    var hit_modifiers = []
    
    # Add terrain modifiers
    if target.components.terrain and target.components.terrain.provides_high_ground():
        hit_modifiers.append(-1)  # Harder to hit targets on high ground
    if performer.components.terrain and performer.components.terrain.provides_high_ground():
        hit_modifiers.append(1)  # Easier to hit from high ground
    
    if performer.roll(hit_dc, hit_modifiers):
        # Apply wound based on damage
        var damage = calculate_damage()
        var wound_type = get_wound_type(damage)
        var severity = get_wound_severity(damage)
        
        # Apply wound to target
        if target.components.body:
            # Special case for headbutt - damage both participants
            if attacking_limb == Constants.BodyPart.HEAD and target_body_part == Constants.BodyPart.HEAD:
                performer.components.body.apply_wound(Constants.WoundType.LIGHT, Constants.BodyPart.HEAD, 1)
                target.components.body.apply_wound(Constants.WoundType.LIGHT, Constants.BodyPart.HEAD, 1)
            else:
                target.components.body.apply_wound(wound_type, target_body_part, severity)
            
            # Apply bleeding for weapon attacks
            if performer.components.equipment:
                var weapon = performer.components.equipment.get_equipped_item(Constants.BodyPart.RIGHT_HAND)
                if weapon and weapon.components.item:
                    # Ensure target has combat_modifier component
                    if not target.components.combat_modifier:
                        var combat_modifier = CombatModifierComponent.new()
                        target.components["combat_modifier"] = combat_modifier
                        target.add_child(combat_modifier)
                    target.components.combat_modifier.apply_state(Constants.StatusEffect.BLEEDING)
        
        return true
    
    return false

func is_valid() -> bool:
    var range = get_range()
    return performer.distance(target.grid_position) <= range

func get_hit_chance() -> float:
    var base_chance = 0.8  # 80% base chance to hit
    
    # Terrain modifiers
    if target.components.terrain:
        var terrain = target.components.terrain
        if terrain.provides_high_ground():
            base_chance *= 0.7  # 30% harder to hit targets on high ground
    
    if performer.components.terrain:
        var terrain = performer.components.terrain
        if terrain.provides_high_ground():
            base_chance *= 1.2  # 20% easier to hit from high ground
    
    return base_chance

func get_range() -> int:
    var base_range = 1  # Base melee range
    
    # Add weapon range if equipped
    if performer.components.equipment:
        var weapon = performer.components.equipment.get_equipped_item(Constants.BodyPart.RIGHT_HAND)
        if weapon and weapon.components.item:
            base_range += weapon.components.item.range - 1  # Subtract 1 since weapon range includes base range
    
    return base_range

func get_damage_bonus() -> int:
    var bonus = 0
    
    # Height advantage
    if performer.components.terrain:
        var terrain = performer.components.terrain
        if terrain.provides_high_ground():
            bonus += 2  # +2 damage when attacking from high ground
    
    # State modifiers
    if performer.components.combat_modifier and performer.components.combat_modifier.has_state(Constants.StatusEffect.WINDED):
        bonus -= 1  # Less power when winded
    if target.components.combat_modifier and target.components.combat_modifier.has_state(Constants.StatusEffect.DAZED):
        bonus += 1  # More damage against dazed targets
    
    return bonus

func calculate_damage() -> int:
    var base_damage = performer.roll_value(3)  # Base unarmed damage is d3
    
    # Add weapon damage if equipped
    if performer.components.equipment:
        var weapon = performer.components.equipment.get_equipped_item(Constants.BodyPart.RIGHT_HAND)
        if weapon and weapon.components.item:
            base_damage += performer.roll_value(6)  # Weapon adds d6
    
    # Add combat power
    if performer.components.combat:
        base_damage += performer.components.combat.power
    
    # Subtract defense
    var defense = 0
    if target.components.combat:
        defense = target.components.combat.defense
    
    var damage = base_damage - defense + get_damage_bonus()
    
    # Critical hits
    if performer.roll(6, []):  # Roll 6 or higher on d6 for crit
        damage *= 2
    
    return maxi(damage, 0)  # Minimum 0 damage

func get_wound_type(damage: int) -> int:
    # For unarmed attacks, check the attacking limb
    if not performer.components.equipment or not performer.components.equipment.get_equipped_item(Constants.BodyPart.RIGHT_HAND):
        # Kicks do moderate damage
        if attacking_limb == Constants.BodyPart.LEFT_LEG or attacking_limb == Constants.BodyPart.RIGHT_LEG:
            return Constants.WoundType.MODERATE
        # All other unarmed attacks do light damage
        return Constants.WoundType.LIGHT
    
    # For weapon attacks, base it on damage
    if damage <= 0:
        return Constants.WoundType.LIGHT
    elif damage <= 3:
        return Constants.WoundType.MODERATE
    elif damage <= 6:
        return Constants.WoundType.SEVERE
    elif damage <= 9:
        return Constants.WoundType.CRITICAL
    else:
        return Constants.WoundType.FATAL

func get_wound_severity(damage: int) -> int:
    # For unarmed attacks, always return 1
    if not performer.components.equipment or not performer.components.equipment.get_equipped_item(Constants.BodyPart.RIGHT_HAND):
        return 1
    
    # For weapon attacks, base it on damage
    if damage <= 0:
        return 1
    elif damage <= 3:
        return 2
    elif damage <= 6:
        return 3
    elif damage <= 9:
        return 4
    else:
        return 5 