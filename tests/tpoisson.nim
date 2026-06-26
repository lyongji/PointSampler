## Poisson disk sampling — all variants.

import std/[assertions, options]
import point_sampler/point
import point_sampler/poisson_disk_sampling

block uniform_poisson_count:
  let pts = poissonDiskSamplingUniform[float, 2](
    50, [(0.0, 1.0), (0.0, 1.0)], 0.1,
    some(uint32(42)))
  doAssert pts.len > 0, "should generate some points"
  doAssert pts.len <= 50

block uniform_poisson_bounds:
  let pts = poissonDiskSamplingUniform[float, 2](
    100, [(0.0, 1.0), (0.0, 1.0)], 0.1,
    some(uint32(42)))
  for p in pts:
    doAssert p[0] >= 0.0 and p[0] <= 1.0
    doAssert p[1] >= 0.0 and p[1] <= 1.0

block uniform_poisson_separation:
  let pts = poissonDiskSamplingUniform[float, 2](
    200, [(0.0, 1.0), (0.0, 1.0)], 0.1,
    some(uint32(42)))
  for i in 0 ..< pts.len:
    for j in (i + 1) ..< pts.len:
      let d = distance(pts[i], pts[j])
      doAssert d >= 0.09, "points should respect min distance"

block empty_count:
  let pts = poissonDiskSamplingUniform[float, 2](
    0, [(0.0, 1.0), (0.0, 1.0)], 0.1)
  doAssert pts.len == 0

block poisson_scaled:
  let scale = proc(p: Point[float, 2]): float = 1.0
  let pts = poissonDiskSampling[float, 2](
    50, [(0.0, 1.0), (0.0, 1.0)], 0.1,
    scale, some(uint32(42)))
  doAssert pts.len > 0

block poisson_distance_distribution:
  # simple radius generator: constant radius
  let radiusGen = proc(): float = 0.15
  let pts = poissonDiskSamplingDistanceDistribution[float, 2, typeof(radiusGen)](
    30, [(0.0, 1.0), (0.0, 1.0)], radiusGen,
    some(uint32(42)), 50)
  doAssert pts.len > 0

block poisson_power_law:
  let pts = poissonDiskSamplingPowerLaw[float, 2](
    30, 0.02, 0.2, 1.5, [(0.0, 1.0), (0.0, 1.0)],
    some(uint32(42)), 50)
  doAssert pts.len > 0

block poisson_weibull:
  let pts = poissonDiskSamplingWeibull[float, 2](
    30, 0.1, 2.0, [(0.0, 1.0), (0.0, 1.0)],
    some(uint32(42)), 50)
  doAssert pts.len > 0

block poisson_weibull_min_dist:
  let pts = poissonDiskSamplingWeibull[float, 2](
    30, 0.1, 2.0, 0.05, [(0.0, 1.0), (0.0, 1.0)],
    some(uint32(42)), 50)
  doAssert pts.len > 0

echo "  ✓ Poisson disk tests"
