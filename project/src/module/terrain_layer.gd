extends TileMapLayer

# 地图生成参数
const MAP_WIDTH = 256
const MAP_HEIGHT = 256

# 高度图参数
const HEIGHT_LEVELS = 8  # 8个高度等级

# 高度等级名称
const HEIGHT_NAMES = [
	"深海", "深水", "浅水", "海岸", "平原", "丘陵", "山地", "高山"
]

# 噪声生成器 - 多层噪声模拟地球地形
var noise_continental: FastNoiseLite  # 大陆噪声
var noise_mountain: FastNoiseLite     # 山脉噪声
var noise_hill: FastNoiseLite         # 丘陵噪声
var noise_detail: FastNoiseLite       # 细节噪声
var noise_ridge: FastNoiseLite        # 山脊噪声
var noise_ocean: FastNoiseLite        # 海洋噪声
var noise_coast: FastNoiseLite        # 海岸噪声
var noise_smoothness: FastNoiseLite   # 平滑度噪声
var noise_coast_type: FastNoiseLite   # 海岸类型噪声（崖壁vs沙滩）

# 高度图数据存储
var height_map: Array[Array] = []

# 地球地形参数 - 提高频率减少平滑度，增加细节
const CONTINENTAL_FREQUENCY = 0.02    # 大陆频率（提高以减少平滑度）
const MOUNTAIN_FREQUENCY = 0.08       # 山脉频率（提高以减少平滑度）
const HILL_FREQUENCY = 0.15           # 丘陵频率（提高以减少平滑度）
const DETAIL_FREQUENCY = 0.3          # 细节频率（提高以增加细节变化）
const RIDGE_FREQUENCY = 0.06          # 山脊频率（提高以减少平滑度）
const OCEAN_FREQUENCY = 0.1           # 海洋频率（提高以减少平滑度）
const COAST_FREQUENCY = 0.25          # 海岸频率（提高以减少平滑度）
const SMOOTHNESS_FREQUENCY = 0.015    # 平滑度频率（控制不同区域的平滑程度）
const COAST_TYPE_FREQUENCY = 0.02     # 海岸类型频率（控制崖壁vs沙滩的分布）

# 地形分布控制参数 - 增加陆地面积
const OCEAN_THRESHOLD = -0.5          # 海洋阈值（降低以增加陆地面积）
const MOUNTAIN_THRESHOLD = 0.7        # 山脉阈值（进一步提高以减少高山）
const RIDGE_THRESHOLD = 0.5           # 山脊阈值（进一步提高以减少高山）

func _ready():
	# 初始化多层噪声生成器
	initialize_noise_generators()
	
	# 初始化高度图数组
	initialize_height_map()
	
	# 设置输入监听
	set_process_input(true)
	
	# 默认生成地球风格高度图
	generate_earth_like_height_map()

func _input(event):
	# 检测按键1重新生成地球风格高度图
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			generate_earth_like_height_map()

func initialize_noise_generators():
	# 初始化大陆噪声（大尺度地形）- 减少平滑度
	noise_continental = FastNoiseLite.new()
	noise_continental.frequency = CONTINENTAL_FREQUENCY
	noise_continental.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_continental.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_continental.fractal_octaves = 3  # 增加分形层数以减少平滑度
	
	# 初始化山脉噪声 - 减少平滑度
	noise_mountain = FastNoiseLite.new()
	noise_mountain.frequency = MOUNTAIN_FREQUENCY
	noise_mountain.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_mountain.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noise_mountain.fractal_octaves = 2  # 增加分形层数以减少平滑度
	
	# 初始化丘陵噪声 - 更平整
	noise_hill = FastNoiseLite.new()
	noise_hill.frequency = HILL_FREQUENCY
	noise_hill.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_hill.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_hill.fractal_octaves = 1  # 减少分形层数以获得更平整的地形
	
	# 初始化细节噪声 - 更平整
	noise_detail = FastNoiseLite.new()
	noise_detail.frequency = DETAIL_FREQUENCY
	noise_detail.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_detail.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_detail.fractal_octaves = 1  # 减少分形层数
	
	# 初始化山脊噪声 - 更平整
	noise_ridge = FastNoiseLite.new()
	noise_ridge.frequency = RIDGE_FREQUENCY
	noise_ridge.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noise_ridge.fractal_octaves = 1  # 减少分形层数
	
	# 初始化海洋噪声 - 减少平滑度
	noise_ocean = FastNoiseLite.new()
	noise_ocean.frequency = OCEAN_FREQUENCY
	noise_ocean.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_ocean.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_ocean.fractal_octaves = 2  # 增加分形层数以减少平滑度
	
	# 初始化海岸噪声 - 更平整
	noise_coast = FastNoiseLite.new()
	noise_coast.frequency = COAST_FREQUENCY
	noise_coast.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_coast.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_coast.fractal_octaves = 1  # 减少分形层数
	
	# 初始化平滑度噪声 - 控制不同区域的平滑程度
	noise_smoothness = FastNoiseLite.new()
	noise_smoothness.frequency = SMOOTHNESS_FREQUENCY
	noise_smoothness.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_smoothness.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_smoothness.fractal_octaves = 2  # 适中的分形层数
	
	# 初始化海岸类型噪声 - 控制崖壁vs沙滩的分布
	noise_coast_type = FastNoiseLite.new()
	noise_coast_type.frequency = COAST_TYPE_FREQUENCY
	noise_coast_type.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_coast_type.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_coast_type.fractal_octaves = 2  # 适中的分形层数

