extends Node

func get_csv_data(path: String) -> Dictionary:
	var data = CSVLoad.load_csv_file(path)
	print("FileManager get_csv_data ->" + JSON.stringify(data, "\t"))
	return data
