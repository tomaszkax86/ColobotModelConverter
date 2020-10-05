class_name Formats

static func read_model(path : String) -> ColobotModel:
	if path.ends_with(".mod"):
		return MODFormat.read(path)
	elif path.ends_with(".gltf"):
		return GLTFFormat.read(path)
	elif path.ends_with(".txt"):
		return TXTFormat.read(path)
	else:
		return null

static func write_model(path : String, model : ColobotModel):
	if path.ends_with(".mod"):
		MODFormat.write(path, model)
	elif path.ends_with(".gltf"):
		GLTFFormat.write(path, model)
	elif path.ends_with(".txt"):
		TXTFormat.write(path, model)
