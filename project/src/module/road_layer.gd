extends Node2D

# 道路系统管理器
# 使用Line2D节点来绘制道路线段（铁路和高速公路）

# 道路数据存储
var roads: Array[Road] = []  # 存储所有道路
var current_road: Array[Vector2] = []  # 当前正在绘制的道路
var is_drawing_road = false  # 是否正在绘制道路
var start_city: Node2D = null  # 起始城市
var current_road_type: Road.RoadType = Road.RoadType.RAILWAY  # 当前道路类型

# 道路样式设置
const RAILWAY_COLOR = Color(0.4, 0.2, 0.1)  # 深棕色
const HIGHWAY_COLOR = Color(0.2, 0.2, 0.2)  # 深灰色
const ROAD_COLOR = Color(0.3, 0.3, 0.3)     # 中灰色
const RAILWAY_WIDTH = 6.0
const HIGHWAY_WIDTH = 4.0
const ROAD_WIDTH = 2.0
const ROAD_ALPHA = 0.8

# 道路纹理
var railway_texture: Texture2D
var highway_texture: Texture2D
var road_texture: Texture2D

# 层引用
var city_layer: TileMapLayer
var terrain_layer: TileMapLayer

# 道路线段节点
var road_lines: Array[Line2D] = []

# 预览线条
var preview_line: Line2D = null

func _ready():
	# 获取层引用
	city_layer = get_node("../CityLayer")
	terrain_layer = get_node("../TerrainLayer")
	
	# 加载道路纹理（如果存在）
	load_road_textures()

func start_road_drawing(from_position: Vector2, from_city: Node2D = null, road_type: Road.RoadType = Road.RoadType.RAILWAY):
	"""开始绘制道路，从指定位置开始"""
	if is_drawing_road:
		# 如果已经在绘制，先结束当前绘制
		end_road_drawing()
	
	start_city = from_city
	current_road_type = road_type
	is_drawing_road = true
	
	# 将起始位置吸附到格子
	var snapped_position = snap_to_grid(from_position)
	current_road = [snapped_position]
	
	# 创建预览线条
	create_preview_line()
	
	var road_type_name = ""
	match road_type:
		Road.RoadType.RAILWAY:
			road_type_name = "铁路"
		Road.RoadType.HIGHWAY:
			road_type_name = "高速公路"
		Road.RoadType.ROAD:
			road_type_name = "公路"
	if from_city:
		print("开始绘制", road_type_name, "，起始城市: ", get_city_name(from_city))
	else:
		print("开始绘制", road_type_name, "，起始位置: ", snapped_position)

func add_road_point(world_position: Vector2):
	"""添加道路点（吸附到格子，支持90度和45度角度）"""
	if not is_drawing_road:
		return
	
	# 将位置吸附到格子
	var snapped_pos = snap_to_grid(world_position)
	
	# 避免重复添加相同位置的点
	if current_road.size() > 0 and current_road[-1].distance_to(snapped_pos) < 1:
		return
	
	# 检查角度限制（90度和45度）
	if current_road.size() > 0:
		var last_point = current_road[-1]
		var angle = get_angle_between_points(last_point, snapped_pos)
		
		# 检查是否为有效的角度（0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°）
		if not is_valid_angle(angle):
			# 如果角度无效，尝试找到最近的有效角度
			var corrected_pos = snap_to_valid_angle(last_point, snapped_pos)
			if corrected_pos:
				snapped_pos = corrected_pos
			else:
				return  # 如果无法找到有效角度，不添加点
	
	current_road.append(snapped_pos)
	
	# 更新预览线条
	update_preview_line()
	
	var road_type_name = ""
	match current_road_type:
		Road.RoadType.RAILWAY:
			road_type_name = "铁路"
		Road.RoadType.HIGHWAY:
			road_type_name = "高速公路"
		Road.RoadType.ROAD:
			road_type_name = "公路"
	print("添加", road_type_name, "点: ", snapped_pos)

