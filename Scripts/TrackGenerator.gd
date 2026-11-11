@tool
extends Path3D

# ──────────────── Parâmetros da Pista ────────────────
@export_group("Track Shape")
@export var track_length: int = 1500
@export var turn_frequency: float = 0.018
@export var turn_amplitude: float = 70.0
@export var height_drop: float = 280.0
@export var road_width: float = 6.5

@export_group("Regenerar")
@export var regenerate: bool = false:
	set(value):
		if value:
			_build_all()
			regenerate = false

# ──────────────── Materiais ────────────────
var _mat_road    : StandardMaterial3D
var _mat_grass   : StandardMaterial3D
var _mat_foliage : StandardMaterial3D
var _mat_trunk   : StandardMaterial3D
var _mat_wall    : StandardMaterial3D
var _mat_stripe  : StandardMaterial3D

func _ready() -> void:
	_init_materials()
	if not Engine.is_editor_hint():
		_build_all()
	elif curve == null or curve.get_point_count() == 0:
		if curve == null:
			curve = Curve3D.new()
		_build_all()

func _init_materials() -> void:
	_mat_road    = _toon(Color(0.42, 0.40, 0.38))
	_mat_grass   = _toon(Color(0.20, 0.50, 0.17))
	_mat_foliage = _toon(Color(0.12, 0.40, 0.13))
	_mat_trunk   = _toon(Color(0.35, 0.22, 0.10))
	_mat_wall    = _toon(Color(0.55, 0.50, 0.43))
	_mat_stripe  = _toon(Color(0.95, 0.92, 0.72))  # linha central amarelada

