class_name DraggableControl
extends Control

@export var id: String = "";

@onready var vp := get_viewport()
@onready var top_bar: ColorRect = $MarginContainer/VBoxContainer/topbar;
@onready var close_button: Button = $MarginContainer/VBoxContainer/topbar/HBoxContainer/Button;
@onready var title: Label = $MarginContainer/VBoxContainer/topbar/HBoxContainer/MarginContainer/Title;
@onready var content_panel: ColorRect = $MarginContainer/VBoxContainer/content;

@export_enum("fullscreen", "display", "no_header") var display_mode: String = "display"
@export_enum("mouse", "center", "override") var position_options: String = "center";
var initial_position: Vector2;

@export var store_position: bool = false;
@export var override_position: Vector2;
@export var override_size: Vector2;
@export var return_on_close: bool = true;
@export var topbar_height: int = 50;

signal close_requested();
signal change_title(name: String);

var dragging := false
var stored_position:Vector2;

func _ready() -> void:
	close_button.pressed.connect(close_window);
	close_requested.connect(close_window)
	top_bar.gui_input.connect(handle_input)
	change_title.connect(_change_title)
	
	if override_size != Vector2.ZERO:
		self.set_deferred("size", override_size)
	
func on_enable(_options: Dictionary = {}) -> void:
	if visible:
		return
	visible = true;
		
	match display_mode:
		"fullscreen":
			top_bar.visible = false;
			size = get_viewport_rect().size;
		"display":
			top_bar.visible = true;
			pass
		"no_header":
			top_bar.visible = false;
			pass
	
	match position_options:
		"mouse":
			initial_position = get_tree().root.get_viewport().get_mouse_position();
		"center":
			initial_position = get_viewport_rect().size / 2
		"override":
			initial_position = override_position;
	position = initial_position - size / 2;
	
	if store_position:
		position = stored_position;

func _change_title(s: String) -> void:
	title.text = s;

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		dragging = event.pressed
	elif dragging and event is InputEventMouseMotion:
		position += event.relative
	else:
		return
	vp.set_input_as_handled()

func close_window() -> void:
	if store_position:
		stored_position = position;
	SceneManager.instance.remove_scene(SceneManager.instance.node_to_info(self), false);
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel") && visible:
		vp.set_input_as_handled()
		close_requested.emit()
