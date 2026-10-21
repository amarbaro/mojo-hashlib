# mojo-hashlib

[![CI](https://github.com/amarbaro/mojo-hashlib/actions/workflows/ci.yml/badge.svg)](https://github.com/amarbaro/mojo-hashlib/actions/workflows/ci.yml)

sha256, sha1 and md5 plus shlex quote, join and split for Mojo, byte for byte the same
as Python's `hashlib` and `shlex`. `shlex` runs about 28 times faster than Python and
small hashes 2 times faster; bulk hashing of large inputs is slower than Python's
OpenSSL (see Performance).

```mojo
from hashlib import Sha256, quote

def main() raises:
    var h = Sha256()
    h.update("python train.py ")
    h.update("--seed 1")
    print(h.hexdigest())
    print(quote("it's"))   # 'it'"'"'s'
```

## Install

Requires Mojo 1.1. No system library: it is plain Mojo.

| Way | Command |
|---|---|
| Source path | `mojo run -I path/to/mojo-hashlib/src app.mojo` |
| Precompiled | `mojo precompile src/hashlib -o hashlib.mojoc`, then put it next to your code |
| Vendor | copy `src/hashlib/` into your project |

## What you get

- `Sha256`, `Sha1`, `Md5`: `update(bytes or string)` any number of times, then
  `hexdigest()` or `digest()`. Reading the digest does not end the hasher.
- `hexlify(bytes)`: lower-case hex.
- `quote(s)`, `join(args)`, `split(s)`: `shlex.quote`, `shlex.join`, `shlex.split` in
  POSIX mode. `split` raises `No closing quotation` and `No escaped character`, the
  messages CPython uses.

The API is in [docs/api.md](docs/api.md). The memory and speed design is in
[docs/design.md](docs/design.md).

## Performance

`tests/bench.mojo` against `tools/bench_oracle.py`, three runs each, same inputs and the
same results. "bulk" is 64 MiB fed through `update()` in 4 KiB pieces. "small" is 200,000
messages of about 30 bytes, each hashed with a new hasher, for each of the three
algorithms. "shlex" is 100,000 rounds of `split`, `join` and `quote` on a command line.

| | Python | mojo-hashlib |
|---|---|---|
| sha256 bulk | 27 to 28 ms | 145 to 150 ms |
| sha1 bulk | 27 to 31 ms | 60 to 63 ms |
| md5 bulk | 61 to 62 ms | 71 to 72 ms |
| small, 3 x 200k | 337 to 343 ms | 153 to 172 ms |
| shlex, 100k rounds | 1551 to 1562 ms | 49 to 58 ms |
| peak RSS | 14.6 to 14.8 MB | 11.8 to 11.9 MB |

Python's bulk hashes call OpenSSL, which uses the CPU's SHA instructions (sha256, sha1)
and hand-written assembly. This library is portable Mojo with no CPU-specific code.
An empty Mojo program uses 11.6 MB, so the library itself adds nothing measurable.

## Limits

- Bulk hashing is slower than OpenSSL: 5.3 times for sha256, 2.2 times for sha1,
  1.2 times for md5 on the machine above.
- Only sha256, sha1 and md5. No sha512, blake2, hmac or `copy()`.
- `shlex.split` is the POSIX, no-comments mode (`shlex.split(s)`). `shlex.shlex` with
  other options is not here.
- The input to `quote`, `join` and `split` is bytes of valid UTF-8. The characters left
  unquoted are ASCII only, as in CPython.
- One hasher is not safe to share across threads.

## Check

```
scripts/ci.sh
```

It runs `uv sync`, builds `tests/cases.mojo`, runs `scripts/check.sh`, then `tests/api.mojo`
and `examples/quickstart.mojo`. CI runs the same script on every push.

`scripts/check.sh` runs `tools/oracle.py` (Python `hashlib` and `shlex`) and the Mojo case
runner on the same fixed inputs, and the output must be identical: 15 inputs of 0 to
100,000 bytes (the 55, 56, 63, 64 and 65 byte block edges among them) through three
hashes, 17 quoted words, 5 joins and 9 splits including both error messages. The random
inputs are CPython's `random.Random(1)` stream, reproduced in the runner with MT19937.

## For coding agents

[skills/mojo-hashlib/SKILL.md](skills/mojo-hashlib/SKILL.md) tells an agent how to use the
library and what to avoid.

## Licence

Apache-2.0, see [LICENSE](LICENSE).
