## PointSampler — `[T; N: static[int]]` 采样库，C++ 后端 Futhark 绑定。
##
## ```nim
## import point_sampler_c
##
## let pts = random([(0.0, 1.0), (0.0, 1.0)], 100)
## let pp  = poissonDiskUniform([(0.0, 1.0), (0.0, 1.0)], 200, 0.05)
## let r   = kmeansClustering(pts, 5)
## echo r.centroids
## ```

import std/os

{.compile: currentSourcePath.parentDir / "c_api" / "ps_c_api.cpp".}
{.passC: "-I" & currentSourcePath.parentDir / "PointSampler/include".}
{.passC: "-I" & currentSourcePath.parentDir / "external/nanoflann/include".}
{.passC: "-I" & currentSourcePath.parentDir / "external/dkm/include".}
{.passL: "-lstdc++".}

from std/options import none, some, Option, isSome, get

import point_sampler/point
import src/bindings/ps_c_api_gen

# ---------------------------------------------------------------------------
# 命名结果类型
# ---------------------------------------------------------------------------

type
  KMeansResult*[T; N: static[int]] = object
    ## K-means 聚类结果。
    centroids*: seq[Point[T, N]]
    labels*: seq[int]

  DbscanResult* = object
    ## DBSCAN 聚类结果。
    labels*: seq[int]

# ---------------------------------------------------------------------------
# 内部辅助
# ---------------------------------------------------------------------------

func toFlat[T; N: static[int]](points: openArray[Point[T, N]]): seq[T] =
  result = newSeq[T](points.len * N)
  for i, p in points:
    for d in 0 ..< N:
      result[i * N + d] = p[d]

func fromFlat[T; N: static[int]](data: openArray[T]; count: int): seq[Point[T, N]] =
  result = newSeq[Point[T, N]](count)
  for i in 0 ..< count:
    for d in 0 ..< N:
      result[i][d] = data[i * N + d]

func toFlatRanges[T; N: static[int]](ranges: array[N, (T, T)]): array[2 * N, T] =
  for i in 0 ..< N:
    result[2 * i] = ranges[i][0]
    result[2 * i + 1] = ranges[i][1]

proc takeBuffer[T](p: ptr T; n: int): seq[T] =
  if p == nil or n <= 0: return
  let arr = cast[ptr UncheckedArray[T]](p)
  result = newSeq[T](n)
  for i in 0 ..< n:
    result[i] = arr[i]
  ps_free(p)

# -- type-erasure helpers (one per C function, avoids let-in-when issue) --

proc callRandomF32(count: int; r: ptr cfloat; usrSeed: Option[uint32];
                   outPtr: ptr ptr cfloat): int =
  if usrSeed.isSome: ps_random_s_f2(count.csize_t, r, usrSeed.get, outPtr).int
  else:              ps_random_f2(count.csize_t, r, outPtr).int

proc callRandomF64(count: int; r: ptr cdouble; usrSeed: Option[uint32];
                   outPtr: ptr ptr cdouble): int =
  if usrSeed.isSome: ps_random_s_d2(count.csize_t, r, usrSeed.get, outPtr).int
  else:              ps_random_d2(count.csize_t, r, outPtr).int

proc callHaltonF32(count: int; r: ptr cfloat; usrSeed: Option[uint32];
                   outPtr: ptr ptr cfloat): int =
  if usrSeed.isSome: ps_halton_s_f2(count.csize_t, r, usrSeed.get, outPtr).int
  else:              ps_halton_f2(count.csize_t, r, outPtr).int

proc callHaltonF64(count: int; r: ptr cdouble; usrSeed: Option[uint32];
                   outPtr: ptr ptr cdouble): int =
  if usrSeed.isSome: ps_halton_s_d2(count.csize_t, r, usrSeed.get, outPtr).int
  else:              ps_halton_d2(count.csize_t, r, outPtr).int

proc callHammersleyF32(count: int; r: ptr cfloat; outPtr: ptr ptr cfloat): int =
  ps_hammersley_f2(count.csize_t, r, outPtr).int

proc callHammersleyF64(count: int; r: ptr cdouble; outPtr: ptr ptr cdouble): int =
  ps_hammersley_d2(count.csize_t, r, outPtr).int

