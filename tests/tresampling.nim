## Rejection sampling and importance resampling.

import std/[assertions, math, options]
import point_sampler/point
import point_sampler/rejection_sampling
import point_sampler/importance_resampling

block rejection_sampling_count:
  let density = proc(p: Point[float, 2]): float =
    exp(-10.0 * (p[0]*p[0] + p[1]*p[1]))
  let pts = rejectionSampling[float, 2](50, [(-1.0, 1.0), (-1.0, 1.0)],
                                          density, some(uint32(42)))
  doAssert pts.len > 0

block rejection_sampling_bounds:
  let density = proc(p: Point[float, 2]): float = 1.0
  let pts = rejectionSampling[float, 2](100, [(0.0, 1.0), (0.0, 1.0)],
                                          density, some(uint32(42)))
  for p in pts:
    doAssert p[0] >= 0.0 and p[0] <= 1.0

block importance_resampling_count:
  let density = proc(p: Point[float, 2]): float =
    exp(-5.0 * (p[0]*p[0] + p[1]*p[1]))
  let pts = importanceResampling[float, 2](50, 5,
    [(-1.0, 1.0), (-1.0, 1.0)], density, some(uint32(42)))
  doAssert pts.len == 50

block importance_resampling_bounds:
  let density = proc(p: Point[float, 2]): float = 1.0
  let pts = importanceResampling[float, 2](30, 3,
    [(0.0, 1.0), (0.0, 1.0)], density, some(uint32(42)))
  for p in pts:
    doAssert p[0] >= 0.0 and p[0] <= 1.0
    doAssert p[1] >= 0.0 and p[1] <= 1.0

echo "  ✓ resampling tests"
