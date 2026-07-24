## Quasi-random sequences: Halton, Hammersley.

import std/[assertions, options]
import point_sampler/point
import point_sampler/halton
import point_sampler/hammersley

block halton_count:
  let pts = halton[float, 2](100, [(0.0, 1.0), (0.0, 1.0)])
  doAssert pts.len == 100

block halton_bounds:
  let pts = halton[float, 2](500, [(0.0, 1.0), (0.0, 1.0)])
  for p in pts:
    doAssert p[0] >= 0.0 and p[0] <= 1.0
    doAssert p[1] >= 0.0 and p[1] <= 1.0

block halton_rescaled:
  let pts = halton[float, 2](50, [(-10.0, 10.0), (0.0, 100.0)])
  for p in pts:
    doAssert p[0] >= -10.0 and p[0] <= 10.0
    doAssert p[1] >= 0.0 and p[1] <= 100.0

block halton_deterministic:
  let a = halton[float, 2](20, [(0.0, 1.0), (0.0, 1.0)], some(uint32(0)))
  let b = halton[float, 2](20, [(0.0, 1.0), (0.0, 1.0)], some(uint32(0)))
  for i in 0 ..< 20:
    doAssert a[i] == b[i]

block hammersley_count:
  let pts = hammersley[float, 2](100, [(0.0, 1.0), (0.0, 1.0)])
  doAssert pts.len == 100

block hammersley_bounds:
  let pts = hammersley[float, 2](500, [(-1.0, 1.0), (-1.0, 1.0)])
  for p in pts:
    doAssert p[0] >= -1.0 and p[0] <= 1.0
    doAssert p[1] >= -1.0 and p[1] <= 1.0

block hammersley_3d:
  let pts = hammersley[float, 3](50, [(0.0, 1.0), (0.0, 1.0), (0.0, 1.0)])
  doAssert pts.len == 50

block halton_float32:
  let pts = halton[float32, 2](20, [(0f, 1f), (0f, 1f)])
  doAssert pts.len == 20
  for p in pts:
    doAssert p[0] >= 0f and p[0] <= 1f

block hammersley_float32:
  let pts = hammersley[float32, 2](20, [(0f, 1f), (0f, 1f)])
  doAssert pts.len == 20
  for p in pts:
    doAssert p[0] >= 0f and p[0] <= 1f

echo "  ✓ Halton / Hammersley tests"