proc callPoissonUniformF32(count: int; r: ptr cfloat; minDist: cfloat;
                           outPtr: ptr ptr cfloat): int =
  ps_poisson_uniform_f2(count.csize_t, r, minDist, outPtr).int

proc callPoissonUniformF64(count: int; r: ptr cdouble; minDist: cdouble;
                           outPtr: ptr ptr cdouble): int =
  ps_poisson_uniform_d2(count.csize_t, r, minDist, outPtr).int

proc callFilterRangeF32(pts: ptr cfloat; n: int; r: ptr cfloat;
                        outPtr: ptr ptr cfloat): int =
  ps_filter_range_f2(pts, n.csize_t, r, outPtr).int

proc callFilterRangeF64(pts: ptr cdouble; n: int; r: ptr cdouble;
                        outPtr: ptr ptr cdouble): int =
  ps_filter_range_d2(pts, n.csize_t, r, outPtr).int

# ---------------------------------------------------------------------------
# 公共 API
# ---------------------------------------------------------------------------

proc random*[T; N: static[int]](
    axisRanges: array[N, (T, T)];
    count: Positive;
    seed: Option[uint32] = none[uint32]()
): seq[Point[T, N]] =
  let ranges = toFlatRanges(axisRanges)
  var outPtr: ptr T = nil
  let n =
    when T is float32:
      let r = cast[ptr cfloat](ranges[0].addr)
      callRandomF32(count, r, seed, cast[ptr ptr cfloat](outPtr.addr))
    elif T is float64:
      let r = cast[ptr cdouble](ranges[0].addr)
      callRandomF64(count, r, seed, cast[ptr ptr cdouble](outPtr.addr))
    else:
      static: error("random: unsupported type " & $T)
  let flat = takeBuffer(outPtr, n * N)
  if flat.len > 0:
    result = fromFlat[T, N](flat, n)

proc halton*[T; N: static[int]](
    axisRanges: array[N, (T, T)];
    count: Positive;
    seed: Option[uint32] = none[uint32]()
): seq[Point[T, N]] =
  let ranges = toFlatRanges(axisRanges)
  var outPtr: ptr T = nil
  let n =
    when T is float32:
      let r = cast[ptr cfloat](ranges[0].addr)
      callHaltonF32(count, r, seed, cast[ptr ptr cfloat](outPtr.addr))
    elif T is float64:
      let r = cast[ptr cdouble](ranges[0].addr)
      callHaltonF64(count, r, seed, cast[ptr ptr cdouble](outPtr.addr))
    else:
      static: error("halton: unsupported type " & $T)
  let flat = takeBuffer(outPtr, n * N)
  if flat.len > 0:
    result = fromFlat[T, N](flat, n)

proc hammersley*[T; N: static[int]](
    axisRanges: array[N, (T, T)];
    count: Positive
): seq[Point[T, N]] =
  let ranges = toFlatRanges(axisRanges)
  var outPtr: ptr T = nil
  let n =
    when T is float32:
      let r = cast[ptr cfloat](ranges[0].addr)
      callHammersleyF32(count, r, cast[ptr ptr cfloat](outPtr.addr))
    elif T is float64:
      let r = cast[ptr cdouble](ranges[0].addr)
      callHammersleyF64(count, r, cast[ptr ptr cdouble](outPtr.addr))
    else:
      static: error("hammersley: unsupported type " & $T)
  let flat = takeBuffer(outPtr, n * N)
  if flat.len > 0:
    result = fromFlat[T, N](flat, n)

proc poissonDiskUniform*[T; N: static[int]](
    axisRanges: array[N, (T, T)];
    count: Positive;
    minDist: T
): seq[Point[T, N]] =
  let ranges = toFlatRanges(axisRanges)
  var outPtr: ptr T = nil
  let n =
    when T is float32:
      let r = cast[ptr cfloat](ranges[0].addr)
      callPoissonUniformF32(count, r, minDist, cast[ptr ptr cfloat](outPtr.addr))
    elif T is float64:
      let r = cast[ptr cdouble](ranges[0].addr)
      callPoissonUniformF64(count, r, minDist, cast[ptr ptr cdouble](outPtr.addr))
    else:
      static: error("poissonDiskUniform: unsupported type " & $T)
  let flat = takeBuffer(outPtr, n * N)
  if flat.len > 0:
    result = fromFlat[T, N](flat, n)

