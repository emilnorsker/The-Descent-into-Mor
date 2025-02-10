extends Node

enum BodyPart {
    HEAD,
    NECK,
    CHEST,
    ABDOMEN,
    LEFT_ARM,
    RIGHT_ARM,
    LEFT_HAND,
    RIGHT_HAND,
    LEFT_LEG,
    RIGHT_LEG,
    FRONT_LEFT_LEG,
    FRONT_RIGHT_LEG,
    BACK_LEFT_LEG,
    BACK_RIGHT_LEG
}

enum DamageType {
    SLASH,
    PIERCE,
    BLUNT,
    FIRE
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
    BURNT,
    INTERNAL
}

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

enum TreatmentType {
    BANDAGE,
    STITCHES,
    SURGERY
}

enum TargetType {
    SINGLE,
    LINE,
    CONE,
    CLEAVE
} 