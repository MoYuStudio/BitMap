extends TileMapLayer

# 城市实例存储
var cities: Dictionary = {}  # Vector2i -> CityInstance (Node2D)
var city_counter: int = 0

# 城市蔓延参数
const MAX_CITY_LEVEL = 5
const SPREAD_CHANCE = 0.3  # 城市蔓延概率
const INITIAL_SPREAD_DISTANCE = 2  # 初始扩散距离
const MAX_SPREAD_DISTANCE = 50  # 最大搜索距离（性能限制）
var spread_enabled = true  # 城市蔓延开关

# 城市地块升级参数
const TILE_UPGRADE_INTERVAL = 5.0  # 地块升级间隔（秒）
const TILE_UPGRADE_CHANCE = 0.2    # 地块升级概率

# 城市实例场景
var city_scene = preload("res://src/module/city.tscn")

# 地形层引用（用于坐标转换和地形检查）
var terrain_layer: TileMapLayer

# 国风城市名词库
const CITY_NAMES = [
	"长安", "洛阳", "姑苏", "金陵", "临安", "广陵", "江州", "锦官", "渝州", "襄阳",
	"赤壁", "鄱阳", "潇湘", "云梦", "蓬莱", "雁门", "玉门", "天水", "酒泉", "张掖",
	"敦煌", "武威", "朔方", "幽州", "蓟门", "范阳", "易水", "邯郸", "邺城", "朝歌",
	"陈留", "许昌", "谯郡", "寿春", "合肥", "建业", "吴郡", "会稽", "山阴", "永嘉",
	"临海", "台州", "婺州", "括苍", "青田", "龙泉", "丽水", "松江", "华亭", "嘉定",
	"镇江", "丹阳", "晋陵", "无锡", "常熟", "昆山", "吴江", "嘉兴", "湖州", "德清",
	"崇德", "桐乡", "余杭", "富阳", "建德", "桐庐", "淳安", "绍兴", "上虞", "余姚",
	"慈溪", "奉化", "宁海", "天台", "仙居", "黄岩", "温岭", "乐清", "瑞安", "平阳",
	"苍南", "三门", "象山", "定海", "普陀", "岱山", "嵊泗", "上海", "青浦", "金山",
	"奉贤", "南汇", "川沙", "宝山", "崇明", "海门", "启东", "如皋", "通州", "泰州",
	"扬州", "仪征", "六合", "滁州", "和州", "庐州", "舒城", "六安", "霍山", "潜山",
	"桐城", "安庆", "池州", "铜陵", "芜湖", "当涂", "马鞍山"
]

func _ready():
	# 获取地形层引用
	terrain_layer = get_node("../TerrainLayer")
	
	# 设置定时器用于城市蔓延
	var spread_timer = Timer.new()
	spread_timer.wait_time = 2.0  # 每2秒检查一次蔓延
	spread_timer.timeout.connect(_on_spread_timer_timeout)
	spread_timer.autostart = true
	add_child(spread_timer)
	
	# 设置定时器用于城市地块升级
	var upgrade_timer = Timer.new()
	upgrade_timer.wait_time = TILE_UPGRADE_INTERVAL  # 每5秒检查一次升级
	upgrade_timer.timeout.connect(_on_upgrade_timer_timeout)
	upgrade_timer.autostart = true
	add_child(upgrade_timer)

func place_city_at_position(tile_position: Vector2i):
	# 检查位置是否已有城市
	if cities.has(tile_position):
		print("位置 ", tile_position, " 已有城市")
		return
	
	# 检查地形是否适合建城（不能在水上建城）
	if not is_suitable_terrain(tile_position):
		print("位置 ", tile_position, " 地形不适合建城")
		return
	
	# 创建城市实例
	var city_instance = city_scene.instantiate()
	add_child(city_instance)
	
	# 设置城市位置（使用TileMapLayer的坐标转换）
	var world_pos = terrain_layer.map_to_local(tile_position)
	city_instance.global_position = terrain_layer.to_global(world_pos)
	
	# 设置城市数据
	city_counter += 1
	var city_name = get_random_city_name()
	city_instance.set_city_data(city_name, tile_position)
	
	# 设置城市等级
	city_instance.city_level = 0  # 初始等级为0
	
	# 更新城市显示
	city_instance.update_city_display()
	
	# 存储城市实例
	cities[tile_position] = city_instance
	
	# 城市中心不放置瓦片，只放置城市实例
	# 城市地块会通过扩散机制从中心向外创建
	
	print("在位置 ", tile_position, " 放置了城市: ", city_name, " (等级 0)")