func end_road_drawing(end_city: Node2D = null):
	"""结束道路绘制"""
	if not is_drawing_road:
		return
	
	# 如果指定了结束城市，添加其位置（吸附到格子）
	if end_city:
		var snapped_city_pos = snap_to_grid(end_city.global_position)
		current_road.append(snapped_city_pos)
		var road_type_name = ""
		match current_road_type:
			Road.RoadType.RAILWAY:
				road_type_name = "铁路"
			Road.RoadType.HIGHWAY:
				road_type_name = "高速公路"
			Road.RoadType.ROAD:
				road_type_name = "公路"
		print("结束绘制", road_type_name, "，终点城市: ", get_city_name(end_city))
	
	# 如果道路有足够的点，保存它
	if current_road.size() >= 2:
		save_road()
	
	# 清除预览线条
	clear_preview_line()
	
	# 重置状态
	is_drawing_road = false
	current_road.clear()
	start_city = null

func save_road():
	"""保存当前道路到道路列表"""
	# 创建道路对象
	var road = Road.new(current_road_type, current_road.duplicate(), start_city, null)
	roads.append(road)
	
	# 将Line2D节点添加到场景
	add_child(road.get_line_node())
	road_lines.append(road.get_line_node())
	
	var road_type_name = ""
	match current_road_type:
		Road.RoadType.RAILWAY:
			road_type_name = "铁路"
		Road.RoadType.HIGHWAY:
			road_type_name = "高速公路"
		Road.RoadType.ROAD:
			road_type_name = "公路"
	print("保存", road_type_name, "，包含 ", current_road.size(), " 个点")


func get_city_at_position(world_position: Vector2) -> Node2D:
	"""获取指定位置的城市"""
	if not city_layer:
		return null
	
	# 将世界坐标转换为瓦片坐标
	var tile_pos = terrain_layer.local_to_map(terrain_layer.to_local(world_position))
	
	# 检查该位置是否有城市实例
	var city_instance = city_layer.get_city_at_position(tile_pos)
	if city_instance:
		# 直接返回城市实例（用于道路连接）
		return city_instance
	
	# 检查该位置是否有城市地块（瓦片）
	if city_layer.get_cell_source_id(tile_pos) != -1:
		# 创建一个临时的Node2D来表示城市地块（用于道路连接）
		var city_tile_node = Node2D.new()
		city_tile_node.global_position = terrain_layer.to_global(terrain_layer.map_to_local(tile_pos))
		# 使用set_meta来存储城市名称，因为Node2D没有city_name属性
		city_tile_node.set_meta("city_name", "城市地块")
		return city_tile_node
	
	return null

func clear_all_roads():
	"""清除所有道路"""
	for line in road_lines:
		if is_instance_valid(line):
			line.queue_free()
	
	road_lines.clear()
	roads.clear()
	
	# 清除预览线条
	clear_preview_line()
	
	# 重置绘制状态
	is_drawing_road = false
	current_road.clear()
	start_city = null
	
	print("清除了所有道路")

func create_preview_line():
	"""创建预览线条"""
	if preview_line:
		preview_line.queue_free()
	
	preview_line = Line2D.new()
	
	# 根据道路类型设置样式
	match current_road_type:
		Road.RoadType.RAILWAY:
			preview_line.width = RAILWAY_WIDTH
			if railway_texture:
				preview_line.texture = railway_texture
				preview_line.texture_mode = Line2D.LINE_TEXTURE_TILE
				preview_line.default_color = Color.WHITE
				preview_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			else:
				preview_line.default_color = RAILWAY_COLOR
		Road.RoadType.HIGHWAY:
			preview_line.width = HIGHWAY_WIDTH
			if highway_texture:
				preview_line.texture = highway_texture
				preview_line.texture_mode = Line2D.LINE_TEXTURE_TILE
				preview_line.default_color = Color.WHITE
				preview_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			else:
				preview_line.default_color = HIGHWAY_COLOR
		Road.RoadType.ROAD:
			preview_line.width = ROAD_WIDTH
			if road_texture:
				preview_line.texture = road_texture
				preview_line.texture_mode = Line2D.LINE_TEXTURE_TILE
				preview_line.default_color = Color.WHITE
				preview_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			else:
				preview_line.default_color = ROAD_COLOR
	
	preview_line.modulate.a = ROAD_ALPHA * 0.6  # 半透明预览
	
	# 设置线条样式
	preview_line.joint_mode = Line2D.LINE_JOINT_ROUND
	preview_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	preview_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	
	add_child(preview_line)

