## 拉丁超立方采样 (Latin Hypercube Sampling, LHS)。
##
## 在每个维度上均匀分层后随机排列，确保各维度覆盖均匀。
## 适合蒙特卡洛积分和代理模型。
## 对应 C++ 版 `ps::latin_hypercube_sampling<T,N>()`。

import std/[random, options]
import point

proc latinHypercubeSampling*[T; N: static[int]](
    sampleCount: int;
    axisRanges: array[N, (T, T)];
    seed: Option[uint32] = none[uint32]()): seq[Point[T, N]] =
  ## 生成 LHS 样本点。
  ##
  ## 每个维度被均匀分为 `sampleCount` 层，每层内随机抖动，
  ## 各维度的层顺序独立排列以消除相关性。
  ##
  ## - `sampleCount` — 样本数
  ## - `axisRanges` — 每个维度的 (min, max) 范围
  ## - `seed` — 可选随机种子
  ##
  ## 示例:
  ## ```nim
  ## let pts = latinHypercubeSampling[float, 2](100, [(0.0, 1.0), (0.0, 1.0)])
  ## ```
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  result = newSeq[Point[T, N]](sampleCount)
  for dim in 0 ..< N:
    let lo = axisRanges[dim][0]
    let hi = axisRanges[dim][1]
    let stride = (hi - lo) / sampleCount.T
    var strata: seq[T] = newSeqOfCap[T](sampleCount)
    for i in 0 ..< sampleCount:
      strata.add(lo + (i.T + rng.rand(1.0).T) * stride)
    rng.shuffle(strata)
    for i in 0 ..< sampleCount:
      result[i][dim] = strata[i]
