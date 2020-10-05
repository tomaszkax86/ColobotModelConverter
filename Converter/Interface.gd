extends CanvasLayer

onready var _file_dialog = $FileDialog
onready var _directory_dialog = $DirectoryDialog
onready var _view_menu = $MenuBar/HBoxContainer/ViewMenuButton
onready var _material_view = $MaterialView
onready var _material_tree = $MaterialView/Tree
onready var _config_dialog = $ConfigDialog
onready var _options_panel = $OptionsPanel
onready var _texture_directory = $ConfigDialog/GridContainer/HBoxContainer/TextureDirectoryEdit

onready var _convert_dialog = $ConvertDialog
onready var _input_files = $ConvertDialog/VBoxContainer/ItemList
onready var _output_directory = $ConvertDialog/VBoxContainer/HBoxContainer/OutputDirectoryTextEdit
onready var _input_dialog = $ConvertDialog/InputFileDialog
onready var _output_dialog = $ConvertDialog/OutputFileDialog
onready var _format_option = $ConvertDialog/VBoxContainer/HBoxContainer/FormatOptionButton
onready var _convertion_progress = $ConvertDialog/VBoxContainer/HBoxContainer2/ConvertionProgressBar

var _thread = null

func _ready():
	var popup = $MenuBar/HBoxContainer/FileMenuButton.get_popup()
	popup.connect("id_pressed", self, "_on_file_item_pressed")

	popup = $MenuBar/HBoxContainer/ViewMenuButton.get_popup()
	popup.connect("id_pressed", self, "_on_view_item_pressed")

	popup = $MenuBar/HBoxContainer/ConvertMenuButton.get_popup()
	popup.connect("id_pressed", self, "_on_convert_item_pressed")

	_format_option.add_item(".mod")
	_format_option.add_item(".txt")
	_format_option.add_item(".gltf")

func _exit_tree():
	if _thread != null:
		_thread.wait_to_finish()

func _on_FileDialog_file_selected(path):
	if _file_dialog.mode == FileDialog.MODE_OPEN_FILE:
		get_tree().call_group("viewer", "load_model", path)
	if _file_dialog.mode == FileDialog.MODE_SAVE_FILE:
		get_tree().call_group("viewer", "save_model", path)

func _on_SaveConfigButton_pressed():
	Config.colobot_data_directory = _texture_directory.text
	_config_dialog.hide()

func _on_DirectoryButton_pressed():
	_directory_dialog.show()

func _on_file_item_pressed(id):
	if id == 0:
		_file_dialog.mode = FileDialog.MODE_OPEN_FILE
		_file_dialog.show()
	elif id == 1:
		_file_dialog.mode = FileDialog.MODE_SAVE_FILE
		_file_dialog.show()
	elif id == 2:
		get_tree().call_group("viewer", "close_model")
	elif id == 3:
		_texture_directory.text = Config.colobot_data_directory
		_config_dialog.show()
	elif id == 4:
		get_tree().quit()

func _on_view_item_pressed(id):
	if id == 0:
		var status = not _view_menu.get_popup().is_item_checked(id)
		_view_menu.get_popup().set_item_checked(id, status)
		get_tree().call_group("viewer", "set_grid_visible", status)
	if id == 1:
		var status = not _view_menu.get_popup().is_item_checked(id)
		_view_menu.get_popup().set_item_checked(id, status)
		get_tree().call_group("viewer", "set_axes_visible", status)
	if id == 2:
		var status = not _view_menu.get_popup().is_item_checked(id)
		_view_menu.get_popup().set_item_checked(id, status)
		get_tree().call_group("viewer", "set_grass_visible", status)
	if id == 4:
		var status = not _view_menu.get_popup().is_item_checked(id)
		_view_menu.get_popup().set_item_checked(id, status)
		_material_view.visible = status
	if id == 5:
		var status = not _view_menu.get_popup().is_item_checked(id)
		_view_menu.get_popup().set_item_checked(id, status)
		_options_panel.visible = status
	if id == 6:
		var status = not _view_menu.get_popup().is_item_checked(id)
		_view_menu.get_popup().set_item_checked(id, status)
		get_tree().call_group("viewer", "set_model_visible", status)
	if id == 7:
		var status = not _view_menu.get_popup().is_item_checked(id)
		_view_menu.get_popup().set_item_checked(id, status)
		get_tree().call_group("viewer", "set_wireframe_visible", status)
	if id == 8:
		var status = not _view_menu.get_popup().is_item_checked(id)
		_view_menu.get_popup().set_item_checked(id, status)
		get_tree().call_group("viewer", "set_normals_visible", status)

