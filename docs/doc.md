# PointSampler — N 维点采样库（中文文档）

## 概述

PointSampler 是一个轻量级的 N 维点采样库，提供多种采样算法、过滤器和聚类工具。项目同时提供两套后端：

- **纯 Nim 版** (`point_sampler.nim`)：纯 Nim 实现，无外部依赖
- **C++ 绑定版** (`point_sampler_c.nim`)：基于 Futhark 生成的 C++ 绑定，复用原始 C++ 库

两种后端共享同一个 `Point[T, N]` 类型定义。

---

## 类型系统

### Point[T, N]

核心数据类型，表示 N 维空间中的一个点。

```nim
type
  Point*[T; N: static[int]] = object
    coords*: array[N, T]
```

- `T` — 坐标类型（`float32` 或 `float64`）
- `N` — 编译期维度常量（2, 3, ...）

**几何函数**：`distance`, `length`, `lengthSquared`, `dot`, `normalized`, `lerp`, `clamp`

**快捷访问器**：`.x`, `.y`, `.z`, `.w`（分别对应 `coords[0]` 到 `coords[3]`）

### 领域类型（C++ 绑定版）

```nim
KMeansResult*[T; N] = object     # K-means 聚类结果
  centroids*: seq[Point[T, N]]
  labels*: seq[int]
DbscanResult* = object           # DBSCAN 聚类结果
  labels*: seq[int]
```

---

## 纯 Nim 版 API

### 导入

```nim
import point_sampler
```

所有函数使用 `[T; N: static[int]]` 泛型，需要显式指定类型和维度。

### 采样

```nim
proc random[T; N](count: int; axisRanges: array[N, (T, T)];
                  seed: Option[uint32] = none[uint32]()): seq[Point[T, N]]

proc halton[T; N](count: int; axisRanges: array[N, (T, T)];
                  seed: Option[uint32] = none[uint32]()): seq[Point[T, N]]

proc hammersley[T; N](count: int; axisRanges: array[N, (T, T)]): seq[Point[T, N]]

proc jitteredGrid[T; N](count: int; axisRanges: array[N, (T, T)];
                        jitterAmount: T = 1.0): seq[Point[T, N]]

proc latinHypercubeSampling[T; N](count: int; axisRanges: array[N, (T, T)]): seq[Point[T, N]]

proc gaussianClusters[T; N](count: int; axisRanges: array[N, (T, T)];
                            nClusters: int; clusterStd: T): seq[Point[T, N]]
```

### 泊松盘采样（5 种变体）

```nim
proc poissonDiskSampling[T; N](count: int; axisRanges: array[N, (T, T)];
    baseMinDist: T; scaleFn: proc(p: Point[T, N]): T;
    seed: Option[uint32] = none[uint32](); newPointsAttempts: int = 30): seq[Point[T, N]]

proc poissonDiskSamplingUniform[T; N](...): seq[Point[T, N]]

proc poissonDiskSamplingDistanceDistribution[T; N; R](...): seq[Point[T, N]]

proc poissonDiskSamplingPowerLaw[T; N](...): seq[Point[T, N]]

proc poissonDiskSamplingWeibull[T; N](...): seq[Point[T, N]]   # 两个重载
```

### 过滤

```nim
proc filterPointsInRange[T; N](points: openArray[Point[T, N]];
    axisRanges: array[N, (T, T)]): seq[Point[T, N]]

proc functionRejectionFilter[T; N](points: openArray[Point[T, N]];
    fn: proc(p: Point[T, N]): T): seq[Point[T, N]]

proc randomRejectionFilter[T; N](points: openArray[Point[T, N]];
    keepFraction: T): seq[Point[T, N]]

proc distanceRejectionFilter[T; N](points: openArray[Point[T, N]];
    minDist: T): seq[Point[T, N]]
```

### 聚类

```nim
proc kmeansClustering[T; N](points: openArray[Point[T, N]];
    k: int): seq[int]

proc dbscanClustering[T; N](points: openArray[Point[T, N]];
    eps: T; minPts: int): seq[int]

proc percolationClustering[T; N](points: openArray[Point[T, N]];
    radius: T; minPoints: int): seq[int]
```

### 度量

```nim
proc nearestNeighborsIndices[T; N](points: openArray[Point[T, N]];
    kNeighbors: int = 8): seq[seq[int]]

proc localDensityKnn[T; N](points: openArray[Point[T, N]];
    k: int = 8): seq[T]

proc radialDistribution[T; N](points: openArray[Point[T, N]];
    axisRanges: array[N, (T, T)]; binWidth, maxDistance: T): (seq[T], seq[T])

proc angleDistributionNeighbors[T; N](points: openArray[Point[T, N]];
    binWidth: T; kNeighbors: int = 8): (seq[T], seq[T])
```

### 工具

