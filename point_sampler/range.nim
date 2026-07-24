## 范围过滤与重映射。
##
## 提供轴对齐包围盒过滤、函数过滤、线性重映射和范围缩放工具函数。
## 对应 C++ 版 `ps::range.hpp`。

import std/[math, sequtils]
import point

proc filterPointsInRange*[T; N: static[int]](
    points: openArray[Point[T, N]];
    axisRanges: array[N, (T, T)]): seq[Point[T, N]] =
  ## 保留位于指定轴对齐包围盒内的点。
  ##
  ## `axisRanges` 为每个维度的 (最小值, 最大值) 范围，所有维度均满足时才保留。
  result = newSeqOfCap[Point[T, N]](points.len)
  for p in points:
    var inside = true
    for i in 0 ..< N:
      if p[i] < axisRanges[i][0] or p[i] > axisRanges[i][1]:
        inside = false
        break
    if inside:
      result.add p

proc filterPointsFunction*[T; N: static[int]](
    points: openArray[Point[T, N]];
    fn: proc(p: Point[T, N]): T): seq[Point[T, N]] =
  ## 使用用户提供的函数过滤点。保留 `fn(p) != 0` 的点。
  points.filterIt(fn(it) != 0.T)

func refitPointsToRange*[T; N: static[int]](
    points: var seq[Point[T, N]];
    targetRanges: array[N, (T, T)]) =
  ## 线性重映射点集，使其 AABB 适配到 `targetRanges`。
  ##
  ## 计算输入点的轴对齐包围盒，然后线性缩放/平移各点到目标范围。
  ## 若某维度为常量值（min == max），则使用目标范围的中点。
  if points.len == 0: return
  var minVals, maxVals: array[N, T]
  for d in 0 ..< N:
    minVals[d] = points[0][d]
    maxVals[d] = points[0][d]
  for p in points:
    for d in 0 ..< N:
      minVals[d] = min(minVals[d], p[d])
      maxVals[d] = max(maxVals[d], p[d])
  for p in mitems(points):
    for d in 0 ..< N:
      let inMin = minVals[d]
      let inMax = maxVals[d]
      let outMin = targetRanges[d][0]
      let outMax = targetRanges[d][1]
      if abs(inMax - inMin) < 1e-12.T:
        p[d] = (outMin + outMax) / 2.T
      else:
        let t = (p[d] - inMin) / (inMax - inMin)
        p[d] = outMin + t * (outMax - outMin)

func rescalePoints*[T; N: static[int]](
    points: var seq[Point[T, N]];
    ranges: array[N, (T, T)]) =
  ## 将归一化点集（[0,1]^N）缩放到指定的 `ranges`。
  ##
  ## 假设输入点在 [0,1]^N 内，不做边界检查。
  for p in mitems(points):
    for d in 0 ..< N:
      p[d] = ranges[d][0] + p[d] * (ranges[d][1] - ranges[d][0])