func _on_convert_item_pressed(id):
	if id == 0:
		_convert_dialog.show()

func _on_EnergySlider_value_changed(value):
	get_tree().call_group("viewer", "set_energy_level", value)

func _on_Tracker1Slider_value_changed(value):
	get_tree().call_group("viewer", "set_tracker_1_level", value)

func _on_Tracker2Slider_value_changed(value):
	get_tree().call_group("viewer", "set_tracker_2_level", value)

func set_materials(materials):
	_material_tree.clear()

	var root = _material_tree.create_item()
	_material_tree.set_hide_root(true)

	var index = 1

	for material in materials:
		var material_node = _material_tree.create_item(root)
		material_node.set_text(0, "Material " + str(index))
		material_node.collapsed = true

		if material.texture != "":
			material_node.set_text(0, "Material " + str(index) + " (" + material.texture + ")")
			var texture_node = _material_tree.create_item(material_node)
			texture_node.set_text(0, "Texture: " + material.texture)

		var diffuse_node = _material_tree.create_item(material_node)
		diffuse_node.set_text(0, "Diffuse: " + str(material.diffuse))

		var specular_node = _material_tree.create_item(material_node)
		specular_node.set_text(0, "Specular: " + str(material.specular))

		var ambient_node = _material_tree.create_item(material_node)
		ambient_node.set_text(0, "Ambient: " + str(material.ambient))

		var lod_node = _material_tree.create_item(material_node)
		lod_node.set_text(0, "LOD range: " + str(material.lod_min) + " - " + str(material.lod_max))

		var dirt_node = _material_tree.create_item(material_node)
		dirt_node.set_text(0, "Dirt: " + str(material.dirt))

		var state_node = _material_tree.create_item(material_node)
		state_node.set_text(0, "States")

		if material.state == 0:
			var node = _material_tree.create_item(state_node)
			node.set_text(0, "normal")
		else:
			if material.state & ColobotModel.USE_ALPHA:
				var node = _material_tree.create_item(state_node)
				node.set_text(0, "alpha transparency")
			if material.state & ColobotModel.WHITE_TO_ALPHA:
				var node = _material_tree.create_item(state_node)
				node.set_text(0, "white transparency")
			if material.state & ColobotModel.BLACK_TO_ALPHA:
				var node = _material_tree.create_item(state_node)
				node.set_text(0, "black transparency")
			if material.state & ColobotModel.TWO_FACE:
				var node = _material_tree.create_item(state_node)
				node.set_text(0, "two face")
			if material.state & ColobotModel.PART_1:
				var node = _material_tree.create_item(state_node)
				node.set_text(0, "part 1")
			if material.state & ColobotModel.PART_2:
				var node = _material_tree.create_item(state_node)
				node.set_text(0, "part 2")
			if material.state & ColobotModel.PART_3:
				var node = _material_tree.create_item(state_node)
				node.set_text(0, "energy")

		index = index + 1

func _on_InputFileDialog_files_selected(paths):
	for path in paths:
		_input_files.add_item(path)

func _on_OutputFileDialog_dir_selected(dir):
	_output_directory.text = dir

func _on_SelectInputButton_pressed():
	_input_dialog.show()

func _on_SelectOutputButton_pressed():
	_output_dialog.show()

func _on_ClearListButton_pressed():
	_input_files.clear()

func _on_ConvertButton_pressed():
	if _thread != null:
		_thread.wait_to_finish()

	_thread = Thread.new()
	_thread.start(self, "_process_files")

func _process_files(_nul):
	var count = _input_files.get_item_count()

	var directory = _output_directory.text

	_convertion_progress.visible = true
	_convertion_progress.max_value = count
	_convertion_progress.value = 0

	$ConvertDialog/VBoxContainer/HBoxContainer2/ConvertButton.disabled = true

	for i in range(count):
		var input_file = _input_files.get_item_text(i)

		var ind = input_file.find_last("/") + 1
		var ext = input_file.find_last(".")

		var filename = input_file.substr(ind, ext - ind)

		var output_file = directory + "/" + filename + _format_option.text

		var model = Formats.read_model(input_file)

		Formats.write_model(output_file, model)

		_convertion_progress.value = _convertion_progress.value + 1

		print(output_file)

	_convertion_progress.visible = false

	$ConvertDialog/VBoxContainer/HBoxContainer2/ConvertButton.disabled = false
