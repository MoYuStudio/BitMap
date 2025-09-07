extends Camera2D

# 移动和缩放参数
const MOVE_SPEED = 300.0  # 移动速度（像素/秒）
const ZOOM_SPEED = 0.1    # 线性缩放速度
const MIN_ZOOM = 0.1      # 最小缩放
const MAX_ZOOM = 5.0      # 最大缩放

func _ready():
	# 设置输入监听
	set_process_input(true)

func _input(event):
	# 处理缩放输入
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			# 放大
			zoom_camera(ZOOM_SPEED)
		elif event.keycode == KEY_E:
			# 缩小
			zoom_camera(-ZOOM_SPEED)

func _process(delta):
	# 处理WASD移动
	var movement = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		movement.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		movement.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		movement.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		movement.x += 1
	
	# 应用移动
	if movement != Vector2.ZERO:
		movement = movement.normalized() * MOVE_SPEED * delta
		position += movement

func zoom_camera(zoom_delta):
	# 线性缩放：直接加减缩放值
	var new_zoom = zoom + Vector2(zoom_delta, zoom_delta)
	
	# 限制缩放范围
	new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
	new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)
	
	# 应用缩放
	zoom = new_zoom
