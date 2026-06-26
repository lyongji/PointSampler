## Utility functions: CSV, dimension ops, normalization.

import std/assertions, std/os, std/strutils
import point_sampler/point
import point_sampler/dbscan_clustering
import point_sampler/utils

block normalize_points:
  var pts = @[
    initPoint[float, 2]([1.0, 5.0]),
    initPoint[float, 2]([3.0, 15.0]),
  ]
  normalizePoints(pts)
  doAssert abs(pts[0][0] - 0.0) < 1e-9
  doAssert abs(pts[1][0] - 1.0) < 1e-9
  doAssert abs(pts[0][1] - 0.0) < 1e-9
  doAssert abs(pts[1][1] - 1.0) < 1e-9

block normalize_points_single_value:
  var pts = @[initPoint[float, 2]([5.0, 5.0]), initPoint[float, 2]([5.0, 5.0])]
  normalizePoints(pts)
  doAssert pts[0][0] == 0.0
  doAssert pts[1][0] == 0.0

block normalize_points_empty:
  var pts: seq[Point[float, 2]] = @[]
  normalizePoints(pts)
  doAssert pts.len == 0

block split_and_merge:
  let pts = @[
    initPoint[float, 3]([1.0, 2.0, 3.0]),
    initPoint[float, 3]([4.0, 5.0, 6.0]),
  ]
  let components = splitByDimension(pts)
  doAssert components[0] == @[1.0, 4.0]
  doAssert components[1] == @[2.0, 5.0]
  doAssert components[2] == @[3.0, 6.0]
  let merged = mergeByDimension(components)
  doAssert merged.len == 2
  doAssert merged[0][0] == 1.0
  doAssert merged[1][2] == 6.0

block add_dimension:
  let pts2d = @[initPoint[float, 2]([1.0, 2.0]), initPoint[float, 2]([3.0, 4.0])]
  let z = @[10.0, 20.0]
  let pts3d = addDimension(pts2d, z)
  doAssert pts3d.len == 2
  doAssert pts3d[0][2] == 10.0
  doAssert pts3d[1][2] == 20.0

block add_dimension_mismatch:
  let pts2d = @[initPoint[float, 2]([1.0, 2.0])]
  let z = @[10.0, 20.0]
  doAssertRaises ValueError:
    discard addDimension(pts2d, z)

block save_points_csv:
  let pts = @[
    initPoint[float, 2]([1.5, 2.5]),
    initPoint[float, 2]([3.5, 4.5]),
  ]
  let tmp = getTempDir() / "test_points.csv"
  doAssert savePointsToCsv(tmp, pts)
  let content = readFile(tmp)
  doAssert "x0,x1" in content
  doAssert "1.5" in content
  doAssert "4.5" in content
  removeFile(tmp)

block save_vector_csv:
  let vals = @[1.0, 2.5, 3.7]
  let tmp = getTempDir() / "test_vector.csv"
  doAssert saveVectorToCsv(tmp, vals)
  let content = readFile(tmp)
  doAssert "value" in content
  doAssert "2.5" in content
  removeFile(tmp)

block extract_clusters:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([1.0, 1.0]),
    initPoint[float, 2]([2.0, 2.0]),
  ]
  let labels = @[0, 0, 1]
  let clusters = extractClusters(pts, labels)
  doAssert clusters.len == 2
  doAssert clusters[0].len == 2
  doAssert clusters[1].len == 1

echo "  ✓ utils tests"
