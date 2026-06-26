## 随机点生成。
##
## 在 N 维轴对齐包围盒内生成均匀分布的随机点。
## 支持可选随机种子以获得可复现的结果。
## 对应 C++ 版 `ps::random<T,N>()`。

import std/[random, options]
import point

proc random*[T; N: static[int]](count: int; axisRanges: array[N, (T, T)];
                   seed: Option[uint32] = none[uint32]()): seq[Point[T, N]] =
  ## 在 `axisRanges` 定义的包围盒内生成 `count` 个均匀分布随机点。
  ##
  ## - `count` — 生成的点数
  ## - `axisRanges` — 每个维度的 (最小值, 最大值) 范围
  ## - `seed` — 可选随机种子；未提供时使用非确定性种子
  ##
  ## 示例:
  ## ```nim
  ## let pts = random[float, 2](100, [(0.0, 1.0), (0.0, 1.0)])
  ## ```
  var rng: Rand
  if seed.isSome: rng = initRand(int64(seed.get))
  else: rng = initRand()
  var dists: array[N, tuple[a, b: T]]
  for i in 0 ..< N:
    let (lo, hi) = axisRanges[i]
    dists[i] = (lo, hi)
  result = newSeqOfCap[Point[T, N]](count)
  for _ in 0 ..< count:
    var p: Point[T, N]
    for j in 0 ..< N:
      let (lo, hi) = dists[j]
      p[j] = lo + T(rng.rand(1.0)) * (hi - lo)
    result.add p
