class_name GLTFFormat

# .glTF 2.0 format
static func read(path : String) -> ColobotModel:
	var filename = path.substr(path.find_last("/") + 1)
	var _model_name = filename.replace(".gltf", "")
	var directory = path.substr(0, path.find_last("/") + 1)
	
	var model_file = File.new()
	model_file.open(path, File.READ)
	var content = model_file.get_as_text()
	model_file.close()
	
	var parsed = JSON.parse(content)
	
	if parsed.error != OK:
		print(parsed.error_string)
	
	var root = parsed.result
	
	var materials = []
	
	for i in range(root.materials.size()):
		materials.append(_parse_gltf_material(root, i))
	
	var mesh = root.meshes[0]
	
	var data_file = File.new()
	data_file.open(directory + root.buffers[0].uri, File.READ)
	
	var cmesh = ColobotModel.new()
	
	for primitive in mesh.primitives:
		var vertex_accessor = root.accessors[ primitive.attributes["POSITION"] ]
		var vertex_buffer = root.bufferViews[ vertex_accessor.bufferView ]
		var vertex_data = _read_buffer(data_file, vertex_buffer.byteOffset, vertex_accessor.count, vertex_accessor.type, vertex_accessor.componentType)
		
		var normal_accessor = root.accessors[ primitive.attributes["NORMAL"] ]
		var normal_buffer = root.bufferViews[ normal_accessor.bufferView ]
		var normal_data = _read_buffer(data_file, normal_buffer.byteOffset, normal_accessor.count, normal_accessor.type, normal_accessor.componentType)
		
		var uv1_accessor = root.accessors[ primitive.attributes["TEXCOORD_0"] ]
		var uv1_buffer = root.bufferViews[ uv1_accessor.bufferView ]
		var uv1_data = _read_buffer(data_file, uv1_buffer.byteOffset, uv1_accessor.count, uv1_accessor.type, uv1_accessor.componentType)
		
		var uv2_accessor = null
		var uv2_buffer = null
		var uv2_data = null
		
		if primitive.attributes.has("TEXCOORD_1"):
			uv2_accessor = root.accessors[ primitive.attributes["TEXCOORD_1"] ]
			uv2_buffer = root.bufferViews[ uv2_accessor.bufferView ]
			uv2_data = _read_buffer(data_file, uv2_buffer.byteOffset, uv2_accessor.count, uv2_accessor.type, uv2_accessor.componentType)
			
		var index_accessor = root.accessors[ primitive.indices ]
		
		var index_buffer = root.bufferViews[ index_accessor.bufferView ]
		
		var index_data = _read_buffer(data_file, index_buffer.byteOffset, index_accessor.count, index_accessor.type, index_accessor.componentType)
		
		var material = _parse_gltf_material(root, primitive.material)
		
		var count = index_accessor.count
		
		for i in range(0, count, 3):
			var v1 = index_data[i + 2]
			var v2 = index_data[i + 1]
			var v3 = index_data[i + 0]
			
			var triangle = ColobotModel.Triangle.new()
			
			triangle.v1 = ColobotModel.Vertex.new()
			triangle.v2 = ColobotModel.Vertex.new()
			triangle.v3 = ColobotModel.Vertex.new()
			
			triangle.v1.position = vertex_data[v1]
			triangle.v2.position = vertex_data[v2]
			triangle.v3.position = vertex_data[v3]
			
			triangle.v1.normal = normal_data[v1]
			triangle.v2.normal = normal_data[v2]
			triangle.v3.normal = normal_data[v3]
			
			triangle.v1.uv1 = uv1_data[v1]
			triangle.v2.uv1 = uv1_data[v2]
			triangle.v3.uv1 = uv1_data[v3]
			
			if uv2_accessor:
				triangle.v1.uv2 = uv2_data[v1]
				triangle.v2.uv2 = uv2_data[v2]
				triangle.v3.uv2 = uv2_data[v3]
			else:
				triangle.v1.uv2 = Vector2()
				triangle.v2.uv2 = Vector2()
				triangle.v3.uv2 = Vector2()
			
			triangle.material = material
			
			cmesh.triangles.append(triangle)
	
	data_file.close()
	
	return cmesh