func update_preview_line():
	"""更新预览线条"""
	if not preview_line:
		return
	
	# 获取当前鼠标位置并吸附到格子
	var mouse_pos = get_global_mouse_position()
	var snapped_mouse_pos = snap_to_grid(mouse_pos)
	
	# 创建包含当前道路点和吸附后鼠标位置的预览点数组
	var preview_points = current_road.duplicate()
	
	# 如果正在绘制道路，添加预览点
	if is_drawing_road and current_road.size() > 0:
		var last_point = current_road[-1]
		
		# 检查角度限制
		var angle = get_angle_between_points(last_point, snapped_mouse_pos)
		var final_preview_pos = snapped_mouse_pos
		
		if not is_valid_angle(angle):
			# 如果角度无效，尝试找到最近的有效角度
			var corrected_pos = snap_to_valid_angle(last_point, snapped_mouse_pos)
			if corrected_pos:
				final_preview_pos = corrected_pos
			else:
				# 如果无法找到有效角度，不显示预览
				preview_line.points = current_road
				return
		
		preview_points.append(final_preview_pos)
	
	preview_line.points = preview_points

func clear_preview_line():
	"""清除预览线条"""
	if preview_line:
		preview_line.queue_free()
		preview_line = null

func is_drawing() -> bool:
	"""是否正在绘制道路"""
	return is_drawing_road

func get_current_road_points() -> Array[Vector2]:
	"""获取当前道路的点"""
	return current_road.duplicate()

func load_road_textures():
	"""加载道路纹理"""
	# 加载铁路纹理
	var railway_paths = [
		"res://assets/railway.png",
		"res://assets/tile/railway.png", 
		"res://railway.png"
	]
	
	for path in railway_paths:
		if ResourceLoader.exists(path):
			railway_texture = load(path)
			print("成功加载铁路纹理: ", path)
			break
	
	# 加载高速公路纹理
	var highway_paths = [
		"res://assets/highway.png",
		"res://assets/tile/highway.png", 
		"res://highway.png"
	]
	
	for path in highway_paths:
		if ResourceLoader.exists(path):
			highway_texture = load(path)
			print("成功加载高速公路纹理: ", path)
			break
	
	# 加载公路纹理
	var road_paths = [
		"res://assets/road.png",
		"res://assets/tile/road.png", 
		"res://road.png"
	]
	
	for path in road_paths:
		if ResourceLoader.exists(path):
			road_texture = load(path)
			print("成功加载公路纹理: ", path)
			break
	
	if not railway_texture:
		print("未找到铁路纹理文件，将使用纯色线条")
	if not highway_texture:
		print("未找到高速公路纹理文件，将使用纯色线条")
	if not road_texture:
		print("未找到公路纹理文件，将使用纯色线条")