proc filterInRange*[T; N: static[int]](
    points: openArray[Point[T, N]];
    axisRanges: array[N, (T, T)]
): seq[Point[T, N]] =
  let flat = toFlat(points)
  let ranges = toFlatRanges(axisRanges)
  var outPtr: ptr T = nil
  let n =
    when T is float32:
      let p = cast[ptr cfloat](flat[0].addr)
      let r = cast[ptr cfloat](ranges[0].addr)
      callFilterRangeF32(p, flat.len, r, cast[ptr ptr cfloat](outPtr.addr))
    elif T is float64:
      let p = cast[ptr cdouble](flat[0].addr)
      let r = cast[ptr cdouble](ranges[0].addr)
      callFilterRangeF64(p, flat.len, r, cast[ptr ptr cdouble](outPtr.addr))
    else:
      static: error("filterInRange: unsupported type " & $T)
  let raw = takeBuffer(outPtr, n * N)
  if raw.len > 0:
    result = fromFlat[T, N](raw, n)

proc distanceReject*[T; N: static[int]](
    points: openArray[Point[T, N]];
    minDist: T
): seq[Point[T, N]] =
  let flat = toFlat(points)
  var outPtr: ptr T = nil
  let n =
    when T is float32 and N == 2:
      let p = cast[ptr cfloat](flat[0].addr)
      ps_dist_reject_f2(p, flat.len.csize_t, minDist,
                        cast[ptr ptr cfloat](outPtr.addr)).int
    else:
      static: error("distanceReject: only float32×2D supported")
  let raw = takeBuffer(outPtr, n * N)
  if raw.len > 0:
    result = fromFlat[T, N](raw, n)

proc dbscanClustering*[T; N: static[int]](
    points: openArray[Point[T, N]];
    eps: T;
    minPts: Positive
): DbscanResult =
  let flat = toFlat(points)
  var outLabels: ptr cint = nil
  var outNClustersDummy: cint = 0
  let nPoints = points.len
  let ok =
    when T is float32 and N == 2:
      let p = cast[ptr cfloat](flat[0].addr)
      ps_dbscan_f2(p, nPoints.csize_t, eps, minPts.csize_t,
                   addr outLabels, addr outNClustersDummy)
    elif T is float64 and N == 2:
      let p = cast[ptr cdouble](flat[0].addr)
      ps_dbscan_d2(p, nPoints.csize_t, eps, minPts.csize_t,
                   addr outLabels, addr outNClustersDummy)
    else:
      static: error("dbscanClustering: only N=2 float32/float64")
  if ok >= 0 and outLabels != nil:
    let arr = cast[ptr UncheckedArray[cint]](outLabels)
    result.labels = newSeq[int](nPoints)
    for i in 0 ..< nPoints:
      result.labels[i] = arr[i].int
    ps_free(outLabels)

proc kmeansClustering*[T; N: static[int]](
    points: openArray[Point[T, N]];
    k: Positive;
    maxIterations: Positive = 100
): KMeansResult[T, N] =
  let flat = toFlat(points)
  var outCentroids: ptr T = nil
  var outLabels: ptr cint = nil
  let nPoints = points.len
  let nCentroids =
    when T is float32 and N == 2:
      let p = cast[ptr cfloat](flat[0].addr)
      ps_kmeans_f2(p, nPoints.csize_t, k.cint, maxIterations.cint,
                   cast[ptr ptr cfloat](outCentroids.addr), addr outLabels).int
    elif T is float64 and N == 2:
      let p = cast[ptr cdouble](flat[0].addr)
      ps_kmeans_d2(p, nPoints.csize_t, k.cint, maxIterations.cint,
                   cast[ptr ptr cdouble](outCentroids.addr), addr outLabels).int
    else:
      static: error("kmeansClustering: only N=2 float32/float64")
  let buf = takeBuffer(outCentroids, nCentroids * N)
  if buf.len > 0:
    result.centroids = fromFlat[T, N](buf, nCentroids)
  if outLabels != nil:
    let arr = cast[ptr UncheckedArray[cint]](outLabels)
    result.labels = newSeq[int](nPoints)
    for i in 0 ..< nPoints:
      result.labels[i] = arr[i].int
    ps_free(outLabels)
