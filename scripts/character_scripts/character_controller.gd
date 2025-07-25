class_name Player
extends CharacterBody3D

@export var movement_speed: float = 2
@export_range(0.1, 1, 0.1, "Higher value means snappier rotation") var rotation_speed: float = 0.1;

@export var camera_relative: bool = false;

@export var interaction_range: Area3D;
@export var weapon_data: WeaponResource;

var player_state: String;

var current_triggers: Array[Area3D];
var do_processing: bool = true;

var direction: Vector3 = Vector3.ZERO;

var animation_controller: AnimationMachine;
@onready var creature_controller: CreatureController = $creature_holder;

@onready var nav_obstacle: NavigationObstacle3D = $NavigationObstacle3D;
@onready var animation_tree: AnimationTree = $character/AnimationTree;

@onready var body_part_inventory: Inventory = $body_parts_inventory;
	
func _ready() -> void:
	if interaction_range:
		interaction_range.area_entered.connect(_on_enter);
		interaction_range.area_exited.connect(_on_leave);
		interaction_range.collision_mask = Manager.instance.interactable_layer;
	else:
		Debug.message("interaction_range undefined, can not interact.")
		
	if nav_obstacle:
		nav_obstacle.visible = true;
		
	animation_controller = AnimationMachine.new(animation_tree, "base");
	_setup_animations()
	
	body_part_inventory.add(Manager.instance.resource_manager.get_item("skeleton_flesh_head"))
	body_part_inventory.add(Manager.instance.resource_manager.get_item("skeleton_flesh_body"))
	
func _setup_animations() -> void:
	animation_controller.add_state(AnimationControllerState.new("IWR", "parameters/IWR/blend_position", AnimationControllerState.StateType.BLEND))
	
func update_movement(b: bool) -> void:
	do_processing = b;

func _physics_process(delta: float) -> void: 
	player_state = "idle"
	var input_dir := Input.get_vector("left", "right", "back", "forward").normalized()
	if camera_relative:
		var cam_transform := Manager.instance.camera.global_transform
		var cam_forward := -cam_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()

		var cam_right := cam_transform.basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()

		direction = (cam_forward * input_dir.y + cam_right * input_dir.x).normalized()
	else:
		direction = Vector3(input_dir.x, 0, -input_dir.y).normalized()
	
	if direction && do_processing:
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
		
		var target_rotation := atan2(direction.x, direction.z);
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed);
	else:
		velocity.x = move_toward(velocity.x, 0, movement_speed)
		velocity.z = move_toward(velocity.z, 0, movement_speed)
	move_and_slide()

	var horizontal_speed := Vector3(velocity.x, 0, velocity.z).length();
	animation_controller.blend_state("IWR", clampf(horizontal_speed, 0.0, 2.0), delta)

	if horizontal_speed > 0.1:
		player_state = "running"
	else:
		player_state = "idle"
	move_and_slide();

	animation_controller.animation_state = player_state;
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact();
	elif event.is_action_pressed("inventory"):
		SceneManager.instance.get_scene_info("inventory").queue(_open_inventory);
			
func _open_inventory(sI: SceneInfo) -> void:
	if SceneManager.instance.add(sI):
		sI.get_instance().element.inventory = body_part_inventory;
		
func interact() -> void:
	if current_triggers.size() != 0:
		var interactable: Interactable = current_triggers[0].get_meta("interactable");
		if interactable.has_method("on_interact"):
			do_processing = not animation_controller.set_state_on_machine("interact");
			interactable.interact(-1);
	
func sort_areas_by_distance() -> void:
	current_triggers.sort_custom(func(a: Node3D, b: Node3D) -> float: return global_position.distance_squared_to(a.global_position) > global_position.distance_squared_to(b.global_position));

func _on_enter(body: Area3D) -> void:
	if !current_triggers.has(body):
		current_triggers.push_back(body);
		sort_areas_by_distance();
		if body.has_method("on_area_enter"):
			body.on_area_enter();
	
func _on_leave(body: Area3D) -> void:
	current_triggers.erase(body);
	if body.has_method("on_area_leave"):
		body.on_area_leave();
		
func on_attack_start() -> void:
	do_processing = false;
	animation_controller.set_state_on_machine("attack_chop");
		
func _on_attack_hit(body: Area3D) -> void:
	var enemy: CreatureInstance = body.get_parent();
	if enemy is CreatureInstance:
		enemy.take_damage(weapon_data.calculate_damage());
