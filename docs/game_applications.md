# PointSampler 在游戏开发中的应用

> 每个采样/聚类/度量算法的游戏开发实战场景

---

## 目录

1. [随机采样 (`random`)](#1-均匀随机采样-random)
2. [准随机序列 (`halton` / `hammersley`)](#2-准随机序列-halton--hammersley)
3. [抖动网格 (`jitteredGrid`)](#3-抖动网格-jitteredgrid)
4. [拉丁超立方 (`latinHypercubeSampling`)](#4-拉丁超立方-latinhypercubesampling)
5. [泊松盘采样 (`poissonDiskSampling*`)](#5-泊松盘采样-poissondisksampling)
6. [高斯聚类 (`gaussianClusters`)](#6-高斯聚类-gaussianclusters)
7. [重要性重采样 & 拒绝采样](#7-重要性重采样--拒绝采样)
8. [随机游走纤维 (`randomWalkFilaments`)](#8-随机游走纤维-randomwalkfilaments)
9. [过滤模块 (`distanceRejectionFilter` 等)](#9-过滤模块)
10. [聚类 (`kmeansClustering` / `dbscanClustering` / `percolationClustering`)](#10-聚类)
11. [松弛 (`relaxationKtree`)](#11-松弛-relaxationktree)
12. [空间度量 (`metrics`)](#12-空间度量-metrics)
13. [组合应用案例](#13-组合应用案例)

---

## 1. 均匀随机采样 (`random`)

**算法**: 在 N 维包围盒内独立均匀采样每个坐标。

### 游戏应用场景

#### 🌲 植被初始布置
在开放世界地图上随机撒种子点，作为树木、草丛、岩石的初始位置。

```nim
# 在 1km² 地图上随机放 10000 棵树
let trees = random[float32, 2](10000, [(0f, 1000f), (0f, 1000f)])
```

#### 💰 战利品掉落
击杀怪物后，在怪物周围随机生成掉落物位置。

```nim
let dropCenter = initPoint[float32, 2]([monster.x, monster.y])
let radius = 2f  # 2 米半径
let drops = random[float32, 2](5, [(-radius, radius), (-radius, radius)])
# 将每个掉落物平移到掉落中心
for d in drops.mitems:
  d = d + dropCenter
```

#### 🎯 准星散布 (Bloom)
FPS 游戏中，子弹在实际弹道周围随机偏移。

```nim
# 准星半径 0.02 弧度内的随机散布
let bloom = random[float32, 2](1, [(-0.02f, 0.02f), (-0.02f, 0.02f)])[0]
applyBloom(bloom)
```

---

## 2. 准随机序列 (`halton` / `hammersley`)

**算法**: 低差异 (low-discrepancy) 序列，比纯随机更均匀地覆盖空间。

### 游戏应用场景

#### 🖼️ 屏幕空间环境光遮蔽 (SSAO)
Halton 序列用于 SSAO 的采样核，减少噪点并提供更均匀的遮蔽估计。

```nim
# 生成 16 个屏幕空间采样方向
let ssaoKernel = hammersley[float32, 2](16, [(0f, 1f), (0f, 1f)])
for sample in ssaoKernel:
  let hemisphereDir = mapToHemisphere(sample, normal)
  shadow += sampleOcclusion(pixelPos, hemisphereDir)
```

#### 🎨 体积雾/云层步进
在体积渲染中沿光线步进时，Halton 偏移使采样更均匀，避免条纹伪影。

```nim
# 体积云光线步进采样位置
let jittered = halton[float32, 1](64, [(0f, 1f)])
for i, offset in jittered:
  let samplePos = rayOrigin + rayDir * (stepSize * (i.float32 + offset[0]))
  density += sampleCloud(samplePos)
```

#### 🖥️ 蒙特卡洛全局光照
用 Halton 序列生成半球方向，比纯随机更快收敛。

```nim
let samples = halton[float32, 2](256, [(0f, 1f), (0f, 1f)])
for s in samples:
  let dir = cosineWeightedHemisphere(s)
  radiance += traceRay(hit.point, dir) * brdf
```

#### 🖌️ 贴图抖动 (Dithering)
在像素着色器中用 Hammersley 值替代阈值贴图的随机噪声。

```nim
# 隐面消隐 (stochastic transparency) 的抖动值
let dither = hammersley[float32, 1](1, [(0f, 1f)])[0][0]
# 若抖动值大于不透明度，则 discard 该片元
if dither > alpha: discard
```

---

## 3. 抖动网格 (`jitteredGrid`)

**算法**: 将空间划分为网格，每格内随机抖动放一个点。

### 游戏应用场景

#### 🏗️ 关卡模块化拼接
在大型关卡中放置预制体模块时，抖动网格确保每个模块区域有一个放置点，避免过密或过稀。

```nim
# 在 500×500 的关卡中放 100 个地牢房间入口
let dungeonEntrances = jitteredGrid[float32, 2](100,
    [(0f, 500f), (0f, 500f)],
    [0.5f, 0.5f],       # 50% 抖动
    [0.2f, 0.2f],       # 交错
    some(uint32(seed)))
```

#### 🔦 局部光照探针 (Light Probes)
在场景中均匀放置光照探针，抖动避免对齐伪影。

```nim
let probes = jitteredGrid[float32, 3](200,
    [(0f, 50f), (0f, 50f), (0f, 10f)],
    [0.8f, 0.8f, 0.2f],
    [0.1f, 0.1f, 0f])
```

#### 🎮 网格化寻路节点
NavMesh 生成前的引导节点放置。

#### 📷 密度采样
将高密度点集降采样为均匀覆盖。

---

## 4. 拉丁超立方 (`latinHypercubeSampling`)

**算法**: 每维均分为 N 层后随机排列，保证各维覆盖均匀且无相关性。

### 游戏应用场景

#### 🌍 开放世界 POI 分布
在大型地图上放置兴趣点 (POI) 时，LHS 确保每个子区域至少有一个 POI，且各维度独立排列避免方向性聚集。

```nim
# 在 10km² 地图上采样 50 个兴趣点
let pois = latinHypercubeSampling[float32, 2](50,
    [(0f, 10000f), (0f, 10000f)])
```

#### 📊 游戏数据分析
在参数空间中均匀采样进行平衡性测试（如攻击力×攻速×防御力的组合空间）。

```nim
# 测试角色属性的参数空间
let testCases = latinHypercubeSampling[float32, 3](1000,
    [(10f, 100f),    # 攻击力
     (0.5f, 3f),      # 攻速
     (5f, 80f)])      # 防御力
for tc in testCases:
  simulateCombat(tc[0], tc[1], tc[2])
```

#### 🎛️ 着色器参数预计算 (LUT)
为查找表 (Look-Up Table) 生成均匀分布的训练样本。

#### 🤖 AI 策略搜索
在混合策略的参数空间中均匀采样进行蒙特卡洛树搜索初始化。

---

## 5. 泊松盘采样 (`poissonDiskSampling`)

**算法**: 确保任意两点间距离 ≥ 指定的最小距离。
提供 5 种变体: 均匀、变密度、幂律半径、Weibull 半径、Weibull+下限。

### 游戏应用场景

#### 🌳 植被分布（均匀变体）
在森林场景中生成自然均匀而不规则重叠的树木分布。

```nim
let trees = poissonDiskSamplingUniform[float32, 2](
    5000,
    [(0f, 1000f), (0f, 1000f)],
    3f,  # 树之间最小 3 米
    some(uint32(mapSeed)))
```

#### 🚶 敌人生成点
确保敌人出生点之间保持最小距离，避免重叠。

```nim
let spawns = poissonDiskSamplingUniform[float32, 2](
    20,
    [(0f, 100f), (0f, 100f)],
    8f,  # 至少 8 米间距
    some(uint32(seed)))
```

#### 🗿 变密度泊松盘（`scaleFn` 参数）
根据地形高度或坡度调整点密度——山坡上树木较密、平地上较稀。

```nim
# 密度随坡度变化
let densityFn = proc(p: Point[float32, 2]): float32 =
  let slope = getTerrainSlope(p.x, p.y)
  1f + 2f * slope  # 陡坡密度×3
let trees = poissonDiskSampling[float32, 2](
    5000, [(0f, 1000f), (0f, 1000f)],
    2f, densityFn)
```

#### 💥 粒子爆炸效果
用幂律半径泊松盘生成自然感碎片飞溅——大量小碎片（小半径）夹杂少量大碎片（大半径）。

```nim
# 幂律分布: 小碎片多(小排距) + 大碎片少(大排距)
let debris = poissonDiskSamplingPowerLaw[float32, 2](
    200,
    0.05f,   # distMin — 小碎片的最小间距
    2f,      # distMax — 大碎片的最大间距
    2.5f,    # alpha — 偏向小碎片
    [(-5f, 5f), (-5f, 5f)],
    some(uint32(seed)))
# 半径映射到碎片尺寸
for i, d in debris:
  spawnDebris(d, radius = 1f / ((i.float32 / 200f) * 9f + 1f))
```

#### 🌌 星空密度分布（Weibull 变体）
银河系恒星分布——中心密集（小半径）、边缘稀疏（大半径）。

```nim
let stars = poissonDiskSamplingWeibull[float32, 2](
    10000,
    lambda = 0.5f,   # 尺度参数
    k = 1.2f,         # 形状参数 (k>1 趋于峰值)
    [(0f, 1000f), (0f, 1000f)])
```

---

## 6. 高斯聚类 (`gaussianClusters`)

**算法**: 围绕簇中心用高斯分布散布点。

### 游戏应用场景

#### 🏘️ 聚落生成
在开放世界地图上围绕村庄/城市中心生成房屋集群。

```nim
# 随机生成 5 个聚落中心
let villageCenters = random[float32, 2](5, [(0f, 1000f), (0f, 1000f)])
# 每个聚落周围散布 50 栋房屋
let houses = gaussianClusters(villageCenters, 50, 15f)
```

#### 🤖 AI 行为热点
围绕资源点、Boss 区域生成巡逻路线点，中心密度高。

#### 👥 人群分布
城市区域 NPC 密度的空间分布——商业区中心密集，周边稀疏。

```nim
let crowdCenters = @[
    initPoint[float32, 2]([250f, 250f]),  # 城市广场
    initPoint[float32, 2]([750f, 750f]),  # 集市
]
let npcs = gaussianClusters(crowdCenters, 200, 50f)
```

#### 🎵 音频源分布
环境音效（鸟鸣、虫鸣）沿音频区域中心聚类分布。

#### 🗺️ 随机遭遇点
RPG 随机遭遇的密度分布——道路附近多，荒野少。

---

## 7. 重要性重采样 & 拒绝采样

**算法**:
- `rejectionSampling`: 按指定概率密度接受/拒绝均匀候选点
- `importanceResampling`: 对 Halton 网格按密度加权后重采样

### 游戏应用场景

#### 🗺️ 按地形密度生成内容
根据地形类型（草地、森林、沙漠、水域）的密度贴图生成植被/建筑。

```nim
# 读取密度贴图
let densityImage = loadImage("terrain_density.png")
let densityFn = proc(p: Point[float32, 2]): float32 =
  densityImage.sample(p.x / 1000f, p.y / 1000f).r

# 重要性重采样
let vegetation = importanceResampling[float32, 2](
    2000,             # 目标点数
    10,               # 过采样倍率
    [(0f, 1000f), (0f, 1000f)],
    densityFn,
    some(uint32(seed)))
```

#### 🏔️ 山脊线采集
用密度函数限制采样点在山脊线附近，用于放置山脊小径、瞭望点。

#### 🎨 体积渲染采样优化
用重要性重采样在体积中沿光学厚度分布采样，使采样集中在高密度区域。

```nim
# 体积渲染: 沿消光系数分布采样
let extinctionFn = proc(p: Point[float32, 3]): float32 =
  sampleVolumeDensity(p)
let samples = importanceResampling[float32, 3](
    64, 4,
    [(0f, 1f), (0f, 1f), (0f, 1f)],
    extinctionFn)
```

#### 💡 路径追踪重要性采样
用 BRDF 或光源可见性作为权重重采样，实现重要性驱动的路径追踪。

---

## 8. 随机游走纤维 (`randomWalkFilaments`)

**算法**: 随机游走生成纤维状结构，可控制方向持续性和厚度。

### 游戏应用场景

#### ⚡ 闪电/电弧
用高持续性 (`persistence ≈ 0.95`) 生成闪电分支，高斯散射 (`gaussianSamples > 0`) 产生电弧宽度。

```nim
let lightning = randomWalkFilaments[float32, 3](
    1,                   # 1 条主干
    50,                  # 50 个步进点
    0.5f,                # 步长
    [(0f, 10f), (0f, 10f), (0f, 50f)],
    seed = some(uint32(42)),
    persistence = 0.95f, # 高度持续（直）
    gaussianSigma = 0.1f,
    gaussianSamples = 5) # 电弧厚度
```

#### 🌊 河流网络
用较低持续性 (`persistence ≈ 0.7`) 生成蜿蜒河流，从源头到入海口。

```nim
let rivers = randomWalkFilaments[float32, 2](
    3,                   # 3 条河
    200,                 # 每河 200 步
    2f,                  # 步长
    [(0f, 1000f), (0f, 1000f)],
    persistence = 0.75f, # 蜿蜒
    gaussianSigma = 3f,  # 河宽
    gaussianSamples = 10)
```

#### 🕸️ 电路/管线/道路网络
多根随机游走纤维作为基础管线，Gaussian 散射生成管道宽度区域。

#### 🎮 弹幕模式
用随机游走生成 Boss 弹幕的子弹轨迹路径点。

#### 🧬 外星地形装饰
生成缠绕的藤蔓、触须、树枝等有机形态装饰。

---

## 9. 过滤模块

| 模块 | 作用 | 游戏用途 |
|------|------|---------|
| `distanceRejectionFilter` | 删除与其他点过近的点 | 消除重复生成、LOD 去重 |
| `functionRejectionFilter` | 按函数概率保留点 | 地形遮罩过滤、区域限制 |
| `randomRejectionFilter` | 随机下采样 | 性能 LOD、数量控制 |
| `filterPointsInRange` | 按轴对齐包围盒过滤 | 视锥剔除、区块加载 |
| `filterPointsFunction` | 按自定义条件过滤 | 可破坏物过滤 |

### 游戏应用场景

#### 🎯 LOD/数量控制
生成 10000 个草点后，用距离拒绝过滤合并重叠，再用随机拒绝降到 2000。

```nim
var grass = random[float32, 2](10000, [(0f, 500f), (0f, 500f)])
grass = distanceRejectionFilter(grass, 0.5f)  # 间距 ≥ 0.5 米
grass = randomRejectionFilter(grass, 0.2f)    # 只保留 20%
```

#### 🏔️ 地形遮罩过滤
只在水面以下的区域放置水生植物。

```nim
let waterPlants = filterPointsFunction(allPlants, proc(p: Point[float32, 2]): float32 =
  if getTerrainHeight(p.x, p.y) < waterLevel: 1f else: 0f)
```

#### 📷 视锥剔除
只保留相机视锥内的点用于渲染。

```nim
let visibleTrees = filterPointsInRange(trees,
    [(camera.minX, camera.maxX), (camera.minZ, camera.maxZ)])
```

---

## 10. 聚类

| 模块 | 适用场景 |
|------|---------|
| `kmeansClustering` | 将点分为 k 个球形簇 |
| `dbscanClustering` | 发现任意形状簇 + 噪声检测 |
| `percolationClustering` | 连通分量（任意形状，无预设 k） |

### 游戏应用场景

#### 🏙️ K-means：城区划分
将建筑物点集分成 k 个区域，每个区域的建筑风格一致。

```nim
let (centroids, labels) = kmeansClustering(buildings, 5)
# labels: 每个建筑属于哪个城区
for i, lbl in labels:
  assignDistrictStyle(buildings[i], styles[lbl])
```

#### 🗑️ DBSCAN：离群点检测
在玩家行为数据中检测异常行为（外挂检测）。

```nim
let labels = dbscanClustering(playerPositions, eps = 2f, minPts = 10)
# labels = -1 的玩家可能是瞬移外挂
```

#### 👥 DBSCAN：玩家聚集热点
分析 MMORPG 玩家位置，找出自发聚集的热点区域。

```nim
let clusterLabels = dbscanClustering(players, eps = 50f, minPts = 5)
let clusters = extractClusters(players, clusterLabels)
for i, cluster in clusters:
  if cluster.len > 20:
    showOnMap("热点区域 #" & $i, centroid(cluster))
```

#### 🔗 逾渗聚类：区域连通性
检查地图上可通行区域的连通分量，发现断开的岛状区域。

```nim
let labels = percolationClustering(navPoints, connectionRadius = 1f)
# 如果有多个簇，则地图不连通
let nClusters = max(labels) + 1
if nClusters > 1:
  warn("地图存在 " & $nClusters & " 个不连通的区域")
```

#### 🏕️ 逾渗聚类：资源点集群
检测矿脉、草药等资源点的空间集群，放置采集区。

---

## 11. 松弛 (`relaxationKtree`)

**算法**: 基于 k 近邻排斥迭代移动点，减少聚类、提高均匀性。

### 游戏应用场景

#### 📐 初始采样后处理
对任意采样结果执行 5-10 次松弛迭代，消除局部密集/稀疏，获得类蓝噪声分布。

```nim
var points = poissonDiskSamplingUniform[float32, 2](
    1000, [(0f, 500f), (0f, 500f)], 3f)
relaxationKtree(points, kNeighbors = 8, stepSize = 0.2f, iterations = 5)
# 点分布更均匀，蓝噪声特性更强
```

#### 🔫 弹幕均匀化
Boss 全屏弹幕时，用松弛避免子弹过密区域——每个子弹间距更均匀。

#### 🌍 最小化碰撞
在物理场景中放置静态物体时，松弛消除初始碰撞。

```nim
var props = gaussianClusters(centers, 50, 2f)
relaxationKtree(props, stepSize = 1f, iterations = 10)
# 道具被推开，避免相互穿插
```

#### 📊 棋盘/网格游戏布局
在策略游戏的网格上均匀放置资源/建筑/单位。

---

## 12. 空间度量 (`metrics`)

| 函数 | 作用 | 游戏用途 |
|------|------|---------|
| `nearestNeighborsIndices` | 每个点的 k 个近邻 | 网格化、路径查找 |
| `firstNeighborDistanceSquared` | 最近邻距离 | 质量评估 |
| `localDensityKnn` | 局部密度估计 | 游戏平衡性分析 |
| `angleDistributionNeighbors` | 角分布函数 | 方向偏好检测 |
| `radialDistribution` | 径向分布函数 g(r) | 空间分布均匀性 |
| `distanceToBoundary` | 到边界距离 | 边界行为调整 |

### 游戏应用场景

#### 📊 平衡性分析
用 `localDensityKnn` 检查地图上资源分布是否均匀。

```nim
let densities = localDensityKnn(oreNodes, k = 8)
let meanDensity = densities.sum / densities.len.float32
let variance = densities.mapIt((it - meanDepth) ^ 2)
# 若方差过大，重新生成
```

#### 🎯 分布质量评估
用 `radialDistribution` 验证泊松盘采样是否满足蓝噪声特性。

```nim
let (r, g) = radialDistribution(
    points, [(0f, 1f), (0f, 1f)], 0.01f, 0.5f)
# g(r) ≈ 0 for r < minDist → 验证最小距离约束
```

#### 🧭 边界感知行为
用 `distanceToBoundary` 让 NPC 远离地图边界或寻路到边界出口。

```nim
let dists = distanceToBoundary(npcPositions, mapBounds)
for i, d in dists:
  if d < 5f:
    npcs[i].steerAwayFrom(nearestBoundary(npcPositions[i]))
```

#### 🔍 异常检测
用 `firstNeighborDistanceSquared` 找出孤立的点——可能是 Bug 生成或异常物品。

---

## 13. 组合应用案例

### 🗺️ 开放世界植被系统（完整管线）

```nim
import point_sampler

let mapBounds = [(0f, 2000f), (0f, 2000f)]
let seed = some(uint32(42))

# 1. 按地形密度生成树木
let treeDensityFn = proc(p: Point[float32, 2]): float32 =
  getBiomeDensity(p.x, p.y)  # 从生物群系贴图读取密度
let trees = importanceResampling[float32, 2](
    5000, 10, mapBounds, treeDensityFn, seed)

# 2. 用泊松盘确保间距
let spacedTrees = poissonDiskSamplingUniform[float32, 2](
    trees.len, mapBounds, 2f, seed)

# 3. 在聚落附近用高斯聚类放草丛
let villageCenters = @[initPoint([500f, 500f]), initPoint([1200f, 800f])]
let grass = gaussianClusters(villageCenters, 1000, 30f, seed)

# 4. 松弛消除重叠
relaxationKtree(grass, kNeighbors=6, stepSize=1f, iterations=3)

# 5. 用抖动网格放石块（防重复）
let rocks = jitteredGrid[float32, 2](200, mapBounds, seed)

# 6. 质量评估
let treeDensity = localDensityKnn(spacedTrees, 8)
echo "平均树木密度: ", treeDensity.sum / treeDensity.len.float32
```

### ⚔️ ARPG 敌人生成系统

```nim
# 1. 用 Halton 序列均匀分布巡逻路线节点
let patrolNodes = halton[float32, 2](50, mapBounds, seed)

# 2. 用泊松盘确保敌人出生点不重叠
let enemySpawns = poissonDiskSamplingUniform[float32, 2](
    30, mapBounds, 10f, seed)

# 3. 用高斯聚类生成 Boss 身边的小怪集群
let bossRoom = @[initPoint([1000f, 500f])]
let minions = gaussianClusters(bossRoom, 15, 5f, seed)

# 4. 用 DBSCAN 检测卡怪/聚集异常
let labels = dbscanClustering(enemyPositions, eps=1f, minPts=5)
let stuckGroups = extractClusters(enemyPositions, labels)
for group in stuckGroups:
  if group.len > 10:
    warn("敌人在 " & $centroid(group) & " 聚集可能卡地形")
```

### 🌊 河流与植被生态系统

```nim
# 1. 生成河流纤维
let river = randomWalkFilaments[float32, 2](
    2, 100, 3f, mapBounds,
    persistence=0.8f, gaussianSigma=5f, gaussianSamples=10, seed=seed)

# 2. 沿河岸用函数过滤放芦苇
let reedDensity = proc(p: Point[float32, 2]): float32 =
  let dist = minDistanceToRiver(p, river)
  if dist < 10f: 1f - dist / 10f else: 0f
let reeds = rejectionSampling[float32, 2](2000, mapBounds, reedDensity, seed)

# 3. 河岸外侧的树木用泊松盘
let riverTreeMask = proc(p: Point[float32, 2]): float32 =
  let dist = minDistanceToRiver(p, river)
  if dist > 10f and dist < 50f: 1f else: 0f
let riverTrees = functionRejectionFilter(allTrees, riverTreeMask)

# 4. 验证分布
let (r, g) = radialDistribution(riverTrees, mapBounds, 0.5f, 100f)
# 确保近河岸的树木密度合理
```

---

## 模块速查表

| 需求 | 推荐模块 |
|------|---------|
| 完全随机分布 | `random` |
| 均匀覆盖无聚集 | `halton` / `hammersley` |
| 网格化放置 + 自然感 | `jitteredGrid` |
| 参数空间均匀采样 | `latinHypercubeSampling` |
| 自然感非重叠分布 | `poissonDiskSamplingUniform` |
| 密度随位置变化 | `poissonDiskSampling` (带 scaleFn) |
| 大小碎片混合 | `poissonDiskSamplingPowerLaw` |
| 中心密外围疏 | `poissonDiskSamplingWeibull` |
| 围绕中心聚集 | `gaussianClusters` |
| 按密度贴图采样 | `importanceResampling` |
| 按概率保留点 | `rejectionSampling` |
| 生成线状轨迹 | `randomWalkFilaments` |
| 消除重叠 | `distanceRejectionFilter` + `relaxationKtree` |
| 点分组/聚类 | `kmeansClustering` / `dbscanClustering` |
| 连通性分析 | `percolationClustering` |
| 分布质量评估 | `radialDistribution` / `localDensityKnn` |

---

*本文档涵盖 PointSampler (Nim 版) 全部 22 个模块在游戏开发中的典型应用。*
*部分示例代码可直接复制使用，替换占位函数（`getTerrainHeight`、`sampleVolumeDensity` 等）即可。*