```nim
proc savePointsToCsv[T; N](filename: string; points: openArray[Point[T, N]];
    writeHeader: bool = true): bool

proc normalizePoints[T; N](points: var seq[Point[T, N]])

proc splitByDimension[T; N](points: openArray[Point[T, N]]): array[N, seq[T]]

proc mergeByDimension[T; N](components: array[N, seq[T]]): seq[Point[T, N]]

proc addDimension[T; N](points: openArray[Point[T, N]];
    newDimension: seq[T]): seq[Point[T, N + 1]]
```

---

## C++ 绑定版 API

### 导入

```nim
import point_sampler_c
```

**不需要显式指定 `[T, N]`** — 默认使用 `float`（=float64），N 由 ranges 数组长度自动推断。

### 采样

```nim
proc random*(axisRanges: array[N, (T, T)]; count: Positive;
             seed: Option[uint32] = none[uint32]()): seq[Point[T, N]]

proc halton*(axisRanges: array[N, (T, T)]; count: Positive;
             seed: Option[uint32] = none[uint32]()): seq[Point[T, N]]

proc hammersley*(axisRanges: array[N, (T, T)]; count: Positive): seq[Point[T, N]]
```

### 泊松盘

```nim
proc poissonDiskUniform*(axisRanges: array[N, (T, T)]; count: Positive;
    minDist: T): seq[Point[T, N]]
```

### 过滤

```nim
proc filterInRange*(points: openArray[Point[T, N]];
    axisRanges: array[N, (T, T)]): seq[Point[T, N]]

proc distanceReject*(points: openArray[Point[T, N]];
    minDist: T): seq[Point[T, N]]
```

### 聚类

```nim
proc dbscanClustering*(points: openArray[Point[T, N]]; eps: T;
    minPts: Positive): DbscanResult

proc kmeansClustering*(points: openArray[Point[T, N]]; k: Positive;
    maxIterations: Positive = 100): KMeansResult[T, N]
```

### 命名结果类型

```nim
type
  DbscanResult* = object
    labels*: seq[int]      # 每个点的簇标签（-1 = 噪声）

  KMeansResult*[T; N] = object
    centroids*: seq[Point[T, N]]   # 簇中心
    labels*: seq[int]              # 每个点的簇标签
```

---

## 用法示例

### 纯 Nim 版

```nim
import point_sampler

# 2D 均匀随机点（1000 个，范围 [0,1]²）
let pts = random[float, 2](1000, [(0.0, 1.0), (0.0, 1.0)])

# 泊松盘采样（500 个，最小间距 0.03）
let poisson = poissonDiskSamplingUniform[float, 2](
  500, [(0.0, 1.0), (0.0, 1.0)], 0.03)

# DBSCAN 聚类
let labels = dbscanClustering(pts, 0.05, 5)

# 保存到 CSV
discard savePointsToCsv("output.csv", pts)
```

### C++ 绑定版

```nim
import point_sampler_c

# 2D 均匀随机点（1000 个，范围 [0,1]²）
let pts = random([(0.0, 1.0), (0.0, 1.0)], 1000)

# 可重现种子
let pts2 = random([(0.0, 1.0), (0.0, 1.0)], 100, seed = some(uint32(42)))

# 泊松盘采样
let pp = poissonDiskUniform([(0.0, 1.0), (0.0, 1.0)], 500, 0.03)

# 范围过滤
let filtered = filterInRange(pts, [(0.25, 0.75), (0.25, 0.75)])

# DBSCAN 聚类
let dr = dbscanClustering(pts, 0.05, 5)
echo "簇数量: ", dr.labels.deduplicate().len

# K-means 聚类
let kr = kmeansClustering(pts, 10)
echo "簇中心: ", kr.centroids
```

---

## 构建说明

### 纯 Nim 版

```bash
# 编译库
nim c point_sampler.nim

# 运行全部测试
nim c -r tests/tester.nim

# 运行单个测试
nim c -r tests/tpoint.nim
```

### C++ 绑定版

依赖：C++ 编译器（g++、clang++ 等）、libstdc++。

```bash
# 运行测试
nim c -r tests/tpoint_sampler_c.nim

# 重新生成 Futhark 绑定（仅 C API 变更时需要）
nim c -r src/bindings/generate_bindings.nim
```

Futhark 生成步骤（仅首次或 C API 变更时需要）：
1. 安装 Clang（含 libclang）：`apt install clang libclang-dev`
2. 安装 Futhark：`nimble install futhark`
3. 运行生成脚本：`nim c -r src/bindings/generate_bindings.nim`

生成的 `ps_c_api_gen.nim` 已提交到仓库，用户不需要 Futhark 即可编译。

---

## 后端选择指南

| 场景 | 推荐后端 |
|------|---------|
| 纯 Nim 项目，无 C++ 工具链 | 纯 Nim 版 |
| 需要最大兼容性 | 纯 Nim 版 |
| 使用 float32 优化内存 | 纯 Nim 版（`[float32, N]`） |
| 与原始 C++ 库结果对比 | C++ 绑定版 |
| 需要完整泊松盘变体 | 纯 Nim 版（5 种） |
| 简单采样任务 | C++ 绑定版（语法更简洁） |

---

## 许可证

GNU General Public License v2.0（与原始 C++ 库一致）。
