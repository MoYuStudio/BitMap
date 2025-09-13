extends Node2D

# 城市实例存储
var cities: Dictionary = {}  # Vector2i -> CityInstance
var city_counter: int = 0

# 城市实例场景
var city_scene = preload("res://src/module/city.tscn")

# 地形层引用（用于坐标转换）
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

func place_city_at_position(tile_position: Vector2i):
	# 检查位置是否已有城市
	if cities.has(tile_position):
		print("位置 ", tile_position, " 已有城市")
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
	
	# 存储城市实例
	cities[tile_position] = city_instance
	
	print("在位置 ", tile_position, " 放置了城市: ", city_name)

func remove_city_at_position(tile_position: Vector2i):
	# 检查位置是否有城市
	if not cities.has(tile_position):
		print("位置 ", tile_position, " 没有城市")
		return
	
	# 移除城市实例
	var city_instance = cities[tile_position]
	city_instance.queue_free()
	cities.erase(tile_position)
	
	print("在位置 ", tile_position, " 移除了城市")

func clear_all_cities():
	# 清除所有城市实例
	for city_instance in cities.values():
		city_instance.queue_free()
	cities.clear()
	city_counter = 0
	print("清除了所有城市")

func get_city_at_position(tile_position: Vector2i) -> Node2D:
	# 获取指定位置的城市实例
	return cities.get(tile_position, null)

func get_all_cities() -> Dictionary:
	# 获取所有城市
	return cities

func get_city_count() -> int:
	# 获取城市数量
	return cities.size()

func get_random_city_name() -> String:
	# 从词库中随机选择一个城市名称
	var used_names = []
	for city in cities.values():
		used_names.append(city.city_name)
	
	# 过滤掉已使用的名称
	var available_names = []
	for name in CITY_NAMES:
		if name not in used_names:
			available_names.append(name)
	
	# 如果没有可用名称，使用编号
	if available_names.is_empty():
		return "新城" + str(city_counter)
	
	# 随机选择一个可用名称
	return available_names[randi() % available_names.size()]
