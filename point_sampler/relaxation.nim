## K‑近邻松弛 (Relaxation)。
##
## 使用 KD‑tree 加速的 k‑近邻排斥算法，使点分布更均匀。
## 对应 C++ 版 `ps::relaxation_ktree<T,N>()`。

import std/[math]
import point
import internal/kdtree

proc relaxationKtree*[T; N: static[int]](
    points: var seq[Point[T, N]];
    kNeighbors: int = 8;
    stepSize: T = 0.1.T;
    iterations: int = 10) =
  ## 通过 k‑近邻排斥松弛点集，减少聚类，产生更均匀的分布。
  ##
  ## 每次迭代：
  ## 1. 为每个点找到 k 个最近邻
  ## 2. 根据反距离加权的排斥向量计算偏移
  ## 3. 沿归化偏移方向移动 `stepSize` 距离
  ##
  ## - `points` — 输入/输出点集（原地修改）
  ## - `kNeighbors` — 近邻数量，默认 8
  ## - `stepSize` — 每步移动距离，默认 0.1
  ## - `iterations` — 松弛迭代次数，默认 10
  ##
  ## 示例:
  ## ```nim
  ## relaxationKtree(pts, kNeighbors=8, stepSize=0.1, iterations=10)
  ## ```
  for iter in 0 ..< iterations:
    let tree = initKDTree(points)
    var newPts = newSeqOfCap[Point[T, N]](points.len)
    for i, p in points:
      let nbrs = kNearestNeighbors(tree, p, kNeighbors + 1)
      var offset: Point[T, N]
      var count = 0
      for (j, dSq) in nbrs:
        if j == i: continue
        let delta = p - points[j]
        let distSq = max(dSq, T(1e-6))
        offset = offset + delta / distSq
        count.inc
      if count > 0:
        let norm = length(offset)
        if norm > 0:
          newPts.add(p + normalized(offset) * stepSize)
        else:
          newPts.add(p)
      else:
        newPts.add(p)
    points = newPts
