extends Node

func execute(_options: Dictionary = {}) -> bool:
	Manager.instance.player.on_attack_start();
	return true;
