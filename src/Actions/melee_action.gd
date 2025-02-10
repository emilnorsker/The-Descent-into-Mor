@tool
extends Action
class_name MeleeAction

var target_body_part: int

func _init(p_performer: Entity, p_target: Entity, p_target_body_part: int) -> void:
    super(p_performer, p_target)
    target_body_part = p_target_body_part

func perform() -> bool:
    if not is_valid():
        return false
        
    var hit_chance = get_hit_chance()
    var roll = randf()
    
    if roll <= hit_chance:
        var damage = calculate_damage()
        target.components.combat.take_damage(damage)
        return true
    
    return false

func is_valid() -> bool:
    return performer.distance(target.grid_position) <= get_range()

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

func get_damage_bonus() -> int:
    var bonus = 0
    
    # Height advantage
    if performer.components.terrain:
        var terrain = performer.components.terrain
        if terrain.provides_high_ground():
            bonus += 2  # +2 damage when attacking from high ground
    
    # State modifiers
    if performer.components.combat_modifier:
        if performer.components.combat_modifier.has_state(Constants.StatusEffect.WINDED):
            bonus -= 1  # Less power when winded
    if target.components.combat_modifier.has_state(Constants.StatusEffect.DAZED):
        bonus += 1  # More damage against dazed targets
    
    return bonus

func calculate_damage() -> int:
    var base_damage = performer.components.combat.power()
    var defense = target.components.combat.defense()
    var damage = base_damage - defense + get_damage_bonus()
    
    # Critical hits
    if randf() <= 0.1:  # 10% crit chance
        damage *= 2
    
    return maxi(damage, 0)  # Minimum 0 damage 