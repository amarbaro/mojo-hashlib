# Same work as tools/bench_oracle.py: 64 MiB through each hash in 4 KiB updates,
# 200k short messages hashed one by one, 100k shlex quote + join + split round trips.
from std.time import perf_counter_ns
from hashlib import Hasher, Sha256, Sha1, Md5, hexlify, quote, join, split


def bulk[algo: Int](chunk: Span[UInt8, _]) -> String:
    var h = Hasher[algo]()
    for _ in range(16384):
        h.update(chunk)
    return h.hexdigest()


def small[algo: Int]() -> Int:
    var sum = 0
    for i in range(200000):
        var h = Hasher[algo]()
        h.update("python train.py --seed " + String(i))
        sum += Int(h.digest()[0])
    return sum


def main() raises:
    var chunk = List[UInt8](length=4096, fill=0)
    for i in range(4096):
        chunk[i] = UInt8(i * 7 & 255)
    var t0 = perf_counter_ns()
    var r256 = bulk[Sha256.algo](chunk)
    var t1 = perf_counter_ns()
    var r1 = bulk[Sha1.algo](chunk)
    var t2 = perf_counter_ns()
    var r5 = bulk[Md5.algo](chunk)
    var t3 = perf_counter_ns()
    var s = small[Sha256.algo]() + small[Sha1.algo]() + small[Md5.algo]()
    var t4 = perf_counter_ns()
    var n = 0
    for i in range(100000):
        var argv = split("python train.py --seed " + String(i) + " --tag 'a b' \"it's\" x\\ y")
        n += len(argv) + join(argv).byte_length() + quote(argv[len(argv) - 1]).byte_length()
    var t5 = perf_counter_ns()
    print("sha256_ms", (t1 - t0) // 1000000, "sha1_ms", (t2 - t1) // 1000000, "md5_ms", (t3 - t2) // 1000000, "small_ms", (t4 - t3) // 1000000, "shlex_ms", (t5 - t4) // 1000000)
    print("check", r256, r1, r5, s, n)
