extends Sprite2D

# 层引用
var terrain_layer: TileMapLayer
var city_layer: Node2D  # 现在是Node2D而不是TileMapLayer
var railway_layer: Node2D  # 铁路层
var building_selector: CanvasLayer

# 建造模式
enum BuildMode {
	CLICK,    # 点击模式
	PAINT,    # 绘制模式
	RAILWAY   # 铁路模式
}
var current_build_mode = BuildMode.CLICK

# 鼠标状态
var is_left_mouse_pressed = false
var is_right_mouse_pressed = false
var last_processed_tile = Vector2i(-999, -999)  # 记录上次处理的位置，避免重复操作

func _ready():
	# 设置光标始终在最前面显示
	z_index = 100
	
	# 隐藏系统光标
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# 获取层引用
	terrain_layer = get_node("../TerrainLayer")
	city_layer = get_node("../CityLayer")
	railway_layer = get_node("../RailwayLayer")
	building_selector = get_node("../CanvasLayer")
	
	# 连接建筑选择器的信号
	if building_selector:
		building_selector.mode_changed.connect(_on_build_mode_changed)
	
	# 设置输入监听
	set_process_input(true)

func _process(delta):
	# 让光标跟随鼠标位置
	var mouse_pos = get_global_mouse_position()
	
	# 如果有地形层，将鼠标位置吸附到瓦片位置
	if terrain_layer:
		# 将世界坐标转换为瓦片坐标
		var tile_pos = terrain_layer.local_to_map(terrain_layer.to_local(mouse_pos))
		# 将瓦片坐标转换回世界坐标
		var snapped_world_pos = terrain_layer.to_global(terrain_layer.map_to_local(tile_pos))
		global_position = snapped_world_pos
		
		# 处理连续绘制和擦除
		handle_continuous_drawing(tile_pos)
		
		# 处理铁路绘制
		handle_railway_drawing(mouse_pos)
	else:
		global_position = mouse_pos

func _input(event):
	# 检测鼠标按下和释放
	if event is InputEventMouseButton:
		# 检查是否在UI区域内，如果是则不处理地图操作
		if building_selector and building_selector.is_mouse_over_ui():
			return
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_left_mouse_pressed = event.pressed
			# 在点击模式下，按下时立即执行操作
			if event.pressed and current_build_mode == BuildMode.CLICK:
				execute_click_action()
			# 在铁路模式下，处理铁路绘制
			elif event.pressed and current_build_mode == BuildMode.RAILWAY:
				handle_railway_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_right_mouse_pressed = event.pressed
			# 在点击模式下，按下时立即执行操作
			if event.pressed and current_build_mode == BuildMode.CLICK:
				execute_click_action()
			# 在铁路模式下，右键取消当前铁路绘制
			elif event.pressed and current_build_mode == BuildMode.RAILWAY:
				cancel_railway_drawing()
		
		# 重置上次处理的位置，允许在按下时立即操作
		if event.pressed:
			last_processed_tile = Vector2i(-999, -999)

func handle_continuous_drawing(tile_pos: Vector2i):
	# 只在绘制模式下处理连续绘制
	if current_build_mode != BuildMode.PAINT:
		return
	
	# 检查是否在UI区域内，如果是则不处理地图操作
	if building_selector and building_selector.is_mouse_over_ui():
		return
	
	# 避免重复操作同一位置
	if tile_pos == last_processed_tile:
		return
	
	# 检查是否有鼠标按下
	if is_left_mouse_pressed and city_layer:
		city_layer.place_city_at_position(tile_pos)
		last_processed_tile = tile_pos
		print("连续绘制: 在位置 ", tile_pos, " 放置城市")
	elif is_right_mouse_pressed and city_layer:
		city_layer.remove_city_at_position(tile_pos)
		last_processed_tile = tile_pos
		print("连续擦除: 在位置 ", tile_pos, " 移除城市")

func execute_click_action():
	# 检查是否在UI区域内，如果是则不处理地图操作
	if building_selector and building_selector.is_mouse_over_ui():
		return
	
	# 获取当前鼠标位置
	var mouse_pos = get_global_mouse_position()
	var tile_pos = terrain_layer.local_to_map(terrain_layer.to_local(mouse_pos))
	
	# 根据鼠标按键执行相应操作
	if is_left_mouse_pressed and city_layer:
		city_layer.place_city_at_position(tile_pos)
	elif is_right_mouse_pressed and city_layer:
		city_layer.remove_city_at_position(tile_pos)

func handle_railway_drawing(mouse_pos: Vector2):
	"""处理铁路绘制（实时更新预览）"""
	if current_build_mode != BuildMode.RAILWAY or not railway_layer:
		return
	
	# 如果正在绘制铁路，实时更新预览线条
	if railway_layer.is_drawing():
		railway_layer.update_preview_line()

func handle_railway_click():
	"""处理铁路模式的点击"""
	if not railway_layer:
		return
	
	var mouse_pos = get_global_mouse_position()
	var clicked_city = railway_layer.get_city_at_position(mouse_pos)
	
	# 将鼠标位置吸附到瓦片位置
	var tile_pos = terrain_layer.local_to_map(terrain_layer.to_local(mouse_pos))
	var snapped_pos = terrain_layer.to_global(terrain_layer.map_to_local(tile_pos))
	
	if not railway_layer.is_drawing():
		# 开始绘制铁路（可以在任何位置开始）
		railway_layer.start_railway_drawing(snapped_pos, clicked_city)
	else:
		# 结束绘制铁路
		if clicked_city:
			railway_layer.end_railway_drawing(clicked_city)
		else:
			# 在空白处点击，添加中间点
			railway_layer.add_railway_point(snapped_pos)

func cancel_railway_drawing():
	"""取消当前铁路绘制"""
	if railway_layer and railway_layer.is_drawing():
		railway_layer.end_railway_drawing()
		print("取消了铁路绘制")

func _on_build_mode_changed(new_mode):
	# 更新建造模式
	current_build_mode = new_mode
	
	# 如果切换到非铁路模式，取消当前铁路绘制
	if new_mode != BuildMode.RAILWAY and railway_layer and railway_layer.is_drawing():
		railway_layer.end_railway_drawing()
	
	var mode_name = ""
	match new_mode:
		BuildMode.CLICK:
			mode_name = "点击"
		BuildMode.PAINT:
			mode_name = "绘制"
		BuildMode.RAILWAY:
			mode_name = "铁路"
	
	print("建造模式切换为: ", mode_name)
	print("当前模式: ", current_build_mode)