func _toon(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.roughness = 0.9
	return m

# ══════════════ GERAÇÃO PRINCIPAL ══════════════

func _build_all() -> void:
	_generate_curve()
	_clear_children_except_road()
	_generate_road_surface()
	_generate_hillside()
	_generate_trees()
	print("[TrackGenerator] Pista completa — ", curve.get_point_count(), " pontos.")

# ── 1. Curva ──────────────────────────────────────────
func _generate_curve() -> void:
	if curve == null:
		curve = Curve3D.new()
	curve.clear_points()

	var steps := int(track_length / 20.0)
	for i in range(steps):
		var p   := float(i) / float(steps - 1)
		var x   := sin(p * track_length * turn_frequency) * turn_amplitude
		var y   := -p * height_drop
		var z   := -p * track_length
		var pos := Vector3(x, y, z)

		var in_t  := Vector3.ZERO
		var out_t := Vector3.ZERO
		if i > 0 and i < steps - 1:
			var pp := float(i - 1) / float(steps - 1)
			var np := float(i + 1) / float(steps - 1)
			var prev := Vector3(sin(pp*track_length*turn_frequency)*turn_amplitude, -pp*height_drop, -pp*track_length)
			var next := Vector3(sin(np*track_length*turn_frequency)*turn_amplitude, -np*height_drop, -np*track_length)
			var d    := (next - prev)
			in_t     = -d.normalized() * (d.length() * 0.25)
			out_t    =  d.normalized() * (d.length() * 0.25)

		curve.add_point(pos, in_t, out_t)
		# banking suave nas curvas
		var bank := cos(p * track_length * turn_frequency) * 0.18
		curve.set_point_tilt(i, bank)

# ── 2. Limpa filhos antigos (exceto RoadSurface) ──────
func _clear_children_except_road() -> void:
	for child in get_children():
		if child.name != "RoadSurface":
			child.queue_free()

# ── 3. Superfície da Estrada ──────────────────────────
func _generate_road_surface() -> void:
	if has_node("RoadSurface"):
		return  # já existe no .tscn

# ── 4. Encosta (Hillside) ─────────────────────────────
func _generate_hillside() -> void:
	var parent := Node3D.new()
	parent.name = "Hillside"
	add_child(parent)
	if Engine.is_editor_hint():
		parent.owner = get_tree().get_edited_scene_root()

	var baked_len := curve.get_baked_length()
	var seg_step  := 25.0
	var t         := 0.0

	while t < baked_len - seg_step:
		var xf     := curve.sample_baked_with_rotation(t, true, true)
		var pos    := xf.origin
		var right  := xf.basis.x.normalized()   # direita local da estrada
		var up_vec := Vector3.UP

		# Encosta ESQUERDA — cai para o oceano (plano inclinado longo)
		var slope_l := CSGBox3D.new()
		slope_l.size      = Vector3(seg_step * 1.05, 1.0, 45.0)
		slope_l.use_collision = false
		slope_l.material_override = _mat_grass
		# posiciona à esquerda, inclinado para baixo
		slope_l.position  = pos - right * (road_width + 22.0) + Vector3(0, -2.5, 0)
		slope_l.rotation  = xf.basis.get_euler() + Vector3(0.0, 0.0, 0.28)
		parent.add_child(slope_l)
		if Engine.is_editor_hint():
			slope_l.owner = get_tree().get_edited_scene_root()

		# Encosta DIREITA — sobe como morro
		var slope_r := CSGBox3D.new()
		slope_r.size      = Vector3(seg_step * 1.05, 1.0, 40.0)
		slope_r.use_collision = false
		slope_r.material_override = _mat_grass
		slope_r.position  = pos + right * (road_width + 18.0) + Vector3(0, -2.0, 0)
		slope_r.rotation  = xf.basis.get_euler() + Vector3(0.0, 0.0, -0.35)
		parent.add_child(slope_r)
		if Engine.is_editor_hint():
			slope_r.owner = get_tree().get_edited_scene_root()

		# Muro de contenção (direita)
		var wall := CSGBox3D.new()
		wall.size      = Vector3(seg_step * 1.05, 1.2, 0.35)
		wall.use_collision = false
		wall.material_override = _mat_wall
		wall.position  = pos + right * (road_width + 0.8) + Vector3(0, 0.6, 0)
		wall.rotation  = xf.basis.get_euler()
		parent.add_child(wall)
		if Engine.is_editor_hint():
			wall.owner = get_tree().get_edited_scene_root()

		t += seg_step

# ── 5. Árvores (distribuídas ao longo da pista) ───────
func _generate_trees() -> void:
	var parent := Node3D.new()
	parent.name = "Trees"
	add_child(parent)
	if Engine.is_editor_hint():
		parent.owner = get_tree().get_edited_scene_root()

	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	var baked_len := curve.get_baked_length()
	var t         := 20.0

	while t < baked_len - 20.0:
		var xf    := curve.sample_baked_with_rotation(t, true, true)
		var pos   := xf.origin
		var right := xf.basis.x.normalized()

		# Árvores no lado DIREITO (encosta que sobe)
		for _i in range(rng.randi_range(2, 4)):
			var off_r := right * rng.randf_range(10.0, 28.0)
			var off_y := Vector3(0, rng.randf_range(-2.0, 4.0), 0)
			_plant_tree(parent, pos + off_r + off_y, rng)

		# Árvores no lado ESQUERDO (encosta para o oceano, mais esparsas)
		for _i in range(rng.randi_range(1, 2)):
			var off_l := -right * rng.randf_range(12.0, 24.0)
			var off_y := Vector3(0, rng.randf_range(-4.0, 0.0), 0)
			_plant_tree(parent, pos + off_l + off_y, rng)

		t += rng.randf_range(18.0, 32.0)

func _plant_tree(parent: Node3D, base_pos: Vector3, rng: RandomNumberGenerator) -> void:
	var h  := rng.randf_range(3.5, 9.0)
	var fr := rng.randf_range(1.8, 4.0)

	# Tronco
	var trunk := CSGCylinder3D.new()
	trunk.radius         = rng.randf_range(0.12, 0.22)
	trunk.height         = h * 0.55
	trunk.use_collision  = false
	trunk.material_override = _mat_trunk
	trunk.position       = base_pos + Vector3(0, h * 0.55 * 0.5, 0)
	parent.add_child(trunk)
	if Engine.is_editor_hint():
		trunk.owner = get_tree().get_edited_scene_root()

	# Folhagem (esfera levemente achatada)
	var foliage := CSGSphere3D.new()
	foliage.radius        = fr
	foliage.use_collision = false
	foliage.material_override = _mat_foliage
	foliage.position      = base_pos + Vector3(0, h * 0.55 + fr * 0.65, 0)
	# Escala para achatamento orgânico
	foliage.scale = Vector3(1.0, rng.randf_range(0.75, 1.1), 1.0)
	parent.add_child(foliage)
	if Engine.is_editor_hint():
		foliage.owner = get_tree().get_edited_scene_root()

	# Segunda esfera de folhagem (árvores mais densas)
	if rng.randf() > 0.4:
		var foliage2 := CSGSphere3D.new()
		foliage2.radius       = fr * rng.randf_range(0.55, 0.80)
		foliage2.use_collision = false
		foliage2.material_override = _mat_foliage
		var off := Vector3(rng.randf_range(-fr*0.5, fr*0.5), rng.randf_range(-fr*0.3, fr*0.5), rng.randf_range(-fr*0.4, fr*0.4))
		foliage2.position = foliage.position + off
		parent.add_child(foliage2)
		if Engine.is_editor_hint():
			foliage2.owner = get_tree().get_edited_scene_root()
