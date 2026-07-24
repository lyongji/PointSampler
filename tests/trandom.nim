## Random point generation.

import std/[assertions, options]
import point_sampler/point
import point_sampler/random

block random_count:
  let pts = random[float, 2](100, [(0.0, 1.0), (0.0, 1.0)])
  doAssert pts.len == 100, "should generate requested count"

block random_bounds:
  let pts = random[float, 2](1000, [(0.0, 1.0), (0.0, 1.0)])
  for p in pts:
    doAssert p[0] >= 0.0 and p[0] <= 1.0, "x in range"
    doAssert p[1] >= 0.0 and p[1] <= 1.0, "y in range"

block random_seed_determinism:
  let a = random[float, 2](50, [(0.0, 1.0), (0.0, 1.0)], some(uint32(42)))
  let b = random[float, 2](50, [(0.0, 1.0), (0.0, 1.0)], some(uint32(42)))
  for i in 0 ..< 50:
    doAssert a[i] == b[i], "same seed should give same points"

block random_seed_different:
  let a = random[float, 2](50, [(0.0, 1.0), (0.0, 1.0)], some(uint32(42)))
  let b = random[float, 2](50, [(0.0, 1.0), (0.0, 1.0)], some(uint32(99)))
  var same = true
  for i in 0 ..< 50:
    if a[i] != b[i]:
      same = false
      break
  doAssert not same, "different seeds should give different points"

block random_3d:
  let pts = random[float, 3](10, [(0.0, 1.0), (0.0, 1.0), (-1.0, 1.0)])
  doAssert pts.len == 10
  for p in pts:
    doAssert p[0] >= 0.0 and p[0] <= 1.0
    doAssert p[2] >= -1.0 and p[2] <= 1.0

block random_float32:
  let pts = random[float32, 2](10, [(0f, 1f), (0f, 1f)])
  doAssert pts.len == 10
  for p in pts:
    doAssert p[0] >= 0f and p[0] <= 1f

block random_invalid_range:
  doAssertRaises AssertionDefect:
    discard random[float, 2](1, [(1.0, 0.0), (0.0, 1.0)])

echo "  ✓ random tests"
