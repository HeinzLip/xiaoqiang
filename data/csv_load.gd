class_name CSVLoad

static func load_csv_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)

	var result = {}
	var line_index = 0
	var first_line: PackedStringArray
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line_index == 0:
			first_line = line.duplicate()
			line_index += 1
			continue
		if line_index == 1:
			line_index += 1
			continue
		var item = {}
		for i in range(first_line.size()):
			item[first_line[i]] = line[i]
		result[line[0]] = item
		line_index += 1
	return result

static func load_csv_skill_list_file() -> Dictionary:
	var file_path = "res://skill_list.csv"
	var result: Dictionary[String, Array] = {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		prints("open file failed")
		return result
	var line_index = 0
	var first_line: PackedStringArray
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line_index == 0:
			first_line = line.duplicate()
			line_index += 1
			continue
		if line_index == 1:
			line_index += 1
			continue
		var item: SkillListItem = SkillListItem.new()
		if not result.has(line[0]):
			result[line[0]] = []
		for i in range(first_line.size()):
			item[first_line[i]] = line[i]
		result[line[0]].append(item)
		line_index += 1
	return result
