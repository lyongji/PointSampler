## 泊松盘采样 (Poisson Disk Sampling) — Bridson 算法。
##
## 提供均匀、变密度、幂律和 Weibull 半径分布的泊松盘采样。
## 确保点之间满足最小距离约束，产生蓝噪声模式。
## 对应 C++ 版 `ps::poisson_disk_sampling.hpp`。

import std/[math, random, options]
import point

type
  GridND*[T; N: static[int]] = object
    ## 哈希网格，用于加速泊松盘采样中的邻域查询。
    cells*: seq[Option[Point[T, N]]]
    gridSize*: array[N, int]
    cellSize*: T

proc initGridND[T; N: static[int]](size: array[N, int]; cellSize: T): GridND[T, N] =
  var total = 1
  for s in size: total *= s
  result.cells = newSeq[Option[Point[T, N]]](total)
  result.gridSize = size
  result.cellSize = cellSize

func pointToGrid[T; N: static[int]](grid: GridND[T, N]; p: Point[T, N];
                                     ranges: array[N, (T, T)]): array[N, int] =
  for i in 0 ..< N:
    let clamped = clamp(p[i], ranges[i][0], ranges[i][1])
    var idx = ((clamped - ranges[i][0]) / grid.cellSize).int
    idx = clamp(idx, 0, grid.gridSize[i] - 1)
    result[i] = idx

func linearIdx[T; N: static[int]](grid: GridND[T, N]; idx: array[N, int]): int =
  var lin = 0; var stride = 1
  for i in 0 ..< N:
    lin += idx[i] * stride
    stride *= grid.gridSize[i]
  result = lin

func `[]`[T; N: static[int]](grid: GridND[T, N]; idx: array[N, int]): Option[Point[T, N]] =
  grid.cells[grid.linearIdx(idx)]

func `[]=`[T; N: static[int]](grid: var GridND[T, N]; idx: array[N, int]; val: Point[T, N]) =
  grid.cells[grid.linearIdx(idx)] = some(val)

proc inNeighborhood[T; N: static[int]](
    grid: var GridND[T, N];
    p: Point[T, N];
    baseMinDist: T;
    ranges: array[N, (T, T)];
    scaleFn: proc(p: Point[T, N]): T): bool =
  let scaleP = scaleFn(p) * baseMinDist
  let idx = grid.pointToGrid(p, ranges)
  let radius = (scaleP / grid.cellSize).ceil.int
  let g = addr(grid)
  var offsets: array[N, int]
  var resultVal = false
  proc recurse(dim: int) =
    if dim == N:
      var nidx: array[N, int]
      for d in 0 ..< N:
        let v = idx[d] + offsets[d]
        if v < 0 or v >= g[].gridSize[d]: return
        nidx[d] = v
      let slot = g[][nidx]
      if slot.isSome:
        let q = slot.get
        let scaleQ = scaleFn(q) * baseMinDist
        let thresh = max(scaleP, scaleQ)
        if distanceSquared(p, q) < thresh * thresh:
          resultVal = true
      return
    for off in -radius .. radius:
      offsets[dim] = off; recurse(dim + 1)
      if resultVal: return
  recurse(0)
  result = resultVal

proc genRandomPointAround[T; N: static[int]](
    center: Point[T, N];
    baseMinDist: T;
    rng: var Rand;
    scaleFn: proc(p: Point[T, N]): T): Point[T, N] =
  let scaled = scaleFn(center) * baseMinDist
  var dir: array[N, T]; var norm: T
  while true:
    norm = 0
    for d in 0 ..< N:
      dir[d] = rng.gauss(0.0.T, 1.0.T); norm += dir[d] * dir[d]
    if norm > 0: break
  norm = sqrt(norm)
  for d in 0 ..< N: dir[d] /= norm
  let r = scaled + rng.rand(1.0).T * scaled
  for d in 0 ..< N: result[d] = center[d] + dir[d] * r

proc poissonDiskSampling*[T; N: static[int]](
    count: int;
    ranges: array[N, (T, T)];
    baseMinDist: T;
    scaleFn: proc(p: Point[T, N]): T;
    seed: Option[uint32] = none[uint32]();
    newPointsAttempts: int = 30): seq[Point[T, N]] =
  ## 使用 Bridson 算法生成泊松盘采样点，支持距离缩放。
  ##
  ## 点之间的最小距离通过 `scaleFn` 进行空间变化。
  ##
  ## - `count` — 目标点数
  ## - `ranges` — 采样区域
  ## - `baseMinDist` — 基础最小距离
  ## - `scaleFn` — 距离缩放函数
  ## - `seed` — 可选随机种子
  ## - `newPointsAttempts` — 每活跃点的候选尝试数
  if count == 0: return
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  let cellSize = baseMinDist / sqrt(N.T)
  var gridSize: array[N, int]
  for i in 0 ..< N:
    gridSize[i] = ((ranges[i][1] - ranges[i][0]) / cellSize).ceil.int
  var grid = initGridND[T, N](gridSize, cellSize)
  result = newSeqOfCap[Point[T, N]](count)
  var processList = newSeqOfCap[Point[T, N]](count)
  var first: Point[T, N]
  for i in 0 ..< N:
    let (lo, hi) = ranges[i]
    first[i] = lo + rng.rand(1.0).T * (hi - lo)
  result.add first; processList.add first
  grid[grid.pointToGrid(first, ranges)] = first
  while processList.len > 0 and result.len < count:
    let idx = rng.rand(processList.high)
    let pt = processList[idx]
    processList.del(idx)
    for _ in 0 ..< newPointsAttempts:
      if result.len >= count: break
      let np = genRandomPointAround[T, N](pt, baseMinDist, rng, scaleFn)
      var inBounds = true
      for d in 0 ..< N:
        if np[d] < ranges[d][0] or np[d] > ranges[d][1]:
          inBounds = false; break
      if not inBounds: continue
      if not inNeighborhood(grid, np, baseMinDist, ranges, scaleFn):
        result.add np; processList.add np
        grid[grid.pointToGrid(np, ranges)] = np

