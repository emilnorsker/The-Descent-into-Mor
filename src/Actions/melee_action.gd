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
    if target.components.terrain and target.components.terrain.provides_high_ground():
        hit_modifiers.append(-1)  # Harder to hit targets on high ground
    if performer.components.terrain and performer.components.terrain.provides_high_ground():
        hit_modifiers.append(1)  # Easier to hit from high ground
    
    if performer.roll(hit_dc, hit_modifiers):
        print(performer.entity_name, " hit ", target.entity_name)
        var damage = calculate_damage(attacking_limb)

        if target.components.body:
            var severity = target.components.body.get_wound_severity(damage, target_body_part)

            # Special case for headbutt - damage both participants - tobe replaced with damage to attacking item etc...
            if attacking_limb == BodyComponent.BodyPart.HEAD and target_body_part == BodyComponent.BodyPart.HEAD:
                performer.components.body.apply_wound(BodyComponent.WoundType.LIGHT, BodyComponent.BodyPart.HEAD)
                target.components.body.apply_wound(BodyComponent.WoundType.LIGHT, BodyComponent.BodyPart.HEAD)
            else:
                target.components.body.apply_wound(severity, target_body_part)
            
            # Apply bleeding for weapon attacks
            if performer.components.equipment:
                var weapon = performer.components.equipment.get_equipped_item(BodyComponent.BodyPart.RIGHT_EQUIPMENT)
                if weapon and weapon.components.item:
                    # Ensure target has modifiers component
                    if not target.components.modifiers:
                        var modifiers = ModifierComponent.new()
                        target.components["modifiers"] = modifiers
                        target.add_child(modifiers)
                    target.components.modifiers.apply_state(ModifierComponent.StatusEffect.BLEEDING)
        
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
        var weapon = performer.components.equipment.get_equipped_item(BodyComponent.BodyPart.RIGHT_EQUIPMENT)
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
    if performer.components.modifiers and performer.components.modifiers.has_state(ModifierComponent.StatusEffect.WINDED):
        bonus -= 1  # Less power when winded
    if target.components.modifiers and target.components.modifiers.has_state(ModifierComponent.StatusEffect.DAZED):
        bonus += 1  # More damage against dazed targets
    
    return bonus

func calculate_damage(attacking_limb: BodyComponent.BodyPart) -> int:
    var damage = 0
    
    # get equipment damage
    match attacking_limb:
        BodyComponent.BodyPart.LEFT_EQUIPMENT, BodyComponent.BodyPart.RIGHT_EQUIPMENT:
            if performer.components.equipment:
                var weapon = performer.components.equipment.get_equipped_item(attacking_limb)
                if weapon and weapon.components.item:
                    if weapon.components.item.equipment_type == ItemComponent.EquipmentType.WEAPON:
                        damage = performer.roll_value(10)  # Full damage for actual weapons
                        damage += weapon.components.item.power_bonus
                    else:
                        # Improvised weapon damage based on weight
                        if weapon.components.weight:
                            damage = ceili(weapon.components.weight.weight)  # Round up weight to nearest int
        BodyComponent.BodyPart.NONE:
            if performer.components.equipment:
                var weapon = performer.components.equipment.get_equipped_item(attacking_limb)
                if weapon and weapon.components.item:
                    if weapon.components.item.equipment_type == ItemComponent.EquipmentType.WEAPON:
                        damage = performer.roll_value(10)  # Full damage for actual weapons
                        damage += weapon.components.item.power_bonus
                    else:
                        # Improvised weapon damage based on weight
                        if weapon.components.weight:
                            damage = ceili(weapon.components.weight.weight)  # Round up weight to nearest int
        
    return maxi(damage, 0)  # Minimum 0 damage
