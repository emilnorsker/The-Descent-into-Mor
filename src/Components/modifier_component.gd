@tool
class_name ModifierComponent extends Component

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

func _init(blueprint: Resource = null) -> void:
    super()
    name = "ModifierComponent"
    
    states = []
    _balance_check_results = {}
    
    if blueprint:
        if not blueprint is ModifierComponentBlueprint:
            push_error("Invalid blueprint type provided to ModifierComponent")
            return
            
        if blueprint.states:
            states = blueprint.states.duplicate()


func apply_state(state: ModifierComponent.StatusEffect, target: Entity = null, body_part: int = -1) -> void:
    if not state in states:
        states.append(state)
    
    # Handle state-specific effects
    match state:
        ModifierComponent.StatusEffect.ABLAZE:
            if target and target.material:
                if target.material.get_is_flammable():
                    target.material.add_state(ModifierComponent.StatusEffect.ABLAZE)
        ModifierComponent.StatusEffect.MUD_COVERED:
            if target and target.modifiers:
                target.modifiers.remove_state(ModifierComponent.StatusEffect.ABLAZE)

        ModifierComponent.StatusEffect.OILED:
            if target and target.material:
                var material = target.material
                # Store the balance check result for this target
                material.set_is_slippery(true)
                material.set_is_flammable(true)
        ModifierComponent.StatusEffect.BLEEDING:
            if target and target.body:
                # Apply bleeding wound
                target.body.apply_wound(BodyComponent.WoundType.MODERATE, BodyComponent.BodyPart.CHEST)
                target.body.consciousness -= 2  # Bleeding causes consciousness loss

func process_turn() -> void:
    var parent = get_parent() as Entity
    if not parent: return
    
    # Process bleeding
    if has_state(ModifierComponent.StatusEffect.BLEEDING) and parent.body:
        parent.body.consciousness -= 2  # Bleeding causes consciousness loss per turn

    if has_state(ModifierComponent.StatusEffect.ABLAZE) and parent.body:
        parent.body.apply_wound(BodyComponent.WoundType.MODERATE, BodyComponent.BodyPart.CHEST)

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

func roll(check: int, modifiers: Array[int] = []) -> bool:
    var dice = randi() % 6 + 1
    for modifier in modifiers:
        dice += modifier
    return dice >= check
