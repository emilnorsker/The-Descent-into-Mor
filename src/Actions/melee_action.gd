@tool
class_name MeleeAction extends Action


var target_body_part: BodyComponent.BodyPart = BodyComponent.BodyPart.NONE
var attacking_limb: BodyComponent.BodyPart = BodyComponent.BodyPart.NONE

func _init(
    performer: Entity,
    target: Entity,
    target_body_part: BodyComponent.BodyPart = BodyComponent.BodyPart.NONE,
    attacking_limb: BodyComponent.BodyPart = BodyComponent.BodyPart.NONE
) -> void:
    super(performer, target)
    self.target_body_part = target_body_part
    self.attacking_limb = attacking_limb
    

func perform() -> bool:
    if not is_valid():
        return false
        
    var hit_chance = get_hit_chance()
    var hit_dc = 4  # Base DC for hit chance, TODO: make this dynamic
    var hit_modifiers = []
    
    # Add terrain modifiers
    if target.terrain and target.terrain.provides_high_ground():
        hit_modifiers.append(-1)  # Harder to hit targets on high ground
    if performer.terrain and performer.terrain.provides_high_ground():
        hit_modifiers.append(1)  # Easier to hit from high ground
    
    if performer.roll(hit_dc, hit_modifiers):
        print(performer.entity_name, " hit ", target.entity_name)
        var damage = calculate_damage(attacking_limb)

        if target.body:
            var severity = target.body.get_wound_severity(damage, target_body_part)

            # Special case for headbutt - damage both participants - tobe replaced with damage to attacking item etc...
            if attacking_limb == BodyComponent.BodyPart.HEAD and target_body_part == BodyComponent.BodyPart.HEAD:
                performer.body.apply_wound(BodyComponent.WoundType.LIGHT, BodyComponent.BodyPart.HEAD)
                target.body.apply_wound(BodyComponent.WoundType.LIGHT, BodyComponent.BodyPart.HEAD)
            else:
                target.body.apply_wound(severity, target_body_part)
            
            # Apply bleeding for weapon attacks
            if performer.equipment:
                var weapon = performer.equipment.get_equipped_item(BodyComponent.BodyPart.RIGHT_EQUIPMENT)
                if weapon and weapon.item:
                    # Ensure target has modifiers component
                    if not target.modifiers:
                        var modifiers = ModifierComponent.new()
                        target.components["modifiers"] = modifiers
                        target.add_child(modifiers)
                    target.modifiers.apply_state(ModifierComponent.StatusEffect.BLEEDING)
        
        return true
    
    return false

func is_valid() -> bool:
    var range = get_range()
    return performer.distance(target.grid_position) <= range

func get_hit_chance() -> float:
    var base_chance = 0.8  # 80% base chance to hit
    
    # Terrain modifiers
    if target.terrain:
        var terrain = target.terrain
        if terrain.provides_high_ground():
            base_chance *= 0.7  # 30% harder to hit targets on high ground
    
    if performer.terrain:
        var terrain = performer.terrain
        if terrain.provides_high_ground():
            base_chance *= 1.2  # 20% easier to hit from high ground
    
    return base_chance

func get_range() -> int:
    var base_range = 1  # Base melee range
    
    # Add weapon range if equipped
    if performer.equipment:
        var weapon = performer.equipment.get_equipped_item(BodyComponent.BodyPart.RIGHT_EQUIPMENT)
        if weapon and weapon.item:
            base_range += weapon.item.range - 1  # Subtract 1 since weapon range includes base range
    
    return base_range

func get_damage_bonus() -> int:
    var bonus = 0
    
    # Height advantage
    if performer.terrain:
        var terrain = performer.terrain
        if terrain.provides_high_ground():
            bonus += 2  # +2 damage when attacking from high ground
    
    # State modifiers
    if performer.modifiers and performer.modifiers.has_state(ModifierComponent.StatusEffect.WINDED):
        bonus -= 1  # Less power when winded
    if target.modifiers and target.modifiers.has_state(ModifierComponent.StatusEffect.DAZED):
        bonus += 1  # More damage against dazed targets
    
    return bonus

func calculate_damage(attacking_limb: BodyComponent.BodyPart) -> int:
    var damage = 0
    
    # get equipment damage
    match attacking_limb:
        BodyComponent.BodyPart.LEFT_EQUIPMENT, BodyComponent.BodyPart.RIGHT_EQUIPMENT:
            if performer.equipment:
                var weapon = performer.equipment.get_equipped_item(attacking_limb)
                if weapon and weapon.item:
                    if weapon.item.equipment_type == ItemComponent.EquipmentType.WEAPON:
                        damage = performer.roll_value(10)  # Full damage for actual weapons
                        damage += weapon.item.power_bonus
                    else:
                        # Improvised weapon damage based on weight
                        if weapon.weight:
                            damage = ceili(weapon.weight.weight)  # Round up weight to nearest int
        BodyComponent.BodyPart.NONE:
            if performer.equipment:
                var weapon = performer.equipment.get_equipped_item(attacking_limb)
                if weapon and weapon.item:
                    if weapon.item.equipment_type == ItemComponent.EquipmentType.WEAPON:
                        damage = performer.roll_value(10)  # Full damage for actual weapons
                        damage += weapon.item.power_bonus
                    else:
                        # Improvised weapon damage based on weight
                        if weapon.weight:
                            damage = ceili(weapon.weight.weight)  # Round up weight to nearest int
        
    return maxi(damage, 0)  # Minimum 0 damage