func initialize_height_map():
	# 初始化高度图数组
	height_map.clear()
	for x in range(MAP_WIDTH):
		height_map.append([])
		for y in range(MAP_HEIGHT):
			height_map[x].append(0.0)


func generate_earth_like_height_map():
	# 生成地球风格的高度图
	var base_seed = randi()
	
	# 设置所有噪声的种子（保持一致性）
	noise_continental.seed = base_seed
	noise_mountain.seed = base_seed + 1000
	noise_hill.seed = base_seed + 2000
	noise_detail.seed = base_seed + 3000
	noise_ridge.seed = base_seed + 4000
	noise_ocean.seed = base_seed + 5000
	noise_coast.seed = base_seed + 6000
	noise_smoothness.seed = base_seed + 7000
	noise_coast_type.seed = base_seed + 8000
	
	clear()
	
	var start_x = -MAP_WIDTH / 2
	var start_y = -MAP_HEIGHT / 2
	
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var world_x = start_x + x
			var world_y = start_y + y
			
			# 计算地球风格的地形高度
			var height_value = calculate_earth_height(world_x, world_y)
			
			height_map[x][y] = height_value
			var height_level = get_height_level_from_noise(height_value)
			set_height_tile_by_level(Vector2i(world_x, world_y), height_level)
	
	print("地球风格16色高度图生成完成！种子: ", base_seed)
	print_height_distribution()

