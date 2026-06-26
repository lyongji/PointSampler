## K-means, DBSCAN, and percolation clustering.

import std/assertions, std/sequtils
import point_sampler/point
import point_sampler/kmeans_clustering
import point_sampler/dbscan_clustering
import point_sampler/percolation_clustering

block kmeans_basic:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([0.1, 0.1]),
    initPoint[float, 2]([0.9, 0.9]),
    initPoint[float, 2]([1.0, 1.0]),
  ]
  let (centroids, labels) = kmeansClustering(pts, 2)
  doAssert centroids.len == 2
  doAssert labels.len == pts.len

block kmeans_labels_assigned:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([0.01, 0.01]),
    initPoint[float, 2]([0.02, 0.02]),
    initPoint[float, 2]([1.0, 1.0]),
    initPoint[float, 2]([0.99, 0.99]),
    initPoint[float, 2]([0.98, 0.98]),
  ]
  let (_, labels) = kmeansClustering(pts, 2, normalizeData=false)
  # first three should be in same cluster, last three in the other
  doAssert labels[0] == labels[1], "close cluster points should share label"
  doAssert labels[0] == labels[2]
  doAssert labels[3] == labels[4]
  doAssert labels[3] == labels[5]

block kmeans_empty:
  let (centroids, labels) = kmeansClustering[float, 2](@[], 3)
  doAssert centroids.len == 0
  doAssert labels.len == 0

block kmeans_single_cluster:
  let pts = newSeqWith(10, initPoint[float, 2]([0.5, 0.5]))
  let (centroids, labels) = kmeansClustering(pts, 1)
  doAssert centroids.len == 1
  doAssert labels.len == 10
  for l in labels: doAssert l == 0

block dbscan_basic:
  let pts = @[
    initPoint[float, 2]([0.0, 0.0]),
    initPoint[float, 2]([0.03, 0.0]),
    initPoint[float, 2]([0.06, 0.0]),
    initPoint[float, 2]([0.9, 0.9]),
  ]
  let labels = dbscanClustering(pts, 0.1, 2)
  # first three should form a cluster
  doAssert labels[0] >= 0
  doAssert labels[0] == labels[1]
  doAssert labels[0] == labels[2]
  # far point might be noise or different cluster
  doAssert labels[3] != labels[0]

block dbscan_empty:
  let labels = dbscanClustering[float, 2](@[], 0.1, 3)
  doAssert labels.len == 0

block percolation_basic:
  let pts = @[
    initPoint[float, 2]([0.1, 0.2]),
    initPoint[float, 2]([0.15, 0.22]),
    initPoint[float, 2]([0.9, 0.9]),
  ]
  let labels = percolationClustering(pts, 0.1)
  doAssert labels[0] == labels[1], "close points should be connected"
  doAssert labels[0] != labels[2], "far point should be separate"

block percolation_empty:
  let labels = percolationClustering[float, 2](@[], 0.1)
  doAssert labels.len == 0

echo "  ✓ clustering tests"
