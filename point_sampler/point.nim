## Point — N 维点/向量。
##
## `Point[T, N]` 是一个固定维度的泛型点类型，支持逐元素算术运算、
## 几何函数（点积、长度、距离、线性插值等）以及 2D/3D/4D 快捷访问。
## 对应 C++ 版 `ps::Point<T,N>`。

import std/math

type
  Point*[T; N: static[int]] = object
    ## N 维点，坐标为数组 `array[N, T]`。
    coords*: array[N, T]

func initPoint*[T; N: static[int]](v: array[N, T]): Point[T, N] =
  ## 从数组创建 Point。
  Point[T, N](coords: v)

func initPoint*[T; N: static[int]](): Point[T, N] =
  ## 创建零向量 Point。
  Point[T, N](coords: default(array[N, T]))

template `[]`*[T; N: static[int]](p: Point[T, N]; i: int): T =
  ## 按索引访问坐标。
  p.coords[i]

template `[]=`*[T; N: static[int]](p: var Point[T, N]; i: int; val: T) =
  ## 按索引设置坐标。
  p.coords[i] = val

# -- 2D/3D/4D 快捷访问器

template x*[T; N: static[int]](p: Point[T, N]): T = p.coords[0]
template y*[T; N: static[int]](p: Point[T, N]): T = p.coords[1]
template z*[T; N: static[int]](p: Point[T, N]): T = p.coords[2]
template w*[T; N: static[int]](p: Point[T, N]): T = p.coords[3]

template x*[T; N: static[int]](p: var Point[T, N]): var T = p.coords[0]
template y*[T; N: static[int]](p: var Point[T, N]): var T = p.coords[1]
template z*[T; N: static[int]](p: var Point[T, N]): var T = p.coords[2]
template w*[T; N: static[int]](p: var Point[T, N]): var T = p.coords[3]

# -- 算术运算

func `+`*[T; N: static[int]](a, b: Point[T, N]): Point[T, N] =
  ## 逐元素加法。
  for i in 0 ..< N: result[i] = a[i] + b[i]

func `-`*[T; N: static[int]](a, b: Point[T, N]): Point[T, N] =
  ## 逐元素减法。
  for i in 0 ..< N: result[i] = a[i] - b[i]

func `*`*[T; N: static[int]](a, b: Point[T, N]): Point[T, N] =
  ## 逐元素乘法 (Hadamard 积)。
  for i in 0 ..< N: result[i] = a[i] * b[i]

func `/`*[T; N: static[int]](a, b: Point[T, N]): Point[T, N] =
  ## 逐元素除法。
  for i in 0 ..< N: result[i] = a[i] / b[i]

# 标量运算
func `+`*[T; N: static[int]](p: Point[T, N]; s: T): Point[T, N] =
  ## 标量加法。
  for i in 0 ..< N: result[i] = p[i] + s

func `-`*[T; N: static[int]](p: Point[T, N]; s: T): Point[T, N] =
  ## 标量减法。
  for i in 0 ..< N: result[i] = p[i] - s

func `*`*[T; N: static[int]](p: Point[T, N]; s: T): Point[T, N] =
  ## 标量乘法。
  for i in 0 ..< N: result[i] = p[i] * s

func `/`*[T; N: static[int]](p: Point[T, N]; s: T): Point[T, N] =
  ## 标量除法。
  for i in 0 ..< N: result[i] = p[i] / s

func `*`*[T; N: static[int]](s: T; p: Point[T, N]): Point[T, N] = p * s
  ## 标量乘法（左乘）。

func `+`*[T; N: static[int]](s: T; p: Point[T, N]): Point[T, N] = p + s
  ## 标量加法（左加）。

# -- 几何函数

func dot*[T; N: static[int]](a, b: Point[T, N]): T =
  ## 点积。
  for i in 0 ..< N: result += a[i] * b[i]

func lengthSquared*[T; N: static[int]](a: Point[T, N]): T =
  ## 向量长度的平方。
  dot(a, a)

func length*[T; N: static[int]](a: Point[T, N]): T =
  ## 向量长度（L2 范数）。
  sqrt(lengthSquared(a))

func normalized*[T; N: static[int]](a: Point[T, N]): Point[T, N] =
  ## 归一化向量。零向量返回零向量。
  let len = length(a)
  if len == 0: Point[T, N]()
  else: a / len

func distanceSquared*[T; N: static[int]](a, b: Point[T, N]): T =
  ## 两点间距离的平方。
  lengthSquared(a - b)

func distance*[T; N: static[int]](a, b: Point[T, N]): T =
  ## 两点间欧几里得距离。
  sqrt(distanceSquared(a, b))

func lerp*[T; N: static[int]](a, b: Point[T, N]; t: T): Point[T, N] =
  ## 线性插值：`a + (b - a) * t`。
  a + (b - a) * t

func clamp*[T; N: static[int]](p: Point[T, N]; minVal, maxVal: T): Point[T, N] =
  ## 将每个坐标限制在 `[minVal, maxVal]` 范围内。
  for i in 0 ..< N:
    result[i] = clamp(p[i], minVal, maxVal)

func `==`*[T; N: static[int]](a, b: Point[T, N]): bool =
  ## 逐元素相等比较。
  a.coords == b.coords
