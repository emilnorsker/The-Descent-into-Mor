@tool
class_name BodyComponent extends Component

signal consciousness_check_failed
signal wound_applied(wound_type: int, body_part: int)
signal condition_applied(condition: int)
signal died

enum BodyPart {
    NONE,
    HEAD,
    NECK,
    CHEST,
    ABDOMEN,
    LEFT_ARM,
    RIGHT_ARM,
    LEFT_LEG,
    RIGHT_LEG
}

enum WoundType {
    LIGHT,
    MODERATE,
    SEVERE,
    CRITICAL,
    FATAL
}

enum WoundEffect {
    BLEEDING,
    PAIN,
    CRIPPLED,
    INTERNAL
}

var parts: Dictionary = {}
var wounds: Dictionary = {}  # Dictionary of BodyPart -> Array of Wound
var consciousness = 0
var is_dead = false
var equipment: Dictionary = {}  # Dictionary of slot -> Entity
var protection: Dictionary = {}  # Dictionary of part -> total protection

class Wound:
    enum TreatmentLevel {
        UNTREATED,
        BANDAGED,
        STITCHED
    }

    var type: int  # WoundType
    var treatment_level: TreatmentLevel  # 0 = untreated, 1 = bandaged, 2 = stitched
    var part: BodyPart
    func _init(p_severity: int):
        severity = p_severity
        effects = []
        bleeding_rate = 0
        treatment_level = 0
        
        # Apply effects based on type and severity
        match type:
            WoundType.LIGHT:
                if severity > 2:
                    effects.append(WoundEffect.BLEEDING)
            WoundType.MODERATE:
                effects.append(WoundEffect.BLEEDING)
                effects.append(WoundEffect.PAIN)
            WoundType.SEVERE:
                effects.append(WoundEffect.BLEEDING)
                effects.append(WoundEffect.PAIN)
                effects.append(WoundEffect.CRIPPLED)
            WoundType.CRITICAL:
                effects.append(WoundEffect.BLEEDING)
                effects.append(WoundEffect.PAIN)
                effects.append(WoundEffect.CRIPPLED)
                effects.append(WoundEffect.INTERNAL)
            WoundType.FATAL:
                effects.append_array([WoundEffect.BLEEDING, WoundEffect.PAIN, 
                                   WoundEffect.CRIPPLED, WoundEffect.INTERNAL])
        
        # Set bleeding rate based on severity and effects
        if WoundEffect.BLEEDING in effects:
            bleeding_rate = severity

func _init() -> void:
    super()

func setup_from_blueprint(blueprint: Resource) -> BodyComponent:
    if not blueprint:
        push_error("Invalid blueprint provided to BodyComponent.setup_from_blueprint")
        return self

    wounds = blueprint.wounds
    consciousness = blueprint.consciousness
    is_dead = blueprint.is_dead
    parts = blueprint.parts

    return self

func _ready():
    # Initialize wounds dictionary for each body part
    for part in BodyPart.values():
        wounds[part] = []
        equipment[part] = null
        protection[part] = 0

func apply_wound(wound: Wound) -> void:
    if is_dead:
        return
        
    var wound = Wound.new(type, severity)
    wounds[body_part].append(wound)
    
    # Add consciousness based on wound severity and location
    var consciousness_gain = severity
    match body_part:
        BodyPart.HEAD:
            consciousness_gain *= 2.5
        BodyPart.NECK:
            consciousness_gain *= 1.75
        BodyPart.CHEST:
            consciousness_gain *= 1.25
    
    add_consciousness(consciousness_gain)
    
    emit_signal("wound_applied", type, body_part)
    
    # Check for instant death conditions
    if type == WoundType.FATAL and (body_part == BodyPart.HEAD or body_part == BodyPart.NECK):
        die()

func add_consciousness(amount: int) -> void:
    consciousness += amount
    check_consciousness()

func check_consciousness() -> void:
    if consciousness >= 10:
        # Roll to stay conscious (1d6)
        var roll = randi() % 6 + 1
        if roll < 4:  # Need 4+ to stay conscious
            emit_signal("consciousness_check_failed")
            die()

