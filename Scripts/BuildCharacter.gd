@tool
extends EditorScript

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.albedo_color = color
	return m

func _box(p: Node3D, nm: String, pos: Vector3, sz: Vector3, mat: Material) -> void:
	var b := CSGBox3D.new()
	b.name = nm
	b.use_collision = false
	b.position = pos
	b.size = sz
	b.material_override = mat
	p.add_child(b)
	b.owner = get_scene()

func _cyl(p: Node3D, nm: String, pos: Vector3, rdeg: Vector3, r: float, h: float, mat: Material) -> void:
	var c := CSGCylinder3D.new()
	c.name = nm
	c.use_collision = false
	c.position = pos
	c.rotation_degrees = rdeg
	c.radius = r
	c.height = h
	c.material_override = mat
	p.add_child(c)
	c.owner = get_scene()

func _sph(p: Node3D, nm: String, pos: Vector3, r: float, mat: Material) -> void:
	var s := CSGSphere3D.new()
	s.name = nm
	s.use_collision = false
	s.position = pos
	s.radius = r
	s.material_override = mat
	p.add_child(s)
	s.owner = get_scene()

func _run() -> void:
	var scene := get_scene()
	if not scene:
		push_error("Nenhuma cena aberta!")
		return
	var vp: Node3D = scene.get_node_or_null("Player/VisualPivot")
	if not vp:
		push_error("Player/VisualPivot nao encontrado!")
		return
	for child in vp.get_children():
		child.free()
	print("[BuildCharacter] Montando...")
	var mat_board  := _mat(Color(0.20, 0.48, 0.80))
	var mat_wheels := _mat(Color(0.90, 0.38, 0.10))
	var mat_shoes  := _mat(Color(0.94, 0.92, 0.88))
	var mat_socks  := _mat(Color(0.92, 0.45, 0.18))
	var mat_pants  := _mat(Color(0.58, 0.52, 0.38))
	var mat_shirt  := _mat(Color(0.22, 0.48, 0.82))
	var mat_pack   := _mat(Color(0.85, 0.62, 0.12))
	var mat_skin   := _mat(Color(0.90, 0.70, 0.52))
	var mat_hat    := _mat(Color(0.88, 0.22, 0.10))
	var mat_hair   := _mat(Color(0.45, 0.30, 0.15))
	_box(vp,"Board",    Vector3(0,0.07,0),          Vector3(0.27,0.06,0.95), mat_board)
	_cyl(vp,"WheelFL", Vector3(0.155,0.068,0.34),   Vector3(0,0,90), 0.07, 0.065, mat_wheels)
	_cyl(vp,"WheelFR", Vector3(-0.155,0.068,0.34),  Vector3(0,0,90), 0.07, 0.065, mat_wheels)
	_cyl(vp,"WheelRL", Vector3(0.155,0.068,-0.34),  Vector3(0,0,90), 0.07, 0.065, mat_wheels)
	_cyl(vp,"WheelRR", Vector3(-0.155,0.068,-0.34), Vector3(0,0,90), 0.07, 0.065, mat_wheels)
	_box(vp,"FootL",   Vector3(0.10,0.14,0.20),     Vector3(0.14,0.12,0.30), mat_shoes)
	_box(vp,"FootR",   Vector3(-0.10,0.14,-0.10),   Vector3(0.14,0.12,0.30), mat_shoes)
	_box(vp,"SockL",   Vector3(0.10,0.33,0.08),     Vector3(0.11,0.22,0.11), mat_socks)
	_box(vp,"SockR",   Vector3(-0.10,0.33,-0.08),   Vector3(0.11,0.22,0.11), mat_socks)
	_box(vp,"LegL",    Vector3(0.11,0.64,0.04),     Vector3(0.14,0.44,0.17), mat_pants)
	_box(vp,"LegR",    Vector3(-0.11,0.64,-0.04),   Vector3(0.14,0.44,0.17), mat_pants)
	_box(vp,"Hips",    Vector3(0,0.90,0),            Vector3(0.37,0.20,0.22), mat_pants)
	_box(vp,"Torso",   Vector3(0,1.20,0),            Vector3(0.44,0.44,0.24), mat_shirt)
	_box(vp,"ArmL",    Vector3(0.30,1.10,0.02),     Vector3(0.13,0.36,0.13), mat_shirt)
	_box(vp,"ArmR",    Vector3(-0.30,1.10,0.02),    Vector3(0.13,0.36,0.13), mat_shirt)
	_box(vp,"Backpack",Vector3(0,1.22,0.22),         Vector3(0.41,0.50,0.23), mat_pack)
	_box(vp,"BpackBot",Vector3(0,0.99,0.20),         Vector3(0.35,0.15,0.21), mat_pack)
	_sph(vp,"Head",    Vector3(0,1.58,0),            0.17, mat_skin)
	_box(vp,"Hair",    Vector3(0,1.59,0.11),         Vector3(0.28,0.24,0.17), mat_hair)
	_cyl(vp,"Hat",     Vector3(0,1.76,0),            Vector3.ZERO, 0.17, 0.13, mat_hat)
	print("[BuildCharacter] OK! ", vp.get_child_count(), " partes.")
	EditorInterface.save_scene()