func remove_city_at_position(tile_position: Vector2i):
	# 检查位置是否有城市实例
	if cities.has(tile_position):
		# 移除城市实例
		var city_instance = cities[tile_position]
		city_instance.queue_free()
		cities.erase(tile_position)
		print("在位置 ", tile_position, " 移除了城市实例: ", city_instance.city_name)
		return  # 城市实例被删除，不需要删除地块
	
	# 检查位置是否有城市地块（瓦片）
	if get_cell_source_id(tile_position) != -1:
		# 移除城市地块瓦片
		set_cell(tile_position, -1, Vector2i(0, 0))
		print("在位置 ", tile_position, " 移除了城市地块")
		return
	
	# 如果既没有城市实例也没有城市地块
	print("位置 ", tile_position, " 没有城市实例或城市地块")

func clear_all_cities():
	# 清除所有城市实例
	for city_instance in cities.values():
		city_instance.queue_free()
	cities.clear()
	city_counter = 0
	
	# 清除所有城市瓦片
	clear()
	
	print("清除了所有城市")

func get_city_at_position(tile_position: Vector2i) -> Node2D:
	# 获取指定位置的城市实例
	return cities.get(tile_position, null)

func has_city_or_city_tile_at_position(tile_position: Vector2i) -> bool:
	# 检查位置是否有城市实例或城市地块
	return cities.has(tile_position) or get_cell_source_id(tile_position) != -1

func get_all_cities() -> Dictionary:
	# 获取所有城市
	return cities

func get_city_count() -> int:
	# 获取城市数量
	return cities.size()

func get_random_city_name() -> String:
	# 从词库中随机选择一个城市名称
	var used_names = []
	for city_instance in cities.values():
		used_names.append(city_instance.city_name)
	
	# 过滤掉已使用的名称
	var available_names = []
	for city_name in CITY_NAMES:
		if city_name not in used_names:
			available_names.append(city_name)
	
	# 如果没有可用名称，使用编号
	if available_names.is_empty():
		return "新城" + str(city_counter)
	
	# 随机选择一个可用名称
	return available_names[randi() % available_names.size()]

func is_suitable_terrain(tile_position: Vector2i) -> bool:
	# 检查地形是否适合建城
	if not terrain_layer:
		return true  # 如果没有地形层，默认可以建城
	
	# 获取地形瓦片
	var terrain_tile = terrain_layer.get_cell_source_id(tile_position)
	
	# 检查是否为水域（假设source_id 0-2为水域）
	if terrain_tile >= 0 and terrain_tile <= 2:
		return false
	
	return true

func _on_spread_timer_timeout():
	# 城市蔓延检查
	check_city_spread()

func _on_upgrade_timer_timeout():
	# 城市地块升级检查
	check_tile_upgrades()
	# 更新所有城市的等级
	update_all_city_levels()

func check_city_spread():
	# 检查蔓延开关
	if not spread_enabled:
		return
	
	# 遍历所有城市，检查是否可以蔓延
	var cities_to_spread = []
	
	for pos in cities.keys():
		var city_instance = cities[pos]
		var _level = city_instance.city_level
		
		# 所有等级的城市都可以蔓延
		cities_to_spread.append(pos)
	
	# 随机选择一些城市进行蔓延
	for pos in cities_to_spread:
		if randf() < SPREAD_CHANCE:
			spread_city(pos)

