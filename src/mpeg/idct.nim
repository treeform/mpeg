## Fixed-point butterfly shared by the portable and AVX2 transforms.
template idctPass*(get, put: untyped) =
  mixin `+`, `-`, `*`, `shr`
  let
    b1 = get(4)
    b3 = get(2) + get(6)
    b4 = get(5) - get(3)
    tmp1 = get(1) + get(7)
    tmp2 = get(3) + get(5)
    b6 = get(1) - get(7)
    b7 = tmp1 + tmp2
    x4 = 2 * b6 - b4 + ((60 * b4 - 39 * b6 + 128) shr 8) - b7
    odd = tmp1 - tmp2
    x0 = x4 - (odd + ((106 * odd + 128) shr 8))
    x1 = get(0) - b1
    even = get(2) - get(6)
    x2 = even + ((106 * even + 128) shr 8) - b3
    x3 = get(0) + b1
    y3 = x1 + x2
    y4 = x3 + b3
    y5 = x1 - x2
    y6 = x3 - b3
    y7 = -x0 - (2 * b4 + b6 + ((128 - 39 * b4 - 60 * b6) shr 8))
  put(0, b7 + y4)
  put(1, x4 + y3)
  put(2, y5 - x0)
  put(3, y6 - y7)
  put(4, y6 + y7)
  put(5, x0 + y5)
  put(6, y3 - x4)
  put(7, y4 - b7)

# AC coefficients are clipped to [-2048, 2047] and premultiplied by at
# most 62. An 8-point butterfly grows by less than 25x, so its first-pass
# outputs fit in 3.2 million and its second-pass outputs in 80 million.
# Splitting 473, 196 and 362 into multiples of 256 plus small remainders
# bounds the largest product by 4 * 3.2 million * 106, within int32.
{.push checks: off.}
proc idctPortable*(coefficients: var array[64, cint]) =
  # Whole DC units add equally to every output. Only the low eight bits
  # participate in rounding, even when the predictor is negative.
  let dc = coefficients[0] shr 8
  coefficients[0] = coefficients[0] and 255

  template transform(column: static bool, base: int) =
    template get(k: static int): cint =
      when column: coefficients[base + 8 * k]
      else: coefficients[base + k]
    template put(k: static int, value: cint) =
      when column: coefficients[base + 8 * k] = value
      else: coefficients[base + k] = dc + ((value + 128) shr 8)
    idctPass(get, put)

  for col in 0..<8:
    transform(true, col)
  for row in 0..<8:
    transform(false, 8 * row)
{.pop.}
