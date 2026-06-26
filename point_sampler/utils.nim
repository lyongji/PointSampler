## 工具函数。
##
## 提供 CSV 读写、维度操作（添加/拆分/合并）、坐标归一化等功能。
## 对应 C++ 版 `ps::utils.hpp`。

import std/[math, strformat]
import point

proc savePointsToCsv*[T; N: static[int]](
    filename: string;
    points: openArray[Point[T, N]];
    writeHeader: bool = true): bool =
  ## 将点集写入 CSV 文件。
  ##
  ## 每行一个点，坐标以逗号分隔。可选写入 "x0,x1,..." 表头。
  ##
  ## 示例:
  ## ```nim
  ## discard savePointsToCsv("pts.csv", pts)
  ## ```
  var f: File
  if not f.open(filename, fmWrite): return false
  if writeHeader:
    for i in 0 ..< N:
      f.write(&"x{i}")
      if i < N - 1: f.write(',')
    f.write('\n')
  for p in points:
    for i in 0 ..< N:
      f.write($p[i])
      if i < N - 1: f.write(',')
    f.write('\n')
  f.close(); result = true

proc saveVectorToCsv*[T](
    filename: string; values: openArray[T];
    writeHeader: bool = true;
    headerName: string = "value"): bool =
  ## 将一维数组写入 CSV 文件。
  var f: File
  if not f.open(filename, fmWrite): return false
  if writeHeader: f.write(headerName & '\n')
  for v in values: f.writeLine($v)
  f.close(); result = true

func addDimension*[T; N: static[int]](
    points: openArray[Point[T, N]];
    newDimension: openArray[T]): seq[Point[T, N + 1]] =
  ## 为每个点追加一个新坐标，维度增加 1。
  ##
  ## 示例:
  ## ```nim
  ## let pts3d = addDimension(pts2d, @[10.0, 20.0])
  ## ```
  if points.len != newDimension.len:
    raise newException(ValueError,
      "addDimension: size mismatch between points and new dimension")
  result = newSeqOfCap[Point[T, N + 1]](points.len)
  for i, p in points:
    var coords: array[N + 1, T]
    for d in 0 ..< N: coords[d] = p[d]
    coords[N] = newDimension[i]
    result.add initPoint(coords)

func normalizePoints*[T; N: static[int]](points: var seq[Point[T, N]]) =
  ## 原地归一化各轴到 [0, 1]。
  ##
  ## 若某轴均为同一值，则该轴归一化为 0。
  if points.len == 0: return
  var minVals, maxVals: array[N, T]
  for d in 0 ..< N: minVals[d] = points[0][d]; maxVals[d] = points[0][d]
  for p in points:
    for d in 0 ..< N:
      minVals[d] = min(minVals[d], p[d]); maxVals[d] = max(maxVals[d], p[d])
  for p in mitems(points):
    for d in 0 ..< N:
      let span = maxVals[d] - minVals[d]
      p[d] = if span > 0: (p[d] - minVals[d]) / span else: 0.T

func splitByDimension*[T; N: static[int]](
    points: openArray[Point[T, N]]): array[N, seq[T]] =
  ## 将 N 维点集分解为 N 个独立坐标向量。
  ##
  ## 示例:
  ## ```nim
  ## let (xs, ys) = splitByDimension(pts)
  ## ```
  for p in points:
    for d in 0 ..< N:
      result[d].add p[d]

func mergeByDimension*[T; N: static[int]](
    components: array[N, seq[T]]): seq[Point[T, N]] =
  ## 从 N 个坐标向量重建点集。
  ##
  ## 示例:
  ## ```nim
  ## let pts = mergeByDimension([xs, ys, zs])
  ## ```
  if N == 0: return
  let count = components[0].len
  for i in 1 ..< N:
    if components[i].len != count:
      raise newException(ValueError,
        "mergeByDimension: all vectors must have same length")
  result = newSeq[Point[T, N]](count)
  for i in 0 ..< count:
    for j in 0 ..< N:
      result[i][j] = components[j][i]
