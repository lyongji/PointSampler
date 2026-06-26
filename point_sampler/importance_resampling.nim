## 重要性重采样 (Importance Resampling)。
##
## 使用 Halton 序列过采样候选点，按密度函数加权后重采样。
## 适合从任意密度函数中生成服从分布的样本。
## 对应 C++ 版 `ps::importance_resampling<T,N>()`。

import std/[algorithm, math, random, options]
import point
import halton

proc importanceResampling*[T; N: static[int]](
    count, oversamplingRatio: int;
    axisRanges: array[N, (T, T)];
    densityFn: proc(p: Point[T, N]): T;
    seed: Option[uint32] = none[uint32]()): seq[Point[T, N]] =
  ## 通过重要性重采样从目标密度函数生成样本。
  ##
  ## 使用 Halton 序列过采样网格作为候选点，
  ## 按 `densityFn` 计算权重，然后通过离散分布重采样。
  ##
  ## - `count` — 最终样本数
  ## - `oversamplingRatio` — 过采样倍率（候选点数 = count × 倍率）
  ## - `axisRanges` — 采样区域
  ## - `densityFn` — 密度函数（返回非负值）
  ## - `seed` — 可选随机种子
  ##
  ## 示例:
  ## ```nim
  ## let density = proc(p: Point[float, 2]): float =
  ##   exp(-10.0 * (p[0]*p[0] + p[1]*p[1]))
  ## let pts = importanceResampling[float, 2](500, 5, [(-1.0, 1.0), (-1.0, 1.0)],
  ##                                         density, some(uint32(42)))
  ## ```
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  let nGrid = count * oversamplingRatio
  let gridPoints = halton.halton[T, N](nGrid, axisRanges, seed)
  var weights = newSeq[T](nGrid)
  for i, p in gridPoints:
    weights[i] = densityFn(p)
  let wSum = sum(weights)
  if wSum > 0:
    for w in mitems(weights): w /= wSum
  var cdf = newSeq[T](nGrid)
  var acc: T = 0
  for i, w in weights:
    acc += w
    cdf[i] = acc
  result = newSeqOfCap[Point[T, N]](count)
  for _ in 0 ..< count:
    let u = rng.rand(1.0).T
    let idx = cdf.upperBound(u)
    result.add gridPoints[min(idx, nGrid - 1)]
