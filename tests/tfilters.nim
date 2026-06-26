## Filtering: function rejection, distance rejection, random rejection.

import std/assertions, std/sequtils
import point_sampler/point
import point_sampler/function_rejection_filter
import point_sampler/distance_rejection_filter
import point_sampler/random_rejection_filter

block function_rejection_all_accept:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([1.0, 1.0]),
  ]
  let fn = proc(p: Point[float, 2]): float = 1.0
  let filtered = functionRejectionFilter(pts, fn)
  doAssert filtered.len == 2, "all accept if fn returns 1.0"

block function_rejection_all_reject:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([1.0, 1.0]),
  ]
  let fn = proc(p: Point[float, 2]): float = 0.0
  let filtered = functionRejectionFilter(pts, fn)
  doAssert filtered.len == 0, "all reject if fn returns 0.0"

block function_rejection_half:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([0.5, 0.5]),
    initPoint[float, 2]([1.0, 1.0]),
  ]
  # deterministic: accept p where x > 0.5 via very high/low probs
  let fn = proc(p: Point[float, 2]): float =
    if p[0] > 0.5: 1.0 else: 0.0
  let filtered = functionRejectionFilter(pts, fn)
  doAssert filtered.len == 1

block distance_rejection_basic:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([0.02, 0.02]),   # too close
    initPoint[float, 2]([0.5, 0.5]),     # far enough
    initPoint[float, 2]([0.51, 0.51]),   # close to #3
  ]
  let filtered = distanceRejectionFilter(pts, 0.1)
  doAssert filtered.len >= 2
  doAssert filtered[0] == pts[0]

block distance_rejection_empty:
  let filtered = distanceRejectionFilter[float, 2](@[], 0.1)
  doAssert filtered.len == 0

block distance_rejection_warped:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([0.05, 0.05]),
    initPoint[float, 2]([0.5, 0.5]),
  ]
  let scale = proc(p: Point[float, 2]): float = 1.0
  let filtered = distanceRejectionFilterWarped(pts, 0.1, scale)
  doAssert filtered.len >= 1

block random_rejection_count:
  let pts = newSeqWith(100, initPoint[float, 2]())
  let reduced = randomRejectionFilter(pts, 30)
  doAssert reduced.len == 30

block random_rejection_fraction:
  let pts = newSeqWith(100, initPoint[float, 2]())
  let reduced = randomRejectionFilter(pts, 0.5)
  doAssert reduced.len == 50

block random_rejection_same_when_smaller:
  let pts = @[initPoint[float, 2]([1.0, 2.0])]
  let reduced = randomRejectionFilter(pts, 100)
  doAssert reduced.len == 1

echo "  ✓ filter tests"
