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
            if target and target.material:
                if target.material.get_is_flammable():
                    target.add_state(Constants.StatusEffect.ABLAZE)
        Constants.StatusEffect.MUD_COVERED:
            if target and target.has_state(Constants.StatusEffect.ABLAZE):
                target.remove_state(Constants.StatusEffect.ABLAZE)
        Constants.StatusEffect.OILED:
            if target and target.material:
                var material = target.material
                # Store the balance check result for this target
                _balance_check_results[target] = roll_balance_check()
                # Apply effects through the setters
                material.set_is_slippery(true)
                material.set_is_flammable(true)


func has_state(state: Constants.StatusEffect) -> bool:
    return state in states

func get_states() -> Array[Constants.StatusEffect]:
    return states

func leaves_trail() -> bool:
    return has_state(Constants.StatusEffect.BLEEDING)

func causes_weakness() -> bool:
    return has_state(Constants.StatusEffect.BLEEDING) or has_state(Constants.StatusEffect.WINDED)

func attracts_predators() -> bool:
    return has_state(Constants.StatusEffect.BLEEDING)

func needs_recovery() -> bool:
    return has_state(Constants.StatusEffect.WINDED)

func affects_reactions() -> bool:
    return has_state(Constants.StatusEffect.WINDED)

func vision_affected() -> bool:
    return has_state(Constants.StatusEffect.WINDED) or has_state(Constants.StatusEffect.DAZED)

func is_treacherous() -> bool:
    return has_state(Constants.StatusEffect.MUD_COVERED) and has_state(Constants.StatusEffect.PRONE)

func can_cause_slides() -> bool:
    return is_treacherous()

func causes_panic() -> bool:
    return has_state(Constants.StatusEffect.ABLAZE) and has_state(Constants.StatusEffect.PRONE)

func get_vision_range() -> float:
    var base_range = 8.0  # Default vision range
    if vision_is_blurred():
        return base_range * 0.5
    return base_range

func vision_is_blurred() -> bool:
    return has_state(Constants.StatusEffect.DAZED)

func roll_detection_check(target: Entity) -> int:
    var base_roll = randi() % 6 + 1
    if target.combat_modifier and target.combat_modifier.is_harder_to_detect():
        base_roll -= 2
    return base_roll

func has_status(status: Constants.StatusEffect) -> bool:
    match status:
        Constants.StatusEffect.PRONE:
            if has_state(Constants.StatusEffect.OILED):
                var check_result = _balance_check_results.get(get_parent(), roll_balance_check())
                return check_result < 4
        Constants.StatusEffect.PRONE_TO_FALLING:
            return has_state(Constants.StatusEffect.DAZED)
        Constants.StatusEffect.PANICKED:
            return has_state(Constants.StatusEffect.ABLAZE)
        Constants.StatusEffect.WEAKENED:
            return causes_weakness()
    return false

func roll_balance_check() -> int:
    return randi() % 6 + 1

func roll_grip_check(body_part: int = 0) -> int:
    return randi() % 6 + 1  # Simple d6 roll 