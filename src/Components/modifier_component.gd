@tool
class_name ModifierComponent
extends Component


enum StatusEffect {
    STUNNED,
    BLEEDING,
    WEAKENED,
    SHOCK,
    PRONE,
    PANICKED,
    DISARMED,
    ABLAZE,
    PRONE_TO_FALLING,
    MUD_COVERED,
    OILED,
    DAZED,
    FLANKING,
    PINNED,
    WOUNDED,
    HEAVY_WOUNDED,
    DEAD,
    WINDED
}


var states: Array[ModifierComponent.StatusEffect] = []
var _balance_check_results: Dictionary = {}

func _init() -> void:
    super()

func setup_from_blueprint(blueprint: Resource) -> ModifierComponent:
    if not blueprint:
        push_error("Invalid blueprint provided to ModifierComponent.StatusEffect.setup_from_blueprint")
        return self

    states = blueprint.states

    return self

func apply_state(state: ModifierComponent.StatusEffect, target: Entity = null, body_part: int = -1) -> void:
    if not state in states:
        states.append(state)
    
    # Handle state-specific effects
    match state:
        ModifierComponent.StatusEffect.ABLAZE:
            if target and target.components.material:
                if target.components.material.get_is_flammable():
                    target.components.material.add_state(ModifierComponent.StatusEffect.ABLAZE)
        ModifierComponent.StatusEffect.MUD_COVERED:
            if target and target.components.modifiers:
                target.components.modifiers.remove_state(ModifierComponent.StatusEffect.ABLAZE)

        ModifierComponent.StatusEffect.OILED:
            if target and target.components.material:
                var material = target.components.material
                # Store the balance check result for this target
                material.set_is_slippery(true)
                material.set_is_flammable(true)
        ModifierComponent.StatusEffect.BLEEDING:
            if target and target.components.body:
                # Apply bleeding wound
                target.components.body.apply_wound(BodyComponent.WoundType.MODERATE, BodyComponent.BodyPart.CHEST)
                target.components.body.consciousness -= 2  # Bleeding causes consciousness loss

func process_turn() -> void:
    var parent = get_parent() as Entity
    if not parent: return
    
    # Process bleeding
    if has_state(ModifierComponent.StatusEffect.BLEEDING) and parent.components.body:
        parent.components.body.consciousness -= 2  # Bleeding causes consciousness loss per turn

    if has_state(ModifierComponent.StatusEffect.ABLAZE) and parent.components.body:
        parent.components.body.apply_wound(BodyComponent.WoundType.MODERATE, BodyComponent.BodyPart.CHEST)

func has_state(state: ModifierComponent.StatusEffect) -> bool:
    return state in states

func get_states() -> Array[ModifierComponent.StatusEffect]:
    return states

func vision_affected() -> bool:
    return has_state(ModifierComponent.StatusEffect.WINDED) or has_state(ModifierComponent.StatusEffect.DAZED)

func is_panicked() -> bool:
    return has_state(ModifierComponent.StatusEffect.ABLAZE) and has_state(ModifierComponent.StatusEffect.PINNED)


func vision_is_blurred() -> bool:
    return has_state(ModifierComponent.StatusEffect.DAZED)

func has_status(status: ModifierComponent.StatusEffect) -> bool:
    match status:
        ModifierComponent.StatusEffect.PINNED:
            if has_state(ModifierComponent.StatusEffect.OILED): # TODO: this is bad fix, we dont want to reroll evertime we check.
                return roll(4)
                
        ModifierComponent.StatusEffect.PRONE_TO_FALLING:
            return has_state(ModifierComponent.StatusEffect.DAZED)
        ModifierComponent.StatusEffect.PANICKED:
            return has_state(ModifierComponent.StatusEffect.ABLAZE)
        ModifierComponent.StatusEffect.BLEEDING:
            return has_state(ModifierComponent.StatusEffect.BLEEDING)
    return false

func roll(check: int, modifiers: Array[int] = []) -> bool:
    var dice = randi() % 6 + 1
    for modifier in modifiers:
        dice += modifier
    return dice >= check