func spread_city(city_position: Vector2i):
	# 城市蔓延逻辑 - 只创建城市地块（瓦片），不创建城市实例
	var city_instance = cities[city_position]
	var current_level = city_instance.city_level
	
	# 寻找蔓延目标位置
	var spread_positions = get_spread_positions(city_position)
	
	# 按优先级排序位置（距离中心近且周围有更多城市地块的位置优先）
	spread_positions.sort_custom(func(a, b): return get_spread_priority(a, city_position) > get_spread_priority(b, city_position))
	
	for pos in spread_positions:
		# 检查位置是否已有城市实例或城市地块
		if cities.has(pos) or get_cell_source_id(pos) != -1:
			continue
		
		# 检查地形是否适合
		if not is_suitable_terrain(pos):
			continue
		
		# 设置新城市地块等级（等级比原城市低1级，最低为0）
		var new_level = max(0, current_level - 1)
		
		# 在TileMapLayer上放置城市地块瓦片
		set_cell(pos, new_level, Vector2i(0, 0))
		
		print("城市蔓延: ", city_instance.city_name, " 蔓延到 ", pos, " 创建了城市地块 (等级 ", new_level, ")")
		break  # 一次只蔓延一个城市地块

func get_spread_positions(center_position: Vector2i) -> Array[Vector2i]:
	# 获取城市蔓延的候选位置（从城市实例中心开始扩散）
	var positions: Array[Vector2i] = []
	
	# 从城市实例中心开始，逐层向外搜索扩散位置
	var search_distance = 1  # 从距离中心1格开始搜索
	
	while search_distance <= MAX_SPREAD_DISTANCE:
		# 在当前距离的圆形边界上寻找空位
		for x in range(-search_distance, search_distance + 1):
			for y in range(-search_distance, search_distance + 1):
				# 计算到中心点的距离
				var distance = sqrt(x * x + y * y)
				
				# 只检查当前搜索距离边界上的位置
				if abs(distance - search_distance) < 0.5:  # 允许一些浮点误差
					var pos = center_position + Vector2i(x, y)
					
					# 检查位置是否已有城市实例或城市地块
					if not cities.has(pos) and get_cell_source_id(pos) == -1:
						# 检查地形是否适合
						if is_suitable_terrain(pos):
							positions.append(pos)
		
		# 如果找到了足够的位置，可以停止搜索
		if positions.size() >= 10:  # 限制候选位置数量以提高性能
			break
		
		search_distance += 1
	
	# 按距离排序，优先选择距离中心较近的位置
	positions.sort_custom(func(a, b): return center_position.distance_to(a) < center_position.distance_to(b))
	
	return positions


func get_spread_priority(pos: Vector2i, center_position: Vector2i) -> float:
	# 计算扩散位置的优先级
	# 优先级 = 距离权重 + 周围城市地块数量权重
	
	# 距离权重（距离中心越近，权重越高）
	var distance = center_position.distance_to(pos)
	var distance_weight = 1.0 / (1.0 + distance)  # 距离越近权重越高
	
	# 周围城市地块数量权重
	var neighbor_count = 0
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0:
				continue
			var neighbor_pos = pos + Vector2i(x, y)
			if get_cell_source_id(neighbor_pos) >= 0:
				neighbor_count += 1
	
	var neighbor_weight = neighbor_count * 0.1  # 周围城市地块越多权重越高
	
	return distance_weight + neighbor_weight

func upgrade_city(tile_position: Vector2i):
	# 升级城市
	if not cities.has(tile_position):
		return
	
	var city_instance = cities[tile_position]
	var current_level = city_instance.city_level
	
	# 检查是否可以升级
	if current_level >= MAX_CITY_LEVEL:
		print("城市 ", city_instance.city_name, " 已达到最高等级")
		return
	
	# 升级城市
	var new_level = current_level + 1
	city_instance.city_level = new_level
	
	# 更新城市显示
	city_instance.update_city_display()
	
	# 更新瓦片
	set_cell(tile_position, new_level, Vector2i(0, 0))
	
	print("城市 ", city_instance.city_name, " 升级到等级 ", new_level)

func get_city_level(tile_position: Vector2i) -> int:
	# 获取城市等级
	if cities.has(tile_position):
		return cities[tile_position].city_level
	return -1

