"""Same work as tests/bench.mojo with Python hashlib and shlex."""
import hashlib, shlex, time
chunk = bytes((i * 7) & 255 for i in range(4096))
def bulk(algo):
    h = hashlib.new(algo)
    for _ in range(16384): h.update(chunk)
    return h.hexdigest()
t0 = time.perf_counter(); r256 = bulk("sha256")
t1 = time.perf_counter(); r1 = bulk("sha1")
t2 = time.perf_counter(); r5 = bulk("md5")
t3 = time.perf_counter()
s = 0
for algo in ("sha256", "sha1", "md5"):
    for i in range(200000):
        h = hashlib.new(algo)
        h.update(f"python train.py --seed {i}".encode())
        s += h.digest()[0]
t4 = time.perf_counter()
n = 0
for i in range(100000):
    argv = shlex.split(f"python train.py --seed {i} --tag 'a b' \"it's\" x\\ y")
    n += len(argv) + len(shlex.join(argv).encode()) + len(shlex.quote(argv[-1]).encode())
t5 = time.perf_counter()
ms = lambda a, b: int((b - a) * 1000)
print("sha256_ms", ms(t0, t1), "sha1_ms", ms(t1, t2), "md5_ms", ms(t2, t3), "small_ms", ms(t3, t4), "shlex_ms", ms(t4, t5))
print("check", r256, r1, r5, s, n)