func set_road_texture(texture: Texture2D, road_type: Road.RoadType):
	"""设置道路纹理"""
	match road_type:
		Road.RoadType.RAILWAY:
			railway_texture = texture
		Road.RoadType.HIGHWAY:
			highway_texture = texture
		Road.RoadType.ROAD:
			road_texture = texture
	
	# 更新所有现有道路线条的纹理
	for road in roads:
		if road.get_road_type() == road_type:
			var line = road.get_line_node()
			if is_instance_valid(line):
				line.texture = texture
				if texture:
					line.texture_mode = Line2D.LINE_TEXTURE_TILE
					line.default_color = Color.WHITE
					line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
				else:
					match road_type:
						Road.RoadType.RAILWAY:
							line.default_color = RAILWAY_COLOR
						Road.RoadType.HIGHWAY:
							line.default_color = HIGHWAY_COLOR
						Road.RoadType.ROAD:
							line.default_color = ROAD_COLOR
	
	# 更新预览线条的纹理
	if preview_line and is_instance_valid(preview_line) and current_road_type == road_type:
		preview_line.texture = texture
		if texture:
			preview_line.texture_mode = Line2D.LINE_TEXTURE_TILE
			preview_line.default_color = Color.WHITE
			preview_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		else:
			match road_type:
				Road.RoadType.RAILWAY:
					preview_line.default_color = RAILWAY_COLOR
				Road.RoadType.HIGHWAY:
					preview_line.default_color = HIGHWAY_COLOR
				Road.RoadType.ROAD:
					preview_line.default_color = ROAD_COLOR
	
	var road_type_name = ""
	match road_type:
		Road.RoadType.RAILWAY:
			road_type_name = "铁路"
		Road.RoadType.HIGHWAY:
			road_type_name = "高速公路"
		Road.RoadType.ROAD:
			road_type_name = "公路"
	print("已更新", road_type_name, "纹理")

func get_road_texture(road_type: Road.RoadType) -> Texture2D:
	"""获取道路纹理"""
	match road_type:
		Road.RoadType.RAILWAY:
			return railway_texture
		Road.RoadType.HIGHWAY:
			return highway_texture
		Road.RoadType.ROAD:
			return road_texture
	return null

func get_city_name(city_node: Node2D) -> String:
	"""获取城市名称，兼容城市实例和城市地块"""
	if city_node.has_method("get") and "city_name" in city_node:
		return city_node.city_name
	elif city_node.has_meta("city_name"):
		return city_node.get_meta("city_name")
	else:
		return "未知城市"

func calculate_line_length(points: Array[Vector2]) -> float:
	"""计算线条的总长度"""
	if points.size() < 2:
		return 0.0
	
	var total_length = 0.0
	for i in range(points.size() - 1):
		total_length += points[i].distance_to(points[i + 1])
	
	return total_length

func get_road_at_position(world_position: Vector2) -> Road:
	"""获取指定位置的道路"""
	# 遍历所有道路，检查点击是否在道路线段上
	for road in roads:
		if road.is_point_on_road(world_position):
			return road
	
	return null

func point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	"""计算点到线段的距离"""
	var line_length = line_start.distance_to(line_end)
	if line_length == 0:
		return point.distance_to(line_start)
	
	# 计算点在线段上的投影参数
	var t = ((point.x - line_start.x) * (line_end.x - line_start.x) + (point.y - line_start.y) * (line_end.y - line_start.y)) / (line_length * line_length)
	
	# 限制t在0到1之间
	t = clamp(t, 0.0, 1.0)
	
	# 计算线段上最近的点
	var closest_point = line_start + t * (line_end - line_start)
	
	# 返回点到最近点的距离
	return point.distance_to(closest_point)

func remove_road_at_position(world_position: Vector2) -> bool:
	"""删除指定位置的道路"""
	var road = get_road_at_position(world_position)
	if not road:
		print("位置 ", world_position, " 没有道路")
		return false
	
	# 删除Line2D节点
	var line_node = road.get_line_node()
	if line_node and is_instance_valid(line_node):
		line_node.queue_free()
	
	# 从数组中移除道路数据
	var road_index = roads.find(road)
	if road_index != -1:
		roads.remove_at(road_index)
	
	# 从道路线条数组中移除对应的Line2D
	var line_index = road_lines.find(line_node)
	if line_index != -1:
		road_lines.remove_at(line_index)
	
	var road_type_name = ""
	match road.get_road_type():
		Road.RoadType.RAILWAY:
			road_type_name = "铁路"
		Road.RoadType.HIGHWAY:
			road_type_name = "高速公路"
		Road.RoadType.ROAD:
			road_type_name = "公路"
	print("在位置 ", world_position, " 删除了", road_type_name)
	return true

