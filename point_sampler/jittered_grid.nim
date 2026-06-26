## 抖动网格采样 (Jittered Grid)。
##
## 将区域划分为网格，每格内随机抖动放置一个点，
## 可选的交错偏移改善均匀性。
## 对应 C++ 版 `ps::jittered_grid<T,N>()`。

import std/[math, random, options]
import point

proc jitteredGrid*[T; N: static[int]](
    count: int;
    axisRanges: array[N, (T, T)];
    jitterAmount: array[N, T];
    staggerRatio: array[N, T];
    seed: Option[uint32] = none[uint32]()): seq[Point[T, N]] =
  ## 生成抖动网格点集。
  ##
  ## - `count` — 目标点数（受网格单元总数限制）
  ## - `axisRanges` — 各维度的 (min, max) 范围
  ## - `jitterAmount` — 每维抖动因子 ∈ [0,1]；1 表示完全抖动
  ## - `staggerRatio` — 每维交错偏移量，基于高维索引奇偶性
  ## - `seed` — 可选随机种子
  ##
  ## 示例:
  ## ```nim
  ## let jitter: array[2, float] = [0.8, 0.8]
  ## let stagger: array[2, float] = [0.2, 0.0]
  ## let pts = jitteredGrid[float, 2](256, [(0.0, 1.0), (0.0, 1.0)],
  ##                                  jitter, stagger, some(uint32(42)))
  ## ```
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  var vol = 1.0.T
  for (lo, hi) in axisRanges: vol *= (hi - lo)
  let cellVol = vol / count.T
  let cellSizeEst = cellVol ^ (1.T / N.T)
  var resolution: array[N, int]
  var totalCells = 1
  for i in 0 ..< N:
    let span = axisRanges[i][1] - axisRanges[i][0]
    resolution[i] = max(1, (span / cellSizeEst).int)
    totalCells *= resolution[i]
  var cellIndices: seq[array[N, int]]
  for lin in 0 ..< totalCells:
    var idx: array[N, int]
    var stride = 1
    for i in 0 ..< N:
      idx[i] = (lin div stride) mod resolution[i]
      stride *= resolution[i]
    cellIndices.add idx
  rng.shuffle(cellIndices)
  let limit = min(count, cellIndices.len)
  result = newSeqOfCap[Point[T, N]](limit)
  for i in 0 ..< limit:
    let idx = cellIndices[i]
    var p: Point[T, N]
    for d in 0 ..< N:
      let lo = axisRanges[d][0]
      let hi = axisRanges[d][1]
      let cs = (hi - lo) / resolution[d].T
      let jr = jitterAmount[d] * cs
      let jc = (1.T - jitterAmount[d]) * 0.5.T * cs
      let jit = rng.rand(1.0).T * jr
      var stagger: T = 0
      for k in d+1 ..< N:
        if idx[k] mod 2 == 1:
          stagger += staggerRatio[d] * cs
      p[d] = lo + idx[d].T * cs + jc + jit + stagger
    result.add p

proc jitteredGrid*[T; N: static[int]](
    count: int;
    axisRanges: array[N, (T, T)];
    seed: Option[uint32]): seq[Point[T, N]] =
  ## 简化版抖动网格：完全抖动，无交错。
  var fullJitter: array[N, T]
  for i in 0 ..< N: fullJitter[i] = 1.T
  result = jitteredGrid[T, N](count, axisRanges, fullJitter,
                               default(array[N, T]), seed)
