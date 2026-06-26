## Metrics: nearest neighbors, density, angular distribution, etc.

import std/assertions, std/math
import point_sampler/point
import point_sampler/metrics

block nearest_neighbors_basic:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([1.0, 0.0]),
    initPoint[float, 2]([0.0, 1.0]),
    initPoint[float, 2]([1.0, 1.0]),
  ]
  let nbrs = nearestNeighborsIndices(pts, 2)
  doAssert nbrs.len == pts.len
  for n in nbrs:
    doAssert n.len == 2

block first_neighbor_distance:
  var pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([0.01, 0.0]),
    initPoint[float, 2]([0.5, 0.5]),
  ]
  let dSq = firstNeighborDistanceSquared(pts)
  doAssert dSq.len == 3
  doAssert dSq[0] < dSq[2], "close pair should have smaller distance"

block local_density:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([0.01, 0.01]),
    initPoint[float, 2]([0.5, 0.5]),
    initPoint[float, 2]([0.51, 0.51]),
  ]
  let dens = localDensityKnn(pts, 2)
  doAssert dens.len == 4
  doAssert dens[0] > 0
  doAssert dens[2] > 0

block distance_to_boundary:
  let pts = @[
    initPoint[float, 2]([0.2, 0.8]),
    initPoint[float, 2]([0.9, 0.1]),
  ]
  let d = distanceToBoundary(pts, [(0.0, 1.0), (0.0, 1.0)])
  doAssert d.len == 2
  doAssert abs(d[0] - 0.2) < 1e-9
  doAssert abs(d[1] - 0.1) < 1e-9

block radial_distribution:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([1.0, 0.0]),
  ]
  let (radii, g) = radialDistribution(pts, [(0.0, 1.0), (0.0, 1.0)],
                                      0.5, 2.0)
  doAssert radii.len > 0
  doAssert g.len > 0

block angle_distribution:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([1.0, 0.0]),
    initPoint[float, 2]([0.0, 1.0]),
    initPoint[float, 2]([1.0, 1.0]),
  ]
  let (angles, gTheta) = angleDistributionNeighbors(pts, 0.2, 3)
  doAssert angles.len > 0
  doAssert gTheta.len > 0

echo "  ✓ metrics tests"
