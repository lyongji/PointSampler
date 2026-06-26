## DBSCAN 聚类 (Density-Based Spatial Clustering)。
##
## 基于密度的空间聚类算法，使用 KD‑tree 加速邻域查询。
## 识别任意形状的簇并标记噪声点。
## 对应 C++ 版 `ps::dbscan_clustering<T,N>()`。

import std/[math, algorithm, sequtils]
import point
import internal/kdtree

proc dbscanClustering*[T; N: static[int]](
    points: openArray[Point[T, N]];
    eps: T; minPts: int): seq[int] =
  ## DBSCAN 聚类，返回标签数组。
  ##
  ## - 标签 ≥ 0: 簇 ID
  ## - 标签 = -1: 噪声点
  ##
  ## 核心点: 半径 `eps` 内至少有 `minPts` 个邻居。
  ## 簇由核心点的密度连通区域扩展形成。
  ##
  ## - `points` — 输入点集
  ## - `eps` — 邻域半径
  ## - `minPts` — 核心点所需的最小邻居数（含自身）
  ##
  ## 示例:
  ## ```nim
  ## let labels = dbscanClustering(pts, 0.05, 5)
  ## ```
  if points.len == 0: return
  result = repeat(-1, points.len)
  let tree = initKDTree(points)
  var clusterId = -1
  for i in 0 ..< points.len:
    if result[i] != -1: continue
    let epsSq = eps * eps
    var seedSet = radiusSearch(tree, points[i], epsSq)
    if seedSet.len + 1 < minPts:
      result[i] = -2; continue
    clusterId.inc; result[i] = clusterId
    var j = 0
    while j < seedSet.len:
      let nbIdx = seedSet[j]
      if result[nbIdx] == -2:
        result[nbIdx] = clusterId
      elif result[nbIdx] == -1:
        result[nbIdx] = clusterId
        let nbrs = radiusSearch(tree, points[nbIdx], epsSq)
        if nbrs.len + 1 >= minPts:
          for n in nbrs:
            if result[n] == -1 or result[n] == -2:
              seedSet.add n
      j.inc
  for i in 0 ..< result.len:
    if result[i] == -2: result[i] = -1

proc extractClusters*[T; N: static[int]](
    points: openArray[Point[T, N]];
    labels: openArray[int]): seq[seq[Point[T, N]]] =
  ## 根据聚类标签将点分组为簇。
  ##
  ## - `points` — 原始点集
  ## - `labels` — DBSCAN 或其它聚类算法的标签输出
  ##
  ## 返回簇列表（每个簇为一个点向量）。标签为负的点被忽略。
  if points.len != labels.len:
    raise newException(ValueError, "extractClusters: size mismatch")
  var maxId = -1
  for lbl in labels:
    if lbl >= 0: maxId = max(maxId, lbl)
  result = newSeq[seq[Point[T, N]]](maxId + 1)
  for i, lbl in labels:
    if lbl >= 0: result[lbl].add points[i]
