class_name CreatureResource extends ValidatedResource

enum Role{
	NONE,
	THRALL,
	ARTILLERY,
	WARDEN,
	MONSTROSITY,
	SPECIALIST
}

@export var translation_key: String = "";
@export var role: Role = Role.NONE;
@export var creature: PackedScene = null;
@export var move_speed: float = 1;

func validate() -> bool:
	_setup();
	is_valid = translation_key != "" && creature != null && role != Role.NONE;
	return is_valid;
