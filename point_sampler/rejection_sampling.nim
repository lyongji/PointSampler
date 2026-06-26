## 拒绝采样 (Rejection Sampling)。
##
## 在轴对齐区域内均匀生成候选点，根据密度函数决定保留或丢弃。
## 对应 C++ 版 `ps::rejection_sampling<T,N>()`。

import std/[options, random]
import point
import function_rejection_filter

proc rejectionSampling*[T; N: static[int]](
    count: int;
    axisRanges: array[N, (T, T)];
    densityFn: proc(p: Point[T, N]): T;
    seed: Option[uint32] = none[uint32]()): seq[Point[T, N]] =
  ## 使用拒绝采样法从密度函数生成样本。
  ##
  ## 先在包围盒内均匀采样 `count × 2` 个候选点，
  ## 然后使用 `functionRejectionFilter` 以概率 `densityFn` 保留。
  ##
  ## - `count` — 目标样本数
  ## - `axisRanges` — 采样区域
  ## - `densityFn` — 返回保留概率 [0,1] 的函数
  ## - `seed` — 可选随机种子
  ##
  ## 注意: 若 `densityFn` 在大部分区域值很低，效率会下降。
  ##
  ## 示例:
  ## ```nim
  ## let density = proc(p: Point[float, 2]): float =
  ##   exp(-(p[0]*p[0] + p[1]*p[1]))
  ## let pts = rejectionSampling[float, 2](1000, [(-2.0, 2.0), (-2.0, 2.0)], density)
  ## ```
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  var candidates = newSeqOfCap[Point[T, N]](count * 2)
  for _ in 0 ..< count * 2:
    var p: Point[T, N]
    for i in 0 ..< N:
      let (lo, hi) = axisRanges[i]
      p[i] = lo + rng.rand(1.0).T * (hi - lo)
    candidates.add p
  result = functionRejectionFilter(candidates, densityFn, seed)
