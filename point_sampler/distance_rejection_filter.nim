## 距离拒绝过滤 (Greedy Distance-based Rejection)。
##
## 贪心算法：依次处理点，仅当与已保留点距离均 ≥ minDist 时保留。
## 支持固定和空间变化的最小距离。
## 对应 C++ 版 `ps::distance_rejection_filter<T,N>()`。

import point
import internal/kdtree

proc distanceRejectionFilter*[T; N: static[int]](
    points: openArray[Point[T, N]];
    minDist: T): seq[Point[T, N]] =
  ## 贪心距离拒绝过滤。
  ##
  ## 依次处理候选点，仅当与已接受点距离 ≥ `minDist` 时保留。
  ## 使用 KD-tree 加速最近邻查询。
  ##
  ## - `points` — 候选点集
  ## - `minDist` — 点之间的最小允许距离
  ##
  ## 示例:
  ## ```nim
  ## let filtered = distanceRejectionFilter(pts, 0.05)
  ## ```
  if points.len == 0: return
  result = @[points[0]]
  for i in 1 ..< points.len:
    let p = points[i]
    var tree = initKDTree(result)
    let matches = radiusSearch(tree, p, minDist * minDist)
    if matches.len == 0:
      result.add p

proc distanceRejectionFilterWarped*[T; N: static[int]](
    points: openArray[Point[T, N]];
    baseMinDist: T;
    scaleFn: proc(p: Point[T, N]): T): seq[Point[T, N]] =
  ## 空间变化距离拒绝过滤。
  ##
  ## 每个点的最小距离为 `baseMinDist * scaleFn(p)`，
  ## 允许局部自适应稠密度。
  ##
  ## - `points` — 候选点集
  ## - `baseMinDist` — 基础最小距离
  ## - `scaleFn` — 空间缩放因子函数
  ##
  ## 示例:
  ## ```nim
  ## let scale = proc(p: Point[float, 2]): float =
  ##   0.5 + 0.5 * sin(p[0] * 3.1415)
  ## let filtered = distanceRejectionFilterWarped(pts, 0.05, scale)
  ## ```
  if points.len == 0: return
  result = @[points[0]]
  for i in 1 ..< points.len:
    let p = points[i]
    let localMinDist = baseMinDist * scaleFn(p)
    var tree = initKDTree(result)
    let matches = radiusSearch(tree, p, localMinDist * localMinDist)
    if matches.len == 0:
      result.add p
