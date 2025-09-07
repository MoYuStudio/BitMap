extends Node2D
class_name Road

# 道路类型枚举
enum RoadType {
	RAILWAY,    # 铁路
	HIGHWAY,    # 高速公路
	ROAD        # 公路
}

# 道路数据
var road_type: RoadType
var points: Array[Vector2]
var start_city: Node2D
var end_city: Node2D
var line_node: Line2D

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

func _init(type: RoadType, road_points: Array[Vector2], start: Node2D = null, end: Node2D = null):
	road_type = type
	points = road_points
	start_city = start
	end_city = end
	
	# 加载纹理
	load_textures()
	
	# 创建Line2D节点
	create_line_node()

func load_textures():
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
			break

func create_line_node():
	"""创建道路的Line2D节点"""
	line_node = Line2D.new()
	line_node.points = points
	
	# 根据道路类型设置样式
	match road_type:
		RoadType.RAILWAY:
			line_node.width = RAILWAY_WIDTH
			if railway_texture:
				line_node.texture = railway_texture
				line_node.texture_mode = Line2D.LINE_TEXTURE_TILE
				line_node.default_color = Color.WHITE
				line_node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			else:
				line_node.default_color = RAILWAY_COLOR
		RoadType.HIGHWAY:
			line_node.width = HIGHWAY_WIDTH
			if highway_texture:
				line_node.texture = highway_texture
				line_node.texture_mode = Line2D.LINE_TEXTURE_TILE
				line_node.default_color = Color.WHITE
				line_node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			else:
				line_node.default_color = HIGHWAY_COLOR
		RoadType.ROAD:
			line_node.width = ROAD_WIDTH
			if road_texture:
				line_node.texture = road_texture
				line_node.texture_mode = Line2D.LINE_TEXTURE_TILE
				line_node.default_color = Color.WHITE
				line_node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			else:
				line_node.default_color = ROAD_COLOR
	
	line_node.modulate.a = ROAD_ALPHA
	
	# 设置线条样式
	line_node.joint_mode = Line2D.LINE_JOINT_ROUND
	line_node.end_cap_mode = Line2D.LINE_CAP_ROUND
	line_node.begin_cap_mode = Line2D.LINE_CAP_ROUND

func get_road_type() -> RoadType:
	return road_type

func get_points() -> Array[Vector2]:
	return points

func get_line_node() -> Line2D:
	return line_node

func get_start_city() -> Node2D:
	return start_city

func get_end_city() -> Node2D:
	return end_city

func calculate_length() -> float:
	"""计算道路的总长度"""
	if points.size() < 2:
		return 0.0
	
	var total_length = 0.0
	for i in range(points.size() - 1):
		total_length += points[i].distance_to(points[i + 1])
	
	return total_length

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

func is_point_on_road(world_position: Vector2) -> bool:
	"""检查点是否在道路上（优化格子吸附道路的检测）"""
	var road_width = RAILWAY_WIDTH
	match road_type:
		RoadType.RAILWAY:
			road_width = RAILWAY_WIDTH
		RoadType.HIGHWAY:
			road_width = HIGHWAY_WIDTH
		RoadType.ROAD:
			road_width = ROAD_WIDTH
	
	# 检查点击是否在任何线段上
	for i in range(points.size() - 1):
		var start_point = points[i]
		var end_point = points[i + 1]
		
		# 计算点到线段的距离
		var distance = point_to_line_distance(world_position, start_point, end_point)
		
		# 对于格子吸附的道路，增加一些容差
		var tolerance = road_width / 2.0 + 4.0  # 增加4像素的容差
		
		# 如果距离小于容差，认为点击了这条道路
		if distance <= tolerance:
			return true
	
	return false

func validate_road_angles() -> bool:
	"""验证道路的所有角度是否符合90度和45度限制"""
	if points.size() < 3:
		return true  # 少于3个点，无需验证角度
	
	for i in range(1, points.size() - 1):
		var prev_point = points[i - 1]
		var current_point = points[i]
		var next_point = points[i + 1]
		
		# 计算两个线段的角度
		var angle1 = get_angle_between_points(prev_point, current_point)
		var angle2 = get_angle_between_points(current_point, next_point)
		
		# 计算角度差
		var angle_diff = abs(angle2 - angle1)
		if angle_diff > 180:
			angle_diff = 360 - angle_diff
		
		# 检查角度差是否为45度的倍数
		var remainder = fmod(angle_diff, 45.0)
		if remainder > 5.0 and remainder < 40.0:  # 5度容差
			return false
	
	return true

func get_angle_between_points(from_point: Vector2, to_point: Vector2) -> float:
	"""计算两点之间的角度（以度为单位）"""
	var direction = to_point - from_point
	var angle_rad = atan2(direction.y, direction.x)
	var angle_deg = rad_to_deg(angle_rad)
	
	# 将角度标准化到0-360度范围
	if angle_deg < 0:
		angle_deg += 360
	
	return angle_deg
