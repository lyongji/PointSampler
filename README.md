# PointSampler — N 维点采样库

> 轻量级 N 维点采样库。提供两种后端：
> - **纯 Nim 移植版** — `point_sampler`，无外部依赖
> - **C++ 绑定版** — `point_sampler_c`，基于原始 C++ 库（Futhark 绑定）
>
> 原始 C++ 版本: [otto-link/PointSampler](https://github.com/otto-link/PointSampler)

## 项目结构

```
PointSampler/
├── point_sampler.nim          # 入口：纯 Nim 后端
├── point_sampler_c.nim        # 入口：C++ 绑定后端（基于 Futhark）
├── point_sampler/              # 纯 Nim 实现
│   ├── point.nim              # Point[T, N] 类型 + 几何运算
│   ├── random.nim             # 均匀随机点生成
│   ├── range.nim              # 范围/函数过滤、重映射、缩放
│   ├── halton.nim             # Halton 序列
│   ├── hammersley.nim         # Hammersley 序列
│   ├── jittered_grid.nim      # 抖动网格
│   ├── latin_hypercube_sampling.nim  # 拉丁超立方
│   ├── gaussian_clusters.nim  # 高斯簇
│   ├── importance_resampling.nim     # 重要性重采样
│   ├── rejection_sampling.nim        # 拒绝采样
│   ├── function_rejection_filter.nim # 概率过滤
│   ├── random_rejection_filter.nim   # 随机下采样
│   ├── distance_rejection_filter.nim # 距离拒绝
│   ├── random_walk_filaments.nim     # 随机游走纤维
│   ├── poisson_disk_sampling.nim     # 泊松盘（5 种变体）
│   ├── relaxation.nim                # K-近邻松弛
│   ├── kmeans_clustering.nim         # K-means
│   ├── dbscan_clustering.nim         # DBSCAN
│   ├── percolation_clustering.nim    # 逾渗聚类
│   ├── metrics.nim                   # 空间度量
│   ├── utils.nim                     # CSV/维度操作
│   └── internal/
│       └── kdtree.nim                # 内置 KD-tree
├── c_api/                      # C++ 包装层（point_sampler_c 用）
│   ├── ps_c_api.h
│   ├── ps_c_api.cpp
│   └── ps_c_api.h
├── src/bindings/               # Futhark 绑定生成
│   ├── generate_bindings.nim   # 重新生成脚本
│   └── ps_c_api_gen.nim        # 自动生成的 C 导入（不手动编辑）
├── tests/
│   ├── tester.nim              # 纯 Nim 测试运行器
│   ├── tpoint_sampler_c.nim    # C++ 绑定版测试（11 用例）
│   ├── tpoint.nim / trandom.nim / …  # 纯 Nim 模块测试
│   └── config.nims
└── docs/
    ├── doc.md                  # 中文文档
    └── images/                 # 采样可视化
```

## 快速开始

### 纯 Nim 版（无外部依赖）

```bash
nim c -r tests/tester.nim
```

```nim
import point_sampler

let pts = random[float, 2](1000, [(0.0, 1.0), (0.0, 1.0)])
let labels = dbscanClustering(pts, 0.05, 5)
```

### C++ 绑定版（需要 C++ 编译器）

```bash
nim c -r tests/tpoint_sampler_c.nim
```

```nim
import point_sampler_c

let pts = random([(0.0, 1.0), (0.0, 1.0)], 1000)
let pp  = poissonDiskUniform([(0.0, 1.0), (0.0, 1.0)], 500, 0.03)
let km  = kmeansClustering(pts, 10)
echo km.centroids
```

## 后端对比

| 特性 | 纯 Nim 版 `point_sampler` | C++ 绑定版 `point_sampler_c` |
|------|--------------------------|------------------------------|
| 外部依赖 | 无 | C++ 编译器、libstdc++、Clang（仅生成期） |
| 精度控制 | `[T, N]` 泛型任意浮点 | `float`（默认）或 `float32` |
| 语法 | `random[float, 2](gen)` | `random(gen)` |
| 泊松盘变体 | 全部 5 种 | 均匀泊松盘 |
| 性能 | 纯 Nim 编译 | 调用 C++ 后端 |
| 平台 | 任何 Nim 支持的平台 | 需 C++ 工具链 |

## 纯 Nim 版 API

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
| **过滤** | `distanceRejectionFilter[T, N]()` | 距离拒绝 |
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

## C++ 绑定版 API

| 函数 | 返回 | 说明 |
|------|------|------|
| `random(axisRanges, count, seed?)` | `seq[Point[T, N]]` | 均匀随机采样 |
| `halton(axisRanges, count, seed?)` | `seq[Point[T, N]]` | Halton 准随机 |
| `hammersley(axisRanges, count)` | `seq[Point[T, N]]` | Hammersley 准随机 |
| `poissonDiskUniform(axisRanges, count, minDist)` | `seq[Point[T, N]]` | 均匀泊松盘 |
| `filterInRange(points, axisRanges)` | `seq[Point[T, N]]` | 范围过滤 |
| `distanceReject(points, minDist)` | `seq[Point[T, N]]` | 贪心距离拒绝 |
| `dbscanClustering(points, eps, minPts)` | `DbscanResult` | DBSCAN 聚类 |
| `kmeansClustering(points, k, maxIterations?)` | `KMeansResult[T, N]` | K-means 聚类 |

## 测试

测试框架自动发现 `tests/t*.nim` 文件。

```bash
# 全部测试（默认 debug）
nim c -r tests/tester.nim

# 多模式运行
nim c -d:release -r tests/tester.nim
nim c -d:danger -r tests/tester.nim

# 单个测试文件
nim c -r tests/tpoint.nim
nim c -r tests/tpoint_sampler_c.nim
```

共 12 个测试文件，100+ 个 block 级测试用例，覆盖所有模块。

| 模式 | 溢出检查 | 堆栈跟踪 |
|------|---------|---------|
| default / debug | 是 | 完整 |
| `-d:release` | 是 | 仅抛出帧 |
| `-d:danger` | 否 | 仅抛出帧 |
