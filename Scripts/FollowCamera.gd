extends Node3D
## FollowCamera.gd
## Câmera desacoplada do player — estilo low follow-cam dos vídeos de referência.
## Deve ser filho de Node3D na raiz da cena (NÃO filho do Player).

@export var player_path: NodePath = ""
@export var follow_speed: float = 8.0          # quão rápido a posição segue o player
@export var rotation_speed: float = 5.0        # quão rápido o ângulo segue o player

# --- Offset da câmera em relação ao player (espaço local do player) ---
# Vídeo ref: câmera MUITO baixa (quase no chão), um pouco atrás
@export var offset_behind: float = 3.5         # distância atrás
@export var offset_up: float = 0.8             # altura (baixa = próxima do chão)
@export var offset_side: float = 0.0           # deslocamento lateral (0 = centralizado)

# --- Dinâmica da câmera ---
@export var min_fov: float = 75.0
@export var max_fov: float = 100.0             # FOV aumenta com velocidade
@export var max_speed: float = 45.0            # referência de velocidade máxima

# --- Roll cinematic nas curvas ---
@export var roll_amount: float = 0.05          # radianos de roll por unidade de turn

var _player: CharacterBody3D
var _camera: Camera3D
var _smooth_pos: Vector3
var _smooth_basis: Basis

func _ready() -> void:
	_camera = $Camera3D
	if player_path:
		_player = get_node(player_path)
	else:
		# Tenta achar o player automaticamente
		_player = get_tree().get_first_node_in_group("player")
	
	if not _player:
		push_error("FollowCamera: Player não encontrado! Defina player_path ou adicione o Player ao grupo 'player'.")
		return
	
	# Inicializa a câmera imediatamente na posição do player (sem lag inicial)
	_smooth_pos = _get_target_position()
	global_position = _smooth_pos
	_smooth_basis = _player.global_transform.basis

func _process(delta: float) -> void:
	if not _player or not _camera:
		return
	
	var player_speed: float = 0.0
	var player_turn: float = 0.0
	var player_drifting: bool = false
	
	# Lê o estado do player via API pública (sem acoplar à rotação interna)
	if _player.has_method("get_speed"):
		player_speed = _player.get_speed()
	if _player.has_method("get_turn_input"):
		player_turn = _player.get_turn_input()
	if _player.has_method("get_is_drifting"):
		player_drifting = _player.get_is_drifting()
	
	# --- Posição alvo ---
	var target_pos = _get_target_position()
	_smooth_pos = _smooth_pos.lerp(target_pos, clamp(follow_speed * delta, 0.0, 1.0))
	global_position = _smooth_pos
	
	# --- Orientação: sempre olha para um ponto À FRENTE do player (não para o player em si) ---
	var look_target = _player.global_position + (-_player.transform.basis.z * 5.0) + Vector3.UP * 0.5
	var current_forward = (look_target - global_position)
	if current_forward.length() > 0.01:
		var target_quat = Quaternion(global_transform.looking_at(look_target, Vector3.UP).basis)
		var current_quat = Quaternion(global_transform.basis)
		var smooth_quat = current_quat.slerp(target_quat, clamp(rotation_speed * delta, 0.0, 1.0))
		global_transform.basis = Basis(smooth_quat)
	
	# --- Roll cinematic (inclinação Z nas curvas) ---
	var target_roll = -player_turn * roll_amount
	if player_drifting:
		target_roll *= 2.0
	var current_euler = global_transform.basis.get_euler()
	current_euler.z = lerp_angle(current_euler.z, target_roll, 5.0 * delta)
	global_transform.basis = Basis.from_euler(current_euler)
	
	# --- FOV dinâmico baseado na velocidade ---
	var speed_ratio = clamp(player_speed / max_speed, 0.0, 1.0)
	_camera.fov = lerp(min_fov, max_fov, speed_ratio)

func _get_target_position() -> Vector3:
	if not _player:
		return global_position
	
	# Offset no espaço local do player (atrás e levemente acima)
	var player_basis = _player.global_transform.basis
	var behind = player_basis.z * offset_behind          # basis.z aponta para trás
	var up = Vector3.UP * offset_up
	var side = player_basis.x * offset_side
	
	return _player.global_position + behind + up + side
