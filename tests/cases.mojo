# Case runner for scripts/check.sh: prints the lines tools/oracle.py prints.
# The random blobs are CPython's random.Random(1).randrange(256) stream, reproduced by MT19937 below.
from hashlib import Hasher, Sha256, Sha1, Md5, hexlify, quote, join, split


struct MT:
    var mt: List[UInt32]
    var i: Int

    def __init__(out self, seed: UInt32):
        self.mt = List[UInt32](length=624, fill=0)
        self.i = 624
        self.mt[0] = 19650218
        for k in range(1, 624):
            self.mt[k] = 1812433253 * (self.mt[k - 1] ^ (self.mt[k - 1] >> 30)) + UInt32(k)
        var i = 1
        for _ in range(624):  # init_by_array([seed])
            self.mt[i] = (self.mt[i] ^ ((self.mt[i - 1] ^ (self.mt[i - 1] >> 30)) * 1664525)) + seed
            i += 1
            if i >= 624:
                self.mt[0] = self.mt[623]
                i = 1
        for _ in range(623):
            self.mt[i] = (self.mt[i] ^ ((self.mt[i - 1] ^ (self.mt[i - 1] >> 30)) * 1566083941)) - UInt32(i)
            i += 1
            if i >= 624:
                self.mt[0] = self.mt[623]
                i = 1
        self.mt[0] = 0x80000000

    def next32(mut self) -> UInt32:
        if self.i >= 624:
            for k in range(624):
                var y = (self.mt[k] & 0x80000000) | (self.mt[(k + 1) % 624] & 0x7FFFFFFF)
                var v = self.mt[(k + 397) % 624] ^ (y >> 1)
                self.mt[k] = v ^ (UInt32(0x9908B0DF) if (y & 1) == 1 else UInt32(0))
            self.i = 0
        var y = self.mt[self.i]
        self.i += 1
        y ^= y >> 11
        y ^= (y << 7) & 0x9D2C5680
        y ^= (y << 15) & 0xEFC60000
        return y ^ (y >> 18)

    def byte(mut self) -> UInt8:  # randrange(256): getrandbits(9), retry while >= 256
        while True:
            var r = self.next32() >> 23
            if r < 256:
                return UInt8(r)


def hash_line[algo: Int](name: String, i: Int, data: Span[UInt8, _]):
    var h = Hasher[algo]()
    h.update(data)
    print("hash", name, i, len(data), h.hexdigest())


def hx(s: String) -> String:
    return hexlify(s.as_bytes())


def main() raises:
    var rng = MT(1)
    var blobs = List[List[UInt8]]()
    blobs.append([])
    blobs.append([97])
    blobs.append([97, 98, 99])
    for n in [1, 55, 56, 63, 64, 65]:
        blobs.append(List[UInt8](length=n, fill=0))
    blobs.append(List(String("çé日本").as_bytes()))
    blobs.append(List(String("python train.py --seed 1").as_bytes()))
    for n in [1, 100, 1000, 100000]:
        var b = List[UInt8](capacity=n)
        for _ in range(n):
            b.append(rng.byte())
        blobs.append(b^)
    for i in range(len(blobs)):
        hash_line[Sha256.algo]("sha256", i, blobs[i])
        hash_line[Sha1.algo]("sha1", i, blobs[i])
        hash_line[Md5.algo]("md5", i, blobs[i])
    var words: List[String] = ["", "a", "a b", "it's", 'say "hi"', "$HOME", "a\tb", "a\nb", "çé", "--flag=1", "*.py", "`x`", "a'b\"c", "~", "#x", "=", "-"]
    for w in words:
        print("quote", hx(w), quote(w))
    var argvs: List[List[String]] = [["python", "train.py"], ["sh", "-c", "echo $X; exit 3"], ["a b", "it's"], [""], ["x", "x", "x"]]
    for argv in argvs:
        var hexes = List[String]()
        for a in argv:
            hexes.append(hx(a))
        print("join", "|".join(hexes), join(argv))
    var splits: List[String] = ["a b c", "a 'b c' d", 'a "b c" d', "a\\ b", "'it'\\''s'", '"$X"', "  lead  trail  ", "a#b", "unterminated 'x"]
    for s in splits:
        try:
            var hexes = List[String]()
            for t in split(s):
                hexes.append(hx(t))
            print("split", hx(s), "|".join(hexes))
        except e:
            print("split", hx(s), "ERR", String(e))
