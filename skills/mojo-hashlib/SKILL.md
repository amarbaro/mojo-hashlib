---
name: mojo-hashlib
description: "Hash with sha256, sha1 or md5 and quote, join or split shell words in Mojo with the mojo-hashlib library, results identical to Python hashlib and shlex. Use when Mojo code needs a digest, a cache key, or to build or parse a shell command line."
---

# mojo-hashlib

sha256, sha1, md5 and shlex quote/join/split for Mojo 1.1. Plain Mojo, no system
library. Results are checked byte for byte against Python's `hashlib` and `shlex`.

## Install

`mojo run -I <repo>/src app.mojo`, or `mojo precompile <repo>/src/hashlib -o hashlib.mojoc`,
or copy `src/hashlib/`.

## Use

```mojo
from hashlib import Sha256, quote, join, split

def main() raises:
    var h = Sha256()
    h.update("python train.py ")      # String, StringSlice or Span[UInt8]
    h.update("--seed 1")
    print(h.hexdigest())               # same as hashlib.sha256(...).hexdigest()

    var argv: List[String] = ["sh", "-c", "echo $X"]
    var line = join(argv)              # sh -c 'echo $X'
    var back = split(line)             # raises on an unterminated quote
```

## Rules

- **Feed in pieces; never join the input first.** `update` hashes whole blocks from the
  caller's memory. Piece boundaries do not change the digest.
- `hexdigest()` and `digest()` do not end the hasher. `update` after them continues.
- `Sha256`, `Sha1`, `Md5` are one type, `Hasher[algo]`. For generic code use
  `def f[algo: Int](...)` and `Hasher[algo]()`; `Sha256.algo` is the parameter.
- `digest()` returns an `Array[UInt8, N]`, N = `Sha256.digest_size` (32), 20 or 16.
- md5 and sha1 are for cache keys and compatibility, not for security.
- `quote` every untrusted word before it goes into a shell command line. `join` does
  this for a list.
- `split` raises `Error("No closing quotation")` or `Error("No escaped character")`:
  call it inside `try` or a `raises` function.
- No sha512, blake2, hmac. Bulk sha256 is about 5 times slower than Python's OpenSSL; for
  gigabytes, call out to `sha256sum`.

## Errors

Only `split` raises. Show the message as it is.
