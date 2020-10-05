extends MeshInstance

class_name ColobotMeshInstance

export(float, 0.0, 1.0) var energy_level = 1.0 setget set_energy_level
export(float, -10.0, 10.0) var tracker_1_position = 0.0 setget set_tracker_1_position
export(float, -10.0, 10.0) var tracker_2_position = 0.0 setget set_tracker_2_position

var colobot_model : ColobotModel

func set_energy_level(v):
	energy_level = v
	_update_parameters()

func set_tracker_1_position(v):
	tracker_1_position = v
	_update_parameters()

func set_tracker_2_position(v):
	tracker_2_position = v
	_update_parameters()

func load_mod(path : String):
	colobot_model = MODFormat.read(path)
	
	mesh = to_mesh()

func save_mod(path : String):
	MODFormat.write(path, colobot_model)

func load_gltf(path : String):
	colobot_model = GLTFFormat.read(path)
	
	mesh = to_mesh()

func save_gltf(path : String):
	GLTFFormat.write(path, colobot_model)

func load_txt(path : String):
	colobot_model = TXTFormat.read(path)

	mesh = to_mesh()

func save_txt(path : String):
	TXTFormat.write(path, colobot_model)

func _fmod(x, y):
	return x - floor(x / y)

func _update_parameters():
	if not mesh: return
	
	for i in range(mesh.get_surface_count()):
		var material = mesh.surface_get_material(i)
		
		if not material is ShaderMaterial: continue
		
		var mat : ShaderMaterial = material
		
		var track1 = -_fmod(tracker_1_position, 1.0) / 32.0
		var track2 = -_fmod(tracker_2_position, 1.0) / 32.0
		
		mat.set_shader_param("energy_level", energy_level)
		mat.set_shader_param("tracker_1_position", track1)
		mat.set_shader_param("tracker_2_position", track2)

func to_mesh() -> ArrayMesh:
	if colobot_model == null: return null
	
	# congregate materials
	var materials : Array = []
	
	for triangle in colobot_model.triangles:
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
	
	# generate new mesh
	var new_mesh = ArrayMesh.new()
	
	var st = SurfaceTool.new()
	
	# iterate over materials
	for i in range(materials.size()):
		var material : ColobotModel.CMaterial = materials[i]
		
		var dirt = material.dirt
		if dirt < 0: dirt = 0
		
		var tex = material.texture.replace(".bmp", ".png").replace(".tga", ".png")
		
		var _spec = (material.specular.r + material.specular.g + material.specular.b) / 3.0
		
		var mat = ShaderMaterial.new()
		mat.shader = Shader.new()
		
		var file = File.new()
		file.open("res://Shaders/Colobot.txt", File.READ)
		var code = file.get_as_text()
		file.close()
		
		if material.state & ColobotModel.TWO_FACE:
			code = code.replace("cull_back", "cull_disabled")
		
		var transparency = ""
		
		if material.state & ColobotModel.USE_ALPHA:
			transparency = "ALPHA = color.a;"
		elif material.state & ColobotModel.WHITE_TO_ALPHA:
			transparency = "ALPHA = clamp(dot(color.rgb, vec3(1.0)), 0.0, 1.0);"
		elif material.state & ColobotModel.BLACK_TO_ALPHA:
			transparency = "ALPHA = clamp(dot(vec3(1.0) - color.rgb, vec3(1.0)), 0.0, 1.0);"
		
		code = code.replace("{ALPHA_TRANSPARENCY}", transparency)
		
		mat.shader.code = code
		
		var diffuse = material.diffuse
		
		mat.set_shader_param("albedo_color", Color(diffuse.r, diffuse.g, diffuse.b))
		#mat.metallic_specular = spec
		if material.texture != '':
			var tex1 = TextureLoader.load_texture("objects/" + tex)
			mat.set_shader_param("albedo_texture", tex1)
		
		if material.dirt > 0:
			var tex2 = TextureLoader.load_texture("dirty%02d.png" % dirt)
			mat.set_shader_param("dirt_texture", tex2)
		
		if material.state & ColobotModel.PART_1:
			mat.set_shader_param("tracker_1_enabled", true)
		
		if material.state & ColobotModel.PART_2:
			mat.set_shader_param("tracker_2_enabled", true)
		
		if material.state & ColobotModel.PART_3:
			mat.set_shader_param("energy_enabled", true)
		
		st.clear();
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		# iterate over triangles and copy the ones that match current material
		for triangle in colobot_model.triangles:
			if triangle.index != i: continue
			
			st.add_normal(triangle.v1.normal)
			st.add_uv(triangle.v1.uv1)
			st.add_uv2(triangle.v1.uv2)
			st.add_vertex(triangle.v1.position)
			
			st.add_normal(triangle.v2.normal)
			st.add_uv(triangle.v2.uv1)
			st.add_uv2(triangle.v2.uv2)
			st.add_vertex(triangle.v2.position)
			
			st.add_normal(triangle.v3.normal)
			st.add_uv(triangle.v3.uv1)
			st.add_uv2(triangle.v3.uv2)
			st.add_vertex(triangle.v3.position)
		
		var arrays = st.commit_to_arrays()
		
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		new_mesh.surface_set_material(i, mat)
		new_mesh.surface_set_name(i, material.texture)
	
	return new_mesh

func to_wireframe() -> ArrayMesh:
	if colobot_model == null: return null
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	
	var mat = SpatialMaterial.new()
	mat.flags_unshaded = true
	st.set_material(mat)
	
	for triangle in colobot_model.triangles:
		var p1 = triangle.v1.position
		var p2 = triangle.v2.position
		var p3 = triangle.v3.position
		
		st.add_vertex(p1)
		st.add_vertex(p2)
		
		st.add_vertex(p2)
		st.add_vertex(p3)
		
		st.add_vertex(p3)
		st.add_vertex(p1)
	
	return st.commit()

func to_normals() -> ArrayMesh:
	if colobot_model == null: return null
	
	var length = 0.2
	
	var st = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_LINES)
	
	var mat = SpatialMaterial.new()
	mat.flags_unshaded = true
	st.set_material(mat)
	
	for triangle in colobot_model.triangles:
		var p1 = triangle.v1.position
		var p2 = p1 + triangle.v1.normal * length
		
		var p3 = triangle.v2.position
		var p4 = p3 + triangle.v2.normal * length
		
		var p5 = triangle.v3.position
		var p6 = p5 + triangle.v3.normal * length
		
		st.add_vertex(p1)
		st.add_vertex(p2)
		
		st.add_vertex(p3)
		st.add_vertex(p4)
		
		st.add_vertex(p5)
		st.add_vertex(p6)
	
	return st.commit()
