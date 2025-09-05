extends Node

var _skill_map: Dictionary
var skill_map: Dictionary:
	get:
		return _skill_map

func _init() -> void:
	_skill_map = CSVLoad.load_csv_skill_list_file()
	pass

func get_csv_data(path: String) -> Dictionary:
	var data = CSVLoad.load_csv_file(path)
	print("FileManager get_csv_data ->" + JSON.stringify(data, "\t"))
	return data
