extends Node

var _textures = {}

func load_texture(name : String) -> Texture:
	if _textures.has(name):
		return _textures[name]
	
	var image = Image.new()
	image.load(Config.colobot_data_directory + "/textures/" + name)
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	_textures[name] = texture
	
	return texture

func clear_cache():
	_textures.clear()
