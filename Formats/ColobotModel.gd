class_name ColobotModel

const NORMAL = 0
const BLACK_TO_ALPHA = 1
const WHITE_TO_ALPHA = 2
const PART_1 = 256
const PART_2 = 512
const PART_3 = 1024
const TWO_FACE = 4096
const USE_ALPHA = 8192

class Vertex:
	var position : Vector3
	var normal : Vector3
	var uv1 : Vector2
	var uv2 : Vector2
	
	func equals(other : Vertex) -> bool:
		if position.distance_to(other.position) > 1e-3: return false
		if normal.distance_to(other.normal) > 1e-3: return false
		if uv1.distance_to(other.uv1) > 1e-3: return false
		if uv2.distance_to(other.uv2) > 1e-3: return false
		return true

class CMaterial:
	var diffuse : Color
	var ambient : Color
	var specular : Color
	var emission : Color
	var power : float
	var state : int
	var texture : String
	var lod_min : float
	var lod_max : float
	var dirt : int
	
	func equals(other : CMaterial) -> bool:
		if diffuse != other.diffuse: return false
		if ambient != other.ambient: return false
		if specular != other.specular: return false
		if emission != other.emission: return false
		if state != other.state: return false
		if texture != other.texture: return false
		if dirt != other.dirt: return false;
		return true

class Triangle:
	var material : CMaterial
	var v1 : Vertex
	var v2 : Vertex
	var v3 : Vertex
	var index : int

var triangles = []
