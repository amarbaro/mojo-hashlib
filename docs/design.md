# Design

Three rules decide the layout: input is hashed where it lies, nothing is allocated per
update, and every constant the compiler can fold is folded.

## One hasher, three algorithms

`Hasher[algo]` is one struct. The algorithm is a compile-time parameter, so `Sha256`,
`Sha1` and `Md5` share the block buffering, the padding and the hex code, and only the
block function and a few constants differ (`comptime if`). That is 240 lines for the
three hashes, hex included.

## Input is hashed in place

`update` compresses every whole 64-byte block straight from the caller's `Span`. Only
the tail (under 64 bytes) is copied, into the one fixed `Array[UInt8, 64]` the hasher
owns. A bulk update allocates nothing. `digest()` finishes on a copy of the state and the
buffer, so it does not change the hasher and does not allocate either (the result is an
`Array`, and `hexdigest` writes one sized `String`).

The struct is 112 bytes for all three algorithms, measured with `size_of`. Fields go
widest first: the 8-byte length, 32 bytes of state, 64 bytes of buffer, the fill count.
Md5 and sha1 do not use the whole 8-word state, and sharing one layout costs 12 to 16
bytes per hasher, which is cheaper than three structs.

## Unrolled rounds with constant operands

The first version looped over the rounds and read the constants from a `comptime` table.
Two costs: a `comptime` array indexed at run time has to be `materialize`d first, a copy
of the table (256 bytes for sha256) on every block, and a branch per round chooses the
round function.

The block functions now use `comptime for` over the rounds. The round function, the
constant, the rotate amount and the message word index are all compile-time values, so
each round is straight-line code with immediates.

| 64 MiB, 4 KiB updates | looped | unrolled |
|---|---|---|
| sha256 | 182 to 185 ms | 133 to 150 ms |
| sha1 | 166 to 233 ms | 57 to 64 ms |
| md5 | 180 to 212 ms | 71 to 84 ms |

## Message schedule in 16 words

Sha256 and sha1 keep only the last 16 words of the message schedule, updated in place as
the rounds run, instead of the full 64 or 80 words. The stack frame shrinks from 256 and
320 bytes to 64. The time did not change within the run-to-run noise (sha256 133 to 150
ms either way), so this is a memory saving only.

## Why not the CPU's SHA instructions

Python gets 27 ms for 64 MiB of sha256 from OpenSSL, which uses SHA-NI. Mojo can call
those instructions through LLVM intrinsics, but they need a build flag or a run-time CPU
check, and a wrong guess crashes on an older CPU. The library stays portable and says so
in its limits.

## shlex

`quote` scans once. A string that needs no quoting is copied once. Otherwise it is
written as slices between the single quotes into one `String` whose capacity is set up
front, so there is no per-byte append. `join` sizes one output for the whole list and
quotes each item into it, with no intermediate string per item.

`split` is one pass over the bytes with five states (between words, in a word, in `'`, in
`"`, after a backslash) and one reused token buffer; each token costs one `String`. It is
byte-wise: the delimiters and quotes are ASCII, and a UTF-8 continuation byte never equals
one of them, so multi-byte characters pass through unchanged. It was written from CPython's
`shlex.read_token` state machine, and the oracle cases include a trailing backslash, an
unterminated quote, an empty quoted token and an escaped quote.

On 100,000 rounds of `split`, `join` and `quote` this takes 49 to 58 ms, against 1.55 s
in Python.

## Correctness: Python is the oracle

`tools/oracle.py` prints one line per case from `hashlib` and `shlex`; `tests/cases.mojo`
prints the same lines from this library; `scripts/check.sh` diffs them. The random
inputs are `random.Random(1).randrange(256)`, so the runner carries a short MT19937
with CPython's seeding. The block edges (55, 56, 63, 64 and 65 bytes, where padding
spills into a second block) and a 100,000-byte input are in the cases. `tests/api.mojo`
adds every two-piece split and the byte-at-a-time split for 14 lengths around the block
size, and digest-then-update.
