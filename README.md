# PointSampler — N 维点采样库

> 轻量级 N 维点采样库，纯 Nim 实现，无外部依赖。
>
> 原始 C++ 版本: [otto-link/PointSampler](https://github.com/otto-link/PointSampler)

## 项目结构

```
PointSampler/
├── point_sampler.nim          # 入口（导出全部）
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
│       ├── kdtree.nim                # 内置 KD-tree
│       └── primes.nim               # 共享质数列表
├── tests/
│   ├── tester.nim              # 测试运行器（自动发现 t*.nim）
│   ├── tpoint.nim / trandom.nim / …  # 模块测试
│   └── config.nims
└── docs/
    ├── doc.md                  # 中文文档
    └── images/                 # 采样可视化（SVG，可用 examples/generate_images.nim 重新生成）
```

## 快速开始

```bash
nim c -r tests/tester.nim
```

```nim
import point_sampler

let pts = random[float, 2](1000, [(0.0, 1.0), (0.0, 1.0)])
let labels = dbscanClustering(pts, 0.05, 5)
```

## API 一览

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
```

共 11 个测试文件，113 个 block 级测试用例，覆盖所有模块。

## 重新生成文档图片

```bash
nim c -r examples/generate_images.nim
```

docs/images/ 下的 SVG 可视化图片均可通过该脚本重新生成。

| 模式 | 溢出检查 | 堆栈跟踪 |
|------|---------|---------|
| default / debug | 是 | 完整 |
| `-d:release` | 是 | 仅抛出帧 |
| `-d:danger` | 否 | 仅抛出帧 |
