## Point type — construction, accessors, arithmetic, geometry.

import std/assertions
import point_sampler/point

block init_default:
  let p = initPoint[float, 2]()
  doAssert p.coords == [0.0, 0.0], "default init should be zero"

block init_array:
  let p = initPoint[float, 3]([1.0, 2.0, 3.0])
  doAssert p[0] == 1.0
  doAssert p[1] == 2.0
  doAssert p[2] == 3.0

block index_access:
  var p = initPoint[float, 2]()
  p[0] = 5.0
  p[1] = 7.0
  doAssert p[0] == 5.0
  doAssert p[1] == 7.0

block named_accessors_2d:
  var p = initPoint[float, 2]()
  p.x = 1.0
  p.y = 2.0
  doAssert p.x == 1.0
  doAssert p.y == 2.0

block named_accessors_3d:
  var p = initPoint[float, 3]()
  p.x = 1.0
  p.y = 2.0
  p.z = 3.0
  doAssert p.x == 1.0
  doAssert p.y == 2.0
  doAssert p.z == 3.0

block named_accessors_4d:
  var p = initPoint[float, 4]()
  p.w = 42.0
  doAssert p.w == 42.0

block add:
  let a = initPoint[float, 2]([1.0, 2.0])
  let b = initPoint[float, 2]([3.0, 4.0])
  let c = a + b
  doAssert c[0] == 4.0
  doAssert c[1] == 6.0

block sub:
  let a = initPoint[float, 2]([5.0, 8.0])
  let b = initPoint[float, 2]([1.0, 3.0])
  let c = a - b
  doAssert c[0] == 4.0
  doAssert c[1] == 5.0

block mul_elementwise:
  let a = initPoint[float, 2]([2.0, 3.0])
  let b = initPoint[float, 2]([4.0, 5.0])
  let c = a * b
  doAssert c[0] == 8.0
  doAssert c[1] == 15.0

block div_elementwise:
  let a = initPoint[float, 2]([10.0, 20.0])
  let b = initPoint[float, 2]([2.0, 4.0])
  let c = a / b
  doAssert abs(c[0] - 5.0) < 1e-12
  doAssert abs(c[1] - 5.0) < 1e-12

block scalar_ops:
  let p = initPoint[float, 2]([1.0, 2.0])
  doAssert (p + 3.0)[0] == 4.0
  doAssert (p - 1.0)[1] == 1.0
  doAssert (p * 2.0)[0] == 2.0
  doAssert (p / 2.0)[1] == 1.0

block scalar_reverse:
  let p = initPoint[float, 2]([1.0, 2.0])
  doAssert (3.0 + p)[0] == 4.0
  doAssert (3.0 * p)[1] == 6.0

block dot:
  let a = initPoint[float, 2]([1.0, 2.0])
  let b = initPoint[float, 2]([3.0, 4.0])
  doAssert dot(a, b) == 11.0

block length_squared:
  let p = initPoint[float, 2]([3.0, 4.0])
  doAssert lengthSquared(p) == 25.0

block length:
  let p = initPoint[float, 2]([3.0, 4.0])
  doAssert length(p) == 5.0

block distance:
  let a = initPoint[float, 2]([0.0, 0.0])
  let b = initPoint[float, 2]([3.0, 4.0])
  doAssert distance(a, b) == 5.0

block distance_squared:
  let a = initPoint[float, 2]([0.0, 0.0])
  let b = initPoint[float, 2]([3.0, 4.0])
  doAssert distanceSquared(a, b) == 25.0

block normalized:
  let p = initPoint[float, 2]([0.0, 3.0])
  let n = normalized(p)
  doAssert abs(n[0] - 0.0) < 1e-12
  doAssert abs(n[1] - 1.0) < 1e-12

block normalized_zero:
  let z = initPoint[float, 2]()
  let n = normalized(z)
  doAssert n.coords == [0.0, 0.0], "normalized zero should be zero"

block lerp:
  let a = initPoint[float, 2]([0.0, 0.0])
  let b = initPoint[float, 2]([10.0, 20.0])
  let m = lerp(a, b, 0.5)
  doAssert abs(m[0] - 5.0) < 1e-12
  doAssert abs(m[1] - 10.0) < 1e-12

block clamp_point:
  let p = initPoint[float, 2]([-5.0, 15.0])
  let c = clamp(p, 0.0, 10.0)
  doAssert c[0] == 0.0
  doAssert c[1] == 10.0

block equality:
  let a = initPoint[float, 2]([1.0, 2.0])
  let b = initPoint[float, 2]([1.0, 2.0])
  let c = initPoint[float, 2]([1.0, 3.0])
  doAssert a == b
  doAssert not (a == c)

echo "  ✓ point tests"
