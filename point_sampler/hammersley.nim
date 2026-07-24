## Hammersley 准随机序列。
##
## 在 N 维单位超立方体内生成 Hammersley 低差异序列点，
## 然后缩放到指定范围。
## 对应 C++ 版 `ps::hammersley<T,N>()`。

import std/[math, options]
import point, range
import internal/primes

func hammersleySequence[T; N: static[int]](count, shift: int): seq[Point[T, N]] =
  ## 生成 Hammersley 序列（内部函数，点位于 [0,1]^N）。
  result = newSeq[Point[T, N]](count)
  for i in 0 ..< count:
    result[i][0] = i.T / count.T
    for d in 1 ..< N:
      let base = Primes[min(Primes.high, d - 1)]
      var n = i + shift
      var q = 0.0.T
      var bk = 1.0.T / base.T
      while n > 0:
        q += (n mod base).T * bk
        n = n div base
        bk /= base.T
      result[i][d] = q

proc hammersley*[T; N: static[int]](
    count: int;
    axisRanges: array[N, (T, T)];
    seed: Option[uint32] = none[uint32]()): seq[Point[T, N]] =
  ## 生成 Hammersley 准随机点并缩放到 `axisRanges`。
  ##
  ## 第一维均匀分布，其余维度使用 van der Corput 序列。
  ##
  ## - `count` — 点数
  ## - `axisRanges` — 每个维度的 (min, max) 范围
  ## - `seed` — 可选种子，用作序列起始偏移
  ##
  ## 示例:
  ## ```nim
  ## let pts = hammersley[float, 3](512, [(-1.0, 1.0), (-1.0, 1.0), (0.0, 1.0)])
  ## ```
  let shift = if seed.isSome: seed.get.int else: 0
  result = hammersleySequence[T, N](count, shift)
  rescalePoints(result, axisRanges)
