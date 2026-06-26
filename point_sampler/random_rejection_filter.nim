## 随机拒绝过滤与随机下采样。
##
## 从点集中随机选择子集，支持指定数量或比例。
## 对应 C++ 版 `ps::random_rejection_filter<T,N>()`。

import std/[random, sequtils]
import point

proc randomRejectionFilter*[T; N: static[int]](
    points: openArray[Point[T, N]];
    targetCount: int): seq[Point[T, N]] =
  ## 随机保留 `targetCount` 个点（不放回抽样）。
  ##
  ## - 若 `targetCount >= points.len`，返回全部点
  ## - 使用 Fisher-Yates 洗牌算法选取子集
  ##
  ## 示例:
  ## ```nim
  ## let reduced = randomRejectionFilter(pts, 300)
  ## ```
  if targetCount >= points.len: return @points
  var indices = toSeq(0 ..< points.len)
  var rng = initRand()
  rng.shuffle(indices)
  result = newSeqOfCap[Point[T, N]](targetCount)
  for i in 0 ..< targetCount:
    result.add points[indices[i]]

proc randomRejectionFilter*[T; N: static[int]](
    points: openArray[Point[T, N]];
    keepFraction: float): seq[Point[T, N]] =
  ## 按比例随机保留点。
  ##
  ## `keepFraction` ∈ [0, 1]，保留 `keepFraction * points.len` 个点。
  let target = (keepFraction * points.len.float).int
  result = randomRejectionFilter[T, N](points, target)
