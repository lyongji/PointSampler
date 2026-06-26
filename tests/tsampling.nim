## Jittered grid, Latin hypercube, Gaussian clusters, random walk, relaxation.

import std/[assertions, options], std/sequtils
import point_sampler/point
import point_sampler/jittered_grid
import point_sampler/latin_hypercube_sampling
import point_sampler/gaussian_clusters
import point_sampler/random_walk_filaments
import point_sampler/relaxation

block jittered_grid_count:
  let pts = jitteredGrid[float, 2](100, [(0.0, 1.0), (0.0, 1.0)],
                                     some(uint32(42)))
  doAssert pts.len > 0

block jittered_grid_bounds:
  let pts = jitteredGrid[float, 2](200, [(0.0, 1.0), (0.0, 1.0)],
                                     some(uint32(42)))
  for p in pts:
    doAssert p[0] >= 0.0 and p[0] <= 1.0
    doAssert p[1] >= 0.0 and p[1] <= 1.0

block jittered_grid_full_params:
  let jitter: array[2, float] = [0.8, 0.8]
  let stagger: array[2, float] = [0.2, 0.0]
  let pts = jitteredGrid[float, 2](50, [(0.0, 1.0), (0.0, 1.0)],
                                     jitter, stagger, some(uint32(42)))
  doAssert pts.len > 0

block latin_hypercube_count:
  let pts = latinHypercubeSampling[float, 2](50, [(0.0, 1.0), (0.0, 1.0)])
  doAssert pts.len == 50

block latin_hypercube_bounds:
  let pts = latinHypercubeSampling[float, 2](100, [(0.0, 1.0), (0.0, 1.0)],
                                               some(uint32(42)))
  for p in pts:
    doAssert p[0] >= 0.0 and p[0] <= 1.0
    doAssert p[1] >= 0.0 and p[1] <= 1.0

block latin_hypercube_3d:
  let pts = latinHypercubeSampling[float, 3](50, [(0.0, 1.0), (0.0, 1.0), (-1.0, 1.0)])
  doAssert pts.len == 50

block gaussian_clusters_count:
  let centers = @[
    initPoint[float, 2]([0.2, 0.2]),
    initPoint[float, 2]([0.8, 0.8]),
  ]
  let pts = gaussianClusters(centers, 50, 0.05, some(uint32(42)))
  doAssert pts.len == 100

block gaussian_clusters_random_centers:
  let pts = gaussianClusters[float, 2](3, 30, [(0.0, 1.0), (0.0, 1.0)],
                                         0.05, some(uint32(42)))
  doAssert pts.len == 90

block random_walk_count_no_thickness:
  let pts = randomWalkFilaments[float, 2](2, 10, 0.1,
    [(0.0, 1.0), (0.0, 1.0)], some(uint32(42)))
  doAssert pts.len == 20

block random_walk_with_thickness:
  let pts = randomWalkFilaments[float, 2](1, 5, 0.1,
    [(0.0, 1.0), (0.0, 1.0)], some(uint32(42)),
    persistence=0.8, gaussianSigma=0.02, gaussianSamples=3)
  doAssert pts.len >= 5

block relaxation_uniformity:
  var pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([0.1, 0.1]),
    initPoint[float, 2]([0.9, 0.9]),
    initPoint[float, 2]([1.0, 1.0]),
  ]
  relaxationKtree(pts, kNeighbors=2, stepSize=0.05, iterations=3)
  doAssert pts.len == 4

block relaxation_no_change_on_empty:
  var pts: seq[Point[float, 2]] = @[]
  relaxationKtree(pts)
  doAssert pts.len == 0

echo "  ✓ sampling & relaxation tests"
