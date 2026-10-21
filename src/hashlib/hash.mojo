"""sha256, sha1 and md5 as one generic hasher: a 64-byte block buffer and a few state words."""
from std.bit import byte_swap, rotate_bits_left as rol, rotate_bits_right as ror
from std.collections import Array

comptime SHA256 = 0
comptime SHA1 = 1
comptime MD5 = 2
comptime Sha256 = Hasher[SHA256]
comptime Sha1 = Hasher[SHA1]
comptime Md5 = Hasher[MD5]

comptime _K256: Array[UInt32, 64] = [
    0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5, 0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
    0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3, 0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
    0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC, 0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
    0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7, 0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
    0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13, 0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
    0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3, 0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
    0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5, 0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
    0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208, 0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2]
comptime _KMD5: Array[UInt32, 64] = [
    0xD76AA478, 0xE8C7B756, 0x242070DB, 0xC1BDCEEE, 0xF57C0FAF, 0x4787C62A, 0xA8304613, 0xFD469501,
    0x698098D8, 0x8B44F7AF, 0xFFFF5BB1, 0x895CD7BE, 0x6B901122, 0xFD987193, 0xA679438E, 0x49B40821,
    0xF61E2562, 0xC040B340, 0x265E5A51, 0xE9B6C7AA, 0xD62F105D, 0x02441453, 0xD8A1E681, 0xE7D3FBC8,
    0x21E1CDE6, 0xC33707D6, 0xF4D50D87, 0x455A14ED, 0xA9E3E905, 0xFCEFA3F8, 0x676F02D9, 0x8D2A4C8A,
    0xFFFA3942, 0x8771F681, 0x6D9D6122, 0xFDE5380C, 0xA4BEEA44, 0x4BDECFA9, 0xF6BB4B60, 0xBEBFBC70,
    0x289B7EC6, 0xEAA127FA, 0xD4EF3085, 0x04881D05, 0xD9D4D039, 0xE6DB99E5, 0x1FA27CF8, 0xC4AC5665,
    0xF4292244, 0x432AFF97, 0xAB9423A7, 0xFC93A039, 0x655B59C3, 0x8F0CCC92, 0xFFEFF47D, 0x85845DD1,
    0x6FA87E4F, 0xFE2CE6E0, 0xA3014314, 0x4E0811A1, 0xF7537E82, 0xBD3AF235, 0x2AD7D2BB, 0xEB86D391]
comptime _K1: Array[UInt32, 4] = [0x5A827999, 0x6ED9EBA1, 0x8F1BBCDC, 0xCA62C1D6]
comptime _SMD5: Array[UInt8, 16] = [7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16, 23, 6, 10, 15, 21]
comptime _INIT: Array[UInt32, 24] = [
    0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A, 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
    0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0, 0, 0, 0,
    0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0, 0, 0, 0]
comptime _HEX = "0123456789abcdef"


@always_inline
def _word[be: Bool](p: Pointer[UInt8, _], i: Int) -> UInt32:
    var w = p.unsafe_offset(4 * i).unsafe_bitcast[UInt32]().unsafe_load[width=1, alignment=1]()
    comptime if be:
        return byte_swap(w)
    else:
        return w


def _sha256(mut h: Array[UInt32, 8], p: Pointer[UInt8, _]):
    var w = Array[UInt32, 16](uninitialized=True)
    comptime for i in range(16):
        w[i] = _word[True](p, i)
    var a = h[0]
    var b = h[1]
    var c = h[2]
    var d = h[3]
    var e = h[4]
    var f = h[5]
    var g = h[6]
    var hh = h[7]
    comptime for i in range(64):
        comptime k = _K256[i]
        comptime if i >= 16:
            var x = w[(i + 1) % 16]
            var y = w[(i + 14) % 16]
            w[i % 16] += (ror[7](x) ^ ror[18](x) ^ (x >> 3)) + w[(i + 9) % 16] + (ror[17](y) ^ ror[19](y) ^ (y >> 10))
        var t1 = hh + (ror[6](e) ^ ror[11](e) ^ ror[25](e)) + ((e & f) ^ (~e & g)) + k + w[i % 16]
        var t2 = (ror[2](a) ^ ror[13](a) ^ ror[22](a)) + ((a & b) ^ (a & c) ^ (b & c))
        hh = g
        g = f
        f = e
        e = d + t1
        d = c
        c = b
        b = a
        a = t1 + t2
    h[0] += a
    h[1] += b
    h[2] += c
    h[3] += d
    h[4] += e
    h[5] += f
    h[6] += g
    h[7] += hh