static func write(path : String, mesh : ColobotModel):
	var filename = path.substr(path.find_last("/") + 1)
	var model_name = filename.replace(".gltf", "")
	var data_path = path.replace(".gltf", ".bin")
	var data_name = filename.replace(".gltf", ".bin")
	
	var root = {}
	
	var asset = {}
	asset.generator = "Colobot Model Converter v0.1"
	asset.version = "2.0"
	root.asset = asset
	
	root.scene = 0
	
	var scene = {}
	scene.name = "Scene"
	scene.nodes = [ 0 ]
	root.scenes = [ scene ]
	
	var node = {}
	node.mesh = 0
	node.name = model_name
	root.nodes = [ node ]
	
	var mesh_node = {}
	mesh_node.name = model_name
	mesh_node.primitives = []
	root.materials = []
	root.meshes = []
	root.textures = []
	root.images = []
	root.accessors = []
	root.bufferViews = []
	root.buffers = []
	
	var data_file = File.new()
	data_file.open(data_path, File.WRITE)
	
	# congregate materials
	var materials : Array = []
	
	for triangle in mesh.triangles:
		var index = -1
		
		for i in range(materials.size()):
			if triangle.material.equals(materials[i]):
				index = i
				break
		
		if index == -1:
			triangle.index = materials.size()
			materials.append(triangle.material)
		else:
			triangle.index = index
	
	# calculate bounding box
	var min_position = Vector3(mesh.triangles[0].v1.position)
	var max_position = Vector3(mesh.triangles[0].v1.position)
	
	for triangle in mesh.triangles:
		var positions = [ triangle.v1.position, triangle.v2.position, triangle.v3.position ]
		
		for p in positions:
			if min_position.x > p.x: min_position.x = p.x
			if min_position.y > p.y: min_position.y = p.y
			if min_position.z > p.z: min_position.z = p.z
			
			if max_position.x < p.x: max_position.x = p.x
			if max_position.y < p.y: max_position.y = p.y
			if max_position.z < p.z: max_position.z = p.z
	
	var minp = [ min_position.x, min_position.y, min_position.z ]
	var maxp = [ max_position.x, max_position.y, max_position.z ]
	
	# iterate over materials
	for i in range(materials.size()):
		var material : ColobotModel.CMaterial = materials[i]
		
		var mat_node = {}
		
		mat_node.name = "Material " + str(i + 1)
		mat_node.pbrMetallicRoughness = {}
		mat_node.pbrMetallicRoughness.baseColorFactor = [ material.diffuse.r, material.diffuse.g, material.diffuse.b, 1.0 ]
		mat_node.pbrMetallicRoughness.metallicFactor = 0.0
		mat_node.pbrMetallicRoughness.roughnessFactor = 1.0
		
		var vertex_buffer : PoolVector3Array = PoolVector3Array()
		var normal_buffer : PoolVector3Array = PoolVector3Array()
		var uv1_buffer : PoolVector2Array = PoolVector2Array()
		var uv2_buffer : PoolVector2Array = PoolVector2Array()
		var index_buffer : PoolIntArray = PoolIntArray()
		
		var extras = {}
		
		extras.dirt = material.dirt
		
		if not material.texture.empty():
			mat_node.name = "Material " + str(i + 1) + " (" + material.texture + ")"
			
			var img_index = -1
			
			for index in range(root.images.size()):
				var img = root.images[index]
				
				if img.uri == material.texture:
					img_index = index
					break
			
			if img_index == -1:
				img_index = root.images.size()
				
				var image = {}
				image.uri = material.texture
				root.images.append(image)
			
			var tex_index = root.textures.size()
			
			var texture = {}
			texture.source = img_index
			root.textures.append(texture)
			
			mat_node.pbrMetallicRoughness.baseColorTexture = {}
			mat_node.pbrMetallicRoughness.baseColorTexture.index = tex_index
			mat_node.pbrMetallicRoughness.baseColorTexture.texCoord = 0
		
		if material.state & ColobotModel.TWO_FACE:
			mat_node.doubleSided = true
		
		if material.state & ColobotModel.USE_ALPHA:
			extras.transparency = 1
		elif material.state & ColobotModel.WHITE_TO_ALPHA:
			extras.transparency = 2
		elif material.state & ColobotModel.BLACK_TO_ALPHA:
			extras.transparency = 3
		
		if material.state & ColobotModel.PART_1:
			extras.tracker_1 = 1
		
		if material.state & ColobotModel.PART_2:
			extras.tracker_2 = 1
		
		if material.state & ColobotModel.PART_3:
			extras.energy = 1
		
		if extras.size() > 0:
			mat_node.extras = extras
		
		var added_vertices = []
		
		# iterate over triangles and copy the ones that match current material
		for triangle in mesh.triangles:
			if triangle.index != i: continue
			
			# vertex 3
			var ind = _find_vertex(added_vertices, triangle.v3)
			
			if ind == -1:
				ind = vertex_buffer.size()
				
				vertex_buffer.append(triangle.v3.position)
				normal_buffer.append(triangle.v3.normal)
				uv1_buffer.append(triangle.v3.uv1)
				uv2_buffer.append(triangle.v3.uv2)
				
				added_vertices.append(triangle.v3)
			
			index_buffer.append(ind)
			
			# vertex 2
			ind = _find_vertex(added_vertices, triangle.v2)
			
			if ind == -1:
				ind = vertex_buffer.size()
				
				vertex_buffer.append(triangle.v2.position)
				normal_buffer.append(triangle.v2.normal)
				uv1_buffer.append(triangle.v2.uv1)
				uv2_buffer.append(triangle.v2.uv2)
				
				added_vertices.append(triangle.v2)
			
			index_buffer.append(ind)
			
			#vertex 1
			ind = _find_vertex(added_vertices, triangle.v1)
			
			if ind == -1:
				ind = vertex_buffer.size()
				
				vertex_buffer.append(triangle.v1.position)
				normal_buffer.append(triangle.v1.normal)
				uv1_buffer.append(triangle.v1.uv1)
				uv2_buffer.append(triangle.v1.uv2)
				
				added_vertices.append(triangle.v1)
			
			index_buffer.append(ind)
		
		_write_alignment_padding(data_file, 3 * 4)
		
		# writing buffers to the data buffer
		var vertex_offset = data_file.get_position()
		var vertex_length = vertex_buffer.size() * 3 * 4
		
		for v in vertex_buffer:
			data_file.store_float(v.x)
			data_file.store_float(v.y)
			data_file.store_float(v.z)
		
		var normal_offset = data_file.get_position()
		var normal_length = normal_buffer.size() * 3 * 4
		
		for v in normal_buffer:
			data_file.store_float(v.x)
			data_file.store_float(v.y)
			data_file.store_float(v.z)
		
		_write_alignment_padding(data_file, 2 * 4)
		
		var uv1_offset = data_file.get_position()
		var uv1_length = uv1_buffer.size() * 2 * 4
		
		for v in uv1_buffer:
			data_file.store_float(v.x)
			data_file.store_float(v.y)
		
		var uv2_offset = data_file.get_position()
		var uv2_length = uv2_buffer.size() * 2 * 4
		
		for v in uv2_buffer:
			data_file.store_float(v.x)
			data_file.store_float(v.y)
		
		var index_offset = data_file.get_position()
		var index_length = index_buffer.size() * 2
		
		for v in index_buffer:
			data_file.store_16(v)
		
		var primitive = {}
		
		var index = root.accessors.size()
		
		var attributes = {}
		attributes.POSITION = index
		attributes.NORMAL = index + 1
		attributes.TEXCOORD_0 = index + 2
		attributes.TEXCOORD_1 = index + 3
		primitive.attributes = attributes
		
		primitive.indices = index + 4
		primitive.material = i
		
		mesh_node.primitives.append(primitive)
		
		root.bufferViews.append({ "buffer": 0, "byteLength": vertex_length, "byteOffset": vertex_offset })
		root.bufferViews.append({ "buffer": 0, "byteLength": normal_length, "byteOffset": normal_offset })
		root.bufferViews.append({ "buffer": 0, "byteLength": uv1_length, "byteOffset": uv1_offset })
		root.bufferViews.append({ "buffer": 0, "byteLength": uv2_length, "byteOffset": uv2_offset })
		root.bufferViews.append({ "buffer": 0, "byteLength": index_length, "byteOffset": index_offset })
		
		root.accessors.append({ "bufferView": index + 0, "componentType" : 5126, "type" : "VEC3", "count" : vertex_buffer.size(), "min" : minp, "max": maxp })
		root.accessors.append({ "bufferView": index + 1, "componentType" : 5126, "type" : "VEC3", "count" : normal_buffer.size() })
		root.accessors.append({ "bufferView": index + 2, "componentType" : 5126, "type" : "VEC2", "count" : uv1_buffer.size() })
		root.accessors.append({ "bufferView": index + 3, "componentType" : 5126, "type" : "VEC2", "count" : uv2_buffer.size() })
		root.accessors.append({ "bufferView": index + 4, "componentType" : 5123, "type" : "SCALAR", "count" : index_buffer.size() })
		
		root.materials.append(mat_node)
	
	root.meshes = [ mesh_node ]
	
	var buffer = {}
	buffer.byteLength = data_file.get_position()
	buffer.uri = data_name
	root.buffers.append(buffer)
	
	data_file.close()
	
	var model_file = File.new()
	model_file.open(path, File.WRITE)
	var text = JSON.print(root, "    ")
	model_file.store_string(text)
	model_file.close()

