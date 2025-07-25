class_name SceneManager
extends Node

@export var initial_scene: SceneInfo;
@onready var root: Node = %"Level";
static var instance: SceneManager;

var scene_stack: Array[SceneInfo] = [];
var scene_cache: SceneCache;

@export var _ui_container: Node;

signal scene_entered(scene: Node)
signal scene_exited(scene: Node)

var _active_scene: Node:
	set(new_scene):
		if _active_scene != null:
			scene_exited.emit(_active_scene);
			if _active_scene.has_method("on_disable"):
				_active_scene.on_disable();
		_active_scene = new_scene;
		_active_scene.visible = true;
		scene_entered.emit(_active_scene);

func _init() -> void:
	SceneManager.instance = self;
	scene_cache = SceneCache.new()
		
func _ready() -> void:
	if initial_scene:
		get_or_create_scene(initial_scene.id).queue(
			func(info: SceneInfo) -> void: root.add_child(info.get_instance()))
			
func get_or_create_scene(scene_name: String, scene_config: SceneConfig = SceneConfig.new()) -> SceneInfo:
	var previous_scene_info: SceneInfo = null;
	if _active_scene != null:
		previous_scene_info = node_to_info(_active_scene);
		if previous_scene_info.id == scene_name:
			return null; 
		if scene_config.disable_processing:
			_active_scene.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	
	var filtered: Array = Manager.instance.resource_manager.scenes.filter(func(scene: SceneInfo) -> bool: return scene != null && scene.id == scene_name);
	if filtered.size() == 0:
		Debug.err(scene_name + " was not found, unable to instantiate!")
	elif filtered.size() > 1:
		Debug.err(scene_name + " appeared multiple times!")
	elif filtered.size() == 1:
		var scene_info: SceneInfo = filtered[0];
		if is_instance_valid(scene_info.node):
			_on_scene_load(scene_info, scene_config);
		else:
			if scene_cache.get_from_cache(scene_info) != null:
				_on_scene_load(scene_info, scene_config);
			else:
				if !scene_info.cached.is_connected(_on_scene_load.bind(scene_config)):
					scene_info.cached.connect(_on_scene_load.bind(scene_config))
				scene_cache.queue(scene_info);
		return scene_info;
	else:
		Debug.err(scene_name + " was invalid. Found more than one resource referencing the scene.")
	return null;
		
func _on_scene_load(scene_info: SceneInfo, scene_config: SceneConfig) -> void:
	_active_scene = scene_info.get_instance();
	_active_scene.visible = true;
	if scene_config.add_to_stack:
		scene_stack.append(scene_info)
			
func node_to_info(node: Node) -> SceneInfo:
	var filtered: Array[SceneInfo] = Manager.instance.resource_manager.scenes.filter(func(x: SceneInfo) -> bool: return x.node == node);
	if filtered.size() == 1:
		return filtered[0];
	Debug.err("Could not find " + node.name + " in scenes.")
	return null
	
func get_scene_info(id: String) -> SceneInfo:
	var filtered: Array[SceneInfo] = Manager.instance.resource_manager.scenes.filter(func(x: SceneInfo) -> bool: return x.id == id);
	if filtered.size() == 1:
		return filtered[0];
	Debug.err("Could not find " + id + " in scenes.")
	return null;

func set_scene_reference(id: String, target: Node) -> void:
	get_scene_info(id).node = target;
	
func reset_to_scene(scene_name: String) -> void:
	for scene_info in Manager.instance.resource_manager.scenes:
		if scene_info.id != scene_name && scene_info.node != null:
			scene_info.node.queue_free()
	get_or_create_scene(scene_name, SceneConfig.new())
	
func remove_scene(info: SceneInfo, permanent: bool = false) -> void:
	if info.node != null:
		scene_stack.erase(info);
		if permanent:
			info.release();
		else:
			info.remove();
	else:
		Debug.message("Could not remove scene %s because it was never loaded" % info.id);
	
func to_previous_scene() -> void:
	if scene_stack.size() != 0:
		scene_stack.pop_back();
		if scene_stack.size() != 0:
			get_or_create_scene(scene_stack[scene_stack.size() - 1].id, SceneConfig.new(false, false));
		
func ui_is_open(exceptions: Array[String]) -> bool:
	return get_children().all(func(x: Node) -> bool: return node_to_info(x).type == SceneInfo.Type.UI && x.visible && !exceptions.has(node_to_info(x).id));
			
func is_active(scene_name: String) -> bool:
	for scene_info in Manager.instance.resource_manager.scenes:
		if scene_info.id != scene_name && scene_info.node != null && scene_info.node.visible == true:
			return true;
	return false;
	
func add(n: SceneInfo) -> bool:
	if n.type == SceneInfo.Type.UI && not n.get_instance().get_parent() == _ui_container:
		_ui_container.add_child(n.get_instance());
		return true;
	return false;