def _sha1(mut h: Array[UInt32, 8], p: Pointer[UInt8, _]):
    var w = Array[UInt32, 16](uninitialized=True)
    comptime for i in range(16):
        w[i] = _word[True](p, i)
    var a = h[0]
    var b = h[1]
    var c = h[2]
    var d = h[3]
    var e = h[4]
    comptime for i in range(80):
        var f: UInt32
        comptime k = _K1[i // 20]
        comptime if i < 20:
            f = (b & c) | (~b & d)
        elif i < 40 or i >= 60:
            f = b ^ c ^ d
        else:
            f = (b & c) | (b & d) | (c & d)
        comptime if i >= 16:
            w[i % 16] = rol[1](w[(i + 13) % 16] ^ w[(i + 8) % 16] ^ w[(i + 2) % 16] ^ w[i % 16])
        var t = rol[5](a) + f + e + k + w[i % 16]
        e = d
        d = c
        c = rol[30](b)
        b = a
        a = t
    h[0] += a
    h[1] += b
    h[2] += c
    h[3] += d
    h[4] += e


def _md5(mut h: Array[UInt32, 8], p: Pointer[UInt8, _]):
    var a = h[0]
    var b = h[1]
    var c = h[2]
    var d = h[3]
    comptime for i in range(64):
        var f: UInt32
        comptime g = i if i < 16 else ((5 * i + 1) % 16 if i < 32 else ((3 * i + 5) % 16 if i < 48 else (7 * i) % 16))
        comptime r = Int(_SMD5[(i // 16) * 4 + i % 4])
        comptime if i < 16:
            f = (b & c) | (~b & d)
        elif i < 32:
            f = (d & b) | (~d & c)
        elif i < 48:
            f = b ^ c ^ d
        else:
            f = c ^ (b | ~d)
        comptime km = _KMD5[i]
        var t = a + f + km + _word[False](p, g)
        a = d
        d = c
        c = b
        b = b + rol[r](t)
    h[0] += a
    h[1] += b
    h[2] += c
    h[3] += d


struct Hasher[algo: Int](Movable):
    """Incremental hasher. Fields widest first; `buf` holds at most one partial block."""
    var nbytes: UInt64
    var h: Array[UInt32, 8]
    var buf: Array[UInt8, 64]
    var fill: Int

    comptime digest_size = 32 if Self.algo == SHA256 else (20 if Self.algo == SHA1 else 16)

    def __init__(out self):
        self.nbytes = 0
        self.fill = 0
        self.buf = Array[UInt8, 64](uninitialized=True)
        self.h = Array[UInt32, 8](uninitialized=True)
        var init = materialize[_INIT]()
        for i in range(8):
            self.h[i] = init[Self.algo * 8 + i]

    @staticmethod
    def _compress(mut h: Array[UInt32, 8], p: Pointer[UInt8, _]):
        comptime if Self.algo == SHA256:
            _sha256(h, p)
        elif Self.algo == SHA1:
            _sha1(h, p)
        else:
            _md5(h, p)

    def update(mut self, data: Span[UInt8, _]):
        var n = len(data)
        var p = data.unsafe_ptr()
        var i = 0
        self.nbytes += UInt64(n)
        if self.fill > 0:
            var take = min(64 - self.fill, n)
            for j in range(take):
                self.buf[self.fill + j] = data[j]
            self.fill += take
            i = take
            if self.fill < 64:
                return
            Self._compress(self.h, self.buf.unsafe_ptr())
            self.fill = 0
        while n - i >= 64:
            Self._compress(self.h, p.unsafe_offset(i))
            i += 64
        for j in range(n - i):
            self.buf[j] = data[i + j]
        self.fill = n - i

    def update(mut self, s: StringSlice[_]):
        self.update(s.as_bytes())

    def digest(self) -> Array[UInt8, Self.digest_size]:
        """The digest; the hasher stays usable and can be updated again."""
        var h = self.h.copy()
        var b = self.buf.copy()
        var n = self.fill
        b[n] = 0x80
        for j in range(n + 1, 64):
            b[j] = 0
        if n + 1 > 56:
            Self._compress(h, b.unsafe_ptr())
            for j in range(56):
                b[j] = 0
        var bits = self.nbytes << 3
        for j in range(8):
            comptime if Self.algo == MD5:
                b[56 + j] = UInt8((bits >> UInt64(8 * j)) & 0xFF)
            else:
                b[63 - j] = UInt8((bits >> UInt64(8 * j)) & 0xFF)
        Self._compress(h, b.unsafe_ptr())
        var out = Array[UInt8, Self.digest_size](uninitialized=True)
        for i in range(Self.digest_size // 4):
            for j in range(4):
                comptime if Self.algo == MD5:
                    out[4 * i + j] = UInt8((h[i] >> UInt32(8 * j)) & 0xFF)
                else:
                    out[4 * i + 3 - j] = UInt8((h[i] >> UInt32(8 * j)) & 0xFF)
        return out^

    def hexdigest(self) -> String:
        var d = self.digest()
        return hexlify(Span(d))


def hexlify(data: Span[UInt8, _]) -> String:
    """Lower-case hex of `data`, written once into a sized buffer."""
    var out = List[UInt8](length=2 * len(data), fill=0)
    var digits = _HEX.as_bytes()
    for i in range(len(data)):
        out[2 * i] = digits[Int(data[i] >> 4)]
        out[2 * i + 1] = digits[Int(data[i] & 15)]
    return String(unsafe_from_utf8=Span(out))
