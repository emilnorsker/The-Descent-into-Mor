@tool
class_name CombatModifierComponent
extends Component

var states: Array[Constants.StatusEffect] = []
var _balance_check_results: Dictionary = {}

func _init() -> void:
    super()

func setup_from_blueprint(blueprint: Resource) -> CombatModifierComponent:
    if not blueprint:
        push_error("Invalid blueprint provided to CombatModifierComponent.setup_from_blueprint")
        return self

    states = blueprint.states

    return self

func apply_state(state: Constants.StatusEffect, target: Entity = null, body_part: int = -1) -> void:
    if not state in states:
        states.append(state)
    
    # Handle state-specific effects
    match state:
        Constants.StatusEffect.ABLAZE:
            if target and target.components.material:
                if target.components.material.get_is_flammable():
                    target.components.material.add_state(Constants.StatusEffect.ABLAZE)
        Constants.StatusEffect.MUD_COVERED:
            if target and target.components.combat_modifier:
                target.components.combat_modifier.remove_state(Constants.StatusEffect.ABLAZE)

        Constants.StatusEffect.OILED:
            if target and target.components.material:
                var material = target.components.material
                # Store the balance check result for this target
                material.set_is_slippery(true)
                material.set_is_flammable(true)
        Constants.StatusEffect.BLEEDING:
            if target and target.components.body:
                # Apply bleeding wound
                target.components.body.apply_wound(Constants.WoundType.MODERATE, Constants.BodyPart.CHEST)
                target.components.body.add_consciousness(2)  # Bleeding causes consciousness loss

func process_turn() -> void:
    var parent = get_parent() as Entity
    if not parent: return
    
    # Process bleeding
    if has_state(Constants.StatusEffect.BLEEDING) and parent.components.body:
        parent.components.body.add_consciousness(2)  # Bleeding causes consciousness loss per turn

    if has_state(Constants.StatusEffect.ABLAZE) and parent.components.body:
        parent.components.body.apply_wound(Constants.WoundType.MODERATE, Constants.BodyPart.CHEST)

func has_state(state: Constants.StatusEffect) -> bool:
    return state in states

func get_states() -> Array[Constants.StatusEffect]:
    return states

func vision_affected() -> bool:
    return has_state(Constants.StatusEffect.WINDED) or has_state(Constants.StatusEffect.DAZED)

func causes_panic() -> bool:
    return has_state(Constants.StatusEffect.ABLAZE) and has_state(Constants.StatusEffect.PINNED)

func get_vision_range() -> float:
    var base_range = 8.0  # Default vision range
    if vision_is_blurred():
        return base_range * 0.5
    return base_range

func vision_is_blurred() -> bool:
    return has_state(Constants.StatusEffect.DAZED)

func has_status(status: Constants.StatusEffect) -> bool:
    match status:
        Constants.StatusEffect.PINNED:
            if has_state(Constants.StatusEffect.OILED): # TODO: this is bad fix, we dont want to reroll evertime we check.
                return roll(4)
                
        Constants.StatusEffect.PRONE_TO_FALLING:
            return has_state(Constants.StatusEffect.DAZED)
        Constants.StatusEffect.PANICKED:
            return has_state(Constants.StatusEffect.ABLAZE)
        Constants.StatusEffect.BLEEDING:
            return has_state(Constants.StatusEffect.BLEEDING)
    return false

func roll(check: int, modifiers: Array[int] = []) -> bool:
    var dice = randi() % 6 + 1
    for modifier in modifiers:
        dice += modifier
    return dice >= check
