## Halton 准随机序列。
##
## 在 N 维单位超立方体内生成 Halton 低差异序列点，
## 然后缩放到指定范围。
## 对应 C++ 版 `ps::halton<T,N>()`。

import std/[math, options]
import point, range
import internal/primes

func haltonSequence[T; N: static[int]](count, shift: int): seq[Point[T, N]] =
  ## 生成 Halton 序列（内部函数，点位于 [0,1]^N）。
  result = newSeq[Point[T, N]](count)
  for i in 0 ..< count:
    for d in 0 ..< N:
      var idx = i + 1 + shift
      let base = Primes[min(Primes.high, d)]
      var f = 1.0.T
      var val = 0.0.T
      while idx > 0:
        f = f / base.T
        val += f * (idx mod base).T
        idx = idx div base
      result[i][d] = val

proc halton*[T; N: static[int]](
    count: int;
    axisRanges: array[N, (T, T)];
    seed: Option[uint32] = none[uint32]()): seq[Point[T, N]] =
  ## 生成 Halton 准随机点并缩放到 `axisRanges`。
  ##
  ## - `count` — 点数
  ## - `axisRanges` — 每个维度的 (min, max) 范围
  ## - `seed` — 可选种子，用作序列起始偏移；同一种子产生相同序列
  ##
  ## 示例:
  ## ```nim
  ## let pts = halton[float, 2](100, [(0.0, 1.0), (0.0, 1.0)])
  ## ```
  let shift = if seed.isSome: seed.get.int else: 0
  result = haltonSequence[T, N](count, shift)
  rescalePoints(result, axisRanges)
