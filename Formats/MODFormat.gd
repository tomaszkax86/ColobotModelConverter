class_name MODFormat

### .mod format ###
static func read(path : String) -> ColobotModel:
	var input = File.new()
	input.open(path, File.READ)
	
	var _version = input.get_32()
	var _revision = input.get_32()
	var triangle_count = input.get_32()
	
	for _i in range(10):
		input.get_32()
	
	var mesh = ColobotModel.new()
	
	for _i in range(triangle_count):
		var triangle = _read_mod_triangle(input)
		
		if triangle.material.lod_min > 0: continue
		
		mesh.triangles.append(triangle)
	
	input.close()
	
	return mesh

static func write(path : String, mesh : ColobotModel):
	var output = File.new()
	output.open(path, File.WRITE)
	
	output.store_32(1)
	output.store_32(2)
	output.store_32(mesh.triangles.size())
	
	for _i in range(10):
		output.store_32(0)
	
	for triangle in mesh.triangles:
		_write_mod_triangle(output, triangle)
	
	output.close()

static func _read_mod_triangle(input : File) -> ColobotModel.Triangle:
	var triangle = ColobotModel.Triangle.new()
	
	var _used = input.get_8()
	var _selected = input.get_8()
	var _padding = input.get_16()
	
	triangle.v1 = _read_mod_vertex(input)
	triangle.v2 = _read_mod_vertex(input)
	triangle.v3 = _read_mod_vertex(input)
	
	triangle.material = _read_mod_material(input)
	
	var _pad1 = input.get_16()
	var _pad2 = input.get_16()
	var _pad3 = input.get_16()
	
	return triangle

static func _write_mod_triangle(output : File, triangle : ColobotModel.Triangle):
	output.store_8(1)
	output.store_8(0)
	output.store_16(0)
	
	_write_mod_vertex(output, triangle.v1)
	_write_mod_vertex(output, triangle.v2)
	_write_mod_vertex(output, triangle.v3)
	
	_write_mod_material(output, triangle.material)
	
	output.store_16(0)
	output.store_16(0)
	output.store_16(0)

static func _read_mod_material(input : File) -> ColobotModel.CMaterial:
	var material = ColobotModel.CMaterial.new()
	
	material.diffuse = _read_mod_color(input)
	material.ambient = _read_mod_color(input)
	material.specular = _read_mod_color(input)
	material.emission = _read_mod_color(input)
	material.power = input.get_float()
	
	material.texture = input.get_buffer(20).get_string_from_ascii().strip_edges()
	#material.texture = material.texture.replace(".bmp", ".png").replace(".tga", ".png")
	material.lod_min = input.get_float()
	material.lod_max = input.get_float()
	material.state = input.get_32()
	material.dirt = input.get_16()
	
	return material

static func _write_mod_material(output : File, material : ColobotModel.CMaterial):
	_write_mod_color(output, material.diffuse)
	_write_mod_color(output, material.ambient)
	_write_mod_color(output, material.specular)
	_write_mod_color(output, material.emission)
	output.store_float(material.power)
	
	var texname = material.texture.to_ascii()
	var length = texname.size()
	
	texname.resize(20)
	
	for i in range(length, 20):
		texname.set(i, 0)
	
	output.store_buffer(texname)
	output.store_float(material.lod_min)
	output.store_float(material.lod_max)
	output.store_32(material.state)
	output.store_16(material.dirt)

static func _read_mod_vertex(input : File) -> ColobotModel.Vertex:
	var vertex = ColobotModel.Vertex.new()
	
	var x = input.get_float()
	var y = input.get_float()
	var z = -input.get_float()
	
	var nx = input.get_float()
	var ny = input.get_float()
	var nz = -input.get_float()
	
	var u1 = input.get_float()
	var v1 = input.get_float()
	
	var u2 = input.get_float()
	var v2 = input.get_float()
	
	vertex.position = Vector3(x, y, z)
	vertex.normal = Vector3(nx, ny, nz)
	vertex.uv1 = Vector2(u1, v1)
	vertex.uv2 = Vector2(u2, v2)
	
	return vertex

static func _write_mod_vertex(output : File, vertex : ColobotModel.Vertex):
	output.store_float(vertex.position.x)
	output.store_float(vertex.position.y)
	output.store_float(-vertex.position.z)
	
	output.store_float(vertex.normal.x)
	output.store_float(vertex.normal.y)
	output.store_float(-vertex.normal.z)
	
	output.store_float(vertex.uv1.x)
	output.store_float(vertex.uv1.y)
	
	output.store_float(vertex.uv2.x)
	output.store_float(vertex.uv2.y)

static func _read_mod_color(input : File) -> Color:
	var r = input.get_float()
	var g = input.get_float()
	var b = input.get_float()
	var a = input.get_float()
	
	return Color(r, g, b, a)

static func _write_mod_color(output : File, color : Color):
	output.store_float(color.r)
	output.store_float(color.g)
	output.store_float(color.b)
	output.store_float(color.a)
