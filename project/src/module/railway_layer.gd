extends Node2D

# 铁路系统管理器
# 使用Line2D节点来绘制铁路线段

# 铁路数据存储
var railways: Array[Dictionary] = []  # 存储所有铁路线段
var current_railway: Array[Vector2] = []  # 当前正在绘制的铁路
var is_drawing_railway = false  # 是否正在绘制铁路
var start_city: Node2D = null  # 起始城市

# 铁路样式设置
const RAILWAY_COLOR = Color(0.4, 0.2, 0.1)  # 深棕色
const RAILWAY_WIDTH = 6.0  # 增加铁路宽度
const RAILWAY_ALPHA = 0.8

# 铁路纹理
var railway_texture: Texture2D

# 层引用
var city_layer: Node2D
var terrain_layer: TileMapLayer

# 铁路线段节点
var railway_lines: Array[Line2D] = []

# 预览线条
var preview_line: Line2D = null

func _ready():
	# 获取层引用
	city_layer = get_node("../CityLayer")
	terrain_layer = get_node("../TerrainLayer")
	
	# 加载铁路纹理（如果存在）
	load_railway_texture()

func start_railway_drawing(from_position: Vector2, from_city: Node2D = null):
	"""开始绘制铁路，从指定位置开始"""
	if is_drawing_railway:
		# 如果已经在绘制，先结束当前绘制
		end_railway_drawing()
	
	start_city = from_city
	is_drawing_railway = true
	current_railway = [from_position]
	
	# 创建预览线条
	create_preview_line()
	
	if from_city:
		print("开始绘制铁路，起始城市: ", from_city.city_name)
	else:
		print("开始绘制铁路，起始位置: ", from_position)

func add_railway_point(world_position: Vector2):
	"""添加铁路点（不吸附到瓦片位置）"""
	if not is_drawing_railway:
		return
	
	# 直接使用鼠标位置，不进行瓦片吸附
	var point_pos = world_position
	
	# 避免重复添加相同位置的点
	if current_railway.size() > 0 and current_railway[-1].distance_to(point_pos) < 8:
		return
	
	current_railway.append(point_pos)
	
	# 更新预览线条
	update_preview_line()
	
	print("添加铁路点: ", point_pos)

func end_railway_drawing(end_city: Node2D = null):
	"""结束铁路绘制"""
	if not is_drawing_railway:
		return
	
	# 如果指定了结束城市，添加其位置
	if end_city:
		current_railway.append(end_city.global_position)
		print("结束绘制铁路，终点城市: ", end_city.city_name)
	
	# 如果铁路有足够的点，保存它
	if current_railway.size() >= 2:
		save_railway()
	
	# 清除预览线条
	clear_preview_line()
	
	# 重置状态
	is_drawing_railway = false
	current_railway.clear()
	start_city = null

func save_railway():
	"""保存当前铁路到铁路列表"""
	var railway_data = {
		"points": current_railway.duplicate(),
		"start_city": start_city,
		"end_city": null,  # 可以后续添加终点城市检测
		"line_node": null  # 将在create_railway_line中设置
	}
	
	railways.append(railway_data)
	create_railway_line(railway_data)
	
	print("保存铁路，包含 ", current_railway.size(), " 个点")

func create_railway_line(railway_data: Dictionary):
	"""创建铁路的Line2D节点"""
	var line = Line2D.new()
	line.points = railway_data["points"]
	line.width = RAILWAY_WIDTH
	
	# 设置铁路纹理和颜色
	if railway_texture:
		line.texture = railway_texture
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.default_color = Color.WHITE  # 使用白色让纹理正常显示
		# 设置纹理重复频率，让纹理更密集地重复
		line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	else:
		line.default_color = RAILWAY_COLOR  # 没有纹理时使用深棕色
	
	line.modulate.a = RAILWAY_ALPHA
	
	# 设置线条样式
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	
	add_child(line)
	railway_lines.append(line)
	railway_data["line_node"] = line

func get_city_at_position(world_position: Vector2) -> Node2D:
	"""获取指定位置的城市"""
	if not city_layer:
		return null
	
	# 遍历所有城市，检查是否在点击范围内
	for city_pos in city_layer.cities.keys():
		var city = city_layer.cities[city_pos]
		if city:
			# 检查点击是否在城市范围内（城市大小为16x16）
			var city_rect = Rect2(city.global_position - Vector2(8, 8), Vector2(16, 16))
			if city_rect.has_point(world_position):
				return city
	
	return null

func clear_all_railways():
	"""清除所有铁路"""
	for line in railway_lines:
		if is_instance_valid(line):
			line.queue_free()
	
	railway_lines.clear()
	railways.clear()
	
	# 清除预览线条
	clear_preview_line()
	
	# 重置绘制状态
	is_drawing_railway = false
	current_railway.clear()
	start_city = null
	
	print("清除了所有铁路")

