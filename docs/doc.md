# PointSampler — N 维点采样库（中文文档）

## 概述

PointSampler 是一个轻量级的 N 维点采样库，纯 Nim 实现，无外部依赖。

```nim
import point_sampler
```

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

---

## API

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

## 用法示例

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

---

## 构建

```bash
# 编译库
nim c point_sampler.nim

# 运行全部测试
nim c -r tests/tester.nim

# 运行单个测试
nim c -r tests/tpoint.nim
```

---

## 许可证

GNU General Public License v2.0（与原始 C++ 库一致）。