func set_current_road_type(road_type: Road.RoadType):
	"""设置当前道路类型"""
	current_road_type = road_type
	var road_type_name = ""
	match road_type:
		Road.RoadType.RAILWAY:
			road_type_name = "铁路"
		Road.RoadType.HIGHWAY:
			road_type_name = "高速公路"
		Road.RoadType.ROAD:
			road_type_name = "公路"
	print("当前道路类型设置为: ", road_type_name)

func get_current_road_type() -> Road.RoadType:
	"""获取当前道路类型"""
	return current_road_type

func get_road_count() -> int:
	"""获取道路数量"""
	return roads.size()

func get_all_roads() -> Array[Road]:
	"""获取所有道路"""
	return roads

func get_roads_by_type(road_type: Road.RoadType) -> Array[Road]:
	"""根据类型获取道路"""
	var filtered_roads: Array[Road] = []
	for road in roads:
		if road.get_road_type() == road_type:
			filtered_roads.append(road)
	return filtered_roads

func snap_to_grid(world_position: Vector2) -> Vector2:
	"""将世界坐标吸附到格子中心"""
	if not terrain_layer:
		return world_position
	
	# 将世界坐标转换为瓦片坐标
	var tile_pos = terrain_layer.local_to_map(terrain_layer.to_local(world_position))
	# 将瓦片坐标转换回世界坐标（格子中心）
	var snapped_world_pos = terrain_layer.to_global(terrain_layer.map_to_local(tile_pos))
	return snapped_world_pos

func get_angle_between_points(from_point: Vector2, to_point: Vector2) -> float:
	"""计算两点之间的角度（以度为单位）"""
	var direction = to_point - from_point
	var angle_rad = atan2(direction.y, direction.x)
	var angle_deg = rad_to_deg(angle_rad)
	
	# 将角度标准化到0-360度范围
	if angle_deg < 0:
		angle_deg += 360
	
	return angle_deg

func is_valid_angle(angle: float) -> bool:
	"""检查角度是否为有效的道路角度（0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°）"""
	var tolerance = 5.0  # 5度的容差
	
	# 检查是否接近任何有效角度
	var valid_angles = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]
	
	for valid_angle in valid_angles:
		var diff = abs(angle - valid_angle)
		# 处理角度跨越0度的情况
		if diff > 180:
			diff = 360 - diff
		if diff <= tolerance:
			return true
	
	return false

func snap_to_valid_angle(from_point: Vector2, to_point: Vector2) -> Vector2:
	"""将目标点调整到最近的有效角度"""
	var angle = get_angle_between_points(from_point, to_point)
	var valid_angles = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]
	
	# 找到最近的有效角度
	var closest_angle = valid_angles[0]
	var min_diff = abs(angle - valid_angles[0])
	
	for valid_angle in valid_angles:
		var diff = abs(angle - valid_angle)
		# 处理角度跨越0度的情况
		if diff > 180:
			diff = 360 - diff
		if diff < min_diff:
			min_diff = diff
			closest_angle = valid_angle
	
	# 计算距离
	var distance = from_point.distance_to(to_point)
	
	# 根据最近的有效角度计算新的目标点
	var angle_rad = deg_to_rad(closest_angle)
	var new_direction = Vector2(cos(angle_rad), sin(angle_rad))
	var new_to_point = from_point + new_direction * distance
	
	# 将新点吸附到格子
	return snap_to_grid(new_to_point)
