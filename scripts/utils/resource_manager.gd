class_name ResourceManager extends Node

@export var creatures: Array[CreatureResource];
@export var items: Array[ItemResource];

@export var packed_donors: Dictionary[String, PackedScene];
var donors: Dictionary[String, Node3D];
		
func get_creature(creature_name: String) -> CreatureResource:
	var valid_creatures := creatures.filter(func(x: CreatureResource) -> bool: return x.unique_id == creature_name);
	if valid_creatures.size() == 1:
		return valid_creatures[0];
	else:
		return null;
		
func get_item(key: String) -> ItemResource:
	var valid_items := items.filter(func(x: ItemResource) -> bool: return x.unique_id == key);
	if valid_items.size() == 1:
		return valid_items[0];
	else:
		Debug.message("No item was found with key: %s" % key)
		return null;

func get_donor(donor_name: String) -> Node3D:
	if donors.has(donor_name):
		return donors[donor_name];
	elif packed_donors.has(donor_name):
		donors.set(donor_name, packed_donors[donor_name].instantiate())
		return donors[donor_name];
	Debug.err("%s was not found on BodyPartManager" % donor_name)
	return null;
