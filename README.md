# PointSampler — Nim 移植版

> 轻量级 N 维点采样库，纯 Nim 实现。  
> 原始 C++ 版本: [otto-link/PointSampler](https://github.com/otto-link/PointSampler)

## 项目结构

```
PointSampler/
├── point_sampler.nim          # 入口模块，导出全部子模块
├── point_sampler/
│   ├── point.nim              # Point[T, N] 类型 + 算术/几何运算
│   ├── random.nim             # 均匀随机点生成
│   ├── range.nim              # 范围过滤、函数过滤、重映射、缩放
│   ├── halton.nim             # Halton 准随机序列
│   ├── hammersley.nim         # Hammersley 准随机序列
│   ├── jittered_grid.nim      # 抖动网格采样
│   ├── latin_hypercube_sampling.nim  # 拉丁超立方采样
│   ├── gaussian_clusters.nim  # 高斯聚类
│   ├── importance_resampling.nim     # 重要性重采样
│   ├── rejection_sampling.nim        # 拒绝采样
│   ├── function_rejection_filter.nim # 概率密度过滤
│   ├── random_rejection_filter.nim   # 随机下采样
│   ├── distance_rejection_filter.nim # 距离拒绝过滤
│   ├── random_walk_filaments.nim     # 随机游走纤维
│   ├── poisson_disk_sampling.nim     # 泊松盘采样（5 种变体）
│   ├── relaxation.nim                # K-近邻松弛
│   ├── kmeans_clustering.nim         # K-means 聚类
│   ├── dbscan_clustering.nim         # DBSCAN 聚类
│   ├── percolation_clustering.nim    # 逾渗聚类
│   ├── metrics.nim                   # 空间度量工具
│   ├── utils.nim                     # 工具函数（CSV、维度操作）
│   └── internal/
│       └── kdtree.nim                # 内置 KD-tree（替代 nanoflann）
├── tests/
│   ├── config.nims            # 编译器配置
│   ├── tester.nim             # 自动发现测试运行器
│   ├── tpoint.nim             # Point 类型测试（24 个用例）
│   ├── trandom.nim            # 随机生成测试
│   ├── trange.nim             # 范围操作测试
│   ├── tquasi.nim             # Halton/Hammersley 测试
│   ├── tfilters.nim           # 过滤功能测试
│   ├── tpoisson.nim           # 泊松盘测试（5 变体）
│   ├── tsampling.nim          # 网格/LHS/高斯/游走/松弛测试
│   ├── tresampling.nim        # 拒绝/重要性重采样测试
│   ├── tclustering.nim        # 聚类测试（K-means/DBSCAN/逾渗）
│   ├── tmetrics.nim           # 空间度量测试
│   └── tutils.nim             # 工具函数测试
└── docs/
    └── images/                # 采样结果可视化图片
```

## 快速开始

```bash
# 编译库
nim c point_sampler.nim

# 运行测试
nim c -r tests/tester.nim

# 在项目中使用
import point_sampler
```

## 模块依赖图

```
point_sampler.nim
  ├── point.nim          ← 基础类型（所有模块依赖）
  ├── utils.nim          ← 依赖 point
  ├── random.nim         ← 依赖 point
  ├── range.nim          ← 依赖 point
  ├── halton.nim         ← 依赖 point, range
  ├── hammersley.nim     ← 依赖 point, range
  ├── jittered_grid.nim  ← 依赖 point
  ├── latin_hypercube_sampling.nim ← 依赖 point
  ├── gaussian_clusters.nim ← depend point, random
  ├── importance_resampling.nim ← depend point, halton
  ├── rejection_sampling.nim ← depend point, function_rejection_filter
  ├── function_rejection_filter.nim ← 依赖 point
  ├── random_rejection_filter.nim ← 依赖 point
  ├── distance_rejection_filter.nim ← 依赖 point, internal/kdtree
  ├── random_walk_filaments.nim ← 依赖 point
  ├── poisson_disk_sampling.nim ← 依赖 point
  ├── relaxation.nim ← 依赖 point, internal/kdtree
  ├── kmeans_clustering.nim ← 依赖 point, utils
  ├── dbscan_clustering.nim ← 依赖 point, internal/kdtree
  ├── percolation_clustering.nim ← 依赖 point, internal/kdtree
  └── metrics.nim ← 依赖 point, internal/kdtree
```

## API 速览

所有函数均为 N 维泛型 `proc[T; N: static[int]](...)`。

| 类别 | 函数 | 说明 |
|------|------|------|
| **基础** | `initPoint[T, N]()` | 创建点 |
| | `distance`, `length`, `dot`, `normalized`, `lerp`, `clamp` | 几何运算 |
| **采样** | `random[T, N]()` | 均匀随机 |
| | `halton[T, N]()` | Halton 准随机 |
| | `hammersley[T, N]()` | Hammersley 准随机 |
| | `jitteredGrid[T, N]()` | 抖动网格 |
| | `latinHypercubeSampling[T, N]()` | 拉丁超立方 |
| | `gaussianClusters[T, N]()` | 高斯聚类 |
| | `poissonDiskSampling*[T, N]()` | 泊松盘（5 变体） |
| | `importanceResampling[T, N]()` | 重要性重采样 |
| | `rejectionSampling[T, N]()` | 拒绝采样 |
| | `randomWalkFilaments[T, N]()` | 随机游走纤维 |
| **过滤** | `distanceRejectionFilter[T, N]()` | 距离拒绝（含 warped） |
| | `functionRejectionFilter[T, N]()` | 概率函数过滤 |
| | `randomRejectionFilter[T, N]()` | 随机下采样 |
| | `filterPointsInRange[T, N]()` | 范围过滤 |
| **松弛** | `relaxationKtree[T, N]()` | K-近邻排斥松弛 |
| **聚类** | `kmeansClustering[T, N]()` | K-means |
| | `dbscanClustering[T, N]()` | DBSCAN |
| | `percolationClustering[T, N]()` | 逾渗聚类 |
| **度量** | `nearestNeighborsIndices[T, N]()` | K 近邻索引 |
| | `localDensityKnn[T, N]()` | 局部密度估计 |
| | `radialDistribution[T, N]()` | 径向分布函数 g(r) |
| | `angleDistributionNeighbors[T, N]()` | 角分布函数 |
| | `distanceToBoundary[T, N]()` | 边界距离 |
| **工具** | `savePointsToCsv[T, N]()` | CSV 导出 |
| | `normalizePoints[T, N]()` | 坐标归一化 |
| | `splitByDimension`, `mergeByDimension` | 维度拆分/合并 |
| | `addDimension[T, N]()` | 追加维度 |
| | `extractClusters[T, N]()` | 从标签提取簇 |

## 用法示例

```nim
import point_sampler

# 2D 均匀随机点
let pts = random[float, 2](1000, [(0.0, 1.0), (0.0, 1.0)], some(uint32(42)))

# 泊松盘采样
let poisson = poissonDiskSamplingUniform[float, 2](
  500, [(0.0, 1.0), (0.0, 1.0)], 0.03, some(uint32(42)))

# DBSCAN 聚类
let labels = dbscanClustering(pts, 0.05, 5)

# 局部密度
let densities = localDensityKnn(pts, 8)

# 保存到 CSV
discard savePointsToCsv("output.csv", pts)
```

## C++ 版对照

| C++ `ps::` | Nim | 差异 |
|-----------|-----|------|
| `Point<T,N>` | `Point[T, N]` | 同 |
| `random<T,N>()` | `random[T, N]()` | 命名风格 `camelCase` |
| `std::optional` | `Option[uint32]` | Nim `std/options` |
| `std::mt19937` | `Rand` | Nim `std/random` |
| `std::array<std::pair<T,T>,N>` | `array[N, (T, T)]` | 同 |
| `nanoflann` KD-tree | `internal/kdtree.nim` | 内置最小实现 |
| `dkm` k-means | 内嵌实现 | k-means++ 初始化 |

## 测试

```bash
# 全部测试
nim c -r tests/tester.nim

# 单个测试
nim c -r tests/tpoint.nim
nim c -r tests/tpoisson.nim
```

共 11 个测试文件，90+ 个测试用例，覆盖所有模块。
