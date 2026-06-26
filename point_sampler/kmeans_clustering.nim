## K‑means 聚类。
##
## 实现 Lloyd 算法（k‑means++ 初始化），对 N 维点集进行聚类。
## 对应 C++ 版 `ps::kmeans_clustering<T,N>()`。

import std/[math, random]
import point, utils

proc kmeansClustering*[T; N: static[int]](
    points: openArray[Point[T, N]];
    kClusters: int;
    normalizeData: bool = true;
    maxIterations: int = 100): tuple[centroids: seq[Point[T, N]],
                                     labels: seq[int]] =
  ## 对点集执行 k‑means 聚类。
  ##
  ## 使用 k‑means++ 初始化策略选取初始簇中心，
  ## Lloyd 迭代直至收敛或达到最大迭代次数。
  ##
  ## - `points` — 输入点集
  ## - `kClusters` — 簇数量
  ## - `normalizeData` — 是否在聚类前归一化各轴到 [0,1]
  ## - `maxIterations` — 最大迭代次数
  ##
  ## 返回 `(centroids, labels)`，其中 `labels[i]` 是点 i 所属的簇索引。
  ##
  ## 示例:
  ## ```nim
  ## let (centroids, labels) = kmeansClustering(pts, 3)
  ## ```
  if points.len == 0: return
  var data = @points
  if normalizeData:
    normalizePoints(data)
  # k‑means++ 初始化
  var rng = initRand()
  var centroids = newSeq[Point[T, N]](kClusters)
  centroids[0] = data[rng.rand(data.high)]
  for k in 1 ..< kClusters:
    var distSq = newSeq[T](data.len)
    var total: T = 0
    for i, p in data:
      var minD = high(T)
      for c in 0 ..< k:
        minD = min(minD, distanceSquared(p, centroids[c]))
      distSq[i] = minD; total += minD
    var r = rng.rand(1.0).T * total
    var idx = 0; var acc: T = 0
    while idx < data.high and acc < r:
      acc += distSq[idx]; idx.inc
    centroids[k] = data[idx]
  result.labels = newSeq[int](data.len)
  for iteration in 0 ..< maxIterations:
    var changed = false
    for i, p in data:
      var bestIdx = 0
      var bestDist = distanceSquared(p, centroids[0])
      for k in 1 ..< kClusters:
        let d = distanceSquared(p, centroids[k])
        if d < bestDist: bestDist = d; bestIdx = k
      if result.labels[i] != bestIdx:
        result.labels[i] = bestIdx; changed = true
    if not changed: break
    var sums = newSeq[Point[T, N]](kClusters)
    var counts = newSeq[int](kClusters)
    for i, p in data:
      let k = result.labels[i]; sums[k] = sums[k] + p; counts[k].inc
    for k in 0 ..< kClusters:
      if counts[k] > 0: centroids[k] = sums[k] / counts[k].T
  result.centroids = centroids