func get_cities_by_level(level: int) -> Array[Vector2i]:
	# 获取指定等级的所有城市位置
	var result: Array[Vector2i] = []
	for pos in cities.keys():
		if cities[pos].city_level == level:
			result.append(pos)
	return result

func set_spread_enabled(spread_enabled_param: bool):
	# 设置城市蔓延开关
	spread_enabled = spread_enabled_param
	print("城市蔓延", "开启" if spread_enabled_param else "关闭")

func is_spread_enabled() -> bool:
	# 获取城市蔓延开关状态
	return spread_enabled

func toggle_spread():
	# 切换城市蔓延开关
	spread_enabled = !spread_enabled
	print("城市蔓延", "开启" if spread_enabled else "关闭")

func check_tile_upgrades():
	# 检查所有城市地块是否可以升级
	var tiles_to_upgrade = []
	
	# 检查每个城市实例周围的地块
	for city_pos in cities.keys():
		# 检查以城市实例为中心的地块
		var check_distance = 30  # 扩大检查范围
		for x in range(-check_distance, check_distance + 1):
			for y in range(-check_distance, check_distance + 1):
				# 计算到城市实例中心的距离
				var distance = sqrt(x * x + y * y)
				
				# 只检查在圆形范围内的位置
				if distance <= check_distance:
					var pos = city_pos + Vector2i(x, y)
					var tile_id = get_cell_source_id(pos)
					
					# 如果是城市地块且未达到最高等级
					if tile_id >= 0 and tile_id < MAX_CITY_LEVEL:
						tiles_to_upgrade.append(pos)
	
	# 随机选择一些地块进行升级
	for pos in tiles_to_upgrade:
		if randf() < TILE_UPGRADE_CHANCE:
			upgrade_tile_at_position(pos)

func upgrade_tile_at_position(tile_position: Vector2i):
	# 升级指定位置的城市地块
	var current_level = get_cell_source_id(tile_position)
	
	# 检查是否可以升级
	if current_level < 0 or current_level >= MAX_CITY_LEVEL:
		return
	
	# 升级地块
	var new_level = current_level + 1
	set_cell(tile_position, new_level, Vector2i(0, 0))
	
	print("城市地块升级: 位置 ", tile_position, " 从等级 ", current_level, " 升级到等级 ", new_level)

func update_all_city_levels():
	# 根据城市地块数量更新所有城市的等级
	for pos in cities.keys():
		var city_instance = cities[pos]
		var new_level = calculate_city_level(pos)
		
		# 如果等级发生变化，更新城市实例
		if city_instance.city_level != new_level:
			city_instance.city_level = new_level
			city_instance.update_city_display()
			print("城市等级更新: ", city_instance.city_name, " 等级更新为 ", new_level)

func calculate_city_level(city_position: Vector2i) -> int:
	# 根据城市地块数量计算城市等级（以城市实例为中心）
	var tile_count = 0
	var total_level = 0
	
	# 统计以城市实例为中心的地块数量和等级
	var search_radius = 20  # 搜索半径，可以根据需要调整
	for x in range(-search_radius, search_radius + 1):
		for y in range(-search_radius, search_radius + 1):
			# 计算到城市实例中心的距离
			var distance = sqrt(x * x + y * y)
			
			# 只统计在搜索范围内的地块
			if distance <= search_radius:
				var pos = city_position + Vector2i(x, y)
				var tile_id = get_cell_source_id(pos)
				
				# 如果是城市地块（不包括城市实例中心）
				if tile_id >= 0:
					tile_count += 1
					total_level += tile_id
	
	# 计算平均等级
	if tile_count == 0:
		return 0  # 如果没有城市地块，城市等级为0
	
	var average_level = float(total_level) / float(tile_count)
	
	# 根据地块数量和平均等级计算城市等级
	# 地块数量越多，城市等级越高，但增长逐渐放缓
	var city_level = int(average_level) + min(sqrt(tile_count) / 2.0, 5.0)  # 使用平方根减缓增长
	
	return clamp(city_level, 0, MAX_CITY_LEVEL)
