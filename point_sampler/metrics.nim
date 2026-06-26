## 空间度量 (Metrics)。
##
## 提供点集的空间分析工具：最近邻查询、局部密度估计、
## 径向分布函数 (RDF)、角分布函数 (ADF)、边界距离等。
## 对应 C++ 版 `ps::metrics.hpp`。

import std/[math]
import point
import internal/kdtree

proc nearestNeighborsIndices*[T; N: static[int]](
    points: openArray[Point[T, N]];
    kNeighbors: int = 8): seq[seq[int]] =
  ## 返回每个点的 k 个最近邻索引（排除自身）。
  ##
  ## 示例:
  ## ```nim
  ## let nbrs = nearestNeighborsIndices(pts, 6)
  ## ```
  let tree = initKDTree(points)
  result = newSeq[seq[int]](points.len)
  for i, p in points:
    let nbrs = kNearestNeighbors(tree, p, kNeighbors + 1)
    result[i] = newSeqOfCap[int](kNeighbors)
    for nb in nbrs:
      let j = nb[0]
      if j != i:
        result[i].add j
        if result[i].len == kNeighbors: break

proc firstNeighborDistanceSquared*[T; N: static[int]](
    points: var seq[Point[T, N]]): seq[T] =
  ## 计算每个点到最近邻的距离平方。
  let tree = initKDTree(points)
  result = newSeqOfCap[T](points.len)
  for i, p in points:
    var idx: int; var distSq: T
    nearestNeighbor(tree, p, idx, distSq)
    result.add distSq

proc localDensityKnn*[T; N: static[int]](
    points: openArray[Point[T, N]];
    k: int = 8): seq[T] =
  ## 基于 k 近邻的局部密度估计。
  ##
  ## ρᵢ = k / (V_N · rᵢ^N)，其中 rᵢ 是到第 k 近邻的距离，
  ## V_N = π^(N/2) / Γ(N/2 + 1) 为 N 维单位球体积。
  let nbrs = nearestNeighborsIndices(points, k)
  let volUnitBall = pow(PI.T, N.T / 2.T) / gamma(N.T / 2.T + 1.T)
  result = newSeq[T](points.len)
  for i, p in points:
    if nbrs[i].len > 0:
      let nkIdx = nbrs[i][^1]
      var dist2: T = 0
      for d in 0 ..< N: dist2 += (p[d] - points[nkIdx][d]) ^ 2
      let r = sqrt(dist2)
      result[i] = k.T / (volUnitBall * pow(r, N.T))

proc angleDistributionNeighbors*[T; N: static[int]](
    points: openArray[Point[T, N]];
    binWidth: T; kNeighbors: int = 8): tuple[angles: seq[T], gTheta: seq[T]] =
  ## 角分布函数 (ADF)：计算近邻间键角的归一化分布。
  ##
  ## - 平坦分布 → 随机均匀
  ## - 特定角度峰值 → 局部有序（如六角格在 60° 处有峰）
  let nBins = (PI / binWidth).ceil.int
  var angles = newSeq[T](nBins)
  var g = newSeq[T](nBins)
  for i in 0 ..< nBins: angles[i] = (i.T + 0.5.T) * binWidth
  let nbrs = nearestNeighborsIndices(points, kNeighbors)
  for i, p in points:
    let nn = nbrs[i]
    for a in 0 ..< nn.len:
      for b in (a + 1) ..< nn.len:
        let (j, k) = (nn[a], nn[b])
        var v1, v2: array[N, T]
        for d in 0 ..< N: v1[d] = points[j][d] - p[d]; v2[d] = points[k][d] - p[d]
        var dot: T = 0; var n1: T = 0; var n2: T = 0
        for d in 0 ..< N:
          dot += v1[d] * v2[d]; n1 += v1[d] ^ 2; n2 += v2[d] ^ 2
        if n1 > 0 and n2 > 0:
          let cosTheta = clamp(dot / (sqrt(n1) * sqrt(n2)), -1.T, 1.T)
          let bin = (arccos(cosTheta) / binWidth).int
          if bin < nBins: g[bin] += 1.T
  let total = sum(g)
  if total > 0:
    for v in mitems(g): v /= total
  result = (angles, g)

proc distanceToBoundary*[T; N: static[int]](
    points: openArray[Point[T, N]];
    axisRanges: array[N, (T, T)]): seq[T] =
  ## 计算每个点到轴对齐域边界的最小欧几里得距离。
  result = newSeqOfCap[T](points.len)
  for p in points:
    var minDist = high(T)
    for d in 0 ..< N:
      minDist = min(min(minDist, abs(p[d] - axisRanges[d][0])),
                    abs(axisRanges[d][1] - p[d]))
    result.add minDist

proc radialDistribution*[T; N: static[int]](
    points: openArray[Point[T, N]];
    axisRanges: array[N, (T, T)];
    binWidth, maxDistance: T): tuple[radii: seq[T], g: seq[T]] =
  ## 归一格化径向分布函数 g(r)。
  ##
  ## - g(r) ≈ 1 → 均匀/随机分布
  ## - g(r) > 1 → 聚集
  ## - g(r) < 1 → 排斥/稀疏
  let nBins = (maxDistance / binWidth).ceil.int
  var radii = newSeq[T](nBins)
  var g = newSeq[T](nBins)
  for i in 0 ..< nBins: radii[i] = (i.T + 0.5.T) * binWidth
  var vol = 1.0.T
  for (lo, hi) in axisRanges: vol *= (hi - lo)
  let n = points.len.T; let density = n / vol
  for i in 0 ..< points.len:
    for j in (i + 1) ..< points.len:
      let dist = distance(points[i], points[j])
      if dist < maxDistance:
        let bin = (dist / binWidth).int
        if bin < nBins: g[bin] += 2.T
  let normFactor = n * density
  let sphereVol = proc(r: T): T =
    pow(PI.T, N.T / 2.T) / gamma(N.T / 2.T + 1.T) * pow(r, N.T)
  for i in 0 ..< nBins:
    let shellVol = sphereVol((i + 1).T * binWidth) - sphereVol(i.T * binWidth)
    if normFactor > 0 and shellVol > 0: g[i] /= normFactor * shellVol
  result = (radii, g)