static func _find_vertex(added_vertices, vertex) -> int:
	for i in range(added_vertices.size()):
		var v = added_vertices[i]
		if vertex.equals(v):
			return i
	return -1

static func _parse_gltf_material(root, index) -> ColobotModel.CMaterial:
	var material = ColobotModel.CMaterial.new()
	
	# set defaults
	material.diffuse = Color(1.0, 1.0, 1.0, 0.0)
	material.specular = Color(0.0, 0.0, 0.0, 0.0)
	material.ambient = Color(0.5, 0.5, 0.5, 0.0)
	material.emission = Color(0.0, 0.0, 0.0, 0.0)
	material.power = 1.0
	material.lod_min = 0.0
	material.lod_max = 1000000.0
	material.dirt = 1
	material.texture = ""
	
	var node = root.materials[index]
	
	if node.has("extras"):
		if node.extras.has("doubleSided"):
			material.state |= ColobotModel.TWO_FACE
		
		if node.extras.has("transparency"):
			if node.extras.transparency == 1:
				material.state |= ColobotModel.USE_ALPHA
			if node.extras.transparency == 2:
				material.state |= ColobotModel.WHITE_TO_ALPHA
			if node.extras.transparency == 3:
				material.state |= ColobotModel.BLACK_TO_ALPHA
		
		if node.extras.has("tracker_1"):
			material.state |= ColobotModel.PART_1
		
		if node.extras.has("tracker_2"):
			material.state |= ColobotModel.PART_2
		
		if node.extras.has("energy"):
			material.state |= ColobotModel.PART_3
		
		if node.extras.has("dirt"):
			material.dirt = node.extras.dirt
	
	if node.pbrMetallicRoughness.has("baseColorFactor"):
		var diffuse = node.pbrMetallicRoughness.baseColorFactor
		
		material.diffuse = Color(diffuse[0], diffuse[1], diffuse[2], 0.0)
	
	if node.pbrMetallicRoughness.has("baseColorTexture"):
		var texture_index = node.pbrMetallicRoughness.baseColorTexture.index
		
		var image_index = root.textures[texture_index].source
		
		var image_name = root.images[image_index].uri
		
		material.texture = image_name
	
	return material

static func _read_buffer(file : File, offset : int, count : int, type : String, component : int):
	file.seek(offset)
	
	var buffer = []
	
	for _i in range(count):
		buffer.append(_read_component(file, type, component))
	
	return buffer

static func _read_component(file : File, type : String, component : int):
	match type:
		"SCALAR":
			return _read_value(file, component)
		"VEC2":
			var x = _read_value(file, component)
			var y = _read_value(file, component)
			return Vector2(x, y)
		"VEC3":
			var x = _read_value(file, component)
			var y = _read_value(file, component)
			var z = _read_value(file, component)
			return Vector3(x, y, z)
	
	return null

static func _read_value(file : File, component : int):
	match component:
		5123:
			return file.get_16()
		5125:
			return file.get_32()
		5126:
			return file.get_float()
	
	return null

static func _write_alignment_padding(file : File, alignment : int):
	var pos = file.get_position() % alignment
	
	if pos == 0: return
	
	var missing = alignment - pos
	
	for _i in range(missing):
		file.store_8(0)
