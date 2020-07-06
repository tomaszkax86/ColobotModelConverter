extends Node

var colobot_data_directory = "" setget set_colobot_data_directory

var _config_file = "user://config.json"

func set_colobot_data_directory(v):
	colobot_data_directory = v
	TextureLoader.clear_cache()

func _ready():
	var file = File.new()
	var err = file.open(_config_file, File.READ)
	
	if err == OK:
		var content = file.get_as_text()
		file.close()
		
		var config = JSON.parse(content).result
		
		colobot_data_directory = config.colobotDataDirectory

func _exit_tree():
	var file = File.new()
	var err = file.open(_config_file, File.WRITE)
	
	if err == OK:
		var config = {}
		config.colobotDataDirectory = colobot_data_directory
		
		var content = JSON.print(config, "    ")
		
		file.store_string(content)
		file.close()
