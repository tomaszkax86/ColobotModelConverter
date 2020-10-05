class_name TXTFormat

### .txt format ###
static func read(path : String) -> ColobotModel:
	var input = File.new()
	input.open(path, File.READ)

	var _version = _read_version(input)
	var _revision = 0
	var triangle_count = _read_triangle_count(input)

	var mesh = ColobotModel.new()

	for _i in range(triangle_count):
		var triangle = _read_txt_triangle(input)

		if triangle.material.lod_min > 0: continue

		mesh.triangles.append(triangle)

	input.close()

	return mesh

static func write(path : String, mesh : ColobotModel):
	var output = File.new()
	output.open(path, File.WRITE)

	output.store_line("# Colobot text model")
	output.store_line("")
	output.store_line("### HEAD")
	output.store_line("version 2")
	output.store_line("total_triangles " + String(mesh.triangles.size()))
	output.store_line("")
	output.store_line("### TRIANGLES")

	for triangle in mesh.triangles:
		_write_txt_triangle(output, triangle)

	output.close()

static func _read_line(input : File):
	while not input.eof_reached():
		var line = input.get_line().strip_edges()

		if line == "": continue
		if line[0] == "#": continue

		return line.split(" ")

	return null

static func _read_version(input : File) -> int:
	var line = _read_line(input)

	return line[1].to_int()

static func _read_triangle_count(input : File) -> int:
	var line = _read_line(input)

	return line[1].to_int()

static func _read_txt_triangle(input : File) -> ColobotModel.Triangle:
	var triangle = ColobotModel.Triangle.new()

	triangle.v1 = _read_txt_vertex(input)
	triangle.v2 = _read_txt_vertex(input)
	triangle.v3 = _read_txt_vertex(input)

	triangle.material = _read_txt_material(input)

	return triangle

static func _write_txt_triangle(output : File, triangle : ColobotModel.Triangle):
	_write_txt_vertex(output, triangle.v1, 1)
	_write_txt_vertex(output, triangle.v2, 2)
	_write_txt_vertex(output, triangle.v3, 3)

	_write_txt_material(output, triangle.material)

	output.store_line("")

static func _read_txt_material(input : File) -> ColobotModel.CMaterial:
	var material = ColobotModel.CMaterial.new()

	var mat = _read_line(input)
	var tex1 = _read_line(input)
	var tex2 = _read_line(input)
	var tex_var = _read_line(input)
	var state = _read_line(input)

	material.diffuse = Color(mat[2].to_float(), mat[3].to_float(), mat[4].to_float(), mat[5].to_float())
	material.ambient = Color(mat[7].to_float(), mat[8].to_float(), mat[9].to_float(), mat[10].to_float())
	material.specular = Color(mat[12].to_float(), mat[13].to_float(), mat[14].to_float(), mat[15].to_float())
	material.emission = Color(0, 0, 0)
	material.power = 1.0

	material.texture = tex1[1]
	#material.texture = material.texture.replace(".bmp", ".png").replace(".tga", ".png")
	material.lod_min = 0
	material.lod_max = 1000
	material.state = state[1].to_int()

	if tex_var[1] == "Y":
		material.dirt = 1
	elif tex2.size() > 1:
		material.dirt = tex2[1].substr(5, 2).to_int()
	else:
		material.dirt = 0

	return material

static func _write_txt_material(output : File, material : ColobotModel.CMaterial):
	var mat = PoolStringArray()
	mat.append("mat")
	mat.append("dif")
	mat.append(String(material.diffuse.r))
	mat.append(String(material.diffuse.g))
	mat.append(String(material.diffuse.b))
	mat.append(String(material.diffuse.a))
	mat.append("amb")
	mat.append(String(material.ambient.r))
	mat.append(String(material.ambient.g))
	mat.append(String(material.ambient.b))
	mat.append(String(material.ambient.a))
	mat.append("spc")
	mat.append(String(material.specular.r))
	mat.append(String(material.specular.g))
	mat.append(String(material.specular.b))
	mat.append(String(material.specular.a))

	var dirt = ("dirty0%d.png" % material.dirt) if material.dirt > 1 else ""

	output.store_line(mat.join(" "))
	output.store_line("tex1 " + material.texture)
	output.store_line("tex2 " + dirt)
	output.store_line("var_tex2 " + ("Y" if material.dirt == 1 else "N"))
	output.store_line("state " + String(material.state))

static func _read_txt_vertex(input : File) -> ColobotModel.Vertex:
	var vertex = ColobotModel.Vertex.new()

	var line = _read_line(input)

	var x = line[2].to_float()
	var y = line[3].to_float()
	var z = -line[4].to_float()

	var nx = line[6].to_float()
	var ny = line[7].to_float()
	var nz = -line[8].to_float()

	var u1 = line[10].to_float()
	var v1 = line[11].to_float()

	var u2 = line[13].to_float()
	var v2 = line[14].to_float()

	vertex.position = Vector3(x, y, z)
	vertex.normal = Vector3(nx, ny, nz)
	vertex.uv1 = Vector2(u1, v1)
	vertex.uv2 = Vector2(u2, v2)

	return vertex

static func _write_txt_vertex(output : File, vertex : ColobotModel.Vertex, index : int):
	var elements = PoolStringArray()

	elements.append("p%d" % index)

	elements.append("c")
	elements.append(String(vertex.position.x))
	elements.append(String(vertex.position.y))
	elements.append(String(vertex.position.z))

	elements.append("n")
	elements.append(String(vertex.normal.x))
	elements.append(String(vertex.normal.y))
	elements.append(String(vertex.normal.z))

	elements.append("t1")
	elements.append(String(vertex.uv2.x))
	elements.append(String(vertex.uv2.y))

	elements.append("t2")
	elements.append(String(vertex.uv1.x))
	elements.append(String(vertex.uv1.y))

	output.store_line(elements.join(" "))
