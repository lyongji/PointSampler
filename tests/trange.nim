## Range filtering and rescaling.

import std/assertions, std/math
import point_sampler/range
import point_sampler/point

block filter_points_in_range:
  let pts = [
    initPoint[float, 2]([0.5, 0.5]),
    initPoint[float, 2]([2.0, 3.0]),
    initPoint[float, 2]([-1.0, 0.0]),
  ]
  let filtered = filterPointsInRange(pts, [(0.0, 1.0), (0.0, 1.0)])
  doAssert filtered.len == 1
  doAssert filtered[0][0] == 0.5

block filter_points_function:
  let pts = [
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([1.0, 1.0]),
    initPoint[float, 2]([2.0, 2.0]),
  ]
  let fn = proc(p: Point[float, 2]): float =
    if p[0] + p[1] < 2.5: 1.0 else: 0.0
  let f = filterPointsFunction(pts, fn)
  doAssert f.len == 2

block refit_points_to_range:
  var pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([1.0, 1.0]),
  ]
  refitPointsToRange(pts, [(10.0, 20.0), (100.0, 200.0)])
  doAssert abs(pts[0][0] - 10.0) < 1e-9
  doAssert abs(pts[0][1] - 100.0) < 1e-9
  doAssert abs(pts[1][0] - 20.0) < 1e-9
  doAssert abs(pts[1][1] - 200.0) < 1e-9

block refit_points_empty:
  var empty: seq[Point[float, 2]] = @[]
  refitPointsToRange(empty, [(0.0, 1.0), (0.0, 1.0)])
  doAssert empty.len == 0, "refit on empty should be a no-op"

block rescale_points:
  var pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([1.0, 1.0]),
  ]
  rescalePoints(pts, [(10.0, 20.0), (100.0, 200.0)])
  doAssert abs(pts[0][0] - 10.0) < 1e-9
  doAssert abs(pts[1][0] - 20.0) < 1e-9
  doAssert abs(pts[1][1] - 200.0) < 1e-9

echo "  ✓ range tests"
