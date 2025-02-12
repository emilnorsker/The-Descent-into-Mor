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
    LEFT_HAND,
    RIGHT_HAND,
    RIGHT_EQUIPMENT,
    LEFT_EQUIPMENT,
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

var parts: Dictionary = {}
var wounds: Dictionary = {}  # Dictionary of BodyPart -> Array of Wound
var consciousness: float = 80.0
var is_dead = false
var equipment: Dictionary = {}  # Dictionary of slot -> Entity
var protection: Dictionary = {}  # Dictionary of part -> total protection

class Wound:
    var type: WoundType
    var treatment_level: int  # 0 = untreated, 1 = bandaged, 2 = stitched
    var part: BodyPart
    var bleeding_rate: int = 0

    func _init(severity: WoundType, part: BodyPart):
        self.type = severity
        self.part = part
        self.treatment_level = 0

func _init() -> void:
    super()
    for part in BodyPart.values():
        wounds[part] = []
        equipment[part] = null
        protection[part] = 0

func setup_from_blueprint(blueprint: Resource) -> BodyComponent:
    if not blueprint:
        push_error("Invalid blueprint provided to BodyComponent.setup_from_blueprint")
        return self

    wounds = blueprint.wounds
    consciousness = blueprint.consciousness
    is_dead = blueprint.is_dead
    parts = blueprint.parts

    return self

func setup_from_dict(data: Dictionary) -> Component:
    if data.has("parts"):
        parts = data.parts if data.parts is Dictionary else {}
    if data.has("wounds"):
        wounds = data.wounds if data.wounds is Dictionary else {}
    if data.has("consciousness"):
        consciousness = data.consciousness
    if data.has("equipment"):
        equipment = data.equipment if data.equipment is Dictionary else {}
    if data.has("protection"):
        protection = data.protection if data.protection is Dictionary else {}
    return self

func apply_wound(type: BodyComponent.WoundType, part: BodyComponent.BodyPart = BodyComponent.BodyPart.NONE) -> void:
    if is_dead:
        return
        
    if part == BodyComponent.BodyPart.NONE:
        part = randi_range(BodyPart.HEAD, BodyPart.RIGHT_LEG)
    var wound = Wound.new(type, part)
    wounds[wound.part].append(wound)
    
    var consciousness_loss = (wound.type+2) * 3  # (0-5 +2) * 3 = 6-24
    match part:
        BodyPart.HEAD:
            consciousness_loss *= 5
        BodyPart.NECK:
            consciousness_loss *= 4
        BodyPart.CHEST:
            consciousness_loss *= 1.5
    
    consciousness -= consciousness_loss #  ranges from 6-120
    emit_signal("wound_applied", type, part)
    
    # Check for instant death conditions
    if type == WoundType.FATAL and (part == BodyPart.HEAD or part == BodyPart.NECK):
        die()
    check_consciousness()
    
    

func add_consciousness(amount: int) -> void:
    consciousness += amount
    check_consciousness()

func check_consciousness() -> void:
    if consciousness <= 30:
        var roll = get_parent().roll(1, [-wounds.size() ])
        print("consciousness check: ", roll)
        if not roll:  # Need 4+ to stay conscious
            emit_signal("consciousness_check_failed")
            print("consciousness check failed, will die")
            die() # TODO: Implement unconsciousness state here
            if consciousness <= -50:
                pass
                # Implement actual death here

func treat_wound(body_part: int, wound_index: int, treatment_level: int) -> void:
    if wound_index < wounds[body_part].size():
        var wound = wounds[body_part][wound_index]
        wound.treatment_level = treatment_level
        
func is_limb_impaired(body_part: int) -> bool:
    # Check if body_part is a valid BodyPart value
    if not body_part in BodyPart.values():
        push_warning("Invalid body part %d passed to is_limb_impaired" % body_part)
        return false
        
    return false

func die() -> void:
    is_dead = true
    emit_signal("died")


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

func get_wound_severity(damage: int, part: BodyPart) -> WoundType:
    damage -= get_bodypart_protection(part)
    if damage < 10:
        return WoundType.LIGHT
    elif damage < 20:
        return WoundType.MODERATE
    elif damage < 30:
        return WoundType.SEVERE
    else:
        return WoundType.CRITICAL

func equip_to_slot(item: Entity, body_part = null) -> void:
    var parent = get_parent() as Entity
    if not parent or not parent.equipment: return
    
    # If no body part specified or invalid (-1), use default right hand
    var slot = BodyPart.RIGHT_EQUIPMENT
    if body_part != BodyPart.NONE and body_part in BodyPart.values():
        slot = body_part
    
    if is_limb_impaired(slot):
        SignalBus.message_sent.emit(parent.entity_name + " is unable to equip the %s." % item.entity_name, Color.RED)
        return
    
    parent.equipment.equip(item, slot)

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

func get_bodypart_protection(part: BodyPart) -> int:
    return 0