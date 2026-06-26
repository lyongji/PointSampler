## 高斯聚类 (Gaussian Clusters)。
##
## 围绕指定或随机生成的簇中心，用高斯分布散布点。
## 对应 C++ 版 `ps::gaussian_clusters<T,N>()`。

import std/[random, options]
import point, random

proc gaussianClusters*[T; N: static[int]](
    clusterCenters: openArray[Point[T, N]];
    pointsPerCluster: int; spread: T;
    seed: Option[uint32] = none[uint32]()): seq[Point[T, N]] =
  ## 围绕指定簇中心生成高斯散布点。
  ##
  ## - `clusterCenters` — 簇中心列表
  ## - `pointsPerCluster` — 每簇点数
  ## - `spread` — 高斯分布标准差
  ## - `seed` — 可选随机种子
  ##
  ## 示例:
  ## ```nim
  ## let centers = @[initPoint[float, 2]([0.2, 0.2]),
  ##                 initPoint[float, 2]([0.8, 0.8])]
  ## let pts = gaussianClusters(centers, 100, 0.05)
  ## ```
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  result = newSeqOfCap[Point[T, N]](clusterCenters.len * pointsPerCluster)
  for c in clusterCenters:
    for _ in 0 ..< pointsPerCluster:
      var p: Point[T, N]
      for d in 0 ..< N:
        p[d] = c[d] + rng.gauss(0.0.T, spread)
      result.add p

proc gaussianClusters*[T; N: static[int]](
    clusterCount, pointsPerCluster: int;
    axisRanges: array[N, (T, T)]; spread: T;
    seed: Option[uint32] = none[uint32]()): seq[Point[T, N]] =
  ## 在轴对齐包围盒内随机生成簇中心，然后生成高斯散布点。
  ##
  ## - `clusterCount` — 簇数量
  ## - `pointsPerCluster` — 每簇点数
  ## - `axisRanges` — 簇中心采样范围
  ## - `spread` — 高斯分布标准差
  ## - `seed` — 可选随机种子
  let centers = random.random[T, N](clusterCount, axisRanges, seed)
  result = gaussianClusters(centers, pointsPerCluster, spread, seed)
