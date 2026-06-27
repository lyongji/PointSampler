## C++ 绑定 API 测试。默认使用 float(=float64)。

import std/assertions
from std/options import some
from std/sequtils import deduplicate

import point_sampler/point
import point_sampler_c

# ---------------------------------------------------------------------------
# 辅助
# ---------------------------------------------------------------------------

proc makeClusters(x, y: float; n: int; step: float): seq[Point[float, 2]] =
  result = newSeq[Point[float, 2]](n * 2)
  for i in 0 ..< n:
    result[i] = Point[float, 2](coords: [x + i.float * step, y + i.float * step])
    result[n + i] = Point[float, 2](coords: [x + 0.7 + i.float * step, y + 0.7 + i.float * step])

# ---------------------------------------------------------------------------
# 随机
# ---------------------------------------------------------------------------

block random_float64:
  let pts = random([(0.0, 1.0), (0.0, 1.0)], 100)
  doAssert pts.len == 100
  for p in pts:
    doAssert p.x >= 0.0 and p.x <= 1.0
    doAssert p.y >= 0.0 and p.y <= 1.0

block random_seed:
  let a = random([(0.0, 1.0), (0.0, 1.0)], 50, seed = some(uint32(42)))
  let b = random([(0.0, 1.0), (0.0, 1.0)], 50, seed = some(uint32(42)))
  doAssert a == b
  let c = random([(0.0, 1.0), (0.0, 1.0)], 50, seed = some(uint32(99)))
  doAssert a != c

block random_float32:
  let pts = random[float32, 2]([(0.0'f32, 1.0'f32), (0.0'f32, 1.0'f32)], 100)
  doAssert pts.len == 100

# ---------------------------------------------------------------------------
# 准随机
# ---------------------------------------------------------------------------

block halton:
  let pts = halton([(0.0, 1.0), (0.0, 1.0)], 50)
  doAssert pts.len == 50

block halton_seed:
  let a = halton([(0.0, 1.0), (0.0, 1.0)], 50, seed = some(uint32(42)))
  let b = halton([(0.0, 1.0), (0.0, 1.0)], 50, seed = some(uint32(42)))
  doAssert a == b

block hammersley:
  let pts = hammersley([(0.0, 1.0), (0.0, 1.0)], 50)
  doAssert pts.len == 50

# ---------------------------------------------------------------------------
# 泊松盘
# ---------------------------------------------------------------------------

block poisson_disk:
  let pts = poissonDiskUniform([(0.0, 1.0), (0.0, 1.0)], 200, 0.05)
  doAssert pts.len > 0
  for i in 0 ..< pts.len:
    for j in i + 1 ..< pts.len:
      doAssert distance(pts[i], pts[j]) >= 0.045

# ---------------------------------------------------------------------------
# 过滤
# ---------------------------------------------------------------------------

block filter_in_range:
  let all = random([(0.0, 1.0), (0.0, 1.0)], 500)
  let filtered = filterInRange(all, [(0.25, 0.75), (0.25, 0.75)])
  doAssert filtered.len > 0 and filtered.len < all.len
  for p in filtered:
    doAssert p.x in 0.25 .. 0.75
    doAssert p.y in 0.25 .. 0.75

block distance_reject:
  let pts = random[float32, 2]([(0.0'f32, 1.0'f32), (0.0'f32, 1.0'f32)], 200)
  let rejected = distanceReject(pts, 0.1'f32)
  doAssert rejected.len in 1 .. pts.len

# ---------------------------------------------------------------------------
# 聚类
# ---------------------------------------------------------------------------

block dbscan:
  let pts = makeClusters(0.1, 0.1, 15, 0.01)
  let r = dbscanClustering(pts, 0.2, 3)
  doAssert r.labels.len == pts.len
  doAssert r.labels.deduplicate().len >= 2

block kmeans:
  let pts = makeClusters(0.1, 0.1, 20, 0.005)
  let r = kmeansClustering(pts, 2)
  doAssert r.centroids.len == 2
  doAssert r.labels.len == pts.len
