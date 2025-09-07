extends Sprite2D

# 层引用
var terrain_layer: TileMapLayer
var city_layer: Node2D  # 现在是Node2D而不是TileMapLayer
var road_layer: Node2D  # 道路层
var building_selector: CanvasLayer

# 建造模式
enum BuildMode {
	PAINT,    # 绘制模式
	ROAD      # 道路模式
}
var current_build_mode = BuildMode.PAINT

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
	road_layer = get_node("../RoadLayer")
	building_selector = get_node("../../CanvasLayer")
	
	# 连接建筑选择器的信号
	if building_selector:
		building_selector.mode_changed.connect(_on_build_mode_changed)
		building_selector.road_type_changed.connect(_on_road_type_changed)
		print("成功连接到建筑选择器信号")
	else:
		print("错误：无法找到建筑选择器")
	
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
		
		# 处理道路绘制
		handle_road_drawing(mouse_pos)
		
		# 处理道路模式下的右键拖拽删除
		handle_road_erasing(mouse_pos)
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
			# 在道路模式下，处理道路绘制
			if event.pressed and current_build_mode == BuildMode.ROAD:
				handle_road_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_right_mouse_pressed = event.pressed
			# 在道路模式下，右键取消当前道路绘制
			if event.pressed and current_build_mode == BuildMode.ROAD:
				cancel_road_drawing()
		
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


func handle_road_drawing(mouse_pos: Vector2):
	"""处理道路绘制（实时更新预览）"""
	if current_build_mode != BuildMode.ROAD or not road_layer:
		return
	
	# 如果正在绘制道路，实时更新预览线条（显示格子吸附和角度限制）
	if road_layer.is_drawing():
		road_layer.update_preview_line()

func handle_road_click():
	"""处理道路模式的点击（按下开始，再按下结束）"""
	if not road_layer:
		return
	
	var mouse_pos = get_global_mouse_position()
	var clicked_city = road_layer.get_city_at_position(mouse_pos)
	
	# 将鼠标位置吸附到瓦片位置
	var tile_pos = terrain_layer.local_to_map(terrain_layer.to_local(mouse_pos))
	var snapped_pos = terrain_layer.to_global(terrain_layer.map_to_local(tile_pos))
	
	if not road_layer.is_drawing():
		# 开始绘制道路（可以在任何位置开始）
		road_layer.start_road_drawing(snapped_pos, clicked_city, road_layer.get_current_road_type())
		print("开始道路绘制")
	else:
		# 结束绘制道路
		if clicked_city:
			road_layer.end_road_drawing(clicked_city)
		else:
			# 在空白处点击，添加中间点
			road_layer.add_road_point(snapped_pos)
		print("结束道路绘制")

func cancel_road_drawing():
	"""取消当前道路绘制"""
	if road_layer and road_layer.is_drawing():
		road_layer.end_road_drawing()
		print("取消了道路绘制")

func handle_road_erasing(mouse_pos: Vector2):
	"""处理道路模式下的右键拖拽删除"""
	# 只在道路模式下处理道路删除
	if current_build_mode != BuildMode.ROAD or not road_layer:
		return
	
	# 检查是否在UI区域内，如果是则不处理地图操作
	if building_selector and building_selector.is_mouse_over_ui():
		return
	
	# 避免重复操作同一位置
	var mouse_tile = terrain_layer.local_to_map(terrain_layer.to_local(mouse_pos))
	if mouse_tile == last_processed_tile:
		return
	
	# 检查是否有右键按下
	if is_right_mouse_pressed:
		# 删除道路
		if road_layer.remove_road_at_position(mouse_pos):
			last_processed_tile = mouse_tile
			print("连续擦除: 在位置 ", mouse_pos, " 移除道路")

func _on_build_mode_changed(new_mode):
	# 更新建造模式
	current_build_mode = new_mode
	
	# 如果切换到非道路模式，取消当前道路绘制
	if new_mode != BuildMode.ROAD and road_layer and road_layer.is_drawing():
		road_layer.end_road_drawing()
	
	var mode_name = ""
	match new_mode:
		BuildMode.PAINT:
			mode_name = "绘制"
		BuildMode.ROAD:
			mode_name = "道路"
	
	print("建造模式切换为: ", mode_name)
	print("当前模式: ", current_build_mode)

func _on_road_type_changed(road_type: Road.RoadType):
	"""处理道路类型变化"""
	if road_layer:
		road_layer.set_current_road_type(road_type)