func process_bleeding() -> void:
    var total_bleeding = 0
    
    # Calculate total bleeding from all wounds
    for part in wounds.keys():
        for wound in wounds[part]:
            if wound.treatment_level == 0 and WoundEffect.BLEEDING in wound.effects:
                total_bleeding += wound.bleeding_rate
    
    if total_bleeding > 0:
        add_consciousness(total_bleeding / 2)  # Consciousness from blood loss

func treat_wound(body_part: int, wound_index: int, treatment_level: int) -> void:
    if wound_index < wounds[body_part].size():
        var wound = wounds[body_part][wound_index]
        wound.treatment_level = treatment_level
        
        # Reduce bleeding based on treatment
        if treatment_level > 0 and WoundEffect.BLEEDING in wound.effects:
            wound.bleeding_rate = max(0, wound.bleeding_rate - treatment_level)

func is_limb_impaired(body_part: int) -> bool:
    # Check if body_part is a valid BodyPart value
    if not body_part in BodyPart.values():
        push_warning("Invalid body part %d passed to is_limb_impaired" % body_part)
        return false
        
    for wound in wounds[body_part]:
        if WoundEffect.CRIPPLED in wound.effects:
            return true
    return false

func get_total_bleeding() -> int:
    var total = 0
    for part in wounds.keys():
        for wound in wounds[part]:
            if wound.treatment_level == 0 and WoundEffect.BLEEDING in wound.effects:
                total += wound.bleeding_rate
    return total

func die() -> void:
    is_dead = true
    emit_signal("died")


func has_any_wound(type: WoundType) -> bool:
    for part in wounds.keys():
        for wound in wounds[part]:
            if wound.type == type:
                return true
    return false

func get_wounds(part = null) -> Array:
    if part:
        assert(part is BodyPart, "ERROR: You must give part a value.");

        return wounds[part]
    else:
        var wounds_arr = []
        for wounded_part in wounds.keys():
            for wound in wounds[wounded_part]:
                wound.part = wounded_part
                wounds_arr.append(wound)
        return wounds_arr

func get_wounds_of_type(type: WoundType) -> Array: 
    var result = []
    for part in wounds.keys():
        for wound in wounds[part]:
            if wound.type == type:
                result.append({"part": part, "wound": wound})
    return result

func equip_to_slot(item: Entity, body_part = null) -> void:
    var parent = get_parent() as Entity
    if not parent or not parent.components.equipment: return
    
    # If no body part specified or invalid (-1), use default right hand
    var slot = BodyComponent.BodyPart.RIGHT_HAND
    if body_part != null and body_part in BodyPart.values():
        slot = body_part
    
    if is_limb_impaired(slot):
        SignalBus.message_sent.emit(parent.entity_name + " is unable to equip the %s." % item.entity_name, Color.RED)
        return
    
    parent.components.equipment.equip(item, slot)

func process_recovery() -> void:
    # Natural consciousness recovery
    if consciousness > 0:
        consciousness = max(0, consciousness - 1)
        
    # Process wound recovery
    for part in wounds.keys():
        for wound in wounds[part]:
            if wound.treatment_level > 0:
                # Treated wounds can improve
                if wound.severity > 1 and randf() < 0.1:  # 10% chance per turn
                    wound.severity -= 1
                    if wound.severity == 0:
                        wounds[part].erase(wound) 

func has_equipment_in_slot(part: int, slot_type: String) -> bool:
    return equipment.has(part) and equipment[part] != null

func get_protection_for_part(part: int) -> int:
    return protection.get(part, 0)

func get_total_protection_for_part(part: int) -> int:
    return protection.get(part, 0)

func has_protection(part: int) -> bool:
    return protection.get(part, 0) > 0

func get_wound_protection(part: int, damage_type: String) -> int:
    if not equipment.has(part) or not equipment[part]:
        return 0
    var item = equipment[part]
    if not item.components.has("armor"):
        return 0
    return item.components.armor.protection 
