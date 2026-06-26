## 函数拒绝过滤 (Function Rejection Filter)。
##
## 基于空间概率密度函数随机保留或丢弃点。
## 每个点以 `densityFn(p)` 的概率被保留（[0,1]）。
## 对应 C++ 版 `ps::function_rejection_filter<T,N>()`。

import std/[random, options]
import point

proc functionRejectionFilter*[T; N: static[int]](
    points: openArray[Point[T, N]];
    densityFn: proc(p: Point[T, N]): T;
    seed: Option[uint32] = none[uint32]()): seq[Point[T, N]] =
  ## 使用概率密度函数过滤点集。
  ##
  ## 每个点以 `densityFn(p)` 的概率被保留。
  ## 用于从非均匀分布中采样。
  ##
  ## - `points` — 候选点集
  ## - `densityFn` — 返回保留概率 [0,1] 的函数
  ## - `seed` — 可选随机种子
  ##
  ## 示例:
  ## ```nim
  ## let keepFn = proc(p: Point[float, 2]): float =
  ##   0.5 + 0.5 * sin(p[0] * 10.0)
  ## let accepted = functionRejectionFilter(pts, keepFn)
  ## ```
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  result = newSeqOfCap[Point[T, N]](points.len)
  for p in points:
    if densityFn(p) >= rng.rand(1.0).T:
      result.add p