proc poissonDiskSamplingUniform*[T; N: static[int]](
    count: int;
    ranges: array[N, (T, T)];
    baseMinDist: T;
    seed: Option[uint32] = none[uint32]();
    newPointsAttempts: int = 30): seq[Point[T, N]] =
  ## 均匀泊松盘采样（恒等距离缩放）。
  ##
  ## 所有点之间的最小距离恒定，产生均匀的蓝噪声分布。
  let identity = proc(p: Point[T, N]): T = 1.T
  result = poissonDiskSampling[T, N](count, ranges, baseMinDist, identity,
                                     seed, newPointsAttempts)

proc poissonDiskSamplingDistanceDistribution*[T; N: static[int]; R](
    nPoints: int;
    axisRanges: array[N, (T, T)];
    radiusGen: R;
    seed: Option[uint32] = none[uint32]();
    maxAttempts: int = 30): seq[Point[T, N]] =
  ## 使用分布定义半径的泊松盘采样。
  ##
  ## 每个点的排除半径通过 `radiusGen` 生成，约束 `d(pᵢ, pⱼ) > rᵢ + rⱼ`。
  ## 适用于生成局部密集程度不同的点集。
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  var radii = newSeqOfCap[T](nPoints)
  result = newSeqOfCap[Point[T, N]](nPoints)
  var attempts = 0
  while result.len < nPoints and attempts < nPoints * maxAttempts:
    attempts.inc
    var p: Point[T, N]
    for d in 0 ..< N:
      let (a, b) = axisRanges[d]
      p[d] = a + rng.rand(1.0).T * (b - a)
    let r = radiusGen()
    var valid = true
    for j in 0 ..< result.len:
      if distance(p, result[j]) < r + radii[j]:
        valid = false; break
    if valid: result.add p; radii.add r

proc poissonDiskSamplingPowerLaw*[T; N: static[int]](
    nPoints: int;
    distMin, distMax, alpha: T;
    axisRanges: array[N, (T, T)];
    seed: Option[uint32] = none[uint32]();
    maxAttempts: int = 30): seq[Point[T, N]] =
  ## 幂律半径分布的泊松盘采样。
  ##
  ## 半径分布: p(r) ∝ r^{-α}, r ∈ [distMin, distMax]。
  ## - α 越大，小半径越占优势，产生更密集的簇
  ## - α 越小，间距更均匀
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  if alpha == 1.T:
    let radiusGen = proc(): T =
      distMin * (distMax / distMin) ^ rng.rand(1.0).T
    result = poissonDiskSamplingDistanceDistribution[T, N, typeof(radiusGen)](
      nPoints, axisRanges, radiusGen, seed, maxAttempts)
  else:
    let radiusGen = proc(): T =
      let u = rng.rand(1.0).T
      (distMin ^ (1.T - alpha) + u * (distMax ^ (1.T - alpha) -
        distMin ^ (1.T - alpha))) ^ (1.T / (1.T - alpha))
    result = poissonDiskSamplingDistanceDistribution[T, N, typeof(radiusGen)](
      nPoints, axisRanges, radiusGen, seed, maxAttempts)

proc poissonDiskSamplingWeibull*[T; N: static[int]](
    nPoints: int;
    lambda, k: T;
    axisRanges: array[N, (T, T)];
    seed: Option[uint32] = none[uint32]();
    maxAttempts: int = 30): seq[Point[T, N]] =
  ## Weibull 半径分布的泊松盘采样。
  ##
  ## 半径分布: p(r; k, λ) = (k/λ)(r/λ)^{k-1} exp(-(r/λ)^k)。
  ## k < 1 → 重尾，k > 1 → 峰值。
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  let radiusGen = proc(): T =
    lambda * (-ln(1.T - rng.rand(1.0).T)) ^ (1.T / k)
  result = poissonDiskSamplingDistanceDistribution[T, N, typeof(radiusGen)](
    nPoints, axisRanges, radiusGen, seed, maxAttempts)

proc poissonDiskSamplingWeibull*[T; N: static[int]](
    nPoints: int;
    lambda, k, distMin: T;
    axisRanges: array[N, (T, T)];
    seed: Option[uint32] = none[uint32]();
    maxAttempts: int = 30): seq[Point[T, N]] =
  ## Weibull 半径分布（下限截断）的泊松盘采样。
  ##
  ## 每个点的半径至少为 `distMin`，确保全局最小间距。
  var rng = if seed.isSome: initRand(int64(seed.get)) else: initRand()
  let radiusGen = proc(): T =
    max(lambda * (-ln(1.T - rng.rand(1.0).T)) ^ (1.T / k), distMin)
  result = poissonDiskSamplingDistanceDistribution[T, N, typeof(radiusGen)](
    nPoints, axisRanges, radiusGen, seed, maxAttempts)
