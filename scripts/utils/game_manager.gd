extends Node
class_name Manager

@onready var player: Player = %character;
var camera: Camera3D;

static var instance: Manager;
var scroll_in_use: bool = false;

@export var resource_manager: ResourceManager;
@export var navigation_region: NavigationRegion3D;
@export var cursor_list: Dictionary[String, Texture2D];
var object_pool: ObjectPool;

var interactable_layer: int = 1 << 4;

signal input_mode_changed(is_keyboard: bool);
var input_mode_is_keyboard: bool = true:
	set(value):
		input_mode_is_keyboard = value;
		input_mode_changed.emit(value)
		
func _ready() -> void:
	object_pool = ObjectPool.new();
	get_parent().add_child.call_deferred(object_pool);
	object_pool.name = "object_pool";
	object_pool.visible = false;

func _init() -> void:
	Manager.instance = self;
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	input_mode_is_keyboard = event is InputEventKey || event is InputEventMouse;
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		pause();
		
func pause(pause_game: bool = !get_tree().paused) -> void:
	get_tree().paused = pause_game
	if pause_game:
		SceneManager.instance.get_or_create_scene("paused", SceneConfig.new(false));
		
func set_cursor(cursor: String) -> void:
	if cursor_list.has(cursor):
		Input.set_custom_mouse_cursor(cursor_list[cursor]);
	else:
		Debug.message("No cursor was found with identifier %s." % cursor)
