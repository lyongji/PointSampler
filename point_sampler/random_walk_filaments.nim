## 随机游走纤维 (Random Walk Filaments)。
##
## 生成 N 维随机游走轨迹，可选高斯厚度（粗纤维）。
## 带持续性因子控制转弯平滑度。
## 对应 C++ 版 `ps::random_walk_filaments<T,N>()`。

import std/[math, random, options]
import point

proc randomWalkFilaments*[T; N: static[int]](
    nFilaments, filamentCount: int;
    stepSize: T;
    ranges: array[N, (T, T)];
    seed: Option[uint32] = none[uint32]();
    persistence: T = 0.8.T;
    gaussianSigma: T = 0.T;
    gaussianSamples: int = 0): seq[Point[T, N]] =
  ## 生成随机游走纤维点集。
  ##
  ## 每条纤维从随机起点开始，逐步游走。方向受持续性因子控制：
  ## `persistence = 0` 完全随机，`persistence = 1` 为直线。
  ## 可选项 `gaussianSigma > 0` 沿纤维生成高斯散布点形成粗纤维。
  ##
  ## - `nFilaments` — 纤维数量
  ## - `filamentCount` — 每条纤维的核心步数
  ## - `stepSize` — 平均步长
  ## - `ranges` — 边界盒（超出部分被裁剪）
  ## - `seed` — 可选随机种子
  ## - `persistence` — 方向持续性 [0, 1]，默认 0.8
  ## - `gaussianSigma` — 高斯散布标准差（0 = 无散布）
  ## - `gaussianSamples` — 每步的散布样本数
  ##
  ## 示例:
  ## ```nim
  ## let pts = randomWalkFilaments[float, 2](
  ##   3, 50, 0.05, [(0.0, 1.0), (0.0, 1.0)],
  ##   some(uint32(42)), persistence=0.9, gaussianSigma=0.01, gaussianSamples=5)
  ## ```
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  let cap = nFilaments * filamentCount * (1 + gaussianSamples)
  result = newSeqOfCap[Point[T, N]](cap)
  for f in 0 ..< nFilaments:
    var p: Point[T, N]
    for d in 0 ..< N:
      let (lo, hi) = ranges[d]
      p[d] = lo + rng.rand(1.0).T * (hi - lo)
    var dir = Point[T, N]()
    for d in 0 ..< N:
      dir[d] = rng.gauss(0.0.T, 1.0.T)
    dir = normalized(dir)
    for i in 0 ..< filamentCount:
      result.add p
      for g in 0 ..< gaussianSamples:
        var q = p
        var dist2: T = 0
        for d in 0 ..< N:
          let off = rng.gauss(0.0.T, gaussianSigma)
          q[d] += off
          dist2 += off * off
        var inside = true
        for d in 0 ..< N:
          if q[d] < ranges[d][0] or q[d] > ranges[d][1]:
            inside = false
            break
        if inside:
          result.add q
      var rnd = Point[T, N]()
      for d in 0 ..< N:
        rnd[d] = -1.T + rng.rand(2.0).T
      rnd = normalized(rnd)
      dir = persistence * dir + (1.T - persistence) * rnd
      dir = normalized(dir)
      p = p + dir * stepSize
