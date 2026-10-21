# API

```mojo
from hashlib import Hasher, Sha256, Sha1, Md5, hexlify, quote, join, split
```

Every behaviour below is asserted in `tests/api.mojo` or diffed against Python in
`scripts/check.sh`.

## Hashers

`Sha256`, `Sha1` and `Md5` are the same type, `Hasher[algo]`, with the algorithm as a
compile-time parameter (`Sha256.algo`, `Sha1.algo`, `Md5.algo`). Write generic code as
`def f[algo: Int](...)` and `Hasher[algo]()`.

| Method | Does |
|---|---|
| `Sha256()` | new hasher, empty input |
| `update(bytes)` | feed a `Span[UInt8]` (a `List[UInt8]` works) |
| `update(s)` | feed the bytes of a `StringSlice` (a `String` works) |
| `hexdigest() -> String` | lower-case hex digest |
| `digest() -> Array[UInt8, N]` | the raw digest, N = `digest_size` |
| `digest_size` | 32, 20 or 16 (`Sha256.digest_size`) |

- Splitting the input into any pieces, down to one byte per `update`, gives the same
  digest as one `update`.
- `digest()` and `hexdigest()` do not end the hasher: call them, `update` again, call
  them again; the second digest covers all the input so far.
- An empty input has the usual digest (`e3b0c442...` for sha256).

## `hexlify(bytes) -> String`

Lower-case hex of a `Span[UInt8]`: `[0, 15, 16, 255]` gives `000f10ff`.

## shlex

| Function | As Python |
|---|---|
| `quote(s) -> String` | `shlex.quote` |
| `join(args) -> String` | `shlex.join`, `args` is a `Span[String]` (a `List[String]` works) |
| `split(s) raises -> List[String]` | `shlex.split(s)`, POSIX mode, comments off |

`quote`:
- the empty string gives `''`;
- a string made only of `A-Z a-z 0-9 _ @ % + = : , . / -` is returned unchanged;
- anything else is wrapped in single quotes, each `'` inside written as `'"'"'`;
- non-ASCII characters are not in the safe set, so `çé` gives `'çé'`.

`join` quotes each item and puts one space between them; an empty list gives `""`.

`split`:
- splits on space, tab, CR and LF; an empty or blank string gives an empty list;
- `'...'` keeps every byte as it is; `"..."` keeps every byte except that `\"` and `\\`
  lose their backslash (any other `\x` keeps both bytes);
- outside quotes `\x` gives `x`;
- an empty quoted string (`''`) is a token: `split("''")` is `[""]`;
- quoted and unquoted pieces next to each other join into one token (`'a'"b"c` is `abc`);
- `#` is not a comment;
- raises `Error("No closing quotation")` inside an unterminated quote, and
  `Error("No escaped character")` for a backslash at the end of the input, even inside a
  quote.