func calculate_earth_height(x: float, y: float) -> float:
	# 计算适合128x128地图的地形高度
	# 使用多层噪声以在小地图中产生可见的地形变化
	
	# 1. 大陆噪声 - 决定大尺度的大陆分布
	var continental = noise_continental.get_noise_2d(x, y)
	
	# 2. 山脉噪声 - 在陆地上添加山脉
	var mountain = noise_mountain.get_noise_2d(x, y)
	
	# 3. 丘陵噪声 - 添加丘陵地形
	var hill = noise_hill.get_noise_2d(x, y)
	
	# 4. 山脊噪声 - 添加山脊特征
	var ridge = noise_ridge.get_noise_2d(x, y)
	
	# 5. 细节噪声 - 添加细节变化
	var detail = noise_detail.get_noise_2d(x, y)
	
	# 6. 海洋噪声 - 海洋地形变化
	var ocean = noise_ocean.get_noise_2d(x, y)
	
	# 7. 海岸噪声 - 海岸线变化
	var coast = noise_coast.get_noise_2d(x, y)
	
	# 8. 平滑度噪声 - 控制不同区域的平滑程度
	var smoothness = noise_smoothness.get_noise_2d(x, y)
	# 将平滑度从 [-1, 1] 映射到 [0.002, 0.3]，进一步增加总平滑度
	var smoothness_factor = 0.002 + (smoothness + 1.0) * 0.149
	
	# 9. 海岸类型噪声 - 控制崖壁vs沙滩的分布
	var coast_type = noise_coast_type.get_noise_2d(x, y)
	# 将海岸类型从 [-1, 1] 映射到 [0.5, 1.5]，控制海岸特征强度
	var coast_type_factor = 0.5 + (coast_type + 1.0) * 0.5
	
	# 组合噪声层，适合小地图的地形特征
	var final_height = 0.0
	
	if continental > OCEAN_THRESHOLD:  # 陆地区域（动态噪声变化）
		# 在陆地上添加地形变化 - 使用平滑度因子动态调整
		var land_height = continental * 1.2  # 基础陆地高度变化
		
		# 添加山脉（使用平滑度因子调整）
		if mountain > 0.1:  # 极大降低阈值
			land_height += mountain * 0.7 * smoothness_factor  # 动态调整山脉贡献
		
		# 添加丘陵（使用平滑度因子调整）
		land_height += hill * 0.6 * smoothness_factor  # 动态调整丘陵贡献
		
		# 添加山脊特征（使用平滑度因子调整）
		if ridge > 0.0:  # 极大降低阈值
			land_height += ridge * 0.5 * smoothness_factor  # 动态调整山脊贡献
		
		# 添加细节（使用平滑度因子调整）
		land_height += detail * 0.5 * smoothness_factor  # 动态调整细节贡献
		
		# 添加海岸变化（使用平滑度和海岸类型因子调整）
		land_height += coast * 0.3 * smoothness_factor * coast_type_factor  # 动态调整海岸线变化
		
		final_height = land_height
	else:  # 海洋区域（动态噪声变化）
		# 海洋深度变化（使用平滑度因子动态调整）
		var ocean_depth = continental * 1.2  # 基础海洋深度变化
		ocean_depth += ocean * 0.5 * smoothness_factor   # 动态调整海洋地形变化
		ocean_depth += detail * 0.4 * smoothness_factor  # 动态调整海洋细节变化
		ocean_depth += hill * 0.25 * smoothness_factor   # 动态调整海洋地形变化
		ocean_depth += coast * 0.25 * smoothness_factor * coast_type_factor  # 动态调整海岸线影响
		final_height = ocean_depth
	
	# 确保高度值在合理范围内
	return clamp(final_height, -1.0, 1.0)

func get_height_level_from_noise(noise_value: float) -> int:
	# 将噪声值 (-1 到 1) 转换为高度等级 (0 到 15)
	# 减少浅水区，让陆地和海洋过渡更快
	
	# 使用非线性映射，减少浅水区
	var normalized_value = (noise_value + 1.0) / 2.0  # 转换到 [0, 1]
	
	# 应用非线性变换，增加陆地面积，保持海岸1-2%
	if normalized_value < 0.3:  # 海洋区域（减少海洋）
		# 减少海洋区域
		normalized_value = normalized_value * 0.4  # 压缩到 [0, 0.12]
	elif normalized_value > 0.4:  # 陆地区域（降低阈值增加陆地）
		# 扩展陆地区域，跳过大部分海岸
		normalized_value = 0.14 + (normalized_value - 0.4) * 2.15  # 扩展到 [0.14, 1.0]
	else:  # 中间区域（保持海岸1-2%）
		# 保持海岸区
		normalized_value = 0.12 + (normalized_value - 0.3) * 0.2  # 保持到 [0.12, 0.14]
	
	var height_level = int(normalized_value * (HEIGHT_LEVELS - 1))
	return clamp(height_level, 0, HEIGHT_LEVELS - 1)

func set_height_tile_by_level(tile_position: Vector2i, height_level: int):
	# 直接使用16色瓦片源 (source_id 0-15 对应高度等级 0-15)
	set_cell(tile_position, height_level, Vector2i(0, 0))


func print_height_distribution():
	# 统计各高度等级的分布情况
	var level_counts: Array[int] = []
	for i in range(HEIGHT_LEVELS):
		level_counts.append(0)
	
	# 统计每个高度等级的数量
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var height_level = get_height_level_from_noise(height_map[x][y])
			level_counts[height_level] += 1
	
	# 打印分布情况
	print("=== 16色高度图分布统计 ===")
	var total_tiles = MAP_WIDTH * MAP_HEIGHT
	for i in range(HEIGHT_LEVELS):
		var percentage = (level_counts[i] / float(total_tiles)) * 100.0
		print("等级 ", i, " (", HEIGHT_NAMES[i], "): ", level_counts[i], " 瓦片 (", "%.1f" % percentage, "%)")


func get_height_name(level: int) -> String:
	# 获取指定高度等级的名称
	if level >= 0 and level < HEIGHT_NAMES.size():
		return HEIGHT_NAMES[level]
	return "未知"
