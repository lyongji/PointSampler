## 逾渗聚类 (Percolation Clustering)。
##
## 基于半径连接图的连通分量分析。
## 距离 ≤ connectionRadius 的点视为连接，BFS 遍历标记簇。
## 对应 C++ 版 `ps::percolation_clustering<T,N>()`。

import std/[math, deques, sequtils]
import point
import internal/kdtree

proc percolationClustering*[T; N: static[int]](
    points: openArray[Point[T, N]];
    connectionRadius: T): seq[int] =
  ## 逾渗聚类：标记半径连接图内的连通分量。
  ##
  ## 使用 KD‑tree 加速邻域查询，BFS 遍历各连通分量。
  ##
  ## - `points` — 输入点集
  ## - `connectionRadius` — 连接半径
  ##
  ## 返回标签数组（标签 ≥ 0 为簇 ID，-1 表示孤立点）。
  ##
  ## 示例:
  ## ```nim
  ## let labels = percolationClustering(pts, 0.1)
  ## ```
  if points.len == 0: return
  result = repeat(-1, points.len)
  let tree = initKDTree(points)
  var currentCluster = 0
  let rSq = connectionRadius * connectionRadius
  for i in 0 ..< points.len:
    if result[i] != -1: continue
    var q = initDeque[int]()
    q.addLast(i)
    result[i] = currentCluster
    while q.len > 0:
      let pIdx = q.popFirst()
      let nbrs = radiusSearch(tree, points[pIdx], rSq)
      for nb in nbrs:
        if result[nb] == -1:
          result[nb] = currentCluster
          q.addLast(nb)
    currentCluster.inc
