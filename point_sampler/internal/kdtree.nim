## KD‑tree 空间索引。
##
## 最小化的 N 维 KD‑tree，支持最近邻、K 近邻和半径搜索。
## 替代 C++ 版的 nanoflann 依赖。
##
## ponytail: 单线程，不重平衡。点数量超过 1e6 时应替换为更高效的实现。

import std/[algorithm, math, sequtils]
import ../point

type
  Node[T; N: static[int]] = ref object
    point: Point[T, N]
    idx: int
    axis: int
    left, right: Node[T, N]

  KDTree*[T; N: static[int]] = object
    ## N 维 KD‑tree。
    points: seq[Point[T, N]]
    root: Node[T, N]

proc build[T; N: static[int]](points: seq[Point[T, N]]; indices: seq[int];
                               depth: int): Node[T, N] =
  if indices.len == 0: return nil
  let axis = depth mod N
  var idxs = indices
  idxs.sort do (a, b: int) -> int: cmp(points[a][axis], points[b][axis])
  let mid = idxs.len div 2
  new result
  result.point = points[idxs[mid]]
  result.idx = idxs[mid]
  result.axis = axis
  result.left = build(points, idxs[0 ..< mid], depth + 1)
  result.right = build(points, idxs[mid + 1 .. ^1], depth + 1)

proc initKDTree*[T; N: static[int]](points: openArray[Point[T, N]]): KDTree[T, N] =
  ## 从点集构建 KD‑tree。
  result.points = @points
  if points.len > 0:
    var indices = toSeq(0 ..< points.len)
    result.root = build(result.points, indices, 0)

proc nearestNeighbor*[T; N: static[int]](tree: KDTree[T, N]; query: Point[T, N];
                                          idx: var int; distSq: var T) =
  ## 查找最近邻（排除自身）。
  ## 返回索引和距离平方。
  var bestIdx = -1
  var bestDistSq = high(T)
  proc search(node: Node[T, N]; depth: int) =
    if node == nil: return
    let axis = depth mod N
    let d = query[axis] - node.point[axis]
    let dSq = distanceSquared(query, node.point)
    if dSq > 0 and dSq < bestDistSq:
      bestDistSq = dSq; bestIdx = node.idx
    let nearer = if d < 0: node.left else: node.right
    let farther = if d < 0: node.right else: node.left
    search(nearer, depth + 1)
    if d * d < bestDistSq: search(farther, depth + 1)
  if tree.root != nil: search(tree.root, 0)
  idx = bestIdx; distSq = bestDistSq

proc kNearestNeighbors*[T; N: static[int]](tree: KDTree[T, N]; query: Point[T, N];
                                             k: int): seq[(int, T)] =
  ## 返回 `k` 个最近邻的 (索引, 距离平方) 列表（排除自身）。
  var results: seq[(T, int)]
  proc search(node: Node[T, N]; depth: int) =
    if node == nil: return
    let axis = depth mod N
    let d = query[axis] - node.point[axis]
    let dSq = distanceSquared(query, node.point)
    if dSq > 0:
      if results.len < k:
        results.add (dSq, node.idx)
        if results.len == k:
          results.sort(order = SortOrder.Descending)
      else:
        if dSq < results[0][0]:
          results[0] = (dSq, node.idx)
          results.sort(order = SortOrder.Descending)
    let nearer = if d < 0: node.left else: node.right
    let farther = if d < 0: node.right else: node.left
    search(nearer, depth + 1)
    if results.len < k or d * d < results[0][0]:
      search(farther, depth + 1)
  if tree.root != nil: search(tree.root, 0)
  result = results.mapIt((it[1], it[0]))

proc radiusSearch*[T; N: static[int]](tree: KDTree[T, N]; query: Point[T, N];
                                        radiusSq: T): seq[int] =
  ## 返回半径范围内所有点的索引（排除自身）。
  var matches: seq[int]
  proc search(node: Node[T, N]; depth: int) =
    if node == nil: return
    let axis = depth mod N
    let d = query[axis] - node.point[axis]
    let dSq = distanceSquared(query, node.point)
    if dSq > 0 and dSq <= radiusSq: matches.add node.idx
    let nearer = if d < 0: node.left else: node.right
    let farther = if d < 0: node.right else: node.left
    search(nearer, depth + 1)
    if d * d <= radiusSq: search(farther, depth + 1)
  if tree.root != nil: search(tree.root, 0)
  result = matches
