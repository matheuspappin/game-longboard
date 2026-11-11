extends CharacterBody3D

# --- Exportáveis ---
@export var MAX_SPEED: float = 45.0
@export var GRAVITY_MULT: float = 2.0         # multiplicador de gravidade para ficar colado no chão
@export var TURN_SPEED: float = 2.2           # velocidade de curva (yaw)
@export var DRIFT_TURN_MULT: float = 1.5      # boost de curva no drift
@export var NORMAL_GRIP: float = 15.0         # quão rápido segue a direção normal
@export var DRIFT_GRIP: float = 0.35          # grip durante drift (baixo = mais slide)
@export var AIR_DRAG: float = 0.5             # arrasto aerodinâmico na velocidade máxima

# --- Estado interno ---
var current_speed: float = 0.0
var is_drifting: bool = false
var turn_input: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Nós filhos ---
@onready var visual_pivot: Node3D = $VisualPivot

func _ready() -> void:
	add_to_group("player")

# --- API para câmera externa ---
func get_speed() -> float:
	return current_speed

func get_turn_input() -> float:
	return turn_input

func get_is_drifting() -> bool:
	return is_drifting

func _physics_process(delta: float) -> void:
	turn_input = Input.get_axis("ui_left", "ui_right")
	is_drifting = Input.is_action_pressed("drift")

	var floor_normal = get_floor_normal() if is_on_floor() else Vector3.UP

	if is_on_floor():
		# --- Aceleração por gravidade da ladeira ---
		var slope_sin = 1.0 - floor_normal.dot(Vector3.UP)   # 0 = plano, 1 = vertical
		var slope_accel = _gravity * slope_sin * 3.0
		current_speed += slope_accel * delta

		# Arrasto aerodinâmico ao atingir velocidade máxima
		var drag = AIR_DRAG * (current_speed / MAX_SPEED)
		current_speed -= current_speed * drag * delta
		
		# Frear em piso plano
		if slope_sin < 0.02:
			current_speed = move_toward(current_speed, 0.0, 4.0 * delta)

		current_speed = clamp(current_speed, 0.0, MAX_SPEED)

		# --- Steering (só yaw — nunca pitch/roll no CharacterBody3D) ---
		var steer = turn_input * TURN_SPEED
		if is_drifting:
			steer *= DRIFT_TURN_MULT
		rotate_y(-steer * delta)

		# --- Direção de movimento projetada no plano do chão ---
		var forward = -transform.basis.z
		var move_dir = (forward - floor_normal * forward.dot(floor_normal)).normalized()
		var target_vel = move_dir * current_speed

		# --- Grip / Drift ---
		var grip = DRIFT_GRIP if is_drifting else NORMAL_GRIP
		velocity.x = lerp(velocity.x, target_vel.x, clamp(grip * delta, 0.0, 1.0))
		velocity.z = lerp(velocity.z, target_vel.z, clamp(grip * delta, 0.0, 1.0))
		# Y: segue a inclinação do chão + força para baixo para manter contato
		velocity.y = target_vel.y - _gravity * GRAVITY_MULT * delta

	else:
		# No ar: só gravidade
		velocity.y -= _gravity * delta

	# --- Animação visual do personagem ---
	if visual_pivot:
		# Lean lateral (carving)
		var target_lean = turn_input * 0.32
		visual_pivot.rotation.z = lerp_angle(visual_pivot.rotation.z, target_lean, 10.0 * delta)
		# Tuck: agacha proporcionalmente à velocidade (tuck position)
		var speed_ratio = current_speed / MAX_SPEED
		visual_pivot.rotation.x = lerp_angle(visual_pivot.rotation.x, -speed_ratio * 0.35, 6.0 * delta)
		# Drift: gira o corpo em relação ao board
		var drift_target_y = turn_input * (PI / 3.5) if is_drifting else 0.0
		visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, drift_target_y, 12.0 * delta)

	move_and_slide()