func create_preview_line():
	"""创建预览线条"""
	if preview_line:
		preview_line.queue_free()
	
	preview_line = Line2D.new()
	preview_line.width = RAILWAY_WIDTH
	preview_line.modulate.a = RAILWAY_ALPHA * 0.6  # 半透明预览
	
	# 设置铁路纹理和颜色
	if railway_texture:
		preview_line.texture = railway_texture
		preview_line.texture_mode = Line2D.LINE_TEXTURE_TILE
		preview_line.default_color = Color.WHITE  # 使用白色让纹理正常显示
		preview_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	else:
		preview_line.default_color = RAILWAY_COLOR  # 没有纹理时使用深棕色
	
	# 设置线条样式
	preview_line.joint_mode = Line2D.LINE_JOINT_ROUND
	preview_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	preview_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	
	add_child(preview_line)

func update_preview_line():
	"""更新预览线条"""
	if not preview_line:
		return
	
	# 添加当前鼠标位置作为预览点（不吸附到瓦片）
	var mouse_pos = get_global_mouse_position()
	
	# 创建包含当前铁路点和鼠标位置的预览点数组
	var preview_points = current_railway.duplicate()
	preview_points.append(mouse_pos)
	
	preview_line.points = preview_points

func clear_preview_line():
	"""清除预览线条"""
	if preview_line:
		preview_line.queue_free()
		preview_line = null

func is_drawing() -> bool:
	"""是否正在绘制铁路"""
	return is_drawing_railway

func get_current_railway_points() -> Array[Vector2]:
	"""获取当前铁路的点"""
	return current_railway.duplicate()

func load_railway_texture():
	"""加载铁路纹理"""
	# 尝试加载铁路纹理文件
	var texture_paths = [
		"res://assets/railway.png",
		"res://assets/tile/railway.png", 
		"res://railway.png"
	]
	
	for path in texture_paths:
		if ResourceLoader.exists(path):
			railway_texture = load(path)
			print("成功加载铁路纹理: ", path)
			return
	
	print("未找到铁路纹理文件，将使用纯色线条")
	print("支持的路径: ", texture_paths)

func set_railway_texture(texture: Texture2D):
	"""设置铁路纹理"""
	railway_texture = texture
	
	# 更新所有现有铁路线条的纹理
	for line in railway_lines:
		if is_instance_valid(line):
			line.texture = railway_texture
			if railway_texture:
				line.texture_mode = Line2D.LINE_TEXTURE_TILE
				line.default_color = Color.WHITE  # 使用白色让纹理正常显示
				line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			else:
				line.default_color = RAILWAY_COLOR  # 没有纹理时使用深棕色
	
	# 更新预览线条的纹理
	if preview_line and is_instance_valid(preview_line):
		preview_line.texture = railway_texture
		if railway_texture:
			preview_line.texture_mode = Line2D.LINE_TEXTURE_TILE
			preview_line.default_color = Color.WHITE  # 使用白色让纹理正常显示
			preview_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		else:
			preview_line.default_color = RAILWAY_COLOR  # 没有纹理时使用深棕色
	
	print("已更新铁路纹理")

func get_railway_texture() -> Texture2D:
	"""获取当前铁路纹理"""
	return railway_texture

func calculate_line_length(points: Array[Vector2]) -> float:
	"""计算线条的总长度"""
	if points.size() < 2:
		return 0.0
	
	var total_length = 0.0
	for i in range(points.size() - 1):
		total_length += points[i].distance_to(points[i + 1])
	
	return total_length

func get_railway_at_position(world_position: Vector2) -> Dictionary:
	"""获取指定位置的铁路"""
	# 遍历所有铁路，检查点击是否在铁路线段上
	for i in range(railways.size()):
		var railway = railways[i]
		var points = railway["points"]
		
		# 检查点击是否在任何线段上
		for j in range(points.size() - 1):
			var start_point = points[j]
			var end_point = points[j + 1]
			
			# 计算点到线段的距离
			var distance = point_to_line_distance(world_position, start_point, end_point)
			
			# 如果距离小于铁路宽度的一半，认为点击了这条铁路
			if distance <= RAILWAY_WIDTH / 2.0:
				return railway
	
	return {}

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

func remove_railway_at_position(world_position: Vector2) -> bool:
	"""删除指定位置的铁路"""
	var railway = get_railway_at_position(world_position)
	if railway.is_empty():
		print("位置 ", world_position, " 没有铁路")
		return false
	
	# 找到要删除的铁路在数组中的索引
	var railway_index = -1
	for i in range(railways.size()):
		if railways[i] == railway:
			railway_index = i
			break
	
	if railway_index == -1:
		print("未找到要删除的铁路")
		return false
	
	# 删除Line2D节点
	var line_node = railway["line_node"]
	if line_node and is_instance_valid(line_node):
		line_node.queue_free()
	
	# 从数组中移除铁路数据
	railways.remove_at(railway_index)
	
	# 从铁路线条数组中移除对应的Line2D
	for i in range(railway_lines.size()):
		if railway_lines[i] == line_node:
			railway_lines.remove_at(i)
			break
	
	print("在位置 ", world_position, " 删除了铁路")
	return true
