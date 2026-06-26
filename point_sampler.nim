## PointSampler — N 维点采样库 (Nim 移植版)。
##
## PointSampler 是一个轻量级的 N 维点采样库，提供多种算法：
## - **随机采样**: 均匀随机、Halton、Hammersley、抖动网格、拉丁超立方
## - **基于密度的采样**: 泊松盘（5 种变体）、高斯聚类、重要性重采样、拒绝采样
## - **过滤**: 距离拒绝、函数拒绝、随机拒绝
## - **聚类**: K‑means、DBSCAN、逾渗聚类
## - **松弛**: K‑近邻排斥松弛
## - **度量和工具**: 最近邻、局部密度、RDF/ADF、CSV 读写、维度操作
##
## 对应 C++ 版 [PointSampler](https://github.com/otto-link/PointSampler)。
##
## 项目结构
## ============
##
## ```
## point_sampler.nim          ← 入口（导出全部）
## point_sampler/
##   point.nim                 Point[T, N] + 几何运算
##   random.nim                均匀随机点
##   range.nim                 范围/函数过滤、重映射
##   halton.nim                 Halton 序列
##   hammersley.nim             Hammersley 序列
##   jittered_grid.nim         抖动网格
##   latin_hypercube_sampling.nim  拉丁超立方
##   gaussian_clusters.nim     高斯簇
##   importance_resampling.nim 重要性重采样
##   rejection_sampling.nim    拒绝采样
##   function_rejection_filter.nim  概率过滤
##   random_rejection_filter.nim    随机下采样
##   distance_rejection_filter.nim  距离过滤
##   random_walk_filaments.nim 随机游走纤维
##   poisson_disk_sampling.nim 泊松盘（5 种）
##   relaxation.nim            K-近邻松弛
##   kmeans_clustering.nim     K-means
##   dbscan_clustering.nim     DBSCAN
##   percolation_clustering.nim  逾渗
##   metrics.nim               空间度量
##   utils.nim                 CSV/维度操作
##   internal/
##     kdtree.nim              内置 KD-tree
## ```
##
## 泛型参数
## ==========
## 所有函数使用 `[T; N: static[int]]` —
## - `T`: 坐标类型（`float`, `float64`, `float32`）
## - `N`: 编译期维度常量（2, 3, ...）
##
## 使用示例
## ==========
## ```nim
## import point_sampler
##
## # 10 个 2D 均匀随机点
## let pts = random[float, 2](10, [(0.0, 1.0), (0.0, 1.0)])
##
## # 泊松盘采样
## let pp = poissonDiskSamplingUniform[float, 2](
##   200, [(0.0, 1.0), (0.0, 1.0)], 0.05)
##
## # DBSCAN 聚类
## let labels = dbscanClustering(pts, 0.1, 3)
## ```

import point_sampler/point
import point_sampler/utils
import point_sampler/random
import point_sampler/range
import point_sampler/halton
import point_sampler/hammersley
import point_sampler/jittered_grid
import point_sampler/latin_hypercube_sampling
import point_sampler/gaussian_clusters
import point_sampler/importance_resampling
import point_sampler/rejection_sampling
import point_sampler/function_rejection_filter
import point_sampler/random_rejection_filter
import point_sampler/distance_rejection_filter
import point_sampler/random_walk_filaments
import point_sampler/poisson_disk_sampling
import point_sampler/relaxation
import point_sampler/kmeans_clustering
import point_sampler/dbscan_clustering
import point_sampler/percolation_clustering
import point_sampler/metrics

export point, utils, random, range, halton, hammersley,
       jittered_grid, latin_hypercube_sampling,
       gaussian_clusters, importance_resampling,
       rejection_sampling, function_rejection_filter,
       random_rejection_filter, distance_rejection_filter,
       random_walk_filaments, poisson_disk_sampling, relaxation,
       kmeans_clustering, dbscan_clustering, percolation_clustering,
       metrics
